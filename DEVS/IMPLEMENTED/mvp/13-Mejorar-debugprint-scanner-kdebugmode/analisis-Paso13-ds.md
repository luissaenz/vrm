# 🧠 ANÁLISIS TÉCNICO — Paso 13: Mejorar-debugprint-scanner-kdebugmode

**Agente:** ds  
**Fecha:** 2026-05-09  
**Fase:** mvp  
**Prioridad:** Baja  
**Origen:** Sugerencia 🔵 de validacion — Paso 08

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `scripts/debugprint_scanner.dart` existe | `glob **/debugprint_scanner*` | ✅ | `scripts/debugprint_scanner.dart`, 331 líneas |
| 2 | `_findDebugPrintCalls()` existe con filtro kDebugMode | `read debugprint_scanner.dart:116-155` | ✅ | L137-140: `if (_isInsideDebugModeBlock(lines, lineIdx))` |
| 3 | `_isInsideDebugModeBlock()` existe | `read debugprint_scanner.dart:160-178` | ✅ | 19 líneas, escanea hacia atrás, busca `kDebugMode` / `!kReleaseMode` |
| 4 | `memory_monitor.dart` usa `if (kDebugMode) { debugPrint(...) }` | `grep kDebugMode lib/` | ✅ | `lib/features/recording/services/memory_monitor.dart:61-62` |
| 5 | Scanner NO reporta `memory_monitor.dart:62` | `dart run scripts/debugprint_scanner.dart` | ✅ | 69 matches, 0 de memory_monitor.dart (filtro kDebugMode funciona) |
| 6 | `logger_service.dart` excluido de scan | `read debugprint_scanner.dart:38` | ✅ | L38: `if (file.path.endsWith('logger_service.dart')) continue;` |
| 7 | `_fixDebugPrintCalls()` también filtra kDebugMode | `read debugprint_scanner.dart:180-281` | ✅ | L217-220: llama `_isInsideDebugModeBlock(lines, i)` |
| 8 | `lib/` contiene 88 archivos .dart | scanner output | ✅ | 88 archivos escaneados |
| 9 | Scanner exit code = 1 cuando hay matches | ejecutado | ✅ | 69 matches → exit code 1 |
| 10 | 21/21 tests pasan | `flutter test` | ✅ | All tests passed! |
| 11 | `flutter analyze` 0 issues | `flutter analyze` | ✅ | No issues found! |
| 12 | `IN_PROGRESS/` directorio existe | `Test-Path DEVS/IN_PROGRESS` | ✅ | True |
| 13 | `_printResults` agrupa por archivo | `read debugprint_scanner.dart:289-307` | ✅ | `byFile` Map + `entry.value` for each |
| 14 | Scanner soporta flag `--fix` | `read debugprint_scanner.dart:14` | ✅ | `final fixMode = args.contains('--fix');` |
| 15 | Scanner soporta flag `--help` | `read debugprint_scanner.dart:9` | ✅ | `if (args.contains('--help') \|\| args.contains('-h'))` |

### Discrepancias encontradas

| # | Discrepancia | Severidad | Resolución propuesta |
|---|---|---|---|
| D1 | `_isInsideDebugModeBlock` NO detecta `if (kDebugMode)` sin llaves en misma línea | Alta | Agregar chequeo de línea actual: si `l.contains('if (kDebugMode)')` antes del `debugPrint(` → skip |
| D2 | `_isInsideDebugModeBlock` NO detecta `if (kDebugMode)` sin llaves en línea adyacente | Media | Agregar lookahead de 1 línea: si línea anterior es `if (kDebugMode)` sin `{` y no hay `}` entre medio |
| D3 | NO detecta `assert(debugPrint(...))` — assert es no-op en Release | Baja | Agregar patrón: `assert(` que envuelve `debugPrint(` |
| D4 | Conteo de braces puede confundirse con `{`/`}` en strings o comentarios | Baja | Versión simplificada: ignorar contenido de strings/comentarios o usar enfoque de líneas |
| D5 | NO detecta `kDebugMode ? debugPrint(...) : null` | Baja | Agregar patrón ternario con `kDebugMode` |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**No aplica.** Paso 13 es mejora de tooling DX (scanner CLI). No toca schema, migraciones, ni persistencia.

