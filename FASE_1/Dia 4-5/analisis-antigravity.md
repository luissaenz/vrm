# Análisis Técnico: FASE 1 - Día 4-5 (Auto-Stitch por Línea de Comandos)

### Diseño funcional
* **Objetivo central**: Automatizar la unión física (concatenación) de todos los clips individuales aprobados (`chunks`) en un producto único, indivisible y exportable (`final.mp4`), de forma ininterrumpida y transparente para el usuario final. Representa el valor "mágico" central del software.
* **Componentes de entrada y salida**: 
  * Inputs: Un array inmutable y estrictamente ordenado de rutas absolutas (`List<String> validTakesPaths`) alojadas en la carpeta temporal de proyecto local.
  * Outputs: Un archivo único consolidado `final.mp4` originado en disco, listo para ser consumido por un Media Player o ser guardado en la galería nativa, además de emitir un stream de porcentaje `0-100%` en todo el proceso.
* **Pipeline de ejecución**:
  1. Boot de Pantalla: El router despliega la `StitchingScreen`, anulando botones de "Atrás" (Back gesture lock).
  2. Indexado: Un servicio traduce el array de rutas en un archivo serial de texto temporal (ej. `list.txt`) con la sintaxis exigida por decodificadores: `file '/absolute/path/chunk_1.mp4'`.
  3. Ejecución FFMPEG: Arranca el proceso de background nativo de la consola ejecutando el armado algorítmico directamente contra el file System del celular (usando un pipeline estricto de demuxer).
  4. Monitoreo UI: Callbacks asíncronos extraen las *statistics* del motor de FFMPEG reportando cuántos fotogramas/segundos ha escrito vs. el total matemático calculado. (Actualización del Spinner circular a usuario).
  5. Remate: Al recibir `ExitCode.success`, el controlador depura y destruye el `list.txt`, y habilita silenciosamente un `Navigator.pushReplacement()` a la pantalla final de `Exportación` (Día 6).
* **Edge Cases (Casos límite)**: 
  * Si la batería se agota o se destruye el proceso a la mitad, se genera un archivo `final.mp4` corrupto o truncado. El Bootloader del celular en la FASE 2 o 3 deberá tener una rutina de "Purga de huérfanos" pre-inicio.

### Diseño técnico
* **Arquitectura de Software**: Aislamiento forzoso en la capa de Domain/Infra; esta labor es matemática-algorítmica y no debe tener conexión al contexto UI. Componente núcleo: `FFmpegStitcherService`.
* **Motor Base y Ejecución**: La gema y corazón de esto es `ffmpeg_kit_flutter`. No obstante, el comando a inyectar no debe provocar "re-encoding" (renderizado gráfico pixel por pixel) sino un **Concatenado Demuxer**. 
  * *Comando de Referencia Obliteratorio*: `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4`
  * *Por qué*: Usar `-c copy` hace una copia bitánea directa de headers, uniendo 5 minutos de video en **segundos**, mientras que transcodificar tardaría minutos y fundiría la placa de iOS/Android.
* **Librerías Extra Cruciales**: `wakelock_plus` (Indispensable para evitar que la pantalla se apague y el SO ponga a FFMPEG a dormir / pause los sub-hilos C++ rompiendo el procesamiento).
* **Modelos de Gestión de Promesas**: Retorno de estructuras tipo `Result<File, StitchError>` porque el fracaso en C++ suele fallar silenciosamente sino se captura un Event Status ajeno al Exception genérico de Dart.

### Decisiones
* **Decisiones de Librería (Bloqueadas y Exigidas)**:
  * Utilización rígida base de `ffmpeg_kit_flutter: ^6.0.3` forzando paquete "Min-Video" o "LTS" (Evitar incluir en pubspec el paquete completo que inyectará +120Mb a la compilación binaria final metiendo librerías inútiles de decodificación satelital).
* **Ambigüedades que el Product Owner / UX deben confirmar inmediatamente**:
  * **Comportamiento Background**: FFMPEG es violento con la asignación del Kernel. Definir explícitamente: ¿Deshabilitaremos y exigiremos que el usuario deje la app encendida (con Wakelock) como un "No cambie de app", o se asume el inmenso costo arquitectónico de crear Event Channels para correr `ios background tasks`? (Sugerencia técnica CTO para MVP: Imponer Wakelock y prohibir/desistir de Background Task).
  * **Destrucción de Archivos Origen**: Una vez exista `/final.mp4`, ¿se requiere destruir inmediatamente todo el árbol `/clips/` (pesando GBs) para vaciar espacio, o el MVP va a retener los metadatos permitiendo "Volver atrás a des-concatenar y re-editar"? Retenerlos ahoga teléfonos de >64GB. (Decisión esperada: Limpieza incondicional).

### Riesgos
* **Incompatibilidad de Frames/Muxers (🔴 RIESGO MUY ALTO)**: El uso inmensamente superior del modo `-c copy` tiene un coste y talón de Aquiles letal: Todos los archivos DEBEN tener la exactamente misma resolución, idéntico codec h264/hevc y el mismo TimeBase nativo. Si la configuración de cámara en "Día 1-2" no se bloqueó férreamente y un bloque se grabó en 30fps y otro en 25fps (Frame-VFR variable de móviles) el resultado concatenado saldrá con Audios Desincronizados progresivos (labios fuera de tiempo en la voz).
* **Cross-Relative Path Security en FFMPEG (🔴 ALTO)**: iOS Sandbox restringe FFMPEG al acceder a estructuras de `list.txt`. Obligatoriamente usar la bandera `-safe 0` en comando e imprimir paths absolutos estrictos o crasheará a pesar de tener correcto código.
* **Muerte Térmica de Proceso (🟡 MEDIO)**: Aunque menor si se copia crudo, operar FFMPEG provoca alertas de System Watchdogs con alzas RAM momentáneas gigantes.

### Plan
* **Desglose de Tareas (Backlog Técnico)**:
  1. Tarea Infra: Implementar paquete en `pubspec` y crear el generador de `ManifestListTxtCreator` (que transforma la lista virtual de dart en un txt físico temporal en la carpeta caché).
  2. Tarea UI Segura: Levantar `StitchingScreen`, bloquear rotaciones de pantalla durante la carga para atar la retención de estado asíncrono e implementar `Wakelock` en todo su scope `init` a `dispose`.
  3. Tarea Motor (Brain): Armar `FFmpegProvider.execute()`. Definir String de comando duro. Crear y suscribirse al StatisticsCallback extrayendo la fórmula del porcentaje del total (CurrentTime / TotalTime).
  4. Tarea Mantenimiento: Purga condicional (`Directory(clips).deleteSync()`) sujeto a directriz de producto post-terminación existosa.
* **Métricas Esperadas**:
  * Eficiencia I/O: El concatenado completo de un archivo de 3 minutos acumulado no debe exceder en absoluto los ~15/20 segundos (validable).
  * Ningún retraso o discrepancia audiovisual (A/V Sync error) al testear clips intercalados múltiples.
* **Testing Específico Estructural**:
  * Unit test sobre el builder de Strings confirmando que el layout de FFMPEG respeta saltos de carro UNIX `\n` (evitando issues de windows vs mac al pasar `list.txt` por el parser interno).
  * QA Monkey Device Testing: El probador humano deberá deliberadamente minimizar/mandar la aplicación a Home justo al instante que se ejecuta el comando de stitching para supervisar qué interrupción devuelve la tarea nativa y si las variables corrompen el estado.
