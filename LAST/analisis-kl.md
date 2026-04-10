# Análisis Técnico: Día 7-8 - Persistencia Local Offline

## 1. Diseño Funcional

### Happy Path Detallado
1. El usuario inicia una nueva sesión de grabación desde el Dashboard.
2. Tras aceptar cada clip en `ClipReviewScreen`, el `RecordingManager` guarda automáticamente `session_data.json` en `/vrm_data/projects/{project_id}/session_data.json`.
3. Si la app se cierra accidentalmente (crash o salida manual), al reabrir, el sistema detecta la sesión pendiente y ofrece reanudar desde el último clip aprobado.
4. El usuario confirma reanudación, cargando el estado persistente (clips existentes, progreso del guion, configuraciones activas).
5. La grabación continúa normalmente desde el siguiente fragmento del guion, preservando todos los clips previos.
6. Al completar la sesión, el video final se genera normalmente, y la sesión se marca como finalizada (eliminando el estado persistente o marcándolo como completado).

### Edge Cases Relevantes para MVP
- **Sesión sin clips previos:** Si el usuario sale antes del primer clip, no hay estado que reanudar; se trata como sesión nueva.
- **Corrupción de JSON:** Si `session_data.json` está corrupto, se informa al usuario y se inicia sesión nueva, perdiendo progreso.
- **Proyecto abandonado:** Si pasan X días sin actividad (configurable), la sesión expirada se puede limpiar automáticamente.
- **Múltiples proyectos:** Solo una sesión activa por proyecto; si el usuario inicia otro proyecto, el anterior queda pausado pero persistente.

### Manejo de Errores
- **Falla al guardar JSON:** Muestra toast "Error al guardar progreso" pero continúa la grabación sin persistencia (fallback a memoria RAM).
- **Falla al cargar JSON:** Alerta modal "Sesión corrupta, iniciando nueva" con opción de borrar datos corruptos.
- **Permisos de almacenamiento denegados:** En Android/iOS, si no hay permisos, deshabilita persistencia y avisa "Grabaciones no se guardarán permanentemente".
- **Espacio insuficiente en disco:** Detecta y avisa "Espacio bajo, riesgo de pérdida de progreso" antes de grabar.

## 2. Diseño Técnico

### Componentes Nuevos o Modificaciones
- **Modificación a `RecordingManager`:** Agregar método `saveSessionData()` que serializa `SessionData` a JSON y escribe a disco usando `path_provider` para directorio interno.
- **Modificación a `RecordingManager`:** Agregar método `loadSessionData(String projectId)` que lee y deserializa el JSON, validando integridad básica.
- **Modificación a `DashboardPage`:** Detectar proyectos con `session_data.json` pendiente y mostrar indicador "Reanudar Grabación".
- **Nuevo modelo `SessionData`:** Extensión de `ProjectState` con campos adicionales: `lastClipIndex`, `approvedClips`, `scriptProgress`, `timestampLastSave`.

### Interfaces (Inputs/Outputs de Cada Componente)
- `RecordingManager.saveSessionData()`:
  - Input: Instancia actual de `SessionData`.
  - Output: `bool` indicando éxito/fallo.
- `RecordingManager.loadSessionData(String projectId)`:
  - Input: `projectId` string.
  - Output: `SessionData?` (null si no existe o falla).
- `DashboardPage`: Input de lista de proyectos; Output de navegación a `RecordingPage` con estado precargado.

### Modelos de Datos Nuevos o Extensiones
- Extensión de `SessionData` (en `lib/core/models/session_data.dart`):
  ```dart
  class SessionData {
    String projectId;
    int lastClipIndex;
    List<String> approvedClipPaths; // Rutas relativas a /clips/
    Map<String, dynamic> scriptProgress; // Estado del guion actual
    DateTime timestampLastSave;
    // ... otros campos existentes
  }
  ```
- Coherente con la estructura de carpetas definida en `estado-fase.md`: `/vrm_data/projects/{id}/session_data.json`.

