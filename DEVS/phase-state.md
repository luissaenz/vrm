# 🗺️ Phase State: mvp

> Generado: 2026-05-05 vía 6_CONTEXTO.md
> Actualizado: 2026-05-09 vía 6_CONTEXTO.md (Post-Paso 15 — Vrm-health-check-resiliencia-archivos)

---

## 1. Resumen de Fase

**Fase:** mvp — Publicación del MVP en stores (3-5 semanas estimadas)

**Objetivo:** Que el usuario complete el flujo completo: Idea → Guion → Grabar → Revisar → Unir → Exportar. Persistencia local offline, fallback IA offline sin backend, y preparación para publicación en App Store y Google Play.

**Pasos en orden:**
| # | Paso | Status |
|---|------|--------|
| 01 | Core de Grabación | 🟡 inherited (features exist via step 02/03, never formalized) |
| 02 | Interfaz Reactiva y Refinamiento Local | ✅ completed |
| 03 | Estabilidad y Pulimento Físico | ✅ completed |
| 04 | Puerta de Tiendas y Valla Legal | ✅ completed |
| 05 | Correcciones y Validación | ✅ completed |
| 06 | MaterialBanner-notificacion-fallback-IA | ✅ completed |
| 07 | Metricas-Reales-Sesion-RecordingEndPage | ✅ completed |
| 08 | Migrar-debugPrint-residual-LoggerService | ✅ completed |
| 09 | vrm-health-check-fix-real | ✅ completed |
| 10 | Adaptive-icons-Android-13 | ✅ completed |
| 11 | Contexto-y-Actualizacion-Estado | ✅ completed |
| 12 | Screenshots-store-ready | ✅ completed |
| 13 | Mejorar-debugprint-scanner-kdebugmode | ✅ completed |
| 14 | Migracion-masiva-debugprint-residuales | ✅ completed |
| 15 | Vrm-health-check-resiliencia-archivos | ✅ completed |

**Dependencias entre pasos:**
- 01 ← 02 ← 03 ← 04 ← 05 ← 06 ← 07 ← 08 ← 09 ← 10 ← 11 ← 12 ← 13 ← 14 ← 15 (secuencial)

---

## 2. Estado Actual del Proyecto

### ✅ Implementado y funcional (verificado contra código fuente)

