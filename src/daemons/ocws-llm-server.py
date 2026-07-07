#!/usr/bin/env python3
import sys
import json
import threading
import time
import os

try:
    from llama_cpp import Llama
    HAS_LLAMA = True
except ImportError:
    HAS_LLAMA = False

class LLMServer:
    def __init__(self):
        self.llm = None
        self.model_path = None
        self.history = []
        
    def send_msg(self, msg_dict):
        sys.stdout.write(json.dumps(msg_dict) + "\n")
        sys.stdout.flush()

    def load_model(self, path):
        if self.llm is not None:
            self.eject_model()
            
        if not os.path.exists(path):
            self.send_msg({"type": "error", "text": f"Model not found: {path}"})
            return
            
        self.send_msg({"type": "status", "text": f"Loading model {os.path.basename(path)}..."})
        try:
            if HAS_LLAMA:
                # Basic initialization, can be expanded with GPU offload config
                self.llm = Llama(model_path=path, n_ctx=4096, n_threads=4, verbose=False)
            self.model_path = path
            self.send_msg({"type": "status", "text": f"Model {os.path.basename(path)} loaded successfully."})
        except Exception as e:
            self.send_msg({"type": "error", "text": f"Failed to load model: {str(e)}"})

    def eject_model(self):
        if self.llm:
            del self.llm
            self.llm = None
        self.model_path = None
        self.send_msg({"type": "status", "text": "Model ejected from memory."})

    def clear_session(self):
        self.history = []
        self.send_msg({"type": "status", "text": "Session cleared."})

    def process_prompt(self, text):
        if not self.model_path:
            self.send_msg({"type": "error", "text": "No model loaded. Please load a model first."})
            self.send_msg({"type": "done"})
            return

        self.history.append({"role": "user", "content": text})
        
        if not HAS_LLAMA:
            # Mock processing
            time.sleep(0.5)
            words = f"This is a mock response from {os.path.basename(self.model_path)} (llama-cpp-python not installed). You said: '{text}'".split(" ")
            response_text = ""
            for word in words:
                self.send_msg({"type": "chunk", "text": word + " "})
                response_text += word + " "
                time.sleep(0.05)
            self.history.append({"role": "assistant", "content": response_text})
            self.send_msg({"type": "done"})
            return

        # Real inference
        try:
            # Simple chat completion wrapper
            stream = self.llm.create_chat_completion(
                messages=self.history,
                stream=True,
                max_tokens=1024
            )
            full_response = ""
            for chunk in stream:
                if "choices" in chunk and len(chunk["choices"]) > 0:
                    delta = chunk["choices"][0].get("delta", {})
                    content = delta.get("content", "")
                    if content:
                        self.send_msg({"type": "chunk", "text": content})
                        full_response += content
            
            self.history.append({"role": "assistant", "content": full_response})
        except Exception as e:
            self.send_msg({"type": "error", "text": f"Inference error: {str(e)}"})
            
        self.send_msg({"type": "done"})

def main():
    server = LLMServer()
    server.send_msg({"type": "status", "text": "ready"})

    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
                
            req = json.loads(line)
            req_type = req.get("type")
            
            if req_type == "prompt":
                server.process_prompt(req.get("text", ""))
            elif req_type == "load":
                server.load_model(req.get("path", ""))
            elif req_type == "eject":
                server.eject_model()
            elif req_type == "clear":
                server.clear_session()
                
        except json.JSONDecodeError:
            pass
        except KeyboardInterrupt:
            break

if __name__ == "__main__":
    main()
