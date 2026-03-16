## CATÁLOGO COMPLETO DE FLUJOS DE "CÁMARA ATÓMICA"
### Hoja de Ruta desde el MVP hasta la Plataforma Definitiva

Este documento describe **exclusivamente los flujos de usuario** del producto, organizados por etapas de madurez y categorías funcionales. Cada flujo incluye su propósito, detalle paso a paso, estados del sistema, transiciones y dependencias.

---

# PARTE 1: FLUJOS FUNDACIONALES (MVP - ETAPA 1)

---

## FLUJO F1: Onboarding Inicial "The Mirror Step"

### Propósito
Capturar la identidad narrativa del usuario para personalizar toda la experiencia posterior con mínima fricción.

### Trigger
Primera apertura de la aplicación después de la instalación.

### Actores
- Usuario nuevo
- Sistema de onboarding

### Precondiciones
- App instalada
- Primera ejecución
- Sin perfil de usuario existente

### Postcondiciones
- Perfil de usuario creado (`user_profile.json`)
- UI personalizada según perfil seleccionado
- Usuario listo para su primer video

---

### Secuencia detallada

**PASO 1: Pantalla de bienvenida con video coach**
- Se reproduce un video corto (3-5 segundos) de un coach virtual
- El coach dice: *"Hola. Para configurar tu estudio personal, dime: ¿Cuál es tu mayor obstáculo hoy?"*
- El video entra en loop suave hasta interacción del usuario

**PASO 2: Selección de identidad mediante tarjetas visuales**
- Aparecen 3 tarjetas con micro-videos en loop representando cada perfil
- **Tarjeta A (Líder):** "Tengo poco tiempo. Necesito autoridad." (Icono: 👔)
- **Tarjeta B (Creador):** "Quiero conectar y vencer el miedo." (Icono: ✨)
- **Tarjeta C (Vendedor):** "Necesito vender y ser claro." (Icono: 🎯)
- Usuario toca una tarjeta (selección única)
- Feedback visual: la tarjeta se expande, el micro-video se amplía
- Coach responde con video personalizado: *"Entendido. Modo [perfil] activado."*

**PASO 3: Configuración inicial invisible**
- Sistema asigna valores por defecto según perfil:
  - **Líder:** velocidad normal (150 wpm), tono profesional, framework educativo
  - **Creador:** velocidad rápida (165 wpm), tono energético, framework storytelling
  - **Vendedor:** velocidad media (145 wpm), tono persuasivo, framework ventas (PAS)
- Se crea `user_profile.json` con identidad base
- Transición automática al Laboratorio de Ideas (F3)

---

### Estados del sistema durante el flujo
| Paso | Estado |
|------|--------|
| 1 | ONBOARDING_WELCOME |
| 2 | ONBOARDING_SELECTION |
| 3 | ONBOARDING_PROCESSING |

### Datos generados
```json
{
  "user_id": "uuid",
  "identity": { "role": "leader|creator|seller", "level": "novice" },
  "preferences": {
    "default_tone": "professional|energetic|persuasive",
    "default_framework": "educational|story|sales",
    "teleprompter_speed": 150|165|145
  }
}
```

### Flujos alternativos
- **FA1.1:** Usuario no selecciona ninguna tarjeta → después de 10s, coach ofrece ayuda
- **FA1.2:** Usuario quiere cambiar perfil después → opción en Configuración (F17)

### Dependencias
- Ninguna (es el primer flujo)

---

## FLUJO F2: Perfilado Progresivo (Calibración Pasiva)

### Propósito
Completar el perfil del usuario infiriendo parámetros de su comportamiento real sin preguntar explícitamente.

### Trigger
- Primer video grabado y completado
- Cada 10 videos (recalibración)

### Actores
- Usuario
- Analizador de voz/audio
- Perfil de usuario

### Precondiciones
- Usuario ha completado onboarding (F1)
- Usuario ha grabado al menos un video completo

### Postcondiciones
- `user_profile.json` actualizado con parámetros inferidos
- Preferencias ajustadas automáticamente

---

### Secuencia detallada

**PASO 1: Detección de oportunidad**
- Usuario completa su primer video
- Sistema detecta que es el primer video (`videos_created === 1`)
- Trigger interno: "calibración necesaria"

**PASO 2: Análisis de audio en segundo plano (no bloqueante)**
- Sistema extrae pista de audio del video completo
- Ejecuta análisis:
  - Velocidad promedio (WPM)
  - Variación de tono (energía vocal)
  - Complejidad léxica (vocabulario)
  - Tono predominante (clasificación emocional)
- Resultados se almacenan temporalmente

**PASO 3: Inferencia de parámetros**
- **Velocidad detectada:**
  - < 130 wpm → "lento" → ajustar preferencia a 130
  - 130-160 wpm → "normal" → mantener 150
  - > 160 wpm → "rápido" → ajustar preferencia a 165
- **Tono detectado:** análisis de prosodia → "profesional|casual|energético"
- **Vocabulario:** densidad de términos técnicos → "beginner|pro|expert"

**PASO 4: Actualización silenciosa del perfil**
- Sistema actualiza `user_profile.json` con nuevos valores
- No se notifica al usuario (para no abrumar)
- Queda registrado en historial: "calibración automática"

**PASO 5: Confirmación opcional (próxima sesión)**
- En la siguiente apertura, mensaje sutil:
  *"Ajustamos tu teleprompter a tu ritmo natural (150 wpm). ¿Prefieres otro?"*
- Opciones: [Más lento] [Perfecto] [Más rápido]
- Si usuario elige, se ajusta manualmente

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 2 | BACKGROUND_ANALYSIS |
| 3-4 | PROFILE_UPDATING |

### Datos actualizados
```json
{
  "preferences": {
    "teleprompter_speed": 150,
    "default_tone": "professional",
    "preferred_audience": "beginner"
  }
}
```

### Flujos alternativos
- **FA2.1:** Usuario desactiva calibración automática en ajustes
- **FA2.2:** Análisis inconcluso por mala calidad de audio → reintentar en próximo video

### Dependencias
- F1 completado
- Flujo de grabación (F6-F10) completado al menos una vez

---

## FLUJO F3: Laboratorio de Ideas (Entrada de Concepto)

### Propósito
Capturar la idea del usuario y prepararla para la generación de guion.

### Trigger
- Usuario toca "Nuevo video" desde dashboard
- Usuario toca "Generar guion" desde cualquier lugar

### Actores
- Usuario
- Laboratorio de ideas

### Precondiciones
- Usuario ha completado onboarding (F1)
- App en estado IDLE o PROJECT_VIEW

