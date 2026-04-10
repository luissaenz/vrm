# 🧠 ANÁLISIS TÉCNICO: Día 7-8 - Persistencia Local Offline

**Agente:** atg
**Fase:** FASE 1 - Core de Grabación
**Alcance:** Implementación de la resiliencia y gestión de estados de sesión en disco (`session_data.json`) para permitir la reanudación de proyectos.

---

## 1. Diseño Funcional

El objetivo es que LUMIS sea "imposible de romper" por interrupciones externas (llamadas, falta de batería, cierre de app).

### Flujo Principal (Happy Path)
1.  **Persistencia Transaccional:** Cada vez que el usuario aprueba un clip (`acceptCurrentClip`), el estado se sincroniza atómicamente con el disco.
2.  **Cierre de App:** El usuario sale de la app o el sistema la mata por recursos.
3.  **Reanudación:** Al volver a abrir el proyecto desde el Dashboard:
    - El sistema lee el `session_data.json`.
    - Se reconstruyen las rutas de los archivos (usando paths relativos).
    - El usuario aparece en la `RecordingPage` posicionado en el `currentChunkIndex` correcto, con los indicadores visuales de clips previos completados.

### Edge Cases (MVP)
-   **Cierre durante grabación:** Si la app se cierra mientras el `_cameraController` está grabando, se intenta capturar el clip parcial en el `dispose()` del `RecordingManager`. Si no se logra, la sesión al recargar simplemente mostrará ese chunk como no grabado (seguridad ante todo).
-   **Inconsistencia de Archivos:** Si el JSON dice que el Chunk 2 está aprobado pero el archivo `.mp4` no existe en la carpeta, el sistema debe degradar el estado de ese chunk a "pendiente" automáticamente para evitar errores de reproducción en el stitching.
-   **Migración de Sandboxing:** En iOS/Android, el path base de la app puede cambiar tras actualizaciones. La persistencia **NO** debe guardar paths absolutos.

### Manejo de Errores
-   **JSON Corrupto:** Si el archivo está malformado, se renombra a `.bak` y se ofrece al usuario empezar de nuevo para no bloquear la app.
-   **Error de Escritura:** Si el disco está lleno, se muestra un aviso persistente al usuario ya que la persistencia es crítica para el valor del MVP.

---

## 2. Diseño Técnico

### Componentes Actualizados y Nuevos
-   **`ProjectStorageService` (Nuevo):**
    - Responsabilidad única: I/O de la carpeta `vrm_data`.
    - Métodos: `saveSession(SessionData)`, `loadSession(String projectId)`, `listProjects()`.
    - Lógica de "Atomic Write": Escribir en `temp.json` y luego `rename` para evitar archivos truncados.
-   **`RecordingManager` (Modificación):**
    - Ya no maneja la lógica de archivos directamente; delega en `ProjectStorageService`.
    - Añadir constructor o método `resume(String projectId)` que orqueste la carga inicial.

### Interfaces
```dart
abstract class IProjectStorage {
  Future<void> saveSession(SessionData data);
  Future<SessionData?> loadSession(String projectId);
  Future<List<String>> getAvailableProjectIds();
  String getAbsoluteClipPath(String projectId, String relativePath);
}
```

### Modelos de Datos
Se mantiene `SessionData` pero se añade lógica de sanitización en el `fromJson` para asegurar que `currentChunkIndex` nunca sea mayor a la cantidad de fragmentos del guion.

---

## 3. Decisiones

1.  **Paths Relativos en JSON:**
    - **Decisión:** Solo guardar el nombre del archivo (ej: `chunk_0_take_1.mp4`) en `approvedClips`.
    - **Justificación:** Los paths absolutos de Flutter (`/var/mobile/Containers/Data/...`) cambian. Reconstruirlos en runtime es la única forma de asegurar que la sesión dure más de un ciclo de vida de la app.
2.  **JSON vs SQLite:**
    - **Decisión:** Seguir con JSON.
    - **Justificación:** La estructura es plana y jerárquica (un JSON por proyecto). SQLite añadiría complejidad innecesaria para el volumen de datos de un MVP (máximo ~50-100 chunks por video).
3.  **Sincronización en el "Accept":**
    - **Decisión:** Solo persistir en disco cuando el usuario toma una decisión definitiva (Aceptar clip, Stitching completado).
    - **Justificación:** Evita escrituras excesivas y asegura que el estado en disco represente pasos "firmes" del usuario.

---

## 4. Criterios de Aceptación (NUEVO)

- [ ] Al reiniciar la app y cargar un proyecto, `RecordingManager` recupera todos los `approvedClips` previos.
- [ ] No se guardan paths con el prefijo del sistema de archivos local (`/Users/...` o `/data/user/0/...`) dentro del JSON.
- [ ] La carpeta del proyecto se crea automáticamente si no existe al intentar guardar la primera toma.
- [ ] El guardado de la sesión ocurre en menos de 100ms (operación no bloqueante para el UI).
- [ ] Si se cierra la app en la pantalla de `StitchProgressPage`, al volver se detecta si el `final.mp4` existe y se redirige a la pantalla de éxito.

---

## 5. Riesgos

| Riesgo | Impacto | Mitigación |
| :--- | :---: | :--- |
| **Pérdida de archivo durante escritura** | Medio | Uso de patrón `writeTemp -> rename`. |
| **Limpieza de caché del sistema** | Alto | Asegurar que `vrm_data` esté en `getApplicationDocumentsDirectory()` y no en `getTemporaryDirectory()`. |
| **Desbordamiento de almacenamiento** | Bajo | Validar espacio disponible con `disk_space` antes de sesiones largas. |

---

## 6. Plan

1.  **Extracción de Lógica (Baja):** Mover lógica de persistencia de `RecordingManager` a `ProjectStorageService`.
2.  **Relativización de Paths (Media):** Implementar la lógica de "relative-to-absolute" en el servicio de almacenamiento.
3.  **UI de Carga (Baja):** Añadir indicador visual en `RecordingPage` mientras se carga el estado previo.
4.  **Robustez de Directorios (Baja):** Asegurar creación recursiva de `vrm_data/projects/{id}/clips/`.
5.  **Pruebas de Resiliencia (Media):** Simular crashes (kill process) en diferentes puntos del flujo y validar recuperación.

---

### 🔮 Roadmap (NO implementar ahora)
- **Auto-Backup:** Comprimir la carpeta del proyecto en un `.zip` para exportación manual.
- **Project Index:** Un archivo `projects_master.json` para no tener que scanear carpetas al listar en el Dashboard.
- **Conflict Resolution:** Si hay dos versiones de sesión (nube vs local), manejar merge de clips grabados.
