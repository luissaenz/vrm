---
description: Guía profunda sobre arquitectura de Pipeline Lineal Modular Determinista
---

# Skill: Arquitectura de Pipeline Lineal Modular Determinista

## 🎯 Definición

Una **arquitectura de Pipeline Lineal Modular Determinista** es un patrón de diseño de software donde:

1. **Pipeline**: Descompone tareas complejas en etapas secuenciales donde la salida de una etapa es la entrada de la siguiente
2. **Lineal**: Flujo unidireccional estricto sin ciclos ni ramificaciones complejas
3. **Modular**: Cada etapa es un módulo independiente e intercambiable
4. **Determinista**: Para una entrada dada, siempre produce la misma salida

---

## 📚 Fundamentos Teóricos

### Pipeline Pattern

El patrón Pipeline (también conocido como "Pipes and Filters") organiza el procesamiento de datos en etapas discretas y secuenciales:

```
[Input] → [Filter 1] → [Filter 2] → [Filter 3] → [Output]
```

**Ventajas**:
- **Throughput incrementado**: Múltiples ítems pueden procesarse concurrentemente en diferentes etapas
- **Modularidad y reusabilidad**: Cada etapa encapsula una responsabilidad única
- **Escalabilidad**: Las etapas pueden distribuirse en diferentes sistemas
- **Separación de responsabilidades**: Código organizado y legible

**Desventajas potenciales**:
- **Complejidad de diseño**: Gestionar el flujo de datos requiere planificación
- **Latencia para ítems individuales**: Un ítem debe atravesar todas las etapas
- **Hazards**: Dependencias de datos pueden causar bloqueos

### Procesamiento Determinista

Un sistema **determinista** garantiza que:
- ✅ Misma entrada → Misma salida (siempre)
- ✅ Resultados reproducibles
- ✅ Sin efectos secundarios impredecibles

**Principios para lograr determinismo**:

1. **Repetibilidad**: Resultados idénticos en múltiples ejecuciones
2. **Dependencias controladas**: Versiones explícitas de librerías/herramientas
3. **Eliminación de influencia externa**: Sin aprobaciones manuales ni intervenciones humanas
4. **Control de tiempo estricto**: No usar "wall-clock time" o condiciones de carrera
5. **Aleatoriedad reproducible**: Usar seeds para generadores de números aleatorios
6. **Tests robustos**: Eliminar tests "flaky"

**Fuentes de no-determinismo a evitar**:
- Race conditions en entornos multi-hilo
- Uso de tiempo del sistema sin control
- Iteración sobre estructuras sin orden garantizado (e.g., hash maps)
- Entrada externa no gestionada (filesystem, red)

---

## 🏗️ Implementación: Contract-Driven Design

### Specification-Driven Development (SDD)

**Definición**: Enfoque donde la interfaz o "contrato" del sistema se define ANTES de escribir cualquier código de implementación.

**Beneficios**:
- Decisiones técnicas explícitas y revisables
- Captura el "por qué" detrás de las decisiones técnicas
- Previene "intent-vs-implementation drift"
- Fomenta entendimiento compartido entre stakeholders

### Contract-First Development

Para APIs y sistemas de plugins, implica:

1. **Definir contratos** (interfaces, JSON Schemas, OpenAPI)
2. **Generar código** a partir de contratos (stubs, DTOs, clientes)
3. **Desarrollo paralelo**: Frontend y backend trabajan simultáneamente contra el contrato
4. **Validación automática**: El código debe cumplir el contrato

**Herramientas comunes**:
- OpenAPI/Swagger (REST APIs)
- JSON Schema (validación de datos)
- AsyncAPI (event-driven APIs)
- Protocol Buffers / Avro (serialización)

---

## 🔌 Plugin Architecture + Strategy Pattern

### Plugin Architecture Best Practices

#### 1. **Loose Coupling y Dependency Inversion**
```dart
// ❌ MAL: Core conoce implementaciones concretas
class Core {
  final GoogleTrendsPlugin plugin = GoogleTrendsPlugin();
}

// ✅ BIEN: Core solo conoce abstracciones
class Core {
  final IIdeaSource plugin;
  Core(this.plugin); // Inyección de dependencias
}
```

#### 2. **APIs e Interfaces Bien Definidas**
```dart
/// Interfaz estable que nunca debe cambiar
abstract class IScriptProcessor {
  String get pluginId;
  Future<ScriptBundle> process(InputSchema input, Map<String, dynamic> config);
}
```

#### 3. **Single Responsibility Principle**
Cada plugin debe hacer **una sola cosa**:
- ❌ `SuperPlugin` que ingiere, procesa Y exporta
- ✅ `IngestionPlugin`, `ProcessorPlugin`, `ExporterPlugin`

