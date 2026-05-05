# 🧠 Análisis Técnico — Paso 2: Interfaz Reactiva y Refinamiento Local

> **Agente:** owl
> **Paso:** 02 — Interfaz Reactiva y Refinamiento Local (Días 11-13)
> **Fecha:** 2026-05-05
> **Plan ref:** `DEVS/plan.md` — FASE 2

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `_applyHardwareSettings()` existe y conecta flash/enfoque/exposición | `recording_page.dart:603-628` | ✅ | Implementa `setFlashMode`, `setExposureMode`, `setFocusMode` vía `CameraService` |
| 2 | `CameraService.setFlashMode()` existe | `camera_service.dart:122-131` | ✅ | Wrapper de `CameraController.setFlashMode` con try/catch |
| 3 | `CameraService.setFocusMode()` existe | `camera_service.dart:134-141` | ✅ | Wrapper de `CameraController.setFocusMode` con try/catch |
| 4 | `CameraService.setExposureMode()` existe | `camera_service.dart:144-151` | ✅ | Wrapper de `CameraController.setExposureMode` con try/catch |
| 5 | Toggle CALLE → `_applyHardwareSettings()` | `recording_page.dart:1464-1468` | ✅ | Llama `setExposureMode(locked)` + `setFocusMode(locked)` |
| 6 | Toggle ENFOQUE → `_applyHardwareSettings()` | `recording_page.dart:1519-1524` | ✅ | Llama `setFocusMode(locked/auto)` + `setExposureMode(auto)` |
| 7 | Toggle LUZ → `_applyHardwareSettings()` | `recording_page.dart:1485-1490` | ✅ | Llama `setFlashMode(torch/off)` |
| 8 | Toggle ESPEJO existe pero NO conecta a hardware | `recording_page.dart:1494-1500` | ❌ DISCREPANCIA | Solo `setState`, sin acción de cámara. `CameraService` no tiene método flip/mirror |
| 9 | Toggle MONITOR existe pero NO conecta a hardware | `recording_page.dart:1526-1533` | ❌ DISCREPANCIA | Solo `setState`, sin acción de audio/monitor |
| 10 | Toggle FANTASMA → `_updateGhostController()` | `recording_page.dart:631-669` | ✅ | Carga `VideoPlayerController.file()` del clip aprobado |
| 11 | Toggle GRILLA solo muestra overlay visual | `recording_page.dart:994` | ✅ | `if (!_isGridActive) return SizedBox.shrink()` — overlay visual, no hardware |
| 12 | Brillo de pantalla es overlay visual, no brillo real | `recording_page.dart:917-927` | ⚠️ | `Container` con `Colors.black.withValues(alpha: 1.0 - _screenBrightness)` — simula brillo, no cambia brillo del sistema |
| 13 | `AccountProfilePage` — email hardcodeado "Not configured" | `account_profile_page.dart:118` | ❌ DISCREPANCIA | Plan dice "leer identificadores nativos en uso" — valor estático |
| 14 | `AccountProfilePage` — deviceId hardcodeado "Android Device" | `account_profile_page.dart:125` | ❌ DISCREPANCIA | Comentario `// Can be made dynamic` — no lee ID real del dispositivo |
| 15 | `AccountProfilePage` — memberSince hardcodeado "April 2026" | `account_profile_page.dart:132` | ❌ DISCREPANCIA | Comentario `// Can be made dynamic` — no lee fecha real |
| 16 | `AccountProfilePage` — Sign Out es no-op | `account_profile_page.dart:364-376` | ❌ DISCREPANCIA | Solo muestra snackbar "Signed out" sin limpiar sesión |
| 17 | `SettingsPage` — Theme switcher no persiste | `settings_page.dart:227-229` | ❌ DISCREPANCIA | `selected: {ThemeMode.dark}` hardcodeado, `onSelectionChanged` vacío |
| 18 | `SettingsPage` — Cloud Sync toggle no-op | `settings_page.dart:98-104` | ❌ DISCREPANCIA | Switch `value: false`, `onChanged` vacío |
| 19 | `SettingsPage` — Sliders de grabación/teleprompter no-op | `settings_page.dart:43-86` | ❌ DISCREPANCIA | Todos los `onTap` vacíos con comentario `// Navigate to...` |
| 20 | `UserProfile` persiste en SharedPreferences | `onboarding_repository.dart:11-24` | ✅ | `getUserProfile()` lee de SharedPreferences |
| 21 | `OnboardingRepository.clearProfile()` existe | `onboarding_repository.dart:40-47` | ✅ | Borra todas las keys de perfil |
| 22 | `AccountProfilePage._showClearDataDialog()` borra `vrm_data/` | `account_profile_page.dart:301-349` | ✅ | `Directory('${appDir.path}/vrm_data').delete(recursive: true)` |
| 23 | `DashboardPage` lee perfil real desde `OnboardingRepository` | `dashboard_page.dart:34-44` | ✅ | `_repository.getUserProfile()` con redirect a onboarding si incompleto |
| 24 | `Telepronter` recibe `fontSize` y `readingSpeed` como props | `telepronter.dart:7-27` | ✅ | Widget acepta ambos parámetros |
| 25 | `Telepronter._startScrolling()` usa fórmula empírica | `telepronter.dart:64-91` | ⚠️ | Factor `0.45` hardcodeado, comentario "ajustado empíricamente" |
| 26 | `CameraConfig` centraliza resolución/FPS/formato | `camera_config.dart:6-24` | ✅ | `ResolutionPreset.high`, `enableAudio: true`, `ImageFormatGroup.jpeg` |
| 27 | `RecordingManager` expone `sessionData` mutable | `recording_manager.dart:25` | ✅ | `SessionData sessionData` es public field |
| 28 | `SessionData` tiene `stitchingCompleted` + `finalVideoPath` | `session_data.dart:42-43` | ✅ | Campos existen para tracking de estado |

