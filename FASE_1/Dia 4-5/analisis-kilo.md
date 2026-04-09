# Análisis: FASE 1 — Día 4-5 (Auto-Stitch por Línea de Comandos)

> **Autor**: Kilo
> **Fecha**: 2026-04-08
> **Fase**: FASE 1 / Día 4-5
> **Fuente**: `docs/mvp-Definition.md` + código existente

---

## Diseño Funcional

### Problema que resuelve
Después de grabar múltiples clips (Día 1-2) y revisarlos (Día 3), el usuario tiene fragmentos separados (`chunk_0_take_1.mp4`, `chunk_1_take_2.mp4`, etc.) pero no un video final unificado. Sin stitching, el usuario debe editar manualmente fuera de la app, rompiendo el flujo "Idea → Guion → Grabar → Unir → Exportar".

Este paso consolida los clips válidos (según `SessionData.selectedTake` por chunk) en un solo archivo `/final.mp4` reproducible y exportable.

### Inputs
- Lista de clips válidos: `List<String>` de rutas absolutas a archivos `.mp4` en `/vrm_data/projects/{projectId}/clips/`
- Orden de concatenación: basado en `chunkIndex` ascendente (0,1,2,...), usando el `selectedTake` para cada chunk
- `SessionData` con `takesPerChunk` que indica cuál take usar por chunk
- `projectId` para localizar el directorio de clips

### Outputs
- Archivo único `final.mp4` en `/vrm_data/projects/{projectId}/final.mp4`
- Ruta absoluta del archivo final: `String`
- Metadata del video final (duración total, tamaño archivo)
- Indicador de éxito: `bool` (true si stitching completó sin errores)

### Flujo Completo
```
1. Obtener lista de clips válidos desde SessionData
   - Para cada chunk, seleccionar el take marcado como selectedTake
   - Verificar que cada archivo existe y no es 0 bytes

2. Preparar comando ffmpeg
   - Input: lista de clips en orden chunk ascendente
   - Output: final.mp4 con codec compatible (H.264/AAC)
   - Concatenar sin re-encoding si posible (para velocidad)

3. Ejecutar stitching con barra de progreso
   - Mostrar UI de "Procesando..." con spinner + texto "Uniendo clips..."
   - Ejecutar `FFmpegKit.executeAsync()` con callback de progreso
   - Monitorear logs para detectar errores (codec mismatch, corruption)

4. Validar output
   - Verificar que final.mp4 existe y es reproducible
   - Calcular duración total vs suma de duraciones individuales

5. Cleanup opcional
   - No borrar clips originales (usuario puede necesitar re-stitch)
   - Log de éxito/error
```

### Casos Normales
- **Stitching exitoso**: 3 clips de 10s cada uno → final.mp4 de 30s reproducible
- **Un solo clip**: Si proyecto tiene 1 chunk → copia el clip a final.mp4
- **Clips con audio sincronizado**: Video + audio concatenados correctamente

### Edge Cases
- **Clip corrupto en medio**: Saltar y continuar con el resto, loggear warning
- **Espacio insuficiente**: Verificar free space > suma de clips antes de iniciar
- **FFmpeg falla**: Fallback a concatenación simple sin re-encoding
- **Proyecto sin clips válidos**: Error temprano, no iniciar stitching

### Manejo de Errores
- **FFmpeg command falla**: Catch `FFmpegKitException`, mostrar "Error al unir clips. Reintente."
- **Archivo output corrupto**: Detectar si `video_player` no puede inicializar, borrar y reintentar
- **Timeout**: FFmpeg puede tardar minutos; implementar timeout de 5 min, cancelar si excede
- **Permisos filesystem**: Ya verificados en Día 1-2, asumir ok

---

## Diseño Técnico

### Arquitectura
```
RecordingEndPage (Día 3 output)
    │
    ├── _onExportPressed()
    │
    ▼
StitcherService (NUEVO)
    ├── prepareClipList(projectId) → List<String>
    ├── executeStitch(clipPaths, outputPath) → Future<String>
    │   ├── FFmpegKit.executeAsync(command)
    │   ├── Progress callback → update UI
    │   └── Validate output
    │
    ▼
Output: final.mp4
    │
    ▼
ExportPage (Día 6)
```

### Componentes Involucrados
- **StitcherService**: Servicio singleton para ejecutar stitching
- **ClipStorageService**: Proporciona paths de clips y valida existencia
- **SessionData**: Determina cuáles clips usar
- **FFmpegKit**: Librería para ejecutar comandos ffmpeg
- **RecordingEndPage**: UI que dispara el stitching

