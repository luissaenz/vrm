# 🏛️ Análisis Unificado — MVP Pasos 05-12

**Generado:** 2026-05-06
**Fase:** mvp
**Pasos cubiertos:** 05 (SessionIntegrityException) → 12 (Screenshots store-ready)
**Proyecto-config:** `D:\Develop\Personal\vrm\proyecto-config.json`

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:-------|:---------------:|:------------------------:|:------------:|:----------------:|:-----------:|
| ling | ✅ | 4 (D1-D4, detectó 3 métodos faltantes) | SessionIntegrityMonitor | ✅ `archivo:línea` exactas | 4.5 |
| coenvironment | ✅ | 6 (cubre pasos 05-12 completos) | vrm_health_check --fix | ✅ `archivo:línea` + contexto | 4.8 |
| laguna | ✅ | 2 (solo _startActualRecording) | session_integrity_validator | ✅ `archivo:línea` exactas | 3.5 |
| ds | ✅ | 2 (plan offset L535 vs L539 + plan vs código) | vrm_health_check --fix | ✅ `archivo:línea` exactas | 4.0 |
| hy3 | ✅ | 2 (plan offset + gap real) | test_integrity_check.dart | ✅ `archivo:línea` exactas | 3.8 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| D1 | Plan dice L535-548 para generic catch, código real L539-553 | ds, hy3 | ✅ `recording_page.dart:539-553` | Implementar según código real. Insertar handler ANTES de L539, no según L535 del plan |
| D2 | `SessionIntegrityException` NO capturado en `_startActualRecording()` | ling, laguna, ds, hy3 | ✅ `recording_page.dart:539-553` (solo catch genérico) | Agregar `on SessionIntegrityException catch (e)` antes de catch genérico |
| D3 | `SessionIntegrityException` NO capturado en `_stopRecording()` | ling | ✅ `recording_page.dart:624-638` (solo catch genérico) | Agregar handler específico — ling único en detectar esto |
| D4 | `SessionIntegrityException` NO capturado en `_applyHardwareSettings()` | ling | ✅ `recording_page.dart:665-667` (solo catch genérico) | Agregar handler específico — ling único en detectar esto |
| D5 | `SessionIntegrityException` YA capturado en `_verifyIntegrity()` | ling, coenvironment, laguna, ds, hy3 | ✅ `recording_page.dart:191-203` | Mantener como está. Patrón a copiar para D2-D4 |
| D6 | Metrics hardcodeadas "42m" en `RecordingEndPage` | coenvironment | ✅ `recording_end_page.dart:316` | Reemplazar con datos reales de SessionData |
| D7 | `debugPrint` residual en `recording_page.dart` L287, L661, L666 | coenvironment | ✅ `recording_page.dart:287,661,666` | Migrar a LoggerService.log() |
| D8 | `vrm_health_check.dart --fix` solo imprime, no ejecuta cleanup | coenvironment, ds | ✅ `vrm_health_check.dart:120-122` | Implementar cleanup real (temp huérfanos, sesiones huérfanas) |
| D9 | `widget_test.dart` roto (referencia counter inexistente) | coenvironment | ✅ `test/widget_test.dart:14-29` | Eliminar o reemplazar con test válido |
| D10 | Screenshots 1024x1024, resolución store insuficiente | coenvironment | ✅ `assets/store/screenshots/step*.png` | Recapturar en dispositivo real ≥1080x1920 (Android) / ≥1284x2778 (iOS) |
| D11 | `adaptive_icon` no configurado en pubspec.yaml | coenvironment | ✅ `pubspec.yaml` (sin adaptive_icon_background/foreground) | Agregar `adaptive_icon_background: "#FFFFFF"` y `adaptive_icon_foreground` |
| D12 | SnackBar flotante para fallback IA en ScriptStudio | coenvironment | ✅ `script_studio_page.dart:338-361` | Reemplazar con MaterialBanner sticky |
| D13 | `SessionIntegrityException` manejo inconsistente: 3 métodos sin handler vs 1 con | ling | ✅ Verificado contra código real | Los 3 métodos listados en D2-D4 necesitan el mismo patrón que `_verifyIntegrity()` L191-203 |
| D14 | Propuestas DX fragmentadas: 4 agentes → 4 herramientas diferentes | ling, laguna, ds, hy3 | N/A — propuestas competidoras | Fusionar: extender `vrm_health_check.dart` existente con `--fix` real (consenso coenvironment + ds). Descartar scripts nuevos (evitar proliferación) |