### Postcondiciones
- `InputSchema.json` creado con la idea del usuario
- Sistema listo para generar guion (F4)

---

### Secuencia detallada

**PASO 1: Acceso al Laboratorio**
- Usuario toca botón flotante "+" o "Nueva idea"
- Transición a pantalla "Laboratorio de Ideas"
- Animación de entrada suave

**PASO 2: Área de entrada de idea**
- Campo de texto grande con placeholder animado rotativo:
  - *"¿De qué quieres hablar hoy?"*
  - *"Ej: Cómo vender más en redes"*
  - *"Ej: 3 consejos para..."*
- Alternativa: botón de micrófono para entrada por voz
- Contador de caracteres (no limitante, solo informativo)

**PASO 3: Detección inteligente de entrada**
- Si usuario pega URL: opción "Extraer contenido del enlace"
- Si pega texto largo (>200 palabras): modo "Refinar guion existente"
- Si entrada por voz: transcripción en tiempo real con feedback visual

**PASO 4: Selección de intención (preseleccionada)**
- Tres botones tipo "chip" debajo del campo:
  - 🎯 "Vender" (preseleccionado si perfil = seller)
  - 🧠 "Educar" (preseleccionado si perfil = leader)
  - ✨ "Conectar" (preseleccionado si perfil = creator)
- Usuario puede cambiar la selección (única)
- Al cambiar, el placeholder se actualiza con ejemplos del nuevo tipo

**PASO 5: Panel de opciones avanzadas (colapsado)**
- Texto pequeño "🛠️ Ajustes de estudio" debajo de chips
- Al expandir, muestra:
  - Framework específico (si usuario quiere forzar)
  - Tono (Zen, Amigo, Hype)
  - Velocidad de habla (Lento/Normal/Rápido)
  - Nivel de audiencia (Principiante/Pro/Experto)
- Valores por defecto vienen del perfil (F1 + F2)

**PASO 6: Botón de acción principal**
- Botón grande "✨ Generar guion" en parte inferior (Sticky CTA)
- Estado: deshabilitado si campo vacío
- Al tocar, inicia flujo F4
- Feedback inmediato: botón cambia a "Generando..." con spinner

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-4 | IDEATION_INPUT |
| 5 | IDEATION_ADVANCED (si expande) |
| 6 | IDEATION_GENERATING |

### Datos generados (`InputSchema.json`)
```json
{
  "idea_id": "uuid",
  "raw_topic": "texto ingresado",
  "source_type": "manual|voice|url",
  "intent": "sell|educate|connect",
  "advanced_options": {
    "framework": "auto|pas|story|list",
    "tone": "professional|casual|energetic",
    "speed": 150,
    "audience": "beginner"
  }
}
```

### Flujos alternativos
- **FA3.1:** Entrada por voz → sistema transcribe y llena campo
- **FA3.2:** Pegar URL → opción de extraer contenido
- **FA3.3:** Texto largo detectado → modo refinar guion

### Dependencias
- F1 (perfil de usuario) para valores por defecto

---

## FLUJO F4: Generación de Guion con IA

### Propósito
Transformar la idea del usuario en un guion estructurado y fragmentado (`ScriptBundle`).

### Trigger
- Usuario toca "Generar guion" en F3
- Usuario toca "Regenerar" desde edición de guion (F5)

### Actores
- Usuario
- Motor de IA (LLM)
- Generador de micro-fragmentos

### Precondiciones
- `InputSchema.json` existe (de F3)
- Conexión a internet disponible

### Postcondiciones
- `ScriptBundle.json` creado
- Usuario en pantalla de edición de guion (F5)

---

### Secuencia detallada

**PASO 1: Construcción del prompt**
- Sistema toma `InputSchema.json`
- Construye prompt combinando:
  - Idea del usuario
  - Intención (sell|educate|connect) → determina framework base
  - Tono seleccionado (del perfil u opciones)
  - Audiencia objetivo
  - Instrucciones de formato (debe generar JSON estructurado)
- Prompt listo para enviar a LLM

**PASO 2: Pantalla de espera con feedback**
- Pantalla muestra: "🧠 Creando tu guion..." con animación
- Tiempo estimado: 2-5 segundos
- Animación de "ondas cerebrales" o "escribiendo"
- Opción de cancelar visible

**PASO 3: Llamada a IA y recepción**
- Sistema envía prompt al LLM
- Recibe respuesta en formato JSON
- Valida estructura contra esquema `ScriptBundle`
- Si válido, continúa; si no, reintenta hasta 2 veces

**PASO 4: Generación de micro-fragmentos (chunking)**
- A partir del texto completo, se aplica chunking semántico:
  - Dividir por oraciones (puntos y seguido)
  - Si oración > 12 palabras, dividir por comas o conectores
  - Cada fragmento: 2-4 segundos estimados
  - Máximo 10-12 palabras por fragmento
- Se asigna orden secuencial
- Se estima duración basada en velocidad del perfil
- Se etiqueta intención de cada fragmento (hook, desarrollo, cierre, CTA)

**PASO 5: Generación de CTA**
- Basado en intención y perfil, IA genera frase de cierre
- Tipos posibles:
  - *"Comenta [palabra] para más info"*
  - *"Sígueme para más consejos"*
  - *"Link en bio para el recurso"*
  - *"Comparte con alguien que lo necesite"*
- Se añade como último fragmento

**PASO 6: Creación de ScriptBundle**
- Se ensambla objeto JSON completo
- Se guarda en carpeta del proyecto temporal
- Se registra en historial del usuario
- Transición a pantalla de edición (F5)

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-2 | SCRIPT_GENERATING |
| 3-5 | SCRIPT_PROCESSING |
| 6 | SCRIPT_COMPLETE |

### Datos generados (`ScriptBundle.json` - estructura)
```json
{
  "script_id": "uuid",
  "total_chunks": 8,
  "chunks": [
    {
      "order": 1,
      "text": "¿Sabías que la mayoría abandona sus videos por ansiedad?",
      "duration_sec": 3.2,
      "intent": "hook",
      "tone": "curious"
    }
  ],
  "cta": { "type": "comment", "value": "VIDEO" }
}
```

### Flujos alternativos
- **FA4.1:** Regenerar guion → misma idea con temperatura más alta
- **FA4.2:** Sin conexión → ofrecer plantillas offline
- **FA4.3:** Framework específico forzado desde opciones avanzadas

### Flujos de error
- **FE4.1:** IA no responde → reintento con backoff
- **FE4.2:** Respuesta malformada → reintentar con prompt más explícito
- **FE4.3:** Guion demasiado largo (>20 fragmentos) → truncar y notificar

### Dependencias
- F3 completado
- Perfil de usuario para parámetros base

