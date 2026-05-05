# 🏛️ Análisis Unificado — Paso 03: Estabilidad y Pulimento Físico
**Unificador:** Arquitecto de Sistemas Senior | **Fuente:** 4 análisis consolidados
**Fecha:** 2026-05-05 | **Fase:** mvp

> Basado en `proyecto-config.json`, código fuente real en `lib/`, y 4 análisis de agentes (speed, hy3, grok, ds).

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) | Notas |
|:---|:---:|:---:|:---:|:---:|:---:|:---|
| **speed** | ✅ (27) | 7 | ✅ VRM System Check | ✅ file:line evidencia | **4.8** | Más verificaciones. Cobertura completa. 2 detecciones ya resueltas en código actual (sqflite ya removida, ProGuard ya configurado). |
| **hy3** | ✅ (12) | 3 | ✅ vrm_data_scaffold | ❌ 1 falsa discrepancia | **2.5** | Superficial. Verificó `/vrm_data/` en raíz del proyecto (debe ser runtime path). Tarea "add ffmpeg_kit_flutter" contradice decisión arquitectónica documentada. |
| **grok** | ✅ (10) | 2 | ✅ Memory Leak Detector | ⚠️ 3 supuestos no verificados | **3.5** | Buen enfoque conceptual en memory profiling. Menos verificaciones concretas. Tareas vagas (Asset Optimization sin detalle). |
| **ds** | ✅ (17) | 5 | ✅ Validador de Resiliencia | ✅ file:line precisa | **4.5** | Detectó dead config en ProGuard que speed no vio. Mejor estructura de tareas (interfaz exacta, patrón, verificación inline). |

**Resumen:** speed (mejor cobertura) + ds (mejor precisión técnica) = base de la unificación. hy3 descartado donde contradice código. grok complementa en memory profiling.

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|:---|:---|---|:---:|:---|
| 1 | **CameraService.setFlashMode/setFocusMode/setExposureMode silencian errores** — solo `debugPrint`, sin feedback UI | speed | ✅ `camera_service.dart:20-55,65-78,90-103` | Remover try-catch silencioso. Propagar `CameraHardwareException` o callback que muestre `SnackBar` vía `VRMNotifications.showWarning`. |
| 2 | **Sin overlay "Guardando..." durante exportación** — `ExportService.saveToGallery()` sin callback de progreso | speed, ds, grok | ✅ `export_service.dart:25-59` | Agregar `Stream<double>` progreso + overlay full-screen `WidgetProgress` con texto en `RecordingEndPage`. |
| 3 | **`ffmpeg_kit_flutter` eliminado permanentemente** — pubspec L70: "has been removed". ProGuard rules preservan reglas muertas (L9-12). | hy3, grok, ds | ✅ `pubspec.yaml:70`, `proguard-rules.pro:9-12` | NO reintroducir. Remover reglas ProGuard muertas L9-12. Decisión arquitectónica confirmada en `phase-state.md`. |
| 4 | **ProGuard tiene reglas muertas de ffmpegkit** — `proguard-rules.pro` L9-12 preservan keep rules para librería eliminada | ds | ✅ `android/app/proguard-rules.pro:9-12` | Remover L9-12. `isMinifyEnabled=true` y `isShrinkResources=true` ya configurados correctamente en `build.gradle.kts:60-61`. |
| 5 | **Sin `didHaveMemoryPressure`** — ninguna página overridea este callback. Sin recovery ante presión de memoria. | speed | ✅ grep en `lib/features/recording/` | Agregar override en `RecordingPage`, limpiar temp, notificar usuario con `VRMNotifications.showWarning`. |
| 6 | **`debugPrint` como única observabilidad** — en Release mode no emite nada. Errores silenciosos en producción. | ds | ✅ `camera_service.dart`, `recording_manager.dart`, `export_service.dart` | Reemplazar con `LoggerService` que persiste a archivo rotativo en `vrm_data/logs/app.log`. |
| 7 | **Sin fallback de resolución en CameraService.initialize()** — si cámara rechaza `ResolutionPreset.high`, no hay degradación. | ds | ✅ `camera_service.dart:36-55` | Agregar reintento con `ResolutionPreset.medium` → `low` si `initialize()` falla con `CameraException`. |
| 8 | **Sin verificación de integridad al iniciar grabación** — `verifyIntegrityStatic()` existe pero no se llama en `startRecording()` | ds | ✅ `recording_manager.dart:328-364` | Llamar `verifySessionIntegrity()` al inicio de `startRecording()`. Mostrar alerta si hay clips faltantes. |
| 9 | **Sin notificación de fallback IA** — `ScriptFallbackService` genera localmente pero UI no informa al usuario | speed | ✅ `script_fallback_service.dart` | Mostrar `Banner` en página consumidora de `ScriptAnalysis` cuando `viability.summary` contenga "localmente" o "fallback". |