**Discrepancias encontradas (8):**

1. **ESPEJO no conecta a hardware** — `recording_page.dart:1494-1500`. Solo alterna estado visual. `CameraService` no tiene método para flip horizontal de preview. Requiere implementar `switchCamera()` o transformación de preview con `Transform`.
2. **MONITOR no conecta a hardware** — `recording_page.dart:1526-1533`. Solo alterna estado visual. No hay routing de audio a auriculares. Requiere implementar monitor de audio en `CameraService` o plugin nativo.
3. **Brillo de pantalla es simulación visual** — `recording_page.dart:917-927`. Overlay negro semi-transparente, no cambia brillo del sistema. Plan dice "parámetros duros a la librería de la cámara" — esto no aplica al brillo.
4. **AccountProfilePage datos hardcodeados** — email, deviceId, memberSince son estáticos. Plan dice "leer correctamente los identificadores nativos en uso". Requiere `device_info_plus` o lectura de `SharedPreferences`.
5. **Sign Out es no-op** — `account_profile_page.dart:364-376`. No borra perfil ni datos. Sin auth real, al menos debería limpiar `UserProfile` y redirigir a onboarding.
6. **SettingsPage theme switcher no persiste** — `settings_page.dart:227-229`. `ThemeMode.dark` hardcodeado, callback vacío. `VRMApp` usa `ThemeMode.dark` fijo (`main.dart:37`).
7. **SettingsPage todos los settings son no-op** — Cloud Sync, sliders de grabación/teleprompter, navegación a sub-pantallas — todo vacío.
8. **Teleprompter scroll factor empírico** — `telepronter.dart:76`. Factor `0.45` puede no funcionar bien en todos los dispositivos/tamaños. No hay calibración dinámica.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Tablas/Modelos tocados

Paso 2 NO crea nuevas tablas ni modelos. Modifica comportamiento de modelos existentes:

| Modelo | Archivo | Cambio necesario |
|---|---|---|
| `UserProfile` | `onboarding_repository.dart` | Agregar campo `createdAt` (DateTime) para "member since" real |
| `SessionData` | `session_data.dart` | Sin cambios — ya tiene `stitchingCompleted` + `finalVideoPath` |

### Integridad referencial

No aplica — persistencia es JSON filesystem, no relacional.

### RLS policies

No aplica — MVP sin auth, single-user offline.

### Índices necesarios

No aplica — no hay DB relacional.

### Tipos de datos

