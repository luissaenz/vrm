# Análisis Técnico: FASE 1 - Día 3 (Revisión Visual)

### Diseño funcional
* **Objetivo central**: Implementar una interfaz de "feedback loop" asíncrono e integrado (`ClipReviewScreen`) que permita al creador validar visual y auditivamente la toma física (`.mp4`) recién grabada. Permite ramificar la decisión del usuario en dos vías: confirmar (Avanzar) o descartar (Repetir).
* **Componentes de entrada y salida**: Recibe como inputs la URI absoluta del archivo recién generado (ej. `.../clips/chunk_x_take_y.mp4`), el estado de recorrido (`chunkIndex` actual y total de bloques). Retorna un estado operativo: `Approve` (consolidando la referencia en el JSON de proyecto) o `Retake` (desencadenando un rollback físico).
* **Pipeline de ejecución**:
  1. Boot: Instanciación rápida del reproductor con el File local (`VideoPlayerController.file`).
  2. Visualización: Reproducción automática (auto-play) en bucle (looping) para que el creador examine calidad de audio y ritmo, junto con botones anclados fijos en el inferior de la UI.
  3. Intercepción Retake: Usuario oprime "Repetir". El archivo temporal crudo se elimina físicamente usando OS file handle (`dart:io`) para evitar basura acumulada, y la navegación remata volviendo a la cámara (`RecordingScreen`) en el mismo índice.
  4. Intercepción Continue: Usuario oprime "Aprobar". El path del `.mp4` final se escribe definitivamente en la estructura de metadatos `script_bundle.json` en memoria y la navegación salta al chunk X+1 (o finaliza delegando a la Fase de Auto-Stitch).
* **Edge Cases (Casos límite)**: 
  * Archivo corrupto: El VideoPlayer intenta abrir un archivo `.mp4` de cero bytes por una cámara crasheada previamente. Se debe forzar un fallo controlado en el `.initialize()` y retornar forzosamente a la vista de cámara advirtiendo del error.
  * Silencio Obligado de Sistema: En iOS, los reproductores encienden silenciados si el interruptor físico del celular (Ring/Silent) está de lado, anulando a un creador que no escuchará su propia voz en el review.

### Diseño técnico
* **Arquitectura de Software**: `ClipReviewScreen` y un `ClipReviewViewModel`/`Provider`. Aquí la pureza recae en desvincular el control del widget de video y manejar una inyección asíncrona de rutas.
* **Componentes Clave**:
  1. *VideoPlaybackManager*: Contenedor aislado de memoria que gestiona inicialización, play, y la eventual recolección de basura (dispose) del reproductor oficial de Flutter.
  2. *State Router*: Nodo de navegación inteligente responsable de usar un sistema sin apilamiento sucio (`pushReplacement` o `GoRouter` rules) para no dejar rastros de páginas muertas en el Stack.
* **Modelos en Memoria**: Actualizador para `script_bundle` local que formaliza en memoria: `ProjectData.chunks[x].validTake = "path..."`.
* **Integración OS**: Lazo profundo sobre los componentes de hardware Decoder utilizando el ecosistema core de `video_player`.
* **Escalabilidad Técnica**: La carga del reproductor es frágil frente a un video sin optimizar. En miras de escalar (clips más largos), preparar la UI inyectando frames vacíos o cargando lógicas asíncronas de pre-render (`FutureBuilder` del controller) previniendo las famosas "pantallas negras (Black Screens)" instanciando el widget solo cuando el driver anuncie estar "Ready".

### Decisiones
* **Decisiones de Librería (Implementación estricta)**:
  * Utilización rígida base de `video_player: ^2.8.0` oficial; abstenerse de interfaces pesadas o inestables como `chewie` solo por ahorrar botones, los botones se codean custom.
* **Decisiones estratégicas necesarias antes de codificar (Ambigüedades a resolver)**:
  * **Tratamiento del Storage (Soft Delete vs Hard Delete)**: Debe decidirse irrevocablemente (sugerencia CTO: imponer **Hard Delete**). Al presionar *Retake*, ¿eliminamos el archivo permanentemente mediante `File.deleteSync()` para ahorrar disco duro, o aplicamos un renombramiento basura para dar oportunidad de retroceder? (El MVP exige simplificación).
  * **Fuerza Bruta de Sonido iOS**: Definir si se requerirá inyectar un paquete controlador intermedio como `audio_session` para forzar categóricamente el ruteado por altavoz incluso si un Switch físico en iPhones está restringiendo el media.
  * **UX de Flujo Automático**: Si un usuario tiene 5 takes malos y uno bueno, ¿volvemos automáticamente por default? Esta interfaz bloqueará por milisegundos todo el pipeline.

### Riesgos
* **Fuga Fatídica de Memoria (RAM Laceration - 🔴 ALTO)**: La interacción continua de ir Cámara -> Review -> Cámara -> Review provoca un apilamiento terrible en los "Device Codecs". Si los desarrolladores olvidan ejecutar `_videoPlayerController.dispose()` adecuadamente antes de hacer el `Navigator.push` de regreso a la cámara, o hacen que convivan vivos ambos recursos la app explotará invariablemente en < 5 iteraciones continuas.
* **Navigational Memory (Stack Overflow) (🟡 MEDIO)**: Utilizar `Navigator.push()` sin destruir capas previas generará una pila de pantallas de cámara superpuestas inusables que arrastrará el contexto del Widget. Es crítico usar mecanismos como `.replace()` o `.popUntil()` en Flutter.
* **Flickering Visual (🟡 MEDIO)**: Pantallazos negros momentáneos mientras el Decoder interpreta los Headers moov atom del archivo local `.mp4`, rompiendo la inmersión UX con parpadeos no planificados.

### Plan
* **Backlog Granular de Implementación**:
  1. Tarea de Infraestructura: `ClipReviewScreen.dart` estructurando `FutureBuilder` aguardando la correcta inicialización vía `File` de `video_player`.
  2. Tarea de UI/UX: Incorporar Spinner o Snapshot provisional local cubriendo el vacío hasta el `controller.value.isInitialized`. Auto-play activado con repetición (loop).
  3. Tarea Lógica Sensible: Incorporar los botones Retake y Approve, encintando obligatoriamente las acciones purga / almacenamiento en bloques `try/catch` de `dart:io`.
  4. Tarea de Recolección (Crítica): Construir sobreescritura estricta del método `dispose()` de la Screen eliminando y vaciando punteros de memoria del `VideoPlayerController` previo al roteador.
* **Métricas de Éxito**:
  * Time-to-First-Frame visualizable no mayor a < 500ms localmente.
  * Ausencia de errores OutOfMemoryExceptions incluso con una validación intensiva humana.
* **Estrategia de Testeo (QA)**:
  * Unit Testing mockeando fallas de FileSystem corroborando que si el usuario hace "Retake", la variable interna de estado devuelva un "Path Failed/Null" correctamente.
  * Monkey Test Integral: Usuario con terminal midiendo perfiles de devTools (Memory Profiler), abriendo, cerrando, grabando clips triviales y pulsando "Retake" al azar 20 veces a velocidad humana-rápida supervisando la bajada forzada del Garbage Collection.
