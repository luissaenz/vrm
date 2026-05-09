# 0️⃣ Verificación contra Código Fuente (OBLIGATORIA)

| # | Elemento | Verificación | Estado | Evidencia |
|---|---|---|---|---|
| 1 | pubspec.yaml tiene config flutter_launcher_icons | grep en pubspec.yaml | ✅ VERIFICADO | pubspec.yaml:128-134, adaptive_icon_background y adaptive_icon_foreground ya presentes |
| 2 | assets/images/branding/icon_source.png existe | glob en assets | ✅ VERIFICADO | assets/images/branding/icon_source.png encontrado |
| 3 | mipmap-anydpi-v26/ generado | ls en android/app/src/main/res | ❌ DISCREPANCIA | directorio no existe, iconos no regenerados |
| 4 | flutter_launcher_icons en dev_dependencies | grep en pubspec.yaml | ✅ VERIFICADO | pubspec.yaml:83, ^0.13.1 instalado |

**Discrepancias encontradas:** (cada una con resolución propuesta)

- Config adaptive presente en pubspec.yaml, pero iconos no regenerados. Ejecutar `flutter pub run flutter_launcher_icons` para generar mipmap-anydpi-v26/ic_launcher.xml.

---

# 1️⃣ Análisis de Datos (ETAPA 1)

- ✅ Schema: cambios en pubspec.yaml para adaptive icons
- ✅ Integridad referencial: dependencias flutter_launcher_icons ya en proyecto
- ✅ RLS policies: no aplica (no DB)
- ✅ Índices necesarios: no aplica
- ✅ Tipos de datos: PNG para foreground, string hex para background

Diagrama ER: no aplica (config de assets).
Cambios de schema necesarios: ninguno, solo config existente.
Impacto en datos existentes: ninguno.

---

# 2️⃣ Análisis de Código (ETAPA 2)

- ✅ Funciones/clases nuevas: ninguna nueva, solo config existente
- ✅ Patrones: sigue patrón flutter_launcher_icons estándar
- ✅ Modularidad: config centralizada en pubspec.yaml
- ✅ Calidad: config simple, baja complejidad
- ✅ Imports exactos: flutter_launcher_icons package ya importado

Firma completa + ejemplo de uso + referencia: no aplica, solo config.
Para cada componente nuevo: ninguno.

---

# 3️⃣ Análisis de Backend (ETAPA 3)

- ✅ APIs/endpoints: no aplica (solo build-time config)
- ✅ Middleware: no aplica
- ✅ Flujos: build process genera iconos
- ✅ Contratos: config define background/foreground
- ✅ Error handling: si icon_source.png falta, build falla

Endpoints: ninguno.
Ejemplo request/response: no aplica.
Ejemplo error handling: build error si asset no encontrado.

---

# 4️⃣ Análisis de Fullstack + DX (ETAPA 4)

- ✅ Flujo completo: pubspec config → flutter pub run → iconos generados → Android 13+ compatible
- ✅ Coherencia: config presente pero no ejecutada
- ✅ Alineación: paso post-MVP, no bloquea release
- ✅ Gaps: regeneración pendiente
- ✅ **DX & Tooling (OBLIGATORIO):**

### Herramienta Propuesta: [vrm-icon-regen]
- **Qué automatiza:** regeneración automática de iconos adaptive después de cambios en assets
- **Tipo:** script / CLI
- **Cómo se usa:** `dart run scripts/vrm_icon_regen.dart`
- **Impacto para el usuario final:** evita olvidar regenerar iconos, asegura compatibilidad Android 13+
- **Prioridad:** Tarea 0 — implementar antes que el resto del paso

Flujo end-to-end: config en pubspec → script ejecuta comando → verifica mipmap-anydpi-v26 existe.
Validación: iconos se ven correctos en Android 13+ con forma adaptable.
Puntos críticos: no romper iconos existentes en Android <13.

---

# 5️⃣ Criterios de Aceptación

- ✅ [DATA] pubspec.yaml tiene adaptive_icon_background y adaptive_icon_foreground
- ✅ [CODE] flutter_launcher_icons ejecuta sin errores
- ✅ [BACKEND] no aplica
- ✅ [FULLSTACK] iconos generados en mipmap-anydpi-v26/
- ✅ [DX] script vrm-icon-regen automatiza regeneración

---

# 6️⃣ Riesgos

| Riesgo | Severidad | Causa | Mitigación |
|---|---|---|---|
| Icon source asset faltante | Baja | Cambio en branding | Verificar existencia antes de regenerar |
| Build falla en Android | Media | Config incorrecta | Test en emulador Android 13+ |
| Rompe iconos legacy | Baja | Overwrite existente | Backup mipmap/ antes de regenerar |

- Riesgos técnicos: compatibilidad con min_sdk_android: 21
- Riesgos de integración: flutter_launcher_icons versión
- Riesgos descubiertos: ninguno adicional

---

# 7️⃣ Plan de Implementación

| # | Tarea | Artefacto | Interfaz exacta | Patrón a seguir | Etapa | Complejidad | Tiempo Est. | Dependencias | Verificación |
|---|---|---|---|---|---|---|---|---|---|
| 0 | **DX & Tooling**: script vrm-icon-regen | D:\Develop\Personal\vrm\scripts\vrm_icon_regen.dart | def run(): subprocess.run(['flutter', 'pub', 'run', 'flutter_launcher_icons']) | D:\Develop\Personal\vrm\scripts\store_prep_cli.dart | DX | Media | 0.5h | Ninguna | → verificar: dart run scripts/vrm_icon_regen.dart ejecuta sin errores |
| 1 | Ejecutar regeneración iconos | — | flutter pub run flutter_launcher_icons | pubspec.yaml:128-134 | CODE | Baja | 0.2h | Tarea 0 | → verificar: mipmap-anydpi-v26/ic_launcher.xml existe |
| 2 | Verificar compatibilidad Android 13+ | — | — | — | FULLSTACK | Baja | 0.3h | Tarea 1 | → verificar: build apk exitoso + icono adaptable en Android 13+ |

**Tiempo total estimado:** 1 hora

---

## 🔮 Roadmap (NO implementar ahora)

- Optimizaciones: iconos WebP para tamaño reducido
- Mejoras: soporte iOS adaptive icons si necesario
- Pre-requisitos: actualizar flutter_launcher_icons si bugs

---

**Idioma de respuesta:** Español 🇪🇸