---

## 1️⃣ Resumen Ejecutivo

Objetivo: Implementar 8 pasos correctivos (05-12) sobre código existente: catch específico SessionIntegrityException en recording_page.dart (3 métodos), MaterialBanner en ScriptStudio, metrics reales en RecordingEndPage, migrar debugPrint residual a LoggerService, implementar --fix real en vrm_health_check, adaptive icons Android 13, reparar widget_test, y guiar captura de screenshots store-ready.

Correcciones críticas al plan: Plan referencia L535-548 para catch genérico, pero código real usa L539-553 (ds, hy3). Plan asume solo `_startActualRecording()` necesita handler, pero ling verificó que `_stopRecording()` y `_applyHardwareSettings()` también carecen de catch específico.

Decisión DX: Extender `vrm_health_check.dart` existente con subcomando `--fix` que ejecute cleanup real (temp huérfanos + sesiones huérfanas). Descarta crear scripts nuevos (session_integrity_validator, test_integrity_check.dart, SessionIntegrityMonitor como wrapper separado). Consistencia con herramienta DX unificada del proyecto.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path (Paso 05 — SessionIntegrityException)

1. Usuario abre RecordingPage → `initState()` → `_verifyIntegrity()` captura `SessionIntegrityException` con SnackBar naranja + aplica `originalError` (YA IMPLEMENTADO)
2. Usuario inicia grabación → `_startActualRecording()` → `RecordingManager.startRecording()` → `verifySessionIntegrity()` → si clips faltan, lanza `SessionIntegrityException`
3. Handler específico captura → setState idle → SnackBar naranja (NUEVO)
4. Usuario detiene grabación → `_stopRecording()` → mismo patrón de captura (NUEVO)
5. Usuario cambia hardware → `_applyHardwareSettings()` → mismo patrón (NUEVO)
6. Si NO hay `SessionIntegrityException` → flujo normal continúa (catch genérico intacto)

### Happy Path (Pasos 06-12)

7. ScriptStudio muestra MaterialBanner sticky para fallback IA (Paso 06)
8. RecordingEndPage muestra duración real + takes count desde SessionData (Paso 07)
9. LoggerService captura todos los eventos de hardware (Paso 08)
10. vrm_health_check --fix limpia temp y repara sesiones huérfanas (Paso 09)
11. Adaptive icons compatibles Android 13+ (Paso 10)
12. widget_test.dart reparado o eliminado (Paso 11)
13. Screenshots capturadas en dispositivo real a resolución store (Paso 12)

### Edge Cases MVP

- SessionIntegrityException lanzado en _startActualRecording → NO solaparse con SnackBar de _verifyIntegrity()
- SessionIntegrityException lanzado en _stopRecording → estado idle sin datos de grabación reciente
- MetricsRecordingEndPage sin datos de sesión → mostrar "--" en vez de "42m"
- MaterialBanner en pantalla pequeña → scrollview contenido, dismiss direction configurado
- vrm_health_check --fix elimina datos válidos → verificar existencia de proyecto padre antes de eliminar
- MissingPluginException en stopRecording (stitch channel sin handler) → NO enmascarar con SessionIntegrityException

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

