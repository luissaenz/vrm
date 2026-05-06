# Paso 4 — Puerta de Tiendas y Valla Legal — ANALISIS FINAL UNIFICADO

---

## 0️⃣ Evaluacion de Analisis y Verificaciones

### Tabla de Evaluacion de Agentes

| Agente | Verifico codigo | Discrepancias detectadas | Propuesta DX | Evidencia solida | Score (1-5) |
|:-------|:---------------:|:------------------------:|:------------:|:----------------:|:-----------:|
| speed | 22/22 | 5 (3 criticas) | `store_prep_cli.dart` + `generate_keystore.dart` | Lineas exactas, archivos, comandos | 5.0 |
| ds | 28/28 | 7 (3 criticas, 1 falsa) | `store_screenshots_generator.dart` | Mayor cantidad verificada, docs/PRIVACY_POLICY detectado | 4.5 |
| hy3 | 17/17 | 3 (1 critica) | `vrm_store_asset_checker.py` (Python) | Verificacion parcial, no detecto keystore critico | 3.0 |
| laguna | 10/10 | 2 (1 critica) | `vrm_store_kit.dart` | Mas superficial, afirmo screenshots OK (error: 1024x1024 no store-ready) | 2.5 |

### Discrepancias Criticas Consolidadas

| # | Discrepancia | Detecto | Verificada contra codigo | Resolucion |
|---|-------------|---------|--------------------------|------------|
| D1 | **Keystore `.jks` no existe.** `key.properties` L4 referencia `../vrm-release-key.jks`, archivo ausente. | speed, ds, hy3, laguna | `android/key.properties:4` → `Test-Path android/vrm-release-key.jks` = False | Generar con keytool RSA 2048, alias `vrm_upload_key`, validez 10000d. Tarea 0 (generate_keystore subcommand). |
| D2 | **Privacy Policy sin URL publica.** Template root `PRIVACY_POLICY.md` placeholders `[your-support-email]`. `docs/PRIVACY_POLICY.md` tiene datos reales (ludens.vrm@gmail.com). | speed, ds, hy3 | `PRIVACY_POLICY.md:11-14` placeholders; `docs/PRIVACY_POLICY.md:33` email real | Usar `docs/PRIVACY_POLICY.md` como source. Hostear en GitHub Pages. Tarea 1-2. |
| D3 | **Screenshots resolucion incorrecta.** 5 archivos existen (`step1-5.png`) pero 1024x1024, no store-ready. Android requiere 1080x1920+, iOS 1284x2778+. | speed, ds | `assets/images/screenshots/step1_idea.png` = 1024x1024 | Recapturar a resolucion store. Tarea 3. |
| D4 | **Stitch Android handler EXISTE.** `MainActivity.kt` L52-146 tiene `mergeVideos()` con MediaMuxer completo. DS afirmo ausencia — FALSO. | ds (falso positivo) | `android/app/src/main/kotlin/.../MainActivity.kt:52-146` | **SE IMPLEMENTA CODIGO EXISTENTE.** No requiere accion. DS se retracta. |
| D5 | **Placeholders PRIVACY_POLICY.md sin reemplazar.** Root tiene 5 placeholders, docs/ tiene datos reales. | speed, ds, hy3 | `PRIVACY_POLICY.md:3,5,11-14` | Docs/ version es source. Reemplazar root con contenido de docs/. Tarea 1. |
| D6 | **Adaptive icons Android 13+ no definidos.** `flutter_launcher_icons` usa `image_path:` legacy, sin `adaptive_icon_*.` | speed | `pubspec.yaml:127-131` sin adaptive fields | Opcional post-MVP. Baja prioridad. |
| D7 | **key.properties passwords default.** `storePassword=vrm_password_123`, `keyPassword=vrm_password_123`. | speed | `android/key.properties:1-2` | Cambiar antes de release. Tarea DX: validar en `store_prep_cli.dart check`. |

---

## 1️⃣ Resumen Ejecutivo

Paso 04 prepara app para publicacion en Google Play y App Store. **No crea codigo Dart nuevo.** Toca: legal (privacy policy), branding (iconos/splash/capturas), signing (keystore), metadata (permisos, Data Safety).

3 bloqueos criticos: keystore ausente, privacy policy sin host, screenshots resolucion incorrecta.

