# 🚀 Documento Unificado: PLAN MVP VRM (Cámara Atómica)
**El Camino Más Corto y Realista hacia Producción (Stores)**

Este documento consolida el análisis de la arquitectura base, requerimientos comerciales y estado técnico actual, estructurando un plan de acción viable de 3 a 5 semanas para publicar la versión inicial (MVP).

---

## 1. DIAGNÓSTICO DEL ESTADO ACTUAL (70-75% Implementado)

En la actualidad, la aplicación cuenta con un esqueleto de UI/UX robusto, pero el "core técnico" (el guardado físico de la grabación y la unión algorítmica de video) requiere implementación directa.

| Componente | Estado | Comentarios y Siguientes Pasos |
| :--- | :---: | :--- |
| **F1-F2: Onboarding** | ✅ 100% | Flujo de bienvenida, identidad y perfíl guardado. |
| **F3: Laboratorio Ideas** | ✅ 95% | Input texto/voz, selección intención, panel avanzado listos. |
| **F12: Dashboard** | ✅ 90% | Navegación funcional. Falta reemplazar mocks con proyectos persistentes. |
| **F6-F7: Teleprompter** | ✅ 90% | Visualización, controles de tamaño y scroll en tiempo real operan. |
| **Mi Cuenta & Opciones** | ✅ 80% | Rutas operativas, UI lista (accesibles desde Dashboard). Faltan acciones de fondo en los toggles. |
| **F4-F5: Generación (IA)** | ⚠️ 60% | Mock hardcodeado. Falta conectar backend IA real o un sistema de templates (fallback). |
| **F8: Control Overlay** | ⚠️ 50% | El Overlay flotante en grabación existe, con sus sub-páginas, pero falta conectar botones a hardware respectivo. |
| **F8: Grabación de Clips** | 🔴 50% | *CRÍTICO:* La cámara inicia la UI, pero el Controller NO guarda archivos de video reales (`.mp4`) en disco. |
| **F9: Revisión Clips** | 🔴 40% | La estructura de pantalla existe. Falta iterar con clips reales previamente grabados. |
| **F10: Auto-Stitch** | 🔴 30% | *CRÍTICO:* Existe `stitcher_plugin.dart` a nivel de arquitectura, pero no ejecuta la "concatenación" a nivel sistema. |
| **F11: Exportación** | 🔴 20% | *FALTA:* Integrar guardado del final en Galería Local y disparar Share Sheet. |

### ⛔ Funcionalidades Excluidas Definidamente del MVP
*   **❌ Gamificación y Métricas de Desempeño:** Toda lógica de ranking, rachas, medición de muletillas (filler words), WPM y puntajes visuales quedan totalmente descartadas. Esto libera la app de al menos ~500 líneas complejas en tiempo real.
*   **❌ Publicación Directa a Redes (OAuth):** Se evita la burocracia de los APIs de TikTok/Facebook/YouTube (ahorro de otras ~500+ líneas). El MP4 final será exportado en frío y el OS del teléfono se encarga del resto.
*   **❌ Modos y Agentes Complejos:** El Maestro IA ("Director") y la capacidad Multi-dispositivo de código abierto pasan directo a la V2 / Etapa 3.
*   **❌ Influencer Profile Avanzado:** Por ahora mantendremos el flujo lineal sin distracciones complejas a nivel identitario de cuenta social.

---

## 2. RUTA CRÍTICA MÍNIMA (Estimación: 15-22 Días, ~1500 a 1900 Líneas)

Esta es la ruta óptima orientada por progreso priorizado, asegurando una funcionalidad publicable continua.

### FASE 1: Core de Grabación (El valor de la herramienta) - Días 1 al 10
Objetivo Innegociable: Que el usuario logre ir desde `Idea → Guion → Grabar → Unir → Exportar`.
*   **Día 1-2 (Grabación Crítica):** Archivos `recording_page.dart`. Instalar invocaciones reales en el `_cameraController` para escribir clips temporales (`chunk_0_take_1.mp4`). Prestar máxima atención a permisos de FileSystem (`path_provider`).
*   **Día 3 (Revisión Visual):** Widget `ClipReviewScreen` usando `VideoPlayerController.file()` permitiendo repetir el "Take" o continuar al siguiente bloque del Script.
*   **Día 4-5 (Auto-Stitch por Línea de Comandos):** Mediante **`ffmpeg_kit_flutter`**. Consolidar los videos crudos de fragmentos secuenciales en un solo compilado a nivel FileSystem, creando el track `/final.mp4`. Incluye feedback/barra de proceso a usuario.
*   **Día 6 (Exportación):** Creación de métodos con `photo_manager` (guardado profundo a iCloud/Fotos) y `share_plus` (despliegue de modal nativo de Compartir).
*   **Día 7-8 (Persistencia Local Offline):** Estructurar `vrm_data` de modo que un `vrm_pipeline` que se canceló al medio pueda ser reanudado por el usuario usando persistencia JSON simple en almacenamiento interno nativo.
*   **Día 9-10 (IA Offline / Fallback):** Si el endpoint de backend externo falla, el sistema debe ser capaz de arrojar `templates` en crudo (Ej: Modelo PAS inyectando la Idea como String) partiéndolo mediante regex (`. ` y `,`) para tener guion a salvo.