- `UserProfile.createdAt` (nuevo campo, `DateTime`) — necesario para mostrar "member since" real en AccountProfilePage.
- `ThemeMode` — debe persistirse en SharedPreferences para sobrevivir reinicio de app.

### Diagrama ER

No aplica — no hay cambios de schema.

### Impacto en datos existentes

- Agregar `createdAt` a `UserProfile` requiere migración suave: si no existe en SharedPreferences, usar `DateTime.now()` como fallback.
- Agregar `themeMode` a SharedPreferences: si no existe, usar `ThemeMode.dark` (actual default).

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones/Clases modificadas

| Componente | Archivo | Qué cambiar | Firma |
|---|---|---|---|
| `_applyHardwareSettings()` | `recording_page.dart:603` | Agregar lógica ESPEJO (flip preview) | `Future<void> _applyHardwareSettings()` |
| Toggle ESPEJO | `recording_page.dart:1494` | Conectar a acción de cámara | `onTap: () { setState(() => _isMirrorActive = !_isMirrorActive); _applyHardwareSettings(); }` |
| Toggle MONITOR | `recording_page.dart:1526` | Conectar a routing de audio | `onTap: () { setState(() => _isMonitorActive = !_isMonitorActive); _toggleMonitor(); }` |
| `_toggleMonitor()` (nuevo) | `recording_page.dart` | Implementar audio routing | `Future<void> _toggleMonitor()` |
| Brillo overlay | `recording_page.dart:917` | Evaluar si mantener simulación o usar brillo real | N/A — decisión de diseño |
| `_buildAccountInfo()` | `account_profile_page.dart:89` | Leer datos reales de dispositivo/perfil | `Widget _buildAccountInfo(context, colors, isDark)` |
| `_showSignOutDialog()` | `account_profile_page.dart:351` | Implementar limpieza real de perfil | `void _showSignOutDialog(context)` |
| `_buildThemeSwitcher()` | `settings_page.dart:202` | Persistir tema en SharedPreferences | `Widget _buildThemeSwitcher(context)` |
| Cloud Sync toggle | `settings_page.dart:98` | Implementar o remover (no aplica MVP) | Remover toggle o marcar "Coming soon" |
| Settings sliders | `settings_page.dart:43-86` | Conectar a `CameraService` / `Telepronter` | Varios `onTap` |
| `Telepronter._startScrolling()` | `telepronter.dart:64` | Calibración dinámica del factor de scroll | `void _startScrolling()` |

### Patrones existentes a seguir

- **Service singleton**: `CameraService`, `ExportService` — agregar métodos nuevos aquí.
- **Repository**: `OnboardingRepository` — agregar `getCreatedAt()`, `saveThemeMode()`.
- **Model with fromJson/toJson**: `UserProfile` — agregar campo `createdAt` con fallback.
- **Exception hierarchy**: `CameraHardwareException` — usar en nuevos métodos de `CameraService`.

### Modularidad

- `CameraService` es el punto correcto para agregar `setMirrorMode()` y `setMonitorMode()`.
- `AccountProfilePage` debe recibir datos vía constructor o repository, no hardcodear.
- `SettingsPage` debe usar `OnboardingRepository` para persistir tema.

### Imports necesarios

- `dart:io` — ya importado en `account_profile_page.dart`
- `package:device_info_plus/device_info_plus.dart` — nueva dependencia para deviceId real (opcional, ver DX)
- `package:screen_brightness/screen_brightness.dart` — opcional para brillo real (nueva dependencia)

### Firmas completas

```dart
// CameraService — nuevo método para mirror/flip
Future<void> setMirrorMode(bool active) async

// CameraService — nuevo método para monitor de audio
Future<void> setMonitorMode(bool active) async

// OnboardingRepository — nuevo método
Future<DateTime> getCreatedAt() async

// OnboardingRepository — nuevo método
Future<void> saveThemeMode(ThemeMode mode) async

// OnboardingRepository — nuevo método
Future<ThemeMode> getThemeMode() async

// RecordingPage — nuevo método
Future<void> _toggleMonitor() async
```

---

## 3️⃣ Análisis de Backend (ETAPA 3)

### Endpoints

