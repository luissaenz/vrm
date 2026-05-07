# Análisis Técnico — Paso 5: Catch-especifico-SessionIntegrityException

**Agente:** ling  
**Paso:** 05-catch-especifico-SessionIntegrityException  
**Fase:** mvp  
**Fecha:** 2026-05-06  
**Origen:** Sugerencia 🟡 validación — Paso 03  
**Prioridad:** Media  

---

## 0️⃣ Verificación contra Código Fuente

### Elementos Verificados

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|--|---|
| 1 | `SessionIntegrityException` existe | `cat lib/core/exceptions/vrm_exceptions.dart` | ✅ | Línea 41-47, clase definida |
| 2 | `recording_page.dart` tiene catch genérico L539-553 | `grep -n "catch (e)" lib/features/recording/recording_page.dart` | ✅ | Líneas 539-553, 624-638, 665-667 |
| 3 | `_verifyIntegrity()` llama `verifyIntegrityStatic()` | `grep -n "_verifyIntegrity\|verifyIntegrityStatic" lib/features/recording/recording_page.dart` | ✅ | Línea 183-184, 191 |
| 4 | `SessionIntegrityException` capturado en `_verifyIntegrity()` | `grep -A5 "on SessionIntegrityException" lib/features/recording/recording_page.dart` | ✅ | Líneas 191-203, SnackBar naranja ya existente |
| 5 | `_startActualRecording()` tiene catch genérico L539 | `sed -n '525,554p' lib/features/recording/recording_page.dart` | ✅ | Línea 539: `catch (e)` genérico |
| 6 | `_stopRecording()` tiene catch genérico L624 | `sed -n '602,639p' lib/features/recording/recording_page.dart` | ✅ | Línea 624: `catch (e)` genérico |
| 7 | `_applyHardwareSettings()` tiene catch genérico L665 | `sed -n '643,668p' lib/features/recording/recording_page.dart` | ✅ | Línea 665: `catch (e)` genérico |
| 8 | `SessionIntegrityException` NO se lanza en `_startRecording` | `grep -n "startRecording\|SessionIntegrity" lib/features/recording/services/recording_manager.dart` | ✅ | `verifyIntegrityStatic` lanza, pero no en flujo startRecording |

### Discrepancias Encontradas

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | Catch genérico L539-553 en `_startActualRecording()` no distingue `SessionIntegrityException` | → Agregar `on SessionIntegrityException catch (e)` antes del catch genérico |
| D2 | Catch genérico L624-638 en `_stopRecording()` no distingue `SessionIntegrityException` | → Agregar `on SessionIntegrityException catch (e)` antes del catch genérico |
| D3 | Catch genérico L665-667 en `_applyHardwareSettings()` no distingue `SessionIntegrityException` | → Agregar `on SessionIntegrityException catch (e)` antes del catch genérico |
| D4 | `SessionIntegrityException` ya capturado en `_verifyIntegrity()` (L191) con SnackBar naranja ✅ | → Mantener como está (ya correcto) |

---

## 1️⃣ Análisis de Datos

**Enfoque:** No hay cambios en schema, tablas o migraciones. Excepción de integridad de sesión es manejo de estado, no persistencia.

- **Excepción:** `SessionIntegrityException` extiende `VRMException`, contiene `message`, `code='session_integrity_error'`, y `originalError` (SessionData corregido)
- **Estado actual:** `SessionData.approvedClips` es Map<int, String> con paths a clips MP4. Si archivo no existe, `verifyIntegrityStatic()` lanza excepción.
- **Impacto:** Ningún cambio en DB. Solo manejo de errores más específico.

---

## 2️⃣ Análisis de Código

### Funciones a modificar

#### 2.1 `_startActualRecording()` - Líneas 525-553
**Ubicación:** `lib/features/recording/recording_page.dart`

**Firma actual:**
```dart
} on CameraHardwareException catch (e) {
  // ...
} catch (e) {  // ← L539: catch genérico
  debugPrint('[RecordingPage] Failed to start recording: $e');
  // ...
}
```

**Cambio propuesto:**
```dart
} on CameraHardwareException catch (e) {
  // ...
} on SessionIntegrityException catch (e) {
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
    });
  }
  // Ya manejado en _verifyIntegrity() con SnackBar naranja
  // No hacer nada aquí, el error ya fue mostrado al usuario
} catch (e) {
  debugPrint('[RecordingPage] Failed to start recording: $e');
  // ...
}
```

**Patrón a seguir:** Igual que `_verifyIntegrity()` (L191-203) que ya captura `SessionIntegrityException` con SnackBar naranja.

#### 2.2 `_stopRecording()` - Líneas 589-639
**Ubicación:** `lib/features/recording/recording_page.dart`

**Firma actual:**
```dart
try {
  final clipPath = await _recordingManager!.stopRecording();
  // ...
} catch (e) {  // ← L624: catch genérico
  debugPrint('[RecordingPage] Failed to stop recording: $e');
  // ...
}
```

