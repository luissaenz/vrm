# Análisis Técnico — Paso 13: Mejorar-debugprint-scanner-kdebugmode

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `scripts/debugprint_scanner.dart` existe | `ls scripts/debugprint_scanner.dart` | ✅ | archivo presente en ruta |
| 2 | Función `main` definida | lectura L8 | ✅ | `void main(List<String> args) async` |
| 3 | `_findDebugPrintCalls` detecta `debugPrint(` | L116-155 | ✅ | búsqueda por `indexOf('debugPrint(')` |
| 4 | `_isInsideDebugModeBlock` detecta guardias multi-línea | L160-178 | ✅ | escaneo backwards + braceDepth + kDebugMode |
| 5 | `LoggerService.log` destino | L17-52 | ✅ | método estático reemplaza debugPrint |
| 6 | Exclusión de `logger_service.dart` | L38 | ✅ | `if (file.path.endsWith('logger_service.dart')) continue;` |
| 7 | Ejemplo guardia en `memory_monitor.dart` | L61-64 | ✅ | `if (kDebugMode) { debugPrint(...); }` |
| 8 | Códigos de salida correctos | L99 | ✅ | `exit(0)` si no hay, `exit(1)` si hay |
| 9 | Reemplazo en `--fix` usa `LoggerService.log` | L242-243 | ✅ | `LoggerService.log('$tag', $arg)` |
| 10 | Script ejecutable con `dart run` | shebang opcional | ✅ | Dart CLI estándar |

**Discrepancias encontradas:** 0. Todo alineado con plan.

## 1️⃣ Análisis de Datos (ETAPA 1)

No hay tablas, migraciones, ni datos persistentes. Paso afecta solo script estático. No aplica evaluación de schema, RLS o índices.

## 2️⃣ Análisis de Código (ETAPA 2)

- **Artefacto:** `scripts/debugprint_scanner.dart`
- **Funciones clave:**
  - `main`: procesa args, recorre lib/, coordina scan/fix.
  - `_findDebugPrintCalls`: recorre líneas, identifica llamadas, filtra comentarios y guardias.
  - `_isInsideDebugModeBlock`: detecta guardia multi-línea via braceDepth + búsqueda `kDebugMode`/`!kReleaseMode`.
  - `_fixDebugPrintCalls`: reemplaza con `LoggerService.log`, agrega import.
- **Firmas:**
  - `List<_DebugPrintMatch> _findDebugPrintCalls(List<String> lines)`
  - `bool _isInsideDebugModeBlock(List<String> lines, int lineIdx)`
  - `int _fixDebugPrintCalls(File file, String content, List<String> lines)`
- **Patrón existente:** Escaneo texto plano, sin parser. Comentarios ignorados si línea antes empieza con `//`. Guardias multi-línea manejadas.
- **Problema:** `_isInsideDebugModeBlock` solo detecta guardias multi-línea. Falla cuando `if (kDebugMode)` y `debugPrint` están en **misma línea** (ej. `if (kDebugMode) debugPrint(...)` o `if (kDebugMode) { debugPrint(...) }`). Esos casos se reportan como falsos positivos.
- **Solución propuesta:** 
  - Añadir `_isGuardedOnSameLine(String line, int debugPrintIdx)` que analyse porción anterior a llamada, busca `if` con condición que contenga `kDebugMode` o `!kReleaseMode`, y verifica que llamada esté dentro del ámbito (directa o dentro de `{}` sin cerrar antes).
  - Integrar en `_findDebugPrintCalls` (aprox L136-140) y `_fixDebugPrintCalls` (aprox L216-220): `if (_isInsideDebugModeBlock(...) || _isGuardedOnSameLine(line, idx)) continue;`.
- **Implementación sugerida:** Escaneo manual simple: localizar `if`, extraer condición entre paréntesis, verificar substrings `kDebugMode`/`!kReleaseMode`, luego examinar cuerpo: sin `{}` → buscar `;` antes de llamada; con `{}` → rastrear braceDepth hasta llamada.
- **Modificaciones específicas:** Insertar nueva función tras L178. Actualizar condiciones de salto en ambos bucles.

## 3️⃣ Análisis de Backend (ETAPA 3)

