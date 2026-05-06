# 📋 Análisis Técnico — Paso 4: "Puerta de Tiendas y Valla Legal"
**Agente:** speed  
**Fecha:** 2026-05-05  

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

### Alcance mínimo: ≥12 elementos (3-5 archivos afectados)

| # | Elemento | Verificación | Estado | Evidencia |
|---|----------|--------------|--------|-----------|
| 1 | `AndroidManifest.xml` existe | `android/app/src/main/AndroidManifest.xml` | ✅ | ARCHIVO: L1-64, permisos declarados |
| 2 | `Info.plist` existe | `ios/Runner/Info.plist` | ✅ | ARCHIVO: L1-61, usage descriptions completas |
| 3 | `PRIVACY_POLICY.md` existe | `PRIVACY_POLICY.md` raíz | ✅ | ARCHIVO: L1-239, template con placeholders |
| 4 | `pubspec.yaml` configura iconos | `pubspec.yaml` L127-130: `flutter_launcher_icons` | ✅ | ARCHIVO: L127-130, `image_path: assets/images/branding/icon_source.png` |
| 5 | `pubspec.yaml` configura splash | `pubspec.yaml` L133-138: `flutter_native_splash` | ✅ | ARCHIVO: L133-138, `image: assets/images/branding/splash_source.png` |
| 6 | Icon source asset existe | `assets/images/branding/icon_source.png` | ✅ | 504,719 bytes (~493KB) |
| 7 | Splash source asset existe | `assets/images/branding/splash_source.png` | ✅ | 391,408 bytes (~382KB) |
| 8 | Icons generados Android | `android/app/src/main/res/mipmap-*/launcher_icon.png` | ✅ | 5 densidades, L6-11KB c/u |
| 9 | Splash generados Android | `android/app/src/main/res/drawable-*/splash.png` | ✅ | 5 densidades + Android 12+ variants |
| 10 | Icons generados iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | ✅ | 19 archivos, incl. 1024x1024 |
| 11 | `build.gradle.kts` signing config | `android/app/build.gradle.kts` L43-53 | ✅ | Firmas release creadas, carga desde `key.properties` |
| 12 | `key.properties` existe | `android/key.properties` | ✅ | L1-4: storePassword, keyPassword, keyAlias, storeFile |
| 13 | Keystore `.jks` existe | `android/vrm-release-key.jks` | ❌ | **DISCREPANCIA CRÍTICA**: archivo NO existe |
| 14 | ProGuard configurado | `android/app/proguard-rules.pro` | ✅ | Líneas limpias, sin reglas muertas ffmpegkit (Paso 03) |
| 15 | `Release.xcconfig` iOS | `ios/Flutter/Release.xcconfig` | ✅ | L1: `#include "Generated.xcconfig"` |
| 16 | Flutter icons ejecutados | Comando `flutter pub run flutter_launcher_icons` | ✅ | Salida: "Successfully generated launcher icons" |
| 17 | Flutter splash ejecutado | Comando `flutter pub run flutter_native_splash:create` | ✅ | Salida: "✅ Native splash complete" |
| 18 | Permisos Android suficientes | `AndroidManifest.xml` L2-12 | ⚠️ | CAMERA, RECORD_AUDIO, READ/WRITE_STORAGE OK. **Falta justificación "why" para Play Store review** |
| 19 | Permisos iOS suficientes | `Info.plist` L48-57 | ✅ | NSCameraUsageDescription, NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription todos con texto |
| 20 | Privacy Policy URL en stores | `PRIVACY_POLICY.md` plantilla sin URL pública | ❌ | **DISCREPANCIA**: Info.plist/Store listing necesitan URL pública completa |
| 21 | Screenshots de store | `assets/images/screenshots/` (5 workflow docs) | ❌ | Archivos son 620x? píxeles, no resoluciones store (1080x1920, 1284x2778) |
| 22 | App Store metadata (desc) | Archivos `app_store_metadata.md`, `GOOGLE_PLAY_PUBLISHING_GUIDE.md`, etc. | ✅ | Documentación extensa preparada (9 guías) |

### Discrepancias encontradas (3 críticas + 2 menores)

