## VISIÓN COMPLETA DEL PROYECTO "CÁMARA ATÓMICA"
### Hoja de Ruta desde el MVP hasta la Plataforma Definitiva

---

# INTRODUCCIÓN: LA TESIS FUNDACIONAL

**Cámara Atómica** no es una aplicación de grabación más. Es un **sistema operativo de producción de discurso en video** diseñado para transformar la experiencia de crear contenido hablado.

Su tesis central es simple pero radical: **el mayor obstáculo para crear videos no es la falta de talento, sino la sobrecarga cognitiva que produce el proceso tradicional**. Al reducir sistemáticamente esa carga, cualquier persona puede comunicarse con naturalidad, fluidez y autoridad frente a una cámara.

El nombre "Atómica" refleja su esencia: dividir el discurso en sus unidades más pequeñas (átomos) para hacerlo manejable, y liberar una energía creativa que el proceso tradicional bloquea.

---

# PARTE 1: LA BASE CONCEPTUAL (Fundamentos del Producto)

## 1.1 El Problema que Resuelve

**El proceso tradicional de creación de video**:

```
Idea → Guion largo → Memorización → Grabación completa → Repeticiones → Edición manual → Video final
```

Este proceso exige que el usuario realice simultáneamente:
- Recordar texto (memoria de trabajo)
- Mantener contacto visual (concentración)
- Modular la voz (expresión)
- Controlar gestos (lenguaje corporal)
- Mantener la narrativa (estructura)

**Esto supera la capacidad de la memoria de trabajo humana** (4±2 elementos simultáneos). El resultado es ansiedad, múltiples tomas, frustración y abandono.

## 1.2 La Solución Propuesta

**El flujo de Cámara Atómica**:

```
Idea → Guion estructurado → Micro-fragmentación → Loop de grabación guiada → Unión automática → Video final
```

Cada etapa está diseñada para **reducir un tipo específico de fricción cognitiva**.

## 1.3 Los Cuatro Pilares del Producto

| Pilar | Función | Beneficio |
|-------|---------|-----------|
| **Estructura de contenido** | Transforma ideas en guiones persuasivos | Elimina "no sé qué decir" |
| **Grabación guiada** | Micro-fragmentos + teleprompter + voz | Elimina "me olvido" y "me trabo" |
| **Edición invisible** | Auto-stitch + normalización | Elimina la post-producción |
| **Progreso psicológico** | Métricas + niveles + misiones | Crea hábito y mejora continua |

---

# PARTE 2: VISIÓN POR ETAPAS DE MADUREZ

## ETAPA 1: EL MVP (Mes 0-6) — "La Semilla"

### Filosofía
Hacer una sola cosa extraordinariamente bien: **permitir que cualquier persona grabe un video hablado en minutos sin ansiedad**.

### Usuario Objetivo
Creadores individuales, emprendedores, profesionales que necesitan video pero lo postergan por miedo o pereza.

### Plataforma
iOS / Android (nativo). Mobile-first, pensado para grabar con una mano.

### Funcionalidades Core (15)

#### 1.1 Onboarding Mínimo
- 3 preguntas: "¿Eres Líder, Creador o Vendedor?"
- Configuración por defecto según perfil
- Sin registro obligatorio inicial

#### 1.2 Laboratorio de Ideas (Básico)
- Campo de texto para ingresar idea
- 3 frameworks narrativos: Vender, Educar, Conectar
- Cada framework tiene una plantilla fija (no IA generativa compleja)
- **Edición manual obligatoria** del guion generado

#### 1.3 Micro-Fragmentación
- Algoritmo que divide el guion en fragmentos de 2-4 segundos
- Máximo 10 palabras por fragmento
- Visualización clara de la secuencia (Fragmento 1/5, etc.)

#### 1.4 Teleprompter Inteligente
- Texto anclado en el tercio superior (20% desde arriba)
- Fondo semitransparente con blur
- Tipografía grande y sans-serif
- Sin scroll automático (el texto cambia al avanzar fragmento)

