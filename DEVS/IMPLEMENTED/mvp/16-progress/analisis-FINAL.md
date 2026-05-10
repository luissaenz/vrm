# 🔍 ANÁLISIS — Paso 16: Correccion-desvio-debugprint-detector

> **Agente:** opus
> **Fecha:** 2026-05-09
> **Fase:** mvp
> **Origen:** Sugerencia 🟡 de validación — Paso ID-002

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `debugprint_detector.dart` existe | ls `scripts/` | ✅ | `scripts/debugprint_detector.dart` (165L, 4223 bytes) |
| 2 | `debugprint_scanner.dart` existe | ls `scripts/` | ✅ | `scripts/debugprint_scanner.dart` (319L, 8322 bytes) |
| 3 | `isSameLineKDebugModeGuard` es **pública** en detector | cat detector L25 | ✅ | `bool isSameLineKDebugModeGuard(String line)` — sin `_` prefijo |
| 4 | `isInsideAssert` es **pública** en detector | cat detector L35 | ✅ | `bool isInsideAssert(String line)` — sin `_` prefijo |
| 5 | `isTernaryKDebugModeGuard` es **pública** en detector | cat detector L61 | ✅ | `bool isTernaryKDebugModeGuard(String line)` — sin `_` prefijo |
| 6 | `isAdjacentKDebugModeGuard` es **pública** en detector | cat detector L67 | ✅ | `bool isAdjacentKDebugModeGuard(List<String>, int)` — sin `_` prefijo |
| 7 | `isInsideBracedDebugModeBlock` es **pública** en detector | cat detector L76 | ✅ | `bool isInsideBracedDebugModeBlock(List<String>, int)` — sin `_` prefijo |
| 8 | `isInsideDebugModeBlock` orquestador **público** en detector | cat detector L13 | ✅ | `bool isInsideDebugModeBlock(List<String>, int)` — sin `_` prefijo |
| 9 | `stripStringsAndComments` es **pública** en detector | cat detector L101 | ✅ | `String stripStringsAndComments(String line)` — sin `_` prefijo |
| 10 | Scanner tiene wrappers `_` privados | cat scanner L159-165 | ✅ | `_isInsideDebugModeBlock`, `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock` — 4 wrappers delegando a detector |
| 11 | Scanner usa `_isInsideDebugModeBlock` internamente | cat scanner L139, L204 | ✅ | L139: `_isInsideDebugModeBlock(lines, lineIdx)` en `_findDebugPrintCalls`. L204: mismo en `_fixDebugPrintCalls` |
| 12 | Test importa detector directamente (no scanner) | cat test L3 | ✅ | `import '../scripts/debugprint_detector.dart';` — testea API pública del detector |
| 13 | analisis-FINAL §3 pide funciones `_` privadas | cat FINAL L84-94 | ✅ | §3 dice: `_isInsideDebugModeBlock`, `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock` — todas con prefijo `_` |
| 14 | analisis-FINAL §3 dice "Funciones privadas `_` ya existentes en `scripts/`" como patrón | cat FINAL L95 | ✅ | "Patrones a seguir: Funciones privadas `_` ya existentes. Mismo patrón que `_deriveTag`, `_printResults`." |
| 15 | Validación Paso 13 ID-002 documenta desvío | cat validacion L72 | ✅ | "Especificación FINAL §3 pide funciones privadas en `debugprint_scanner.dart`. Implementación las hizo públicas en módulo separado `debugprint_detector.dart`. Desvío del diseño acordado." |
| 16 | Test pasa 31 tests (31 calls a `expect`) | cat test completo | ✅ | 31 `expect()` calls en 8 grupos. `flutter test` 52/52 total |
| 17 | Scanner tiene 2 wrappers **no usados** | cat scanner L162-165 | ⚠️ | `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock` — 3 wrappers **nunca invocados** en scanner. Solo `_isInsideDebugModeBlock` se usa (L139, L204). `// ignore_for_file: unused_element` en L1 suprime warning |
| 18 | `// ignore_for_file: avoid_print, unused_element` | cat scanner L1 | ✅ | Doble ignore: `avoid_print` (legítimo — CLI) + `unused_element` (suprime warnings de wrappers no usados) |

**Discrepancias encontradas:**

| # | Discrepancia | Resolución propuesta |
|---|---|---|
| D1 | FINAL §3 pide `_` privadas en scanner. Impl tiene 7 fn públicas en detector + 4 wrappers `_` en scanner. Desvío arquitectónico. | **Opción A (recomendada):** Actualizar analisis-FINAL §3 para reflejar decisión real: detector público + wrappers privados. Razón: testabilidad > pureza de spec. **Opción B:** Renombrar a `_` en detector (rompe test que importa detector). |
| D2 | 3 wrappers `_` en scanner (L162-165) **nunca se usan**. Solo `_isInsideDebugModeBlock` (L160) se invoca. `unused_element` ignore suprime warning. | Eliminar wrappers muertos + quitar `unused_element` del ignore. Reducir deuda técnica. |
| D3 | `_deriveTag` en scanner (L270-274) genera tag sin PascalCase. Ej: `recording_page` no `RecordingPage`. Inconsistente con convención Paso 14 (tags PascalCase). | No es scope Paso 16 — documentar en Roadmap. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ **Schema:** N/A — paso no toca DB, modelos, ni persistencia JSON.
- ✅ **Integridad referencial:** N/A.
- ✅ **RLS:** N/A.
- ✅ **Índices:** N/A.
- ✅ **Tipos de datos:** N/A.

