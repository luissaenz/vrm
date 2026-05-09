# 🏛️ ANÁLISIS UNIFICADO — Paso 13: Mejorar-debugprint-scanner-kdebugmode

> **Generado:** 2026-05-09
> **Fase:** mvp
> **Origen:** Sugerencia 🔵 de validacion — Paso 08

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---|:---|:---|:---|:---|
| **glm** | ✅ 13/13 | 2 (D1 same-line, D2 braceDepth strings) | ✅ test unitario + refactor | ✅ Bugs documentados con líneas exactas, evidencia de código | 4.5 |
| **step** | ✅ 10/10 | 1 (same-line) | ✅ debugprint_scanner v2 | ✅ Código real, solución con `_isGuardedOnSameLine` | 3.5 |
| **ds** | ✅ 15/15 | 5 (same-line, adjacent, assert, braces, ternary) | ✅ debugprint_scanner 3 niveles | ✅ Refactor completo con helpers separados, firmas exactas | 5.0 |
| **gmn** | ✅ 4/4 | 1 (backward scan limitado) | ✅ debugprint_scanner_fix | ⚠️ Solo 4 verificaciones, sin evidencia de líneas | 2.0 |
| **grok** | ✅ 5/5 | 1 (scanner buggy) | ✅ debugprint_scanner mejorado | ⚠️ Superficial, verificación 4 no ejecutada realmente (dice falso positivo donde no existe) | 2.5 |
| **lgn** | ✅ 15/15 | 2 (!kReleaseMode variantes, espacios) | ✅ debugprint-scanner-v2 | ✅ Lista 55 archivos residuales, código real | 4.0 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| 1 | `_isInsideDebugModeBlock` no detecta `if (kDebugMode) debugPrint(...)` misma línea sin llaves | glm, step, ds, gmn, grok, lgn (6/6) | ✅ `scripts/debugprint_scanner.dart:161` braceDepth = 0 sin llaves → retorna false | Agregar detección misma-línea: regex `if\s*\(\s*kDebugMode\s*\)\s*debugPrint\(` antes de contar braces |
| 2 | `_isInsideDebugModeBlock` no detecta `if (kDebugMode)\n  debugPrint(...)` línea adyacente sin llaves | ds | ✅ `scripts/debugprint_scanner.dart:163-168` braceDepth nunca supera 0 sin `{` | Agregar lookahead 1 línea: si línea anterior es `if (kDebugMode)` sin `{`, retornar true |
| 3 | `assert(debugPrint(...))` no detectado como no-op en Release | ds | ✅ `scripts/debugprint_scanner.dart:124` busca `debugPrint(` sin verificar si está dentro de `assert(` | Agregar `_isInsideAssert()` que verifica si hay `assert(` antes de `debugPrint(` |
| 4 | `kDebugMode ? debugPrint(...) : null` no detectado | ds | ✅ Mecanismo: ternario no usa `if {}`, braceDepth nunca > 0 | Agregar `_isTernaryKDebugMode()` que busca `kDebugMode\s*\?` antes de `debugPrint(` |
| 5 | Llaves en strings/comentarios (`'{test}'`, `// {comment}`) alteran braceDepth | glm, ds | ✅ `scripts/debugprint_scanner.dart:167-168` cuenta todo `{`/`}` sin contexto | Implementar mini-parser que ignore chars dentro de strings `'...'` / `"..."` y comentarios `//` `/* */` |
| 6 | No detecta `!kReleaseMode` con variantes de espaciado (`if(!kReleaseMode)` sin espacio) | lgn | ✅ `scripts/debugprint_scanner.dart:172` usa `l.contains('kDebugMode')` — detecta substring sin importar espaciado | **No es bug real.** `contains()` funciona con cualquier espaciado. D6 es falso. |
| 7 | Scanner reporta falso positivo en `memory_monitor.dart:62` | grok | ❌ Verificación 4 no ejecutada realmente. Código actual SÍ detecta bloque con llaves: L60 `if (kDebugMode) {` → braceDepth=1 en backward scan | **Falso positivo no existe.** `memory_monitor.dart:61-62` usa `{}` multilinea → detectado correctamente. |

