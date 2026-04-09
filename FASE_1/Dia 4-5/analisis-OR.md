# Análisis Técnico: FASE 1 - Día 4-5 (Auto-Stitch con FFmpeg)

## 1. Comprensión del Paso

### Problema que resuelve
Consolidar múltiples clips de video individuales (`chunk_0_take_X.mp4`, `chunk_1_take_Y.mp4`, etc.) en un único archivo de video unificado (`final.mp4`) que el usuario pueda exportar y compartir. Sin stitching, el usuario tendría que publicar múltiples clips separados - experiencia inaceptable.

### Inputs
- Lista de rutas de clips aprobados (array de strings): `["/path/clips/chunk_0_take_1.mp4", "/path/clips/chunk_1_take_1.mp4", ...]`
- Resolución objetivo (string): `"1080x1920"` (debe ser consistente con `CameraConfig`)
- FPS objetivo (int): `30`
- Output path: `/vrm_data/projects/{project_id}/final.mp4`

### Outputs
- **Éxito**: Archivo `final.mp4` generado en el directorio del proyecto
- **Error**: Excepción con mensaje descriptivo, usuario puede re-intentar o intentar con clips individuales

### Rol en el sistema
Es el **punto de consolidación** del pipeline de video. Transforma fragmentos aislados en producto final comercializable. Conecta:
- **Entrada**: Día 3 (ClipReviewScreen) - provee lista de clips aprobados
- **Salida**: Día 6 (Exportación) - consume `final.mp4` para galería y share sheet

---

## 2. Supuestos y Ambigüedades

### Críticas (requieren resolución antes de coding)

1. **¿Qué pasa si un clip está corrupto o tiene formato incompatible?**
   - No está definido si el sistema valida cada clip antes de stitching
   - Pregunta: ¿FFmpeg fallará silenciosamente o se detectará el problema antes?

2. **¿Cómo se maneja la transición entre clips?**
   - ¿Corte limpio (direct cut)? ¿Transición cruzada (crossfade)? ¿Dissolve?
   - Documento dice "consolidar" pero no especifica técnica

3. **¿Progress feedback es bloqueante o no?**
   - Dice "barra de proceso a usuario" - ¿puede el usuario seguir usando la app mientras stitchea?
   - Para MVP: Asumir comportamiento síncrono/bloqueante con UI de progreso

4. **¿Qué pasa si el usuario cierra la app durante stitching?**
   - ¿Se reanuda automáticamente? ¿Se pierde el progreso?
   - Documento de Día 7-8 habla de persistencia - ¿incluye stitching interrumpido?

5. **¿FFmpeg está disponible en dispositivos del equipo de desarrollo?**
   - El documento marca riesgo: "ffmpeg_kit no transpila en C++ nativo"
   - Necesita verification inmediata en iOS simulator + Android emulator

6. **¿Orden de concatenación?**
   - Los chunks deben concatenarse en orden numérico (chunk 0 → 1 → 2 → ...)
   - ¿Qué pasa si falta un chunk intermedio? (ej: chunk 0 y 2 existen, pero no 1)

### Secundarias

- ¿El usuario puede elegir calidad de salida (1080p vs 720p)?
- ¿Se preserva el audio de cada clip?
- ¿Qué codec de salida? (H.264, H.265, VP9?)

---

## 3. Diseño Funcional

### Flujo Principal (Pipeline)

```
[ClipReviewScreen] → ultimo chunk aprobado
        ↓
   [StitchingScreen / ProgressOverlay]
        ↓
   Verificar que existen todos los clips (0 a N-1)
        ↓
   Construir comando FFmpeg (concat demuxer o filter complex)
        ↓
   Ejecutar FFmpeg con callback de progreso
        ↓
   ┌────┴────┐
   ↓          ↓
[Éxito]    [Error]
   ↓          ↓
Guardar    Mostrar
final.mp4  mensaje
   ↓          ↓
[ExportScreen] ←Ir a Día 6
```

### Casos Normales

1. **Stitching directo**: 3 clips → 1 video final en ~10-30 segundos
2. **Stitching con re-intento**: Fallo temporal → reintentar automáticamente
3. **Stitching con clips de distintos tamaños**: FFmpeg concat maneja automáticamente