---

## FLUJO F5: Edición y Aprobación de Guion

### Propósito
Permitir al usuario revisar, editar y aprobar el guion generado antes de grabarlo.

### Trigger
- Finalización exitosa de F4
- Usuario selecciona "Editar guion" desde proyecto existente

### Actores
- Usuario
- Editor de guion

### Precondiciones
- `ScriptBundle.json` existe (de F4 o proyecto previo)

### Postcondiciones
- Guion final aprobado (original o modificado)
- Sistema listo para iniciar grabación (F6)

---

### Secuencia detallada

**PASO 1: Visualización del guion completo**
- Pantalla dividida en dos áreas:
  - **Superior:** vista compacta de todos los fragmentos (scroll vertical)
  - **Inferior:** editor del fragmento seleccionado
- Fragmentos numerados: "1/8", "2/8", etc.
- Cada fragmento muestra:
  - Texto
  - Duración estimada (icono de reloj)
  - Intención (icono: 🎯 gancho, 💡 desarrollo, 🛑 cierre, 📢 CTA)
- Fragmento actualmente seleccionado resaltado

**PASO 2: Edición de fragmento individual**
- Usuario toca un fragmento para editarlo
- Se abre editor de texto en línea
- Límite visible: contador de palabras (máx 12)
- Sugerencias automáticas:
  - Si supera 12 palabras: advertencia "Muy largo para una toma"
  - Si detecta muletillas escritas: sugerencia de eliminación
- Al terminar, toca fuera o botón "Listo" para guardar

**PASO 3: Reordenamiento de fragmentos (opcional)**
- Usuario mantiene presionado un fragmento
- Entra en modo reordenamiento
- Arrastra fragmentos para cambiar orden
- Feedback visual de posición (sombra, guías)
- Al soltar, se actualiza numeración automáticamente

**PASO 4: Eliminación de fragmentos (opcional)**
- Usuario desliza fragmento a la izquierda
- Aparece opción "Eliminar"
- Confirmación: "¿Eliminar este fragmento?"
- Si confirma, se renumera el resto automáticamente

**PASO 5: Inserción de nuevo fragmento (opcional)**
- Botón "+" entre fragmentos
- Al tocarlo, se abre editor de texto vacío
- Usuario escribe nuevo contenido
- Se inserta en esa posición
- Se renumera todo

**PASO 6: Ajuste de tono global (opcional)**
- Botón "🎭 Ajustar tono" en parte superior
- Abre selector rápido: [Zen] [Amigo] [Hype]
- Al seleccionar, IA regenera el guion manteniendo estructura pero ajustando vocabulario
- (Requiere reconexión a IA)

**PASO 7: Validación y aprobación final**
- Botón Sticky CTA: "✅ Listo para grabar"
- Sistema valida:
  - Todos los fragmentos tienen texto
  - Ningún fragmento supera 12 palabras
  - Hay al menos 3 fragmentos (mínimo para video)
- Si válido, se guarda `ScriptBundle` actualizado
- Transición a preparación de grabación (F6)

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-5 | SCRIPT_EDITING |
| 6 | SCRIPT_REGEN_REQUESTED |
| 7 | SCRIPT_VALIDATING |

### Reglas de negocio
- Cada fragmento: mínimo 2 palabras, máximo 12 palabras
- Duración estimada se recalcula automáticamente al editar texto
- El CTA (último fragmento) no puede eliminarse sin añadir otro
- Video mínimo: 3 fragmentos (10-15 segundos)
- Video máximo: 20 fragmentos (60-80 segundos)

### Flujos alternativos
- **FA5.1:** Regenerar con IA → botón "Probar otro enfoque"
- **FA5.2:** Guardar como borrador → proyecto en estado "draft"
- **FA5.3:** Cancelar edición → confirmar descarte de cambios

### Dependencias
- F4 completado (guion generado)
- Perfil de usuario para validación de tono

---

## FLUJO F6: Preparación para Grabación

### Propósito
Preparar al usuario para la sesión de grabación, mostrando el primer fragmento y activando sistemas de control por voz.

### Trigger
- Usuario toca "Listo para grabar" en F5
- Usuario retoma un proyecto en estado "preparado"

### Actores
- Usuario
- Sistema de grabación
- Motor de reconocimiento de voz

### Precondiciones
- `ScriptBundle.json` aprobado existe
- Permisos de cámara y micrófono concedidos

### Postcondiciones
- Sistema en estado RECORDING_PREP
- Primer fragmento visible en teleprompter
- Micrófono activo escuchando comando "grabar"

---

### Secuencia detallada

**PASO 1: Acceso a sala de grabación**
- Transición a pantalla completa (cámara ocupa todo)
- Breve animación de entrada (1 segundo)
- Texto en pantalla: "Preparando tu estudio..."
- Desaparece, dejando vista de cámara frontal

**PASO 2: Configuración de interfaz**
- Elementos que aparecen:
  - **Header superior:** "FRAGMENTO 1 / 8" (progreso)
  - **Botón cerrar (✕)** en esquina superior izquierda
  - **Botón rotar cámara** en esquina superior derecha
  - **Teleprompter** con texto del fragmento 1 (tercio superior)
  - **Sticky Bottom CTA** mostrando "GRABAR" (rojo)
  - **Indicador** "🎤 ESCUCHANDO..." en parte inferior
- Todos los elementos tienen fondo semitransparente (glassmorphism)

**PASO 3: Verificación de sistemas**
- Sistema verifica:
  - Cámara funcionando (muestra feed en tiempo real)
  - Micrófono activo (indicador de nivel de audio)
  - Reconocimiento de voz cargado
- Si todo OK, indicador "🎤 ESCUCHANDO..." se vuelve verde
- Mensaje breve: "Di 'Grabar' cuando estés listo"

**PASO 4: Modo práctica (opcional)**
- Usuario puede leer el fragmento en voz alta para practicar
- Sistema escucha pero no graba
- El texto no avanza (es solo práctica)
- No hay penalización por errores
- Al decir "Grabar", termina modo práctica

**PASO 5: Espera activa**
- Sistema permanece en estado RECORDING_PREP
- Escucha continua del comando "grabar" (o "acción")
- Sticky CTA también puede iniciar grabación (táctil)
- Después de 30 segundos sin actividad: "¿Necesitas ayuda?"

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1 | TRANSITION_TO_RECORDING |
| 2-4 | RECORDING_PREP |
| 5 | LISTENING_FOR_COMMAND |

### Datos de sesión (inicializados)
```json
{
  "session_id": "uuid",
  "project_id": "uuid",
  "start_time": "timestamp",
  "current_chunk_index": 0,
  "recorded_clips": []
}
```