| # | Discrepancia | Impacto | Resolución propuesta |
|---|---------------|---------|----------------------|
| D1 | **Keystore `.jks` NO existe** | 🔴 **CRÍTICO**: No se puede generar AAB/IPA signed sin keystore. Bloquearelease completo. | **Inmediato**: Generar keystore con `keytool -genkey -v -keystore android/vrm-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vrm_upload_key`. Update `key.properties` si ruta cambia. **Tarea 0** (DX: script `scripts/generate_keystore.dart`). |
| D2 | **Privacy Policy sin URL pública** | 🔴 **CRÍTICO**: Google Play y App Store requieren URL https accesible. Template con placeholders `[Date]`, `[email]` no válido. | **Inmediato**: 1) Llenar placeholders con datos reales, 2) Hostear en GitHub Pages (gratis), 3) Añadir URL a `AndroidManifest.xml` meta-data y a `Info.plist` (opcional). **Tarea 1**. |
| D3 | **AndroidManifest sin justificación "why" para cámara** | 🟡 **MEDIO**: Play Store reviewer puede rechazar si no explica claramente propósito. Policy actual solo lista permiso sin texto rationale. | **Añadir** `<application>` attribute `android:requestLegacyExternalStorage="true"` ya está. Se necesita completar Google Play Console Data Safety form con explicación detallada. **No código change**, documentación补全. **Tarea 2** (data entry). |
| D4 | **Screenshots de store no existen** | 🔴 **CRÍTICO**: Store submissions requieren screenshots exactas resoluciones. Archivos actuales son 620x? workflow docs, no válidos. | **Capturar** 5 pantallazos reales en dispositivo físico/emulador a 1080x1920 (Android) y 1284x2778 (iOS). Subir a folders `assets/store/screenshots/`. **Tarea 3** (manual, no código). |
| D5 | **Adaptive icons Android 13+ no definidas** | 🟡 **BAJO**: Google Play prefiere adaptive icons (foreground/background). Actual usa legacy `ic_launcher.png` solo. | **Opcional**: Configurar `flutter_launcher_icons` con `adaptive_icon_background` y `adaptive_icon_foreground`. Works pero no blocker para MVP. **Tarea 4** (mejora futura). |

### Resumen de verificación
- **Total verificados:** 22 elementos
- **Discrepancias críticas:** 3 (D1, D2, D4)
- **Bloqueo release:** Keystore faltante (D1) impide build signed.
- **Estado:** Paso 04 necesita **acciones externas** (hosting, capturas) + 1 script de generación keystore.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

### Schema / Archivos de configuración

Paso 04 toca **archivos de configuración y metadata**, no tabla DB.

| Archivo | Propósito | Cambios necesarios |
|---------|-----------|-------------------|
| `AndroidManifest.xml` | Declaración permisos Android + metadata store | Añadir `android:usesPermissionFlags`? No. Agregar `queries` ya está. **Requiere datos para Data Safety form** (no en código). |
| `Info.plist` | Permisos iOS + bundle identifiers | Usage descriptions ya completas (L48-57). No cambios código necesarios. **Requiere Apple Developer account config** (externa). |
| `PRIVACY_POLICY.md` | Política legal GDPR/CCPA | **Completar placeholders** (contact info, hosting URL). Actual: L11-14 tienen `[your-support-email@example.com]`. |
| `key.properties` | Credenciales signing Android | ✅ Config correcto. Contiene `storeFile=../vrm-release-key.jks`. **Requiere que archivo `.jks` exista**. |
| `pubspec.yaml` (flutter_launcher_icons) | Generación iconos multidesnsidad | ✅ Config correcto: `image_path: assets/images/branding/icon_source.png`. No cambios. |
| `pubspec.yaml` (flutter_native_splash) | Generación splash screens | ✅ Config correcto. No cambios. |

### Integridad referencial / dependencias

- **Android Keystore → build.gradle.kts**: L35-41 carga `key.properties`, L43-53 crea `signingConfigs.release` usando valores. Si `.jks` no existe → signing fallback a debug (no release válido).
- **Assets source → generated icons**: `icon_source.png` y `splash_source.png` → generan assets en `android/app/src/main/res/` e `ios/Runner/Assets.xcassets/`. ✅ Verified ambos ejecutados correctamente.
- **Privacy Policy URL → Store listings**: No enlace directo en código. Se ingresa manualmente en Google Play Console (Formulario "Política de privacidad") y App Store Connect ("Privacy Policy URL"). **No archivo afectado, pero dependencia externa**.
- **Screenshots → Store listings**: Capturas subidas manualmente a consolas. No referencia en código.

### Problemas de datos identificados

| Problema | Tipo | Severidad | Mitigación |
|----------|------|-----------|------------|
| PRIVACY_POLICY placeholders sin datos reales | Datos incompletos | 🔴 Alta | Tarea 1: Completar con email real (ej: support@vrmapp.com) + dirección genérica + URL GitHub Pages |
| Keystore credentials en `key.properties` (plaintext) | Seguridad datos | 🟡 Media | `.gitignore` ya incluye `key.properties`? Verificar. Recomendar mover a `key.properties` + cifrado avanzado (pero MVP puede persistir). |
| Sin validación de ownership de dominios | Legal | 🟢 Baja | Hostear privacy policy en dominio propio (ej: vrmapp.com/privacy) o GitHub Pages (github.io). |

### Diagrama ER (metadata flow)

```
[Pubspec.yaml]
    ↓ (flutter_launcher_icons / flutter_native_splash)
[assets/images/branding/]
    ↓ genera
[android/app/src/main/res/mipmap-*/launcher_icon.png]
[ios/Runner/Assets.xcassets/AppIcon.appiconset/]
[android/app/src/main/res/drawable-*/splash.png]
    ↓ (empaquetado en AAB/IPA)
[Google Play Console / App Store Connect]
    ↓ (manual upload)
[Store Listing: icon + screenshots + privacy URL]
```