---

## 1️⃣ Resumen Ejecutivo

**Objetivo del paso:** Blindar la app contra fallos de grabación (try/catch + recovery paths visuales), optimizar performance física (ProGuard/minify), completar estados UX faltantes (overlay exportación, loading, errores hardware), y establecer observabilidad en producción (logger persistente).

**Correcciones críticas al plan original:**
- ⚠️ Plan Día 4-5 exige `ffmpeg_kit_flutter ^6.0.3` → Código real lo eliminó (problemas compilación nativa). Se implementa con MethodChannel + 3 fallbacks nativos existentes en `NativeStitcherService`. NO reintroducir.
- ⚠️ Plan Día 16-17 asume ProGuard no configurado → Realidad: `isMinifyEnabled=true`, `isShrinkResources=true`, `proguard-rules.pro` existe (pero con reglas muertas).
- ⚠️ Plan no menciona `sqflite` ni `battery_plus` removidas → Ya no están en `pubspec.yaml`. Confirmado.
- ⚠️ Plan Día 14-15 no cubre debugPrint silencioso en Release → Crítico para diagnóstico en producción.

**Decisión DX fusionada:** Se adopta **VRM Health Check** — fusión de VRM System Check (speed) + Validador de Resiliencia (ds) + Memory Leak Detector (grok) + vrm_data_scaffold (hy3). Un único CLI con subcomandos que cubre pre-flight checks, resilience validation, memory profiling y scaffolding.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path
1. Usuario abre app → Permisos OK → Dashboard carga proyectos desde `ProjectRepository`
2. Nuevo proyecto → ScriptStudio genera guion (IA o fallback templates)
3. `RecordingPage` → `CameraService.initialize()` con fallback resolución si es necesario
4. `RecordingManager.startRecording()` → verifica integridad sesión previa → chequea espacio libre (>500MB)
5. Usuario graba clips → `ClipStorageService.saveClip()` con fallback copy/writeAsBytes
6. `ClipReviewPage` → accept/reject con `VideoPlayerController.file()` real
7. `RecordingManager.startStitching()` → `NativeStitcherService` con 3 niveles de fallback
8. `StitchProgressPage` con progreso retry en error
9. `RecordingEndPage` → overlay "Guardando en galería..." con progreso → `ExportService.saveToGallery()`
10. Share sheet nativo (share_plus)

### Edge Cases MVP
- **Sin espacio**: `StorageFullException` → UI "Libera al menos 500MB"
- **Cámara no disponible**: `CameraHardwareException` → UI error + "Ir a Configuración"
- **Cámara rechaza resolución alta**: Fallback automático medium → low
- **Archivos faltantes en disco**: `SessionIntegrityException` → elimina referencias rotas + alerta usuario
- **Memory pressure**: Limpieza temp + notificación "Memoria baja — limpiando caché"
- **Stitch falla**: 3 fallbacks (native → ffmpeg → raw concat) + botón RETRY
- **MissingPluginException en stitch**: Ya capturado por cadena de fallbacks
- **Export falla en iOS 14+ limited access**: ExportResult con `permanently_denied` + UI explicativa
- **Error hardware silencioso (flash/focus/exposure)**: SnackBar con mensaje
- **debugPrint silencioso en Release**: LoggerService persiste a archivo

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

