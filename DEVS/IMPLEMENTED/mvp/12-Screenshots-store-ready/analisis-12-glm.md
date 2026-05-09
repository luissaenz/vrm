# 🧠 Análisis Técnico — Paso 12: Screenshots-store-ready
**Agente:** glm | **Paso:** 12 | **Fase:** mvp

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | Directorio `assets/store/screenshots/` existe | `ls` en directorio | ✅_VERIFICADO | Dir existe con 5 archivos + .gitkeep |
| 2 | 5 archivos PNG en `assets/store/screenshots/` | Archivos: step1_idea.png, step2_recording.png, step3_review.png, step4_stitch.png, step5_export.png | ✅_VERIFICADO | 5 archivos, 475-620KB cada uno |
| 3 | Nombres de archivo coinciden con guía CLI (`step1.png..step5.png`) | grep `step\d+\.png` en store_prep_cli.dart:699 | ❌_DISCREPANCIA | CLI dice "Guardar como step1.png..step5.png" pero archivos reales son `step1_idea.png`, `step2_recording.png`, etc. Nombres no coinciden. Verificar si CLI cuenta cualquier `*.png` o solo nombres específicos. |
| 4 | Formato de screenshots = PNG válido | Header check: `bytes[0:8]` = `FF D8 FF E0 00 10 4A 46` = **JPEG JFIF** | ❌_DISCREPANCIA | Archivos tienen extensión `.png` pero contenido es JPEG (header `FF D8 FF E0`). `_getPngDimensionsSync()` retorna `null` → validación de resolución FALLA. |
| 5 | Resolución ≥1080x1920 | Phase-state dice 1024x1024; store_prep_cli check reporta "Resolución insuficiente" | ❌_DISCREPANCIA | Resolución actual insuficiente. Archivos son JPEG, PNG IHDR parser no puede leer dimensiones. Necesitan recaptura en dispositivo real. |
| 6 | Directorio legacy `assets/images/screenshots/` | `ls` en directorio | ✅_VERIFICADO | Existe con mismos 5 archivos JPEG duplicados |
| 7 | CLI `store_prep_cli.dart` existe y funciona | `dart run scripts/store_prep_cli.dart check` | ✅_VERIFICADO | 703L, 10/11 checks pasan. Screenshots falla. |
| 8 | `_getPngDimensionsSync()` parsea PNG IHDR | Líneas 648-665 | ✅_VERIFICADO | Lee bytes 16-23 para width/height big-endian. Retorna null si header no empieza con `0x89 0x50 0x4E 0x47`. |
| 9 | `_validateScreenshotResolution()` | Líneas 667-671 | ✅_VERIFICADO | `dims.width >= 1080 && dims.height >= 1920`. Retorna false si dims es null. |
| 10 | CLI check cuenta PNGs en AMBOS directorios | Líneas 188-236, 529-576 | ✅_VERIFICADO | Cuenta `assets/store/screenshots/` + `assets/images/screenshots/`. Actual: 10 archivos (5+5 duplicados), todos fallan resolución. |
| 11 | Dashboard page existe | `dashboard_page.dart` (539L) | ✅_VERIFICADO | Clase `DashboardPage`, ruta `'/dashboard'`, avatar + greeting + action cards + projects. |
| 12 | NewProjectPage existe | `new_project_page.dart` | ✅_VERIFICADO | Script input, mic dictation, AI button, "SPLIT INTO FRAGMENTS" CTA. Navegación directa (sin ruta nombrada). |
| 13 | RecordingPage existe | `recording_page.dart` (1625L) | ✅_VERIFICADO | Camera preview, teleprompter, overlay con 9 toggles, countdown. Ruta `'/recording'`. Requiere `analysis` + `projectId`. |
| 14 | ClipReviewPage existe | `clip_review_page.dart` (323L) | ✅_VERIFICADO | VideoPlayerController.file(), auto-accept 3s, accept/reject buttons. Navegación directa (sin ruta). Requiere clipPath + projectId. |
| 15 | RecordingEndPage existe | `recording_end_page.dart` (604L) | ✅_VERIFICADO | Video playback, session stats, export con progress bar. Ruta `'/recording-end'`. Parámetros: finalVideoPath + sessionData. |
| 16 | StitchProgressPage existe | `stitch_progress_page.dart` (128L) | ✅_VERIFICADO | Progress bar, status labels. Ruta `'/stitch-progress'`. |
| 17 | `_runScreenshotsGuide()` en CLI | Líneas 673-702 | ✅_VERIFICADO | Guía completa: requisitos Android/iOS, pasos ADB, validación. |
| 18 | Licencias Android/iOS OK para captura | No impacta screenshots | ✅_VERIFICADO | Solo captura de pantalla, no usa APIs con restricciones. |

