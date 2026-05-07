# Análisis Técnico — Paso 08: Migrar-debugPrint-residual-LoggerService

**Agente:** ds
**Fecha:** 2026-05-07
**Fase:** mvp
**Estado del paso:** ✅ COMPLETADO (pre-implementado en Paso 05)

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `debugPrint` en `recording_page.dart:_applyHardwareSettings()` L657 | `grep debugPrint lib/features/recording/recording_page.dart` | ✅ COMPLETADO | 0 ocurrencias de `debugPrint` en todo el archivo |
| 2 | `debugPrint` en `recording_page.dart:_applyHardwareSettings()` L662 | `grep debugPrint lib/features/recording/recording_page.dart` | ✅ COMPLETADO | Idem — 0 debugPrint en archivo |
| 3 | LoggerService.log() en catch de `_applyHardwareSettings()` | leer L683-704 | ✅ VERIFICADO | `LoggerService.log()` usado en ambos catch blocks (CameraHardwareException + genérico) |
| 4 | `_applyHardwareSettings()` firma actual | leer L666-706 | ✅ EXISTE | `Future<void> _applyHardwareSettings()` — 41 líneas sin debugPrint |
| 5 | LoggerService.log() usado en recording_page.dart | grep | ✅ VERIFICADO | Usado en L648, L684-688, L700-703 |
| 6 | LoggerService singleton disponible | `lib/core/services/logger_service.dart` | ✅ EXISTE | `static Future<void> log(String tag, String message, {Object? error, StackTrace? stack})` |
| 7 | plan.md claim L657,L662 debugPrint | diff contra código real | ❌ DISCREPANCIA | Plan referencia líneas antiguas. Código actual no tiene debugPrint allí |
| 8 | phase-state.md §5 confirma migración | L221-222 | ✅ CONFIRMADO | "7 debugPrint residuales en recording_page.dart migrados a LoggerService.log()" |

### Discrepancias encontradas

| Discrepancia | Resolución |
|---|---|
| Plan referencia L657, L662 de `recording_page.dart` para debugPrint | Líneas desactualizadas. `_applyHardwareSettings()` actual (L666-706) usa LoggerService.log() en todos sus catch blocks. Código ejecutó el paso en Paso 05. |
| Paso 08 existe como pendiente en plan.md pero implementado en realidad | Paso 08 debe marcarse COMPLETADO. No requiere implementación adicional. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**Sin impacto.** Paso 08 es migración de logging (código puro). No toca:
- Schema de datos (JSON filesystem)
- Integridad referencial
- RLS (no existe en MVP offline)
- Índices
- Tipos de datos

LoggerService ya escribe a `vrm_data/logs/app.log` con rotación. No hay cambios en estructura de datos.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Estado actual de `_applyHardwareSettings()` (L666-706)

```
Future<void> _applyHardwareSettings() async
```

**Estructura:**
- Guard: `if (!_isCameraInitialized) return;`
- Try: setFlashMode → setExposureMode/setFocusMode según _isStreetModeActive
- `on CameraHardwareException catch (e)`: LoggerService.log() + VRMNotifications.showWarning()
- `on SessionIntegrityException catch`: reset idle state
- `catch (e)`: LoggerService.log() (genérico)

**debugPrint count: 0.** Ambos handlers de error ya usan `LoggerService.log()`.

### Patrón existente (conservado)
```
LoggerService.log('RecordingPage', 'mensaje', error: e)
```
Mismo patrón usado en:
- `recording_page.dart:648` — catch _stopRecording
- `recording_page.dart:684-688` — on CameraHardwareException
- `recording_page.dart:700-703` — catch genérico

### Calidad
- Cohesión alta: cada catch tiene responsabilidad única
- Sin duplicación: LoggerService es punto único de logging persistente
- debugPrint eliminado → LoggerService garantiza diagnóstico en Release (debugPrint es no-op en Release)

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**Sin impacto.** No hay backend involucrado. Paso 08 es 100% frontend (Flutter/Dart).

- No hay endpoints
- No hay middleware
- No hay contratos entre servicios
- LoggerService es local (filesystem del dispositivo)

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end
```
debugPrint → LoggerService.log() → vrm_data/logs/app.log
```