| Componente | Archivo(s) Clave | Evidencia |
|---|---|---|
| **F1-F2 Onboarding** | `lib/features/onboarding/` | Flujo 3-step completo. Persiste identidad/config en SharedPreferences. Redirige a dashboard al finalizar. |
| **F6-F7 Teleprompter** | `lib/features/recording/widgets/telepronter.dart` (L261) | Auto-scroll con Timer.periodic, emphasis en negrita+ámbar, pausas con icono, palabras leídas a 30% opacidad. 3 sliders configurables (fontSize 20-30, speed 50-300 WPM, brightness). |
| **F8 Grabación de Clips** | `lib/features/recording/services/camera_service.dart` (L169), `recording_manager.dart` (L375), `clip_storage_service.dart` (L240) | REAL: `CameraService.startRecording()` → `_controller!.startVideoRecording()` → `XFile` → `ClipStorageService.saveClip()` copia a `vrm_data/projects/{id}/clips/chunk_N_take_M.mp4`. Verifica espacio libre (>500MB). Maneja lifecycle (background/crash vía `stopAndSavePartial()`). |
| **F8 Control Overlay** | `lib/features/recording/recording_page.dart` (L1279-1625) | Página 1: GRILLA, TELEPRONTER, CALLE, FANTASMA, LUZ, ESPEJO. Página 2: ENFOQUE, MONITOR, VOZ. Todos conectados a `setState()` + `CameraService`. |
| **F9 Revisión Clips** | `lib/features/recording/clip_review_page.dart` (L323) | REAL: `VideoPlayerController.file(File(clipPath))` con auto-play, loop, muted. Auto-accept 3s con barra de progreso. Accept → avanza fragmento. Reject → elimina archivo. |
| **F12 Dashboard** | `lib/features/dashboard/dashboard_page.dart` (L526) | REAL: Carga proyectos desde `ProjectRepository.listProjects()` vía FutureBuilder. Muestra hasta 5 tarjetas con progreso desde session_data. Navegación inferior a 4 secciones. |
| **Persistencia Local** | `lib/core/data/project_repository.dart` (L187), `lib/core/models/project_state.dart` | JSON filesystem: `vrm_data/projects/{id}/project.json` + `session_data.json` + `clips/`. CRUD completo, búsqueda por topic, conteo. 4 JSON schemas de validación en `lib/core/schemas/`. |
| **Preparación (TTS + Voz)** | `lib/features/recording/preparation_page.dart` (L1092) | TTS-based reading con highlight, voice-controlled decision con countdown, animación sound wave. |
| **Director's Card** | `lib/features/recording/directors_card_page.dart` (L540) | Vista detalle de segmentos con emphasis/pauses. Navegación entre segmentos. |
| **Pipeline Architecture** | `lib/core/pipeline/` | `VRMPipeline.execute(params)` con 3 stages (fetchIdea → process → enhance). `PipelineFactory.createDefaultPipeline()` y `createBackendPipeline()`. Validación con `SchemaValidator`. |
| **Exception Hierarchy** | `lib/core/exceptions/` | `CameraHardwareException`, `PersistenceException`, `PluginException` con metadata. Catch en todos los services. |
| **LoggerService persistente** | `lib/core/services/logger_service.dart` (L53) | Escribe errores críticos a `{getApplicationDocumentsDirectory()}/vrm_data/logs/app.log`. Rotación automática a 512KB. Singleton. Usado en CameraService, RecordingManager, ExportService. |
| **CameraService fallback resolución** | `lib/features/recording/services/camera_service.dart` (L16-20, L44-61) | Fallback automático `high→medium→low` en initialize() si CameraException. Loggea via LoggerService. |
| **CameraService propagación errores hardware** | `lib/features/recording/services/camera_service.dart` (L143-184) | `setFlashMode/setFocusMode/setExposureMode` lanzan `CameraHardwareException` en vez de try-catch silencioso. UI captura y muestra SnackBar. |
| **ExportService progreso Stream** | `lib/core/services/export_service.dart` (L19-26) | `StreamController<double>.broadcast()` con `_emitProgress()`. Progreso 0.0→1.0. Consumido por `RecordingEndPage`. |
| **RecordingEndPage overlay exportación** | `lib/features/recording/recording_end_page.dart` (L202-210) | `_isSavingOverlay` + `WidgetProgress` con título "Guardando en galería..." y `CircularProgressIndicator`. |
| **RecordingEndPage metrics reales** | `lib/features/recording/recording_end_page.dart` (L37-56) | `_durationMinutes`, `_totalTakes`, `_progress` calculados desde SessionData. 0 valores hardcodeados. Progress circle refleja `chunksRecorded / totalChunks`. |
| **RecordingPage pasa finalVideoPath** | `lib/features/recording/recording_page.dart` (L826) | `RecordingEndPage(sessionData: _sessionData, finalVideoPath: _sessionData?.finalVideoPath)` — sesion completa navega con video path. |
| **Stitch→End con sessionData** | `lib/features/recording/pages/stitch_progress_page.dart` (L10, L91, L134) | `sessionData` como param del widget + pasado en route arguments. Sin perdida de datos post-stitch. |
| **Validador metricas sesion** | `scripts/validador_metrics_session.dart` (173L) | CLI con `check --project-id <uuid> [--progress-only]` y `demo`. Detecta hardcodeo de duracion/takes/progreso en session_data.json. |
| **RecordingPage didHaveMemoryPressure** | `lib/features/recording/recording_page.dart` (L283-290) | Override `didHaveMemoryPressure()` → `ClipStorageService.cleanupTemp()` + `VRMNotifications.showWarning('Memoria baja — limpiando caché')`. 0 debugPrint en archivo — todos migrados a LoggerService.log(). |
| **MemoryMonitor singleton** | `lib/features/recording/services/memory_monitor.dart` (L105) | Timer periódico (30s). Genera `LeakReport` con warnings de leak. Patrón singleton. Integrado con LoggerService. |
| **SessionIntegrityException recovery** | `lib/features/recording/services/recording_manager.dart` (L330-366) | `verifyIntegrityStatic()` remueve referencias a clips faltantes sin perder proyecto. Datos corregidos pasados en `originalError`. |
| **ScriptStudio fallback notification** | `lib/features/assistant/script_studio_page.dart` (L337-363) | MaterialBanner sticky naranja con dismiss manual cuando `viability.summary` contiene "localmente" o "fallback". |
| **ProGuard limpio** | `android/app/proguard-rules.pro` (L1-12) | Reglas ffmpegkit muertas removidas (L9-12). Solo Flutter wrapper + JNI. |
| **Integridad al iniciar grabación** | `lib/features/recording/services/recording_manager.dart` (L60) | `verifySessionIntegrity()` llamado al inicio de `startRecording()`. Alerta si clips faltantes. |
| **SessionIntegrityException handlers (3 métodos)** | `lib/features/recording/recording_page.dart` (L541, L634, L683) | `on SessionIntegrityException catch` capturado en `_startActualRecording()`, `_stopRecording()`, `_applyHardwareSettings()` — todos antes de catch genérico. Reset idle + sin duplicar SnackBar. |
| **VRM Health Check --dry-run + --fix real + resiliencia** | `scripts/vrm_health_check.dart` (L63-83, L189-217, L219-328) | Flag `--dry-run` previsualiza cleanup sin modificar archivos. `_fixProguardDeadRules()` elimina reglas ffmpegkit muertas (antes solo warning). `_runFixCleanup({bool dryRun})` con rama dry-run completa. **Paso 15:** 3 `delete()` envueltos en try/catch individual + `failedFiles` lista + resumen `⚠️ ARCHIVOS NO ELIMINADOS`. No aborta con archivos bloqueados. |
| **Health Check Resilience Test** | `scripts/health_check_resilience_test.dart` (234L) | DX CLI: simula archivo read-only (`attrib +R`) en `vrm_data/tmp/` real, ejecuta `check --fix`, verifica output contiene `⚠️ No se pudo eliminar...locked_temp.mp4` + `⚠️ ARCHIVOS NO ELIMINADOS`. 5 tests. Cleanup automático con `attrib -R` + delete. Reduce verificación manual de resiliencia a ~5s. |
| **Store Prep CLI unificado** | `scripts/store_prep_cli.dart` (L703) | CLI con 5 subcomandos: check, keystore, assets, privacy, screenshots. Sigue patron `vrm_health_check.dart`. 11 checks (agregado check [9] adaptive icons). Detecta keystore faltante, passwords default, placeholders, permisos, gitignore. Valida resolución screenshots via PNG IHDR header. |
| **PRIVACY_POLICY.md sin placeholders** | `PRIVACY_POLICY.md` (raíz), `docs/PRIVACY_POLICY.md` | Root reemplazado con version docs/. 0 placeholders. Email real: ludens.vrm@gmail.com. Fecha: April 18, 2026. |
| **Keystore generado** | `android/vrm-release-key.jks` (2760 bytes), `android/key.properties` | RSA 2048, alias vrm_upload_key, validez 10000d. Passwords randomizadas (no default). |
| **Settings enlace Privacy Policy** | `lib/features/settings/settings_page.dart` (L8-9, L413-424) | `_privacyPolicyUrl` apunta a raw.githubusercontent.com/luissaenz/vrm/main/PRIVACY_POLICY.md → HTTP 200. `_openPrivacyPolicy()` con try/catch + SnackBar. |
| **key.properties passwords randomizadas** | `android/key.properties` (L1-2) | `vrm_store_2kh`, `vrm_key_2kh`. No default. Verificado por store_prep_cli.dart check. |
| **Screenshots store-ready** | `assets/store/screenshots/step{1-5}.png` | 5 PNGs reales 1080x2400 (Xiaomi 2201117TL). Headers `89 50 4E 47` verificados. No JPEG disguised. Nombres `step1.png..step5.png`. Legacy `assets/images/screenshots/` eliminado. Capturadas via `capture_store_screenshots.dart` con dogfooding. Validado por `store_prep_cli.dart check` (11/11). |
| **Capture Store Screenshots DX tool** | `scripts/capture_store_screenshots.dart` (247L) | CLI interactivo ADB: captura secuencial 5 screenshots en dispositivo Android. Flags: `--device <id>`, `--clean`, `--help`. Valida PNG header + dimensiones + file size post-captura. Reduce ~30min manual a ~5min. |
| **Shared PNG utils** | `scripts/utils.dart` (28L) | `getPngDimensions()` + `validatePngHeader()` compartidos entre `capture_store_screenshots.dart` y `store_prep_cli.dart`. Elimina duplicacion de PNG parser. |
| **DebugPrint detector** | `scripts/debugprint_detector.dart` (164L) | API pública con 7 funciones: `isInsideDebugModeBlock` (orquestador), `isSameLineKDebugModeGuard`, `isInsideAssert`, `isTernaryKDebugModeGuard`, `isAdjacentKDebugModeGuard`, `isInsideBracedDebugModeBlock`, `stripStringsAndComments`. Cross-file usable por scanner y tests. |
| **DebugPrint scanner mejorado** | `scripts/debugprint_scanner.dart` (328L) | Refactor: extrae lógica a `debugprint_detector.dart`. 4 wrappers `_` privados (`_isInsideDebugModeBlock`, `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock`) según spec FINAL. 5 discrepancias D1-D5 resueltas: same-line, adyacente, assert, ternario, braces en strings/comentarios. 88 archivos escaneados, 7 residuales encontrados. |
| **DebugPrint scanner test** | `test/debugprint_scanner_test.dart` | 31 tests unitarios (8 grupos) cubriendo TP-1 a TP-8 + stripStringsAndComments + orquestador. 52/52 tests totales pasan. |
| **Paso 14: Migración 7 debugPrint residuales → LoggerService** | `vrm_pipeline.dart`, `stitcher_plugin.dart`, `schema_validator.dart`, `clip_storage_service.dart`, `social_account_manager.dart` | 7 debugPrint multilínea migrados a LoggerService.log() en 5 archivos. Tags PascalCase según spec: VRMPipeline, StitcherPlugin, SchemaValidator, ClipStorageService, SocialAccountManager. 0 debugPrint residuales confirmados por scanner. Imports `flutter/foundation.dart` unused removidos de los 5 archivos. Import LoggerService agregado en stitcher_plugin.dart. `memory_monitor.dart:62` y `logger_service.dart:48` conservan debugPrint intencional. |
| **DebugPrint migration verifier** | `scripts/debugprint_migration_verifier.dart` | CLI post-migración: `dart run scripts/debugprint_migration_verifier.dart` ejecuta scanner + valida 0 unused imports `flutter/foundation.dart` + `flutter analyze` en archivos meta. 3/3 checks pasan. Reduce verificación manual de ~10min a ~2s. |
| **Play Store Data Safety documentado** | `DEVS/play_store_data_safety.md` | Checklist de respuestas para formulario Data Safety de Play Console. |
| **.gitignore secreto** | `.gitignore` | Cubre `*.jks`, `*.keystore`, `/android/key.properties`. |
| **Adaptive icons Android 13+** | `pubspec.yaml:133`, `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml` | `adaptive_icon_background: "#000000"` (corregido de `#FFFFFF`). XML generado con `<adaptive-icon>` → background `#000000` + foreground `icon_source.png`. Icono legacy intacto en mipmap-*/launcher_icon.png. store_prep_cli.dart check [9] verifica existencia post-generación. |

### ⚠️ Parcialmente implementado

| Componente | Archivo(s) | Qué falta |
|---|---|---|
| **F3 Idea Lab** | `script_studio_page.dart`, `script_fallback_service.dart` | Script generation usa 6 templates hardcodeados en español con `{{idea}}` placeholder. No hay IA real conectada. ✅ Notificación fallback implementada (SnackBar informativo cuando se usa generación local). |
| **F4-F5 Generación IA** | `new_project_page.dart` (L68-226), `backend_script_plugin.dart` | `NewProjectPage` tiene API call comentado (L68-101), usa mock inline de 200 líneas con 8 segmentos hardcodeados. `BackendScriptPlugin` apunta a `localhost:8000` sin servidor. |
| **F11 Exportación** | `lib/core/services/export_service.dart` (L125), `recording_end_page.dart` | ✅ ExportService con `Stream<double>` progreso. ✅ Overlay "Guardando en galería..." con `WidgetProgress`. ✅ Metrics reales vía SessionData (duración desde startedAt/lastUpdatedAt, takes desde takesPerChunk, progreso desde chunksRecorded/totalChunks). NO probado en dispositivo real. Permisos (`Permission.photos`) pueden tener edge cases en iOS 14+ / Android 13+. |
| **Tests** | `test/repository_test.dart` (L156), `pipeline_test.dart` (L78), `error_handling_test.dart` (L76) | 3 tests reales: ProjectRepository (save/load/list/delete/search/count con FakePathProvider), Pipeline factory/execution/validation, PipelineException hierarchy. `widget_test.dart` reparado (renderiza VRMApp sin crash, 3 escenarios: onboarding, dashboard, themes). `social_media_test.dart` usa mocks. 21/21 tests pasan. |

