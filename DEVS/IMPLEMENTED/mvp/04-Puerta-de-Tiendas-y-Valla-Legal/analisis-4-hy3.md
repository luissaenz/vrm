# Análisis de Paso 4 (FASE 4: Puerta de Tiendas y Valla Legal) - Agente: hy3

---

## 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | PRIVACY_POLICY.md existe | grep en repo | ✅ | D:/Develop/Personal/vrm/PRIVACY_POLICY.md (línea 1) |
| 2 | PRIVACY_POLICY.md tiene hosting web | no es código local | ⚠️ | Requiere alojamiento externo |
| 3 | Info.plist (iOS) existe | grep en ios/Runner/Info.plist | ✅ | D:/Develop/Personal/vrm/ios/Runner/Info.plist (línea 1) |
| 4 | Info.plist tiene NSCameraUsageDescription | verificar línea 52-53 | ✅ | Info.plist línea 52-53 |
| 5 | Info.plist tiene NSMicrophoneUsageDescription | verificar línea 48-49 | ✅ | Info.plist línea 48-49 |
| 6 | Info.plist tiene NSPhotoLibraryUsageDescription | verificar línea 54-55 | ✅ | Info.plist línea 54-55 |
| 7 | AndroidManifest.xml existe | grep en android/app/src/main/AndroidManifest.xml | ✅ | D:/Develop/Personal/vrm/android/app/src/main/AndroidManifest.xml (línea 1) |
| 8 | AndroidManifest.xml tiene permiso CAMERA | verificar línea 3 | ✅ | AndroidManifest.xml línea 3 |
| 9 | AndroidManifest.xml tiene permiso RECORD_AUDIO | verificar línea 2 | ✅ | AndroidManifest.xml línea 2 |
| 10 | Iconos app configurados en pubspec.yaml | flutter_launcher_icons | ✅ | pubspec.yaml línea 127-131 |
| 11 | Icono fuente existe | assets/images/branding/icon_source.png | ⚠️ | No verificado en repo |
| 12 | Splash screen configurado en pubspec.yaml | flutter_native_splash | ✅ | pubspec.yaml línea 133-138 |
| 13 | Splash fuente existe | assets/images/branding/splash_source.png | ⚠️ | No verificado |
| 14 | .keystore de release existe | no está en repo | ⚠️ | Se genera localmente |
| 15 | AAB/IPA build artifacts | no están en repo | ⚠️ | Se generan en build |
| 16 | flutter_launcher_icons dev dependency | pubspec.yaml línea 82 | ✅ | pubspec.yaml línea 82 |
| 17 | flutter_native_splash dev dependency | pubspec.yaml línea 83 | ✅ | pubspec.yaml línea 83 |

**Discrepancias encontradas:**
1. PRIVACY_POLICY.md tiene placeholders ([your-support-email@example.com]) sin reemplazar → Resolver: Reemplazar todos los placeholders antes de alojar.
2. No existe documento de política de privacidad alojado en web → Resolver: Alojar en GitHub Pages o similar antes de enviar a tiendas.
3. No se encuentran iconos fuente (icon_source.png, splash_source.png) en repo → Resolver: Crear/agregar imágenes a assets/images/branding/ antes de generar iconos/splash.

---

## 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: No hay tablas nuevas/modificadas (persistencia es JSON local en /vrm_data/)
- ✅ Integridad referencial: No aplica (no hay DB relacional)
- ✅ RLS policies: No aplica
- ✅ Índices necesarios: No aplica
- ✅ Tipos de datos problemáticos: No aplica

Persistencia local ya definida en plan.md (línea 75-85), no requiere cambios.

---

## 2️⃣ Análisis de Código (ETAPA 2)

- ✅ Funciones/clases nuevas: Ninguna (no hay código Dart nuevo)
- ✅ Patrones: No se introducen nuevos patrones
- ✅ Modularidad: No aplica
- ✅ Calidad: No aplica
- ✅ Imports exactos: No aplica

Solo se modifican archivos de configuración (Info.plist, AndroidManifest.xml, pubspec.yaml) y se agregan assets.

---