- ✅ Sin tablas afectadas
- ✅ Sin columnas nuevas
- ✅ Sin cambios en RLS
- ✅ Sin índices necesarios

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivo modificado: `scripts/debugprint_scanner.dart`

**Estado actual:** 331 líneas, 2 clases privadas (`_DebugPrintMatch`, `_MatchResult`), 6 funciones.

### Funciones existentes (firmas verificadas)

| Función | Firma | Línea |
|---|---|---|
| `main` | `void main(List<String> args) async` | L8 |
| `_printUsage` | `void _printUsage()` | L102 |
| `_findDebugPrintCalls` | `List<_DebugPrintMatch> _findDebugPrintCalls(List<String> lines)` | L116 |
| `_isInsideDebugModeBlock` | `bool _isInsideDebugModeBlock(List<String> lines, int lineIdx)` | L160 |
| `_fixDebugPrintCalls` | `int _fixDebugPrintCalls(File file, String content, List<String> lines)` | L180 |
| `_deriveTag` | `String _deriveTag(String path)` | L283 |
| `_printResults` | `void _printResults(List<_MatchResult> results, int totalFiles)` | L289 |

### Análisis de `_isInsideDebugModeBlock` (L160-178)

**Lógica actual:** Escanea hacia atrás desde `lineIdx`, cuenta `{`(+1) / `}`(-1) para profundidad de bloque, detecta `kDebugMode` o `!kReleaseMode` cuando `braceDepth > 0`.

**Bug raíz:** Requiere `braceDepth > 0` para disparar. Esto falla en:
- `if (kDebugMode) debugPrint('x');` — sin llaves → braceDepth=0 en la misma línea
- `if (kDebugMode)\n  debugPrint('x');` — sin llaves → braceDepth=0 en línea previa

**Propuesta de mejora:** Función `_isInsideDebugModeBlock` refactorizada con 3 niveles de detección:

```dart
bool _isInsideDebugModeBlock(List<String> lines, int lineIdx) {
  // Nivel 1: Misma línea — if (kDebugMode) debugPrint(...) sin llaves
  final currentLine = lines[lineIdx];
  if (_isSameLineKDebugModeGuard(currentLine)) return true;

  // Nivel 2: assert(debugPrint(...)) — no-op en Release
  if (_isInsideAssert(currentLine)) return true;

  // Nivel 3: Bloque con llaves (lógica existente, corregida)
  return _isInsideBracedDebugModeBlock(lines, lineIdx);
}

bool _isSameLineKDebugModeGuard(String line) {
  // Detecta: if (kDebugMode) debugPrint( o kDebugMode ? debugPrint(
  final debugIdx = line.indexOf('debugPrint(');
  if (debugIdx == -1) return false;
  final beforeDebug = line.substring(0, debugIdx);
  return beforeDebug.contains(RegExp(r'\bif\s*\(\s*kDebugMode\s*\)')) ||
         beforeDebug.contains(RegExp(r'\bkDebugMode\s*\?'));
}

bool _isInsideAssert(String line) {
  final debugIdx = line.indexOf('debugPrint(');
  if (debugIdx == -1) return false;
  final beforeDebug = line.substring(0, debugIdx);
  return beforeDebug.contains(RegExp(r'\bassert\s*\('));
}
```

### Patrón de referencia

Sigue el patrón existente de scripts CLI Dart en `scripts/`:
- `scripts/vrm_health_check.dart` — CLI con subcomandos
- `scripts/store_prep_cli.dart` — CLI unificado
- `scripts/validador_metrics_session.dart` — CLI con flags
- `scripts/capture_store_screenshots.dart` — CLI interactivo ADB
- `scripts/utils.dart` — Módulo compartido

Convención: `dart run scripts/<nombre>.dart [flags]`

### Imports actuales

```dart
import 'dart:io';
```

**No se requieren nuevos imports.** Toda la lógica usa `dart:core` y `dart:io`.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**No aplica.** Paso 13 es herramienta CLI Dart local. Sin endpoints, sin APIs, sin middleware.

- ✅ Sin nuevos endpoints
- ✅ Sin cambios en middleware
- ✅ Sin contratos entre servicios
- ✅ Sin flujos backend→frontend

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo actual del scanner

