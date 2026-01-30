from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="VRM AI Backend",
    description="Servicio centralizado para comunicación con modelos de IA y gestión de agentes.",
    version="0.1.0"
)

# Configuración de CORS para permitir peticiones desde la app Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar los dominios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.core.prompts import prompt_manager
from app.services.ai_service import ai_service
from pydantic import BaseModel
from typing import Optional, Dict, Any

class PromptRequest(BaseModel):
    category: str
    name: str
    variables: Optional[Dict[str, Any]] = None

@app.post("/test/prompt")
async def test_prompt(request: PromptRequest):
    """Prueba la generación de un prompt formateado."""
    content = prompt_manager.get_prompt(request.category, request.name, request.variables)
    return {"formatted_prompt": content}

@app.post("/test/ai-chat")
async def test_ai_chat(message: str):
    """Endpoint de prueba para verificar la conexión con el modelo de IA."""
    response = await ai_service.get_chat_completion([{"role": "user", "content": message}])
    return {"ai_response": response}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
