# 📋 Análisis Unificado — Paso 10: Adaptive-icons-Android-13

**Generado:** 2026-05-09
**Fase:** mvp
**Prioridad:** Baja (post-MVP, no bloquea release)
**Origen:** Sugerencia Paso 04

---

## 0️⃣ Evaluación de Análisis y Verificaciones

### Tabla de Evaluación de Agentes

| Agente | Verificó código | Discrepancias detectadas | Propuesta DX | Evidencia sólida | Score (1-5) |
|:---|:---:|:---:|:---:|:---:|:---:|
| opus | ✅ 13 items | 5 (D1-D5) | ✅ check [9] store_prep_cli | ✅ descubrió bg color issue | **5.0** |
| glm | ✅ 14 items | 3 | ✅ adaptive_icon_validator | ✅ safe zone + store gap | **4.5** |
| ring | ✅ 13 items | 3 | ✅ extender store_prep_cli | ⚠️ no detectó bg color | **3.5** |
| step | ✅ 9 items | 3 | ✅ icons-generate subcmd | ⚠️ no detectó bg color | **3.0** |
| ds | ✅ 10 items | 2 | ❌ "ya cubierto" | ⚠️ no detectó bg color | **3.0** |
| LagunaM1 | ✅ 8 items | 1 | ✅ generate_adaptive_icons | ⚠️ superficial | **2.0** |
| Grok | ⚠️ 4 items | 1 | ✅ vrm-icon-regen | ❌ muy superficial | **1.5** |

### Discrepancias Críticas Consolidadas

| # | Discrepancia | Detectó | Verificada contra código | Resolución |
|---|---|---|---|---|
| D1 | Plan dice "Agregar `adaptive_icon_background`" y "Agregar `adaptive_icon_foreground`" — AMBAS YA EXISTEN en pubspec.yaml L133-134 | opus, ring, step, Grok, glm, ds, LagunaM1 | ✅ `pubspec.yaml:133-134` | Plan desactualizado. Config existe. Tarea real = ejecutar generador. |
| D2 | `mipmap-anydpi-v26/` no existe → Android 13+ muestra icono legacy sin forma adaptable | opus, ring, step, Grok, glm, ds, LagunaM1 | ✅ `ls android/app/src/main/res/` | Ejecutar `flutter pub run flutter_launcher_icons`. Verificar XML generado. |
| D3 | `icon_source.png` tiene fondo negro integrado. Usarlo como foreground con `background: "#FFFFFF"` → anillo blanco visible | opus | ✅ `assets/images/branding/icon_source.png` | Cambiar `adaptive_icon_background` de `"#FFFFFF"` a `"#000000"` en pubspec.yaml L133. |
| D4 | `store_prep_cli.dart` check [3] no valida existencia de `mipmap-anydpi-v26/` post-generación | opus, glm | ✅ `store_prep_cli.dart:480-492` | Agregar check [9] en `_runCheck()` que verifique `mipmap-anydpi-v26/launcher_icon.xml` existe. |
| D5 | `ic_launcher.png` (5 archivos) coexisten en mipmap-*/ sin ser referenciados | opus, ring, step, ds, glm | ✅ `ls mipmap-hdpi/ic_launcher.png` | Dead files del template Flutter. Opcional: eliminar post-MVP. No afectan funcionalidad. |
| D6 | `android:roundIcon` ausente en `AndroidManifest.xml` | opus | ✅ `AndroidManifest.xml:16` | Post-MVP. Android resuelve adaptive icon sin roundIcon explícito. |
| D7 | `icon_source.png` safe zone 66% no verificable programáticamente | glm | ⚠️ Verificación visual | Post-MVP. Logo centrado → bajo riesgo de recorte con máscara Android. |

---

## 1️⃣ Resumen Ejecutivo

Paso 10 configura adaptive icons Android 13+ en la app. **Hallazgo clave:** configuración `pubspec.yaml` (L128-134) ya está completa desde 2026-05-05, pero el comando `flutter pub run flutter_launcher_icons` nunca se ejecutó — `mipmap-anydpi-v26/` no existe.

**Corrección crítica al plan:** Plan dice "Agregar `adaptive_icon_background` y `adaptive_icon_foreground`" — ambas YA EXISTEN. Tarea real = regenerar iconos.

**Hallazgo técnico crítico (opus):** `icon_source.png` tiene fondo negro integrado. `adaptive_icon_background: "#FFFFFF"` → anillo blanco visible en Android 13+. Solución: cambiar a `"#000000"`.

**DX seleccionada:** Extender `store_prep_cli.dart` con check [9] que verifique `mipmap-anydpi-v26/launcher_icon.xml` existe post-generación. Fusión de propuestas opus (check [9]) + glm (validador post-generación). Sin script nuevo — consistente con patrón existente.