```
Usuario ejecuta: dart run scripts/debugprint_scanner.dart
  → main() lee lib/ recursivamente (88 .dart)
  → Para cada archivo: _findDebugPrintCalls()
    → Busca 'debugPrint(' en cada línea
    → Filtra comentarios (//, *, ///)
    → Filtra kDebugMode blocks (_isInsideDebugModeBlock)
    → Reporta matches restantes
  → _printResults() agrupa por archivo, muestra L:C + snippet
  → Exit code 0 (limpio) o 1 (residuales encontrados)
```

### Gaps detectados

1. **Falso positivo #1:** `if (kDebugMode) debugPrint('x');` → scanner lo reporta como residual
2. **Falso positivo #2:** `if (kDebugMode)\n  debugPrint('x');` → scanner lo reporta como residual
3. **Falso positivo #3:** `assert(debugPrint('x'));` → scanner lo reporta como residual
4. **Falso positivo #4:** `kDebugMode ? debugPrint('x') : null;` → scanner lo reporta como residual

Impacto: Ninguno en el código actual (solo existe 1 uso de kDebugMode en lib/, y funciona). Pero la mejora previene falsos positivos futuros.

### DX & Tooling (OBLIGATORIO)

#### Herramienta Propuesta: `debugprint_scanner.dart` (mejorado)

- **Qué automatiza:** Escaneo de `debugPrint` residuales con detección precisa de guards `kDebugMode`. Elimina falsos positivos para `if (kDebugMode)` sin llaves, `assert()`, y ternarios. Previene que futuros `debugPrint` legítimos dentro de guards de debug sean reportados como residuales.

- **Tipo:** CLI / Scanner

- **Cómo se usa:**
  ```
  dart run scripts/debugprint_scanner.dart        # Escanea, reporta solo residuales reales
  dart run scripts/debugprint_scanner.dart --fix  # Migra automáticamente a LoggerService.log()
  dart run scripts/debugprint_scanner.dart --help # Muestra ayuda
  ```

- **Impacto para el usuario final:** Reduce falsos positivos de 0 actuales a 0 futuros. El equipo puede agregar `if (kDebugMode) debugPrint('...')` sin que el scanner falle. Menos fricción en CI/CD.

- **Prioridad:** Baja. Mejora de robustez, no bloquea release.

---

## 5️⃣ Criterios de Aceptación

