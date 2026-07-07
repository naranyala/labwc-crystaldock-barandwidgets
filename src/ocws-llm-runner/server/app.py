"""
Flask server for ocws-llm-runner.
Provides REST API for LLM inference, OCR, model management, and sessions.
"""

import os
import json
import time
import uuid
import shutil
import threading
from datetime import datetime
from flask import Flask, request, jsonify, Response
from flask_cors import CORS

from .llm import LLMEngine
from .ocr import OCRProcessor
from .sessions import SessionManager


def create_app(model_path=None, data_dir=None):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    CORS(app)
    
    # Data directory for sessions and settings
    if data_dir is None:
        data_dir = os.path.expanduser("~/.local/share/ocws/llm-runner")
    os.makedirs(data_dir, exist_ok=True)
    os.makedirs(os.path.join(data_dir, "sessions"), exist_ok=True)
    os.makedirs(os.path.join(data_dir, "models"), exist_ok=True)
    
    # Initialize engines
    llm = LLMEngine(model_path=model_path)
    ocr = OCRProcessor()
    sessions = SessionManager(data_dir)
    
    # Server state
    server_state = {
        "started_at": datetime.now().isoformat(),
        "requests_served": 0,
        "total_tokens": 0,
    }
    
    def increment_requests():
        server_state["requests_served"] += 1
    
    # ============================================================
    # Health & Status
    # ============================================================
    
    @app.route("/api/health", methods=["GET"])
    def health():
        """Health check endpoint."""
        return jsonify({
            "status": "ok",
            "llm_loaded": llm.is_loaded,
            "model_path": llm.model_path,
            "model_name": os.path.basename(llm.model_path) if llm.model_path else None,
            "uptime": (datetime.now() - datetime.fromisoformat(server_state["started_at"])).seconds,
            "requests_served": server_state["requests_served"],
        })
    
    @app.route("/api/status", methods=["GET"])
    def status():
        """Detailed server status."""
        return jsonify({
            "status": "running",
            "started_at": server_state["started_at"],
            "llm": {
                "loaded": llm.is_loaded,
                "model_path": llm.model_path,
                "model_name": os.path.basename(llm.model_path) if llm.model_path else None,
                "model_size": os.path.getsize(llm.model_path) if llm.model_path and os.path.exists(llm.model_path) else 0,
            },
            "ocr": {
                "tesseract_available": ocr.tesseract_available,
                "ocws_ocr_available": ocr.ocws_ocr_available,
            },
            "sessions": {
                "total": sessions.count_sessions(),
                "active": sessions.get_active_session_id(),
            },
            "stats": {
                "requests_served": server_state["requests_served"],
            }
        })
    
    # ============================================================
    # Model Management
    # ============================================================
    
    @app.route("/api/models", methods=["GET"])
    def list_models():
        """List available models on disk."""
        models = []
        
        search_dirs = [
            os.path.join(data_dir, "models"),
            os.path.expanduser("~/.local/share/ocws/models"),
            os.path.expanduser("~/.cache/ocws/models"),
            "/usr/share/ocws/models",
        ]
        
        seen_paths = set()
        for d in search_dirs:
            if os.path.isdir(d):
                for f in os.listdir(d):
                    if f.endswith(".gguf"):
                        full_path = os.path.join(d, f)
                        if full_path not in seen_paths:
                            seen_paths.add(full_path)
                            size = os.path.getsize(full_path)
                            models.append({
                                "name": f,
                                "path": full_path,
                                "size": size,
                                "size_human": _human_size(size),
                                "loaded": full_path == llm.model_path,
                            })
        
        recommendations = llm.get_recommended_models()
        
        return jsonify({
            "models": sorted(models, key=lambda m: m["name"]),
            "recommendations": recommendations,
            "current_model": llm.model_path,
        })
    
    @app.route("/api/model/load", methods=["POST"])
    def load_model():
        """Load a GGUF model."""
        data = request.get_json()
        path = data.get("path")
        
        if not path:
            return jsonify({"error": "No model path provided"}), 400
        
        if not os.path.exists(path):
            return jsonify({"error": f"Model not found: {path}"}), 404
        
        # Eject current model first if loaded
        if llm.is_loaded:
            llm.unload()
        
        success = llm.load_model(path)
        if success:
            sessions.set_meta("last_model", path)
            return jsonify({
                "status": "loaded",
                "path": path,
                "name": os.path.basename(path),
                "size": os.path.getsize(path),
            })
        else:
            return jsonify({"error": "Failed to load model"}), 500
    
    @app.route("/api/model/eject", methods=["POST"])
    def eject_model():
        """Unload the current model."""
        if llm.is_loaded:
            model_name = os.path.basename(llm.model_path)
            llm.unload()
            return jsonify({"status": "ejected", "model": model_name})
        else:
            return jsonify({"status": "no_model_loaded"})
    
    @app.route("/api/model/switch", methods=["POST"])
    def switch_model():
        """Switch to a different model (eject current, load new)."""
        data = request.get_json()
        path = data.get("path")
        
        if not path:
            return jsonify({"error": "No model path provided"}), 400
        
        if not os.path.exists(path):
            return jsonify({"error": f"Model not found: {path}"}), 404
        
        # Eject current
        old_model = None
        if llm.is_loaded:
            old_model = os.path.basename(llm.model_path)
            llm.unload()
        
        # Load new
        success = llm.load_model(path)
        if success:
            sessions.set_meta("last_model", path)
            return jsonify({
                "status": "switched",
                "from": old_model,
                "to": os.path.basename(path),
                "path": path,
            })
        else:
            return jsonify({"error": "Failed to load new model"}), 500
    
    @app.route("/api/model/download", methods=["POST"])
    def download_model():
        """Download a model from URL."""
        data = request.get_json()
        url = data.get("url")
        filename = data.get("filename")
        
        if not url:
            return jsonify({"error": "No URL provided"}), 400
        
        if not filename:
            filename = url.split("/")[-1]
        
        model_dir = os.path.join(data_dir, "models")
        os.makedirs(model_dir, exist_ok=True)
        filepath = os.path.join(model_dir, filename)
        
        # Start download in background
        def do_download():
            try:
                import urllib.request
                urllib.request.urlretrieve(url, filepath)
                print(f"[server] Downloaded: {filename}")
            except Exception as e:
                print(f"[server] Download failed: {e}")
                if os.path.exists(filepath):
                    os.unlink(filepath)
        
        thread = threading.Thread(target=do_download, daemon=True)
        thread.start()
        
        return jsonify({
            "status": "downloading",
            "filename": filename,
            "filepath": filepath,
        })
    
    @app.route("/api/model/delete", methods=["POST"])
    def delete_model():
        """Delete a model file."""
        data = request.get_json()
        path = data.get("path")
        
        if not path:
            return jsonify({"error": "No path provided"}), 400
        
        # Don't delete loaded model
        if path == llm.model_path:
            return jsonify({"error": "Cannot delete loaded model. Eject first."}), 400
        
        if os.path.exists(path):
            os.remove(path)
            return jsonify({"status": "deleted", "path": path})
        else:
            return jsonify({"error": "File not found"}), 404
    
    # ============================================================
    # Chat
    # ============================================================
    
    @app.route("/api/chat", methods=["POST"])
    def chat():
        """Send a chat message and get a response."""
        increment_requests()
        data = request.get_json()
        message = data.get("message", "")
        session_id = data.get("session_id")
        system_prompt = data.get("system_prompt", "")
        
        if not message:
            return jsonify({"error": "No message provided"}), 400
        
        # Use session manager for history
        if session_id is None:
            session_id = sessions.get_or_create_active()
        
        history = sessions.get_history(session_id)
        
        # Add user message
        history.append({"role": "user", "content": message})
        
        # Generate response
        if llm.is_loaded:
            response = llm.chat(history, system_prompt=system_prompt)
        else:
            response = "[No model loaded. Load a model first via /api/model/load]"
        
        # Add assistant response
        history.append({"role": "assistant", "content": response})
        
        # Save to session
        sessions.save_history(session_id, history)
        
        return jsonify({
            "response": response,
            "session_id": session_id,
        })
    
    @app.route("/api/chat/stream", methods=["POST"])
    def chat_stream():
        """Send a chat message and stream the response."""
        increment_requests()
        data = request.get_json()
        message = data.get("message", "")
        session_id = data.get("session_id")
        system_prompt = data.get("system_prompt", "")
        
        if not message:
            return jsonify({"error": "No message provided"}), 400
        
        if session_id is None:
            session_id = sessions.get_or_create_active()
        
        history = sessions.get_history(session_id)
        history.append({"role": "user", "content": message})
        
        def generate():
            full_response = []
            for token in llm.chat_stream(history, system_prompt=system_prompt):
                full_response.append(token)
                yield f"data: {json.dumps({'token': token})}\n\n"
            
            complete_response = "".join(full_response)
            history.append({"role": "assistant", "content": complete_response})
            sessions.save_history(session_id, history)
            
            yield f"data: {json.dumps({'done': True, 'session_id': session_id})}\n\n"
        
        return Response(generate(), mimetype="text/event-stream")
    
    # ============================================================
    # Session Management
    # ============================================================
    
    @app.route("/api/sessions", methods=["GET"])
    def list_sessions():
        """List all sessions."""
        session_list = sessions.list_sessions()
        return jsonify({
            "sessions": session_list,
            "active": sessions.get_active_session_id(),
        })
    
    @app.route("/api/sessions", methods=["POST"])
    def create_session():
        """Create a new session."""
        data = request.get_json() or {}
        name = data.get("name", f"Session {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        session_id = sessions.create_session(name)
        return jsonify({
            "session_id": session_id,
            "name": name,
        })
    
    @app.route("/api/sessions/<session_id>", methods=["GET"])
    def get_session(session_id):
        """Get session details and history."""
        session = sessions.get_session(session_id)
        if session:
            return jsonify(session)
        return jsonify({"error": "Session not found"}), 404
    
    @app.route("/api/sessions/<session_id>", methods=["PUT"])
    def update_session(session_id):
        """Update session metadata."""
        data = request.get_json()
        name = data.get("name")
        if name:
            sessions.rename_session(session_id, name)
            return jsonify({"status": "updated"})
        return jsonify({"error": "No updates provided"}), 400
    
    @app.route("/api/sessions/<session_id>", methods=["DELETE"])
    def delete_session(session_id):
        """Delete a session."""
        sessions.delete_session(session_id)
        return jsonify({"status": "deleted"})
    
    @app.route("/api/sessions/<session_id>/history", methods=["GET"])
    def get_session_history(session_id):
        """Get session chat history."""
        history = sessions.get_history(session_id)
        return jsonify({
            "session_id": session_id,
            "history": history,
        })
    
    @app.route("/api/sessions/<session_id>/history", methods=["DELETE"])
    def clear_session_history(session_id):
        """Clear session chat history."""
        sessions.save_history(session_id, [])
        return jsonify({"status": "cleared"})
    
    @app.route("/api/sessions/active", methods=["GET"])
    def get_active_session():
        """Get or create active session."""
        session_id = sessions.get_or_create_active()
        session = sessions.get_session(session_id)
        return jsonify(session)
    
    @app.route("/api/sessions/active", methods=["PUT"])
    def set_active_session():
        """Set active session."""
        data = request.get_json()
        session_id = data.get("session_id")
        if session_id:
            sessions.set_active_session(session_id)
            return jsonify({"status": "active", "session_id": session_id})
        return jsonify({"error": "No session_id provided"}), 400
    
    @app.route("/api/sessions/active", methods=["DELETE"])
    def clear_active_session():
        """Clear active session (start fresh)."""
        sessions.clear_active()
        return jsonify({"status": "cleared"})
    
    # ============================================================
    # OCR
    # ============================================================
    
    @app.route("/api/ocr", methods=["POST"])
    def ocr_image():
        """OCR an uploaded image."""
        increment_requests()
        if "image" not in request.files:
            return jsonify({"error": "No image provided"}), 400
        
        image_file = request.files["image"]
        lang = request.form.get("lang", "eng")
        
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            image_file.save(tmp.name)
            text = ocr.ocr_file(tmp.name, lang=lang)
            os.unlink(tmp.name)
        
        if text:
            return jsonify({"text": text})
        else:
            return jsonify({"error": "OCR failed"}), 500
    
    @app.route("/api/ocr/region", methods=["POST"])
    def ocr_region():
        """Capture screen region and OCR it."""
        increment_requests()
        lang = request.form.get("lang", "eng")
        text = ocr.capture_region(lang=lang)
        
        if text:
            return jsonify({"text": text})
        else:
            return jsonify({"error": "OCR failed or no text detected"}), 500
    
    # ============================================================
    # Export / Import
    # ============================================================
    
    @app.route("/api/export/session/<session_id>", methods=["GET"])
    def export_session(session_id):
        """Export session as JSON."""
        session = sessions.get_session(session_id)
        if session:
            return jsonify(session)
        return jsonify({"error": "Session not found"}), 404
    
    @app.route("/api/import/session", methods=["POST"])
    def import_session():
        """Import session from JSON."""
        data = request.get_json()
        name = data.get("name", "Imported Session")
        history = data.get("history", [])
        
        session_id = sessions.create_session(name, history=history)
        return jsonify({
            "session_id": session_id,
            "name": name,
            "messages": len(history),
        })
    
    return app


def _human_size(size_bytes):
    """Convert bytes to human readable string."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"