---

## 1️⃣ Resumen Ejecutivo

- **Objetivo:** Eliminar falsos positivos en `debugprint_scanner.dart` cuando `debugPrint` está envuelto en `if (kDebugMode)` / `if (!kReleaseMode)` sin llaves (misma línea o línea adyacente). También cubrir `assert()` y ternarios con `kDebugMode`.
- **Correcciones críticas:** 5 discrepancias reales (D1-D5). D6 y D7 son falsos — `contains()` ya maneja espaciado variable, y `memory_monitor.dart` ya es excluido correctamente por el código actual.
- **Decisión DX:** Fusionar propuesta **ds** (3 niveles de detección refactorizados) + **glm** (test unitario preventivo). Herramienta final: `debugprint_scanner.dart` mejorado + `test/debugprint_scanner_test.dart`.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path

1. Desarrollador ejecuta `dart run scripts/debugprint_scanner.dart`
2. Scanner recorre 88+ archivos `.dart` en `lib/`
3. Por cada `debugPrint(` encontrado:
   a. Verifica si está en comentario (`//`, `*`, `///`) → skip
   b. Verifica si está en misma línea con `if (kDebugMode)` / `if (!kReleaseMode)` sin llaves → skip
   c. Verifica si está en línea adyacente sin llaves (`if (kDebugMode)\n  debugPrint()`) → skip
   d. Verifica si está dentro de `assert()` → skip
   e. Verifica si está en ternario `kDebugMode ? debugPrint() : null` → skip
   f. Verifica si está dentro de bloque con llaves via backward scan (lógica existente) → skip
   g. Si no pasa ningún filtro → reporta como residual
4. Muestra resultados agrupados por archivo con línea:columna + snippet
5. Exit code 0 (limpio) o 1 (residuales)
6. Modo `--fix`: reemplaza automáticamente `debugPrint()` por `LoggerService.log()`

### Edge Cases MVP

1. `if (kDebugMode) debugPrint('x');` — misma línea sin llaves → ignorado
2. `if (kDebugMode)\n  debugPrint('x');` — línea adyacente sin llaves → ignorado
3. `assert(debugPrint('x'));` — debugPrint dentro de assert → ignorado
4. `kDebugMode ? debugPrint('x') : null;` — ternario debug → ignorado
5. Strings con braces: `'{test}'` no alteran braceDepth counting
6. Comentarios con braces: `// {comment}` no alteran braceDepth counting
7. `if (!kReleaseMode) { debugPrint('x'); }` — multilinea con llaves → ignorado (ya funciona)
8. `debugPrint('real residual');` sin guard → reportado como residual

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

#### **`scripts/debugprint_scanner.dart`** — Modificación

- **Ruta real:** `D:\Develop\Personal\vrm\scripts\debugprint_scanner.dart`
- **Tipo de cambio:** Refactor
- **Descripción:** Refactorizar `_isInsideDebugModeBlock` de una función monolítica (19 líneas, backward scan + braceDepth) a 4 helpers con responsabilidad única:
  - `_isInsideDebugModeBlock(lines, lineIdx)` — orquestador
  - `_isSameLineKDebugModeGuard(line)` — detecta misma línea `if (kDebugMode) debugPrint(`
  - `_isInsideAssert(line)` — detecta `assert(debugPrint(`
  - `_isInsideBracedDebugModeBlock(lines, lineIdx)` — backward scan existente mejorado con ignorado de braces en strings/comments
- **Interfaces clave:**
  ```dart
  bool _isInsideDebugModeBlock(List<String> lines, int lineIdx)
  bool _isSameLineKDebugModeGuard(String line)
  bool _isInsideAssert(String line)
  bool _isInsideBracedDebugModeBlock(List<String> lines, int lineIdx)
  ```
