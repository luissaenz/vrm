# 🗺️ Phase State: mvp

> Generado: 2026-05-05 vía 6_CONTEXTO.md

---

## 1. Resumen de Fase

**Fase:** mvp — Publicación del MVP en stores (3-5 semanas estimadas)

**Objetivo:** Que el usuario complete el flujo completo: Idea → Guion → Grabar → Revisar → Unir → Exportar. Persistencia local offline, fallback IA offline sin backend, y preparación para publicación en App Store y Google Play.

**Pasos en orden:**
| # | Paso | Status |
|---|------|--------|
| 01 | Core de Grabación | pending |
| 02 | Interfaz Reactiva y Refinamiento Local | pending |
| 03 | Estabilidad y Pulimento Físico | pending |
| 04 | Puerta de Tiendas y Valla Legal | pending |

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

### ⚠️ Parcialmente implementado

| Componente | Archivo(s) | Qué falta |
|---|---|---|
| **F3 Idea Lab** | `script_studio_page.dart`, `script_fallback_service.dart` | Script generation usa 6 templates hardcodeados en español con `{{idea}}` placeholder. No hay IA real conectada. |
| **F4-F5 Generación IA** | `new_project_page.dart` (L68-226), `backend_script_plugin.dart` | `NewProjectPage` tiene API call comentado (L68-101), usa mock inline de 200 líneas con 8 segmentos hardcodeados. `BackendScriptPlugin` apunta a `localhost:8000` sin servidor. |
| **F11 Exportación** | `lib/core/services/export_service.dart` (L98), `recording_end_page.dart` | `ExportService.saveToGallery()` usa `PhotoManager.editor.saveVideo()` + `Share.shareXFiles()`. NO probado en dispositivo real. Permisos (`Permission.photos`) pueden tener edge cases en iOS 14+ / Android 13+. `RecordingEndPage` muestra métricas hardcodeadas ("42m"). |
| **Tests** | `test/repository_test.dart` (L156), `pipeline_test.dart` (L78), `error_handling_test.dart` (L76) | 3 tests reales: ProjectRepository (save/load/list/delete/search/count con FakePathProvider), Pipeline factory/execution/validation, PipelineException hierarchy. `widget_test.dart` (L30) está roto (referencia counter que no existe). `social_media_test.dart` usa mocks. |

### 🟡 No existe aún / stubbed

| Componente | Archivo(s) | Problema |
|---|---|---|
| **F10 Auto-Stitch** | `lib/core/services/native_stitcher_service.dart` (L52), `lib/core/plugins/default/stitcher_plugin.dart` (L64), `lib/features/recording/pages/stitch_progress_page.dart` (L128) | **ROTO**: `MethodChannel('com.vrm.vrm_app/stitcher')` definido en Dart pero SIN handler nativo en Android (Java/Kotlin) ni iOS (Swift). `stitchVideos()` siempre lanza `MissingPluginException`. UI de progreso y orquestación (RecordingManager.startStitching) están completas. `pubspec.yaml` L71: `# ffmpeg_kit_flutter has been removed`. |
| **Mi Cuenta** | `account_profile_page.dart` | UI shell: email = "Not configured", device ID = "Android Device", member since = "April 2026". Toggles Settings sin onTap. Solo "Clear All Data" funciona (borra vrm_data). "Sign Out" es no-op. |
| **Settings** | `settings_page.dart` | Appearance (theme switcher sin toggle real), Recording (sliders no-op), Teleprompter (sliders no-op), Data & Storage (Cloud Sync toggle no-op). |
| **Perfil Influencer** | `influencer_profile_page.dart` (L631) | Formulario 3-pasos completo pero datos NO persisten. Finalize solo hace `Navigator.pop()`. |
| **Backend IA** | `backend/` (FastAPI), `lib/core/api_service.dart` | Backend FastAPI existe en código (POST `/prompt/{category}/{name}` con OpenAI/Anthropic/Gemini) pero requiere servidor corriendo en `localhost:8000`. Ningún servidor desplegado. |

### ❌ Discrepancias plan vs código

| # | Plan dice | Código real | Impacto |
|---|---|---|---|
| D1 | F8 Grabación: 🔴 50% NO guarda MP4 | ✅ COMPLETE: Escribe MP4 reales con space check + lifecycle | Plan desactualizado ~50% |
| D2 | F9 Revisión: 🔴 40% sin clips reales | ✅ COMPLETE: `VideoPlayerController.file()` con paths reales | Plan desactualizado ~60% |
| D3 | F8 Overlay: ⚠️ 50% botones desconectados | ✅ COMPLETE: 9 botones conectados a CameraService | Plan desactualizado ~50% |
| D4 | Mi Cuenta: ✅ 80% faltan acciones | 🟡 MOCK: Solo UI shells, toggles no-op | Plan sobreestimado ~65% |
| D5 | F12 Dashboard: ✅ 90% falta reemplazar mocks | ✅ COMPLETE: Proyectos reales desde ProjectRepository | Plan desactualizado ~10% |
| D6 | Dependencia ffmpeg_kit_flutter: ^6.0.3 | Eliminado (`pubspec.yaml` L71). NativeStitcherService usa MethodChannel sin impl | Arquitectura cambió, stitch nativo sin implementar |
| D7 | Dependencia sqflite como necesaria | Declarada pero NUNCA importada en ningún .dart | Dependencia muerta |
| D8 | Dependencia path: ^1.8.0 | `path: ^1.9.0` presente | Versión superior, compatible |
| D9 | user_profile.json en disco | Perfil guardado en SharedPreferences, no como JSON file | Diferencia de implementación, funcionalmente equivalente |

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
| **Service singleton/stateful** | `CameraService`, `RecordingManager`, `ExportService` | `lib/features/recording/services/camera_service.dart` |
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
- `sqflite: ^2.3.3+1` — **NO USADA**
- `battery_plus: ^6.1.0` — **NO USADA**

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
- **Plan dice Mi Cuenta 80% → Realidad <20%**: Solo UI shell. Toggles, datos de perfil, persistencia de settings no existen.
- **Plan asume ffmpeg_kit_flutter → Realidad MethodChannel**: Arquitectura de stitch cambió. Plan debe actualizarse.

---

## 5. Registro de Pasos Completados

| Paso | Estado | Archivos Archivados En | Commit | Decisiones Tomadas | Notas |
|---|---|---|---|---|---|
| — | — | — | — | — | Primer paso de fase mvp. IN_PROGRESS vacío. |

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
- [ ] Dependencias muertas (sqflite, battery_plus) removidas antes de release

### NO requerido para MVP
- Retry con backoff — conexiones fallidas muestran error, no reintentan
- Caching avanzado — datos se leen de disco cada vez
- Rate limiting — no aplica (single-user offline)
- Observabilidad — solo debugPrint
- Optimización de performance extrema — aceptable para dispositivo de gama media
- Publicación directa a redes sociales — share sheet nativo es suficiente
- Gamificación / Métricas de desempeño — excluidas del alcance MVP

### Herramientas DX detectadas

| Herramienta | Descripción | Impacto usuario final |
|---|---|---|
| **Validador de pipeline end-to-end** | Script que ejecuta flujo completo en dispositivo real y reporta etapa a etapa ✅/❌ | Detecta MissingPluginException, permisos faltantes y errores filesystem antes de release |
| **Scripts Python existentes** | `scripts/fragmentation_test.py`, `scripts/verify_backend.py` | Útiles para validación backend, pero no cubren frontend |
