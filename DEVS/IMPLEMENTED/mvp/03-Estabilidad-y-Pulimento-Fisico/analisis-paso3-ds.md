# 🧠 Análisis Técnico — Paso 3: Estabilidad y Pulimento Físico
**Agente:** ds | **Fecha:** 2026-05-05 | **Fase:** mvp

> Basado en `plan.md § Fase 3` (Días 14-18) y verificación contra código fuente real.

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

### Elementos Verificados

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `CameraHardwareException` existe | grep vrm_exceptions.dart | ✅ | `vrm_exceptions.dart:14` — clase con code, message, originalError |
| 2 | `StorageFullException` existe | grep vrm_exceptions.dart | ✅ | `vrm_exceptions.dart:19` — usado en `RecordingManager.startRecording()` L62 |
| 3 | `SessionIntegrityException` existe | grep vrm_exceptions.dart | ✅ | `vrm_exceptions.dart:29` — lanzado en `verifyIntegrityStatic()` L354 |
| 4 | `VideoProcessingException` existe | grep vrm_exceptions.dart | ✅ | `vrm_exceptions.dart:24` — para errores de stitch |
| 5 | `RecordingManager.verifyIntegrityStatic()` | grep recording_manager.dart | ✅ | `recording_manager.dart:328` — verifica clips aprobados existen en disco |
| 6 | ProGuard rules file existe | glob proguard* | ✅ | `android/app/proguard-rules.pro`, 17 líneas |
| 7 | `isMinifyEnabled=true` en build | grep build.gradle.kts | ✅ | `android/app/build.gradle.kts:60` — release build |
| 8 | `isShrinkResources=true` | grep build.gradle.kts | ✅ | `android/app/build.gradle.kts:61` — release build |
| 9 | `WidgetProgress` existe | grep widget_progress.dart | ✅ | `lib/shared/widgets/widget_progress.dart` — animación IA existente |
| 10 | `VRMEmptyState` existe | grep vrm_empty_state.dart | ✅ | `lib/shared/widgets/vrm_empty_state.dart:4` — reutilizable |
| 11 | CameraService try/catch cubre init/start/stop | read camera_service.dart | ✅ | L20-55 init, L65-79 start, L90-104 stop — wraps CameraException |
| 12 | RecordingManager try/catch cubre operaciones | read recording_manager.dart | ✅ | L58-79 start (space check), L84-162 stop, L302-323 dispose |
| 13 | Empty script guard en UI | read recording_page.dart | ✅ | L754-765 — `VRMEmptyState` si segments.isEmpty |
| 14 | Camera loading screen en UI | read recording_page.dart | ✅ | L820-838 — spinner + "Preparando cámara..." |
| 15 | Camera init error screen | read recording_page.dart | ✅ | L841-859 — mensaje error + volver |
| 16 | NativeStitcherService fallbacks | read native_stitcher_service.dart | ✅ | 3 niveles: native → ffmpeg → raw concat |
| 17 | ExportService error handling | read export_service.dart | ✅ | L25-59 — file check + permiso + try/catch photo_manager |

### Discrepancias

| # | Elemento | Discrepancia | Resolución |
|---|---|---|---|
| D1 | ProGuard `proguard-rules.pro` L9-12 | Reglas para `ffmpegkit` (L9-12) preservadas pero ffmpeg_kit_flutter eliminado de pubspec.yaml | **Limpiar**: remover L9-12 de `proguard-rules.pro`. Dead config infla APK innecesariamente. |
| D2 | No existe "Guardando..." state para exportación | `ExportService.saveToGallery()` no tiene callback de progreso ni UI de "Guardando en galería..." | **Agregar**: `Stream<double>` de progreso + UI overlay o snackbar persistente. |
| D3 | No hay recovery path para frame rejection | `CameraService` solo captura `CameraException` genérico. No hay lógica de re-intento ni fallback a resolución más baja cuando cámara rechaza frames. | **Agregar**: si `startVideoRecording()` falla con `CameraException`, reintentar con `ResolutionPreset.medium` → `low`. |
| D4 | Assets de branding no optimizados | `icon_source.png` y `splash_source.png` en `assets/images/branding/` sin minificación visible | **Verificar**: tamaños reales. Flutter ya comprime en build pero recomendar <500KB cada uno. |
| D5 | Test de recovery paths no existen | Solo `error_handling_test.dart` para PipelineException. No hay tests para CameraHardwareException, StorageFullException, SessionIntegrityException recovery. | **Agregar**: tests unitarios con mocks que simulen space full, camera crash, missing files. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema / Persistencia
- Sin cambios de schema. Paso 3 no toca datos nuevos.
- `SessionIntegrityException` en `RecordingManager.verifyIntegrityStatic()` es la única lógica de integridad de datos existente.
- `session_data.json` y `project.json` persisten en disco. Si hay corrupción → `PersistenceException`.

