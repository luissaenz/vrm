# Análisis de Viabilidad Técnica: Edge AI & AR

## 1. Comandos de Voz Offline (Keyword Spotting - KWS)
Para mantener el "Estado de Flow" sin latencia ni dependencia de internet.

### Tecnologías Recomendadas:
- **iOS:** `SiriKit` / `Speech Framework`. Permite reconocimiento *on-device* para comandos específicos.
- **Android:** `Vosk` o `TensorFlow Lite Audio Classification`. Alternativas ligeras y 100% offline.
- **Estrategia: Implementar un "Limited Vocabulary Engine" enfocado solo en los tokens clave: *"Listo", "Aceptar", "Repetir", "Seguir"*. Esto minimiza el consumo de batería y maximiza la precisión.

---

## 2. Tracking de Contacto Visual y AR
Garantizar la coherencia visual entre los micro-fragmentos.

### Tecnologías Recomendadas:
- **iOS (ARKit):** `ARFaceAnchor`. Proporciona el vector de mirada (`lookAtPoint`) y la posición de los ojos en tiempo real.
- **Android (ARCore):** `Augmented Faces`. Permite identificar la malla facial y la orientación del rostro.
- **Implementación de la Guía:** 
  1. Al iniciar el proyecto, se captura la posición "Home" de los ojos.
  2. Se proyecta una línea horizontal (UI Overlay) que persiste entre clips.
  3. **Corrección Predictiva:** Guardar los metadatos de la posición de la cabeza para aplicar un micro-ajuste de re-encuadres (pans/zooms) en el stitching local.

---

## 3. Stitching Local (AVFoundation / MediaCodec)
Unión de clips de 2-4 segundos al finalizar la sesión.

### Flujo Técnico:
- **Buffer Management:** Los clips se guardan temporalmente en caché local.
- **Export Session:** Se utiliza `AVAssetExportSession` (iOS) o `MediaMuxer` (Android) para concatenar los archivos sin re-codificación completa (passthrough), lo que hace que el proceso sea casi instantáneo.
- **Normalización de Audio:** Aplicación de filtros de ganancia localmente para evitar saltos de volumen entre fragmentos.

---

## 4. Subtítulos On-Device (Privacidad & Latencia)
La transcripción local es el mayor diferenciador contra competidores basados en la nube (CapCut/HeyGen).

### Tecnologías Nativas:
- **iOS:** `Speech Framework` (Dictado local en modelos nuevos).
- **Android:** `Android Speech APIs` / `Gboard Engine`.
- **Estrategia Híbrida:**
  - **Local (Gratis/Rápido):** Subtítulos inmediatos para fragmentos de 2-4s. Privacidad garantizada (IP protegida).
  - **Cloud (Premium):** Traducciones complejas o corrección gramatical avanzada vía plugins.
---

## 6. Limpieza de Audio (Noise Suppression)
Aprovechar la micro-fragmentación para procesamiento casi instantáneo.

### Implementación Local (Básica):
- **iOS:** `AVAudioEngine` con supresores de ruido integrados.
- **Android:** `NoiseSuppressor` API nativa.
- **Open Source:** `RNNoise` (RNN liviana) para limpieza de voz en tiempo real con latencia < 10ms.

### Implementación Cloud (Pro):
- **Estrategia:** Envío del audio del fragmento (4s) a APIs de reconstrucción generativa (ej. NVIDIA Maxine / Descript Studio Sound API).
- **Ventaja VRM:** Al procesar clips cortos, el tiempo de respuesta de la nube parece instantáneo para el usuario.

## 7. Viabilidad del "Semáforo de Calidad" (Local)
- **Latencia:** < 200ms tras el corte del clip.
- **Procesamiento:** El análisis de decibelios (ruido) y el éxito del tracking ocular se realizan concurrentemente con la grabación. El resultado está listo en cuanto el usuario deja de hablar.
