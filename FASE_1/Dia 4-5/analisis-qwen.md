# 🔗 Análisis Técnico — Día 4-5: Auto-Stitch (Concatenación FFmpeg)

## 1. Diseño Funcional

### Happy Path Detallado
1. El usuario completa la grabación de todos los fragments del guion y llega a `RecordingEndPage`.
2. Toca el botón "Exportar Video" (actualmente `onPressed: {}` placeholder).
3. El sistema recopila todas las rutas de clips aprobados desde `SessionData.approvedClips` (ordenados por índice de chunk: `0, 1, 2, ...`).
4. Se muestra una pantalla/modal de **progreso de stitching** con:
   - Indicador del tipo: "Uniendo clip 3 de 7..."
   - Barra de progreso lineal.
   - Botón de cancelar (opcional, ver sección de riesgos).
5. FFmpeg concatena los clips en orden secuencial dentro de un archivo `final.mp4` en la carpeta del proyecto.
6. Al completarse, la pantalla de progreso navega a una versión **funcional** de `RecordingEndPage` que muestra:
   - Duración real del video final (calculada desde el archivo).
   - Thumbnail/preview del video final usando `VideoPlayerController.file()`.
   - Botón "Exportar a Galería" (preparado para Día 6).
7. El usuario puede reproducir el preview del video final.

### Edge Cases Relevantes para MVP
| Escenario | Comportamiento |
|---|---|
| **0 clips aprobados** | Imposible en el flujo normal (la revisión obliga a aceptar). Se valida defensivamente: si ocurre, se muestra error "No hay clips para unir". |
| **1 solo clip** | FFmpeg aún puede hacer un "copy" del archivo. Se optimiza detectando este caso: simplemente se copia el clip como `final.mp4` sin invocar ffmpeg. |
| **Clip eliminado del disco** (usuario borró archivo manualmente) | Se detecta antes de iniciar: se valida que cada ruta en `approvedClips` exista físicamente. Si falta alguno, se muestra error con opción de "Volver a grabar ese fragmento". |
| **Espacio insuficiente en disco** | Se usa `disk_space` (ya instalado) para verificar que haya al menos **2x el tamaño total de los clips** disponibles antes de iniciar. |
| **FFmpeg falla durante la concatenación** | El usuario ve un mensaje de error genérico: "No se pudo procesar el video. Inténtalo de nuevo." con botón de reintentar. El `final.mp4` parcial se elimina si existe. |
| **App va a background durante stitching** | Se usa un `BackgroundTask` wrapper o al mínimo se mantiene un isolate. Para MVP: si la app se minimiza, el proceso se cancela y se notifica al usuario al volver. |

### Manejo de Errores — Qué Ve el Usuario
- **Spinner de carga** con texto contextual → durante el proceso.
- **Pantalla roja de error** con ícono ❌, mensaje descriptivo y botón "Reintentar" → si ffmpeg retorna código de error.
- **Toast/snackbar breve** → si el problema es de espacio en disco ("Almacenamiento insuficiente. Libera espacio e intenta de nuevo.").
- **Navegación bloqueada** → mientras el stitching está en curso, no se puede navegar fuera de la pantalla de progreso (modal `barrierDismissible: false`).

---

## 2. Diseño Técnico

### 2.1 Nuevo Componente: `FFmpegStitcherService`

**Ubicación:** `lib/features/recording/services/ffmpeg_stitcher_service.dart`

**Responsabilidad:** Encapsular toda la lógica de FFmpeg — construir el comando, ejecutarlo, reportar progreso, y validar el resultado.