- **Patrones a seguir:** Funciones privadas `_` ya existentes en `scripts/`. Mismo patrón que `_deriveTag`, `_printResults`.

#### **`test/debugprint_scanner_test.dart`** — Creación

- **Ruta real:** `D:\Develop\Personal\vrm\test\debugprint_scanner_test.dart`
- **Tipo de cambio:** Creación
- **Descripción:** Test unitario que valida los 8 escenarios de detección kDebugMode (multilinea, misma-línea, adyacente, assert, ternario, con/sin llaves, sin guard, nested).
- **Interfaz clave:** `void main()` con 8+ tests.
- **Patrones a seguir:** `test/repository_test.dart` (arrange-act-assert).

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: debugprint_scanner.dart (mejorado)
- **Qué automatiza:** Escaneo preciso de `debugPrint` residuales, ignorando aquellos dentro de guards `if (kDebugMode)` / `if (!kReleaseMode)` / `assert()` / ternarios — incluso sin llaves.
- **Tipo:** CLI / Scanner
- **Ubicación:** `D:\Develop\Personal\vrm\scripts\debugprint_scanner.dart`
- **Cómo se usa:**
  ```
  dart run scripts/debugprint_scanner.dart          # Escanear residuales
  dart run scripts/debugprint_scanner.dart --fix   # Migrar automáticamente a LoggerService
  dart run scripts/debugprint_scanner.dart --help  # Ayuda
  ```
- **Impacto para el usuario final:** Reduce falsos positivos a 0. Desarrolladores pueden usar `if (kDebugMode) debugPrint(...)` sin que el scanner lo reporte como residual. Menos fricción en DX.
- **El implementador DEBE usarla** para validar que no hay regresión antes de continuar a Tarea 1.
```

### Test unitario — Tarea 0 complementaria

```
### Herramienta: debugprint_scanner_test.dart
- **Qué automatiza:** Validación de que `_isInsideDebugModeBlock` + helpers detectan correctamente 8+ patrones de guard kDebugMode.
- **Tipo:** Test
- **Ubicación:** `D:\Develop\Personal\vrm\test\debugprint_scanner_test.dart`
- **Cómo se usa:**
  ```
  dart test test/debugprint_scanner_test.dart
  ```