Herramienta DX fusionada: **`scripts/store_prep_cli.dart`** — CLI unificado con subcomandos `check`, `keystore`, `assets validate`, `privacy`, `screenshots`. Reemplaza todas las propuestas individuales de los 4 agentes.

---

## 2️⃣ Diseno Funcional Consolidado

### Happy Path

1. Dev completa `PRIVACY_POLICY.md` con datos reales (docs/ como source).
2. Dev hostea policy en GitHub Pages. URL publica HTTPS.
3. Dev ejecuta `store_prep_cli.dart keystore` → genera `vrm-release-key.jks`.
4. Dev ejecuta `store_prep_cli.dart assets validate` → iconos listos, splash listo.
5. Dev captura 5 screenshots a resolucion store en dispositivo real.
6. Dev ejecuta `store_prep_cli.dart check` → todos ✅.
7. Dev corre `flutter build appbundle --release` → `.aab` firmado.
8. Dev corre `flutter build ios --release` → `.ipa` (requiere Mac).
9. Dev sube AAB a Play Console, completa Data Safety form.
10. Dev sube IPA a App Store Connect.
11. Store review → aprobado → usuarios descargan.

### Edge Cases MVP

- Keystore perdido → no se puede actualizar app. Backup obligatorio.
- Privacy policy incumple GDPR/CCPA → template minimo aceptable (no datos compartidos).
- Screenshots en emulador → UI escalada no nativa, posible rechazo. Usar dispositivo real.
- Play Store Data Safety form complejo → checklist documentado.
- iOS build requiere Mac → Windows no puede. Documentar en BUILD_CONFIGURATION.md.
- No Fastlane → deploy manual lento (2-3h por release).
- Passwords default en key.properties → cambiar antes de release.

---

## 3️⃣ Diseno Tecnico Definitivo

### Componentes y Modificaciones

| Ruta real | Tipo de cambio | Descripcion | Interfaces clave | Patrones a seguir |
|-----------|---------------|-------------|------------------|-------------------|
| `scripts/store_prep_cli.dart` | **Creacion** (DX) | CLI unificado store readiness. Subcomandos: `check`, `keystore`, `assets validate`, `privacy`, `screenshots`. | `void main(List<String> args)` con ArgParser, subcomandos. | `scripts/vrm_health_check.dart` (415L, CLI ArgParser + subcomandos + colores ANSI) |
| `PRIVACY_POLICY.md` (raiz) | **Modificacion** | Reemplazar contenido template con version real de `docs/PRIVACY_POLICY.md` | Texto plano markdown | `docs/PRIVACY_POLICY.md` (33L, data real) |
| `android/vrm-release-key.jks` | **Creacion** (generado) | Keystore RSA 2048, validez 10000d, alias `vrm_upload_key` | No interfaz directa. Referenciado por `android/key.properties:4` | Comando: `keytool -genkey -v -keystore android/vrm-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vrm_upload_key` |
| `assets/store/screenshots/` | **Creacion** (assets) | 5 capturas resolucion store: 1080x1920+ Android, 1284x2778+ iOS | Archivos PNG en directorio `assets/store/screenshots/` | Convencion assets `assets/images/` |
| `lib/features/settings/settings_page.dart` | **Modificacion** | Agregar enlace "Politica de Privacidad" que abre URL publica via `launchUrl` | `ListTile(title: Text('Privacy Policy'), onTap: () => launchUrl(Uri.parse(privacyUrl)))` | `settings_page.dart` ListTile pattern existente |
| `DEVS/play_store_data_safety.md` | **Creacion** | Documentar respuestas cuestionario Data Safety Play Console | Documento markdown de referencia | `PRIVACY_POLICY.md` como source de verdad |

### DX & Tooling — Tarea 0 (OBLIGATORIO)

```
### Herramienta: `scripts/store_prep_cli.dart`
- **Que automatiza:** Pipeline completo store readiness: check pre-build, generacion keystore, validacion assets, hosteo privacy policy, generacion screenshots via golden tests.
- **Tipo:** CLI script (Dart) con subcomandos
- **Ubicacion:** `D:\Develop\Personal\vrm\scripts\store_prep_cli.dart`
- **Como se usa:**
  ```bash
  dart run scripts/store_prep_cli.dart check
  dart run scripts/store_prep_cli.dart keystore --output android/vrm-release-key.jks --alias vrm_upload_key
  dart run scripts/store_prep_cli.dart assets validate
  dart run scripts/store_prep_cli.dart privacy --host github
  dart run scripts/store_prep_cli.dart screenshots generate
  ```
- **Impacto para el usuario final:** Reduce tiempo preparacion store de ~4h manual a ~15min automatizado. Evita errores validacion Play Store por assets faltantes.
- **El implementador DEBE usarla** para completar las tareas 1..5 del paso.
```