### Edge Cases

| Escenario | Comportamiento |
|-----------|-----------------|
| Un clip falta | Mostrar error: "Falta clip del fragmento X", sugerir re-grabación |
| Clip corrupto (no se puede abrir) | Skipear el clip y warnear al usuario, o fallar completamente |
| Storage lleno durante stitch | Liberar espacio temporal y re-intentar, o mostrar error claro |
| Stitching muy largo (>2 min) | Cancel button visible, posibilidad de crear video parcial |
| App va a background durante stitch | Continuar en background (iOS tiene límites) |
| Dispositivo sin FFmpeg (fallback) | Implementar concatenador manual en Dart como backup |

### Manejo de Errores

```
try {
  // 1. Validar archivos existen
  for each clip:
    if (!File.exists(clip)) throw MissingClipException(chunkIndex)
  
  // 2. Verificar espacio disponible (debe haber ~2x tamaño total clips)
  
  // 3. Ejecutar FFmpeg con timeout (5 min max para MVP)
  result = await ffmpeg.executeCommand()
  
  // 4. Validar output existe y tiene tamaño > 0
  if (!File(finalPath).existsSync()) throw StitchFailedException()
  
} on FFmpegException catch (e) {
  // Loggear comando que falló
  // Mostrar: "Error al unir videos. ¿Reintentar?"
}
```

---

## 4. Diseño Técnico

### Arquitectura Sugerida

```
lib/
├── features/
│   └── recording/
│       ├── screens/
│       │   ├── stitching_screen.dart      ← UI principal
│       │   └── stitching_progress_dialog.dart  ← Overlay de progreso
│       └── services/
│           └── ffmpeg_stitch_service.dart  ← Lógica de stitching
```

### Componentes Involucrados

1. **FFmpegStitchService** - Clase principal
   - `stitchClips(List<String> clipPaths, String outputPath, Function(double)? onProgress)`
   - `validateClips(List<String> clipPaths) -> List<String> errors`
   - `cancelStitch() -> void`

2. **StitchingScreen** - Widget de UI
   - Muestra lista de clips a unir
   - Botón "Crear Video" que dispara stitching
   - Progress indicator durante ejecución
   - Resultado: preview del video final o error

3. **StitchingNotifier** - State management
   - `isStitching: bool`
   - `progress: double (0.0 - 1.0)`
   - `error: String?`
   - `finalVideoPath: String?`

### APIs / Endpoints
No hay endpoints HTTP. Todo es ejecución local de FFmpeg.

### Modelos de Datos

```dart
// Input: Lista de clips válidos (del script_bundle.json)
class StitchInput {
  final String projectId;
  final List<StitchClip> clips;  // ordenados por chunkIndex
  final StitchConfig config;
}

class StitchClip {
  final int chunkIndex;
  final String filePath;
  final ClipMetadata metadata;
}

class StitchConfig {
  final String outputResolution;  // "1080x1920"
  final int outputFps;            // 30
  final String videoCodec;        // "libx264"
  final String audioCodec;        // "aac"
  final int videoBitrate;        // 4000000 (4 Mbps)
}

// Output: session_data.json actualizado
{
  "projectId": "uuid-123",
  "stitch": {
    "status": "completed",
    "outputPath": "/path/to/final.mp4",
    "durationMs": 125000,
    "fileSizeBytes": 45000000,
    "createdAt": "2026-04-08T15:30:00Z",
    "clipCount": 5
  }
}
```

### Integraciones Externas

| Paquete | Versión | Propósito |
|---------|---------|------------|
| `ffmpeg_kit_flutter` | ^6.0.3 | Ejecución de comandos FFmpeg |
| `path_provider` | ^2.1.3 | Rutas de directorios |
| `video_player` | ^2.9.1 | Validación (opcional) de output |

---

## 5. Decisiones Tecnológicas

### Librería Principal
- **ffmpeg_kit_flutter: ^6.0.3** - única opción viable para stitching offline en mobile
- **Justificación técnica**:
  - Soporta concat demuxer (más rápido, sin re-encoding)
  - Filter complex disponible para transiciones
  - Callback de progreso (FFmpeg retorna % de frames procesados)

