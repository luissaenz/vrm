# 🧠 ANALISIS TECNICO: Paso 17 — Mejorar-debugprint-fix-multilinea

**Agente:** opus
**Paso:** 17
**Origen:** Sugerencia 🔵 — Paso ID-003
**Fecha:** 2026-05-09
**Fase:** mvp

---

## 0️⃣ Verificacion contra Codigo Fuente

| # | Elemento | Verificacion | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `scripts/debugprint_scanner.dart` existe | `ls scripts/debugprint_scanner.dart` | ✅ | 314 lineas |
| 2 | `scripts/debugprint_detector.dart` existe | `ls scripts/debugprint_detector.dart` | ✅ | 164 lineas, 7 fn publicas |
| 3 | `_findDebugPrintCalls()` usa escaneo linea por linea | grep `for (int lineIdx` en scanner L118-157 | ✅ | Busca `debugPrint(` solo dentro de una linea |
| 4 | `_fixDebugPrintCalls()` busca `)` solo en misma linea | grep `for (int j = idx` en scanner L206-217 | ✅ | Bucle `modified.length` — no cruza lineas |
| 5 | Salto `endIdx == -1` = multi-linea tratado como malformado | grep `Malformed, skip` en scanner L219-222 | ✅ | Lineas 219-222: `if (endIdx == -1) { /* Malformed, skip */ }` |
| 6 | Paso 14 ya migro 7 debugPrint multi-linea | `git show 9058ed7 --stat` | ✅ | 5 archivos modificados, 7 reemplazos |
| 7 | Patron multi-linea unico en los 7 calls | `git show 9058ed7 -p` | ✅ | Todos: `debugPrint(\n  'msg',\n);` |
| 8 | Scanner actual reporta 0 residuales | execution manual post-Paso 14 | ✅ | phase-state L86 |
| 9 | `test/debugprint_scanner_test.dart` existe | `ls test/debugprint_scanner_test.dart` | ✅ | 31 tests, 8 grupos |
| 10 | `debugprint_alignment_check.dart` tiene bug ID-001 | Paso 16 rechazado | ✅ | Regex `bool\\s+` no matcha `String` retorno de `stripStringsAndComments` |
| 11 | `debugprint_migration_verifier.dart` existe | `ls scripts/debugprint_migration_verifier.dart` | ✅ | 160 lineas, verifica scanner + imports + analyze |
| 12 | Sin dependencias externas necesarias | scanner usa solo `dart:io` | ✅ | `import 'dart:io'` L3 |

### Discrepancias encontradas

| # | Discrepancia | Resolucion propuesta |
|---|---|---|
| **D1** | Plan dice "Analizar las 7 llamadas residuales de debugPrint multilinea para entender el patron" | Los 7 calls YA fueron migrados en Paso 14 (commit 9058ed7). Patron ya conocido: `debugPrint(\n  'msg',\n);`. El scanner reporta 0 residuales. El analisis debe basarse en el patron conocido + el codigo historico del diff, no en busqueda de residuales actuales que no existen. |
| **D2** | Plan dice "Modificar la logica de escaneo/reemplazo... parser multi-linea o enfoque basado en AST (Analyzer)" | Aproximacion AST via `analyzer` es overkill: requiere dependencia `analyzer` no presente en pubspec.yaml, parsing de archivos completos, y manejo de resolucion de tipos. Line-based parser con forward-tracking es suficiente para el patron real. **Rechazar AST.** |
| **D3** | Plan dice "Ejecutar la correccion automatica sobre los residuales" | No hay residuales actuales. Validacion debe ser via tests unitarios + golden test con fixture de archivo sintetico que contenga `debugPrint(` multi-linea. |

---

## 1️⃣ Analisis de Datos (ETAPA 1)

**No aplica.** Paso 17 es puramente DX/tooling — modifica scripts CLI sin tocar datos, DB, ni persistencia.

---

## 2️⃣ Analisis de Codigo (ETAPA 2)

### Archivos afectados

