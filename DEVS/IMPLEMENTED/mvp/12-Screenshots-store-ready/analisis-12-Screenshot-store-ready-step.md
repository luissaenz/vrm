# 📋 Análisis Paso 12: Screenshots-store-ready
**Agente:** step  
**Fecha:** 2026-05-09  
**Fase:** mvp  
**Prioridad:** Alta  

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | Directorio `assets/store/screenshots/` existe | `ls assets/store/screenshots/` | ✅ | 5 archivos presentes: step1_idea.png, step2_recording.png, step3_review.png, step4_stitch.png, step5_export.png |
| 2 | Archivos PNG existen (5) | `Directory.list()` en store_prep_cli.dart:L196-198 | ✅ | step1_idea.png, step2_recording.png, step3_review.png, step4_stitch.png, step5_export.png |
| 3 | Resolución actual de screenshots | Python PIL: `Image.open(f).size` | ❌ | Todos 1024x1024 (requerido: ≥1080x1920 Android, ≥1284x2778 iOS) |
| 4 | Validación de resolución en CLI | `_validateScreenshotResolution()` en store_prep_cli.dart:L667-671 | ✅ | Chequea `width >= 1080 && height >= 1920` |
| 5 | `store_prep_cli.dart check` integrado | L220: `results['screenshots'] = screenshotCount >= 5 && resolutionOk` | ✅ | Check [5] actualmente ❌ por resolución |
| 6 | Captura en dispositivo real (no emulador) | Documentado en _runScreenshotsGuide() L673-703 | ⚠️ | NO VERIFICABLE — requiere acción manual externa |
| 7 | Guía de captura con ADB | L689-691: `adb shell screencap -p` + `adb pull` | ✅ | Comandos documentados |
| 8 | Nombres de archivo = step{N}.png | L699: "Guardar como step1.png..step5.png" | ⚠️ | Archivos actuales: step1_idea.png, step2_recording.png... (tienen sufijo descriptivo) |

**Discrepancias encontradas:**

| # | Discrepancia | Resolución propuesta |
|---|---|---|
| D1 | Archivos existen pero resolución 1024x1024 < mínimos store (1080x1920+) | **RECAPTURAR** en dispositivo real a resolución ≥1080x1920 (Android) o ≥1284x2778 (iOS). No es cuestión de upscaling — se requieren capturas nativas. |
| D2 | Nombres de archivo incluyen sufijos (`_idea`, `_recording`, etc.) en vez de `step1.png`…`step5.png` | **Renombrar** a `step1.png`, `step2.png`, `step3.png`, `step4.png`, `step5.png` para cumplir especificación store. El CLI actual no valida nombres específicos — solo cuenta `.png` — pero convención store usa nombres numéricos secuenciales. |
| D3 | Capturas actuales probablemente de emulador o screenshot de UI Flutter (no dispositivo físico) | **Verificar origen**: Capturas en dispositivo real (req del plan). Emulador puede ser rechazado por Google Play/App Store review. |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**Schema/estructura de datos:**
- No hay cambios en schema de base de datos. Paso puramente de assets gráficos.
- Archivos: 5 imágenes PNG en `assets/store/screenshots/` — assets estáticos empaquetados con app.
- No hay tablas ni migraciones afectadas.

**Integridad referencial:**
- assets/store/screenshots/ no tiene dependencias externas. Solo requerimiento: resolución mínima y formato PNG.

**Índices/validación:**
- Validación por resolución via PNG IHDR header parsing (store_prep_cli.dart:L648-671). Parseo binario directo, 0 dependencias externas.
- Chequeo robusto: lee bytes 16-23 (big-endian width/height) del header PNG. Si bytes[0-3] != 0x89 0x50 0x4E 0x47 → null (no PNG válido).

**Tipo de datos problemáticos:**
- Ninguno. PNG es formato fijo.

---

## 2️⃣ Análisis de Código (ETAPA 2)

**Archivos directamente relacionados:**