Paso 100% code/tooling. Sin impacto en data layer.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Estado actual

**`scripts/debugprint_detector.dart` (165L):**
- 7 funciones públicas: `isInsideDebugModeBlock`, `isSameLineKDebugModeGuard`, `isInsideAssert`, `isTernaryKDebugModeGuard`, `isAdjacentKDebugModeGuard`, `isInsideBracedDebugModeBlock`, `stripStringsAndComments`
- Header comment L1-11: "All functions public — usable by scanner and test."
- 0 imports externos. Solo `dart:core`.

**`scripts/debugprint_scanner.dart` (319L):**
- L1: `// ignore_for_file: avoid_print, unused_element`
- L5: `import 'debugprint_detector.dart';`
- L159-165: 4 wrappers `_` privados delegando a detector público
- Solo `_isInsideDebugModeBlock` (L160) se invoca (L139, L204)
- `_isSameLineKDebugModeGuard` (L162), `_isInsideAssert` (L163), `_isInsideBracedDebugModeBlock` (L164-165) → **dead code**

**`test/debugprint_scanner_test.dart` (196L):**
- L3: `import '../scripts/debugprint_detector.dart';`
- Testea funciones públicas del detector directamente
- 31 expects, 8 grupos, 52/52 tests pasan

### Análisis de opciones

**Opción A: Mantener públicas + actualizar spec** (RECOMENDADA)
- Impacto: 0 cambios en código funcional
- Artefacto: actualizar `analisis-FINAL.md` §3 para documentar decisión
- + Eliminar 3 wrappers muertos + `unused_element` del ignore
- Justificación: detector público es **decisión correcta** — Dart no permite testear funciones `_` de otro archivo. Wrappers `_` existen para satisfacer spec literalmente pero son dead code innecesario.

**Opción B: Renombrar a privadas + mover test inline**
- Impacto: mover 7 funciones a scanner como `_`, mover tests a test inline, eliminar detector.dart
- Destruye modularidad. Test no puede importar funciones `_` de script externo.
- **Descartada:** Dart fundamentalmente no soporta testar `_` cross-file.

**Decisión: Opción A.** Código gana. Spec se actualiza.

### Funciones/clases afectadas

| Función | Archivo | Cambio | Firma |
|---|---|---|---|
| `_isSameLineKDebugModeGuard` | scanner L162 | **ELIMINAR** (dead code) | `bool _isSameLineKDebugModeGuard(String line)` |
| `_isInsideAssert` | scanner L163 | **ELIMINAR** (dead code) | `bool _isInsideAssert(String line)` |
| `_isInsideBracedDebugModeBlock` | scanner L164-165 | **ELIMINAR** (dead code) | `bool _isInsideBracedDebugModeBlock(List<String>, int)` |
| `_isInsideDebugModeBlock` | scanner L160-161 | **MANTENER** (único wrapper usado) | `bool _isInsideDebugModeBlock(List<String>, int)` |

### Imports

| Archivo | Import | Estado |
|---|---|---|
| scanner L5 | `import 'debugprint_detector.dart';` | ✅ Mantener — `_isInsideDebugModeBlock` lo necesita |
| test L3 | `import '../scripts/debugprint_detector.dart';` | ✅ Mantener — test importa API pública |

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ **APIs/endpoints:** N/A — paso no toca backend, APIs, ni middleware.
- ✅ **Middleware:** N/A.
- ✅ **Flujos:** N/A.
- ✅ **Contratos:** N/A.
- ✅ **Error handling:** N/A.

Paso es 100% refactor de scripts DX + actualización doc. Sin impacto backend.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ **Flujo completo:** N/A — no afecta DB→Backend→Frontend→UX.
- ✅ **Coherencia:** Detector público + wrappers privados en scanner es patrón válido. Test confirma funcionalidad.
- ✅ **Alineación:** Spec desactualizada vs código funcional. Actualizar spec restaura coherencia.
- ✅ **Gaps:** 3 wrappers dead code + `unused_element` ignore → fricción para futuro desarrollador que no entiende por qué existen.

### Herramienta Propuesta: `debugprint_alignment_check.dart`
- **Qué automatiza:** Verifica que scanner use detector correctamente — grep wrappers `_` en scanner, confirma que detector export matches scanner import, valida `flutter analyze` 0 issues post-cambio.
- **Tipo:** validador / script CLI
- **Cómo se usa:** `dart run scripts/debugprint_alignment_check.dart`
- **Impacto para el usuario final:** Confirma en ~1s que detector↔scanner están alineados. Previene dead code futuro.
- **Prioridad:** Tarea 0

### Flujo end-to-end

