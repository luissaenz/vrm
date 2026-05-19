# 🏛️ Arquitectura y Estructura — VRM Atomic Camera

> Generado por SETUP v3.2. Fuente: código real en `D:\Develop\Personal\vrm`. Nada inventado.
> **Carga condicional:** cuando el paso crea módulos, modifica capas o altera estructura de carpetas.

## Patrón de Capas

- **Flujo:** `main.dart` → `features/{feature}/pages/` → `features/{feature}/services/` → `core/models/` + `core/persistence/` → Filesystem JSON
  - **Evidencia:** `lib/main.dart:27-60` (VRMApp StatefulWidget con onGenerateRoute), `lib/features/recording/recording_page.dart`, `lib/core/data/project_repository.dart:187`
- **Restricciones:**
  - Pages acceden a Services y Models (nunca a filesystem directamente)
  - Services acceden a Models, Repository y filesystem vía `path_provider`
  - Models son POJOs con `fromJson`/`toJson` (sin lógica de negocio)
  - Pipeline (`lib/core/pipeline/`) orquesta stages (fetchIdea → process → enhance)

## Estructura de Módulos

- **Patrón:** Feature-based directories. Cada feature autocontenida con `{pages, services, models, widgets}/`.
  ```
  lib/
  ├── core/             → modelos, excepciones, servicios, schemas, pipeline
  │   ├── data/         → repositories (ProjectRepository, OnboardingRepository)
  │   ├── exceptions/   → jerarquía VRMException
  │   ├── models/       → ProjectState, InputSchema, ScriptBundle, etc.
  │   ├── persistence/  → JSON file I/O
  │   ├── pipeline/     → VRMPipeline, PipelineFactory
  │   ├── plugins/      → TemplateScriptPlugin, BackendScriptPlugin, StitcherPlugin
  │   ├── schemas/      → validadores JSON schema
  │   ├── services/     → LoggerService, ExportService, NativeStitcherService
  │   ├── theme/        → AppTheme (light + dark)
  │   └── utils/        → helpers
  ├── data/
  │   └── repositories/ → repos adicionales
  ├── features/
  │   ├── account/      → AccountProfilePage
  │   ├── assistant/    → ScriptStudioPage + fallback service
  │   ├── dashboard/    → DashboardPage
  │   ├── export/       → RecordingEndPage (overlay exportación)
  │   ├── influencer_profile/ → InfluencerProfilePage
  │   ├── new_project/  → NewProjectPage + models
  │   ├── onboarding/   → OnboardingFlow (3 steps)
  │   ├── preparation/  → PreparationPage (TTS + voice)
  │   ├── recording/    → RecordingPage, ClipReviewPage, StitchProgressPage, CameraService, RecordingManager
  │   ├── settings/     → SettingsPage + SettingsService
  │   └── social_accounts/ → SocialAccountManager
  ├── l10n/             → localización (AppLocalizations)
  ├── shared/
  │   ├── utils/        → helpers compartidos
  │   └── widgets/      → widgets reutilizables
  └── main.dart         → entry point + VRMApp + onGenerateRoute
  ```

- **Nuevos módulos van en:** `lib/features/{feature_name}/` siguiendo la estructura `pages/`, `services/`, `models/`, `widgets/` según necesidad.
- **Scripts DX:** `scripts/` — archivos `.dart` independientes ejecutables con `dart run`, sin dependencias externas.

## Restricciones de Arquitectura Detectadas

- Sin autenticación MVP (offline single-user) — no hay middleware, no hay RLS, no hay login
- Persistencia exclusivamente en filesystem JSON (sin SQLite, sin backend). Ruta: `{appDocuments}/vrm_data/projects/{id}/`
- MethodChannel para stitch de video nativo: `com.vrm.vrm_app/stitcher` con handlers en `MainActivity.kt` (Android/MediaMuxer) y `AppDelegate.swift` (iOS/AVComposition)
- Servicios críticos usan patrón singleton (`CameraService`, `RecordingManager`, `LoggerService`, `MemoryMonitor`, `ExportService`, `SettingsService`, `DeviceInfoService`)
- Theme global gestionado por `VRMApp` StatefulWidget cargando desde `SettingsService` en `initState`

## Patrones de Integración

- **Entre servicios:** Dependencia directa vía instanciación o singleton (sin DI container)
- **Con filesystem:** `path_provider` para rutas, `dart:io` para I/O de archivos, `shared_preferences` para settings key-value
- **Con nativo (Android/iOS):** `MethodChannel` único (`com.vrm.vrm_app/stitcher`) para stitch de video
- **Con externos:** `http: ^1.2.1` para llamadas al backend IA (localhost:8000). `backend/` (FastAPI + Python) como servidor de IA (no desplegado).

## ⚠️ No detectado

- DI / service locator — no hay inyección de dependencias formal. Servicios se instancian directamente o usan singletons.
- Route guards / middleware de navegación — no hay protección de rutas (MVP offline no lo requiere)
- Backend desplegado — código FastAPI existe en `backend/` pero sin servidor corriendo