- **Impacto para el usuario final:** Previene regresión del scanner en CI. Asegura que futuras mejoras no rompan detección existente.
- **El implementador DEBE ejecutarlo** después de Tarea 1 y antes de Tarea 2.
```

---

## 4️⃣ Decisiones Tecnológicas

1. **Refactor a 4 helpers en vez de refactor completo:** ds propone 3 niveles, glm propone refactor a pre-computed line ranges. La opción más segura y mantenible = extraer helpers actuales + agregar nueva lógica sin reescribir backward scan existente. gmn propuso forward scan completo — descartado por riesgo de regresión.
2. **Dart puro sin dependencias:** Scanner actual usa solo `dart:io`. No se agregan dependencias. Toda la lógica nueva usa `dart:core` (RegExp, String). ds y glm coinciden.
3. **Test unitario ANTES de modificar scanner:** glm propone Tarea 0 = test primero. Aceptado. Previene regresión.
4. **No agregar soporte `!kReleaseMode` con espacios:** lgn D6 dice que `if(!kReleaseMode)` (sin espacio) no se detecta. **Falso.** `l.contains('!kReleaseMode')` funciona con cualquier espaciado. No requiere cambio.
5. **Corrección al plan:** El plan Paso 13 dice "Actualizar debugprint_scanner para ignorar `if (kDebugMode)`". El análisis revela 5 edge cases específicos no contemplados en el plan (misma línea, adyacente, assert, ternario, braces en strings).
6. **Prioridad de discrepancias:** D1 (same-line) = crítica (afecta reporte actual). D2 (adyacente) = media. D3 (assert) = baja. D4 (ternario) = baja. D5 (braces en strings) = baja. D6-D7 = falsos, no implementar.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [CODE] _isSameLineKDebugModeGuard detecta if (kDebugMode) debugPrint() misma línea sin llaves
✅ [CODE] _isInsideBracedDebugModeBlock detecta if (kDebugMode) { debugPrint() } multilinea (existente, no regresión)
✅ [CODE] _isInsideAssert detecta assert(debugPrint()) 
✅ [CODE] Scanner ignora debugPrint en línea adyacente if (kDebugMode)\n  debugPrint()
✅ [CODE] Scanner ignora debugPrint en ternario kDebugMode ? debugPrint() : null
✅ [CODE] Brace counting ignora braces dentro de strings '...' y "..." 
✅ [CODE] Brace counting ignora braces dentro de comentarios // y /* */
✅ [CODE] Scanner NO reporta memory_monitor.dart (guard existente, no regresión)
✅ [CODE] Scanner SÍ reporta clip_review_page.dart (residuales reales, no regresión)
✅ [DX] dart run scripts/debugprint_scanner.dart ejecuta sin errores
✅ [DX] dart run scripts/debugprint_scanner.dart --fix ejecuta sin errores y respeta guards
✅ [DX] dart test test/debugprint_scanner_test.dart pasa 8+ tests
✅ [DX] flutter analyze reporta 0 issues
✅ [DX] flutter test pasa 21/21 (sin regresión)
```

**Funcionales:**
- [ ] Scanner ignora debugPrint dentro de guards kDebugMode en todos los patrones soportados
- [ ] Scanner reporta solo debugPrint residuales reales (sin guard) después del cambio

**Técnicos:**
- [ ] `_isInsideDebugModeBlock` refactorizado con ≤ 4 helpers, cada uno con responsabilidad única
- [ ] 0 dependencias nuevas agregadas
- [ ] Archivo test/debugprint_scanner_test.dart creado con 8+ casos

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** Crear `test/debugprint_scanner_test.dart` con 8+ casos de guard kDebugMode | Media | 1h | Ninguna |
| 1 | Refactor `_isInsideDebugModeBlock` → `_isSameLineKDebugModeGuard` + `_isInsideAssert` + `_isInsideBracedDebugModeBlock` + orquestador | Media | 1h | Tarea 0 |
| 2 | Mejorar braceDepth counting: ignorar braces en strings `'...'` / `"..."` y comentarios `//` `/* */` | Media | 0.75h | Tarea 1 |
| 3 | Agregar detección ternario `kDebugMode ? debugPrint() : null` | Baja | 0.25h | Tarea 1 |
| 4 | Validación end-to-end: scanner no reporta falsos positivos ni pierde residuales reales | Baja | 0.5h | Tareas 1-3 |
| 5 | `flutter analyze` + `flutter test` — 0 issues, 21/21 tests | Baja | 0.25h | Tarea 4 |
| **TOTAL** | | | **3.75h** | |

> [!IMPORTANT]
> **Tarea 0 = DX & Tooling.** Implementador DEBE ejecutarla primero y usar el test para validar Tareas 1-3.

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Regresión: scanner deja de detectar debugPrint reales por regex sobre-expansivo | Alta | Regex `\bif\s*\(\s*kDebugMode\s*\)` podría hacer match parcial en strings/comentarios | Test unitario Tarea 0 con casos known-good + known-bad. Verificar count post-cambio = mismo que antes (69). |
| Falso negativo: omitir debugPrint genuino dentro de bloque complejo | Media | Nuevos helpers no cubren patrón anidado complejo | Tarea 0 test con caso `if (kDebugMode) if (other) debugPrint()` — decidir si se ignora o reporta. |
| Brace counting con string interpolation `'${x}'` | Baja | String interpolation contiene `{` que no es apertura de bloque | Mini-parser Tarea 2 ignora contenido completo entre comillas simples/duples. |
| Regresión en `--fix` mode | Alta | `_fixDebugPrintCalls` también usa `_isInsideDebugModeBlock`. Si cambia lógica, `--fix` podría migrar debugPrint protegidos. | Tarea 4 validar que `--fix` no toca archivos con guards. Test específico. |

