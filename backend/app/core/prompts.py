import os
import json
from typing import Dict, Any

class PromptManager:
    """Gestiona la carga y formateo de prompts desde archivos para evitar hardcoding."""
    
    def __init__(self, prompts_dir: str = "prompts"):
        self.prompts_dir = prompts_dir
        if not os.path.exists(self.prompts_dir):
            os.makedirs(self.prompts_dir)

    def get_prompt(self, category: str, name: str, variables: Dict[str, Any] = None) -> str:
        """Carga un prompt y reemplaza las variables indicadas."""
        file_path = os.path.join(self.prompts_dir, f"{category}.json")
        
        if not os.path.exists(file_path):
            return f"Error: Categoría de prompt '{category}' no encontrada."
            
        with open(file_path, 'r', encoding='utf-8') as f:
            prompts = json.load(f)
            
        prompt_template = prompts.get(name)
        if not prompt_template:
            return f"Error: Prompt '{name}' no encontrado en la categoría '{category}'."
            
        if variables:
            try:
                return prompt_template.format(**variables)
            except KeyError as e:
                return f"Error: Falta la variable {e} para el prompt {name}."
                
        return prompt_template

prompt_manager = PromptManager()
