# 🧠 Análisis Técnico — Paso 03: Estabilidad y Performance
**Agente:** speed  
**Fecha:** 2026-05-05  
**Fuentes:** `DEVS/plan.md`, `DEVS/plan.json`, `proyecto-config.json`  
**Destino:** `DEVS/IN_PROGRESS/analisis-paso-03-speed.md`

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `proyecto-config.json` leído | Lectura directa | ✅ | `name: VRM Atomic Camera`, `frontend: lib/`, `commands.test: flutter test` |
| 2 | Estructura `lib/` | `ls lib/` | ✅ | `features/`, `core/`, `shared/` presentes |
| 3 | Excepciones base `VRMException` | Grep `abstract class VRMException` | ✅ | `lib/core/exceptions/vrm_exceptions.dart:2` |
| 4 | Excepciones específicas: `CameraHardwareException`, `StorageFullException`, `VideoProcessingException`, `SessionIntegrityException` | Grep clases | ✅ | vrm_exceptions.dart líneas 14-30 |
| 5 | Pipeline exceptions (`PluginException`, `ValidationException`, `PersistenceException`) | Grep | ✅ | `lib/core/exceptions/pipeline_exceptions.dart` completo |
| 6 | `CameraService` con try-catch en initialize/start/stop | Lectura archivo | ✅ | `camera_service.dart` líneas 20-55, 65-78, 90-103 |
| 7 | `CameraService` métodos setFlash/setFocus/setExposure capturan pero no propagan | Lectura | ⚠️ | Solo `debugPrint`; no hay feedback UI (discrepancia) |
| 8 | `RecordingManager` try-catch en startRecording/stopRecording/stopAndSavePartial/dispose | Lectura | ✅ | `recording_manager.dart` líneas 58-79, 98-161, 175-196, 302-323 |
| 9 | `RecordingManager.verifyIntegrityStatic` | Grep | ✅ | `recording_manager.dart:328-364` — elimina clips faltantes y lanza `SessionIntegrityException` |
| 10 | `ClipStorageService` fallback en `saveClip` (copy → writeAsBytes) | Lectura | ✅ | `clip_storage_service.dart:111-169` |
| 11 | `ClipStorageService` chequeo de espacio libre (`getFreeSpaceMB`, `hasFreeSpace`) | Lectura | ✅ | `clip_storage_service.dart:189-210` |
| 12 | `NativeStitcherService` cadena de fallbacks (native → ffmpeg → concat) | Lectura | ✅ | `native_stitcher_service.dart:45-78, 80-119, 121-166` |
| 13 | `StitchProgressPage`: UI de progreso + retry | Lectura | ✅ | `stitch_progress_page.dart:20-97` usa `WidgetProgress` |
| 14 | `RecordingPage`: diálogos de recovery para `StorageFullException` y `CameraHardwareException` | Lectura | ✅ | `recording_page.dart:500-523, 541-572` |
| 15 | `RecordingPage`: verificación de integridad al inicio y SnackBar | Lectura | ✅ | `recording_page.dart:177-204` |
| 16 | `ClipReviewPage`: spinner initialization + error screen | Lectura | ✅ | `clip_review_page.dart:68-96, 230-281` |
| 17 | `RecordingEndPage`: botónExport con `isLoading`,SnackBar,diálogos permiso | Lectura | ✅ | `recording_end_page.dart:28-29,96-143,154-175` |
| 18 | Widgets reutilizables: `VRMButton.isLoading`, `WidgetProgress` | Lectura | ✅ | `vrm_button.dart` (circular progress), `widget_progress.dart` (atomic animation) |
| 19 | `PermissionService` check/request permisos | Lectura | ✅ | `permission_service.dart:7-20` |
| 20 | `SessionData` / `ClipMetadata`: fromJson/toJson, `copyWith` | Lectura | ✅ | `session_data.dart`, `clip_metadata.dart` |
| 21 | Dependencia `sqflite` no usada en código | `grep -r "sqflite" lib/` | ❌ | Ninguna coincidencia; pubspec la marca `(UNUSED)` |
| 22 | Dependencia `battery_plus` ausente | `grep "battery_plus" pubspec.yaml` | ✅ | No está |
| 23 | Tests existentes: `error_handling_test.dart` cubre `PipelineException` | Lectura | ✅ | 76 líneas, 3 grupos de test |
| 24 | Tests: `pipeline_test.dart` cubre flujo básico | Lectura | ✅ | 78 líneas |
| 25 | Tests: `widget_test.dart` placeholder | Lectura | ✅ | 30 líneas, básico |
| 26 | Ausencia de manejo `didHaveMemoryPressure` | Grep | ❌ | No hay override en ninguna página |
| 27 | Configuración Proguard/R8 ausente | `ls android/app/` (no generado aún) | ⚠️ | Flutter genera al compilar; aún no configurado |