#### 4. **Dynamic Loading**
El sistema debe poder cargar/descargar plugins en runtime:
```dart
final pipeline = PipelineFactory.createFromConfig({
  'script_processor': 'backend_api_v1' // Cambiar sin recompilar
});
```

#### 5. **Versioning**
```dart
abstract class IPlugin {
  String get pluginId; // Ejemplo: "template_script_v1"
  String get version;  // Ejemplo: "1.2.0"
}
```

#### 6. **Error Handling & Security**
```dart
try {
  final plugin = loadPlugin(pluginPath);
  // Ejecutar en sandbox si es third-party
} catch (e) {
  // Error boundary: no crashear toda la app
  logger.error('Plugin failed: $e');
}
```

### Strategy Pattern Best Practices

#### 1. **Interfaz Simple y Enfocada**
```dart
// ✅ BIEN: Interfaz simple con un método claro
abstract class IAnalyzer {
  Future<Report> analyze(Data input);
}

// ❌ MAL: Interfaz sobrecargada
abstract class IAnalyzer {
  Future<Report> analyze(Data input);
  void configure(Map config);
  bool validateInput(Data input);
  String getReport();
  // ...demasiados métodos
}
```

#### 2. **Estado Encapsulado**
```dart
// El estado va en la estrategia concreta, no en el contexto
class AggressiveStrategy implements IStrategy {
  int _attemptCount = 0; // Estado privado
  
  @override
  Result execute(Input input) {
    _attemptCount++;
    // ...
  }
}
```

#### 3. **Uso de Dependency Injection**
```dart
// ✅ BIEN: Inyectar estrategia
class Context {
  final IStrategy strategy;
  Context(this.strategy); // Constructor injection
}

// ❌ MAL: Crear estrategia internamente
class Context {
  final strategy = ConcreteStrategy(); // Hard-coded
}
```

#### 4. **Factory o Enum para Creación**
```dart
enum StrategyType { template, backend, local }

class StrategyFactory {
  static IScriptProcessor create(StrategyType type) {
    switch (type) {
      case StrategyType.template:
        return TemplateScriptPlugin();
      case StrategyType.backend:
        return BackendScriptPlugin();
      case StrategyType.local:
        return LocalScriptPlugin();
    }
  }
}
```

---

## 🎨 Data Contracts con JSON Schema

### Principios de Data Contracts

Un **Data Contract** es un acuerdo formal que especifica:
- Nombres de campos
- Tipos de datos
- Nullability
- Campos requeridos
- Valores permitidos (ranges, enums)
- Expectativas semánticas

### Arquitectura por Capas

```
┌─────────────────────────────────┐
│  Schema Definition Layer        │ ← "Rulebook"
│  (JSON Schema)                  │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│  Validation Layer               │ ← "Bouncer"
│  (Enforce contracts)            │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│  Processing Layer               │ ← "Workers"
│  (Plugins)                      │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│  Monitoring Layer               │ ← "Watchtower"
│  (Check violations)             │
└─────────────────────────────────┘
```

### Ejemplo Práctico: InputSchema.json

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "InputSchema",
  "type": "object",
  "properties": {
    "idea_id": { 
      "type": "string", 
      "format": "uuid",
      "description": "Unique identifier"
    },
    "raw_topic": { 
      "type": "string",
      "minLength": 1,
      "maxLength": 200 
    },
    "source_type": { 
      "enum": ["manual", "rss", "api"],
      "description": "Source of the idea"
    }
  },
  "required": ["idea_id", "raw_topic", "source_type"],
  "additionalProperties": false  // ← Previene schema drift
}
```

### Validación en Código

```dart
import 'package:json_schema/json_schema.dart';

class InputSchemaValidator {
  static final schema = JsonSchema.createSchema({
    // ... definición del schema
  });

  static bool validate(Map<String, dynamic> data) {
    final result = schema.validate(data);
    if (!result.isValid) {
      throw ValidationError(result.errors);
    }
    return true;
  }
}

// Uso en plugin
class ManualInputPlugin implements IIdeaSource {
  @override
  Future<InputSchema> fetchIdea(Map<String, dynamic> params) async {
    // Validar contra schema ANTES de procesar
    InputSchemaValidator.validate(params);
    
    return InputSchema.fromJson(params);
  }
}
```

### Versioning de Contratos

```
project_v1.json  → Versión inicial
project_v2.json  → Agrega campo opcional "tags"
project_v3.json  → Campo "tags" ahora es required
```

**Reglas**:
- ✅ Agregar campos opcionales: compatible hacia atrás
- ❌ Remover campos: **breaking change**
- ❌ Cambiar tipos: **breaking change**
- ✅ Deprecar campos: marcar como `deprecated` en schema

---

## 📐 Dependency Injection Best Practices

### 1. Constructor Injection (Preferido)
```dart
// ✅ BIEN: Todas las dependencias son explícitas
class VRMPipeline {
  final IIdeaSource ideaSource;
  final IScriptProcessor scriptProcessor;
  
