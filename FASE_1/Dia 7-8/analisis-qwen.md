# Análisis Técnico: Día 7-8 — Persistencia Local Offline

> **Agente:** Qwen  
> **Documento:** mvp-Definition.md  
> **Paso:** Día 7-8  
> **Alcance:** Estructurar `vrm_data` con persistencia JSON para reanudar pipelines cancelados

---

## 1. Diseño Funcional

### Problema que resuelve
El usuario puede interrumpir una grabación en cualquier punto (llamada, cierre de app, crash, batería baja). Sin persistencia, pierde todo el progreso del pipeline (idea → guion → clips grabados) y debe reiniciar desde cero. Este paso garantiza **resiliencia ante interrupciones**.

### Inputs
- `project_id` (UUID generado al iniciar un nuevo proyecto)
- `input_schema.json`: parámetros crudos del pipeline (intención, template seleccionado, idea original, parámetros de cámara)
- `script_bundle.json`: guion generado (texto validado, fragmentos/partes del guion, metadata de cada fragmento)
- `session_data.json`: estado de grabación (qué fragmentos ya tienen clips válidos, cuáles fueron descartados, timestamps, número de takes por fragmento)
- Clips de video existentes en `/clips/` (archivos `.mp4` ya grabados y validados)

### Outputs
- Estructura de carpetas `/vrm_data/projects/{project_id}/` creada y poblada en disco
- Archivos JSON serializados y escritos correctamente
- Capacidad de **reanudación**: al reabrir la app, el dashboard lee `session_data.json` y restaura el estado exacto del pipeline
- `user_profile.json` en `/vrm_data/` con preferencias maestras (velocidad del teleprompter, modo de cámara, auto-focus, etc.)

### Rol dentro del sistema
Es la **capa de persistencia** que conecta:
- **Fase anterior (Día 1-6):** Grabación → Revisión → Stitch → Export
- **Fase siguiente (Día 9-10):** IA Offline / Fallback y dashboard con proyectos persistentes

Sin este paso, el sistema es **stateless** y no puede sobrevivir a un restart de la app.

---

## 2. Supuestos y Ambigüedades

### No definido explícitamente
1. **¿Cómo se genera `project_id`?** No se especifica si es UUID v4, timestamp-based, o un hash de la idea original.
2. **¿Cuándo se disparan las escrituras a disco?** ¿Cada vez que cambia un estado (incremental) o solo al cerrar la app?
3. **¿Qué pasa si el JSON se corrompe?** No hay estrategia de recovery definida.
4. **¿Se persisten los clips descartados?** El documento menciona "takes válidos/descartados" pero no aclara si los descartados se eliminan del disco o solo se marcan en el JSON.
5. **¿Existe un límite de proyectos almacenados?** Sin política de cleanup, el almacenamiento se llenará.
6. **¿Qué preferencias específicas van en `user_profile.json`?** Solo se menciona "preferencias maestras estáticas" sin detalle.
7. **¿Se necesita encriptación?** Datos de usuario en texto plano pueden ser problema para revisión de tiendas.

### Preguntas críticas antes de implementar
1. ¿El usuario debe poder ver una lista de proyectos anteriores y reanudar cualquiera, o solo el más reciente?
2. ¿Los clips descartados se eliminan físicamente o se mantienen en una carpeta `/clips/discarded/`?
3. ¿Qué ocurre si el archivo `session_data.json` existe pero los clips referenciados ya no están en disco?
4. ¿Se necesita migración de esquema para futuras versiones del formato JSON?

---

## 3. Diseño Funcional

### Pipeline Completo

