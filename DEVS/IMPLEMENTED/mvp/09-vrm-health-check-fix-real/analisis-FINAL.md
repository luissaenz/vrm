# 🏛️ ANÁLISIS UNIFICADO — Paso 09: vrm-health-check-fix-real

**Generado:** 2026-05-07
**Fase:** mvp
**Fuentes:** 6 análisis (LagunaM1, LagunaXS2, step, glm, ds, hy3)

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---|:---|:---|:---|:---|
| LagunaM1 | ✅ | 2 | ✅ | ✅ | 4.3 |
| LagunaXS2 | ✅ | 2 | ✅ | ✅ | 4.3 |
| step | ✅ | 2 | ✅ | ✅ | 4.0 |
| glm | ✅ | 6 | ✅ | ✅ | 4.8 |
| ds | ✅ | 3 | ✅ | ✅ | 4.5 |
| hy3 | ✅ | 1 | ✅ | ✅ | 3.5 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| 1 | Plan cita `vrm_health_check.dart:120-122` para fix | LagunaM1, LagunaXS2, step, glm, ds, hy3 | ✅ `scripts/vrm_health_check.dart:175-223` | Código gana. Fix real en `_runFixCleanup()` L175-223. L120-122 son strings de MemoryMonitor. Actualizar plan. |
| 2 | ProGuard `--fix` es no-op (solo imprime warning) | glm | ✅ `scripts/vrm_health_check.dart:136-138` | ProGuard ya limpio (Paso 03). Si hubiera reglas muertas, `--fix` debería removerlas automáticamente. Mejora para implementar. |
| 3 | `vrm_data/tmp/` no es path runtime real (app usa `getTemporaryDirectory()`) | glm, ds | ✅ `clip_storage_service.dart:215`, `recording_manager.dart:240-242` | Aceptado. Todos los scripts CLI del proyecto usan rutas relativas al CWD. Agregar flag `--data-dir` post-MVP. |
| 4 | Sin confirmación antes de eliminar archivos | glm, hy3 | ✅ `_runFixCleanup()` L181-184 (delete sin confirmar) | Agregar confirmación interactiva + flag `--dry-run` como mejora inmediata. Aceptable para MVP sin confirmación en script de desarrollo. |
| 5 | Sin cleanup de clips .mp4 huérfanos | glm | ✅ No hay lógica que compare `clips/` contra `approvedClips` | Mejora post-MVP. Bajo impacto porque clips huérfanos existen solo si se corrompió `session_data.json`. |
| 6 | Sin reporte detallado por archivo (solo conteo) | glm | ✅ L185: `print('Eliminados $cleaned archivos')` | Mejora post-MVP. Conteo es suficiente para script de desarrollo. |
| 7 | Sin integración con `verifyIntegrityStatic()` | glm | ✅ `recording_manager.dart:366-406` | No aplicable. CLI standalone no tiene acceso a runtime Flutter. Aceptado. |
| 8 | Plan Paso 9 completo — pero ya implementado en Paso 05 | ds, LagunaM1, LagunaXS2, step, hy3 | ✅ commit b603e48 | Confirmado: `_runFixCleanup()` implementado en Paso 05 como tarea M7. Paso 09 es verificación + documentación. |

---

## 1️⃣ Resumen Ejecutivo

- **Objetivo:** Implementar cleanup real en `vrm_health_check.dart --fix` (eliminar tmp, resetear sesiones huérfanas, eliminar clips/ vacíos).
- **Estado real:** YA IMPLEMENTADO en Paso 05 (commit b603e48). Paso 09 es esencialmente verificación y documentación.
- **Corrección crítica al plan:** L120-122 no contienen el fix — está en `_runFixCleanup()` L175-223.
- **Decisión DX:** Fusionar propuestas de 6 agentes en herramienta única: `vrm_health_check.dart check --fix --dry-run`. Agregar flag `--dry-run` como mejora inmediata.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path

1. Usuario ejecuta `dart run scripts/vrm_health_check.dart check --fix`
2. Script corre 6 checks pre-flight (estructura, pipeline, logger, memory, proguard, scripts)
3. Tras checks, invoca `_runFixCleanup()`
4. Limpia archivos temporales en `vrm_data/tmp/`
5. Itera proyectos en `vrm_data/projects/`
6. Detecta sesiones huérfanas (existe `session_data.json` sin `project.json`)
7. Elimina `session_data.json` huérfano y directorios `clips/` vacíos
8. Reporta conteo de elementos procesados
9. Exit code 0 si todo ok, 1 si algún check falló

### Edge Cases MVP

- `vrm_data/tmp/` no existe → skip con mensaje informativo ✅
- `vrm_data/projects/` no existe → skip ✅
- Sesión huérfana sin `project.json` padre → elimina `session_data.json` ✅
- Proyecto válido con `project.json` presente → NO elimina sesión ✅
- Directorio `clips/` vacío → elimina directorio ✅
- Archivo temporal bloqueado por otro proceso → falla silenciosamente (sin try/catch individual — mejora)

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

