# VRM App - Sistema de Diseño

Este documento define los lineamientos estéticos y de diseño para toda la aplicación VRM. Todos los desarrolladores deben seguir estas guías al crear nuevas pantallas o componentes.

---

## 🎨 Paleta de Colores

### Colores Principales

| Color | Código | Uso |
|-------|--------|-----|
| **Forest** (Verde Institucional) | `#2D423F` | Color primario, botones principales, iconos activos |
| **Forest Vibrant** | `#219653` | Acentos y estados de éxito |
| **Forest Dark** | `#162210` | Botones de acción importantes, estados hover |
| **Accent Orange** | `#F97316` | Color secundario, llamadas a la acción |

### Colores de Fondo

| Color | Código | Uso |
|-------|--------|-----|
| **Background Light** | `#F8F9F8` | Fondo principal de la aplicación |
| **Surface** | `#FFFFFF` | Tarjetas, contenedores elevados |
| **Earth Light** | `#EAE7E2` | Fondos alternativos |

### Colores de Texto

| Color | Código | Uso |
|-------|--------|-----|
| **Text Main** | `#0F172A` (Slate 900) | Texto principal, títulos |
| **Text Muted** | `#64748B` (Slate 500) | Texto secundario, subtítulos |
| **Green Grey** | `#94A3B8` (Slate 400) | Texto deshabilitado, estados inactivos |

### Colores de Borde

| Color | Código | Uso |
|-------|--------|-----|
| **Border** / **Earth Border** | `#E5E7EB` | Bordes de tarjetas y contenedores |

### Implementación

```dart
import 'package:vrm_app/core/theme.dart';

// Usar siempre las constantes del tema
color: AppTheme.forest,
color: AppTheme.textMain,
color: AppTheme.backgroundLight,
```

