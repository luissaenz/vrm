# 🧠 Análisis Técnico — Paso 10: Adaptive Icons Android 13+

**Agente:** ring  
**Fecha:** 2026-05-09  
**Paso:** 10 — Adaptive-icons-Android-13  
**Fase:** mvp  
**Prioridad:** Baja (post-MVP, no bloquea release actual)  
**Fuente:** `DEVS/plan.md` líneas 231-251

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `adaptive_icon_background` en pubspec.yaml | grep pubspec.yaml L128-134 | ✅ | `"#FFFFFF"` ya configurado en línea 133 |
| 2 | `adaptive_icon_foreground` en pubspec.yaml | grep pubspec.yaml L128-134 | ✅ | `"assets/images/branding/icon_source.png"` en línea 134 |
| 3 | `image_path` referencia icono fuente | grep pubspec.yaml L131 | ✅ | `"assets/images/branding/icon_source.png"` |
| 4 | `icon_source.png` existe en disco | ls assets/images/branding/ | ✅ | Archivo presente |
| 5 | `splash_source.png` existe en disco | ls assets/images/branding/ | ✅ | Archivo presente |
| 6 | `flutter_launcher_icons` en dev_dependencies | grep pubspec.yaml | ✅ | `^0.13.1` en línea 83 |
| 7 | `mipmap-anydpi-v26/` con adaptive XML | glob `**/mipmap-anydpi-v26/**` | ❌ | **NO EXISTE** — carpeta nunca generada |
| 8 | `launcher_icon.png` en mipmap-* | glob `**/mipmap-*/launcher_icon.png` | ✅ | Presente en mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi |
| 9 | `ic_launcher.png` legacy en mipmap-* | glob `**/mipmap-*/ic_launcher.png` | ✅ | 5 archivos residuales del template Flutter |
| 10 | AndroidManifest referencia `@mipmap/launcher_icon` | grep AndroidManifest.xml | ✅ | Línea 16: `android:icon="@mipmap/launcher_icon"` |
| 11 | `min_sdk_android: 21` en pubspec.yaml | grep pubspec.yaml | ✅ | Línea 132. `build.gradle.kts` tiene minSdk=24 (mayor, válido) |
| 12 | `build.gradle.kts` namespace y config | leer build.gradle.kts | ✅ | `namespace = "com.vrm.vrm_app"`, `minSdk = 24`, `compileSdk = 34` |
| 13 | `values-v31/styles.xml` configurado | leer values-v31/styles.xml | ✅ | Tiene `windowSplashScreenBackground` y `windowSplashScreenAnimatedIcon` para Android 12+ |

### Discrepancias encontradas

| # | Discrepancia | Resolución propuesta |
|---|---|---|
| D1 | Plan dice "Agregar `adaptive_icon_background`" y "Agregar `adaptive_icon_foreground`" → **AMBAS YA EXISTEN** en pubspec.yaml L133-134 | Plan desactualizado. La configuración es correcta. Solo falta **regenerar iconos**. |
| D2 | `ic_launcher.png` (5 archivos) existen en mipmap-*/ pero NO son referenciados por AndroidManifest (usa `@mipmap/launcher_icon`) | Dead files del template Flutter inicial. No afectan funcionalmente. Eliminar post-MVP. |
| D3 | `mipmap-anydpi-v26/` no existe → Android 13+ usa icono plano escalado en vez de adaptive | Ejecutar `flutter pub run flutter_launcher_icons` para generar `launcher_icon.xml` adaptive |

---

## 1️⃣ Análisis de Datos (ETAPA 1)

**No aplica.** Paso 10 es pura configuración de assets y build tooling. No involucra:
- Schema de base de datos
- Modelos de datos
- Persistencia
- RLS / políticas de acceso

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivos involucrados

