# 📋 Análisis Técnico — Paso 14: Migracion-masiva-debugprint-residuales
**Agente:** op | **Fecha:** 2026-05-09

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `debugprint_scanner.dart` existe | grep en `scripts/` | ✅ | `scripts/debugprint_scanner.dart` (319L) |
| 2 | `debugprint_detector.dart` existe | grep en `scripts/` | ✅ | `scripts/debugprint_detector.dart` (165L) |
| 3 | `LoggerService` singleton disponible | lectura `lib/core/services/logger_service.dart` | ✅ | L10-53, método `static log(tag, message, {error, stack})` |
| 4 | Scanner `--fix` flag implementado | lectura `debugprint_scanner.dart:16` | ✅ | `final fixMode = args.contains('--fix');` → L167 `_fixDebugPrintCalls()` |
| 5 | Scanner excluye `logger_service.dart` | lectura `debugprint_scanner.dart:40` | ✅ | `if (file.path.endsWith('logger_service.dart')) continue;` |
| 6 | Scanner detecta guards kDebugMode | ejecución scanner | ✅ | `memory_monitor.dart:62` correctamente ignorado (guard `if (kDebugMode)` L61) |
| 7 | Plan dice "~70 debugPrint residuales" | ejecución `dart run scripts/debugprint_scanner.dart` | ❌ DISCREPANCIA | Scanner reporta **7 residuales** en 5 archivos, no ~70. Plan desactualizado post-Paso 08+13 |
| 8 | `--fix` maneja multilínea | lectura `_fixDebugPrintCalls()` L209-227 | ❌ DISCREPANCIA | Busca `)` en misma línea. Si `endIdx == -1` → skip. 6 de 7 residuales son multilínea → `--fix` NO los migra |
| 9 | `vrm_pipeline.dart` tiene 3 debugPrint | grep L30,43,58 | ✅ | Todos multilínea (arg en línea sig). Sin guard kDebugMode → residuales |
| 10 | `stitcher_plugin.dart` tiene 1 debugPrint | grep L37 | ✅ | Multilínea. Dentro de callback `onProgress`. Sin guard → residual |
| 11 | `schema_validator.dart` tiene 1 debugPrint | grep L36 | ✅ | Multilínea. Sin guard → residual |
| 12 | `clip_storage_service.dart` tiene 1 debugPrint | grep L168 | ✅ | Multilínea. En fallback path. Sin guard → residual |
| 13 | `social_account_manager.dart` tiene 1 debugPrint | grep L32 | ✅ | Multilínea. Sin guard → residual |
| 14 | `memory_monitor.dart:62` debugPrint | grep L62 | ✅ | Dentro `if (kDebugMode)` L61 → INTENCIONAL. Scanner lo ignora correctamente |
| 15 | `logger_service.dart:48` debugPrint | grep L48 | ✅ | Intencional (echo en debug mode). Scanner excluye archivo completo |
| 16 | LoggerService import ya presente en archivos | lectura archivos | ✅ | `vrm_pipeline.dart:10`, `clip_storage_service.dart:8`, `social_account_manager.dart:7`, `schema_validator.dart:5` ya importan LoggerService |
| 17 | `stitcher_plugin.dart` importa LoggerService | lectura archivo | ❌ DISCREPANCIA | NO importa LoggerService. Necesita agregar import |
| 18 | `flutter/foundation.dart` import en archivos | lectura archivos | ✅ | Todos los 5 archivos importan `flutter/foundation.dart` (provee `debugPrint`). Verificar si queda usado post-migración |

**Discrepancias encontradas:**

1. **D1 — Plan dice ~70 residuales, realidad = 7.** Plan.md L332 dice "~70 `debugPrint` residuales en `lib/`". Scanner real encuentra 7. Causa: Paso 08 documentó 72 residuales en 15 archivos, pero scanner Paso 13 mejoró detección de guards (kDebugMode, assert, ternario, braced blocks). Muchos eran intencionales. **Resolución:** Paso 14 scope = migrar 7 residuales, no ~70.

2. **D2 — `--fix` no maneja multilínea.** 6 de 7 residuales son multilínea (debugPrint en línea X, argumento en línea X+1). `_fixDebugPrintCalls()` L209-227 busca `)` en misma línea → `endIdx == -1` → skip. **Resolución:** Migración manual de los 7 debugPrint. `--fix` queda para Paso 17 (mejora parser multilínea). Alternativa: implementar mini-parser multilínea en Tarea 0 DX.

