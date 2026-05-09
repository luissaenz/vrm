# 📋 Análisis Paso 10: Adaptive-icons-Android-13

**Agente:** opus
**Paso:** 10 — Adaptive-icons-Android-13
**Fecha:** 2026-05-09

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `flutter_launcher_icons` en dev_dependencies | grep `pubspec.yaml` | ✅ | `pubspec.yaml:83` — `flutter_launcher_icons: ^0.13.1` |
| 2 | Config `flutter_launcher_icons:` en pubspec | lectura `pubspec.yaml` L128-134 | ✅ | `android: "launcher_icon"`, `ios: true`, `image_path`, `adaptive_icon_background`, `adaptive_icon_foreground` — TODO configurado |
| 3 | `adaptive_icon_background` declarado | lectura `pubspec.yaml:133` | ✅ | `adaptive_icon_background: "#FFFFFF"` |
| 4 | `adaptive_icon_foreground` declarado | lectura `pubspec.yaml:134` | ✅ | `adaptive_icon_foreground: "assets/images/branding/icon_source.png"` |
| 5 | `icon_source.png` existe | `ls assets/images/branding/` | ✅ | `icon_source.png` — 504719 bytes, 1024x1024, logo VRM neon azul sobre fondo negro con esquinas redondeadas |
| 6 | `mipmap-anydpi-v26/` existe en `android/app/src/main/res/` | `ls android/app/src/main/res/` | ❌ | **NO EXISTE** — 21 dirs, ninguno `mipmap-anydpi-v26` → adaptive icons nunca generados |
| 7 | `ic_launcher_foreground.xml` o `.png` en res | grep `android/app/src/main/res/` por `adaptive-icon` | ❌ | 0 archivos XML adaptive-icon encontrados |
| 8 | `AndroidManifest.xml` `android:roundIcon` | grep `AndroidManifest.xml` por `roundIcon` | ❌ | Atributo ausente. Solo `android:icon="@mipmap/launcher_icon"` (L16) |
| 9 | `launcher_icon.png` en mipmap dirs | `ls mipmap-hdpi/` | ✅ | Existe en hdpi(6887B), mdpi(3395B), xhdpi, xxhdpi, xxxhdpi(40526B) — iconos legacy generados |
| 10 | `ic_launcher.png` (Flutter default) coexiste | `ls mipmap-hdpi/` | ⚠️ | `ic_launcher.png` (544B) coexiste con `launcher_icon.png` — residuo del template Flutter, no referenciado |
| 11 | `minSdk` en `build.gradle.kts` | lectura `build.gradle.kts:29` | ✅ | `minSdk = 24` — compatible con adaptive icons (API 26+) |
| 12 | `store_prep_cli.dart` valida adaptive icons | lectura `store_prep_cli.dart:480-492` | ❌ | Check [3] solo verifica `flutter_launcher_icons:` existe + `android:` + `ios:` + `image_path:`. **NO verifica** `adaptive_icon_background`, `adaptive_icon_foreground`, ni existencia de `mipmap-anydpi-v26/` |
| 13 | Icon source tiene fondo separado foreground | inspección visual `icon_source.png` | ❌ | **PROBLEMA**: logo VRM tiene fondo negro integrado en PNG. Foreground adaptive icon debería ser transparente. Usar mismo PNG como foreground → fondo negro dentro de fondo blanco = anillo blanco visible en Android 13+ |

**Discrepancias encontradas:**

1. **❌ D1: Config existe pero nunca ejecutada.** `pubspec.yaml` L128-134 tiene `adaptive_icon_background` y `adaptive_icon_foreground` configurados. PERO `flutter pub run flutter_launcher_icons` nunca se ejecutó con esta config (o se ejecutó antes de agregar adaptive params). `mipmap-anydpi-v26/` no existe → Android 13+ usa icono legacy (sin forma adaptable).

2. **❌ D2: Foreground asset inadecuado.** `icon_source.png` = logo con fondo negro integrado + esquinas redondeadas. Android adaptive icons requieren foreground con fondo **transparente** (72dp safe zone centrado en 108dp canvas). Usar `icon_source.png` como foreground sobre `#FFFFFF` background → franja blanca visible alrededor del fondo negro del logo.

3. **❌ D3: `store_prep_cli.dart` no valida adaptive icons.** Check [3] solo verifica presencia textual de config, no que `mipmap-anydpi-v26/` exista ni que iconos adaptativos estén realmente generados.