**Total verificados:** 27 ≥ umbral (>12).  
**Discrepancias críticas:** ítems 7, 21, 26, 27.

**Discrepancias encontradas:**

1. **`CameraService.setFlashMode/setFocusMode/setExposureMode` silencian errores**. No propagan excepción ni muestran UI. Plan exige "recovery path visual" → *Resolución*: Remover try-catch silencioso; dejar que excepción ascienda o bien callback que `_applyHardwareSettings` capture y muestre `SnackBar` vía `VRMNotifications.showWarning`.
2. **No hay overlay "Guardando..." completo**. Export flow muestra solo spinner en botón → *Resolución*: Implementar overlay `WidgetProgress` durante `saveToGallery()` en `RecordingEndPage._exportVideo`, similar a `StitchProgressPage`.
3. **Falta notificación de guión fallback**. `ScriptFallbackService` genera locally pero UI no informa → *Resolución*: En página donde se consume `ScriptAnalysis` (ScriptStudio o NewProject), mostrar `Banner` cuando `viability.summary` contenga "localmente" o "fallback".
4. **`sqflite` no removida** → *Resolución*: Eliminar línea de `pubspec.yaml` y confirmar `flutter pub get`.
5. **Sin manejo de memoria crítica** (`didHaveMemoryPressure`) → *Resolución*: Override en `RecordingPage`, limpiar temp y notificar usuario.
6. **Proguard/AppSize no configurado** → *Resolución*: Crear `android/app/proguard-rules.pro` y habilitar `minifyEnabled release` en `build.gradle`.
7. **`VoiceCommandService` no reporta errores** (`_handleStatus` solo log) → *Resolución*: Exponer `Stream<Exception>` y consumir en UI para SnackBar.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- **Almacenamiento**: Filesystem JSON en `getApplicationDocumentsDirectory()/vrm_data/projects/{projectId}/`.
  - `session_data.json` (estado actual)
  - `clips/` (videos crudos `chunk_X_take_Y.mp4`)
  - `final.mp4` (resultado stitching)
- **Modelos**:
  - `SessionData` (inmutable, `copyWith`, `toJson/fromJson`).
  - `ClipMetadata` (metadatos técnicos: resolución, fps, duración, tamaño).
  - `ClipStatus` enum: `pending`, `recorded`, `approved`, `rejected`.
- **Integridad referencial**: `RecordingManager.verifyIntegrityStatic` verifica existencia física de cada clip aprobado; elimina referencias rotas y notifica.
- **Índices/RLS**: No aplica (JSONFS, permisos OS).
- **Tipos de datos**: Todos nativos Dart (int, String, DateTime, bool) — sin incompatibilidades.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Clases/Servicios relevantes
- `CameraService` (lib/features/recording/services/camera_service.dart) — envoltura de `camera` plugin.
- `RecordingManager` — orquestación: espacio, grabación, guardado, stitching, dispose.
- `ClipStorageService` — FS: paths, `getNextTakeNumber`, `saveClip` (copy + fallback), `cleanupTemp`.
- `NativeStitcherService` — stitching nativo/ffmpeg/concat con progreso.
- `ExportService` — guardado en galería (`photo_manager`) y share (`share_plus`).
- `ScriptFallbackService` — templates locales.

### Patrones detectados
- **Service layer**: Singletons con factory constructor.
- **Exception hierarchy**: `VRMException` base; `PipelineException` para IA.
- **State**: `SessionData` inmutable; `copyWith`.
- **Callbacks de progreso**: `StitcherProgress`, `onProgress`.
- **UI**: `StatefulWidget` con `setState`; widgets reutilizables (`VRMButton`, `WidgetProgress`, `VRMEmptyState`).

### Calidad & modularidad
- Separación clara: UI (pages) → servicios → modelos.
- `recording_page.dart` ~2000 líneas — monolítico pero funcional. Refactor no crítico para Paso 03.
- Imports consistentes: package imports absolutos (`package:vrm_app/...`).

