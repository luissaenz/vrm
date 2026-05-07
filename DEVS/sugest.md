# 📝 Sugerencias pendientes

## Paso 08 — Migrar-debugPrint-residual-LoggerService

### 🔵 Mejoras
- **M-001:** `debugprint_scanner.dart` no filtra debugPrint bajo `kDebugMode` wrap (memory_monitor.dart:62). Falso positivo en debug-only log. Ignorar lineas dentro de `if (kDebugMode)`.
- **M-002:** 70 debugPrint residuales fuera de scope en lib/. Roadmap post-MVP. Scanner `--fix` puede migrarlos.

> Incorporado desde validacion Paso 08 (2026-05-07).
