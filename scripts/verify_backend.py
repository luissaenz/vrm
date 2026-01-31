import requests
import json

def test_backend_prompt():
    url = "http://localhost:8000/prompt/tasks/SCRIPT_ANALYZER"
    
    script_content = """
Hay una estrategia para adquirir clientes que pocos usan y se llama Content Pillars.
Se basa en dividir tu contenido en tres pilares claros.

El primero es Atracción.
Acá no hablás de vos.
Hablás de los objetivos, miedos y obstáculos de tu audiencia.
Este contenido no vende, trae a la gente correcta.

El segundo pilar es Nutrición.
Y esto es clave: repetir tips, repetir ideas, repetir mensajes.
La repetición genera posicionamiento.
Y el posicionamiento genera confianza.

Ahora, el tercer pilar es el que paga las cuentas: Venta.
Acá el contenido no vende en el post.
El contenido lleva la conversación al inbox o a WhatsApp.
Y ahí es donde se crea la oportunidad de venta.

Si querés ideas de contenido para cada pilar,
escribime “PILARES” en los comentarios.
""".strip()

    payload = {
        "SCRIPT": script_content,
        "segment_minTime": 3.0,
        "segment_maxTime": 10.0,
        "segment_RateWpm": 130.0,
        "send_to_ai": True
    }
    
    try:
        print(f"Sending request to {url}...")
        response = requests.post(url, json=payload)
        response.raise_for_status()
        result = response.json()
        
        print("\n--- Backend Response Summary ---")
        print(f"Category: {result.get('category')}")
        print(f"Name: {result.get('name')}")
        
        ai_response = result.get('ai_response')
        if ai_response:
            if 'error' in ai_response:
                print(f"AI Error: {ai_response['error']}")
            elif 'validation_error' in ai_response:
                print(f"Validation Error: {ai_response['validation_error']}")
            else:
                print("AI Response received and validated successfully!")
                print(json.dumps(ai_response, indent=2))
                print("\n--- Execution Metadata ---")
                meta = ai_response.get('meta', {})
                print(f"Language: {meta.get('language')}")
                print(f"Total Segments: {meta.get('total_segments')}")
                print(f"Estimated Duration: {meta.get('estimated_duration_seconds')}s")
                
                print("\n--- Segments Breakdown ---")
                for seg in ai_response.get('segments', []):
                    print(f"[{seg['id']}] ({seg['type']}) {seg['edit_metadata']['duration_seconds']}s")
                    print(f"Text: {seg['text']}")
                    print(f"Subtitles: {seg['subtitles']}")
                    print("-" * 20)
        else:
            print("No AI response received (did you set send_to_ai: true?)")
            
    except Exception as e:
        print(f"Error connecting to backend: {e}")

if __name__ == "__main__":
    test_backend_prompt()
