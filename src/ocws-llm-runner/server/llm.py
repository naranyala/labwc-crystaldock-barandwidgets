"""
LLM inference engine using llama-cpp-python.
Local-first, no cloud dependencies.
"""

import os
from typing import List, Dict, Optional, Generator


# Recommended models for different tasks
RECOMMENDED_MODELS = {
    "coding": [
        {
            "name": "Qwen2.5-Coder-1.5B",
            "size": "1.5B",
            "ram": "~2GB",
            "quant": "Q4_K_M",
            "best_for": "Code completion, debugging",
            "url": "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            "filename": "qwen2.5-coder-1.5b.gguf"
        },
        {
            "name": "DeepSeek-Coder-V2-Lite",
            "size": "2.7B",
            "ram": "~3GB",
            "quant": "Q4_K_M",
            "best_for": "Code generation, refactoring",
            "url": "https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct-GGUF/resolve/main/DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf",
            "filename": "deepseek-coder-v2-lite.gguf"
        },
        {
            "name": "Phi-3-mini-4k",
            "size": "3.8B",
            "ram": "~4GB",
            "quant": "Q4_K_M",
            "best_for": "General coding, reasoning",
            "url": "https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/resolve/main/Phi-3-mini-4k-instruct-Q4_K_M.gguf",
            "filename": "phi-3-mini-4k.gguf"
        },
    ],
    "vision": [
        {
            "name": "Llama-3.2-1B-Vision",
            "size": "1B",
            "ram": "~2GB",
            "quant": "Q4_K_M",
            "best_for": "Image understanding, OCR",
            "url": "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            "filename": "llama-3.2-1b-vision.gguf"
        },
        {
            "name": "LLaVA-1.6-7B",
            "size": "7B",
            "ram": "~6GB",
            "quant": "Q4_K_M",
            "best_for": "Visual QA, screenshot analysis",
            "url": "https://huggingface.co/mradermacher/llava-v1.6-mistral-7b-GGUF/resolve/main/llava-v1.6-mistral-7b.Q4_K_M.gguf",
            "filename": "llava-1.6-7b.gguf"
        },
    ],
    "lightweight": [
        {
            "name": "TinyLlama-1.1B",
            "size": "1.1B",
            "ram": "~1GB",
            "quant": "Q4_K_M",
            "best_for": "Quick tests, low RAM",
            "url": "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            "filename": "tinyllama-1.1b.gguf"
        },
    ]
}


class LLMEngine:
    """Local LLM inference engine."""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.model_path = None
        self.is_loaded = False
        
        if model_path and os.path.exists(model_path):
            self.load_model(model_path)
    
    def get_recommended_models(self) -> Dict:
        """Get list of recommended models."""
        return RECOMMENDED_MODELS
    
    def load_model(self, path: str) -> bool:
        """Load a GGUF model."""
        try:
            from llama_cpp import Llama
            
            if not os.path.exists(path):
                print(f"[llm] Model not found: {path}")
                return False
            
            print(f"[llm] Loading model: {path}")
            self.model = Llama(
                model_path=path,
                n_ctx=4096,
                n_threads=os.cpu_count() or 4,
                verbose=False
            )
            self.model_path = path
            self.is_loaded = True
            print(f"[llm] Model loaded successfully")
            return True
            
        except ImportError:
            print("[llm] llama-cpp-python not installed")
            print("[llm] Install with: pip install llama-cpp-python")
            return False
        except Exception as e:
            print(f"[llm] Failed to load model: {e}")
            return False
    
    def _build_prompt(self, history: List[Dict], system_prompt: str = "") -> str:
        """Build prompt from conversation history."""
        prompt_parts = []
        
        if system_prompt:
            prompt_parts.append(f"System: {system_prompt}")
        
        for msg in history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            
            if role == "user":
                prompt_parts.append(f"User: {content}")
            elif role == "assistant":
                prompt_parts.append(f"Assistant: {content}")
        
        prompt_parts.append("Assistant:")
        return "\n".join(prompt_parts)
    
    def chat(self, history: List[Dict], system_prompt: str = "", 
             max_tokens: int = 2048, temperature: float = 0.7) -> str:
        """Generate a chat response."""
        if not self.is_loaded or not self.model:
            return "[No model loaded]"
        
        try:
            prompt = self._build_prompt(history, system_prompt)
            
            response = self.model(
                prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                stop=["User:", "System:"],
                echo=False
            )
            
            return response["choices"][0]["text"].strip()
            
        except Exception as e:
            return f"[Error: {str(e)}]"
    
    def chat_stream(self, history: List[Dict], system_prompt: str = "",
                    max_tokens: int = 2048, temperature: float = 0.7) -> Generator[str, None, None]:
        """Stream a chat response token by token."""
        if not self.is_loaded or not self.model:
            yield "[No model loaded]"
            return
        
        try:
            prompt = self._build_prompt(history, system_prompt)
            
            for token in self.model(
                prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                stop=["User:", "System:"],
                echo=False,
                stream=True
            ):
                text = token["choices"][0]["text"]
                if text:
                    yield text
                    
        except Exception as e:
            yield f"[Error: {str(e)}]"
    
    def unload(self):
        """Unload the current model."""
        self.model = None
        self.model_path = None
        self.is_loaded = False
        print("[llm] Model unloaded")
