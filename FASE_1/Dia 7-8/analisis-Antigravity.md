# Análisis de Implementación: Día 7-8 (Persistencia Local Offline)

**Agente:** Antigravity
**Documento Base:** `mvp-Definition.md`
**Enfoque del Paso:** Persistencia Local Offline de datos y preservación de estados del proyecto (`vrm_data`, recuperación y autosave).

---

## 1. Comprensión del paso

*   **Problema que resuelve:** Protege al usuario de interrupciones destructivas durante el flujo de grabación. Dado que el flujo interactúa con hardware intensivo (teleprompter y cámaras), el SO móvil puede liquidar la aplicación temporalmente. Este paso asegura que cualquier proyecto pueda reanudarse desde el último segmento validado sin obligar al usuario a recomenzar desde la idea.
*   **Inputs:** El estado transitorio en memoria RAM del Pipeline (el objeto o modelo de proyecto en la app que contiene metadatos de configuración, el string del guion segmentado, y paths locales de clips temporales ya capturados).
*   **Outputs:** Una jerarquía física serializada en disco interno del SO (JSONs y carpetas contenedoras para cada `uuid` de proyecto), que plasma el estado 1:1 de los modelos en memoria.
*   **Rol en el sistema:** Base unificadora del progreso (checkpointing). Funciona también como puente (Single Source of Truth en disco) entre el `_cameraController` que graba fragmentos y el `ffmpeg_kit` que leerá los fragmentos para el stitching final (Día 4-5).

## 2. Supuestos y ambigüedades (Aclaraciones Críticas)

*   **¿Cuál es el Trigger del Guardado?** El doc no menciona cuándo ocurre la serialización. Un abordaje on-pause puede ser arriesgado por cierres abruptos (OOM killer del OS). 
    *   *Resolución esperada:* El guardado debe ser de tipo autosave reactivo. Cualquier transición principal (Ideas -> Guion, o Finalización positiva de un Segmento de video) debe enganchar un guardado en background asíncrono.
*   **Archivos de Video Temp Vs Destino:** Cuando se para de grabar, el video suele quedar en un directorio tipo caché del SO. 
    *   *Resolución esperada:* El Controller debe Mover `File.copy() / File.rename()` explícitamente el stream resultante hacia la carpeta `./clips/` del proyecto y luego invocar la actualización de `session_data.json` asegurando simetría.
*   **Retención de Archivos:** Los archivos `.mp4` residuales pesan decenas/cientos de megabytes.
    *   *Ambigüedad:* ¿Qué pasa con "takes" repetidos o proyectos no exportados?
    *   *Pregunta crítica antes de ejecutar:* ¿Borraremos físicamente los clips descartados al instante de "rehacer", o hacemos un *soft-delete* (solo no referenciado en JSON)? Recomiendo en el MVP un hard-delete `file.deleteSync()` para el clip reemplazado para no arriesgar saturar el almacenamiento local.

## 3. Diseño funcional

**Flujo End-to-End (Autosave Pipeline):**
1. **Creación (Casos normales):** El usuario confirma el guion generado. El sistema hace un flush a disco creando la carpeta UUID del proyecto e inicializa `input_schema.json` y `script_bundle.json`. Al Dashboard entra un registro inicial con estado "Borrador".
2. **Grabación (Update incremental):** El usuario graba el Segmento 1 de 3. Aprueba el clip. El clip se aloja en `clips/seq1.mp4`. El `session_data.json` actualiza un diccionario indicando `{ "segment_1": "clips/seq1.mp4", "completed": false }`.
3. **Restauración (Resume):** La aplicación se abre "en frío". El usuario entra al Dashboard. El sistema lee (con `listSync`) los IDs de directorios en `vrm_data/projects/`, de ahí, escanea sus `input_schema.json` para sacar los títulos de lista. Al pulsar sobre él, se deserializa en memoria todo el modelo de proyecto.
4. **Edge Cases & Correcciones:** 
    *   *Si JSON dice que `seq1.mp4` existe, pero el archivo no está físicamente (borrado fantasma):* Al instanciar, una validador chequea todos los paths y retrocede el estado del Segmento 1 a "vacío".
    *   *Si la app se mata durante el render (Autostitch):* El `session_data.json` debería marcar que la fase de auto-stitch no terminó adecuadamente para no generar crashes por MP4 corruptos en el final, y ofrecer re-render a los crudos.

## 4. Diseño técnico

*   **Arquitectura sugerida:** Patrón de Repositorio sobre un *Local Storage Provider*.
    *   `Project` (Entity Principal) -> contiene referencias de negocio.
    *   `ProjectRepository` (Interfaz abstracta) -> `saveProject()`, `loadProject()`, `listProjects()`.
    *   `ProjectFileSystemStorage` (Implementación) -> usa dart:io y `path_provider` para la serialización.
*   **Manejo de Rutas Base:**
    *   El "Root" será: `final appDir = await getApplicationDocumentsDirectory(); final vrmRoot = Directory('${appDir.path}/vrm_data/projects');`
*   **Modelos de Datos y Jerarquía (Schemas):**
    *   **InputSchema/ScriptBundle:** Strings y lista secuencial con metadata texto (PODO simple).
    *   **SessionData:** El tracker de estado fundamental. Debe ser un JSON clave-valor. Ejemplo: `{"currentPhase": "RECORDING", "clipsRecorded": {"0": "path/clip_0_T1.mp4"}, "lastUpdate": "ISO8601"}`.

