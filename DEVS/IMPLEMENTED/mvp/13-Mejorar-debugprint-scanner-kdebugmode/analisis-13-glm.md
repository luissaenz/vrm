# Análisis Técnico — Paso 13: Mejorar-debugprint-scanner-kdebugmode

**Agente:** glm
**Paso:** 13
**Fecha:** 2026-05-09

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|----------|-------------|--------|-----------|
| 1 | `debugprint_scanner.dart` existe | `ls scripts/debugprint_scanner.dart` | ✅ VERIFICADO | 331 líneas, L1 |
| 2 | `_isInsideDebugModeBlock()` existe | Backward scan L160-178 | ✅ VERIFICADO | L160 |
| 3 | `_findDebugPrintCalls()` usa `_isInsideDebugModeBlock` | L137-139 skip si dentro de kDebugMode | ✅ VERIFICADO | L136-139 |
| 4 | `_fixDebugPrintCalls()` usa `_isInsideDebugModeBlock` | L217 skip si dentro de kDebugMode | ✅ VERIFICADO | L217 |
| 5 | `memory_monitor.dart` L61-62 tiene `if (kDebugMode) { debugPrint(...) }` | Escaneo no reporta `memory_monitor.dart` | ✅ VERIFICADO | `kDebugMode` L61, `debugPrint` L62 |
| 6 | Scanner reporta 69 debugPrint en 14 archivos | `dart run scripts/debugprint_scanner.dart` | ✅ VERIFICADO | Output: 69 calls, 14 archivos |
| 7 | Scanner salta `logger_service.dart` | L38: `if (file.path.endsWith('logger_service.dart')) continue;` | ✅ VERIFICADO | L38 |
| 8 | `kDebugMode` solo usado en 1 archivo lib/ | `grep kDebugMode lib/` → solo `memory_monitor.dart` | ✅ VERIFICADO | 1 match |
| 9 | `!kReleaseMode` no usado en lib/ | `grep !kReleaseMode lib/` → 0 matches | ✅ VERIFICADO | 0 matches |
| 10 | Bug: misma-línea `if (kDebugMode) debugPrint('x')` no detectado | `_isInsideDebugModeBlock` requiere braceDepth > 0 → false si no hay `{` | ❌ DISCREPANCIA | L161-174: braceDepth = 0 sin llaves |
| 11 | Vulnerabilidad: llaves en strings/comments afectan braceDepth | `debugPrint('{test}')` → `{` suma a braceDepth | ⚠️ NO VERIFICABLE | Caso edge raro en código actual |
| 12 | `logger_service.dart` L48 usa `debugPrint(entry)` dentro de `LoggerService.log()` | Scanner lo salta (L38) | ✅ VERIFICADO | L48: `debugPrint(entry)` |
| 13 | 14 archivos importan `foundation.dart` (acceso a `kDebugMode`) | grep фундамент.dart en lib/ | ✅ VERIFICADO | 14 archivos con import |

**Discrepancias encontradas:**

1. **❌ D1: `_isInsideDebugModeBlock` no detecta `if (kDebugMode) debugPrint(...)` en una línea** — Función requiere `braceDepth > 0` para retornar true. Patrón `if (kDebugMode) debugPrint('x');` sin llaves tiene braceDepth = 0 → retorna false → reporte falso positivo. **Resolución:** Agregar detección de misma-línea con regex `if\s*\(\s*kDebugMode\s*\)\s*debugPrint\(` o validar que la línea contiene `kDebugMode` antes de la posición de `debugPrint(`.

2. **⚠️ D2: Llaves en strings/comments afectan braceDepth** — `debugPrint('{error}')` suma al braceDepth. Probabilidad baja en código VRM actual (0 instancias detectadas con llaves en strings de debugPrint), pero implica riesgo de falso negativo si llave en string balancea incorrectamente. **Resolución:** Ignorar llaves dentro de strings literales (implementar mini-parser de strings `'...'` y `"..."`).

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: N/A. Script CLI sin base de datos.
- ✅ Integridad referencial: N/A.
- ✅ RLS policies: N/A.
- ✅ Índices: N/A.
- ✅ Tipos de datos: Scanner opera sobre texto (archivos `.dart`). Entry de datos = `List<String> lines` por archivo.

**Diagrama de flujo de datos del scanner:**

```
lib/ → dartFiles list → readAsString → split('\n') → _findDebugPrintCalls() → results[]
                                                                 ↓
                                                        _isInsideDebugModeBlock() [BUG]
                                                        comment check [OK]
                                                                 ↓
                                                        _fixDebugPrintCalls() → writeAsString
```

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones existentes en `debugprint_scanner.dart`