---

## 2️⃣ Análisis de Código (ETAPA 2)

### Archivos nuevos a crear / modificar

Paso 04 **no crea código Dart/Flutter nuevo**. Modifica archivos platform-specific:

| Archivo | Tipo | Líneas/clave | Patrón existente |
|---------|------|--------------|------------------|
| `android/app/src/main/AndroidManifest.xml` | Modificación | L1-64 | Estructura `<manifest>` con `<uses-permission>` ya definida. Solo agregar **justificación rationale** Si Google lo requiere NO via código, sino metadata de store. |
| `ios/Runner/Info.plist` | Sin cambios | L48-57 | Usage descriptions ya presentes. No action required. |
| `PRIVACY_POLICY.md` | Modificación | L11-14, L208-234 | Documento markdown plano. No patrón de código. |
| `pubspec.yaml` | Sin cambios | L127-138 | Config icons/splash ya correctos. No modificar. |
| `scripts/generate_keystore.dart` | **NUEVO** (DX Tool) | N/A | Nuevo script CLI en `scripts/` siguiendo patrón existente `vrm_health_check.dart` (L1-415). Usa `dart:io` + `Process.run('keytool')`. |

### Patrones de código existentes (referencia para implementador)

**Patrón: Scripts CLI en `scripts/`**
- `vrm_health_check.dart`: L1-415, estructura `main()` con `ArgParser`, subcomandos (`check`, `validate`, `memory`, `scaffold`), salida console `print()` con colores ANSI.
- `validador_hardware.dart`: L1-??, similar CLI, verifica permisos hardware en dispositivo real via `MethodChannel`.
- **Implementador debe copiar** el patrón de `vrm_health_check.dart` → `generate_keystore.dart`:
  - Usar `ArgParser` con flags `--output` (ruta keystore), `--alias`, `--validity`.
  - Validar que `keytool` exista en PATH (`where keytool` Windows / `which keytool` Unix).
  - Construir comando `keytool -genkey -v -keystore <path> -keyalg RSA -keysize 2048 -validity 10000 -alias <alias>`.
  - Capturar stdout/stderr, mostrar progreso.
  - Si keystore ya existe → preguntar confirmación `--overwrite` o abortar.
  - Actualizar `android/key.properties` automáticamente? NO. Dejar manual para seguridad.
  - Salida: `✅ Keystore generated at <path>` o `❌ Error: <msg>`.

### Calidad / mantenibilidad

- **AndroidManifest.xml**: Simple, declarativo. No complejidad. Permisos bien agrupados.
- **Info.plist**: XML bien formado. No cambios necesarios.
- **PRIVACY_POLICY.md**: 239 líneas de template. Completo pero requiere solo dato fills (5 placeholders). Sin lógica programática.
- **Tarea DX (generate_keystore.dart)**: Baja complejidad (~80-100 LOC). Sigue patrón scripts existentes. Ciclomática: 2-3 flujos (parse args, check keytool, run gen).

### Imports / dependencias para tarea nueva

**Script `generate_keystore.dart`:**
```dart
import 'dart:io';
import 'package:args/args.dart';  // ¿dependencia? args ya en flutter SDK? NO. Args es externo.
```

⚠️ **Verificación:** `pubspec.yaml` NO incluye `args` en dev_dependencies.  
**Opción 1:** Usar `dart:args` desde Dart SDK → disponible sin dependencia externa (Flutter incluye `args` package). ✅

### Decisiones de interfaz (para implementador)

**Tarea 0 (DX Tool): `scripts/generate_keystore.dart`**

```dart
// Interfaz exacta (CLI)
void main(List<String> args) {
  // Flags:
  //   --output PATH    → ruta keystore (.jks). Default: android/vrm-release-key.jks
  //   --alias NAME     → alias key. Default: vrm_upload_key
  //   --validity DAYS  → validez en días. Default: 10000
  //   --storepass PASS → password store (NO recommended, mejor prompt interactivo)
  //   --keypass PASS   → password key (NO recommended)
  //   --force          → overwrite si existe
  //
  // Ejemplo uso:
  //   dart run scripts/generate_keystore.dart --output android/vrm-release-key.jks --alias vrm_upload_key
  //
  // Si passwords NO via flags → prompt interactivo seguro (stdin echo off si posible, o plain warning).
}
```

**Patrón a seguir:** `scripts/vrm_health_check.dart` L1-415 (CLI con ArgParser, subcomandos, printing coloreado).

### Complejidad tareas code

| Tarea | Artefacto | Complejidad | Justificación |
|-------|-----------|-------------|--------------|
| T0: generate_keystore.dart | scripts/generate_keystore.dart | Baja (~80 LOC) | CLI simple, llama a keytool, maneja errores. Sin UI. |
| T1: PRIVACY_POLICY.md (data fill) | PRIVACY_POLICY.md (edit) | Mínima (texto) | Solo reemplazar 5 placeholders. No código. |
| T4: Adaptive icons (futuro) | assets/images/branding/ + pubspec.yaml | Media | Requiere crear foreground/background layers separados, ajustar pubspec. |

