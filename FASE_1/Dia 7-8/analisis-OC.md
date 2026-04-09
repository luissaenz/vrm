# Análisis de Implementación: Día 7-8 (Persistencia Local Offline)

**Agente:** OC (OpenCode)
**Documento Base:** `mvp-Definition.md`
**Enfoque del Paso:** Persistencia Local Offline - Implementación técnica del sistema de guardado y recuperación de proyectos.

---

## Diseño Funcional

### 1.1 Objetivo del paso
Permitir que un proyecto VRM pueda interrumpirse y continuarse posteriormente sin pérdida de datos. El usuario debe poder cerrar la app en cualquier momento y resuming posteriormente desde el último punto válido.

### 1.2 Inputs
- `VrmProject` en memoria (modelo con metadatos, guion, configuración)
- Clips de video temporales capturados por `_cameraController`
- Estado actual del pipeline (Idea → Guion → Grabación → Stitch → Export)

### 1.3 Outputs
- Estructura de archivos en `ApplicationDocumentsDirectory/vrm_data/projects/{uuid}/`
- JSONs: `input_schema.json`, `script_bundle.json`, `session_data.json`
- Directorio `/clips/` con clips validados

### 1.4 Flujo operacional

| Evento | Trigger | Acción |
|--------|---------|--------|
| Crear proyecto | Usuario confirma guion | Crear carpeta uuid + init JSONs |
| Grabar segmento | Aprobar clip | Mover clip a `/clips/` + update `session_data.json` |
| Cambiar pantalla | Navigator push/pop | Autosave background async |
| Kill app (crash) | OS cleanup | Auto-recuperar desde último JSON válido |
| Reabrir app | Dashboard load | Leer directorios → deserializar → mostrar lista |

### 1.5 Edge cases
- **Archivo referenciado no existe:** Validar paths al cargar. Si `clips/seq1.mp4` no existe, marcar segmento como "pendiente".
- **Stitch incompleto:** Si app mata durante stitch, `session_data.json` debe indicar `stitch_status: "incomplete"` para permitir re-render.
- **Storage lleno:** Capturar `FileSystemException` y mostrar UI de error clara.

---

## Diseño Técnico

### 2.1 Arquitectura - Patrón Repository

```
lib/
├── data/
│   ├── models/
│   │   ├── vrm_project.dart        # Entidad raíz
│   │   ├── script_bundle.dart     # Guion segmentado
│   │   └── session_metadata.dart  # Estado del pipeline
│   ├── repositories/
│   │   ├── project_repository.dart    # Interfaz abstracta
│   │   └── project_repository_impl.dart # Implementación FileSystem
│   └── datasources/
│       └── local_file_datasource.dart # I/O operations
└── core/
    └── constants/
        └── storage_paths.dart     # Rutas base path_provider
```

### 2.2 Modelos de datos

