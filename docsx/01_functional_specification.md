## 1. Visión Estratégica y Fundamentación Científica
La app se posiciona como un **Coach Personal de Comunicación**. Su diseño se rige por la protección del **Estado de Flow** (Lodder, 2021).

### 1.1 El Principio de "Flow"
- **Feedback Diferido (Principal):** El análisis detallado se ofrece post-grabación para no interrumpir la inmersión inconsciente.
- **Nudges In-Flow (Secundario):** Alertas visuales minimalistas (máx. 1-2 por sesión) desactivadas por defecto. Foco correctivo mecánico (ej. muletillas).
- **Entorno Seguro:** Repetición instantánea sin menús complejos ni penalización emocional.

### 1.2 Jerarquía de los 4 Pilares Disruptivos
1. **Productividad (Magia Invisible):** Edición basada en texto. Arquitectura Local-First.
2. **Mejora (Coach Invisible):** Validación por semáforo. **Escala de Competencia** (Novato → Maestro) que adapta el desafío a la habilidad.
3. **Hábito (Gamificación Estructural):** Rachas de creación e Inventario de Clips.
4. **Plataforma (Hiper-Personalización):** IA Adaptativa y Ecosistema de Plugins.

---

## 2. Pilar 1: Preparación e Inteligencia Adaptativa
*Foco: Reducir la ansiedad y el bloqueo creativo mediante IA que aprende del usuario.*

- **Producción Automatizada (Local):**
  - Unión automática de clips (Stitching) mediante **AVFoundation/MediaCodec** sin latencia.
  - **Subtítulos On-Device:** Transcripción instantánea y privada (Privacidad Total).
  - Dinamismo visual: Micro-zooms/pan automáticos (Magia Invisible).
- **Técnica "Glance and Grab":** El texto se muestra para asimilación rápida, desaparece durante la captura para forzar contacto visual y mirada natural, y vuelve para el siguiente clip.

## 3. Pilar 2: Experiencia de Grabación y Coach Invisible
*Foco: Proteger el flujo y asegurar calidad profesional instantánea.*

- **Coach Invisible (Validación):**
  - **Semáforo de Adherencia:** Calificación inmediata de dicción, energía y fidelidad al guion (Verbatim/Semántico).
  - **Semáforo de Audio (Preventivo):** Análisis del ruido ambiental antes de grabar. Sugerencia de "Modo Calle" o cambio de entorno.
  - **AI Overdub (Corrección):** Capacidad de corregir palabras erróneas en el audio usando síntesis de voz del usuario sin volver a grabar (IA Generativa local/nube).
- **Limpieza de Audio Inteligente:**
  - **Nivel Básico (Local):** Supresión de ruido constante (viento, motor) integrada en el stitching.
  - **Nivel Studio Sound (Plugin Cloud):** Reconstrucción de voz profesional (eliminación de eco y ruido complejo).
- **Detección de "Mirada de Zombi":** Alerta sutil si detecta lectura activa (movimiento ocular lateral).

## 4. Pilar 3: Análisis y Feedback Diferido (Maestría)
*Foco: Reflexión profunda y analítica post-grabación (Modelo Ovation).*

- **Dashboard de Rendimiento:**
  - **Score Global:** Calificación (0-100%) comparada con el desempeño histórico propio.
  - **Métricas de Voz:**
    - **Ritmo (PPM):** Promedio numérico + gráfico de línea temporal de fluctuación.
    - **Pausas:** Frecuencia por minuto + gráfico circular de duración (1-2s, 2-3s, etc.).
    - **Claridad:** Tabla de muletillas (frecuencia/%) y transcripción con resaltado contextual.
    - **Entonación:** Medidor de Variación Tonal (Monótono -> Dinámico).

## 5. Pilar 4: Escala del Influencer y Progresión
*Foco: Gestionar la carga cognitiva mediante el equilibrio desafío-habilidad.*

### 5.1 Escala de Competencia (Niveles)
- **Nivel 1 (Novato):** Micro-fragmentación obligatoria (3-5s). Foco en contacto visual y adherencia al guion.
- **Nivel 2 (Desarrollo):** Bloques de 15-30s. Foco en ritmo (PPM) y variación tonal.
- **Nivel 3 (Maestro):** Bloques de hasta 60s. Foco en storytelling y energía narrativa.

### 5.2 Sistema de Aliento y Alerta (Feedback Dinámico)
- **Modo Alerta:** Si el usuario falla en bloques largos, la app sugiere volver a micro-fragmentos ("Estrategia de alta carga cognitiva. Sugerimos fragmentar").
- **Modo Aliento:** Micro-victorias por clips limpios ("¡3 clips seguidos sin muletillas!").
- **Refuerzo Positivo:** Celebración de la constancia sobre la perfección técnica.
- **Comparación Centrada en el Yo:** Sin rankings públicos para evitar ansiedad.
- **Responsabilidad Social:** Grupos de reto con puntuación compartida.

## 5. Experiencia Contextual y Adaptativa
- **UI Evolutiva:** El layout se simplifica o expande (Modo Experto) según el uso y métricas.
- **Onboarding Gamificado:** Mini-desafío interactivo de 60s en el primer inicio.
- **Contextual Nudging:** Notificaciones de logros reales ("Mejoraste tu ritmo un 15%").
- **Continuidad Multiplataforma:** Sincronización para revisión final en Desktop/Web.
- **Asistente IA Integrado:** Guía en tiempo real y revisión de performance post-grabación.

## 6. Pilar 4: Plataforma y Ecosistema (Plugins)
*Foco: Escalabilidad sin inflar el núcleo de la app y creación de red económica.*

- **Arquitectura de Plugins (Modelo Híbrido SDD):**
  - **Plugins Generativos (IA):** Operan vía **Cloud API**. El plugin es un contrato de especificación (.yml) que conecta con el servidor externo. (Ej: Lip-sync, Clonación de Voz).
  - **Plugins de Utilidad (Local):** Operan vía **Scripts Sandboxed** (JS/Lua) o Assets (JSON). Se ejecutan en el dispositivo para latencia cero. (Ej: Filtros, Guías AR).
  - **Validación Automática:** Los plugins deben cumplir con los **JSON Schemas** de datos y contratos **OpenAPI** definidos por el SSoT de la plataforma.
- **Modelo de Negocio:**
  - Marketplace integrado con Revenue Share.
  - Paquetes de metodología para coaches y expertos.

## 7. Arquitectura Técnica: Local-First (Edge Computing)
*Foco: Latencia cero, privacidad y funcionamiento offline.*

### 7.1 Procesamiento en el Dispositivo (Local)
- **Stitching de Video:** Unión de micro-fragmentos mediante librerías nativas (**AVFoundation** en iOS, **CameraX/MediaCodec** en Android).
- **Edge AI:** Reconocimiento de voz (Comandos "Listo", "Seguir") y análisis de semáforo de calidad procesado localmente.
- **Micro-Edición:** Aplicación de zooms, pans, filtros y subtítulos en tiempo real.

### 7.2 Procesamiento en la Nube (Hybrid Cloud)
- **Plugins de IA Generativa:** Tareas de alto cómputo como **Lip-Sync**, clonación de voz y re-renderizado de avatares (Wan 2.2).
- **Almacenamiento y Backup:** Sincronización de proyectos y gestión de activos del "Inventario de Clips".

## 8. IA de Próxima Generación (Escalabilidad)
- **Visual IA:** Avatares Wan 2.2, cambio de vestimenta y escenarios.
- **Internacionalización:** Traducción de guion + Lip-sync sincronizado.