1. `scripts/store_prep_cli.dart` (703L) — CLI principal
   - Función `_validateScreenshotResolution(String path)` → bool (L667-671)
     - Input: ruta absoluta a PNG
     - Output: `true` si `width >= 1080 && height >= 1920`
     - Importa: `dart:io` (`File`, `Directory`), `dart:convert` (no usado), `dart:math` (no usado en esta fn)
   - Función `_getPngDimensionsSync(String path)` → `(width, height)?` (L648-665)
     - Lee archivo binario, verifica firma PNG (0x89 0x50 0x4E 0x47), extrae dims de bytes 16-19 (width) y 20-23 (height)
     - No maneja endianness beyond big-endian (PNG estándar, correcto)
     - Retorna `null` si archivo muy pequeño o no PNG
   - Patrón: validación sincrónica (readAsBytesSync) dentro de loop asíncrono (L200-218) — aceptable para 5 archivos pequeños.

2. `assets/store/screenshots/{step1..5}.png` — assets estáticos
   - Actualmente: 1024x1024 cada uno.
   - Formato: PNG (comprimido). No metadatos EXIF relevantes.

**Patrones existentes que se deben seguir:**
- Ninguno específico para captura — es tarea manual.
- Convención de nombres: `step{N}.png` (L699). Archivos actuales usan `stepN_desc.png`. **Inconsistencia** → renombrar.

**Imports correctos:**
- store_prep_cli.dart solo usa `dart:io`, `dart:math` (declarado pero no usado en screenshot validation). Sin imports externos.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**APIs/Endpoints:**
- No hay APIs involucradas. Assets estáticos empaquetados con APK/AAB.

**Middleware:**
- No aplica.

**Flujos:**
- Flujo simple:
  1. Dispositivo físico con app en modo debug/release
  2. Navegación manual a 5 pantallas
  3. Captura pantalla via `adb shell screencap -p` o gesto nativo del OS
  4. Transferencia a PC: `adb pull` o USB MTP
  5. Copia a `assets/store/screenshots/`
  6. Validación: `dart run scripts/store_prep_cli.dart check`
  7. Si resolución <1080x1920 → recapturar
  8. Si OK → proseguir a build store

**Contratos:**
- No hay contratos programáticos. Es activo manual.

**Error handling:**
- store_prep_cli detecta archivos faltantes (<5) o resolución insuficiente → imprime mensaje específico + `exitCode = 1`.
- Mensajes claros: "Resolución insuficiente: step1_idea.png, ..." (L224) y "Recapturar en dispositivo real a resolución ≥1080x1920" (L235).

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

**Flujo completo:**
- El paso NO es código. Es contenido gráfico (screenshots) necesario para store listing.
- **Flujo manual:**
  - Usuario (desarrollador) → conecta dispositivo físico → compila app `flutter run` → navega 5 pantallas → captura → transfiere → copia a directorio → ejecuta `store_prep_cli.dart check` → verifica ✅ → continúa build.
- No hay backend involvement.

**Coherencia end-to-end:**
- Screenshots representan fielmente las 5 pantallas clave del flujo MVP: Dashboard → Creación/Script → Grabación → Revisión → Exportación.
- **Alineación con arquitectura:** Las pantallas existen en código:
  - Dashboard: `lib/features/dashboard/dashboard_page.dart`
  - Creación/Script: `lib/features/new_project/new_project_page.dart` o `script_studio_page.dart`
  - Grabación: `lib/features/recording/recording_page.dart`
  - Revisión: `lib/features/recording/clip_review_page.dart`
  - Exportación/Performance: `lib/features/recording/recording_end_page.dart`
- **UX coherencia:** Los screenshots reflejan flujo real I→G→R→U→E. Correcto.

**Gaps / fricción:**
- **Captura manual es lenta y propensa a error.** No hay automatización posible debido a que requiere interacción UI en dispositivo real.
- **Resolución:** screenshots actuales 1024x1024 probablemente capturados en emulador o via Flutter screenshot tool (que captura widget tree, no pantalla nativa a resolución hardware). Se necesitan capturas *reales* de dispositivo.
- **Validación post-hoc:** store_prep_cli detecta resolución insuficiente **después** de copiar archivos. No previene captures inválidas en el momento.

**DX & Tooling — Propuesta concreta:**

