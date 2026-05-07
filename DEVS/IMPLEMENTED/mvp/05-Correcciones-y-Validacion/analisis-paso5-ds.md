# Análisis Técnico — Paso 5: Catch-especifico-SessionIntegrityException

**Agente:** ds
**Paso:** 5
**Fase:** mvp
**Prioridad:** Media
**Origen:** Sugerencia 🟡 validacion — Paso 03

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `SessionIntegrityException` existe | grep en `lib/core/exceptions/vrm_exceptions.dart` | ✅ | L41-46: clase con `message`, `code`, `originalError` |
| 2 | `RecordingManager.verifyIntegrityStatic()` existe | `recording_manager.dart` | ✅ | L366-406: `static Future<SessionData> verifyIntegrityStatic(SessionData data)` |
| 3 | `RecordingManager.verifySessionIntegrity()` existe | `recording_manager.dart` | ✅ | L409-416: instancia wrapper que rethrow |
| 4 | `startRecording()` llama a `verifySessionIntegrity()` | `recording_manager.dart` | ✅ | L60: `await verifySessionIntegrity();` |
| 5 | `recording_page.dart` importa `vrm_exceptions.dart` | imports | ✅ | L29: `import '../../../core/exceptions/vrm_exceptions.dart';` |
| 6 | `recording_page.dart` ya maneja `SessionIntegrityException` en `_verifyIntegrity()` | `recording_page.dart` | ✅ | L191-203: handler con orange SnackBar |
| 7 | `_startActualRecording()` tiene generic catch sin `SessionIntegrityException` | `recording_page.dart` | ✅ | L539-553: solo generic `catch (e)` — **NO** hay handler especifico |
| 8 | `_startActualRecording()` tiene `StorageFullException` catch | `recording_page.dart` | ✅ | L515-526 |
| 9 | `_startActualRecording()` tiene `CameraHardwareException` catch | `recording_page.dart` | ✅ | L527-538 |
| 10 | Plan dice L535-548 para generic catch | `recording_page.dart` | ⚠️ | Generic catch REALMENTE L539-553 (offset menor, no funcional) |

### Discrepancias encontradas

| Discrepancia | Resolución |
|---|---|
| Plan referencia L535-548, pero generic catch real en L539-553 | Offset irrelevante para implementacion — insertar handler ENTRE L538 y L539 |
| Plan dice "reemplazar catch generico" pero es AGREGAR handler especifico ANTES del generico | Aclarar: NO reemplazar — agregar `on SessionIntegrityException` antes del `catch (e)` existente. Generic catch debe seguir funcionando |

---

## 1️⃣ Análisis de Datos

No aplica. Paso 5 no toca schema, migraciones, ni persistencia de datos. Solo manejo de excepciones en codigo existente.

---

## 2️⃣ Análisis de Código

### Funciones afectadas

| Funcion | Archivo | Rol | Cambio necesario |
|---|---|---|---|
| `_startActualRecording()` | `recording_page.dart:473-554` | Inicia grabacion, llama `RecordingManager.startRecording()` | Agregar handler `on SessionIntegrityException` antes de generic catch |
| `_verifyIntegrity()` | `recording_page.dart:179-207` | Verifica integridad al iniciar pagina | **YA** maneja `SessionIntegrityException` — patron a copiar |
| `RecordingManager.verifyIntegrityStatic()` | `recording_manager.dart:366-406` | Static — verifica que clips aprobados esten en disco | Existe, no modificar |
| `RecordingManager.verifySessionIntegrity()` | `recording_manager.dart:409-416` | Instancia — catch SIE, update sessionData, rethrow | Existe, no modificar |
| `RecordingManager.startRecording()` | `recording_manager.dart:47-86` | Llama `verifySessionIntegrity()` L60 | Existe, no modificar |

### Cadena de excepcion

```
_startActualRecording()                    (recording_page.dart:510-554)
  └─ _recordingManager!.startRecording()  (recording_manager.dart:47-86)
       └─ verifySessionIntegrity()         (recording_manager.dart:409-416)
            └─ verifyIntegrityStatic()     (recording_manager.dart:366-406)
                 throws SessionIntegrityException ← PROYECTIL A CAPTURAR
```

Actualmente propaga hasta generic `catch (e)` L539. Necesita handler dedicado.

### Patron existente a copiar

`recording_page.dart:191-203` (en `_verifyIntegrity()`):

```dart
    } on SessionIntegrityException catch (e) {
      if (mounted) {
        setState(() {
          _sessionData = e.originalError as SessionData?;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
```

Mismo patron debe aplicarse en `_startActualRecording()` con el mensaje del plan: *"Integridad de sesion comprometida — clips faltantes removidos"*.

### Ubicacion exacta de insercion

```dart
    } on CameraHardwareException catch (e) {   // L527
      // ... dialog ...
      }                                           // L538 -- FIN CameraHardwareException
    } on SessionIntegrityException catch (e) {   // ← INSERTAR AQUI
      // Orange SnackBar con mensaje especifico
    } catch (e) {                                 // L539
      // ... red SnackBar generico ...
    }
```

### Imports