#### 1.5 Grabación por Fragmentos
- Ciclo: mostrar texto → grabar → detener → revisar → siguiente
- Botón grande y visible para grabar/detener
- Cada fragmento se guarda como clip independiente

#### 1.6 Control por Voz Básico
- Comandos: "grabar", "siguiente", "repetir"
- Reconocimiento offline (on-device) para velocidad
- Feedback visual claro cuando se detecta comando

#### 1.7 Sticky Bottom CTA
- Botón persistente en la parte inferior
- Estados: GRABAR (rojo) → DETENER (rojo pulsante) → SIGUIENTE (verde)
- Feedback háptico al presionar

#### 1.8 Repetición Rápida
- Al finalizar cada fragmento, opciones: [Repetir] [Aceptar]
- Si se repite, el clip anterior se descarta
- Contador de intentos por fragmento (opcional)

#### 1.9 Auto-Stitch Básico
- Unión secuencial de todos los clips aceptados
- Eliminación de silencios entre fragmentos (corte simple)
- Exportación a MP4 en resolución original

#### 1.10 Gestión de Proyectos Simple
- Cada sesión de grabación es un "proyecto"
- El proyecto guarda: idea original, guion, clips raw, video final
- Lista de proyectos recientes

#### 1.11 Asset Bundle Mínimo
- Estructura de carpetas por proyecto
- Archivo manifest.json con metadatos básicos (fecha, duración, fragmentos)

#### 1.12 Vista Previa Final
- Reproducción del video unido antes de guardar
- Opción de regrabar fragmentos específicos

#### 1.13 Exportación Básica
- Guardar en galería del dispositivo
- Formato 9:16 (vertical) por defecto

#### 1.14 Perfil de Usuario Local
- Almacenamiento local de preferencias (tono preferido, velocidad)
- Sin sincronización en la nube

#### 1.15 Feedback Post-Grabación Mínimo
- Duración total del video
- Número de fragmentos grabados
- Mensaje de ánimo ("¡Primer video completado!")

### Entregables de la Etapa 1
- ✅ App funcional en tiendas (TestFlight / Beta cerrada)
- ✅ 100 usuarios activos semanales
- ✅ Tiempo de grabación < 10 minutos para video de 60 segundos
- ✅ Tasa de finalización > 70% (usuarios que completan el video que empezaron)

---

## ETAPA 2: VALIDACIÓN Y PULIDO (Mes 6-12) — "El Crecimiento"

### Filosofía
Refinar el core, añadir las funcionalidades que aumentan retención, y preparar el terreno para la expansión.

### Nuevas Funcionalidades (12)

#### 2.1 Detección Automática de Voz (VAD)
- Stop automático al detectar silencio > 1.5 segundos
- Ajuste de sensibilidad según perfil
- Fallback manual siempre disponible

#### 2.2 Aprobación Pasiva
- Si el usuario no dice "repetir" en 3 segundos, el clip se acepta automáticamente
- Barra de progreso visual del tiempo restante
- Reducción drástica de interacciones

#### 2.3 Análisis de Rendimiento Post-Grabación
- Métricas: palabras por minuto, muletillas detectadas, duración de pausas
- Visualización simple (gráficos de barras)
- Comparación con videos anteriores

#### 2.4 Sistema de Rachas (Streaks)
- Contador de días consecutivos grabando
- Notificaciones de "¡Ya casi pierdes tu racha!"
- Celebración al alcanzar hitos (7, 30, 100 días)

#### 2.5 Perfilado Progresivo
- Calibración automática con los primeros videos
- Detección de velocidad de habla preferida
- Ajuste automático del teleprompter

#### 2.6 Editor de Guion Mejorado
- Resaltado de palabras clave
- Sugerencias de mejora (basadas en reglas, no IA)
- Guardado de versiones del guion

#### 2.7 Normalización de Audio
- Reducción de ruido de fondo básica
- Normalización de volumen entre fragmentos
- Opciones: "Modo estudio" / "Modo calle"

