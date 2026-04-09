# 🏛️ BLUEPRINT MAESTRO: REVISIÓN DE CLIPS (Día 3)

## 1. Resumen Ejecutivo
Este Blueprint establece la especificación definitiva para la **Pantalla de Revisión de Clips** (`ClipReviewPage`). El objetivo es proporcionar al usuario una validación visual inmediata y sin fricciones después de grabar cada fragmento del guion. Se prioriza la resiliencia en el manejo de archivos de video, la limpieza de recursos y una UX "Atomic" que minimiza los taps necesarios para avanzar en la sesión de grabación.

---

## 2. Diseño Funcional Consolidado

### 2.1 Flujo Central
1.  **Transición Post-Grabación:** Al detener la grabación en `RecordingPage`, el sistema navega automáticamente a `ClipReviewPage` pasando la ruta del archivo `.mp4`.
2.  **Reproducción Automática:** El video inicia inmediatamente en loop y silenciado (mute) por defecto.
3.  **Decisión Binaria:**
    *   **✅ Aceptar (Siguiente):** Marca el clip como válido, actualiza la sesión y avanza al siguiente fragmento.
    *   **🗑️ Repetir (Rechazar):** Elimina el archivo físico de la toma actual y vuelve a la cámara para re-grabar el mismo fragmento.
4.  **Aprobación Pasiva (F7.3):** Si el usuario no interactúa durante 3 segundos, el clip se acepta automáticamente (configurable o toggleable en settings futuro, activo por defecto para el MVP).

### 2.2 Catálogo de Edge Cases
*   **Video Corrupto/Inexistente:** Si el controlador falla al inicializar, se muestra una pantalla de error con opción única de "Re-grabar".
*   **Cierre de App en Review:** El sistema detectará el clip "huérfano" (grabado pero no aceptado) al reanudar el proyecto y obligará a pasar por la revisión antes de permitir nuevas grabaciones.
*   **Filtro de Salida Prematura:** Se bloquea el botón "Atrás" físico/del sistema durante la inicialización para evitar leaks de memoria.

---

## 3. Diseño Técnico Definido

### 3.1 Arquitectura de Componentes
*   **`ClipReviewPage` (StatefulWidget):** Orquestador de la lógica de video y timers.
*   **`ClipVideoArea`:** Widget especializado en `VideoPlayer` con manejo de aspect ratio dinámico (9:16 o 16:9).
*   **`ReviewOverlay`:** Capa superior que muestra:
    *   Texto del guion (correspondiente al fragmento).
    *   Indicador de nivel: "FRAGMENTO X de Y".
    *   Contador de Intentos: "Take Z".
*   **`AutoAcceptBar`:** Barra de progreso visual que se consume en 3s para la aprobación pasiva.

### 3.2 Mapa de Concurrencia y Resiliencia
| Evento | Acción Crítica | Garantía |
| :--- | :--- | :--- |
| **Inicialización** | `VideoPlayerController.initialize()` | Envolver en try/catch + timeout de 5s. |
| **Navegación** | `Navigator.pushReplacement` | Evita que el usuario regrese a una toma "muerta" con el botón atrás. |
| **Cleanup** | `controller.dispose()` | Mandatorio en el método `dispose` del State, sin excepciones. |
| **I/O Disco** | `File(path).delete()` | Ejecutar de forma asíncrona pero bloqueando la navegación hasta confirmar (o fallar tras 1 retry). |

### 3.3 Esquemas de Datos
*   **`ClipStatus` (enum):** `pending`, `recorded`, `approved`, `rejected`.
*   **`SessionData` (Update):**
    ```dart
    Map<int, String> approvedClips; // chunkIndex -> filePath
    int currentChunkIndex;         // Índice del fragmento actual
    ```

---

## 4. Restricciones de Implementación (Reglas para el Agente)
1.  **Cero Lógica Inline:** Los handlers `onAccept` y `onReject` deben estar definidos como métodos en el State, no como funciones anónimas en el `build`.
2.  **Mounted Checks:** Es OBLIGATORIO usar `if (!mounted) return;` después de cada `await` que preceda un `setState`.
3.  **Video Muted:** El video DEBE empezar con `volume = 0.0`.
4.  **No Placeholders:** Si no hay video, mostrar el `_ReviewErrorScreen`, nunca un contenedor vacío.
5.  **Naming Strict:** Usar `ClipReviewPage` como nombre de clase y `clip_review_page.dart` como archivo.

---

## 5. Decisiones Tecnológicas
*   **`video_player` nativo:** Se prefiere sobre Chewie para mantener el binario liviano y tener control total sobre el overlay UI custom.
*   **`Persistence Layer`:** Se utiliza el `RecordingManager` existente para centralizar todas las operaciones de FileSystem, evitando que la View manipule archivos directamente.
*   **Timer de Aprobación Pasiva:** Se implementa mediante un `Timer` de Dart para asegurar precisión y fácil cancelación.

---

## 6. Plan de Implementación (Tareas Atómicas)

1.  **T1: Modelado:** Crear enum `ClipStatus` y actualizar `SessionData` para trackear clips aprobados. (~15 min)
2.  **T2: Service Update:** Implementar `acceptCurrentClip()` y `rejectCurrentClip()` en `RecordingManager` (incluye borrado de archivo). (~20 min)
3.  **T3: Esqueleto UI:** Crear `ClipReviewPage` con Scaffold negro y Stack de capas. (~15 min)
4.  **T4: Lógica de Video:** Implementar inicialización, loop y dispose infalible del `VideoPlayerController`. (~30 min)
5.  **T5: Overlays & Controls:** Añadir barra de progreso, texto del guion y botones flotantes (Custom Icons VRM). (~25 min)
6.  **T6: Aprobación Pasiva:** Implementar el Timer de 3s y la barra de progreso animada. (~20 min)
7.  **T7: Integración:** Conectar `RecordingPage` para que navegue a la revisión tras `stopRecording`. (~15 min)

---

## 7. Estrategia de Testing
*   **Manual 1 (Happy Path):** Grabar -> Revisar -> Esperar 3s -> Verificar avance a Fragmento 2.
*   **Manual 2 (Retry Path):** Grabar -> Revisar -> Tocar 🗑️ -> Verificar vuelta a Cámara y archivo borrado.
*   **Manual 3 (Resiliencia):** Simular error de carga (ruta inválida) -> Verificar pantalla de error.
*   **Performance:** Monitorear uso de memoria RAM después de 10 ciclos de Grabar/Revisar para descartar fugas de controladores.

---
**Status:** 🏛️ FINAL BLUEPRINT READY FOR PRODUCTION.
**Referencia:** Unificación de Antigravity, Kilo, OC y Qwen.