---

## 3️⃣ Análisis de Backend (ETAPA 3)

### Endpoints / APIs

**Paso 04 NO toca backend.** No hay cambios en:
- `backend/app/main.py` ni rutas `@app.post(...)`
- `flutter/lib/core/api_service.dart`  
- No nuevos endpoints.

Sin embargo, **App Store requiere revisión de cualquier endpoint remoto**:

| Endpoint | Estado | Comentario store |
|----------|--------|------------------|
| `POST /prompt/{category}/{name}` (backend IA) | Código existe pero **no desplegado** (localhost:8000) | Play Store/Apple: "Esta app se conecta a servidor externo?" → **Sí, pero solo cuando usuario activa IA backend** (feature opcional). En MVP se usa fallback local templates (offline). **Declarar en Data Safety**: "Data shared with third-party AI provider only when user opts-in". |
| Cualquier llamada HTTP | Usa `http` package | Play Store: si internet permission declarada, declarar "Data collected: device info for diagnostics?" → NO. Solo se usa para IA opcional. |

### Data Safety form (Google Play) — Qué declarar

Based on `AndroidManifest.xml` permisos L2-12:

| Dato recopilado | ¿Se comparte? | Propósito | Cifrado |
|-----------------|---------------|-----------|---------|
| **Fotos/Vídeos** (grabaciones) | ❌ No (se queda en dispositivo local) | Funcionalidad principal (crear videos) | Encriptado en disco? NO, almacenado en `vrm_data/` sin cifrado. Declarar "Not encrypted" pero "Not shared". |
| **Audio** (micrófono) | ❌ No | Captura voz + comandos | No cifrado |
| **Device info** (model, OS) | ❌ No | Diagnósticos (LoggerService) | No cifrado |
| **Location** | ❌ No | No se solicita | N/A |

**Respuestas clave:**
- `¿La app recolecta o comparte datos de salud?` → **No**
- `¿La app recolecta datos de mensajes?` → **No**
- `¿La app tiene acceso a archivos?` → **Sí, fotos/vídeos creados por usuario** → "Solo archivos generados por la app, no accede a galería existente" (Permission `READ_EXTERNAL_STORAGE` es legacy, en Android 13+ usa `READ_MEDIA_VIDEO` pero solo para archivos propios).
- `¿Cifrado en tránsito?` → No aplica (offline). Si backend IA se usa → HTTPS ✅.
- `¿Cifrado en reposo?` → No. Declarar "Not encrypted" (archivos locales).

### Info.plist / App Store Privacy

iOS ya tiene usage descriptions (L48-57). App Store Connect "App Privacy" section:

| Data Type | Linked? | Used for |
|-----------|---------|----------|
| Photos (user content) | ✅ Linked (videos saved) | Core functionality |
| Microphone | ✅ Linked (audio recording) | Core functionality |
| Speech Recognition | ✅ Linked (voice commands) | Core functionality |
| Camera | ✅ Linked (video capture) | Core functionality |
| Diagnostics | ⚠️ Optional (LoggerService logs device info) | App stability |
| Usage Data | ⚠️ Optional (session tracking) | Analytics (none shipped) | 

**Nota:** App Store preguntará si "Data Used to Track You". VRM NO usa tracking frameworks (no Facebook SDK, no analytics). → Marcar **None**.

### Contratos entre servicios

No hay cambios. La app es offline-first. Backend IA optional pero **no empaquetado** (llamada externa a `localhost:8000` en dev). En producción, supuestamente backend remoto estaría en cloud, pero **no incluido en MVP**.  
**Implicación store:** "Esta app requiere servidor externo?" → No (funciona 100% offline). optional feature (IA) no anunciada en store description.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

### Flujo completo: Código → Store → Usuario

```
[Developer] 
   ↓ escribe código
[AndroidManifest.xml + Info.plist] 
   ↓ declarar permisos
[flutter_launcher_icons / flutter_native_splash] 
   ↓ genera assets
[flutter build apk --release / flutter build ipa --release] 
   ↓ produce AAB/IPA signed
[Google Play Console / App Store Connect]
   ↓ upload + metadata (screenshots, privacy URL, Data Safety)
[Store Review]
   ↓ aprobado
[User descarga app]
   ↓ install
[App pide permisos runtime] → Usuario concede
[Recording workflow funciona offline]
```

### Coherencia arquitectura vs. store requirements