#### 2.8 Normalización de Iluminación
- Análisis de luminancia por clip
- Ajuste automático para consistencia visual
- Opción de ajuste manual sobre frame de referencia

#### 2.9 Biblioteca de Guiones
- Guardar guiones exitosos
- Etiquetado por tema, tono, resultado
- Reutilización con un clic

#### 2.10 Exportación a Redes
- Formatos: 9:16 (Reels/TikTok), 1:1 (Instagram), 16:9 (YouTube)
- Generación de subtítulos automáticos (opcional)
- Copia de descripción sugerida

#### 2.11 Sincronización en la Nube
- Respaldo de proyectos
- Continuidad entre dispositivos
- Compartición de proyectos con equipo (básico)

#### 2.12 Sistema de Misiones (Versión 1)
- Después de cada análisis, una misión personalizada
- Ejemplo: "Reduce tus muletillas a menos de 5 en el próximo video"
- Seguimiento de cumplimiento

### Entregables de la Etapa 2
- ✅ 1,000 usuarios activos mensuales
- ✅ Retención D30 > 30%
- ✅ Creator Score implementado y aceptado
- ✅ Validación de que las métricas mejoran con el uso

---

## ETAPA 3: EXPANSIÓN Y DIFERENCIACIÓN (Mes 12-24) — "El Ecosistema"

### Filosofía
Introducir las capacidades avanzadas que diferencian radicalmente el producto y lo convierten en plataforma.

### Nuevas Funcionalidades (12)

#### 3.1 Creator Score
- Métrica única compuesta: claridad (30%) + ritmo (25%) + filler words (20%) + energía (15%) + consistencia (10%)
- Rango: 0-2000
- Historial gráfico de evolución
- Comparación con oneself (nunca con otros)

#### 3.2 Niveles de Creador
- 5 niveles: Novato (0-300), Comunicador (301-600), Narrador (601-900), Influencer (901-1300), Maestro (1301-2000)
- Cada nivel desbloquea nuevas funciones
- Insignias visuales

#### 3.3 Sistema de Misiones Avanzado
- Misiones generadas por IA basadas en debilidades detectadas
- Dificultad adaptativa
- Recompensas: puntos extra, insignias, desbloqueos

#### 3.4 Grabación con Dos Teléfonos (Modo Estudio)
- Sincronización vía QR + Wi-Fi Direct
- Device A: cámara principal
- Device B: teleprompter + control remoto
- Edición multicámara automática (alternancia de ángulos)

#### 3.5 Director de IA (Montaje Semántico)
- Análisis del guion antes de grabar
- Etiquetado de fragmentos por intención (datos, historia, CTA)
- Sugerencias de cámara: "Usa cámara B para esta frase emocional"
- Generación automática de B-Roll (integración con bancos de stock)

#### 3.6 Corrección de Contacto Visual
- Post-procesamiento que redirige la mirada hacia la cámara
- Tecnología similar a NVIDIA Maxine / VEED
- Toggle en ajustes (requiere créditos premium)

#### 3.7 Overdub (Corrección por Texto)
- Cambiar palabras sin regrabar
- Escribir el texto corregido → IA genera audio con voz clonada
- Lip-sync automático
- Requiere entrenamiento de voz inicial

#### 3.8 Traducción Automática
- Generar versiones del video en otros idiomas
- Mantiene la voz original (clonada)
- Subtítulos automáticos en el idioma destino
- Distribución internacional con un clic

#### 3.9 Radar de Tendencias
- Conexión a Google Trends, RSS, APIs de nicho
- Sugerencias: "Hoy se habla de X en tu industria"
- Generación automática de guion sobre el tema

#### 3.10 Integración con Redes Sociales (Métricas)
- Conexión vía OAuth con plataformas
- Lectura de rendimiento: vistas, retención, engagement
- Correlación: "Tus videos con tono humorístico tienen 20% más retención"
- Feedback al generador de guiones