| Función | Firma | Uso |
|---------|-------|-----|
| `main(List<String> args)` | Entry point. Parse --fix, --help | L8-100 |
| `_printUsage()` | `void _printUsage()` | L102-114 |
| `_findDebugPrintCalls(List<String> lines)` | `List<_DebugPrintMatch>` → retorna matches | L116-155 |
| `_isInsideDebugModeBlock(List<String> lines, int lineIdx)` | `bool` → detecta si línea está dentro de bloque kDebugMode | L160-178 **BUG** |
| `_fixDebugPrintCalls(File file, String content, List<String> lines)` | `int` → retorna replacements count | L180-281 |
| `_deriveTag(String path)` | `String` → nombre PascalCase sin extensión | L283-287 |
| `_printResults(List<_MatchResult> results, int totalFiles)` | `void` → imprime resultados agrupados por archivo | L289-307 |

### Bug principal: `_isInsideDebugModeBlock`

**Problema 1 — Misma-línea sin llaves:**
```dart
// PATRÓN NO DETECTADO (false negative):
if (kDebugMode) debugPrint('test');
// braceDepth = 0 → _isInsideDebugModeBlock retorna false
// Scanner reporta este debugPrint como residual → FALSO POSITIVO
```

**Problema 2 — Llaves en strings afectan depth:**
```dart
// PATRÓN QUE PODRÍA CAUSAR FALSO NEGATIVO:
debugPrint('{ error }');  // '{' suma braceDepth
// Si hay un if (kDebugMode) 2 líneas arriba,
// este '{' extra desbalancearía el tracking
```

**Problema 3 — Comentarios con llaves:**
```dart
// { comment } → '{' y '}' afectan braceDepth si no se filtran
```

### Patrones: se siguen los existentes

Scanner sigue patrón de otros CLI en `scripts/`:
- Entry point con `main(List<String> args>)` → same as `vrm_health_check.dart`, `store_prep_cli.dart`
- File walk con `Directory.list(recursive: true)` → same pattern
- Classes privadas `_DebugPrintMatch`, `_MatchResult` → data classes

### Modularidad

- `_isInsideDebugModeBlock` es función privada con responsabilidad única ✅
- Pero tiene 2 callers: `_findDebugPrintCalls` (L137) y `_fixDebugPrintCalls` (L217) — cambios se propagan a ambos ✅
- Scope limitado a `debugprint_scanner.dart` — 0 acoplamiento externo ✅

### Calidad

- Complejidad ciclomática de `_isInsideDebugModeBlock`: 5 (for + if + contains + return). Baja. ✅
- Bug de same-line detection incrementa complejidad levemente si se agrega regex check.

### Imports exactos

```dart
import 'dart:io';
```

Único import. Sin dependencias externas. ✅

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: N/A. Script CLI local.
- ✅ Middleware: N/A.
- ✅ Flujos: CLI → filesystem read → pattern matching → output stdout.
- ✅ Contratos: Scanner retorna exit code 0 (sin findings) o 1 (con findings).
- ✅ Error handling: `lib/` no encontrado → `exit(1)`. Sin try-catch en file operations ←_mejorable.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: Desarrollador ejecuta scanner → obtiene lista de debugPrint residuales → puede decidir migrar manualmente o con `--fix`.
- ✅ Coherencia: Scanner es parte del ecosistema DX de VRM (vrm_health_check, store_prep_cli, validador_metrics). Sigue patrón consistente.
- ✅ Alineación: Plan Paso 13 pide eliminar falsos positivos. Scanner actualmente filtra `kDebugMode` blocks pero con bug en same-line pattern.
- ✅ Gaps:
  - Bug D1 hace que `if (kDebugMode) debugPrint('x')` sea reportado como residual (falso positivo)
  - Bug D2 potencial pero low-risk en código actual (0 instancias de llaves en strings de debugPrint)
  - `_isInsideDebugModeBlock` no distingue comentarios con llaves
- ✅ **DX & Tooling (OBLIGATORIO):**