### Cobertura de errores
- Amplia: try-catch en servicios críticos.  
- **Gaps**: 
  - Métodos de ajuste hardware (`setFlashMode`, etc.) silencian errores — sin feedback.
  - `VoiceCommandService._handleStatus` solo loguea.
  - No `didHaveMemoryPressure` → sin recovery ante memory pressure.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- No backend server. Aplicación Flutter pura.
- APIs locales: ninguna (invocaciones nativas via MethodChannel).
- Middleware: no aplica.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end
```
Idea → ScriptAnalysis (IA/fallback) → RecordingPage
  → Camera init → Record (XFile) → saveClip (FS)
  → ClipReviewPage (VideoPlayer)
  → Accept → RecordingManager.startStitching
  → StitchProgressPage → NativeStitcherService
  → final.mp4 → RecordingEndPage
  → ExportService.saveToGallery → share_plus
```

### Coherencia
- Cada capa respeta contratos: ClipMetadata → saveClip → approvedClips (paths) → stitching → export.
- No gaps arquitectónicos críticos.

### Gaps de UX
1. **Sin pantalla full "Guardando..."** durante export → usuario no ve progreso.
2. **No notificación de fallback IA** → confusión sobre origen del guion.
3. **Errores de hardware** no mostrados → usuario no sabe por qué no cambia modo.
4. **Memory pressure** no manejado → posible crash.

### DX & Tooling propuesta

#### Herramienta: **VRM System Check** (CLI + Settings)
- **Qué automatiza**: Chequeo pre-grabación de permisos, espacio libre (>500MB), disponibilidad de cámara, archivos temporales huérfanos, integridad JSON de sesión. Reduce tiempo de diagnóstico manual.
- **Tipo**: Script Dart (`scripts/vrm_system_check.dart`), invocable desde terminal o menú Ajustes (modo debug).
- **Cómo se usa**:  
  ```bash
  dart run scripts/vrm_system_check.dart        # solo reporte
  dart run scripts/vrm_system_check.dart --fix  # limpia temp si es seguro
  ```
- **Impacto**: Usuario/desarrollador ve reporte inmediato; puede limpiar caché o liberar espacio sin perder datos.
- **Prioridad**: Tarea 0 — implementar antes que resto de Paso 03 (valida entorno).

---

## 5️⃣ Criterios de Aceptación

