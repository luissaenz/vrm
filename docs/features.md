## CATÁLOGO COMPLETO DE FUNCIONALIDADES DE "CÁMARA ATÓMICA"
### Hoja de Ruta desde el MVP hasta la Plataforma Definitiva

Este documento enumera y describe **exclusivamente las funcionalidades** del producto, organizadas por categorías y etapas de madurez. Cada funcionalidad incluye su propósito, comportamiento esperado y la etapa en la que estará disponible.

---

# PARTE 1: FUNCIONALIDADES CORE (MVP - ETAPA 1)

## 1.1 SISTEMA DE IDENTIDAD Y PERFIL

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F1.1** | Onboarding "The Mirror Step" | Video de coach virtual que pregunta el obstáculo principal del usuario. Selección de identidad mediante 3 tarjetas visuales: Líder, Creador, Vendedor. | MVP |
| **F1.2** | Perfil de usuario local | Almacenamiento local de preferencias básicas (rol, velocidad por defecto, tono preferido). Archivo `user_profile.json`. | MVP |
| **F1.3** | Valores por defecto por perfil | Asignación automática de configuración inicial según perfil seleccionado (velocidad, tono, frameworks sugeridos). | MVP |

## 1.2 LABORATORIO DE IDEAS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F2.1** | Campo de entrada de idea | Área de texto grande para que el usuario escriba su idea. Placeholder rotativo con ejemplos. | MVP |
| **F2.2** | Entrada por voz a texto | Botón de micrófono que transcribe la idea del usuario y llena el campo automáticamente. | MVP |
| **F2.3** | Selector de intención | 3 botones tipo chip: 🎯 Vender, 🧠 Educar, ✨ Conectar. Preselección basada en perfil. | MVP |
| **F2.4** | Detección automática de guion | Si el usuario pega texto largo (>200 palabras), detecta que es un guion y ofrece fragmentarlo directamente. | MVP |
| **F2.5** | Panel de opciones avanzadas (colapsado) | Sección expandible con controles de personalización de guion (ver sección 1.3). | MVP |

## 1.3 GENERACIÓN Y EDICIÓN DE GUION

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F3.1** | Generación de guion con IA | Transforma la idea en un guion estructurado usando IA. Incluye pantalla de "Generando..." con animación. | MVP |
| **F3.2** | Frameworks narrativos básicos | 3 opciones: Vender (estructura PAS), Educar (estructura How-To), Conectar (estructura storytelling). | MVP |
| **F3.3** | Selector de tono | 3 opciones: Zen/Serio, Cerca/Amigo, Hype/Energía. Afecta vocabulario y estilo del guion. | MVP |
| **F3.4** | Selector de velocidad de habla | Lento (130 wpm), Normal (150 wpm), Rápido (170 wpm). Ajusta duración estimada de fragmentos. | MVP |
| **F3.5** | Selector de nivel de audiencia | Principiante, Colega, Experto. Ajusta complejidad del vocabulario. | MVP |
| **F3.6** | Generación automática de CTA | Crea frase de cierre según intención: comentar, seguir, link en bio, compartir. | MVP |
| **F3.7** | Editor de guion manual | Interfaz para editar, reordenar, eliminar o añadir fragmentos. Cada fragmento con límite de 12 palabras. | MVP |
| **F3.8** | Vista compacta de fragmentos | Lista de todos los fragmentos con numeración, texto y duración estimada. | MVP |
| **F3.9** | Reordenamiento por arrastre | Usuario puede cambiar el orden de los fragmentos arrastrándolos. | MVP |
| **F3.10** | Contador de palabras por fragmento | Indicador visual del número de palabras, con advertencia al superar el límite (12 palabras). | MVP |
| **F3.11** | Botón "Regenerar guion" | Genera una nueva versión del guion con la misma idea pero enfoque diferente. | MVP |
| **F3.12** | Guardado de borrador | Guarda el estado actual del guion sin aprobar para continuar después. | MVP |