| # | Ruta real | Tipo | Descripción | Interfaces clave | Patrón a seguir |
|:---|:---|---|:---|:---|:---|
| 1 | `D:\Develop\Personal\vrm\scripts\vrm_health_check.dart` | **Creación** | CLI unificado con subcomandos: `check` (pre-flight sistema), `validate` (resiliencia recovery paths), `memory` (detección leaks), `scaffold` (crear estructura datos) | `Future<void> main(List<String> args)` — flags: `--device`, `--fix`, `--project-id`, `--help` | Scripts existentes en `D:\Develop\Personal\vrm\scripts\` |
| 2 | `android/app/proguard-rules.pro` | **Modificación** | Remover L9-12 (dead ffmpegkit rules). Mantener Flutter wrapper, JNI. | — | — |
| 3 | `lib/features/recording/services/camera_service.dart` | **Modificación** | En métodos `setFlashMode`, `setFocusMode`, `setExposureMode`: reemplazar try-catch silencioso con propagación de `CameraHardwareException`. En `initialize()`: agregar fallback resolución `high → medium → low`. | `Future<void> setFlashMode(FlashMode mode)`, `Future<void> initialize({CameraLensDirection? direction})` | Try/catch existente en `camera_service.dart:36-55` |
| 4 | `lib/features/recording/recording_page.dart` | **Modificación** | Capturar `CameraHardwareException` en `_applyHardwareSettings` y mostrar `VRMNotifications.showWarning`. Agregar `@override void didHaveMemoryPressure()`. | `Future<void> _applyHardwareSettings()`, `@override void didHaveMemoryPressure()` | `_showRecoveryDialog` L541-572, `didChangeAppLifecycleState` L271-327 |
| 5 | `lib/features/recording/recording_end_page.dart` | **Modificación** | Agregar estado `_exportProgress: double` + `_isSavingOverlay: bool`. Overlay full-screen con `WidgetProgress` durante `saveToGallery()`. | `bool _isSavingOverlay`, `double _exportProgress` | `StitchProgressPage` L46-97 |
| 6 | `lib/core/services/logger_service.dart` | **Creación** | Logger que escribe a archivo rotativo en `vrm_data/logs/app.log`. Solo errores críticos. Reemplazar `debugPrint` en `RecordingManager`, `CameraService`, `ExportService`. | `class LoggerService { static void log(String tag, String message, {Object? error, StackTrace? stack}) }` | `RecordingManager._saveSessionDataToDisk()` L224-239 |
| 7 | `lib/features/recording/services/recording_manager.dart` | **Modificación** | Llamar `verifySessionIntegrity()` al inicio de `startRecording()`. Reemplazar `debugPrint` con `LoggerService.log`. | `Future<SessionData> verifyIntegrityStatic(SessionData data)` ya existe L328 | Método existente `verifyIntegrityStatic()` |
| 8 | `lib/features/assistant/script_studio_page.dart` | **Modificación** | Agregar `Banner` cuando `analysis.viability.summary` contenga "localmente" o "fallback". | — | `VRMEmptyState` widget |
| 9 | `lib/features/recording/services/memory_monitor.dart` | **Creación** | Monitor de memoria para detección de leaks en sesiones largas. | `class MemoryMonitor { Future<void> startMonitoring(); Future<LeakReport> getReport(); }` | `CameraService` singleton pattern |
| 10 | `lib/core/services/export_service.dart` | **Modificación** | Agregar callback de progreso `Stream<double>`. Reemplazar `debugPrint` con `LoggerService.log`. | `Future<ExportResult> saveToGallery(String filePath, {void Function(double progress)? onProgress})` | — |
| 11 | `test/performance/memory_stress_instructions.md` | **Creación** | Documento con procedimiento para validación manual de 10 min grabación continua. | — | — |

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: VRM Health Check
- **Qué automatiza:** Diagnóstico pre-grabación (permisos, espacio, cámara, temp huérfanos) + validación de recovery paths (espacio insuficiente, cámara no disponible, archivos faltantes, stitch fallido) + detección de memory leaks + scaffolding de estructura de datos.
- **Tipo:** CLI script Dart con subcomandos
- **Ubicación:** `D:\Develop\Personal\vrm\scripts\vrm_health_check.dart`
- **Cómo se usa:**
  ```bash
  dart run scripts/vrm_health_check.dart check              # Pre-flight report
  dart run scripts/vrm_health_check.dart check --fix        # Clean temp if safe
  dart run scripts/vrm_health_check.dart validate --device  # Test recovery paths on device
  dart run scripts/vrm_health_check.dart memory             # Memory leak detection
  dart run scripts/vrm_health_check.dart scaffold --project-id <uuid>  # Create data structure
  ```
- **Impacto para el usuario final:** QA automatizado de todos los estados de error. Elimina prueba manual de casos borde. Reporte JSON por subcomando. Reduce tiempo de diagnóstico de 30min a 2s.
- **El implementador DEBE usarla** para completar las tareas 1..7 del paso (dogfooding obligatorio).
```

---

## 4️⃣ Decisiones Tecnológicas

