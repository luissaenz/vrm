# Análisis: Día 6 - Exportación
**Documento:** docs\mvp-Definition.md  
**Paso:** día 6  
**Agente:** OC  

---

## 1. Comprensión del paso

### Problema que resuelve
Permite al usuario exportar el video final (`final.mp4`) a la galería del dispositivo y compartirlo vía el modal nativo del OS.

### Inputs
- `projectId`: Identificador del proyecto
- Archivo `final.mp4` existente en `/vrm_data/projects/{project_id}/final.mp4`

### Outputs
- Video guardado en galería nativa (Fotos/iCloud)
- Modal de Share Sheet abierto con el video

### Rol en el sistema
Es el paso final del pipeline: `Idea → Guion → Grabar → Unir → Exportar`

---

## 2. Supuestos y ambigüedades

| Item | Estado | Pregunta crítica |
| :--- | :--- | :--- |
| Ubicación de `final.mp4` | Assumido | ¿Ya está stitcheado en la ruta correcta `/vrm_data/projects/{project_id}/final.mp4`? |
| Permisos de galería | Por definir | ¿Se manejan en RecordingEndPage o se solicita en el momento? |
| Preview del video | No hay | ¿Se reproduce antes de exportar? |
| Progress indicator | No hay | ¿Se muestra feedback visual durante save/share? |
| Manejo de retry | Por definir | ¿Qué pasa si el usuario cancela o falla? |

---

## 3. Diseño funcional

### Flujo paso a paso (pipeline)
```
1. Usuario toca "Exportar Video" en RecordingEndPage
2. Show loading indicator (save to gallery...)
3. Verificar archivo final.mp4 existe
4. Solicitar permisos de galería (si no granted)
5. photo_manager.saveVideo() → asset en galería
6. Hide loading, show success
7. share_plus.shareXFiles([file])
8. OS Share Sheet nativo aparece
9. Usuario selecciona destino → share
10. Callback success/failure
```

### Casos normales
- Permisos granted → guardar → share sheet abre
- Permisos ya granted → skip step 4

### Edge cases
| Escenario | Manejo |
| :--- | :--- |
| `final.mp4` no existe | Mostrar error: "Video no encontrado. ¿Deseas reintentar stitching?" |
| Archivo corrupto (0 bytes) | 동일 |
| Permisos denegados | Mostrar diálogo explicativo + botón a Settings |
|Storage lleno | "Espacio insuficiente. Libera {X}MB e intenta de nuevo" |
| share_plus falla | Fallback: mostrar ruta del archivo para share manual |
| Timeout (>30s) | Cancelar, mostrar retry button |

### Manejo de errores
```dart
enum ExportState { idle, saving, sharing, success, error }

class ExportException implements Exception {
  final String message;
  final ExportErrorType type;
}
```

---

## 4. Diseño técnico

### Arquitectura sugerida
```
lib/
  services/
    export_service.dart      ← ExportService (EXPORTADO)
  features/
    recording/
      recording_end_page.dart ← Hookear buttons
```

### Componentes

#### ExportService
```dart
class ExportService {
  final String projectId;
  final ClipStorageService _storage;
  
  Future<ExportResult> saveToGallery() async
  Future<void> shareVideo(BuildContext context) async
  Future<ExportResult> exportFull(BuildContext context) async
  String? get finalVideoPath
}
```

#### RecordingEndPage (modificar)
- `onPressed` del ElevatedButton → ExportService.exportFull()
- Agregar estado local `ExportState`
- Agregar loading overlay

### APIs necesarias

| Paquete | Método | Uso |
| :--- | :--- | :--- |
| `photo_manager` | `PhotoManager.editor.saveVideo(path)` | Guardar en galería |
| `share_plus` | `Share.shareXFiles([XFile(path)])` | Native share sheet |
| `path_provider` | `getApplicationDocumentsDirectory()` | Obtener ruta |
| `permission_handler` | `Permission.photos.request()` | Solicitar permisos |