## 1.4 TELEPROMPTER Y VISUALIZACIÓN

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F4.1** | Teleprompter en tercio superior | Texto anclado en el 20% superior de la pantalla, cerca del lente de la cámara. | MVP |
| **F4.2** | Contenedor semitransparente | Fondo oscuro con blur para legibilidad sobre cualquier fondo. | MVP |
| **F4.3** | Tipografía grande y sans-serif | Texto grande (mínimo 24pt) y de alto contraste. | MVP |
| **F4.4** | Resaltado de fragmento activo | El fragmento actual se muestra completo; los anteriores/futuros no visibles durante grabación. | MVP |
| **F4.5** | Indicador de progreso de fragmentos | Texto superior: "FRAGMENTO 3/8". Barra de progreso segmentada. | MVP |
| **F4.6** | Ajuste de tamaño de fuente | Control para aumentar/disminuir tamaño del texto del teleprompter. | MVP |

## 1.5 CONTROL POR VOZ

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F5.1** | Comando "grabar" | Inicia la cuenta atrás y la grabación del fragmento actual. | MVP |
| **F5.2** | Comando "siguiente" | Avanza al siguiente fragmento después de aprobar el actual. | MVP |
| **F5.3** | Comando "repetir" | Descarta el clip actual y vuelve a grabar el mismo fragmento. | MVP |
| **F5.4** | Comando "menú" | Abre el panel de control inferior con opciones adicionales. | MVP |
| **F5.5** | Indicador de escucha activa | Icono de micrófono pulsando que indica que el sistema está escuchando comandos. | MVP |
| **F5.6** | Feedback visual de comandos | Confirmación visual cuando un comando de voz es detectado (el botón correspondiente se ilumina). | MVP |

## 1.6 INTERFAZ DE GRABACIÓN

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F6.1** | Sticky Bottom CTA | Botón persistente en la parte inferior que muta según el estado: GRABAR (rojo) → DETENER (rojo pulsante) → SIGUIENTE (verde). | MVP |
| **F6.2** | Cuenta atrás visual | Números grandes 3-2-1 en pantalla antes de comenzar grabación. Flash de borde al llegar a 0. | MVP |
| **F6.3** | Borde de estado (Tally light) | Borde rojo alrededor de la pantalla durante la grabación activa. | MVP |
| **F6.4** | Botón de cierre (✕) | Permite salir de la sesión de grabación guardando el progreso. | MVP |
| **F6.5** | Botón de rotación de cámara | Cambia entre cámara frontal y trasera durante la preparación. | MVP |
| **F6.6** | Modo práctica | Usuario puede leer el fragmento en voz alta sin que se grabe, para calentar o ensayar. | MVP |
| **F6.7** | Detección automática de fin por silencio (VAD) | Al detectar silencio > 1.5 segundos, detiene la grabación automáticamente. | MVP+ |
| **F6.8** | Timeout de seguridad | Si la grabación excede duración estimada + 3 segundos, se detiene automáticamente. | MVP |

## 1.7 REVISIÓN Y APROBACIÓN DE FRAGMENTOS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F7.1** | Reproducción automática en loop | Al terminar de grabar, el clip se reproduce en bucle para revisión. | MVP |
| **F7.2** | Botones de decisión | 🗑️ "Repetir" (rojo) y ✅ "Siguiente" (verde) flotantes sobre el video. | MVP |
| **F7.3** | Aprobación pasiva | Si el usuario no actúa en 3 segundos, el clip se acepta automáticamente (barra de progreso visible). | MVP+ |
| **F7.4** | Silenciado por defecto | El clip se reproduce sin audio para no interrumpir el flujo mental (opción de activar audio). | MVP |
| **F7.5** | Contador de takes | Registra cuántos intentos ha tomado cada fragmento. | MVP |
| **F7.6** | Transición suave entre fragmentos | Animación de deslizamiento al pasar al siguiente fragmento. | MVP |

