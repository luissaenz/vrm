# 📊 Análisis de Implementación: Día 3 - Revisión Visual (antigravity)

Este análisis define la arquitectura y el flujo de la pantalla `ClipReviewScreen`, el punto de control de calidad crítico dentro del pipeline de "Cámara Atómica".

---

## 1. Diseño Funcional
La función principal es permitir al usuario decidir el destino de cada fragmento grabado antes de que forme parte del ensamblado final.

### Flujo Detallado (Pipeline)
1.  **Cierre de Buffer:** Al detener la grabación en `RecordingPage`, se confirma la escritura del archivo en la ruta persistente del proyecto.
2.  **Transición Focalizada:** Navegación inmediata a `ClipReviewScreen` pasando el `path` del clip y el `segmentIndex`.
3.  **Reproducción Automática:** El video inicia en `loop` sin audio por defecto (configurable) para no aturdir al usuario.
4.  **Matriz de Decisión:**
    *   **"Repetir Toma":** Se marca el archivo para eliminación/limpieza y se retorna al estado de grabación del mismo segmento.
    *   **"Aceptar Fragmento":** Se actualiza el `session_data.json` marcando el segmento como completado y se dispara la navegación al siguiente bloque del script o al stitching final si es el último.

### Manejo de Casos Especiales
*   **Archivos Corruptos:** Si el driver de video falla al cargar, la UI debe degradarse elegantemente a un estado de "Error de archivo" con un botón prominente para "Volver a Grabar" inmediatamente.
*   **Abandono de Sesión:** Si la app se cierra, al reabrir, el Project Manager detectará un clip en "limbo de revisión" y forzará esta pantalla para evitar pérdida de progreso.

---

## 2. Diseño Técnico
Se propone un diseño desacoplado que utiliza el sistema de archivos como única fuente de verdad para el estado del clip.

*   **Componentes Clave:**
    *   `ClipReviewScreen`: Widget principal de la interfaz.
    *   `ClipPlayerProvider`: Controlador reactivo que gestiona el ciclo de vida de `VideoPlayerController`, asegurando la liberación de memoria en el `dispose`.
    *   `ActionController`: Orquesta la actualización de la persistencia local (JSON) antes de cualquier navegación.
*   **Modelos de Datos:**
    *   `SessionUpdate`: Objeto de transferencia que incluye el ID del proyecto, el índice del segmento y el nuevo estado (COMPLETED | REJECTED).
*   **UI Architecture:**
    *   Uso de `Stack` para mantener el video en background y controles de alto contraste (Glassmorphism) en el foreground.

---

## 3. Decisiones Tecnológicas
*   **`video_player` (Official):** Mantenemos la dependencia mínima para reducir el tamaño del binario y asegurar compatibilidad nativa con los buffers generados por la cámara.
*   **Lifecycle Awareness:** Implementación estricta de `WidgetsBindingObserver` para pausar el video si el usuario recibe una llamada o minimiza la app, preservando batería y recursos de GPU.
*   **Atomic Persistence:** La actualización del `session_data.json` debe ocurrir *antes* de la animación de salida para garantizar que un crash post-pantalla no revierta el progreso.

---

## 4. Riesgos y Cuellos de Botella
*   **Gestión de Memoria:** Es el riesgo más crítico. El encadenamiento de múltiples segmentos (ej. 20 bloques de guion) puede saturar la GPU si no se destruyen correctamente las instancias anteriores.
*   **I/O Race Conditions:** Intentar leer el video antes de que el `camera_controller` termine de cerrar el descriptor del archivo. Se implementará una pequeña espera reactiva (debounce) o validación de tamaño de archivo > 0.
*   **Thermal Throttling:** El uso intensivo de CPU (ffmpeg/camera) y GPU (video preview) puede calentar el dispositivo, lo que degradaría el performance.

---

## 5. Plan de Implementación
1.  **Skeleton UI [Tarea 1]:** Crear `clip_review_screen.dart` con soporte para temas oscuros y layout responsivo.
2.  **Video Logic [Tarea 2]:** Implementar el wrapper del reproductor con soporte para archivos locales (`path_provider`).
3.  **Persistence Bridge [Tarea 3]:** Integrar con el servicio de datos para actualizar el estado del proyecto al "Aceptar".
4.  **Flow Control [Tarea 4]:** Conectar la navegación circular entre `RecordingPage` -> `ClipReviewScreen` -> `RecordingPage` (next segment).
5.  **Quality Assurance [Tarea 5]:** Validar en hardware real que la transición sea fluida (< 300ms) y sin parpadeos visuales.

---
✅ **Análisis completado para el Día 3 por agende: antigravity**