> [!IMPORTANT]
> **NUNCA** usar colores hardcodeados como `Color(0xFF2D423F)` directamente en las páginas. Siempre usar `AppTheme.forest` y las constantes definidas en [theme.dart](file:///d:/Develop/Personal/vrm/lib/core/theme.dart).

---

## 📝 Tipografía

### Jerarquía de Texto

| Estilo | Tamaño | Peso | Color | Uso |
|--------|--------|------|-------|-----|
| **Display Large** | 32px | 800 (ExtraBold) | Text Main | Títulos principales de página |
| **Headline Large** | 24px | 800 (ExtraBold) | Text Main | Títulos de sección importantes |
| **Headline Medium** | 18px | 700 (Bold) | Text Main | Encabezados de sección |
| **Body Large** | 16px | 600 (SemiBold) | Text Main | Texto destacado |
| **Body Medium** | 14px | 500 (Medium) | Text Muted | Texto de cuerpo, subtítulos |
| **Body Small** | 12px | 500 (Medium) | Text Muted | Texto secundario |
| **Label Large** | 11px | 700 (Bold) | Text Muted | Etiquetas, badges en mayúsculas |
| **Label Small** | 10px | 700 (Bold) | Text Muted | Etiquetas pequeñas en mayúsculas |
| **Label Extra Small** | 9px | 700 (Bold) | Text Muted | Etiquetas muy pequeñas |

### Características Especiales

- **Letter Spacing**: 
  - Títulos grandes: `-1.0` a `-0.5`
  - Etiquetas en mayúsculas: `0.5` a `2.5`
  - Texto normal: `0`

- **Line Height**:
  - Títulos: `1.0` a `1.3`
  - Texto de cuerpo: `1.5`

### Fuente

- **Principal**: `Segoe UI` (sistema)
- **Alternativa**: `Space Grotesk` (solo para pantalla de grabación)

### Implementación

```dart
// Títulos principales de página (ej: "¿Listo para crear?")
Text(
  'Título Principal',
  style: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppTheme.textMain,
    letterSpacing: -1,
  ),
)

// Encabezados de sección (ej: "Proyectos Recientes")
Text(
  'Sección',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppTheme.textMain,
  ),
)

// Subtítulos y texto secundario
Text(
  'Subtítulo',
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.textMuted,
  ),
)

// Etiquetas en mayúsculas (ej: "FRAGMENTOS", "GRABANDO")
Text(
  'ETIQUETA'.toUpperCase(),
  style: const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppTheme.textMuted,
    letterSpacing: 1.2,
  ),
)
```

---

## 📏 Espaciado

### Sistema de Espaciado

Usar múltiplos de **4px** para mantener consistencia:

| Tamaño | Valor | Uso |
|--------|-------|-----|
| **XXS** | 2px | Separación mínima entre elementos muy relacionados |
| **XS** | 4px | Separación entre elementos relacionados |
| **S** | 8px | Espaciado pequeño |
| **M** | 12px | Espaciado medio entre elementos |
| **L** | 16px | Espaciado estándar entre componentes |
| **XL** | 20px | Espaciado grande entre secciones |
| **XXL** | 24px | Padding de contenedores principales |
| **XXXL** | 32px | Separación entre secciones importantes |
| **XXXXL** | 40px | Separación máxima entre secciones |

### Padding de Contenedores

```dart
// Padding horizontal estándar de página
padding: const EdgeInsets.symmetric(horizontal: 24)

// Padding de tarjetas y contenedores
padding: const EdgeInsets.all(20)

// Padding de botones grandes
padding: const EdgeInsets.symmetric(horizontal: 24)

// Padding de footer/bottom navigation
padding: const EdgeInsets.fromLTRB(32, 16, 32, 40)
```

### Márgenes entre Secciones

```dart
const SizedBox(height: 16)  // Entre elementos de una sección
const SizedBox(height: 20)  // Entre subsecciones
const SizedBox(height: 32)  // Entre secciones principales
const SizedBox(height: 40)  // Entre secciones muy separadas
```

---

## 🔘 Botones

### Botón Principal (Primary Button)

**Uso**: Acción principal de la pantalla (ej: "Dividir en Fragmentos", "Grabar")

```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.forestDark,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 8,
    shadowColor: AppTheme.forest.withValues(alpha: 0.3),
  ),
  child: Text(
    'ACCIÓN PRINCIPAL',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),
)
```

**Características**:
- Color: `AppTheme.forestDark`
- Altura mínima: `56px` (full-width), `64px` (píldora/centrado)
- Border radius: `16px` (full-width), `999px` (píldora/centrado)
- Texto: `16px`, en mayúsculas, bold, letter-spacing `0.5`
- Elevation: `8`
- Shadow: `shadowColor: AppTheme.forest.withValues(alpha: 0.3)`.

#### Acción de Sticky Footer (Pegado abajo)
- **Fondo**: Gradiente de `AppTheme.backgroundLight` a transparente.
- **Padding**: `EdgeInsets.fromLTRB(20, 16, 20, 40)`.
- **Botón**: `minimumSize: const Size(double.infinity, 56)`.

### Botón de Acción (Action Card)

**Uso**: Tarjetas de acción principales (ej: "Nuevo Proyecto", "Perfil Influencer")

```dart
VRMActionCard(
  title: 'Título de Acción',
  subtitle: 'Descripción breve',
  icon: Icons.keyboard_voice,
  actionIcon: Icons.add, // o Icons.arrow_forward_rounded
  onTap: () {},
)
```

**Características**:
- Color de fondo: `AppTheme.forest`
- Altura: `84px`
- Border radius: `99px` (completamente redondeado)
- Texto del título: `18px`, bold, blanco
- Texto del subtítulo: `11px`, medium, blanco con 80% opacidad
- Icono de acción: círculo de `44px` con fondo blanco al 10%
- Shadow: `blurRadius: 24`, `offset: Offset(0, 12)`

### Botón Circular (Icon Button)

**Uso**: Botones de navegación, configuración, acciones secundarias

```dart
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(color: AppTheme.earthBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: IconButton(
    icon: Icon(icon, size: 20, color: AppTheme.forest),
    onPressed: onTap,
    padding: EdgeInsets.zero,
  ),
)
```

**Características**:
- Tamaño: `40px x 40px`
- Color de fondo: blanco
- Border: `AppTheme.earthBorder`
- Icono: `20px`, color `AppTheme.forest`
- Shadow sutil

### Botón de Control (Control Button)

**Uso**: Botones de control en footers (ej: "Pausar", "Regresar")

```dart
// Ver implementación en preparation_page.dart líneas 753-807
// Estados: activo (forest) vs inactivo (greenGrey)
```

**Características**:
- Tamaño: `56px x 56px`
- Forma: círculo
- Color activo: `AppTheme.forest`
- Color inactivo: `AppTheme.greenGrey` (Slate 400)
- Etiqueta debajo en mayúsculas, `9px`, bold

---

## 🎴 Tarjetas y Contenedores

### Tarjeta de Estadística (Stat Card)

```dart
VRMStatCard(
  value: '42',
  label: 'Fragmentos',
  icon: Icons.mic,
  color: AppTheme.forest,
)
```

**Características**:
- Padding: `20px`
- Border radius: `24px`
- Border: `AppTheme.earthBorder`
- Fondo: blanco
- Shadow: `blurRadius: 10`, `offset: Offset(0, 4)`, alpha `0.05`
- Icono: círculo de `36px` con fondo del color al 5%
- Valor: `24px`, bold, `AppTheme.textMain`
- Etiqueta: `11px`, bold, mayúsculas, `AppTheme.textMuted`

### Tarjeta de Proyecto (Project Card)

```dart
VRMProjectCard(
  title: 'Título del Proyecto',
  time: 'Editado hace 2 horas',
  progress: 0.3,
  statusText: '3/10 fragmentos',
  badgeText: 'Borrador',
  progressLabel: 'Progreso',
  icon: Icons.smartphone_rounded,
  badgeBg: const Color(0xFFFFF7ED),
  badgeTextCol: const Color(0xFFC2410C),
)
```

**Características**:
- Border radius: `20px`
- Padding: `20px`
- Fondo: blanco
- Border: `AppTheme.earthBorder`
- Badge: colores personalizados según estado
- Barra de progreso: `AppTheme.forest`

### Encabezado de Sección (Section Header)

```dart
VRMSectionHeader(
  title: 'Título de Sección',
  actionLabel: 'Ver todo', // opcional
  onActionPressed: () {}, // opcional
  icon: Icons.calendar_month, // opcional
)
```

**Características**:
- Título: `18px`, bold, `AppTheme.textMain`
- Action label: `14px`, bold, `AppTheme.forest`
- Icono opcional: círculo de `36px`, borde `AppTheme.earthBorder`

---

## 🎯 Componentes Especiales

### Indicador de Voz

**Activo**:
```dart
Row(
  children: [
    Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.forest,
        shape: BoxShape.circle,
      ),
    ),
    const SizedBox(width: 6),
    Text(
      'ESCUCHANDO',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppTheme.forest,
        letterSpacing: 1.2,
      ),
    ),
  ],
)
```

**Inactivo**: Usar `Colors.grey[400]` en lugar de `AppTheme.forest`

### Barra de Progreso

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(999),
  child: LinearProgressIndicator(
    value: 0.2,
    backgroundColor: AppTheme.forest.withValues(alpha: 0.1),
    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forest),
    minHeight: 4,
  ),
)
```

### Badge de Estado

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppTheme.forest.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: AppTheme.forest.withValues(alpha: 0.1),
    ),
  ),
  child: Text(
    'ESTADO'.toUpperCase(),
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: AppTheme.forest.withValues(alpha: 0.6),
      letterSpacing: 1.0,
    ),
  ),
)
```

