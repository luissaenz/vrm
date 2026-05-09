# Análisis Técnico — Paso 12: Screenshots-store-ready

**Agente:** ds
**Fecha:** 2026-05-09
**Fase:** mvp
**Prioridad:** Alta
**Origen:** Sugerencia 🔵 (escalado) de validación — Paso 04

---

## 0 Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `assets/store/screenshots/` existe | `Get-ChildItem` en directorio | ✅ | 6 entradas: `.gitkeep`, `step1_idea.png`...`step5_export.png` |
| 2 | 5 archivos PNG en directorio | `ls *.png` | ✅ | step1..step5 existen (nombres con sufijo descriptivo) |
| 3 | Resolución ≥1080x1920 | PNG IHDR header parsing | ❌ | Todos: 0x135 (ancho 0 — archivos corruptos o no-PNG reales) |
| 4 | Nombres correctos (`step1.png`..`step5.png`) | Plan especifica `step{N}.png` | ❌ | Archivos reales: `step1_idea.png`, `step2_recording.png`, `step3_review.png`, `step4_stitch.png`, `step5_export.png` |
| 5 | `store_prep_cli.dart check` reporta screenshots OK | Código L188-236 | ❌ | Validación `_validateScreenshotResolution()` width≥1080 && height≥1920 → FALLA (0x135) |
| 6 | `store_prep_cli.dart screenshots` guía existe | Código L673-703 | ✅ | Guía completa con pasos ADB y validación |
| 7 | Dispositivo físico conectado | `adb devices` | ❌ | ADB no disponible en entorno de análisis |
| 8 | `_validateScreenshotResolution()` existe | Código L667-671 | ✅ | Lee PNG IHDR header, verifica ≥1080x1920 |
| 9 | `_getPngDimensionsSync()` existe | Código L648-665 | ✅ | Parseo PNG header nativo, 0 dependencias externas |
| 10 | Screenshots en `assets/images/screenshots/` | Directorio existe | ⚠️ | Directorio existe pero sin archivos PNG (solo placeholders) |

### Discrepancias encontradas

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | **Screenshots corruptas/resolución 0x135**: Los 5 PNGs existentes no son imágenes reales válidas (IHDR reporta ancho=0). Probablemente archivos placeholder generados durante scaffolding. | Reemplazar con capturas reales desde dispositivo físico. |
| D2 | **Nombres de archivo incorrectos**: Plan especifica `step1.png`..`step5.png`. Archivos reales tienen sufijos descriptivos (`step1_idea.png`). | store_prep_cli.dart referencia nombres sin sufijo. Ambos formatos son funcionales para stores — pero hay inconsistencia. Decisión: mantener nombres con sufijo descriptivo (mejor DX), actualizar guía CLI. |
| D3 | **Sin dispositivo físico disponible**: Análisis ejecutado sin ADB/device. Captura real requiere paso manual post-análisis. | Documentar procedimiento exacto. Tarea no automatizable 100%. |

---

## 1 Análisis de Datos

**No aplica.** Paso 12 no crea/modifica tablas, schemas, migraciones ni modelos de datos. No hay capa de persistencia involucrada.

### Impacto en datos existentes
- Ninguno. Las screenshots son assets estáticos fuera del flujo de datos de la app.

### Schema de assets
```
assets/store/screenshots/
  step1_dashboard.png      ← Dashboard (pantalla principal)
  step2_script.png         ← Creación de proyecto / Script
  step3_recording.png      ← Grabación con overlay de control
  step4_review.png         ← Revisión de clips
  step5_export.png         ← Exportación / Performance
```

---

## 2 Análisis de Código

### Archivos afectados

| Archivo | Tipo | Acción |
|---|---|---|
| `assets/store/screenshots/step{1-5}_*.png` | Asset | **Reemplazar** — archivos existentes corruptos/placeholder |
| `scripts/store_prep_cli.dart` | CLI existente | **Modificar** — actualizar nombres de archivo en guía y checks si se cambia naming convention |
| `pubspec.yaml` (assets section) | Config | **Verificar** — que `assets/store/screenshots/` esté incluido |

### Patrón a seguir
El paso sigue el patrón de **assets store-ready** ya establecido en Paso 04:
- `store_prep_cli.dart check` como validador (L188-236)
- `store_prep_cli.dart screenshots` como guía (L673-703)
- Validación de resolución vía PNG IHDR header (L648-671)

No se crean funciones, clases ni servicios nuevos. Es un paso puramente de assets + validación.

