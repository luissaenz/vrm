# 🏛️ BLUEPRINT MAESTRO: Auto-Stitch (Día 4-5)
**Estado:** DEFINITIVO / PARA IMPLEMENTACIÓN
**Versión:** 1.0 (Consonancia con `estado-fase.md`)

## 1. Resumen Ejecutivo
El proceso de **Auto-Stitch** representa el hito final de la Fase 1. Su función es consolidar los fragmentos de video (clips) aprobados individualmente durante la fase de grabación y revisión en un único archivo maestro de video (`final.mp4`). 

Este proceso debe ser transparente para el usuario, ejecutándose de forma asíncrona tras la aprobación de la secuencia de guion, garantizando la integridad técnica del archivo resultante y preparando el terreno para la exportación a galería y compartición social.

---

## 2. Diseño Funcional Consolidado

### 2.1 Happy Path Detallado
1. **Trigger:** El usuario aprueba el último fragmento pendiente del guion en `ClipReviewPage`.
2. **Activación:** Se muestra automáticamente la pantalla de procesamiento **`StitchProgressPage`**. Esta pantalla es bloqueante (non-dismissible).
3. **Verificación:** El sistema valida que todos los clips indexados en `sessionData.approvedClips` existan físicamente en el disco.
4. **Procesamiento:** Se genera un archivo de índice temporal y se invoca a FFmpeg para la concatenación mediante "stream copy" (concat demuxer).
5. **Feedback:** La UI muestra una barra de progreso real basada en el tiempo de procesamiento reportado por el motor de video.
6. **Finalización:** El sistema actualiza la sesión con la ruta del video final y redirige al usuario a la **`RecordingEndPage`** funcional, donde puede previsualizar el resultado completo.

### 2.2 Edge Cases (MVP)
- **Un solo clip:** Si solo se aprobó un clip, el sistema realiza una copia directa de archivo a `final.mp4` sin invocar FFmpeg, reduciendo el tiempo de espera casi a cero.
- **Espacio Insuficiente:** Antes de iniciar, se verifica que el dispositivo tenga al menos el **doble del espacio** requerido por la suma de los clips.
- **Cierre de App:** Si el proceso se interrumpe, al reiniciar el `RecordingManager` detectará clips válidos pero un `final.mp4` inexistente, ofreciendo el botón "Continuar al Procesamiento".
- **Codecs Inconsistentes:** Si por alguna razón los clips difieren en parámetros técnicos, se aplica un **Re-encoding Fallback** automático.

### 2.3 Manejo de Errores (UX)
- **Falla Crítica:** Diálogo modal indicando la naturaleza del error (ej: "Error de Memoria") con opciones de "Reintentar" o "Volver a Grabar" (si el clip está corrupto).
- **Archivo Faltante:** Si un clip fue borrado por el sistema operativo (poco probable en MVP), se marca el fragmento como "Pendiente" y se redirige a la cámara.

---

## 3. Diseño Técnico Definitivo

### 3.1 Arquitectura de Componentes
1. **`FFmpegStitcherService` (Nuevo - `lib/core/services/`):**
   - Encapsula la lógica de `ffmpeg_kit_flutter`.
   - Responsable de crear el archivo `inputs.txt` (Demuxer format).
   - Maneja los callbacks de progreso y estadísticas de sesión.
2. **`StitcherPlugin` (Modificado - `lib/core/plugins/default/`):**
   - Actúa como el puente del pipeline VRM, delegando la ejecución real al `FFmpegStitcherService`.
3. **`RecordingManager` (Extensión):**
   - Orquesta el flujo: invoca al servicio de stitch y persiste el resultado en el esquema JSON de la sesión.
4. **`StitchProgressPage` (Nueva UI - `lib/features/recording/pages/`):**
   - Pantalla fullscreen con `LinearProgressIndicator` reactivo a los streams del servicio.

### 3.2 Contratos y Estructura de Datos
- **Ruta de Salida:** `vrm_data/projects/{projectId}/final.mp4`
- **Comando Principal (Rápido):**
  ```bash
  ffmpeg -f concat -safe 0 -i list.txt -c copy -y final.mp4
  ```