### Flujos alternativos
- **FA6.1:** Primer video del usuario → mostrar tooltip explicativo
- **FA6.2:** Usuario dice "menú" → abre panel de control (F7)
- **FA6.3:** Usuario toca ajustes → panel rápido de configuración

### Flujos de error
- **FE6.1:** Error de cámara/micrófono → mensaje y opción de reintentar permisos
- **FE6.2:** Reconocimiento de voz no disponible → desactivar comandos, botón más prominente

### Dependencias
- F5 completado (guion aprobado)
- Permisos de hardware concedidos

---

## FLUJO F7: Menú de Control durante Grabación

### Propósito
Proporcionar acceso rápido a funciones de control y configuración sin interrumpir el flujo de grabación.

### Trigger
- Usuario dice "menú" durante RECORDING_PREP, RECORDING o REVIEW
- Usuario desliza hacia arriba desde borde inferior
- Usuario toca botón de menú (si visible)

### Actores
- Usuario
- Panel de menú

### Precondiciones
- Sistema en estado de grabación (cualquier estado excepto STITCHING)
- Sesión activa

### Postcondiciones
- Panel de menú visible
- Grabación pausada (si estaba activa)
- Usuario puede realizar acciones de control

---

### Secuencia detallada

**PASO 1: Activación del menú**
- Usuario dice "menú" (o gesto táctil)
- Feedback inmediato: breve sonido de confirmación
- Grabación actual se pausa automáticamente (si estaba activa)
- Fondo de cámara se desenfoca sutilmente (blur)
- Panel inferior se desliza hacia arriba (animación 300ms)

**PASO 2: Visualización del panel principal**
- Panel ocupa 45% inferior de la pantalla
- Fondo: blur oscuro, bordes redondeados
- Organización: grid de 3 columnas x 2 filas
- Cada botón: icono grande + texto + comando de voz asociado

**Opciones del menú principal:**
| Posición | Icono | Comando | Acción |
|----------|-------|---------|--------|
| 1 | ⚙️ | "Ajustes" | Abre subpanel de configuración |
| 2 | 🔁 | "Cámara" | Alterna frontal/trasera |
| 3 | ⏯️ | "Pausar" | Pausa/reanuda sesión |
| 4 | 🚪 | "Salir" | Guarda progreso y vuelve al dashboard |
| 5 | 🗑️ | "Repetir" | Reinicia fragmento actual |
| 6 | ⬇️ | "Cerrar" | Oculta menú |

**PASO 3: Interacción por voz en menú**
- Sistema sigue escuchando dentro del menú
- Cada opción tiene comando de voz asociado
- Usuario dice "Ajustes" → abre subpanel
- Usuario dice "Cerrar" → oculta menú
- Feedback visual: botón se ilumina al detectar comando

**PASO 4: Subpanel de ajustes rápidos**
- Al seleccionar "Ajustes", panel se transforma
- Controles visibles:
  - **Velocidad:** slider 🐢 [---●---] 🐇 (ajusta scroll del teleprompter)
  - **Tamaño texto:** slider A- [---●---] A+
  - **Brillo:** slider ☀️ [---●---] ☀️+ (exposición de cámara)
- Botón "Volver" al menú principal
- Los cambios se aplican en tiempo real (previsualización)
- Al volver, ajustes quedan guardados para la sesión

**PASO 5: Cierre del menú**
- Usuario dice "Cerrar" o toca botón ⬇️
- Panel se desliza hacia abajo (animación 300ms)
- Desenfoque de fondo desaparece
- Sistema retoma estado anterior (preparación o grabación)
- Mensaje breve: "Sesión reanudada. Di 'Grabar' para continuar."

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1 | MENU_ACTIVATING |
| 2-3 | MENU_MAIN |
| 4 | MENU_SETTINGS |
| 5 | MENU_CLOSING |

### Flujos alternativos
- **FA7.1:** Usuario selecciona "Salir" → confirmación y guardado
- **FA7.2:** Usuario selecciona "Repetir" → descarta clip actual y reinicia
- **FA7.3:** Inactividad en menú (15s) → cierre automático

### Reglas de negocio
- El menú no debe aparecer durante la cuenta atrás (3,2,1)
- Los ajustes afectan solo a la sesión actual (no al perfil global)
- "Pausar" congela grabación pero mantiene sesión abierta

### Dependencias
- Sesión de grabación activa (F6)

---

## FLUJO F8: Grabación de Fragmento Individual

### Propósito
Grabar un micro-fragmento del guion con control por voz y feedback visual.

### Trigger
- Usuario dice "grabar" (o toca Sticky CTA) en estado RECORDING_PREP
- Sistema inicia cuenta atrás

### Actores
- Usuario
- Sistema de grabación
- Motor de detección de voz (VAD)

### Precondiciones
- Sistema en estado RECORDING_PREP
- Fragmento actual visible en teleprompter
- Micrófono activo

### Postcondiciones
- Clip de audio/video guardado para fragmento actual
- Sistema en estado REVIEW (reproducción del clip)

---

### Secuencia detallada

**PASO 1: Inicio por comando de voz**
- Usuario dice "grabar"
- Feedback inmediato: indicador de micrófono cambia a "✅"
- Sistema bloquea nuevos comandos de voz temporalmente
- Transición a cuenta atrás

**PASO 2: Cuenta atrás visual**
- Números grandes 3, 2, 1 en centro de pantalla
- No cubren el texto del teleprompter (posición superior)
- Cada número con breve vibración háptica
- Al llegar a 0, flash de borde blanco (señal de inicio)
- Sonido suave de inicio (opcional, no se graba)

**PASO 3: Grabación activa**
- Borde de pantalla cambia a rojo (tally light digital)
- Temporizador oculto (para no estresar)
- Texto del teleprompter permanece visible
- Sistema escucha activamente para detección de fin de frase (VAD)
- Usuario lee/habla el texto
- Grabación continúa hasta detección de fin o timeout

**PASO 4: Detección automática de fin (VAD)**
- Motor VAD detecta silencio > 1.5 segundos
- Sistema espera 0.3 seg adicional (buffer para no cortar palabras)
- Si sigue silencio, detiene grabación automáticamente
- Borde rojo desaparece
- Breve sonido de fin (opcional)
- Clip guardado temporalmente con timestamp exacto

**PASO 5: Timeout de seguridad**
- Si después de duración estimada + 3 segundos no hay silencio
- Sistema detiene grabación automáticamente
- Mensaje: "Grabación detenida por tiempo máximo"
- Clip guardado (lo que se haya grabado)