`vrm_exceptions.dart` ya importado L29. No requiere cambios.

---

## 3️⃣ Análisis de Backend

No aplica. Paso 5 es exclusivamente frontend Flutter.

---

## 4️⃣ Análisis de Fullstack + DX

### Flujo

```
startRecording() → verifySessionIntegrity()
  → integrity OK? → prosigue grabacion
  → missing clips? → verifyIntegrityStatic() throw SIE
    → verifySessionIntegrity() catch SIE, update sessionData, rethrow
      → _startActualRecording() catch SIE → orange SnackBar, setState idle
```

### Coherencia MVP

Paso coherente. Closing el gap donde `SessionIntegrityException` de `startRecording()` solo caia en catch generico (red SnackBar) sin distincion UX. Usuario perdeia contexto de que es error de integridad recuperable vs error critico de hardware.

### DX & Tooling

```
### Herramienta Propuesta: vrm_health_check.dart --fix
- **Que automatiza:** Reparacion automática de integridad de sesiones huerfanas o corruptas
- **Tipo:** CLI (ya existe como script)
- **Como se usa:** `dart run scripts/vrm_health_check.dart --fix`
- **Impacto:** Usuario no necesita saber que clips faltan → herramienta limpia referencias huerfanas y repara session_data.json automaticamente
- **Prioridad:** Tarea 0 — implementar antes del catch para que el flujo completo (deteccion + reparacion + UI) funcione como unidad
```

---

## 5️⃣ Criterios de Aceptacion

```
✅ [CODE] `on SessionIntegrityException catch (e)` agregado en `_startActualRecording()` entre CameraHardwareException y generic catch
✅ [CODE] Handler muestra SnackBar naranja con mensaje "Integridad de sesion comprometida — clips faltantes removidos"
✅ [CODE] setState resetea `_recordingState = RecordingState.idle` y `_isProcessingRecording = false` en el handler
✅ [CODE] Generic `catch (e)` posterior permanece intacto para otras excepciones
✅ [CODE] No hay regresion en `_verifyIntegrity()` handler existente (L191-203)
✅ [TEST] `flutter test` pasa sin cambios rotos
✅ [DX] `vrm_health_check.dart --fix` ejecuta reparacion real (no solo print)
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigacion |
|---|---|---|---|
| Handler agregado en posicion incorrecta rompe cadena catch | Media | Insertar en linea equivocada entre try-catch anidados | Referencia exacta: insertar entre L538 y L539. Verificar con `flutter analyze` |
| SnackBar se solapa con `_verifyIntegrity()` SnackBar si ambos fires | Baja | `_verifyIntegrity()` se ejecuta en `initState`, `_startActualRecording()` es posterior — gap temporal suficiente | No hay overlap real. Monitorear en prueba manual |
| `e.originalError` casteo falla si tipo cambia | Media | `SessionIntegrityException.originalError` se usa como `SessionData` en `_verifyIntegrity()` pero en `startRecording()` el `verifySessionIntegrity()` ya actualizo sessionData internamente | En el handler de `_startActualRecording()` NO se necesita castear `originalError` — RecordingManager ya modifico su sessionData. Solo mostrar SnackBar y resetear UI state |

---

## 7️⃣ Plan de Implementacion

| # | Tarea | Artefacto | Interfaz exacta | Patron a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificacion |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX**: reparar `vrm_health_check.dart --fix` | `scripts/vrm_health_check.dart` | `void runFix() → Future<void>` — eliminar tmp huerfanos, resetear sesiones sin proyecto | `scripts/store_prep_cli.dart` (subcomandos ejecutan acciones reales) | DX | Baja | 0.5h | Ninguna | `dart run scripts/vrm_health_check.dart --fix` sin errores |
| 1 | Agregar catch `SessionIntegrityException` en `_startActualRecording()` | `recording_page.dart` | Insertar `} on SessionIntegrityException catch (e) {` entre L538 y L539 con orange SnackBar + setState idle | `recording_page.dart:191-203` (`_verifyIntegrity()` handler) | CODE | Baja | 0.3h | Tarea 0 | `flutter analyze` sin errores + revisar L538-553 confirmando 3 catch clauses |
| 2 | Verificar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.3h | Tarea 1 | Criterios §5 pasan todos |

**Tiempo total estimado:** 1.1h

### Detalle Tarea 1

Insertar en `recording_page.dart` entre linea 538 y 539:

```dart
    } on SessionIntegrityException catch (e) {
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Integridad de sesion comprometida — clips faltantes removidos',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
```

**Nota:** Usar mensaje hardcodeado del plan (no `e.message`) por consistencia con el requisito del paso. Si se prefiere mensaje dinamico de la exception, usar `Text(e.message)` como en `_verifyIntegrity()` L198 — pero el plan especifica texto literal.

---

## Riesgos Futuros (Roadmap)

- `SessionIntegrityException` podria beneficiarse de un `userFacingMessage` separado del `message` tecnico para reuso en UI sin hardcodear textos
- Considerar centralizar patron de SnackBar naranja en `VRMNotifications.showWarning()` para consistencia visual — actualmente hay 3 formas distintas de mostrar orange SnackBar