## 5. Decisiones tecnológicas

*   **Flutter `path_provider`:** Obligatorio. Encapsula las diferencias restrictivas de almacenamiento entre Sandboxes de iOS y Content Providers en Android (Directorio persistente pero invisible para la app general archivos, y no devorado por el colector de caché del OS).
*   **Garantías JSON Serializables (`dart:convert`):**
    *   *Decisión:* Parsers fuertemente tipados. Aunque el MVP sea ágil, los métodos de serialización desde objeto de memoria a JSON deben validarse.
    *   *Por qué:* Los modelos de estado híbridos darán múltiples null pointers en UI al rehidratar una sesión si se usan diccionarios sueltos en Dart.
*   **I/O Transaction File Swap (Atómico):**
    *   Para mitigar corrupción por interrupción súbita, escribir temporal y renombrar atómicamente: 
        `fileTmp.writeAsString(json); fileTmp.rename(fsDestination);` 
        (Si el OS interrumpe, el viejo config siempre perdura e intacto).

## 6. Plan de implementación

*   **Tarea 1: Estructuras Locales y Serializadores.** Crear las clases modelo (`VrmProject`, `SessionMetadata`, `ScriptBundle`) e implementar métodos nativos `.toJson()` y `.fromJson(Map<String, dynamic> json)`.
*   **Tarea 2: `ProjectFileSystemStorage` (Capa Física).** Implementar las herramientas de I/O puras: crear subcarpetas basadas en proyecto, métodos que guardan/renombran un file, método que agarra string a archivo y viceversa.
*   **Tarea 3: Bootstrapping & Dashboard Read.** En el main (o providers) proveer una inyección de dependencias con este Storage, y enganchar al `dashboard_page` para leer los proyectos existentes extrayendo solo `input_schema/script_bundle` local.
*   **Tarea 4: Save Triggers (Autoguardado) / Clip File Manager.** Conectar la salida del controller de grabación (al dar el OK a la toma) con una utilidad que mueva el clip de `/temp_cam` a su subcarpeta `/vrm_data/projects/{id}/clips/` síncronamente antes de invocar el guardado de estado JSON.
*   **Tarea 5: Cleanup System.** Pequeña utilería para el botón "Delete Project" o limpieza general, borrando la subcarpeta interna con todos sus videos. Dependencia crítica antes de darlo por cerrado.

## 7. Riesgos y cuellos de botella

*   **Escalabilidad a nivel de Dashboard:** A medida que crezcan los proyectos, leer docenas de archivos JSON de disco al solo renderizar una View de listado producirá *UI Jank* (pérdida de frames) si se hiciera síncronamente en el UI thread. **Mitigación:** Asegurar que `list_projects` hace lecturas asíncronas bajo `compute()` / isolates en Dart.
*   **Almacenamiento Local Físico Exhausto (IOError):** Grabar en 4K/1080p dejará videos pesados rápidamente. Guardar archivos podría fallar si Storage = 0 bytes. **Mitigación:** Capturar Excepciones `FileSystemException` cuando estalle en error _Disk Space Full_ y devolver un flag visual claro para prevenir corrupción al usuario.
*   **Permitir huérfanos de video locales:** Las cancelaciones del sistema dejando archivos de sistema temporales. 

## 8. Métricas de éxito

*   **Pérdida de Sesión nula (Crash Test):** En medio del segundo segmento, detener el target en iOS Xcode (kill process hard). Al reiniciar, abrir la app y se debe aterrizar en el Segmento 2 intacto reconociendo el clip del Segmento 1. Esto valida el auto-save + rehidratación completa.
*   **Dashboard Loading Time:** El listado general carga en menos de `300ms` al parsear metadatos en un escenario con 10 proyectos persistentes (Performance KPI local).

## 9. Estrategia de testing

*   **Unit Tests:** Evaluar PODO DataClasses. Insertar JSONs erróneos, vacíos, y sin algunas keys esperadas para ver qué valores default arroja (prevenir `NullPointerException` en front-end).
*   **Integration Tests:** (Testing físico imperativo). Boot de un entorno de prueba en Dart que genere 1 proyecto e intente simular el pegado de 3 clips fantasma (`.txt` vacios o de bytes de ceros) y su posterior lectura, confirmando que la estructura se levantó `vrm_data -> /project_id -> /clips`. 

## 10. Optimización y escalabilidad futura

*   **Reemplazo del Listado (Metadata Indexing):** En V2/V3, el listado de proyectos será ineficiente si se extrae leyendo iterativamente miles de carpetas y JSONS. Habrá que saltar a SQLite (ej. Paquete *sqflite* o *drift*) para indexar únicamente el "Abstract" o Status de metadatos (Titulo, Fecha, Status del Job) en memoria en tiempo `O(1)`, delegando el `ProjectFileSystemStorage` ÚNICAMENTE para guardar guiones extensos y apuntar a los blobs pesados.
*   **Sincronización en la Nube:** Desde este diseño, la carpeta del proyecto está autocontenida por concepto, es decir: si una integración en un futuro manda la carpeta entera y sus clips a AWS S3 (Backup y Export API), el modelo seguirá siendo compatible estructuralmente. 
