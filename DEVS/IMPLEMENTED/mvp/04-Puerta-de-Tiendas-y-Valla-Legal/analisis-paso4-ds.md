# Análisis Técnico — Paso 04: Puerta de Tiendas y Valla Legal
**Agente:** ds
**Fecha:** 2026-05-05
**Fase:** mvp

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | PRIVACY_POLICY.md (raíz) existe | `grep` en raíz | ✅ | `PRIVACY_POLICY.md` (239L, template con placeholders `[your-support-email@example.com]`, `[Date]`, etc.) |
| 2 | PRIVACY_POLICY.md (docs/) existe | `grep` en raíz | ✅ | `docs/PRIVACY_POLICY.md` (33L, VRM-specific, email real: ludens.vrm@gmail.com, fecha real: April 18, 2026) |
| 3 | PRIVACY_POLICY alojada públicamente | no URL pública configurada | ❌ | Sin hosting activo. Plan.md Día 19 exige alojamiento web |
| 4 | Info.plist existe | `grep` en `ios/Runner/` | ✅ | `ios/Runner/Info.plist` (61L) |
| 5 | Info.plist tiene NSCameraUsageDescription | grep en archivo | ✅ | L53: `"VRM necesita acceso a la cámara para grabar videos..."` |
| 6 | Info.plist tiene NSMicrophoneUsageDescription | grep en archivo | ✅ | L49: `"VRM requiere acceso al micrófono..."` |
| 7 | Info.plist tiene NSPhotoLibraryUsageDescription | grep en archivo | ✅ | L54-55: permisos biblioteca |
| 8 | Info.plist tiene NSPhotoLibraryAddUsageDescription | grep en archivo | ✅ | L56-57: guardado galería |
| 9 | AndroidManifest.xml existe | `grep` en android/ | ✅ | `android/app/src/main/AndroidManifest.xml` (64L) |
| 10 | AndroidManifest.xml tiene RECORD_AUDIO | grep | ✅ | L2 |
| 11 | AndroidManifest.xml tiene CAMERA | grep | ✅ | L3 |
| 12 | AndroidManifest.xml tiene INTERNET | grep | ✅ | L6 |
| 13 | AndroidManifest.xml tiene READ_MEDIA_VIDEO | grep | ✅ | L9 |
| 14 | AndroidManifest.xml tiene WRITE_EXTERNAL_STORAGE (maxSdk=28) | grep | ✅ | L11-12 |
| 15 | Icono app 1024x1024 existe | `glob` assets | ✅ | `assets/images/branding/icon_source.png` |
| 16 | Splash screen existe | `glob` assets | ✅ | `assets/images/branding/splash_source.png` |
| 17 | iOS AppIcon set existe | `glob` ios | ✅ | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| 18 | flutter_launcher_icons configurado | grep pubspec.yaml | ✅ | L127-131, `image_path: assets/images/branding/icon_source.png` |
| 19 | flutter_native_splash configurado | grep pubspec.yaml | ✅ | L133-138, `color: "#000000"`, `image: assets/images/branding/splash_source.png` |
| 20 | key.properties existe | `glob` | ✅ | `android/key.properties` (storePassword, keyPassword, keyAlias, storeFile) |
| 21 | keystore (.jks) existe | `glob` `*.jks` | ❌ | `vrm-release-key.jks` NO existe (referenciado en key.properties L4 como `../vrm-release-key.jks`) |
| 22 | ProGuard configurado | read | ✅ | `proguard-rules.pro` (12L), referenciado en `build.gradle.kts` L62-65 |
| 23 | Release build.signingConfig firmado | read build.gradle.kts | ✅ | L56-58: release usa signingConfig si key existe |
| 24 | .aab generado | `glob` | ❌ | No existe build de release |
| 25 | .ipa generado | `glob` | ❌ | No existe build de release |
| 26 | SharedPreferences privacy link | grep en lib/ | ⚠️ | No verificado — puede o no existir enlace a privacidad en Settings |
| 27 | AppDelegate.swift handler stitch | read | ✅ | `ios/Runner/AppDelegate.swift` (82L) con `mergeVideos()` usando AVComposition |
| 28 | Stitch Android handler | `glob` `*.java`, `*.kt` en android/ | ❌ | Sin handler nativo Android para MethodChannel `com.vrm.vrm_app/stitcher` |