**Interfaz Pública:**
```
class FFmpegStitcherService {
  /// Constructor que recibe un callback opcional de progreso (0.0 a 1.0)
  FFmpegStitcherService({void Function(double progress)? onProgress});

  /// Concatena una lista de archivos de video en orden.
  /// Retorna la ruta absoluta del archivo final.mp4 resultante.
  /// Lanza StitchException si falla.
  Future<String> concatenate({
    required List<String> clipPaths,   // Rutas absolutas de los clips en orden
    required String projectId,          // Para determinar el directorio de salida
    String? outputFileName,             // Default: 'final.mp4'
  });

  /// Verifica que FFmpeg esté disponible en el entorno actual
  Future<bool> isAvailable();
}
```

**Lógica Interna:**

1. **Validación previa:**
   - Verificar que cada `clipPath` existe (`File(path).existsSync()`).
   - Verificar espacio en disco disponible ≥ 2x la suma de tamaños de clips.

2. **Caso optimizado (1 solo clip):**
   - Copiar directamente `clipPaths[0]` → `{outputDir}/final.mp4`.
   - Retornar la ruta. Sin invocar ffmpeg.

3. **Generar archivo de lista para FFmpeg concat demuxer:**
   - Crear un archivo temporal `concat_list.txt` en el directorio temporal del proyecto.
   - Formato de contenido (una línea por clip):
     ```
     file '/path/to/chunk_0_take_1.mp4'
     file '/path/to/chunk_1_take_1.mp4'
     file '/path/to/chunk_2_take_1.mp4'
     ```
   - Las rutas deben ser **absolutas** y con `/` (FFmpeg en móvil requiere este formato).

4. **Determinar directorio de salida:**
   - `{appDocsDir}/vrm_data/projects/{projectId}/final.mp4`

5. **Construir comando FFmpeg:**
   ```
   -f concat -safe 0 -i concat_list.txt -c copy -y final.mp4
   ```
   - `-f concat`: Usa el demuxer de concatenación.
   - `-safe 0`: Permite rutas absolutas en el archivo de lista.
   - `-c copy`: **Sin re-encoding** — copia directa de streams (velocidad: ~1-3 segundos para clips cortos).
   - `-y`: Sobreescribe `final.mp4` si ya existe sin pedir confirmación.

6. **Ejecutar y reportar progreso:**
   - Usar `FFmpegKit.executeAsync()` con un callback de `onProgress`.
   - El progreso se calcula comparando el tiempo de video procesado vs. la duración total estimada.
   - FFmpegKit reporta sesiones con `Log` y `Statistics` callbacks.

7. **Limpieza:**
   - Eliminar `concat_list.txt` después de la ejecución (éxito o fallo).
   - Si la sesión retorna con `ReturnCode.FAILURE`, eliminar cualquier `final.mp4` parcial.

### 2.2 Nueva Excepción: `StitchException`

**Ubicación:** `lib/features/recording/services/stitch_exception.dart`

```
class StitchException implements Exception {
  final String message;
  final StitchErrorType type;
  final dynamic cause;

  StitchException(this.message, {required this.type, this.cause});
}

enum StitchErrorType {
  noClips,
  missingClip,       // Un archivo de clip no existe en disco
  insufficientSpace,
  ffmpegNotAvailable,
  ffmpegFailed,      // FFmpeg ejecutó pero retornó error
  unknown,
}
```

### 2.3 Modificación: `RecordingEndPage`

**Archivo existente:** `lib/features/recording/recording_end_page.dart`

**Cambios necesarios:**
- Agregar parámetros al constructor: `projectId`, `recordingManager` (o directamente `sessionData`).
- Reemplazar los valores hardcodeados ("42m", imagen de URL) con datos reales:
  - Calcular duración total desde los clips aprobados.
  - Mostrar preview del `final.mp4` si ya existe (con `VideoPlayerController.file()`).
  - Si aún no se hizo stitching: mostrar botón "Procesar Video" que inicia el flujo.
- Conectar el botón "Exportar Video" para invocar el stitching si `final.mp4` no existe aún, o directamente mostrar el resultado si ya fue procesado.

