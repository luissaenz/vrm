# 📋 Análisis Día 7-8: Persistencia Local Offline

## 1. Diseño Funcional

### 1.1 Happy Path
1. **Usuario inicia nueva sesión:** Crea un proyecto en Dashboard → entra a Grabación → se inicializa `SessionData` vacía con `projectId` y timestamps.
2. **Grabación de clips:** Por cada chunk aprobado, `RecordingManager.acceptCurrentClip()` actualiza `sessionData` y dispara `_saveSessionDataToDisk()`.
3. **Guardado automático:** Cada "Accept" o actualización de estado persisten inmediatamente a `vrm_data/projects/{projectId}/session_data.json`.
4. **Recuperación de sesión:**
   - Al abrir proyecto existente, el sistema debe detectar `session_data.json` y restaurar estado.
   - El usuario retoma desde el `currentChunkIndex` persisted.
5. **Interrupciones:**
   - App en background: `stopAndSavePartial()` guarda clip parcial.
   - Crash/cierre forzado: Al reopen, se reconstruye estado desde disco.

### 1.2 Edge Cases MVP
| Escenario | Manejo |
|-----------|-------|
| Session vacía (sin clips) al recuperar | Iniciar fresh, `currentChunkIndex = 0` |
| Archivo corrupto (JSON inválido) | Log error + iniciar session nueva |
| Archivo no existe | Crear nueva sesión |
| Disk full durante save | Fallback: mantener solo en memoria, warn user |
| Stitching completado + recuperar | Mostrar `RecordingEndPage` directamente |
| `approvedClips` referencian archivos borrados | Warn user, предложить re-grabar chunk |

### 1.3 Manejo de Errores
- **Save failure:** Silently log, no bloquia grabación. Evitar UX blocking.
- **Load failure:** Iniciar nueva sesión, no exponer stacktrace.
- **Archivo borrado por usuario:** Verificar existencia antes de reproducir en revisión.

---

## 2. Decisiones

### ✅ Decisiones Existentes (ya implementadas)
1. **JSON como formato de persistencia** —Ligero, legible, sin dependencia SQLite para MVP.
2. **Save on Accept** —Persistencia en cada paso crítico, no solo al final.
3. **Ruta:** `vrm_data/projects/{projectId}/session_data.json` —Estructura definida.
4. **Modelo `SessionData`** con `toJson()`/`fromJson()` —Contrato serializable.
5. **`projectId` como clave** —Identificador único por proyecto.

### ⚠️ Decisiones PENDIENTES Detectadas
| Decisión | Status | Propuesta |
|----------|--------|------------|
| Carga de sesión existente | 🔴 No implementado | Agregar método estático `SessionData.load(projectId)` y `RecordingManager.loadOrCreate(projectId)` |
| Reanudación automática al reopen | 🔴 No implementado | En `recording_page.dart`, chequear existencia antes de inicializar |
| Validación de archivos al cargar | 🔴 No implementado | Verificar que `approvedClips` paths sigan existiendo |

---

## 3. Criterios de Aceptación

- [ ] `session_data.json` se escribe correctamente tras cada `acceptCurrentClip()`
- [ ] El archivo contiene todos los campos: `projectId`, `currentChunkIndex`, `approvedClips`, `stitchingCompleted`, `finalVideoPath`
- [ ] Al reabrir proyecto, el UI posiciona en el `currentChunkIndex` persisted
- [ ] Clips asociados en `approvedClips` son reproducibles (archivo existe)
- [ ] Si `stitchingCompleted = true`, mostrar `RecordingEndPage` directamente
- [ ] Si archivo corrupto/inexistente, se crea session nueva sin crash
- [ ] Sesión corrupta no bloquea navegación al Dashboard

---

## 4. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|-------|--------------|---------|------------|
| **Session recovery no implementada** | ALTA | 🔴 CRÍTICO | Agregar `SessionData.load(projectId)` + `RecordingManager.loadOrCreate()` |
| **Approved clips referencian archivos borrados** | MEDIA | 🟡 MEDIO | Validar existencia en load + warn user |
| **JSON corrupto por write concurrente** | BAJA | 🟡 MEDIO | Try/catch en load, fallback a nueva sesión |

---

## 5. Plan de Implementación

### Tareas Atómicas
| # | Tarea | Complejidad | Dependencia |
|---|-------|-------------|-------------|
| 1 | Agregar `SessionData.load(projectId)` estático | Baja | Modelo existente |
| 2 | Agregar `RecordingManager.loadOrCreate(projectId)` factory | Baja | #1 |
| 3 | Implementar validación de `approvedClips` al cargar | Media | #2 |
| 4 | Integrar carga en `recording_page.dart` | Media | #2 |
| 5 | Test de recovery: reopen proyecto con sesión abierta | Baja | #4 |

---

## 6. Roadmap (NO implementar ahora)

- **Persistencia de proyectos múltiples:** Lista de proyectos en Dashboard desde `vrm_data/projects/`.
- **Versionado de schema:** Si cambia estructura `session_data.json`, migrar automáticamente.
- **Backup automático:** Copia de seguridad antes de cada save.
- **Sincronización Cloud:** iCloud/Google Drive para cross-device resume.
- **Sesiones abandonadas自動detect:** Limpiar proyectos sin actividad > 30 días.