# Análisis Paso 12: Screenshots-store-ready

**Agente:** lgnm1  
**Fase:** mvp  
**Fecha:** 2026-05-09

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `assets/store/screenshots/` existe | Directory check | ✅ | `D:\Develop\Personal\vrm\assets\store\screenshots\` |
| 2 | 5 screenshots existen | File count check | ✅ | step1_idea.png, step2_recording.png, step3_review.png, step4_stitch.png, step5_export.png |
| 3 | `store_prep_cli.dart` tiene subcomando `screenshots` | Grep en L520-522 | ✅ | `case 'screenshots': _runScreenshotsGuide();` L520 |
| 4 | Check [5] valida resolución screenshots | Grep en L188-236 | ✅ | `_validateScreenshotResolution()` L667-671 verifica ≥1080x1920 |
| 5 | PNG IHDR parsing implementado | Grep en L648-665 | ✅ | `_getPngDimensionsSync()` extrae width/height de bytes 16-23 |
| 6 | DashboardPage existe como pantalla destino | File exists | ✅ | `lib/features/dashboard/dashboard_page.dart` L17-22 |
| 7 | NewProjectPage existe como pantalla destino | File exists | ✅ | `lib/features/new_project/new_project_page.dart` |
| 8 | RecordingPage tiene overlay de control | Grep en L1279-1625 | ✅ | 9 botones conectados a CameraService |
| 9 | ClipReviewPage existe | File exists | ✅ | `lib/features/recording/clip_review_page.dart` L323 |
| 10 | RecordingEndPage muestra exportación | File exists | ✅ | `lib/features/recording/recording_end_page.dart` L202-210 |
| 11 | `--help` muestra guía de screenshots | Grep en L19-32 | ✅ | Subcomando `screenshots` en usage string |

**Discrepancias encontradas:**  
❌ **D1:** Resolución screenshots insuficiente. phase-state.md L92 confirma: "5 archivos existen pero 1024x1024. Android requiere 1080x1920+, iOS 1284x2778+". `store_prep_cli.dart check` fallará al validar resolución.

---

## 1️⃣ Análisis de Datos

- ✅ **Schema:** No aplica — screenshots son archivos binarios, no datos estructurados
- ✅ **Paths esperados:**
  - `assets/store/screenshots/step1.png` (Dashboard)
  - `assets/store/screenshots/step2.png` (Creación proyecto/script)
  - `assets/store/screenshots/step3.png` (Grabación overlay)
  - `assets/store/screenshots/step4.png` (Revisión clips)
  - `assets/store/screenshots/step5.png` (Exportación/performance)
- ✅ **Resolución requerida:** ≥1080x1920 (Android) o ≥1284x2778 (iOS)
- ⚠️ **Problema:** Archivos actuales son 1024x1024 — insuficiente para stores
- ⚠️ **Nombre de archivos:** Actualmente `step1_idea.png`, `step2_recording.png`, etc. — deben ser `step1.png` a `step5.png` o `step{X}.png`

---

## 2️⃣ Análisis de Código

- ✅ **store_prep_cli.dart** `screenshots` subcomando (L520-522):
  ```dart
  case 'screenshots':
    _runScreenshotsGuide();
  ```
- ✅ **_runScreenshotsGuide()** (L673-703):
  - Muestra requisitos: Android 1080x1920+, iOS 1284x2778+
  - Lista 5 pantallas: Dashboard, Creación proyecto, Grabación overlay, Revisión clips, Exportación
  - Comandos ADB: `adb shell screencap`, `adb pull`
  - Destino: `assets/store/screenshots/` como `step1.png`..`step5.png`
- ✅ **_validateScreenshotResolution()** (L667-671):
  ```dart
  bool _validateScreenshotResolution(String path) {
    final dims = _getPngDimensionsSync(path);
    if (dims == null) return false;
    return dims.width >= 1080 && dims.height >= 1920;
  }
  ```
- ✅ **_getPngDimensionsSync()** (L648-665): Parsea header PNG IHDR desde bytes 16-23

**Pantallas disponibles para captura:**
| # | Pantalla | Archivo | Navegación |
|---|---|---|---|
| 1 | Dashboard | `dashboard_page.dart` | Ruta inicial `/dashboard` |
| 2 | Creación proyecto | `new_project_page.dart` | Desde Dashboard → "Nuevo proyecto" |
| 3 | Grabación overlay | `recording_page.dart:1279-1625` | Desde proyecto → botón grabar |
| 4 | Revisión clips | `clip_review_page.dart` | Desde grabación completada |
| 5 | Exportación | `recording_end_page.dart` | Desde stitch completado |

---

## 3️⃣ Análisis de Backend

- ✅ **No aplica:** Screenshots son UI estática, no requieren backend
- ✅ **Rutas de archivos:** Todas las pantallas son accesibles vía navigation stack sin autenticación
- ✅ **Flujo end-to-end:** Onboarding → Dashboard → Nuevo Proyecto → Grabación → Revisión → Stitch → Export → End

---

## 4️⃣ Análisis de Fullstack + DX

### Flujo completo:
```
Dashboard (step1)
   ↓ tap "Nuevo proyecto"
