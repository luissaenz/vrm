# Análisis Técnico: FASE 1 - Día 9-10 (IA Offline / Fallback)

> **Agente**: Antigravity
> **Documento Fuente**: `mvp-Definition.md`
> **Paso**: Día 9-10 (IA Offline / Fallback)

---

## 1. Comprensión del paso

* **Qué problema resuelve**: Previene un bloqueo absoluto (single point of failure) de la aplicación si el backend encargado de la IA generativa de guiones falla, se encuentra bajo latencia extrema, o no hay conexión de red. Garantiza que el usuario pueda siempre transicionar desde la "Idea" a la "Grabación" (RecordingPage).
* **Inputs**:
  * `ideaText`: String con la idea cruda dictada o tipeada por el usuario en el Dashboard (F3).
  * `intentionType`: Enum indicando la intención elegida (ej. PAS, Educación, Humor).
* **Outputs**:
  * Un objeto `ScriptBundle` (o `ScriptAnalysis`) estructurado y segmentado en `chunks` listo para ser ingerido por el Teleprompter y el Camera Controller.
* **Rol en el sistema**: Actúa como un *Circuit Breaker* y ruta de contingencia. Es el sustituto local, transitorio y veloz de las Fases F4-F5 (Generación IA remota).

## 2. Supuestos y ambigüedades

* **Ambigüedad (Mecánica de Partición)**: El documento sugiere *"partiéndolo mediante regex (`. ` y `,`) para tener guion a salvo"*. Si partimos el texto estrictamente por cada coma, obtendremos fragmentos (chunks) minúsculos de 2 o 3 palabras. Esto haría que el teleprompter escupa docenas de cortes al grabar (generando excesivos videos `take`).
* **Ambigüedad (Timeout)**: No se especifica cuánto tiempo se debe esperar por el backend de IA antes de inferir fallo y activar el contingente.
* **Ambigüedad (Notificación al usuario)**: ¿Debería enterarse el usuario que la IA falló y se aplicó un molde simple? El documento no menciona requerimientos de UX al respecto.
* **Preguntas críticas a resolver**:
  * ¿Se establecerá una métrica "mínimo de palabras por chunk" para el parser offline a fin de fusionar aquellos trozos muy breves destrozados por la regex?
  * ¿Cuántos templates crudos o marcos iniciales obligatorios habrá para el MVP?

## 3. Diseño funcional

* **Flujo completo (Pipeline)**:
  1. El usuario presiona "Generar".
  2. `GenerationController` encapsula la llamada HTTP a la IA remota dentro de un límite de tiempo fijo (ej. 8 segundos).
  3. Si la solicitud explota (`SocketException`, 500, o expira el timeout), se captura la excepción.
  4. El catch invoca al `FallbackScriptGenerator`.
  5. Este servicio toma la `intentionType` y recupera un String template *hardcodeado*.
  6. Opera sobre el String con un `.replaceAll("{{IDEA}}", ideaText)`.
  7. El *Chunker* parte el resultado interceptando separadores fuertes (`.` o `,`), uniendo aquellos que sean lógicamente muy breves, hasta obtener de 3 a 5 fragmentos sustanciales.
  8. Propulsa al sistema a la `RecordingPage` de forma transparente.
* **Casos normales**: El backend no responde, genera el script PAS insertando la idea velozmente, se particiona en 4 partes, carga la cámara.
* **Edge cases**:
  * Input minúsculo (ej. `< 20 chars`): El template lo envuelve y da volumen, pero podría sentirse no orgánico.
  * Input gigante (ej. copy-paste largo): El backend falla. El template offline no debería intentar repetir la estructura inyectando bloques de 10,000 letras. Se debe procesar y respetar solo un chunk central de contenido.
* **Manejo de errores**: Todo corre local de forma sincrónica. Si esta capa defensiva por algún motivo falla, arrojar el último recurso visual `SnackBar("Error crítico de generación. Modifica tu texto levemente y reintenta.")`.

## 4. Diseño técnico

* **Arquitectura sugerida**:
  * Utilizar Patrón de Estrategia (Strategy Pattern) o un proxy donde `IScriptService` es proveído por `RemoteScriptService` y `OfflineScriptService` es la red de captura mediante un try-catch envolvente principal sobre el Repositorio.
* **Componentes involucrados**:
  * `lib/features/generation/services/offline_script_simulator.dart`
  * `lib/features/generation/utils/script_chunker_regex.dart`
