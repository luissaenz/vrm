# Análisis Técnico — Paso 05: Catch SessionIntegrityException, MaterialBanner, Metrics, debugPrint, HealthCheck, Adaptive Icons, Widget Test, Screenshots

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | SessionIntegrityException existe | vrm_exceptions.dart L41-46 | ✅ | Excepción definida con message, code, originalError |
| 2 | verifyIntegrityStatic existe | recording_manager.dart L366-406 | ✅ | Función estática que lanza SessionIntegrityException |
| 3 | Catch SessionIntegrityException en recording_page.dart | recording_page.dart L191-203 | ✅ | Ya implementado en _verifyIntegrity() |
| 4 | SnackBar naranja en SessionIntegrityException | recording_page.dart L196-201 | ✅ | backgroundColor: Colors.orange |
| 5 | SnackBar fallback en script_studio_page.dart L338-361 | script_studio_page.dart L338-361 | ✅ | SnackBar flotante naranja implementado |
| 6 | Metrics hardcoded "42m" en recording_end_page.dart L316 | recording_end_page.dart L316 | ⚠️ | "42" hardcoded, no conectado a SessionData |
| 7 | debugPrint en recording_page.dart L287, L661, L666 | recording_page.dart L287, L661, L666 | ⚠️ | debugPrint presente en _applyHardwareSettings |
| 8 | LoggerService disponible | logger_service.dart L17-52 | ✅ | Singleton con log persistente |
| 9 | vrm_health_check.dart --fix imprime solo | vrm_health_check.dart L60-166 | ⚠️ | check mode imprime pero no ejecuta cleanup |
| 10 | Widget test roto | test/widget_test.dart L14-29 | ⚠️ | Referencia counter que no existe |
| 11 | Screenshots existentes | assets/store/screenshots/ | ⚠️ | 5 archivos pero resolución 1024x1024 |
| 12 | adaptive_icon no configurado | pubspec.yaml | ❌ | Sin adaptive_icon_background/foreground |

**Discrepancias encontradas**:
- recording_end_page.dart usa "42" hardcoded en vez de datos reales de SessionData
- recording_page.dart L661, L666 usa debugPrint en vez de LoggerService
- vrm_health_check.dart check --fix no ejecuta acciones reales
- widget_test.dart referencia counter inexistente
- Screenshots resolución insuficiente para store
- adaptive_icon no configurado en pubspec.yaml

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### SessionIntegrityException - Data Flow
- **SessionData.approvedClips**: Map<int, String> con paths a clips aprobados
- **verifyIntegrityStatic()**: Itera approvedClips, verifica existencia de archivos en disco
- **SessionIntegrityException.originalError**: Contiene SessionData corregida sin clips faltantes
- **Impacto**: Si clips faltan, se eliminan referencias y se notifica al usuario

### RecordingEndPage metrics
- **Datos hardcodeados**: "42" en L316, "42" y "12" en L367
- **SessionData disponible**: sessionData.chunksRecorded, sessionData.takesPerChunk
- **Cálculo real**: duración = suma de durations de clips, takes = conteo de takesPerChunk

### Archivos de datos involucrados
- `lib/features/recording/models/session_data.dart` - modelo con approvedClips, takesPerChunk
- `lib/features/recording/services/recording_manager.dart` - maneja sessionData durante grabación

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Tarea 1: Catch SessionIntegrityException en recording_page.dart
**Estado**: ✅ YA IMPLEMENTADO en L191-203 de recording_page.dart
- `on SessionIntegrityException catch (e)` captura excepción específica
- SnackBar naranja con mensaje de integridad comprometida
- originalError contiene SessionData corregida

### Tarea 2: MaterialBanner en script_studio_page.dart
**Archivo**: lib/features/assistant/script_studio_page.dart L338-361
**Estado actual**: SnackBar flotante naranja
**Cambio necesario**: Reemplazar `ScaffoldMessenger.showSnackBar()` por `ScaffoldMessenger.showMaterialBanner()`
- **Interfaz**: Sin cambios, mismo mensaje y comportamiento
- **Patrón a seguir**: MaterialBanner sticky visible hasta descarte del usuario

### Tarea 3: Metrics reales en recording_end_page.dart
**Archivo**: lib/features/recording/recording_end_page.dart L316, L367
**Cambio necesario**: Conectar a SessionData del proyecto
- Reemplazar "42" por cálculo real de duración desde clips
- Reemplazar "12" por conteo real de takes
- Si no hay datos, mostrar "--"
- **Dependencia**: SessionData debe pasarse como parámetro o leerse desde ProjectRepository

### Tarea 4: Migrar debugPrint a LoggerService en recording_page.dart
**Archivos**: recording_page.dart L287, L661, L666
**Cambio necesario**:
- L287: `debugPrint('[RecordingPage] Memory pressure...')` → `LoggerService.log('RecordingPage', 'Memory pressure detected')`
- L661: `debugPrint('[RecordingPage] Hardware setting not supported')` → `LoggerService.log('RecordingPage', 'Hardware setting not supported: $e')`
- L666: `debugPrint('[RecordingPage] Error aplicando ajustes')` → `LoggerService.log('RecordingPage', 'Error applying hardware settings: $e')`

### Tarea 5: vrm_health_check.dart --fix real
**Archivo**: scripts/vrm_health_check.dart L60-166
**Cambio necesario**: Implementar cleanup real en _runCheck() cuando fix=true
- Eliminar archivos temporales huérfanos en vrm_data/tmp/
- Resetear sesiones huérfanas sin proyecto padre
- Acciones documentadas en output

### Tarea 6: Widget test roto
**Archivo**: test/widget_test.dart
**Opciones**:
- Eliminar si no cubre funcionalidad real
- Reemplazar con test que verifique renderizado de pantalla principal

