# 📋 Análisis Técnico — Paso 15: Vrm-health-check-resiliencia-archivos

**Agente:** opus
**Fecha:** 2026-05-09
**Paso:** 15
**Archivo único modificado:** `scripts/vrm_health_check.dart` (601L)

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `_runFixCleanup()` existe | grep en `vrm_health_check.dart` | ✅ | L219-297, firma: `Future<void> _runFixCleanup({bool dryRun = false})` |
| 2 | `entity.delete(recursive: true)` sin try/catch | lectura L240-241 | ✅ CONFIRMADO — sin protección | L241: `await entity.delete(recursive: true);` dentro de `await for` — 0 try/catch |
| 3 | `sessionFile.delete()` sin try/catch | lectura L263 | ✅ CONFIRMADO — sin protección | L263: `await sessionFile.delete();` — 0 try/catch |
| 4 | `clipsDir.delete()` sin try/catch | lectura L277 | ✅ CONFIRMADO — sin protección | L277: `await clipsDir.delete();` — 0 try/catch |
| 5 | Patrón try/catch por operación existe en mismo archivo | lectura `_runScaffold()` | ✅ | L572-596: `try { create() } catch (e) { print('❌ Error...'); }` — patrón a replicar |
| 6 | `_fixProguardDeadRules()` patrón similar | lectura L189-217 | ✅ | No usa try/catch individual (opera líneas texto, no filesystem) — no aplica |
| 7 | Variable `cleaned` acumula conteo | L220 | ✅ | `var cleaned = 0;` — incrementado en L231,L242,L269 |
| 8 | `dryRun` rama ya protegida (no borra) | L229-238 | ✅ | Rama `if (dryRun)` solo hace `print()` — no necesita try/catch |
| 9 | `dart:io` importado | L4 | ✅ | `import 'dart:io';` — FileSystemException disponible |
| 10 | `_runCheck()` invoca `_runFixCleanup()` | L173 | ✅ | `await _runFixCleanup(dryRun: dryRun);` |
| 11 | No existe reporte de fallos individual | L219-297 completo | ✅ CONFIRMADO | Cuando falla `delete()` → excepción propaga → aborta `await for` loop → cleanup incompleto |
| 12 | Función retorna `void` (no errores acumulados) | L219 | ✅ | `Future<void>` — sin retorno de errores. Reporte va a stdout. |

**Discrepancias encontradas:**

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | Plan dice "envolver `entity.delete()` en try/catch" — hay 3 `delete()` calls, no 1 | Envolver LAS 3 llamadas: `entity.delete()` (L241), `sessionFile.delete()` (L263), `clipsDir.delete()` (L277) |
| D2 | Plan dice "generar reporte individual para archivos que fallaron" — no especifica formato | Usar mismo patrón `_runScaffold()` L576: `print('  ❌ Error...'); ` + acumular lista `failedFiles` para resumen final |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ **Schema:** No aplica — paso opera sobre filesystem (`vrm_data/tmp/`, `vrm_data/projects/`), no DB.
- ✅ **Integridad referencial:** N/A — JSON persistence sin relaciones formales.
- ✅ **RLS:** N/A — sin auth, single-user offline.
- ✅ **Índices:** N/A.
- ✅ **Tipos de datos:** FileSystem entities (`File`, `Directory`) → `FileSystemException` como tipo de error esperado en operaciones bloqueadas.

**Impacto datos:** 0 cambios en schema. Paso es puramente script-level resiliencia filesystem.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivo afectado: `scripts/vrm_health_check.dart`

**Función a modificar:** `_runFixCleanup({bool dryRun = false})` — L219-297

**Firma actual (sin cambios):**
```dart
Future<void> _runFixCleanup({bool dryRun = false}) async
```

**3 puntos sin protección:**

| # | Línea | Call | Riesgo |
|---|---|---|---|
| 1 | L241 | `await entity.delete(recursive: true)` | Archivo bloqueado por proceso → `FileSystemException` → aborta loop tmpDir |
| 2 | L263 | `await sessionFile.delete()` | Archivo read-only o locked → aborta loop projectsDir |
| 3 | L277 | `await clipsDir.delete()` | Dir no realmente vacío (race condition) → aborta loop |

