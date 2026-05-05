# 📊 Análisis Técnico — Paso 02: Interfaz Reactiva y Refinamiento Local

**Agente:** sf  
**Fecha:** 2026-05-05  
**Paso:** 02-Interfaz-Reactiva  
**Objetivo:** Conectar toggles de hardware (modo calle/fantasma, bloqueo auto-focus) a la librería de cámara, persistir preferencias del teleprompter, y conectar ajustes de cuenta con dashboard.

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `CameraService.setFocusMode()` | grep `camera_service.dart` L134-141 | ✅ | `Future<void> setFocusMode(FocusMode mode)` |
| 2 | `CameraService.setFlashMode()` | grep `camera_service.dart` L122-131 | ✅ | `Future<void> setFlashMode(FlashMode mode)` |
| 3 | `CameraService.setExposureMode()` | grep `camera_service.dart` L144-151 | ✅ | `Future<void> setExposureMode(ExposureMode mode)` |
| 4 | `RecordingPage._applyHardwareSettings()` | `recording_page.dart` L603-628 | ✅ | Aplica flash, focus, exposure |
| 5 | `_isStreetModeActive` en RecordingPage | `recording_page.dart` L62 | ✅ | `bool _isStreetModeActive = false;` |
| 6 | `_isFocusLocked` en RecordingPage | `recording_page.dart` L67 | ✅ | `bool _isFocusLocked = false;` |
| 7 | `_isGhostActive` en RecordingPage | `recording_page.dart` L65 | ✅ | `bool _isGhostActive = false;` |
| 8 | `_teleprompterFontSize` en RecordingPage | `recording_page.dart` L69 | ✅ | `double _teleprompterFontSize = 24.0;` |
| 9 | `_readingSpeed` en RecordingPage | `recording_page.dart` L70 | ✅ | `double _readingSpeed = 150.0;` |
| 10 | `AccountProfilePage` existe | `lib/features/account/` | ✅ | L1-378: UI con Clear All Data funcional |
| 11 | `SettingsPage` existe | `lib/features/settings/` | ✅ | L1-284: UI con toggles no-op |
| 12 | `OnboardingRepository` (SharedPreferences) | `onboarding_repository.dart` | ✅ | Usa `SharedPreferences` para perfil |
| 13 | `ProjectRepository` (JSON persistencia) | `project_repository.dart` | ✅ | JSON filesystem en `vrm_data/` |
| 14 | Telepronter widget | `widgets/telepronter.dart` | ✅ | Necesita recibir `fontSize` y `speed` |

**Discrepancias encontradas:**

| # | Tipo | Descripción | Impacto | Resolución propuesta |
|---|---|---|---|---|
| D1 | ⚠️ | `AccountProfilePage` datos hardcodeados: deviceId="Android Device", memberSince="April 2026" | No muestra info real del dispositivo | Implementar `DeviceInfoService` con `device_info_plus` + lectura de install date |
| D2 | ⚠️ | `SettingsPage` toggles (cloud sync, recording, teleprompter) son no-op | Settings no persisten ni aplican | Crear `SettingsService` con `SharedPreferences` y conectar cada toggle |
| D3 | ⚠️ | `InfluencerProfilePage` datos no persisten (L631 solo `Navigator.pop()`) | Perfil se pierde al cerrar | Persistir en `SharedPreferences` o `user_profile.json` |
| D4 | ❌ | Teleprompter settings (fontSize, speed) no se pasan como props al widget `Telepronter` | Cambios en sliders no afectan visualización | Pasar `_teleprompterFontSize` y `_readingSpeed` como parámetros obligatorios |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema existente

Paso 2 no modifica schema de base de datos. Persistencia local suficiente:

- **`SharedPreferences`** — Usado por `OnboardingRepository` para `UserProfile`.
- **JSON filesystem** — `ProjectRepository` escribe en `vrm_data/projects/{id}/project.json`.
- **SessionData** — `session_data.json` por proyecto.

### Integridad referencial

- ✅ `ProjectState` → `SessionData` relación 1:1 por `projectId`.
- ✅ Clips almacenados en `vrm_data/projects/{id}/clips/`.