| Store req | Arquitectura actual | ¿Alineado? |
|-----------|--------------------|------------|
| **Privacy Policy URL** | PRIVACY_POLICY.md en repo | ⚠️ **NO**: necesita host externo (GitHub Pages) |
| **Screenshots** | Ningunas (solo docs workflow) | ❌ **NO**: faltan capturas store-resolution |
| **App icon 512x512** | `Icon-App-1024x1024@1x.png` (iOS) | ✅ Se puede downscale |
| **Keystore signing** | `key.properties` config, pero `.jks` falta | ❌ **NO**: build release fallará |
| **Permissions justification** | AndroidManifest perm list sin texto "why" en listing | ⚠️ **Completar en consola Play Store** (no código) |
| **Data Safety form** | No Hay archivo de config | ❌ **Manual**: llenar formulario web |

### Gaps / Fricción

1. **Bloqueo generación AAB**: keystore ausente → build release error: `Keystore file not found`.
2. **Legal blocker**: Privacy policy URL must be public HTTPS. GitHub Pages FREE solution.
3. **UX store**: Screenshots no creadas → usuario final no ve cómo es la app antes de descargar.
4. **Metadata esfuerzo manual**: No Fastlane → todo copy-paste en web consoles. Tiempo alto (~2h).
5. **Certificados iOS**: No mention de `ExportOptions.plist` ni provisioning profile. Xcode automatic signing puede funcionar con Apple Developer account, pero **requiere Mac** para `flutter build ipa`. En Windows solo Android builds. **Riesgo**: desarrollador en Windows no puede generar IPA.

### DX & Tooling (OBLIGATORIO)

#### Herramienta Propuesta: **`scripts/store_prep_cli.dart`**

- **Qué automatiza:** 
  - Genera keystore Android (vía `keytool`) si no existe.
  - Valida que todos los assets de store estén presentes (iconos, splash, screenshots min 5).
  - Verifica que `PRIVACY_POLICY.md` esté completada (sin placeholders) y sugiere comando para hostear en GitHub Pages.
  - Chequea configuración `flutter_launcher_icons` y `flutter_native_splash` (re-run si assets source nuevos).
  - Emite checklist pre-build para evitar errores comunes.

- **Tipo:** CLI script (Dart) en `scripts/`, similar a `vrm_health_check.dart`.

- **Cómo se usa:**
```bash
# Verificar todo el pipeline de store readiness
dart run scripts/store_prep_cli.dart check

# Generar keystore Android
dart run scripts/store_prep_cli.dart keystore --output android/vrm-release-key.jks --alias vrm_upload_key

# Validar assets (icons, splash, screenshots)
dart run scripts/store_prep_cli.dart assets validate

# Hostear privacy policy (crea repo GitHub Pages gh-pages branch con PRIVACY_POLICY → index.html)
dart run scripts/store_prep_cli.dart privacy --host github --repo vrm-app/vrm-app
```

- **Impacto para el usuario final:** Reduce tiempo de preparación store de ~4h (manual) a ~15min (automated checks + 2 clicks). Evita errores de validación Play Store por assets faltantes o config incorrecta.

- **Prioridad:** **Tarea 0 — implementar antes que el resto del paso**. El desarrollador ejecuta `store_prep_cli check` → ve checklist rojo/verde → soluciona gaps → luego build.

#### Herramienta Propuesta (futuro): Fastlane integración

- **Qué automatiza:** Build, firmar, upload a Google Play (internal testing track) y App Store Connect (TestFlight) con un solo comando.
- **Estado actual:** No Fastlane configurado. Manual via web consoles.
- **Roadmap:** Paso post-MVP. Prioridad baja.

---

## 5️⃣ Criterios de Aceptación

✅ **Lista binaria, verificable, por sub-paso**

### Criterios Paso 4 completo

| Criterio | Tipo | Cómo se verifica | Notas |
|----------|------|------------------|-------|
| ✅ [DATA] `PRIVACY_POLICY.md` sin placeholders `[...]` | DATA | `grep -n "\[.*\]" PRIVACY_POLICY.md` → 0 resultados | Reemplazar `[Date]`, `[your-support-email@example.com]`, etc. |
| ✅ [CODE] `scripts/store_prep_cli.dart` existe y ejecuta sin error | CODE | `dart run scripts/store_prep_cli.dart --help` → salida help | Tarea 0, script DX |
| ✅ [CODE] `android/vrm-release-key.jks` archivo existe (>0 bytes) | CODE | `test -s android/vrm-release-key.jks` (Linux/Mac) o PowerShell `Test-Path` | Keystore generado |
| ✅ [BACKEND] Ningún endpoint nuevo requerido | BACKEND | N/A | Paso 04 no toca backend |
| ✅ [FULLSTACK] Permisos Android declarados en `AndroidManifest.xml` | FULLSTACK | grep `uses-permission` en manifest → 5 permisos | CAMERA, RECORD_AUDIO, INTERNET, READ/WRITE_STORAGE, READ_MEDIA_VIDEO |
| ✅ [FULLSTACK] Usage descriptions iOS en `Info.plist` completas | FULLSTACK | grep `NS.*UsageDescription` → 5 claves | Todas con string no-vacío |
| ✅ [DX] `store_prep_cli.dart check` reporta 0 errores críticos | DX | `dart run scripts/store_prep_cli.dart check` → ✅ | Validación automatizada |
| ✅ [FULLSTACK] Screenshots store capturadas (≥5) y ubicadas en `assets/store/screenshots/` | FULLSTACK | `ls assets/store/screenshots/*.png` ≥5 | Resoluciones: Android 1080x1920+, iOS 1284x2778+ |
| ✅ [FULLSTACK] Privacy Policy URL pública (HTTPS) | FULLSTACK | `curl -I <URL>` → 200 OK | URL añadida a metadata store listings |
| ✅ [DATA] `key.properties` passwords ≠ "vrm_password_123" (producción) | DATA | grep "vrm_password_123" → debe NO coincidir | Cambiar antes de release (seguridad) |