4. **⚠️ D4: `ic_launcher.png` residual.** Flutter default `ic_launcher.png` coexiste en todos los mipmap dirs. No referenciado por `AndroidManifest.xml` (usa `launcher_icon`). Basura pero inofensivo.

5. **❌ D5: `android:roundIcon` ausente.** `AndroidManifest.xml` L16 solo tiene `android:icon`. Android recomienda `android:roundIcon="@mipmap/launcher_icon_round"` para dispositivos que muestran iconos redondos.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**N/A para este paso.** Paso 10 no toca schema, DB, JSON, ni persistencia. Es 100% configuración de assets nativos Android.

- Sin tablas afectadas
- Sin cambios de modelo Dart
- Sin impacto en `vrm_data/` filesystem

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivos afectados

| Archivo | Acción | Detalle |
|---|---|---|
| `pubspec.yaml` L128-134 | MODIFICAR | Config `flutter_launcher_icons` — cambiar `adaptive_icon_background` de `#FFFFFF` a `#000000` para match fondo icon |
| `assets/images/branding/icon_foreground.png` | CREAR (post-MVP) | Foreground PNG 1024x1024 con fondo transparente, solo logo VRM centrado en safe zone (72dp / 108dp = 66.7% del canvas) |
| `android/app/src/main/res/mipmap-anydpi-v26/` | GENERADO | Creado por `flutter pub run flutter_launcher_icons` — contiene `launcher_icon.xml` (adaptive-icon XML) |
| `android/app/src/main/res/mipmap-*/launcher_icon.png` | REGENERADO | Sobrescrito por flutter_launcher_icons con nuevos iconos legacy |
| `android/app/src/main/AndroidManifest.xml` L16 | POTENCIAL | flutter_launcher_icons v0.13 puede agregar `android:roundIcon` automáticamente si config adaptive |
| `scripts/store_prep_cli.dart` | MODIFICAR | Agregar check de `mipmap-anydpi-v26/` existencia |

### Patrones existentes

- `flutter_launcher_icons` config en `pubspec.yaml` — patrón estándar Flutter (no hay archivo separado `flutter_launcher_icons.yaml`)
- CLI tools en `scripts/` — patrón Dart CLI (switch/case subcomandos) — referencia `store_prep_cli.dart`
- Assets branding en `assets/images/branding/` — convención existente (`icon_source.png`, `splash_source.png`)

### Problema técnico clave: icon_source.png como foreground

```
Estado actual icon_source.png:
┌────────────────────┐
│ ████████████████████│ ← fondo negro integrado
│ ████ VRM LOGO █████│ ← logo neon centrado
│ ████████████████████│
│ ███(esquinas ████████│ ← esquinas redondeadas
│ ████redondeadas)████│
└────────────────────┘

Resultado si se usa como foreground con background #FFFFFF:
┌────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← #FFFFFF background layer
│▓┌──────────────┐▓▓▓│
│▓│ ████████████ │▓▓▓│ ← fondo negro del PNG
│▓│ ████VRM█████ │▓▓▓│ ← logo neon
│▓│ ████████████ │▓▓▓│
│▓└──────────────┘▓▓▓│ ← BORDE BLANCO VISIBLE ❌
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└────────────────────┘
```

**Solución:** 2 opciones:
- **Opción A (rápida, MVP):** Cambiar `adaptive_icon_background` de `"#FFFFFF"` a `"#000000"` → match fondo negro del icon. Esquinas redondeadas del PNG se notan minimamente (Android recorta con máscara).
- **Opción B (correcta, post-MVP):** Crear `icon_foreground.png` con fondo transparente, solo logo centrado en safe zone 66.7%. Requiere edición gráfica.

**Recomendación:** Opción A para MVP (0 esfuerzo gráfico). Opción B para roadmap post-MVP.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**N/A para este paso.** Sin endpoints, sin middleware, sin API, sin auth.

Paso 10 = pura configuración nativa Android (assets + build tools). Sin impacto backend.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo end-to-end

