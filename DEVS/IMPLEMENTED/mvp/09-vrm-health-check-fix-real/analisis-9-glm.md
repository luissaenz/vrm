# 🧠 Análisis Técnico — Paso 09: vrm-health-check-fix-real

**Agente:** glm
**Paso:** Paso 09 — Implementar cleanup real en `vrm_health_check.dart --fix`
**Fecha:** 2026-05-07

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|----------|-------------|--------|-----------|
| 1 | `_runFixCleanup()` existe | grep en `scripts/vrm_health_check.dart` | ✅ VERIFICADO | Líneas 175-223: función con cleanup de tmp/ y sesiones huérfanas |
| 2 | Cleanup `vrm_data/tmp/` | Lectura completa del archivo | ⚠️ PARCIAL | Elimina archivos pero ruta relativa no coincide con runtime path (`getTemporaryDirectory()`) |
| 3 | Cleanup sesiones huérfanas | Lectura líneas 191-219 | ✅ VERIFICADO | Elimina `session_data.json` cuando `project.json` no existe. Limpia `clips/` vacío |
| 4 | ProGuard `--fix` solo imprime warning | Lectura líneas 136-138 | ✅ VERIFICADO | `if (hasDeadRules && fix) { print('⚠️ Usa Tarea 1...'); }` — no ejecuta acción |
| 5 | ProGuard ya limpio | Referencia phase-state | ✅ VERIFICADO | phase-state: "ProGuard limpio" — reglas ffmpegkit muertas removidas en Paso 03 |
| 6 | `ClipStorageService.cleanupTemp()` usa `getTemporaryDirectory()` | `clip_storage_service.dart:215` | ✅ VERIFICADO | Usa `getTemporaryDirectory()` del sistema, NO `vrm_data/tmp/` |
| 7 | `_saveSessionDataToDisk()` usa `getApplicationDocumentsDirectory()` | `recording_manager.dart:240-242` | ✅ VERIFICADO | Path real: `{appDir}/vrm_data/projects/{projectId}/session_data.json` |
| 8 | `_runCheck(bool fix)` invoca `_runFixCleanup()` | `vrm_health_check.dart:156-160` | ✅ VERIFICADO | `if (fix) { await _runFixCleanup(); }` |
| 9 | `_extractFlagValue()` funciona con `--fix` | `vrm_health_check.dart:51-56` | ✅ VERIFICADO | Extrae valor de flag, pero `--fix` es booleano sin valor — usa `flags.contains('--fix')` |
| 10 | `_runFixCleanup()` usa rutas relativas al CWD | `vrm_health_check.dart:179,191` | ✅ VERIFICADO | `Directory('vrm_data/tmp')` y `Directory('vrm_data/projects')` — rutas relativas |
| 11 | `_runScaffold()` también usa rutas relativas al CWD | `vrm_health_check.dart:495` | ✅ VERIFICADO | Patrón consistente con `_runFixCleanup()` |
| 12 | `store_prep_cli.dart` usa rutas relativas consistentes | `store_prep_cli.dart:7-17` | ✅ VERIFICADO | `_projectRoot = '.'` — mismo patrón |
| 13 | `_runFixCleanup()` no tiene confirmación antes de eliminar | Lectura líneas 175-223 | ❌ DISCREPANCIA | Elimina archivos sin pedir confirmación — riesgo de pérdida de datos |
| 14 | `_runFixCleanup()` no reporta detalle por archivo | Lectura líneas 184 | ⚠️ MEJORABLE | Solo cuenta `cleaned` como entero, no lista archivos eliminados individualmente |
| 15 | `RecordingManager.verifyIntegrityStatic()` existe | `recording_manager.dart:366-406` | ✅ VERIFICADO | Verifica clips aprobados existen en disco, remueve referencias faltantes, lanza `SessionIntegrityException` |
| 16 | `_runFixCleanup()` no integra `verifyIntegrityStatic()` | Comparación archivos | ❌ DISCREPANCIA | Health check no reutiliza lógica de integridad de `RecordingManager` |