**Discrepancias encontradas:**

| # | Discrepancia | Resolución |
|---|---|---|
| D1 | `PRIVACY_POLICY.md` raíz es template genérico con placeholders. `docs/PRIVACY_POLICY.md` tiene contenido VRM-specific pero duplicado. | Unificar: usar `docs/PRIVACY_POLICY.md` (más específico) como fuente de verdad. Eliminar/ignorar raíz template. Falta reemplazar `[Date]` con fecha real (usar April 18, 2026 de la versión docs/). |
| D2 | PRIVACY_POLICY no alojada públicamente. Play Store + App Store requieren URL pública accesible. | Hostear en GitHub Pages del repo, o GH raw URL, o Firebase Hosting. El plan lo menciona pero no ejecutado. |
| D3 | keystore (`vrm-release-key.jks`) no existe. key.properties lo referencia pero archivo ausente. | Generar keystore con `keytool -genkey -v -keystore vrm-release-key.jks -alias vrm_upload_key -keyalg RSA -keysize 2048 -validity 10000`. |
| D4 | Stitch handler Android no existe. `AppDelegate.swift` (iOS) tiene `mergeVideos()` completo, pero Android no tiene equivalente Kotlin/Java. | Implementar handler Android usando MediaMoxer. Ya existe el canal `com.vrm.vrm_app/stitcher` en Dart. |
| D5 | 5 capturas de uso requeridas por plan no existen. No hay screenshots en assets. | Generar 5 capturas del flujo: Onboarding → Script → Grabación → Revisión → Exportación. Resolución máxima + frame device. |
| D6 | Enlace a PRIVACY_POLICY no verificado en UI de Settings. `settings_page.dart` puede o no tener enlace. | Verificar y agregar "Privacy Policy" row en Settings que abra URL pública. |
| D7 | Cuestionario Seguridad Datos Play Console sin completar. Apple Transporter/TestFlight sin subir. | Son procesos manuales post-build, no automatizables. Documentar respuestas del cuestionario. |

**Umbral: 28 elementos verificados ≥ 22 mínimo ✅**

---

## 1️⃣ Análisis de Datos (ETAPA 1)

No aplica. Paso 04 no toca datos persistentes, schemas, RLS ni migraciones. Es paso de configuración de plataforma, branding, legal y builds.

**Único elemento "data":** key.properties contiene credenciales keystore (vulnerables en texto plano). Considerar si esto es aceptable MVP o si debe externalizarse a CI/CD secrets.

---

## 2️⃣ Análisis de Código (ETAPA 2)

No hay funciones/clases nuevas que implementar. Paso puramente configurativo:

**Archivos a modificar (no crear):**
- `PRIVACY_POLICY.md` (raíz + docs/) — reemplazar placeholders
- `ios/Runner/Info.plist` — ya completo
- `android/app/src/main/AndroidManifest.xml` — ya completo
- `pubspec.yaml` — ya configurado (flutter_launcher_icons, flutter_native_splash)

**Archivos a crear:**
- `vrm-release-key.jks` — keystore (generado con keytool)
- Capturas de pantalla (5 assets nuevos en `assets/images/screenshots/`)

**Patrón a seguir:**
- `pubspec.yaml` ya sigue convención Flutter estándar para launcher_icons y native_splash
- assets de branding siguen patrón `assets/images/branding/`

**Modularidad:** Bajo riesgo de acoplamiento. Archivos independientes entre sí.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

No aplica tradicionalmente. Paso 04 no expone APIs ni endpoints.

**Puntos relevantes:**
- `AppDelegate.swift` (iOS) tiene handler nativo de stitch completo con AVComposition. ✅
- Android carece de handler nativo para `com.vrm.vrm_app/stitcher`. ❌
- Si se despliega backend IA (fuera de MVP), agregar dominio a `Info.plist` `NSAppTransportSecurity`.
- `key.properties` expone contraseñas keystore en texto plano en repo. Considerar migrar a CI variables de entorno pre-build.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