**Patrones existentes:**
- `_runScaffold()` L572-596: `try { op } catch (e) { print('❌ Error...'); exitCode = 1; }` — **PATRÓN A SEGUIR**
- `_runValidate()` L311-445: try/catch por stage — patrón similar nivel alto

**Patrón propuesto (cada delete):**
```dart
try {
  await entity.delete(recursive: true);
  cleaned++;
} catch (e) {
  failedFiles.add(entity.path);
  print('  ⚠️ No se pudo eliminar: ${entity.path} ($e)');
}
```

**Reporte final:** Tras ambos loops, si `failedFiles.isNotEmpty` → imprimir resumen.

**Imports:** 0 nuevos imports necesarios. `FileSystemException` es parte de `dart:io` (ya importado L4).

**Modularidad:** Cambio contenido en `_runFixCleanup()` — 0 nuevas funciones. Cohesión alta, acoplamiento bajo. Solo se agrega try/catch + lista `failedFiles`.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ **APIs/endpoints:** N/A — paso es CLI script, no backend.
- ✅ **Middleware:** N/A.
- ✅ **Flujos:** CLI `check --fix` → `_runCheck()` → `_runFixCleanup()`. Flujo no cambia.
- ✅ **Contratos:** Output del CLI sigue mismo formato: `✅/❌/⚠️/ℹ️` + resumen final.
- ✅ **Error handling:** Actualmente: excepción propaga → crash. Propuesto: catch → `⚠️` warning + continúa.

**Ejemplo output actual (con archivo bloqueado):**
```
[7] Ejecutando --fix cleanup...
Unhandled exception: FileSystemException: Cannot delete file...
```

**Ejemplo output propuesto:**
```
[7] Ejecutando --fix cleanup...
  ⚠️ No se pudo eliminar: vrm_data/tmp/locked.mp4 (FileSystemException: ...)
  ✅ Eliminados 3 archivos temporales de vrm_data/tmp/ (1 falló)
  ...
  ⚠️ ARCHIVOS NO ELIMINADOS:
    - vrm_data/tmp/locked.mp4
```

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ **Flujo completo:** CLI `check --fix` → cleanup tmpDir → cleanup orphan sessions → cleanup empty clips. Fallo en 1 archivo no debe parar los otros 2 stages.
- ✅ **Coherencia:** Paso alinea `_runFixCleanup()` con `_runScaffold()` que ya tiene try/catch individual.
- ✅ **Alineación:** Plan factible — cambio puro dentro de 1 función, 1 archivo.
- ✅ **Gaps:** 0 — cambio quirúrgico.