| Archivo | Accion | Lineas actuales |
|---|---|---|
| `scripts/debugprint_scanner.dart` | **MODIFICAR** | 314 |
| `scripts/debugprint_detector.dart` | No tocar | 164 (0 cambios) |
| `test/debugprint_scanner_test.dart` | **MODIFICAR** (agregar tests multi-linea) | 195 |

### 2.1 Patron multi-linea real (evidencia historica)

Los 7 calls migrados en Paso 14 (commit `9058ed7`) comparten un unico patron:

```dart
// PATRON A — string literal en linea siguiente, ) en linea subsiguiente
debugPrint(
  '[Pipeline] Stage 1: Fetching idea...',   // <-- argumento en 1 linea
);
```

**Variantes detectadas en el diff:**
- `debugPrint(` solo en linea → `  'un solo string literal',` → `);` (6 de 7 calls)
- `debugPrint(` solo en linea → `  'string con ${interpolacion}',` → `);` (1 call en StitcherPlugin)

**Patrones NO encontrados pero posibles:**
- Multiples argumentos: `debugPrint(\n  'a',\n  'b',\n);` (Dart no soporta — `debugPrint` acepta 1 arg posicional)
- String multilinea: `debugPrint(\n  'line1'\n  'line2',\n);` (concatenacion implicita Dart)
- Expresiones complejas: `debugPrint(\n  someFunc() ?? 'fallback',\n);` 

### 2.2 Bug actual en `_fixDebugPrintCalls()`

**Ubicacion:** `debugprint_scanner.dart:206-222`

```dart
// Busca ) de cierre en MISMA linea
int depth = 0;
int endIdx = -1;
for (int j = idx + 'debugPrint('.length; j < modified.length; j++) {  // ← modified.length = fin de ESTA linea
  if (modified[j] == '(') depth++;
  if (modified[j] == ')') {
    if (depth == 0) {
      endIdx = j;
      break;
    }
    depth--;
  }
}

if (endIdx == -1) {
  // Malformed, skip         // ← AQUI abandona calls multi-linea
  searchFrom = idx + 1;
  continue;
}
```

**Causa raiz:** `_fixDebugPrintCalls` itera `for (int i = 0; i < lines.length; i++)` pero dentro de cada iteracion modifica `modified = lines[i]` y busca `)` dentro de ese string unico. Multi-linea → `)` en `lines[i+1]` o `lines[i+2]` → no encontrado → skip.

### 2.3 Estrategia de fix

**Enfoque: Line-based forward tracking** (rechazar AST/analyzer — ver D2).

En `_fixDebugPrintCalls`, cuando `endIdx == -1`:

1. **No hacer skip** — en vez, hacer `_findClosingParen(lines, startLine, startCol)` que:
   - Empieza en `lines[i]` desde `idx + 'debugPrint('.length`
   - Si `)` no encontrado en esta linea, avanza a `lines[i+1]`, `lines[i+2]`, etc.
   - Lleva contador `depth` a traves de lineas
   - Retorna `(endLine, endCol)` o `(-1, -1)` si malformado

2. **Extraer argumento multi-linea:** substring desde `(` hasta `)` a traves de lineas

3. **Reconstruir replacement:** `LoggerService.log('$tag', $arg)` preservando indentacion

4. **Reconstruir lineas afectadas:** merge de lineas originales + replacement

### 2.4 Modificaciones necesarias en `_fixDebugPrintCalls`

La funcion actual itera `for (int i = 0; i < lines.length; i++)` y construye `newLines` incrementalmente. Para soporte multi-linea, se necesita:

- **Variable `skipUntil`: int** — cuando el fix consume multiples lineas, saltarlas en iteraciones futuras
- **`_findClosingParenMultiLine(List<String> lines, int startLine, int startCol)`** — busca `)` a traves de lineas