## 1.8 MENÚ DE CONTROL DURANTE GRABACIÓN

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F8.1** | Activación por voz ("menú") | Abre panel inferior de control sin tocar la pantalla. | MVP |
| **F8.2** | Activación por gesto | Deslizar hacia arriba desde el borde inferior abre el menú. | MVP |
| **F8.3** | Panel de menú principal | Grid de botones: ⚙️ Ajustes, 🔁 Cámara, ⏯️ Pausar, 🚪 Salir, 🗑️ Repetir, ⬇️ Cerrar. | MVP |
| **F8.4** | Subpanel de ajustes rápidos | Sliders para velocidad de texto, tamaño de fuente, brillo de pantalla. | MVP |
| **F8.5** | Control por voz dentro del menú | Cada opción tiene comando de voz asociado ("ajustes", "cerrar", etc.). | MVP |
| **F8.6** | Pausa de grabación | Al abrir el menú, la grabación se pausa automáticamente si estaba activa. | MVP |

## 1.9 POST-PRODUCCIÓN AUTOMÁTICA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F9.1** | Auto-stitch básico | Unión secuencial de todos los clips aceptados en orden. | MVP |
| **F9.2** | Eliminación de silencios entre clips | Corta los silencios al inicio y final de cada clip para transiciones limpias. | MVP |
| **F9.3** | Normalización de audio básica | Ajusta el volumen para que todos los clips tengan nivel similar. | MVP+ |
| **F9.4** | Barra de progreso de procesamiento | Indicador visual del avance del auto-stitch. | MVP |
| **F9.5** | Procesamiento en segundo plano | Opción de procesar el video en background y recibir notificación cuando esté listo. | MVP+ |
| **F9.6** | Exportación a MP4 | Genera archivo de video final en formato MP4. | MVP |

## 1.10 PREVISUALIZACIÓN Y EXPORTACIÓN

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F10.1** | Reproductor de video final | Visualización del video completo con controles estándar. | MVP |
| **F10.2** | Guardar en galería | Exporta el video a la galería del dispositivo. | MVP |
| **F10.3** | Compartir | Abre el share sheet nativo para compartir en redes sociales o mensajería. | MVP |
| **F10.4** | Selector de formato de exportación | 9:16 (Reels/TikTok), 1:1 (Instagram), 16:9 (YouTube), Original. | MVP+ |
| **F10.5** | Texto sugerido para publicación | Genera un copy sugerido basado en el guion y tono del video. | MVP+ |

## 1.11 ANÁLISIS Y MÉTRICAS BÁSICAS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F11.1** | Duración total del video | Muestra el tiempo total del video generado. | MVP |
| **F11.2** | Número de fragmentos | Indica cuántos fragmentos componen el video. | MVP |
| **F11.3** | Mensaje de ánimo | Texto positivo al completar el primer video: "¡Primer video completado!" | MVP |

## 1.12 GESTIÓN DE PROYECTOS BÁSICA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F12.1** | Lista de proyectos recientes | Muestra los últimos proyectos del usuario con miniatura y fecha. | MVP |
| **F12.2** | Estados de proyecto | Borrador, en progreso, completado, procesando. | MVP |
| **F12.3** | Reanudar proyecto | Continuar grabación de un proyecto en progreso. | MVP |
| **F12.4** | Duplicar proyecto | Crear nuevo proyecto basado en guion anterior. | MVP+ |

## 1.13 ESTRUCTURA DE DATOS (INVISIBLE PARA USUARIO)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F13.1** | Asset Bundle | Estructura de carpetas por proyecto con idea original, guion, clips y video final. | MVP |
| **F13.2** | ScriptBundle.json | Archivo JSON con guion fragmentado, duraciones, tono, framework. | MVP |
| **F13.3** | InputSchema.json | Registro de la idea original y parámetros de generación. | MVP |
| **F13.4** | AssetManifest.json | Metadatos del video final: duración, fragmentos, métricas básicas. | MVP |
| **F13.5** | Persistencia basada en archivos | Todo el estado guardado en archivos JSON, no en memoria volátil. | MVP |