---

## 🎭 Efectos y Sombras

### Sombras de Tarjetas

```dart
// Sombra estándar de tarjeta
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
]

// Sombra de botón elevado
boxShadow: [
  BoxShadow(
    color: AppTheme.forest.withValues(alpha: 0.15),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
]

// Sombra sutil
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.02),
    blurRadius: 4,
    offset: const Offset(0, 2),
  ),
]
```

### Blur (Glassmorphism)

```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      color: Colors.white.withValues(alpha: 0.8),
      // contenido
    ),
  ),
)
```

### Border Radius

| Componente | Valor |
|------------|-------|
| Botones principales full-width | `16px` |
| Botones principales centrados | `999px` (píldora) |
| Tarjetas | `20px` - `24px` |
| Action Cards | `99px` (completamente redondeado) |
| Badges y pills | `999px` (completamente redondeado) |
| Contenedores grandes | `40px` |

---

## 📱 Layouts

### Layout de Formularios / Creación
- **Padding Horizontal**: 20px.
- **Padding Vertical**: 24px.
- **Scroll**: Usar `BouncingScrollPhysics()`.
- **Estructura**: `SafeArea` -> `Column` (Header + Expanded Scrollable Content + Bottom Action).

### Estructura de Página Estándar

```dart
Scaffold(
  backgroundColor: AppTheme.backgroundLight,
  body: SafeArea(
    child: Column(
      children: [
        // Header (si aplica)
        VRMHeader(title: 'Título', onBack: () {}),
        
        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenido
              ],
            ),
          ),
        ),
      ],
    ),
  ),
  // Bottom navigation o footer (si aplica)
  bottomNavigationBar: _buildBottomNav(),
)
```

