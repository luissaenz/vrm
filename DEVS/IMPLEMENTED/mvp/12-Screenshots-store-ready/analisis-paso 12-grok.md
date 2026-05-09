# Análisis Técnico — Paso 12: Screenshots-store-ready (AGENTE: grok)

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|----------|--------------|--------|-----------|
| 1 | `assets/store/screenshots/` existe | `ls {paths.root}/assets/store/screenshots` | ✅ | Dir exists |
| 2 | Screenshots capturados (5 archivos) | `ls {paths.root}/assets/store/screenshots/*.png` | ✅ | step1_idea.png, step2_recording.png, step3_review.png, step4_stitch.png, step5_export.png |
| 3 | Resolución store-ready (>=1080x1920 Android, >=1284x2778 iOS) | `dart run scripts/store_prep_cli.dart check` | ❌ | All 5 fail resolution check |
| 4 | `store_prep_cli.dart` tiene guía y validación | Grep en `scripts/store_prep_cli.dart` | ✅ | `_runScreenshotsGuide()`, `_validateScreenshotResolution()` |
| 5 | `proyecto-config.json` paths correctos | Read `proyecto-config.json` | ✅ | `paths.scripts`, `paths.root` |

**Discrepancias encontradas:**  
- Screenshots existen pero resolución insuficiente (<1080x1920). Plan requiere >=1080x1920 (Android) o >=1284x2778 (iOS). Capturas actuales probablemente emulador.  
  **Resolución:** Recapturar en dispositivo real usando `adb shell screencap -p` o captura nativa, como indica `store_prep_cli.dart screenshots`.

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ **No cambios DB:** Paso manual, no toca schema ni datos.
- ✅ **Archivos static:** Screenshots PNG en `assets/store/screenshots/`.
- ✅ **Requisitos resolución:** Android 1080x1920+, iOS 1284x2778+ (16:9 landscape).
- ✅ **Persistencia:** Archivos locales en repo (git track via .gitkeep).

Impacto: Screenshots bajos bloquean store submission. Recaptura en real device → fix.

## 2️⃣ Análisis de Código (ETAPA 2)

- ✅ **No código nuevo:** Paso captura manual.
- ✅ **Herramientas existentes:** `store_prep_cli.dart` valida resolución via `_getPngDimensionsSync()`.
- ✅ **Patrón:** Store prep scripts siguen patrón CLI Dart (como `vrm_health_check.dart`).
- ✅ **Calidad:** Validación PNG header parsing correcta (bytes 16-23 para width/height).
- ✅ **Imports:** Dart core (File, bytes), no externos.

Ejemplo patrón: `_validateScreenshotResolution()` en `store_prep_cli.dart:667` — valida width >=1080 && height >=1920.

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ **No endpoints:** Paso frontend/UI only.
- ✅ **No APIs:** Captura manual de UI.
- ✅ **No middleware:** No backend involved.
- ✅ **Flujos:** Transferencia manual a `assets/store/screenshots/`.

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ **Flujo end-to-end:** UI screens → captura → store submission.
- ✅ **Coherencia:** Screenshots representan flujo app (Dashboard → Script → Grabación → Review → Export).
- ✅ **UX:** Screenshots para stores muestran value prop (grabación asistida).
- ✅ **Gaps:** Resolución baja = bloqueo stores.
- ✅ **DX & Tooling (OBLIGATORIO):**

### Herramienta Propuesta: `store_prep_cli.dart screenshots`
- **Qué automatiza:** Guía captura manual + validación resolución post-captura.
- **Tipo:** CLI guide + validator.
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart screenshots` → imprime pasos ADB. `dart run scripts/store_prep_cli.dart check` → valida archivos.
- **Impacto para el usuario final:** Reduce errores captura (resolución wrong, emulador reject). Evita submission fail stores.
- **Prioridad:** Tarea 0 — usar antes captura.

## 5️⃣ Criterios de Aceptación

- ✅ [FULLSTACK] 5 PNG en `assets/store/screenshots/` con nombres step1.png..step5.png
- ✅ [FULLSTACK] Cada PNG >=1080x1920px (Android) o >=1284x2778 (iOS)
- ✅ [DX] `store_prep_cli.dart check` pasa screenshots validation
- ✅ [FULLSTACK] Capturas en dispositivo real (no emulador)

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| Resolución insuficiente | 🔴 ALTO | Captura emulador o manual low-res | Recapturar real device + validar con CLI |
| Stores rechazan screenshots | 🟡 MEDIO | Formato wrong o contenido no representativo | Seguir guía CLI, asegurar 16:9 landscape |
| Dispositivo no disponible | 🟡 MEDIO | Solo emulador | Plan backup: usar device físico para MVP |

- Riesgos integración: Stores requieren screenshots → blocker release.
- Riesgos futuro: Screenshots outdated → actualizar en updates.

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|--------|------------|-----------------|-----------------|--------|-------------|-------------|--------------|-------------|
| 0 | **DX & Tooling:** Ejecutar guía CLI | N/A | `dart run scripts/store_prep_cli.dart screenshots` | `scripts/store_prep_cli.dart :: _runScreenshotsGuide()` | DX | Baja | 0.1h | Ninguna | → verificar: Output guía impresa |
| 1 | Conectar dispositivo físico | N/A | ADB o USB | Manual | FULLSTACK | Baja | 0.2h | Tarea 0 | → verificar: `adb devices` muestra device |
| 2 | Capturar Dashboard | `assets/store/screenshots/step1.png` | PNG >=1080x1920 | `store_prep_cli.dart` guide | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: File exists + resolution OK |
| 3 | Capturar Creación proyecto/Script | `assets/store/screenshots/step2.png` | PNG >=1080x1920 | `store_prep_cli.dart` guide | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: File exists + resolution OK |
| 4 | Capturar Grabación overlay | `assets/store/screenshots/step3.png` | PNG >=1080x1920 | `store_prep_cli.dart` guide | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: File exists + resolution OK |
| 5 | Capturar Revisión clips | `assets/store/screenshots/step4.png` | PNG >=1080x1920 | `store_prep_cli.dart` guide | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: File exists + resolution OK |
| 6 | Capturar Exportación | `assets/store/screenshots/step5.png` | PNG >=1080x1920 | `store_prep_cli.dart` guide | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: File exists + resolution OK |
| 7 | Transferir archivos | `assets/store/screenshots/` | step1.png..step5.png | Manual ADB pull | FULLSTACK | Baja | 0.2h | Tareas 2-6 | → verificar: 5 files in dir |
| 8 | Validar con CLI | N/A | `dart run scripts/store_prep_cli.dart check` | `scripts/store_prep_cli.dart :: check screenshots` | FULLSTACK | Baja | 0.1h | Tarea 7 | → verificar: Output "screenshots OK" |

**Tiempo total estimado:** 2.0 horas

## Roadmap (NO implementar ahora)

- Automatizar captura: Script ADB para batch capture screens.
- Screenshots iOS/Android separate: Detect platform, adjust min res.
- CI validation: Hook en build para check screenshots.

---

**Idioma:** Español 🇪🇸