### Integridad Referencial
- ✅ `approvedClips` en `SessionData` referencia paths de archivos en disco.
- ✅ `verifyIntegrityStatic()` (L328-364) elimina referencias a clips que ya no existen en disco.
- ⚠️ **Riesgo**: `SessionIntegrityException.originalError` transporta `SessionData` corregido — esto es frágil. Si el receptor no captura el `originalError`, la data corregida se pierde.

### RLS / Auth
- No aplica (MVP 100% offline single-user).

### Índices / Tipos
- No aplica (JSON filesystem, sin DB).

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones/Clases Existentes (ninguna nueva en Paso 3)

| Función | Archivo | Firma | Patrón |
|---|---|---|---|
| `CameraService.initialize()` | `camera_service.dart:17` | `Future<void> initialize({CameraLensDirection? direction})` | try/catch con 3 niveles (no cameras → CameraException → catch-all) |
| `CameraService.startRecording()` | `camera_service.dart:59` | `Future<void> startRecording()` | Guard (not initialized → throw) → try/catch |
| `RecordingManager.verifyIntegrityStatic()` | `recording_manager.dart:328` | `static Future<SessionData> verifyIntegrityStatic(SessionData data)` | Itera approvedClips → verifica File.exists() → remove missing → throw SessionIntegrityException |
| `RecordingManager.dispose()` | `recording_manager.dart:302` | `Future<void> dispose()` | 3-step cleanup: stop partial → camera dispose → temp cleanup |
| `NativeStitcherService.stitchVideos()` | `native_stitcher_service.dart:14` | `Future<String> stitchVideos({required String projectId, required List<String> clipPaths, ...})` | Fallback chain: native → ffmpeg → raw concat |
| `ExportService.saveToGallery()` | `export_service.dart:25` | `Future<ExportResult> saveToGallery(String filePath)` | File check → permission → photo_manager try/catch |

### Patrones Existentes
- ✅ **Try/catch jerárquico**: `CameraException` específico → catch-all genérico. Consistente en `CameraService`, `RecordingManager`, `ClipStorageService`.
- ✅ **State reset en finally**: `RecordingManager` resetea `_isRecording` y `_isProcessing` en catch/finally (L71-79).
- ✅ **Cleanup idempotente**: `dispose()` en CameraService, RecordingManager — seguro llamar múltiples veces.
- ⚠️ **debugPrint como única observabilidad**: Todos los errores van a `debugPrint`. Sin logging a archivo ni crash reporter. En Release mode, `debugPrint` es no-op — errores silenciosos.