**Cambio propuesto:**
```dart
try {
  final clipPath = await _recordingManager!.stopRecording();
  // ...
} on SessionIntegrityException catch (e) {
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
    });
  }
  // Ya manejado en _verifyIntegrity() con SnackBar naranja
} catch (e) {
  debugPrint('[RecordingPage] Failed to stop recording: $e');
  // ...
}
```

**Patrón a seguir:** Mismo patrón de separación de concerns — excepción específica antes de genérica.

#### 2.3 `_applyHardwareSettings()` - Líneas 643-668
**Ubicación:** `lib/features/recording/recording_page.dart`

**Firma actual:**
```dart
try {
  await _cameraService.setFlashMode(...);
  // ...
} on CameraHardwareException catch (e) {
  // ...
} catch (e) {  // ← L665: catch genérico
  debugPrint('[RecordingPage] Error aplicando ajustes de hardware: $e');
}
```

**Cambio propuesto:**
```dart
try {
  await _cameraService.setFlashMode(...);
  // ...
} on CameraHardwareException catch (e) {
  // ...
} on SessionIntegrityException catch (e) {
  // No aplica en este contexto, pero por consistencia
  if (mounted) {
    setState(() {
      _recordingState = RecordingState.idle;
      _isProcessingRecording = false;
    });
  }
} catch (e) {
  debugPrint('[RecordingPage] Error aplicando ajustes de hardware: $e');
}
```

**Patrón a seguir:** Consistencia en manejo de excepciones específicas.

### Clases y tipos involucrados

| Clase | Archivo | Uso |
|---|---|---|
| `SessionIntegrityException` | `lib/core/exceptions/vrm_exceptions.dart` | Excepción lanzada por `verifyIntegrityStatic()` |
| `SessionData` | `lib/features/recording/models/session_data.dart` | Contiene `approvedClips: Map<int, String>` |
| `RecordingManager` | `lib/features/recording/services/recording_manager.dart` | `verifyIntegrityStatic()` estático |

---

## 3️⃣ Análisis de Backend

**Endpoints:** No aplica — manejo de excepciones puramente frontend.

**Contratos:** 
- `SessionIntegrityException` transporta `originalError` como `SessionData` corregido
- La UI en `_verifyIntegrity()` (L196-202) ya muestra SnackBar naranja con `e.message`

**Flujo:**
```
RecordingPage.initState()
  → _checkPermissionsAndInitCamera()
    → _verifyIntegrity()
      → RecordingManager.verifyIntegrityStatic()
        → Si faltan clips: lanza SessionIntegrityException
        → Catch en _verifyIntegrity() on SessionIntegrityException
          → Muestra SnackBar naranja
          → Recupera SessionData corregido
```

**Cambio propuesto:** Extender el mismo patrón a `_startActualRecording()` y `_stopRecording()` para consistencia.

---

## 4️⃣ Análisis de Fullstack + DX

### Flujo completo actual

```
Usuario inicia grabación
  → _startActualRecording()
    → try { startRecording() }
      → on CameraHardwareException: diálogo de error
      → catch (e): SnackBar rojo "Error inesperado"
        ✗ SessionIntegrityException cae aquí (mal)
```

### Problema DX

**Fricción:** Si `SessionIntegrityException` ocurre durante grabación (p. ej., clip aprobado fue eliminado manualmente del disco), el usuario ve:
- ❌ SnackBar rojo genérico "Error inesperado"
- ❌ Mensaje técnico `$e` en debugPrint
- ❌ Ninguna acción de recuperación clara

**Solución DX:**
```dart
on SessionIntegrityException catch (e) {
  // El error ya fue mostrado en _verifyIntegrity()
  // Solo limpiar estado, no molestar al usuario
}
```

### Herramienta Propuesta: Extensión de LoggerService para SessionIntegrity

```
### Herramienta Propuesta: SessionIntegrityMonitor
- **Qué automatiza:** Monitorea consistencia de clips aprobados vs archivos en disco
  antes de operaciones críticas (start/stop recording)
- **Tipo:** Wrapper de RecordingManager con pre-check automático
- **Cómo se usa:**
  ```dart
  await SessionIntegrityMonitor.ensureCleanState(sessionData);
  // Lanza SessionIntegrityException con SnackBar naranja si hay inconsistencia
  ```
- **Impacto para el usuario final:** Evita que operaciones fallen a mitad de camino
  por inconsistencias detectables previamente. SnackBar naranja no intrusivo.
- **Prioridad:** Tarea 0 — implementar antes de integración completa
```

### Gaps detectados