```
### Herramienta Propuesta: debugprint_kdebug_test
- **Qué automatiza:** Test unitario que valida que _isInsideDebugModeBlock detecta correctamente patrones kDebugMode (multilinea, misma-línea, sin guard) y no tiene falsos positivos/negativos.
- **Tipo:** test
- **Cómo se usa:** `dart test test/debugprint_scanner_test.dart`
- **Impacto para el usuario final:** Previene regresión del scanner. Asegura que futuras mejoras no rompan detección existente. Previene falsos positivos en CI.
- **Prioridad:** Tarea 0 — implementar ANTES de modificar scanner
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] _isInsideDebugModeBlock detecta if (kDebugMode) { debugPrint() } multilinea (caso actual)
✅ [CODE] _isInsideDebugModeBlock detecta if (kDebugMode) debugPrint() misma-línea sin llaves
✅ [CODE] _isInsideDebugModeBlock detecta if (!kReleaseMode) { debugPrint() } multilinea
✅ [CODE] _isInsideDebugModeBlock detecta if (!kReleaseMode) debugPrint() misma-línea sin llaves
✅ [CODE] Scanner NO reporta memory_monitor.dart L62 como residual
✅ [CODE] _fixDebugPrintCalls respeta kDebugMode blocks (no reemplaza dentro de guard)
✅ [FULLSTACK] dart run scripts/debugprint_scanner.dart ejecuta sin errores
✅ [DX] Test unitario valida 4+ escenarios de kDebugMode detection (multilinea, misma-línea, sin guard, nested)
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| Falso negativo: `if (kDebugMode) debugPrint()` no detectado | Alta | `_isInsideDebugModeBlock` requiere `braceDepth > 0` → same-line sin `{` retorna false | Agregar detección same-line con check de `kDebugMode`/`!kReleaseMode` en misma línea antes de `debugPrint(` |
| Falso positivo: llaves en strings/comments alteran braceDepth | Baja | Scanner cuenta `{` y `}` sin distinguir contexto string/comentario | Agregar mini-parser que ignore chars dentro de strings `'...'` y `"..."` y comentarios `//` `/* */` |
| Regresión: cambio en scanner rompe detección existente | Media | Refactor de `_isInsideDebugModeBlock` podría dejar de detectar caso `if (kDebugMode) { ... }` multilinea | Test unitario con casos known-good antes de cambios |
| Scanner no detecta `!kReleaseMode` actual | Baja | 0 usos de `!kReleaseMode` en lib/ actualmente | Incluir soporte anyway para futuro-proofing |

---

## 7️⃣ Plan de Implementación

> **Reglas de segmentación atómica:** Cada tarea = un artefacto. Interfaz completa. Patrón de referencia explícito. Verificación inline.

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|-------|-----------|-----------------|-----------------|-------|-------------|-------------|--------------|--------------|
| 0 | **DX & Tooling**: Test unitario scanner | `test/debugprint_scanner_test.dart` | `void main() { test('same-line guard detected', ...); test('multiline guard detected', ...); test('no guard detected', ...); test('nested guard detected', ...); }` | `test/repository_test.dart` ( Patrón: arrange-act-assert ) | DX | Media | 1h | Ninguna | → verificar: `dart test test/debugprint_scanner_test.dart` pasa 4+ tests |
| 1 | Fix _isInside DebugModeBlock same-line | `scripts/debugprint_scanner.dart` L160-178 | `bool _isInsideDebugModeBlock(List<String> lines, int lineIdx)` — agregar detección same-line: si línea contiene `kDebugMode` o `!kReleaseMode` ANTES de posición de `debugPrint(`, retornar true | Patrón actual `_isInsideDebugModeBlock` manteniendo backward scan | CODE | Media | 0.5h | Tarea 0 | → verificar: test same-line guard detected pasa |
| 2 | Fix _isInsideDebug ModeBlock string/comment braces | `scripts/debugprint_scanner.dart` L160-178 | Helper `String _stripStringsAnd Comments(String line)` que remueve contenido entre `'...'`, `"..."`, `//...` antes de contar llaves | — | CODE | Media | 0.5h | Tarea 1 | → verificar: test con `debugPrint('{test}')` no altera brace counting |
| 3 | Refactor _isInside DebugModeBlock a pre-computed line ranges | `scripts/debugprint_scanner.dart` L116-178 | `Set<int> _findDebugModeLineRanges(List<String> lines)` pre-computa líneas dentro de bloques kDebugMode; `_findDebugPrintCalls` y `_fixDebugPrintCalls` usan el set | — | CODE | Alta | 1h | Tarea 2 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta memory_monitor.dart; test cases 4/4 pasan |
| 4 | Validar scanner end-to-end | — | — | — | FULLSTACK | Baja | 0.25h | Tareas 0-3 | → verificar: `dart run scripts/debugprint_scanner.dart` ejecuta sin errores y reporta mismo count (69) pero sin falsos positivos en kDebugMode blocks |

**Tiempo total estimado:** 3.25 horas

---

## Discordancias con análisis gmn anterior

El análisis `analisis-paso13-gmn.md` existente en IN_PROGRESS tiene las siguientes limitaciones:
1. Sección §0 solo 4 verificaciones — este análisis tiene 13 verificando bugs y edge cases específicos
2. No identificó el bug de same-line detection (D1) con código de evidencia
3. No identificó el bug de strings/comments con braces (D2)
4. Plan de implementación con solo 1 tarea — este propone 5 atómicas
5. Sección DX propone "debugprint_scanner_fix" pero sin definir test unitario obligatorio previo

---

## 🔮 Roadmap (NO implementar ahora)

- **Paso 14:** Migración masiva de ~70 debugPrint a LoggerService.log() — usar scanner con `--fix` una vez corregido el bug D1
- **AST-based parsing:** Reemplazar regex/string matching con `analyzer` package de Dart para detección 100% precisa de guards y bloques. Post-MVP.
- **CI integration:** Agregar scanner como hook pre-commit para prevenir regresión de debugPrint en Release
- **Unified DX CLI:** Consolidar debugprint_scanner en vrm_health_check.dart como subcomando `check --debug`