**Nuevo constructor propuesto:**
```dart
class RecordingEndPage extends StatelessWidget {
  final String projectId;
  final SessionData sessionData;
  final bool stitchingAlreadyDone;

  const RecordingEndPage({
    super.key,
    required this.projectId,
    required this.sessionData,
    this.stitchingAlreadyDone = false,
  });
  // ...
}
```

### 2.4 Nuevo Widget: `StitchingProgressDialog`

**Ubicación:** `lib/features/recording/widgets/stitching_progress_dialog.dart`

Un `Dialog` modal (no dismissible) que muestra:
- Título: "Procesando video..."
- Subtítulo dinámico: "Uniendo clip 3 de 7"
- `LinearProgressIndicator(value: progress)` donde `progress` va de 0.0 a 1.0.
- Mensaje de error si falla, con botón "Reintentar".

Se invoca con `showDialog(..., barrierDismissible: false)` desde `RecordingEndPage`.

### 2.5 Modelos de Datos — Extensiones

**No se necesitan nuevos modelos.** Se reutiliza:
- `SessionData.approvedClips` → `Map<int, String>` ya contiene las rutas ordenadas por chunk.
- Se añade un campo opcional `stitchingCompleted` a `SessionData` para trackear si el stitching ya se realizó (persistido en el JSON de sesión).

**Extensión a `SessionData`:**
```dart
// Nuevos campos:
final bool stitchingCompleted;
final String? finalVideoPath;  // Ruta absoluta de final.mp4

// Actualizar toJson(), fromJson(), copyWith()
```

### 2.6 Integración con el Pipeline Existente

El `StitcherPlugin` actual (`IPostProcessor.enhance()`) es un placeholder que opera sobre un **único** `AssetManifest`. Para el stitching real necesitamos operar sobre una **lista de clips**.

**Decisión:** NO modificar la interfaz `IPostProcessor` para el MVP. En su lugar:
- `FFmpegStitcherService` se invoca **directamente** desde `RecordingEndPage` como un servicio independiente.
- El `StitcherPlugin` placeholder se mantiene para no romper el pipeline existente; se puede actualizar en el roadmap para que internamente delegue en `FFmpegStitcherService`.

Esto evita un refactor innecesario del patrón de plugins que no aporta valor al MVP.

### 2.7 Dependencia Nueva: `ffmpeg_kit_flutter`

Se agrega a `pubspec.yaml`:
```yaml
ffmpeg_kit_flutter: ^6.0.3
```

**Nota de compatibilidad:** `ffmpeg_kit_flutter` requiere configuración específica por plataforma:
- **Android:** `minSdkVersion 24` (verificar en `android/app/build.gradle`).
- **iOS:** No requiere configuración adicional si se usa la dependencia directamente.
- **ProGuard (Android release):** Agregar reglas de keep para `com.arthenica.ffmpegkit`.

---

## 3. Decisiones

| Decisión | Justificación |
|---|---|
| **Usar `-c copy` (sin re-encoding)** | La concatenación con copy es instantánea (segundos) vs. re-encoding que tarda minutos en móvil. Como todos los clips vienen de la misma cámara con la misma configuración, los codecs son compatibles. |
| **Invocar stitching directamente desde UI, no desde el pipeline** | El pipeline `VRMPipeline` opera en el flujo de idea→script→video conceptual, pero el stitching real ocurre post-grabación con clips físicos. Separar la responsabilidad evita acoplar el pipeline abstracto con la realidad del FileSystem. |
| **No modificar `IPostProcessor` para MVP** | Cambiar la interfaz para aceptar `List<AssetManifest>` rompería la coherencia del patrón. Se pospone para el roadmap cuando el pipeline pueda orquestar stitching multi-asset nativamente. |
| **Usar `FFmpegKit.executeAsync` con callback de estadísticas** | Permite reportar progreso real al usuario. La alternativa síncrona (`execute`) bloquearía sin feedback. |
| **Validar existencia de clips antes de invocar FFmpeg** | Fail-fast: es mejor detectar un archivo faltante antes de iniciar ffmpeg que fallar a mitad del proceso con un comando críptico. |
| **Optimización de 1 solo clip** | Si solo hay 1 fragmento en el guion, no tiene sentido invocar ffmpeg. Copiar el archivo es O(1) y evita una dependencia innecesaria. |
| **Modal no-dismissible durante stitching** | El usuario no debe poder abandonar el proceso a mitad, ya que dejaría un `final.mp4` corrupto. Para MVP no soportamos reanudación de stitching cancelado. |