1. **MethodChannel para stitch en vez de ffmpeg_kit_flutter:** `ffmpeg_kit_flutter` eliminado por problemas de compilación nativa iOS/Android. `NativeStitcherService` usa MethodChannel con 3 fallbacks (native → ffmpeg → raw concat). Decisión confirmada en `phase-state.md` y `pubspec.yaml:70`.
2. **LoggerService a archivo persistente en vez de debugPrint:** `debugPrint` es no-op en Release mode. Logger persiste a `vrm_data/logs/app.log` con rotación. Sigue patrón de escritura asincrónica de `RecordingManager._saveSessionDataToDisk()`.
3. **VRM Health Check unificado como CLI:** Fusión de 4 propuestas DX en 1 herramienta con subcomandos. Evita proliferación de scripts independientes. Sigue convención de `scripts/` del proyecto.
4. **Fallback de resolución en CameraService:** `ResolutionPreset.high → medium → low`. Sin intervención de usuario. Sigue patrón existente de 3 fallbacks en `NativeStitcherService`.
5. **MemoryMonitor como servicio singleton:** Sigue patrón existente de `CameraService`. Expone `LeakReport` para profiling en debug mode.
6. **ProGuard ya configurado, solo limpiar reglas muertas:** `isMinifyEnabled=true`, `isShrinkResources=true`, `proguard-rules.pro` existe. Solo remover reglas ffmpegkit (L9-12).

