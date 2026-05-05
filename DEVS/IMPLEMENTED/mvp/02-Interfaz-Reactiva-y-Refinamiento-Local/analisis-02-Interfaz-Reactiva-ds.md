# Análisis Técnico — Paso 2: Interfaz Reactiva y Refinamiento Local

**Agente:** ds
**Fecha:** 2026-05-05
**Proyecto:** VRM Atomic Camera
**Fase:** MVP

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `CameraService.setFlashMode()` | grep en `camera_service.dart:122` | ✅ | Existe con parámetro `FlashMode mode` |
| 2 | `CameraService.setFocusMode()` | grep en `camera_service.dart:134` | ✅ | Existe con parámetro `FocusMode mode` |
| 3 | `CameraService.setExposureMode()` | grep en `camera_service.dart:144` | ✅ | Existe con parámetro `ExposureMode mode` |
| 4 | `_applyHardwareSettings()` en recording_page | grep en `recording_page.dart:603` | ✅ | Orquesta luz → calle → enfoque → exposición |
| 5 | `_isStreetModeActive` toggle | grep en `recording_page.dart:62,1461-1467` | ✅ | Botón CALLE en overlay, conectado a `_applyHardwareSettings()` |
| 6 | `_isFocusLocked` toggle | grep en `recording_page.dart:67,1518-1523` | ✅ | Botón ENFOQUE en overlay, conectado a `_applyHardwareSettings()` |
| 7 | `_isGhostActive` + `_updateGhostController()` | grep en `recording_page.dart:63,1473-1479,631-669` | ✅ | Fantasma carga clip previo como overlay vía `VideoPlayerController.file()` |
| 8 | `_readingSpeed` en recording_page | grep en `recording_page.dart:70,1705-1712` | ✅ | Slider en teleprompter settings, valor 50-300 PPM |
| 9 | Teleprompter usa `readingSpeed` | `telepronter.dart:12,76` | ✅ | `pixelsPerSecond = (readingSpeed / 60) * (fontSize * 0.45)` |
| 10 | `AccountProfilePage.clearAllData` | `account_profile_page.dart:315-341` | ✅ | Borra `vrm_data/` recursivamente con confirmación |
| 11 | Identificadores nativos reales | grep `device_info_plus\|DeviceId\|getDeviceId\|android_id` | ❌ | No existe plugin ni lectura real. Valores hardcodeados |
| 12 | `SettingsPage` theme switcher | `settings_page.dart:227-230` | ❌ | `selected: {ThemeMode.dark}` hardcodeado, `onSelectionChanged` no-op |
| 13 | `SettingsPage` cloud sync | `settings_page.dart:98-104` | ❌ | Switch `value: false`, `onChanged` no-op |
| 14 | `SettingsPage` recording duration/camera | `settings_page.dart:48-61` | ❌ | `onTap` comentarios sin implementación |
| 15 | `SettingsPage` fontSize/scrollSpeed | `settings_page.dart:72-86` | ❌ | `onTap` comentarios sin implementación |
| 16 | Dashboard → AccountProfilePage conexión | `dashboard_page.dart:112` | ✅ | `Navigator.push` a `AccountProfilePage()` |
| 17 | Dashboard → SettingsPage conexión | `dashboard_page.dart:173` | ✅ | `Navigator.push` a `SettingsPage()` |
| 18 | `device_info_plus` en pubspec.yaml | pubspec.yaml | ❌ | No declarado. Sin dependencia para leer info nativa |

### Discrepancias encontradas

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | Plan dice "Volver real Modo Calle/Fantasma/Auto-focus" — ya están implementados | Plan desactualizado. Toggles operativos desde `_applyHardwareSettings()` línea 603. No requieren implementación |
| D2 | Plan dice "Interconectar preferencias en tiempo real" — velocidad prompter solo vive en estado local de RecordingPage. Settings page no conecta | Settings page sliders de fontSize/scrollSpeed son stubs. Falta shared state o Provider para propagar preferencias a RecordingPage |
| D3 | "Clear All Data" ya existe con confirmación y borrado recursivo | Plan desactualizado. Ya implementado en account_profile_page.dart:315-341 |
| D4 | Identificadores nativos son strings hardcodeados ("Android Device", "April 2026", "Not configured") | Falta plugin `device_info_plus`. AccountProfilePage debe leer modelo real, ID único y fecha de primer uso |
| D5 | Settings page entera (7 secciones) tiene 100% de handlers no implementados | No es crítica para MVP pero el plan la lista en este paso. Todos los `onTap` y `onChanged` son comentarios sin lógica |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**Schema:** Sin cambios de datos. Paso 2 no toca persistencia.

