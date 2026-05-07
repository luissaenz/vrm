# 🧠 ANÁLISIS TÉCNICO — Paso 05: Catch-especifico-SessionIntegrityException

**Agente:** hy3  
**Fase:** mvp  
**Fecha:** 2026-05-06  
**Archivo plan:** `DEVS/plan.md` L109-129

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `SessionIntegrityException` existe | grep vrm_exceptions.dart | ✅ | vrm_exceptions.dart:41-46 |
| 2 | `verifyIntegrityStatic()` lanza excepción | read recording_manager.dart | ✅ | L366-406, throw L392 |
| 3 | `verifySessionIntegrity()` re-lanza | read recording_manager.dart | ✅ | L409-415, rethrow L414 |
| 4 | `startRecording()` llama verify | read recording_manager.dart | ✅ | L60: await verifySessionIntegrity() |
| 5 | `_startActualRecording()` L510-554 | read recording_page.dart | ✅ | L510-554, catch L539 genérico |
| 6 | `on SessionIntegrityException` en _startActualRecording | grep recording_page.dart | ❌ | NO EXISTE en L510-554 |
| 7 | `on SessionIntegrityException` en L191 | read recording_page.dart | ✅ | L191-206, otro método init |
| 8 | SnackBar naranja existe | read recording_page.dart L191-206 | ✅ | L196-202, backgroundColor: Colors.orange |
| 9 | `originalError` transporta `SessionData` | read recording_manager.dart | ✅ | L396-398, originalError: newData |
| 10 | `CameraHardwareException` catch existe | read recording_page.dart | ✅ | L527-538 |
| 11 | `StorageFullException` catch existe | read recording_page.dart | ✅ | L515-526 |
| 12 | Generic catch L539 → SnackBar rojo | read recording_page.dart | ✅ | L546-551, backgroundColor: Colors.red |

**Discrepancias:**
1. Plan dice "agregar on SessionIntegrityException en L535-548" → L535 es CameraHardwareException. Correcto es ANTES de L539 (generic catch).
2. `SessionIntegrityException` ya capturado en L191 (init method) pero NO en `_startActualRecording()` → gap real.

---

## 1️⃣ Análisis de Datos

- ✅ `SessionData.approvedClips: Map<int, String>` → claves chunkIndex, valores filePath
- ✅ `verifyIntegrityStatic()` itera `approvedClips` → verifica `File(filePath).exists()`
- ✅ Faltantes → remueve de `updatedApproved` → `newData.copyWith(approvedClips: updatedApproved)`
- ✅ `newData` pasa en `originalError` de `SessionIntegrityException`
- ⚠️ Si `_startActualRecording()` no captura → `originalError` perdido → datos corregidos no aplicados

---

## 2️⃣ Análisis de Código

- ✅ `SessionIntegrityException` extiende `VRMException` → `message`, `code`, `originalError`
- ✅ Catch L191 (init): `setState(_sessionData = e.originalError)` + SnackBar naranja
- ❌ Catch en `_startActualRecording()` (L510-554): SOLO `StorageFullException`, `CameraHardwareException`, genérico
- ✅ Patrón catch específico: `on XException catch (e)` antes de `catch (e)`
- ✅ `ScaffoldMessenger.showSnackBar()` con `Colors.orange` ya usado en L196

**Firma handler propuesto:**
```dart
on SessionIntegrityException catch (e) {
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
      _sessionData = e.originalError as SessionData?;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Integridad de sesion comprometida — clips faltantes removidos'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
```

**Patrón a seguir:** `recording_page.dart:191-206` (mismo archivo, init method).

---

## 3️⃣ Análisis de Backend

- ⚠️ No aplica. Paso 05 es frontend puro (Flutter/Dart).

---

## 4️⃣ Análisis de Fullstack + DX

- ✅ Flujo: `startRecording()` → `verifySessionIntegrity()` → `verifyIntegrityStatic()` → throw `SessionIntegrityException` → UI handler
- ✅ Coherencia: `originalError` transporta data corregida → UI debe aplicar
- ❌ Gap: `_startActualRecording()` no captura → user ve SnackBar rojo genérico "Error inesperado: SessionIntegrityException" en vez de mensaje específico
- ✅ UX: SnackBar naranja + mensaje claro + datos corregidos aplicados = recoverable sin crash

### Herramienta Propuesta: `test_integrity_check.dart`
- **Qué automatiza:** Verifica que `SessionIntegrityException` handlers capturen y apliquen `originalError` en todas las llamadas a `verifyIntegrityStatic()`.
- **Tipo:** Script CLI / test helper
- **Cómo se usa:** `dart run scripts/test_integrity_check.dart` → inyecta archivos faltantes mock → valida SnackBar naranja + data corregida
- **Impacto usuario final:** QA automatizado previene que fallos de integridad pasen desapercibidos a release.
- **Prioridad:** Tarea 0

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] on SessionIntegrityException catch (e) agregado en _startActualRecording() ANTES de generic catch
✅ [CODE] Handler captura e.originalError y actualiza _sessionData
✅ [UX] SnackBar naranja con mensaje "Integridad de sesion comprometida — clips faltantes removidos"
✅ [CODE] Generic catch L539 sigue funcionando para otras excepciones
✅ [DATA] approvedClips faltantes removidos de SessionData tras catch
✅ [DX] test_integrity_check.dart ejecuta sin errores y valida flujo
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `originalError` cast fail | Media | `e.originalError` null o tipo incorrecto | `as SessionData?` + null check + fallback a data existente |
| Handler en lugar equivocado | Baja | Confusión entre L191 y L510 | Verificar `_startActualRecording()` context, no init method |
| SnackBar duplicado | Baja | Init method L191 + nuevo handler L510 ambos disparan | Usar `mounted` check + return tras setState |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: test_integrity_check.dart | `scripts/test_integrity_check.dart` | `void main() async { ... }` | `scripts/vrm_health_check.dart` | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/test_integrity_check.dart` ejecuta sin crash |
| 1 | Agregar on SessionIntegrityException catch | `lib/features/recording/recording_page.dart` | `on SessionIntegrityException catch (e) { setState(_sessionData = e.originalError); ScaffoldMessenger.showSnackBar(orange) }` | `recording_page.dart:191-206` | CODE | Baja | 0.5h | Tarea 0 | → verificar: `flutter analyze` sin errores + catch específico presente en `_startActualRecording()` |
| 2 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.5h | Tarea 1 | → verificar: Criterios §5 [CODE] y [UX] pasan todos |

**Tiempo total estimado:** 2 horas

---

## 🔮 Roadmap (NO implementar ahora)

- Unificar todos los catch de excepciones VRM en un widget helper `VRMErrorHandler.show()` que centralice SnackBar/Dialog según tipo.
- Agregar tests unitarios con mocks para `CameraHardwareException`, `StorageFullException`, `SessionIntegrityException` en `error_handling_test.dart`.
