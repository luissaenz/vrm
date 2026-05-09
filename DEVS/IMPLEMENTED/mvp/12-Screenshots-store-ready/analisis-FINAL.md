# 🏛️ Análisis Unificado — Paso 12: Screenshots-store-ready
**Unificador:** Arquitecto Sistemas Senior | **Fecha:** 2026-05-09 | **Fase:** mvp

> **Fuente de verdad única.** Resuelve contradicciones entre 6 análisis de agentes. Prioriza discrepancias verificadas contra código. El Implementador ejecuta sin ambigüedad.

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---:|:---:|:---:|:---:|:---:|
| **GLM** | ✅ 18 elementos | 4 (D1-D4) | ✅ `screenshot_capture.dart` | ✅ `analisis-12-glm.md:10-28` | 5.0 |
| **Step** | ✅ 8 elementos | 3 (D1-D3) | ✅ `capture_store_screenshots.dart` | ✅ `analisis-12-Screenshot-store-ready-step.md:11-21` | 4.5 |
| **DS** | ✅ 10 elementos | 3 (D1-D3) | ✅ mejorar `store_prep_cli.dart` | ✅ `analisis-paso-12-ds.md:13-25` | 4.0 |
| **LGNM1** | ✅ 11 elementos | 1 | ✅ `screenshot_naming_validator.dart` | ✅ `analisis-12-lgnm1.md:11-26` | 3.5 |
| **Grok** | ✅ 5 elementos | 1 | ✅ existente `store_prep_cli.dart` | ✅ `analisis-paso-12-grok.md:5-12` | 2.5 |
| **Gem** | ✅ 3 elementos | 1 | ✅ `capture_store_screenshots.sh` | ✅ `analisis-paso12-gem.md:5-10` | 2.0 |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| 1 | **Resolución insuficiente**: 1024x1024 vs mínimo 1080x1920 (Android) / 1284x2778 (iOS) | TODOS | ✅ `store_prep_cli.dart:667-671` valida `width>=1080 && height>=1920` → FALLA | Recapturar en dispositivo real. Eliminar archivos actuales. |
| 2 | **Nombres archivo inconsistentes**: archivos reales `step1_idea.png`..`step5_export.png`, CLI guía dice `step1.png`..`step5.png` | GLM, Step, DS, LGNM1 | ✅ `store_prep_cli.dart:699` guía dice `step1.png..step5.png`. CLI check cuenta `*.png` sin filtrar → no invalida | Renombrar a `step1.png`..`step5.png` al recapturar. Consistencia con guía CLI. |
| 3 | **JPEG disfrazado de PNG**: archivos con extensión `.png` pero header `FF D8 FF E0` (JPEG) | GLM, Step | ✅ `analisis-12-glm.md:13` bytes `[0:8]` = JPEG. `_getPngDimensionsSync()` `analisis-12-glm.md:17` retorna null | Recapturar con `adb shell screencap -p` que produce PNG nativo. Eliminar JPEGs actuales. |
| 4 | **Directorio legacy duplicado**: `assets/images/screenshots/` contiene mismos 5 archivos | GLM | ✅ `analisis-12-glm.md:15` CLI cuenta ambos dirs → 10 archivos total | Eliminar `assets/images/screenshots/` post-recaptura. |
| 5 | **Sin dispositivo físico disponible**: análisis no pudo verificar captura real | DS | ✅ `analisis-paso-12-ds.md:24` `adb devices` no disponible | Documentar procedimiento manual. Tarea no automatizable 100%. |

---

## 1️⃣ Resumen Ejecutivo