**Umbral verificación:** 6-10 archivos afectados → ≥12 elementos. Elementos verificados: 18. ✅ Supera umbral.

### Discrepancias encontradas:

| # | Discrepancia | Resolución propuesta |
|---|---|---|
| D1 | Nombres de screenshots: archivos reales son `step1_idea.png`..`step5_export.png` pero CLI guía dice `step1.png`..`step5.png`. CLI check cuenta `*.png` sin filtrar por nombre, así que no invalida — pero documenta inconsistencia. | Renombrar archivos a `step1.png`..`step5.png` al recapturar. Actualizar nombres descriptivos en guía CLI si se desea mantener contexto. |
| D2 | Archivos son JPEG con extensión `.png`. `_getPngDimensionsSync()` retorna null → check falla. | Recapturar como PNG real desde dispositivo (ADB `screencap` produce PNG nativo). Eliminar JPEGs actuales. |
| D3 | Resolución insuficiente (1024x1024 vs mínimo 1080x1920 Android / 1284x2778 iOS). | Recapturar en dispositivo con pantalla ≥1080x1920. ADB `screencap` produce resolución nativa del dispositivo. |
| D4 | Screenshots duplicados en `assets/images/screenshots/` (legacy). CLI cuenta 10 total (5+5). | Eliminar directorio `assets/images/screenshots/` o servir solo como referencia. Check cuenta ambos dirs → puede dar falso positivo si solo un dir tiene archivos válidos. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema / Persistencia

- **No hay tablas ni migraciones涉及.** Paso 12 es 100% manual/asset.
- Persistencia relevant: `vrm_data/logs/app.log` (LoggerService) para diagnóstico de errores durante captura.
- JSON filesystem (`vrm_data/projects/`) — screenshots no lo tocan.

### Integridad referencial

- N/A. No hay FK, no hay constraints de datos.

### RLS policies

- N/A. App offline/single-user sin auth.

### Índices necesarios

- N/A.

### Tipos de datos problemáticos

- **JPEG disfrazado de PNG**: Los 5 archivos actuales tienen extensión `.png` pero contenido JPEG (header `FF D8 FF E0`). El parser PNG en `store_prep_cli.dart:648-665` no puede leer dimensiones. Necesitan ser recapturados como PNG nativos (`screencap` en Android produce PNG).

### Impacto en datos existentes

- Reemplazar 5 archivos en `assets/store/screenshots/`.
- Opcional: eliminar o mantener `assets/images/screenshots/` como backup.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Funciones/clases creadas/modificadas

**NADA nuevo en `lib/`.** Paso 12 es captura manual de assets.

### Código existente relevante

| Archivo | Función | Firma | Rol en paso |
|---|---|---|---|
| `scripts/store_prep_cli.dart:673-702` | `_runScreenshotsGuide()` | `void _runScreenshotsGuide()` | Guía de captura manual. Printe pasos, requisitos, comandos ADB. |
| `scripts/store_prep_cli.dart:648-665` | `_getPngDimensionsSync()` | `({int width, int height})? _getPngDimensionsSync(String path)` | Parsea PNG IHDR para obtener dimensiones. Retorna null si no es PNG válido. |
| `scripts/store_prep_cli.dart:667-671` | `_validateScreenshotResolution()` | `bool _validateScreenshotResolution(String path)` | Valida width≥1080 && height≥1920. Retorna false si dims null. |
| `scripts/store_prep_cli.dart:188-236` | Check [5] screenshots | En `_runCheck()` | Cuenta PNGs en ambos dirs, valida resolución mínima. |
| `scripts/store_prep_cli.dart:529-576` | Assets validate [5] | En `_runAssets()` | Similar a check [5] pero en contexto de validación de assets. |

### Patrones existentes

- **Patón CLI**: `store_prep_cli.dart` sigue patrón de `vrm_health_check.dart` — subcomandos con switch/case, `_run*()` funciones privadas, `allOk` boolean tracking.
- **Patón validación**: `_getPngDimensionsSync()` lee bytes crudos → sin dependencias externas. Similar a `_randomSuffix()` en keystore.
- **Patón directorios**: Dos directorios de screenshots (`_storeScreenshotsDir` y `_existingScreenshotsDir`) — check valida ambos.

### Modularidad

- `store_prep_cli.dart` ya maneja screenshots. No se necesita nuevo archivo Dart.
- Posible DX tool: script ADB para automatizar captura de 5 screenshots en secuencia.