### Coherencia
Paso 08 es trivial y ya ejecutado. Consistente con decisión de Paso 03/05:
- phase-state.md §4: "LoggerService.log() sobre debugPrint — 7 debugPrint residuales en recording_page.dart migrados"
- Mismo patrón aplicado en CameraService, RecordingManager, ExportService

### DX & Tooling

```
### Herramienta Propuesta: vrm_log_checker
- **Qué automatiza:** Escanea todos los archivos .dart en lib/ buscando debugPrint() que deberían ser LoggerService.log(). Reporta archivo, línea y fragmento de código.
- **Tipo:** script Dart (patrón scripts/ existente)
- **Cómo se usa:** `dart run scripts/vrm_log_checker.dart check` o `dart run scripts/vrm_log_checker.dart fix` (migración automática)
- **Impacto para el usuario final:** Previene regresión de debugPrint en Release. QA automatizado de logging.
- **Prioridad:** Baja (Paso 08 ya completado manualmente — herramienta preventiva)
```

---

## 5️⃣ Criterios de Aceptación

| # | Criterio | Verificable | Estado |
|---|---|---|---|
| ✅ [CODE] 0 debugPrint en `recording_page.dart` | `grep debugPrint lib/features/recording/recording_page.dart` → 0 matches | ✅ PASA |
| ✅ [CODE] LoggerService.log() en catch blocks de `_applyHardwareSettings()` | leer L683-704 | ✅ PASA |
| ✅ [CODE] LoggerService.log() con tag 'RecordingPage' | patrón L684, L700 | ✅ PASA |
| ✅ [FULLSTACK] Mensajes aparecen en vrm_data/logs/app.log (Release) | LoggerService escribe a archivo persistente con rotación | ✅ PASA |
| ✅ [FULLSTACK] Funcionamiento idéntico en debug y release | LoggerService.log() → writeAsString (no debugPrint) | ✅ PASA |
| ❌ [PLAN] Paso 08 NO está pendiente — ya completado en Paso 05 | plan.md vs código real | ❌ DISCREPANCIA |

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Regresión: nuevo debugPrint agregado en recording_page.dart | Baja | Desarrollador futuro usa debugPrint sin conocer LoggerService | Herramienta DX propuesta (`vrm_log_checker.dart`) como pre-commit hook |
| LoggerService rotación pierde logs históricos | Baja | Rotación a 512KB reemplaza app.log por app.old.log | Aceptable MVP. Post-MVP: rotación por fecha |
| Paso 08 duplicado si implementador no verifica | Media | Plan marca paso pendiente pero código ya ejecutado | Este análisis documenta discrepancia. Marcar paso COMPLETO en plan |

---

## 7️⃣ Plan de Implementación

**Paso 08 no requiere implementación.** Código ya refleja el estado deseado.

| # | Tarea | Artefacto | Interfaz exacta | Patrón | Etapa | Compl. | Tiempo | Deps | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX:** vrm_log_checker | `scripts/vrm_log_checker.dart` | `check()` → prints report; `fix()` → reemplaza debugPrint con LoggerService.log() | `scripts/vrm_health_check.dart` | DX | Baja | 15min | Ninguna | → `dart run scripts/vrm_log_checker.dart check` sin errores |
| 1 | Marcar Paso 08 completado | `plan.md` L185-204 | Actualizar estado a ✅ COMPLETADO | — | DOC | Baja | 1min | Ninguna | → plan.md refleja cambio |

**Tiempo total estimado:** 0h (ya implementado) + 15min (DX tool opcional)

---

## 🔮 Roadmap

- **vrm_log_checker.dart** como herramienta preventiva — puede integrarse en CI pre-commit para evitar regresión de debugPrint en toda la codebase
- Extender a todos los archivos con debugPrint detectados en grep (74 ocurrencias en lib/): clip_review_page.dart, recording_end_page.dart, memory_monitor.dart, clip_storage_service.dart, vrm_pipeline.dart, voice_command_service.dart, etc. — post-MVP
