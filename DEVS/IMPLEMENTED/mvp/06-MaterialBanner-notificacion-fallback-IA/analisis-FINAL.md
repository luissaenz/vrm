# 🏛️ Análisis Unificado — Paso 06: MaterialBanner-notificacion-fallback-IA

**Generado por:** UNIFICADOR v3.1
**Fecha:** 2026-05-07
**Fase:** mvp
**Estado:** ✅ YA IMPLEMENTADO (NO-OP)

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---:|:---:|:---:|:---:|:---:|
| step | ✅ 10/10 | 1 | ✅ `snackbar_consistency_linter` | ✅ Líneas exactas | 4.5 |
| hy3 | ✅ 8/8 | 1 | ✅ `test_fallback_banner` | ✅ Líneas exactas | 4.0 |
| laguna | ✅ 8/8 | 1 | ✅ `validador_fallback_ia` | ✅ Incluye referencias cruzadas | 4.8 |
| ds | ✅ 10/10 | 2 | ✅ `validador-banners-flutter` | ✅ Código real + phase-state.md | 5.0 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| 1 | Plan dice "reemplazar SnackBar por MaterialBanner" pero código YA tiene MaterialBanner L338-363 | step, hy3, laguna, ds | ✅ `script_studio_page.dart:338-363` | **NO-OP.** Implementado en Paso 05. Código actual es correcto. Plan desactualizado. |
| 2 | Plan referencia L337 como target pero bloque MaterialBanner ocupa L337-363 | ds | ✅ `script_studio_page.dart:337-363` | **AMBIGÜEDAD RESUELTA.** Bloque existe donde plan indica. Coincidencia correcta. |

---

## 1️⃣ Resumen Ejecutivo

- **Objetivo paso 06:** Reemplazar SnackBar flotante por MaterialBanner sticky en fallback IA de ScriptStudio.
- **Estado real:** Código YA implementado en Paso 05 (Correcciones). `script_studio_page.dart:338-363` contiene MaterialBanner naranja con dismiss manual. No existe SnackBar que reemplazar.
- **Corrección crítica al plan:** Plan marca paso como pendiente. Debe marcarse como completado. Sin cambios requiere implementación.
- **Herramienta DX fusionada:** Se adopta `validador-banners-flutter` (ds) fusionado con `snackbar_consistency_linter` (step) → **`vrm_banner_validator`** como CLI único para consistencia de notificaciones.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path

1. Usuario escribe idea en `ScriptStudioPage._buildInputCard()` + selecciona objetivo (conectar/educar/vender)
2. Presiona "GENERAR GUION" → `_handleGenerateScript()` (L324)
3. `ScriptFallbackService.generateAnalysis()` ejecuta generación local offline (L331-332)
4. `viability.summary` = `'Guion generado localmente vía fallback.'` → contiene "localmente"
5. Condición L337: `summary.contains('localmente') || summary.contains('fallback')` → true
6. `ScaffoldMessenger.of(context).showMaterialBanner()` muestra banner sticky naranja L338-363
7. Usuario lee advertencia → presiona "OK" → `hideCurrentMaterialBanner()` (L357-359)
8. Banner descartado → navegación a `RecordingPage` con análisis generado (L366-375)
9. Si error real → catch genérico L376-383 → SnackBar rojo (no afectado)

### Edge Cases MVP

| # | Edge Case | Manejo actual |
|---|---|---|
| EC1 | `summary` no contiene "localmente" ni "fallback" | No se muestra banner. Flujo normal sin advertencia. Correcto. |
| EC2 | Contexto Scaffold destruido antes de dismiss | `if (!mounted) return` (L334) protege. `ScaffoldMessenger` válido mientras `ScriptStudioPage` (Scaffold L38) exista. |
| EC3 | Error real durante generación | Catch genérico L376-383 → SnackBar rojo "Error al generar guion: $e". Separado del banner fallback. |
| EC4 | Backend IA real conectado en futuro | `summary` sin keywords "localmente"/"fallback" → banner no se muestra. Comportamiento correcto por diseño. |

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

| Archivo | Tipo | Descripción | Interfaces clave |
|---|---|---|---|
| `lib/features/assistant/script_studio_page.dart` (L337-363) | **Ya implementado** | MaterialBanner sticky naranja para fallback IA dentro de `_handleGenerateScript()` | `_handleGenerateScript() → Future<void>` |
| `lib/features/assistant/services/script_fallback_service.dart` (L34-63) | **Ya implementado** | `generateAnalysis()` retorna `ScriptAnalysis` con `viability.summary` = texto fallback | `generateAnalysis(String idea, String objective) → Future<ScriptAnalysis>` |
| `lib/features/new_project/models/script_analysis.dart` | **Ya implementado** | Modelo `Viability` con campo `summary` | `Viability.summary: String` |

**Patrón:** `ScaffoldMessenger.showMaterialBanner()` con `leading: Icon(Icons.info_outline)`, `backgroundColor: Colors.orange.shade700`, `actions: [TextButton(hideCurrentMaterialBanner)]`.

### DX & Tooling — Tarea 0

