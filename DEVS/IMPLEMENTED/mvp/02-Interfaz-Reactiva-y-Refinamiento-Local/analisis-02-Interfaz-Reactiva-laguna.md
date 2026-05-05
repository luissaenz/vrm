# 📊 Análisis Técnico — Paso 02: Interfaz Reactiva y Refinamiento Local

**Agente:** laguna  
**Fecha:** 2026-05-05  
**Paso:** 02-Interfaz-Reactiva  
**Objetivo:** Conectar toggles de hardware (modo calle/fantasma, bloqueo auto-focus) a la librería de cámara y las preferencias del teleprompter. Implementar datos reales de cuenta de usuario.

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `CameraService.setFocusMode()` existe | grep en `lib/features/recording/services/camera_service.dart` | ✅ | L134-141: `Future<void> setFocusMode(FocusMode mode)` |
| 2 | `CameraService.setFlashMode()` existe | grep en `camera_service.dart` | ✅ | L122-131: `Future<void> setFlashMode(FlashMode mode)` |
| 3 | `CameraService.setExposureMode()` existe | grep en `camera_service.dart` | ✅ | L144-151: `Future<void> setExposureMode(ExposureMode mode)` |
| 4 | `CameraService.switchCamera()` existe | grep en `camera_service.dart` | ✅ | L108-119: `Future<void> switchCamera()` |
| 5 | `RecordingPage._applyHardwareSettings()` existe | grep en `recording_page.dart` | ✅ | L603-628: Aplica settings a cámara |
| 6 | `AccountProfilePage` existe | grep en `lib/features/account/` | ✅ | L1-378: UI completa con toggles |
| 7 | `SettingsPage` existe | grep en `lib/features/settings/` | ✅ | L1-284: UI completa |
| 8 | `InfluencerProfilePage` existe | grep en `lib/features/influencer_profile/` | ✅ | L1-631: Formulario 3-pasos |
| 9 | `_isStreetModeActive` variable existe | grep en `recording_page.dart` | ✅ | L62: `bool _isStreetModeActive = false;` |
| 10 | `_isFocusLocked` variable existe | grep en `recording_page.dart` | ✅ | L67: `bool _isFocusLocked = false;` |
| 11 | `_isGhostActive` variable existe | grep en `recording_page.dart` | ✅ | L65: `bool _isGhostActive = false;` |
| 12 | `_isLightActive` variable existe | grep en `recording_page.dart` | ✅ | L64: `bool _isLightActive = false;` |
| 13 | `_teleprompterFontSize` variable existe | grep en `recording_page.dart` | ✅ | L69: `double _teleprompterFontSize = 24.0;` |
| 14 | `_readingSpeed` variable existe | grep en `recording_page.dart` | ✅ | L70: `double _readingSpeed = 150.0;` |
| 15 | `_buildHardwareSettings()` aplica toggles | grep en `recording_page.dart` L603-628 | ✅ | Líneas 607-624 aplican settings |

**Discrepancias encontradas:**

| # | Tipo | Descripción | Impacto | Resolución propuesta |
|---|---|---|---|---|
| D1 | ⚠️ | `AccountProfilePage` muestra datos hardcodeados ("Android Device", "April 2026") | Los datos de dispositivo no son dinámicos | Implementar lectura real de `deviceId` y `memberSince` desde `ProjectRepository` |
| D2 | ⚠️ | `SettingsPage` toggles (nube, grabación, teleprompter) son no-op | Settings no persisten | Conectar toggles a `SharedPreferences` y aplicar cambios reales |
| D3 | ⚠️ | `InfluencerProfilePage` datos no persisten al finalizar | Perfil se pierde al cerrar | Guardar datos en `SharedPreferences` o `vrm_data/user_profile.json` |
| D4 | ❌ | `Telepronter` widget usa variables hardcodeadas | Velocidad y tamaño texto no responden a settings | Verificar que `Telepronter` reciba parámetros dinámicos |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema existente

**No aplica — Paso 2 no introduce cambios en schema de base de datos.**

- El paso 2 se enfoca en UI toggles y conexión de hardware, no en estructura de datos.
- Persistencia existente (`ProjectRepository`, `SharedPreferences`) es suficiente.

### Verificación de integridad

- ✅ `vrm_data` estructura existe (phase-state.md L96-103)
- ✅ `project.json`, `session_data.json`, `clips/` funcionales
- ✅ `SharedPreferences` usado para `UserProfile` (onboarding)

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones/clases modificadas o creadas

#### `CameraService` (existente, se usan métodos existentes)

**Ubicación:** `lib/features/recording/services/camera_service.dart`

**Firmas verificadas:**

```dart
class CameraService {
  Future<void> initialize({CameraLensDirection? direction})
  Future<void> startRecording()
  Future<XFile> stopRecording()
  Future<void> switchCamera()
  Future<void> setFlashMode(FlashMode mode)
  Future<void> setFocusMode(FocusMode mode)
  Future<void> setExposureMode(ExposureMode mode)
  Future<void> dispose()
}
```

**Patrón seguido:** Singleton stateful service, inyectado en `RecordingPage`.

#### `_applyHardwareSettings()` en `RecordingPage`

**Ubicación:** `lib/features/recording/recording_page.dart:603-628`

**Implementación verificada:**

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

**Referencia patrón:** `lib/features/recording/services/camera_service.dart:122-151`

### Análisis de modularidad

- ✅ `CameraService` aísla hardware de UI — cohesión alta, acoplamiento bajo
- ✅ `_applyHardwareSettings()` separado, llamado desde múltiples puntos
- ✅ `_isStreetModeActive`, `_isFocusLocked`, `_isLightActive` son state management local

### Imports verificados