```
1. Usuario inicia nuevo proyecto desde Dashboard
   ↓
2. Se genera project_id (UUID v4)
   ↓
3. Se crea estructura de carpetas en /vrm_data/projects/{project_id}/
   ↓
4. Se escribe input_schema.json con parámetros iniciales
   ↓
5. Usuario genera guion (IA o template fallback)
   ↓
6. Se escribe script_bundle.json con guion validado
   ↓
7. Se inicia session_data.json con estado inicial (todos los fragmentos pendientes)
   ↓
8. POR CADA fragmento grabado:
   a. Clip se guarda en /clips/fragmento_{N}_take_{M}.mp4
   b. Se actualiza session_data.json (estado: "validado" o "descartado")
   ↓
9. SI app se cierra/crashea:
   a. Al reabrir, Dashboard lee /vrm_data/projects/
   b. Identifica proyectos con session_data.json donde haya fragmentos pendientes
   c. Ofrece "Reanudar" o "Descartar"
   ↓
10. SI proyecto se completa y exporta:
    a. Se marca session_data.json como "completado"
    b. Opcional: mover a /projects/archive/
```

### Casos Normales
- Usuario graba 3 fragmentos, cierra app, vuelve y reanuda desde el fragmento 4
- Usuario completa un proyecto, lo exporta, el JSON queda marcado como `status: "exported"`

### Edge Cases
| Escenario | Comportamiento |
|---|---|
| App crashea a mitad de escribir JSON | Usar write atomica: escribir a `.tmp` y renombrar |
| Clip referenciado en JSON ya no existe en disco | Marcar como `status: "missing"` y ofrecer re-grabar |
| Múltiples proyectos con mismo estado `in_progress` | Listar todos en Dashboard y permitir elegir cuál reanudar |
| Espacio en disco insuficiente para crear carpeta | Validar espacio antes de crear proyecto, mostrar error |
| JSON con formato inválido al leer | Try-catch con fallback: si falla, ofrecer "Reiniciar proyecto" |
| Usuario desinstala y reinstala app | Los datos en `getApplicationDocumentsDirectory()` persisten |

### Manejo de Errores
```dart
// Patrón obligatorio en TODAS las operaciones de I/O
Future<T> safeReadJson<T>({
  required String path,
  required T Function(Map<String, dynamic>) fromJson,
  required T fallback,
}) async {
  try {
    final file = File(path);
    if (!await file.exists()) return fallback;
    final raw = await file.readAsString();
    return fromJson(jsonDecode(raw));
  } catch (e, stack) {
    // Log silencioso, no crash
    debugPrint('safeReadJson error: $e\n$stack');
    return fallback;
  }
}

// Escritura atómica
Future<void> safeWriteJson({
  required String path,
  required Map<String, dynamic> data,
}) async {
  final file = File(path);
  final tempPath = '$path.tmp';
  final tempFile = File(tempPath);
  await tempFile.writeAsString(jsonEncode(data));
  await tempFile.rename(path); // Atómico en POSIX y la mayoría de FS
}
```

---

## 4. Diseño Técnico

### Arquitectura Sugerida
**Repository Pattern** con una capa de abstracción sobre el filesystem.

```
lib/
├── core/
│   ├── persistence/
│   │   ├── vrm_storage_service.dart       ← Servicio principal
│   │   ├── models/
│   │   │   ├── project_schema.dart         ← input_schema
│   │   │   ├── script_bundle.dart          ← script_bundle
│   │   │   └── session_data.dart           ← session_data
│   │   └── user_profile_store.dart         ← user_profile.json
│   └── utils/
│       └── json_helpers.dart               ← safeReadJson, safeWriteJson
├── features/
│   ├── dashboard/
│   │   └── dashboard_page.dart             ← Lee proyectos existentes
│   ├── recording/
│   │   └── recording_page.dart             ← Escribe session_data
│   └── project/
│       └── project_resume_page.dart        ← Pantalla de reanudar
```

### Componentes

#### `VRMStorageService`
Responsabilidad única: CRUD sobre la estructura `/vrm_data/`.