### Correcciones al plan
- ⚠️ El plan Día 4-5 dice instalar `ffmpeg_kit_flutter ^6.0.3` pero el código real lo eliminó. Se implementa con MethodChannel + fallbacks nativos.
- ⚠️ El plan Día 16-17 dice "Reducción del AppSize empaquetando con Proguard" asumiendo no configurado. Realidad: ya configurado con reglas muertas.
- ⚠️ El plan Día 14-15 no menciona observabilidad en Release. `debugPrint` no emite en Release → crítico para diagnóstico.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [DATA] SessionIntegrityException elimina referencias a clips faltantes sin perder proyecto
✅ [CODE] CameraService.initialize() fallback resolución high→medium→low si CameraException
✅ [CODE] CameraService.setFlashMode/setFocusMode/setExposureMode propagan errores a UI
✅ [CODE] RecordingManager.verifySessionIntegrity() llama al inicio de startRecording()
✅ [CODE] LoggerService loggea errores críticos a vrm_data/logs/app.log en Release
✅ [CODE] ProGuard rules sin reglas muertas (ffmpegkit removido)
✅ [BACKEND] ExportService.saveToGallery() con Stream<double> progreso
✅ [FULLSTACK] Overlay "Guardando en galería..." visible durante exportación
✅ [FULLSTACK] SnackBar al ocurrir error de hardware (flash/focus/exposure)
✅ [FULLSTACK] Banner visible cuando ScriptAnalysis usa fallback local
✅ [FULLSTACK] didHaveMemoryPressure() limpia temp y notifica usuario
✅ [FULLSTACK] Alerta de integridad al iniciar grabación si hay clips faltantes
✅ [DX] VRM Health Check ejecuta sin errores y cubre: check, validate, memory, scaffold
✅ [DX] Sin memory leaks detectables en 10 min grabación continua
```

**Funcionales:**
- [ ] Usuario ve progreso real durante exportación a galería
- [ ] Usuario ve notificación cuando modo hardware no soportado (flash, focus, exposure)
- [ ] Usuario ve banner cuando guion se generó localmente (fallback)
- [ ] Usuario ve alerta si hay clips faltantes al iniciar grabación
- [ ] Usuario ve "Memoria baja" si el SO presiona por recursos

**Técnicos:**
- [ ] ProGuard rules sin reglas de ffmpegkit (L9-12 removidas)
- [ ] `flutter build apk --release` compila sin advertencias
- [ ] LoggerService escribe archivo rotativo en `vrm_data/logs/app.log`
- [ ] MemoryMonitor genera LeakReport en debug mode
- [ ] `flutter test` pasa todos los tests existentes
- [ ] `flutter analyze` sin nuevos issues (actual: 37 lint issues pre-existentes)

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias | Verificación |
|:---:|---|:---:|:---:|:---:|---|
| 0 | **DX & Tooling:** VRM Health Check — CLI unificado (check, validate, memory, scaffold) | Media | 2.5h | Ninguna | `dart run scripts/vrm_health_check.dart --help` imprime subcomandos sin error |
| 1 | Limpiar ProGuard rules muertas (ffmpegkit L9-12) | Baja | 0.2h | Tarea 0 | `flutter build apk --release` compila sin advertencias |
| 2 | CameraService: propagar errores hardware a UI + fallback resolución initialize() | Media | 1.5h | Tarea 0 | Forzar error flash no soportado → SnackBar aparece. Simular CameraException → verifica fallback medium/low |
| 3 | Overlay "Guardando..." con progreso en RecordingEndPage + ExportService Stream | Media | 1.5h | Tarea 2 | Tap "Exportar" → overlay `WidgetProgress` visible hasta ExportResult |
| 4 | LoggerService persistente + reemplazar debugPrint en servicios críticos | Media | 1.5h | Tarea 3 | Forzar error → log creado en `vrm_data/logs/app.log` con timestamp |
| 5 | MemoryMonitor + didHaveMemoryPressure en RecordingPage | Media | 2h | Tarea 4 | Simular presión de memoria → logs cleanup + notificación UI |
| 6 | Banner fallback IA en ScriptStudio + verifyIntegrity al inicio de RecordingSession | Baja | 1h | Tarea 5 | Generar script vía fallback → banner visible. Borrar clip aprobado → alerta al iniciar grabación |
| 7 | Documento validación sin leaks + asset branding optimization | Baja | 1h | Tarea 6 | QA sigue instrucciones, confirma estabilidad en 10 min |
| | **TOTAL** | | **9.7h** | | |

> [!IMPORTANT]
> **Tarea 0 siempre = DX & Tooling.** Implementador DEBE ejecutarla primero y usar la herramienta resultante para el resto del paso (dogfooding obligatorio).

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|:---|:---:|:---|---|
| MissingPluginException no capturado en stitch (MethodChannel sin handler nativo) | Alta | NativeStitcherService usa MethodChannel sin impl Android/iOS | Ya tiene 3 fallbacks (native → ffmpeg → raw concat). Verificar raw concat con MP4s reales. |
| debugPrint silencioso en Release no reemplazado completamente | Media | LoggerService cubre servicios críticos pero puede quedar algún `print` suelto | Tarea 4 debe incluir grep de `print\(` y `debugPrint` residual. |
| Memory leaks no detectables en CI (requiere dispositivo físico) | Media | Leaks aparecen solo en sesiones largas con hardware real | Tarea 7 documenta procedimiento manual. MemoryMonitor ayuda en debug pero no es automático. |
| Frame rejection sin fallback suficiente | Baja | CameraService degrade medium→low puede no ser suficiente en hardware muy limitado | Aceptable para MVP. Post-MVP evaluar `ResolutionPreset.veryLow` o desactivar video. |
| Assets branding sin optimizar inflan APK | Baja | icon_source.png, splash_source.png sin tamaño verificado | Flutter comprime en build. Recomendar <500KB cada uno. Verificar con `ls -la`. |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|:---:|---|---|---|
| TP-1 | CameraService fallback resolución | Simular `CameraException` en `initialize()` con `ResolutionPreset.high` | Reintento con `medium`, luego `low`. Loggeado en LoggerService. Sin crash. |
| TP-2 | ExportService overlay progreso | Tap "Exportar" en RecordingEndPage | Overlay `WidgetProgress` visible. `CircularProgressIndicator` animando. Texto "Guardando video en galería...". |
| TP-3 | Memory pressure recovery | `didHaveMemoryPressure()` llamado (simulado vía test) | `ClipStorageService.cleanupTemp()` ejecutado. `VRMNotifications.showWarning` llamado con mensaje "Memoria baja — limpiando caché". |
| TP-4 | ProGuard dead rules cleanup | `flutter build apk --release` | Compila sin warnings. APK generado. `proguard-rules.pro` L9-12 ausentes. |
| TP-5 | LoggerService persistencia | Forzar `CameraHardwareException` en `setFlashMode` | Archivo `vrm_data/logs/app.log` creado con timestamp, tag, mensaje, stack trace. |
| TP-6 | VRM Health Check validate | `dart run scripts/vrm_health_check.dart validate --device` | Reporte JSON con stages space, camera, stitch, export. Cada stage: ✅ o ❌ con detalle. |
| TP-7 | verifyIntegrity al iniciar grabación | Borrar clip aprobado del FS, iniciar nueva grabación | UI muestra alerta "Se detectaron X fragmentos faltantes. ¿Resetear?" con opciones Sí/No. |

Comando para ejecutar tests: `flutter test`

---

*Documento generado por proceso de unificación v3.1 — 4 análisis consolidados, 9 discrepancias resueltas, 1 herramienta DX fusionada.*