### 🟡 No existe aún / stubbed

| Componente | Archivo(s) | Problema |
|---|---|---|
| **F10 Auto-Stitch** | `lib/core/services/native_stitcher_service.dart` (L52), `android/.../MainActivity.kt` (L52), `ios/Runner/AppDelegate.swift` (L35), `lib/core/plugins/default/stitcher_plugin.dart` (L64), `lib/features/recording/pages/stitch_progress_page.dart` (L128) | ✅ IMPLEMENTADO: `MethodChannel('com.vrm.vrm_app/stitcher')` tiene handlers nativos en AMBAS plataformas. Android: `mergeVideos()` via `MediaMuxer` (L52-146). iOS: `mergeVideos()` via `AVMutableComposition` + `AVAssetExportSession` (L35-81). Dart side: `NativeStitcherService.stitchVideos()` invoca MethodChannel + fallback `MissingPluginException`. `pubspec.yaml` L71: `# ffmpeg_kit_flutter has been removed`. ⚠️ No probado end-to-end en dispositivo real. |
| **Backend IA** | `backend/` (FastAPI), `lib/core/api_service.dart` | Backend FastAPI existe en código (POST `/prompt/{category}/{name}` con OpenAI/Anthropic/Gemini) pero requiere servidor corriendo en `localhost:8000`. Ningún servidor desplegado. |
| **Privacy Policy hosteada via GitHub Pages** | `settings_page.dart:8-9` | URL apunta a raw.githubusercontent.com (funciona). GitHub Pages no habilitado — post-MVP. |
| **Mi Cuenta** | `account_profile_page.dart` | ✅ IMPLEMENTADO: DeviceInfoService con device_info_plus. Muestra modelo real, memberSince desde primer launch. |
| **Settings** | `settings_page.dart` | ✅ IMPLEMENTADO: SettingsService conecta a SharedPreferences. Theme switcher funciona (VRMApp carga desde prefs). Teleprompter sliders persisten prefs. Cloud sync toggle funciona. |
| **Perfil Influencer** | `influencer_profile_page.dart` (L631) | ✅ IMPLEMENTADO: _saveProfile() persiste en SharedPreferences al hacer finalize. |

### ❌ Discrepancias plan vs código (Paso 10)

| # | Plan dice | Código real | Impacto | Estado |
|---|---|---|---|---|
| D1 | Agregar `adaptive_icon_background: "#FFFFFF"` y `adaptive_icon_foreground` | YA EXISTEN en pubspec.yaml L133-134 desde 2026-05-05 | Plan desactualizado. Tarea real = regenerar iconos + corregir color. | ✅ Corregido (color `#000000`) |
| D2 | `mipmap-anydpi-v26/` existe | NO existía pre-ejecución. `flutter pub run flutter_launcher_icons` lo generó. | Icono Android 13+ se veía cuadrado/legacy sin forma adaptable. | ✅ Resuelto |
| D3 | `adaptive_icon_background: "#FFFFFF"` es correcto | `icon_source.png` tiene fondo negro integrado. Background blanco → anillo blanco visible. | Opus detectó. 3 agentes (ring, step, ds) no lo vieron. | ✅ Corregido a `#000000` |

### ❌ Discrepancias plan vs código (generales)

| # | Plan dice | Código real | Impacto | Estado |
|---|---|---|---|---|
| D1 | F8 Grabación: 🔴 50% NO guarda MP4 | ✅ COMPLETE: Escribe MP4 reales con space check + lifecycle | Plan desactualizado ~50% | ✅ Resuelto |
| D2 | F9 Revisión: 🔴 40% sin clips reales | ✅ COMPLETE: `VideoPlayerController.file()` con paths reales | Plan desactualizado ~60% | ✅ Resuelto |
| D3 | F8 Overlay: ⚠️ 50% botones desconectados | ✅ COMPLETE: 9 botones conectados a CameraService | Plan desactualizado ~50% | ✅ Resuelto |
| D4 | Mi Cuenta: ✅ 80% faltan acciones | 🟡 MOCK: Solo UI shells, toggles no-op | Plan sobreestimado ~65% | ✅ Resuelto (Paso 2) |
| D5 | F12 Dashboard: ✅ 90% falta reemplazar mocks | ✅ COMPLETE: Proyectos reales desde ProjectRepository | Plan desactualizado ~10% | ✅ Resuelto |
| D6 | Dependencia ffmpeg_kit_flutter: ^6.0.3 | Eliminado (`pubspec.yaml` L71). NativeStitcherService usa MethodChannel CON handlers nativos reales | Arquitectura cambió a stitch nativo. Android: MediaMuxer (MainActivity.kt:52-146). iOS: AVComposition (AppDelegate.swift:35-81). ✅ Resuelto |
| D7 | Dependencia sqflite como necesaria | Declarada pero NUNCA importada en ningún .dart | Dependencia muerta. ✅ REMOVIDA de pubspec.yaml en Paso 03 | ✅ Resuelto |
| D8 | Dependencia path: ^1.8.0 | `path: ^1.9.0` presente | Versión superior, compatible | ✅ Resuelto |
| D9 | user_profile.json en disco | Perfil guardado en SharedPreferences, no como JSON file | Diferencia de implementación, funcionalmente equivalente | ✅ Resuelto |

---

## 3. Contratos Técnicos Vigentes

### Modelos de datos (Dart classes, JSON persistence)

| Modelo | Archivo | Campos clave |
|---|---|---|
| `ProjectState` | `lib/core/models/project_state.dart` | projectId, createdAt, updatedAt, InputSchema?, ScriptBundle?, List\<AssetManifest\> |
| `InputSchema` | `lib/core/models/input_schema.dart` | ideaId, rawTopic, sourceType, contextData |
| `ScriptBundle` | `lib/core/models/script_bundle.dart` | scriptId, totalChunks, chunks[ordered, text] |
| `AssetManifest` | `lib/core/models/asset_manifest.dart` | videoId, filePath, status(enum), metadata |
| `ScriptAnalysis` | `lib/features/new_project/models/script_analysis.dart` | meta, segments[ScriptSegment], direction[hooks, development, cta] |
| `SessionData` | `lib/features/recording/models/session_data.dart` | projectId, chunksRecorded, currentChunkIndex, takesPerChunk, approvedClips, stitchingStatus, finalVideoPath |
| `ClipMetadata` | `lib/features/recording/models/clip_metadata.dart` | chunkIndex, takeIndex, filePath, duration, fileSize, approved, timestamp |
| `UserProfile` | `lib/features/onboarding/data/user_profile.dart` | identity(UserIdentity enum), onboardingCompleted, segmentMinTime, segmentMaxTime, segmentRateWpm |
| `LeakReport` | `lib/features/recording/services/memory_monitor.dart` | heapUsageBytes, allocations, leakCandidateCount, warnings, hasLeaks |
| `LoggerService` | `lib/core/services/logger_service.dart` | static log(tag, message, {error, stack}) — escribe a `vrm_data/logs/app.log` con rotación |

### Persistencia en disco
```
{getApplicationDocumentsDirectory()}/
  vrm_data/
    projects/{projectId}/
      project.json          ← ProjectState serialization
      session_data.json     ← RecordingSession serialization
      clips/
        chunk_{N}_take_{M}.mp4
```

### Endpoints / APIs

| Nombre | Ruta | Método | Input | Output | Estado |
|---|---|---|---|---|---|
| Backend Prompt | `POST /prompt/{category}/{name}` | HTTP | `{topic, context, profile_id, send_to_ai}` | `{formatted_prompt, ai_response, security}` | Código existe, servidor no desplegado |
| API Service (Flutter) | `ApiService.callPrompt()` | Dart | `category, name, payload` | `Map<String, dynamic>` | Conecta a `localhost:8000`, usa Platform.isAndroid → 10.0.2.2 |
| Native Stitcher | `MethodChannel('com.vrm.vrm_app/stitcher')` | Dart→Native | `{clips: [], outputPath: ""}` | `bool` (success) | ✅ Handlers nativos Android (MediaMuxer) + iOS (AVComposition) |