NewProjectPage (step2)
   ↓ input idea → "Continuar al guion"
ScriptStudioPage (step2 cont.)
   ↓ "Grabar videos"
RecordingPage con Overlay (step3)
   ↓ completar todos los chunks
ClipReviewPage (step4)
   ↓ aceptar clips
StitchProgressPage → RecordingEndPage (step5)
```

### DX & Tooling — OBLIGATORIO:

### Herramienta Propuesta: screenshot_naming_validator.dart
- **Qué automatiza:** Valida que los screenshots existan con nombres correctos (`step1.png` a `step5.png`) y resolución mínima
- **Tipo:** Script CLI
- **Cómo se usa:** `dart run scripts/screenshot_naming_validator.dart --fix` renombra automáticamente archivos mal nombrados
- **Impacto para el usuario final:** Evita que el implementador tenga que renombrar manualmente 5 archivos y verifique resoluciones una por una
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso

```dart
// scripts/screenshot_naming_validator.dart
// Verifica existencia y nomenclatura de screenshots
// --fix: renombra archivos pattern step{N}_*.png → step{N}.png
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] 5 archivos PNG en `assets/store/screenshots/`
✅ [DATA] Cada archivo ≥ 1080x1920px (Android) o ≥ 1284x2778px (iOS)
✅ [CODE] store_prep_cli.dart check reporta screenshots OK
✅ [CODE] Screenshots nombrados step1.png..step5.png (o validados por naming validator)
✅ [FULLSTACK] Capturas en dispositivo real (no emulador)
✅ [DX] screenshot_naming_validator.dart ejecuta sin errores
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Screenshots mal nombrados | Media | Archivos actuales usan naming `step1_idea.png` en vez de `step1.png` | DX tool renombra automáticamente |
| Resolución insuficiente | Alta | Dispositivos físicos pueden no alcanzar 1080x1920+ en portrait | Usar landscape o generar desde emulator de alta densidad |
| Captura manual en dispositivo real | Media | Requiere hardware físico disponible | Guía CLI `store_prep_cli.dart screenshots` con pasos detallados |
| store_prep_cli.dart no detecta resolución | Baja | Ya implementado L667-671 | Validado contra código fuente |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX & Tooling: screenshot_naming_validator | `scripts/screenshot_naming_validator.dart` | `void main(List<String> args)` — busca `*.png` en `assets/store/screenshots/`, valida nombres, `--fix` renombra | `scripts/store_prep_cli.dart` estructura CLI | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/screenshot_naming_validator.dart` lista archivos correctos |
| 1 | Capturar screenshot Dashboard | `assets/store/screenshots/step1.png` | PNG, 1080x1920+ resolution | Captura manual en dispositivo real | FULLSTACK | Baja | 0.5h | Tarea 0 | → verificar: `store_prep_cli.dart check [5]` |
| 2 | Capturar screenshot Creación proyecto | `assets/store/screenshots/step2.png` | PNG, 1080x1920+ resolution | Navegar: Dashboard → Nuevo proyecto → Script studio | FULLSTACK | Baja | 0.5h | Tarea 1 | → verificar: `store_prep_cli.dart check [5]` |
| 3 | Capturar screenshot Grabación overlay | `assets/store/screenshots/step3.png` | PNG, 1080x1920+ resolution | Navegar: Proyecto → RecordingPage (overlay visible) | FULLSTACK | Baja | 0.5h | Tarea 2 | → verificar: `store_prep_cli.dart check [5]` |
| 4 | Capturar screenshot Revisión clips | `assets/store/screenshots/step4.png` | PNG, 1080x1920+ resolution | Navegar: Recording completada → ClipReviewPage | FULLSTACK | Baja | 0.5h | Tarea 3 | → verificar: `store_prep_cli.dart check [5]` |
| 5 | Capturar screenshot Exportación | `assets/store/screenshots/step5.png` | PNG, 1080x1920+ resolution | Navegar: Stitch completado → RecordingEndPage | FULLSTACK | Baja | 0.5h | Tarea 4 | → verificar: `store_prep_cli.dart check [5]` |
| 6 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.25h | Tareas 0-5 | → verificar: `dart run scripts/store_prep_cli.dart check` pasa todos los tests |

**Tiempo total estimado:** 3.25 horas

---

## Roadmap (NO implementar ahora)

- Automatizar captura vía integration test con `integration_test` package
- Generar screenshots en CI usando Firebase Test Lab o similar
- Soporte para screenshots en landscape (actualmente portrait)