**PASO 6: Transición a revisión**
- Clip grabado se carga en reproductor
- Sistema pasa a estado REVIEW
- Sticky CTA cambia a [Repetir] [Siguiente]
- (Continúa en F9)

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1 | RECORDING_REQUESTED |
| 2 | COUNTDOWN |
| 3-5 | RECORDING_ACTIVE |
| 6 | REVIEW |

### Datos generados por clip
```json
{
  "chunk_index": 3,
  "clip_path": "clips/chunk_3_take_1.mp4",
  "duration": 4.2,
  "take_number": 1,
  "end_method": "vad|timeout|manual"
}
```

### Flujos alternativos
- **FA8.1:** Inicio por botón táctil (respaldo)
- **FA8.2:** Detención manual durante grabación (comando "detener")
- **FA8.3:** Pérdida de foco (llamada/notificación) → guarda clip hasta ese punto

### Flujos de error
- **FE8.1:** No se detectó voz en 5 segundos → mensaje y opción de repetir
- **FE8.2:** Error al guardar clip → reintentar

### Reglas de negocio
- Duración máxima por fragmento: 10 segundos (timeout)
- Múltiples intentos se numeran como takes (take_1, take_2)
- El clip anterior se descarta al grabar nuevo take

### Dependencias
- Fragmento actual definido en sesión
- Permisos de cámara/micrófono activos

---

## FLUJO F9: Revisión y Decisión de Fragmento

### Propósito
Permitir al usuario revisar el clip recién grabado y decidir si lo acepta o lo repite.

### Trigger
- Finalización de grabación de fragmento (F8)

### Actores
- Usuario
- Reproductor de video

### Precondiciones
- Clip grabado existe para fragmento actual
- Sistema en estado REVIEW

### Postcondiciones
- Si acepta: clip guardado definitivamente, avanza al siguiente fragmento
- Si repite: clip descartado, vuelve a RECORDING_PREP para mismo fragmento

---

### Secuencia detallada

**PASO 1: Reproducción automática**
- Clip recién grabado comienza a reproducirse automáticamente
- Reproducción en bucle (loop) hasta decisión del usuario
- Audio: por defecto silenciado (para no interrumpir flujo mental)
- Opción: tocar para activar audio
- Indicador visible: "Revisando fragmento 3/8"

**PASO 2: Opciones de decisión**
- Dos botones grandes flotantes (no ocultan el video):
  - **Izquierda:** 🗑️ "Repetir" (rojo)
  - **Derecha:** ✅ "Siguiente" (verde)
- Sticky CTA también muestra las mismas opciones
- Comandos de voz activos: "repetir", "siguiente"

**PASO 3: Aprobación pasiva (clave UX)**
- Barra de progreso circular alrededor de botón "Siguiente"
- Barra se llena en 3 segundos
- Si usuario no dice nada ni toca nada:
  - Barra se completa
  - Clip se acepta automáticamente
  - Breve animación de "✅ Aceptado"
  - Transición al siguiente fragmento
- Si usuario dice "repetir" antes de completarse, se cancela

**PASO 4: Decisión explícita de aceptar**
- Usuario dice "siguiente" (o toca botón)
- Feedback: botón se ilumina, sonido de confirmación
- Clip se marca como aceptado
- Se añade a la lista de clips de la sesión
- Sistema avanza al siguiente fragmento

**PASO 5: Decisión de repetir**
- Usuario dice "repetir" (o toca botón)
- Feedback: botón se ilumina, sonido de descarte
- Clip actual se descarta (eliminación temporal)
- Contador de takes del fragmento aumenta
- Sistema vuelve a RECORDING_PREP para mismo fragmento

**PASO 6: Transición al siguiente fragmento**
- Si había más fragmentos:
  - Animación: fragmento actual se desliza hacia arriba
  - Nuevo fragmento aparece desde abajo
  - Número de fragmento se actualiza (ej. "4/8")
  - Sistema vuelve a RECORDING_PREP
- Si era último fragmento:
  - Mensaje: "¡Fragmentos completados!"
  - Botón: "Procesar video"
  - Transición a F10

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-2 | REVIEW |
| 3 | REVIEW_AUTO_APPROVING |
| 4 | REVIEW_APPROVED |
| 5 | REVIEW_REJECTED |
| 6 | TRANSITION_NEXT_CHUNK |

### Datos actualizados
```json
{
  "recorded_clips": [{
    "chunk_index": 3,
    "status": "approved",
    "approval_method": "voice|tap|passive"
  }],
  "current_chunk_index": 4
}
```

### Flujos alternativos
- **FA9.1:** Usuario activa audio del clip (toca altavoz)
- **FA9.2:** Usuario expande a pantalla completa

### Reglas de negocio
- Aprobación pasiva: 3 segundos sin acción = aceptar
- El clip no se elimina físicamente hasta que se acepta otro take

### Dependencias
- Clip grabado existe (F8)
- ScriptBundle para saber si hay más fragmentos

---

## FLUJO F10: Auto-Stitch (Unión Automática)

### Propósito
Unir todos los clips aceptados en un video final continuo, aplicando correcciones básicas.

### Trigger
- Último fragmento aprobado en F9
- Usuario selecciona "Procesar video" manualmente

### Actores
- Motor de procesamiento de video
- Usuario (en espera)

### Precondiciones
- Todos los fragmentos tienen clips aceptados
- Sesión de grabación completada

### Postcondiciones
- Video final generado (`final.mp4`)
- `AssetManifest.json` actualizado
- Usuario en pantalla de previsualización (F11)

---

### Secuencia detallada

**PASO 1: Inicio de procesamiento**
- Mensaje en pantalla: "Preparando tu video..."
- Animación de progreso (spinner o barra)
- Tiempo estimado mostrado: "Unos segundos..."
- Opción de "Procesar en segundo plano" (notificación después)

**PASO 2: Recopilación de clips**
- Sistema recorre todos los clips aceptados en orden
- Verifica integridad de cada archivo
- Registra duración y metadatos de cada uno
- Crea lista de procesamiento

**PASO 3: Normalización de audio (básica)**
- Analiza niveles de volumen de cada clip
- Calcula volumen promedio
- Ajusta ganancia para nivel similar entre clips
- Aplica compresión suave
- Genera pista de audio normalizada

**PASO 4: Normalización de iluminación (básica)**
- Analiza luminancia promedio de cada clip
- Si hay diferencias significativas (>20%):
  - Calcula factor de corrección por clip
  - Aplica ajuste de brillo/contraste individual
- Si no, mantiene original

**PASO 5: Unión de clips**
- Concatena clips en orden secuencial
- Aplica crossfade de audio de 0.2s entre clips (transición suave)
- Elimina silencios excesivos entre clips
- Asegura continuidad de tiempo
- Genera archivo de video temporal