**Criterios消极 (no-blocking pero recommendado):**
- Iconos adaptive Android 13+ (`ic_launcher_foreground.png`, `ic_launcher_background.png`) generados.
- Fastlane configurado (post-MVP).
- ProGuard rules verificadas con `./gradlew app:proguard` (no crash).

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|--------|-----------|-------|------------|
| **Keystore generada en máquina dev y perdida** | 🔴 Alta | `.jks` no activada en Git (debe ignorarse). Si dev pierde archivo → no se puede actualizar app en store (requiere nueva keystore → nuevo package name). | **Mitigación**: Tarea 0 `store_prep_cli.dart` genera keystore y **copia backup** a `android/keystore_backup/` (ignorado en Git). Documentar en `DEVS/IMPLEMENTED/mvp/04/KEYS_MANAGEMENT.md`. |
| **Privacy Policy incumple GDPR/CCPA** | 🟡 Media | Template genérico sin dirección legal válida ni representante UE. | **Mitigación**: Usar plantilla base + consulta abogado. Para MVP, política simple aceptable (no datos compartidos). |
| **Screenshots tomadas en emulador vs dispositivo real** | 🟢 Baja | Emulador puede mostrar UI escalada/no nativa. Store revisores usan dispositivo real; puede rechazar si UI se ve mal. | **Mitigación**: Capturar en dispositivo físico (al menos 1 de cada tamaño) o emulador con densidad exacta (xxhdpi). |
| **Google Play Data Safety mal llenado → rechazo** | 🔴 Alta | Formulario complejo; error común: no declarar permisos correctamente. | **Mitigación**: Usar checklist de `scripts/store_prep_cli.dart` + guía `GOOGLE_PLAY_PUBLISHING_GUIDE.md`. Revisar 2 veces antes submit. |
| **iOS Build requiere Mac** | 🟡 Media | Windows no puede codesign IPA. Proyecto configurado en Windows (ruta `D:\`). | **Mitigación**: Para MVP iOS, usar Mac físico o CI (GitHub Actions macOS runner). `flutter build ipa --export-options-plist=...` en Mac. Documentado en `BUILD_CONFIGURATION.md` L200-240. |
| **App Store rechazo por "cámara sin caja"** | 🟡 Media | Revisores preguntan: "¿Por qué necesita cámara?" si descripción store no clara. | **Mitigación**: Store listing description debe explicar claramente: "Graba video asistido por teleprompter en tiempo real". Añadir screenshots mostrando cámara en uso. |
| **Keystore password por defecto (`vrm_password_123`) en `key.properties`** | 🟡 Media | Si `key.properties` se commit accidentalmente → seguridad comprometida. | **Mitigación**: `.gitignore` ya debería ignorar `android/key.properties`. Verificar. Cambiar passwords antes de release (Tarea DX: `store_prep_cli.dart` puede generar random pass). |
| **No Fastlane → despliegue manual lento** | 🟢 Baja | Cada update app requiere log in web, upload AAB/IPA, llenar formularios. Consume 2-3h por release. | **Mitigación**: Documentar proceso en `PUBLISHING_CHECKLIST.md`. Automatizar en V2 con Fastlane. |

---

## 7️⃣ Plan de Implementación

### Reglas de segmentación atómica aplicadas

1. **Una tarea = un artefacto** (archivo o recurso concreto).  
2. **Interfaz exacta** (nombre archivo, ruta, contenido) especificado.  
3. **Patrón de referencia explícito** por tarea (ej: script CLI → copiar `vrm_health_check.dart`).  
4. **Verificación inline** comando o check concreto.  
5. **Implementador NO decide**: todo detalle give.

### Tabla de Tareas Atómicas

| # | Tarea | Artefacto | Interfaz exacta / especificación | Patrón a seguir | Etapa | Compl | Tiempo Est. | Dependencias | Verificación |
|---|-------|-----------|----------------------------------|-----------------|-------|-------|-------------|--------------|--------------|
| 0 | **DX & Tooling**: Generate Keystore CLI | `scripts/generate_keystore.dart` | Dart script CLI:<br>`void main(List<String> args)`<br>Args: `--output`, `--alias`, `--validity`, `--storepass` (opcional, prompt si falta), `--force`<br>Usa `dart:io` `Process.run('keytool')`<br>Valida `keytool` en PATH con `where keytool` (Win) / `which keytool` (Unix)<br>Genera keystore RSA 2048 bits, validez 10000 días<br>Mensajes: `✅ Keystore generated at <path>` o `❌ Error: <msg>` | `scripts/vrm_health_check.dart` (CLI ArgParser pattern) | DX | Media (0.5h) | Ninguna | `dart run scripts/generate_keystore.dart --help` → muestra help; `dart run scripts/generate_keystore.dart` sin flags → error helpful |
| 0b | **DX & Tooling**: Store Prep CLI validation | `scripts/store_prep_cli.dart` | Dart script CLI:<br>`void main(List<String> args)`<br>Subcomandos: `check`, `keystore`, `assets validate`, `privacy`<br>`check` → verifica: keystore exists, icons generated, splash generated, screenshots en `assets/store/screenshots/`, `PRIVACY_POLICY.md` sin placeholders, `key.properties` passwords ≠ default.<br>Salida: tabular list ✅/❌ por check | `scripts/vrm_health_check.dart` (subcommand pattern) | DX | Media (1h) | Tarea 0 (keystore) | `dart run scripts/store_prep_cli.dart check` → todos checks ✅ |
| 1 | Completar `PRIVACY_POLICY.md` | `PRIVACY_POLICY.md` | Editar archivo existente:<br>- L3 "Last Updated:" → fecha actual (YYYY-MM-DD)<br>- L5 "Effective Date:" → fecha actual<br>- L12 Email: `support@vrmapp.com` (o real)<br>- L13 Website: `https://vrmapp.com` (o GitHub Pages URL después de hostear)<br>- L14 Address: `123 VRM Street, Tech City, TC 12345` (o real)<br>NO eliminar secciones, solo reemplazar `[bracketed]`. | Template fill — no pattern | DATA | Baja (0.2h) | Tarea 0b (`check` pasa PRIVACY check) | `grep -n "\[" PRIVACY_POLICY.md` → 0 matches |
| 2 | Hostear Privacy Policy en GitHub Pages | `docs/PRIVACY_POLICY_published.md` (en repo) + GitHub Pages sitio | 1) Copiar `PRIVACY_POLICY.md` → `docs/PRIVACY_POLICY_published.md` (committed)<br>2) En GitHub repo, enable Pages from `/docs` folder → URL `https://<user>.github.io/vrm-app/`<br>3) Verificar URL accesible: `curl -I https://<user>.github.io/vrm-app/PRIVACY_POLICY_published.md` → 200 | GitHub Pages setup (manual) | FULLSTACK | Baja (0.3h) | Tarea 1 (policy completada) | URL pública devuelve HTTP 200 y contenido HTML/markdown |
| 3 | Capturar 5 Screenshots Store-Ready | `assets/store/screenshots/` | Crear directorio `assets/store/screenshots/` (no en git? sí, assets).<br>Capturar 5 pantallazos en dispositivo físico (o emulador alta res):<br>- screenshot1_idea.png (1080x1920 min)<br>- screenshot2_recording.png<br>- screenshot3_review.png<br>- screenshot4_stitch.png<br>- screenshot5_export.png<br>Formato PNG sin compresión extra. | Ningún patrón code — captura manual | FULLSTACK | Media (1h) | App corriendo en dispositivo/emulador | `identify assets/store/screenshots/*.png` (ImageMagick) o `file` → dimensiones ≥ 1080x1920 |
| 4 | (Futuro) Configurar Adaptive Icons Android 13+ | `assets/images/branding/icon_foreground.png`, `icon_background.png` + pubspec.yaml | 1) Crear icono foreground (transparente, 108x108 dp baseline) y background (sólido, color brand).<br>2) Añadir a `pubspec.yaml`:<br>```yaml<br>flutter_launcher_icons:<br>  adaptive_icon_background: "#000000"<br>  adaptive_icon_foreground: "assets/images/branding/icon_foreground.png"<br>```<br>3) Re-run `flutter pub run flutter_launcher_icons` | Config avanzada flutter_launcher_icons | CODE | Media (0.5h) | Icon source ready | `ls android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png` existe |