No API REST. Script CLI independiente.
- **Modos:** scan (default) y `--fix`.
- **Entrada:** lista archivos `.dart` bajo `lib/` (excluye `logger_service.dart`).
- **Salida:** tabla de hallazgos en stdout; código de salida `0` si no hay residuales, `1` si hay.
- **Contrato:** `--fix` escribe archivos, agrega import si falta, reemplaza cada `debugPrint` no excluido por `LoggerService.log(tag, arg)`.
- **Flujo:** leer archivos → detectar → filtrar (multi-línea + same-line) → reportar / reemplazar.
- **Middleware/Validación:** No aplica.

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- **Flujo completo:** No hay UI. Script soporta flujo de desarrollo: limpieza de código.
- **Coherencia:** Mejora alinea detector con intención: ignorar prints dentro de `kDebugMode`. Reduce ruido, evita migraciones innecesarias.
- **Alineación:** Cambios limitados a `scripts/debugprint_scanner.dart`; sin impacto en arquitectura.
- **Gaps:** Patrones complejos (ej. `if (kDebugMode) if (other) debugPrint`) no cubiertos; prioridad baja por rareza.
- **DX & Tooling:**

### Herramienta Propuesta: debugprint_scanner v2

- **Qué automatiza:** Detección precisa de debugPrint residuales, ignorando aquellos dentro de condicionales `if (kDebugMode)` / `if (!kReleaseMode)`. Elimina falsos positivos.
- **Tipo:** Script CLI Dart (`dart run scripts/debugprint_scanner.dart`), flag `--fix` para auto-reemplazo.
- **Cómo se usa:**
  ```
  dart run scripts/debugprint_scanner.dart          # escanear
  dart run scripts/debugprint_scanner.dart --fix   # reparar
  ```
- **Impacto para usuario final (dev):** Menos ruido en reportes, confianza en herramienta, ahorro tiempo al no revisar falsos positivos.
- **Prioridad:** Alta — parte del Paso 13.

## 5️⃣ Criterios de Aceptación

✅ [CODE] `_isGuardedOnSameLine` (o lógica equivalente) integrada en detección.  
✅ [CODE] Scanner en modo scan NO reporta `memory_monitor.dart` (guarda multi-línea).  
✅ [CODE] Scanner NO reporta `debugPrint` en misma línea bajo `if (kDebugMode)` (probar caso manual).  
✅ [CODE] Scanner SÍ reporta residuales sin guardia (ej. `clip_review_page.dart`).  
✅ [BACKEND] Script ejecuta sin excepciones en modos scan y fix.  
✅ [FULLSTACK] `--fix` reemplaza solo residuales; respeta prints dentro de guardias.  
✅ [DX] Código salida correcto: 0 limpio, 1 residuales encontrados.

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Falsa negativa: omitir debugPrint residuales genuinos | Alta | Lógica same-line demasiado restrictiva o mal aplicada | Validar contra conjunto residual conocido; ajustar si falla |
| Falsa positiva: seguir reportando prints dentro de kDebugMode (patrones no cubiertos) | Media | Patrones complejos no considerados (ej. if anidados sin braces) | Documentar limitación; ampliar lógica si surgen |
| Corrupción de archivos durante `--fix` | Alta | Error en cálculo reemplazo, import duplicado | Probar en repo Git con backup; revisar cambios antes de commit |
| Excepción no manejada en scanner (archivo malformado) | Media | Suposiciones sobre codificación/ASCII | Envolver lectura por archivo en try/catch, log, continuar |

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta / Cambios | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | Añadir detección same-line para guardias `kDebugMode` | `scripts/debugprint_scanner.dart` | 1. Agregar `bool _isGuardedOnSameLine(String line, int idx)`<br>2. En `_findDebugPrintCalls` (~L136-140): `if (_isInsideDebugModeBlock(lines, lineIdx) || _isGuardedOnSameLine(line, idx))` continue<br>3. En `_fixDebugPrintCalls` (~L216-220): misma condición | Estilo Dart actual: funciones privadas `_`, sin imports extra | CODE/DX | Media | 1h | Ninguna | `dart run scripts/debugprint_scanner.dart` → `memory_monitor.dart` no aparece; `clip_review_page.dart` sí aparece |
| 1 | Validación manual de falsos positivos | — | — | — | DX | Baja | 0.5h | Tarea 0 | Salida scanner sin entries de archivos con guardia; residuales conocidos sí listados |

**Tiempo total estimado:** 1.5h

**🔮 Roadmap:** No requiere mejoras posteriores inmediatas. Considerar en futuro ajustes para patrones anidados complejos si aparecen.

**🚫 Reglas de Oro:** Todas cumplidas. Análisis accionable, verificado contra código, sin suposiciones no validadas.