```dart
class VRMStorageService {
  final Directory _baseDir;

  VRMStorageService(this._baseDir);

  // Projects
  Future<String> createProject(ProjectSchema input);
  Future<ProjectSchema?> loadProjectSchema(String projectId);
  Future<void> saveScriptBundle(String projectId, ScriptBundle bundle);
  Future<SessionData?> loadSessionData(String projectId);
  Future<void> saveSessionData(String projectId, SessionData data);
  Future<List<ProjectSummary>> listProjects();
  Future<void> deleteProject(String projectId);
  Future<void> archiveProject(String projectId);

  // Clips
  Future<String> getClipPath(String projectId, int fragmentIndex, int takeNumber);
  Future<List<String>> listClips(String projectId);
  Future<void> deleteClip(String projectId, String clipFileName);

  // User Profile
  Future<UserProfile?> loadUserProfile();
  Future<void> saveUserProfile(UserProfile profile);

  // Utility
  Future<int> getStorageUsageBytes();
  Future<void> clearAllData();
}
```

#### Modelos de Datos (Schemas)

```dart
// input_schema.json
{
  "project_id": "uuid-v4-string",
  "created_at": "ISO-8601",
  "intention": "educate | entertain | inspire | sell",
  "template_id": "PAS | AIDA | STORY",
  "raw_idea": "texto original del usuario",
  "camera_params": {
    "resolution": "1080p",
    "fps": 30,
    "auto_focus": true,
    "street_mode": false
  }
}

// script_bundle.json
{
  "generated_at": "ISO-8601",
  "full_text": "guion completo como string",
  "fragments": [
    {
      "index": 0,
      "text": "primer párrafo del guion",
      "estimated_duration_sec": 12
    },
    {
      "index": 1,
      "text": "segundo párrafo",
      "estimated_duration_sec": 8
    }
  ]
}

// session_data.json
{
  "status": "in_progress | completed | exported | abandoned",
  "current_fragment_index": 2,
  "fragments": [
    {
      "index": 0,
      "status": "validated",
      "takes": [
        {"take_number": 1, "file": "fragment_0_take_1.mp4", "duration_sec": 11.5, "discarded": true},
        {"take_number": 2, "file": "fragment_0_take_2.mp4", "duration_sec": 12.1, "discarded": false}
      ],
      "validated_clip": "fragment_0_take_2.mp4"
    },
    {
      "index": 1,
      "status": "validated",
      "takes": [...],
      "validated_clip": "fragment_1_take_1.mp4"
    },
    {
      "index": 2,
      "status": "pending",
      "takes": [],
      "validated_clip": null
    }
  ],
  "last_updated": "ISO-8601"
}

// user_profile.json
{
  "prompter_speed": 1.0,
  "font_size": 18,
  "camera_resolution": "1080p",
  "camera_fps": 30,
  "auto_focus": true,
  "street_mode": false,
  "ghost_mode": false,
  "filler_words_tracking": false,    // Siempre false (excluido del MVP)
  "last_opened_at": "ISO-8601"
}
```

### Integraciones Externas
| Librería | Uso |
|---|---|
| `path_provider` | Obtener `getApplicationDocumentsDirectory()` |
| `path` | Construir rutas seguras (`join`, `basename`) |
| `uuid` | Generar `project_id` |

---

## 5. Decisiones Tecnológicas

### Lenguaje y Framework
- **Dart + Flutter** (ya es el stack del proyecto)