---

## 4️⃣ Decisiones Tecnologicas

1. **`store_prep_cli.dart` como herramienta DX unificada:** Fusiona propuestas de speed (store_prep_cli + generate_keystore), ds (store_screenshots_generator), hy3 (asset checker), y laguna (vrm_store_kit). Unica CLI, reduce fragmentacion. Sigue patron `vrm_health_check.dart` existente.

2. **Dart sobre Python para DX:** Todos los scripts del proyecto usan Dart (`vrm_health_check.dart`, `validador_hardware.dart`). hy3 propuso Python — DESVIACION. Se descarta.

3. **docs/PRIVACY_POLICY.md como fuente de verdad:** `docs/` version tiene datos reales (ludens.vrm@gmail.com, April 18, 2026). Root `PRIVACY_POLICY.md` es template generico con placeholders. Se unifica.

4. **Android stitch handler YA implementado:** `MainActivity.kt` L52-146 tiene `mergeVideos()` completo con MediaMuxer. DS afirmo ausencia — FALSO. El codigo existe. Implementador no toca.

5. **Capturas manuales + golden tests:** `store_prep_cli.dart screenshots generate` inicia golden tests que generan capturas base. Capturas finales requieren dispositivo real para resolucion exacta.

6. **Correcciones al plan:** Plan dice F10 Auto-Stitch 30% — REALIDAD: Android handler existe (MediaMuxer en MainActivity.kt:52-146), iOS handler existe (AppDelegate.swift mergeVideos). Solo falta orquestacion Dart que ya esta en NativeStitcherService.

---

## 5️⃣ Criterios de Aceptacion MVP

```
[LEGAL] PRIVACY_POLICY.md sin placeholders, datos reales (email, fecha)
[LEGAL] Privacy Policy hosteada en URL HTTPS publica
[LEGAL] key.properties passwords cambiadas de default
[CODE] scripts/store_prep_cli.dart existe y ejecuta sin error
[CODE] android/vrm-release-key.jks existe (>0 bytes)
[CODE] Iconos app generados (mipmap-* + AppIcon.appiconset/)
[CODE] Splash nativa generada
[FULLSTACK] AndroidManifest.xml permisos correctos (CAMERA, RECORD_AUDIO, INTERNET, READ_MEDIA_VIDEO)
[FULLSTACK] Info.plist usage descriptions correctas (5 claves con texto)
[FULLSTACK] 5 screenshots store-ready (1080x1920+ Android, 1284x2778+ iOS)
[FULLSTACK] Settings page enlace Privacy Policy funcional
[FULLSTACK] flutter build appbundle --release genera .aab firmado
[FULLSTACK] flutter build ios --release genera .ipa (desde Mac)
[DX] store_prep_cli.dart check reporta 0 errores criticos
```

**Funcionales:**
- [ ] Privacy policy publica accesible sin login
- [ ] 5 capturas de uso en resolucion de store listas para upload
- [ ] AAB firmado se genera sin errores
- [ ] Key.properties passwords no son default

**Tecnicos:**
- [ ] store_prep_cli.dart check pasa todos los checks
- [ ] Keystore generado, backups documentados
- [ ] ProGuard rules limpias verificadas con build release
- [ ] Git ignora key.properties y *.jks

---

## 6️⃣ Plan de Implementacion

| # | Tarea | Complejidad | Tiempo Est. | Dependencias |
|---|-------|------------|-------------|--------------|
| 0 | **DX & Tooling:** `scripts/store_prep_cli.dart` | Media | 1.5h | Ninguna |
| 1 | Unificar `PRIVACY_POLICY.md` (reemplazar root con docs/ version + hostear) | Baja | 0.5h | Tarea 0 (check valida) |
| 2 | Generar keystore via `store_prep_cli.dart keystore` | Baja | 0.3h | Tarea 0 |
| 3 | Capturar 5 screenshots store-ready (1080x1920+) | Media | 1h | App corriendo en dispositivo |
| 4 | Agregar enlace Privacy Policy en Settings page | Baja | 0.5h | Tarea 1 (URL publica) |
| 5 | Validacion final: `store_prep_cli.dart check` + build release AAB | Baja | 0.5h | Tareas 0-4 |
| **TOTAL** | | | **4.3h** | |