### Imports existentes relevantes

```dart
// store_prep_cli.dart (ya importados)
import 'dart:io';
import 'dart:math';
```

No se necesitan imports adicionales.

### Calidad

- `_getPngDimensionsSync()` NO valida que el archivo tenga extensión `.png` antes de parsear. Si un `.jpg` se coloca en el directorio, retorna null → falla check. **Este comportamiento es correcto** para el propósito del paso (requerir PNG reales).
- El check cuenta archivos en **dos directorios** sin verificar duplicados. Si mismo archivo existe en ambos dirs, cuenta 2x. Podría dar falsos positivos.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

### APIs / Endpoints

- **N/A.** No hay cambios de API. Paso 12 es captura de assets + validación CLI.

### Middleware

- N/A.

### Flujos

- **Flujo manual:**
  1. Conectar dispositivo físico con app compilada en debug
  2. Navegar a cada pantalla (Dashboard → NewProject → Recording → ClipReview → RecordingEnd)
  3. Capturar screenshot con `adb shell screencap -p /sdcard/step1.png`
  4. Transferir con `adb pull /sdcard/step1.png assets/store/screenshots/`
  5. Repetir para las 5 pantallas
  6. Ejecutar `dart run scripts/store_prep_cli.dart check`

### Contratos

- **Contrato CLI-filesystem**: `assets/store/screenshots/*.png` deben ser archivos PNG válidos con resolución ≥1080x1920.
- **Contrato CLI-Android**: ADB screencap produce PNG nativo con resolución del dispositivo.
- **Contrato stores**: Google Play requiere ≥1080x1920px. Apple App Store requiere ≥1284x2778px.

### Error handling

- Si dispositivo no conectado: `adb: device not found` → usuario debe conectar.
- Si app no instalada: `adb shell am start` falla → usuario debe instalar.
- Si resolución del dispositivo < 1080x1920: screenshot no pasa validación → usuario necesita dispositivo compatible.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo: DB → Backend → Frontend → UX

```
[Dispositivo Físico]
  │
  ├── App en debug mode
  │     ├── Dashboard (screenshot 1)
  │     ├── NewProjectPage (screenshot 2) 
  │     ├── RecordingPage + overlay (screenshot 3)
  │     ├── ClipReviewPage (screenshot 4)
  │     └── RecordingEndPage (screenshot 5)
  │
  ├── ADB screencap → /sdcard/stepN.png
  ├── ADB pull → assets/store/screenshots/stepN.png
  │
  └── store_prep_cli.dart check → ✅/❌ validación
```

### Coherencia

- Las 5 pantallas objetivo existen y son navegables en la app. ✅
- El flujo Dashboard → NewProject → ScriptStudio → Recording → ClipReview → Stitch → RecordingEnd es funcional (aunque IA usa fallback). ✅
- RecordingPage requiere `analysis` + `projectId` → screenshot 3 necesita proyecto previo con guion. ✅

### Alineación plan-arquitectura

- Plan dice "capturar en dispositivo real" → correcto. Emuladorproducer resolución menor y stores rechazan screenshots de emulador. ✅
- Plan dice "5 screenshots" → coincide con CLI check (mínimo 5). ✅
- Plan dice "1080x1920+ (Android), 1284x2778+ (iOS)" → CLI valida solo width≥1080 && height≥1920. **⚠️ iOS requiere 1284x2778 pero CLI no distingue plataformas. Para publicar en ambas stores, se necesitan screenshots en ambas resoluciones o al menos la mayor (1284x2778).**

### Gaps

1. **Navegación a pantallas para screenshot**: RecordingPage y ClipReviewPage requieren datos en vivo (projectId, analysis, clipPath). No hay forma de navegar directamente a estas pantallas sin proyecto activo. Se necesita proyecto dummy con guión y clips para capturas 3 y 4.
2. **RecordingPage con overlay visible**: Para capturar "Grabación con overlay de control", se necesita grabación activa con teleprompter + overlay desplegado. Esto requiere permisos de cámara + micrófono + sesión de grabación en curso.
3. **iOS screenshots**: Plan menciona 1284x2778+ pero CLI solo valida ≥1080x1920. Si se publica en App Store, se necesitan screenshots de iPhone 14 Pro/15 Pro o similar.
4. **Archivos duplicados en legacy dir**: `assets/images/screenshots/` tiene copias idénticas. Check cuenta ambos. Eliminar legacy o ignore.
5. **Formato JPEG vs PNG**: Los archivos actuales son JPEG con extensión .png. `_getPngDimensionsSync()` no los puede leer. Al recapturar con ADB screencap, se obtiene PNG nativo.