### Librerías
| Librería | Versión | Justificación |
|---|---|---|
| `path_provider` | `^2.1.0` | Estándar para obtener rutas persistentes en iOS/Android. Los datos sobreviven a reinstalaciones en iOS (iCloud backup por defecto). |
| `path` | `^1.9.0` | Manipulación segura de rutas. Evita errores de separadores `/` vs `\` entre plataformas. |
| `uuid` | `^4.0.0` | Generación de IDs únicos sin colisiones. Mejor que timestamp-based para evitar conflictos si el usuario crea dos proyectos en el mismo segundo. |

### ¿Por qué JSON y no SQLite/Isar/Hive?
- **JSON es suficiente** para el MVP: < 50 proyectos simultáneos, archivos < 10KB cada uno
- **Menos dependencias** = menos riesgos de build (especialmente con `ffmpeg_kit` ya agregado)
- **Debuggable**: se pueden inspeccionar archivos directamente desde el dispositivo o simulador
- **Migración futura**: si el volumen crece, se puede migrar a Hive/Isar con un script de migración leyendo los JSON existentes

### Escritura Síncrona vs Asíncrona
- **Siempre asíncrona** (`file.writeAsString()` con `await`). Escritura síncrona en el main thread causa jank en Flutter.
- **No se necesita isolate**: los archivos son < 10KB, la serialización JSON es trivial para ese tamaño.

---

## 6. Plan de Implementación

### Backlog de Tareas (Orden Recomendado)

| # | Tarea | Descripción | Dependencias | Estimación |
|---|---|---|---|---|
| 1 | **Agregar dependencias** | Añadir `path_provider`, `path`, `uuid` al `pubspec.yaml` y ejecutar `flutter pub get` | — | 15 min |
| 2 | **Crear modelos de datos** | Implementar clases `ProjectSchema`, `ScriptBundle`, `SessionData`, `UserProfile` con `fromJson`/`toJson` | #1 | 1 hora |
| 3 | **Crear `VRMStorageService`** | Implementar servicio con métodos CRUD + `safeReadJson`/`safeWriteJson` | #2 | 3 horas |
| 4 | **Crear proyecto desde Dashboard** | Al iniciar nuevo proyecto, generar UUID, crear carpetas, escribir `input_schema.json` | #3 | 1.5 horas |
| 5 | **Guardar guion generado** | Cuando IA/fallback genera guion, escribir `script_bundle.json` | #3, #4 | 1 hora |
| 6 | **Inicializar session_data** | Al empezar grabación, crear `session_data.json` con todos los fragmentos en `pending` | #3, #5 | 1 hora |
| 7 | **Actualizar sesión por clip** | Cada vez que se graba y valida/descarta un clip, actualizar `session_data.json` | #3, #6 | 1.5 horas |
| 8 | **Reanudación desde Dashboard** | Dashboard lee `listProjects()`, muestra proyectos `in_progress`, botón "Reanudar" | #3, #7 | 2 horas |
| 9 | **Pantalla de reanudación** | Si hay proyecto incompleto, mostrar "Tienes un proyecto en progreso. ¿Reanudar o descartar?" | #3, #8 | 1.5 horas |
| 10 | **`user_profile.json`** | Leer al inicio de la app, guardar cuando cambien preferencias | #3 | 1 hora |
| 11 | **Manejo de errores y edge cases** | JSON corrupto, clips missing, espacio insuficiente | #3-#10 | 2 horas |
| 12 | **Testing en dispositivo físico** | Probar flujo completo: crear → grabar 2 clips → cerrar app → reabrir → reanudar → completar | #1-#11 | 2 horas |

**Total estimado: ~18 horas (~2 días de trabajo concentrado)**

### Orden de Desarrollo
```
#1 → #2 → #3 → #4 → #5 → #6 → #7 → #8 → #9 → #10 → #11 → #12
```
Las tareas #4-#7 pueden implementarse en paralelo si hay 2 desarrolladores, pero #3 es bloqueante de todas.

---

## 7. Riesgos y Cuellos de Botella

### Técnicos
| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `path_provider` devuelve ruta sin permisos de escritura | Baja | 🔴 Alto | Testear en iOS y Android físico el día 1 de implementación |
| JSON se corrompe por write interrumpido | Media | 🟡 Medio | Escritura atómica (`.tmp` → rename) ya contemplada |
| Memoria insuficiente en dispositivos de gama baja | Media | 🟡 Medio | Validar `StorageInfo` antes de crear proyecto |
| `uuid` genera colisión (extremadamente raro) | ~0 | ⚪ Mínimo | No aplica |

### Operativos
| Riesgo | Mitigación |
|---|---|
| Usuario llena el almacenamiento del teléfono con proyectos abandonados | Implementar `getStorageUsageBytes()` y alerta cuando supere 500MB |
| Usuario no entiende por qué aparece un proyecto "en progreso" | UI clara: "Grabaste 3 de 8 fragmentos. ¿Continuar?" |

### Escalabilidad
| Problema al escalar | Solución |
|---|---|
| +500 proyectos = lentitud listándolos todos | Paginar en Dashboard (mostrar 10 más recientes) |
| JSON de session_data crece con muchos takes | Implementar rotación: mantener solo último take descartado + validado |
| Múltiples procesos accediendo al mismo archivo | No aplica en MVP (single-user, single-process) |

### Costos
- **$0 adicionales.** Todo es almacenamiento local. No hay backend ni servicios externos.

---

## 8. Métricas de Éxito

### KPIs Técnicos
| Métrica | Target | Cómo medir |
|---|---|---|
| Tiempo de lectura de `session_data.json` | < 50ms | `DateTime.now()` antes/después de `readAsString` |
| Tiempo de escritura atómica | < 100ms | Idem |
| Tasa de corrupción de JSON | 0% | Contar cuántas veces `safeReadJson` retorna fallback por error de parseo |
| Tasa de reanudación exitosa | > 95% | Proyectos reanudados / proyectos interrumpidos |
| Crash rate por I/O | 0 crashes | Firebase Crashlytics o logs locales |

### KPIs de Producto
| Métrica | Target |
|---|---|
| Usuarios que reanudan un proyecto al menos 1 vez | > 30% de sesiones |
| Pérdida de progreso reportada por usuarios | < 1% de sesiones |

### Validación de Implementación
1. Crear proyecto, grabar 3 clips, forzar cierre de app (swipe up)
2. Reabrir app → Dashboard muestra proyecto "en progreso"
3. Click "Reanudar" → Recording page aparece en fragmento 4
4. Completar grabación → verificar que `final.mp4` se genera correctamente
5. Verificar que todos los JSON son legibles y consistentes

---

## 9. Estrategia de Testing

### Unit Tests
```dart
// test/core/persistence/vrm_storage_service_test.dart