---

## 2️⃣ Diseño Funcional Consolidado

### Happy Path
1. `pubspec.yaml` tiene config `flutter_launcher_icons` con `adaptive_icon_background` + `adaptive_icon_foreground`
2. Desarrollador ejecuta `dart run scripts/store_prep_cli.dart check` → check [9] reporta ❌ (mipmap-anydpi-v26/ no existe)
3. Desarrollador ejecuta `flutter pub run flutter_launcher_icons`
4. Tool genera `mipmap-anydpi-v26/launcher_icon.xml` con `<adaptive-icon>` + foreground/background layers
5. `mipmap-*/launcher_icon.png` regenerados (PNGs legacy)
6. Desarrollador ejecuta `dart run scripts/store_prep_cli.dart check` → check [9] reporta ✅
7. Android 13+ (API 33+) resuelve `@mipmap/launcher_icon` → `mipmap-anydpi-v26/launcher_icon.xml` → icono adaptable
8. Android <26 (API <26) ignora `mipmap-anydpi-v26/` → usa `mipmap-*/launcher_icon.png` legacy

### Edge Cases MVP
- **icon_source.png no encontrado:** `flutter pub run flutter_launcher_icons` falla con error claro. Verificar asset existe antes de regenerar.
- **flutter_launcher_icons v0.13.1 no genera mipmap-anydpi-v26/:** Bug conocido en versiones antiguas. Actualizar a ^0.14.0+ si falla.
- **icon_source.png sin safe zone 66%:** Logo cerca del borde se recorta con máscara OEM. Verificar visualmente en dispositivo real.
- **Android <26 coexiste:** `mipmap-anydpi-v26/` ignorado. Iconos legacy intactos.

---

## 3️⃣ Diseño Técnico Definitivo

### Componentes y Modificaciones

| Archivo | Tipo de cambio | Descripción | Interfaces clave | Patrón a seguir |
|---|---|---|---|---|
| `D:\Develop\Personal\vrm\pubspec.yaml` L133 | Modificación | Cambiar `adaptive_icon_background: "#FFFFFF"` → `"#000000"` | `adaptive_icon_background: "#000000"` | Mismo bloque L128-134 |
| `D:\Develop\Personal\vrm\scripts\store_prep_cli.dart` | Modificación | Agregar check [9] adaptive icons en `_runCheck()` | `_runCheck()` L303 (antes del Summary) | Check [6] gitignore (L238-261): Directory.existsSync + results + details + print |
| `android/app/src/main/res/mipmap-anydpi-v26/` | Creación (autogenerado) | Contiene `launcher_icon.xml` con `<adaptive-icon>` | XML genera `<adaptive-icon><background/><foreground/></adaptive-icon>` | Generado por `flutter_launcher_icons` v0.13+ |
| `android/app/src/main/res/mipmap-*/launcher_icon.png` | Regeneración (autogenerado) | PNGs sobrescritos desde `icon_source.png` | N/A | Misma tool |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Eliminación (opcional post-MVP) | Dead files template Flutter | N/A | N/A |

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: store_prep_cli.dart check [9] — Adaptive Icons Validation
- **Qué automatiza:** Verifica que `mipmap-anydpi-v26/launcher_icon.xml` existe post-generación.
  Detecta olvido de regeneración y XML mal formado.
- **Tipo:** Extensión de CLI existente (store_prep_cli.dart _runCheck())
- **Ubicación:** `D:\Develop\Personal\vrm\scripts\store_prep_cli.dart` — check [9] antes del Summary
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart check` → check [9] reporta ✅/❌
- **Impacto para el usuario final:** Detecta ANTES del build release que adaptive icons no se generaron.
  Sin esto → icono se ve recortado/cuadrado en Android 13+ y el usuario nunca lo sabría hasta instalar en dispositivo.
- **El implementador DEBE usarla** antes y después de regenerar iconos (dogfooding).
```

---

## 4️⃣ Decisiones Tecnológicas

1. **`adaptive_icon_background: "#000000"` en vez de `"#FFFFFF"`:** `icon_source.png` tiene fondo negro integrado. Background blanco → anillo blanco visible en Android 13+. Usar negro → match perfecto, esquinas redondeadas del PNG mitigadas por máscara Android.

2. **Extender store_prep_cli.dart existente en vez de crear script nuevo:** 3 agentes propusieron scripts independientes (Grok → vrm-icon-regen, step → icons-generate, LagunaM1 → generate_adaptive_icons). Opción de opus/glm (extender CLI existente) gana: consistente con patrón actual, 0 fragmentación, 1 comando para todo store prep.

3. **No crear foreground transparente (Opción B de opus) para MVP:** Requiere edición gráfica. Opción A (background negro) es suficiente para MVP. Post-MVP crear `icon_foreground.png` con fondo transparente.

