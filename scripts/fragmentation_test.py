import requests
import json

class ScriptFragmentationAgent:
    def __init__(self, api_key):
        self.api_key = api_key
        self.url = "https://api.deepseek.com/v1/chat/completions" # Verificando endpoint
        
    def fragment_script(self, text):
        prompt = f"""
        Eres un experto en oratoria y creación de contenido para redes sociales. 
        Tu tarea es dividir el siguiente guion en fragmentos cortos para una aplicación de grabación fragmentada.
        
        REGLAS DE ORO:
        1. Cada fragmento debe tener entre 20 y 30 palabras (aprox. 4-8 segundos de habla).
        2. Mantén la coherencia narrativa. No cortes frases a la mitad de forma antinatural.
        3. Identifica la función de cada bloque: Hook, Valor o CTA.
        4. Devuelve un JSON con el formato: {{"fragments": [{{"id": 1, "text": "...", "type": "Hook"}}, ...]}}

        GUION:
        {text}
        """
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }
        
        data = {
            "model": "deepseek-chat",
            "messages": [
                {"role": "system", "content": "Eres un asistente especializado en estructuración de guiones."},
                {"role": "user", "content": prompt}
            ],
            "response_format": {"type": "json_object"}
        }
        
        try:
            response = requests.post(self.url, headers=headers, json=data)
            response.raise_for_status()
            return response.json()['choices'][0]['message']['content']
        except Exception as e:
            return f"Error en la fragmentación: {str(e)}"

# Ejemplo de uso (para testing manual)
if __name__ == "__main__":
    API_KEY = "sk-d3c168f012274a29bd93617498c4e219"
    TEST_TEXT = """
    ¿Alguna vez has sentido que tus videos no conectan? El problema no es tu cámara ni tu micrófono, sino la forma en que estructuras tu mensaje. Hoy te voy a enseñar 3 pasos infalibles para retener la atención de tu audiencia desde el primer segundo. Primero, define un solo objetivo claro. Segundo, usa subtítulos dinámicos. Y tercero, asegúrate de mirar siempre al lente, no a la pantalla. Si aplicas esto hoy mismo, verás la diferencia en tus métricas. Sígueme para más consejos de creación de contenido.
    """
    
    agent = ScriptFragmentationAgent(API_KEY)
    result = agent.fragment_script(TEST_TEXT)
    print(result)