#### M1: Catch SessionIntegrityException en `_startActualRecording()`
- **Ruta real:** `lib/features/recording/recording_page.dart`
- **Tipo de cambio:** Modificación
- **Descripción:** Insertar `on SessionIntegrityException catch (e)` entre `CameraHardwareException` (L538) y catch genérico (L539). SnackBar naranja + setState idle + `_sessionData = e.originalError as SessionData?`. NO mostrar SnackBar duplicado (ya mostrado en _verifyIntegrity)
- **Interfaz clave:** `on SessionIntegrityException catch (e) { if (mounted) { setState(() { _recordingState = RecordingState.idle; _isProcessingRecording = false; _sessionData = e.originalError as SessionData?; }); } }`
- **Patrón a seguir:** `recording_page.dart:191-203` (mismo archivo, método `_verifyIntegrity()`)

#### M2: Catch SessionIntegrityException en `_stopRecording()`
- **Ruta real:** `lib/features/recording/recording_page.dart`
- **Tipo de cambio:** Modificación
- **Descripción:** Insertar `on SessionIntegrityException catch (e)` antes de catch genérico L624. Mismo patrón que M1
- **Interfaz clave:** Misma que M1
- **Patrón a seguir:** `recording_page.dart:191-203`

#### M3: Catch SessionIntegrityException en `_applyHardwareSettings()`
- **Ruta real:** `lib/features/recording/recording_page.dart`
- **Tipo de cambio:** Modificación
- **Descripción:** Insertar `on SessionIntegrityException catch (e)` antes de catch genérico L665. Mismo patrón que M1
- **Interfaz clave:** Misma que M1
- **Patrón a seguir:** `recording_page.dart:191-203`

#### M4: MaterialBanner en ScriptStudio fallback IA
- **Ruta real:** `lib/features/assistant/script_studio_page.dart`
- **Tipo de cambio:** Modificación (L338-361)
- **Descripción:** Reemplazar `ScaffoldMessenger.showSnackBar()` con `ScaffoldMessenger.showMaterialBanner()`. Mismo mensaje naranja, mismo comportamiento de cierre. MaterialBanner sticky visible hasta descarte del usuario
- **Interfaz clave:** `ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(content: Text(...), backgroundColor: Colors.orange, actions: [TextButton(child: Text('OK'), onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner())]));`
- **Patrón a seguir:** Documentación Flutter MaterialBanner

#### M5: Metrics reales en RecordingEndPage
- **Ruta real:** `lib/features/recording/recording_end_page.dart`
- **Tipo de cambio:** Modificación (L316, L367)
- **Descripción:** Reemplazar valores hardcodeados "42" con datos reales de SessionData. Calcular duración total desde clips, conteo de takes desde takesPerChunk. Mostrar "--" si no hay datos
- **Interfaz clave:** `SessionData.chunksRecorded`, `SessionData.takesPerChunk`, `ClipMetadata.duration`
- **Patrón a seguir:** `SessionData` model fields ya disponibles en `lib/features/recording/models/session_data.dart`

#### M6: Migrar debugPrint a LoggerService
- **Ruta real:** `lib/features/recording/recording_page.dart`
- **Tipo de cambio:** Modificación (L287, L661, L666)
- **Descripción:** Reemplazar `debugPrint(...)` con `LoggerService.log('RecordingPage', ...)`. 3 llamadas: memory pressure (L287), hardware not supported (L661), error apply settings (L666)
- **Interfaz clave:** `LoggerService.log('RecordingPage', 'message')`
- **Patrón a seguir:** `lib/core/services/logger_service.dart` — singleton ya importado y usado en otros servicios

#### M7: vrm_health_check --fix real
- **Ruta real:** `scripts/vrm_health_check.dart`
- **Tipo de cambio:** Modificación (L120-122)
- **Descripción:** Implementar cleanup real cuando `fix=true`. Eliminar archivos temporales huérfanos en `vrm_data/tmp/`. Resetear sesiones huérfanas sin proyecto padre. Acciones documentadas en output
- **Interfaz clave:** `Future<void> _runCheck(bool fix) { if (fix) { ... cleanup logic ... } }`
- **Patrón a seguir:** `scripts/store_prep_cli.dart` (subcomandos ejecutan acciones reales, no solo print)