---

## 8️⃣ Testing Mínimo Viable

### Test unitario (Tarea 0): `test/debugprint_scanner_test.dart`

| ID | Caso | Input (línea) | Output Esperado |
|---|---|---|---|
| TP-1 | Multilinea con llaves | `if (kDebugMode) {\n  debugPrint('test');\n}` | `_isInsideDebugModeBlock` → true |
| TP-2 | Misma línea sin llaves | `if (kDebugMode) debugPrint('test');` | `_isInsideDebugModeBlock` → true |
| TP-3 | Línea adyacente sin llaves | `if (kDebugMode)\n  debugPrint('test');` | `_isInsideDebugModeBlock` → true |
| TP-4 | Sin guard | `debugPrint('test');` | `_isInsideDebugModeBlock` → false |
| TP-5 | Assert wrapper | `assert(debugPrint('test'));` | `_isInsideDebugModeBlock` → true |
| TP-6 | Ternario kDebugMode | `kDebugMode ? debugPrint('test') : null;` | `_isInsideDebugModeBlock` → true |
| TP-7 | String con braces | `debugPrint('{test}')` en línea posterior a `if (kDebugMode) {` | braceDepth no afectado por braces en string |
| TP-8 | Comentario con braces | `// if (kDebugMode) {` en línea posterior + `debugPrint('real')` | braceDepth no afectado por braces en comentario |

### Verificación integración

| ID | Caso | Comando | Output Esperado |
|---|---|---|---|
| TP-9 | Scan sin regresión | `dart run scripts/debugprint_scanner.dart` | Mismo conteo (69 matches) sin falsos positivos nuevos |
| TP-10 | --fix sin tocar guards | `dart run scripts/debugprint_scanner.dart --fix` + diff | Archivos con guards kDebugMode no modificados |
| TP-11 | Analyze limpio | `flutter analyze` | 0 issues |
| TP-12 | Tests pasan | `flutter test` | 21/21 passed |

Comando para ejecutar tests: `flutter test`

---

## 📊 Calidad de Aportes por Análisis

| Agente | Score | Fortaleza | Debilidad |
|:---|:---:|:---|:---|
| **ds** | **5.0** | 15 verificaciones, 5 discrepancias detectadas (la más completa), 3 niveles de detección diseñados, firmas exactas, 6 tareas atómicas, 8 secciones completas | Estimación 3.25h vs real 3.75h (subestima Tarea 2 brace parsing) |
| **glm** | **4.5** | 13 verificaciones, bugs documentados con líneas exactas, propone test unitario como Tarea 0 (mejor práctica), roadmap claro | No detecta D2 (adyacente), D3 (assert), D4 (ternario) |
| **lgn** | **4.0** | 15 verificaciones, lista 55 archivos residuales, detecta variantes espaciado | D6 es falso positivo (contains() ya maneja espaciado), propone migración masiva fuera de scope |
| **step** | **3.5** | 10 verificaciones, solución concreta `_isGuardedOnSameLine`, plan simple | Solo detecta D1, no cubre D2-D5 |
| **grok** | **2.5** | 5 verificaciones, identifica scanner buggy | Superficial: D7 (falso positivo memory_monitor.dart) es falso — código actual funciona. Verificación 4 no ejecutada. |
| **gmn** | **2.0** | Identifica backward scan limitado | Solo 4 verificaciones, plan 1 tarea (subestimación), sin evidencia de líneas, propone forward scan completo (riesgo regresión innecesario) |