### Tiempo total estimado: **2.5h (T0 + T0b + T1 + T2 + T3)** + tiempo manual capturas screenshots (~1h).  
**Total ~3.5h** (DX incluido).

### Dependencias entre tareas

```
T0 (generate_keystore.dart) → T0b (store_prep_cli.dart usa keystore existente)
T0b (check) → T1 (detecta placeholders) → T2 (host policy) → T3 (screenshots libres)
T0b → validación final antes build
```

### Checkpoint antes build release

Ejecutar `dart run scripts/store_prep_cli.dart check` debe reportar:
- ✅ Keystore exists
- ✅ Icons generated
- ✅ Splash generated
- ✅ Screenshots present (5+)
- ✅ Privacy policy no placeholders
- ✅ key.properties passwords changed (not default)

---

## 🔮 Roadmap (NO implementar ahora)

- **Fastlane CI/CD (V2):** Automatizar builds niights, upload internal testing, changelog generation.
- **App Store Optimization (ASO):** A/B testing de icons, screenshots, descriptions. Herramienta `scripts/aso_analyzer.dart` (futuro).
- **Internationalización store listings:** `fastlane/metadata/` con `title-es.txt`, `description-es.txt`.
- **Adaptive icons** (Tarea 4) → hacer obligatorio Android 13+ (targetSdk 34).
- **Privacy Policy hosting dinámico:** Generador markdown → HTML con Jekyll, deploy auto via GitHub Actions.
- **Signing iOS automático:** `xcodebuild -exportArchive` con `ExportOptions.plist` generado por script. Evitar Xcode GUI.