**PASO 6: Exportación final**
- Comprime video a formato optimizado (H.264)
- Resolución: mantiene la original
- Bitrate: adaptativo según calidad
- Guarda como `final.mp4` en carpeta del proyecto
- Actualiza `AssetManifest.json` con ruta del video final

**PASO 7: Notificación y transición**
- Mensaje: "¡Video listo!"
- Vibración de éxito
- Botón: "Ver video"
- Transición a F11 (Previsualización)

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1 | STITCHING_STARTING |
| 2 | STITCHING_COLLECTING |
| 3 | STITCHING_AUDIO |
| 4 | STITCHING_VIDEO |
| 5 | STITCHING_MERGING |
| 6 | STITCHING_EXPORTING |
| 7 | STITCHING_COMPLETE |

### Datos generados (`AssetManifest.json`)
```json
{
  "project_id": "uuid",
  "final_video": "final.mp4",
  "total_duration": 24.5,
  "processing_metadata": {
    "audio_normalized": true,
    "light_normalized": true
  }
}
```

### Flujos alternativos
- **FA10.1:** Procesamiento en segundo plano → notificación push cuando listo
- **FA10.2:** Procesamiento con efectos avanzados (si hay plugins)
- **FA10.3:** Clip corrupto → opción de regrabar o continuar sin él

### Flujos de error
- **FE10.1:** Error general de procesamiento → reintentar o guardar clips por separado
- **FE10.2:** Espacio insuficiente → mensaje y opción de liberar espacio

### Reglas de negocio
- Tiempo máximo en primer plano: 30 segundos (si excede, ofrecer background)
- La calidad de exportación debe ser ajustable (baja/media/alta)

### Dependencias
- Todos los clips aceptados (F9 completado)
- Espacio de almacenamiento suficiente

---

## FLUJO F11: Previsualización y Exportación

### Propósito
Mostrar al usuario el video final procesado y ofrecer opciones de guardado, compartición y análisis.

### Trigger
- Finalización exitosa de F10
- Usuario selecciona un video completado desde dashboard

### Actores
- Usuario
- Reproductor de video
- Sistema de exportación

### Precondiciones
- Video final generado (`final.mp4`)
- `AssetManifest.json` actualizado

### Postcondiciones
- Video guardado en galería (opcional)
- Compartido en redes (opcional)
- Análisis generado (F12)
- Proyecto marcado como "completado"

---

### Secuencia detallada

**PASO 1: Pantalla de previsualización**
- Video final comienza a reproducirse automáticamente
- Controles de reproducción estándar (play/pause, volumen, pantalla completa)
- Indicador de duración total
- Botón de "Pantalla completa" para mejor vista

**PASO 2: Opciones de exportación**
- Botones de acción principales:
  - 💾 "Guardar en galería"
  - 📤 "Compartir"
  - 📊 "Ver análisis"
- Opciones secundarias (menú ⋮):
  - "Exportar como..." (formato)
  - "Añadir a proyecto"
  - "Renombrar video"
- Sticky CTA muestra "Listo" (vuelve a dashboard)

**PASO 3: Selección de formato (si aplica)**
- Usuario toca "Exportar como..."
- Opciones de formato:
  - 9:16 (Reels/TikTok) - por defecto
  - 1:1 (Instagram)
  - 16:9 (YouTube)
  - Original (mantiene relación de aspecto)
- Vista previa del recorte (si aplica)
- Confirmar exportación

**PASO 4: Guardado en galería**
- Al tocar "Guardar en galería"
- Procesamiento de exportación (si cambió formato)
- Barra de progreso breve
- Confirmación: "Video guardado en tu galería"
- Botón "Ver en galería" (abre app de fotos)

**PASO 5: Compartición directa**
- Al tocar "Compartir"
- Abre share sheet nativo del sistema
- Opciones: Instagram, TikTok, YouTube, WhatsApp, etc.
- Puede incluir texto sugerido (copy generado)
- Al completar, vuelve a previsualización

**PASO 6: Finalización**
- Usuario toca "Listo" (o "← Volver")
- Proyecto se marca como completado
- Estadísticas del usuario actualizadas (`videos_created +1`)
- Transición a dashboard

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-2 | PREVIEW |
| 3 | PREVIEW_FORMAT_SELECT |
| 4 | PREVIEW_SAVING |
| 5 | PREVIEW_SHARING |
| 6 | PREVIEW_COMPLETE |

### Datos actualizados
```json
{
  "project_status": "completed",
  "completed_at": "timestamp",
  "exported_formats": ["9:16", "original"]
}
```

### Flujos alternativos
- **FA11.1:** Usuario quiere editar algo → botón "Editar fragmentos" (vuelve a F5)
- **FA11.2:** Usuario quiere regenerar con ajustes → "Ajustar y procesar de nuevo"

### Flujos de error
- **FE11.1:** Error al guardar en galería → reintentar
- **FE11.2:** Formato no soportado → sugerir conversión

### Dependencias
- Video final generado (F10)

---

## FLUJO F12: Análisis de Rendimiento y Gamificación

### Propósito
Proporcionar al usuario métricas de su desempeño y recompensas por su progreso, fomentando mejora continua y adherencia.

### Trigger
- Finalización de video (después de F11)
- Usuario selecciona "Ver análisis" desde previsualización
- Usuario accede a su perfil desde dashboard

### Actores
- Usuario
- Motor de análisis
- Sistema de gamificación

### Precondiciones
- Video completado y procesado
- `AssetManifest.json` con métricas básicas

### Postcondiciones
- Usuario visualiza su rendimiento
- Puntuaciones actualizadas
- Rachas y niveles actualizados
- Nueva misión generada (opcional)

---

### Secuencia detallada

**PASO 1: Acceso al dashboard de análisis**
- Pantalla dividida en secciones:
  - **Superior:** Creator Score actual y nivel
  - **Media:** Métricas del último video
  - **Inferior:** Historial y progreso
- Animación de entrada con datos
- Tono positivo: "¡Buen trabajo!"

**PASO 2: Visualización de Creator Score**
- Número grande: "742" (ejemplo)
- Tendencia: "↑ +23 respecto al anterior"
- Componentes del score (barras de progreso):
  - Claridad: 85% ████████░░
  - Ritmo: 78% ███████░░░
  - Muletillas: 92% █████████░
  - Energía: 81% ████████░░
  - Consistencia: 88% ████████░░
- Tooltips al tocar cada componente (explicación)