### pubspec.yaml — verificación de assets
```yaml
# Buscar si assets/store/screenshots/ está declarado
```

---

## 3 Análisis de Backend

**No aplica.** Paso 12 no crea/modifica endpoints, middleware, flujos entre servicios ni contratos API. No hay capa backend involucrada.

---

## 4 Análisis de Fullstack + DX

### Flujo completo
```
Dispositivo físico → App compilada (debug) → Navegación 5 pantallas → Captura nativa → Transferencia a assets/ → Validación CLI
```

### Pantallas a capturar (orden secuencial)

| # | Pantalla | Ruta en app | Contenido clave |
|---|---|---|---|
| 1 | Dashboard | `/dashboard` | Tarjetas de proyecto, navegación inferior, greeting |
| 2 | Creación proyecto / Script | `/new-project` o `/script-studio` | Input idea, generación guion, segmentos |
| 3 | Grabación con overlay | `/recording` | Cámara activa, overlay con grilla/teleprompter/controles |
| 4 | Revisión de clips | `/clip-review` | Video player, accept/reject, barra progreso |
| 5 | Exportación / Performance | `/recording-end` | Métricas sesión, progreso, botón exportar |

### Coherencia end-to-end
- ✅ Las 5 pantallas existen y son funcionales (verificado en phase-state.md §2)
- ✅ store_prep_cli.dart ya valida resolución mínima vía PNG IHDR header
- ✅ Guía CLI explica pasos exactos para captura ADB
- ⚠️ Sin dispositivo físico, el paso no puede completarse completamente

### Gaps y ambigüedades

| Gap | Detalle | Resolución |
|---|---|---|
| G1 | Paso requiere dispositivo físico pero no especifica SO objetivo | Capturar Android primero (más accesible). iOS requiere Mac + Xcode. Documentar ambos. |
| G2 | No especifica landscape vs portrait | Stores requieren ambas. MVP: portrait (la app es portrait-first). |
| G3 | No especifica si las capturas deben incluir datos reales o mock | Usar datos reales de proyecto de prueba (más creíble para stores). |

### DX & Tooling

