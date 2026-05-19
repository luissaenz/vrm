# 🎨 Estilo y Convenciones — VRM Atomic Camera

> Generado por SETUP v3.2. Fuente: código real en `D:\Develop\Personal\vrm`. Nada inventado.
> **Carga condicional:** cuando el paso crea archivos nuevos o define naming de componentes.

## Naming

- **Dart (variables/funciones):** camelCase — evidencia: `lib/main.dart:44` (`_loadThemeMode`), `lib/core/models/project_state.dart:23` (`fromJson`)
- **Dart (clases):** PascalCase — evidencia: `lib/core/models/project_state.dart:6` (`class ProjectState`), `lib/core/exceptions/vrm_exceptions.dart:2` (`class VRMException`)
- **Dart (constantes):** camelCase (no SCREAMING_SNAKE) — evidencia: `lib/core/services/logger_service.dart:11-13`
- **Archivos Dart:** snake_case — evidencia: `project_state.dart`, `camera_service.dart`, `logger_service.dart`
- **Archivos Python (backend):** snake_case — evidencia: `backend/main.py`, `backend/app/ai_service.py`
- **Funciones Python (backend):** snake_case — evidencia: `backend/main.py`
- **Directorios:** snake_case (Dart), lowercase sin guiones — evidencia: `lib/features/recording/`, `lib/core/models/`
- **Endpoints (FastAPI):** kebab-case con parámetros — evidencia: `backend/main.py :: POST /prompt/{category}/{name}`
- **Tablas DB:** No aplica (sin SQL)

## Imports

- **Estilo:** Absolutos con prefijo `package:vrm_app/...` — evidencia: `lib/main.dart:3-12`
- **Orden convencional:**
  1. `dart:*` (stdlib)
  2. `package:flutter/*` (Flutter SDK)
  3. `package:*` (third-party)
  4. `package:vrm_app/*` (locales)
  - **Evidencia:** `lib/main.dart:1-12`
- **Barrel files:** No se usan. Cada archivo importa directamente lo que necesita.
- **Scripts DX:** `import 'dart:io';` + `import 'dart:convert';` únicamente. Sin imports de `package:`.

## Formato

- **Formatter:** `flutter format .` (dart_style) — `proyecto-config.json → commands.lint_fix`
- **Longitud máxima de línea:** 80 caracteres (default de dart_style)
- **Comillas:** Simples para strings (preferencia observada en código), dobles para interpolación
- **Trailing commas:** Sí, en listas y maps multilínea — evidencia: `lib/core/models/project_state.dart:37-41`

## Estructura de Archivos Nuevos

Para cada tipo de archivo, el patrón a seguir:

| Tipo | Copiar patrón de | Convención de nombre |
|---|---|---|
| Página/Widget Flutter | `lib/features/recording/recording_page.dart` | `{feature}_page.dart` o `{feature}_flow.dart` |
| Service | `lib/features/recording/services/camera_service.dart` | `{feature}_service.dart` |
| Model / Schema | `lib/core/models/project_state.dart` | `{entity}.dart` (snake_case) |
| Excepción | `lib/core/exceptions/vrm_exceptions.dart` | Agregar subclase en archivo existente |
| Repositorio | `lib/core/data/project_repository.dart` | `{entity}_repository.dart` |
| Plugin de Pipeline | `lib/core/plugins/default/stitcher_plugin.dart` | `{feature}_plugin.dart` |
| Script DX | `scripts/vrm_health_check.dart` | `{funcionalidad}.dart` |
| Test unitario | `test/repository_test.dart` | `{archivo_base}_test.dart` |
| Widget test | `test/widget_test.dart` | `widget_test.dart` |

## Convenciones Específicas Dart/Flutter

- **StatefulWidget:** Usar cuando se necesita `setState` o `initState` con async. StatelessWidget para UI pura.
- **Rutas:** `onGenerateRoute` en `main.dart:87-119` con named routes (`/dashboard`, `/recording`, `/stitch-progress`, `/recording-end`).
- **Tema:** `AppTheme.lightTheme` + `AppTheme.darkTheme` en `lib/core/theme.dart`. Usar `Theme.of(context)` en widgets.
- **Localización:** `AppLocalizations.of(context)!` para strings traducibles. Archivos `.arb` en `lib/l10n/`.
- **LoggerService:** `LoggerService.log('ClassName', 'message', error: e)` — tag = PascalCase, nombre de clase.
- **debugPrint:** Solo permitido dentro de `if (kDebugMode)` o `assert()`. Migrar todo lo demás a `LoggerService.log()`.

## Convenciones Específicas Python/Backend

- **FastAPI:** Decoradores `@app.post("/prompt/{category}/{name}")` con Pydantic models para request/response
- **AI Service:** `backend/app/ai_service.py` — wrapper de OpenAI/Anthropic/Gemini
- **Prompts:** Templates en `backend/prompts/data/`, schemas en `backend/prompts/schemas/`, tareas en `backend/prompts/tasks/`
- **Variables de entorno:** `os.getenv("KEY")` desde `.env` cargado con `python-dotenv`

## ⚠️ No detectado

- Preferencia de comillas (simples vs dobles) — código usa ambas. No hay regla de linter que lo imponga.
- `analysis_options.yaml` — reglas de linter específicas no documentadas aquí (usar `flutter_lints: ^6.0.0` por defecto)
