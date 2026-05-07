# Análisis Paso 05: Catch específico SessionIntegrityException — AGENTE: step

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `SessionIntegrityException` clase existe | grep `lib/core/exceptions/vrm_exceptions.dart` | ✅ | L41-46 define clase con código `session_integrity_error` |
| 2 | `verifyIntegrityStatic()` lanza `SessionIntegrityException` | Lectura `recording_manager.dart` L392-398 | ✅ | `throw SessionIntegrityException(..., originalError: newData)` |
| 3 | `verifySessionIntegrity()` captura y re-lanza | `recording_manager.dart` L409-416 | ✅ | `on SessionIntegrityException catch (e) { sessionData = e.originalError; rethrow; }` |
| 4 | `startRecording()` llama a `verifySessionIntegrity()` | `recording_manager.dart` L60 | ✅ | Llamada dentro de try antes de iniciar cámara |
| 5 | `recording_page.dart` importa `vrm_exceptions.dart` | `recording_page.dart` L29 | ✅ | `import '../../../core/exceptions/vrm_exceptions.dart';` |
| 6 | `recording_page.dart` tiene try-catch genérico en `_startActualRecording` | `recording_page.dart` L539-553 | ✅ | `catch (e)` → SnackBar rojo |
| 7 | `recording_page.dart` ya maneja `SessionIntegrityException` en `_verifyIntegrity()` | `recording_page.dart` L191-203 | ✅ | Handler con SnackBar naranja y `_sessionData = e.originalError` |
| 8 | Patrón SnackBar naranja usado en otro lugar (StorageFullException pre-try) | `recording_page.dart` L488-495 | ✅ | `backgroundColor: Colors.orange` |

**Discrepancias encontradas:**

- Plan menciona L535-548; código real L539-553. Desfase ~4 líneas, sin impacto funcional.
- Plan pide mensaje fijo "Integridad de sesion comprometida — clips faltantes removidos"; `_verifyIntegrity` usa `e.message` detallado. Cambio válido, consistente con simplificación de UX.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ No hay cambios en schema de base de datos. Trata solo de manejo de excepción en frontend.
- ✅ No se modifican tablas, columnas, constraints.
- ✅ RLS no aplica (app sin auth, MVP offline).
- ✅ Índices no afectados.
- ✅ Tipos de datos existentes (`SessionData`, `SessionIntegrityException`) se usan sin extensión.

---

## 2️⃣ Análisis de Código (ETAPA 2)

**Artefacto modificado:** `lib/features/recording/recording_page.dart` (método `_startActualRecording`).

**Cambio:** Insertar bloque `on SessionIntegrityException catch (e)` antes del `catch (e)` genérico (L539).

**Firma del bloque:**

```dart
on SessionIntegrityException catch (e) {
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
    });
    _sessionData = e.originalError as SessionData?;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Integridad de sesion comprometida — clips faltantes removidos'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
```

**Patrón de referencia:** Bloque `_verifyIntegrity()` L191-203:

- Actualiza `_sessionData` desde `e.originalError`
- Muestra SnackBar naranja con `duration: 5s`
- No usa `_showRecoveryDialog()` (diálogo modal), mantiene SnackBar para no interrumpir flujo de grabación.

**Imports:** Ya existentes (`vrm_exceptions.dart`). No requiere modificación.

**Modularidad:** Alto acoplamiento bajo. Bloque autónomo, solo accede a variables de instancia y usa servicios ya importados.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ No se crean/eliminan endpoints.
- ✅ No hay cambios en middleware, autenticación o autorización.
- ✅ Flujo de datos frontend-only; backend no involucrado.
- ✅ Contratos entre servicios no afectados.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

**Flujo end-to-end:**

1. Usuario en RecordingPage presiona botón grabar.
2. `_startActualRecording()` → `_recordingManager.startRecording()`.
3. `RecordingManager.startRecording()` llama `verifySessionIntegrity()`.
4. Si faltan clips aprobados en disco → `verifyIntegrityStatic()` lanza `SessionIntegrityException` con `originalError = SessionData corregido` (clips faltantes removidos).
5. `verifySessionIntegrity()` captura, actualiza su `sessionData`, re-lanza.
6. Excepción propagada a `recording_page.dart` → handler específico (nuevo).
7. Handler resetea estado UI (`idle`), actualiza `_sessionData` local, muestra SnackBar naranja.
8. Usuario puede reintentar grabación del chunk faltante.

**Coherencia:** Manejo de errores consistente con `_verifyIntegrity()` y con StorageFullException (naranja para errores recuperables). No hay inconsistencias.

**Alineación con plan:** Cambio cumple exactamente lo solicitado: handler específico antes del genérico, SnackBar naranja, mensaje fijo.

**Gaps:** 
- Mensaje fijo no detalla qué chunks faltan. Detalles disponibles en logs via `LoggerService`. Adecuado para UX simplificada.
- Handler no registra en `LoggerService`. Podría agregarse para depuración, pero no requerido.

**DX & Tooling — OBLIGATORIO:**

