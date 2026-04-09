# 📊 Análisis: Día 6

**Documento:** docs/mvp-Definition.md
**Sección:** Día 6
**Agente:** antigravity
**Fecha:** 2026-04-08T17:15:00-03:00

---

## 1. Comprensión del Paso
- **¿Qué problema resuelve?** Al finalizar la edición o unión (Auto-Stitch) del video, el usuario necesita disponer de su obra de forma útil, ya sea guardándola en el carrete de su teléfono (para uso personal) o compartiéndola en redes sociales y/o aplicaciones de mensajería nativas.
- **¿Qué inputs recibe?** La ruta de archivo física (`file path`) del video en formato `.mp4` generado en el paso anterior de compilación.
- **¿Qué outputs debe generar?** Un video almacenado persistentemente en la galería del dispositivo y/o el panel modal nativo de compartir (`Share Sheet`) activado.
- **¿Qué rol cumple?** Es el último eslabón de la "Ruta Crítica Mínima" que consolida el flujo MVP. Es lo que entrega el valor real del producto a manos del usuario.

## 2. Supuestos y Ambigüedades
- **Ubicación del álbum:** No se indica si se debe crear un álbum personalizado, por ejemplo, "VRM Videos", o guardarlo directamente en el carrete general.
- **Gestión después de Exportar:** ¿El archivo temporal `final.mp4` dentro de la carpeta local `./projects/{id}` debe ser eliminado para ahorrar memoria una vez la sesión termina, o debe conservarse de forma indefinida?
- **Estados Cero:** ¿Qué pasa si el video es corrupto al momento de generar la ruta a `share_plus`?

## 3. Diseño Funcional
- **Flujo paso a paso:**
  1. El usuario visualiza la pantalla de resultados después del paso Auto-Stitch. 
  2. Selecciona "Guardar en Galería" o "Compartir".
  3. Si la selección es "Guardar": se solicita permiso al File System/Foto (en caso de aplicar), se utiliza un plugin intermedio (`photo_manager`) para colocar el archivo en disco público, visualizando finalmente una alerta de "Video Guardado".
  4. Si la selección es "Compartir": se levanta la llamada al OS con `share_plus` indicando el path del vídeo temporal y el tipo mime (`video/mp4`).
- **Casos normales:** Flujo directo, permisos otorgados previamente, operaciones I/O exitosas de inmediato.
- **Edge cases:** Permisos denegados (requiriendo llevar al usuario a la app 'Settings'). Falta de memoria de disco del sistema nativo.
- **Manejo de errores:** Captura de try/catch con un UI Dialog/Toast indicando de forma explícita: "Permiso denegado para Guardar", o "Falta espacio en dispositivo".

## 4. Diseño Técnico
- **Arquitectura y Componentes:** Se debe abstraer todo en una capa de infraestructura, e.g. `ExportService` o `MediaRepository`, de forma tal que la UI solo invoca llamadas a un provider/bloc sin incluir lógica externa.
- **APIs/Endpoints:** `PhotoManager.editor.saveVideo` y `Share.shareXFiles`.
- **Modelos de datos:** Invocado recibiendo parámetros tipo `File` (Dart) o rutas String, devolviendo enumerables de resultado: `ExportResult.success`, `ExportResult.permissionDenied`, `ExportResult.error`.

## 5. Decisiones Tecnológicas
- **Framework:** Flutter (Dart) 
- **Librerías principales:**
  - `photo_manager: ^3.0.0`: Utilizado en la definición. Extremadamente resiliente a los cambios continuos granulares de permisos en Android 14+ y el comportamiento fotográfico nativo de iOS.
  - `share_plus: ^7.0.0`: Es el estandar *def-acto* en la comunidad Flutter para un puente robusto con las APIs `UIActivityViewController` (iOS) y de `Intent` (Android) sin bugs adicionales de UI.
- **Justificación técnica:** Dependencias estables, nativas y de alto mantenimiento que evitan reescribir bridges con `MethodChannels`.

## 6. Plan de Implementación
1. **Configuración Nativa de SO:**
   - **iOS:** Configurar `Info.plist` con metadatos: `NSPhotoLibraryUsageDescription` y `NSPhotoLibraryAddUsageDescription` indicando exactamente por qué se guardan videos.
   - **Android:** Ajustar permisos especiales de "Vídeos" `READ_MEDIA_VIDEO` / `WRITE_EXTERNAL_STORAGE` en `AndroidManifest.xml` si se requiere compatibilidad hacia atrás.
2. **Implementación Lógica:** Programación de clase `ExportService` y pruebas unitarias aisladas (`mock_share`, `mock_photo_manager`).
3. **Integración con Interfaz:** Acoplar la vista existente conectando llamadas al ActionButton e implementando indicadores de progreso (Spinners).
4. **Manejo de estados de respuesta:** Diálogos ante fallas u omisiones de permiso por parte del usuario.

## 7. Riesgos y Cuellos de Botella
- **Riesgos Técnicos:** Cambios drásticos en la API oficial de Android/iOS para salvar archivos pueden requerir reingeniería completa la librería (Scoped Storage o Sandboxing de iOS 16).
- **Riesgos Operacionales:** El rechazo de revisión de Apple en el paso posterior si la explicación (`NSPhotoLibraryAddUsageDescription`) es vaga ("please allow access to photos") en vez de algo específico ("VRM necesita acceso a las fotos para guardar las grabaciones resultantes").

## 8. Métricas de Éxito
- **Validación Manual Correcta:** Comprobar físicamente comprobando la apertura de la Galería del dispositivo constatando que el archivo existe y es jugable; compartir sin fallos en WhatsApp y Telegram.
- **KPIs:** Disminución paulatina de incidencias `Permission Denied` gracias al prompt contextual correcto antes del prompt nativo imperativo.

## 9. Estrategia de Testing
- **E2E / Integración:** Utilización de mocks de las dependencias usando `mockito`. Por defecto `mock_photo_manager` proveerá un permiso validado y otro revocado para comprobar ambos caminos de UI.
- **Pruebas manuales en fierros (dispositivos físicos):** Realizar un share en un ecosistema Android 13/14 real y un iOS 16+ ya que los simuladores no proveen validaciones `shareList` fiables ni almacenamiento externo replicable exactamente.

## 10. Optimización y Escalabilidad Futura
- **Desaceleración/Eficiencia de Espacio:** Agregar un *Clear Local Project Cache* que se detona justo al recibir el evento del share_sheet, para mantener la app VRM en < 100 MB totales previniendo ser detectada como Bloatware.
- **Metadata Analytics e IDs:** Marcado nativo a través del propio archivo `.mp4` con firmas Metadata EXIF para telemetría sin involucrar SDK excesivos de métrica explícita, o la inyección de marcas de agua gráficas.

---

✅ Análisis completado exitosamente