**Discrepancias encontradas:**

1. **D1 — ProGuard `--fix` es no-op**: Línea 137 imprime warning en vez de eliminar reglas muertas de `proguard-rules.pro`. ProGuard ya limpio (Paso 3), pero el código debería ejecutar la acción real si se encontrara el problema.

2. **D2 — `vrm_data/tmp/` no es el path real de archivos temporales**: `ClipStorageService.cleanupTemp()` opera sobre `getTemporaryDirectory()` (system cache), NO sobre `vrm_data/tmp/`. El cleanup del health check limpia un directorio que no es donde la app almacena archivos temporales en runtime.

3. **D3 — Sin confirmación antes de eliminar archivos**: `_runFixCleanup()` borra archivos sin pedir confirmación al usuario. Destructivo sin safety net.

4. **D4 — No reporta archivos eliminados individualmente**: Solo cuenta número total, no lista qué se eliminó. Difícil auditar qué pasó.

5. **D5 — Sin integración con `verifyIntegrityStatic()`**: RecordingManager ya tiene lógica de verificación de integridad de clips (remueve referencias a clips faltantes). Health check duplica parcialmente esta lógica sin usarla.

6. **D6 — No hay cleanup de archivos `.mp4` huérfanos en `clips/`**: Si un clip existe en disco pero no está referenciado en `session_data.json`, queda como archivo huérfano sin cleanup.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema y estructura de datos afectada

**Archivos en disco que `--fix` manipula:**

| Path | Tipo | Acción `--fix` | Riesgo |
|------|------|-----------------|--------|
| `vrm_data/tmp/*` | Archivos temporales | Eliminar todos | ⚠️ No es el path real de temps (ver D2) |
| `vrm_data/projects/{id}/session_data.json` | JSON de sesión | Eliminar si no hay `project.json` | 🟡 Podría perder sesión activa si `project.json` se corrompió |
| `vrm_data/projects/{id}/clips/` | Directorio | Eliminar si vacío | ✅ Seguro — directorio vacío |
| `android/app/proguard-rules.pro` | Archivo config | Debería eliminar líneas ffmpegkit | ✅ Ya limpio, pero acción no implementada |
| `vrm_data/projects/{id}/clips/*.mp4` | Video clips | NO se limpian huérfanos | ⚠️ Archivos sin referencia en sesión se acumulan |

### Modelo `SessionData` relevante

```dart
class SessionData {
  final String projectId;
  final Map<int, String> approvedClips;  // chunkIndex → clipPath (absoluto)
  final Map<int, ChunkTakeInfo> takesPerChunk; // chunkIndex → {total, selectedTake}
  final List<int> chunksRecorded;
  ...
}
```

**Integridad referencial relevante:**
- `approvedClips` contiene paths absolutos a clips `.mp4`
- Si un clip `.mp4` existe pero no está en `approvedClips` → huérfano (no se limpia)
- Si `session_data.json` existe pero `project.json` no → sesión huérfana (se elimina ✅)
- Si `project.json` existe pero `session_data.json` no → proyecto sin sesión (no se limpia, correcto)

### Path resolution

**Problema arquitectónico clave:** El health check usa rutas relativas (`vrm_data/tmp/`, `vrm_data/projects/`) relativas al CWD. En runtime, la app usa:
- Sesiones: `{getApplicationDocumentsDirectory()}/vrm_data/projects/{id}/`
- Temp: `getTemporaryDirectory()` (NO `vrm_data/tmp/`)
- Logs: `{getApplicationDocumentsDirectory()}/vrm_data/logs/`

Para que `--fix` opere sobre datos reales del dispositivo, necesitaría acceso al path absoluto de la app, que solo está disponible dentro del runtime Flutter. Como CLI standalone, solo puede operar sobre el scaffold/test data.