### DX & Tooling (OBLIGATORIO)

```
### Herramienta Propuesta: screenshot_capture.dart
- **Qué automatiza:** Captura secuencia de 5 screenshots en dispositivo Android conectado vía ADB. Navega app a las 5 pantallas, captura screenshot estratégicamente, valida resolución, renombra a step1.png..step5.png, transfiere a assets/store/screenshots/.
- **Tipo:** CLI script
- **Cómo se usa:** `dart run scripts/screenshot_capture.dart --device <device_id> [--ios]`
- **Impacto para el usuario final:** Reduce captura manual de 5 screenshots de ~30min a ~5min. Automatiza captura, renombrado, transferencia y validación en un solo comando.
- **Prioridad:** Tarea 0 — implementar antes de captura manual. Si dispositivo conectado, script puede hacer todo. Si no, guía manual existente funciona como fallback.
```

**Nota alternativa**: Dado que el paso es PRINCIPALMENTE manual (capturar screenshots en dispositivo real), el script DX es un nice-to-have. La guía `_runScreenshotsGuide()` ya existe y es funcional. El valor real está en:
1. Automatizar ADB capture + validate + rename
2. Limpieza de archivos legacy (eliminar `assets/images/screenshots/`)
3. Validación post-captura (`store_prep_cli.dart check`)

---

## 5️⃣ Criterios de Aceptación