---

# PARTE 2: FUNCIONALIDADES DE VALIDACIÓN Y RETENCIÓN (ETAPA 2)

## 2.1 ANÁLISIS AVANZADO DE RENDIMIENTO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F14.1** | Métricas detalladas por video | Palabras por minuto (WPM), cantidad de muletillas, duración de pausas. | Etapa 2 |
| **F14.2** | Gráfico de ritmo de habla | Visualización de la velocidad a lo largo del video, con zona ideal marcada. | Etapa 2 |
| **F14.3** | Detección y conteo de muletillas | Lista de "um", "eh", "o sea" con frecuencia y porcentaje. | Etapa 2 |
| **F14.4** | Transcripción con resaltado | Texto completo del video con palabras de relleno resaltadas en color. | Etapa 2 |
| **F14.5** | Análisis de pausas | Gráfico circular con distribución de pausas por duración. | Etapa 2 |
| **F14.6** | Detección de contacto visual | Porcentaje de tiempo mirando a cámara (si hardware lo permite). | Etapa 2 |
| **F14.7** | Comparativa con videos anteriores | Gráfico de evolución de métricas a lo largo del tiempo. | Etapa 2 |

## 2.2 GAMIFICACIÓN Y PROGRESO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F15.1** | Creator Score | Métrica única compuesta (0-2000) que combina claridad, ritmo, filler words, energía y consistencia. | Etapa 2 |
| **F15.2** | Niveles de Creador | Novato (0-300), Comunicador (301-600), Narrador (601-900), Influencer (901-1300), Maestro (1301-2000). | Etapa 2 |
| **F15.3** | Barra de progreso de nivel | Visualización del avance hacia el siguiente nivel. | Etapa 2 |
| **F15.4** | Desbloqueo de beneficios | Cada nivel desbloquea nuevas funcionalidades (frameworks, plugins, modos). | Etapa 2 |
| **F15.5** | Sistema de rachas (streaks) | Contador de días consecutivos grabando. Calendario de actividad mensual. | Etapa 2 |
| **F15.6** | Rachas máximas | Registro de la racha más larga alcanzada por el usuario. | Etapa 2 |
| **F15.7** | Logros e insignias | "Primer video", "7 días seguidos", "30 videos", "Maestro de pausas", etc. | Etapa 2 |
| **F15.8** | Efecto "Antes y Después" | Comparativa lado a lado del primer video vs el más reciente. | Etapa 2 |

## 2.3 SISTEMA DE MISIONES PERSONALIZADAS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F16.1** | Generación automática de misiones | Basada en la métrica con peor rendimiento del último video. | Etapa 2 |
| **F16.2** | Tipos de misiones | "Reduce filler words a menos de 5", "Mantén ritmo entre 140-160 WPM", "Mejora contacto visual 10%". | Etapa 2 |
| **F16.3** | Recompensas por misión | Puntos extra para Creator Score al completar la misión. | Etapa 2 |
| **F16.4** | Seguimiento de misiones activas | Hasta 3 misiones simultáneas con progreso visible. | Etapa 2 |
| **F16.5** | Dificultad adaptativa | Las misiones se ajustan según el nivel y progreso del usuario. | Etapa 2 |

## 2.4 PERFILADO AVANZADO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F17.1** | Calibración automática por voz | Análisis del primer video para inferir velocidad, tono y nivel de vocabulario. | Etapa 2 |
| **F17.2** | Ajuste automático de teleprompter | Velocidad de texto se adapta a la velocidad natural del usuario. | Etapa 2 |
| **F17.3** | Historial de métricas | Registro histórico de todas las métricas para análisis de tendencias. | Etapa 2 |
| **F17.4** | Perfil de usuario enriquecido | Almacena preferencias, historial, rachas, niveles y logros. | Etapa 2 |