4. **`android:roundIcon` no requerido:** Android 13+ resuelve adaptive icon sin roundIcon explícito. Opus lo menciona pero no bloquea.

5. **Correcciones al plan:**
   - ⚠️ Plan dice "Agregar `adaptive_icon_background: "#FFFFFF"`" pero YA EXISTE en pubspec.yaml L133. Se implementa sin cambio (excepto color → `"#000000"`).
   - ⚠️ Plan dice "Agregar `adaptive_icon_foreground: assets/...`" pero YA EXISTE en pubspec.yaml L134. Se implementa sin cambio.
   - ⚠️ Plan completa Tarea 1 y 2 solo con regenerar. Se agrega Tarea 0 (DX check) y corrección de color.

---

## 5️⃣ Criterios de Aceptación MVP

```
✅ [DATA] pubspec.yaml L133: adaptive_icon_background = "#000000" (corregido de #FFFFFF)
✅ [DATA] pubspec.yaml L134: adaptive_icon_foreground apunta a assets/images/branding/icon_source.png
✅ [CODE] mipmap-anydpi-v26/ existe en android/app/src/main/res/ con ≥1 archivo XML
✅ [CODE] launcher_icon.xml contiene <adaptive-icon> con <background> y <foreground>
✅ [CODE] store_prep_cli.dart check [9] verifica existencia de mipmap-anydpi-v26/
✅ [BACKEND] N/A — sin backend afectado
✅ [FULLSTACK] Icono se ve correcto en Android 13+ con forma adaptable (sin borde blanco visible)
✅ [FULLSTACK] No rompe iconos existentes en Android <13 (legacy mipmap PNGs siguen existiendo)
✅ [FULLSTACK] iOS icons no afectados (siguen usando icon_source.png)
✅ [DX] store_prep_cli.dart check → check [9] adaptive icons reporta ✅ post-generación
✅ [DX] flutter pub run flutter_launcher_icons ejecuta sin errores
```

**Funcionales:**
- [ ] Icono se adapta a forma del launcher en Android 13+ (círculo, squircle, rounded square)
- [ ] Icono legacy en Android <26 sin cambios (misma apariencia que antes)

**Técnicos:**
- [ ] `mipmap-anydpi-v26/launcher_icon.xml` contiene `<adaptive-icon>` con foreground y background
- [ ] `dart run scripts/store_prep_cli.dart check` → check [9] ✅
- [ ] `flutter build apk --debug` compila sin errores de recursos

---

## 6️⃣ Plan de Implementación

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|---|---|---|---|
| 0 | **DX & Tooling:** Agregar check [9] adaptive icons en `store_prep_cli.dart` | Baja | 0.25h | Ninguna |
| 1 | Corregir `adaptive_icon_background` color en `pubspec.yaml` L133: `"#FFFFFF"` → `"#000000"` | Baja | 0.05h | Ninguna |
| 2 | Ejecutar `flutter pub run flutter_launcher_icons` (o `dart run flutter_launcher_icons`) para generar adaptive icons | Baja | 0.1h | Tarea 1 |
| 3 | Verificar XML `launcher_icon.xml` contiene `<adaptive-icon>` con background + foreground | Baja | 0.05h | Tarea 2 |
| 4 | Validar flujo end-to-end: `dart run scripts/store_prep_cli.dart check` → check [9] ✅ + build debug sin error | Baja | 0.1h | Tareas 0-3 |
| 5 | (Opcional) Limpiar `ic_launcher.png` dead files de `mipmap-*/` | Baja | 0.05h | Tarea 2 |
| **TOTAL** | | | **~0.6h** | |

### Detalle Tarea 0 — DX & Tooling

**Archivo:** `scripts/store_prep_cli.dart`

**Insertar** en `_runCheck()` después de check [8] (L301) y antes del Summary (L303):

```dart
// 9. Adaptive icons Android 13+
print('[9] Verificando adaptive icons Android 13+...');
final adaptiveDir = Directory(
  '$_projectRoot/android/app/src/main/res/mipmap-anydpi-v26',
);
final adaptiveDirExists = await adaptiveDir.exists();
var adaptiveXmlExists = false;
if (adaptiveDirExists) {
  final files = await adaptiveDir.list().toList();
  adaptiveXmlExists = files.any((f) => f.path.endsWith('.xml'));
}
results['adaptive_icons'] = adaptiveDirExists && adaptiveXmlExists;
details['adaptive_icons'] = (adaptiveDirExists && adaptiveXmlExists)
    ? 'mipmap-anydpi-v26/ existe con XML adaptive'
    : 'mipmap-anydpi-v26/ NO encontrado o sin XML — ejecutar flutter pub run flutter_launcher_icons';
print(
  '  ${(adaptiveDirExists && adaptiveXmlExists) ? "✅" : "❌"} ${details["adaptive_icons"]}',
);
if (!adaptiveDirExists || !adaptiveXmlExists) {
  allOk = false;
}
```