**Decisión:** Aceptar limitación actual + agregar flag `--data-dir` para especificar path absoluto cuando se use con datos extraídos del dispositivo. Documentar que sin `--data-dir`, opera sobre datos de scaffold/test en el proyecto.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones/clases existentes relevantes

**`vrm_health_check.dart` (526L):**

| Función | Firma | Propósito |
|---------|-------|-----------|
| `_runCheck(bool fix)` | `Future<void> _runCheck(bool fix)` | 6 checks pre-flight. Si `fix=true`, invoca `_runFixCleanup()` |
| `_runFixCleanup()` | `Future<void> _runFixCleanup()` | Elimina tmp/ y sesiones huérfanas. 48 líneas |
| `_runValidate(bool device)` | `Future<void> _runValidate(bool device)` | 5 stages de validación de resiliencia |
| `_runMemory()` | `Future<void> _runMemory()` | 3 checks estáticos de memory leaks |
| `_runScaffold(String? projectId)` | `Future<void> _runScaffold(String? projectId)` | Crea estructura vrm_data/ para proyecto nuevo |

**Problemas en `_runFixCleanup()` (líneas 175-223):**

1. **Eliminación sin confirmación:** `await entity.delete(recursive: true)` sin pedir confirmación
2. **Conteo sin detalle:** Solo imprime `Eliminados X archivos temporales` sin listar qué se eliminó
3. **Path `vrm_data/tmp/` no es runtime path:** `ClipStorageService` usa `getTemporaryDirectory()`, no `vrm_data/tmp/`
4. **No logea acciones:** No escribe al log qué se eliminó (LoggerService no disponible en CLI standalone)
5. **No detecta clips huérfanos:** Un `.mp4` en `clips/` sin referencia en `session_data.json` queda acumulando

**Patrón de referencia (store_prep_cli.dart):**

- `_runKeystore()`: Genera keystore con confirmación previa (verifica si existe)
- `_runPrivacy()`: Valida y sugiere acción concreta
- `_validateScreenshotResolution()`: Parsea PNG para validar
- Patrón: cada subcomando hace verificación → acción → reporte detallado

**Patrón a seguir para `--fix`:**

- Antes de eliminar: listar qué se va a eliminar
- Solicitar confirmación si hay más de 0 elementos
- Reportar cada acción individualmente
- Escribir log de acciones realizadas

### Código nuevo necesario

**Función `_performFixAction()`:** Reemplazar `_runFixCleanup()` con versiones que ejecuten acciones concretas:

1. `_fixProguardDeadRules()`: Remover líneas con `ffmpegkit` de `proguard-rules.pro`
2. `_fixOrphanTempFiles(String dataDir)`: Eliminar archivos temporales con reporte detallado
3. `_fixOrphanSessions(String dataDir)`: Resetear sesiones sin proyecto padre con confirmación
4. `_fixOrphanClips(String dataDir)`: Eliminar clips .mp4 no referenciados en session_data.json
5. `_fixEmptyDirectories(String dataDir)`: Eliminar directorios clips/ vacíos

---

## 3️⃣ Análisis de Backend (ETAPA 3)

### No aplica — CLI standalone

El health check es un script CLI Dart que corre en el host, no en un backend. No hay endpoints, middleware ni APIs involucradas.

**Contrato de entrada/salida:**

| Input | Output |
|-------|--------|
| `dart run scripts/vrm_health_check.dart check` | 6 checks pre-flight, JSON resultado |
| `dart run scripts/vrm_health_check.dart check --fix` | 6 checks + ejecuta cleanup real |
| `dart run scripts/vrm_health_check.dart validate` | 5 stages validación resiliencia |
| `dart run scripts/vrm_health_check.dart memory` | 3 checks memory leaks estáticos |
| `dart run scripts/vrm_health_check.dart scaffold --project-id <uuid>` | Crea estructura vrm_data/ |

