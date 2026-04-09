# Análisis Técnico: Día 4-5 - Auto-Stitch (Concatenación vía FFmpeg)

## 1. Diseño Funcional

### Happy Path Detallado
1. El usuario completa la revisión de todos los clips del script y aprueba al menos uno.
2. Desde la pantalla de revisión, selecciona "Finalizar Grabación" o similar.
3. El sistema muestra una pantalla de "Procesando Video" con barra de progreso indeterminada inicialmente.
4. El stitching comienza automáticamente, concatenando los clips aprobados en orden secuencial (chunk_0, chunk_1, etc.).
5. La barra de progreso se actualiza en tiempo real mostrando porcentaje completado, tiempo restante estimado y velocidad de procesamiento.
6. Al completar exitosamente, se muestra el video final reproducible en la galería del dispositivo.
7. El archivo `final.mp4` queda guardado en `/vrm_data/projects/{project_id}/final.mp4`.

### Edge Cases Relevantes para MVP
- **Un solo clip aprobado:** Se copia directamente como `final.mp4` sin procesamiento FFmpeg (optimización de performance).
- **Clips con resoluciones diferentes:** FFmpeg re-encoding automático asegura compatibilidad (todos los clips se convierten a la resolución del primer clip).
- **Clip corrupto en medio de la secuencia:** El proceso falla y muestra error específico, permitiendo al usuario re-grabar el clip problemático.
- **Sin clips aprobados:** No debería ocurrir por validación previa, pero si pasa, muestra mensaje "No hay clips para procesar" y redirige a revisión.
- **Video muy largo (>5min total):** Progreso muestra correctamente hasta 100%, sin timeouts artificiales.

### Manejo de Errores: Qué Ve el Usuario Cuando Algo Falla
- **Fallo de FFmpeg (comando inválido/codec incompatible):** Mensaje "Error al combinar videos. Verifica que todos los clips sean válidos e intenta nuevamente." con botón "Reintentar".
- **Archivo de salida no se puede escribir (espacio insuficiente):** "Espacio insuficiente en dispositivo. Libera espacio e intenta nuevamente."
- **Crash del proceso:** Pantalla de error genérica con opción de "Volver a Revisión" para no perder progreso.
- **Timeout (>2min sin progreso):** "Procesamiento lento. Puedes esperar o cancelar y reintentar."
- En todos los casos, el estado del proyecto se preserva para reintento sin perder clips grabados.

## 2. Diseño Técnico

### Componentes Nuevos o Modificaciones a Existentes
- **Nueva Dependencia:** `ffmpeg_kit_flutter: ^6.0.3` en `pubspec.yaml` para procesamiento de video cross-platform.
- **Modificación: StitcherPlugin** (`lib/core/plugins/default/stitcher_plugin.dart`):
  - Implementa `enhance(AssetManifest)` con lógica real de FFmpeg.
  - Agrega método `_stitchVideos(List<String> clipPaths)` que construye comandos FFmpeg.
  - Integra callbacks de progreso para actualizar UI.
- **Nueva Clase: StitchProgressNotifier** (en `lib/features/recording/services/`):
  - Extiende `ValueNotifier<StitchProgress>` para estado reactivo del progreso.
  - Incluye campos: `progressPercent`, `timeRemaining`, `currentSpeed`, `status` (idle/processing/completed/error).
- **Modificación: RecordingManager**:
  - Agrega método `Future<String> performStitch()` que orquesta el stitching usando el pipeline.
  - Actualiza `sessionData` con ruta del `final.mp4` al completar.

### Interfaces (Inputs/Outputs de Cada Componente)
- **Input a StitcherPlugin.enhance():**
  - `AssetManifest` con `status: 'raw'`, `approvedClips: Map<int, String>` (rutas absolutas), `projectId: String`.
- **Output de StitcherPlugin.enhance():**
  - `AssetManifest` con `status: 'processed'`, `finalVideoPath: String` (ruta a `final.mp4`), `metadata` actualizado con duración total y tamaño.
- **Input a RecordingManager.performStitch():**
  - `sessionData.approvedClips` (validado que no esté vacío).
- **Output de RecordingManager.performStitch():**
  - Ruta absoluta del `final.mp4` o lanza `StitchException` con detalles del error.

### Modelos de Datos Nuevos o Extensiones
- **Nuevo: StitchProgress** (`lib/features/recording/models/stitch_progress.dart`):
  ```dart
  class StitchProgress {
    final double progressPercent;
    final Duration timeRemaining;
    final double speed;
    final StitchStatus status;
    final String? errorMessage;
  }
  ```
- **Extensión: AssetManifest** agrega campo `finalVideoPath: String?`.

### Debe Ser Coherente con `estado-fase.md`
- Respeta estructura `/vrm_data/projects/{project_id}/final.mp4` definida en el plan general.
- Usa `approvedClips` de `sessionData` como fuente única de verdad.
- No modifica contratos existentes: `ClipStorageService` y `RecordingManager` permanecen intactos.
- Arquitectura de plugins se mantiene: `StitcherPlugin` implementa `IPostProcessor`.

## 3. Decisiones

### Solo Decisiones Nuevas, No Repetir las de `estado-fase.md`
- **Uso de FFmpeg concat filter sobre file list:** Para garantizar compatibilidad entre clips de diferentes tomas, se usa re-encoding automático en lugar de concatenación cruda. Esto evita fallos por codecs/resoluciones incompatibles, priorizando estabilidad sobre performance.
- **Feedback de progreso en tiempo real:** Se implementa callback de `FFmpegKit` para actualizar UI cada 500ms, mostrando progreso basado en tiempo procesado vs. tiempo total estimado. No se usa barra indeterminada para dar sensación de control al usuario.
- **Manejo de un solo clip como copia directa:** Optimización de performance: si `approvedClips.length == 1`, se copia el archivo directamente sin invocar FFmpeg, reduciendo tiempo de procesamiento de ~30s a ~2s.
- **Validación previa de archivos:** Antes del stitching, se verifica que todos los `approvedClips` existan y sean archivos MP4 válidos (>0 bytes), fallando temprano con mensaje claro.
- **Límite de tiempo por seguridad:** Timeout de 5 minutos máximo por stitching para evitar procesos zombies en dispositivos lentos.