#### M8: Adaptive icons Android 13
- **Ruta real:** `pubspec.yaml`
- **Tipo de cambio:** Modificación
- **Descripción:** Agregar `adaptive_icon_background: "#FFFFFF"` y `adaptive_icon_foreground: "assets/images/branding/icon_source.png"` en config flutter_launcher_icons. Regenerar con `flutter pub run flutter_launcher_icons`
- **Interfaz clave:** flutter_launcher_icons config section in pubspec.yaml

#### M9: Reparar widget_test.dart
- **Ruta real:** `test/widget_test.dart`
- **Tipo de cambio:** Modificación / Eliminación
- **Descripción:** Opción A: Eliminar si no cubre funcionalidad real. Opción B: Reemplazar con test que verifique renderizado de pantalla principal
- **Patrón a seguir:** `test/repository_test.dart` (tests reales existentes)

#### M10: Screenshots store-ready
- **Ruta real:** `assets/store/screenshots/`
- **Tipo de cambio:** Manual (captura en dispositivo real)
- **Descripción:** Capturar 5 screenshots en dispositivo real: Dashboard, Creación proyecto/Script, Grabación overlay, Revisión clips, Exportación. Resolución ≥1080x1920 (Android) o ≥1284x2778 (iOS). Transferir a step1.png..step5.png. Verificar con `dart run scripts/store_prep_cli.dart check`
- **Patrón a seguir:** Guía en `dart run scripts/store_prep_cli.dart screenshots`

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: vrm_health_check --fix (extensión)
- **Qué automatiza:** Cleanup de archivos temporales huérfanos y reparación de sesiones huérfanas sin proyecto padre. Reemplaza limpieza manual de vrm_data/tmp/ y detección manual de session_data.json corruptos
- **Tipo:** CLI (extensión de script existente)
- **Ubicación:** scripts/vrm_health_check.dart
- **Cómo se usa:** `dart run scripts/vrm_health_check.dart check --fix`
- **Impacto para el usuario final:** Elimina tarea manual de limpiar archivos temporales y diagnosticar sesiones corruptas. Reduce diagnóstico de 15min a ~2s
- **El implementador DEBE usarla** antes de las tareas 1-10 para verificar estado limpio del sistema
```

> **Fundamento de fusión DX:** 4 agentes propusieron 4 herramientas diferentes (SessionIntegrityMonitor, session_integrity_validator, test_integrity_check.dart, vrm_health_check --fix). Se selecciona vrm_health_check --fix porque: (a) extiende herramienta existente del proyecto, (b) apareció en 2 análisis (coenvironment + ds), (c) sigue patrón store_prep_cli.dart, (d) evita proliferación de scripts. Las otras 3 propuestas se descartan por crear fragmentación.

---

## 4️⃣ Decisiones Tecnológicas

1. **Extender vrm_health_check.dart sobre crear nuevo script:** Existe consenso entre coenvironment y ds. Evita proliferación de 3 scripts nuevos (session_integrity_validator, test_integrity_check, SessionIntegrityMonitor). Sigue patrón de store_prep_cli.dart como herramienta DX unificada.

2. **3 handlers SessionIntegrityException vs 1:** ling detectó que `_stopRecording()` y `_applyHardwareSettings()` también carecen de handler específico. Los otros 3 agentes (laguna, ds, hy3) solo detectaron `_startActualRecording()`. Se implementan los 3 por completitud y consistencia.

3. **Correcciones al plan:**
   - ⚠️ El plan dice L535-548 para generic catch, pero el código real usa L539-553. Se implementa según código real: insertar handler entre L538 y L539.
   - ⚠️ El plan solo menciona `_startActualRecording()` para SessionIntegrityException. El código real tiene 3 métodos con catch genérico que deben actualizarse.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [DATA] SessionIntegrityException existe con message, code, originalError (SessionData corregida)
✅ [DATA] SessionData.approvedClips, chunksRecorded, takesPerChunk disponibles para metrics reales
✅ [CODE] recording_page.dart: _startActualRecording() captura on SessionIntegrityException antes de catch genérico
✅ [CODE] recording_page.dart: _stopRecording() captura on SessionIntegrityException antes de catch genérico
✅ [CODE] recording_page.dart: _applyHardwareSettings() captura on SessionIntegrityException antes de catch genérico
✅ [CODE] SessionIntegrityException handler resetea _recordingState = idle, _isProcessingRecording = false
✅ [CODE] SnackBar NO se duplica (ya mostrado en _verifyIntegrity)
✅ [CODE] Generic catch posterior intacto para otras excepciones
✅ [CODE] MaterialBanner reemplaza SnackBar en script_studio_page.dart:338
✅ [CODE] Metrics reales (duración + takes) conectados a SessionData en recording_end_page.dart
✅ [CODE] 0 debugPrint en recording_page.dart — migrados a LoggerService.log()
✅ [CODE] vrm_health_check.dart --fix ejecuta cleanup real (temp + sesiones huérfanas)
✅ [CODE] adaptive_icon_background/foreground configurado en pubspec.yaml
✅ [CODE] widget_test.dart reparado o eliminado
✅ [FULLSTACK] Flujo verifyIntegrity() → SnackBar naranja → operaciones subsiguientes no fallan por misma excepción
✅ [FULLSTACK] Usuario ve MaterialBanner sticky en fallback IA
✅ [FULLSTACK] Usuario ve metrics reales (no "42m") en RecordingEndPage
✅ [DX] Herramienta vrm_health_check --fix ejecuta sin errores y reduce limpieza manual
✅ [DX] Screenshots store-ready capturadas en dispositivo real (≥1080x1920)
✅ [TEST] flutter test pasa sin regresiones
```