### Conexiones Flutter → Nativas

| Channel | Namespace | Uso | Estado |
|---|---|---|---|
| Stitcher | `com.vrm.vrm_app/stitcher` | `stitchVideos(clips, outputPath)` | ✅ IMPLEMENTADO — handlers nativos en Android (MediaMuxer) e iOS (AVComposition) |

### Patrones de código en uso

| Patrón | Ejemplo | Archivo referencia |
|---|---|---|
| **Service singleton/stateful** | `CameraService`, `RecordingManager`, `ExportService`, `LoggerService`, `MemoryMonitor` | `lib/features/recording/services/camera_service.dart` |
| **Repository** | `ProjectRepository`, `OnboardingRepository` | `lib/core/data/project_repository.dart` |
| **Plugin + Factory** | `TemplateScriptPlugin`, `BackendScriptPlugin`, `PipelineFactory` | `lib/core/pipeline/` |
| **Model with fromJson/toJson** | `ProjectState`, `ScriptBundle`, `SessionData` | `lib/core/models/project_state.dart` |
| **Exception hierarchy** | `CameraHardwareException`, `PersistenceException`, `PluginException` | `lib/core/exceptions/` |
| **Named routes + onGenerateRoute** | `/recording`, `/stitch-progress`, `/recording-end` | `lib/main.dart` L48-79 |
| **Feature-based directory structure** | `lib/features/{feature}/{pages,services,models,widgets}/` | `lib/features/recording/` |

### Convenciones de naming (de proyecto-config.json)

| Capa | Convención |
|---|---|
| Dart (frontend) | camelCase variables/funciones, PascalCase clases |
| Python (backend) | snake_case |
| Archivos | snake_case (Dart y Python) |
| Imports | Absolutos: `package:vrm_app/...` |

### Dependencias instaladas

**Directas clave:**
- `camera: ^0.11.0+4` — hardware cámara
- `video_player: ^2.9.1` — reproducción clips
- `path_provider: ^2.1.3` — rutas filesystem
- `path: ^1.9.0` — manipulación rutas
- `shared_preferences: ^2.2.3` — perfil usuario
- `permission_handler: ^11.3.0` — permisos cámara/almacenamiento
- `photo_manager: ^3.5.0` — guardado galería nativa
- `share_plus: ^10.1.0` — share sheet nativo
- `speech_to_text: ^7.3.0` — dictado por voz
- `flutter_tts: ^4.2.5` — text-to-speech
- `uuid: ^4.0.0` — IDs únicos
- `storage_space: ^1.0.1` — verificación espacio disco
- `device_info_plus: ^11.0.0` — información del dispositivo (modelo, brand, ID)
- *(sqflite and battery_plus removed in Paso 03)*

**Dev:**
- `flutter_lints: ^6.0.0`
- `flutter_launcher_icons: ^0.13.1`
- `flutter_native_splash: ^2.4.0`

---

## 4. Decisiones de Arquitectura Tomadas

| Decisión | Detalle | Justificación |
|---|---|---|
| **Persistencia JSON** en vez de SQLite | `ProjectRepository` escribe/lee JSON en filesystem. `sqflite` declarado pero 0 uso. | Simplicidad MVP. Datos son documento, no relacionales. Evita overhead de ORM para schemas que cambian rápido. |
| **Plugin pipeline** (3 stages) | `VRMPipeline.execute()` = ManualInputPlugin → TemplateScriptPlugin/BackendScriptPlugin → StitcherPlugin | Separación clara ingest/procesamiento/post-procesamiento. Factory permite switchear entre local y backend. |
| **MethodChannel para stitch** en vez de ffmpeg_kit_flutter | `NativeStitcherService` usa `MethodChannel('com.vrm.vrm_app/stitcher')`. Handlers nativos: Android `mergeVideos()` con `MediaMuxer` (MainActivity.kt:52-146), iOS `mergeVideos()` con `AVMutableComposition` + `AVAssetExportSession` (AppDelegate.swift:35-81). `ffmpeg_kit_flutter` eliminado. | ffmpeg_kit_flutter tenía problemas de compilación nativa. MethodChannel usa APIs nativas del OS (MediaMuxer/AVComposition). ⚠️ No probado end-to-end en dispositivo real. |
| **Sin autenticación MVP** | No hay auth middleware, no hay RLS, no hay login. | MVP es 100% offline/single-user. Backend IA para V2. |
| **Feature-based directories** | `lib/features/{feature}/{pages,services,models,widgets}/` | Escalabilidad y separación de concerns. Cada feature autocontenida. |
| **Onboarding → Dashboard → Recording** como flujo principal | `main.dart` L45: onboarding condicional. Named routes para navegación profunda. | Flujo lineal simple para MVP. |

### Decisiones de Paso 10 (Adaptive-icons-Android-13)

| Decisión | Detalle | Justificación |
|---|---|---|
| **`adaptive_icon_background: "#000000"`** en vez de `"#FFFFFF"` | `icon_source.png` tiene fondo negro integrado. Background blanco → anillo blanco visible en Android 13+. Usar negro → match perfecto. | Opus detectó el fondo negro en `icon_source.png`. 3 agentes no lo vieron (ring, step, ds). Corrección crítica. |
| **Extender store_prep_cli.dart check [9]** en vez de script nuevo | 3 agentes propusieron scripts independientes (Grok → vrm-icon-regen, step → icons-generate, LagunaM1 → generate_adaptive_icons). Opción opus/glm (extender CLI existente) gana. | Consistente con patrón actual. 0 fragmentación. 1 comando para todo store prep. |
| **No crear foreground transparente (Opción B) para MVP** | Requiere edición gráfica. Opción A (background negro) es suficiente para MVP. | Post-MVP crear `icon_foreground.png` con fondo transparente. |
| **`android:roundIcon` no requerido** | Android 13+ resuelve adaptive icon sin roundIcon explícito. | Opus lo mencionó pero no bloquea. Post-MVP. |

### Decisiones de Paso 13 (Mejorar-debugprint-scanner-kdebugmode)

| Decisión | Detalle | Justificación |
|---|---|---|
| **Refactor a 4 helpers + orquestador** | `_isInsideDebugModeBlock` → `isSameLineKDebugModeGuard` + `isInsideAssert` + `isTernaryKDebugModeGuard` + `isAdjacentKDebugModeGuard` + `isInsideBracedDebugModeBlock`. Orquestador en `isInsideDebugModeBlock`. | ds propuso 3 niveles, glm propuso test unitario. Fusión de ambas. Responsabilidad única por helper. |
| **Dart puro sin dependencias** | Scanner usa solo `dart:io`. Detector usa `dart:core` (RegExp, String). 0 dependencias externas. | Consistencia con scripts existentes. ds y glm coinciden. |
| **Extracción a `debugprint_detector.dart`** como módulo público | Funciones públicas en archivo separado para testing. Wrappers `_` privados en scanner delegando a detector. | FINAL §3 especifica `_` privadas + test unitario externo — contradicción en Dart. Solución: detector público + wrappers `_` en scanner. Test importa detector. |
| **Mini-parser strings/comentarios para braceDepth** | `stripStringsAndComments()` ignora `'...'`, `"..."`, `//`, `/* */` antes de contar braces. Maneja escapes `\\` y strings anidados. | D5: braces en strings/comentarios alteraban braceDepth. Prevenía falsos positivos. |
| **Test unitario como Tarea 0 (DX primero)** | 31 tests en 8 grupos (isSameLineKDebugModeGuard, isInsideAssert, isTernaryKDebugModeGuard, isAdjacentKDebugModeGuard, isInsideBracedDebugModeBlock, stripStringsAndComments, orquestador). | glm propuso test primero. Previene regresión. |
| **D6-D7 descartadas** | D6 (espaciado `!kReleaseMode`) es falso — `contains()` ya maneja. D7 (falso positivo memory_monitor.dart) no existe. | Verificado contra código real. No implementar. |
| **Corrector: ID-001 unused_import** | 3 `import 'package:flutter/foundation.dart';` removidos de `project_repository.dart`, `voice_command_service.dart`, `platform_services.dart`. | `--fix` migró debugPrint→LoggerService dejando imports huérfanos. Validación rechazó por criterio #13 (flutter analyze 0 issues). |
| **Corrector: ID-002 wrappers `_` privados** | Agregados `_isInsideDebugModeBlock`, `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock` wrappers en scanner delegando al detector público. Scanner interno usa `_isInsideDebugModeBlock`. | FINAL spec pedía `_` privadas en scanner. Wrappers reconcilian spec + testabilidad. |

