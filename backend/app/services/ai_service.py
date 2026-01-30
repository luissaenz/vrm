from openai import OpenAI
import os
from typing import List, Dict

class AIService:
    def __init__(self):
        self.openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    async def get_chat_completion(self, messages: List[Dict[str, str]], model: str = "gpt-4o"):
        """Envía una petición a OpenAI."""
        try:
            response = self.openai_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"Error en la comunicación con IA: {str(e)}"

ai_service = AIService()
