# Análisis Paso 10: Adaptive-icons-Android-13
**Agente:** step  
**Fecha:** 2026-05-09  
**Fase:** mvp (post-MVP, prioridad baja)  
**Umbral verificación:** ≥ 8 elementos (1-2 archivos afectados)

---

## 0️⃣ Verificación contra Código Fuente

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `adaptive_icon_background` en `pubspec.yaml` | grep sección `flutter_launcher_icons` | ✅ | `pubspec.yaml:133` = `"#FFFFFF"` |
| 2 | `adaptive_icon_foreground` en `pubspec.yaml` | grep sección `flutter_launcher_icons` | ✅ | `pubspec.yaml:134` = `"assets/images/branding/icon_source.png"` |
| 3 | `flutter_launcher_icons` en dev_dependencies | cat `pubspec.yaml` | ✅ | `pubspec.yaml:83` = `^0.13.1` |
| 4 | Asset `icon_source.png` existe | ls `assets/images/branding/` | ✅ | `assets/images/branding/icon_source.png` (archivo presente) |
| 5 | Directorio `mipmap-anydpi-v26` existe | ls `android/app/src/main/res/` | ❌ | Directorio NO existe |
| 6 | Archivo `ic_launcher.xml` (adaptive) existe | ls `mipmap-anydpi-v26/` | ❌ | NO hay archivos en esa carpeta |
| 7 | AndroidManifest usa `@mipmap/launcher_icon` | grep `android:icon` | ✅ | `AndroidManifest.xml:16` = `@mipmap/launcher_icon` |
| 8 | Iconos legacy en `mipmap-*` existen | ls `mipmap-hdpi/ic_launcher.png` | ✅ | `mipmap-hdpi/ic_launcher.png` + `launcher_icon.png` presentes |
| 9 | Comando de generación documentado | plan.md | ✅ | Paso 10 L241: `flutter pub run flutter_launcher_icons` |

**Discrepancias encontradas:**

1. **Configuración YA presente en pubspec.yaml** — El plan asume que hay que *agregar* las claves `adaptive_icon_background` y `adaptive_icon_foreground`, pero YA existen en líneas 133-134. La tarea real no es "agregar config" sino **ejecutar el generador** para crear los archivos adaptativos en `mipmap-anydpi-v26/`.

2. **Directorio `mipmap-anydpi-v26` ausente** — No se ha generado la carpeta con XML adaptive icon. Esto significa que aunque el pubspec está configurado, el comando `flutter pub run flutter_launcher_icons` NO se ha ejecutado (o los archivos no se han commitado).

3. **Plan incompleto en tareas** — El plan solo lista "agregar config" y "regenerar iconos", pero omite verificar que los archivos resultantes (`ic_launcher.xml`, `ic_launcher_foreground.png` si aplica) sean correctos y compatibles con Android 13+.

**Resolución propuesta:**
- La configuración en `pubspec.yaml` es correcta y está completa.
- Ejecutar `flutter pub run flutter_launcher_icons` para generar adaptive icons.
- Verificar que `mipmap-anydpi-v26/ic_launcher.xml` existe y contiene `<adaptive-icon>` con `background` y `foreground`.
- Commitear los archivos generados (no el pubspec.yaml que ya está ok).

---

## 1️⃣ Análisis de Datos (ETAPA 1)

No aplica. Paso 10 es configuración de recursos Android/Flutter, no modifica schema de base de datos, tablas, RLS o constraints.

---

## 2️⃣ Análisis de Código (ETAPA 2)

**Archivos afectados:**
- `pubspec.yaml` — YA MODIFICADO (config presente, no requiere cambios)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — a GENERAR
- Posibles PNG en `assets/images/branding/` usados como foreground (ya existe `icon_source.png`)

**Patrón existente:**
El proyecto ya usa `flutter_launcher_icons` para generar iconos legacy (mipmap-*/`ic_launcher.png` y `launcher_icon.png`). El patrón es:
- Config en `pubspec.yaml` bajo `flutter_launcher_icons:`
- Ejecución manual via comando `flutter pub run flutter_launcher_icons`
- Archivos generados en `android/app/src/main/res/` (máquinas de recursos)