**Flujo actual `check --fix`:**

```
check --fix → _runCheck(true) → [6 checks] → _runFixCleanup() → [tmp cleanup + orphan sessions]
```

**Flujo propuesto `check --fix`:**

```
check --fix → _runCheck(true) → [6 checks con fix real por check]
  → Check[5] Proguard: si hasDeadRules && fix → _fixProguardDeadRules()
  → _runFixCleanup() → [tmp cleanup + orphan sessions + orphan clips + empty dirs + confirmación + log detallado]
```

**Error handling:** Actualmente `_runFixCleanup()` no maneja errores por archivo individual. Un `try/catch` por archivo falla silenciosamente si el directorio no existe.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
Usuario corre: dart run scripts/vrm_health_check.dart check --fix
  ↓
Check[1]: Estructura proyecto (lib/) → PASS/FAIL (no fix aplicable)
  ↓
Check[2]: Pipeline files → PASS/FAIL (no fix aplicable)
  ↓
Check[3]: LoggerService → PASS/FAIL (no fix aplicable)
  ↓
Check[4]: MemoryMonitor → PASS/FAIL (no fix aplicable)
  ↓
Check[5]: ProGuard → si dead rules + fix → REMOVER LÍNEAS MUERTAS (actualmente solo print)
  ↓
Check[6]: Scripts dir → PASS/FAIL (no fix aplicable)
  ↓
Fix cleanup:
  ├─ Escanear archivos temporales huérfanos
  ├─ Mostrar lista de archivos a eliminar
  ├─ Pedir confirmación (y/n) si archivos > 0
  ├─ Eliminar con reporte individual
  ├─ Escanear sesiones huérfanas
  ├─ Escanear clips huérfanos
  ├─ Eliminar directorios vacíos
  └─ Reporte resumen detallado