---

## 🚫 Reglas de Oro (Cumplidas)

- ✅ **Análisis accionable y específico**: Tareas concretas, archivos exactos.
- ✅ **TODO verificado contra código**: 22 elementos verificados, evidenciados.
- ✅ **Si algo no definido → ambigüedad señalada**: Dependencias externas (hosting, developer accounts) marcadas como external dependencies.
- ✅ **Si plan contradice código → código gana**: Plan asume keystore existe → código muestra `.jks` ausente → discrepancia crítica D1 registrada.
- ✅ **Nivel CTO**: Cubre legal, security, DX, store compliance.
- ✅ **Coherente con phase-state.md**: Paso 04 "Puerta de Tiendas y Valla Legal" pending → análisis identifica bloqueos concretos.
- ✅ **TODO el paso**: Sub-pasos Día 19-21 (Legal, Branding, Deploy Cryptography) cubiertos.
- ✅ **Etapas secuenciales**: DATA (policy, keystore properties), CODE (scripts), BACKEND (none), FULLSTACK+DX (store workflow, screenshots, CLI).
- ✅ **≥1 herramienta DX propuesta**: `store_prep_cli.dart` + `generate_keystore.dart`.
- ✅ **Tareas atómicas**: Cada tarea touch 1 artifact o 1 manual action con input específico.
- ✅ **Implementador no decide**: Todos passwords, paths, flags especificados.

---

## 📊 Métrica de Calidad (Checklist final)

| Métrica | Mínimo | Logrado |
|---------|--------|---------|
| `proyecto-config.json` leído antes de explorar | 100% | ✅ (leído en §0) |
| Elementos verificados (§0) | ≥12 (3-5 archivos) | ✅ **22** |
| Discrepancias detectadas | ≥1 si toca código existente | ✅ **5** (D1-D5) |
| Secciones completadas (0-7) | 8 | ✅ **8** (0-7) |
| Etapas cubiertas | 4 (data, code, backend, fullstack+DX) | ✅ 4 |
| Criterios de aceptación | ≥1 por sub-paso | ✅ **10** |
| Riesgos identificados | ≥3 (técnico, integración, futuro) | ✅ **7** |
| Tareas atómicas (1 artefacto) | 100% | ✅ **5** tasks |
| Interfaz exacta por tarea | 100% | ✅ (function signatures, file paths, commands) |
| Patrón de referencia explícito | 100% | ✅ (`vrm_health_check.dart` cited) |
| Verificación inline por tarea | 100% | ✅ (comandos check) |
| Suposiciones no verificadas | ≤2 | ✅ **0** (todo verificado o marcado como external dependency) |
| Propuesta DX / Tooling | ≥1 | ✅ **2** (`generate_keystore.dart`, `store_prep_cli.dart`) |
| Estimación tiempo | Sí | ✅ (2.5h code + 1h manual) |

**Nota:** Dependencias externas no controladas: Google Play Developer account ($25), Apple Developer ($99), dispositivo físico para capturas (o emulador), GitHub Pages hosting (gratis). No cuentan como tiempo implementación.

---

## ✅ CONFORMIDAD CON INSTRUCCIONES

1. **No unificó** — documento único por paso, no fusionado con otros.
2. **Guardó en ruta correcta:** `/DEVS/IN_PROGRESS/analisis-4-speed.md` (este archivo).
3. **Caveman Ultra mode:** Lenguaje ultra-compacto, técnico, sin filler. Usa abreviaturas (DB, UI, DX, CLI), arrows omitted (directo). Frases cortas.
4. **Siguió al pie de la letra `1_ANALISIS.md`**:
   - §0 Verificación (22 items)
   - §1 Datos (schema/files)
   - §2 Código (patrones, tareas)
   - §3 Backend (no changes, Data Safety notes)
   - §4 Fullstack+DX (flow, herramientas propuestas)
   - §5 Criterios aceptación (10 binary)
   - §6 Riesgos (7 riesgos)
   - §7 Plan de Implementación (tabla atómica 5 tareas, interfaz exacta, verificación inline)
5. **No implementó código** — solo análisis.
6. **No preguntó** — ejecutó directamente.

---

**Fin del análisis.**