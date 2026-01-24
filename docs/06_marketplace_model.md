# Modelo de Negocio: Marketplace de Plugins VRM

## 1. Visión del Ecosistema
Transformar la app en una plataforma donde terceros (Desarrolladores, Coaches, Agencias) puedan monetizar su conocimiento técnico o metodológico a través de utilidades integradas en el flujo de grabación.

## 2. Modelo de Ingresos (Revenue Share)
- **Reparto Estándar:** 70% para el Desarrollador / 30% para VRM Platform.
- **Plugins Gratuitos:** Sin comisión. Fomentan la retención y el crecimiento del ecosistema.
- **Suscripciones (SaaS):** Soporte para pagos recurrentes gestionados por la plataforma.

## 3. Categorías y Formatos Técnicos
| Categoría | Ejemplo | Formato de Descarga | Ejecución |
| :--- | :--- | :--- | :--- |
| **Generativo (IA)** | Lip-sync, Clonación de Voz | Spec (.yml) + API Token | Cloud (Desarrollador) |
| **Utilidad (UI/UX)** | Filtros, Detector de Mirada | Script (JS/Lua) + Assets | Local (Sandbox) |
| **Contenido** | Guiones Pro, Plantillas | JSON Schema | Local |
| **Automatización** | Zapier, Make | API Contract | Cloud/Híbrido |

## 4. Gobernanza y Calidad
- **Certificación VRM:** Proceso de revisión técnica para asegurar que el plugin no rompa el "Estado de Flow" (latencia < 200ms).
- **Sandboxing:** Los plugins operan sobre los contratos definidos (OpenAPI/JSON Schema) para garantizar la seguridad de los datos del usuario.
- **Rating de Comunidad:** Sistema de estrellas y reseñas enfocado en la utilidad comunicativa.

## 5. Estrategia de Adquisición de Partners
1. **Beta Program:** Acceso anticipado para coaches de oratoria influyentes.
2. **SDK Documentation:** Documentación exhaustiva y herramientas de validación (SDD) para desarrolladores.
3. **App Showcase:** Sección destacada en el dashboard para plugins que mejoren drásticamente las métricas de usuario.