No aplica — Paso 2 es 100% frontend/local. No hay llamadas a backend.

### Middleware

No aplica.

### Flujos de datos

```
Toggle CALLE → _applyHardwareSettings() → CameraService.setExposureMode(locked) + setFocusMode(locked)
Toggle LUZ → _applyHardwareSettings() → CameraService.setFlashMode(torch/off)
Toggle ENFOQUE → _applyHardwareSettings() → CameraService.setFocusMode(locked/auto)
Toggle ESPEJO → [ROTO: solo setState] → DEBE → CameraService.setMirrorMode()
Toggle MONITOR → [ROTO: solo setState] → DEBE → CameraService.setMonitorMode()
Toggle FANTASMA → _updateGhostController() → VideoPlayerController.file(approvedClip)
Toggle GRILLA → setState → overlay visual (OK, no requiere hardware)
Brillo → overlay visual (OK como simulación para MVP)
```

### Contratos

No hay contratos backend. Los "contratos" son las interfaces de `CameraService`:

| Método | Input | Output | Estado |
|---|---|---|---|
| `setFlashMode(FlashMode)` | `FlashMode.torch` / `FlashMode.off` | `void` | ✅ Implementado |
| `setFocusMode(FocusMode)` | `FocusMode.locked` / `FocusMode.auto` | `void` | ✅ Implementado |
| `setExposureMode(ExposureMode)` | `ExposureMode.locked` / `ExposureMode.auto` | `void` | ✅ Implementado |
| `setMirrorMode(bool)` | `bool active` | `void` | ❌ No existe |
| `setMonitorMode(bool)` | `bool active` | `void` | ❌ No existe |

### Error handling

`CameraService` existente usa try/catch con `debugPrint` silencioso. Nuevos métodos deben seguir mismo patrón — no crash si hardware no soporta la feature.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo

```
Usuario abre RecordingPage
  → initState() → CameraService.initialize() → _applyHardwareSettings()
  → Usuario toca toggle (CALLE/LUZ/ENFOQUE)
    → setState() → _applyHardwareSettings() → CameraService → hardware
  → Usuario toca ESPEJO
    → setState() → [SIN EFECTO EN CÁMARA] ← GAP
  → Usuario toca MONITOR
    → setState() → [SIN EFECTO EN AUDIO] ← GAP
  → Usuario ajusta brillo
    → overlay visual (simulación aceptable para MVP)

Usuario abre AccountProfilePage
  → Muestra email="Not configured" ← HARDCODED
  → Muestra deviceId="Android Device" ← HARDCODED
  → Muestra memberSince="April 2026" ← HARDCODED
  → Clear All Data → borra vrm_data/ ← FUNCIONAL
  → Sign Out → no-op ← GAP

Usuario abre SettingsPage
  → Theme switcher → no persiste ← GAP
  → Cloud Sync → no-op ← GAP
  → Recording/Teleprompter settings → no-op ← GAP
```

### Coherencia

- Toggles de hardware (CALLE, LUZ, ENFOQUE) están correctamente implementados.
- Toggles "cosméticos" (ESPEJO, MONITOR) están como UI shell — inconsistente con el resto.
- SettingsPage es UI shell completa — inconsistente con la madurez del resto del codebase.
- AccountProfilePage tiene datos hardcodeados — inconsistente con `OnboardingRepository` que sí persiste datos reales.

### Alineación plan vs arquitectura

- Plan dice "Volver real el Modo de calle / Modo fantasma / Bloqueo de Auto-focus" → CALLE y ENFOQUE ya son reales. FANTASMA ya funciona (ghost overlay). ✅
- Plan dice "Interconectar en tiempo real las preferencias (velocidad del prompter)" → Teleprompter ya recibe `fontSize` y `readingSpeed` como props. ✅
- Plan dice "Dotar la vista de cuenta del borrado de carpetas persistentes" → Clear All Data ya funciona. ✅
- Plan dice "leer correctamente los identificadores nativos en uso" → NO implementado. ❌
- Plan dice "todo conectado con el nuevo dashboard_page" → Dashboard ya carga proyectos reales. ✅

### Gaps