#### 3.11 Arquitectura de Plugins (Alpha)
- Interfaces públicas: IIdeaSource, IScriptProcessor, IPostProcessor, IAnalyticsProvider
- Documentación para desarrolladores
- Marketplace de plugins (lanzamiento limitado)

#### 3.12 Modo Maratón (Commitment Contract)
- Compromiso de X días grabando
- Sistema de puntos con multiplicador por consistencia
- Penalización por fallo (pérdida de puntos)
- Recompensas reales (descuentos, funciones exclusivas)

### Entregables de la Etapa 3
- ✅ 10,000 usuarios activos mensuales
- ✅ 3 plugins de terceros en el marketplace
- ✅ Integración con 5 plataformas principales
- ✅ Creator Score como estándar de la industria

---

## ETAPA 4: LA PLATAFORMA DEFINITIVA (Mes 24-36) — "El Sistema Operativo"

### Filosofía
Cámara Atómica se convierte en el centro neurálgico de la creación de contenido para profesionales y equipos.

### Nuevas Funcionalidades (8)

#### 4.1 Agentes Autónomos (MCP)
- El usuario puede dar instrucciones de alto nivel
- "Toma las 5 ideas de esta fuente, genera guiones y prepáralos para grabar"
- "Del proyecto X, genera versión en inglés y publícala en YouTube"
- Agentes ejecutan el pipeline completo sin intervención

#### 4.2 Colaboración en Equipo
- Proyectos compartidos
- Flujos de aprobación: guionista → editor → talento
- Comentarios y versionado

#### 4.3 Biblioteca de Activos Corporativa
- Todos los videos de la empresa en un repositorio
- Búsqueda semántica por contenido hablado
- Reutilización de fragmentos en múltiples campañas

#### 4.4 Analytics Predictivo
- Predicción de rendimiento antes de publicar
- "Este video tiene 85% de probabilidad de superar 10k vistas"
- Basado en datos históricos y tendencias actuales

#### 4.5 Generación de Variantes A/B
- Crear múltiples versiones del mismo video
- Ganchos diferentes, tonos diferentes, CTAs diferentes
- Publicación automática para testeo

#### 4.6 Studio Remoto Completo
- Integración con hardware profesional (luces, teleprompters físicos)
- Control de estudio desde tablet
- Grabación con hasta 4 cámaras sincronizadas

#### 4.7 API Pública
- Terceros pueden construir sobre Cámara Atómica
- Integración con CRMs, herramientas de marketing, plataformas educativas
- Automatización de flujos completos

#### 4.8 Comunidad y Mercado de Talentos
- Creadores pueden ofrecer sus servicios
- Empresas pueden encontrar talento verificado
- Los guiones y métricas de calidad respaldan el perfil

### Entregables de la Etapa 4
- ✅ 100,000 usuarios activos mensuales
- ✅ 50+ plugins en el marketplace
- ✅ API con 1,000+ desarrollores registrados
- ✅ Posicionamiento como estándar de la industria

---

# PARTE 3: ARQUITECTURA TÉCNICA TRANSVERSAL

## 3.1 Principios Arquitectónicos Fundamentales

| Principio | Descripción | Aplicación |
|-----------|-------------|------------|
| **Specification-Driven Design** | Todo se define por contratos antes de implementar | JSON Schemas para cada etapa |
| **Pipeline Lineal** | Flujo unidireccional de datos | Idea → Guion → Grabación → Post → Análisis |
| **Persistencia Basada en Archivos** | Estado guardado en JSON, no en memoria volátil | user_profile.json, project_xxx/ |
| **Modularidad por Interfaces** | Cada etapa expone una interfaz | IIdeaSource, IScriptProcessor, etc. |
| **MCP-Ready** | Preparado para agentes autónomos | Datos legibles por máquinas |

## 3.2 Contratos de Datos (JSON Schemas)

### InputSchema.json
```json
{
  "idea_id": "uuid",
  "raw_topic": "string",
  "source_type": "manual|rss|api",
  "context_data": "string",
  "user_profile_id": "uuid"
}
```

