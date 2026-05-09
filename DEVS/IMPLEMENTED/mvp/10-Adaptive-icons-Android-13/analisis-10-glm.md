# Análisis Técnico: Paso 10 — Adaptive-icons-Android-13

**Agente:** glm  
**Paso:** 10 (Adaptive-icons-Android-13)  
**Fecha:** 2026-05-09  
**Prioridad plan:** Baja  
**Fase:** mvp  

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `adaptive_icon_background` en pubspec.yaml | grep en `pubspec.yaml` L133 | ✅ VERIFICADO | `pubspec.yaml:133` → `adaptive_icon_background: "#FFFFFF"` |
| 2 | `adaptive_icon_foreground` en pubspec.yaml | grep en `pubspec.yaml` L134 | ✅ VERIFICADO | `pubspec.yaml:134` → `adaptive_icon_foreground: "assets/images/branding/icon_source.png"` |
| 3 | `flutter_launcher_icons` en dev_dependencies | grep en `pubspec.yaml` L83 | ✅ VERIFICADO | `pubspec.yaml:83` → `flutter_launcher_icons: ^0.13.1` |
| 4 | `icon_source.png` existe en assets | File.exists en `assets/images/branding/` | ✅ VERIFICADO | 1024x1024 RGB, archivo presente |
| 5 | `image_path` en flutter_launcher_icons | grep en `pubspec.yaml` L131 | ✅ VERIFICADO | `pubspec.yaml:131` → `image_path: "assets/images/branding/icon_source.png"` |
| 6 | `android: "launcher_icon"` en flutter_launcher_icons | grep en `pubspec.yaml` L129 | ✅ VERIFICADO | `pubspec.yaml:129` → `android: "launcher_icon"` |
| 7 | Directorio `mipmap-anydpi-v26/` existe | Dir.exists en Android res | ❌ DISCREPANCIA | No existe. Es el output esperado de flutter_launcher_icons |
| 8 | `mipmap-*/ic_launcher.png` presentes | File.exists en mipmap dirs | ✅ VERIFICADO | hdpi(544B), mdpi, xhdpi, xxhdpi(14KB), xxxhdpi(40KB) — iconos legacy |
| 9 | `mipmap-*/launcher_icon.png` presentes | File.exists en mipmap dirs | ✅ VERIFICADO | Presentes en hdpi(6.8KB) a xxxhdpi(40KB) |
| 10 | `AndroidManifest.xml` referencia icon | grep `@mipmap/launcher_icon` L16 | ✅ VERIFICADO | `AndroidManifest.xml:16` → `android:icon="@mipmap/launcher_icon"` |
| 11 | `minSdk = 24` en build.gradle.kts | grep L29 | ✅ VERIFICADO | `build.gradle.kts:29` → `minSdk = 24` |
| 12 | `targetSdk` usa flutter.targetSdkVersion | grep L30 | ✅ VERIFICADO | `build.gradle.kts:30` → `targetSdk = flutter.targetSdkVersion` |
| 13 | `store_prep_cli.dart` verifica adaptive icons | grep mipmap-anydpi | ❌ DISCREPANCIA | No verifica existencia de `mipmap-anydpi-v26/`. Solo verifica config en pubspec.yaml L482-492 |
| 14 | `flutter_native_splash` config presente | grep en `pubspec.yaml` L136-141 | ✅ VERIFICADO | Config completa con android_12 section |

**Discrepancias encontradas:**

1. **D1 — Plan dice "Agregar adaptive_icon_background/foreground" → YA EXISTEN en pubspec.yaml L133-134.** Resolución: Tarea de "agregar config" es redundante. El problema real es que `flutter pub run flutter_launcher_icons` nunca se ejecutó (o se ejecutó sin generar adaptive icons). Falta `mipmap-anydpi-v26/`.

2. **D2 — `mipmap-anydpi-v26/` no existe.** Sin este directorio, Android 13+ (API 33) trata el icono como legacy PNG y lo recorta mal. Resolución: Ejecutar `dart run flutter_launcher_icons` y verificar que se genera `mipmap-anydpi-v26/ic_launcher.xml`.

3. **D3 — `store_prep_cli.dart` no verifica adaptive icons.** Solo chequea config en pubspec pero no verifica output en `mipmap-anydpi-v26/`. Resolución: Agregar check en `store_prep_cli.dart` → subcomando `check` o `assets validate`.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema / Persistencia