### Modelos de datos
```dart
class ExportResult {
  final bool success;
  final String? assetId;
  final String? errorMessage;
  final ExportErrorType? errorType;
}

enum ExportErrorType {
  fileNotFound,
  fileCorrupt,
  permissionDenied,
  storageFull,
  shareFailed,
  unknown
}
```

### Estructura de archivos (ya existe)
```
/vrm_data/
  /projects/
    /{project_id}/
      final.mp4          ← Input para export
```

---

## 5. Decisiones tecnológicas

### Librerías requeridas (agregar a pubspec.yaml)
```yaml
dependencies:
  photo_manager: ^3.0.0
  share_plus: ^7.0.0
  permission_handler: ^6.0.0   # opcional, PhotoManager maneja algunos
```

### Justificación
- `photo_manager`: Estándar Flutter para galería, maneja permisos iOS/Android automáticamente
- `share_plus`: API nativa share en iOS/Android, mantenimiento activo
- No require backend externo

### Configuración nativa requerida
- **iOS (Info.plist)**:
  - `NSPhotoLibraryAddUsageDescription`
  - `NSPhotoLibraryUsageDescription`
- **Android (AndroidManifest.xml)**:
  - `WRITE_EXTERNAL_STORAGE` (API < 29)
  - `READ_EXTERNAL_STORAGE` (API < 33)

---

## 6. Plan de implementación

### Tareas (backlog)

| # | Tarea | Depende de | Estimación |
| :--- | :--- | :--- | :--- |
| 1 | Agregar dependencias a `pubspec.yaml` | - | 5 min |
| 2 | Configurar Info.plist / AndroidManifest permisos | 1 | 10 min |
| 3 | Crear `ExportService` en `lib/services/export_service.dart` | 1 | 2 horas |
| 4 | Agregar `ExportState` y lógica a `RecordingEndPage` | 3 | 1 hora |
| 5 | Implementar manejo de errores y UI feedback | 4 | 30 min |
| 6 | Testing en device físico | - | 1 hora |

### Orden recomendado
1. Dependencias + configs nativas
2. ExportService (core logic)
3. Hook en RecordingEndPage
4. Errores + UI states
5. Test físico

---

## 7. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
| :--- | :---: | :--- | :--- |
| `photo_manager` no guarda video en iOS 14+ con Photos framework | Media | ALTO | Test early, fallback a file path manual |
| Permisos denegados y usuario no sabe ir a Settings | Media | MEDIO | Mostrar diálogo con "Abrir Ajustes" button |
| Archivo corrupto/vacío | Baja | ALTO | Verificar tamaño > 0 antes de save |
| Share sheet no abre por permissions denied | Baja | MEDIO | Try/catch, mostrar ruta manual |
| OOM en video muy grande (>2GB) | Baja | ALTO | Verificar tamaño antes |

---

## 8. Métricas de éxito

### KPIs técnicos
- [ ] `photo_manager.saveVideo()` retorna success en < 5s (video < 100MB)
- [ ] Share sheet abre sin crash
- [ ] Sin FileSystemException en logs

### KPIs de negocio
- [ ] Usuario puede exportar a galería
- [ ] Usuario puede compartir a cualquier app nativa
- [ ] Flujo completo < 30 segundos

---

## 9. Estrategia de testing

### Unit tests
- ExportService.saveToGallery() con file mock
- ExportService.shareVideo() con mock

### Integration tests
- Flow completo: tap Export → gallery → share sheet (manual)
- Permisos denegados flow

### Casos críticos
1. Video no existe → error correcto mostrado
2. Video corrupto (0 bytes) → error
3. Permisos denegados → diálogo shown
4. Storage lleno → mensajeclair

---

## 10. Optimización y escalabilidad futura

### Problemas futuros
- **Videos muy grandes**: Implementar chunks o compression antes de save
- **Múltiples exports**: Cola de exportación si usuario exporta repetidamente
- **Redirección a apps específicas**: Agregar share buttons directos (WhatsApp, TikTok, etc.)

### Preparación actual
- ExportService separado → fácil extender
- State management centralizado → no tightly coupled