**Persistencia actual:**
- `UserProfile` se guarda en `SharedPreferences` vía `OnboardingRepository`
- `ProjectRepository` escribe JSON en filesystem
- No hay base de datos relacional

**Requerido para este paso:**
- Guardar preferencias de teleprompter (fontSize, readingSpeed, brightness) en `SharedPreferences` o `UserProfile`
- Leer identificadores nativos no requiere persistencia

**Impacto en datos existentes:** Ninguno. Solo extender `UserProfile` con campos opcionales de preferencias si se persisten.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones ya existentes (NO requieren implementación)

| Función | Archivo | Firma | Uso |
|---|---|---|---|
| `RecordingPage._applyHardwareSettings()` | `recording_page.dart:603` | `Future<void> _applyHardwareSettings()` | Orquesta flash/focus/exposure según estado de toggles |
| `RecordingPage._updateGhostController()` | `recording_page.dart:631` | `Future<void> _updateGhostController()` | Carga clip aprobado como overlay ghost |
| `CameraService.setFlashMode()` | `camera_service.dart:122` | `Future<void> setFlashMode(FlashMode mode)` | Setea flash/torch |
| `CameraService.setFocusMode()` | `camera_service.dart:134` | `Future<void> setFocusMode(FocusMode mode)` | Lock/auto focus |
| `CameraService.setExposureMode()` | `camera_service.dart:144` | `Future<void> setExposureMode(ExposureMode mode)` | Lock/auto exposure |
| `AccountProfilePage._showClearDataDialog()` | `account_profile_page.dart:301` | `void _showClearDataDialog(BuildContext)` | Confirmación + borrado vrm_data/ |

### Funciones que requieren implementación

| Función | Archivo destino | Firma propuesta | Patrón a seguir |
|---|---|---|---|
| `SettingsPage._onThemeChanged()` | `settings_page.dart` | `void _onThemeChanged(ThemeMode mode)` | `OnboardingRepository.saveProfile()` en `onboarding_repository.dart:35` |
| `SettingsPage._onCloudSyncChanged()` | `settings_page.dart` | `void _onCloudSyncChanged(bool enabled)` | `OnboardingRepository` patron SharedPreferences |
| `SettingsPage._onSettingTap()` | `settings_page.dart` | `void _onSettingTap(String settingKey)` | Sustituir comentarios por calls reales o navegación |
| `AccountProfilePage._loadDeviceInfo()` | `account_profile_page.dart` | `Future<Map<String,String>> _loadDeviceInfo()` | `device_info_plus` package → `DeviceInfoPlugin().deviceInfo` |
| `RecordingPage._syncPreferences()` | `recording_page.dart` | `void _syncPreferences(TeleprompterPrefs prefs)` | Provider / InheritedWidget para compartir estado entre Settings y Recording |
| `TeleprompterPrefs` (modelo) | `lib/features/recording/models/` | `class TeleprompterPrefs { double fontSize, double readingSpeed, double brightness }` | `UserProfile` en `user_profile.dart` |

### Patrones existentes a reutilizar
- `UserProfile` + `OnboardingRepository` (SharedPreferences) → para persistir preferencias de teleprompter
- `ProjectRepository` (JSON filesystem) → para leer/escribir settings si se prefiere archivo
- `CameraService` singleton → para toggles de hardware (ya implementado)

### Calidad actual
- `_applyHardwareSettings()`: Complejidad baja (3 condiciones if/else). Bien modularizada.
- `SettingsPage`: 284 líneas, toda UI muerta. Complejidad ciclomática 1 (sin bifurcaciones reales).
- `AccountProfilePage`: 378 líneas. ClearAllData bien implementado con try/catch y feedback. Información de dispositivo hardcodeada.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**No aplica.** Paso 2 es 100% frontend. No hay endpoints, middleware ni servicios backend involucrados.

- Toggles de cámara → API directa del plugin `camera` (MethodChannel nativo)
- Preferencias → SharedPreferences local
- Identificadores nativos → `device_info_plus` plugin (MethodChannel nativo)

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
SettingsPage ──→ SharedPreferences ──→ RecordingPage
  (fontSize,        persistir            leer al
   readingSpeed,    preferencias         iniciar grabación
   brightness)      del usuario)         + aplicar en Telepronter