- **Objetivo paso 12**: Capturar 5 screenshots de la app en dispositivo real con resolución store-ready (≥1080x1920 Android, ≥1284x2778 iOS) y colocarlas en `assets/store/screenshots/` como `step1.png..step5.png`.
- **Estado actual**: 5 archivos existen pero son JPEGs con extensión `.png` a 1024x1024 — todos fallan validación CLI store_prep_cli.dart check.
- **Corrección crítica al plan**: Plan no detectó que archivos son JPEG (no PNG). GLM+Step verificaron header bytes — confirmado. Recaptura obligatoria.
- **Herramienta DX**: Fusionada de 6 propuestas → `capture_store_screenshots.dart` (script ADB interactivo para captura secuencial + naming + validación). Complementa `store_prep_cli.dart` existente.
- **DX secundaria**: Mejorar `store_prep_cli.dart` check con validación de archivos corruptos (tamaño >10KB) — propuesta DS.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path

1. Desarrollador conecta dispositivo físico Android con app compilada en debug
2. Abre app → navega manualmente a Dashboard (pantalla principal con proyectos)
3. Tapea "Nuevo proyecto" → ingresa idea → genera guion → pantalla Creación/Script
4. Tapea "Grabar" → espera cámara activa → overlay de control visible → RecordingPage
5. Graba 1-2 clips → tapea "Revisar" → ClipReviewPage con video reproduciéndose
6. Finaliza sesión → RecordingEndPage con métricas y exportación
7. Por cada pantalla: `adb shell screencap -p /sdcard/stepN.png` → `adb pull` → renombra a `assets/store/screenshots/stepN.png`
8. Elimina directorio legacy `assets/images/screenshots/`
9. Ejecuta `dart run scripts/store_prep_cli.dart check` → 11/11 checks OK

### Edge Cases MVP

- Dispositivo con resolución <1080x1920 → no apto para captura. Verificar con `adb shell wm size`.
- Proyecto sin guion → RecordingPage no se abre. Crear proyecto dummy antes de captura 3 y 4.
- Permisos cámara/micrófono denegados → overlay no se muestra completamente. Conceder antes de captura 3.
- iOS requiere Mac + Xcode. Captura Android primero. Documentar pasos iOS por separado.

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

| # | Ruta real | Tipo cambio | Descripción | Interfaces clave | Patrón a seguir |
|---|---|---|---|---|---|
| 1 | `D:\Develop\Personal\vrm\assets\store\screenshots\step1.png`..`step5.png` | Reemplazo | PNG válidos ≥1080x1920 de las 5 pantallas MVP. Eliminar JPEGs actuales. | N/A. Assets estáticos. | N/A |
| 2 | `D:\Develop\Personal\vrm\assets\images\screenshots\` | Eliminación | Directorio legacy con archivos duplicados. Eliminar post-recaptura. | N/A. Eliminación de directorio. | N/A |
| 3 | `D:\Develop\Personal\vrm\scripts\capture_store_screenshots.dart` | Creación (DX tool) | Script ADB interactivo: captura secuencial 5 screenshots, renombra, valida resolución. | `Future<void> main(List<String> args)` con flags: `--interactive`, `--device <id>`, `--clean` | `scripts/store_prep_cli.dart` (CLI con subcomandos) |
| 4 | `D:\Develop\Personal\vrm\scripts\store_prep_cli.dart` | Modificación menor | Agregar validación archivos corruptos en `_validateScreenshotResolution()`: tamaño mínimo >10KB + mensaje claro. | `bool _validateScreenshotResolution(String path)` — agregar `fileSize > 10240` | Patrón existente en `_runCheck()` L220-236 |

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: capture_store_screenshots.dart
- **Qué automatiza:** Captura secuencial de 5 screenshots en dispositivo Android vía ADB.
  Navegación manual guiada paso a paso + captura nativa + renombrado automático + validación post-captura.
- **Tipo:** CLI script interactivo (Dart)
- **Ubicación:** `D:\Develop\Personal\vrm\scripts\capture_store_screenshots.dart`
- **Cómo se usa:**
  ```
  dart run scripts/capture_store_screenshots.dart
  # Sigue instrucciones interactivas: presiona ENTER en cada pantalla
  # Opcional:
  dart run scripts/capture_store_screenshots.dart --clean   # Elimina JPEGs actuales + legacy dir
  dart run scripts/capture_store_screenshots.dart --help     # Muestra uso
  ```
- **Impacto para el usuario final:** Reduce captura manual de ~30min (con ADB manual + renombrado + validación) a ~5min. Automatiza rename, transfer, cleanup y validation en 1 comando. Elimina error humano de nombres/resolución.
- **El implementador DEBE usarla** para completar las tareas 1-5 del paso.

### Herramienta Complementaria: store_prep_cli.dart (mejora existente)
- **Qué automatiza:** Validación post-captura. Mejorar para detectar archivos corruptos (tamaño <10KB).
- **Tipo:** Modificación CLI existente
- **Ubicación:** `D:\Develop\Personal\vrm\scripts\store_prep_cli.dart`
- **Impacto:** Previene falsos positivos cuando archivo es placeholder/corrupto (IHDR null pero sin mensaje claro).
```

