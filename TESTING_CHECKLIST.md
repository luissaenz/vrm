# Lista de Verificación para Pruebas Pre-Publicación

## Áreas Críticas de Prueba para Lanzamiento MVP

### 🚨 Niveles de Prioridad
- **P0**: Debe corregirse - Causará rechazo en la tienda o cierre de la app
- **P1**: Debería corregirse - Problema mayor de experiencia de usuario
- **P2**: Bueno corregir - Mejora/pulido menor

---

## 1. Pruebas de Funcionalidad Principal

### Flujo de Incorporación (Onboarding)
- [ ] El onboarding se muestra correctamente (P0)
- [ ] Todas las pantallas de onboarding son accesibles (P0)
- [ ] Se puede completar el onboarding sin errores (P0)
- [ ] Se puede omitir el onboarding (si aplica) (P1)
- [ ] La finalización del onboarding navega al dashboard (P0)
- [ ] El texto del onboarding no se corta en ningún tamaño de pantalla (P1)
- [ ] El onboarding funciona tanto en inglés como en español (P1)

### Dashboard (Panel Principal)
- [ ] El dashboard se carga sin errores (P0)
- [ ] Todos los elementos de navegación funcionan (P0)
- [ ] Todas las funciones son accesibles desde el dashboard (P0)
- [ ] El dashboard se muestra correctamente en diferentes tamaños de pantalla (P1)
- [ ] No hay estados placeholder/vacíos visibles (P0)
- [ ] Las acciones rápidas funcionan como se espera (P0)
- [ ] Al tocar el avatar navega al perfil de cuenta (P0)
- [ ] Al tocar el ícono de configuración navega a ajustes (P0)
- [ ] La sección de estadísticas NO está visible (eliminada) (P0)

### Funciones de Grabación/Cámara
- [ ] El permiso de cámara se solicita correctamente (P0)
- [ ] La cámara se abre sin errores (P0)
- [ ] Se puede iniciar/detener la grabación (P0)
- [ ] El video se guarda exitosamente (P0)
- [ ] La cámara funciona en frontal y trasera (si aplica) (P0)
- [ ] Maneja la denegación de permiso de cámara con gracia (P1)
- [ ] Funciona en diferentes versiones de Android/iOS (P1)
- [ ] La página de fin de grabación se muestra sin métricas de rendimiento (P0)

### Asistente de IA
- [ ] El permiso de micrófono se solicita (P0)
- [ ] El reconocimiento de voz funciona (P0)
- [ ] El asistente responde a los comandos (P0)
- [ ] Maneja la conversión de voz a texto correctamente (P0)
- [ ] Tiene fallback elegante si se deniega el permiso (P1)
- [ ] La conversión de texto a voz funciona (si aplica) (P1)

### Gestión de Proyectos
- [ ] Se puede crear un nuevo proyecto (P0)
- [ ] Se pueden ver proyectos existentes (P0)
- [ ] Se puede eliminar proyecto (si aplica) (P1)
- [ ] Los datos del proyecto persisten al reiniciar la app (P0)
- [ ] La gestión de fragmentos funciona (P0)

### Perfil de Cuenta
- [ ] La página de perfil se carga al tocar el avatar (P0)
- [ ] La información de la cuenta se muestra correctamente (P0)
- [ ] La navegación a ajustes funciona desde el perfil (P0)
- [ ] El diálogo de borrar datos se muestra y funciona (P0)
- [ ] El diálogo de cerrar sesión se muestra y funciona (P0)
- [ ] Los elementos de UI del perfil se renderizan correctamente (P1)

### Menú de Configuración
- [ ] La página de ajustes se carga desde el ícono de configuración (P0)
- [ ] El selector de tema se muestra y funciona (P1)
- [ ] Los ajustes de grabación son navegables (P0)
- [ ] Los ajustes del teleprompter son navegables (P0)
- [ ] Los ajustes de almacenamiento son navegables (P0)
- [ ] La sección "Acerca de" se muestra correctamente (P0)
- [ ] Todos los tiles de ajustes son pulsables (P0)