**PASO 3: Métricas detalladas del último video**
- **Gráfico de ritmo:** palabras por minuto a lo largo del video, con línea ideal superpuesta
- **Detección de muletillas:** lista de "um", "eh", "o sea" con frecuencia
- **Transcripción con resaltado:** texto completo con palabras de relleno en color
- **Análisis de pausas:** gráfico circular con distribución por duración
- **Contacto visual:** porcentaje de tiempo mirando a cámara (si medible)

**PASO 4: Comparativa con historial**
- Gráfico de evolución del Creator Score (línea ascendente)
- Hitos destacados:
  - "Mejor video: 15 enero (780 pts)"
  - "Mayor progreso: +50 pts en 7 días"
  - "Racha actual: 12 días"
- Botón "Ver todos los videos" (historial completo)

**PASO 5: Sistema de niveles**
- Nivel actual: "Narrador (Nivel 3/5)"
- Barra de progreso al siguiente nivel
- "Te faltan 158 pts para alcanzar 'Influencer'"
- Beneficios desbloqueados en este nivel:
  - ✅ Frameworks avanzados
  - ✅ Análisis detallado
  - ⏳ Siguiente: Grabación dual

**PASO 6: Sistema de rachas**
- "🔥 Racha actual: 12 días"
- "Racha máxima: 23 días"
- Calendario de los últimos 30 días (verde = día con video)
- Mensaje: "¡No rompas la racha! Graba hoy."

**PASO 7: Generación de misión personalizada**
- Basada en la mayor debilidad detectada:
  - Si muchas muletillas: "Reduce tus muletillas a menos de 5 en el próximo video"
  - Si ritmo inestable: "Mantén tu ritmo entre 140-160 WPM"
  - Si contacto visual bajo: "Mantén la mirada en cámara >90%"
- Recompensa al completar: +50 puntos extra
- Botón "Aceptar misión" (guarda para próxima sesión)

**PASO 8: Opciones de cierre**
- Botones de acción:
  - "🎬 Grabar nuevo video" (va a F3)
  - "📋 Ver mis proyectos" (dashboard)
  - "🏆 Logros" (ver insignias desbloqueadas)
- Sticky CTA: "Continuar"

---

### Estados del sistema
| Paso | Estado |
|------|--------|
| 1-2 | ANALYSIS_DASHBOARD |
| 3 | ANALYSIS_DETAILS |
| 4 | ANALYSIS_HISTORY |
| 5-6 | ANALYSIS_GAMIFICATION |
| 7 | ANALYSIS_MISSION |
| 8 | ANALYSIS_COMPLETE |

### Datos actualizados
```json
{
  "creator_score": 742,
  "level": "storyteller",
  "level_progress": 0.68,
  "current_streak": 12,
  "longest_streak": 23,
  "missions": [{
    "id": "mission_123",
    "type": "reduce_fillers",
    "target": "<5",
    "reward": 50
  }]
}
```

### Flujos alternativos
- **FA12.1:** Primer video del usuario → mensaje especial y score inicial 100
- **FA12.2:** Nuevo nivel alcanzado → animación de celebración
- **FA12.3:** Racha completada (7/30/100 días) → insignia especial

### Reglas de negocio
- Creator Score = media ponderada de métricas
- Misiones basadas en la métrica con peor rendimiento
- Máximo 3 misiones activas simultáneamente
- Rachas = días con al menos un video grabado
- Niveles basados en score acumulado

### Dependencias
- Video completado (F10-F11)
- Historial de videos (perfil de usuario)

---

# PARTE 2: FLUJOS AVANZADOS (ETAPA 2 - VERSIÓN 1.5)

---

## FLUJO F13: Grabación Multi-Dispositivo (Modo Estudio)

### Propósito
Permitir grabar simultáneamente con dos dispositivos sincronizados para obtener múltiples ángulos y mejor control.

### Trigger
- Usuario selecciona "Modo Estudio" desde inicio de nuevo proyecto
- Usuario tiene nivel de creador suficiente (Influencer+)

### Actores
- Usuario
- Dispositivo A (Cámara principal)
- Dispositivo B (Control/Teleprompter)

### Precondiciones
- Ambos dispositivos con app instalada
- Misma red WiFi (o Bluetooth activo)
- Nivel de batería suficiente

### Postcondiciones
- Conexión establecida entre dispositivos
- Grabación sincronizada iniciada
- Clips etiquetados por cámara

---

### Secuencia detallada (resumida)

**PASO 1: Inicio en dispositivo A**
- Usuario selecciona "Modo Estudio"
- Genera código QR con información de conexión
- Muestra pantalla de espera

**PASO 2: Conexión desde dispositivo B**
- Usuario abre app en dispositivo B
- Selecciona "Conectar como control"
- Escanea código QR del dispositivo A
- Establece conexión vía Wi-Fi Direct/BLE
- Confirmación en ambos dispositivos

**PASO 3: Configuración de roles**
- Dispositivo A: cámara principal (graba video)
- Dispositivo B: teleprompter + control remoto
- Script se sincroniza automáticamente en ambos
- Posibilidad de intercambiar roles

**PASO 4: Grabación sincronizada**
- Ambos dispositivos muestran mismo estado
- Comandos en B afectan a A (grabar, stop, next)
- Al grabar, ambos guardan clip localmente
- Clips se etiquetan: "clip1_camA", "clip1_camB"
- Metadatos de sincronización incluidos

**PASO 5: Transferencia de clips**
- Al finalizar, clips del dispositivo B se transfieren a A
- Transferencia automática vía WiFi Direct
- Confirmación de recepción

**PASO 6: Post-procesamiento multicámara**
- Auto-stitch detecta clips de ambas cámaras
- Alternancia automática de ángulos (ej. frases impares: CamA, pares: CamB)
- Opciones de edición: qué cámara priorizar
- Video final con ángulos alternados

---

### Requerimientos técnicos
- Protocolo de sincronización en tiempo real
- Latencia máxima: <100ms
- Manejo de desconexiones con reconexión automática

---

## FLUJO F14: Director de IA (Montaje Semántico Automático)

### Propósito
La IA analiza el guion y decide automáticamente qué cámara usar, cuándo hacer zoom y qué B-roll insertar.

### Trigger
- Usuario activa "Director IA" en opciones avanzadas
- Disponible en niveles superiores (Narrador+)

---

### Secuencia detallada

**PASO 1: Análisis semántico del guion**
- IA analiza cada fragmento del `ScriptBundle`
- Clasifica por intención: dato, historia, emoción, CTA, descripción

**PASO 2: Generación de plan de montaje**
- Para cada fragmento, asigna:
  - **Cámara sugerida:** principal (frontal) para datos, secundaria (ángulo) para historias
  - **Zoom:** in/out según énfasis requerido
  - **B-roll:** si hay descripciones visuales, sugiere clip de stock