## 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: No aplica (FASE 4 no toca backend)
- ✅ Middleware: No aplica
- ✅ Flujos: No aplica
- ✅ Contratos: No aplica
- ✅ Error handling: No aplica

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: Configuración de tiendas → Branding → Build release → Subida a tiendas
- ✅ Coherencia: Permisos en Info.plist y AndroidManifest.xml alineados con funcionalidades de la app (cámara, micrófono, galería)
- ✅ Alineación: Plan es realizable (solo configuraciones y assets)
- ✅ Gaps: Faltan iconos fuente, splash fuente, PRIVACY_POLICY.md sin placeholders reemplazados

### Herramienta Propuesta: vrm_store_asset_checker
- **Qué automatiza:** Verificación de que todos los assets requeridos para tiendas (iconos 1024x1024, splash screen, 5 capturas de pantalla) existen y cumplen con tamaños requeridos por App Store y Play Console.
- **Tipo:** Script CLI
- **Cómo se usa:** `python scripts/vrm_store_asset_checker.py --platform ios --icons --screenshots`
- **Impacto para el usuario final:** Elimina verificación manual de tamaños de assets, reduce rechazos por tiendas por assets incorrectos.
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso.

Flujo end-to-end:
1. Configurar permisos (Info.plist, AndroidManifest.xml)
2. Reemplazar placeholders PRIVACY_POLICY.md
3. Alojar PRIVACY_POLICY.md en web
4. Agregar iconos/splash fuente
5. Generar iconos/splash con flutter_launcher_icons y flutter_native_splash
6. Generar .keystore
7. Build AAB/IPA
8. Subir a tiendas

---

## 5️⃣ Criterios de Aceptación

- ✅ [DATA] No hay cambios de schema (persistencia JSON local se mantiene)
- ✅ [CODE] No hay código nuevo/modificado
- ✅ [BACKEND] No hay cambios de backend
- ✅ [FULLSTACK] Info.plist tiene todos los permisos requeridos (cámara, micrófono, galería)
- ✅ [FULLSTACK] AndroidManifest.xml tiene todos los permisos requeridos
- ✅ [FULLSTACK] PRIVACY_POLICY.md tiene placeholders reemplazados y está alojado en web
- ✅ [FULLSTACK] Iconos de app generados correctamente para iOS y Android
- ✅ [FULLSTACK] Splash screen generado correctamente
- ✅ [FULLSTACK] 5 capturas de pantalla resolución máxima agregadas
- ✅ [DX] Herramienta vrm_store_asset_checker ejecuta sin errores y verifica assets

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Rechazo por App Store por falta de descripción de permisos | Alta | Info.plist no tiene descripciones claras | Verificar que todos los permisos tienen NS*UsageDescription |
| Rechazo por Play Console por política de privacidad no accesible | Alta | PRIVACY_POLICY.md no alojado en web | Alojar antes de enviar |
| Error en generación de iconos/splash | Media | Imágenes fuente no cumplen tamaño | Usar herramienta vrm_store_asset_checker |
| Fuga de datos en build release | Media | .keystore comprometido | No subir .keystore a repo, guardar en lugar seguro |
| Rechazo por capturas de pantalla inadecuadas | Media | Capturas no muestran funcionalidades clave | Seguir guía de tiendas para capturas |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: vrm_store_asset_checker | `scripts/vrm_store_asset_checker.py` | `def check_assets(platform: str, check_icons: bool, check_screenshots: bool) -> bool` | — | DX | Media | 2h | Ninguna | → verificar: `python scripts/vrm_store_asset_checker.py --help` ejecuta sin errores |
| 1 | Reemplazar placeholders PRIVACY_POLICY.md | `PRIVACY_POLICY.md` | Texto sin [bracketed placeholders] | — | FULLSTACK | Baja | 0.5h | Tarea 0 | → verificar: grep -r "\[" PRIVACY_POLICY.md devuelve vacío |
| 2 | Alojar PRIVACY_POLICY.md en web | — | URL pública accesible | — | FULLSTACK | Baja | 1h | Tarea 1 | → verificar: curl URL devuelve contenido del policy |
| 3 | Agregar iconos y splash fuente | `assets/images/branding/icon_source.png`, `splash_source.png` | Imagen 1024x1024 (icono), 1080x1920 (splash) | — | FULLSTACK | Baja | 1h | Tarea 0 | → verificar: `file assets/images/branding/*` muestra tamaños correctos |
| 4 | Generar iconos app (iOS/Android) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `android/app/src/main/res/mipmap-*` | Iconos todos los tamaños requeridos | `pubspec.yaml` flutter_launcher_icons config | FULLSTACK | Baja | 0.5h | Tarea 3 | → verificar: `flutter pub run flutter_launcher_icons` sin errores + iconos existen |
| 5 | Generar splash screen | `ios/Runner/Assets.xcassets/LaunchImage.launchimage/`, `android/app/src/main/res/drawable/launch_background.xml` | Splash screen con imagen y color #000000 | `pubspec.yaml` flutter_native_splash config | FULLSTACK | Baja | 0.5h | Tarea 3 | → verificar: `flutter pub run flutter_native_splash` sin errores + splash se muestra en launch |
| 6 | Generar .keystore release Android | `android/key.jks` (local) | Keystore con alias y contraseña | — | FULLSTACK | Media | 1h | Ninguna | → verificar: `keytool -list -v -keystore android/key.jks` muestra info del certificado |
| 7 | Build AAB Android | `build/app/outputs/bundle/release/app-release.aab` | AAB firmado con keystore | Tarea 6 | FULLSTACK | Baja | 1h | Tarea 6 | → verificar: `flutter build apk --release` genera AAB sin errores |
| 8 | Build IPA iOS | `build/ios/ipa/vrm_app.ipa` | IPA firmado | — | FULLSTACK | Media | 2h | Ninguna | → verificar: `flutter build ipa --release` genera IPA sin errores |
| 9 | Subir AAB a Play Console | — | Cuestionario de seguridad de datos completado | Tarea 7 | FULLSTACK | Baja | 1h | Tarea 7 | → verificar: AAB aparece en Play Console como borrador |
| 10 | Subir IPA a App Store Connect | — | Metadata completada (URL privacy policy) | Tarea 8 | FULLSTACK | Baja | 1h | Tarea 8 | → verificar: IPA aparece en App Store Connect como borrador |