* **APIs / endpoints necesarios**: Totalmente desconectado, cero tráfico de network. Todo en memoria.
* **Modelos de datos (schemas sugeridos)**:
  * No requerirá un Schema DB extra. Deberá mapear forzosamente al modelo base de salida ya esperado por `ScriptAnalysis`.

## 5. Decisiones tecnológicas

* **Lenguajes / frameworks recomendados**: Dart nativo.
* **Librerías o herramientas clave**: *Zero-dependency*. Usaremos expresiones regulares nativas `RegExp(r'(?<=[.!?])\s+')`.
* **Justificación técnica**: Incrustar sistemas robustos de templating (como Moustache) rompe la métrica del MVP de acortar peso del sistema y evitar redundancias. Una simple sustitución de mapa constante e inclusión String de Dart es 100 veces más veloz, con un costo 0 de adición a la Build. 

## 6. Plan de implementación

* **Tarea 1: Factorizar Modelos Dummys (Templates)**. 
  * Crear constantes (maps) que vinculen Enums de Intención a párrafos crudos.
* **Tarea 2: Algoritmo de Regex + Normalización (Chunker)**.
  * Escribir el parcelador asegurando que, si un string partido por coma o punto es `< 6 palabras`, se adhiera al *chunk* adyacente para no matar el teleprómpter.
* **Tarea 3: Interceptor de Fallo (Circuit Breaker local)**. 
  * Reenvolver el handler en el controlador actual metiendo obligatoriamente `Future.timeout` a la firma. En el bloque de Catch inyectar la generación offline y resolver el state.
* **Tarea 4: Mensajería al usuario**.
  * Mostrar `SnackBar('Conexión débil, generando modelo offline')` para alertar en la transición (opt-in temporal).

* **Orden recomendado**: Tarea 1 -> Tarea 2 (Vital) -> Tarea 3 -> Tarea 4. En paralelo al desarrollo real actual.
* **Dependencias**: Ninguna de UI exterior, pero requiere que el Data Model de salida hacia RecordingPage esté definido unificadamente.

## 7. Riesgos y cuellos de botella

* **Técnicos**: Que la regex parta un URL, números decimanles o acrónimos (ej., `U. S. A.`). Mitigación: Validar y robustecer la regex nativa para no fragmentar por signos dentro de frases pegadas.
* **Operativos**: Si el usuario escribe ideas con groserías o ilógicas, la interpolación offline genera un guion muy torpe ya que aquí no hay un LLM operando el filtro semántico, solo una inserción String genérica.
* **Escalabilidad**: Mantener textos largos *quemados* en el binario `.apk`/`.ipa` es una mala práctica de escalabilidad en sistemas de contenido.
* **Costos**: $0. Totalmente offline.

## 8. Métricas de éxito

* **Validación**: Conectar dispositivo, arrancar con 'Modo Avión'. Intentar generación general. Debe llegar a Interfaz de Cámara con script particionado exitosamente en `< 1.2 segundos`.
* **KPIs técnicos**: Tasa de supervivencia de caídas de Red = 100%. `0 exceptions` reportadas al Analytics al fallar llamadas AI en generación.

## 9. Estrategia de testing

* **Unit tests**: 
  * Inyectar entradas como *"Hola, soy Pedro. ¿Sabes? Pienso vender 3.5 casas, de inmediato!"* al particionador. Validar que asimiló *3.5* como cifra unificada y no la cortó. Comprobar conteo mínimo de fragmentos > 1.
* **Integration tests**: 
  * Mockear HttpClient y ordenarle devolver Status 500 y/o latencia de 15 segundos. Revisar que la app no quede bloqueada perpetuamente y pase formalmente al `ClipReviewScreen / RecordingPage`.
* **Casos críticos a validar**: El motor partidor dejando Chunks vacíos o invisibles de puros espacios (" "). Asegurar el `string.trim().isNotEmpty`.

## 10. Optimización y escalabilidad futura

* **Problemas al escalar**: Requisitos de internacionalización y multilingüismo. Hoy los strings quemados en const de Dart solo soportan típicamente español o requerirán reescribir Switch Cases largos de lenguajes de device.
* **Preparación arquitectónica**: No quemar directamente los strings, sino en una interfaz que abstraiga los recursos (Ej: `AssetTemplateResolver`), para en el futuro -V2-, si no hay red, leer del sistema de `shared_preferences` los templates cargados dinámica y transparentemente por Push/JSON remoto en plano silencioso en la última sesión en línea que tuvo el cliente.
