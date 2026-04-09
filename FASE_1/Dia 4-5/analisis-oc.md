# 📋 ANÁLISIS TÉCNICO: Auto-Stitch (Día 4-5)

**Agente:** oc  
**Paso:** Día 4-5 - Auto-Stitch por Línea de Comandos  
**Fase:** Fase 1 - Core de Grabación

---

## 1. DISEÑO FUNCIONAL

### 1.1 Happy Path

1. El usuario completa la grabación y revisión de todos los chunks (flujo días 1-3).
2. El usuario presiona "Generar Video Final" en la UI (nueva pantalla o botón en Review).
3. El sistema obtiene la lista de `approvedClips` desde `SessionData`.
4. El `StitcherService` verifica que todos los clips existen y son válidos.
5. El sistema ejecuta el comando FFmpeg para concatenar secuencialmente.
6. Se muestra progressbar con porcentaje y estimated time.
7. Al finalizar, el `final.mp4` se almacena en `{projectId}/final.mp4`.
8. La UI muestra previsualización del video final y opciones de Exportación (Día 6).

### 1.2 Edge Cases para MVP

| Edge Case | Comportamiento MVP |
|-----------|-------------------|
| Solo 1 clip aprobado | Copiar el clip como final.mp4 (no requiere stitch). |
| Clip corrupto o no encontrado | Mostrar error: "Clip {n} no disponible. ¿Regrabar?" y cancelar stitch. |
| FFmpeg falla (codec incompatible) | Fallback: intentar recodificar con `-c:v libx264 -c:a aac`. |
| Sin clips aprobados | Deshabilitar botón de stitch; tooltip: "Graba al menos un clip". |
| Usuario cierra app durante stitch | Cancelar operación; parcial no se guarda. |

### 1.3 Experiencia de Usuario (Manejo de Errores)

- **Spiner con texto**: "Uniendo videos... {X}% completado"
- **Error de stitch**: Diálogo modal con mensaje claro + botón "Reintentar" + "Cancelar".
- **Stitch exitoso**: Transición automática a pantalla de previsualización/exportación.

---

## 2. DISEÑO TÉCNICO

### 2.1 Componentes Nuevos o Modificados

####Nuevo: `lib/features/recording/services/stitcher_service.dart`
Servicio dedicado que maneja la lógica de stitching usando FFmpeg.

```dart
class StitcherService {
  final String projectId;
  final ClipStorageService _storage;
  
  Future<String> stitchClips({
    required List<String> clipPaths,
    required void Function(double progress) onProgress,
  });
  
  Future<String?> getFinalVideoPath();
  Future<void> cancelStitch();
}
```

**Responsabilidades:**
1. Validar que todos los clips existan.
2. Generar archivo de lista para FFmpeg (concat demuxer).
3. Ejecutar comando FFmpeg con progress callback.
4. Manejar fallbacks de codec.
5. Gestionar cancelación.

#### Modificado: `lib/core/plugins/default/stitcher_plugin.dart`
Actualizar para delegar al `StitcherService` real con FFmpeg.

#### Modificado: `lib/features/recording/services/recording_manager.dart`
Añadir método `getApprovedClipsOrdered()` que retorna la lista de paths en orden de chunk.

#### Nueva Pantalla: `lib/features/recording/pages/export_preview_page.dart` (Día 6 base)
Pantalla que muestra el video final generado y las opciones de exportación.

### 2.2 Flujo de Datos

```
[SessionData.approvedClips] → [StitcherService.stitchClips()]
                                      ↓
                              [Validar archivos]
                                      ↓
                              [Generar list.txt]
                                      ↓
                              [FFmpeg: -f concat -safe 0 -i list.txt]
                                      ↓
                              [Output: final.mp4]
                                      ↓
                              [Guardar en project folder]
                                      ↓
                              [Actualizar session_data.json]
```

### 2.3 Comando FFmpeg

El método de concatenación más robusto para clips del mismo codec es el **concat demuxer**:

```bash
# 1. Generar archivo de lista:
file 'chunk_0_take_1.mp4'
file 'chunk_1_take_2.mp4'
file 'chunk_2_take_1.mp4'

# 2. Comando:
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4
```

**Fallback** (si codecs difieren o copy falla):
```bash
ffmpeg -f concat -safe 0 -i list.txt -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k output.mp4
```

### 2.4 Integración con Contratos Existentes

- La estructura de carpetas ya existe: `{projectId}/clips/`.
- El `final.mp4` debe ir en `{projectId}/final.mp4` (mismo nivel que `clips/`).
- El `session_data.json` debe actualizarse con `finalVideoPath` y `stitchedAt`.
- El `ClipStorageService` ya tiene `projectId` y métodos para rutas absolutas.

### 2.5 Modelo de Datos (Extensiones)

```dart
// En session_data.dart
class SessionData {
  // ... campos existentes ...
  
  String? finalVideoPath;
  DateTime? stitchedAt;
}
```

---

## 3. DECISIONES