### Tarea 7: Screenshots store-ready
**Requisito**: 5 screenshots >= 1080x1920 (Android) o 1284x2778 (iOS)
**Estado**: 5 archivos existen pero 1024x1024
**Acción**: Capturar en dispositivo real

### Tarea 8: Adaptive icons Android 13
**Archivo**: pubspec.yaml
**Cambio necesario**: Agregar adaptive_icon_background y adaptive_icon_foreground

---

## 3️⃣ Análisis de Backend (ETAPA 3)

No aplica directamente. Paso 05 es frontend/DX.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo SessionIntegrityException
```
RecordingPage._verifyIntegrity() → RecordingManager.verifyIntegrityStatic()
→ verifica approvedClips en disco → lanza SessionIntegrityException si faltan
→ recording_page.dart captura con SnackBar naranja → UI actualiza sessionData
```

### Flujo fallback IA notification
```
ScriptStudioPage._handleGenerateScript() → ScriptFallbackService.generateAnalysis()
→ viability.summary contiene "localmente"/"fallback" → SnackBar naranja
→ PLAN: cambiar a MaterialBanner sticky
```

### Flujo metrics reales
```
RecordingEndPage → necesita SessionData con chunksRecorded, takesPerChunk
→ calcular duración total, conteo de takes
→ mostrar "--" si no hay datos
```

### DX & Tooling Propuesto: vrm_health_check --fix real
- **Qué automatiza**: Cleanup de archivos temporales huérfanos y sesiones huérfanas
- **Tipo**: CLI command
- **Cómo se usa**: `dart run scripts/vrm_health_check.dart check --fix`
- **Impacto**: Elimina tareas manuales de limpieza de vrm_data/tmp/
- **Prioridad**: Tarea 0 — implementar antes que el resto

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] SessionIntegrityException captura con handler dedicado en recording_page.dart
✅ [DATA] SessionData tiene approvedClips, takesPerChunk para calcular metrics
✅ [CODE] MaterialBanner reemplaza SnackBar en script_studio_page.dart:338
✅ [CODE] Metrics reales conectados a SessionData en recording_end_page.dart
✅ [CODE] debugPrint migrado a LoggerService en recording_page.dart:657,662
✅ [CODE] vrm_health_check.dart --fix ejecuta cleanup real
✅ [CODE] widget_test.dart eliminado o reparado
✅ [CODE] adaptive_icon configurado en pubspec.yaml
✅ [FULLSTACK] Usuario recibe SnackBar/Banner naranja en fallback IA
✅ [FULLSTACK] Usuario ve metrics reales en RecordingEndPage
✅ [DX] Herramienta vrm_health_check --fix limpia temp y sesiones huérfanas
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| SessionData no disponible en RecordingEndPage | Media | recording_end_page.dart no recibe projectId/sessionData | Pasar SessionData como parámetro desde RecordingManager |
| MaterialBanner overflow en pantalla pequeña | Baja | MaterialBanner sticky puede ocupar espacio | Usar ScaffoldMessenger.showMaterialBanner con dismiss direction |
| LoggerService.log no llama a debugPrint en Release | Baja | Logger solo escribe a archivo | Verificar que debugPrint no es necesario en Release |
| vrm_health_check --fix elimina datos válidos | Alta | Lógica de "huérfano" incorrecta | Validar que proyecto existe antes de eliminar |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: vrm_health_check --fix real | scripts/vrm_health_check.dart | `Future<void> _runCheck(bool fix)` | -- | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/vrm_health_check.dart check --fix` ejecuta cleanup |
| 1 | MaterialBanner fallback IA | lib/features/assistant/script_studio_page.dart | Reemplazar L338-361 | -- | CODE | Baja | 0.5h | Tarea 0 | → verificar: MaterialBanner visible sticky |
| 2 | Metrics reales RecordingEndPage | lib/features/recording/recording_end_page.dart | Agregar SessionData parámetro, calcular duración/takes | lib/features/recording/recording_manager.dart :: sessionData | CODE | Media | 1h | Tarea 0 | → verificar: "42" reemplazado por dato real, "--" si vacío |
| 3 | debugPrint → LoggerService | lib/features/recording/recording_page.dart | Reemplazar L287, L661, L666 | lib/core/services/logger_service.dart :: log() | CODE | Baja | 0.5h | Ninguna | → verificar: 0 debugPrint en recording_page.dart, mensajes en app.log |
| 4 | vrm_health_check --fix real | scripts/vrm_health_check.dart | Implementar cleanup en L120-122 | -- | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/vrm_health_check.dart check --fix` elimina temp |
| 5 | Reparar widget_test | test/widget_test.dart | Eliminar o reemplazar | -- | CODE | Baja | 0.25h | Ninguna | → verificar: `flutter test` pasa |
| 6 | Screenshots store-ready | assets/store/screenshots/ | Capturar en dispositivo real | -- | CODE | Manual | Variable | Dispositivo físico | → verificar: resolución >= 1080x1920 |
| 7 | Adaptive icons | pubspec.yaml | Agregar adaptive_icon_background/foreground | -- | CODE | Baja | 0.5h | Ninguna | → verificar: flutter pub run flutter_launcher_icons genera adaptive |

**Tiempo total estimado**: 5h (excluyendo screenshots manuales)

---

## Notas
- Paso 05 ya tiene SessionIntegrityException catch implementado
- MaterialBanner es cambio directo de SnackBar.showSnackBar → showMaterialBanner
- Metrics reales requieren pasar SessionData a RecordingEndPage
- debugPrint → LoggerService es reemplazo directo
- vrm_health_check --fix requiere implementar lógica de cleanup