```
Paso 16 flujo:
1. DX tool verifica estado actual
2. Eliminar 3 wrappers dead code en scanner
3. Quitar `unused_element` del ignore_for_file
4. Actualizar analisis-FINAL §3 con decisión real
5. Verificar: flutter analyze 0 issues + flutter test 52/52
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] scanner tiene 1 wrapper `_isInsideDebugModeBlock` (no 4)
✅ [CODE] scanner NO tiene `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock` (eliminados)
✅ [CODE] scanner L1 ignore solo `avoid_print` (no `unused_element`)
✅ [CODE] detector.dart 7 funciones públicas intactas (sin cambios)
✅ [CODE] scanner `_isInsideDebugModeBlock` sigue delegando a detector `isInsideDebugModeBlock`
✅ [CODE] test/debugprint_scanner_test.dart sigue importando detector y pasando 31 tests
✅ [CODE] analisis-FINAL.md §3 actualizado: documenta decisión detector público + wrapper privado
✅ [DX] `dart run scripts/debugprint_alignment_check.dart` ejecuta sin errores
✅ [DX] `dart run scripts/debugprint_scanner.dart` → 0 residuales (sin regresión)
✅ [DX] `flutter analyze` → 0 issues
✅ [DX] `flutter test` → 52/52 passed
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Eliminar wrappers rompe algo no visible | Baja | Wrappers marcados `unused_element`, grep confirma 0 invocaciones fuera de declaración | `flutter analyze` post-cambio + `flutter test` 52/52 |
| Quitar `unused_element` del ignore expone otros unused | Media | Podría haber otros `_` unused en scanner no identificados | grep `_` privadas en scanner → solo `_deriveTag`, `_printResults`, `_findDebugPrintCalls`, `_fixDebugPrintCalls`, `_printUsage`, `_DebugPrintMatch`, `_MatchResult` — todos usados |
| Editar analisis-FINAL archivado causa inconsistencia | Baja | FINAL está en `IMPLEMENTED/mvp/13-...` — archivo histórico | Crear addendum en analisis-FINAL, no reescribir. O actualizar inline con nota `[Actualizado Paso 16]` |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling:** Crear `debugprint_alignment_check.dart` — verifica wrappers scanner, imports detector, `flutter analyze` | `scripts/debugprint_alignment_check.dart` | `void main()` — exit 0 si alineado, exit 1 si desvío | `scripts/debugprint_migration_verifier.dart` (patrón verificador post-cambio) | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/debugprint_alignment_check.dart` exit 0 |
| 1 | Eliminar 3 wrappers dead code en scanner L162-165 | `scripts/debugprint_scanner.dart` | Eliminar `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock`. Mantener `_isInsideDebugModeBlock` (L160-161) y comment L159 | `scripts/debugprint_scanner.dart` L270-274 (`_deriveTag` — función `_` privada usada) | CODE | Baja | 0.25h | Tarea 0 | → verificar: grep `_isSameLineKDebugModeGuard\|_isInsideAssert\|_isInsideBracedDebugModeBlock` en scanner → 0 resultados |
| 2 | Quitar `unused_element` del ignore L1 | `scripts/debugprint_scanner.dart` | L1: `// ignore_for_file: avoid_print` (solo `avoid_print`, sin `unused_element`) | N/A — eliminación directa | CODE | Baja | 0.1h | Tarea 1 | → verificar: `flutter analyze` → 0 issues (no unused element warnings) |
| 3 | Actualizar analisis-FINAL §3 con nota de decisión | `DEVS/IMPLEMENTED/mvp/13-Mejorar-debugprint-scanner-kdebugmode/analisis-FINAL.md` | Agregar nota `[Actualizado Paso 16]` en §3 L95: "Decisión real: funciones públicas en `debugprint_detector.dart` para testabilidad cross-file. Scanner usa wrapper `_isInsideDebugModeBlock` único." | N/A — documentación | FULLSTACK | Baja | 0.25h | Tarea 2 | → verificar: grep `Paso 16` en analisis-FINAL → 1 resultado |
| 4 | Validación end-to-end | — | — | — | FULLSTACK | Baja | 0.25h | Tareas 0-3 | → verificar: `dart run scripts/debugprint_scanner.dart` exit 0 + `flutter analyze` 0 issues + `flutter test` 52/52 + `dart run scripts/debugprint_alignment_check.dart` exit 0 |

**Tiempo total estimado:** 1.35h

---

## 🔮 Roadmap (NO implementar ahora)

- **`_deriveTag` PascalCase:** scanner genera tags `snake_case` (`recording_page`) vs convención Paso 14 (`RecordingPage`). Fix trivial pero fuera de scope Paso 16. D3.
- **Eliminar comment L159:** `// ── FINAL-spec private wrappers (delegate to debugprint_detector.dart) ──` se vuelve misleading post Paso 16 (ya no hay "wrappers" plural). Actualizar comment post-eliminación.
- **Doc: ARCHITECTURE.md para scripts/:** Documentar relación detector↔scanner↔test para futuros desarrolladores. Patrón "módulo público para test + wrapper privado en CLI" no es obvio sin contexto.