test('creates project directory structure', () async {
  // Mock path_provider → directorio temporal
  final service = VRMStorageService(tempDir);
  final projectId = await service.createProject(testInputSchema);
  
  expect(Directory(join(tempDir.path, 'projects', projectId)).existsSync(), isTrue);
  expect(File(join(tempDir.path, 'projects', projectId, 'input_schema.json')).existsSync(), isTrue);
});

test('safeWriteJson is atomic (no corruption on interrupt)', () async {
  // Simular interrupción a mitad de escritura verificando que .tmp existe
  // y que el archivo final nunca queda a medio escribir
});

test('safeReadJson returns fallback on corrupted file', () async {
  // Escribir JSON inválido manualmente
  // Verificar que safeReadJson retorna fallback sin lanzar excepción
});

test('listProjects returns only projects with valid session_data', () async {
  // Crear 3 proyectos, corromper uno, verificar que solo devuelve 2
});

test('session_data updates correctly when clip is validated', () async {
  // Grabar clip simulado → actualizar session_data → verificar estado
});
```

### Integration Tests
```dart
// integration_test/persistence_flow_test.dart

testWidgets('full record-resume-export flow persists correctly', (tester) async {
  // 1. Crear proyecto desde UI
  // 2. Grabar 2 clips
  // 3. Matar app (no hay forma programática, pero se puede simular con popUntil)
  // 4. Reiniciar app
  // 5. Verificar que Dashboard muestra proyecto en progreso
  // 6. Reanudar y completar
  // 7. Verificar que session_data.json tiene status "completed"
});
```

### Casos Críticos a Validar
| # | Caso | Resultado Esperado |
|---|---|---|
| 1 | Crear proyecto sin espacio en disco | Error UI: "No hay suficiente espacio" |
| 2 | JSON corrupto al reabrir | Diálogo: "Proyecto dañado. ¿Reiniciar?" |
| 3 | Clip referenciado no existe en disco | `status: "missing"`, ofrecer re-grabar |
| 4 | App cerrada durante stitch | `session_data` sigue `in_progress`, clips individuales intactos |
| 5 | 50 proyectos en paralelo | Dashboard carga en < 2 segundos |
| 6 | Usuario borra carpeta manualmente desde file manager | App no crashea, proyecto desaparece del Dashboard |

---

## 10. Optimización y Escalabilidad Futura

### Problemas que aparecerán al escalar
| Umbral | Problema | Solución |
|---|---|---|
| > 100 proyectos | `listProjects()` lento leyendo JSON uno por uno | Index file: `projects_index.json` con metadatos resumidos |
| > 1GB de clips | `getStorageUsageBytes()` tarda | Cachear tamaño y actualizar incrementalmente |
| Multi-usuario | JSON local no permite concurrencia | Migrar a Hive/Isar con soporte multi-isolate |
| Cloud sync | Sin backend los proyectos son device-local | Implementar sync con Firebase Storage o iCloud/Google Drive |
| Búsqueda de proyectos | Filtrar por fecha, estado, tags | Migrar a SQLite/Isar con queries indexadas |

### Cómo dejar preparado el diseño desde ahora
1. **Interfaz `IVRMStorage`**: Definir una interfaz abstracta. Hoy la implementación es `FileSystemStorage`, mañana puede ser `DatabaseStorage` sin cambiar el resto del código.
2. **Versionado de schemas**: Agregar `"schema_version": 1` a todos los JSON. Cuando el formato cambie, se detecta y se migra.
3. **Event bus**: Emitir eventos `ProjectCreated`, `SessionUpdated`, `ClipSaved`. Permite que otros componentes reaccionen sin acoplarse al storage service.
4. **Lazy loading en Dashboard**: No cargar todos los JSON al inicio. Cargar metadatos mínimos y hacer load completo solo al seleccionar un proyecto.

```dart
// Interfaz abstracta para futura migración
abstract class IVRMStorage {
  Future<String> createProject(ProjectSchema input);
  Future<ProjectSchema?> loadProjectSchema(String projectId);
  // ... resto de métodos
}

// Implementación actual
class FileSystemVRMStorage implements IVRMStorage {
  final Directory baseDir;
  // ...
}

// Implementación futura (cuando escale)
class DatabaseVRMStorage implements IVRMStorage {
  final Database db;
  // ...
}
```

---

## Resumen de Artefactos a Crear

| Archivo | Contenido |
|---|---|
| `lib/core/persistence/vrm_storage_service.dart` | Servicio principal CRUD |
| `lib/core/persistence/models/project_schema.dart` | Modelo input_schema |
| `lib/core/persistence/models/script_bundle.dart` | Modelo script_bundle |
| `lib/core/persistence/models/session_data.dart` | Modelo session_data |
| `lib/core/persistence/models/user_profile.dart` | Modelo user_profile |
| `lib/core/utils/json_helpers.dart` | safeReadJson, safeWriteJson |
| `lib/features/project/project_resume_page.dart` | Pantalla de reanudación |
| `test/core/persistence/vrm_storage_service_test.dart` | Unit tests |
| `integration_test/persistence_flow_test.dart` | Integration test |

---

*Análisis generado por Qwen — Día 7-8: Persistencia Local Offline*  
*Nivel: Listo para revisión por CTO / implementación inmediata por equipo de desarrollo*