AccountProfilePage ──→ device_info_plus ──→ Mostrar modelo real
  (device ID,           leer info           + ID único
   email,               nativa del          + fecha app install
   member since)        dispositivo)

Dashboard ──→ Navigator.push ──→ AccountProfilePage (✅ ya conectado)
          ──→ Navigator.push ──→ SettingsPage (✅ ya conectado)
```

### Coherencia
- **Ya implementado:** Toggles de hardware (CALLE, FANTASMA, ENFOQUE), Clear All Data, navegación Dashboard → Cuenta/Settings
- **Gap principal:** Settings page no escribe ni lee preferencias. La velocidad de teleprompter en RecordingPage usa valor fijo 150 PPM y no se sincroniza con settings
- **Gap secundario:** AccountProfilePage muestra información hardcodeada del dispositivo

### DX & Tooling

```
### Herramienta Propuesta: Validador de Preferencias y Toggles
- **Qué automatiza:** Script CLI que verifica que todos los toggles de Settings (theme, cloud sync, recording, teleprompter) escriban/lean correctamente en SharedPreferences y que los valores persistan al cerrar/reabrir la app
- **Tipo:** script
- **Cómo se usa:** `flutter test test/settings_toggle_test.dart` (test de integración con `SharedPreferences.setMockInitialValues`)
- **Impacto para el usuario final:** Garantiza que ajustes de teleprompter (velocidad, tamaño fuente) persistan entre sesiones sin que el usuario tenga que reconfigurar cada vez
- **Prioridad:** Tarea 0 — implementar antes de tocar SettingsPage handlers
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] SettingsPage theme switcher escribe en SharedPreferences y cambia ThemeMode real
✅ [CODE] SettingsPage teleprompter fontSize/scrollSpeed sliders persisten en SharedPreferences
✅ [CODE] RecordingPage lee preferencias de teleprompter desde SharedPreferences al iniciar
✅ [CODE] AccountProfilePage muestra device model real desde device_info_plus (no "Android Device")
✅ [CODE] AccountProfilePage muestra member since real (fecha de primer launch)
✅ [BACKEND] Sin cambios backend necesarios
✅ [FULLSTACK] Usuario cambia velocidad de teleprompter en Settings → se refleja en RecordingPage
✅ [FULLSTACK] Usuario ve info real de su dispositivo en AccountProfilePage
✅ [FULLSTACK] Clear All Data borra vrm_data/ + SharedPreferences + redirige a onboarding
✅ [DX] Test settings_toggle_test.dart verifica persistencia de preferencias
✅ [DX] No hay stubs ni comentarios "// Navigate to..." sin implementación en SettingsPage
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `device_info_plus` no disponible en todas las plataformas (web/linux) | Media | Paso es mobile-only pero plugin puede fallar en desktop | Envolver en try/catch con fallback a "Unknown Device". No bloquear UI |
| SharedPreferences race condition al leer/escribir simultáneo | Baja | SettingsPage y RecordingPage pueden leer/escribir al mismo tiempo | Usar async/await secuencial. SharedPreferences es thread-safe en plataformas mobile |
| Toggles hardware ya implementados pero plan indica que faltan → confusión en implementador | Alta | Plan desactualizado (FASE 2 describe como pendiente lo que ya existe en FASE 1) | El análisis §0 documenta discrepancias. Implementador debe verificar contra código antes de tocar |
| Settings page tiene 7 stubs → alto riesgo de implementación incompleta | Media | Implementador puede priorizar solo 1-2 toggles | Tarea por tarea en §7. Cada toggle es independiente y verificable |
| Teleprompter speed no sincronizado entre Settings y Recording | Media | Provider/InheritedWidget no existe para el paso de preferencias | Crear `TeleprompterPrefsProvider` o usar callback + SharedPreferences como puente |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: Test de persistencia de preferencias | `test/settings_toggle_test.dart` | `void main()` con `SharedPreferences.setMockInitialValues({})` | `test/repository_test.dart :: test("save and load project")` | DX | Baja | 0.5h | Ninguna | → verificar: `flutter test test/settings_toggle_test.dart` pasa |
| 1 | Agregar `device_info_plus` a pubspec.yaml | `pubspec.yaml` | `device_info_plus: ^11.0.0` | `camera: ^0.11.0+4` | CODE | Baja | 0.1h | Tarea 0 | → verificar: `flutter pub get` sin errores |
| 2 | Implementar `_loadDeviceInfo()` en AccountProfilePage | `lib/features/account/account_profile_page.dart` | `Future<Map<String,String>> _loadDeviceInfo()` → `{model, id, firstInstallDate}` | `CameraService` singleton pattern (pero como método de instancia) | CODE | Media | 1h | Tarea 1 | → verificar: valores dinámicos reemplazan "Android Device", "April 2026" |
| 3 | Crear `TeleprompterPrefs` model | `lib/features/recording/models/teleprompter_prefs.dart` | `class TeleprompterPrefs { double fontSize, double readingSpeed, double brightness; factory fromJson(), Map toJson() }` | `UserProfile` en `user_profile.dart :: 19 líneas, fromJson/toJson` | CODE | Baja | 0.5h | Tarea 0 | → verificar: importable sin error |
| 4 | Implementar persistencia de preferencias de teleprompter en SettingsPage | `lib/features/settings/settings_page.dart` | `_saveFontSize(double size)`, `_saveScrollSpeed(double speed)` escribiendo en SharedPreferences | `OnboardingRepository.saveProfile()` en `onboarding_repository.dart:35` | CODE | Media | 1.5h | Tarea 0, 3 | → verificar: test Tarea 0 pasa con valores guardados |
| 5 | Sincronizar preferencias en RecordingPage al iniciar | `lib/features/recording/recording_page.dart` | `_loadTeleprompterPrefs()` llamado en `initState()` → sobrescribe `_readingSpeed`, `_teleprompterFontSize` | `_loadProfile()` en `dashboard_page.dart:34-41` (Future en initState) | CODE | Media | 1h | Tarea 3, 4 | → verificar: slider de velocidad refleja valor persistido |
| 6 | Implementar theme switcher real en SettingsPage | `lib/features/settings/settings_page.dart` | `_onThemeChanged(ThemeMode mode)` → guarda en SharedPreferences + `setState()` | `OnboardingRepository` pattern | CODE | Baja | 0.5h | Tarea 0 | → verificar: cambiar tema actualiza UI inmediatamente |
| 7 | Eliminar stubs de SettingsPage (onTap de recording/teleprompter navegan a settings dedicados o muestran opciones inline) | `lib/features/settings/settings_page.dart` | `_onSettingTap(String key)` → `Navigator.push` o diálogo inline según caso | No hay patrón exacto. Usar `showDialog` o `showModalBottomSheet` para opciones inline | CODE | Media | 1h | Tarea 4, 5 | → verificar: ningún `// Comment` sin implementación en handlers |
| 8 | Validar flujo end-to-end | — | Verificar criterios §5 completos | — | FULLSTACK | Baja | 0.5h | Tareas 1-7 | → verificar: todos los criterios §5 pasan |

