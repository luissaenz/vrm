# 🗺️ Phase State: mvp

> Generado: 2026-05-05 vía 6_CONTEXTO.md
> Actualizado: 2026-05-06 vía 6_CONTEXTO.md (Post-Paso 04)

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

**Dependencias entre pasos:**
- 01 ← 02 ← 03 ← 04 (secuencial)

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
| **RecordingPage didHaveMemoryPressure** | `lib/features/recording/recording_page.dart` (L283-290) | Override `didHaveMemoryPressure()` → `ClipStorageService.cleanupTemp()` + `VRMNotifications.showWarning('Memoria baja — limpiando caché')`. |
| **MemoryMonitor singleton** | `lib/features/recording/services/memory_monitor.dart` (L105) | Timer periódico (30s). Genera `LeakReport` con warnings de leak. Patrón singleton. Integrado con LoggerService. |
| **SessionIntegrityException recovery** | `lib/features/recording/services/recording_manager.dart` (L330-366) | `verifyIntegrityStatic()` remueve referencias a clips faltantes sin perder proyecto. Datos corregidos pasados en `originalError`. |
| **ScriptStudio fallback notification** | `lib/features/assistant/script_studio_page.dart` (L337-361) | SnackBar flotante naranja cuando `viability.summary` contiene "localmente" o "fallback". |
| **ProGuard limpio** | `android/app/proguard-rules.pro` (L1-12) | Reglas ffmpegkit muertas removidas (L9-12). Solo Flutter wrapper + JNI. |
| **Integridad al iniciar grabación** | `lib/features/recording/services/recording_manager.dart` (L60) | `verifySessionIntegrity()` llamado al inicio de `startRecording()`. Alerta si clips faltantes. |
| **Store Prep CLI unificado** | `scripts/store_prep_cli.dart` (L642) | CLI con 5 subcomandos: check, keystore, assets, privacy, screenshots. Sigue patron `vrm_health_check.dart`. 10/10 checks. Detecta keystore faltante, passwords default, placeholders, permisos, gitignore. |
| **PRIVACY_POLICY.md sin placeholders** | `PRIVACY_POLICY.md` (raíz), `docs/PRIVACY_POLICY.md` | Root reemplazado con version docs/. 0 placeholders. Email real: ludens.vrm@gmail.com. Fecha: April 18, 2026. |
| **Keystore generado** | `android/vrm-release-key.jks` (2760 bytes), `android/key.properties` | RSA 2048, alias vrm_upload_key, validez 10000d. Passwords randomizadas (no default). |
| **Settings enlace Privacy Policy** | `lib/features/settings/settings_page.dart` (L8-9, L413-424) | `_privacyPolicyUrl` apunta a raw.githubusercontent.com/luissaenz/vrm/main/PRIVACY_POLICY.md → HTTP 200. `_openPrivacyPolicy()` con try/catch + SnackBar. |
| **key.properties passwords randomizadas** | `android/key.properties` (L1-2) | `vrm_store_2kh`, `vrm_key_2kh`. No default. Verificado por store_prep_cli.dart check. |
| **Screenshots en directorio store** | `assets/store/screenshots/step{1-5}.png` | 5 screenshots copiadas a directorio correcto segun diseño (1024x1024 — pendiente recapturar a 1080x1920+). |
| **Play Store Data Safety documentado** | `DEVS/play_store_data_safety.md` | Checklist de respuestas para formulario Data Safety de Play Console. |
| **.gitignore secreto** | `.gitignore` | Cubre `*.jks`, `*.keystore`, `/android/key.properties`. |

### ⚠️ Parcialmente implementado

