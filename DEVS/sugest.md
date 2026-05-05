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