  VRMPipeline({
    required this.ideaSource,
    required this.scriptProcessor,
  });
}

// Uso
final pipeline = VRMPipeline(
  ideaSource: ManualInputPlugin(),
  scriptProcessor: TemplateScriptPlugin(),
);
```

### 2. Interfaces sobre Implementaciones
```dart
// ✅ BIEN: Depende de abstracción
class Service {
  final IRepository repository;
  Service(this.repository);
}

// ❌ MAL: Depende de implementación concreta
class Service {
  final SQLRepository repository;
  Service(this.repository);
}
```

### 3. Evitar Dependencias Circulares
```dart
// ❌ MAL: A depende de B, B depende de A
class A {
  final B b;
  A(this.b);
}
class B {
  final A a;
  B(this.a);
}

// ✅ BIEN: Extraer interfaz común
abstract class IEventBus {}

class A {
  final IEventBus bus;
  A(this.bus);
}
class B {
  final IEventBus bus;
  B(this.bus);
}
```

### 4. Servicios Pequeños y Enfocados
```dart
// ✅ BIEN: Un servicio, una responsabilidad
class EmailService {
  Future<void> send(Email email);
}

class ValidationService {
  bool validate(Data data);
}

// ❌ MAL: God Object
class SuperService {
  void sendEmail();
  void validateData();
  void processPayment();
  void generateReport();
  // ...
}
```

### 5. NO usar Service Locator
```dart
// ❌ MAL: Service Locator oculta dependencias
class Service {
  void doWork() {
    final repo = ServiceLocator.get<IRepository>();
    repo.save(...);
  }
}

// ✅ BIEN: Dependencias explícitas
class Service {
  final IRepository repo;
  Service(this.repo);
  
  void doWork() {
    repo.save(...);
  }
}
```

---

## 🚀 Patrón Completo: Pipeline + Plugins + Contracts + DI

### Arquitectura Final

```
┌─────────────────────────────────────────────────────┐
│                Application Layer                     │
│  - UI                                               │
│  - User Input                                       │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│              Pipeline Orchestrator                   │
│  (VRMPipeline - Injected with plugins)              │
└─────────────────────────────────────────────────────┘
         ↓           ↓           ↓           ↓
    [Plugin 1]  [Plugin 2]  [Plugin 3]  [Plugin 4]
    (IIdeaSource)(IScriptProc)(IPostProc)(IAnalytics)
         ↓           ↓           ↓           ↓
    InputSchema ScriptBundle AssetManifest ReportJSON
         ↓           ↓           ↓           ↓
┌─────────────────────────────────────────────────────┐
│           JSON Schema Validation Layer               │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│          Persistence Layer (JSON Files)              │
│          project_v1.json (Single Source of Truth)   │
└─────────────────────────────────────────────────────┘
```

### Ejemplo Completo

```dart
// 1. Definir contratos (JSON Schema)
// input_schema.json, script_bundle.json, etc.

// 2. Generar modelos Dart
class InputSchema { /* fromJson, toJson */ }
class ScriptBundle { /* fromJson, toJson */ }

// 3. Definir interfaces
abstract class IIdeaSource {
  Future<InputSchema> fetchIdea(Map<String, dynamic> params);
}

// 4. Implementar plugins concretos
class ManualInputPlugin implements IIdeaSource {
  @override
  String get pluginId => 'manual_input_v1';
  
  @override
  Future<InputSchema> fetchIdea(Map<String, dynamic> params) async {
    // Validar contra JSON Schema
    InputSchemaValidator.validate(params);
    
    // Procesar
    return InputSchema(
      ideaId: uuid.v4(),
      rawTopic: params['topic'],
      sourceType: 'manual',
    );
  }
}

// 5. Pipeline con DI
class VRMPipeline {
  final IIdeaSource ideaSource;
  final IScriptProcessor scriptProcessor;
  
  VRMPipeline({required this.ideaSource, required this.scriptProcessor});
  
  Future<ScriptBundle> execute(Map<String, dynamic> params) async {
    // Flow determinista lineal
    final input = await ideaSource.fetchIdea(params);
    final script = await scriptProcessor.process(input, {});
    return script;
  }
}