### Comando FFmpeg Recomendado

**Opción A: Concat Demuxer (más rápido, sin re-encoding)**
```bash
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4
```
- Pros: Rápido, no re-encoda
- Cons: Requiere que todos los clips tengan misma resolución/codec
- **Adecuado para MVP** si CameraConfig garantiza consistencia

**Opción B: Filter Complex (más flexible)**
```bash
ffmpeg -i clip1.mp4 -i clip2.mp4 -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" output.mp4
```
- Pros: Maneja diferentes formatos
- Cons: Más lento, mayor uso de memoria
- **Para V2 si hay problemas de compatibilidad**

### Decisiones Pendientes

| Decisión | Recomendada | Alternativa |
|----------|-------------|-------------|
| Técnica de concatenación | Concat demuxer (copy) | Filter complex |
| Transición entre clips | Direct cut | Crossfade 0.5s |
| Timeout de ejecución | 5 minutos | 10 minutos |
| Cancelación | Allow anytime | Solo antes de 50% |

---

## 6. Plan de Implementación

### Backlog Técnico

#### Tarea 1: Verificación de FFmpeg (0.5h) - CRÍTICA
- Agregar `ffmpeg_kit_flutter` a pubspec.yaml
- Testear en iOS simulator y Android emulator
- Si no compila: preparar alternativas (Dart concat, native plugins)
- **Dependencia**: Ninguna, es la primera tarea

#### Tarea 2: FFmpegStitchService - core (1.5h)
- Crear `lib/features/recording/services/ffmpeg_stitch_service.dart`
- Implementar método `stitchClips()`
- Construir comando ffmpeg con concat demuxer
- Agregar logging para debugging
- **Dependencia**: Tarea 1 completa

#### Tarea 3: Progress callback (1h)
- Implementar callback de progreso desde FFmpeg
- mapear frame count → percentage
- Agregar timeout handling
- **Dependencia**: Tarea 2 completa

#### Tarea 4: StitchingScreen UI (1.5h)
- Crear `lib/features/recording/screens/stitching_screen.dart`
- Mostrar lista de clips a unir
- Botón principal "Crear Video Unificado"
- **Dependencia**: Tareas 2-3 completas

#### Tarea 5: Progress overlay (1h)
- Agregar UI de progreso con percentage
- Cancel button
- Manejo de errores visuales
- **Dependencia**: Tarea 4 completa

#### Tarea 6: Integración con pipeline (1h)
- Conectar con ClipReviewScreen (último chunk aprobado → StitchingScreen)
- Guardar resultado en session_data.json
- Navegar a ExportScreen al completar
- **Dependencia**: Tareas 1-5 completas

### Total Estimado: 6.5 horas

### Orden de Desarrollo
1. Tarea 1 es bloqueante - no se puede avanzar sin verificar que FFmpeg compila
2. Tareas 2-3 son paralelas (servicio + progress)
3. Tareas 4-5 son paraleles (UI de screen + progress overlay)
4. Tarea 6 es integración final

---

## 7. Riesgos y Cuellos de Botella

### Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **FFmpeg no compila en iOS** | MEDIA | 🔴 ALTO | Test inmediato en simulator; tener fallback Dart list concat |
| **Clips de diferentes formatos** | ALTA | 🟡 MEDIO | CameraConfig garantiza consistencia; validar antes de stitch |
| **Memoria agotada durante stitch** | BAJA | 🔴 ALTO | Usar concat demuxer (no carga todo en memoria) |
| **Timeout en dispositivo lento** | MEDIA | 🟡 MEDIO | Timeout 5 min + option to cancel |

### Operativos

- El usuario no ve progreso detallado (solo % genérico) - esto es aceptable para MVP
- No hay manera de "deshacer" stitch - si quedó mal, debe re-grabar clips
- Progress no es updateable desde background en iOS (limitación de OS)

### Escalabilidad

- Para > 20 clips: el comando concat crece mucho - considerar generar filelist primero
- Videos 4K: pueden overflow memoria en stitching - detectar y warnear
- En el futuro: ofrecer diferentes calidades de output (720p, 1080p, 4K)

### Costos

- **ffmpeg_kit_flutter**: ~10MB incremento en app size
- No hay costos de API externos
- Tiempo de stitching es cpu-bound (sin costo monetario directo)