## 3. Decisiones
- **Formato de Persistencia:** Usar JSON plano en lugar de base de datos (SQLite) para simplicidad y portabilidad, evitando complejidad adicional en MVP.
- **Guardado Automático:** Ejecutar save en cada "Accept" de clip para minimizar pérdida de progreso, priorizando robustez sobre performance (escrituras frecuentes son aceptables en móvil moderno).
- **Validación de Integridad:** Incluir checksum simple (hash del JSON) para detectar corrupciones obvias, pero no implementar recuperación automática para mantener bajo alcance.
- **Límite de Sesiones Activas:** Máximo 1 sesión pendiente por proyecto; si el usuario inicia nueva grabación en proyecto existente, sobrescribe la anterior (simplifica gestión).

## 4. Criterios de Aceptación
- El archivo `session_data.json` se escribe correctamente en disco tras aceptar un clip.
- Al cerrar y reabrir la app, la sesión pendiente se detecta y ofrece opción de reanudar.
- Los clips aprobados previos se cargan correctamente al reanudar, permitiendo reproducción en `ClipReviewScreen`.
- Si el JSON está corrupto, el sistema inicia sesión nueva sin crash.
- La persistencia funciona tanto en iOS como en Android con permisos estándar de almacenamiento.
- No se pierden clips al reanudar una sesión interrumpida.

## 5. Riesgos
- **Riesgo de Corrupción por Crash Durante Escritura:** Probabilidad media. Mitigación: Escribir a archivo temporal primero, luego renombrar atómicamente.
- **Riesgo de Pérdida de Datos en Actualizaciones de App:** Probabilidad baja. Mitigación: Versionar el esquema JSON con campo `version` para migraciones futuras.
- **Riesgo de Sobrecarga de Disco:** Probabilidad baja en MVP. Mitigación: Implementar limpieza automática de sesiones expiradas (>7 días sin actividad).
- **Riesgo de Permisos Denegados en Android 13+:** Probabilidad alta. Mitigación: Integrar con `PermissionService` existente para solicitar permisos preemptivamente en onboarding.

## 6. Plan
1. **Extender Modelo SessionData** (Baja): Agregar campos `lastClipIndex`, `approvedClipPaths`, `scriptProgress`, `timestampLastSave`. Dependencia: Ninguna.
2. **Implementar saveSessionData en RecordingManager** (Media): Método que serializa a JSON y guarda en `/vrm_data/projects/{id}/session_data.json`. Dependencia: Modelo extendido.
3. **Integrar Guardado Automático** (Baja): Llamar `saveSessionData()` en cada `acceptClip()` en `RecordingManager`. Dependencia: Método implementado.
4. **Implementar loadSessionData en RecordingManager** (Media): Método que lee y parsea JSON, retornando `SessionData` o null. Dependencia: Modelo extendido.
5. **Modificar DashboardPage para Detectar Sesiones Pendientes** (Baja): Escanear proyectos con `session_data.json` y mostrar botón "Reanudar". Dependencia: Método load implementado.
6. **Agregar Lógica de Reanudación en RecordingPage** (Media): Precargar estado al iniciar si proviene de reanudación. Dependencia: Dashboard modificado.
7. **Agregar Validación de JSON y Manejo de Errores** (Baja): Try/catch en load/save con fallbacks. Dependencia: Métodos implementados.
8. **Testing Manual en Dispositivo Físico** (Media): Verificar persistencia tras crash/simulación de cierre. Dependencia: Todo implementado.

## 🔮 Roadmap
- **Compresión de Sesiones:** Implementar gzip en JSON para reducir footprint en disco.
- **Sincronización en la Nube:** Extensión para backup de sesiones en iCloud/Google Drive.
- **Recuperación Automática de Corrupción:** Algoritmos de reparación basados en backups incrementales.
- **Analytics de Sesiones:** Tracking de abandono y reanudación para métricas de UX.
- **Multi-Sesión Concurrente:** Permitir múltiples proyectos activos simultáneamente (requiere refactor de estado global).