## 2.5 POST-PRODUCCIÓN AVANZADA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F18.1** | Normalización de iluminación por clip | Análisis de luminancia y ajuste individual para consistencia visual. | Etapa 2 |
| **F18.2** | Corrección de color básica | Ajuste de brillo, contraste y saturación basado en frame de referencia. | Etapa 2 |
| **F18.3** | Reducción de ruido de audio | Limpieza de ruido de fondo (tráfico, aire acondicionado). | Etapa 2 |
| **F18.4** | Compresión y optimización | Reducción de tamaño de archivo sin pérdida significativa de calidad. | Etapa 2 |
| **F18.5** | Generación de subtítulos automáticos | Subtítulos en el idioma original (SRT o quemados). | Etapa 2 |

## 2.6 BIBLIOTECA Y PLANTILLAS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F19.1** | Biblioteca de guiones | Guardado de guiones exitosos para reutilización. | Etapa 2 |
| **F19.2** | Plantillas de contenido | 5 plantillas predefinidas: educativo, venta, storytelling, tutorial, promocional. | Etapa 2 |
| **F19.3** | Etiquetado de proyectos | Posibilidad de añadir etiquetas a proyectos para organización. | Etapa 2 |
| **F19.4** | Búsqueda en biblioteca | Por título, contenido del guion o etiquetas. | Etapa 2 |

---

# PARTE 3: FUNCIONALIDADES AVANZADAS Y DIFERENCIADORAS (ETAPA 3)

## 3.1 GRABACIÓN MULTI-DISPOSITIVO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F20.1** | Conexión entre dispositivos vía QR | Un dispositivo genera QR, el otro escanea para emparejar. | Etapa 3 |
| **F20.2** | Roles de dispositivo | Principal (cámara) y secundario (control/teleprompter). | Etapa 3 |
| **F20.3** | Sincronización de comandos | Iniciar/detener grabación desde dispositivo secundario afecta al principal. | Etapa 3 |
| **F20.4** | Sincronización de teleprompter | El texto avanza sincronizado en ambos dispositivos. | Etapa 3 |
| **F20.5** | Grabación simultánea | Ambos dispositivos graban al mismo tiempo, generando clips etiquetados por cámara. | Etapa 3 |
| **F20.6** | Transferencia de clips | Los clips del dispositivo secundario se transfieren al principal al finalizar. | Etapa 3 |
| **F20.7** | Auto-stitch multicámara | Unión automática alternando ángulos (cámara A para frases impares, cámara B para pares). | Etapa 3 |

## 3.2 DIRECTOR DE IA (MONTAJE SEMÁNTICO)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F21.1** | Análisis semántico de guion | IA clasifica cada fragmento por intención: datos, historia, emoción, CTA. | Etapa 3 |
| **F21.2** | Asignación automática de cámara | Sugiere qué cámara usar para cada fragmento según su intención. | Etapa 3 |
| **F21.3** | Indicaciones en teleprompter | Muestra iconos: "Usa cámara B para esta frase" durante grabación. | Etapa 3 |
| **F21.4** | Sugerencias de zoom | Indica cuándo hacer zoom in/out para énfasis. | Etapa 3 |
| **F21.5** | Generación de B-roll | Detecta descripciones visuales y sugiere insertar clips de stock. | Etapa 3 |
| **F21.6** | Edición automática basada en intención | Al unir, aplica transiciones y efectos según el tipo de contenido. | Etapa 3 |

## 3.3 CORRECCIÓN DE CONTACTO VISUAL POR IA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F22.1** | Análisis de mirada post-grabación | Detecta dónde mira el usuario en cada frame. | Etapa 3 |
| **F22.2** | Corrección de pupilas | Redirige digitalmente la mirada hacia la cámara. | Etapa 3 |
| **F22.3** | Toggle de activación | Opción en ajustes para aplicar corrección (requiere créditos). | Etapa 3 |

