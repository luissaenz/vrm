# Análisis de Implementación: Día 3 - Revisión Visual (oc)

Este análisis define la implementación de la pantalla de revisión de clips (`ClipReviewScreen`), componente crítico para la validación de calidad antes del stitching final.

## 1. Diseño Funcional
Permite la inspección inmediata de la calidad del material grabado para asegurar que el pipeline de "Cámara Atómica" solo procese clips válidos.

### Flujo Paso a Paso
1.  **Activación:** Se dispara automáticamente al finalizar la grabación de un segmento del guion (Segmento `N`).
2.  **Carga:** El sistema localiza el archivo `.mp4` temporal generado en la ruta del proyecto y lo carga en el reproductor.
3.  **Reproducción:** El video se reproduce en bucle (loop) para evaluación constante de audio y encuadre.
4.  **Acciones del Usuario:**
    *   **Repetir (Re-take):** Elimina el archivo temporal actual y regresa a la pantalla de grabación en el mismo segmento.
    *   **Siguiente (Accept):** Marca el clip como válido, persiste el estado en `session_data.json` y avanza a la grabación del segmento `N+1`.

### Casos de Borde (Edge Cases)
*   **Interrupción de App:** Al reabrir, la app debe detectar que hay un clip pendiente de revisión en la sesión persistente.
*   **Falla de Reproductor:** Si el archivo está corrupto, mostrar error claro y permitir "Forzar Grabación Nueva".

---

## 2. Diseño Técnico
Arquitectura basada en el desacoplamiento del reproductor de video y la lógica de flujo de sesión.

*   **Componentes Principales:**
    *   `ClipReviewScreen`: Widget contenedor principal.
    *   `VideoPreviewWidget`: Encapsulación de `VideoPlayerController.file` con manejo de estados de inicialización.
    *   `ReviewActionOverlay`: UI reactiva con botones de alta visibilidad para "Repeat" y "Forward".
*   **Modelos e Integración:**
    *   Recepción de objeto `ClipMetadata` con el path absoluto del archivo.
    *   Comunicación con `SessionProvider` (o similar) para actualizar el índice de progreso global.

---

## 3. Decisiones Tecnológicas
*   **`video_player` (Flutter Official):** Elegido por su estabilidad y bajo overhead en archivos locales.
*   **Manejo de Ciclo de Vida:** Uso obligatorio de `dispose()` para el controlador de video. En el MVP, los recursos de GPU son limitados y acumular controladores causará crasheos.
*   **FileSystem Directo:** No se usará base de datos para los clips temporales; la jerarquía de carpetas (`/clips/`) es la fuente de verdad.

---

## 4. Riesgos y Cuellos de Botella
*   **Memory Leaks:** El riesgo #1 en Flutter con video. Se requiere monitoreo de la memoria en transiciones repetitivas.
*   **Latencia de E/S:** El tiempo entre "Grabar" y "Ver" debe ser < 300ms. Se recomienda inicializar el reproductor tan pronto como se cierre el archivo de grabación.
*   **Consumo de Batería:** El uso constante de cámara + reproductor de video drena la batería rápidamente. Se debe mantener el brillo controlado.

---

## 5. Plan de Implementación
1.  **Infraestructura:** Crear el widget `ClipReviewScreen` y definir su contrato de datos (input: path, output: boolean).
2.  **Core Player:** Implementar el reproductor con soporte para loop y mute/unmute opcional.
3.  **Integración de Flujo:** Conectar el fin de grabación en `RecordingPage` con la navegación a esta pantalla.
4.  **Persistencia:** Asegurar que si el usuario acepta, el archivo se mueva de `temporary` a `valid` (o se actualice su flag en el JSON).
5.  **Refinamiento UX:** Añadir micro-animaciones en los botones de acción para feedback táctil premium.