1. **Inconsistencia en manejo:** `_verifyIntegrity()` ya captura bien `SessionIntegrityException`, pero `_startActualRecording()` y `_stopRecording()` no
2. **Duplicación de código:** Cada método debería delegar verificación a `RecordingManager.verifyIntegrityStatic()` antes de operar
3. **Falta de logging estructurado:** `SessionIntegrityException` no se loguea con tag específico

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] recording_page.dart: _startActualRecording() captura on SessionIntegrityException antes de catch genérico
✅ [CODE] recording_page.dart: _stopRecording() captura on SessionIntegrityException antes de catch genérico  
✅ [CODE] recording_page.dart: _applyHardwareSettings() captura on SessionIntegrityException antes de catch genérico
✅ [CODE] SessionIntegrityException no produce SnackBar duplicado (ya mostrado en _verifyIntegrity)
✅ [CODE] Estado limpio (_recordingState = idle, _isProcessingRecording = false) al capturar SessionIntegrityException
✅ [FULLSTACK] Flujo: verifyIntegrity() → SnackBar naranja → usuario informado → operaciones subsiguientes no fallan por misma excepción
✅ [DX] LoggerService.log() registra SessionIntegrityException con tag 'SessionIntegrity'
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| SnackBar duplicado | Baja | _verifyIntegrity() ya muestra, _startRecording() podría mostrar otro | En catch específico no mostrar SnackBar (ya mostrado) |
| Estado inconsistente | Media | Si exception ocurre mid-recording, estado queda "recording" | Resetear _recordingState = idle en catch específico |
| Performance | Baja | verifyIntegrityStatic() llamado múltiples veces | Cachear resultado por 5s o verificar solo en puntos críticos |
| MissingPluginException en stopRecording() | Alta | stitcher plugin sin handler nativo | SessionIntegrityException no enmascara MissingPluginException |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX**: SessionIntegrityMonitor wrapper | `lib/features/recording/services/session_integrity_monitor.dart` | `static Future<void> ensureCleanState(SessionData data)` | `RecordingManager.verifyIntegrityStatic()` | DX | Baja | 0.2h | Ninguna | → importable sin error, test unitario pasa |
| 1 | Modificar _startActualRecording() | `lib/features/recording/recording_page.dart` L539 | `on SessionIntegrityException catch (e)` antes de `catch (e)` | Igual a _verifyIntegrity() L191 | CODE | Baja | 0.1h | Tarea 0 | → `flutter test test/recording_page_test.dart` pasa |
| 2 | Modificar _stopRecording() | `lib/features/recording/recording_page.dart` L624 | `on SessionIntegrityException catch (e)` antes de `catch (e)` | Igual a _verifyIntegrity() L191 | CODE | Baja | 0.1h | Tarea 0 | → `flutter test test/recording_page_test.dart` pasa |
| 3 | Modificar _applyHardwareSettings() | `lib/features/recording/recording_page.dart` L665 | `on SessionIntegrityException catch (e)` antes de `catch (e)` | Igual a _verifyIntegrity() L191 | CODE | Baja | 0.1h | Tarea 0 | → `flutter test test/camera_service_test.dart` pasa |
| 4 | LoggerService tag para SessionIntegrity | `lib/core/services/logger_service.dart` | `LoggerService.log('SessionIntegrity', ...)` | Igual a 'RecordingManager' tag | CODE | Baja | 0.1h | Ninguna | → `grep SessionIntegrity lib/core/services/logger_service.dart` |
| 5 | Verificación lint + tests | — | — | — | FULLSTACK | Baja | 0.2h | Tareas 1-4 | → `flutter analyze` 0 errores, `flutter test` pasa |

**Tiempo total estimado:** ~0.8 horas

---

## 🔮 Roadmap

- **Integridad proactiva:** Llamar `verifyIntegrityStatic()` antes de cualquier operación crítica (start/stop recording) para prevenir excepciones a mitad de flujo
- **Auto-recuperación:** Si `SessionIntegrityException` detecta clips faltantes, ofrecer botón "Re-scan" para reconstruir estado desde disco
- **Métricas:** Trackear ocurrencias de `SessionIntegrityException` para identificar patrones (¿los usuarios borran clips manualmente?)

---

## 🚫 Reglas de Oro Verificadas

- ✅ **Análisis accionable y específico:** 5 tareas atómicas, cada una con interfaz exacta
- ✅ **TODO verificado contra código:** 8 elementos en §0, todos con evidencia
- ✅ **Discrepancias señaladas:** 4 (D1-D4) con resolución concreta
- ✅ **Si plan contradice código → código gana:** Plan dice "Catch genérico", código necesita específico → se especifica
- ✅ **Etapas secuenciales:** data → code → backend → fullstack+DX, sin saltar
- ✅ **≥ 1 herramienta DX propuesta:** SessionIntegrityMonitor
- ✅ **Tareas atómicas:** 1 artefacto por tarea, interfaz completa, patrón explícito, verificación inline
- ✅ **El implementador no decide nada:** Interfaces completas, sin inferencias