---

## 8. Métricas de Éxito

### KPIs Técnicos

| Métrica | Target | Método de Medición |
|---------|--------|---------------------|
| Stitch成功率 | > 95% | (stitches exitosos / total intentos) × 100 |
| Tiempo promedio stitch | < 30s | Medir duration de executeCommand para 3-5 clips |
| Memory peak | < 200MB | Profile en iOS/Android durante stitch |
| Progress accuracy | ±10% | Comparar % reportado vs duration real |

### KPIs de Negocio

| Métrica | Target | Método |
|---------|--------|---------|
| Usuarios que completan stitch | > 80% | analytics event al iniciar vs completar |
| Videos exportados exitosamente | > 90% | tracking de final.mp4 generado → export success |

### Validación

- Test con 3 clips de 10 segundos cada uno
- Test con 10 clips de 5 segundos cada uno
- Test con clips de diferente resolución (debe fallar con mensaje claro)
- Test cancel durante stitching (50% + 90%)

---

## 9. Estrategia de Testing

### Unit Tests

```dart
// Test: validateClips detecta clip faltante
test('validateClips returns error for missing file', () async {
  final service = FFmpegStitchService();
  final errors = await service.validateClips(['/missing/path.mp4']);
  expect(errors.length, 1);
  expect(errors[0], contains('chunk 0'));
});

// Test: buildConcatCommand genera comando correcto
test('buildConcatCommand creates valid filelist', () {
  final service = FFmpegStitchService();
  final cmd = service.buildConcatCommand(
    ['/clip1.mp4', '/clip2.mp4'],
    '/output.mp4'
  );
  expect(cmd, contains('-f concat'));
  expect(cmd, contains('-safe 0'));
});

// Test: progress callback mapea correctamente
test('progress callback receives values 0.0-1.0', () async {
  double? lastProgress;
  await stitchWithProgress((p) => lastProgress = p);
  expect(lastProgress, greaterThanOrEqualTo(0.0));
  expect(lastProgress, lessThanOrEqualTo(1.0));
});
```

### Integration Tests

- **Happy path**: Grabar 3 clips → hacer stitch → verificar final.mp4 existe
- **Cancel path**: Iniciar stitch → cancelar a los 3 segundos → verificar cleanup
- **Error path**: Stitch con clip corrupto → verificar mensaje de error

### Casos Críticos

1. **Clip con 0 bytes**: FFmpeg debe fallar con error claro
2. **Dos usuarios staincheando al mismo tiempo**: Primer intento simúltaneo - no hay protección, es single-user app
3. **Stitch exitoso pero final.mp4 no se puede reproducir**: Usar video_player para validar output post-stitch
4. **Dispositivo sin espacio**: Pre-check de storage antes de stitch

---

## 10. Optimización y Escalabilidad Futura

### Problemas al Escalar

1. **Clips muy largos**: Stitch de videos > 1 minuto puede tomar > 60s
   - Solución V2: Background processing con notifications
2. **Múltiples grabaciones del mismo proyecto**: ¿Se permite hacer stitch de diferentes takes?
   - Solución V2: UI para seleccionar qué take usar por chunk
3. **Calidad variable**: Usuarios con dispositivos distintos producen calidades distintas
   - Solución V2: Normalizar a 720p antes de stitch para consistencia

### Preparación desde Ahora

1. **Session data extensible**: El schema ya tiene campo `stitch` que puede expandirse
2. **FFmpeg command aislados**: Mantener el comando en un solo método para facilitar cambios
3. **No hardcodear paths**: Usar path_provider consistentemente
4. **Progress callback abstract**: Permitir inyectar diferentes UI (overlay, notification, etc.)

---

## Notas Adicionales

- Este análisis asume que Tarea 1 (verificar FFmpeg compila) es exitosa
- Si FFmpeg falla, el fallback mínimo es concatenación de archivos con filter complex sin re-encoding, o un simple "no soportado" hasta tener recursos
- El riesgo de ffmpeg_kit no transpilar es real - verificar con build de debug early
- La dependencia crítica es CameraConfig (resolución/FPS consistente) -documentado en análisis de Día 1-2