### Calidad
- **Cobertura try/catch**: 8/8 operaciones de IO cubiertas. Bueno.
- **Fallback en NativeStitcherService**: 3 niveles. Excelente robustez.
- **Missing**: No hay try/catch alrededor de `PhotoManager.editor.saveVideo()` en ExportService más allá del básico (L51-58). `PhotoManager` puede fallar en iOS 14+ limited access mode — el catch solo retorna `'exception'`.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- **No aplica**: Paso 3 es 100% frontend (Flutter). No hay endpoints, middleware ni servicios backend involucrados.
- Único punto de integración externa: `Permission.photos` y `PhotoManager.editor.saveVideo()` — APIs nativas del SO.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo End-to-End (Día 14-18)
```
Usuario graba → [D14-15] Blindaje:
  ├─ ¿Sin espacio? → StorageFullException → UI: "Espacio insuficiente, libera al menos 500MB"
  ├─ ¿Cámara falla? → CameraHardwareException → UI: "Error de cámara" + Recovery path
  └─ ¿Archivos faltantes? → SessionIntegrityException → UI: elimina referencias + reset fragmentos

[D16-17] Performance:
  ├─ ProGuard: isMinifyEnabled + isShrinkResources (release)
  ├─ Assets: branding images sin optimizar
  └─ Memory leaks: sin herramientas de profiling en el pipeline CI

[D18] UX States:
  ├─ Loading: "Preparando cámara..." (circular progress)
  ├─ Error cámara: icono + mensaje + "Ir a Configuración"
  ├─ Script vacío: VRMEmptyState + "Volver"
  └─ Export: sin "Guardando..." feedback
```

### Gaps Detectados
1. **Sin UI de progreso para exportación**: `ExportService.saveToGallery()` no notifica progreso. Usuario toca "Exportar" y no sabe si está funcionando.
2. **Sin recovery path visual para frame rejection**: Si cámara no puede grabar, solo lanza excepción. No hay "¿Intentar con menor resolución?"
3. **Observabilidad en Release**: `debugPrint` no emite en Release. Si hay crash silencioso en stitch o export, no hay forma de diagnosticar.
4. **Assets branding**: 2 imágenes en `assets/images/branding/`. Sin verificación de peso. Podrían inflar APK si no están optimizadas.

### DX & Tooling

