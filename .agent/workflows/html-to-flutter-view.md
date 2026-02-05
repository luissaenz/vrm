---
description: Proceso para generar vistas Flutter desde diseños HTML
---

# Workflow: Generación de Vistas Flutter desde HTML

Este workflow define el proceso paso a paso para convertir diseños HTML en vistas Flutter, asegurando alineación con las directrices gráficas del proyecto.

---

## Paso 1: Análisis de Elementos de la Interfaz

**Objetivo**: Identificar y catalogar todos los elementos visuales del diseño HTML.

**Acciones**:
- [ ] Revisar el código HTML proporcionado
- [ ] Listar todos los elementos de UI:
  - Botones y sus variantes (primario, secundario, etc.)
  - Campos de texto (input, textarea)
  - Labels y textos descriptivos
  - Iconos y elementos gráficos
  - Contenedores y layout (cards, sections, etc.)
  - Estados visuales (hover, active, disabled)
- [ ] Identificar elementos interactivos vs estáticos
- [ ] Documentar estructura jerárquica (padre-hijo)

**Salida**: Lista completa de componentes identificados

---

## Paso 2: Verificación de Directrices Gráficas

**Objetivo**: Asegurar que todos los elementos se alinean con las directrices visuales del proyecto VRM.

**Directrices Gráficas del Proyecto VRM**:

### Colores
```dart
// Paleta principal
Color primary = Color(0xFF6C63FF);      // Violeta principal
Color secondary = Color(0xFF4CAF50);    // Verde acento
Color background = Color(0xFF0A0E27);   // Azul oscuro
Color surface = Color(0xFF1A1F3A);      // Card background
Color error = Color(0xFFFF5252);        // Rojo error
Color textPrimary = Color(0xFFFFFFFF);  // Blanco
Color textSecondary = Color(0xFFB0B3C1); // Gris claro
```

### Tipografía
```dart
// Familia: 'Inter' o sistema default
TextStyle heading1 = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
TextStyle heading2 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
TextStyle heading3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
TextStyle body = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
TextStyle caption = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
TextStyle label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
```

### Espaciado
```dart
// Padding estándar
EdgeInsets padding = EdgeInsets.all(20.0);  // Padding general
double spacing8 = 8.0;   // Espaciado pequeño
double spacing16 = 16.0; // Espaciado medio
double spacing24 = 24.0; // Espaciado grande
```

### Bordes
```dart
// Border radius
BorderRadius small = BorderRadius.circular(8.0);
BorderRadius medium = BorderRadius.circular(16.0);
BorderRadius large = BorderRadius.circular(24.0);
BorderRadius pill = BorderRadius.circular(999.0); // Botones pill
```

### Sombras y Elevación
```dart
// Box shadows
BoxShadow elevation2 = BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 8,
  offset: Offset(0, 2),
);
BoxShadow elevation8 = BoxShadow(
  color: Colors.black.withOpacity(0.2),
  blurRadius: 16,
  offset: Offset(0, 8),
);
```

### Componentes Estándar

#### Botones
```dart
// Botón primario
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 0,
  ),
  onPressed: () {},
  child: Text('Label', style: TextStyle(fontSize: 16)),
);

// Botón pill (centrado)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 64),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
  ),
);
```

#### Cards
```dart
Container(
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [elevation2],
  ),
  padding: EdgeInsets.all(20),
  child: ...,
);
```