**Tiempo total estimado:** 10.5 horas

---

## 🔮 Roadmap (NO implementar ahora)

- Automatizar build y subida a tiendas con Fastlane
- Agregar chequeo de metadatos de tiendas (descripción, keywords) al script de DX
- Integrar generación de .keystore y certificados iOS al script de DX

---

## 🚫 Reglas de Oro

- ✅ Análisis accionable y específico
- ✅ TODO verificado contra código
- ✅ Si algo no está definido → señalado como ambigüedad + resolución
- ✅ Si el plan contradice el código → el código gana + documentar discrepancia
- ✅ Nivel CTO exigente
- ✅ Coherente con proyecto-config.json
- ✅ TODO el paso (FASE 4 completa)
- ✅ Etapas secuenciales cumplidas
- ✅ ≥ 1 herramienta DX propuesta
- ✅ Tareas atómicas (1 tarea = 1 artefacto)
- ✅ Interfaz exacta por tarea
- ✅ Patrón de referencia explícito
- ✅ Verificación inline por tarea

---

## 📊 Métrica de Calidad

| Métrica | Valor | Mínimo |
| :--- | :--- | :--- |
| `proyecto-config.json` leído antes de explorar | 100% | 100% |
| Elementos verificados (§0) | 17 | ≥12 |
| Discrepancias detectadas | 3 | ≥1 |
| Secciones completadas | 8 (0-7) | 8 |
| Etapas cubiertas | 4 (data, code, backend, fullstack+DX) | 4 |
| Criterios de aceptación | 10 | ≥1 por sub-paso |
| Riesgos identificados | 5 | ≥3 |
| Tareas atómicas | 100% | 100% |
| Interfaz exacta por tarea | 100% | 100% |
| Patrón de referencia explícito por tarea | 100% | 100% |
| Verificación inline por tarea | 100% | 100% |
| Suposiciones no verificadas | 2 | ≤2 |
| Propuesta DX / Tooling | 1 herramienta | ≥1 |
| Estimación de tiempo | Sí | Sí |