### Decisiones de Paso 14 (Migracion-masiva-debugprint-residuales)

| Decisión | Detalle | Justificación |
|---|---|---|
| **Scope real = 7 residuales, no ~70** | Scanner Paso 13 mejoró detección guards (kDebugMode, assert, ternario, braced blocks). 72→7 residuales reales. | Plan original Paso 08 decía "~70 debugPrint en 15 archivos". Código gana sobre plan. |
| **Migración manual sobre `--fix` automático** | 6 de 7 debugPrint son multilínea. `--fix` del scanner no soporta multilínea (busca `)` en misma línea). Migración manual más eficiente que mejorar parser para solo 7 calls. | Paso 17 planifica parser multilínea completo. Invertir en mini-parser ahora es YAGNI. |
| **Verifier como Tarea 0 DX** | `scripts/debugprint_migration_verifier.dart` en vez de extender `--fix`. Verifica post-migración: scanner 0 residuales + 0 unused imports + flutter analyze 0 issues. | ~2s vs ~10min revisión manual de 5 archivos. Previene regresión. Sigue patrón `validador_metrics_session.dart` (verificador, no modificador). |
| **Tags PascalCase en LoggerService.log** | `'VRMPipeline'`, `'StitcherPlugin'`, `'SchemaValidator'`, `'ClipStorageService'`, `'SocialAccountManager'` — PascalCase consistente con nombre de clase. | Archivos ya tenían tags snake_case en algunos calls existentes. Tags nuevos usan PascalCase para identificar calls migrados del scope Paso 14. |
| **Remoción imports `flutter/foundation.dart` unused** | 5 archivos ya no usan `debugPrint` ni `kDebugMode` → import removido. Verificado con `flutter analyze` 0 issues en lib/. | Mismo patrón que Paso 13 ID-001. Previene warnings de unused imports. |
| **`memory_monitor.dart:62` y `logger_service.dart:48` conservan debugPrint** | Intencional: memory_monitor dentro de `if (kDebugMode)`, logger_service como echo en debug. Scanner los excluye correctamente. | No migrar — son debugPrint legítimos. Scanner Paso 13 ya los detecta como guardados. |

### Decisiones de Paso 15 (Vrm-health-check-resiliencia-archivos)

| Decisión | Detalle | Justificación |
|---|---|---|
| **Catch genérico `catch (e)` sobre `on FileSystemException`** | 3 try/catch usan `catch (e)` no `on FileSystemException catch (e)`. | MVP: atrapa cualquier excepción de filesystem (race conditions, permisos, corruption). Post-MVP: catch específico para distinguir tipos. Ya documentado en Roadmap. |
| **`failedFiles` lista local, no campo de clase** | `final failedFiles = <String>[];` declarado dentro de `_runFixCleanup()`. | Scope mínimo. Solo se usa dentro de la función. Sin estado compartido. |
| **`cleaned++` dentro de try (post-delete exitoso)** | Movido de fuera del try (contaba fallidos) a dentro. | Previene conteo erróneo. Solo cuenta archivos realmente eliminados. |
| **DX tool simula archivo bloqueado real** | `health_check_resilience_test.dart` usa `attrib +R` en Windows para crear archivo read-only en `vrm_data/tmp/` (dir real). Verifica output contiene `⚠️`. | Demuestra try/catch bajo presión real. Cleanup automático con `attrib -R`. Dir correcto = archivos procesados por health check. |
| **5 tests en DX tool** | (1) exitCode=0, (2) output contiene ⚠️ locked_temp.mp4, (3) no Unhandled exception, (4) --dry-run OK, (5) resumen ARCHIVOS NO ELIMINADOS | Cobertura completa del comportamiento esperado. Maneja edge case admin (attrib no impide delete → test pasa gracefully). |

### Decisiones de Paso 12 (Screenshots-store-ready)

| Decisión | Detalle | Justificación |
|---|---|---|
| **Dart sobre Bash para DX tool** | `capture_store_screenshots.dart` en vez de script Bash. 5/6 agentes propusieron Dart. | Consistencia con ecosistema existente (`store_prep_cli.dart`, `vrm_health_check.dart`, etc). Sin dependencias externas. |
| **ADB screencap como metodo captura** | `adb shell screencap -p` produce PNG nativo. No requiere plugins Flutter ni MethodChannel. | Simplicidad MVP. Resolucion nativa del dispositivo. Sin dependencias extras. |
| **step1.png..step5.png (sin sufijo descriptivo)** | Naming coincide con guia CLI existente (`store_prep_cli.dart:699`). Consistencia. | Evita confusion entre script y realidad. Guia CLI = unica verdad. |
| **Validacion corruptos <10KB** | `_validateScreenshotResolution()` chequea `file.lengthSync() <= 10240`. `_runCheck()` distingue corrupto vs resolucion insuficiente. | Propuesta DS aceptada. Previene falsos positivos (IHDR null sin mensaje). |
| **Shared utils module** | `scripts/utils.dart` extrae `getPngDimensions()` + `validatePngHeader()`. Importado por ambos scripts. | Elimina duplicacion (ID-004). Previene drift entre parsers. |
| **Captura en dispositivo real > emulador** | 5 screenshots capturadas en Xiaomi 2201117TL (1080x2400). PNG headers verificados. | Emuladores rechazados por Google Play/App Store. Dispositivo real obligatorio. |
| **Eliminar legacy `assets/images/screenshots/`** | Directorio duplicado removido via `--clean`. No referenciado en codigo. | Evita falsos positivos en store_prep_cli check (contaba ambos dirs = 10 archivos). |

### Decisiones de Paso 11 (Contexto-y-Actualizacion-Estado)

| Decisión | Detalle | Justificación |
|---|---|---|
| **Corrección CRÍTICA: Stitch handler nativo EXISTE** | Phase-state decía "STUB — sin handler Android/iOS". Verificación contra código fuente confirma: `MainActivity.kt:52-146` (Android MediaMuxer) y `AppDelegate.swift:35-81` (iOS AVComposition) implementados. Discrepancia D6 cambia de ⏳→✅. | 6_CONTEXTO.md requiere verificación contra código fuente. Error en phase-state previo propagaría info falsa a agentes downstream. |
| **72 debugPrint residuales confirman deuda técnica** | Escaneo confirma 72+ debugPrint en 15 archivos de lib/. Documentado como post-MVP. | No bloquea release. debugPrint_scanner.dart disponible para migración gradual. |

### Decisiones de Paso 9 (vrm-health-check-fix-real)

| Decision | Detalle | Justificacion |
|---|---|---|
| **`--dry-run` como flag** en vez de subcomando separado | `check --fix --dry-run` muestra acciones sin ejecutar. Reutiliza toda la logica de `_runFixCleanup()` con condicional `if (dryRun)` ramificado. | Sin duplicacion. Preview natural sin estado. Mismo flag pattern que `--fix`. |
| **`_fixProguardDeadRules()` como fn separada** | Extraida de `_runCheck()` L136-152 para soportar dry-run y reutilizacion. Lee/filtra/escribe archivo. | Mantiene `_runCheck()` limpio. Sigue SRP. |
| **Paso 09 = verificacion + DX enhancement** | `_runFixCleanup()` ya implementado en Paso 05. Paso 09 agrega `--dry-run` y `_fixProguardDeadRules()` real. | Consistente con hallazgos de 6/6 agentes. Codigo existente gana. |

### Decisiones de Paso 8 (Migrar-debugPrint-residual-LoggerService)

| Decision | Detalle | Justificacion |
|---|---|---|
| **Scope original ya completado en Paso 05** | 6/6 agentes verificaron que recording_page.dart tiene 0 debugPrint. Plan desactualizado. | Codigo gana. Paso 08 es esencialmente validacion + DX tooling. |
| **DX tool: debugprint_scanner.dart** | `scripts/debugprint_scanner.dart` (276L) con `dart run scripts/debugprint_scanner.dart` para scan y `--fix` para migracion automatica. | Unifica 5 propuestas de agentes (glm51, laguna1, Kilo, hy3, ds). Kilo propuso version mas completa con --fix. Previene regresion de debugPrint en Release. |
| **72 debugPrint residuales fuera de scope** | 15 archivos en lib/ tienen 70 debugPrint documentados en analisis-FINAL D3. | Roadmap post-MVP. Paso 08 scope limitado a recording_page.dart. |