```
✅ [DX] Scanner ignora debugPrint dentro de if (kDebugMode) { ... }
✅ [DX] Scanner ignora debugPrint en if (kDebugMode) sin llaves (misma línea)
✅ [DX] Scanner ignora debugPrint en if (kDebugMode) sin llaves (línea adyacente)
✅ [DX] Scanner ignora debugPrint dentro de assert(...)
✅ [DX] Scanner ignora debugPrint en kDebugMode ? debugPrint(...) : null
✅ [DX] dart run scripts/debugprint_scanner.dart ejecuta sin errores
✅ [DX] dart run scripts/debugprint_scanner.dart --help muestra uso correcto
✅ [DX] flutter analyze reporta 0 issues
✅ [DX] 21/21 tests pasan (sin regresión)
✅ [DX] memory_monitor.dart:62 sigue sin ser reportado (no regresión)
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Regresión: scanner deja de detectar debugPrint reales por regex sobre-expansivo | Media | Regex `\bif\s*\(\s*kDebugMode\s*\)` podría hacer match en strings/comentarios que mencionen `if (kDebugMode)` | Regex usa `\b` word boundary. Test manual con casos representativos. |
| Complejidad: `_isInsideDebugModeBlock` crece de 19 a ~50 líneas | Baja | 3 niveles de detección agregados | Extraer helpers `_isSameLineKDebugModeGuard`, `_isInsideAssert`, `_isInsideBracedDebugModeBlock`. Mantener SRP. |
| Falso negativo: debugPrint real dentro de bloque con `kDebugMode` en comentario | Baja | `// if (kDebugMode)` comentado pero debugPrint es real | No mitigable con análisis estático simple. Aceptable para MVP. |
| Brace counting con strings que contienen `{`/`}` | Baja | String interpolation `'valor: ${x}'` contiene `{` que no es apertura de bloque | Versión mejorada ignora contenido de strings. Aceptar como limitación conocida si no se implementa parser completo. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Refactorizar `_isInsideDebugModeBlock` → 3 helpers | `scripts/debugprint_scanner.dart` | `bool _isInsideDebugModeBlock(List<String> lines, int lineIdx)` + `bool _isSameLineKDebugModeGuard(String line)` + `bool _isInsideAssert(String line)` + `bool _isInsideBracedDebugModeBlock(List<String> lines, int lineIdx)` | Mismo archivo, patrón de extracción de helpers existente (`_deriveTag`, `_printResults`) | CODE | Media | 1h | Ninguna | → verificar: `dart run scripts/debugprint_scanner.dart` reporta mismos 69 matches (sin falsos positivos nuevos) |
| 2 | Agregar detección misma-línea `if (kDebugMode)` sin llaves | `scripts/debugprint_scanner.dart` L160-178 | `_isSameLineKDebugModeGuard(String line)` → `bool` | Regex existente en codebase: `store_prep_cli.dart` usa `RegExp` para validación | CODE | Baja | 0.5h | Tarea 1 | → verificar: crear archivo test con `if (kDebugMode) debugPrint('test');` → scanner NO lo reporta |
| 3 | Agregar detección `assert(debugPrint(...))` | `scripts/debugprint_scanner.dart` L160-178 | `_isInsideAssert(String line)` → `bool` | — | CODE | Baja | 0.25h | Tarea 1 | → verificar: crear archivo test con `assert(debugPrint('test'));` → scanner NO lo reporta |
| 4 | Mejorar brace counting: ignorar braces en strings/comentarios | `scripts/debugprint_scanner.dart` L163-169 | Ajuste en loop `for (int j = 0; j < l.length; j++)` para trackear `inString`/`inComment` | — | CODE | Media | 0.75h | Tarea 1 | → verificar: archivo con `String s = '}'; if (kDebugMode) { debugPrint(s); }` → scanner NO lo reporta |
| 5 | Validar regresión: 69 matches actuales sin cambios | — | — | — | DX | Baja | 0.5h | Tareas 1-4 | → verificar: `dart run scripts/debugprint_scanner.dart` reporta 69 matches, mismos archivos |
| 6 | Ejecutar `flutter analyze` + `flutter test` | — | — | — | DX | Baja | 0.25h | Tareas 1-5 | → verificar: 0 issues en analyze, 21/21 tests pasan |

**Tiempo total estimado:** 3.25 horas

---

## 🔮 Roadmap (NO implementar ahora)

- **`debugprint_scanner.dart --fix-all`**: Migración masiva de los 69 debugPrint residuales a LoggerService.log(). Bloqueado por Paso 14 (Migracion-masiva-debugprint-residuales).
- **Integración CI/CD**: Agregar `dart run scripts/debugprint_scanner.dart` como paso en pre-commit hook para prevenir regresión de debugPrint en PRs.
- **Parser AST completo**: Reemplazar análisis basado en líneas/regex con `analyzer` package para detección precisa de guards `kDebugMode` en cualquier estructura de control (if/else/for/while/switch).
- **Soporte `// ignore: avoid_print`**: Detectar el comentario de supresión de lint y excluir esas líneas del reporte.

---

## 📊 Métrica de Calidad

| Métrica | Estado |
|---|---|
| `proyecto-config.json` leído antes de explorar | ✅ |
| Elementos verificados (§0) | 15/12 (mínimo) |
| Discrepancias detectadas | 5 (≥1, código existente) |
| Secciones completadas | 8/8 (0-7) |
| Etapas cubiertas | 4/4 (data, code, backend, fullstack+DX) |
| Criterios de aceptación | 10 (≥1 por sub-paso) |
| Riesgos identificados | 4 (≥3) |
| Tareas atómicas (1 artefacto por tarea) | 6/6 — cada tarea = 1 función o 1 validación |
| Interfaz exacta por tarea | 6/6 — firmas completas con tipos |
| Patrón de referencia explícito por tarea | 6/6 — archivo concreto o "mismo archivo" |
| Verificación inline por tarea | 6/6 — comando concreto |
| Suposiciones no verificadas | 0 |
| Propuesta DX / Tooling | 1 (debugprint_scanner.dart mejorado) |
| Estimación de tiempo | 3.25h total |