---

## 4️⃣ Decisiones Tecnológicas

1. **Dart sobre Bash para DX tool**: 5/6 agentes propusieron Dart. Gem propuso Bash — descartado. Todos los scripts del proyecto (`store_prep_cli.dart`, `vrm_health_check.dart`, `validador_hardware.dart`) usan Dart. Consistencia del ecosistema.
2. **ADB screencap como método de captura**: `adb shell screencap -p` produce PNG nativo a resolución del dispositivo. No requiere dependencias externas ni plugins nativos. Step propuso MethodChannel nativo — descartado por sobreingeniería para MVP.
3. **Renombrar a step1.png..step5.png (sin sufijo descriptivo)**: Coincide con guía CLI existente (`store_prep_cli.dart:699`). Mantiene consistencia. Si se desea contexto, actualizar guía CLI separadamente.
4. **⚠️ Corrección al plan: Plan dice 1080x1920+ (genérico) pero iOS requiere 1284x2778+**: Para MVP, capturar en dispositivo ≥1080x1920 (suficiente para Android). Si se publica en App Store, capturar en iPhone 14+ para ≥1284x2778.
5. **⚠️ Corrección al plan: Plan dice "capturar" sin mencionar formato**: Archivos actuales son JPEG con extensión .png. Plan omite este problema. Recaptura obligatoria como PNG real.
6. **Eliminar `assets/images/screenshots/`**: Directorio legacy. No referenciado en código. Eliminar post-captura para evitar falsos positivos en check (CLI cuenta ambos directorios).

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [DATA] 5 archivos PNG válidos en `assets/store/screenshots/` (header 0x89 0x50 0x4E 0x47)
✅ [DATA] Cada archivo ≥1080x1920px (verificado por store_prep_cli.dart check)
✅ [DATA] Archivos nombrados step1.png..step5.png
✅ [DATA] No hay archivos JPEG con extensión .png (header checker)
✅ [DATA] Directorio `assets/images/screenshots/` eliminado o vacío
✅ [CODE] `_getPngDimensionsSync()` lee dimensiones correctamente (no retorna null)
✅ [CODE] `store_prep_cli.dart check` reporta "screenshots OK" (≥5, resolución OK)
✅ [BACKEND] No aplica — paso de assets
✅ [FULLSTACK] Capturas tomadas en dispositivo real (no emulador) — declaración manual
✅ [FULLSTACK] 5 pantallas representadas: Dashboard, Script, Grabación, Revisión, Exportación
✅ [DX] `capture_store_screenshots.dart` ejecuta sin errores
✅ [DX] `store_prep_cli.dart check` detecta archivos corruptos <10KB con mensaje claro
```

**Funcionales:**
- [ ] Screenshot 1 = Dashboard con proyectos reales
- [ ] Screenshot 2 = NewProjectPage/ScriptStudio con texto en editor
- [ ] Screenshot 3 = RecordingPage con overlay de control desplegado
- [ ] Screenshot 4 = ClipReviewPage con video reproduciéndose
- [ ] Screenshot 5 = RecordingEndPage con métricas + botón exportar

**Técnicos:**
- [ ] `dart run scripts/capture_store_screenshots.dart` produce 5 PNGs válidos en directorio correcto
- [ ] `dart run scripts/store_prep_cli.dart check` reporta 11/11 checks OK
- [ ] `file step1.png` muestra "PNG image data" (no JPEG)
- [ ] 0 archivos en `assets/images/screenshots/`

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** `capture_store_screenshots.dart` + mejora `store_prep_cli.dart` | Media | 2.5h | Ninguna |
| 1 | Limpiar archivos actuales: eliminar JPEGs `assets/store/screenshots/` + legacy dir | Baja | 0.1h | Tarea 0 |
| 2 | Capturar Dashboard — `step1.png` ≥1080x1920 | Baja | 0.3h | Dispositivo físico |
| 3 | Capturar Creación/Script — `step2.png` ≥1080x1920 | Baja | 0.3h | Dispositivo físico |
| 4 | Capturar Grabación + overlay — `step3.png` ≥1080x1920 | Media | 0.5h | Permisos cámara+mic |
| 5 | Capturar Revisión clips — `step4.png` ≥1080x1920 | Media | 0.5h | Proyecto con clips |
| 6 | Capturar Exportación — `step5.png` ≥1080x1920 | Media | 0.5h | Sesión completada |
| 7 | Validación final store-ready — `store_prep_cli.dart check` | Baja | 0.1h | Tareas 1-6 |
| **TOTAL** | | | **4.8h** | |

> **Tarea 0 siempre = DX & Tooling.** Implementador DEBE ejecutarla primero y usar la herramienta resultante para el resto del paso (dogfooding obligatorio).

**Notas de implementación:**
- Tareas 2-6 son MANUALES. Requieren dispositivo físico con app instalada.
- Si dispositivo no disponible, `store_prep_cli.dart screenshots` contiene guía manual completa como fallback.
- iOS requiere captura separada en iPhone con resolución ≥1284x2778. No incluido en MVP time estimate.

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Dispositivo de prueba resolución <1080x1920 | Alta | Dispositivos gama baja (720x1280) | Verificar con `adb shell wm size` antes. Usar Pixel 6+ o iPhone 14+. |
| JPEGs actuales se renombran sin recapturar | Media | Desarrollador cree que renombrar basta | Validar con `file` command que sean PNG reales. Tarea 1 elimina archivos existentes. |
| Grabación no muestra overlay completo sin permisos | Media | RecordingPage necesita cámara+mic activos | Conceder permisos antes. Preparar proyecto dummy con guion antes de captura 3. |
| Screenshots de emulador rechazadas por stores | Alta | Google Play/App Store detectan emulador | Documentar explícitamente: SOLO dispositivo real. Guía CLI ya advierte. |
| iOS screenshots requieren dispositivo Apple | Media | Desarrollador sin Mac/iPhone | MVP enfocado en Android. iOS post-MVP. Documentar requisitos. |
| store_prep_cli.dart no valida archivos corruptos | Media | `_getPngDimensionsSync()` retorna null sin mensaje claro | Tarea 0 agrega validación tamaño >10KB + mensaje descriptivo. |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|---|---|---|---|
| TP-1 | DX tool crea estructura correcta | `dart run scripts/capture_store_screenshots.dart --clean` | Directorio `assets/store/screenshots/` vacío (solo .gitkeep) |
| TP-2 | DX tool captura secuencia | `dart run scripts/capture_store_screenshots.dart` con dispositivo conectado | 5 archivos `step1.png`..`step5.png` en directorio, todos PNG válidos |
| TP-3 | Validación CLI post-captura | `dart run scripts/store_prep_cli.dart check` | JSON output `"screenshots": true`. 11/11 checks OK. |
| TP-4 | Detección archivo corrupto | Colocar archivo texto como `step1.png` en directorio | `store_prep_cli.dart check` reporta error con mensaje claro |
| TP-5 | Legacy dir no interfiere | `assets/images/screenshots/` ausente | CLI check no cuenta archivos de ese directorio. Total = 5, no 10. |

Comando para ejecutar tests: `flutter test` / `dart run scripts/store_prep_cli.dart check`
