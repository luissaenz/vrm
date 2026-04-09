# Análisis Técnico: FASE 1 - Día 1-2 (Grabación Crítica)

### Diseño funcional
* **Objetivo central**: Implementar el ciclo completo de captura de video y audio en tiempo real y su salvado físico, reemplazando la simulación actual de UI. Es la arteria principal del MVP, ya que sin un archivo `.mp4` válido no hay pasos posteriores de stitching ni exportación.
* **Componentes de entrada y salida**: Recibe como comandos el trigger físico del usuario (Start/Stop) y sus metadatos (`project_id`, `chunk_id`, `take_n`). Genera un clip `.mp4` grabado físicamente en la ruta `.../vrm_data/projects/{project_id}/clips/chunk_x_take_y.mp4` y actualiza el estado local.
* **Pipeline de ejecución**:
  1. Boot: Validaciones estrictas de permisos nativos de Cámara y Micrófono.
  2. Preparación de FileSystem: Garantizar la pre-existencia del árbol de directorios del proyecto `/clips/`.
  3. Grabación normal: Inicio del motor `CameraController`, desplegando interfaz paralela operativa (cronómetro y teleprompter al unísono).
  4. Detención: Respuesta nativa devuelve un fichero temporal `XFile` en el caché del OS local.
  5. Volcado: Copiado veloz del temporal hacia la estructura definitiva del proyecto y purgado del remanente en caché.
* **Edge Cases (Casos límite)**: Intercepción vital (volcado seguro) si la aplicación pasa a segundo plano o llamada entrante (State Lifecycle), y manejo explícito con UI Alert cuando el FileSystem devuelve excepción de disco lleno.

### Diseño técnico
* **Arquitectura Sugerida**: Patrón Repository/Service, desacoplando absolutamente a la UI (`RecordingPage.dart`) del hardware.
* **Componentes Implicados**:
  1. *CameraManager*: Envoltorio de la cámara (Init/Start/Stop/Record/Dispose).
  2. *ProjectFileSystem*: Manipulador físico que aisla la manipulación de `path_provider`.
  3. *RecordingViewModel*: Controller agnóstico para estados UI reactivos (Loading, Recording, Stopped, Error).
* **Modelos en Memoria**: Registro de `ClipRecord(id, absolutePath, chunkIndex, takeNumber, durationMs)` trackeando estado real.
* **Integración OS**: Abstracción vía plugins apuntando a `AVFoundation` y `CameraX` con control de I/O por `dart:io`.
* **Optimización y Escalabilidad**: Necesidad de centralizar un `AppConfig` inmutable de cámara (fijando resolución / FPS). Permitir que salten configuraciones arruinará las pasarelas posteriores de compresión mediante `ffmpeg` (Día 4). Establecer interfaces sólidas por si escalar requiere bajar el bitrate ante usuarios con memorias lentas.

### Decisiones
* **Decisiones de Librería (Implementación estricta)**:
  * Uso de `camera: ^0.10.x` oficial, descartando cualquier fork de terceros inestable.
  * `path_provider` genérico + `dart:io` para el manejo de FS (Uso recomendado de `File.copy()` + `File.delete()` sobre `File.rename()` para evitar "Cross-device link" crashes que ocurren en Android entre el Temporary Storage y App Doc Dir).
  * `permission_handler: ^11.0.0` obligatorio para evitar Force Closes (FC).
* **Decisiones estratégicas necesarias antes de codificar (Ambigüedades a bloquear)**:
  * **Configuración del Encoder**: Exigencia total de fijar preset técnico (`ResolutionPreset.high` / 30fps) - NO DEJAR VARIABLE.
  * **Tratamiento de Takes**: El PM debe definir de forma explícita: si un usuario graba el `take_X+1`, ¿se sobrescribe el take anterior borrándolo del disco, o se guarda el historial consumiendo megabytes exponencialmente?
  * **Hardware Periférico**: Establecer política de UI respecto a cámara frontal vs principal, uso del flash, y anulación total/soporte de fuentes auxiliares Bluetooth.

### Riesgos
* **Crasheos de hardware por Memory Leaks (🔴 ALTO)**: Si `CameraController` no ejecuta apropiadamente su `dispose()` ante cierres de vista, provocará un Lock del hardware a nivel OS, perdiendo funcionalidad hasta forzar un Stop del proceso y provocando alza térmica.
* **Bloat de almacenamiento basura (🟡 MEDIO)**: Un mal manejo del ciclo transaccional con la carpeta `Temp` por el framework generará archivos temporales encubiertos MP4 (Storage Leaks) saturando el disco del móvil silenciosamente si no se limpian religiosamente post-guardado o al cierre.
* **Sincronización A/V (🟡 MEDIO)**: Operaciones CPU-Heavy combinando iteraciones pesadas UI (el Teleprompter renderizando líneas base) podrían retrasar el loop del grabador asíncrono, resultando en saltos (stuttering frames) en el producto final.

### Plan
* **Backlog Granular de Implementación**:
  1. Construir `ProjectFileSystem` cimentando lógicas de creación de directorios asertivos.
  2. Implementar integrador de Interfaz nativa Hardware con `permission_handler` y config cerrada.
  3. Desacople y vinculación en `RecordingPage`, atando triggers físicos con Debouncers (500ms) para anular bugs críticos de múltiple click en Botón REC que rompen el buffer OS.
  4. Lógica de interceptación en la parada: traslado manual `XFile` -> Guardado de Proyecto.
* **Metodología de Validación (Métricas)**: 
  * Playback local real de MP4 directamente extraído desde Device Explorer usando VLC constatando que Metadata interna se escribió correctamente y que A/V están rítmicamente enlazados.
  * Latencia UI de volcado menor a 1.5s entre instrucción de "Stop" y disponibilidad de path.
* **Estrategia de Testing**:
  * Unit tests probando que el indexado numérico de `.../clips/chunk_X_take_Y.mp4` respeta una secuencialidad impecable que no produce overwriting indeseado.
  * Integration tests rudos ("monkey-tests") obligatoriamente **en hardware físico** (jamás en emulador): forzando estrés extremo (start/stop en ciclos de 1 segundo 15 veces consecutivas) supervisando si el OS mata la app por OOM (Out Of Memory).
