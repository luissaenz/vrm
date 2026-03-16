# Lógica de Fragmentación y Calidad (Voice & Video Rubric)

## 1. Fragmentación Automática de Guion
Para asegurar que los fragmentos duren entre 6 y 8 segundos (Cámara Atómica):
- **Algoritmo de Conteo de Palabras:** Basado en una velocidad promedio de 130-150 palabras por minuto (aprox. 15-20 palabras por fragmento).
- **Detección de Signos de Puntuación:** Priorizar cortes en puntos seguidos, comas o pausas naturales para evitar cortes abruptos en medio de una idea.
- **Validación de Longitud:** Si un fragmento es > 8s, buscar la pausa más cercana para subdividirlo.

## 2. Semáforo de Calidad (Visual Feedback In-Flow)
Sistema de indicadores en pantalla (Overlay) para el influencer:

| Color | Estado | Significado | Acción App |
| :--- | :--- | :--- | :--- |
| 🔴 **Rojo** | Mala Calidad | Mirada fuera de rango o ruido excesivo. | Sugiere repetir automáticamente. |
| 🟡 **Amarillo** | Alerta | Encuadre límite o audio con eco ligero. | Permite seguir pero con advertencia. |
| 🟢 **Verde** | Óptima | Ojos nivelados y audio limpio. | Habilita comando "Seguir" con confianza. |

## 3. Guía Ocular Dinámica (AR Reference)
- **Referencia AR:** Una línea horizontal semi-transparente fijada en la posición detectada de los ojos en el primer clip.
- **Persistencia:** La línea se mantiene fija en las siguientes tomas para forzar al influencer a re-posicionarse exactamente igual.
- **Resultado:** Elimina el efecto de "salto" visual entre clips fragmentados.

## 4. Rúbrica de Voz (PPM & Fillers)
Métricas analizadas post-grabación para el dashboard de maestría:
- **PPM (Palabras por Minuto):** Evalúa el ritmo natural vs. apresurado.
- **Muletillas (Filler Words):** Identifica recurrencias de "eh", "um", "este".
- **Energía Vocal:** Análisis de la amplitud de onda para detectar variaciones tonales.