---

## 4. Criterios de Aceptación

- [ ] `ffmpeg_kit_flutter` está instalado en `pubspec.yaml` y `flutter pub get` completa sin errores.
- [ ] `FFmpegStitcherService.concatenate()` recibe una lista de 2+ rutas de clips y produce un `final.mp4` válido en `{docs}/vrm_data/projects/{projectId}/final.mp4`.
- [ ] El archivo `final.mp4` resultante es reproducible con `VideoPlayerController.file()`.
- [ ] Si solo hay 1 clip, se copia directamente sin invocar ffmpeg (verificable: el archivo resultante tiene el mismo tamaño que el original).
- [ ] Si un clip no existe en disco, se lanza `StitchException` con `type == StitchErrorType.missingClip` **antes** de invocar ffmpeg.
- [ ] Si no hay espacio suficiente, se lanza `StitchException` con `type == StitchErrorType.insufficientSpace`.
- [ ] `RecordingEndPage` recibe `projectId` y `sessionData` como parámetros (no usa valores hardcodeados).
- [ ] `RecordingEndPage` muestra la duración real del video final (no "42m" hardcodeado).
- [ ] `RecordingEndPage` muestra un preview reproducible del `final.mp4` si el stitching ya se completó.
- [ ] `StitchingProgressDialog` muestra una barra de progreso que se actualiza durante el proceso.
- [ ] Si ffmpeg falla, el usuario ve un mensaje de error con botón "Reintentar".
- [ ] El archivo `concat_list.txt` temporal se elimina después de la ejecución (éxito o fallo).
- [ ] Si el stitching falla, no queda un `final.mp4` corrupto en disco.
- [ ] La sesión (`session_data.json`) se actualiza con `stitchingCompleted: true` y `finalVideoPath` tras el éxito.

---

## 5. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **`ffmpeg_kit_flutter` no compila en iOS/Android por configuración de build** | Media | 🔴 ALTO | Probar el build en modo release en un dispositivo físico inmediatamente tras la instalación. Tener como fallback la copia directa (caso 1 clip) y, para múltiples clips, un mensaje "Procesamiento no disponible en este dispositivo" con opción de exportar clips individuales. |
| **`-c copy` falla porque los clips tienen codecs incompatibles** | Baja (todos los clips vienen de la misma sesión de cámara) | 🟡 MEDIO | Si `-c copy` falla, reintentar automáticamente con `-c:v libx264 -c:a aac` (re-encoding). Esto es más lento pero garantiza compatibilidad. |
| **FFmpeg consume demasiada memoria durante la operación** | Baja (con `-c copy` el uso es mínimo) | 🟡 MEDIO | Monitorear con `debugPrint` de estadísticas. Si se detecta memory pressure, abortar y sugerir re-encoding con menor resolución. |
| **El usuario fuerza el cierre de la app durante stitching** | Media | 🟡 MEDIO | Para MVP, se acepta la pérdida: el usuario deberá reintentar. Se limpia `final.mp4` parcial al reiniciar detectando archivos huérfanos. |
| **Las rutas en `concat_list.txt` usan backslashes en Windows (desarrollo)** | Baja (solo afecta desarrollo en desktop) | 🟢 BAJO | Normalizar rutas con `.replaceAll('\\', '/')` al escribir el archivo de lista. |

---

## 6. Plan

### Tareas Atómicas (orden recomendado)