```
### Herramienta Propuesta: Validador de Resiliencia (validador_resiliencia.dart)
- **Qué automatiza:** Prueba recovery paths en dispositivo real: espacio insuficiente (mock), cámara no disponible, archivos faltantes, stitch fallido. Reporta qué excepciones atrapa la app y cuáles causan crash.
- **Tipo:** script CLI (Dart)
- **Cómo se usa:** `dart run scripts/validador_resiliencia.dart --device`
- **Impacto para el usuario final:** QA automatizado de todos los estados de error del core de grabación. Elimina prueba manual de casos borde. Detecta MissingPluginException y errores silenciosos antes de release.
- **Prioridad:** Tarea 0 — implementar antes que resto del paso
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] SessionIntegrityException elimina referencias a clips faltantes sin perder proyecto
✅ [CODE] CameraService.initialize() captura CameraException + catch-all en todos los llamadores
✅ [CODE] RecordingManager.dispose() ejecuta cleanup completo (stop, dispose, temp) sin crash
✅ [CODE] ProGuard rules no contienen reglas muertas (ffmpegkit)
✅ [BACKEND] ExportService.saveToGallery() retorna ExportResult con error específico (file_not_found, permanently_denied, denied, exception)
✅ [FULLSTACK] UI muestra "Error de cámara" con botón "Ir a Configuración" cuando permiso denegado
✅ [FULLSTACK] UI muestra estado "Preparando cámara..." mientras CameraService.initialize() ejecuta
✅ [FULLSTACK] UI muestra "Espacio insuficiente" cuando RecordingManager detecta <500MB libres
✅ [FULLSTACK] UI de stitch muestra error + botón RETRY cuando MissingPluginException
✅ [DX] Script validador_resiliencia.dart existe y ejecuta sin errores
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| MissingPluginException no capturado en stitch | Alta | NativeStitcherService usa MethodChannel sin handler nativo Android/iOS | Ya tiene 3 fallbacks (native → ffmpeg → raw concat). Verificar que raw concat funciona con MP4s de cámara real. |
| debugPrint silencioso en Release | Media | Flutter no emite debugPrint en modo Release. Errores de disco, permiso o stitch invisibles en producción. | Reemplazar debugPrint con logger que persista a archivo (al menos en sesiones de grabación). |
| Assets branding sin optimizar | Baja | icon_source.png y splash_source.png sin tamaño verificado. Podrían sumar >1MB al APK. | Verificar tamaño con `ls -la` y optimizar manualmente. Flutter comprime en build pero imágenes grandes siguen siendo grandes. |
| Recovery path de cámara no probado en hardware real | Media | `CameraService` no tiene fallback a resolución menor. Si cámara no acepta `ResolutionPreset.high`, no hay degradación. | Agregar fallback: `high → medium → low` en initialize. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Validador de Resiliencia | `scripts/validador_resiliencia.dart` | `Future<void> main(List<String> args)` — `--device` flag para conectarse a dispositivo físico. Stages: space, camera, stitch, export. Reporte JSON por stage. | `scripts/validate_pipeline.dart` (etapas secuenciales + reporte) | DX | Media | 2h | Ninguna | → verificar: `dart run scripts/validador_resiliencia.dart --help` imprime ayuda sin error |
| 1 | Limpiar ProGuard rules muertas | `android/app/proguard-rules.pro` | Remover L9-12 (`com.arthurivanets.ffmpegkit.**`, `com.arthenica.ffmpegkit.**`, `-dontwarn`). Mantener Flutter wrapper y JNI. | — | CODE | Baja | 0.2h | Ninguna | → verificar: `flutter build apk --release` compila sin advertencias |
| 2 | Agregar fallback de resolución en CameraService.initialize() | `lib/features/recording/services/camera_service.dart` | `Future<void> initialize(...)` — si `_controller!.initialize()` falla, reintentar con `CameraConfig.resolutionLow` y loguear. Sin UI change. | CameraService L36-55 (try/catch existente) | CODE | Baja | 0.5h | Tarea 0 | → verificar: `flutter test` pasa + simular CameraException verifica fallback |
| 3 | Agregar UI de progreso para ExportService | `lib/features/recording/recording_end_page.dart` | Agregar estado `_exportProgress: double` en `_RecordingEndPageState`. Mostrar overlay con `CircularProgressIndicator` + texto "Guardando en galería..." durante `saveToGallery()`. | StitchProgressPage L46-97 (estado _isRetrying + indicador) | FULLSTACK | Media | 1.5h | Tareas 0, 2 | → verificar: tap "Exportar" muestra spinner hasta que retorna ExportResult |
| 4 | Reemplazar debugPrint con logger persistente en RecordingManager y ExportService | `lib/core/services/logger_service.dart` (nuevo) | `class LoggerService { static void log(String tag, String message, {Object? error, StackTrace? stack}) }` — escribe a archivo rotativo en `getApplicationDocumentsDirectory()/vrm_data/logs/app.log`. Solo para errores críticos. | `RecordingManager._saveSessionDataToDisk()` L224-239 (write asincrónico a disco) | CODE | Media | 1h | Ninguna | → verificar: forzar error → log creado en `vrm_data/logs/app.log` con timestamp |
| 5 | Agregar verifyIntegrity al inicio de RecordingSession | `lib/features/recording/services/recording_manager.dart` | Llamar `this.verifySessionIntegrity()` al inicio de `startRecording()`. Si falla, mostrar alerta en UI con fragmentos reseteados. | `verifyIntegrityStatic()` L328-364 existente | FULLSTACK | Baja | 0.5h | Tarea 0 | → verificar: borrar clip aprobado → UI muestra alerta con fragmentos afectados |

**Tiempo total estimado:** 5.7h

---

## 🔮 Roadmap (No implementar ahora)
- Integrar crash reporter (Sentry o Firebase Crashlytics) post-MVP
- ProGuard rules: agregar keep rules para MethodChannel handlers de stitch cuando se implementen nativamente
- CI/CD pipeline con `flutter analyze` y `flutter test` automático antes de release build
- Script de verificación de assets: `scripts/verify_assets.dart` — reporta tamaños de imagen, formatos no óptimos