3. **D3 — `stitcher_plugin.dart` no importa LoggerService.** Otros 4 archivos ya tienen import. Este archivo solo importa `flutter/foundation.dart`. **Resolución:** Agregar `import 'package:vrm_app/core/services/logger_service.dart';` en Tarea 4.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ **Schema:** Sin cambios. No hay tablas/JSON schemas afectados.
- ✅ **Integridad referencial:** N/A — paso puramente de código.
- ✅ **RLS/Permisos:** N/A.
- ✅ **Índices:** N/A.
- ✅ **Tipos de datos:** N/A.

Paso 14 no toca datos. Solo refactor de logging en código.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivos afectados (5 archivos, 7 reemplazos)

| Archivo | Línea | Tipo | debugPrint call | Tag LoggerService propuesto |
|---|---|---|---|---|
| `vrm_pipeline.dart` | L30-32 | multilínea | `debugPrint('[Pipeline] Stage 1: ...')` | `'VRMPipeline'` |
| `vrm_pipeline.dart` | L43-45 | multilínea | `debugPrint('[Pipeline] Stage 2: ...')` | `'VRMPipeline'` |
| `vrm_pipeline.dart` | L58-60 | multilínea | `debugPrint('[Pipeline] Stage 3: ...')` | `'VRMPipeline'` |
| `stitcher_plugin.dart` | L37-39 | multilínea | `debugPrint('Stitching progress: ...')` | `'StitcherPlugin'` |
| `schema_validator.dart` | L36-38 | multilínea | `debugPrint('✅ [SchemaValidator] ...')` | `'SchemaValidator'` |
| `clip_storage_service.dart` | L168-170 | multilínea | `debugPrint('[ClipStorage] Clip saved ...')` | `'ClipStorageService'` |
| `social_account_manager.dart` | L32-34 | multilínea | `debugPrint('Account connected: ...')` | `'SocialAccountManager'` |

### Patrón existente (referencia)

Archivos ya migrados siguen patrón idéntico (ref: `recording_page.dart` Paso 05):
```dart
// ANTES:
debugPrint('Setting flash mode to $mode');

// DESPUÉS:
LoggerService.log('RecordingPage', 'Setting flash mode to $mode');
```

**Firma LoggerService.log:**
```dart
static Future<void> log(String tag, String message, {Object? error, StackTrace? stack}) async
```

### Import requerido
```dart
import 'package:vrm_app/core/services/logger_service.dart';
```

### Imports `flutter/foundation.dart` post-migración

Verificar si `kDebugMode` u otro símbolo de `foundation.dart` se usa en cada archivo tras migración:

| Archivo | Otros usos de foundation.dart | Acción |
|---|---|---|
| `vrm_pipeline.dart` | NO — solo usa `debugPrint` | ⚠️ Puede quedar unused import. Verificar con `flutter analyze` |
| `stitcher_plugin.dart` | NO — solo usa `debugPrint` | ⚠️ Probable unused import |
| `schema_validator.dart` | NO — solo usa `debugPrint` | ⚠️ Probable unused import |
| `clip_storage_service.dart` | SÍ — `kDebugMode` NO se usa, pero `@required`/`@protected` posibles. Verificar | ⚠️ Revisar |
| `social_account_manager.dart` | NO — solo usa `debugPrint` | ⚠️ Probable unused import |

**Predicción:** 4-5 archivos quedarán con `import 'package:flutter/foundation.dart'` unused → `flutter analyze` reportará warnings. Misma situación corregida en Paso 13 (ID-001).

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ **APIs/Endpoints:** Sin cambios. Backend FastAPI no afectado.
- ✅ **Middleware:** N/A.
- ✅ **Flujos:** Logging cambia de `debugPrint` (no-op en Release) → `LoggerService.log` (persiste a disco). Mejora observabilidad en producción.
- ✅ **Contratos:** Sin cambios en interfaces.
- ✅ **Error handling:** Sin cambios — `debugPrint` no es error handling, es tracing.

### Impacto en producción

`debugPrint` es **no-op en Release mode** → mensajes se pierden. `LoggerService.log` escribe a `vrm_data/logs/app.log` con rotación (512KB) → mensajes persisten en Release. Esto es **mejora de observabilidad**, no cambio funcional.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
debugPrint (no-op Release) → LoggerService.log (persiste a disco)
                                      ↓
                              vrm_data/logs/app.log (rotación 512KB)