| # | Criterio | Verificable |
|---|---|---|
| 1 | ✅ [DATA] 5 archivos PNG válidos en `assets/store/screenshots/` (no JPEG disfrazado) | `file step1.png` muestra "PNG image data" |
| 2 | ✅ [DATA] Cada archivo ≥1080x1920px | `dart run scripts/store_prep_cli.dart check` → screenshots ✅ |
| 3 | ✅ [DATA] Archivos nombrados step1.png..step5.png | `ls assets/store/screenshots/step*.png` |
| 4 | ✅ [CODE] `_getPngDimensionsSync()` lee dimensiones correctamente | Cuando archivos son PNG reales, check pasa |
| 5 | ✅ [CODE] Directorio legacy `assets/images/screenshots/` eliminado o vacío | No duplica archivos en check |
| 6 | ✅ [BACKEND] `store_prep_cli.dart check` reporta screenshots OK (≥5, resolución OK) | Ejecución CLI → "X screenshots OK (≥1080x1920)" |
| 7 | ✅ [FULLSTACK] Capturas reflejan flujos reales de la app (no mockups/emulador) | Inspección visual: screenshots muestran UI real |
| 8 | ✅ [FULLSTACK] Screenshot 1 = Dashboard con proyectos | Inspección visual |
| 9 | ✅ [FULLSTACK] Screenshot 2 = Creación proyecto / Script | Inspección visual |
| 10 | ✅ [FULLSTACK] Screenshot 3 = Grabación con overlay de control | Inspección visual |
| 11 | ✅ [FULLSTACK] Screenshot 4 = Revisión de clips | Inspección visual |
| 12 | ✅ [FULLSTACK] Screenshot 5 = Exportación / Performance | Inspección visual |
| 13 | ✅ [DX] Herramienta screenshot_capture.dart ejecuta sin errores | `dart run scripts/screenshot_capture.dart --help` |

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Dispositivo de prueba tiene resolución <1080x1920 | Alta | Muchos dispositivos de gama baja tienen 720x1280 o 1080x720 (landscape) | Verificar resolución del dispositivo con `adb shell wm size` antes de capturar. Usar dispositivo Pixel 6+ o iPhone 14+ para ≥1080x1920. |
| Archivos JPEG con extensión .png siguen presentes | Media | Los 5 archivos actuales son JPEG. Si se renombran sin recapturar, check sigue fallando | Eliminar todos los archivos actuales antes de recapturar. Validar con `file` command que sean PNG. |
| Grabación no se puede capturar sin permisos reales | Media | RecordingPage necesita cámara+micrófono activos para mostrar overlay completo | Usar dispositivo con permisos concedidos. Preparar proyecto con guión antes de capturar screenshot 3. |
| Duplicados en assets/images/screenshots/ influyen en check | Baja | CLI cuenta ambos directorios | Eliminar `assets/images/screenshots/` antes de validar. O modificar CLI para contar solo store dir. |
| iOS App Store rechaza screenshots de emulador | Media | Apple detecta status bar de simulator | Capturar SOLO en dispositivo real. Guía CLI ya advierte esto. |
| Nombres screenshots no coinciden con guía CLI | Baja | CLI dice `step1.png` pero no filtra por nombre específico | Renombrar a `step1.png`..`step5.png` al recapturar. Consistencia con guía. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: script captura screenshots** | `scripts/screenshot_capture.dart` | `Future<void> main(List<String> args)` con subcomandos: `capture [--device <id>]`, `validate`, `clean` | `scripts/vrm_health_check.dart` (CLI con subcomandos) | DX | Media | 2h | Ninguna | → verificar: `dart run scripts/screenshot_capture.dart --help` ejecuta sin errores |
| 1 | Eliminar screenshots JPEG actuales | `assets/store/screenshots/step*.png` | N/A (eliminación) | N/A | DATA | Baja | 0.1h | Ninguna | → verificar: `ls assets/store/screenshots/*.png` retorna vacío (solo .gitkeep) |
| 2 | Eliminar directorio legacy screenshots | `assets/images/screenshots/` | N/A (eliminación) | N/A | DATA | Baja | 0.1h | Ninguna | → verificar: `assets/images/screenshots/` no existe |
| 3 | Capturar screenshot Dashboard | `assets/store/screenshots/step1.png` | PNG válido, width≥1080, height≥1920, contenido: `DashboardPage` con proyectos | Guía clín `_runScreenshotsGuide()` | FULLSTACK | Baja | 0.3h | Dispositivo conectado con app debug | → verificar: `dart run scripts/store_prep_cli.dart check` → screenshots OK |
| 4 | Capturar screenshot Script creation | `assets/store/screenshots/step2.png` | PNG válido, width≥1080, height≥1920, contenido: `NewProjectPage` con texto en editor | Guía CLI `_runScreenshotsGuide()` | FULLSTACK | Baja | 0.3h | Tarea 3 (mismo dispositivo) | → verificar: mismo que Tarea 3 |
| 5 | Capturar screenshot Recording + overlay | `assets/store/screenshots/step3.png` | PNG válido, width≥1080, height≥1920, contenido: `RecordingPage` con overlay desplegado | Guía CLI `_runScreenshotsGuide()` | FULLSTACK | Media | 0.5h | Permisos cámara+micrófono, proyecto con guión activo | → verificar: mismo que Tarea 3 |
| 6 | Capturar screenshot Clip Review | `assets/store/screenshots/step4.png` | PNG válido, width≥1080, height≥1920, contenido: `ClipReviewPage` con video playing | Guía CLI `_runScreenshotsGuide()` | FULLSTACK | Media | 0.5h | Proyecto con clip grabado | → verificar: mismo que Tarea 3 |
| 7 | Capturar screenshot Export | `assets/store/screenshots/step5.png` | PNG válido, width≥1080, height≥1920, contenido: `RecordingEndPage` con stats y export | Guía CLI `_runScreenshotsGuide()` | FULLSTACK | Media | 0.5h | Proyecto con sesión completada | → verificar: mismo que Tarea 3 |
| 8 | Validación final store-ready | N/A | `store_prep_cli.dart check` → 11/11 checks OK | N/A | BACKEND | Baja | 0.2h | Tareas 1-7 | → verificar: `dart run scripts/store_prep_cli.dart check` → "11/11 checks" y screenshots ✅ |

**Tiempo total estimado:** 4.5 horas (2h DX + 2.5h manual/validación)

**Nota:** Tareas 3-7 son MANUALES. Requieren dispositivo físico con app instalada. No se pueden automatizar completamente sin root o instrumentación (Appium). El script DX (Tarea 0) automatiza ADB capture + validate pero requiere que el usuario ya esté en la pantalla correcta.

---

## 🔮 Roadmap (NO implementar ahora)

- **iOS-specific screenshots**: Para App Store, se necesitan captures en dispositivo iPhone (1284x2778). El script DX solo verifica ≥1080x1920. Agregar flag `--ios` que valide ≥1284x2778.
- **Automated UI navigation**: Appium o integration test que navega automáticamente a cada pantalla y captura screenshot. Reduciría captura manual a 0.
- **Screenshot diff regression**:icionar detección de cambios visuales entre versiones (pixel diff). `screenshot_capture.dart validate` podría comparar contra baseline.
- **Play Console / App Store Connect automation**: Subir screenshots automáticamente vía API. Store Prep CLI podría tener subcomando `upload`.
- **Eliminar `_existingScreenshotsDir` del CLI**: El directorio `assets/images/screenshots/` es legacy. El check solo debería mirar `assets/store/screenshots/`.