### Herramienta Propuesta: `capture_store_screenshots.dart`
- **Qué automatiza:** Guía interactiva paso-a-paso para capturar screenshots store-ready **directamente en dispositivo físico**, eliminando necesidad de ADB/transferencia manual. Automatiza:
  1. Verificar que dispositivo esté conectado y app en modo debug
  2. Navegar automáticamente (via deep links) a cada pantalla en orden
  3. Esperar a que pantalla esté estable (chequeo de frames)
  4. Disparar captura nativa via platform channel (`MethodChannel('com.vrm.vrm_app/screenshot')`) que ejecuta `MediaProjection` en Android y `UIGraphics` en iOS
  5. Guardar PNG automáticamente en resolución nativa del dispositivo (≥1080x1920) a carpeta app docs
  6. Sincronizar a PC si conectado (pull automático via ADB)
- **Tipo:** CLI script + plugin nativo (MethodChannel para captura de pantalla in-app)
- **Cómo se usa:**
  ```bash
  dart run scripts/capture_store_screenshots.dart --interactive
  # O no-interactivo (auto-captura en orden):
  dart run scripts/capture_store_screenshots.dart --auto
  ```
- **Impacto para el usuario final (desarrollador):**
  - Reduce 20-30 min de captura manual + transferencia USB a ~2 min automatic.
  - Elimina errores de resolución incorrecta (captura a resolución nativa del dispositivo).
  - Asegura nombres correctos (`step1.png`–`step5.png`) automáticamente.
  - Verifica instantly con `store_prep_cli.dart check` al final.
- **Prioridad:** **Tarea 0** — implementar antes que recaptura manual. Justificación: Si el desarrollador recaptura manual, igual debe ejecutar CLI para verificar. Automatizar captura previene repetición de trabajo y garantiza consistencia.
- **Complejidad:** Media-Alta (requiere handler nativo en Android/iOS para captura programática de pantalla full-device, no solo widget). Workaround: si no se puede captura automática vía plugin, al menos guiar con Deep Links y espera de pantallas, captura externa via ADB wrapper.

**Nota:** Actualmente store_prep_cli solo valida, no captura. Herramienta propuesta cierra el gap completo.

---

## 5️⃣ Criterios de Aceptación

✅ [DATA] 5 archivos PNG presentes en `assets/store/screenshots/`  
✅ [CODE] Archivos con nombres `step1.png`, `step2.png`, `step3.png`, `step4.png`, `step5.png` (o sufijos permitidos)  
✅ [CODE] Resolución ≥1080x1920px (Android) o ≥1284x2778px (iOS) detectada vía IHDR header parsing  
✅ [BACKEND] No aplica — no APIs  
✅ [FULLSTACK] Cada screenshot representa fielmente pantalla real del flujo: Dashboard, Creación/Script, Grabación, Revisión, Exportación  
✅ [FULLSTACK] Capturas originadas en dispositivo físico (no emulador) — declaración manual, no detectable automáticamente  
✅ [DX] `dart run scripts/store_prep_cli.dart check` reporta `screenshots: true` en JSON y ✅ en pantalla  
⚠️ [DX] Herramienta `capture_store_screenshots.dart` ejecuta sin errores y genera screenshots válidos (Opcional — propuesta mejora DX)  

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Desarrollador no tiene dispositivo físico disponible | Media | Muchos trabajan solo con emulador | Documentar claramente: Google Play/App Store **rechazan** screenshots de emulador. Proporcionar guía para captura en dispositivo real (ADB o manual USB). Considerar device lab compartido. |
| Recaptura manual → nombres incorrectos o resolución inconsistentes | Baja | Errores humanos en renombrado/redimensionado | Renombrar archivos existentes a step1.png..step5.png (simple). Validar con `store_prep_cli.dart check` antes de commit. |
| screenshots 1024x1024 son únicas copias (p. ej. diseño único irreversible) | Baja | Se pierde trabajo de diseño si se borran sin backup | **NO BORRAR** archivos actuales. Mover a `assets/store/screenshots/legacy/` como backup. Generar nuevas capturas. |
| store_prep_cli validation solo verifica dimensión, no que screenshot sea "store-quality" (sin bloques de desarrollo, sin overlays de debug) | Media | CLI no analiza contenido visual | Agregar validación opcional en CLI que detecte elementos de debug (banner "Debug", overlay de performance) si se quiere máxima calidad. Para MVP basta dimensión. |
| Diferencia de aspect ratio entre dispositivos (Android vs iOS) → screenshots no universales | Baja | Android: 16:9 típico; iOS: 19.5:9 (iPhone moderno) | Capturar en dispositivo que represente mejor ambos (iPhone para iOS, Android flagship para Android). Stores permiten múltiples screenshots por dispositivo. Para MVP, 1 set único es aceptable. |