| # | Tarea | Complejidad | Dependencias |
|---|---|---|---|
| 1 | Agregar `ffmpeg_kit_flutter: ^6.0.3` al `pubspec.yaml` y ejecutar `flutter pub get`. Verificar que no hay conflictos de versión. | Baja | — |
| 2 | Crear `StitchException` (`lib/features/recording/services/stitch_exception.dart`) con el enum `StitchErrorType`. | Baja | — |
| 3 | Crear `FFmpegStitcherService` (`lib/features/recording/services/ffmpeg_stitcher_service.dart`) con la lógica de validación, generación de `concat_list.txt`, invocación de `FFmpegKit.executeAsync`, y limpieza. | **Alta** | #2 |
| 4 | Extender `SessionData` con campos `stitchingCompleted` y `finalVideoPath` (actualizar `toJson`, `fromJson`, `copyWith`). | Baja | — |
| 5 | Crear `StitchingProgressDialog` (`lib/features/recording/widgets/stitching_progress_dialog.dart`) como dialog modal con progress bar dinámico. | Media | — |
| 6 | Refactorizar `RecordingEndPage` para recibir `projectId` y `sessionData`, reemplazar valores hardcodeados, conectar botón "Exportar Video" al stitching, y mostrar preview del video final. | **Alta** | #3, #4, #5 |
| 7 | Actualizar la navegación desde `ClipReviewPage`: cuando el último fragmento se acepta, navegar a `RecordingEndPage(projectId, sessionData)` en lugar del placeholder actual. | Media | #6 |
| 8 | Probar end-to-end en dispositivo físico: grabar 3+ fragmentos → revisar → stitching → preview. Verificar que `final.mp4` se reproduce correctamente. | Media | #1–#7 |
| 9 | Probar edge cases: 1 solo clip, clip faltante, espacio insuficiente, fallo de ffmpeg (simulada). | Media | #8 |
| 10 | Configurar reglas de ProGuard para Android release (`android/app/proguard-rules.pro`). | Baja | #1 |

### Dependencias Visuales
```
#1 (dep) → #10
#2 ─┐
#4 ─┼──→ #3 ──→ #6 ──→ #7 ──→ #8 ──→ #9
#5 ─┘         ↑
              └── #3
```

---

## 🔮 Roadmap (NO implementar ahora)

### Mejoras Post-MVP
1. **Re-encoding automático como fallback:** Si `-c copy` falla, reintentar con re-encoding. Para MVP asumimos compatibilidad de codecs.
2. **Stitching en background real:** Usar `workmanager` o `background_fetch` para que el stitching continúe si el usuario minimiza la app.
3. **Integrar `StitcherPlugin` con `FFmpegStitcherService`:** Refactorizar el placeholder para que `IPostProcessor.enhance()` acepte una lista de assets y delegue en el servicio. Esto requeriría rediseñar ligeramente la interfaz del pipeline.
4. **Overlay de progreso nativo:** Notificación del sistema operativo (Android/iOS) mostrando el progreso del stitching, útil si la app se minimiza.
5. **Stitching incremental:** Si el usuario graba más takes después de un stitching previo, solo procesar los nuevos clips y appending al `final.mp4` existente.
6. **Personalización de output:** Permitir al usuario elegir resolución, frame rate, y codec del video final antes de exportar.
7. **Detección automática de incompatibilidad de codecs:** Analizar los metadatos de cada clip (codec, resolución, fps) antes de concatenar y advertir al usuario si hay diferencias.

### Decisiones de Diseño que No Bloquean el Futuro
- El `FFmpegStitcherService` es una clase independiente (no acoplada a la UI), lo que permite reutilizarla cuando se integre con el pipeline.
- `SessionData` ahora tiene `stitchingCompleted` y `finalVideoPath`, que servirán para la reanudación de sesiones (Día 7-8).
- El uso de `-c copy` es la estrategia default pero el diseño permite intercambiar a re-encoding sin cambiar la interfaz pública del servicio.
