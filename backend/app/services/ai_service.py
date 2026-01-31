from openai import OpenAI
import os
import json
from typing import List, Dict, Optional
from jsonschema import validate, ValidationError
import logging

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        # Configurar OpenAI/DeepSeek (usan la misma API)
        openai_key = os.getenv("OPENAI_API_KEY")
        deepseek_key = os.getenv("DEEPSEEK_API_KEY")
        
        self.openai_client = None
        self.deepseek_client = None
        
        if openai_key:
            self.openai_client = OpenAI(api_key=openai_key)
        
        if deepseek_key:
            # DeepSeek usa la API de OpenAI pero con base_url diferente
            self.deepseek_client = OpenAI(
                api_key=deepseek_key,
                base_url="https://api.deepseek.com"
            )
        
        if not self.openai_client and not self.deepseek_client:
            logger.warning("No AI API keys found in environment")

    async def get_chat_completion(
        self, 
        messages: List[Dict[str, str]], 
        model: str = "deepseek-chat",
        force_json: bool = False,
        expected_schema: Optional[Dict] = None,
        provider: str = "deepseek"
    ) -> Dict[str, any]:
        """
        Envía una petición a un proveedor de IA con soporte para validación de schema.
        
        Args:
            messages: Lista de mensajes para el chat
            model: Modelo a usar (deepseek-chat, gpt-4o, etc.)
            force_json: Si True, fuerza respuesta en formato JSON
            expected_schema: Schema JSON para validar la respuesta
            provider: Proveedor a usar (deepseek, openai)
            
        Returns:
            Dict con 'content' y opcionalmente 'validation_error'
        """
        # Seleccionar cliente
        if provider == "deepseek":
            client = self.deepseek_client
            if not client:
                return {"content": None, "error": "DeepSeek API key not configured"}
        elif provider == "openai":
            client = self.openai_client
            if not client:
                return {"content": None, "error": "OpenAI API key not configured"}
        else:
            return {"content": None, "error": f"Unknown provider: {provider}"}
        
        try:
            # Configurar parámetros
            params = {
                "model": model,
                "messages": messages,
                "temperature": 0.7
            }
            
            # Si hay schema esperado, forzar JSON
            if expected_schema or force_json:
                params["response_format"] = {"type": "json_object"}
            
            # --- LOG PETICIÓN ---
            print("\n" + "="*50)
            print(f"🚀 ENVIANDO PETICIÓN A IA ({provider.upper()})")
            print(f"Modelo: {model}")
            for msg in messages:
                print(msg.get('content', ''))
            print("="*50 + "\n")
            
            # Llamar a la IA
            response = client.chat.completions.create(**params)
            content = response.choices[0].message.content
            
            # --- LOG RESPUESTA ---
            print("\n" + "✨"*25)
            print(f"📥 RESPUESTA RECIBIDA DE IA ({provider.upper()})")
            print(content)
            print("✨"*25 + "\n")
            
            # Validar contra schema si existe
            if expected_schema and content:
                try:
                    response_json = json.loads(content)
                    validate(instance=response_json, schema=expected_schema)
                    print("✅ VALIDACIÓN DE SCHEMA: EXITOSA")
                    logger.info("Response validated successfully against schema")
                    return {
                        "content": content,
                        "validated": True
                    }
                except json.JSONDecodeError as e:
                    print(f"❌ ERROR: JSON INVÁLIDO -> {e}")
                    logger.error(f"Response is not valid JSON: {e}")
                    return {
                        "content": content,
                        "validation_error": f"Invalid JSON: {str(e)}"
                    }
                except ValidationError as e:
                    print(f"❌ ERROR: FALLO DE SCHEMA -> {e.message}")
                    logger.error(f"Schema validation failed: {e.message}")
                    return {
                        "content": content,
                        "validation_error": f"Schema validation failed: {e.message}"
                    }
            
            return {"content": content}
            
        except Exception as e:
            print(f"🔥 ERROR GENERAL IA: {e}")
            logger.error(f"Error calling {provider}: {e}")
            return {
                "content": None,
                "error": f"Error en la comunicación con IA: {str(e)}"
            }

ai_service = AIService()
