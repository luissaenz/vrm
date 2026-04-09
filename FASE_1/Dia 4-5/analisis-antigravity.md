# 🧠 ANÁLISIS TÉCNICO: Auto-Stitch (Día 4-5)
**Agente:** agt (Antigravity)
**Estado:** PRODUCCIÓN / ACCIONABLE

---

## 1. Diseño Funcional

El proceso de **Auto-Stitch** es el puente crítico entre la captura fragmentada y el producto final. Su objetivo es la invisibilidad: debe ser rápido, fiable y dar feedback constante.

### Happy Path
1. El usuario aprueba el último fragmento del guion en `ClipReviewPage`.
2. El `RecordingManager` detecta que la sesión está completa (todos los chunks tienen un clip aprobado).
3. Se activa automáticamente la **Pantalla de Procesamiento** (`StitchProgressPage`).
4. El sistema genera un archivo de índice temporal y ejecuta la concatenación de videos vía FFmpeg.
5. Se muestra una barra de progreso real basada en el tiempo de ejecución.
6. Al finalizar, el usuario es dirigido a la previsualización del video consolidado `final.mp4`.

### Edge Cases (MVP)
- **Cierre Inesperado de App:** Si el proceso se interrumpe, al reiniciar el `RecordingManager` debe detectar que los clips están listos pero el `final.mp4` no existe (o está incompleto) y ofrecer "Generar Video".
- **Espacio Insuficiente:** Antes de iniciar, validar que existe al menos el doble del tamaño total de los clips en espacio libre.
- **Clips de Diferente FPS:** Aunque la app fuerza la config, si un clip falla en mantener el FPS, el stitch podría desincronizar audio. Se usará un comando de copia de streams para mitigar esto sin re-encodear.

### Manejo de Errores
- **Falla de FFmpeg:** Diálogo modal con código de error técnico y botón de "Reintentar".
- **Archivo No Encontrado:** Si un clip aprobado fue borrado del FS por el SO, marcar el chunk como "Pendiente de Grabación" y regresar al Laboratorio.

---

## 2. Diseño Técnico

### Componentes y Responsabilidades
- **`StitcherPlugin` (`lib/core/plugins/default/`):** 
    - Implementará la lógica de bajo nivel de FFmpeg.
    - Responsable de crear el archivo `inputs.txt` (Demuxer format).
    - Orquestará los callbacks de `FFmpegKit`.
- **`RecordingManager` (Extensión):** 
    - Nuevo método `Future<String> performStitching()` que consuma el plugin.
    - Validará la integridad de los paths en `sessionData.approvedClips`.
- **`StitchProgressPage` (Nueva UI):** 
    - Pantalla minimalista con `LinearProgressIndicator` y mensajes motivacionales (ej: "Uniendo tus ideas...").

### Interfaces y Contratos
- **Input:** `Map<int, String> approvedClips` (ordenado por clave).
- **Output:** `String finalPath` (Ruta absoluta a `vrm_data/projects/{id}/final.mp4`).
- **Comando FFmpeg:**
  ```bash
  ffmpeg -f concat -safe 0 -i list.txt -c copy -y final.mp4
  ```
  *Nota: `-c copy` es vital para evitar el procesamiento de CPU innecesario.*

### Modelo de Datos
- No se requieren modelos nuevos. Se extiende `SessionData` (implícito) al validar el campo `finalVideoPath`.

---

## 3. Decisiones

1. **Uso de FFmpeg Kit (Main Bundle):** Se decide usar la versión *Main* (no full) para reducir el App Size, ya que solo necesitamos concatenación básica de MP4, no filtros complejos de audio/video por ahora.
2. **Método "Concat Demuxer":** Es la técnica más rápida para unir archivos con el mismo codec. Evita la pérdida de calidad y el sobrecalentamiento del dispositivo.
3. **Persistencia de Índice:** El archivo `inputs.txt` será temporal (`Directory.systemTemp`) y se eliminará inmediatamente tras el éxito/error del comando.

---

## 4. Criterios de Aceptación

- [ ] Generación exitosa de `final.mp4` en el directorio del proyecto.
- [ ] El video final integra el 100% de los fragmentos aprobados en orden secuencial.
- [ ] Ausencia de "glitches" visuales o saltos de audio en las uniones (transiciones limpias).
- [ ] La barra de progreso en UI refleja el estado real informado por `FFmpegKitConfig.enableStatisticsCallback`.
- [ ] El proceso completo para un video de 1 min no debe exceder los 5 segundos (en dispositivos gama media).

---

## 5. Riesgos

| Riesgo | Impacto | Mitigación |
| :--- | :---: | :--- |
| **Bloqueo de UI (Main Thread)** | Alto | Ejecutar FFmpeg Kit en su propia isolación nativa (comportamiento por defecto del plugin). |
| **Permisos de Escritura** | Medio | Asegurar que el path de salida use `getApplicationDocumentsDirectory()` para evitar restricciones de Sandbox. |
| **Inconsistencia de Codec** | Bajo | Los clips son generados por la misma instancia de `CameraService`, garantizando uniformidad. |

---

## 6. Plan de Implementación

1. **Instalación (Baja):** Agregar `ffmpeg_kit_flutter_main: ^6.0.3` al `pubspec.yaml`.
2. **Core Logic (Alta):** Implementar `StitcherPlugin` creando el file-wrap de inputs y manejando el `FFmpegSession`.
3. **Servicio (Media):** Integrar el plugin en `RecordingManager` para que sea invocado tras la última aprobación.
4. **UI Refinement (Media):** Crear la vista de progreso y conectarla con los streams de eventos del proceso.
5. **Testing (Media):** Validar en iOS y Android físico el performance de la concatenación.

---

## 🔮 Roadmap (No implementar ahora)
- **Cross-fade transitions:** Agregar transiciones de 0.5s entre clips (requerirá re-encoding parcial).
- **Overlay de Marca de Agua:** Inyectar logo en la esquina superior durante el stitch.
- **Normalización de Audio:** Nivelar volúmenes si los fragmentos tienen varianza sonora.