---

## 7️⃣ Plan de Implementación

**Tiempo total estimado:** 0.5h (manual) + 2h (herramienta DX opcional) = **2.5h**

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX & Tooling: `capture_store_screenshots.dart` (opcional) | `scripts/capture_store_screenshots.dart` | `Future<void> main(List<String> args)` con flags `--interactive`, `--auto`, `--output-dir` | Sigue patrón `store_prep_cli.dart` (estructura CLI con subcomandos) | DX | Alta | 2h | Ninguna | → verificar: `dart run scripts/capture_store_screenshots.dart --help` imprime guía sin error |
| 1 | Renombrar screenshots existentes a convención store | `assets/store/screenshots/` | — | — | FULLSTACK | Baja | 0.1h | Ninguna | → verificar: 5 archivos llamados step1.png…step5.png presentes |
| 2 | Capturar screenshots en dispositivo real (Android) | `assets/store/screenshots/` (fuente: captura nativa) | — | Guía store_prep_cli L673-703 | FULLSTACK | Manual | 0.3h | Tarea 1 | → verificar: `store_prep_cli.dart check` muestra ✅ screenshots con resolución ≥1080x1920 |
| 3 | Validación final store-ready | `scripts/store_prep_cli.dart` (check) | — | — | DX | Baja | 0.1h | Tarea 2 | → verificar: `dart run scripts/store_prep_cli.dart check` reporta JSON `"screenshots": true` y pantalla ✅ |

**Notas:**
- Tarea 2 es manual, requiere dispositivo físico. Tarea 0 (herramienta DX) es **recomendada como Tarea 0** para evitar captura manual en futuras iteraciones y garantizar consistencia.
- Si se implementa Tarea 0, el orden ejecución: 0 → 2 → 3. Si no, 1 → 2 → 3.
- **No** se puede upscale artificialmente screenshots existentes — stores requieren capturas de dispositivo real (no emulador, no screenshots de emulación).
- Resolución mínima **absoluta**: 1080x1920 (Android 16:9 portrait). iOS recomienda 1284x2778 (iPhone 12+). Para MVP, cumplir 1080x1920 es suficiente para ambos (se escalará en store UI).
- Archivos legacy (1024x1024) mover a `assets/store/screenshots/legacy/` como backup antes de reemplazar.

---

## 8️⃣ Suposiciones no verificadas

⚠️ **ASUNCIÓN:** Capturas en dispositivo real producirán imágenes ≥1080x1920.  
| Justificación: Cualquier smartphone Android mínimo (720p) con captura nativa via screencap entrega resolución nativa de pantalla, típicamente 1080x1920 o superior. iPhone modernos >1284x2778.  
| Riesgo: Dispositivo muy antiguo (480x800) no cumpliría. Mitigación: Usar dispositivo de testing ≥ Android 8 / iPhone X.

⚠️ **ASUNCIÓN:** Desarrollador ejecutará `store_prep_cli.dart check` después de capturar.  
| Justificación: Es flujo estándar documentado en fase mvp. No hay automatización de gating en CI para esto (no aplica para assets gráficos).  
| Riesgo: Olvidar validación → screenshots inválidas entran a repo. Mitigación: Agregar pre-commit hook que ejecute `store_prep_cli check` si screenshots cambiaron.

---

## 📊 Resumen Ejecutivo

- **Estado actual:** 5 screenshots presentes pero resolución 1024x1024 < mínimos store (❌ check falla).
- **Root cause:** Capturas anteriores probablemente de emulador/widget screenshot, no dispositivo físico a resolución full.
- **Acción inmediata:** Recapturar en dispositivo real a ≥1080x1920 (portrait). Renombrar a step1.png..step5.png.
- **Herramienta DX sugerida:** `capture_store_screenshots.dart` automatiza navegación + captura nativa via MethodChannel (Android/iOS handlers). Prioridad **Tarea 0** para evitar repetición manual.
- **Validación:** `store_prep_cli.dart check` ya detecta resolución insuficiente (check 5). No requiere cambios.
- **Riesgo principal:** desarrollador sin dispositivo físico. Mitigar: documentar alternativa (device lab, préstamo).

---

**Caveman out.**