**Patrón a seguir:** Check [6] gitignore (L238-261) — `Directory.existsSync` + `results['key']` + `details['key']` + print + `allOk` flag.

### Detalle Tarea 1 — Corrección color

**Archivo:** `pubspec.yaml` L133

```
-  adaptive_icon_background: "#FFFFFF"
+  adaptive_icon_background: "#000000"
```

### Detalle Tarea 2 — Regeneración

```bash
cd D:\Develop\Personal\vrm
flutter pub run flutter_launcher_icons
# Alternativa:
dart run flutter_launcher_icons
```

**Verificar:**
```bash
Test-Path "android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml"
```

### Detalle Tarea 3 — Verificar XML

```bash
Get-Content "android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml"
```

Debe contener:
- `<adaptive-icon ...>`
- `<background android:drawable="@color/launcher_icon_background"/>` (o referencia a color)
- `<foreground android:drawable="@mipmap/launcher_icon_foreground"/>`

### Detalle Tarea 4 — Validación

```bash
dart run scripts/store_prep_cli.dart check
# check [9] debe mostrar ✅
flutter build apk --debug
# debe compilar sin errores de recursos
```

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Foreground con fondo opaco → anillo blanco visible | Media | `icon_source.png` tiene fondo negro. Background `#FFFFFF` → borde visible | Tarea 1: cambiar background a `"#000000"`. Post-MVP crear foreground transparente. |
| `flutter_launcher_icons` v0.13.1 no genera `mipmap-anydpi-v26/` | Baja | Bug conocido en versiones antiguas | Verificar output. Si falla, actualizar a `^0.14.0+` o generar manualmente. |
| Safe zone del foreground cortada por máscara OEM | Baja | Logo ocupa >66% del canvas adaptive icon 108dp | Logo centrado → bajo riesgo. Background negro mitiga artefactos de esquinas redondeadas. |
| `ic_launcher.png` dead files causan confusión | Muy Baja | 5 archivos template Flutter nunca limpiados | Sin impacto funcional. AndroidManifest usa `launcher_icon`, no `ic_launcher`. Tarea 5 opcional. |
| Build release rechazado por Google Play | Baja | Icono no cumple guidelines adaptive icons | Check [9] en store_prep_cli detecta ausencia antes de build. |

---

## 8️⃣ Testing Mínimo Viable

| ID | Caso | Input | Output Esperado |
|---|---|---|---|
| TP-1 | Regeneración exitosa | `flutter pub run flutter_launcher_icons` | Exit code 0. `mipmap-anydpi-v26/launcher_icon.xml` creado. |
| TP-2 | store_prep_cli check [9] post-generación | `dart run scripts/store_prep_cli.dart check` | check [9] ✅ "mipmap-anydpi-v26/ existe con XML adaptive" |
| TP-3 | store_prep_cli check [9] pre-generación | `dart run scripts/store_prep_cli.dart check` (sin regenerar) | check [9] ❌ "mipmap-anydpi-v26/ NO encontrado" |
| TP-4 | XML validación contenido | `Get-Content` de `launcher_icon.xml` | Contiene `<adaptive-icon>`, `<background>`, `<foreground>` |
| TP-5 | Build debug sin error | `flutter build apk --debug` | Exit code 0. Sin MissingPluginException ni resource errors. |
| TP-6 | Icono legacy intacto (Android <26) | Verificar `mipmap-hdpi/launcher_icon.png` existe | Archivo presente, mismo tamaño aprox (~6.8KB hdpi) |

Comando para ejecutar tests: `flutter test` / `dart run scripts/store_prep_cli.dart check`

---

## 9️⃣ Roadmap (NO implementar ahora)

- **Foreground transparente (Opción B):** Crear `icon_foreground.png` 1024x1024 con solo logo VRM sobre fondo transparente, centrado en safe zone 66.7%. Requiere edición gráfica. Mejora visual en launchers con formas no-cuadradas.
- **`android:roundIcon` en AndroidManifest:** Si `flutter_launcher_icons` no lo agrega automáticamente, agregar `android:roundIcon="@mipmap/launcher_icon"` para dispositivos que priorizan roundIcon.
- **Cleanup `ic_launcher.png`:** Eliminar 5 archivos residuales de `mipmap-*/`. Tarea 5 opcional ya lista.
- **Migrar `flutter_launcher_icons` a >= v0.14.0:** Mejor soporte Android 14+ (monochrome icons).
- **Pre-commit hook:** Regenerar adaptive icons automáticamente cuando cambie `icon_source.png`.