### ScriptBundle.json
```json
{
  "script_id": "uuid",
  "project_id": "uuid",
  "framework": "pas|aida|story|list",
  "total_chunks": "integer",
  "chunks": [
    {
      "order": 1,
      "text": "string",
      "estimated_duration_sec": 3,
      "intent": "hook|value|cta",
      "tone": "neutral|urgent|empathetic"
    }
  ],
  "target_audience": "beginner|pro|expert",
  "cta": {
    "type": "comment|follow|link|share",
    "value": "string"
  }
}
```

### AssetManifest.json
```json
{
  "project_id": "uuid",
  "video_id": "uuid",
  "created_at": "timestamp",
  "chunks": [
    {
      "order": 1,
      "clip_path": "clips/clip_1.mp4",
      "duration": 3.2,
      "metadata": {
        "wpm": 145,
        "filler_words": 1,
        "gaze_score": 0.92,
        "audio_clarity": 0.88
      }
    }
  ],
  "final_video": "final.mp4",
  "transcript": "string",
  "quality_metrics": {
    "average_wpm": 148,
    "total_filler_words": 3,
    "consistency_score": 0.85
  }
}
```

### UserProfile.json
```json
{
  "user_id": "uuid",
  "identity": {
    "role": "leader|creator|seller",
    "level": "novice|communicator|storyteller|influencer|master",
    "creator_score": 742
  },
  "preferences": {
    "default_tone": "professional|casual|energetic",
    "default_framework": "pas|story|list",
    "teleprompter_speed": 150,
    "preferred_audience": "beginner|pro|expert"
  },
  "history": {
    "total_videos": 47,
    "current_streak": 12,
    "longest_streak": 23,
    "last_session": "timestamp"
  },
  "metrics_history": [
    {
      "date": "2024-01-01",
      "creator_score": 650,
      "average_wpm": 142,
      "filler_words_per_minute": 4.2
    }
  ]
}
```

## 3.3 Interfaces de Plugins

### IIdeaSource
```typescript
interface IIdeaSource {
  name: string;
  fetchIdeas(params: any): Promise<InputSchema[]>;
  configure(config: any): void;
}
```

### IScriptProcessor
```typescript
interface IScriptProcessor {
  name: string;
  process(input: InputSchema, config: ScriptConfig): Promise<ScriptBundle>;
  getFrameworks(): Framework[];
}
```

### IPostProcessor
```typescript
interface IPostProcessor {
  name: string;
  enhance(manifest: AssetManifest, options: ProcessingOptions): Promise<AssetManifest>;
  getCapabilities(): string[];
}
```

### IAnalyticsProvider
```typescript
interface IAnalyticsProvider {
  name: string;
  analyze(manifest: AssetManifest): Promise<AnalyticsReport>;
  getHistoricalData(userId: string, period: string): Promise<HistoricalData>;
}
```

---

# PARTE 4: EXPERIENCIA DE USUARIO TRANSVERSAL

## 4.1 Filosofía UX

| Principio | Manifestación |
|-----------|---------------|
| **Invisible UI** | Los controles desaparecen durante la grabación |
| **Fricción Cero** | Cada interacción debe ser la mínima posible |
| **Divulgación Progresiva** | La complejidad se revela solo cuando es necesaria |
| **Feedback Positivo** | Tono de entrenador, no de analista |
| **Contacto Visual Siempre** | El texto nunca obstruye la mirada a cámara |

## 4.2 Elementos de UI Persistentes

### Sticky Bottom CTA
- Siempre visible, siempre accesible
- Muta según el estado del flujo
- Diseño minimalista, feedback háptico

### Indicador de Estado del Agente
- Esfera dinámica que "respira" cuando escucha
- Cambia de color según estado (azul → rojo → verde)
- Muestra en tiempo real el comando detectado

### Barra de Progreso de Fragmentos
- "Fragmento 3/7"
- Visualización segmentada
- Micro-celebración al completar cada fragmento

## 4.3 Tono de Comunicación