| Decisión | Justificación |
|----------|---------------|
| **Usar `ffmpeg_kit_flutter`** en lugar de APIs nativas (AVFoundation/MediaCodec) | El plan MVP lo define explícitamente; reduce complejidad de implementación multiplataforma; ofrece más control sobre parámetros de encoding. |
| **Concat Demuxer** como método principal | Funciona cuando clips tienen el mismo codec (nuestro caso, todos vienen de la misma cámara). Es más rápido que re-encoding. |
| **Fallback a re-encoding** solo si concat falla | Evita crear 2 archivos si no es necesario; respeta principio de mínima transformación. |
| **Progress via FFmpeg session** | `FFmpegKit` proporciona callbacks de progress que permiten actualizar UI. |
| **Cancelación vía `FFmpegKit.cancel()`** | Mecanismo nativo de FFmpegKit para detener ejecución en curso. |

### Dependencias a agregar en pubspec.yaml

```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.3
```

> **Nota:** Según el plan MVP, `ffmpeg_kit_flutter` no está en pubspec.yaml actual. Se debe agregar.

---

## 4. CRITERIOS DE ACEPTACIÓN

- [ ] El usuario ve botón "Generar Video" solo cuando hay ≥1 clip aprobado.
- [ ] El sistema valida que todos los clips de `approvedClips` existan antes de iniciar.
- [ ] La UI muestra progressbar con porcentaje (0-100%) durante el stitch.
- [ ] El `final.mp4` se genera correctamente y es reproducible en el dispositivo.
- [ ] Si FFmpeg falla, el usuario ve mensaje de error claro con opción de reintentar.
- [ ] Si el usuario cancela, el proceso se detiene y no deja archivos parciales.
- [ ] El `session_data.json` se actualiza con `finalVideoPath` después de stitch exitoso.
- [ ] El stitch funciona con 1 solo clip (copia directa, no concat).
- [ ] No hay fugas de memoria tras múltiples ciclos de stitch.

---

## 5. RIESGOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|---------------|---------|------------|
| **FFmpegKit no transpila en iOS/Android nativo** | Media | Alto | Probar en device físico temprano (Día 4). Si falla, usar fallback a implementación Dart con `video_player` + `image_video_stitcher` o método nativo directo. |
| **Clips con codecs diferentes** | Baja | Medio | El Grabación (Día 1-2) usa configuración fija. Risk bajo, pero implementar fallback de re-encoding. |
| **Stitch muy largo para videos largos** | Media | Bajo | Implementar estimated time basado en duración total; permitir cancel. |
| **Memoria insuficiente en stitch de muchos clips** | Baja | Alto | Limitar a 20 clips por sesión (MVP); no hay videos tan largos. |

---

## 6. PLAN

### Tareas Atómicas

| # | Tarea | Complejidad | Dependencias |
|---|-------|-------------|---------------|
| 1 | Agregar `ffmpeg_kit_flutter` a pubspec.yaml | Baja | Ninguna |
| 2 | Crear `StitcherService` con método `stitchClips()` | Alta |pubsec actualizado |
| 3 | Implementar validación de archivos existentes | Media | Ninguna |
| 4 | Implementar generación de `list.txt` para concat | Media | Ninguna |
| 5 | Implementar ejecución FFmpeg con progress callback | Alta | Ninguna |
| 6 | Agregar fallback de re-encoding | Media | Tarea 5 |
| 7 | Actualizar `StitcherPlugin` para delegar al servicio | Media | Tareas 2-6 |
| 8 | Añadir método `getApprovedClipsOrdered()` en RecordingManager | Baja | Ninguna |
| 9 | Crear UI: botón "Generar Video" en Review screen | Baja | Ninguna |
| 10 | Crear UI: pantalla de progress con progressbar | Media | Tareas 2-6 |
| 11 | Manejar errores y retry en UI | Media | Tareas 2-10 |
| 12 | Guardar `finalVideoPath` en session_data.json | Baja | Tareas 2-10 |
| 13 | Testing en dispositivo físico (iOS + Android) | Alta | Todas las anteriores |

### Orden Recomendado

1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13

---

## 🔮 ROADMAP (NO implementar en MVP)

- **Stitching con transiciones**: Agregar fade-in/out entre clips usando filtros de FFmpeg.
- **Preview de transiciones**: Mostrar miniaturas de clips con indicador de transición.
- **Re-stitch parcial**: Permitir reemplazar un clip específico sin re-stitchear todo.
- **Stitching en background**: Usar isolate para que el stitch continúe si la app pasa a background.
- **Compresión avanzada**: Ofrecer opciones de calidad (720p, 1080p, 4K) antes de export.
- **Watermark**: Insertar marca de agua configurable.

### Decisiones de Diseño que NO Bloquean el Roadmap

- El `finalVideoPath` se guarda en `session_data.json` para permitir re-stitch posterior.
- El servicio de stitch es independiente de la UI, permitiendo reutilización en otros flujos.
- Los logs de FFmpeg se capturan para debugging futuro sin mostrarse al usuario MVP.

---

**Documento generado:** Día 4-5 - Análisis Auto-Stitch  
**Siguiente paso:** Implementación de StitcherService y UI asociada.