### APIs / Endpoints
- `FFmpegKit.executeAsync(String command, FFmpegExecuteCallback callback)`
- `ClipStorageService.getSelectedClipsForProject(String projectId)` → `List<String>`
- `ClipStorageService.getProjectDirectory(String projectId)` → `Directory`

### Modelos de Datos
- **StitchResult**:
  ```dart
  class StitchResult {
    final bool success;
    final String outputPath;
    final int totalDurationMs;
    final int fileSizeBytes;
    final String? errorMessage;
  }
  ```
- **ClipMetadata**: Ya existe, usar para validar inputs

### Integraciones Externas
- **ffmpeg_kit_flutter: ^6.0.3**: Ejecuta comandos ffmpeg en mobile
- **path_provider**: Para paths de output
- **video_player**: Para validar output post-stitch

---

## Decisiones

### Decisiones Arquitectónicas
- **Stitching offline**: Todo local, no cloud. Compatible con offline-first MVP.
- **Concatenate sin re-encoding**: `-f concat -c copy` para velocidad, asumiendo clips consistentes (CameraConfig).
- **No transcode automático**: Si codecs difieren, fallar y mostrar error (simplifica MVP).
- **Progress feedback**: Callback de FFmpegKit para actualizar UI, no polling.
- **Single output format**: MP4 con H.264 video + AAC audio.

### Decisiones Tecnológicas
- **Framework**: Flutter con plugin nativo FFmpegKit (no alternativa Dart pura, demasiado lento).
- **Librerías**: ffmpeg_kit_flutter (único que soporta concat en mobile), video_player para validation.
- **Justificación**: FFmpeg es estándar industrial para A/V processing. Plugin nativo asegura performance en mobile.

### Decisiones de Ambigüedades Resueltas
- **Orden de clips**: Chunk index ascendente, selectedTake por chunk.
- **Codec consistency**: Asumir clips de CameraConfig son compatibles. Si no, error.
- **Re-stitch**: Permitido, sobrescribe final.mp4.
- **Cleanup**: No borrar clips originales, storage barato.

---

## Riesgos

### Riesgos Técnicos
- **FFmpegKit no soporta concat en algunos dispositivos**: Prob. media, Impacto alto → Fallback a copy manual de clips uno por uno.
- **Clips con codecs diferentes**: Prob. baja (CameraConfig), Impacto alto → Error temprano.
- **Performance en clips largos**: >10 clips → tiempo >5 min → Implementar chunking.
- **Memory leaks en FFmpegKit**: Prob. baja, Impacto medio → Dispose correctamente.

### Riesgos Operativos
- **Stitching falla en release build**: Prob. alta → Test obligatorio en dispositivo físico.
- **Usuario abandona durante proceso**: Prob. media → UI debe permitir cancelar.

### Riesgos de Escalabilidad
- **Proyectos con 100+ clips**: Prob. baja para MVP, Impacto alto → Implementar batch processing.
- **Storage explosion**: Clips + final.mp4 → Monitorear en Día 16-17.

### Costos
- **Nueva dependencia**: ffmpeg_kit_flutter (~10MB app size increase).
- **Testing**: Dispositivo físico obligatorio para validar stitching.

---

## Plan

### Backlog de Tareas
1. **Agregar ffmpeg_kit_flutter a pubspec.yaml** [5 min]
   - `flutter pub add ffmpeg_kit_flutter`
   - Verificar instalación en dispositivo

2. **Crear StitchResult model** [10 min]
   - `lib/features/recording/models/stitch_result.dart`

3. **Crear StitcherService** [60 min]
   - `lib/features/recording/services/stitcher_service.dart`
   - `prepareClipList()`: scan SessionData, validate files
   - `executeStitch()`: build ffmpeg command, execute with progress
   - Handle errors, validate output

4. **Agregar método a ClipStorageService** [20 min]
   - `getSelectedClipsForProject(projectId)` → List<String>

5. **Integrar en RecordingEndPage** [30 min]
   - Botón "Exportar" → llamar StitcherService
   - Mostrar progress dialog durante stitching
   - On success → navegar a export page

6. **Test en dispositivo físico** [45 min]
   - Grabar 2-3 clips → stitch → verificar final.mp4 reproducible
   - Test error cases (clip corrupto, no space)

### Dependencias entre Tareas
```
T1 → T2 → T3 → T4 → T5 → T6
```

### Definition of Done
- [ ] ffmpeg_kit_flutter agregado y funcionando
- [ ] StitcherService ejecuta concat de 3 clips en <30s
- [ ] final.mp4 reproducible en video_player
- [ ] UI muestra progreso y maneja errores
- [ ] 0 crashes en stitching de proyecto completo
</content>
<parameter name="filePath">D:\Develop\Personal\vrm\.kilo\plans\1775662926532-calm-harbor.md