```
pubspec.yaml config → flutter pub run flutter_launcher_icons → genera:
  ├── mipmap-hdpi/launcher_icon.png (legacy)
  ├── mipmap-mdpi/launcher_icon.png
  ├── mipmap-xhdpi/launcher_icon.png
  ├── mipmap-xxhdpi/launcher_icon.png
  ├── mipmap-xxxhdpi/launcher_icon.png
  ├── mipmap-anydpi-v26/launcher_icon.xml (adaptive-icon XML)
  └── mipmap-*/launcher_icon_foreground.png (foreground layer scaled)
→ AndroidManifest.xml refs → Android 13+ muestra icono con forma adaptable
```

### Coherencia con plan

Plan dice:
> - Agregar `adaptive_icon_background: "#FFFFFF"` en config flutter_launcher_icons
> - Agregar `adaptive_icon_foreground: "assets/images/branding/icon_source.png"`
> - Regenerar iconos con `flutter pub run flutter_launcher_icons`

**Discrepancia:** Tareas 1 y 2 del plan YA ESTÁN en `pubspec.yaml`. Solo falta ejecutar tarea 3 (regenerar) + resolver D2 (foreground asset inadecuado).

### DX & Tooling — OBLIGATORIO

### Herramienta Propuesta: Check [9] adaptive icons en store_prep_cli.dart