#### Inputs
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    hintText: 'Placeholder...',
    hintStyle: TextStyle(color: textSecondary),
  ),
);
```

**Verificación**:
- [ ] Colores coinciden con la paleta del proyecto
- [ ] Tipografía usa los estilos definidos
- [ ] Espaciado es consistente (múltiplos de 8)
- [ ] Border radius sigue los estándares
- [ ] Componentes reutilizan los widgets estándar

---

## Paso 3: Preguntas de Aclaración

**Objetivo**: Resolver ambigüedades antes de implementar.

**Si alguno de los siguientes puntos no está claro, PREGUNTAR AL USUARIO**:

### Sobre Diseño:
- [ ] ¿El diseño HTML incluye estados (hover, active, disabled)?
- [ ] ¿Hay variantes del mismo componente (diferentes tamaños, colores)?
- [ ] ¿Existe una versión responsive? ¿Cómo debe adaptarse en diferentes pantallas?

### Sobre Funcionalidad:
- [ ] ¿Qué acciones deben ejecutarse al interactuar con elementos?
- [ ] ¿Hay validaciones de formulario?
- [ ] ¿Se requiere navegación a otras pantallas?

### Sobre Datos:
- [ ] ¿Los datos son estáticos o vienen de una fuente externa?
- [ ] ¿Se integra con el pipeline existente (InputSchema, ScriptBundle)?
- [ ] ¿Requiere persistencia (ProjectRepository)?

### Sobre Estado:
- [ ] ¿Qué estados maneja la vista (loading, error, success)?
- [ ] ¿Es un StatefulWidget o StatelessWidget?
- [ ] ¿Usa algún state management (Provider, Riverpod, etc.)?

**Formato de Pregunta**:
```
Necesito aclaraciones sobre el diseño HTML:

1. [Categoría]: [Pregunta específica]
2. [Categoría]: [Pregunta específica]
...

Por favor confirma o provee los detalles necesarios.
```

---

## Paso 4: Iteración (si es necesario)

**Objetivo**: Refinar el análisis con las aclaraciones del usuario.

**Acciones**:
- [ ] Incorporar feedback del usuario
- [ ] Actualizar lista de elementos (Paso 1)
- [ ] Re-verificar directrices (Paso 2)
- [ ] Volver a Paso 3 si quedan dudas

**Criterio de Salida**: Todas las preguntas resueltas, diseño claro y alineado.

---

## Paso 5: Generación de la Vista

**Objetivo**: Implementar la vista Flutter siguiendo las mejores prácticas.

### 5.1. Estructura del Archivo

```dart
import 'package:flutter/material.dart';
// Imports adicionales según necesidad

class [NombreVista]Page extends StatelessWidget {
  const [NombreVista]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(...);
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection1(),
          const SizedBox(height: 24),
          _buildSection2(),
          // ...
        ],
      ),
    );
  }

  Widget _buildSection1() {
    return ...;
  }
}
```

### 5.2. Checklist de Implementación

**Estructura**:
- [ ] Separar en métodos privados (`_buildX()`) para cada sección
- [ ] Usar `const` para widgets que no cambian
- [ ] Evitar nesting profundo (max 3-4 niveles)

**Estilos**:
- [ ] NO usar valores hard-coded, usar constantes
- [ ] Aplicar directrices gráficas (colores, tipografía, espaciado)
- [ ] Usar `Theme.of(context)` cuando corresponda

**Responsividad**:
- [ ] Usar `MediaQuery` para adaptar a diferentes tamaños
- [ ] Considerar orientación (portrait/landscape)
- [ ] Probar en diferentes dispositivos

**Accesibilidad**:
- [ ] Agregar `Semantics` para screen readers
- [ ] Contraste de colores suficiente
- [ ] Touch targets mínimo 48x48 dp

**Performance**:
- [ ] Evitar reconstrucciones innecesarias
- [ ] Usar `ListView.builder` para listas largas
- [ ] Lazy loading de imágenes si aplica

### 5.3. Ejemplo Completo

```dart
import 'package:flutter/material.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Título'),
        backgroundColor: const Color(0xFF1A1F3A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Encabezado',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: () {
          // Acción
        },
        child: const Text(
          'Continuar',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
```

---

## Salida Final

**Entregables**:
1. Archivo `.dart` con la vista implementada
2. Captura de pantalla o demo (si aplica)
3. Notas sobre decisiones de implementación
4. Tests básicos (si es una vista compleja)

**Criterios de Éxito**:
- ✅ Vista funcional e interactiva
- ✅ 100% alineada con directrices gráficas
- ✅ Código limpio y mantenible
- ✅ Sin warnings de lint
- ✅ Probada en al menos un dispositivo/emulador

---

## Notas Adicionales

- **Reutilización**: Si se identifica un patrón repetitivo, extraer a un widget reutilizable en `lib/core/widgets/`
- **Temas**: Considerar crear un `AppTheme` si hay muchas vistas con estilos similares
- **Navegación**: Usar rutas nombradas si la app crece en complejidad