```

- ✅ Coherencia: misma estrategia que Pasos 05/08. Unifica logging.
- ✅ Alineación: código gana sobre plan (~7 vs ~70).
- ✅ Gaps: `--fix` multilínea no funciona → migración manual requerida.

### Herramienta Propuesta: `debugprint_fix_multiline.dart`

- **Qué automatiza:** Parser multilínea para `--fix` que soporta debugPrint en múltiples líneas (arg en línea siguiente). Reemplaza manualmente los 7 residuales actual y previene futuros.
- **Tipo:** script CLI (extensión de scanner existente)
- **Cómo se usa:** `dart run scripts/debugprint_fix_multiline.dart --dry-run` (preview) → `dart run scripts/debugprint_fix_multiline.dart --apply` (ejecutar)
- **Impacto para el usuario final:** Elimina migración manual de ~7 calls multilínea. Reduce de ~15min a ~2s.
- **Prioridad:** Tarea 0 — implementar antes que migraciones manuales

**DECISIÓN CRÍTICA:** Implementar mini-fixer como Tarea 0 vs migrar manualmente 7 calls.

Dado que son solo 7 calls y el Paso 17 ya planifica parser multilínea completo → **migración manual es más eficiente**. DX tool = **verificador post-migración** que confirma 0 residuales.

### Herramienta Propuesta (ajustada): `debugprint_migration_verifier.dart`

- **Qué automatiza:** Verificación post-migración: ejecuta scanner + confirma 0 residuales + valida imports limpios + `flutter analyze` 0 issues
- **Tipo:** script CLI
- **Cómo se usa:** `dart run scripts/debugprint_migration_verifier.dart`
- **Impacto para el usuario final:** Evita regresión. Confirma migración completa en ~2s sin revisión manual.
- **Prioridad:** Tarea 0 — ejecutar antes y después de migraciones

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] 0 debugPrint residuales reportados por `dart run scripts/debugprint_scanner.dart` (exit code 0)
✅ [CODE] `vrm_pipeline.dart` usa LoggerService.log('VRMPipeline', ...) en L30, L43, L58
✅ [CODE] `stitcher_plugin.dart` usa LoggerService.log('StitcherPlugin', ...) en L37
✅ [CODE] `schema_validator.dart` usa LoggerService.log('SchemaValidator', ...) en L36
✅ [CODE] `clip_storage_service.dart` usa LoggerService.log('ClipStorageService', ...) en L168
✅ [CODE] `social_account_manager.dart` usa LoggerService.log('SocialAccountManager', ...) en L32
✅ [CODE] `stitcher_plugin.dart` importa `package:vrm_app/core/services/logger_service.dart`
✅ [CODE] 0 `import 'package:flutter/foundation.dart'` unused → `flutter analyze` 0 issues
✅ [CODE] `memory_monitor.dart:62` sigue usando debugPrint dentro de `if (kDebugMode)` (intencional, no migrar)
✅ [CODE] `logger_service.dart:48` sigue usando debugPrint (intencional, echo en debug mode)
✅ [FULLSTACK] `flutter test` pasa todos los tests existentes (52/52)
✅ [DX] `dart run scripts/debugprint_migration_verifier.dart` ejecuta sin errores y confirma 0 residuales
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Imports `flutter/foundation.dart` unused post-migración | Media | debugPrint era único uso de foundation.dart en 4-5 archivos | Verificar con `flutter analyze` tras cada migración. Eliminar import si no hay otros usos. Patrón ya resuelto en Paso 13 ID-001 |
| `LoggerService.log()` es `async` pero debugPrint era sync | Baja | LoggerService escribe a disco (async). Pipeline calls eran fire-and-forget debugPrint | No usar `await` en calls de tracing — mantener fire-and-forget pattern (`LoggerService.log(...)` sin await). Mismo patrón que L78 `vrm_pipeline.dart` ya existente |
| Regresión en tests por cambio de imports | Baja | Tests mock debugPrint indirectamente. Si test depende de console output → podría fallar | Ejecutar `flutter test` post-migración. Tests existentes no verifican console output → riesgo mínimo |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Crear verificador migración | `scripts/debugprint_migration_verifier.dart` | `void main(List<String> args)` — ejecuta scanner + valida 0 residuales + lista unused imports + sugiere removal | `scripts/debugprint_scanner.dart :: main()` | DX | Baja | 20min | Ninguna | → verificar: `dart run scripts/debugprint_migration_verifier.dart --help` ejecuta sin errores |
| 1 | Migrar 3 debugPrint en `vrm_pipeline.dart` | `lib/core/pipeline/vrm_pipeline.dart` | L30-32: `LoggerService.log('VRMPipeline', '[Pipeline] Stage 1: Fetching idea with plugin ${ideaSource.pluginId}')`, L43-45: ídem Stage 2, L58-60: ídem Stage 3. Verificar si `import 'package:flutter/foundation.dart'` queda unused → eliminar si sí | `lib/core/pipeline/vrm_pipeline.dart :: L78` (ya usa `LoggerService.log`) | CODE | Baja | 10min | Tarea 0 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta `vrm_pipeline.dart` + `flutter analyze` 0 issues en archivo |
| 2 | Migrar 1 debugPrint en `schema_validator.dart` | `lib/core/services/schema_validator.dart` | L36-38: `LoggerService.log('SchemaValidator', '✅ Contrato "$schemaName" validado correctamente')`. Verificar unused `flutter/foundation.dart` → eliminar si sí | `lib/core/services/schema_validator.dart :: L22-29` (ya usa LoggerService en validation errors) | CODE | Baja | 5min | Tarea 0 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta `schema_validator.dart` |
| 3 | Migrar 1 debugPrint en `clip_storage_service.dart` | `lib/features/recording/services/clip_storage_service.dart` | L168-170: `LoggerService.log('ClipStorageService', '[ClipStorage] Clip saved (fallback): $destPath ($size bytes)')`. `flutter/foundation.dart` tiene `kDebugMode` usado en archivo? → verificar. Ya importa LoggerService | `lib/features/recording/services/clip_storage_service.dart :: L143-146` (ya usa LoggerService.log en save path primario) | CODE | Baja | 5min | Tarea 0 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta `clip_storage_service.dart` |
| 4 | Migrar 1 debugPrint en `stitcher_plugin.dart` + agregar import | `lib/core/plugins/default/stitcher_plugin.dart` | L37-39: `LoggerService.log('StitcherPlugin', 'Stitching progress: ${progress.progress} - ${progress.status}')`. Agregar `import 'package:vrm_app/core/services/logger_service.dart';` después de L1. Verificar unused `flutter/foundation.dart` → eliminar si sí | `lib/core/pipeline/vrm_pipeline.dart :: L78` (LoggerService.log con tag PascalCase) | CODE | Baja | 5min | Tarea 0 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta `stitcher_plugin.dart` |
| 5 | Migrar 1 debugPrint en `social_account_manager.dart` | `lib/features/social_accounts/social_account_manager.dart` | L32-34: `LoggerService.log('SocialAccountManager', 'Account connected: ${account.name} on ${platform.displayName}')`. Ya importa LoggerService (L7). Verificar unused `flutter/foundation.dart` → eliminar si sí | `lib/features/social_accounts/social_account_manager.dart :: L44-47` (ya usa LoggerService.log en disconnect) | CODE | Baja | 5min | Tarea 0 | → verificar: `dart run scripts/debugprint_scanner.dart` no reporta `social_account_manager.dart` |
| 6 | Limpiar imports unused `flutter/foundation.dart` | Archivos de Tareas 1-5 | Para cada archivo: si `flutter/foundation.dart` no tiene otros usos post-migración → eliminar línea import. Verificar con `flutter analyze`. Archivos candidatos: `vrm_pipeline.dart`, `stitcher_plugin.dart`, `schema_validator.dart`, `social_account_manager.dart` | `lib/core/data/project_repository.dart` (Paso 13 ID-001 removió unused import idéntico) | CODE | Baja | 10min | Tareas 1-5 | → verificar: `flutter analyze` 0 issues |
| 7 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 10min | Tareas 0-6 | → verificar: `flutter test` 52/52 pasan + `dart run scripts/debugprint_scanner.dart` exit 0 + `dart run scripts/debugprint_migration_verifier.dart` pasa + `flutter analyze` 0 issues |

**Tiempo total estimado:** 1h 10min

---

## 🔮 Roadmap (NO implementar ahora)

- **Paso 17 — Parser multilínea para `--fix`:** Mejorar `_fixDebugPrintCalls()` para soportar debugPrint con argumentos en líneas siguientes. Beneficiaría futuras migraciones.
- **Unificar `debugprint_migration_verifier.dart` en `debugprint_scanner.dart`:** Agregar flag `--verify` al scanner existente en vez de script separado. Post-MVP.
- **LoggerService niveles (info/warn/error):** Actualmente `log()` es genérico. Post-MVP agregar `LogLevel` enum para filtrar en producción.
- **`logger_service.dart:48` — debugPrint intencional:** Evaluar si echo a console debe ser condicional (`if (kDebugMode) debugPrint(entry)`). Actualmente siempre imprime en debug. No bloquea Release.