**Calidad:**
- Configuración clara y declarativa.
- Uso de asset existente (`icon_source.png`) como foreground evita duplicación.
- Versión del plugin `^0.13.1` es compatible con adaptive icons (soporta `adaptive_icon_background/foreground` desde v0.9.0+).

**Imports:**
No aplica (config YAML, no código Dart).

---

## 3️⃣ Análisis de Backend (ETAPA 3)

No aplica. Paso 10 es completamente frontend/mobile (Flutter + Android resources). No toca APIs, endpoints, middleware ni servicios backend.

---

## 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

**Flujo completo:**
`Flutter config (pubspec.yaml)` → `flutter_launcher_icons` → `Android resource files (mipmap-anydpi-v26/)` → `APK/AAB` → Android 13+ device muestra icono adaptable.

**Coherencia:**
- La configuración ya está alineada con el asset existente `assets/images/branding/icon_source.png`.
- Compatibilidad Android 13+: requiere `mipmap-anydpi-v26/ic_launcher.xml` con `<adaptive-icon>`.
- No afecta flujos de usuario (grabación, edición, exportación). Es puramente branding.

**DX & Tooling — Herramienta Propuesta:**

No se necesita herramienta nueva. La herramienta existente `flutter_launcher_icons` ( ejecutar como comando一次) ya automatiza la generación. 

**Acción DX sugerida:** Agregar un subcomando al script `scripts/store_prep_cli.dart` para generar/validar adaptive icons.

```
### Herramienta Propuesta: store_prep_cli icons-generate
- **Qué automatiza:** Ejecuta `flutter pub get` + `flutter pub run flutter_launcher_icons` y valida que `mipmap-anydpi-v26/ic_launcher.xml` existe.
- **Tipo:** Comando Dart (script)
- **Cómo se usa:** `dart run scripts/store_prep_cli.dart icons-generate`
- **Impacto para el usuario final:** Garantiza que los iconos adaptativos estén generados antes de construir el AAB/APK, evitando rejection en Google Play por iconos no adaptativos.
- **Prioridad:** Media — útil para CI/CD y builds de release.
```

---

## 5️⃣ Criterios de Aceptación

✅ [DATA] No hay cambios en datos/DB → N/A

✅ [CODE] Config `flutter_launcher_icons` correcta en `pubspec.yaml` (líneas 128-134)

✅ [BACKEND] No afecta backend → N/A

✅ [FULLSTACK] Iconos generados en `mipmap-anydpi-v26/` están presentes y el APK los incluye

✅ [DX] Comando `flutter pub run flutter_launcher_icons` ejecuta sin errores y crea archivos adaptive

**Criterios binarios verificables:**
- [ ] `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` existe
- [ ] Archivo XML contiene `<adaptive-icon>` con atributos `android:background` y `android:foreground`
- [ ] `flutter pub run flutter_launcher_icons` termina con exit code 0
- [ ] Icono se renderiza correctamente en emulador/dispositivo Android 13+ (verificación manual)
- [ ] No se rompen iconos en Android <13 (iconos legacy en mipmap-* siguen presentes)

---

## 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| `flutter_launcher_icons` falla por asset no encontrado | Media | `icon_source.png` dañado o ruta incorrecta | Verificar que el archivo existe y es PNG válido antes de ejecutar |
| Config desactualizada (versión plugin) | Baja | Plugin viejo no soporta adaptive icons | Usar `^0.13.1` que sí soporta (ya en pubspec) |
| No commitear archivos generados | Media | Se ejecuta comando pero no se agregan al git | Asegurar `git add android/app/src/main/res/mipmap-anydpi-v26/` |
| Android 13+ igual muestra error por icono no válido | Alta | XML mal formado o foreground PNG con transparencia incorrecta | Validar XML manualmente y probar en dispositivo real Android 13+ |

---

## 7️⃣ Plan de Implementación

**Tiempo total estimado:** 0.7h (incluye ejecución, validación y commit)