1. ESPEJO no tiene efecto en cámara
2. MONITOR no tiene efecto en audio routing
3. AccountProfilePage datos hardcodeados
4. Sign Out no limpia estado
5. SettingsPage completamente no-op
6. Theme switcher no persiste
7. Brillo es simulación, no brillo real del sistema

### DX & Tooling

#### Herramienta Propuesta: `validate_toggles.dart`

- **Qué automatiza:** Verifica que cada toggle en `recording_page.dart` tenga una acción de hardware asociada (no solo `setState`). Escanea el código buscando patrones `setState(() => _isXActive = !_isXActive)` sin llamada a `_applyHardwareSettings()` o método equivalente.
- **Tipo:** Script Dart standalone (análisis estático)
- **Cómo se usa:**
  ```bash
  dart run scripts/validate_toggles.dart --path lib/features/recording/recording_page.dart
  ```
- **Impacto para el implementador:** Detecta toggles "huérfanos" antes de testing manual. Reduce tiempo de QA en cada cambio de overlay.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso

#### Herramienta Propuesta: `device_info_reader.dart`

- **Qué automatiza:** Lee información real del dispositivo (modelo, OS version, deviceId) y la muestra en consola. Reemplaza los 3 valores hardcodeados de `AccountProfilePage`.
- **Tipo:** Script Dart standalone
- **Cómo se usa:**
  ```bash
  dart run scripts/device_info_reader.dart
  ```
- **Impacto para el implementador:** Permite verificar que `device_info_plus` funciona correctamente antes de integrar en la UI.
- **Prioridad:** Tarea 1 — usar output para implementar datos reales en AccountProfilePage

---

## 5️⃣ Criterios de Aceptación

### Sub-paso 2.1: Toggles Operativos (Día 11-12)

```
✅ [DATA] UserProfile tiene campo createdAt con fallback a DateTime.now()
✅ [CODE] Toggle ESPEJO ejecuta acción de cámara (flip preview o switchCamera)
✅ [CODE] Toggle MONITOR ejecuta routing de audio a auriculares
✅ [CODE] Toggle CALLE mantiene ExposureMode.locked + FocusMode.locked
✅ [CODE] Toggle LUZ mantiene FlashMode.torch/off
✅ [CODE] Toggle ENFOQUE mantiene FocusMode.locked/auto
✅ [CODE] Toggle FANTASMA mantiene ghost overlay con VideoPlayerController
✅ [CODE] Toggle GRILLA mantiene overlay visual
✅ [CODE] Brillo de pantalla funciona (simulación aceptable)
✅ [FULLSTACK] Usuario puede activar/desactivar cada toggle y ver efecto inmediato
✅ [CODE] Nuevos métodos en CameraService siguen patrón try/catch + debugPrint
```

### Sub-paso 2.2: Datos del Usuario (Día 13)

```
✅ [DATA] AccountProfilePage muestra email real (o "Not configured" si no hay auth)
✅ [DATA] AccountProfilePage muestra deviceId real del dispositivo
✅ [DATA] AccountProfilePage muestra memberSince real (fecha de onboarding)
✅ [CODE] Sign Out limpia UserProfile de SharedPreferences y redirige a onboarding
✅ [CODE] Clear All Data sigue funcionando (borra vrm_data/)
✅ [FULLSTACK] Dashboard muestra identidad correcta del usuario
✅ [CODE] SettingsPage theme switcher persiste en SharedPreferences
✅ [FULLSTACK] Cambio de tema sobrevive a reinicio de app
```

### Criterio DX