## 3.4 OVERDUB Y CORRECCIÓN POR TEXTO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F23.1** | Entrenamiento de voz inicial | Usuario graba frases de calibración para clonar su voz. | Etapa 3 |
| **F23.2** | Corrección de palabras por texto | Escribir texto corregido → IA genera audio con voz clonada. | Etapa 3 |
| **F23.3** | Lip-sync automático | Sincronización labial con el nuevo audio generado. | Etapa 3 |
| **F23.4** | Reemplazo en contexto | Sustituye solo la palabra o frase indicada, manteniendo el resto. | Etapa 3 |

## 3.5 TRADUCCIÓN AUTOMÁTICA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F24.1** | Detección de idioma original | Identifica el idioma del video grabado. | Etapa 3 |
| **F24.2** | Traducción de guion | Traduce manteniendo tono, estructura y estilo. | Etapa 3 |
| **F24.3** | Generación de audio traducido | Voz clonada en el idioma destino. | Etapa 3 |
| **F24.4** | Lip-sync en nuevo idioma | Sincronización labial con el audio traducido. | Etapa 3 |
| **F24.5** | Exportación multi-idioma | Genera versiones del video en diferentes idiomas. | Etapa 3 |

## 3.6 RADAR DE TENDENCIAS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F25.1** | Conexión a fuentes de tendencias | Google Trends, RSS feeds por nicho, APIs de redes sociales. | Etapa 3 |
| **F25.2** | Detección de temas relevantes | Identifica temas trending en la industria del usuario. | Etapa 3 |
| **F25.3** | Sugerencias proactivas | "Hoy se habla de X en tu sector. ¿Quieres generar un guion?" | Etapa 3 |
| **F25.4** | Generación automática sobre tendencia | Al aceptar, genera guion completo sobre el tema detectado. | Etapa 3 |

## 3.7 INTEGRACIÓN CON REDES SOCIALES (MÉTRICAS)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F26.1** | Conexión OAuth con plataformas | Instagram, TikTok, YouTube, LinkedIn. | Etapa 3 |
| **F26.2** | Obtención de métricas de rendimiento | Vistas, retención, likes, comentarios, shares. | Etapa 3 |
| **F26.3** | Correlación con metadatos de producción | Relaciona cómo se grabó (tono, ritmo) con cómo funcionó. | Etapa 3 |
| **F26.4** | Feedback al generador de guiones | "Tus videos con tono humorístico tienen 20% más retención." | Etapa 3 |
| **F26.5** | Publicación directa desde la app | Subir video con descripción generada automáticamente. | Etapa 3 |

## 3.8 ARQUITECTURA DE PLUGINS (ALPHA)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F27.1** | Interfaces públicas para plugins | IIdeaSource, IScriptProcessor, IPostProcessor, IAnalyticsProvider. | Etapa 3 |
| **F27.2** | Documentación para desarrolladores | API docs, ejemplos de integración. | Etapa 3 |
| **F27.3** | Marketplace de plugins (alpha) | Listado de plugins disponibles para usuarios. | Etapa 3 |
| **F27.4** | Sistema de créditos para plugins de pago | Microtransacciones para usar plugins premium. | Etapa 3 |

## 3.9 MODO MARATÓN (COMMITMENT CONTRACT)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F28.1** | Activación de reto | Usuario selecciona duración: 7, 30, 60 días. | Etapa 3 |
| **F28.2** | Objetivo diario | 1 video por día (configurable). | Etapa 3 |
| **F28.3** | Sistema de puntos | 10 puntos base por video. Multiplicador por consistencia (x1.2 a x2). | Etapa 3 |
| **F28.4** | Penalización por fallo | -50 puntos por día no grabado. | Etapa 3 |
| **F28.5** | Bonus por completar reto | +500 puntos al alcanzar el objetivo. | Etapa 3 |
| **F28.6** | Tablas de clasificación opcionales | Comparación con otros usuarios (opt-in). | Etapa 3 |