**vrm_project.dart:**
```dart
class VrmProject {
  final String id;           // UUID
  final String title;       // Título user-facing
  final InputSchema input;  // Parámetros iniciales
  final ScriptBundle script;
  final SessionMetadata session;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**session_metadata.dart:**
```dart
class SessionMetadata {
  final String currentPhase;      // IDEA, SCRIPT, RECORDING, STITCH, EXPORT
  final Map<String, String> clipsRecorded;  // segment_id -> path
  final bool stitchCompleted;
  final String? finalVideoPath;
  final DateTime lastUpdate;
}
```

### 2.3 APIs del Repository

```dart
abstract class ProjectRepository {
  Future<void> saveProject(VrmProject project);
  Future<VrmProject?> loadProject(String id);
  Future<List<VrmProjectSummary>> listProjects();  // Lightweight para dashboard
  Future<void> deleteProject(String id);
  Future<void> updateClipPath(String projectId, String segmentId, String path);
}
```

### 2.4 Estrategia de escritura atómica
Para evitar corrupción por interrupción:

```dart
Future<void> safeWrite(String path, String content) async {
  final tempPath = '$path.tmp';
  final tempFile = File(tempPath);
  await tempFile.writeAsString(content);
  await tempFile.rename(path);  // Atomic on most OS
}
```

### 2.5 Rutas base
```dart
final appDir = await getApplicationDocumentsDirectory();
final vrmRoot = Directory('${appDir.path}/vrm_data/projects');
```

---

## Decisiones

### 3.1 Por qué JSON sobre SQLite
- **Simplesidad MVP:** Los proyectos son documentos texto, no datos relacionales
- **Schemas evolutivos:** JSON permite agregar campos sin migración
- **Debugging:** JSON legible facilita desarrollo

### 3.2 Por qué path_provider
- **Persistencia real:** `ApplicationDocumentsDirectory` sobrevive app updates
- **No limpieza automática:** A diferencia de cache, no se borra por OS
- **Compatibilidad:** Funciona tanto en iOS como Android

### 3.3 Clips: Move vs Copy
- **Decisión:** Mover (`File.rename()`) en vez de copiar
- **Justificación:** Evita duplicar archivos pesados
- **Fallback:** Si rename falla (cross-filesystem), usar copy + delete

### 3.4 Trigger de guardado
- **Decisión:** Autosave en transiciones de fase + al aprobar clip
- **No usar:** onPause/ lifecycle - puede no ejecutarse en kill abrupto
- **Razón:** Las transiciones son puntos claros de estado válido

---

## Riesgos

### 4.1 Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Corrupción JSON por write interrumpido | Media | Alto | Escritura atómica (temp + rename) |
| NullPointer al cargar JSON mal formados | Media | Medio | Parser con defaults explícitos |
| Storage lleno durante grabación | Baja | Alto | Pre-check espacio antes de grabar |

### 4.2 Operativos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Orphaned clips (sin proyecto referenciado) | Baja | Medio | Cleanup en deleteProject() |
| Dashboard lento con muchos proyectos | Media | Medio | Usar isolates para parsing |

### 4.3 Escalabilidad

- **Problema:** Leer 50 JSONs para listing会造成 UI jank
- **Solución V2:** Índice SQLite con solo id + title + status
- **Preparación actual:** Estructura de carpetas permite migración transparente

---

## Plan

### Tareas (Orden recomendado)

| # | Tarea | Dependencias | Estimación |
|---|-------|--------------|------------|
| 1 | Crear modelos `VrmProject`, `ScriptBundle`, `SessionMetadata` con toJson/fromJson | Ninguna | 1h |
| 2 | Implementar `LocalFileDatasource` - métodos CRUD archivos/carpetas | #1 | 2h |
| 3 | Implementar `ProjectRepositoryImpl` con escritura atómica | #2 | 2h |
| 4 | Integrar repository en Provider/ServiceLocator del app | #3 | 1h |
| 5 | Hookear autosave en transición Idea→Guion y Segment approval | #4 | 2h |
| 6 | Modificar dashboard para leer lista de proyectos | #4 | 1h |
| 7 | Implementar lógica de resume: cargar proyecto y detectar último estado válido | #5 | 2h |
| 8 | Implementar deleteProject con cleanup de archivos | #7 | 1h |
| 9 | Testing: crash recovery, storage full, JSON corruption | Todas | 3h |

### Priorización
1-4: Core infrastructure (días 7)
5-7: Integración UI (día 8)
8-9: Cleanup y testing (día 8后半)

---

## Validación

### Criterios de éxito
- [ ] Crear proyecto → kill app → reabrir → proyecto aparece en dashboard
- [ ] Grabar segmento → kill → reabrir → segmento marcado como "completado" con path válido
- [ ] 10 proyectos en dashboard carga en < 500ms
- [ ] Delete borra carpeta física completamente

### Tests críticos
1. **Crash recovery:** Kill app durante grabación. Reabrir. Verificar estado intacto.
2. **Corruption:** Editar JSON manualmente. Verificar que parser no crashea.
3. **Storage full:** Simulardisk lleno. Verificar mensaje de error claro.