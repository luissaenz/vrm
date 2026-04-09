# Análisis Técnico Unificado: FASE 1 — Día 3 (Revisión Visual de Clips)

## 1. Resumen Ejecutivo
**Qué se va a construir:** 
Un "feedback loop" crítico post-grabación que permite al creador visualizar el clip (`.mp4`) recién generado antes de que se incruste definitivamente en la línea de montaje del proyecto.

**Enfoque elegido:** 
Se implementará una pantalla asíncrona de revisión (`ClipReviewScreen`) que operará funcionalmente como un diálogo interactivo de pantalla completa. La navegación adoptará un patrón funcional de respuesta (`Navigator.push<ReviewAction>`), permitiendo desacoplar la revisión en sí del motor de almacenamiento y estado global. En caso de una toma inaceptable, se forzará un "Hard Delete" físico para optimizar los recursos restringidos del MVP.

---

## 2. Diseño Funcional Consolidado

### Flujo Completo
1. El usuario detiene la grabación en `RecordingPage` (`stopRecording()`).
2. Se realiza una **validación preventiva** del archivo (chequeo de tamaño > 0 bytes). Si está corrupto, se reporta el error y la revisión ni siquiera se abre (se mantiene al usuario en grabación).
3. Si es válido, se instancia `ClipReviewScreen` pasando la URI absoluta local.
4. **Reproducción automática ("Auto-loop"):** El clip comienza a reproducirse infinitamente en bucle tan pronto se decodifica en memoria. La UI con opciones de confirmación se anclará en la interfaz.
5. **Decisión del usuario:**
   - **"Aprobar/Siguiente" (Continue):** El toma es válida, se guarda la validación en el estado de metadatos general (`session_data.json` o equivalente en memoria) y se devuelve una señal positiva a la ruta madre, promoviendo el salto al fragmento N+1 o a la finalización de sesión.
   - **"Repetir/Regrabar" (Retake) o botón 'Back':** El usuario decide descartar su grabación más reciente. Retorna la señal de descarte. La lógica base en el originador dispara la eliminación limpia del archivo .mp4 temporal y se reestablece el módulo listando la cámara para grabar en el mismo índice de fragmento.

### Edge Cases Tratados
- **Archivo Resultante Corrupto:** Validación estricta previa a la inicialización del `video_player`.
- **Interruptor de silencio físico (iOS):** Asumimos reproducción regular de base, permitiendo controles al usuario para subir el volumen, prescindiendo de forzar el hardware con paquetes de tercero.
- **Doble toque accidental:** La acción del primer toque en botones desactiva la interactividad temporalmente hasta la resolución asíncrona.
- **Acceso por retroceso físico del equipo (.pop() de sistema o botón atras):** Es automáticamente asimilado como `ReviewAction.retake`.

---

## 3. Diseño Técnico Definitivo

### Arquitectura Final
Adoptar una delegación responsiva basada en retorno seguro a un Stateful originador. 

**Componentes Principales:**
1. **`ReviewAction` (Enum):** `retake`, `next`, `finish`. Define el contrato exacto de navegación de salida devuelto a la grabación.
2. **`ClipReviewScreen` (UI Hija):** Widget agnóstico e independiente basado puramente en un `StatefulWidget` que retiene y administra en su scope su propio `VideoPlayerController` minimizado localmente. Se apoya en un `FutureBuilder` para inicializar en un estado de "Carga" y transiciona a una UI limpia al estar listo, previniendo de forma reactiva las "black screens".
3. **Controlador Madre (`RecordingPage`):** Centraliza la lógica de las persistencias. Recibe la respuesta `ReviewAction` del Navigator local como un Promise/Future asíncrono y, en consecuencia, avanza contadores lógicos o purga archivos mediante `File.deleteSync()` de `dart:io`.

### APIs / Dependencias Intrasistema
- Entrada transaccional: Instancia de Fichero OS local proveniente de un `clipPath`.
- Salida transaccional (En caso de Continuar): Inserción del path validado en registro para stitching (ej., bloque activo de `script_bundle.json`).

---

## 4. Decisiones Tecnológicas

### Stack Elegido
- **`video_player: ^2.9.1` (Oficial Flutter):** 
  *Justificación Comparativa:* Todos los análisis coinciden en esta dependencia estable. Opciones más pesadas como `chewie` inyectan ~500KB de capa superflua con comportamientos poco adaptables, mientras que una UI minimalista cuyos botones implementaremos nativamente en la misma Screen nos aportará control total sin dependencias rotas a futuro.
- **Flujo de Retorno (Push > Pop con Dato, en lugar de PushReplacement o Router Global):** 
  *Justificación Comparativa:* Enviar un Reemplazo (apilando infinidad de páginas y demoliendo el state) o inyectar NotifyProviders globales es erróneo para este modal efímero de confirmación. Usar el patrón de *Dumb Widget Stateful* (`var accion = await Navigator.push(...)`) acopla menos el estado general de la aplicación, facilita el control y evitamos "Ram Lacerations" (Memory leaks documentados fuertemente, suscitados por decodificadores mal destruidos de la memoria entre vistas perdidas del router).
- **Gestión de Basura local: Hard Delete Inmediato:** 
  *Justificación:* Mantener el historial de *todos los takes descartados* en el teléfono forzaría al diseño a integrar un bottom-sheet elector recargando al MVP con dependencias no vitales. Implementar un borrado forzoso (Hard Delete en `dart:io`) optimiza dramáticamente el I/O en hardware móvil de gama media baja y simplifica la lógica actual. 