| Archivo | Acción | Estado actual |
|---|---|---|
| `pubspec.yaml` (L128-134) | Config `flutter_launcher_icons` **ya completa** | ✅ No requiere modificación |
| `android/app/src/main/res/mipmap-anydpi-v26/` | **CREAR** — generar con `flutter_launcher_icons` | ❌ No existe |
| `android/app/src/main/res/mipmap-*/launcher_icon.png` | **REGENERAR** — reemplazar bitmaps legacy por versiones adaptive | ⚠️ Actuales son legacy |
| `android/app/src/main/res/values-v31/styles.xml` | Verificar config splash para Android 12+ | ✅ Ya configurado |

### Patrón a seguir

La configuración en `pubspec.yaml` sigue el estándar documentado de [`flutter_launcher_icons ^0.13.1`](https://pub.dev/packages/flutter_launcher_icons):

```yaml
# pubspec.yaml L128-134 — REFERENCIA (ya existe, no modificar)
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/branding/icon_source.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/branding/icon_source.png"
```

**Resultado esperado tras ejecución:**
- `mipmap-anydpi-v26/launcher_icon.xml` — XML adaptive con foreground/background
- `mipmap-*/launcher_icon.png` — PNGs regenerados a partir de `icon_source.png`

### Consideraciones

- `icon_source.png` debería ser **1024x1024 px** recomendado por el package. Dimensión real no verificada (verificar con `identify` o similar).
- Android adaptive icons usan una **máscara** (círculo, rounded square, squircle) definida por el OEM. El contenido foreground debe respetar el **safe zone ~72% central**.
- Android < API 26 ignora `mipmap-anydpi-v26/` y usa `mipmap-*/launcher_icon.png` sin cambios.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

**No aplica.** No hay APIs, endpoints, middleware ni contratos involucrados.

- ✅ Sin cambios en backend
- ✅ Sin nuevos endpoints
- ✅ Sin autenticación/autorización afectada

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo

```
pubspec.yaml (config existente)
    → flutter pub run flutter_launcher_icons
    → android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml (CREADO)
    → android/app/src/main/res/mipmap-*/launcher_icon.png (REGENERADOS)
    → Android 13+ muestra adaptive icon
    → Android <13 muestra PNG legacy (sin cambio)
```

### Coherencia

- ✅ AndroidManifest ya apunta a `@mipmap/launcher_icon` — no requiere cambio
- ✅ `build.gradle.kts` tiene `namespace`, `compileSdk`, `minSdk` correctos
- ✅ `values-v31/styles.xml` tiene config de splash screen para Android 12+
- ⚠️ **Gap:** No hay verificación automatizada post-generación de que el adaptive XML fue creado

### DX & Tooling

```
### Herramienta Propuesta: store_prep_cli.dart assets validate (EXISTENTE)
- **Qué automatiza:** Verifica que icon_source.png existe, que flutter_launcher_icons
  está configurado, y que splash/branding assets están presentes.
- **Tipo:** Subcomando CLI existente
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart assets validate`
- **Qué NO cubre actualmente:** Verificación de que mipmap-anydpi-v26/launcher_icon.xml
  fue generado (solo valida que la CONFIG exista, no que la GENERACIÓN haya ocurrido).
- **Impacto para el usuario final:** Confirma en 1 comando que assets y config de iconos
  están listos antes de build release.
- **Prioridad:** Baja
```

**Mejora sugerida para DX (opcional):** Extender `store_prep_cli.dart assets validate` con un check que verifique la existencia de `mipmap-anydpi-v26/launcher_icon.xml` post-regeneración. Esto cerraría el gap de verificación.

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] No aplica — 0 cambios en datos/schema
✅ [CODE] pubspec.yaml L128-134: config flutter_launcher_icons correcta (ya existe, no modificar)
✅ [CODE] build.gradle.kts: namespace, minSdk, compileSdk coherentes
✅ [BACKEND] No aplica — 0 cambios backend
✅ [FULLSTACK] Ejecutar `flutter pub run flutter_launcher_icons` → mipmap-anydpi-v26/launcher_icon.xml generado
✅ [FULLSTACK] mipmap-*/launcher_icon.png regenerados (reemplazan legacy)
✅ [FULLSTACK] AndroidManifest L16: @mipmap/launcher_icon sigue funcional (sin cambio)
✅ [FULLSTACK] Android 13+ muestra icono adaptive con forma correcta (verificar en device)
✅ [FULLSTACK] Android <13 muestra icono sin cambios (backward compatible)
✅ [DX] `dart run scripts/store_prep_cli.dart assets validate` pasa
✅ [DX] `flutter build apk --release` compila sin errores de recursos
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `icon_source.png` no cumple dimensiones mínimas (1024x1024 recomendado) | Media | Package falla o genera icono pixelado | Verificar resolución antes de regenerar. `identify icon_source.png` o equivalente |
| `flutter_launcher_icons ^0.13.1` tiene bug y no genera `mipmap-anydpi-v26/` | Baja | Bug conocido en versiones anteriores | Verificar output del comando. Si falla, actualizar a `^0.14.0` |
| Adaptive icon se ve mal en ciertos OEMs (Samsung, Xiaomi) | Baja | Máscaras OEM varían | Probar en múltiples dispositivos. Área segura 72% central |
| `ic_launcher.png` legacy causa confusión en el repo | Muy baja | Dead files del template | Eliminar en cleanup post-MVP |

---

## 7️⃣ Plan de Implementación

> Regla: Tarea 0 siempre = DX & Tooling. El implementador DEBE ejecutarla primero.

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: Validar estado pre-regeneración** | `store_prep_cli.dart` (existente) | `dart run scripts/store_prep_cli.dart assets validate` | Comando existente, sin cambios | DX | Baja | 1 min | Ninguna | Comando ejecuta sin error y reporta icon_source.png OK |
| 1 | **Regenerar adaptive icons** | `android/app/src/main/res/mipmap-anydpi-v26/` + mipmap-\*/ | `flutter pub run flutter_launcher_icons` | Config en pubspec.yaml L128-134. Comando estándar del package | CODE | Baja | 1 min | Tarea 0 | `ls android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml` existe |
| 2 | **Verificación post-regeneración** | Repositorio completo | `dart run scripts/store_prep_cli.dart assets validate` + `flutter build apk --release` | StorePrepCLI validation + build check | FULLSTACK | Baja | 2 min | Tarea 1 | CLI pasa + APK compila sin errores de recursos |

**Tiempo total estimado:** ~4 minutos (tareas automáticas) + verificación manual en device

---

## 📋 Resumen ejecutivo

Este paso es **principalmente operativo**, no de implementación de código:

1. La configuración de `flutter_launcher_icons` **ya está completa** en `pubspec.yaml` (incluyendo `adaptive_icon_background` y `adaptive_icon_foreground`)
2. **Lo único pendiente** es ejecutar `flutter pub run flutter_launcher_icons` para generar los archivos adaptivos en `mipmap-anydpi-v26/`
3. Los iconos legacy `ic_launcher.png` son dead files que no afectan funcionalidad
4. El paso se resuelve en ~4 minutos de ejecución automatizada

> **Nota para el plan:** Las líneas del plan que dicen "Agregar `adaptive_icon_*`" están desactualizadas — ya fueron agregadas. Reescribir como: *"Regenerar iconos con `flutter_launcher_icons` y verificar `mipmap-anydpi-v26/`"*

---

## 🔮 Roadmap (NO implementar ahora)

- Extender `store_prep_cli.dart assets validate` con check de `mipmap-anydpi-v26/launcher_icon.xml` post-generación
- Agregar pre-commit hook que regenere adaptive icons automáticamente cuando cambie `icon_source.png`
- Evaluar diferenciar `icon_source.png` (monocromático para adaptive) vs `splash_source.png` a futuro

---

*Análisis generado el 2026-05-09 por agente ring. Verificado contra código fuente real del repositorio.*