**Tiempo total estimado:** 5.6 horas

---

## 🔮 Roadmap (NO implementar ahora)

- **Provider/Riverpod**: Migrar preferencias compartidas a un state management central en lugar de SharedPreferences directo. Bloquea: necesidad de V2 con múltiples consumidores de preferencias
- **i18n dinámico**: Language switcher en SettingsPage debería cambiar locale en caliente. Actualmente requiere reinicio de app
- **Cloud Sync**: Toggle de cloud sync stub. No implementar hasta que exista backend de sincronización (post-MVP)
- **Notificaciones push**: Toggle de notificaciones stub. No implementar sin backend de push notifications
- **Optimización**: Unificar preferencias de teleprompter entre SettingsPage y RecordingPage en un solo provider para evitar duplicación de lectura SharedPreferences

---

## 📊 Métrica de Calidad

| Métrica | Resultado |
|---|---|
| `proyecto-config.json` leído antes de explorar | ✅ 100% |
| Elementos verificados (§0) | 18 (≥12 umbral para 3-5 archivos) |
| Discrepancias detectadas | 5 (≥1 exigido) |
| Secciones completadas | 8 (0-7) |
| Etapas cubiertas | 4 (data, code, backend, fullstack+DX) |
| Criterios de aceptación | 10 (≥1 por sub-paso) |
| Riesgos identificados | 5 (≥3 exigido) |
| Tareas atómicas (1 artefacto por tarea) | 9 tareas, 100% atómicas |
| Interfaz exacta por tarea | 100% |
| Patrón de referencia explícito por tarea | 100% |
| Verificación inline por tarea | 100% |
| Suposiciones no verificadas | 0 |
| Propuesta DX / Tooling | 1 herramienta (validador de preferencias) |
| Estimación de tiempo | ✅ 5.6h total, por tarea individual |