**Funcionales:**
- [ ] SessionIntegrityException capturado con handler dedicado en 3 métodos de recording_page.dart
- [ ] Usuario recibe SnackBar naranja para integridad comprometida (no rojo genérico)
- [ ] MaterialBanner sticky para fallback IA en ScriptStudio
- [ ] RecordingEndPage muestra datos reales de sesión

**Técnicos:**
- [ ] flutter analyze 0 errores
- [ ] LoggerService.log() usado en vez de debugPrint en recording_page.dart
- [ ] vrm_health_check --fix ejecuta cleanup real documentado en output
- [ ] adaptive icons generados correctamente
- [ ] widget_test.dart no rompe suite de tests

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|-------|:-----------:|:-----------:|:------------:|
| 0 | **DX & Tooling:** vrm_health_check --fix real | Media | 1h | Ninguna |
| 1 | Catch SessionIntegrityException en _startActualRecording() | Baja | 0.3h | Tarea 0 |
| 2 | Catch SessionIntegrityException en _stopRecording() | Baja | 0.2h | Tarea 0 |
| 3 | Catch SessionIntegrityException en _applyHardwareSettings() | Baja | 0.2h | Tarea 0 |
| 4 | MaterialBanner fallback IA en ScriptStudio | Baja | 0.5h | Tarea 0 |
| 5 | Metrics reales en RecordingEndPage (SessionData) | Media | 1h | Tarea 0 |
| 6 | Migrar debugPrint → LoggerService (3 llamadas) | Baja | 0.3h | Ninguna |
| 7 | Adaptive icons Android 13 | Baja | 0.5h | Ninguna |
| 8 | Reparar widget_test.dart | Baja | 0.25h | Ninguna |
| 9 | Verificación: flutter analyze + flutter test | Baja | 0.5h | Tareas 1-8 |
| 10 | Screenshots store-ready (dispositivo real) | Manual | 2h (variable) | Tarea 9 |
| **TOTAL** | | | **~6.75h** | |