### Decisiones de Paso 7 (Metricas Reales Sesion RecordingEndPage)

| Decision | Detalle | Justificacion |
|---|---|---|
| **Progreso desde `chunksRecorded / totalChunks`** en vez de `approvedClips` | `_progress` = `chunksRecorded.length / (currentChunkIndex + 1)` | `chunksRecorded` = chunks efectivamente grabados. `approvedClips` no existe en SessionData. Mas precisa sin agregar campos. |
| **`totalChunks` inferido de `currentChunkIndex + 1`** | SessionData no tiene campo `totalChunks` explícito | Aceptable MVP. Post-MVP agregar campo explicito. |
| **sessionData como route argument** en flujo Stitch→End | `stitch_progress_page.dart` pasa `sessionData` en Navigator arguments | Mismo patron que `recording_page.dart:826`. Evita perder datos de sesion tras stitch exitoso. |
| **Validador CLI con `--progress-only`** | `validador_metrics_session.dart` flag para validar solo calculo de progreso | Permite validacion rapida sin session_data.json completo. Usado en Tarea 0. |

### Decisiones de Paso 5 (Correcciones y Validación)

| Decisión | Detalle | Justificación |
|---|---|---|
| **LoggerService.log() sobre debugPrint** | 7 debugPrint residuales en recording_page.dart migrados a LoggerService.log(). Patrón: `LoggerService.log('RecordingPage', 'msg', error: e)`. | debugPrint es no-op en Release. LoggerService garantiza diagnóstico en producción. Patrón ya establecido en L288-290. |
| **PNG IHDR header parsing en store_prep_cli** | `_getPngDimensionsSync()` parsea bytes 16-23 (big-endian width/height) del header PNG. 0 dependencias externas. | store_prep_cli check/assets validate ahora detectan resolución <1080x1920. Sin esto, tool reportaba ✅ con screenshots inválidas. |
| **3 handlers SessionIntegrityException** | Insertados antes de catch genérico en `_startActualRecording`, `_stopRecording`, `_applyHardwareSettings`. Reset idle + sin SnackBar duplicado. | ling detectó que 3 métodos (no 1) necesitaban handler. Consistencia con patrón `_verifyIntegrity()`. |
| **MaterialBanner sobre SnackBar** | Reemplazado SnackBar flotante con MaterialBanner sticky + dismiss manual en ScriptStudio. | MaterialBanner permanece visible hasta descarte del usuario. Mejor UX para advertencias importantes. |

### Correcciones al plan (discrepancias detectadas)

- **Plan dice F8 Grabación 50% → Realidad 100%**: El plan asume que `_cameraController` no escribe disco. `CameraService` + `ClipStorageService` ya escriben MP4 reales con manejo de espacio y lifecycle.
- **Plan dice F9 Revisión 40% → Realidad 100%**: `ClipReviewPage` ya reproduce clips reales con accept/reject.
- **Plan dice F8 Overlay 50% → Realidad 100%**: Todos los botones del overlay conectados a hardware.
- **Plan dice Mi Cuenta 80% → Realidad <20%**: Solo UI shell. Toggles, datos de perfil, persistencia de settings no existen. → **IMPLEMENTADO EN P2**
- **Plan asume ffmpeg_kit_flutter → Realidad MethodChannel CON handlers nativos**: Arquitectura de stitch cambió a nativo. Android (MediaMuxer) e iOS (AVComposition) implementados. ⚠️ No probado E2E en dispositivo real.
- **Plan dice Perfil Influencer no persiste → IMPLEMENTADO EN P2**: `SettingsService.setInfluencerProfile()` guarda en SharedPreferences.
- **Plan dice Settings stubs → IMPLEMENTADO EN P2**: Theme switcher funciona, teleprompter persisten, cloud sync toggle funciona.

### Decisiones de Paso 2 (Interfaz Reactiva)

| Decisión | Detalle | Justificación |
|---|---|---|
| **SettingsService singleton** | Wrapper de SharedPreferences para teleprompter, theme, cloud sync, influencer profile | Mantiene consistencia con CameraService y OnboardingRepository. Simplicidad MVP. |
| **DeviceInfoService singleton** | Wrapper de device_info_plus para model/brand/id | Información real del dispositivo en AccountProfile. Try/catch con fallback Unknown. |
| **TeleprompterPrefs value object** | fromMap/toMap para serialización JSON | Consistencia con UserProfile, ProjectState. |
| **VRMApp StatefulWidget** | Carga ThemeMode desde SettingsService en initState | Theme switcher en Settings ahora afecta tema global. Criterio #11 MVP cumplido. |
| **validador_hardware.dart DX** | Script CLI que prueba focus lock, flash, exposure en dispositivo real | Automatiza QA de toggles de cámara. Requiere dispositivo físico. |

### Decisiones de Paso 3 (Estabilidad y Pulimento Físico)

| Decisión | Detalle | Justificación |
|---|---|---|
| **LoggerService a archivo persistente** | Logger escribe a `vrm_data/logs/app.log` con rotación. Reemplaza `debugPrint` en servicios críticos. | `debugPrint` es no-op en Release. Logger garantiza diagnóstico en producción. Sigue patrón async de `RecordingManager._saveSessionDataToDisk()`. |
| **VRM Health Check CLI unificado** | Fusión de VRM System Check + Validador de Resiliencia + Memory Leak Detector + vrm_data_scaffold en 1 CLI con subcomandos. | Evita proliferación de scripts independientes. Sigue convención `scripts/` del proyecto. |
| **Fallback resolución en CameraService** | `ResolutionPreset.high → medium → low` sin intervención de usuario. | Sigue patrón existente de 3 fallbacks en `NativeStitcherService`. |
| **MemoryMonitor singleton** | Timer periódico (30s) para muestreo de memoria. Genera `LeakReport`. Solo debug/profile mode. | Sigue patrón singleton de `CameraService`. No requiere dependencias externas para MVP. |
| **ProGuard ya configurado, solo limpiar reglas muertas** | `isMinifyEnabled=true`, `isShrinkResources=true`, `proguard-rules.pro` existe. Solo remover reglas ffmpegkit (L9-12). | Confirmado en análisis de código. No requiere configuración adicional. |
| **Stream<double> para progreso exportación** | `ExportService` emite progreso via `StreamController.broadcast()` en vez de callback `onProgress`. | Permite múltiples suscriptores. Desacopla UI de lógica de exportación. |

### Decisiones de Paso 4 (Puerta de Tiendas y Valla Legal)

| Decisión | Detalle | Justificación |
|---|---|---|
| **store_prep_cli.dart como herramienta DX unificada** | CLI unificado con 5 subcomandos. Reemplaza propuestas individuales de 4 agentes (speed, ds, hy3, laguna). Sigue patron `vrm_health_check.dart`. | Reduce fragmentación. Unica CLI para todo el pipeline store readiness. |
| **Dart sobre Python para DX** | CLI escrito en Dart. hy3 propuso Python — descartado. | Todos los scripts del proyecto usan Dart (`vrm_health_check.dart`, `validador_hardware.dart`). Consistencia del ecosistema. |
| **docs/PRIVACY_POLICY.md como fuente de verdad** | Root PRIVACY_POLICY.md reemplazado con contenido de docs/ version. docs/ tiene datos reales, root era template genérico. | Unifica versiones. Elimina riesgo de placeholders en release. |
| **Android stitch handler ya implementado** | `MainActivity.kt:52-146` tiene mergeVideos() con MediaMuxer. DS afirmó ausencia — FALSO. iOS handler también existe en AppDelegate.swift:35-81 con AVMutableComposition. | Código existe en AMBAS plataformas. Implementador no toca. |
| **Capturas manuales + guía CLI** | `store_prep_cli.dart screenshots` guía captura manual. Capturas finales requieren dispositivo real. | Golden tests generan base, pero resolución store requiere dispositivo físico. |
| **Corrección D7: key.properties passwords** | Passwords randomizadas via `_randomSuffix()` con `Random.secure()`. No más `vrm_password_123`. | Seguridad: passwords default expuestas en repo público. |

---

## 5. Registro de Pasos Completados