### Integración de Redes Sociales
- [ ] La UI de conexión de cuentas sociales funciona (P1)
- [ ] Los flujos de autenticación funcionan (si está implementado) (P0)
- [ ] Maneja fallos de conexión con gracia (P1)

---

## 2. Pruebas de Experiencia de Usuario

### Navegación
- [ ] El botón atrás funciona correctamente (P0)
- [ ] El deep linking funciona (si está implementado) (P2)
- [ ] No hay bucles de navegación (P0)
- [ ] Se puede navegar a todas las pantallas y volver (P0)
- [ ] Los elementos de la barra de pestañas/navegación funcionan (P0)

### Pulido de UI/UX
- [ ] No hay desbordamiento o recorte de texto (P1)
- [ ] No hay elementos superpuestos (P1)
- [ ] Los estados de carga se muestran durante operaciones asíncronas (P1)
- [ ] Los mensajes de error son amigables para el usuario (P1)
- [ ] Los botones tienen retroalimentación adecuada (visual/táctil) (P1)
- [ ] El teclado no cubre los campos de entrada (P1)
- [ ] No hay elementos de UI cortados en pantallas pequeñas (P1)

### Gestión de Estados
- [ ] El estado de la app persiste al minimizar/reanudar (P0)
- [ ] La app maneja transiciones fondo/primer plano (P0)
- [ ] No hay pérdida de datos al rotar la pantalla (si no está bloqueado) (P1)
- [ ] Los spinners de carga aparecen durante las operaciones (P1)
- [ ] Retroalimentación de éxito/error para acciones del usuario (P1)

### Estados Vacíos
- [ ] Los estados vacíos tienen mensajes útiles (P1)
- [ ] No hay pantallas en blanco cuando no existen datos (P0)
- [ ] Llamadas a la acción en estados vacíos (P2)

---

## 3. Pruebas de Rendimiento

### Lanzamiento de la App
- [ ] La app se lanza en menos de 5 segundos (P1)
- [ ] No hay pantalla blanca/negra al inicio (P1)
- [ ] La pantalla de splash hace transición suave (P2)

### Rendimiento en Ejecución
- [ ] No hay retrasos notorios al navegar (P1)
- [ ] La cámara se abre rápidamente (P1)
- [ ] Los videos se reproducen suavemente (P1)
- [ ] No hay errores ANR (Aplicación No Responde) (P0)
- [ ] El uso de memoria es razonable (P2)

### Rendimiento de Red
- [ ] Las llamadas a API se completan exitosamente (P0)
- [ ] El manejo de timeouts funciona (P1)
- [ ] El modo sin conexión funciona (si aplica) (P1)
- [ ] Los errores de red se muestran al usuario (P1)

---

## 4. Pruebas de Compatibilidad de Dispositivos

### Android (Probar en al menos 2 dispositivos)
- [ ] Android 8.0 (API 26) - si es compatible (P1)
- [ ] Android 10 (API 29) (P1)
- [ ] Android 12 (API 31) (P0)
- [ ] Android 13+ (API 33+) (P0)
- [ ] Diferentes tamaños de pantalla (teléfono/tableta) (P1)
- [ ] Diferentes fabricantes (Samsung, Pixel, etc.) (P2)

### iOS (Probar en al menos 2 dispositivos)
- [ ] iPhone SE (pantalla más pequeña) (P1)
- [ ] iPhone 12/13/14/15 (estándar) (P0)
- [ ] iPhone Pro Max (pantalla más grande) (P1)
- [ ] iOS 15+ (P0)
- [ ] iOS 16+ (P0)
- [ ] iOS 17+ (P0)

---

## 5. Pruebas de Permisos

### Permisos de Android
- [ ] Permiso de cámara solicitado cuando es necesario (P0)
- [ ] Permiso de micrófono solicitado cuando es necesario (P0)
- [ ] Permiso de almacenamiento solicitado cuando es necesario (P0)
- [ ] Se muestra la justificación del permiso (si es requerido) (P2)
- [ ] La app funciona con permisos denegados (con gracia) (P1)
- [ ] Se pueden solicitar permisos nuevamente después de la denegación (P1)