### FASE 2: Interfaz Reactiva y Refinamiento Local - Días 11 al 13
*   **Día 11-12 (Toggles Operativos):** Volver real el "Modo de calle / Modo fantasma" o "Bloqueo de Auto-focus" ordenando parámetros duros a la librería de la cámara. Interconectar en tiempo real las preferencias (velocidad del prompter).
*   **Día 13 (Datos del Usuario):** Dotar la vista de cuenta del borrado de carpetas persistentes (`Clear All Data`) y leer correctamente los identificadores nativos en uso; todo conectado con el nuevo `dashboard_page`.

### FASE 3: Estabilidad y Pulimento Físico - Días 14 al 18
*   **Día 14-15 (Manejo de Críticos):** Blindaje (Try/Catches). Qué pasa cuando no hay memoria, o cuando la cámara rechaza la entrega de frames; proveer un "Recovery path" para el usuario visual.
*   **Día 16-17 (Performance de Fuego):** Ejecución rigurosa en dispositivos iOS y Android físicos para cazar **Lossy Memory Leaks**. Reducción del AppSize empaquetando con Proguard / optimización de los Assets inyectados.
*   **Día 18 (Carga e Interfaces UX):** Implementación masiva de estados intermedios. Pantallas de "Guardando...", Spinners apropiados, notificaciones de guión faltante.

### FASE 4: Puerta de Tiendas y Valla Legal - Días 19 al 21
*   **Día 19 (Gestión de Tienda & Legal):** Alojamiento Web del archivo `PRIVACY_POLICY.md` y actualización formal del `Info.plist` en iOS / `AndroidManifest.xml`. Sin un porqué documentado pidiendo la cámara, la app colapsa por rechazo manual del revisor.
*   **Día 20 (Branding):** Inyectar íconos oficiales App (1024x1024), LaunchScreen (Splash Screen Nativa), y 5 Capturas de uso a resolución máxima demostrando cada paso.
*   **Día 21 (Despliegue Criptográfico):** Generación del `.keystore` de Release, subida de paquetes AAB al Play Console rellenando cuestionario de Seguridad de Datos, y despliegue del `.ipa` final a Apple Transporter for Connect.

---

## 3. ARQUITECTURA CLAVE IMPRESCINDIBLE PARA EL MVP

### Dependencias Nuevas Prioritarias (`pubspec.yaml`):
```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.3  # Comando universal A/V para el Stitching offline.
  photo_manager: ^3.0.0       # Garantiza la escritura a nivel galería del celular.
  share_plus: ^7.0.0          # Llama al framework nativo social de iOS/Android.
  path: ^1.8.0                # Auxiliar obligatorio para consistencias FileSystem en todos los OS.
```

### Estructura Base de Datos en Disco (Persistencia Resiliente)
```text
/vrm_data/
  /projects/
    /{project_id}/
      input_schema.json        ← Parámetros crudos iniciales y template.
      script_bundle.json       ← Guion validado y recortado visualmente.
      session_data.json        ← Diccionario general de grabación.
      /clips/                  ← Audios y MP4 de tomas ('takes') crudas validas/descartadas.
      final.mp4                ← Autostitch final producto de ffmpeg exportable.
  user_profile.json            ← Preferencias maestras estáticas.
```

---

## 4. ANÁLISIS DE RIESGOS MAYORES

| Riesgo / Falla Prevista | Probabilidad | Impacto | Estrategia de Mitigación Inmediata |
| :--- | :---: | :--- | :--- |
| **`ffmpeg_kit` no transpila en C++ nativo iOS/Android** | Media | 🔴 ALTO | Poseer un build alterno con unificación lógica vía VideoPlayer (Playback) y captura manual, o concatenadores en Dart menores. |
| **Cámara crashea en Android 13+ por problemas de permisos** | Baja | 🟡 MEDIO | Empezar los Test en hardware real *HOY*, garantizando estabilización de plugins de hardware en Release. |
| **API Backend de IA bloqueado o en Demora** | Alta | 🟡 MEDIO | Uso de Fallbacks "Templates Hardcodeados" para simular respuestas locales al instante. |