**Pseudocodigo del nuevo flujo:**
```
for i in 0..lines.length:
  if i < skipUntil: continue
  
  line = lines[i]
  idx = line.indexOf('debugPrint(')
  if idx != -1 and no-comment and no-guard:
    (endLine, endCol) = _findClosingParenMultiLine(lines, i, idx + 'debugPrint('.length)
    if endLine == -1: skip  // malformed
    
    arg = extractMultiLineArg(lines, i, idx, endLine, endCol)
    replacement = "LoggerService.log('$tag', $arg)"
    
    if endLine == i:
      // single-line — existing logic
      modified = line[0..idx] + replacement + line[endCol+1..]
      newLines.add(modified)
    else:
      // multi-line
      firstLine = line[0..idx] + replacement + lines[endLine][endCol+1..]
      newLines.add(firstLine)
      skipUntil = endLine + 1
      replacements++
      continue  // skip lines consumed
```

### 2.5 Funcion auxiliar: `_findClosingParenMultiLine`

```dart
/// Returns (lineIndex, columnIndex) of matching `)` or (-1, -1)
(int, int) _findClosingParenMultiLine(List<String> lines, int startLine, int startCol) {
  int depth = 0;
  for (int li = startLine; li < lines.length; li++) {
    final line = lines[li];
    int j = (li == startLine) ? startCol : 0;
    for (; j < line.length; j++) {
      if (line[j] == '(') depth++;
      if (line[j] == ')') {
        if (depth == 0) return (li, j);
        depth--;
      }
    }
  }
  return (-1, -1);
}
```

### 2.6 Funcion auxiliar: `_extractMultiLineArg`

```dart
String _extractMultiLineArg(List<String> lines, int startLine, int openParenCol, int endLine, int endCol) {
  if (startLine == endLine) {
    return lines[startLine].substring(openParenCol + 1, endCol).trim();
  }
  // Multi-line: collect from first line after ( to last line before )
  final buf = StringBuffer();
  // First line: content after (
  buf.write(lines[startLine].substring(openParenCol + 1));
  // Middle lines
  for (int li = startLine + 1; li < endLine; li++) {
    buf.write('\n');
    buf.write(lines[li]);
  }
  // Last line: content before )
  if (endLine > startLine) {
    buf.write('\n');
    buf.write(lines[endLine].substring(0, endCol));
  }
  return buf.toString().trim();
}
```

### 2.7 Impacto en `_findDebugPrintCalls`

La deteccion actual ya funciona para multi-linea porque escanea cada linea independientemente buscando `debugPrint(`. La linea con `debugPrint(` sola sera detectada. **Sin cambios necesarios en deteccion.** Sin embargo, la columna y snippet reportados corresponderan solo a la linea inicial, no al call completo — aceptable para reporte.

### 2.8 Patrones de codigo a seguir

| Que crear/seguir | Referencia |
|---|---|
| Funcion helper en mismo archivo scanner | `_findClosingParenMultiLine` — misma convencion `_` privada que `_isInsideDebugModeBlock`, `_deriveTag` |
| Tests unitarios en `debugprint_scanner_test.dart` | Mismo patron: grupo `group('...')` con `test('TP-...')`, imports de `debugprint_detector.dart` |
| Tag derivado de nombre archivo | `_deriveTag()` existente — PascalCase |

---

## 3️⃣ Analisis de Backend (ETAPA 3)

**No aplica.** Paso 17 modifica exclusivamente scripts CLI (`dart:io`), sin APIs, endpoints ni servicios backend.

---

## 4️⃣ Analisis de Fullstack + DX (ETAPA 4)

### 4.1 Flujo completo

```
Usuario ejecuta: dart run scripts/debugprint_scanner.dart --fix
  → Scanner escanea 88+ archivos .dart en lib/
  → Detecta debugPrint( (incluyendo multi-linea)
  → Si multi-linea: busca ) a traves de lineas siguientes
  → Extrae argumento multi-linea
  → Reemplaza por LoggerService.log('Tag', arg)
  → Agrega import LoggerService si no existe
  → Escribe archivo modificado
  → Reporta reemplazos aplicados
```

