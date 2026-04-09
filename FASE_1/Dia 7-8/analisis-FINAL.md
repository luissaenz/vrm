# Documento Consolidado de Análisis: Día 7-8 (Persistencia Local Offline)

## 1. Resumen ejecutivo
El objetivo de este paso es implementar la capa de persistencia local offline para el MVP de la app "Cámara Atómica" (VRM). Esto garantizará la **resiliencia total ante interrupciones** (cierres abruptos, batería baja o crashes), permitiendo a los usuarios reanudar sus proyectos (grabaciones de video fragmentadas) desde el último estado válido. La solución se basa en un sistema de archivos local (`path_provider`) estructurado por directorios y archivos JSON para los metadatos, utilizando patrones de escritura atómica.

## 2. Diseño funcional consolidado

### Flujo Completo
1. **Creación:** El usuario confirma un guion. El sistema genera un `project_id` (UUID v4), crea la carpeta `/vrm_data/projects/{project_id}/` e inicializa los archivos `input_schema.json`, `script_bundle.json` y `session_data.json`.
2. **Grabación Incremental (Event-Driven Autosave):** Cada vez que un usuario aprueba un segmento de video, el archivo se mueve atómicamente de la caché temporal a `/clips/` y se actualiza `session_data.json`. **No se confía en el ciclo de vida del OS (onPause)** para salvar, el guardado es reactivo a la transición de fase explícita o a la aprobación individual de un segmento.
3. **Manejo de Descartes (Hard-delete):** Al repetir una toma finalizada ("retake"), el clip anterior se elimina físicamente del disco (`file.deleteSync()`) para proteger la salud del almacenamiento del dispositivo en vez de apilar basura residual que satura rápidamente.
4. **Reanudación (Resume):** Al abrir la app, el Dashboard escanea la carpeta asincrónicamente. Si detecta un proyecto incompleto, ofrece la opción de retomarlo, restaurando el pipeline desde el último clip con estado "validado".

### Casos Especiales (Edge Cases) Resueltos
*   **Clips huérfanos o ausentes:** Si `session_data.json` referencia un clip que ya no existe físicamente, un proceso validador en la carga del repositorio local reestablece el estado de ese tramo a "pendiente" (`status: "missing"`).
*   **Archivos corrompidos durante la escritura (Crash abrupto):** Mitigado estrictamente mediante **Escritura Atómica**.
*   **Almacenamiento lleno (Disk Full):** Se debe capturar `FileSystemException` de forma global al intentar grabar video o al hacer rename de un clip, mostrando un error UI de "Espacio insuficiente" en lugar de generar un error genérico o corromper el modelo interno.

## 3. Diseño técnico definitivo

### Arquitectura (Clean Architecture + Repository Pattern)
Separaremos responsabilidades aislando un Patrón Repository con DataSource físico local, que es robusto y permite crecimiento:

```text
lib/
├── core/
│   ├── persistence/
│   │   ├── io_utils.dart                # Helpers reutilizables (ej. Atomic Write, MoveFallback)
│   │   ├── local_file_datasource.dart   # Operaciones crudas de File Storage
│   │   └── models/
│   │       ├── project_schema.dart      # Clases PODO
│   │       ├── script_bundle.dart       # Usarán json_serializable o equivalentes seguros
│   │       └── session_metadata.dart
├── data/
│   └── repositories/
│       ├── project_repository.dart      # Interfaz abstracta (IProjectRepository)
│       └── project_repository_impl.dart # Une LocalFileDatasource y los parseos json_serializable
```

### Decisión sobre Operaciones I/O y Fallbacks
*   **Mover VS Copiar un Video:** Para trasladar el clip .mp4 desde la zona temporal del framework a la subcarpeta `/clips/` se utilizará prioritariamente `File.rename()` por velocidad e inodes. Si el OS arroja un error cross-filesystem (ej. partición bloqueada o volumen externo), se activará un fallback explícito a `File.copy()` seguido del respectivo `File.delete()`.
*   **Escritura Atómica OBLIGATORIA (`safeWriteJson`):** 
    Toda actualización de archivos `.json` utilizará un esquema transaccional:
    `tmpFile.writeAsStringSync(data) -> tmpFile.renameSync(destinationFile)`. Previene JSON truncados o parcialmente llenos si ocurre un cierre catastrófico a nivel kernel y asegura compatibilidad con rutinas asíncronas masivas concurrentes.

### Modelos de Datos Formateados (Schemas robustos y preparados)
Los archivos JSON contarán con control de un tag `"schema_version": 1`. Se modelará por key explícita del segmento asegurando accesos directos (`O(1)`), en lugar de buscar por arreglos:
```json
{
  "schema_version": 1,
  "status": "recording",
  "fragments_state": {
    "0": {"status": "validated", "clip_path": "clips/frag_0_take_1.mp4"},
    "1": {"status": "pending", "clip_path": null}
  },
  "last_updated": "2026-04-08T10:00:00Z"
}
```

## 4. Decisiones tecnológicas