- Se genera `edit_decision_list.json`

**PASO 3: Indicaciones durante grabación**
- En teleprompter, muestra iconos sutiles:
  - "🎥 Cámara B para esta frase"
  - "🔍 Zoom in al final"
- Usuario sigue indicaciones opcionalmente

**PASO 4: Edición automática post-grabación**
- Al unir clips, aplica las decisiones del plan
- Inserta B-roll en los puntos indicados
- Aplica zooms y transiciones según intención

---

## FLUJO F15: Modo Maratón (Commitment Contract)

### Propósito
Crear compromiso a largo plazo mediante sistema de apuesta psicológica con puntos y penalizaciones.

### Trigger
- Usuario activa "Modo Maratón" desde perfil

---

### Secuencia detallada

**PASO 1: Configuración del reto**
- Usuario selecciona duración: 7, 30, 60 días
- Objetivo diario: 1 video por defecto (configurable)
- Sistema muestra reglas:
  - Puntos base por video: 10
  - Multiplicador por consistencia: x1.2 (2 videos/día) hasta x2 (5+ videos)
  - Penalización por día fallado: -50 puntos
  - Bonus por completar reto: +500 puntos

**PASO 2: Seguimiento diario**
- Dashboard muestra progreso:
  - Días completados / total
  - Puntos acumulados
  - Rachas dentro del reto
- Notificaciones recordatorias

**PASO 3: Finalización del reto**
- Si completa: celebración, bonus aplicado, insignia desbloqueada
- Si falla: mensaje de ánimo, opción de reiniciar

---

# PARTE 3: FLUJOS DE SOPORTE (TRANSVERSALES)

---

## FLUJO F16: Gestión de Proyectos

### Propósito
Permitir al usuario organizar, buscar y reutilizar sus proyectos anteriores.

### Trigger
- Usuario accede a "Mis proyectos" desde dashboard

---

### Vista principal
- Lista de proyectos ordenados por fecha (más reciente primero)
- Cada proyecto muestra: miniatura, título, fecha, duración, estado
- Estados: borrador, en progreso, completado, procesando
- Filtros: por estado, por fecha, por etiqueta
- Búsqueda por título o contenido del guion

### Acciones por proyecto
- Ver video final
- Editar guion (regrabar fragmentos)
- Duplicar proyecto (nuevo video basado en mismo guion)
- Exportar todos los archivos
- Eliminar proyecto (con confirmación)

---

## FLUJO F17: Gestión de Perfil y Configuración

### Propósito
Permitir al usuario ver y ajustar su perfil, preferencias y configuración de la app.

### Secciones

**Perfil público**
- Foto, nombre, biografía (opcional)
- Estadísticas públicas (opt-in)

**Preferencias de grabación**
- Velocidad por defecto
- Tono preferido
- Audiencia objetivo

**Configuración de teleprompter**
- Tamaño de fuente
- Posición del texto (tercio superior ajustable)
- Color y opacidad de fondo

**Configuración de audio**
- Sensibilidad de VAD
- Reducción de ruido (on/off)
- Volumen de monitorización

**Cuenta**
- Email
- Plan actual (Free/Pro/Studio)
- Método de pago
- Historial de facturas

**Privacidad**
- Qué datos compartir
- Exportar mis datos
- Eliminar cuenta

---

## FLUJO F18: Integración con Redes Sociales

### Propósito
Conectar la app con plataformas sociales para publicar directamente y obtener métricas de rendimiento.

### Funcionalidades

**Conexión de cuentas**
- OAuth con Instagram, TikTok, YouTube, LinkedIn
- Permisos de lectura de métricas y publicación

**Publicación directa**
- Seleccionar video desde biblioteca
- Añadir descripción (puede usar texto sugerido)
- Programar publicación
- Publicar ahora

**Obtención de métricas**
- Vistas, likes, comentarios, shares
- Retención de audiencia
- Datos demográficos básicos

**Correlación y aprendizaje**
- Relaciona métricas con metadatos de producción:
  - "Tus videos con tono humorístico tienen 20% más retención"
  - "Los videos de <60s funcionan mejor en TikTok"
- Feedback al generador de guiones para optimización

---

# PARTE 4: FLUJOS DE PLATAFORMA (ETAPA 4 - FUTURO)

---

## FLUJO F19: Agentes Autónomos (MCP)

### Propósito
Permitir al usuario dar instrucciones de alto nivel que la IA ejecuta automáticamente.

### Comandos soportados
- "Toma las 5 ideas de mi repositorio, genera guiones y prepáralos para grabar"
- "Del proyecto X, genera versión en inglés y publícala en YouTube"
- "Crea una campaña semanal con los temas más trending de mi nicho"

### Arquitectura
- Basada en MCP (Model Context Protocol)
- Agente orquestador que coordina flujos F3-F11 automáticamente

---

## FLUJO F20: Colaboración en Equipo

### Propósito
Permitir que equipos trabajen juntos en proyectos de contenido.

### Funcionalidades
- Proyectos compartidos con invitación
- Roles: editor, revisor, talento, administrador
- Flujos de aprobación (guionista → editor → talento)
- Comentarios en fragmentos específicos
- Versionado de proyectos
- Historial de cambios

---

## FLUJO F21: API Pública

### Propósito
Permitir que terceros integren y extiendan la plataforma.

### Endpoints
- Crear proyecto
- Generar guion
- Subir video procesado
- Obtener métricas
- Webhooks para notificaciones

### Documentación
- Swagger/OpenAPI
- SDKs para Python, JavaScript, etc.
- Ejemplos de integración

---

# RESUMEN DE FLUJOS POR ETAPA

| Etapa | Flujos incluidos |
|-------|------------------|
| **MVP (Etapa 1)** | F1 Onboarding, F2 Perfilado, F3 Idea Lab, F4 Generación, F5 Edición, F6 Preparación, F7 Menú, F8 Grabación, F9 Revisión, F10 Auto-stitch, F11 Previsualización, F12 Análisis |
| **Etapa 2 (1.5)** | F13 Multi-dispositivo, F14 Director IA, F15 Modo Maratón |
| **Soporte** | F16 Gestión proyectos, F17 Perfil/config, F18 Integración social |
| **Etapa 4 (Futuro)** | F19 Agentes autónomos, F20 Colaboración equipo, F21 API pública |

---

**Total de flujos definidos: 21**

Esta hoja de ruta proporciona una guía completa para el desarrollo incremental del producto, desde el MVP funcional hasta la plataforma completa con capacidades avanzadas de IA, colaboración y ecosistema.