No hay migraciones ni tablas afectadas. Este paso toca exclusivamente assets estáticos y configuración de build.

- ✅ **Icono fuente:** `assets/images/branding/icon_source.png` — 1024x1024 RGB. Tamaño correcto para generación de adaptive icons (requerido ≥ 48x48dp safe zone, 1024px es el estándar).
- ✅ **Config en pubspec.yaml:** Completa. `flutter_launcher_icons` configurado con `android: "launcher_icon"`, `ios: true`, `image_path`, `adaptive_icon_background`, `adaptive_icon_foreground`.
- ⚠️ **NO VERIFICABLE:** Si `icon_source.png` tiene safe zone de 66% (requerido por adaptive icon spec). Si el logo ocupa más del 66% del área, se recortará en formas no circulares. Confirmar visualmente.

### Impacto en datos existentes

Nulo. No hay tablas, schemas ni datos.

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivos afectados

| Archivo | Acción | Detalle |
|---|---|---|
| `pubspec.yaml` L128-134 | SIN CAMBIO — ya tiene config completa | `adaptive_icon_background` y `adaptive_icon_foreground` ya presentes |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | CREAR (autogenerado por tool) | Adaptive icon XML con foreground/background layers |
| `android/app/src/main/res/drawable*/` | POSIBLE ACTUALIZACIÓN (autogenerado) | adaptive_icon Foreground/Background drawables |
| `android/app/src/main/res/mipmap-*/launcher_icon.png` | SIN CAMBIO | Iconos legacy ya generados, funcionan para API <26 |
| `scripts/store_prep_cli.dart` | MODIFICAR | Agregar check de `mipmap-anydpi-v26/` en subcomando `check` o `assets validate` |

### Patrones existentes

- **flutter_native_splash** ya se ejecutó correctamente → generó `drawable*/splash.png`, `drawable*/android12splash.png`, `values*/styles.xml`. Patrón a seguir para generación de assets.
- **flutter_launcher_icons** Config existe pero output incompleto → sin `mipmap-anydpi-v26/`.

### Firmas

Sin funciones/clases nuevas en código Dart. Generación es por tool de build.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

### APIs / Endpoints

No aplica. Este paso no toca el backend ni APIs.

### Middleware

No aplica.

### Contratos

No aplica.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo

```
icon_source.png (1024x1024)
    → flutter_launcher_icons (tool)
        → mipmap-*/launcher_icon.png (legacy, API <26)
        → mipmap-*/ic_launcher.png (legacy alternate)
        → mipmap-anydpi-v26/ic_launcher.xml (adaptive, API 26+/Android 13+)
            → references drawable foreground/background layers
    → AndroidManifest @mipmap/launcher_icon
        → API 26+: usa ic_launcher.xml (adaptive)
        → API <26: usa launcher_icon.png (legacy)
```

### Coherencia

- ✅ Config en pubspec.yaml alineada con assets existentes.
- ✅ `icon_source.png` 1024x1024 es tamaño estándar.
- ✅ `minSdk = 24` → fallback a PNG legacy funciona para API 24-25.
- ✅ `AndroidManifest` referencia `@mipmap/launcher_icon` → correcto.

### Gaps

- ⚠️ **Visual verification needed:** No se puede verificar programáticamente que el logo cumpla safe zone 66% de adaptive icon spec. Safe zone = círculo de 66dp dentro del adaptive icon de 108dp.
- ❌ **`mipmap-anydpi-v26/` ausente** → Android 13+ (API 33) muestra icono en forma circular recortada del PNG legacy, perdiendo calidad y diseño intencionado.

### Herramienta Propuesta: adaptive-icon-validator

