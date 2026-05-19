# ✅ Calidad Mínima Exigible — VRM Atomic Camera

> Generado por SETUP v3.2. Fuente: código real en `D:\Develop\Personal\vrm`. Nada inventado.
> **Carga:** obligatoria en todos los agentes del pipeline.

## §7 Estándares Mínimos

Todo código nuevo debe cumplir estos criterios para ser aceptado por el Validador:

- [ ] Linter pasa sin errores: `flutter analyze` (0 issues)
- [ ] Tests unitarios pasan: `flutter test` (todos pasan)
- [ ] Sin imports no usados (verificado por flutter analyze)
- [ ] Sin `debugPrint` sin guard en código de producción — migrar a `LoggerService.log()` (evidencia: recording_page.dart:L288-290)
- [ ] Sin stubs (`pass` como implementación, `TODO` sin referencia a plan)
- [ ] Error handling presente en happy path (try/except con feedback al usuario vía SnackBar/MaterialBanner)
- [ ] Naming sigue convenciones de `style.md`
- [ ] Nuevos archivos usan snake_case (evidencia: todo lib/ y scripts/)
- [ ] Scripts DX usan Dart puro (dart:io + dart:core) sin dependencias externas (evidencia: scripts/debugprint_scanner.dart, scripts/vrm_health_check.dart)

## Error Handling

- **Patrón:** Jerarquía de excepciones `VRMException` → subclases específicas (`CameraHardwareException`, `StorageFullException`, `VideoProcessingException`, `SessionIntegrityException`) con `message`, `code`, `originalError`. Try/catch con `LoggerService.log()` + feedback UI vía SnackBar/MaterialBanner.
  - **Evidencia:** `lib/core/exceptions/vrm_exceptions.dart:2-47`, `lib/features/recording/recording_page.dart:541-683`
- **Flujo ante error:** Capturar excepción específica → loguear vía `LoggerService.log(tag, msg, error: e)` → mostrar SnackBar al usuario → resetear estado a idle
- **Errores de validación:** `lib/core/schemas/` usa `json_schema: ^5.2.2` para validación de JSON schemas
- **NUNCA:** `except Exception` sin log, swallow silencioso de errores de cámara

## Testing

- **Framework:** `flutter test` (paquete `flutter_test`)
- **Estrategia:** Unitarios (modelos, repositorios, pipeline, detector) + Widget tests (VRMApp rendering)
- **Convención de archivos:** `{name}_test.dart` en `test/` (evidencia: `test/repository_test.dart`, `test/widget_test.dart`)
- **Fixtures:** Datos inline en tests (sin factories externos ni mocks complejos). `FakePathProvider` para tests de filesystem.
- **NO se testea:** E2E en dispositivo real, performance, integración con hardware cámara

## Logging

- **Librería:** `LoggerService` (singleton propio) — `lib/core/services/logger_service.dart:10-53`
- **Niveles:** No explícitos. Todo log va a archivo con timestamp ISO 8601 + tag + mensaje + error/stack opcionales.
- **Formato:** Texto plano con timestamp: `[timestamp] [TAG] message`
- **Rotación:** Automática a 512KB (`_maxFileSize`), renombra a `app.old.log`
- **Destino:** `{getApplicationDocumentsDirectory()}/vrm_data/logs/app.log`
- **NUNCA loguear:** datos sensibles, passwords, tokens

## Dependencias

- **Política de versiones:** Caret ranges (`^X.Y.Z`) en pubspec.yaml. No versiones pinned.
- **NO agregar sin justificación:** Dependencias que duplican funcionalidad existente (ej: nueva lib de logging cuando LoggerService ya existe)
- **Prohibidas:** `sqflite` (removida en Paso 03), `battery_plus` (removida en Paso 03), `ffmpeg_kit_flutter` (removida — reemplazada por MethodChannel nativo)
- **Scripts DX:** Dart puro sin dependencias externas (`dart:io` + `dart:core` únicamente). No usar `package:` imports en scripts/.

## ⚠️ No detectado

- Cobertura mínima de tests — no hay threshold definido ni tool de coverage configurado (aunque `test_coverage_report.dart` existe como DX tool)
- CI/CD pipeline — no hay GitHub Actions ni similar detectado