- **Qué automatiza:** Verificar que adaptive icons estén correctamente generados después de ejecutar flutter_launcher_icons. Actualmente `store_prep_cli.dart` check [3] NO detecta que `mipmap-anydpi-v26/` falta.
- **Tipo:** Extensión de `store_prep_cli.dart` (nuevo check [9] en `_runCheck()`)
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart check` → check [9] reporta ✅/❌ adaptive icons
- **Impacto para el usuario final:** Detecta ANTES del build que adaptive icons no se generaron. Sin esto → icono se ve recortado/cuadrado en Android 13+ y el usuario nunca lo sabría hasta instalar en dispositivo.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso

### Flujo end-to-end en diagrama

```
[pubspec.yaml config] ──→ [dart run flutter_launcher_icons] ──→ [mipmap-anydpi-v26/ generado]
                                      │                                    │
                                      ↓                                    ↓
                              [legacy mipmap PNGs]              [launcher_icon.xml (adaptive)]
                                      │                                    │
                                      ↓                                    ↓
                        [Android <13: icono normal]       [Android 13+: icono adaptable]
                                      │                                    │
                                      └──────────────┬─────────────────────┘
                                                     ↓
                                        [store_prep_cli.dart check]
                                              check [9]: ✅/❌
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] N/A — paso no toca datos
✅ [CODE] pubspec.yaml: adaptive_icon_background = "#000000" (match fondo icon)
✅ [CODE] pubspec.yaml: adaptive_icon_foreground apunta a asset existente (icon_source.png)
✅ [CODE] `mipmap-anydpi-v26/` existe en android/app/src/main/res/ con ≥1 archivo XML
✅ [CODE] launcher_icon.xml contiene <adaptive-icon> con <background> y <foreground>
✅ [BACKEND] N/A — sin backend afectado
✅ [FULLSTACK] Icono se ve correcto en Android 13+ con forma adaptable (sin borde blanco visible)
✅ [FULLSTACK] No rompe iconos existentes en Android <13 (legacy mipmap PNGs siguen existiendo)
✅ [FULLSTACK] iOS icons no afectados (siguen usando icon_source.png)
✅ [DX] store_prep_cli.dart check incluye validación de mipmap-anydpi-v26/ existencia
✅ [DX] `dart run scripts/store_prep_cli.dart check` → check [9] adaptive icons reporta ✅
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Foreground con fondo opaco → anillo visible | Media | `icon_source.png` tiene fondo negro integrado. Si background ≠ negro → borde visible. | Cambiar background a `"#000000"` (Opción A). Post-MVP crear foreground transparente (Opción B). |
| `flutter pub run flutter_launcher_icons` falla en Windows | Baja | Versión ^0.13.1 puede tener edge cases con paths Windows + Dart 3.10 | Ejecutar con `dart run flutter_launcher_icons` (alternativa). Verificar output completo. |
| Safe zone del foreground cortada por máscara | Media | Android adaptive icons usan máscara que corta 18dp exteriores del canvas 108dp. Logo cerca del borde → recortado. | `icon_source.png` tiene logo centrado → bajo riesgo. Background negro mitiga artefactos de esquinas redondeadas del PNG. |
| Conflicto ic_launcher.png residual | Baja | Flutter default `ic_launcher.png` coexiste. flutter_launcher_icons puede o no sobrescribirlo. | Irrelevante — `AndroidManifest.xml` usa `launcher_icon`, no `ic_launcher`. Cleanup opcional en Tarea 4. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: Agregar check [9] adaptive icons en store_prep_cli.dart | `scripts/store_prep_cli.dart` | En `_runCheck()` después de check [8] (L284-301), agregar: `print('[9] Verificando adaptive icons Android 13+...');` + `final adaptiveDir = Directory('$_projectRoot/android/app/src/main/res/mipmap-anydpi-v26');` + `final adaptiveDirExists = await adaptiveDir.exists();` + verificar que contenga ≥1 archivo `.xml`. Key: `adaptive_icons`. Patrón: mismo que check [6] gitignore (Directory.exists + print ✅/❌ + set allOk). | `store_prep_cli.dart :: _runCheck() check [6]` (L238-261) — patrón Directory.existsSync + results + details + print | DX | Baja | 0.25h | Ninguna | → verificar: `dart run scripts/store_prep_cli.dart check` ejecuta sin errores Y muestra `[9] Verificando adaptive icons Android 13+...` |
| 1 | Actualizar adaptive_icon_background color en pubspec.yaml | `pubspec.yaml` L133 | Cambiar `adaptive_icon_background: "#FFFFFF"` → `adaptive_icon_background: "#000000"` | `pubspec.yaml:128-134` (mismo bloque flutter_launcher_icons) | CODE | Baja | 0.05h | Ninguna | → verificar: `findstr "adaptive_icon_background" pubspec.yaml` muestra `"#000000"` |
| 2 | Ejecutar flutter_launcher_icons para generar adaptive icons | N/A (archivos generados) | `dart run flutter_launcher_icons` (ejecutar desde raíz proyecto `D:\Develop\Personal\vrm`) | Docs oficiales: https://pub.dev/packages/flutter_launcher_icons | CODE | Baja | 0.1h | Tarea 1 | → verificar: `dir android\app\src\main\res\mipmap-anydpi-v26\` muestra `launcher_icon.xml` |
| 3 | Verificar XML adaptive-icon generado correctamente | `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml` | Archivo debe contener `<adaptive-icon>` con `<background android:drawable="@color/launcher_icon_background"/>` y `<foreground android:drawable="@mipmap/launcher_icon_foreground"/>` | Generado automáticamente por flutter_launcher_icons v0.13 | FULLSTACK | Baja | 0.1h | Tarea 2 | → verificar: `type android\app\src\main\res\mipmap-anydpi-v26\launcher_icon.xml` contiene `adaptive-icon` |
| 4 | Limpiar ic_launcher.png residuales (opcional) | `android/app/src/main/res/mipmap-*/ic_launcher.png` | Eliminar `ic_launcher.png` de mipmap-hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi. AndroidManifest usa `launcher_icon`, no `ic_launcher`. | — | CODE | Baja | 0.1h | Tarea 2 | → verificar: 0 archivos `ic_launcher.png` en `android\app\src\main\res\mipmap-*\` |
| 5 | Validar flujo end-to-end | — | — | — | FULLSTACK | Baja | 0.25h | Tareas 0-3 | → verificar: `dart run scripts/store_prep_cli.dart check` → check [9] ✅ + todos criterios §5 pasan |

> [!IMPORTANT]
> **Tarea 0 siempre = DX & Tooling.** El implementador DEBE ejecutarla primero y usar la herramienta resultante para el resto del paso.

**Tiempo total estimado:** ~0.9h (1 hora)

---

## 🔮 Roadmap (NO implementar ahora)

- **Foreground transparente (Opción B):** Crear `icon_foreground.png` con solo logo VRM sobre fondo transparente, centrado en safe zone 66.7%. Mejora visual en Android 13+ con launchers que usan formas no-cuadradas (circle, teardrop, etc.).
- **`android:roundIcon` en AndroidManifest:** `flutter_launcher_icons` v0.13+ puede agregarlo automáticamente. Si no → agregar manualmente `android:roundIcon="@mipmap/launcher_icon_round"` en L16.
- **iOS icon variant:** iOS no usa adaptive icons pero requiere 1024x1024 sin alpha para App Store. `icon_source.png` tiene fondo opaco → OK.
- **Cleanup `ic_launcher.png` Flutter default:** Eliminar en todos los mipmap dirs. Inofensivo pero basura del template inicial.