---

## 5. Plan de Implementación

**Tarea 1: Modelo de Navegación Aislado**
- Construcción del enum semántico `ReviewAction`.
*Dependencias: Ninguna.*

**Tarea 2: Validaciones y Desconexión Primaria (Gateway Seguro)**
- Refactorización fina en `_stopRecording()` ubicada en la `RecordingPage`. Añadir lógica de file mapping y validación por existencia local y control que rechace cualquier file con tamaño <1 Byte previo a transicionar al ReviewScreen.
*Dependencias: Tarea 1.*

**Tarea 3: UI Pura y Estructura Mecánica del Review (`ClipReviewScreen`)**
- Constructor formal que adquiera por parámetro `clipPath`, índices lógicos correspondientes actuales, y texto temporal del bloque como contexto semántico a renderizar (estilo mini teleprompter visual inferior). Diseño enfocado de la interfaz overlay sobre el render box.
*Dependencias: Tarea 1.*

**Tarea 4: Lógica de Ciclo de Vida Local del Video Player**
- En `ClipReviewScreen`, aplicar el contructor `VideoPlayerController.file()` en base al path validado, en método `.initState()`. Incorporar Loader Spinner que impere hasta asegurar vía future un estado `.isInitialized()`, entonces aplicar auto loop con `.play()` y `.setLooping(true)`. 
- **[CRÍTICO]** Escribir limpieza en `dispose()` con sobre-escritura formal asegurando la remoción total del pointer a la memoria sobre del Controller en sistema base.
*Dependencias: Tarea 3.*

**Tarea 5: Conexión Bidireccional Integrada (En RecordingPage)**
- Implementación de la solicitud vía `navigator` asíncrono hacia `ClipReviewScreen`. 
- Switch statement para resolver la salida devuelta: `next` procede a incrementar índice y avanza UI (O cierra de haber concluido chunks). `retake` o `null` activan un purge hard-link vía `File(path).deleteSync()` física e invoca reseteo explícito para habilitar el grabador en el iterador fragmento previamente fallido.
*Dependencias: Tareas 2 y 4.*

---

## 6. Riesgos y Mitigaciones

| Riesgo (Identificado) | Severidad | Mitigación Definida |
| --------------------- | --------- | ------------------- |
| **Fuga de memoria severa (RAM Laceration) por VideoPlayer superpuestos o Zombies.** | 🔴 ALTO | Revisión y code review de la invocación rigurosa a `videoController.dispose()`. Solo uno activo per stack, eliminando la vida residual a su salida inminente. |
| **Video en negro carente de dummy frame inicial o sin marco de carga (Flickering).** | 🟡 MEDIO | Condicionar absolutamente el widget con `AspectRatio` encapsulado en un `ValueListenableBuilder` o wrapper que supervise visual status pre-decodificación en sistema nativo (Dummy poster precarga). |
| **Pase de Archivo OS falso de 0 bytes o Temblores físicos (File Lock).** | 🟡 MEDIO | Detección manual de acceso IO y comprobante >0 bytes impidiendo derivación de render; expulsar al usuario con SnackBar advirtiendo error del micrófono/cámara crudo, evitando paros en `ClipReviewScreen`. |
| **Mute natural de sistemas iOS (Ring/Silent hardware switch status).** | 🟢 BAJO | Advertencias o UI hints de sonido en review explícitas al usuario sin recurrir como parche urgente a bindings de root (`audio_session`) para MVP. |

---

## 7. Métricas de Éxito

- **Time-to-first-frame (TTFF):** < 500ms medible empíricamente al transcurrir el salto nativo y consolidar frames con el VideoPlayer en OS nativo real.
- **Sobrevivencia y Solidez en QA (Crash/Leak rate null):** Lograr de forma fluida y auditable tolerar un "Testing Monocíclico" de 20 secuencias sucesivas agresivas (Grabar → Revisar → Repetir) sin generar reportes de saturación (Out of Memory Exception) en DevTools.

---

## 8. Estrategia de Testing

- **Caja Blanca sobre IO nativo:** Mockeo estricto o simulación forzosa cargando una URI falsa rota para corroborar los diques de la Tarea 2, validando intercepciones transparentes antes de intentar `file open`. 
- **Prueba Unitaria de Retake/Hard-Delete:** Control físico del assert con test local de entorno asegurando que tras un rechazo en UI `ReviewAction.retake`, la inspección manual demuestre en un expect `.existsSync() == false`.
- **Doble Toque Excesivo UX (Bounce Defense):** Verificar consistencia limitadora de toques, unificando estados interactivos hasta que el Async Navigation router conteste y remueva el state, previniendo enfilamiento fantasma y ruteos incontrolables de stack.

---

## 9. Consideraciones de Escalabilidad

- En V2 (FASE >2), se podrá considerar transcodificación delegada en plano invisible, propiciando pre-buffers ligeros 1080p y previsualizaciones ultrarrápidas, si el bitrate y 4k del MVP actual demuestran ser incompatibles en dispositivos entry list de Android.
- La abstracción del modelo enum permite la transición asimétrica por la cual `ReviewAction` podría en iteraciones ulteriores, propulsar nuevas ventanas de edición de micro-trimming o segmentación de rangos visuales finos para el usuario demandante avanzado de la plataforma.
