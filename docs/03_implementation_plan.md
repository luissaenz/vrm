# Arquitectura "Cámara Atómica" (VRM App)

## Resumen Ejecutivo
VRM App es un sistema de **transferencia cognitiva** que resuelve la fricción de la creación de contenido mediante tres pilares jerárquicos:
1.  **Productividad:** Captura manos libres y fragmentada (2-4s) para grabar y publicar rápido.
2.  **Mejora:** Feedback humano y modo entrenamiento para ganar fluidez sin esfuerzo.
3.  **Hábito:** Gamificación adaptativa para sostener la constancia.

**Estrategia:** El usuario entra por velocidad, se queda por su progreso y no abandona por el hábito.

## Stack Tecnológico: Local-First (Edge)

### 1. Procesamiento en el Dispositivo (On-Device)
- **Video Stitching & Audio:** **FFmpeg** nativo integrado. Uso de **AVFoundation** (iOS) y **MediaCodec** (Android) para passthrough sin latencia.
- **Limpieza de Audio (Local):** **RNNoise** (RNN liviana) para supresión básica de ruido en tiempo real.
- **IA & Visión (Edge AI):** 
  - **MediaPipe** (Tracking facial/manos).
  - **OpenCV** (Análisis de postura/calidad).
  - **ARKit Attention Correction** (Contacto visual nativo).
- **Audio & Comandos:** Reconocimiento local mediante frameworks nativos.

### 2. Procesamiento Híbrido (Cloud)
- **Inteligencia de Guion:** **DeepSeek API** (Fragmentación inteligente, hooks automáticos y detección de tono).
- **Audio Pro:** **Studio Sound API** (Reconstrucción de voz generativa para plugins premium).
- **IA Pesada:** Sincronización labial (Lip-sync), traducción y clonación de voz delegada a la nube (PaaS).
- **Infraestructura:** Firebase como Single Source of Truth para sincronización cross-device.

## Flujo Core de Grabación (Dynamics)
*Optimizada por la potencia del hardware local.*

1. **Fase de Asimilación:** Audio en bucle + Teleprompter.
2. **Comando "Listo":** Dispara cuenta regresiva (3s) y señal sonora.
3. **Grabación Automática:** Teleprompter activo. Corte automático al finalizar texto del fragmento.
4. **Validación por Voz:**
   - *"Repetir"*: Vuelve a fase 1.
   - *"Grabar"*: Vuelve a fase 2.
   - *"Seguir"*: Guarda clip y avanza al siguiente fragmento.

## Componentes UI Críticos
- **Guía de Contacto Visual:** Línea de referencia dinámica para nivelar ojos entre tomas.
- **Visualizador de Comando:** Feedback visual de reconocimiento de voz.
- **Motor de Stitching:** Unión transparente de clips terminados.