// 6. Factory con configuración
class PipelineFactory {
  static VRMPipeline createFromConfig(Map<String, dynamic> config) {
    final ideaSource = _createIdeaSource(config['idea_source'] ?? 'manual');
    final scriptProcessor = _createScriptProcessor(config['script_processor'] ?? 'template');
    
    return VRMPipeline(
      ideaSource: ideaSource,
      scriptProcessor: scriptProcessor,
    );
  }
}

// 7. Uso
final pipeline = PipelineFactory.createFromConfig({
  'idea_source': 'manual',
  'script_processor': 'template'
});

final result = await pipeline.execute({'topic': 'Mi video'});
```

---

## ✅ Checklist de Implementación

Al construir una arquitectura de Pipeline Lineal Modular Determinista:

### Fase 1: Contratos (Contract-First)
- [ ] Definir JSON Schemas para todos los datos intercambiados
- [ ] Validar schemas (herramientas de linting)
- [ ] Versionar schemas desde el inicio
- [ ] Generar modelos/clases desde schemas

### Fase 2: Interfaces (Strategy Pattern)
- [ ] Crear interfaces abstractas para cada etapa del pipeline
- [ ] Una responsabilidad por interfaz (SRP)
- [ ] Métodos mínimos y enfocados
- [ ] Documentar contratos con comentarios claros

### Fase 3: Plugins Default (MVP)
- [ ] Implementar un plugin básico por interfaz
- [ ] 100% funcional sin dependencias externas
- [ ] Validar input contra schemas
- [ ] Tests unitarios para cada plugin

### Fase 4: Pipeline Orchestrator
- [ ] Crear clase Pipeline que SOLO invoca plugins
- [ ] NO lógica de negocio en el orchestrator
- [ ] Flujo lineal y explícito (sin ciclos)
- [ ] Manejo de errores centralizado

### Fase 5: Dependency Injection
- [ ] Factory para creación de pipelines
- [ ] Constructor injection para plugins
- [ ] Configuración externa (JSON/YAML)
- [ ] Sin service locators

### Fase 6: Determinismo
- [ ] Eliminar dependencias de tiempo real
- [ ] Seeds para aleatoriedad
- [ ] Versiones fijas de dependencias
- [ ] Tests reproducibles

### Fase 7: Persistencia
- [ ] Estado como archivos JSON simples
- [ ] Un archivo = Un proyecto completo (InputSchema + ScriptBundle + AssetManifest)
- [ ] Versionado de archivos de estado

---

## 🎓 Casos de Uso

### ✅ Cuándo usar este patrón

- Procesamiento de datos con múltiples transformaciones secuenciales
- Sistemas que necesitan extensibilidad (agregar nuevas fuentes/destinos)
- Aplicaciones donde la reproducibilidad es crítica
- CI/CD pipelines
- ETL (Extract, Transform, Load) systems
- Content creation workflows
- Data processing pipelines
- Plugin systems (editors, IDEs, frameworks)

### ❌ Cuándo NO usar este patrón

- Flujos simples con 1-2 pasos
- Interacciones altamente branched/condicionales
- Sistemas con lógica de negocio muy dinámica
- Prototipos rápidos donde la flexibilidad > estructura

---

## 📖 Referencias y Lecturas Recomendadas

### Patrones de Diseño
- Martin Fowler - "Pipes and Filters" (Enterprise Integration Patterns)
- Gang of Four - "Strategy Pattern" (Design Patterns)
- Robert C. Martin - "Dependency Inversion Principle" (Clean Architecture)

### Contract-Driven Development
- OpenAPI Specification (swagger.io)
- JSON Schema (json-schema.org)
- AsyncAPI (asyncapi.com)

### Sistemas Deterministas
- Continuous Delivery Foundation - "Deterministic CI/CD"
- Academic: "Deterministic Parallel Processing"

---

## 🔧 Herramientas Útiles

### Validación de Schemas
- `json_schema` (Dart/Flutter)
- `ajv` (JavaScript/TypeScript)
- `jsonschema` (Python)

### Code Generation
- `quicktype` - Genera modelos desde JSON Schema
- `openapi-generator` - Genera código desde OpenAPI specs

### Testing
- `mockito` (Dart) - Mocking de interfaces
- `faker` - Generación de datos deterministas para tests

---

## 💡 Principios Clave a Recordar

1. **Contratos primero, código después**
2. **Interfaces > Implementaciones concretas**
3. **Inyección > Instanciación directa**
4. **Explícito > Implícito**
5. **Determinista > No-determinista**
6. **Modular > Monolítico**
7. **Validado > Asumido**