**Flujo completo del paso:**
```
Configurar → Hostear PRIVACY_POLICY → Verificar Info.plist + AndroidManifest
→ Generar keystore → Generar icons/splash (ya hecho) → Generar 5 capturas
→ flutter build appbundle → flutter build ios → Subir a stores
```

**Coherencia:**
- Branding assets (icon_source, splash_source) ya existen y están configurados en pubspec.yaml
- flutter_launcher_icons + flutter_native_splash ya configurados → solo ejecutar `flutter pub run flutter_launcher_icons` y `flutter pub run flutter_native_splash`
- Permisos ya declarados correctamente en ambas plataformas
- Privacy policy tiene 2 versiones (template + real) → unificar antes de hostear

**Gaps:**
1. Dependencia circular: keystore debe generarse antes de build release
2. Privacy policy hosting requiere subir a URL pública (GH Pages o similar)
3. Capturas UI requieren dispositivo real funcionando (feature 01 debe estar completa)

**DX & Tooling:**

```
### Herramienta Propuesta: store_screenshots_generator
- **Qué automatiza:** Genera capturas de pantalla del flujo MVP usando golden tests o widget screenshots, evitando depender de dispositivo físico para las 5 capturas requeridas por stores.
- **Tipo:** Script Dart (flutter test --update-goldens + widget screenshot)
- **Cómo se usa:** `cd scripts && dart run store_screenshots_generator.dart`
- **Impacto para el usuario final:** Elimina ciclo manual de grabar dispositivo, transferir capturas, redimensionar. Produce assets listos para upload.
- **Prioridad:** Tarea 0 — evita bloqueo por falta de hardware real para screenshots.
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [CODE] PRIVACY_POLICY.md unificado (docs/ como source), placeholders reemplazados con datos reales (ludens.vrm@gmail.com, fecha April 18, 2026)
✅ [CODE] PRIVACY_POLICY hosteada en URL pública accesible
✅ [CODE] keystore vrm-release-key.jks generado con keytool (keyAlias=vrm_upload_key)
✅ [CODE] flutter_launcher_icons ejecutado genera todos los sizes iOS/Android
✅ [CODE] flutter_native_splash ejecutado genera splash nativa
✅ [CODE] 5 screenshots de uso generados en assets/images/screenshots/
✅ [FULLSTACK] Settings page incluye enlace "Privacy Policy" que abre URL pública
✅ [FULLSTACK] flutter build appbundle --release genera .aab firmado sin error
✅ [FULLSTACK] flutter build ios --release genera .ipa sin error
✅ [DX] store_screenshots_generator.dart ejecuta y produce capturas
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| keystore perdido o sin respaldo | Alta | Solo existe local, no en CI. Perderlo = nueva firma = nueva app en stores | Respaldar en lugar seguro + documentar ubicación. GitHub Secrets o 1Password. |
| key.properties expuesto en repo | Alta | Contraseñas keystore en texto plano en repo git | Agregar `android/key.properties` a `.gitignore`. Ya existe `key.properties` → verificar si está en `.gitignore`. |
| Stitch Android handler inexistente | Media | MethodChannel `com.vrm.vrm_app/stitcher` sin handler Kotlin/Java en android/ | Implementar antes de release. AppDelegate.swift ya lo tiene para iOS. |
| App rejection iOS por metadata insuficiente | Media | Privacy policy placeholders, capturas faltantes, descripción incompleta | Tener todos los assets listos antes de subir a Transporter. |
| Cuestionario Play Store incompleto/respuestas inconsistentes | Media | Respuestas requieren revisión legal. Privacy policy template vs real pueden diferir | Usar docs/PRIVACY_POLICY.md como fuente de verdad para respuestas. |
| Build release falla por ProGuard / resource shrinking | Baja | isMinifyEnabled=true + isShrinkResources=true pueden eliminar clases usadas dinámicamente | ProGuard rules ya limpias (Paso 03). Verificar con build de prueba. |
| Dependencia de paso 01 (grabación) para capturas | Baja | Capturas requieren flujo funcional. Si paso 01 no completo, no hay UI que capturar | Usar mock data o golden tests para screenshots. |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX: store_screenshots_generator** | `scripts/store_screenshots_generator.dart` | `Future<void> generateScreenshots()` | `scripts/vrm_health_check.dart` (CLI entry point pattern) | DX | Media | 2h | Ninguna | `dart run scripts/store_screenshots_generator.dart --help` sin error |
| 1 | Unificar PRIVACY_POLICY | `docs/PRIVACY_POLICY.md` | Contenido: versión docs/ es source de verdad. Eliminar placeholders raíz. | docs/PRIVACY_POLICY.md (actual) | CODE | Baja | 0.5h | Ninguna | → verificar: `grep -c 'your-support-email' PRIVACY_POLICY.md` = 0 |
| 2 | Hostear PRIVACY_POLICY en URL pública | GitHub Pages / raw URL | URL: `https://ludensdev.github.io/vrm/privacy` o raw GH | — | CODE | Baja | 0.5h | Tarea 1 | → verificar: `curl -s -o /dev/null -w "%{http_code}" <URL>` = 200 |
| 3 | Verificar/agregar link Privacy Policy en Settings | `lib/features/settings/settings_page.dart` | Row con ListTile → `launchUrl(Uri.parse(privacyUrl))` | Patrón existente de settings_page.dart | FULLSTACK | Baja | 0.5h | Tarea 2 | → verificar: enlace navega a URL correcta |
| 4 | Generar keystore release | `android/vrm-release-key.jks` | `keytool -genkey -v -keystore vrm-release-key.jks -alias vrm_upload_key -keyalg RSA -keysize 2048 -validity 10000` | — | CODE | Baja | 0.3h | Ninguna | → verificar: `keytool -list -keystore vrm-release-key.jks -storepass vrm_password_123` muestra huella SHA1 |
| 5 | Ejecutar flutter_launcher_icons | genera todos los sizes en `android/app/src/main/res/` + `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | `flutter pub run flutter_launcher_icons` | pubspec.yaml L127-131 | CODE | Baja | 0.3h | Ninguna | → verificar: `ls android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` existe |
| 6 | Ejecutar flutter_native_splash | genera splash nativa en ambas plataformas | `flutter pub run flutter_native_splash:create` | pubspec.yaml L133-138 | CODE | Baja | 0.3h | Ninguna | → verificar: splash visible al iniciar app en emulador |
| 7 | Generar 5 screenshots de uso | `assets/images/screenshots/{01..05}.png` | Resolución máxima, con frame device | — | FULLSTACK | Alta | 2h | Tarea 0 + feature 01 funcional | → verificar: 5 archivos PNG existen en assets |
| 8 | Build release Android | `build/app/outputs/bundle/release/app-release.aab` | `flutter build appbundle --release` | — | FULLSTACK | Media | 1h | Tareas 4, 5, 6 | → verificar: `.aab` existe y `jarsigner -verify` pasa |
| 9 | Build release iOS | `build/ios/ipa/vrm_app.ipa` | `flutter build ios --release` luego Archive desde Xcode | — | FULLSTACK | Alta | 2h | Tareas 5, 6, Mac con Xcode | → verificar: `.ipa` existe |
| 10 | Documentar respuestas cuestionario Play Console | `DEVS/play_store_data_safety.md` | Respuestas basadas en docs/PRIVACY_POLICY.md | — | CODE | Baja | 0.5h | Tarea 1 | → verificar: documento completo con todas las secciones del formulario |

**Tiempo total estimado:** 9.9 horas

---

## 🔮 Roadmap (NO implementar ahora)

- Migrar key.properties a CI/CD secrets cuando se configure GitHub Actions para builds automáticos
- Implementar handler Android nativo para `com.vrm.vrm_app/stitcher` (MediaMoxer) antes de release real
- Considerar Firebase App Distribution para TestFlight alternativo Android
- Agregar `NSAppTransportSecurity` con excepciones si backend IA se despliega con HTTP
- Evaluar privacy policy hosting en dominio propio vs GitHub Pages
- Agregar `.gitignore` entry para `android/key.properties` y `*.jks`