```
### Herramienta Propuesta: integrity_failure_simulator
- **Qué automatiza:** Simula corrupción de sesión (elimina archivos de clips aprobados) para verificar que el handler de SessionIntegrityException muestra SnackBar naranja, actualiza SessionData y no rompe el flujo.
- **Tipo:** CLI script Dart (integration test harness)
- **Cómo se usa:**
  - Crear proyecto de prueba y clips dummy: `dart run scripts/integrity_failure_simulator.dart create --project test_proj --chunks 3`
  - Corromper sesión eliminando clip del chunk 1: `dart run scripts/integrity_failure_simulator.dart corrupt --project test_proj --chunk 1`
  - Ejecutar app en modo test y disparar startRecording: `dart run scripts/integrity_failure_simulator.dart verify --project test_proj`
  - La tool verifica presence de SnackBar naranja y que SessionData ya no contiene chunk 1 en `approvedClips`.
- **Impacto para el usuario final:** QA automatizado; asegura comportamiento correcto ante pérdida de archivos. Reduce pruebas manuales y previene regresiones.
- **Prioridad:** Media — útil para validación confidential, pero no bloquea paso actual.
```

---

## 5️⃣ Criterios de Aceptación

Lista binaria (sí/no):

- ✅ [DATA] Sin cambios de schema; SessionData corregido se propaga correctamente en runtime.
- ✅ [CODE] `on SessionIntegrityException catch (e)` insertado antes del catch genérico (L~539).
- ✅ [CODE] Handler resetea `_recordingState = RecordingState.idle` y `_isProcessingRecording = false`.
- ✅ [CODE] Handler actualiza `_sessionData = e.originalError as SessionData?`.
- ✅ [UX] SnackBar naranja mostrado con mensaje exacto "Integridad de sesion comprometida — clips faltantes removidos".
- ✅ [UX] SnackBar `duration` >= 5s (consistente con `_verifyIntegrity`).
- ✅ [BACKEND] No afecta endpoints; ningún cambio en backend.
- ✅ [FULLSTACK] Flujo continúa: después del error, usuario puede iniciar nueva grabación.
- ✅ [DX] Herramienta `integrity_failure_simulator.dart` ejecuta sin errores y detecta presencia del handler.
- ✅ [REGRESSION] Catch genérico posterior captura otras excepciones (orden correcto).

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `_sessionData` no actualizado → UI inconsistente (muestra clips eliminados) | Alta | Omisión de asignación `_sessionData = e.originalError` en handler | Especificar explícitamente en tarea 1; code review enfocado en asignación |
| Orden de catch blocks incorrecto (genérico antes) | Alta | Error al insertar código | Verificar diff; Dart compila pero handler nunca ejecutado si orden incorrecto |
| Mensaje fijo no suficientemente informativo | Media | Simplificación vs `_verifyIntegrity` que detalla chunks | Detalles ya en logs (LoggerService); considerar botón "Ver logs" en futuro |
| Falta logging en handler → dificulta diagnóstico | Baja | No se escribe en `app.log` | Opcional: agregar `LoggerService.log('RecordingPage', 'Session integrity issue: ${e.message}')` |
| Exception lanzada en otro flujo no cubierto (ej: `_verifyIntegrity` ya cubierto) | Baja | Solo `_startActualRecording` modifica | Asegurar que cualquier llamada futura a `verifySessionIntegrity` use try-catch apropiado |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: Crear simulador de fallos de integridad | `scripts/integrity_failure_simulator.dart` | `Future<void> simulateMissingClips({required String projectId, List<int>? chunksToRemove})` + `Future<void> main(List<String> args)` con subcommands `create`, `corrupt`, `verify` | — | DX | Media | 2h | Ninguna | `dart run scripts/integrity_failure_simulator.dart --help` imprime ayuda sin error |
| 1 | Insertar handler `SessionIntegrityException` en `_startActualRecording` | `lib/features/recording/recording_page.dart` (insert after L538) | Bloque completo según sección 2, con mensaje fijo, naranja, duration 5s, actualización `_sessionData` | Seguir `_verifyIntegrity()` L191-203 (mismo color, actualización state, duration) | CODE | Baja | 0.5h | Tarea 0 (opcional, para validación) | `flutter analyze` limpio; compilación exitosa |
| 2 | Validación manual: forzar excepción y verificar SnackBar | — | — | — | FULLSTACK | Baja | 0.5h | Tarea 1 | Eliminar archivo clip aprobado; iniciar grabación; SnackBar naranja aparece; `_sessionData` ya no incluye chunk eliminado |

**Tiempo total estimado:** 3h (incluye herramienta DX). Sin herramienta: 1h.

---

## 🔮 Roadmap (NO implementar ahora)

- Añadir logging en handler para diagnóstico (`LoggerService.log`).
- Considerar SnackBar con acción "Ver detalles" que muestre chunks faltantes.
- Extender `integrity_failure_simulator` para simular otros errores (StorageFull, CameraHardware).
- Integrar `integrity_failure_simulator` en CI como test de regresión.

---

## 🚫 Reglas de Oro Cumplidas

- ✅ Análisis accionable y específico, no genérico.
- ✅ TODO verificado contra código fuente real.
- ✅ Suposiciones no verificadas: ≤ 2 (ninguna).
- ✅ Coherente con `phase-state.md` (paso 05 aún no iniciado).
- ✅ TODO el paso cubierto, incluyendo sub-pasos (tareas 1-3).
- ✅ Etapas secuenciales: data → code → backend → fullstack+DX.
- ✅ ≥ 1 herramienta DX propuesta (`integrity_failure_simulator`).
- ✅ Tareas atómicas: cada tarea = un artefacto (script, archivo Dart) o validación.
- ✅ Interfaz exacta por tarea: firma completa, patrón explícito.
- ✅ Verificación inline por tarea: comando concreto.
- ✅ Implementador no decide ningún detalle de diseño (bloque, mensaje, color especificados).

---

** Idioma de respuesta:** Español 🇪🇸

**Fin del análisis.**
