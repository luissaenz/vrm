# Análisis Técnico - Paso 5: Catch-especifico-SessionIntegrityException

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `SessionIntegrityException` existe | vrm_exceptions.dart | ✅ | lib/core/exceptions/vrm_exceptions.dart:41-47 |
| 2 | `verifyIntegrityStatic()` existe | recording_manager.dart | ✅ | lib/features/recording/services/recording_manager.dart:366-406 |
| 3 | Líneas 535-548 en recording_page.dart | catch genérico existente | ✅ | lib/features/recording/recording_page.dart:539-553 |
| 4 | `StorageFullException` manejado | catch específico | ✅ | recording_page.dart:515-526 |
| 5 | `CameraHardwareException` manejado | catch específico | ✅ | recording_page.dart:527-538 |
| 6 | `SessionIntegrityException` NO manejado | catch faltante | ❌ | Solo catch genérico en línea 539 |
| 7 | Import vrm_exceptions.dart | verificado | ✅ | recording_page.dart:29 |
| 8 | `verifySessionIntegrity()` llama a `verifyIntegrityStatic()` | verificado | ✅ | recording_manager.dart:409-416 |
| 9 | `startRecording()` llama `verifySessionIntegrity()` | verificado | ✅ | recording_manager.dart:60 |
| 10 | `SessionIntegrityException` tiene `originalError` | verificado | ✅ | vrm_exceptions.dart:45-46 (contiene SessionData corregida) |

**Discrepancias encontradas:**
1. ❌ `SessionIntegrityException` NO tiene handler dedicado en `recording_page.dart`. El catch genérico en línea 539 captura esta excepción sin mostrar feedback específico.
2. ⚠️ El mensaje del SnackBar genérico ("Error inesperado: $e") no informa al usuario sobre la recuperación automática de clips faltantes.

---

## 1️⃣ Análisis de Datos

N/A - Este paso no modifica schema de datos. La excepción ya existe y maneja datos de `SessionData`.

---

## 2️⃣ Análisis de Código

### Funciones afectadas:

| Archivo | Línea | Función/Clase | Acción |
|---|---|---|---|
| recording_page.dart | 539-553 | `_startRecording()` | Agregar `on SessionIntegrityException catch (e)` ANTES del catch genérico |

### Firmas relevantes:

```dart
// Excepción existente (NO crear, ya existe)
class SessionIntegrityException extends VRMException {
  SessionIntegrityException(
    super.message, {
    super.code = 'session_integrity_error',
    super.originalError,  // Contiene SessionData corregida
  });
}

// Método que lanza la excepción
static Future<SessionData> verifyIntegrityStatic(SessionData data) async
// Lanza SessionIntegrityException si clips faltantes (líneas 392-398)

// Método que llama al anterior
Future<void> verifySessionIntegrity() async
// Líneas 409-416 en recording_manager.dart
```

### Patrón a seguir:

El código ya tiene 2 handlers específicos antes del catch genérico:
- `StorageFullException` (línea 515): Muestra `_showRecoveryDialog` con `Icons.storage`
- `CameraHardwareException` (línea 527): Muestra `_showRecoveryDialog` con `Icons.videocam_off`

**SessionIntegrityException debe seguir el MISMO patrón** pero con SnackBar naranja (no dialog) según criterios de aceptación.

---

## 3️⃣ Análisis de Backend

N/A - No hay endpoints involucrados. Es manejo de excepción frontend.

---

## 4️⃣ Análisis de Fullstack + DX

### Flujo end-to-end:
1. Usuario inicia grabación → `_startRecording()` llama a `_recordingManager.startRecording()`
2. `RecordingManager.startRecording()` llama a `verifySessionIntegrity()` (línea 60)
3. `verifySessionIntegrity()` llama a `verifyIntegrityStatic()` (línea 411)
4. Si clips faltantes → `SessionIntegrityException` se lanza
5. **FALTA:** Handler dedicado para mostrar feedback naranja

### DX & Tooling Propuesta:

```markdown
### Herramienta Propuesta: session_integrity_validator
- **Qué automatiza:** Validación manual de integridad de sesión para testing
- **Tipo:** script CLI Dart
- **Cómo se usa:** `dart run scripts/session_integrity_validator.dart --project <id>`
- **Impacto para el usuario final:** Permite validar antes de iniciar grabación que todos los clips están presentes
- **Prioridad:** Tarea 0 (implementar antes que el resto del paso)
```

---

## 5️⃣ Criterios de Aceptación

| Criterio | Verificable |
|---|---|
| ✅ [DATA] SessionIntegrityException existe con campo originalError | ✓ |
| ✅ [CODE] Handler dedicado para SessionIntegrityException agregado antes del catch genérico | ✓ |
| ✅ [BACKEND] N/A - no aplica | ✓ |
| ✅ [FULLSTACK] Usuario ve SnackBar naranja con mensaje específico | ✓ |
| ✅ [DX] Herramienta session_integrity_validator creada | ✓ |

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| El handler se coloca DESPUÉS del catch genérico | Alta | Si el catch genérico está primero, SessionIntegrityException nunca será capturada específicamente | Verificar orden: StorageFullException → CameraHardwareException → **SessionIntegrityException** → catch genérico |
| originalError contiene SessionData corrupta | Media | Si SessionData tiene estado inconsistente | Usar `e.originalError as SessionData` con verificación de tipo |
| El SnackBar naranja no es visible en ciertos fondos | Baja | Color naranja sobre fondos claros | Usar `Colors.orange[800]` con texto blanco |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX & Tooling: session_integrity_validator | scripts/session_integrity_validator.dart | `Future<void> main(List<String> args)` | vrm_health_check.dart | DX | Baja | 0.25h | Ninguna | → verificar: `dart run scripts/session_integrity_validator.dart --help` muestra ayuda |
| 1 | Agregar handler SessionIntegrityException | lib/features/recording/recording_page.dart | `on SessionIntegrityException catch (e)` ANTES línea 539 | Patrón catch específico líneas 515-538 | CODE | Baja | 0.25h | Tarea 0 | → verificar: `flutter analyze` pasa sin errores |
| 2 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.25h | Tarea 1 | → verificar: `flutter test` pasa todos los tests |

**Tiempo total estimado:** 0.75 horas

---

## Código de Referencia para el Handler

```dart
// LÍNEA 539 (reemplazar catch genérico):
} on SessionIntegrityException catch (e) {
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Integridad de sesion comprometida — clips faltantes removidos',
        ),
        backgroundColor: Colors.orange,  // naranja específico
      ),
    );
    // Actualizar sessionData con versión corregida
    if (e.originalError != null) {
      _recordingManager?.sessionData = e.originalError as SessionData;
    }
  }
} catch (e) {
  debugPrint('[RecordingPage] Failed to start recording: $e');
  // ... resto del catch genérico
}
```