### RLS policies

No aplica — MVP 100% offline, sin autenticación.

### Tipos de datos

- Preferencias teleprompter: `double fontSize` (20-30 PT), `double readingSpeed` (50-300 PPM), `double screenBrightness` (0.1-1.0).
- Toggles hardware: `bool` (street, ghost, focus, light, mirror, monitor).
- Device info: strings (model, brand, id, version).

---

## 2️⃣ Análisis de Código (ETAPA 2)

### CameraService — métodos existentes (sin cambios)

```dart
class CameraService {
  Future<void> initialize({CameraLensDirection? direction});
  Future<void> startRecording();
  Future<XFile> stopRecording();
  Future<void> switchCamera();
  Future<void> setFlashMode(FlashMode mode);
  Future<void> setFocusMode(FocusMode mode);
  Future<void> setExposureMode(ExposureMode mode);
  Future<void> dispose();
}
```

**Patrón:** Singleton stateful, inyectado en `RecordingPage`.  
**Referencia:** `lib/features/recording/services/camera_service.dart`.

### `_applyHardwareSettings()` — implementación verificada

**Ubicación:** `lib/features/recording/recording_page.dart:603-628`

```dart
Future<void> _applyHardwareSettings() async {
  if (!_isCameraInitialized) return;
  await _cameraService.setFlashMode(
    _isLightActive ? FlashMode.torch : FlashMode.off,
  );
  if (_isStreetModeActive) {
    await _cameraService.setExposureMode(ExposureMode.locked);
    await _cameraService.setFocusMode(FocusMode.locked);
  } else {
    await _cameraService.setFocusMode(
      _isFocusLocked ? FocusMode.locked : FocusMode.auto,
    );
    await _cameraService.setExposureMode(ExposureMode.auto);
  }
}
```

**Correcto:** Toggles ya aplican parámetros a la cámara en tiempo real via `CameraService`.

### Telepronter widget — verificar interfaz

```dart
Telepronter(
  scriptChunks: chunks,
  fontSize: 24.0,        // DEBERÍA venir de _teleprompterFontSize
  readingSpeed: 150.0,   // DEBERÍA venir de _readingSpeed
  ...
)
```

**Patrón a seguir:** Props explícitas. El widget NO debe leer variables globales de `RecordingPage`.

### AccountProfilePage — datos estáticos

```dart
// L125: hardcodeado
value: 'Android Device',
// L132: hardcodeado
value: 'April 2026',
```

**Debería:** `DeviceInfoService.getDeviceId()` y `ProjectRepository.getCreationDate()`.

### SettingsPage — toggles no-op

```dart
// L98-103: Switch con onChanged vacío
trailing: Switch(value: false, onChanged: (value) {}),
```

**Debería:** `SettingsService.toggleCloudSync(value)` + persistencia.

### Modularidad

- ✅ `CameraService` aísla hardware (alta cohesión, bajo acoplamiento).
- ✅ `RecordingPage` orquesta estado y llama a `_applyHardwareSettings()`.
- ⚠️ Falta `SettingsService` y `DeviceInfoService` para separación de concerns.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

No aplica — Paso 2 es 100% frontend/local.

- Sin endpoints nuevos.
- Sin contratos de API.
- Persistencia: `SharedPreferences` + JSON filesystem.
- Backend IA (FastAPI) no se toca.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
1. Usuario ajusta sliders teleprompter (font, speed, brightness)
   → setState local → Telepronter widget recibe props → actualiza scroll

2. Usuario activa "Modo Calle"
   → setState(_isStreetModeActive=true) → _applyHardwareSettings()
   → CameraService.setExposureMode(locked) + setFocusMode(locked)

3. Usuario activa "Bloqueo Enfoque"
   → setState(_isFocusLocked=true) → _applyHardwareSettings()
   → CameraService.setFocusMode(locked)

4. Usuario cambia Settings (ej: cloud sync)
   → SettingsService.save() → persistencia → reinicio app aplica

5. Usuario ve Cuenta
   → AccountProfilePage.loadDeviceInfo() → DeviceInfoService → muestra datos reales