## 4. Criterios de Aceptación

- El archivo `final.mp4` se crea correctamente en `/vrm_data/projects/{project_id}/final.mp4` con duración igual a la suma de clips aprobados.
- La pantalla muestra barra de progreso que llega exactamente al 100% al completar el stitching.
- Si FFmpeg falla por cualquier motivo, el usuario ve un mensaje de error específico y puede reintentar sin perder clips.
- Para un solo clip aprobado, el proceso completa en menos de 5 segundos sin invocar FFmpeg.
- El `final.mp4` es reproducible inmediatamente en `VideoPlayer` de Flutter.
- Si no hay espacio suficiente en disco, el proceso falla con mensaje claro antes de iniciar.
- Los clips originales permanecen intactos después del stitching (no se modifican ni eliminan).
- El proceso puede ser cancelado por el usuario, guardando progreso parcial si es posible.

## 5. Riesgos

### Solo Riesgos Concretos del Paso, Con Estrategia de Mitigación para Cada Uno
- **FFmpeg no concatena correctamente en Android 13+ por restricciones de ejecución:** Probabilidad Media, Impacto Alto. **Mitigación:** Test inmediato en dispositivo físico Android, con fallback a copia de archivos si FFmpeg falla. Documentar versión exacta de `ffmpeg_kit_flutter` probada.
- **Performance degradada en videos largos (>10 clips o 5min total):** Probabilidad Alta, Impacto Medio. **Mitigación:** Implementar optimización de "un clip = copia directa". Monitorear tiempos en tests y agregar límite de 20 clips máximo para MVP.
- **Pérdida de calidad de video por re-encoding múltiple:** Probabilidad Baja, Impacto Bajo. **Mitigación:** Usar bitrate alto en comando FFmpeg (ej: `-b:v 5000k`) para mantener calidad visual aceptable. No afecta funcionalidad core.
- **Callbacks de progreso no funcionan en iOS por sandboxing:** Probabilidad Media, Impacto Bajo. **Mitigación:** Fallback a progreso estimado basado en tiempo transcurrido, con tests en iOS físico para validar.
- **Dependencia de librería discontinuada:** Probabilidad Baja, Impacto Alto (si deja de funcionar). **Mitigación:** Evaluar forks activos como `ffmpeg_kit_flutter_new` post-MVP. Para MVP, asumir estabilidad de ^6.0.3.

## 6. Plan

### Tareas Atómicas Ordenadas
1. **Agregar dependencia ffmpeg_kit_flutter** (Baja, 30min): Actualizar `pubspec.yaml` y ejecutar `flutter pub get`.
2. **Crear modelo StitchProgress** (Baja, 45min): Implementar clase con campos necesarios y ValueNotifier wrapper.
3. **Implementar _stitchVideos en StitcherPlugin** (Media, 2h): Lógica de comandos FFmpeg con concat filter, manejo de progreso y errores.
4. **Extender AssetManifest** (Baja, 30min): Agregar campo `finalVideoPath` y actualizar factory methods.
5. **Modificar RecordingManager para performStitch** (Media, 1.5h): Método que integra con pipeline y actualiza sessionData.
6. **Crear pantalla de progreso de stitching** (Media, 2h): UI con barra de progreso, tiempo restante y botones de cancelar.
7. **Integrar llamada a stitching en flujo de revisión** (Media, 1h): Trigger desde `clip_review_page.dart` al aprobar último clip.
8. **Tests de integración** (Alta, 3h): Validar stitching con 1, 3 y 5 clips en emulador y dispositivo físico.
9. **Manejo de errores end-to-end** (Media, 1.5h): Simular fallos de FFmpeg y verificar UI de error.

### Estimación de Complejidad Relativa (Baja / Media / Alta)
- Baja: Cambios menores, sin lógica compleja (<1h).
- Media: Implementación de nueva funcionalidad con integración (1-2h).
- Alta: Testing exhaustivo y edge cases (2-3h).

### Dependencias Explícitas Entre Tareas
- 1 debe completarse antes de 3 (dependencia de librería).
- 2 debe completarse antes de 6 (modelo para UI).
- 3 debe completarse antes de 5 y 6 (lógica core).
- 4 debe completarse antes de 3 (modelo extendido).
- 7 depende de 5 y 6 (integración completa).
- 8 y 9 requieren que 1-7 estén completas (testing post-implementación).

## 🔮 Roadmap (NO Implementar Ahora)
- **Optimizaciones de Performance:** Implementar concatenación sin re-encoding usando file list para clips compatibles, reduciendo tiempo de 30s a 5s.
- **Hardware Acceleration:** Integrar GPU acceleration en Android/iOS para stitching más rápido en dispositivos potentes.
- **Audio Normalization:** Asegurar volumen consistente entre clips usando filtros FFmpeg (`loudnorm`).
- **Efectos Básicos:** Transiciones suaves entre clips (fade in/out) como feature post-MVP.
- **Stitching Paralelo:** Procesar múltiples proyectos en background si el dispositivo lo permite.
- **Compresión Inteligente:** Reducir tamaño del `final.mp4` automáticamente basado en resolución objetivo (1080p vs 4K).
- **Recuperación de Stitching Parcial:** Si falla a medio camino, resumir desde el último clip exitoso en lugar de reiniciar.