### Ancho Máximo de Contenido

Para pantallas grandes, limitar el ancho:

```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 450),
    child: // contenido
  ),
)
```

### Bottom Navigation

```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: AppTheme.earthBorder, width: 1),
        ),
      ),
      child: // contenido de navegación
    ),
  ),
)
```

---

## ✅ Checklist para Nuevas Pantallas

Al crear una nueva pantalla, verificar:

- [ ] Usa `AppTheme.backgroundLight` como fondo del Scaffold
- [ ] Todos los colores usan constantes de `AppTheme`
- [ ] Los tamaños de fuente siguen la jerarquía definida
- [ ] El espaciado usa múltiplos de 4px
- [ ] Los botones principales tienen altura mínima de 56px
- [ ] Las tarjetas tienen border radius de 20-24px
- [ ] Las sombras usan valores alpha consistentes (0.02, 0.05, 0.1)
- [ ] Los textos en mayúsculas usan `toUpperCase()` y letter-spacing
- [ ] El padding horizontal de página es 24px
- [ ] Usa `BouncingScrollPhysics()` para scroll
- [ ] Los iconos activos usan `AppTheme.forest`
- [ ] Los iconos inactivos usan `Colors.grey[400]` o `AppTheme.textMuted`

---

## 📚 Widgets Compartidos

Siempre usar los widgets compartidos cuando sea posible:

- `VRMActionCard` - Tarjetas de acción principales
- `VRMStatCard` - Tarjetas de estadísticas
- `VRMProjectCard` - Tarjetas de proyectos
- `VRMSectionHeader` - Encabezados de sección
- `VRMHeader` - Header de página con botón de regreso
- `VRMStepIndicator` - Indicador de pasos
- `VRMScriptEditor` - Editor de guion
- `VRMCalendarDay` - Día del calendario

### Secciones y Encabezados de Paso (VRMStepIndicator)
- **Círculo de Número**: 32x32px, `AppTheme.forest`, Texto 14px bold blanco.
- **Título de Paso**: 11px, Bold, `AppTheme.earth`, Letter Spacing: 1.1, Uppercase.
- **Espaciado**: 12px entre número y título, 20px bajo el indicador.

### Editor de Guion (VRMScriptEditor)
- **Contenedor**:
  - Color: `AppTheme.surfaceColor`.
  - Border Radius: 20px.
  - Borde: 1px, `Colors.grey.withValues(alpha: 0.1)`.
  - Sombra: `blurRadius: 20`, `offset: (0, 4)`, alpha: 0.05.
- **Tipografía**:
  - Texto: 16px, `height: 1.6`, Slate 700.
  - Hint: 16px, Slate 300.
- **Barra de Acciones**:
  - Borde Superior: 1px, alpha 0.05.
  - Botones de Acción: 12px bold, 0.5 letter spacing.

### Etiquetas de Estadísticas
- **Estilo**: 11px, Bold (w700), `AppTheme.textMuted`, Letter Spacing: 0.5, Uppercase.
- **Valores Destacados**: Usar `AppTheme.forest` dentro de un `TextSpan`.
- **Iconos Auxiliares**: 14px, `AppTheme.textMuted`.

**Ubicación**: `lib/shared/widgets/`

---

## 🔗 Referencias

- [theme.dart](file:///d:/Develop/Personal/vrm/lib/core/theme.dart) - Definición de colores y tema
- [dashboard_page.dart](file:///d:/Develop/Personal/vrm/lib/features/dashboard/dashboard_page.dart) - Página de referencia principal
- [Widgets compartidos](file:///d:/Develop/Personal/vrm/lib/shared/widgets/) - Componentes reutilizables

---

**Última actualización**: 2026-01-28
**Versión**: 1.0