La app habla como un **entrenador personal**:

- "¡Buen trabajo! Ese fragmento quedó muy natural."
- "Vas por buen camino. 3 fragmentos más y terminamos."
- "Noté que usaste 'eh' dos veces. ¿Quieres repetir o seguimos?"
- "¡Racha de 7 días! Estás convirtiendo esto en hábito."

Nunca:

- "Error: muletillas detectadas"
- "Fallo en la grabación"
- "Debes mejorar tu puntuación"

---

# PARTE 5: MODELO DE NEGOCIO Y SOSTENIBILIDAD

## 5.1 Estructura de Monetización

| Nivel | Precio | Funcionalidades | Público |
|-------|--------|-----------------|---------|
| **Free** | $0 | MVP completo (Etapa 1) + análisis básico + 5 proyectos | Creadores ocasionales |
| **Pro** | $9.99/mes | Todo el core (Etapas 1-2) + grabación dual + normalización avanzada | Creadores regulares |
| **Studio** | $29.99/mes | Todo (Etapas 1-3) + plugins premium + colaboración en equipo | Equipos y agencias |
| **Enterprise** | Custom | API dedicada, entrenamiento, soporte prioritario, instancia privada | Empresas grandes |

## 5.2 Modelo de Plugins

- **Plugins gratuitos**: Desarrollados por Cámara Atómica (core)
- **Plugins de pago**: Desarrollados por terceros, revenue share 70/30
- **Plugins internos**: Funcionalidades avanzadas como servicio (eye contact, overdub, traducción) con créditos prepagos

---

# PARTE 6: MÉTRICAS DE ÉXITO POR ETAPA

| Etapa | Métrica Clave | Objetivo |
|-------|---------------|----------|
| **1 - MVP** | Tasa de finalización de primer video | > 70% |
| **1 - MVP** | Tiempo hasta primer video | < 5 minutos |
| **2 - Validación** | Retención D30 | > 30% |
| **2 - Validación** | Videos por usuario activo mensual | > 5 |
| **3 - Expansión** | Usuarios activos mensuales | > 10,000 |
| **3 - Expansión** | NPS (Net Promoter Score) | > 50 |
| **4 - Plataforma** | Ingresos recurrentes anuales (ARR) | > $1M |
| **4 - Plataforma** | Plugins de terceros | > 50 |

---

# PARTE 7: VISIÓN A 5 AÑOS

Cámara Atómica no es solo una app. Es:

- **El estándar de facto** para la creación de video hablado
- **La memoria externa** de la identidad comunicativa de cada creador
- **El centro de operaciones** donde humanos y agentes de IA colaboran para producir contenido
- **La plataforma** que democratiza la producción profesional de video

**Frase que define el destino del producto**:

> "Cámara Atómica es el lugar donde tus ideas se convierten en video sin que tengas que pensar en el proceso. Solo hablas; nosotros hacemos el resto."

---

# RESUMEN EJECUTIVO DE LA HOJA DE RUTA

| Etapa | Duración | Foco | Funcionalidades Clave | Usuarios Meta |
|-------|----------|------|----------------------|---------------|
| **1 - MVP** | 0-6 meses | Validar tesis central | Micro-fragmentación, teleprompter, auto-stitch básico | Early adopters |
| **2 - Validación** | 6-12 meses | Retención y mejora | VAD, análisis, rachas, normalización | Creadores regulares |
| **3 - Expansión** | 12-24 meses | Diferenciación | Creator Score, grabación dual, director IA, plugins | Profesionales |
| **4 - Plataforma** | 24-36 meses | Ecosistema | Agentes MCP, colaboración, API, mercado | Equipos y empresas |

---

Esta es la **visión completa y detallada** de Cámara Atómica, desde su núcleo más esencial hasta su expresión más ambiciosa como plataforma. Cada etapa está diseñada para construir sobre la anterior, validando hipótesis y agregando valor de forma incremental, sin desviarse de la tesis central: **hacer que crear video sea tan fácil como hablar**.