| Criterio | Estado | Notas |
|----------|--------|-------|
| ✅ [DATA] Tablas/estructura `SessionData` y `ClipMetadata` existen con columnas correctas | ✅ | models/session_data.dart, clip_metadata.dart |
| ✅ [CODE] Try/catch en todos los puntos de fallo de cámara con recovery path visual | ❌ (parcial) | Faltan ajustes hardware feedback y memory pressure |
| ✅ [BACKEND] (N/A) | — | — |
| ✅ [FULLSTACK] Flujo completo Idea→Script→Grabar→Revisar→Stitch→Exportar | ✅ | Funcional según código |
| ✅ [DX] Herramienta `vrm_system_check.dart` ejecuta sin errores y reduce chequeo manual | pendiente | Tarea 0 |
| ✅ [DX] Pantallas de Guardando... implementadas (overlay durante guardado) | pendiente | Tarea 3 |
| ✅ [DX] Spinners ya existen (`VRMButton`, `WidgetProgress`) | ✅ | vrm_button.dart, widget_progress.dart |
| ✅ [DX] Notificaciones de guión faltante implementadas | pendiente | Tarea 4 (fallback script) |
| ✅ [DX] Dependencias no utilizadas removidas | pendiente | Tarea 1 (sqflite) |
| ❌ [DX] AppSize optimizado (Proguard/asset trimming) | pendiente | Tarea 6 |
| ❌ [DX] Sin memory leaks detectables en 10 min grabación continua | pendiente | Tarea 5 + validación manual (Tarea 7) |

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| Fallo de cámara en Android 13+ por permisos | Alta | Fragmentación OS, cambios runtime permissions | Probar en hardware real temprano; recovery dialog ya presente |
| Stitching nativo ausente (MissingPluginException) | Media | Native handler no instalado en emulador | Fallback ffmpeg/direct concat ya implementado; verificar en device |
| Memory leaks en grabación larga (10 min+) | Alta | Acumulación de controladores, buffers sin liberar | Implementar `didHaveMemoryPressure`, limpieza temp periódica, prueba estrés |
| APK grande por falta de Proguard/shrinker | Media | Sin configuración de minificación | Habilitar Proguard/R8 (Tarea 6) |
| Notificación fallback IA no visible → UX confusa | Baja | Falta banner/ SnackBar | Tarea 4: Banner en ScriptStudioPage |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta / Cambios | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|-------|-----------|--------------------------|-----------------|-------|-------------|-------------|--------------|--------------|
| 0 | DX: VRM System Check CLI | `scripts/vrm_system_check.dart` | `Future<Map<String, dynamic>> checkSystem({bool fix = false})` → retorna permisos, espacio, cámara, temp size | — | DX | Media | 2h | Ninguna | `dart run scripts/vrm_system_check.dart` ok; salida JSON |
| 1 | Remover `sqflite` no utilizado | `pubspec.yaml` | Eliminar línea `sqflite: ^2.3.3+1 (UNUSED)` | — | CODE | Baja | 0.2h | Tarea 0 | `flutter pub get` sin warnings; `grep -r "sqflite" lib/` vacío |
| 2 | Mostrar errores de hardware en UI | `lib/features/recording/recording_page.dart` | En `_applyHardwareSettings`, capturar `CameraHardwareException` y llamar `VRMNotifications.showWarning(context, e.message)` | Según `_showRecoveryDialog` (líneas 541-572) | CODE | Media | 1h | Tarea 1 | Forzar error (ej: flash no soportado) → SnackBar aparece |
| 3 | Overlay "Guardando..." en exportación | `lib/features/recording/recording_end_page.dart` | Añadir `bool _isSavingOverlay`; durante `_exportVideo`, mostrar `WidgetProgress` full-screen con texto "Guardando video en galería..." | Seguir `StitchProgressPage` (líneas 20-97) | FULLSTACK | Media | 1.5h | Tarea 2 | Al pulsar Export, overlay visible hasta finish save |
| 4 | Notificar uso de fallback IA | `lib/features/assistant/script_studio_page.dart` (o NewProject page donde se recibe `ScriptAnalysis`) | Insertar `Banner` si `analysis.viability.summary.toLowerCase().contains('localmente')` | Reutilizar widget `Banner` de Flutter; estilo similar a `VRMEmptyState` | FULLSTACK | Baja | 0.5h | Tarea 3 | Generar script vía fallback → banner superior visible |
| 5 | Manejo de memory pressure | `lib/features/recording/recording_page.dart` | añadir `@override void didHaveMemoryPressure() { cleanup(); VRMNotifications.showWarning(context, "Memoria baja — limpiando caché"); }` | Seguir patrón `didChangeAppLifecycleState` (271-327) | CODE | Media | 1h | Tarea 4 | Simular presión (no API directa) → verificar logs y limpieza temp |
| 6 | Optimización AppSize (Proguard/R8) | `android/app/proguard-rules.pro`, `android/app/build.gradle` | Crear rules básicas; habilitar `minifyEnabled true` y `shrinkResources true` en release | Doc: https://docs.flutter.dev/perf/shrink-code | CODE | Media | 2h | Tarea 5 | `flutter build apk --release` → tamaño reducido (~30%) |
| 7 | Validación sin leaks 10 min (instrucciones) | `test/performance/memory_stress_instructions.md` | Documentar procedimiento: grabar 10 min continuo, monitorear DevTools, sin crashes | — | TEST | Baja | 0.5h | Tarea 6 | QA sigue pasos, confirma estabilidad |

**Tiempo total estimado:** 7.7 horas (≈ 2 días a 4h/día).

---

## 8️⃣ Roadmap (NO implementar ahora)

- Añadir paquete `memory_leak_detector` para detección automática en debug mode.
- Auto-cleanup de clips antiguos (>30 días) en `ClipStorageService`.
- Mostrar métricas de performance en Settings (tamaño proyecto, número de clips).
- Evaluar compresión HEVC para reducir tamaño de videos.
- Integrar `flutter_ffmpeg` como reemplazo más robusto (ya hay fallbacks nativos).

---

**Cumplimiento de Reglas de Oro:**  
✅ Análisis accionable, no genérico  
✅ Todo verificado contra código  
✅ Tareas atómicas (1 artefacto/tarea)  
✅ Interfaz exacta por tarea  
✅ Patrón de referencia explícito  
✅ Verificación inline por tarea  
✅ ≥1 herramienta DX propuesta  
✅ Estimación de tiempo incluida  

---