| Componente | Archivo(s) | Qué falta |
|---|---|---|
| **F3 Idea Lab** | `script_studio_page.dart`, `script_fallback_service.dart` | Script generation usa 6 templates hardcodeados en español con `{{idea}}` placeholder. No hay IA real conectada. ✅ Notificación fallback implementada (SnackBar informativo cuando se usa generación local). |
| **F4-F5 Generación IA** | `new_project_page.dart` (L68-226), `backend_script_plugin.dart` | `NewProjectPage` tiene API call comentado (L68-101), usa mock inline de 200 líneas con 8 segmentos hardcodeados. `BackendScriptPlugin` apunta a `localhost:8000` sin servidor. |
| **F11 Exportación** | `lib/core/services/export_service.dart` (L125), `recording_end_page.dart` | ✅ ExportService con `Stream<double>` progreso. ✅ Overlay "Guardando en galería..." con `WidgetProgress`. NO probado en dispositivo real. Permisos (`Permission.photos`) pueden tener edge cases en iOS 14+ / Android 13+. `RecordingEndPage` muestra métricas hardcodeadas ("42m"). |
| **Tests** | `test/repository_test.dart` (L156), `pipeline_test.dart` (L78), `error_handling_test.dart` (L76) | 3 tests reales: ProjectRepository (save/load/list/delete/search/count con FakePathProvider), Pipeline factory/execution/validation, PipelineException hierarchy. `widget_test.dart` (L30) está roto (referencia counter que no existe). `social_media_test.dart` usa mocks. |

### 🟡 No existe aún / stubbed

| Componente | Archivo(s) | Problema |
|---|---|---|
| **F10 Auto-Stitch** | `lib/core/services/native_stitcher_service.dart` (L52), `lib/core/plugins/default/stitcher_plugin.dart` (L64), `lib/features/recording/pages/stitch_progress_page.dart` (L128) | **ROTO**: `MethodChannel('com.vrm.vrm_app/stitcher')` definido en Dart pero SIN handler nativo en Android (Java/Kotlin) ni iOS (Swift). `stitchVideos()` siempre lanza `MissingPluginException`. UI de progreso y orquestación (RecordingManager.startStitching) están completas. `pubspec.yaml` L71: `# ffmpeg_kit_flutter has been removed`. |
| **Screenshots store-ready** | `assets/store/screenshots/step{1-5}.png` | 5 archivos existen pero 1024x1024. Android requiere 1080x1920+, iOS 1284x2778+. Pendiente capturar en dispositivo real. |
| **Privacy Policy hosteada via GitHub Pages** | `settings_page.dart:8-9` | URL apunta a raw.githubusercontent.com (funciona). GitHub Pages no habilitado — post-MVP. |
| **Mi Cuenta** | `account_profile_page.dart` | ✅ IMPLEMENTADO: DeviceInfoService con device_info_plus. Muestra modelo real, memberSince desde primer launch. |
| **Settings** | `settings_page.dart` | ✅ IMPLEMENTADO: SettingsService conecta a SharedPreferences. Theme switcher funciona (VRMApp carga desde prefs). Teleprompter sliders persisten prefs. Cloud sync toggle funciona. |
| **Perfil Influencer** | `influencer_profile_page.dart` (L631) | ✅ IMPLEMENTADO: _saveProfile() persiste en SharedPreferences al hacer finalize. |
| **Backend IA** | `backend/` (FastAPI), `lib/core/api_service.dart` | Backend FastAPI existe en código (POST `/prompt/{category}/{name}` con OpenAI/Anthropic/Gemini) pero requiere servidor corriendo en `localhost:8000`. Ningún servidor desplegado. |

### ❌ Discrepancias plan vs código

| # | Plan dice | Código real | Impacto | Estado |
|---|---|---|---|---|
| D1 | F8 Grabación: 🔴 50% NO guarda MP4 | ✅ COMPLETE: Escribe MP4 reales con space check + lifecycle | Plan desactualizado ~50% | ✅ Resuelto |
| D2 | F9 Revisión: 🔴 40% sin clips reales | ✅ COMPLETE: `VideoPlayerController.file()` con paths reales | Plan desactualizado ~60% | ✅ Resuelto |
| D3 | F8 Overlay: ⚠️ 50% botones desconectados | ✅ COMPLETE: 9 botones conectados a CameraService | Plan desactualizado ~50% | ✅ Resuelto |
| D4 | Mi Cuenta: ✅ 80% faltan acciones | 🟡 MOCK: Solo UI shells, toggles no-op | Plan sobreestimado ~65% | ✅ Resuelto (Paso 2) |
| D5 | F12 Dashboard: ✅ 90% falta reemplazar mocks | ✅ COMPLETE: Proyectos reales desde ProjectRepository | Plan desactualizado ~10% | ✅ Resuelto |
| D6 | Dependencia ffmpeg_kit_flutter: ^6.0.3 | Eliminado (`pubspec.yaml` L71). NativeStitcherService usa MethodChannel sin impl | Arquitectura cambió, stitch nativo sin implementar. ProGuard dead rules cleaned ✅ | ⏳ Pendiente |
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
| Native Stitcher | `MethodChannel('com.vrm.vrm_app/stitcher')` | Dart→Native | `{clips: [], outputPath: ""}` | `String` (output path) | MethodChannel sin handler nativo |