### 4.2 Coherencia DX

El scanner `--fix` actual es **incompleto**: detecta `debugPrint(` multi-linea pero no puede corregirlo. El usuario debe migrar manualmente (como se hizo en Paso 14 → ~15min de trabajo manual en 5 archivos).

Con el fix, `--fix` cubre 100% de los patrones reales, eliminando intervencion manual.

### 4.3 Gaps detectados

| Gap | Descripcion | Impacto |
|---|---|---|
| G1 | `_findDebugPrintCalls` reporta multi-linea como "encontrado" pero snippet muestra solo `debugPrint(` parcial | Bajo — solo afecta output visual del scan |
| G2 | String concatenacion Dart implicita: `'a'\n  'b'` → `_extractMultiLineArg` debe preservar el string completo sin alterar sintaxis | Medio — si el argumento usa concatenacion, el reemplazo debe preservarla |
| G3 | Expresiones con parentesis anidados: `debugPrint(\n  someMap['key'],\n);` — los `[`/`]` no afectan depth de `(`/`)` pero complejizan extraccion | Bajo — patron no observado en codigo real |
| G4 | Multiples `debugPrint(` en archivo — `skipUntil` debe manejar correctamente la numeracion de lineas despues de modificaciones | Alto — riesgo de corromper archivo si skipUntil se desalinea |

### 4.4 DX Tooling

```
### Herramienta Propuesta: debugprint_scanner --fix multi-linea

- **Que automatiza:** Migracion de llamadas `debugPrint()` multi-linea a `LoggerService.log()` sin intervencion manual. Actualmente `--fix` solo corrige single-line; multi-linea requiere edicion manual (~3min por call, ~15min total Paso 14).

- **Tipo:** Mejora de CLI existente (no script nuevo)

- **Como se usa:** 
  dart run scripts/debugprint_scanner.dart --fix

- **Impacto para el usuario final:** 0 debugPrint residuales en lib/ garantizados con 1 comando. Sin edicion manual de archivos. Previene regresion cuando nuevos devs introduzcan debugPrint multi-linea.

- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## 5️⃣ Criterios de Aceptacion

```
✅ [CODE] _findClosingParenMultiLine() existe en debugprint_scanner.dart con firma (int, int) Function(List<String>, int, int)
✅ [CODE] _extractMultiLineArg() existe en debugprint_scanner.dart con firma String Function(List<String>, int, int, int, int)
✅ [CODE] _fixDebugPrintCalls() maneja endIdx == -1 via forward tracking (no skip)
✅ [CODE] skipUntil evita procesar lineas ya consumidas por fix multi-linea
✅ [CODE] Tag derivado de nombre archivo usando _deriveTag() existente
✅ [CODE] Import LoggerService se agrega automaticamente si no existe
✅ [TEST] Test: debugPrint multi-linea (patron A) es detectado por _findDebugPrintCalls
✅ [TEST] Test: debugPrint multi-linea (patron A) es corregido por _fixDebugPrintCalls → LoggerService.log
✅ [TEST] Test: debugPrint multi-linea con interpolacion es corregido correctamente
✅ [TEST] Test: debugPrint multi-linea con parentesis anidados en string no rompe depth counter
✅ [TEST] Test: archivo con multiples debugPrint (single + multi) → todos corregidos
✅ [TEST] Test: debugPrint multi-linea dentro de kDebugMode guard NO es corregido (falso positivo)
✅ [DX] dart run scripts/debugprint_scanner.dart --fix sobre archivo fixture multi-linea → 0 errores de sintaxis
✅ [DX] flutter analyze 0 issues en archivo fixture post --fix
✅ [FULLSTACK] Scanner --fix cubre 100% de patrones observados en codigo real (historial Paso 14)
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigacion |
|---|---|---|---|
| **Corrupcion de archivos por skipUntil desalineado** | 🔴 Alta | Si `_fixDebugPrintCalls` modifica lineas y `skipUntil` no recalcula offsets correctamente, lineas subsiguientes se escriben mal | Implementar enfoque alternativo: procesar `newLines` en vez de modificar in-place. Test golden con archivo fixture complejo |
| **No manejar strings con parentesis平衡** | 🟡 Media | String como `'func(x)'` contiene `(` y `)` que alteran depth counter | `_findClosingParenMultiLine` DEBE ignorar contenido de strings. Extender `stripStringsAndComments` del detector o implementar mini string-skipper |
| **Falso positivo en comentarios multi-linea** | 🟡 Media | `/* debugPrint(\n  'msg',\n); */` → detectado como call real | Reutilizar `_isInsideDebugModeBlock` + verificar si la linea `debugPrint(` esta dentro de `/* */` |
| **Romper tests existentes (31/31)** | 🟢 Baja | Cambios en `_fixDebugPrintCalls` pueden afectar firma o comportamiento single-line | Ejecutar `flutter test test/debugprint_scanner_test.dart` antes y despues de cada cambio. No modificar firma publica de funciones del detector |
| **Bug ID-001 en alignment_check bloquea validacion** | 🟡 Media | Regex `bool\\s+stripStringsAndComments` no matcha `String` → false positive | Fix trivial (1 linea). Incluir en Tarea 1 de este paso ya que es pre-requisito para verificacion final |