```

### Gaps detectados

| Gap | Fase afectada | Descripción |
|---|---|---|
| Teleprompter no recibe `fontSize`/`speed` | FULLSTACK | Sliders cambian state pero widget no los consume |
| Settings toggles sin persistencia | FULLSTACK | Cambios se pierden al cerrar app |
| AccountProfile data estática | FULLSTACK | No refleja dispositivo real |
| InfluencerProfile sin guardar | FULLSTACK | Datos ingresados se pierden |

### DX & Tooling — OBLIGATORIO

```
### Herramienta Propuesta: validador-hardware
- **Qué automatiza:** Verifica que la cámara responda a focus, flash, exposure settings en dispositivo físico (no emulator). Reporta compatibilidad hardware.
- **Tipo:** script Dart (CLI) + Flutter integration test
- **Cómo se usa:** `dart run scripts/validador-hardware.dart --device-id=<id>` o `flutter test integration/test/hardware_validation_test.dart`
- **Impacto para el usuario final:** Evita que el usuario final descubra tarde que su dispositivo no soporta某个功能 (ej. focus lock). Detecta problemas antes de release.
- **Prioridad:** Tarea 0 — se ejecuta antes de tocar settings
```

**Implementación:**
- `scripts/validador-hardware.dart` -> `CameraConfig.testFocusMode()`, `testFlashMode()`, `testExposureMode()`.
- Report: JSON con `{device: "...", focusSupported: true/false, flashSupported: true/false, exposureSupported: true/false}`.

### Coherencia arquitectónica

- Patrón Service (CameraService) se replica correctamente → `SettingsService`, `DeviceInfoService`.
- Persistencia via `SharedPreferences` ya establecido por `OnboardingRepository`.
- UI/UX: Toggles existen, solo falta cableado a estado persistente.

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] Persistencia SharedPreferences operativa (OnboardingRepository)
✅ [CODE] CameraService.setFocusMode(torch/locked/auto) sin errores
✅ [CODE] _applyHardwareSettings() llama correctamente a CameraService
✅ [BACKEND] No aplica
✅ [FULLSTACK] Telepronter actualiza fontSize y readingSpeed en tiempo real
✅ [FULLSTACK] Modo Calle/Bloqueo Enfoque/Luz cambian parámetros de cámara
✅ [FULLSTACK] SettingsPage toggles guardan/leen de SharedPreferences
✅ [FULLSTACK] AccountProfilePage muestra deviceId y memberSince reales
✅ [FULLSTACK] InfluencerProfilePage persiste datos al finalizar
✅ [DX] validador-hardware.dart ejecuta y reporta compatibilidad hardware
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `setFocusMode(FocusMode.locked)` no soportado en dispositivos low-end | Media | Hardware limitado | `CameraService` ya tiene try/catch silencioso + fallback a `FocusMode.auto` |
| `setExposureMode(ExposureMode.locked)` no disponible en some Android ROMs | Media | Custom ROMs omiten ExposureMode | Probar en dispositivos físicos 다양; validator detecta |
| `device_info_plus` no añadido a `pubspec.yaml` | Alta | Nueva dependencia necesaria | Agregar `device_info_plus: ^10.0.0` antes de implementar `DeviceInfoService` |
| Persistencia de_settings sin migrate | Media | Versionado de preferencias | Usar `SharedPreferences` keys con version prefix `v2_` |
| InfluencerProfile guarda en `SharedPreferences` limita tamaño | Baja | JSON de perfil puede crecer | Usar `vrm_data/user_profile.json` si supera 10KB |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX Tooling:** validador-hardware | `scripts/validador-hardware.dart` | `Future<void> main(List<String> args)` | — | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/validador-hardware.dart` retorna JSON sin error |
| 1 | Pasar fontSize a Telepronter | `recording_page.dart` (~L150-200) | `Telepronter(fontSize: _teleprompterFontSize, readingSpeed: _readingSpeed)` | `Telepronter` widget existente | CODE | Baja | 0.25h | Tarea 0 | → verificar: slider tamaño texto afecta UI |
| 2 | Crear SettingsService | `lib/features/settings/services/settings_service.dart` | `class SettingsService { Future<void> setBool(String key, bool v); Future<bool> getBool(String key); }` | `OnboardingRepository` (SharedPreferences) | CODE | Media | 0.5h | Ninguna | → verificar: `settings_service_test.dart` cubre get/set |
| 3 | Conectar toggles Settings a SettingsService | `settings_page.dart` | `onChanged: (v) => _settingsService.setBool('cloud_sync', v)` + `initState()` carga estado | `settings_service.dart` | CODE | Media | 0.5h | Tarea 2 | → verificar: toggle Cloud Sync persiste tras reinicio |
| 4 | Persistir toggles Recording (font, speed, brightness) | `recording_page.dart` | `_saveTeleprompterSettings()` llama `SettingsService` al cambiar sliders | `settings_service.dart` | CODE | Baja | 0.25h | Tarea 2 | → verificar: valores persisten al reabrir recording |
| 5 | Implementar DeviceInfoService | `lib/features/account/services/device_info_service.dart` | `Future<DeviceInfo> getDeviceInfo()` donde `DeviceInfo { model, brand, id, installDate }` | `device_info_plus` + `path_provider` para install date | CODE | Media | 0.5h | Agregar dependencia `device_info_plus` | → verificar: `DeviceInfo` retorna datos no-nulos en físico |
| 6 | Conectar AccountProfilePage a DeviceInfoService | `account_profile_page.dart` | `_loadDeviceInfo()` en `initState()` → `_deviceId = info.id` | `device_info_service.dart` | CODE | Baja | 0.25h | Tarea 5 | → verificar: Device ID displays real value |
| 7 | Persistir InfluencerProfile | `influencer_profile_page.dart` | `_saveProfile()` → `SharedPreferences.setString('influencer_profile', json)` | `onboarding_repository.dart` | CODE | Media | 0.5h | Ninguna | → verificar: perfil survives app restart |

