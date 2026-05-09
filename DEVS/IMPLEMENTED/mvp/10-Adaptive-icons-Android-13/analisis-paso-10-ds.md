# Análisis Técnico — Paso 10: Adaptive-icons-Android-13

**Agente:** ds
**Fecha:** 2026-05-09
**Fase:** mvp
**Prioridad:** Baja (post-MVP, no bloquea release)

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|----------|-------------|--------|-----------|
| 1 | `adaptive_icon_background: "#FFFFFF"` existe en pubspec.yaml | grep `pubspec.yaml` | ✅ | L133. `adaptive_icon_background: "#FFFFFF"` |
| 2 | `adaptive_icon_foreground: "assets/images/branding/icon_source.png"` existe en pubspec.yaml | grep `pubspec.yaml` | ✅ | L134. Misma ruta que `image_path` |
| 3 | `image_path: "assets/images/branding/icon_source.png"` | grep `pubspec.yaml` | ✅ | L131. Referencia al archivo fuente |
| 4 | `icon_source.png` existe en disco | Test-Path | ✅ | `assets/images/branding/icon_source.png` |
| 5 | `flutter_launcher_icons` en dev_dependencies | grep `pubspec.yaml` | ✅ | L83. `flutter_launcher_icons: ^0.13.1` |
| 6 | `mipmap-anydpi-v26/` directorio existe | Glob `**/mipmap-anydpi-v26/**` | ❌ | NO EXISTE. Adaptive icon XML nunca generado |
| 7 | `launcher_icon.png` existe en mipmaps | Glob `**/mipmap-*/launcher_icon.png` | ✅ | mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi — generados por flutter_launcher_icons previo |
| 8 | `ic_launcher.png` (legacy template) existe | Glob `**/mipmap-*/ic_launcher.png` | ✅ | 5 archivos. NO referenciados en AndroidManifest — dead files |
| 9 | AndroidManifest usa `@mipmap/launcher_icon` | grep `AndroidManifest.xml` | ✅ | L16. Correcto |
| 10 | min_sdk_android configurado | grep `pubspec.yaml` | ✅ | L132. `min_sdk_android: 21`. build.gradle.kts minSdk=24 (mayor) |

### Discrepancias encontradas

| # | Discrepancia | Resolución |
|---|-------------|------------|
| D1 | Plan dice "Agregar `adaptive_icon_background: "#FFFFFF"`" y "Agregar `adaptive_icon_foreground: assets/...`" → AMBAS YA EXISTEN en pubspec.yaml L133-134 | Plan desactualizado. Config completa en pubspec.yaml. Solo falta regenerar iconos. |
| D2 | `ic_launcher.png` (5 archivos) existen en mipmap-*/ pero NO son referenciados por AndroidManifest (usa `@mipmap/launcher_icon`) | Dead files del template Flutter inicial. No afectan. Opcional: eliminar en cleanup post-MVP. |

---

## 1️⃣ Análisis de Datos

No aplica. Paso 10 no toca datos persistentes, schemas, DB ni RLS.

- ✅ Schema: Sin cambios — 0 tablas, 0 modelos, 0 archivos JSON
- ✅ Integridad referencial: No aplica
- ✅ RLS: No aplica
- ✅ Índices: No aplica
- ✅ Tipos de datos: No aplica

---

## 2️⃣ Análisis de Código

**Archivos afectados:**
- `pubspec.yaml` (L128-134) — Config flutter_launcher_icons **YA EXISTE**
- `android/app/src/main/res/` — Regeneración de iconos raster + creación XML adaptive

**Funciones/clases:** Ninguna. Cambio puramente declarativo + comando.

**Patrón:** Sigue config estándar de `flutter_launcher_icons ^0.13.1`. Sin archivo de referencia adicional — la config en pubspec.yaml es self-contained.

⚠️ **Riesgo:** `icon_source.png` no verificado por dimensiones/resolución. La regeneración usará esta imagen para todos los density buckets. Adaptive icons Android esperan foreground con área de seguridad ~72% central (máscara: circle, rounded square, squircle, etc.).

---

## 3️⃣ Análisis de Backend

No aplica. Paso 10 es 100% frontend/build config.

- ✅ APIs: Sin cambios
- ✅ Middleware: Sin cambios
- ✅ Flujos: Sin cambios
- ✅ Contratos: Sin cambios
- ✅ Error handling: Sin cambios

---

## 4️⃣ Análisis de Fullstack + DX

**Flujo completo DB→Backend→Frontend→UX:**
No aplica — no hay flujo de datos. El cambio afecta solo al icono del launcher en Android API 26+. El icono adaptive reemplaza el icono plano actual en dispositivos Android 13+.

**Coherencia:**
- AndroidManifest ya referencia `@mipmap/launcher_icon`. Regenerar flutter_launcher_icons actualizará los PNGs existentes y creará `mipmap-anydpi-v26/launcher_icon.xml` para icono adaptive.
- No hay breaking changes: Android <26 ignora `mipmap-anydpi-v26/` y usa `mipmap-*/launcher_icon.png` (API 21+).

**Gaps:**
- El plan asume que las líneas adaptive NO existen. Ya existen desde configuración previa. La única acción pendiente es regenerar.
- El comando `flutter pub run flutter_launcher_icons` puede fallar si `icon_source.png` no cumple dimensiones esperadas por el package.

### DX & Tooling