---

## 7️⃣ Plan de Implementacion

| # | Tarea | Artefacto | Interfaz exacta | Patron a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificacion |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: Test fixture multi-linea para validacion** | `test/debugprint_scanner_test.dart` (modificar) | Agregar grupo `group('multi-line debugPrint', ...)` con 6 tests: (1) detect patron A, (2) fix patron A, (3) fix con interpolacion, (4) fix con strings+pares, (5) no fix con kDebugMode guard, (6) fix multiples calls | Mismo patron que tests existentes: `group('...') { test('TP-...', () { ... }); }` | TEST | Media | 0.5h | Ninguna | → verificar: `flutter test test/debugprint_scanner_test.dart` 37/37 tests pasan |
| 1 | **Fix ID-001 en alignment_check** | `scripts/debugprint_alignment_check.dart` L70 | `final regex = RegExp('$fn\\\\s*\\\\(');` → `final regex = RegExp('(bool|String|int|void)\\\\s+$fn\\\\s*\\\(');` | Linea 70 del archivo | DX | Baja | 0.25h | Ninguna (pre-existente) | → verificar: `dart run scripts/debugprint_alignment_check.dart` reporta ALINEACION COMPLETA |
| 2 | **Implementar _findClosingParenMultiLine** | `scripts/debugprint_scanner.dart` (nueva fn privada) | `(int, int) _findClosingParenMultiLine(List<String> lines, int startLine, int startCol)` — retorna (lineIdx, colIdx) de `)` o (-1, -1). IGNORA parentesis dentro de strings (single/double quote + escapes). | `_isInsideDebugModeBlock` en mismo archivo (fn privada, opera sobre lines[]) | CODE | Alta | 1.5h | Tarea 0 | → verificar: test fixture multi-linea detecta `)` correctamente (test TP-M1 en Tarea 0) |
| 3 | **Implementar _extractMultiLineArg** | `scripts/debugprint_scanner.dart` (nueva fn privada) | `String _extractMultiLineArg(List<String> lines, int startLine, int openParenCol, int endLine, int endCol)` — extrae y trimmea argumento entre parentesis | `_deriveTag` en mismo archivo | CODE | Media | 0.75h | Tarea 2 | → verificar: extrae argumento correcto de fixture multi-linea (test TP-M2 en Tarea 0) |
| 4 | **Modificar _fixDebugPrintCalls para multi-linea** | `scripts/debugprint_scanner.dart` L163-263 | Agregar variable `skipUntil`, llamar `_findClosingParenMultiLine` cuando `endIdx == -1`, reconstruir `newLines` con skip. NO modificar firma publica. | Logica actual de `_fixDebugPrintCalls` para single-line (preservar inalterado) | CODE | Alta | 1.5h | Tareas 2, 3 | → verificar: `dart run scripts/debugprint_scanner.dart --fix` sobre archivo fixture multi-linea produce codigo valido (test TP-M3..M6 en Tarea 0) |
| 5 | **Validar sintaxis post-fix** | — | Ejecutar `flutter analyze` sobre archivo fixture post-fix. 0 errores de sintaxis o tipos | — | FULLSTACK | Baja | 0.25h | Tarea 4 | → verificar: `flutter analyze` 0 issues en archivo fixture + lib/ sin cambios |
| 6 | **Ejecutar bateria completa de validacion** | — | `flutter test test/debugprint_scanner_test.dart` (≥37 tests), `dart run scripts/debugprint_scanner.dart` (reporta 0 residuales), `dart run scripts/debugprint_migration_verifier.dart` (3/3 checks), `dart run scripts/debugprint_alignment_check.dart` (ALINEACION COMPLETA) | Patron verificador: `debugprint_migration_verifier.dart` | FULLSTACK | Baja | 0.5h | Tareas 0-5 | → verificar: todos los criterios §5 pasan |

