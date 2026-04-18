# 🧠 ANÁLISIS TÉCNICO: Día 13 (Proyectos & Dashboard)

## 0. Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento del Plan | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | `ProjectRepository` existe | `lib/core/data/project_repository.dart` | ✅ | `class ProjectRepository` (L9) |
| 2 | Dashboard usa datos reales | `lib/features/dashboard/dashboard_page.dart` | ❌ | Los proyectos están hardcodeados en `_RecentProjectsSection` (L466-490) |
| 3 | Perfil tiene "Clear All Data" | `lib/features/account/account_profile_page.dart` | ⚠️ | Existe el botón (L252) pero `_showClearDataDialog` no borra archivos físicos (L314) |
| 4 | Ruta de persistencia | `RecordingManager` vs `ProjectRepo` | ❌ | **DISCREPANCIA:** `RecordingManager` usa `vrm_data/projects/` (L218) y `ProjectRepo` usa `projects/` (L15) |
| 5 | Modelo `ProjectState` | `lib/core/models/project_state.dart` | ✅ | Posee `projectId`, `input`, `script` y `assets` (L6-12) |
| 6 | Cálculo de Progreso | `lib/features/recording/models/session_data.dart` | ✅ | `approvedClips` (L39) permite calcular avance contra `totalChunks` |
| 7 | Títulos de Proyecto | `lib/core/models/input_schema.dart` | ✅ | `rawTopic` (L4) es el campo origen para los títulos |
| 8 | Navegación Dashboard | `lib/main.dart` | ✅ | Ruta `/dashboard` definida y `onboarding` como home inicial (L47) |
| 9 | Carpeta `vrm_data` | `RecordingManager.dart` | ✅ | Referenciada en L218 como raíz de la sesión |
| 10 | Localización (L10n) | `lib/l10n/app_es.arb` | ✅ | `clearAllData`, `dataCleared` y `fragmentCount` disponibles |
| 11 | Componente Card | `lib/shared/widgets/project_card.dart` | ✅ | `VRMProjectCard` diseñado para recibir progreso (L4) |
| 12 | Persistencia JSON | `ProjectRepository.dart` | ✅ | Usa `jsonEncode(project.toJson())` en L37 |

**Discrepancias encontradas:**
1.  **Rutas Inconsistentes:** `ProjectRepository` guarda en una carpeta distinta a `RecordingManager`. 
    *   *Resolución:* Unificar `ProjectRepository` para usar la raíz `vrm_data/projects` definida en el plan.
2.  **Dashboard Estático:** La sección de proyectos recientes ignora el repositorio.
    *   *Resolución:* Convertir `_RecentProjectsSection` a `StatefulWidget` o usar `FutureBuilder` para consumir `ProjectRepository.listProjects()`.
3.  **Borrado Incompleto:** "Clear All Data" solo muestra un SnackBar. 
    *   *Resolución:* Implementar borrado recursivo del directorio `vrm_data` usando `Directory.delete(recursive: true)`.

## 1. Diseño Funcional
- **Happy Path:** Al abrir el dashboard, el sistema lee los archivos `.json` en `vrm_data/projects/`. Si existen proyectos, se muestran ordenados por `updatedAt`. Al pulsar "Borrar Todo" en perfil, se eliminan todos los archivos y el dashboard queda vacío en la siguiente carga.
- **Edge Cases:**
    - **Cero proyectos:** Mostrar una card de "Crea tu primer video" o estado vacío elegante.
    - **Sesión sin script:** Si un proyecto se creó pero no se generó el guion, el progreso debe ser 0% evitando errores de división por cero.
- **Manejo de Errores:** Si un JSON está corrupto, `ProjectRepository` ya registra el error y continúa (L96); se debe asegurar que el usuario vea la lista de los archivos válidos restantes.

## 2. Diseño Técnico
- **DashboardPage:** Integrar `ProjectRepository` mediante `FutureBuilder` para cargar la lista de proyectos.
- **Mapping de Datos:**
    - `title` -> `project.input.rawTopic`
    - `progress` -> `session.approvedClips.length / project.script.totalChunks`
    - `time` -> Formatear `updatedAt` (ej: "Editado hace 2h").
- **AccountProfilePage:** Inyectar lógica de borrado físico en el diálogo de confirmación. Requerirá importar `dart:io` y `path_provider`.

## 3. Decisiones
- **D13.1 - Unificación de Root:** Se establece `vrm_data/` como la carpeta raíz para TODA la persistencia local, alineando `ProjectRepository` con `RecordingManager`.
- **D13.2 - Desacoplamiento de Mocks:** Se eliminan los datos de prueba de `iPhone 15` y `Vlog Japón` para forzar el uso de datos reales.

## 4. Criterios de Aceptación
1.  ¿El Dashboard carga proyectos reales de `vrm_data/projects`? (SÍ/NO)
2.  ¿Las tarjetas muestran el progreso real (clips aprobados vs chunks totales)? (SÍ/NO)
3.  ¿Al pulsar "Borrar Todos los Datos" se eliminan físicamente los directorios de proyectos? (SÍ/NO)
4.  ¿El Dashboard se vacía inmediatamente después de un borrado exitoso? (SÍ/NO)

## 5. Riesgos
- **Riesgo:** Pérdida accidental de datos por borrado sin confirmación clara.
    - *Mitigación:* Usar el diálogo `AlertDialog` con estilo `foregroundColor: Colors.red` ya presente.
- **Riesgo:** Conflicto de IO al intentar borrar una carpeta que tiene un archivo de video abierto por el sistema.
    - *Mitigación:* Manejar excepciones en el borrado y notificar si se requiere reiniciar la app.

## 6. Plan
- **Tarea 1:** Corregir ruta en `ProjectRepository` a `vrm_data/projects`. (Baja | 15 min)
- **Tarea 2:** Implementar borrado físico en `AccountProfilePage._showClearDataDialog`. (Media | 30 min)
- **Tarea 3:** Refactorizar `_RecentProjectsSection` para usar `FutureBuilder` y datos reales. (Alta | 60 min)
- **Tarea 4:** Implementar el "Empty State" en el Dashboard. (Baja | 30 min)

**Total estimado:** 2h 15min.

---

### 🔮 Roadmap (NO implementar ahora)
- **Búsqueda en Dashboard:** Implementar la lógica del SearchBar que ya está en la UI pero no conectada al repositorio.
- **Sincronización:** Preparar el campo `updatedAt` para futuros conflictos de versión con la nube.