```
### Herramienta Propuesta: Validador de iconos regenerados
- **Qué automatiza:** Verifica que `mipmap-anydpi-v26/launcher_icon.xml` existe tras regeneración + valida dimensiones de icono fuente
- **Tipo:** Subcomando en store_prep_cli.dart (assets validate ya existe)
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart assets validate`
- **Impacto para el usuario final:** Confirma en 1 comando que adaptive icons están correctos sin abrir Android Studio
- **Prioridad:** Baja — store_prep_cli.dart:54 ya valida `icon_source.png` via `assets validate`
```

El comando `store_prep_cli.dart assets validate` ya cubre validación de iconos. No se requiere herramienta DX nueva para este paso.

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] No aplica — 0 cambios en datos
✅ [CODE] pubspec.yaml L128-134 no modificado (config ya existe correcta)
✅ [BACKEND] No aplica — 0 cambios backend
✅ [FULLSTACK] `mipmap-anydpi-v26/launcher_icon.xml` generado tras regeneración
✅ [FULLSTACK] `@mipmap/launcher_icon` en AndroidManifest L16 sigue funcional
✅ [FULLSTACK] Icono se ve correcto en Android 13+ con forma adaptable
✅ [FULLSTACK] Icono existente en Android <13 no roto (mipmap-*/launcher_icon.png intacto)
✅ [DX] `flutter pub run flutter_launcher_icons` ejecuta sin error
✅ [DX] `store_prep_cli.dart assets validate` reporta iconos OK
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| Regeneración falla por imagen fuente inválida | Baja | `icon_source.png` puede no cumplir dimensiones/ratio esperado por flutter_launcher_icons | Verificar que PNG existe (sí) y tiene formato válido. El package falla con error claro si la imagen no sirve |
| `mipmap-anydpi-v26/` no se genera por versión package | Baja | `flutter_launcher_icons ^0.13.1` soporta adaptive icons, pero bug de version podría omitir XML | Verificar output del comando. Si no genera, actualizar a ^0.14.0+ |
| Iconos legacy (ic_launcher.png) son dead files pero no causan error | Baja | Template Flutter original nunca limpiado | Sin impacto funcional. Post-MVP cleanup opcional |
| Android <13 no muestra icono adaptive (comportamiento esperado) | Nula | Por diseño Android API <26 ignora mipmap-anydpi-v26 | Comportamiento correcto por platform. Sin acción requerida |

---

## 7️⃣ Plan de Implementación

### Tarea 0: DX — Validar estado pre-regeneración
| Campo | Valor |
|-------|-------|
| **Artefacto** | `store_prep_cli.dart` (ya existe) |
| **Interfaz** | `dart run scripts/store_prep_cli.dart assets validate` |
| **Patrón a seguir** | Comando existente, sin cambios |
| **Etapa** | DX |
| **Complejidad** | Baja |
| **Tiempo Est.** | 1min |
| **Dependencias** | Ninguna |
| **Verificación** | `dart run scripts/store_prep_cli.dart assets validate` reporta icon_source.png OK |
| **Nota** | Esta tarea es informativa. Si el comando falla, diagnosticar antes de T1 |

### Tarea 1: Regenerar iconos con flutter_launcher_icons
| Campo | Valor |
|-------|-------|
| **Artefacto** | `android/app/src/main/res/` (iconos regenerados) |
| **Interfaz** | `flutter pub run flutter_launcher_icons` |
| **Patrón a seguir** | Config ya completa en `pubspec.yaml` L128-134. Comando estándar del package |
| **Etapa** | CODE |
| **Complejidad** | Baja |
| **Tiempo Est.** | 1min |
| **Dependencias** | Tarea 0 (validación pre-vuelo) |
| **Verificación** | `ls android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml` existe |

### Tarea 2: Verificar post-regeneración
| Campo | Valor |
|-------|-------|
| **Artefacto** | `store_prep_cli.dart assets validate` (mismo comando T0) |
| **Interfaz** | `dart run scripts/store_prep_cli.dart assets validate` |
| **Patrón a seguir** | StorePrepCLI validation flow |
| **Etapa** | FULLSTACK |
| **Complejidad** | Baja |
| **Tiempo Est.** | 1min |
| **Dependencias** | Tarea 1 |
| **Verificación** | `dart run scripts/store_prep_cli.dart assets validate` + `flutter build apk --debug` compila sin error |

**Tiempo total estimado:** 3 minutos

---

## 8️⃣ Roadmap

- D2 (opcional): Eliminar `ic_launcher.png` dead files de `mipmap-*/`. No referenciados por AndroidManifest. Post-MVP cleanup.
- Verificar visualmente icono en dispositivo Android 13+ físico tras regeneración (QA manual).

---

## Métrica de Calidad

| Métrica | Resultado |
|---------|-----------|
| `proyecto-config.json` leído antes de explorar | ✅ |
| Elementos verificados (§0) | 10 (umbral paso simple: ≥ 8) |
| Discrepancias detectadas | 1 (D1: plan vs código) |
| Secciones completadas | 8 (0-7) |
| Etapas cubiertas | 4 (data sin cambios, code, backend sin cambios, fullstack+DX) |
| Criterios de aceptación | 9, todos verificables |
| Riesgos identificados | 4 (técnico, integración, legacy, comportamiento esperado) |
| Tareas atómicas (1 artefacto por tarea) | 100% — T0: validación, T1: regeneración, T2: verificación |
| Propuesta DX / Tooling | StorePrepCLI ya cubre. Sin herramienta nueva necesaria |
| Suposiciones no verificadas | 0 |
| Estimación de tiempo | Sí, 3min total |