### Permisos de iOS
- [ ] Todos los mensajes de permiso tienen descripciones claras (P0)
- [ ] Descripción de uso de cámara en Info.plist (P0)
- [ ] Descripción de uso de micrófono en Info.plist (P0)
- [ ] Descripción de uso de biblioteca de fotos en Info.plist (P0)
- [ ] Descripción de reconocimiento de voz (si se usa) (P0)

---

## 6. Pruebas de Localización

### Inglés (en)
- [ ] Todo el texto en inglés (P0)
- [ ] No hay placeholders de traducción visibles (P0)
- [ ] Formato adecuado de fecha/números (P1)

### Español (es)
- [ ] Todo el texto en español (P0)
- [ ] No hay placeholders de traducción visibles (P0)
- [ ] El texto más largo no rompe la UI (P1)
- [ ] Formato adecuado de fecha/números (P1)

---

## 7. Casos Extremos y Manejo de Errores

### Problemas de Red
- [ ] Sin conexión a internet muestra mensaje adecuado (P1)
- [ ] Fallos de API muestran error amigable (P1)
- [ ] Mecanismo de reintento disponible (P2)

### Problemas de Almacenamiento
- [ ] Espacio de almacenamiento bajo manejado con gracia (P1)
- [ ] Archivos corruptos manejados con gracia (P1)
- [ ] Errores de base de datos no cierran la app (P0)

### Entrada del Usuario
- [ ] Entradas inválidas son capturadas y mostradas (P1)
- [ ] La validación de formularios funciona (P0)
- [ ] Caracteres especiales no rompen nada (P0)
- [ ] Entradas muy largas manejadas correctamente (P1)

### Interrupciones
- [ ] Llamada entrante durante la grabación (P1)
- [ ] La app pasa a segundo plano durante la operación (P1)
- [ ] Advertencias de batería baja (P2)
- [ ] Las alertas del sistema no rompen la app (P1)

---

## 8. Pruebas de Seguridad

### Protección de Datos
- [ ] No hay datos sensibles en los logs (P0)
- [ ] No hay claves/secrets de API hardcodeados (P0)
- [ ] Los datos del usuario se almacenan de forma segura (P0)
- [ ] Se usa HTTPS para todas las llamadas de red (P0)
- [ ] No hay datos sensibles en las URLs (P0)

### Autenticación (si aplica)
- [ ] La gestión de sesiones funciona (P0)
- [ ] El cierre de sesión borra datos sensibles (P0)
- [ ] No se puede acceder a pantallas protegidas sin auth (P0)

---

## 9. Pruebas de Cumplimiento con Tiendas de Apps

### Requisitos de Google Play Store
- [ ] No hay logging de debug en la build de release (P0)
- [ ] No hay anuncios de prueba (si se usa AdMob) (P0)
- [ ] La app no se cierra al inicio (P0)
- [ ] Apunta al nivel de API 33+ (Android 13+) (P0)
- [ ] Usa formato Android App Bundle (P0)
- [ ] Tamaño de la app menor a 150MB (P0)
- [ ] No hay bugs obvios visibles (P0)

### Requisitos de Apple App Store
- [ ] No hay contenido placeholder (P0)
- [ ] No hay datos de prueba visibles (P0)
- [ ] La app no se cierra (P0)
- [ ] Todas las funciones funcionan como se describe (P0)
- [ ] Sigue las Directrices de Interfaz Humana de iOS (P1)
- [ ] Política de privacidad accesible (P0)
- [ ] Solicitudes de permiso adecuadas (P0)
- [ ] No hay funciones beta/expiradas (P0)

### Razones Comunes de Rechazo
- [ ] La app no es un simple envoltorio web (P0)
- [ ] Proporciona valor único (no funcionalidad duplicada) (P0)
- [ ] No hay contenido spam o inapropiado (P0)
- [ ] La descripción de la app es precisa y coincide con la funcionalidad (P0)
- [ ] Las capturas de pantalla representan la app real (P0)

---

## 10. Verificaciones Finales de Calidad

### Calidad del Código
```bash
# Ejecuta estos comandos y corrige todos los problemas
flutter analyze
flutter test
```

- [ ] No hay errores ni advertencias del analizador (P0)
- [ ] Todas las pruebas pasan (P0)
- [ ] No hay uso de API obsoletas (P1)
- [ ] No hay importaciones/variables sin usar (P2)