```
### Herramienta Propuesta: adaptive_icon_validator
- **Qué automatiza:** Verifica que la generación de adaptive icons sea completa después de ejecutar flutter_launcher_icons. Detecta ausencia de mipmap-anydpi-v26/, icon_source.png que no cumpla safe zone, y configuración inconsistente en pubspec.yaml.
- **Tipo:** Validador (extensión de store_prep_cli.dart)
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart check` (check existente ampliado con verificación de adaptive icons)
- **Impacto para el usuario final:** Evita icono roto en Android 13+ por olvido de regeneración. Reduce QA manual de ~10min a ~1s.
- **Prioridad:** Tarea 0 — implementar antes de regenerar iconos
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] icon_source.png existe y es 1024x1024 (VERIFICADO)
✅ [DATA] pubspec.yaml tiene adaptive_icon_background y adaptive_icon_foreground configurados (VERIFICADO)
✅ [CODE] mipmap-anydpi-v26/ic_launcher.xml existe después de regenerar iconos
✅ [CODE] mipmap-anydpi-v26/ic_launcher.xml contiene <adaptive-icon> con foreground y background
✅ [CODE] store_prep_cli.dart check verifica existencia de mipmap-anydpi-v26/
✅ [BACKEND] No aplica
✅ [FULLSTACK] Icono se muestra correctamente en Android 13+ (forma adaptable, no circular recortada)
✅ [FULLSTACK] Icono en Android <26 muestra PNG legacy sin cambio
✅ [DX] store_prep_cli.dart check reporta estado de adaptive icons
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| icon_source.png no respeta safe zone 66% | Media | Logo podría recortarse en formas circulares/squircle en Android 13+ | Verificar visualmente que logo central ocupa ≤ 66% del área total. Si no, crear versión con padding. |
| flutter_launcher_icons ^0.13.1 no genera mipmap-anydpi-v26/ en algunos entornos | Baja | Bug conocido en versiones antiguas del package | Verificar output después de ejecutar. Si falla, actualizar a versión más reciente (>0.14.0) o generar manualmente. |
| Regenerar iconos sobreescribe personalizaciones manuales | Baja | Si alguien editó ic_launcher.png manualmente, se pierde | Los PNG legacy actuales son autogenerados (544B hdpi = placeholder Flutter). Sin riesgo. |
| AndroidManifest referencia @mipmap/launcher_icon sin roundIcon | Baja | Algunos launchers usan roundIcon si está definido | Android resuelve adaptive icon sin roundIcon explícito. Verificar visualmente. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: Agregar check adaptive icons en store_prep_cli** | `scripts/store_prep_cli.dart` | Agregar función `_checkAdaptiveIcons()` que verifica `mipmap-anydpi-v26/ic_launcher.xml` existe y contiene `<adaptive-icon>`. Llamar desde `_runCheck()` y `_runAssetsValidate()` | `store_prep_cli.dart :: _checkBrandingIcons()` (L457-462) | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/store_prep_cli.dart check` reporta línea "Adaptive icons" con ✅ o ❌ |
| 1 | Ejecutar flutter_launcher_icons | Directorio `android/app/src/main/res/mipmap-anydpi-v26/` | N/A (tool de build autogenerado) | `flutter_native_splash` ya generó assets de splash correctamente | DATA | Baja | 0.25h | Ninguna | → verificar: `Test-Path "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"` devuelve true |
| 2 | Verificar contenido de ic_launcher.xml | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Debe contener: `<adaptive-icon>` con `<foreground>` apuntando a drawable y `<background>` apuntando a color/drawable | Android adaptive icon spec (https://developer.android.com/guide/topics/ui/look-and-feel) | CODE | Baja | 0.25h | Tarea 1 | → verificar: contenido XML tiene `<adaptive-icon>` + `<foreground>` + `<background>` |
| 3 | Verificar que iconos legacy no se rompieron | `android/app/src/main/res/mipmap-*/launcher_icon.png` | Archivos PNG en hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi intactos | Archivos actuales en mipmap dirs | CODE | Baja | 0.25h | Tarea 1 | → verificar: `dart run scripts/store_prep_cli.dart check` reporta branding_icons ✅ |
| 4 | Verificación visual en dispositivo/emulador Android 13+ | N/A (verificación manual) | Icono se muestra en forma adaptable (no circular rota) | N/A | FULLSTACK | Baja | 0.5h | Tareas 1-3 | → verificar: instalar APK en emulador API 33+, icono se ve correcto en home screen |

**Tiempo total estimado:** 1.75 horas

---

## 🔮 Roadmap (NO implementar ahora)

- Agregar `android:roundIcon="@mipmap/launcher_icon"` en AndroidManifest.xml para consistencia con launchers que priorizan roundIcon.
- Crear versión del icono con safe zone garantizada (foreground con padding al 66%) para adaptive icon foreground.
- Migrar a `flutter_launcher_icons` >= 0.14.0 que mejoró soporte para Android 14+ (monochrome icons).
- Agregar `monochrome_icon` config en pubspec.yaml para Android 13+ themed icons.