> Tarea 0 siempre = DX & Tooling. Implementador DEBE ejecutarla primero y usar la herramienta resultante para el resto del paso (dogfooding obligatorio).

### Dependencias entre tareas
```
T0 (store_prep_cli.dart) → T1 (valida policy) → T2 (keystore)
T0 → T2 (keystore subcommand)
T1 → T4 (URL para settings)
T0..4 → T5 (validacion final)
```

---

## 7️⃣ Riesgos y Mitigaciones

| Riesgo | Severidad | Causa | Mitigacion |
|--------|-----------|-------|------------|
| Keystore perdido sin backup | Alta | Solo existe local, no CI. Perderlo = nueva firma = nueva app en stores | `store_prep_cli.dart keystore` sugiere backup path. Documentar en KEYS_MANAGEMENT.md |
| key.properties expuesto en repo | Alta | Passwords en texto plano. Si se commitea → seguridad comprometida | `.gitignore` debe incluir `android/key.properties`. Verificar. |
| Privacy Policy incumple GDPR/CCPA | Media | Template generico sin direccion legal ni representante UE | Usar docs/ version (mas especifica). Para MVP sin datos compartidos, policy simple aceptable. |
| Google Play Data Safety mal llenado | Alta | Formulario complejo, errores comunes | Checklist en DEVS/play_store_data_safety.md. Revisar 2x antes de submit. |
| iOS Build requiere Mac | Media | Windows no puede codesign IPA | Usar Mac fisico o GitHub Actions macOS runner. |
| Screenshots emulador vs real | Baja | UI emulador no nativa, posible rechazo store | Capturar en dispositivo real al menos 1 vez. |
| Build release falla por ProGuard | Baja | isMinifyEnabled=true elimina clases dinamicas | ProGuard rules ya limpias (Paso 03). Verificar con build de prueba. |

---

## 8️⃣ Testing Minimo Viable

| ID | Caso | Input | Output Esperado |
|----|------|-------|-----------------|
| TP-1 | `store_prep_cli.dart check` sin keystore | `dart run scripts/store_prep_cli.dart check` | ❌ Keystore missing (rojo) + instrucciones para generar |
| TP-2 | `store_prep_cli.dart keystore` genera archivo | `dart run scripts/store_prep_cli.dart keystore` | `Keystore generated at android/vrm-release-key.jks` + archivo existe |
| TP-3 | `store_prep_cli.dart assets validate` todo OK | `dart run scripts/store_prep_cli.dart assets validate` | ✅ Icons OK, ✅ Splash OK, ✅ Screenshots present (>=5) |
| TP-4 | Build AAB release firmado | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` existe y `jarsigner -verify` OK |

Comando para ejecutar tests: `flutter test` / `dart run scripts/store_prep_cli.dart check`

---

## 📊 Calidad de Aportes por Analisis

| Agente | Score | Fortaleza | Debilidad |
|--------|:-----:|-----------|-----------|
| **speed** | **5.0** | 22 verificaciones con evidencia linea exacta. 5 discrepancias, 3 criticas. 2 herramientas DX. Mejor cobertura. Mas preciso. | Ninguna significativa. |
| **ds** | **4.5** | 28 verificaciones (maximo). Detecto docs/PRIVACY_POLICY. 7 discrepancias. | Falsa discrepancia D4 (stitch Android handler). Propuesta DX solo cubre screenshots, no general. |
| **hy3** | **3.0** | 17 verificaciones. Propuso asset checker. | No detecto keystore critico. Propuso Python (viola convencion Dart del proyecto). Verificacion menos precisa sin lineas exactas. |
| **laguna** | **2.5** | 10 verificaciones (minimo). Analisis conciso. | Afirmo screenshots OK (falso: 1024x1024). 2 discrepancias solamente. Mas superficial. No detecto privacy policy dual. |