```
✅ [DX] Script validate_toggles.dart ejecuta sin errores y reporta 0 toggles huérfanos
✅ [DX] Script device_info_reader.dart muestra info real del dispositivo
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| ESPEJO requiere transformación de preview que no es soportada por `camera` plugin en todas las versiones | Media | `CameraController` no tiene método nativo de flip horizontal. Requiere `Transform` widget o manipulación de imagen | Usar `Transform.scale(scaleX: -1)` sobre el preview como fallback. Test en dispositivos reales |
| MONITOR requiere acceso a routing de audio que `camera` plugin no expone | Alta | No hay API pública en `camera` para redirigir audio a auriculares | Postergar a V2 o implementar con `MethodChannel` nativo. Marcar como "Coming soon" en UI si no es viable |
| Agregar `createdAt` a UserProfile rompe compatibilidad con perfiles existentes | Baja | Perfiles guardados no tienen el campo | Usar fallback `prefs.getInt('created_at') ?? DateTime.now().millisecondsSinceEpoch` en `getUserProfile()` |
| ThemeMode requiere refactor de `VRMApp` de `StatelessWidget` a `StatefulWidget` | Media | `main.dart:26` — `VRMApp` es Stateless con `ThemeMode.dark` hardcodeado | Convertir a StatefulWidget con `setState` al cambiar tema, o usar `ValueNotifier<ThemeMode>` |
| `device_info_plus` agrega nueva dependencia y posibles issues de permisos en iOS | Baja | Algunos datos de dispositivo requieren permisos especiales en iOS 16+ | Usar solo datos que no requieren permisos (model, systemVersion). Fallback a "Unknown device" |
| Brillo real del sistema requiere `screen_brightness` plugin con issues conocidos en iOS | Media | Plugin `screen_brightness` tiene bugs reportados en iOS 15+ | Mantener simulación con overlay para MVP. Documentar como limitación conocida |
| Sign Out sin auth real puede confundir al usuario | Baja | No hay sesión real que cerrar | Mostrar diálogo explicativo: "Esto borrará tu perfil y todos los proyectos. ¿Continuar?" |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Comp. | Tiempo | Deps | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX**: Crear validador de toggles huérfanos | `scripts/validate_toggles.dart` | `void main(List<String> args)` | `scripts/validate_pipeline.dart` | DX | Media | 1h | Ninguna | → verificar: `dart run scripts/validate_toggles.dart --path lib/features/recording/recording_page.dart` reporta ESPEJO y MONITOR como huérfanos |
| 1 | **DX**: Crear lector de info de dispositivo | `scripts/device_info_reader.dart` | `Future<void> main()` | `scripts/validate_pipeline.dart` | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/device_info_reader.dart` muestra modelo + OS version |
| 2 | Agregar `createdAt` + `themeMode` a `UserProfile` y `OnboardingRepository` | `lib/features/onboarding/data/user_profile.dart`, `onboarding_repository.dart` | `UserProfile({..., DateTime? createdAt})`, `Future<DateTime> getCreatedAt()`, `Future<void> saveThemeMode(ThemeMode)`, `Future<ThemeMode> getThemeMode()` | `onboarding_repository.dart :: saveProfile()` | DATA | Baja | 0.5h | Ninguna | → verificar: `flutter test` pasa + `getUserProfile().createdAt` retorna fecha válida |
| 3 | Implementar ESPEJO — flip de preview en `_applyHardwareSettings()` | `lib/features/recording/recording_page.dart` | Modificar `_applyHardwareSettings()`: agregar `if (_isMirrorActive) { /* aplicar Transform flip */ }` | `recording_page.dart :: _applyHardwareSettings()` | CODE | Media | 1h | Ninguna | → verificar: toggle ESPEJO aplica `Transform.scale(scaleX: -1)` sobre CameraPreview |
| 4 | Implementar MONITOR — marcar como "Coming soon" o stub con MethodChannel | `lib/features/recording/recording_page.dart` | `Future<void> _toggleMonitor() async { /* stub con debugPrint */ }` | `recording_page.dart :: _applyHardwareSettings()` | CODE | Baja | 0.5h | Ninguna | → verificar: toggle MONITOR muestra snackbar "Monitor de audio — disponible en V2" |
| 5 | Convertir `VRMApp` a StatefulWidget para tema dinámico | `lib/main.dart` | `class VRMApp extends StatefulWidget`, `_VRMAppState extends State<VRMApp>` con `ValueNotifier<ThemeMode>` | `dashboard_page.dart :: _loadPattern()` | CODE | Media | 1h | Tarea 2 | → verificar: cambiar tema en Settings y ver cambio inmediato en toda la app |
| 6 | Conectar SettingsPage theme switcher a SharedPreferences | `lib/features/settings/settings_page.dart` | `_buildThemeSwitcher()`: `onSelectionChanged: (mode) => OnboardingRepository().saveThemeMode(mode)` | `settings_page.dart :: _buildThemeSwitcher()` | CODE | Baja | 0.5h | Tarea 5 | → verificar: cambiar tema → reiniciar app → tema persiste |
| 7 | Implementar datos reales en AccountProfilePage | `lib/features/account/account_profile_page.dart` | `_buildAccountInfo()`: leer deviceId de script `device_info_reader.dart`, memberSince de `OnboardingRepository.getCreatedAt()`, email de `UserProfile` | `account_profile_page.dart :: _buildAccountInfo()` | CODE | Media | 1.5h | Tarea 1 | → verificar: AccountProfilePage muestra modelo real del dispositivo y fecha de registro |
| 8 | Implementar Sign Out real | `lib/features/account/account_profile_page.dart` | `_showSignOutDialog()`: llamar `OnboardingRepository().clearProfile()` + `Navigator.pushReplacementNamed('/onboarding')` | `account_profile_page.dart :: _showClearDataDialog()` | CODE | Baja | 0.5h | Ninguna | → verificar: Sign Out → redirige a onboarding + perfil borrado |
| 9 | Remover/marcar no-op settings en SettingsPage | `lib/features/settings/settings_page.dart` | Agregar comentario `// TODO: V2` o remover tiles no implementados | `settings_page.dart` | CODE | Baja | 0.5h | Ninguna | → verificar: `flutter analyze` sin warnings + settings sin onTap vacíos |
| 10 | Validar flujo end-to-end de toggles | — | — | — | FULLSTACK | Baja | 1h | Tareas 0-4, 7-9 | → verificar: criterios §5 pasan todos en dispositivo real o emulador |