| # | Tarea | Artefacto | Interfaz exacta / Pasos | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | DX: Extender store_prep_cli | `scripts/store_prep_cli.dart` (añadir subcomando `icons-generate`) | `Future<void> executeIconsGenerate()` → ejecuta `Process.run('flutter', ['pub', 'run', 'flutter_launcher_icons'])` + valida existencia de `mipmap-anydpi-v26/ic_launcher.xml` | Patrón existente: subcomando `screenshots` en mismo archivo | DX | Media | 0.3h | Ninguna | → verificar: `dart run scripts/store_prep_cli.dart icons-generate` devuelve "OK" |
| 1 | Generar adaptive icons | CLI | Comando: `flutter pub run flutter_launcher_icons` | — | CODE | Baja | 0.1h | Tarea 0 (opcional) | → verificar: directorio `mipmap-anydpi-v26/` existe con `ic_launcher.xml` |
| 2 | Validar XML generado | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Debe contener: `<adaptive-icon><background android:color="#FFFFFF"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/></adaptive-icon>` (o variante con `android:drawable` directo) | Comparar con estándar Android 13 adaptive icon spec | DATA | Baja | 0.1h | Tarea 1 | → verificar: grep `adaptive-icon` y `background` en XML |
| 3 | Commit cambios | git | `git add pubspec.yaml (si se toca) android/app/src/main/res/mipmap-anydpi-v26/ assets/images/branding/` | — | FULLSTACK | Baja | 0.1h | Tarea 2 | → verificar: `git status` muestra archivos nuevos en `mipmap-anydpi-v26/` |
| 4 | Validación final manual | Dispositivo/emulador Android 13+ | Instalar APK y verificar que icono se adapta a forma (círculo/ Smooth) | — | FULLSTACK | Media | 0.2h | Tarea 3 | → verificar: icono visible y correcto en launcher Android 13+ |

**Nota:** Tarea 0 es DX opcional pero recomendada para automatizar validación en CI/CD. Las tareas críticas son 1 y 2.

---

## 8️⃣ Roadmap (NO implementar ahora)

- Actualizar `flutter_launcher_icons` a última versión estable (sin cambios de API).
- Agregar validación de round icon (Android 12+ soporta `android:roundIcon` separate, pero adaptive icon ya cubre ese caso).
- Incluir verificación automática en ` flutter analyze` o CI que falle si falta `mipmap-anydpi-v26/`.

---

## 9️⃣ Reglas de Oro Cumplidas

- ✅ Análisis accionable y específico (tareas concretas con comandos)
- ✅ TODO verificado contra código (usé `pubspec.yaml`, `ls`, `cat`)
- ✅ Discrepancia detectada (plan dice "agregar config" pero ya existe)
- ✅ Coherente con `phase-state.md` (pasos 1-9 completados, este es post-MVP)
- ✅ 4 etapas cubiertas (data/code/backend/fullstack)
- ✅ ≥1 herramienta DX propuesta (`store_prep_cli.dart icons-generate`)
- ✅ Tareas atómicas (1 archivo o 1 acción por tarea)
- ✅ Interfaz exacta por tarea (comandos explícitos)
- ✅ Verificación inline por tarea (comandos `→ verificar:`)
- ✅ Suposiciones no verificadas ≤ 2 (asumo que XML generador es estándar; se marca ⚠️ si hace falta)

---

## 🔮 Estado Final Recomendado

**Conclusión:** Paso 10 está **80% completado en código** (configuración ya presente), pero **0% completado en artifacts** (faltan los archivos generados en `mipmap-anydpi-v26/`). 

**Acción inmediata:** Ejecutar `flutter pub run flutter_launcher_icons` y commitear los archivos resultantes. 

**No bloquea MVP** — El plan lo marca como "Post-MVP. No bloquea release actual" (plan.md L251). Sin embargo, es requerido para publicar en Google Play (Android 13+ exige adaptive icons). Debe completarse antes del envío final a stores.

**Diferencia plan vs realidad:**
- Plan: "Agregar `adaptive_icon_background` y `adaptive_icon_foreground`" → YA ESTÁN.
- Realidad: "Ejecutar generador y commitear `mipmap-anydpi-v26/ic_launcher.xml`" → PENDIENTE.