```
### Herramienta: vrm_banner_validator
- **Qué automatiza:** Escanea todos los ScaffoldMessenger.showSnackBar/showMaterialBanner en el proyecto y verifica consistencia de estilos (colores semánticos, acciones de dismiss, mensajes). Sugiere reemplazo de SnackBar por MaterialBanner en contextos de mensajes persistentes.
- **Tipo:** Script Dart CLI
- **Ubicación:** D:\Develop\Personal\vrm\scripts\vrm_banner_validator.dart
- **Cómo se usa:** `dart run scripts/vrm_banner_validator.dart --check` (modo análisis) / `--fix` (aplica reemplazos automáticos en patrones reconocidos)
- **Impacto para el usuario final:** Asegura que todas las notificaciones sigan sistema semántico unificado (rojo=error, naranja=warning, verde=éxito). Previene regresiones donde nuevo desarrollador use SnackBar gris default para mensajes persistentes.
- **El implementador DEBE usarla** para verificar consistencia de notificaciones antes de cerrar el paso y en futuros cambios UI.
```

---

## 4️⃣ Decisiones Tecnológicas

1. **MaterialBanner sobre SnackBar:** MaterialBanner sticky requiere dismiss manual del usuario. Mejor UX para advertencias importantes (fallback IA) porque usuario no pierde notificación por auto-dismiss. Código real ya implementado en Paso 05.
2. **Colors.orange.shade700:** Mantiene semántica de advertencia consistente con otros warnings en la app (integridad de sesión, errores de hardware).
3. **Icons.info_outline blanco:** Icono informativo estándar Material. Contraste sobre fondo naranja.
4. **TextButton "OK" con hideCurrentMaterialBanner():** Acción mínima para descartar. Evita fricción (no requiere leer/confirmar, solo reconocer).
5. **Correcciones al plan:**
   - ⚠️ El plan paso 06 dice "Reemplazar SnackBar por MaterialBanner" pero el código real YA tiene MaterialBanner en `script_studio_page.dart:338-363`. No existe SnackBar que reemplazar. Se implementó en Paso 05. **Acción: marcar paso 06 como completado en plan.md.**

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [DATA] Sin cambios DB — N/A
✅ [CODE] MaterialBanner presente en bloque fallback (script_studio_page.dart:338-363)
✅ [CODE] Banner naranja (Colors.orange.shade700)
✅ [CODE] Icon info_outline blanco
✅ [CODE] Texto "Guion generado localmente (fallback). Conecta el backend para generación IA."
✅ [CODE] Botón OK llama a hideCurrentMaterialBanner()
✅ [CODE] SnackBar error (L378-383) intacto y separado del flujo fallback
✅ [BACKEND] Sin impacto — ScriptFallbackService es 100% local Dart
✅ [FULLSTACK] Banner sticky visible hasta interacción usuario (dismiss manual)
✅ [FULLSTACK] Navegación a RecordingPage funciona tras dismiss del banner
✅ [DX] vrm_banner_validator ejecuta sin errores y detecta inconsistencias de notificaciones
```

**Funcionales:**
- [ ] Fallback IA muestra MaterialBanner naranja sticky (no SnackBar auto-dismiss)
- [ ] Usuario descarta banner manualmente → navegación a RecordingPage funciona
- [ ] Error real de generación muestra SnackBar rojo separado

**Técnicos:**
- [ ] 0 showSnackBar para fallback (solo catch genérico L378)
- [ ] MaterialBanner usa ScaffoldMessenger.of(context) con contexto válido (Scaffold L38)
- [ ] `flutter analyze` pasa sin errores

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** `vrm_banner_validator` — escanea y verifica consistencia de notificaciones del proyecto | Media | 0.5h | Ninguna |
| 1 | **Verificar implementación existente:** Confirmar MaterialBanner en `script_studio_page.dart:338-363` | Baja | 0h | Tarea 0 |
| 2 | **Actualizar plan.md:** Marcar paso 06 como completado | Baja | 0.1h | Tarea 1 |
| **TOTAL** | | | **0.6h** | |

> **Nota:** Paso 06 ya implementado en código (Paso 05). Tareas son verificación + DX tooling + actualización de plan.

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Regresión: SnackBar reintroducido en futuro refactor | Baja | Desarrollador futuro desconoce que MaterialBanner es requisito UX para fallback sticky | Documentar L337-363 con comentario. Usar vrm_banner_validator en CI. |
| Contraste naranja/blanco insuficiente WCAG AA | Baja | `orange.shade700` sobre blanco puede no cumplir 4.5:1 | Probar con contrast checker. Si falla, usar `orange.shade800`. |
| MaterialBanner no funciona si Scaffold no es ancestro | Baja | `_handleGenerateScript()` llamado sin contexto Scaffold (ej: desde diálogo modal) | Verificar ScriptStudioPage = Scaffold L38. Contexto siempre disponible. |
| Dependencia futura: backend IA real no usa keywords en summary | Media | Backend real podría no contener "localmente" ni "fallback" en summary | Comportamiento correcto: banner solo se muestra en fallback. Sin keywords → sin banner. |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|---|---|---|---|
| TP-1 | Fallback IA muestra MaterialBanner | `summary = 'Guion generado localmente vía fallback.'` → contiene "localmente" | `showMaterialBanner()` invocado con banner naranja sticky (L338-363) |
| TP-2 | Error real NO muestra MaterialBanner (usa SnackBar) | Excepción lanzada durante generación | Catch genérico L376 → `showSnackBar()` rojo. No hay banner. |
| TP-3 | Dismiss manual funciona | Usuario presiona "OK" en banner | `hideCurrentMaterialBanner()` ejecutado. Banner desaparece. Navegación a RecordingPage ocurre. |
| TP-4 | Sin keywords no hay banner | `summary = 'Análisis completado exitosamente.'` (sin "localmente"/"fallback") | Condición L337 false. No se invoca `showMaterialBanner()`. Flujo normal continúa. |

Comando: `flutter test`