```

### Coherencia con la arquitectura existente

- ✅ Sigue patrón de `store_prep_cli.dart` (subcomandos con acciones reales)
- ✅ Usa rutas relativas consistentes con scaffold y otros scripts
- ⚠️ No reutiliza `RecordingManager.verifyIntegrityStatic()` (no disponible en CLI standalone)
- ⚠️ Ruta `vrm_data/tmp/` no coincide con path real de temps en dispositivo

### Gaps y fricciones

1. **Sin `--data-dir`:** Usuario no puede apuntar health check a datos extraídos del dispositivo
2. **Sin confirmación destructiva:** Elimina archivos sin pedir permiso
3. **Sin log detallado:** No escribe qué se hizo a archivo de log
4. **Sin cleanup de clips huérfanos:** Acumula archivos .mp4 sin referencia
5. **ProGuard fix es no-op:** Imprime warning en vez de corregir

### DX & Tooling (OBLIGATORIO)

```
### Herramienta Propuesta: vrm_health_check --fix mejorado
- **Qué automatiza:** Cleanup real de archivos huérfanos, reglas ProGuard muertas, y directorios vacíos con confirmación previa y reporte detallado
- **Tipo:** comando CLI existente (mejora de subcomando)
- **Cómo se usa:** `dart run scripts/vrm_health_check.dart check --fix [--data-dir <path>] [--dry-run]`
- **Impacto para el usuario final:** Reduce diagnóstico manual de ~10min a ~2s. `--dry-run` permite previsualizar qué se eliminaría sin tocar nada. `--data-dir` permite apuntar a datos extraídos del dispositivo.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] --fix elimina archivos temporales huérfanos con reporte individual
✅ [DATA] --fix resetea sesiones huérfanas (sin project.json padre) con confirmación
✅ [DATA] --fix elimina clips .mp4 huérfanos (no referenciados en session_data.json)
✅ [DATA] --fix elimina directorios clips/ vacíos
✅ [CODE] ProGuard --fix remueve líneas muertas de proguard-rules.pro (no solo imprime warning)
✅ [CODE] --fix muestra confirmación antes de acciones destructivas
✅ [CODE] --fix reporta cada acción individualmente (archivo + acción + resultado)
✅ [CODE] Flag --dry-run permite previsualizar sin eliminar
✅ [BACKEND] check --fix ejecuta sin errores con exitCode 0 cuando no hay problemas
✅ [BACKEND] check --fix ejecuta sin errores con exitCode 1 cuando hay problemas no-fixeables
✅ [FULLSTACK] `dart run scripts/vrm_health_check.dart check --fix` funciona end-to-end
✅ [FULLSTACK] `--dry-run` lista acciones pendientes sin ejecutarlas
✅ [DX] Flag --data-dir permite apuntar a path absoluto de datos del dispositivo
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|-------------|
| Eliminación de datos de usuario sin confirmación | Alta | `--fix` borra archivos destructivos sin `y/n` | Agregar confirmación interactiva + `--dry-run` |
| Path `vrm_data/tmp/` no existe en runtime del dispositivo | Media | `ClipStorageService` usa `getTemporaryDirectory()` | Agregar `--data-dir` flag + documentar limitación |
| Clips huérfanos acumulan espacio en dispositivo | Media | No existe cleanup de `.mp4` sin referencia en sesión | Implementar `_fixOrphanClips()` |
| ProGuard fix elimina líneas incorrectas si pattern cambia | Baja | Pattern `content.contains('ffmpegkit')` puede matchear demasiado | Usar regex más específico o buscar por contexto |
| Sesión huérfana eliminada que estaba en uso | Baja | `project.json` corrupto o temporalmente ausente | Verificar que `project.json` no existe Y que sesión tiene `lastUpdatedAt` > 24h |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|-------|-----------|-----------------|-----------------|-------|-------------|-------------|--------------|--------------|
| 0 | **DX Tooling**: Flag `--dry-run` + `--data-dir` | `scripts/vrm_health_check.dart` | `_runCheck(bool fix, {bool dryRun = false, String? dataDir})`, `_runFixCleanup({bool dryRun = false, String dataDir = 'vrm_data'})` | `store_prep_cli.dart:51-56` (_extractFlagValue) | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/vrm_health_check.dart check --dry-run` ejecuta sin eliminar archivos |
| 1 | Implementar confirmación interactiva antes de eliminación | `scripts/vrm_health_check.dart` | `Future<bool> _confirmAction(String message, {bool dryRun = false})` — Lee stdin para `y/n`, retorna `true` si dryRun o confirmado | Patrón de utils CLI Dart | CODE | Baja | 0.5h | Tarea 0 | → verificar: `check --fix` pide confirmación antes de eliminar. `--dry-run` salta confirmación |
| 2 | Refactor `_runFixCleanup()` con reporte detallado y confirmación | `scripts/vrm_health_check.dart:175-223` | `Future<void> _runFixCleanup({bool dryRun = false, String dataDir = 'vrm_data'})` — Lista archivos antes de eliminar, pide confirmación, reporta cada acción | `store_prep_cli.dart:88-316` (patrón check detallado) | CODE | Media | 1h | Tarea 0, 1 | → verificar: `check --fix --dry-run` lista archivos sin eliminar. `check --fix` elimina con confirmación y reporta cada acción |
| 3 | Implementar `_fixProguardDeadRules()` | `scripts/vrm_health_check.dart` | `Future<int> _fixProguardDeadRules({bool dryRun = false})` — Lee `android/app/proguard-rules.pro`, remueve líneas con `ffmpegkit`, escribe archivo modificado, retorna líneas removidas | `store_prep_cli.dart:565-621` (patrón validación + fix) | CODE | Baja | 0.5h | Tarea 0 | → verificar: Injectar línea `ffmpegkit` en proguard, correr `check --fix`, verificar línea removida. `--dry-run` no remueve |
| 4 | Implementar `_fixOrphanClips()` — eliminar .mp4 sin referencia | `scripts/vrm_health_check.dart` | `Future<int> _fixOrphanClips(String dataDir, {bool dryRun = false})` — Lee `session_data.json` de cada proyecto, parsea `approvedClips` paths, lista .mp4 en `clips/` no referenciados, elimina con confirmación | `_runFixCleanup()` existente (patrón listado de directors) | DATA | Media | 1h | Tarea 0, 2 | → verificar: Crear clip `.mp4` huérfano en scaffold, `check --fix --dry-run` lo lista, `check --fix` lo elimina |
| 5 | Conectar ProGuard fix en `_runCheck()` | `scripts/vrm_health_check.dart:136-138` | Reemplazar `if (hasDeadRules && fix) { print('⚠️ Usa Tarea 1...'); }` con `if (hasDeadRules && fix) { final removed = await _fixProguardDeadRules(dryRun: dryRun); ... }` | Líneas 136-138 actuales | CODE | Baja | 0.25h | Tarea 3 | → verificar: `check --fix` remueve líneas ffmpegkit de proguard. ProGuard ya limpio → no-op |
| 6 | Integrar `_fixOrphanClips()` en `_runFixCleanup()` | `scripts/vrm_health_check.dart:175-223` | Agregar `await _fixOrphanClips(dataDir, dryRun: dryRun)` después de cleanup de sesiones huérfanas | Líneas 215-217 actuales | DATA | Baja | 0.25h | Tarea 4 | → verificar: `check --fix` detecta y elimina clips huérfanos |
| 7 | Agregar `_fixEmptyDirectories()` explícito | `scripts/vrm_health_check.dart` | `Future<int> _fixEmptyDirectories(String dataDir, {bool dryRun = false})` — Escanea subdirectorios vacíos en `vrm_data/projects/`, elimina con confirmación | `_runFixCleanup()` existente (patrón listado) | DATA | Baja | 0.25h | Tarea 0 | → verificar: `check --fix` detecta y elimina directorios vacíos |
| 8 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.5h | Tareas 0-7 | → verificar: criterios §5 todos pasan. `check --dry-run` lista sin eliminar. `check --fix` ejecuta con confirmación. Exit codes correctos |

**Tiempo total estimado:** 4.75 horas

---

## 🔮 Roadmap (NO implementar ahora)

- **Integración Flutter:** Corsar health check desde dentro de la app usando `Process.run()` o refactoring como librería importable. Permite cleanup en-device con paths reales.
- **Auto-cleanup on app start:** Ejecutar cleanup de temps al iniciar la app (migrar `_runFixCleanup()` a `RecordingManager.init()`).
- **Watchdog de espacio:** Alertar al usuario cuando `vrm_data/` supera umbral de tamaño (ej: 1GB).
- **Backup antes de cleanup:** Copiar archivos a `vrm_data/backups/` antes de eliminar, con retención configurable.
- **Health check integrado en CI:** Agregar `dart run scripts/vrm_health_check.dart check` como paso de CI para detectar regresiones.

---

## 🚫 Reglas de Oro cumplidas

- ✅ Análisis basado en código fuente real (16 elementos verificados en §0)
- ✅ Discrepancias documentadas (D1-D6)
- ✅ Plan contradice código → código gana (ProGuard ya limpio, --fix solo imprime warning → implementar fix real)
- ✅ Tareas atómicas: 1 artefacto por tarea, interfaz completa, patrón explícito, verificación inline
- ✅ ≥ 1 herramienta DX propuesta (--dry-run + --data-dir)
- ✅ Etapas secuenciales: data → code → backend → fullstack+DX
- ✅ Coherente con phase-state.md (ProGuard ya limpio, LoggerService existente, MemoryMonitor existente)
- ✅ El implementador no decide nada: cada tarea tiene firma exacta, patrón de referencia, y verificación concreta