---

## CONCLUSIÓN DE ATAQUE INMEDIATO (¿QUÉ HACEMOS HOY?)

La app está increíblemente bien cimentada en la base UI (75% codeada, 25% por terminar), pero es imperativo **trasladar el esfuerzo directamente al componente `_cameraController` que efectúa escritura de disco**, validando si esto no explota en un entorno `Release` de un móvil físico.
Este plan se acatará como la "Guía Principal VRM" hasta que `final.mp4` pueda reproducirse sanamente en la galería de su inventor.

---

## 📥 Pasos incorporados desde sugerencias de validación
> Incorporados el 2026-05-06 — Fase activa: mvp

## Paso 05: Catch-especifico-SessionIntegrityException

**Origen:** Sugerencia 🟡 de validacion — Paso 03
**Prioridad:** Media
**Fase:** mvp

### Objetivo
Reemplazar catch generico en `recording_page.dart` por `on SessionIntegrityException catch (e)` con feedback visual especifico (SnackBar naranja).

### Tareas
- [ ] Agregar `on SessionIntegrityException catch (e)` antes del catch generico en L535-548
- [ ] Mostrar SnackBar naranja con mensaje "Integridad de sesion comprometida — clips faltantes removidos"

### Criterios de Aceptacion
- [ ] SessionIntegrityException capturado con handler dedicado
- [ ] Usuario recibe SnackBar naranja (no gris generico)
- [ ] Catch generico posterior sigue funcionando para otras excepciones

### Notas
Depende de `recording_manager.dart:verifyIntegrityStatic()` que ya existe.

## Paso 06: MaterialBanner-notificacion-fallback-IA ✅ COMPLETADO

**Origen:** Sugerencia 🔵 de validacion — Paso 03
**Prioridad:** Baja
**Fase:** mvp
**Implementado en:** Paso 05 (Correcciones)

### Objetivo
Reemplazar SnackBar flotante por `MaterialBanner` sticky en `script_studio_page.dart:337` para notificacion de fallback IA.

### Tareas
- [x] Reemplazar `ScaffoldMessenger.showSnackBar()` con `ScaffoldMessenger.showMaterialBanner()`
- [x] Mantener mismo mensaje naranja y comportamiento de cierre

### Criterios de Aceptacion
- [x] Banner sticky visible hasta que usuario lo descarte
- [x] Mismo contenido informativo que SnackBar actual
- [x] No rompe flujo de ScriptStudio

### Notas
MaterialBanner es mas visible que SnackBar para estados de fallback.
Código ya implementado en Paso 05 (Correcciones). `script_studio_page.dart:338-363`.
Plan actualizado tras unificación de análisis (2026-05-07).

## Paso 07: Metricas-reales-sesion-RecordingEndPage ✅ COMPLETADO

**Origen:** Sugerencia 🔵 de validacion — Paso 03
**Prioridad:** Baja
**Fase:** mvp
**Implementado en:** Código existente (recording_end_page.dart:37-49) + Residuales 2026-05-07

### Objetivo
Reemplazar metricas hardcodeadas "42m" en `recording_end_page.dart:309` con datos reales de `SessionData`.

### Tareas
- [x] Conectar `RecordingEndPage` a `SessionData` del proyecto actual
- [x] Mostrar duracion real de clips grabados
- [x] Mostrar cantidad real de takes
- [x] Reemplazar progress:0.75 hardcodeado con getter _progress calculado
- [x] Pasar sessionData en stitch_progress_page.dart navegacion a /recording-end
- [x] Pasar finalVideoPath en recording_page.dart:826
- [x] Crear validador_metrics_session.dart con flag --progress-only

### Criterios de Aceptacion
- [x] Metricas reflejan datos reales de la sesion
- [x] Si no hay datos, mostrar "--" en vez de "42m"
- [x] Compatible con estado previo a primera grabacion
- [x] Progress circle no hardcodeado — usa chunksRecorded / totalChunks
- [x] Flujo Stitch→End pasa sessionData correctamente
- [x] DX: validador_metrics_session.dart ejecuta sin errores

### Notas
Ya implementado: `_durationMinutes` y `_totalTakes` calculan métricas reales desde `startedAt`/`lastUpdatedAt` y `takesPerChunk`. Fallback "--" cuando `sessionData` es null.
Residuales implementados 2026-05-07: progress real, sessionData en stitch, finalVideoPath en recording_page, validador DX.

## Paso 08: Migrar-debugPrint-residual-LoggerService

**Origen:** Sugerencia 🔵 de validacion — Paso 03
**Prioridad:** Baja
**Fase:** mvp