**Tiempo total estimado:** 3.25 horas

**Nota:** Tarea 0 (validador-hardware) se ejecuta PRIMERO y valida compatibilidad antes de tocar settings.

---

## 📌 Notas de Implementación

1. **Telepronter widget:** Ya recibiría `fontSize` y `readingSpeed` como parámetros final. Verificar que el widget los use en `build()` para `TextStyle` y `ScrollController`.

2. **SharedPreferences:** Ya declarado en `pubspec.yaml`. Keys sugeridas:
   - `settings_cloud_sync` (bool)
   - `settings_teleprompter_fontSize` (double)
   - `settings_teleprompter_speed` (double)
   - `settings_teleprompter_brightness` (double)
   - `influencer_profile` (String JSON)

3. **Device ID:** Agregar `device_info_plus: ^10.0.0` a `dependencies`. `DeviceInfoService` debe detectar platform (Android/iOS) y obtener `androidId` / `identifierForVendor`.

4. **Migrations:** No hay cambios en migraciones DB (no SQL). Solo agregar `device_info_plus` y correr `flutter pub get`.

5. **Phase-state.md:** Actualizar sección "Mi Cuenta & Opciones" de ⚠️ 80% a ✅ 100% una vez finalizado.

---

## 🗺️ Roadmap (NO implementar ahora)

- **Optimización:** Caching de DeviceInfo en memoria para no recalcular.
- **V2:** Sincronización cloud de settings via backend (ahora solo local).
- **Mejora UX:** Reset a valores por defecto desde Settings page.
- **Pre-requisito Paso 3:** Validar que todos los settings se aplican correctamente antes de fase de estabilidad.

---

## 🔮 Reglas de Oro (revisión final)

- ✅ Análisis accionable y específico
- ✅ Todo verificado contra código real (14 elementos verificados)
- ✅ Discrepancias claras (D1-D4)
- ✅ 4 etapas cubiertas (data, code, backend, fullstack+DX)
- ✅ ≥1 herramienta DX propuesta (validador-hardware)
- ✅ Tareas atómicas: cada tarea modifica UN solo artefacto con interfaz exacta
- ✅ Patrones explícitos (OnboardingRepository, CameraService)
- ✅ Implementador no decide nada: todas las interfaces están dadas

---
