# Sugerencias Post-Validación — Paso 03

## Issues 🟡 Importantes

- **ID-001:** SessionIntegrityException en startRecording() capturado genéricamente — `recording_page.dart` catch L535-548 no específico. Agregar `on SessionIntegrityException catch (e)` con SnackBar naranja.
- **ID-002:** Dogfooding no verificable en git history. Invocar `vrm_health_check.dart` por tarea en commits futuros.
- **ID-003:** MemoryMonitor._takeSample() no mide heap real (`heapUsageBytes=0`). Post-MVP: integrar `dart:developer` para muestreo real.

## Issues 🔵 Mejoras

- **ID-004:** Notificación fallback IA usa SnackBar → reemplazar con `MaterialBanner` widget sticky (`script_studio_page.dart:337`).
- **ID-005:** Métricas hardcodeadas "42m" en RecordingEndPage (`recording_end_page.dart:309`). Conectar a datos reales de sesión.
- **ID-006:** `debugPrint` residual en `RecordingPage._applyHardwareSettings()` (`recording_page.dart:657,662`). Migrar a LoggerService.
- **ID-007:** `vrm_health_check.dart --fix` solo imprime advertencia, no ejecuta cleanup real (`vrm_health_check.dart:120-122`).

---

# Sugerencias Post-Validación — Paso 04

## Issues 🟡 Importantes

- ~~**ID-008:** Dogfooding parcial.~~ ✅ RESUELTO en correccion. `store_prep_cli.dart` usado para regenerar keystore + fix keytool PATH discovery + check post-correccion.

## Issues 🔵 Mejoras

- ~~**ID-009:** Comentario SUPUESTO URL placeholder.~~ ✅ RESUELTO. URL actualizada a raw.githubusercontent.com + comentario removido.
- **ID-010:** Adaptive icons Android 13+ (`adaptive_icon_background`, `adaptive_icon_foreground`) opcionales. Configurar en pubspec.yaml post-MVP.
- **ID-011:** `widget_test.dart` test pre-existing roto (referencia counter widget inexistente). Eliminar o arreglar.
- **VAL-003 (ESCALADO):** Screenshots 1024x1024 requieren recaptura manual en dispositivo real a 1080x1920+ (Android) / 1284x2778+ (iOS). Usar `adb shell screencap -p`. No automatizable por codigo.