- **Comando Fallback (Robustez):**
  ```bash
  ffmpeg -f concat -safe 0 -i list.txt -c:v libx264 -preset ultrafast -crf 23 -c:a aac final.mp4
  ```

### 3.3 Modelo de Datos
Se extiende `SessionData` con:
- `bool stitchingCompleted`
- `String? finalVideoPath`
- `DateTime? stitchedAt`

---

## 4. Decisiones Tecnológicas

1. **Uso de FFmpeg Kit (Paquete: `ffmpeg_kit_flutter_main`):** Se selecciona la versión *Main* para optimizar el peso de la APK/IPA, ya que los filtros complejos no son necesarios para el MVP.
2. **Método Concat Demuxer:** Priorizado por ser O(1) en términos de re-encoding (copia directa). Es la forma más rápida y fiel de unir videos tomados con la misma cámara.
3. **Validación Pre-Stitch:** Se decide realizar una validación de "Checksums" superficial (existencia y tamaño > 0) para evitar que FFmpeg lance errores crípticos a mitad del proceso.

---

## 5. Criterios de Aceptación MVP ✅

### Funcionales:
- [ ] El usuario llega a la pantalla de progreso automáticamente al terminar el último Take.
- [ ] El video `final.mp4` resultante reproduce todos los clips en el orden correcto del guion.
- [ ] El audio y video están perfectamente sincronizados en las transiciones entre clips.
- [ ] La previsualización final permite reproducir el video completo inmediatamente.

### Técnicos:
- [ ] Se crea un archivo `final.mp4` en el directorio del proyecto especificado en `estado-fase.md`.
- [ ] El archivo temporal `inputs.txt` se elimina después del procesamiento (éxito o error).
- [ ] La barra de progreso refleja porcentajes reales informados por el motor FFmpeg.
- [ ] No hay fugas de memoria (Memory Leaks) al ejecutar el stitching 3 veces seguidas.

### Robustez:
- [ ] Si el proceso es cancelado, no quedan archivos temporales pesados ni bloqueos en el hilo principal.
- [ ] Si falla el comando `-c copy`, el sistema ejecuta automáticamente el fallback de re-encoding sin intervención del usuario.

---

## 6. Plan de Implementación

1. **Setup (Baja):** Instalar `ffmpeg_kit_flutter_main` y configurar `minSdkVersion 24` en Android.
2. **Core Service (Alta):** Implementar `FFmpegStitcherService` con manejo de archivos y comandos asíncronos.
3. **Persistencia (Baja):** Actualizar el modelo `SessionData` y su serialización.
4. **UI Progress (Media):** Crear `StitchProgressPage` con integración de streams de estadísticas.
5. **Orquestación (Media):** Conectar `RecordingManager` con el servicio tras el flujo de revisión.
6. **Validación (Media):** Pruebas de campo en dispositivos físicos (Android/iOS).

---

## 7. Riesgos y Mitigaciones
- **Riesgo:** Incompatibilidad de codecs entre clips (poco probable).
  - **Mitigación:** Inclusión del comando de fallback con re-encoding forzado y presets de velocidad.
- **Riesgo:** Bloqueo de la app por procesos pesados.
  - **Mitigación:** Ejecución en Isolate nativo mediante `FFmpegKit.executeAsync`.
- **Riesgo:** Rechazo en App Store por uso de FFmpeg.
  - **Mitigación:** Uso de la versión filtrada (Main) y declaración clara de permisos en `plist`.

---

## 8. Testing Mínimo Viable
1. **Test Unitario:** Generación correcta del archivo `list.txt` con rutas absolutas normalizadas.
2. **Test de Integración:** Grabar 3 clips de 5s cada uno y verificar que el `final.mp4` dura exactamente 15s.
3. **Test de Estrés:** Simular falta de espacio en disco y verificar diálogo de error amigable.

---

## 9. 🔮 Roadmap (Post-MVP)
- **Fade Transitions:** Añadir transiciones cruzadas (dissolve) entre clips.
- **Marca de Agua:** Inyectar el logo de la marca en un rincón del video durante la unión.
- **Lower Thirds:** Soporte para títulos estáticos basados en el guion.
- **Cloud Upload:** Subida automática del `final.mp4` a almacenamiento en la nube.