### Herramienta Propuesta: `health_check_resilience_test.dart`
- **Qué automatiza:** Verificación post-implementación de que `_runFixCleanup()` no aborta con archivos bloqueados. Simula directorio con archivos read-only y ejecuta `--fix`.
- **Tipo:** Script CLI / test
- **Cómo se usa:** `dart run scripts/health_check_resilience_test.dart`
- **Impacto para el usuario final:** Confirma que `check --fix` es seguro en escenarios adversos sin prueba manual de bloqueo de archivos.
- **Prioridad:** Tarea 0 — ejecutar antes de modificar `_runFixCleanup()`

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] L241 `entity.delete()` envuelto en try/catch individual
✅ [CODE] L263 `sessionFile.delete()` envuelto en try/catch individual
✅ [CODE] L277 `clipsDir.delete()` envuelto en try/catch individual
✅ [CODE] Cada catch imprime `⚠️ No se pudo eliminar: {path} ({error})`
✅ [CODE] Lista `failedFiles` acumula paths fallidos
✅ [CODE] Resumen final imprime archivos no eliminados si existen
✅ [CODE] `cleaned` solo incrementa en delete exitoso (no en fallido)
✅ [CODE] Rama `dryRun` NO cambia (no necesita try/catch — no borra)
✅ [CODE] Sigue patrón `_runScaffold()` L572-596
✅ [BACKEND] `dart run scripts/vrm_health_check.dart check --fix` ejecuta sin crash con archivos bloqueados
✅ [BACKEND] `dart run scripts/vrm_health_check.dart check --fix --dry-run` sigue funcionando igual
✅ [DX] `health_check_resilience_test.dart` ejecuta sin errores y simula escenario de archivo bloqueado
✅ [FULLSTACK] 0 cambios en lib/ — solo scripts/
✅ [FULLSTACK] `flutter test` sigue pasando (52/52 tests)
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Try/catch silencia errores legítimos (ej: permisos raíz) | Media | Catch genérico `catch (e)` atrapa TODO, no solo `FileSystemException` | Loggear tipo de excepción en output. `⚠️` no es silencio — usuario ve warning. Post-MVP: catch específico `on FileSystemException`. |
| `cleaned` count incorrecta si no se ajusta | Baja | Incrementar `cleaned` antes de delete exitoso → cuenta archivos fallidos como limpiados | Mover `cleaned++` DESPUÉS de `delete()` exitoso (dentro del try, no fuera). Ya corregido en plan tarea. |
| Race condition: archivo borrado entre `list()` y `delete()` | Baja | Otro proceso borra archivo entre listado y eliminación | Try/catch ya maneja: `FileSystemException: No such file` → catch → continúa. No bloquea. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: health_check_resilience_test | `scripts/health_check_resilience_test.dart` | `void main()` — crea dir tmp con archivo read-only, ejecuta `_runFixCleanup` simulación, verifica no crash | `scripts/validador_metrics_session.dart` (patrón CLI test) | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/health_check_resilience_test.dart` ejecuta sin errores |
| 1 | Agregar `failedFiles` lista + try/catch en delete tmpDir L241 | `scripts/vrm_health_check.dart` L219-248 | Agregar `final failedFiles = <String>[];` en L220. Envolver L241 en `try { await entity.delete(recursive: true); cleaned++; } catch (e) { failedFiles.add(entity.path); print('  ⚠️ No se pudo eliminar: ${entity.path} ($e)'); }`. Ajustar print L244 a `'  ✅ Eliminados $cleaned archivos temporales de vrm_data/tmp/${failedFiles.isNotEmpty ? " (${failedFiles.length} fallaron)" : ""}'` | `_runScaffold()` L572-596 :: `try { } catch (e) { print('❌ Error...'); }` | CODE | Baja | 15min | Tarea 0 | → verificar: `dart run scripts/vrm_health_check.dart --help` sin errores compilación |
| 2 | Try/catch en `sessionFile.delete()` L263 | `scripts/vrm_health_check.dart` L259-269 | Envolver L263 en `try { await sessionFile.delete(); } catch (e) { failedFiles.add(sessionFile.path); print('  ⚠️ No se pudo eliminar sesión: ${sessionFile.path} ($e)'); }` | Tarea 1 (mismo patrón try/catch) | CODE | Baja | 10min | Tarea 1 | → verificar: compilación sin errores |
| 3 | Try/catch en `clipsDir.delete()` L277 | `scripts/vrm_health_check.dart` L271-280 | Envolver L277 en `try { await clipsDir.delete(); } catch (e) { failedFiles.add(clipsDir.path); print('  ⚠️ No se pudo eliminar clips vacío: ${clipsDir.path} ($e)'); }` | Tarea 1 (mismo patrón try/catch) | CODE | Baja | 10min | Tarea 2 | → verificar: compilación sin errores |
| 4 | Resumen final de archivos fallidos | `scripts/vrm_health_check.dart` L290-296 | Antes del resumen final (L290), insertar: `if (failedFiles.isNotEmpty) { print(''); print('  ⚠️ ARCHIVOS NO ELIMINADOS:'); for (final f in failedFiles) { print('    - $f'); } }` | — | CODE | Baja | 10min | Tarea 3 | → verificar: `dart run scripts/vrm_health_check.dart check --fix` ejecuta completo |
| 5 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 15min | Tareas 0-4 | → verificar: criterios §5 todos pasan. `flutter test` 52/52. `dart run scripts/vrm_health_check.dart check --fix --dry-run` funciona. |

**Tiempo total estimado:** 1.5 horas

---

## 🔮 Roadmap (NO implementar ahora)

- **Catch específico `on FileSystemException`** en vez de genérico `catch (e)` → distinguir permisos vs corruption vs otros
- **Logging a archivo** de archivos fallidos (no solo stdout) → útil en CI/CD
- **Retry con delay** para archivos temporalmente bloqueados (ej: antivirus escaneando)
- **`--force` flag** para intentar `chmod` antes de delete en archivos read-only