```dart
import 'package:camera/camera.dart';
import 'services/camera_service.dart';
```

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**No aplica — Paso 2 es 100% frontend/local.**

- No hay endpoints nuevos.
- No hay contratos de API.
- Persistencia es local (SharedPreferences, JSON filesystem).

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
Usuario activa "Modo Calle" → setState(_isStreetModeActive=true) → _applyHardwareSettings() → CameraService.setExposureMode(locked) + setFocusMode(locked)
Usuario activa "Enfoque Bloqueado" → setState(_isFocusLocked=true) → _applyHardwareSettings() → CameraService.setFocusMode(locked)
Usuario cambia velocidad teleprompter → setState(_readingSpeed) → Telepronter widget actualiza scroll
```

### Cobertura de aceptación

| Criterio | Estado | Verificación |
|---|---|---|
| Modo Calle ejecuta parámetros reales en cámara | ✅ | `setExposureMode(locked)`, `setFocusMode(locked)` en L615-616 |
| Modo Fantasma conectado a video | ✅ | `_updateGhostController()` carga clip aprobado |
| Bloqueo de auto-focus conectado a setFocusMode() | ✅ | L619-621 |
| Toggles del teleprompter persisten y afectan widget | ⚠️ | Variables existen, pero Telepronter debe recibir parámetros |
| Mi Cuenta muestra datos reales del dispositivo | ❌ | Hardcodeado en L125, L132 |
| Clear All Data borra directorio vrm_data | ✅ | L321-323: `vrmDataDir.delete(recursive: true)` |
| Settings page toggles tienen efecto real | ❌ | No-op en L201, L210, L228 |

### DX & Tooling — OBLIGATORIO

**Herramientra Propuesta: Validador de Hardware**

```
### Herramienta Propuesta: validador-hardware.dart
- **Qué automatiza:** Ejecuta pruebas de conexión de hardware (cámara, foco, luz, grabación) y reporta estado en consola
- **Tipo:** script / validador
- **Cómo se usa:** `dart run scripts/validador-hardware.dart`
- **Impacto para el usuario final:** Elimina necesidad de pruebas manuales de cada toggle de hardware en distintos dispositivos
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] Persistencia local existe y funciona (SharedPreferences + JSON)
✅ [CODE] CameraService setFocusMode(), setFlashMode(), setExposureMode() existen con firmas correctas
✅ [CODE] _applyHardwareSettings() aplica toggles a hardware
✅ [BACKEND] No aplica — paso 100% local
✅ [FULLSTACK] Modo Calle, Fantasma, Enfoque, Luz ejecutan parámetros reales
✅ [FULLSTACK] Teleprompter fontSize y speed responden a variables
✅ [DX] Herramienta validador-hardware ejecuta sin errores
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| CameraService falla en Android 13+ | Media | Permisos de cámara cambian en Android 13 | Probar en dispositivo físico antes de release |
| setFocusMode no soportado por hardware | Baja | Algunos dispositivos no soportan focus locked | Usar try/catch silencioso como ya existe |
| Teleprompter no recibe parámetros dinámicos | Media | Widget podría usar valores static | Verificar que `Telepronter` acepte `fontSize`, `speed` como parámetros |
| Settings toggles no persisten | Media | setState no persiste entre sesiones | Conectar a `SharedPreferences` |
| Influencer profile no persiste | Media | Solo UI shell | Guardar en `SharedPreferences` al finalizar |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX Tooling:** Validador de hardware | `{paths.scripts}/validador-hardware.dart` | `void main() async { checkCamera(); checkFocus(); checkFlash(); }` | — | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/validador-hardware.dart` sin errores |
| 1 | Conectar _readingSpeed a Telepronter | `recording_page.dart` | `Telepronter(..., readingSpeed: _readingSpeed)` | `Telepronter` existente L1-200 | CODE | Baja | 0.25h | Tarea 0 | → verificar: slider speed cambia scroll |
| 2 | Conectar _teleprompterFontSize a Telepronter | `recording_page.dart` | `Telepronter(..., fontSize: _teleprompterFontSize)` | `Telepronter` existente | CODE | Baja | 0.25h | Tarea 0 | → verificar: slider font cambia tamaño texto |
| 3 | Persistir toggles Settings en SharedPreferences | `settings_page.dart` | `onChanged: (v) => _saveSetting('cloud_sync', v)` | `onboarding_repository.dart` como referencia | CODE | Media | 0.5h | Ninguna | → verificar: toggle persiste tras reiniciar app |
| 4 | Datos reales dispositivo en Account | `account_profile_page.dart` | `Text(_deviceId ?? 'Unknown')` | `path_provider.dart` para obtener device ID | CODE | Media | 0.5h | Tarea 0 | → verificar: device ID muestra valor real |
| 5 | Persistir Influencer Profile | `influencer_profile_page.dart` | `onPressed: _saveProfile` → `SharedPreferences.setString('profile', jsonEncode(data))` | `onboarding_repository.dart` como referencia | CODE | Media | 0.5h | Ninguna | → verificar: perfil persiste tras cerrar app |

**Tiempo total estimado:** 2 horas

---

## 📌 Notas de Implementación

1. **Telepronter widget:** Verificar que acepte parámetros `fontSize` y `readingSpeed` como props (actualmente usados como variables del padre).

2. **SharedPreferences:** Ya está importado en `account_profile_page.dart` (L3). Usar `shared_preferences: ^2.2.3` (proyecto-config.json L148).

3. **Device ID:** Usar `path_provider: ^2.1.3` + `device_info_plus` (no existe en dependencies, necesario agregar).

4. **Manejo de errores:** `CameraService` ya tiene try/catch en todos los métodos de hardware.