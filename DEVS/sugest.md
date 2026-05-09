# 📝 Sugerencias pendientes

## 🟡 Importantes

- **ID-002:** Especificación analisis-FINAL §3 pide funciones privadas (`_isSameLineKDebugModeGuard`) en `debugprint_scanner.dart`. Implementación las hizo públicas en `debugprint_detector.dart`. Desvío de diseño acordado. Corrección: renombrar a privadas o actualizar especificación para reflejar módulo separado.

## 🔵 Mejoras

- **ID-003:** `debugprint_scanner.dart --fix` no maneja `debugPrint()` multilínea (arg en línea siguiente). 7 calls residuales no migrables automáticamente. Considerar parser multi-línea o AST-based.

> Las sugerencias anteriores fueron incorporadas a `plan.md` el 2026-05-09.
> Fase procesada: mvp