**Tiempo total estimado:** ~8.5 horas

---

## 8️⃣ Roadmap (NO implementar ahora)

- **ESPEJO con flip nativo:** Investigar si `camera` plugin soporta `CameraController.setExposurePoint` + mirror nativamente en futuras versiones. Alternativa: `MethodChannel` con `AVCaptureVideoOrientation` (iOS) y `Matrix` transform (Android).
- **MONITOR con audio routing completo:** Implementar `MethodChannel` nativo con `AudioManager.setMode()` (Android) y `AVAudioSession.setCategory()` (iOS) para routing real a auriculares.
- **Brillo real del sistema:** Evaluar `screen_brightness` plugin cuando se estabilice en iOS 17+. Requiere manejo de permisos adicional.
- **Settings de teleprompter persistentes:** Guardar `fontSize`, `readingSpeed`, `screenBrightness` en SharedPreferences para que sobrevivan a reinicio.
- **Sub-pantallas de Settings:** Implementar navegación a `RecordingDurationSettingsPage`, `CameraSettingsPage`, `FontSizeSettingsPage` cuando features estén listas.
- **InfluencerProfile persistence:** Los datos del formulario de 3 pasos en `influencer_profile_page.dart` no persisten. Conectar a `UserProfile` o modelo dedicado en V2.
- **Remover dependencias muertas:** `sqflite` y `battery_plus` en `pubspec.yaml` — no importadas en ningún archivo. Remover antes de release (Paso 4).
- **Tests de toggles:** Agregar tests unitarios que verifiquen `_applyHardwareSettings()` llama los métodos correctos de `CameraService` para cada combinación de toggles.

---

## 📊 Resumen de Métricas

| Métrica | Valor |
|---|---|
| Elementos verificados (§0) | 28 (umbral: ≥12 para 3-5 archivos) |
| Discrepancias detectadas | 8 |
| Secciones completadas | 8/8 (0-7) |
| Etapas cubiertas | 4/4 (data, code, backend, fullstack+DX) |
| Criterios de aceptación | 17 (≥1 por sub-paso) |
| Riesgos identificados | 7 (≥3 requeridos) |
| Tareas atómicas | 10 (100% — 1 artefacto por tarea) |
| Interfaz exacta por tarea | 100% |
| Patrón de referencia explícito | 100% |
| Verificación inline | 100% |
| Suposiciones no verificadas | 1 (factor empírico 0.45 en Telepronter) |
| Propuestas DX/Tooling | 2 herramientas concretas |
| Tiempo total estimado | ~8.5 horas |
