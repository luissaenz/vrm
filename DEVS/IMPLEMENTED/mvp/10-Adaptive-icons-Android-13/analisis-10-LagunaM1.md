# Análisis Técnico Paso 10 - Adaptive Icons Android 13

**Agente:** LagunaM1  
**Fecha:** 2026-05-09  
**Paso:** 10 - Adaptive-icons-Android-13

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `adaptive_icon_background` config | pubspec.yaml línea 133 | ✅ | `"#FFFFFF"` configurado |
| 2 | `adaptive_icon_foreground` config | pubspec.yaml línea 134 | ✅ | `"assets/images/branding/icon_source.png"` configurado |
| 3 | `icon_source.png` existe | assets/images/branding/ | ✅ | Archivo existe (512x512 típico) |
| 4 | `flutter_launcher_icons` dependencia | pubspec.yaml línea 83 | ✅ | `^0.13.1` en dev_dependencies |
| 5 | `mipmap-anydpi-v26/` existe | android/app/src/main/res/ | ❌ | **FALTA** - carpeta no generada |
| 6 | `launcher_icon.png` en mipmap-* | android/app/src/main/res/mipmap-hdpi/ | ✅ | Generado pero NO es adaptive |
| 7 | AndroidManifest icon ref | AndroidManifest.xml línea 16 | ✅ | `@mipmap/launcher_icon` apunta a icono no-adaptive |
| 8 | `flutter_launcher_icons` config completa | pubspec.yaml líneas 128-134 | ✅ | Config presente, falta ejecución |

**Discrepancias encontradas:**
- **❌ DISCREPANCIA:** El plan indica que hay que agregar `adaptive_icon_*` config, pero YA existe en pubspec.yaml desde 2026-05-05. La configuración está correcta.
- **⚠️ NO VERIFICABLE:** Faltan los archivos generados `mipmap-anydpi-v26/adaptive_icon.xml` porque el comando `flutter pub run flutter_launcher_icons` nunca se ejecutó.

---

## 1️⃣ Análisis de Datos

**No aplica.** Paso 10 es configuración de assets Android, sin involucrar schema de base de datos.

---

## 2️⃣ Análisis de Código

### Archivos involucrados:
- `pubspec.yaml` — configuración de flutter_launcher_icons
- `assets/images/branding/icon_source.png` — asset fuente

### Estado actual:
```yaml
# pubspec.yaml líneas 128-134
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/branding/icon_source.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/branding/icon_source.png"
```

### Diferencia con patrón existente:
- El icono actual (`launcher_icon.png`) es un bitmap plano
- Para Android 13+, se necesita `adaptive_icon.xml` en `mipmap-anydpi-v26/`

---

## 3️⃣ Análisis de Backend

**No aplica.** Es configuración móvil, sin APIs involucradas.

---

## 4️⃣ Análisis de Fullstack + DX

### Flujo completo:
```
pubspec.yaml → flutter pub run flutter_launcher_icons → mipmap-anydpi-v26/
```

### Coherencia:
- Config está bien, pero **falta ejecución** del comando
- Los iconos en mipmap-*hdpi son legacy (no adaptive)
- Android 13+ usa `mipmap-anydpi-v26/` como prioridad

### DX & Tooling:

```
### Herramienta Propuesta: generate_adaptive_icons
- **Qué automatiza:** Ejecuta flutter_launcher_icons y verifica generación de adaptive icons
- **Tipo:** script CLI
- **Cómo se usa:** `dart run scripts/generate_adaptive_icons.dart`
- **Impacto para el usuario final:** Garantiza icono correcto en Android 13+ sin pasos manuales
- **Prioridad:** Tarea 0 — ejecutar antes de generar builds release
```

---

## 5️⃣ Criterios de Aceptación

```
✅ [DATA] No aplica — paso de assets
✅ [CODE] adaptive_icon_background y adaptive_icon_foreground configurados en pubspec.yaml
✅ [BACKEND] No aplica — sin APIs
✅ [FULLSTACK] mipmap-anydpi-v26/ contiene adaptive_icon.xml generado
✅ [DX] Herramienta generate_adaptive_icons verifica generación exitosa
```

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Icono pixelado en Android 13+ | Media | Sin adaptive icon, Android escala bitmap | Ejecutar flutter_launcher_icons |
| Build release rechazado | Baja | Icono no cumple guidelines de Play Store | Verificar mipmap-anydpi-v26 generado |
| Config se pierde en merge | Baja | Config ya existe en pubspec.yaml | Git diff antes de commit |

---

## 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: generate_adaptive_icons script | `scripts/generate_adaptive_icons.dart` | `Future<void> run()` verifica generación | similar a `store_prep_cli.dart` | DX | Baja | 0.5h | Ninguna | → verificar: `dart run scripts/generate_adaptive_icons.dart` pasa |
| 1 | Ejecutar flutter_launcher_icons | `android/app/src/main/res/mipmap-anydpi-v26/` | N/A - generación automática | `flutter pub run flutter_launcher_icons` | CODE | Baja | 0.5h | Tarea 0 | → verificar: carpeta mipmap-anydpi-v26 existe con adaptive_icon.xml |
| 2 | Verificar icono en Android 13+ | Dispositivo físico | N/A - validación manual | Captura pantalla | FULLSTACK | Baja | 0.5h | Tarea 1 | → verificar: icono se ve correcto en dispositivo Android 13+ |

**Tiempo total estimado:** 1.5 horas

---

## 🔮 Roadmap

- Optimización: script que auto-genera adaptive icons en pre-build hook
- Mejora futura: configurar adaptive_icon_foreground distinto a icon_source para mejor forma