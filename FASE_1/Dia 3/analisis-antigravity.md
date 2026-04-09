# 🧠 ANÁLISIS TÉCNICO: REVISIÓN DE CLIPS (Día 3)

## 📋 Perfil del Rol
**Agente:** Antigravity (Principal Systems Architect)
**Objetivo:** Implementar la pantalla de revisión visual post-grabación para asegurar la calidad de cada fragmento antes de proceder.

---

## 🏗️ 1. Anatomía de Componentes

### `ClipReviewPage` (Widget: StatefulWidget)
- **Inputs (Props):**
  - `File videoFile`: El archivo `.mp4` recién grabado.
  - `int segmentIndex`: Índice del fragmento actual para saber qué sigue.
  - `ScriptAnalysis analysis`: Para mostrar el texto que se acaba de leer.
  - `String projectId`: Identificador del proyecto para persistencia.
- **Outputs (Events):**
  - `onKeep()`: El usuario acepta el clip. Navega al siguiente fragmento o al final.
  - `onRetry()`: El usuario descarta el clip. Vuelve a la cámara para re-grabar.
- **Estado Interno:**
  - `VideoPlayerController _controller`: Manejo del stream de video.
  - `bool _isInitialized`: Control de UI (mostrar spinner vs video).
  - `bool _isPlaying`: Estado visual del botón play/pause.

---

## 🔄 2. Mapa de Concurrencia y Lifecycle

- **Zonas Rojas:**
  - **Inicialización:** La llamada a `_controller.initialize()` es asíncrona. Si el usuario sale de la pantalla antes de que termine, el `dispose` debe ser infalible para evitar un "Zombie Controller".
  - **Acceso a Disco:** El archivo puede estar siendo finalizado por el sistema de archivos justo cuando intentamos leerlo. Se implementará un pequeño delay o re-intento si falla la carga inicial.
- **Limpieza (`dispose`):**
  - Es mandatorio llamar a `_controller.dispose()` en el método `dispose` del State.

---

## 🛡️ 3. Protocolos de Error y Resiliencia

- **Caso: Video Corrupto o No Encontrado:**
  - Si `VideoPlayerController` arroja un error en `initialize()`, se mostrará una tarjeta de error: "No se pudo cargar la previsualización".
  - Opción para el usuario: "Grabar de nuevo" (Retry) directamente.
- **Caso: Cierre de App en Revisión:**
  - El clip ya está en disco por el `RecordingManager`. Al reabrir, el flujo de "Reanudación" (Día 7-8) detectará el clip huérfano y preguntará si desea revisarlo.

---

## 📝 4. Diseño Técnico Nominativo

- **Archivo:** `lib/features/recording/clip_review_page.dart`
- **Clase:** `ClipReviewPage`
- **Controladores:**
  - `void _togglePlay()`: Switchea estado de reproducción.
  - `Future<void> _handleConfirm()`: Navega al siguiente paso.
  - `Future<void> _handleRetry()`: Elimina archivo y vuelve a grabar.

---

## 🎯 5. Diseño para la Salida (Pilares)

### 1. Diseño Funcional
- Interfaz premium en modo oscuro con previsualización a pantalla completa (o aspect ratio detectado).
- Overlay con el texto del guion correspondiente al fragmento para validación visual rápida.
- Barra de progreso discreta y controles minimalistas.

### 2. Diseño Técnico
- Integración con `video_player`.
- Uso de `Navigator.pushReplacement` para evitar ciclos infinitos de navegación entre Grabar -> Revisar -> Grabar.

### 3. Decisiones
- **¿Por qué VideoPlayer nativo y no Chewie?** Control total sobre la estética "Atomic" del MVP y menor peso de dependencias iniciales.
- **Persistencia:** La decisión de "Aceptar" actualiza el `SessionData` del `RecordingManager`.

### 4. Riesgos
- **Uso de Memoria:** Videos 4K en dispositivos antiguos pueden colapsar si no se liberan bien los recursos.
- **Race conditions:** Cambiar de fragmento mientras el video aún se está guardando en disco.

### 5. Plan de Implementación Atómico
1. **Tarea 1:** Crear `ClipReviewPage` con esqueleto de UI y botones (30 líneas).
2. **Tarea 2:** Implementar lógica de `VideoPlayerController` y lifecycle (40 líneas).
3. **Tarea 3:** Añadir overlay de texto del guion y barra de progreso (30 líneas).
4. **Tarea 4:** Conectar `RecordingPage` para que al disparar `_stopRecording()` navegue a la revisión (20 líneas).
5. **Tarea 5:** Implementar `_handleRetry()` con borrado físico del clip (15 líneas).

---
**Status:** READY FOR IMPLEMENTATION 🚀