### Pruebas en Modo Release
- [ ] Probar en modo release: `flutter run --release`
- [ ] No hay errores de consola en modo release (P0)
- [ ] Todas las funciones funcionan en modo release (P0)
- [ ] El rendimiento es aceptable en modo release (P1)

### Prueba de Build Limpia
```bash
flutter clean
flutter pub get
flutter run --release
```

- [ ] La app se compila exitosamente desde estado limpio (P0)
- [ ] No hay errores ni advertencias de compilación (P0)
- [ ] La app se ejecuta después de una compilación limpia (P0)

### Inspección Visual
- [ ] El ícono de la app se muestra correctamente (P0)
- [ ] La pantalla de splash se ve bien (P1)
- [ ] El tema oscuro funciona (si está implementado) (P1)
- [ ] La tipografía es legible (P1)
- [ ] El contraste de color es suficiente (P1)
- [ ] No hay fallos visuales en ninguna pantalla (P1)

---

## 11. Pruebas Beta (Altamente Recomendado)

### Pruebas Internas
- [ ] Conseguir 5-10 personas para probar la app (P1)
- [ ] Recopilar comentarios sobre usabilidad (P1)
- [ ] Corregir cualquier problema crítico encontrado (P0)

### Pruebas Internas de Google Play
- [ ] Subir AAB a la pista de pruebas internas (P1)
- [ ] Agregar correos electrónicos de probadores (P1)
- [ ] Recopilar comentarios (P1)

### TestFlight de Apple
- [ ] Subir a TestFlight (P1)
- [ ] Agregar probadores internos (P1)
- [ ] Recopilar comentarios (P1)

---

## Plantilla de Informe de Pruebas

```
FECHA DE PRUEBA: [Fecha]
PROBADOR: [Nombre]
DISPOSITIVO: [Modelo del dispositivo, versión del SO]
VERSIÓN DE BUILD: [1.0.0+1]

PROBLEMAS CRÍTICOS (P0):
- [Descripción del problema]
- [Pasos para reproducir]
- [Comportamiento esperado vs real]

PROBLEMAS MAYORES (P1):
- [Descripción del problema]

PROBLEMAS MENORES (P2):
- [Descripción del problema]

ESTADO GENERAL: [Listo para release / Necesita correcciones]
```

---

## Script de Prueba Rápida (Verificaciones Automatizadas)

Crea una prueba simple para verificar los flujos principales:

```dart
// test/smoke_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La app se carga y muestra onboarding o dashboard', (tester) async {
    await tester.pumpWidget(const VRMApp(startWithOnboarding: true));
    await tester.pumpAndSettle();

    // Debería mostrar onboarding o dashboard
    expect(
      find.byType(OnboardingFlow).evaluate().isNotEmpty ||
      find.byType(DashboardPage).evaluate().isNotEmpty,
      true,
    );
  });
}
```

Ejecutar con: `flutter test`

---

## Resumen de Lista de Verificación Pre-Vuelo

**DEBE APROBAR ANTES DE PUBLICAR:**

✅ Todas las pruebas P0 pasan
✅ La app se compila sin errores: `flutter build appbundle --release`
✅ La app se ejecuta en modo release sin cierres
✅ No hay bugs obvios en los flujos principales
✅ La política de privacidad es accesible
✅ Los íconos de la app están configurados correctamente
✅ Al menos 2 capturas de pantalla tomadas
✅ Los metadatos (título, descripción) están listos
✅ Probado en al menos 1 dispositivo físico por plataforma

---

## Cronograma de Pruebas

**Semana 1:** Pruebas de funcionalidad principal (Sección 1-2)
**Semana 2:** Compatibilidad de dispositivos y casos extremos (Sección 3-5)
**Semana 3:** Localización, seguridad, cumplimiento (Sección 6-9)
**Semana 4:** Pruebas beta y verificaciones finales (Sección 10-11)

**Prueba mínima viable:** 1 semana (enfocarse en elementos P0)

---

**Recuerda:** ¡Es mejor retrasar el lanzamiento unos días que publicar una app con bugs que obtenga reseñas negativas o rechazos de las tiendas!