| Ruta real | Tipo de cambio | Descripción | Interfaces clave |
|-----------|---------------|-------------|-----------------|
| `scripts/vrm_health_check.dart` (526L) | Ya implementado (Paso 05) | Script CLI con subcomandos check/validate/memory/scaffold. `_runFixCleanup()` ejecuta cleanup real. | `Future<void> _runFixCleanup()` en L175-223 |
| `scripts/vrm_health_check.dart` | Mejora: agregar `--dry-run` | Flag que lista acciones sin ejecutarlas | Extender `_runCheck(bool fix, {bool dryRun = false})` |

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: vrm_health_check --fix con --dry-run
- **Qué automatiza:** Cleanup de archivos temporales huérfanos, reseteo de sesiones sin proyecto padre, eliminación de directorios clips/ vacíos. Flag --dry-run permite previsualizar antes de ejecutar.
- **Tipo:** CLI (script Dart existente con mejora)
- **Ubicación:** `scripts/vrm_health_check.dart:175-223`
- **Cómo se usa:** `dart run scripts/vrm_health_check.dart check --fix --dry-run` (preview) / `check --fix` (ejecutar)
- **Impacto para el usuario final:** Elimina limpieza manual de directorios temporales y diagnóstico manual de sesiones huérfanas. Reduce ~15min a ~2s. --dry-run evita borrados accidentales.
- **El implementador DEBE usarla** para verificar que --fix funciona sin eliminar datos válidos.
```

---

## 4️⃣ Decisiones Tecnológicas

1. **`_runFixCleanup()` ya implementado y funcional:** El código existe desde Paso 05. No requiere cambios para cumplir objetivos base del paso.
2. **Rutas relativas `vrm_data/` en CLI:** Convención aceptada y consistente con todos los scripts del proyecto (`store_prep_cli.dart`, `debugprint_scanner.dart`). Para operar sobre datos reales del dispositivo se requeriría flag `--data-dir` (post-MVP).
3. **Conteo agregado sin detalle por archivo:** Suficiente para MVP. Mejora post-MVP.
4. **Sin confirmación interactiva:** Aceptable para script de desarrollo. Agregar flag `--dry-run` mitiga riesgo de borrado accidental.
   - ⚠️ El plan dice Paso 09 requiere implementar cleanup real → código ya lo tiene. El plan además dice L120-122 pero la implementación está en L175-223. Se implementa L175-223.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [CODE] `_runFixCleanup()` elimina todo el contenido de `vrm_data/tmp/`
✅ [CODE] `_runFixCleanup()` elimina `session_data.json` sin `project.json` padre
✅ [CODE] `_runFixCleanup()` elimina directorios `clips/` vacíos
✅ [CODE] No elimina datos de proyectos válidos (verifica existencia de `project.json`)
✅ [CODE] Sigue patrón de `store_prep_cli.dart` (acciones reales, no solo print)
✅ [DX] `dart run scripts/vrm_health_check.dart check --fix` ejecuta sin errores y limpia datos
✅ [DX] Flag `--dry-run` permite previsualizar acciones sin ejecutarlas
```

**Funcionales:**
- [ ] Usuario ejecuta `check --fix` y script limpia datos huérfanos correctamente
- [ ] Usuario ejecuta `check --fix --dry-run` y script lista acciones sin modificar archivos

**Técnicos:**
- [ ] `_runFixCleanup()` no crashea si directorios no existen
- [ ] `_runFixCleanup()` no elimina archivos cuando `project.json` existe
- [ ] Exit code 0 si todo ok, 1 si algún check falla

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** Agregar flag `--dry-run` a `check --fix` + refactor `_runFixCleanup({bool dryRun = false})` | Baja | 0.5h | Ninguna |
| 1 | Verificar que `_runFixCleanup()` existe y ejecuta acciones reales | Baja | 0h | Tarea 0 |
| 2 | Corregir discrepancia D1 en `DEVS/plan.md` (L120-122 → L175-223) | Baja | 0.1h | Tarea 0 |
| 3 | Documentar acciones --fix en output (ya existe) | Baja | 0h | Tarea 1 |
| **TOTAL** | | | **0.6h** | |

> [!IMPORTANT]
> **Tarea 0 siempre = DX & Tooling.** Implementador DEBE ejecutarla primero.

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| Borrado de datos válidos si `project.json` está corrupto | Media | `_runFixCleanup()` confía en existencia de `project.json`. Si está corrupto, sesión válida es eliminada. | Verificar que `project.json` existe Y tiene `projectId` válido antes de considerar huérfana. |
| Script usa ruta relativa `vrm_data/` — no afecta datos reales del dispositivo | Baja | No usa `getApplicationDocumentsDirectory()` | Documentado. Es herramienta DX de desarrollo. Post-MVP agregar `--data-dir`. |
| Sin try/catch individual por archivo | Baja | `entity.delete()` falla silenciosamente sin reporte | Aceptable para MVP. Mejora post-MVP: try/catch por archivo con reporte individual. |
| `vrm_data/tmp/` no existe o está vacío | Baja | Directorio no creado por otros scripts | Script ya maneja: verifica existencia antes de iterar. |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|----|------|-------|-----------------|
| TP-1 | --fix con tmp/ y sesiones huérfanas | Ejecutar en proyecto scaffold con datos corruptos | Script limpia tmp/, elimina session_data.json huérfano, elimina clips/ vacío |
| TP-2 | --fix sin datos corruptos | Ejecutar en proyecto limpio | Mensajes "nada que limpiar", exit code 0 |
| TP-3 | --dry-run con datos corruptos | `--fix --dry-run` en proyecto con datos | Lista acciones sin modificar archivos |

Comando para ejecutar tests: `dart run scripts/vrm_health_check.dart check --fix` / `dart run scripts/vrm_health_check.dart check --fix --dry-run`