> [!IMPORTANT]
> **Tarea 0 siempre = DX & Tooling.** Implementador DEBE ejecutar `vrm_health_check.dart check --fix` primero y usarlo durante el resto del paso para verificar estado limpio antes de cada modificación (dogfooding obligatorio).

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|--------|:---------:|-------|------------|
| SnackBar duplicado SessionIntegrityException | Baja | _verifyIntegrity() ya muestra SnackBar, _startActualRecording() podría mostrar otro | En catch específico de _startActualRecording NO mostrar SnackBar (ya mostrado en init). Solo setState idle |
| Estado inconsistente mid-recording | Media | SessionIntegrityException ocurre mientras _recordingState = recording | Resetear _recordingState = idle + _isProcessingRecording = false en catch específico |
| MissingPluginException en stopRecording | Alta | stitcher channel sin handler nativo — excepción diferente a SessionIntegrity | SessionIntegrityException catch no interfiere con MissingPluginException (sigue en catch genérico) |
| MaterialBanner overflow en pantalla pequeña | Baja | Banner sticky ocupa espacio vertical | Usar MaterialBanner con leading widget + dismiss direction + scrollview en contenido subyacente |
| SessionData no disponible en RecordingEndPage | Media | RecordingEndPage no recibe projectId/sessionData | Pasar SessionData como parámetro desde RecordingManager o leer desde ProjectRepository |
| vrm_health_check --fix elimina datos válidos | Alta | Lógica de "huérfano" incorrecta — sesión sin proyecto padre puede ser válida | Verificar que proyecto NO existe en disco ANTES de eliminar. Loggear cada acción. Confirmar con usuario si >5 elementos a eliminar |
| Screenshots requieren dispositivo físico | Media | No se pueden capturar en emulador para resolución store | Guiar implementador con `store_prep_cli.dart screenshots`. Captura manual con adb o herramienta nativa |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|----|------|-------|-----------------|
| TP-1 | SessionIntegrityException en startRecording | Sesión con clip aprobado faltante en disco → iniciar grabación | Handler específico captura → setState idle → SnackBar naranja visible → catch genérico NO se ejecuta |
| TP-2 | SessionIntegrityException en stopRecording | Sesión con clip aprobado faltante → detener grabación | Handler específico captura → estado idle → sin crash |
| TP-3 | Catch genérico sigue funcionando | Lanzar excepción genérica (no-VRM) en startRecording | Catch genérico L539 captura → SnackBar rojo "Error inesperado" |
| TP-4 | MaterialBanner visible en fallback IA | ScriptStudio genera con fallback local | MaterialBanner sticky naranja visible hasta descarte manual |
| TP-5 | Metrics reales en RecordingEndPage | Sesión con 3 chunks grabados, duración total 2m30s | RecordingEndPage muestra "2m 30s" y "3 takes". No muestra "42m" |
| TP-6 | LoggerService captura hardware events | Cambiar flash mode → debugPrint reemplazado | `vrm_data/logs/app.log` contiene "Setting flash mode to ..." |
| TP-7 | vrm_health_check --fix real | Ejecutar `dart run scripts/vrm_health_check.dart check --fix` con temp huérfanos | Temp eliminados, sesiones huérfanas reparadas, output documenta acciones |
| TP-8 | flutter test sin regresiones | `flutter test` | 16/16 o 17/17 tests pasan (dependiendo si widget_test eliminado o reparado) |

Comando para ejecutar tests: `flutter test` / `flutter analyze`

---

## 📊 Métrica de Calidad del FINAL

| Métrica | Cumplimiento |
|:--------|:------------:|
| `proyecto-config.json` leído antes de generar | ✅ 100% |
| Discrepancias consolidadas con resolución | ✅ 14/14 detectadas |
| Correcciones al plan documentadas | ✅ 2 encontradas (offset línea + scope incompleto) |
| Propuesta DX incluida en §3 y Tarea 0 en §6 | ✅ vrm_health_check --fix |
| Criterio DX en §5 | ✅ |
| Secciones completadas | ✅ 9 secciones (0-8) |
| Casos de testing | ✅ 8 casos concretos |
| Tiempo estimado por tarea | ✅ 100% (~6.75h total) |