### Objetivo
Reemplazar 2 llamadas `debugPrint` residuales en `RecordingPage._applyHardwareSettings()` (L657, L662) con `LoggerService.log()`.

### Tareas
- [ ] Reemplazar `debugPrint('Setting flash mode to $mode')` con `LoggerService.log('CameraService', 'Setting flash mode to $mode')`
- [ ] Reemplazar segundo `debugPrint` similar

### Criterios de Aceptacion
- [ ] 0 llamadas a `debugPrint` en `recording_page.dart`
- [ ] Mensajes aparecen en `vrm_data/logs/app.log`
- [ ] Funcionamiento identico en debug y release

### Notas
Fix trivial (<5 lineas). LoggerService singleton ya disponible.

## Paso 09: vrm-health-check-fix-real

**Origen:** Sugerencia 🔵 de validacion — Paso 03
**Prioridad:** Baja
**Fase:** mvp

### Objetivo
Implementar cleanup real en `vrm_health_check.dart --fix` en vez de solo imprimir advertencia.

### Tareas
- [ ] Implementar logica de reparacion en `vrm_health_check.dart:120-122`
- [ ] Eliminar archivos temporales huerfanos en `vrm_data/tmp/`
- [ ] Resetear sesiones huerfanas sin proyecto padre

### Criterios de Aceptacion
- [ ] `--fix` ejecuta acciones concretas, no solo print
- [ ] Acciones documentadas en output
- [ ] No elimina datos de proyectos validos

### Notas
Sigue patron de `store_prep_cli.dart` donde los subcomandos ejecutan acciones reales.

## Paso 10: Adaptive-icons-Android-13

**Origen:** Sugerencia 🔵 de validacion — Paso 04
**Prioridad:** Baja
**Fase:** mvp

### Objetivo
Configurar `adaptive_icon_background` y `adaptive_icon_foreground` en `pubspec.yaml` para compatibilidad Android 13+.

### Tareas
- [ ] Agregar `adaptive_icon_background: "#FFFFFF"` en config flutter_launcher_icons
- [ ] Agregar `adaptive_icon_foreground: "assets/images/branding/icon_source.png"`
- [ ] Regenerar iconos con `flutter pub run flutter_launcher_icons`

### Criterios de Aceptacion
- [ ] `mipmap-anydpi-v26/` contiene adaptive icon config
- [ ] Icono se ve correcto en Android 13+ con forma adaptable
- [ ] No rompe iconos existentes en Android <13

### Notas
Post-MVP. No bloquea release actual. D6 del analisis-FINAL.

## Paso 11: Reparar-widget-test-roto

**Origen:** Sugerencia 🔵 de validacion — Paso 04
**Prioridad:** Baja
**Fase:** mvp

### Objetivo
Eliminar o reparar `test/widget_test.dart` que falla por referencia a widget counter inexistente.

### Tareas
- [ ] Opcion A: Eliminar `widget_test.dart` si no cubre funcionalidad real
- [ ] Opcion B: Reemplazar con test util que verifique renderizado de pantalla principal

### Criterios de Aceptacion
- [ ] `flutter test` pasa 18/18 o 17/17 (dependiendo si se elimina o reemplaza)
- [ ] No se pierde cobertura de tests existentes

### Notas
Test pre-existente del template Flutter inicial. Nunca fue relevante para VRM.

## Paso 12: Screenshots-store-ready

**Origen:** Sugerencia 🔵 (escalado) de validacion — Paso 04
**Prioridad:** Alta
**Fase:** mvp

### Objetivo
Capturar 5 screenshots en dispositivo real a resolucion store: 1080x1920+ (Android), 1284x2778+ (iOS).

### Tareas
- [ ] Conectar dispositivo fisico con app compilada en debug
- [ ] Capturar Dashboard (pantalla principal)
- [ ] Capturar Creacion de proyecto / Script
- [ ] Capturar Grabacion con overlay de control
- [ ] Capturar Revision de clips
- [ ] Capturar Exportacion / Performance
- [ ] Transferir a `assets/store/screenshots/` como step1.png..step5.png
- [ ] Ejecutar `dart run scripts/store_prep_cli.dart check` para verificar

### Criterios de Aceptacion
- [ ] 5 archivos PNG en `assets/store/screenshots/` 
- [ ] Cada archivo >= 1080x1920px (Android) o 1284x2778+ (iOS)
- [ ] `store_prep_cli.dart check` reporta screenshots OK
- [ ] Capturas en dispositivo real (no emulador)

### Notas
Tarea manual. Usar `adb shell screencap -p` o captura nativa. Guia en `dart run scripts/store_prep_cli.dart screenshots`. Es el unico blocker 🔴 remanente para release a stores.
