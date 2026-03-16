# Biblia de Diseño y UX: VRM App

## 1. Identidad de Marca y Posicionamiento
**Concepto:** Coach / Entrenador Personal de Comunicación.
**Posicionamiento:** Identidad aspiracional. Usar la app es parte de "ser un mejor creador".
**Personalidad:** Minimalista, Calma, Profesional, Moderna, Humana.
**Referencias:** Headspace (Calma), Apple Fitness (Cierre de anillos), Notion (Claridad).

## 2. Mandamientos de UX (Basados en el Estudio de Lodder)
1. **Protección del Flow:** Prohibido el feedback analítico inmediato. El análisis ocurre en la fase de "Feedback Retardado".
2. **Coach Invisible:** Validación inmediata mediante Semáforo (Verde=Sigue) solo después de la captura del clip.
3. **Personalización Adaptativa:** Detección de fatiga; la UI sugiere simplificar frases si hay fallos recurrentes.
4. **Fricción Cero:** Máximo 2 decisiones simultáneas. Flujo guiado del "grabar → revisar → continuar".
5. **Inventario de Clips:** Visualizar el progreso como acumulación de activos, no solo tareas completadas.

## 3. Paleta y Estética
- **Base (80%):** Grises carbón cálidos o beiges desaturados. Sin estridencias.
- **Acción (15%):** Un solo color protagonista (Verde Menta o Azul Eléctrico suave).
- **Semántica:** Verde (Logro), Amarillo (Sugerencia), Rojo (Error técnico solamente).

## 4. Tipografía y Microcopy
- **Fuente:** Sans Serif moderna (Inter / SF Pro / Manrope).
- **Tono de Voz:** Cercano, calmo, empático.
  - *Ejemplos:* "Respirá, no es en vivo", "Repetir también es avanzar", "Tu mensaje se entiende".

## 5. Diseño de Pantallas Críticas

### 5.1 Grabación (Hands-Free)
- **Modo "Glance and Grab":** El texto aparece con alta opacidad para lectura (fase de asimilación), se vuelve casi invisible durante la grabación real para evitar la "mirada de teleprompter" y re-aparece al finalizar.
- **Semáforo de Adherencia:** Un pequeño círculo que cambia entre verde (aprobado semántico) y azul (verbatim exacto), dando feedback de fidelidad al mensaje.
- **Limpieza Automática:** Visualización opcional de cómo la IA elimina muletillas ("eh", "um") en el preview instantáneo.

### 5.2 Dashboard de Progreso
- **Visualización:** Niveles con nombres humanos ("Primer Mensaje", "Ritmo Constante").
- **Gamificación Avanzada:** 
  - Progression Loops: Ciclos de incentivo basados en progreso personal.
  - Recompensas visibles (XP, niveles, badges) que se pueden reflejar en la ficha final del video.
  - Streak Freeze: Posibilidad de "congelar" la racha (estilo Duolingo) para evitar desmotivación.
- **Contextual Nudging:** Notificaciones personalizadas ("Has mejorado tu claridad un 20%").
- **Adaptive Difficulty:** La complejidad de los desafíos sube conforme el usuario domina métricas (ej. de muletillas a entonación).

## 6. Módulos de Entrenamiento Específicos

### 6.1 Interfaz de Calentamiento (Pre-Grabación)
- **Visual:** Tarjetas rápidas con frases de énfasis o trabalenguas.
- **Feedback:** Onda de audio circular que valida la articulación antes de la toma real.

### 6.2 Nudges In-Flow (Aliento / Alerta Sutil)
*Opcional y minimalista para proteger el estado de Flow.*
- **Visual:** Bordes de pantalla con gradientes suaves: **Gris/Neutro** (Calma), **Verde** (Aliento: Buen ritmo/contacto), **Ámbar** (Alerta sutil: Fatiga/Métrica decayendo).
- **Control:** Sin pop-ups de texto durante la toma; el feedback detallado se reserva para el Post-Clip.

### 6.3 Interfaz de la "Escala del Influencer"
- **Progression View:** Mapa de niveles donde se desbloquea el "tiempo máximo de grabación" (3s → 60s) como recompensa de maestría.
- **Dashboard de Voz:**
  - **Gráfico de Línea:** Variación de PPM (Palabras por Minuto) a lo largo del tiempo.
  - **Gráfico de Tarta:** Desglose de pausas por duración (1-2s, 3s+, etc.).
  - **Tabla de Muletillas:** Frecuencia exacta y porcentaje del total.
- **Transcripción Inteligente:** Texto completo con las muletillas resaltadas para revisión contextual (estilo Descript).