*   **`path_provider` (^2.1.0):** Empleo canónico en Flutter de `getApplicationDocumentsDirectory()`, garantizando acceso consistente para iOS y Android y asegurando que las carpetas de proyectos y configuración sobrevivirán al limpiador temporal del OS.
*   **`uuid` (^4.0.0):** Crucial para los IDs del proyecto y prevención de choques de nombres de clips (saltándose los timestamps que sufren si cambian zonas horarias de repente).
*   **Parseo seguro de Models (e.g. `json_serializable`)*:** Adoptar un parseo y mapeo fuertemente tipado en Dart con soporte autogenerado para campos nullable con fallbacks coherentes en caso de corrupciones leves. 
*   **Parseo Asíncrono en Dashboard (uso de `compute` / Isolates):** Proceso preventivo. Leer del disco un loop docenas de carpetas, con sus JSONs y parsearlos bloqueará severamente la animación de Flutter si se lanza desde el *main thread*. El `listProjects()` estará en una capa asíncrona delegando idealmente en `compute()` para aislar la sobrecarga.

## 5. Plan de implementación

1.  **Fundamentos (Día 7, Bloque 1):** Configurar paquete y dependencias en `pubspec.yaml` (`path_provider`, `uuid`). Programar y tipar los modelos DTO PODO usando constructores fuertemente asegurados contra inputs `dynamic`.
2.  **I/O Storage Service (Día 7, Bloque 2):** Implementar la lógica del `local_file_datasource.dart`, conteniendo la lógica de `safeWriteJson` atómica y la transacción del clip MP4 garantizando los directorios físicos inicializados.
3.  **Core Repository (Día 8, Bloque 1):** Aglutinar DataSource y DTO en `project_repository_impl.dart`, cumpliendo con `IProjectRepository`. Conectar al inyector de dependencias.
4.  **Enlace al Pipeline (Triggers) (Día 8, Bloque 2):** Implementar llamadas en el flujo (Eventos): Crear proyecto justo luego de aceptar guion. Invocar Update JSON en la aprobación con éxito del Segmento y de `rename()` de un *.mp4*.
5.  **Front-Dashboard (Día 8, Bloque 3):** Conectar `listProjects()` para mostrar de inmediato proyectos truncos y funcionales. Implementar la API de Delete físico por interfaz para usuarios para habilitar depuración completa. 

## 6. Riesgos y mitigaciones consolidados

| Riesgo | Impacto | Mitigación Elegida |
| :--- | :--- | :--- |
| **Escritura Interrumpida (JSON truncado)** | CRÍTICO | Uso estricto de atómica `tempFile.writeAsString() + tempFile.rename()`. |
| **Saturación Subproceso UI (Jank)** | ALTO | Carga masiva de proyectos en Dashboard con procesos off-thread o Future concurrents / `compute`. |
| **Almacenamiento OS Lleno** | ALTO | Uso proactivo al llamar escritura o grabar limitando con un Catch de la `FileSystemException`, fallando limpiamente y mostrando diálogo a usuario en español de "Espacio Llano". |
| **Clips Archivos Fantasmas (Broken links)** | MEDIO | Validar que exista el archivo `File(clip).existsSync()` en la apertura (load); si no degrada a "pending". |

## 7. Métricas de éxito

*   **Pérdida de Sesión Resiliente (Crash Survival Rate):** Forzando un stop en el IDE en pleno grabado de un segmento, al abrir de nuevo el target el Dashboard reencadena al 100% de los Segmentos pasados (completados).
*   **Tiempos de Interfaz de Dashboard (Rendimiento):** Una prueba de métrica de lectura con 20 proyectos (cada uno con 3 fragmentos JSON) debe generar la vista de listado en menos de `400ms`. 

## 8. Estrategia de testing

1.  **Test Unitario de Resiliencia I/O:** Usar una unidad aislada proveyendo un JSON incompleto y fallido y observar su reacción de no volcar excepciones nativas no procesadas, validando el graceful degradation (o marcando el proyecto completo como corrompido pero controlable).
2.  **Prueba de Integración Falsa de Crash:** Lanzar script en backend de Flutter simulado guardando segmento 1 de video -> deteniendo sin grabar JSON -> validando error de clip missing, y Viceversa garantizando que al grabar primero el texto, no desate fallos de syncrono.

## 9. Consideraciones de escalabilidad

*   **Índice de Metadatos V2:** Mencionan múltiples agentes un futuro red flag. A medida que la lista de proyectos en Dashboard crezca masivamente a futuro o incluya búsquedas completas de palabras, el read JSON O(N) de docenas de carpetas escalará severamente en disco y procesador. La decisión arquitectónica y abstracta de interfaz unificada facilita que a posteriori una DB basada en `SQLite` sirva de *índice ligero* global, consultando nombre/status/fecha para la UI rápida, pero delegando siempre al FileSystem el peso de blobs. La transición actual previene bloqueos masivos sin forzar el coste de SQlite en un MVP urgente.