---

# PARTE 4: FUNCIONALIDADES DE PLATAFORMA (ETAPA 4)

## 4.1 AGENTES AUTÓNOMOS (MCP)

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F29.1** | Comandos de alto nivel | "Toma las 5 ideas de esta fuente, genera guiones y prepáralos para grabar." | Etapa 4 |
| **F29.2** | Orquestación automática | Agente ejecuta el pipeline completo sin intervención. | Etapa 4 |
| **F29.3** | Programación de tareas | "Genera versión en inglés del proyecto X y publícala en YouTube mañana." | Etapa 4 |
| **F29.4** | Integración MCP | Conexión con asistentes de IA externos (Claude, GPT). | Etapa 4 |

## 4.2 COLABORACIÓN EN EQUIPO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F30.1** | Proyectos compartidos | Invitar a miembros del equipo a un proyecto. | Etapa 4 |
| **F30.2** | Roles y permisos | Editor, revisor, talento, administrador. | Etapa 4 |
| **F30.3** | Flujos de aprobación | Guionista → Editor → Talento → Publicación. | Etapa 4 |
| **F30.4** | Comentarios en fragmentos | Feedback sobre fragmentos específicos. | Etapa 4 |
| **F30.5** | Versionado de proyectos | Historial de cambios y versiones anteriores. | Etapa 4 |

## 4.3 BIBLIOTECA DE ACTIVOS CORPORATIVA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F31.1** | Repositorio centralizado | Todos los videos de la organización en un solo lugar. | Etapa 4 |
| **F31.2** | Búsqueda semántica | Por contenido hablado, no solo por título. | Etapa 4 |
| **F31.3** | Reutilización de fragmentos | Usar clips de videos anteriores en nuevos proyectos. | Etapa 4 |
| **F31.4** | Análisis de rendimiento agregado | Métricas consolidadas por equipo, campaña, tema. | Etapa 4 |

## 4.4 ANALYTICS PREDICTIVO

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F32.1** | Predicción de rendimiento | "Este video tiene 85% de probabilidad de superar 10k vistas." | Etapa 4 |
| **F32.2** | Modelo entrenado con datos históricos | Basado en rendimiento pasado de videos similares. | Etapa 4 |
| **F32.3** | Recomendaciones de optimización | "Prueba un gancho más polémico para mejorar retención." | Etapa 4 |

## 4.5 GENERACIÓN DE VARIANTES A/B

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F33.1** | Creación de múltiples versiones | Diferentes ganchos, tonos, CTAs para el mismo guion base. | Etapa 4 |
| **F33.2** | Publicación para testeo | Programa las variantes en diferentes momentos/plataformas. | Etapa 4 |
| **F33.3** | Análisis de resultados | Comparativa de rendimiento entre variantes. | Etapa 4 |
| **F33.4** | Selección automática de ganador | Sugiere la variante con mejor rendimiento. | Etapa 4 |

## 4.6 API PÚBLICA

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F34.1** | Endpoints REST | Acceso programático a todas las funcionalidades core. | Etapa 4 |
| **F34.2** | Webhooks | Notificaciones cuando se completan videos o procesamientos. | Etapa 4 |
| **F34.3** | SDKs | Librerías para Python, JavaScript, etc. | Etapa 4 |
| **F34.4** | Documentación interactiva | Swagger/OpenAPI con ejemplos. | Etapa 4 |

## 4.7 COMUNIDAD Y MERCADO DE TALENTOS

| ID | Funcionalidad | Descripción | Etapa |
|----|---------------|-------------|-------|
| **F35.1** | Perfiles públicos de creadores | Portafolio con videos y métricas de calidad. | Etapa 4 |
| **F35.2** | Búsqueda de talento | Empresas pueden encontrar