| Paso | Estado | Archivos Archivados En | Commit | Decisiones Tomadas | Notas |
|---|---|---|---|---|---|
| — | — | — | — | — | Primer paso de fase mvp. IN_PROGRESS vacío. |
| 02-Interfaz-Reactiva-y-Refinamiento-Local | ✅ completed | `DEVS/IMPLEMENTED/mvp/02-Interfaz-Reactiva-y-Refinamiento-Local/` | 34949d7 | Corrections applied: CR-001 (theme switcher), IMP-002 (stubs removed), IMP-003 (memberSince), IMP-004 (file naming). 12/13 criteria passed. | Paso 2 completado y validado. Theme persistence now works (VRMApp loads from SettingsService). |
| 03-Estabilidad-y-Pulimento-Fisico | ✅ completed | `DEVS/IMPLEMENTED/mvp/03-Estabilidad-y-Pulimento-Fisico/` | 10cad57 | LoggerService persistente, CameraService fallback resolución + error propagation, ExportService Stream progreso + overlay, MemoryMonitor + didHaveMemoryPressure, ScriptStudio fallback notification, ProGuard limpio, VRM Health Check CLI. 14/14 criteria passed. | Paso 3 completado y validado. 0 críticos, 3 importantes, 4 mejoras. |
| 04-Puerta-de-Tiendas-y-Valla-Legal | ✅ completed | `DEVS/IMPLEMENTED/mvp/04-Puerta-de-Tiendas-y-Valla-Legal/` | 35f6c57 | store_prep_cli.dart CLI unificado, PRIVACY_POLICY.md limpio (0 placeholders), keystore RSA 2048 generado, key.properties passwords randomizadas, settings page enlace Privacy Policy funcional, screenshots en directorio store, Play Store data safety documentado, gitignore seguro. 10/12 criteria verified passed. | Paso 4 completado con 3 críticos residuales (privacy URL hosting, screenshots resolución, link settings). Corrector aplicó fixes: URL raw.githubusercontent.com funcional, Random.secure(), paths portátiles. |
| 05-Correcciones-y-Validacion | ✅ completed | `DEVS/IMPLEMENTED/mvp/05-Correcciones-y-Validacion/` | 64dc630 | SessionIntegrityException handlers en 3 métodos (`_startActualRecording`, `_stopRecording`, `_applyHardwareSettings`). MaterialBanner en ScriptStudio. Metrics reales SessionData en RecordingEndPage. 0 debugPrint en recording_page.dart (7 migrados a LoggerService.log()). store_prep_cli.dart validación resolución screenshots via PNG IHDR header. widget_test.dart reparado. | Corrector aplicó fixes: 7 debugPrint→LoggerService, store_prep_cli resolution validation. 19/20 criteria met. 1 crítico residual (#19 screenshots requiere captura manual en dispositivo real). 18/18 tests pass, flutter analyze 0 errores. |
| 06-MaterialBanner-notificacion-fallback-IA | ✅ completed | `DEVS/IMPLEMENTED/mvp/06-MaterialBanner-notificacion-fallback-IA/` | 328055e | MaterialBanner sticky naranja en `script_studio_page.dart:338-363`. vrm_banner_validator CLI creado como DX para consistencia de notificaciones. | Unificado de 4 análisis (ds, laguna, step, hy3). Todos confirmaron: código ya implementado. Sin cambios adicionales. |
| 07-Metricas-Reales-Sesion-RecordingEndPage | ✅ completed | `DEVS/IMPLEMENTED/mvp/07-Metricas-Reales-Sesion-RecordingEndPage/` | 88df3de | `progress: 0.75` → getter `_progress` (chunksRecorded/totalChunks). `stitch_progress_page.dart` pasa sessionData en route args (L91, L134). `recording_page.dart` pasa finalVideoPath (L826). `validador_metrics_session.dart` con flag `--progress-only` (173L). | 3 correcciones aplicadas (D1-D3). 8/8 criterios aceptacion. 0 criticos. 1 importante (dogfooding). 18/18 tests. flutter analyze 0 errores. |
| 08-Migrar-debugPrint-residual-LoggerService | ✅ completed | `DEVS/IMPLEMENTED/mvp/08-Migrar-debugPrint-residual-LoggerService/` | 7fa5dfa | Scope original (2 debugPrint en recording_page.dart L657,L662) YA COMPLETADO en Paso 05. 6/6 agentes confirmaron 0 debugPrint. Kilo migró 2 debugPrint extra en recording_end_page.dart (L95, L172). DX tool `scripts/debugprint_scanner.dart` (276L) creado con scan + --fix. 72 debugPrint residuales en 15 archivos documentados como roadmap post-MVP. | 5/5 criterios aceptacion. 3/3 correcciones D1-D3 aplicadas. 0 criticos. 2 mejoras. flutter analyze 0 errores. 18/18 tests. |
| 09-vrm-health-check-fix-real | ✅ completed | `DEVS/IMPLEMENTED/mvp/09-vrm-health-check-fix-real/` | 378d54b | `--dry-run` flag agregado a `check --fix`. `_runFixCleanup({bool dryRun = false})` con preview completo. `_fixProguardDeadRules()` nuevo — realmente elimina reglas ffmpegkit (antes solo print warning). `_runCheck()` refactorizado para soportar dryRun. CLI help actualizado. 7/7 criterios aceptacion. Validacion 8/10 calidad. | Paso esencialmente verificacion — `_runFixCleanup()` ya existia desde Paso 05 (b603e48). `--dry-run` enhancement nuevo en este paso. 0 criticos, 0 importantes, 2 mejoras. flutter analyze 0 errores. 18/18 tests. |
| 10-Adaptive-icons-Android-13 | ✅ completed | `DEVS/IMPLEMENTED/mvp/10-Adaptive-icons-Android-13/` | 4877955 | `pubspec.yaml:133` `adaptive_icon_background` corregido `#FFFFFF`→`#000000`. store_prep_cli.dart check [9] agregado (L303-323) verifica `mipmap-anydpi-v26/` existe con XML. `flutter pub run flutter_launcher_icons` ejecutado → XML generado con `<adaptive-icon>` + foreground/background layers. colors.xml `ic_launcher_background` = `#000000`. Iconos legacy PNGs regenerados en todas densidades. 14/15 criterios aceptacion. Validacion 9/10 calidad. | Correccion critica: plan decia "agregar config" pero ya existia. Tarea real = regenerar iconos + corregir color. D3 fondo negro integrado en icon_source.png detectado por opus. 0 criticos, 1 importante (screenshots pre-existente), 2 mejoras. flutter analyze 0 errores. 18/18 tests. |
| 11-Contexto-y-Actualizacion-Estado | ✅ completed | `DEVS/IMPLEMENTED/mvp/11-Contexto-y-Actualizacion-Estado/` | f7b0527 | Corrección CRÍTICA: Stitch handler nativo EXISTE en Android (MediaMuxer, `MainActivity.kt:52-146`) e iOS (AVComposition, `AppDelegate.swift:35-81`). Phase-state decía "STUB sin handler" — falso. Discrepancia D6 corregida: ⏳→✅ Resuelto. 7 análisis archivados. Tests 21/21 pasan. | Sin cambios en lib/. Solo actualización de estado. Archivado de IN_PROGRESS → IMPLEMENTED. Nuevo DX tool: `scripts/test_coverage_report.dart`. |
| 12-Screenshots-store-ready | ✅ completed | `DEVS/IMPLEMENTED/mvp/12-Screenshots-store-ready/` | d9a4ef4 | DX tool: `capture_store_screenshots.dart` + `utils.dart` shared module. `store_prep_cli.dart` validacion corruptos <10KB. 5 PNGs 1080x2400 capturadas en Xiaomi 2201117TL. D1-D4 corregidas (JPEGs eliminados, legacy dir removido). ID-004 resuelta (shared utils). 12/12 criterios aceptacion. 11/11 store check. Dogfooding completo. | 8 analisis archivados. 3 scripts nuevos/modificados. Sin cambios en lib/. |
| 13-Mejorar-debugprint-scanner-kdebugmode | ✅ completed | `DEVS/IMPLEMENTED/mvp/13-Mejorar-debugprint-scanner-kdebugmode/` | 705eb0a | Refactor `_isInsideDebugModeBlock` → 4 helpers + orquestador. D1-D5 resueltas (same-line, adjacent, assert, ternary, braces strings/comentarios). `debugprint_detector.dart` (164L) API pública. `debugprint_scanner_test.dart` 31 tests. Corrector: ID-001 (3 unused_import removidos), ID-002 (_wrappers privados). 52/52 tests. flutter analyze 0 issues. | 8 archivos archivados. 3 archivos nuevos/modificados (detector, scanner, test). 3 archivos lib/ corregidos (ID-001). |
| 14-Migracion-masiva-debugprint-residuales | ✅ completed | `DEVS/IMPLEMENTED/mvp/14-Migracion-masiva-debugprint-residuales/` | 9058ed7 | Migración manual 7 debugPrint→LoggerService.log() en 5 archivos. 5 imports flutter/foundation.dart unused removidos. Import LoggerService agregado en stitcher_plugin.dart. DX: debugprint_migration_verifier.dart. Validación: 14/14 criterios, 0 críticos, 52/52 tests, flutter analyze 0 issues en lib/, scanner 0 residuales. | 2 archivos archivados (analisis-FINAL.md + validacion.md). 6 archivos lib/ modificados. 1 script nuevo (verifier). |
| 15-Vrm-health-check-resiliencia-archivos | ✅ completed | `DEVS/IMPLEMENTED/mvp/15-Vrm-health-check-resiliencia-archivos/` | 6d7fa7b | 3 `delete()` en `_runFixCleanup()` envueltos en try/catch individual. `failedFiles` lista acumula paths fallidos. Resumen final `⚠️ ARCHIVOS NO ELIMINADOS`. `cleaned++` solo post-delete exitoso. Rama dryRun intacta. DX: `health_check_resilience_test.dart` (234L) simula archivo bloqueado real con `attrib +R`. Validación: 14/14 criterios, 0 críticos, 52/52 tests, 0 cambios lib/. Calidad 9.5/10. | 3 archivos archivados. 1 script modificado (`vrm_health_check.dart`). 1 script nuevo (`health_check_resilience_test.dart`). Sin cambios en lib/. |

---

## 6. Criterios Generales de Aceptación MVP

- [ ] Happy path: Idea → Script → Grabar → Revisar → Stitch → Exportar funciona end-to-end sin crash
- [ ] Fallback IA offline: ScriptStudio genera guion con templates cuando backend no responde
- [ ] Stitch: Clips se concatenan en `final.mp4` — handlers nativos implementados (Android MediaMuxer + iOS AVComposition), pendiente prueba end-to-end en dispositivo real
- [ ] Export: `final.mp4` se guarda en galería nativa y share sheet se abre
- [ ] Persistencia: Proyecto guardado en disco puede reanudarse después de cerrar app
- [ ] Permisos: Cámara, micrófono y almacenamiento solicitados correctamente con mensaje explicativo
- [ ] Errores: Cámara no disponible, disco lleno, stitch fallido → mensaje visible al usuario, no crash
- [ ] Toggles hardware: Modo calle, fantasma, enfoque, flash ejecutan parámetros reales en cámara
- [ ] Tests existentes pasan (repository_test, pipeline_test, error_handling_test)
- [x] Dependencias muertas (sqflite, battery_plus) removidas en Paso 03

### NO requerido para MVP
- Retry con backoff — conexiones fallidas muestran error, no reintentan
- Caching avanzado — datos se leen de disco cada vez
- Rate limiting — no aplica (single-user offline)
- Observabilidad avanzada — LoggerService implementado para errores críticos (MVP suficiente). No hay APM/monitoring.
- Optimización de performance extrema — aceptable para dispositivo de gama media
- Publicación directa a redes sociales — share sheet nativo es suficiente
- Gamificación / Métricas de desempeño — excluidas del alcance MVP

### Herramientas DX detectadas

| Herramienta | Descripción | Impacto usuario final |
|---|---|---|
| **Validador de pipeline end-to-end** | Script que ejecuta flujo completo en dispositivo real y reporta etapa a etapa ✅/❌ | Detecta MissingPluginException, permisos faltantes y errores filesystem antes de release |
| **validador_hardware.dart (Paso 2)** | Script CLI que prueba focus lock, flash torch, exposure lock en dispositivo real. Reporta compatibilidad JSON. | QA automatizado de toggles de cámara. Elimina prueba manual por modelo. |
| **VRM Health Check (Pasos 3+9+15)** | `scripts/vrm_health_check.dart` (632L) | CLI unificado: `check [--fix] [--dry-run]` (pre-flight + cleanup temp/sesiones huérfanas con preview), `validate` (recovery paths), `memory` (leak detection), `scaffold` (estructura datos). `--fix` ahora elimina reglas ProGuard muertas. `--dry-run` previsualiza acciones sin modificar. **Paso 15:** `_runFixCleanup()` resiliente — 3 `delete()` con try/catch individual, `failedFiles` acumula, resumen final reporta archivos no eliminados. No aborta con archivos bloqueados/read-only. Reduce diagnóstico + limpieza de 30min a ~2s. |
| **Health Check Resilience Test (Paso 15)** | `scripts/health_check_resilience_test.dart` (234L) | DX CLI: simula archivo read-only (`attrib +R`) en `vrm_data/tmp/` real, ejecuta `check --fix`, 5 tests verifican: exitCode=0 + warning ⚠️ locked_temp.mp4 + no Unhandled exception + --dry-run OK + resumen ARCHIVOS NO ELIMINADOS. Cleanup automático. Reduce verificación de resiliencia de ~5min manual a ~5s automático. |
| **Scripts Python existentes** | `scripts/fragmentation_test.py`, `scripts/verify_backend.py` | Útiles para validación backend, pero no cubren frontend |
| **Store Prep CLI (Pasos 4-5+10)** | `scripts/store_prep_cli.dart` (703L) | CLI unificado: `check` (11 checks pre-store + check [9] adaptive icons + validación resolución screenshots via PNG IHDR header), `keystore` (genera RSA 2048), `assets validate` (iconos/splash/screenshots + validación resolución), `privacy` (valida placeholders), `screenshots` (guía captura). Reduce preparación store de ~4h a ~15min. Detecta keystore faltante, passwords default, placeholders, permisos, gitignore, adaptive icons faltantes, resolución screenshots insuficiente. Check [9] evita icono recortado/cuadrado en Android 13+ detectable solo en dispositivo físico. |
| **Validador Metricas Sesion (Paso 7)** | `scripts/validador_metrics_session.dart` (173L) | CLI: `check --project-id <uuid> [--progress-only]` y `demo`. Valida que RecordingEndPage use metricas reales (no hardcodeadas). Detecta `0.75` hardcodeado, duracion "42m", takes falsos en session_data.json. Reduce QA manual de metricas de 10min a ~1s. |
| **DebugPrint Scanner (Pasos 8+13)** | `scripts/debugprint_scanner.dart` (328L) + `scripts/debugprint_detector.dart` (164L) | CLI: `dart run scripts/debugprint_scanner.dart` escanea 88+ archivos lib/ buscando debugPrint residuales en ~1s. `--fix` migra automaticamente a LoggerService.log(). 5 guard patterns detectados: same-line, adjacente, braced block, assert, ternario. `stripStringsAndComments` ignora braces en strings/comentarios. `test/debugprint_scanner_test.dart` con 31 tests previene regresión. QA automatizado de logging — evita regresion de debugPrint en Release. Reduce revision manual de ~15min a ~1s. |
| **Test Coverage Report (Paso 11)** | `scripts/test_coverage_report.dart` (233L) | CLI: `dart run scripts/test_coverage_report.dart` escanea `lib/features/` y `test/` para generar reporte de cobertura por feature. Detecta features sin tests. UX DX para visibilidad de cobertura. |
| **Capture Store Screenshots (Paso 12)** | `scripts/capture_store_screenshots.dart` (247L) | CLI interactivo ADB: `dart run scripts/capture_store_screenshots.dart` guia paso a paso captura 5 pantallas. `--clean` elimina JPEGs existentes + dir legacy. `--device <id>` especifica dispositivo. Valida PNG header + dimensiones + file size. Reduce captura manual ~30min a ~5min. Dogfooding verificado (5/5 capturadas). |
| **Shared PNG Utils (Paso 12)** | `scripts/utils.dart` (28L) | `getPngDimensions()` + `validatePngHeader()` compartidos. Evita duplicacion de PNG parser entre `capture_store_screenshots.dart` y `store_prep_cli.dart`. SRP aplicado: logica PNG en modulo unico. |
| **DebugPrint Migration Verifier (Paso 14)** | `scripts/debugprint_migration_verifier.dart` | CLI: `dart run scripts/debugprint_migration_verifier.dart` ejecuta 3 verificaciones: scanner (0 residuales) + imports flutter/foundation.dart (0 unused) + flutter analyze (0 issues). Confirma migración completa en ~2s. Previene regresión de debugPrint en Release. Reduce verificación manual de ~10min a ~2s. |