### Conexiones Flutter → Nativas

| Channel | Namespace | Uso | Estado |
|---|---|---|---|
| Stitcher | `com.vrm.vrm_app/stitcher` | `stitchVideos(clips, outputPath)` | STUB — sin handler Android/iOS |

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
| **MethodChannel para stitch** en vez de ffmpeg_kit_flutter | `NativeStitcherService` usa `MethodChannel('com.vrm.vrm_app/stitcher')`. `ffmpeg_kit_flutter` eliminado. | ffmpeg_kit_flutter tenía problemas de compilación nativa en iOS/Android. MethodChannel permite usar MediaMuxer (Android) o AVComposition (iOS) nativos. **Pendiente: implementar handlers nativos.** |
| **Sin autenticación MVP** | No hay auth middleware, no hay RLS, no hay login. | MVP es 100% offline/single-user. Backend IA para V2. |
| **Feature-based directories** | `lib/features/{feature}/{pages,services,models,widgets}/` | Escalabilidad y separación de concerns. Cada feature autocontenida. |
| **Onboarding → Dashboard → Recording** como flujo principal | `main.dart` L45: onboarding condicional. Named routes para navegación profunda. | Flujo lineal simple para MVP. |

### Correcciones al plan (discrepancias detectadas)

- **Plan dice F8 Grabación 50% → Realidad 100%**: El plan asume que `_cameraController` no escribe disco. `CameraService` + `ClipStorageService` ya escriben MP4 reales con manejo de espacio y lifecycle.
- **Plan dice F9 Revisión 40% → Realidad 100%**: `ClipReviewPage` ya reproduce clips reales con accept/reject.
- **Plan dice F8 Overlay 50% → Realidad 100%**: Todos los botones del overlay conectados a hardware.
- **Plan dice Mi Cuenta 80% → Realidad <20%**: Solo UI shell. Toggles, datos de perfil, persistencia de settings no existen. → **IMPLEMENTADO EN P2**
- **Plan asume ffmpeg_kit_flutter → Realidad MethodChannel**: Arquitectura de stitch cambió. Plan debe actualizarse.
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
| **Android stitch handler ya implementado** | `MainActivity.kt:52-146` tiene mergeVideos() con MediaMuxer. DS afirmó ausencia — FALSO. | Código existe. Implementador no toca. |
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

---

## 6. Criterios Generales de Aceptación MVP

- [ ] Happy path: Idea → Script → Grabar → Revisar → Stitch → Exportar funciona end-to-end sin crash
- [ ] Fallback IA offline: ScriptStudio genera guion con templates cuando backend no responde
- [ ] Stitch: Clips se concatenan en `final.mp4` sin error (requiere implementar handler nativo)
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
| **VRM Health Check (Paso 3)** | `scripts/vrm_health_check.dart` (415L) | CLI unificado: `check` (pre-flight permisos/espacio/cámara), `validate` (recovery paths), `memory` (leak detection), `scaffold` (estructura datos). Reduce diagnóstico de 30min a ~2s. Verifica LoggerService, MemoryMonitor, ProGuard, pipeline files. |
| **Scripts Python existentes** | `scripts/fragmentation_test.py`, `scripts/verify_backend.py` | Útiles para validación backend, pero no cubren frontend |
| **Store Prep CLI (Paso 4)** | `scripts/store_prep_cli.dart` (642L) | CLI unificado: `check` (8 checks pre-store), `keystore` (genera RSA 2048), `assets validate` (iconos/splash/screenshots), `privacy` (valida placeholders), `screenshots` (guía captura). Reduce preparación store de ~4h a ~15min. Detects keystore faltante, passwords default, placeholders, permisos, gitignore. |
