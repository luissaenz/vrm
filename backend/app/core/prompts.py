import os
import json
import re
from typing import Dict, Any, Optional, Tuple
import logging

logger = logging.getLogger(__name__)

class PromptContext:
    """Contexto de ejecución de un prompt con metadata de seguridad."""
    def __init__(self):
        self.expected_schema: Optional[Dict] = None
        self.has_sanitized_content: bool = False

class PromptManager:
    """Gestiona la carga y resolución de prompts con pipes de seguridad."""
    
    def __init__(self, prompts_dir: str = "prompts"):
        self.prompts_dir = prompts_dir
        self._ensure_directories()
        # Regex para detectar {{payload.X|pipe}} o {{file.X[Y]|pipe}}
        self.tag_pattern = re.compile(
            r'\{\{\s*(payload|file)\.([a-zA-Z0-9_.\[\]]+?)(?:\|(\w+))?\s*\}\}'
        )

    def _ensure_directories(self):
        """Crea la estructura de directorios si no existe."""
        for subdir in ['tasks', 'schemas', 'data']:
            path = os.path.join(self.prompts_dir, subdir)
            if not os.path.exists(path):
                os.makedirs(path)

    def _load_json_file(self, category: str, subcategory: str) -> Dict[str, Any]:
        """Carga un archivo JSON desde la estructura organizada."""
        file_path = os.path.join(self.prompts_dir, category, f"{subcategory}.json")
        if not os.path.exists(file_path):
            logger.warning(f"File not found: {file_path}")
            return {}
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading {file_path}: {e}")
            return {}

    def _sanitize_user_input(self, text: str) -> str:
        """Sanitiza input del usuario contra prompt injection."""
        if not isinstance(text, str):
            text = str(text)
        
        # Patrones peligrosos comunes
        dangerous_patterns = [
            r"ignore\s+(all\s+)?previous\s+instructions?",
            r"ignora\s+(todas?\s+)?las?\s+instrucciones?\s+anteriores?",
            r"forget\s+everything",
            r"olvida\s+todo",
            r"new\s+instructions?:",
            r"nuevas?\s+instrucciones?:",
            r"system\s*:",
            r"assistant\s*:",
            r"\{\{.*?\}\}",  # Evitar tags anidados
        ]
        
        text_lower = text.lower()
        for pattern in dangerous_patterns:
            if re.search(pattern, text_lower):
                logger.warning(f"Potential injection attempt detected: {pattern}")
                text = re.sub(pattern, "[CONTENIDO BLOQUEADO]", text, flags=re.IGNORECASE)
        
        # Limitar longitud
        max_length = 10000
        if len(text) > max_length:
            logger.warning(f"Input truncated from {len(text)} to {max_length} chars")
            text = text[:max_length] + "\n\n[CONTENIDO TRUNCADO]"
        
        # Envolver con delimitadores
        return f"[INICIO CONTENIDO USUARIO]\n{text}\n[FIN CONTENIDO USUARIO]"

    def _resolve_path(self, path: str, payload: Dict[str, Any]) -> Any:
        """Resuelve una ruta como 'key' o 'nested.key' o 'array[payload.key]'."""
        # Manejar indexación dinámica: category[payload.key]
        bracket_match = re.match(r'([a-zA-Z0-9_]+)\[payload\.([a-zA-Z0-9_]+)\]', path)
        if bracket_match:
            base_key = bracket_match.group(1)
            index_key = bracket_match.group(2)
            index_value = payload.get(index_key)
            if not index_value:
                return f"[Error: payload.{index_key} no encontrado]"
            return (base_key, index_value)
        
        # Ruta simple con dots
        parts = path.split('.')
        return '.'.join(parts)

    def _resolve_tag(self, match: re.Match, payload: Dict[str, Any], context: PromptContext) -> str:
        """Resuelve un tag individual."""
        source = match.group(1)  # 'payload' o 'file'
        path = match.group(2)     # 'SCRIPT' o 'schemas.ANALYSIS' o 'data.profiles[payload.id]'
        pipe = match.group(3)     # 'sanitize' o 'validate_output' o None

        # Resolver desde payload
        if source == 'payload':
            resolved_path = self._resolve_path(path, payload)
            value = payload.get(resolved_path, f"[Error: payload.{path} no encontrado]")
            
            if pipe == 'sanitize':
                context.has_sanitized_content = True
                return self._sanitize_user_input(str(value))
            
            return str(value)

        # Resolver desde file
        elif source == 'file':
            # Parsear: 'schemas.ANALYSIS' o 'data.profiles[payload.id]'
            parts = path.split('.', 1)
            if len(parts) < 2:
                return f"[Error: Ruta de archivo inválida: {path}]"
            
            category = parts[0]  # 'schemas', 'data', 'tasks'
            subpath = parts[1]   # 'ANALYSIS' o 'profiles[payload.id]'
            
            # Manejar indexación dinámica
            bracket_match = re.match(r'([a-zA-Z0-9_]+)\[payload\.([a-zA-Z0-9_]+)\]', subpath)
            if bracket_match:
                file_name = bracket_match.group(1)
                index_key = bracket_match.group(2)
                index_value = payload.get(index_key)
                
                data = self._load_json_file(category, file_name)
                value = data.get(index_value, f"[Error: {file_name}[{index_value}] no encontrado]")
            else:
                # Carga directa del archivo
                data = self._load_json_file(category, subpath)
                value = data
            
            # Aplicar pipe si existe
            if pipe == 'validate_output':
                context.expected_schema = value
                return json.dumps(value, indent=2, ensure_ascii=False)
            
            # Si es un objeto/dict, convertir a JSON string
            if isinstance(value, (dict, list)):
                return json.dumps(value, indent=2, ensure_ascii=False)
            
            return str(value)

        return match.group(0)  # No cambiar si no se pudo resolver

    def resolve_prompt(self, category: str, name: str, payload: Dict[str, Any]) -> Tuple[str, PromptContext]:
        """Resuelve un prompt completo con todos sus tags."""
        context = PromptContext()
        
        # Cargar el template base
        template_data = self._load_json_file(category, name)
        if not template_data or 'main' not in template_data:
            return f"Error: Prompt '{name}' no encontrado en '{category}'", context
        
        template = template_data['main']
        
        # Resolver todos los tags
        resolved = self.tag_pattern.sub(
            lambda m: self._resolve_tag(m, payload, context),
            template
        )
        
        return resolved, context

prompt_manager = PromptManager()