```
### Herramienta Propuesta: store_prep_cli.dart screenshots (existente — mejorar)
- **Qué automatiza:** Guía interactiva + validación de resolución. Ya existe pero necesita:
  a) Actualizar nombres de archivo de referencia si se cambia naming
  b) Agregar validación de que los PNGs no son placeholder/corruptos (checksum mínimo >10KB)
- **Tipo:** CLI (Dart) — ya implementado en Paso 04
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart screenshots` + `dart run scripts/store_prep_cli.dart check`
- **Impacto para usuario final:** Reduce el paso de "tomar 5 capturas manualmente y esperar revisión" a "seguir 5 comandos y validar en 1 comando"
- **Prioridad:** Tarea 0 — mejorar validación existente antes de capturar
```

---

## 5 Criterios de Aceptación

```
✅ [ASSET] 5 archivos PNG en `assets/store/screenshots/` con nombres step{1-5}_*.png
✅ [ASSET] Cada PNG tiene resolución ≥1080x1920 (verificado por store_prep_cli.dart check)
✅ [ASSET] Cada PNG es un archivo de imagen válido (PNG magic bytes + header IHDR correcto, tamaño >10KB)
✅ [ASSET] No hay archivos placeholder/corruptos (0x135 o dimensiones 0)
✅ [DX] `dart run scripts/store_prep_cli.dart check` reporta "5 screenshots OK (≥1080x1920)"
✅ [DX] `dart run scripts/store_prep_cli.dart check` NO reporta errores de resolución
✅ [FULLSTACK] Captura tomada en dispositivo físico (no emulador) — verificado por metadatos o declaración manual
✅ [FULLSTACK] Las 5 pantallas funcionales del MVP están representadas: Dashboard, Script, Grabación, Revisión, Exportación
```

---

## 6 Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Capturas en emulador rechazadas por stores | Alta | Store requiere capturas en dispositivo real | Documentar explícitamente que emulador no es aceptable. Usar `store_prep_cli.dart check` sin flag de emulador. |
| Resolución insuficiente para iOS (1284x2778+) | Media | Paso solo especifica Android 1080x1920+ | Validación actual solo checkea ≥1080x1920. iOS requiere umbral diferente. Agregar detección de plataforma o documentar doble captura. |
| Captura con overlay de sistema (barra estado, notch) | Baja | Screenshots nativas siempre incluyen UI del sistema | Aceptable para stores — es estándar. No recortar. |
| Screenshots existentes no reemplazables post-análisis | Baja | Análisis no tiene dispositivo físico | Documentación + guía CLI suficiente. Implementador sigue pasos. |
| store_prep_cli.dart no valida archivos corruptos | Media | `_getPngDimensionsSync()` retorna null para archivos inválidos pero no hay check de tamaño mínimo | Agregar validación de tamaño mínimo de archivo (>10KB) en el check. |

---

## 7 Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: Mejorar validación screenshots en CLI** | `scripts/store_prep_cli.dart` L648-671 | `_getPngDimensionsSync()` — agregar check `fileSize > 10240` (10KB). `_validateScreenshotResolution()` — mismo comportamiento pero reporta archivos corruptos con mensaje claro. | Patrón existente en `_runCheck()` L220-236 | DX | Baja | 0.25h | Ninguna | → verificar: `dart run scripts/store_prep_cli.dart assets validate` rechaza PNG corrupto <10KB |
| 1 | Capturar Dashboard | Dispositivo físico + `adb shell screencap` | `assets/store/screenshots/step1_dashboard.png` ≥1080x1920 | Guía `store_prep_cli.dart screenshots` | ASSET | Media | 0.25h | Tarea 0, dispositivo físico | → verificar: `dart run scripts/store_prep_cli.dart check` reporta screenshot 1 OK |
| 2 | Capturar Creación proyecto / Script | Dispositivo físico + `adb shell screencap` | `assets/store/screenshots/step2_script.png` ≥1080x1920 | Guía `store_prep_cli.dart screenshots` | ASSET | Media | 0.25h | Tarea 0, dispositivo físico | → verificar: `dart run scripts/store_prep_cli.dart check` reporta screenshot 2 OK |
| 3 | Capturar Grabación con overlay | Dispositivo físico + `adb shell screencap` | `assets/store/screenshots/step3_recording.png` ≥1080x1920 (overlay de control visible) | Guía `store_prep_cli.dart screenshots` | ASSET | Media | 0.25h | Tarea 0, dispositivo físico | → verificar: `dart run scripts/store_prep_cli.dart check` reporta screenshot 3 OK |
| 4 | Capturar Revisión de clips | Dispositivo físico + `adb shell screencap` | `assets/store/screenshots/step4_review.png` ≥1080x1920 (clip reproduciéndose) | Guía `store_prep_cli.dart screenshots` | ASSET | Media | 0.25h | Tarea 0, dispositivo físico, Tareas 1-3 | → verificar: `dart run scripts/store_prep_cli.dart check` reporta screenshot 4 OK |
| 5 | Capturar Exportación / Performance | Dispositivo físico + `adb shell screencap` | `assets/store/screenshots/step5_export.png` ≥1080x1920 (métricas + botón exportar) | Guía `store_prep_cli.dart screenshots` | ASSET | Media | 0.25h | Tarea 0, dispositivo físico, Tareas 1-4 | → verificar: `dart run scripts/store_prep_cli.dart check` reporta screenshot 5 OK |
| 6 | Validación final | — | `dart run scripts/store_prep_cli.dart check` → 0 errores | Mismo comando CI | FULLSTACK | Baja | 0.1h | Tareas 1-5 | → verificar: criterios §5 pasan todos (6/6) |

**Tiempo total estimado:** 1.5 horas (asumiendo dispositivo físico disponible + app compilada funcionando)

### Notas de implementación

- **Dispositivo requerido:** Android físico con app compilada en debug mode (`flutter run`).
- **Comando ADB por captura:**
  ```bash
  adb shell screencap -p /sdcard/screenshot.png
  adb pull /sdcard/screenshot.png assets/store/screenshots/step{N}_{name}.png
  adb shell rm /sdcard/screenshot.png
  ```
- **Navegación previa a cada captura:**
  1. Abrir app → esperar Dashboard cargue proyectos reales
  2. Tap "Nuevo proyecto" → ingresar idea → generar guion
  3. Tap "Grabar" → esperar cámara activa → overlay visible
  4. Grabar 1-2 clips → tap "Revisar" en cada uno
  5. Finalizar grabación → esperar pantalla de métricas
- **Post-captura:** eliminar archivos placeholder existentes antes de copiar nuevos.

---

## Roadmap (post-MVP)

- Automatizar captura con `flutter test --integration` + screenshot golden tests para detectar regresiones visuales
- Agregar validación de resolución iOS (1284x2778+) en `store_prep_cli.dart`
- Script de captura batch que navegue automáticamente las 5 pantallas y capture