**Tiempo total estimado:** 5.25 horas

---

## 🔮 Roadmap

- **Post-MVP — soporte AST completo:** Usar `package:analyzer` para parseo real de Dart en vez de regex/line-based. Cubriria 100% de edge cases (strings multi-linea `'''`, raw strings `r'...'`, comentarios `/* */` multi-linea, funciones anidadas). Justificado solo si aparecen patrones no cubiertos por el line-based parser.
- **Post-MVP — `--fix --all` flag:** Extender scanner para auto-aplicar `--fix` a TODOS los archivos sin confirmacion. Actualmente requiere ejecucion manual por archivo.
- **Post-MVP — integrar alignment_check en CI:** `dart run scripts/debugprint_alignment_check.dart` como paso de pre-commit hook para prevenir drift detector↔scanner.
- **Pre-requisito para Paso 18+:** Este fix garantiza que futuros pasos que introduzcan `debugPrint` multi-linea puedan ser corregidos automaticamente sin el trabajo manual del Paso 14.

---

## 📊 Metrica de Calidad

| Metrica | Estado |
|---|---|
| `proyecto-config.json` leido | ✅ |
| Elementos verificados (§0) | 12 (umbral: 8+) |
| Discrepancias detectadas | 3 (D1, D2, D3) |
| Secciones completadas | 8 (0-7) |
| Etapas cubiertas | DATA, CODE, FULLSTACK+DX (BACKEND no aplica) |
| Criterios de aceptacion | 15 (cubren CODE + TEST + DX + FULLSTACK) |
| Riesgos identificados | 5 (tecnico, integracion, futuro) |
| Tareas atomicas | 7 (1 artefacto cada una) |
| Interfaz exacta por tarea | 100% |
| Patron de referencia explicito | 100% |
| Verificacion inline por tarea | 100% |
| Suposiciones no verificadas | 0 |
| Propuesta DX / Tooling | 1 (mejora de `--fix` existente) |
| Estimacion de tiempo | 5.25h total |

---

## 🚫 Reglas de Oro — Cumplimiento

- ✅ Analisis accionable y especifico — cada tarea con firma y verificacion concreta
- ✅ TODO verificado contra codigo — 12 elementos en §0
- ✅ Plan contradice codigo → 3 discrepancias documentadas (D1-D3)
- ✅ Analisis cubre TODO el paso (5 tareas + 2 verificacion)
- ✅ Etapas secuenciales — data → code → backend → fullstack+DX
- ✅ ≥ 1 herramienta DX — mejora de `--fix` + fix ID-001 en alignment_check
- ✅ Tareas atomicas — 1 artefacto = 1 tarea, interfaz completa, patron explicito, verificacion inline
- ✅ Implementador no decide nada — firmas exactas, archivos concretos, patrones explicitos
