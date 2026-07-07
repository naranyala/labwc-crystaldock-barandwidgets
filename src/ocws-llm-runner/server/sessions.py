"""
Session manager for ocws-llm-runner.
Handles conversation persistence and session lifecycle.
"""

import os
import json
import uuid
from datetime import datetime
from typing import List, Dict, Optional


class SessionManager:
    """Manages chat sessions with persistence."""
    
    def __init__(self, data_dir: str):
        self.data_dir = data_dir
        self.sessions_dir = os.path.join(data_dir, "sessions")
        self.meta_file = os.path.join(data_dir, "meta.json")
        os.makedirs(self.sessions_dir, exist_ok=True)
        self._meta = self._load_meta()
    
    def _load_meta(self) -> Dict:
        """Load metadata (active session, etc.)."""
        if os.path.exists(self.meta_file):
            try:
                with open(self.meta_file, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return {"active_session": None, "last_model": None}
    
    def _save_meta(self):
        """Save metadata."""
        with open(self.meta_file, "w") as f:
            json.dump(self._meta, f, indent=2)
    
    def _session_path(self, session_id: str) -> str:
        """Get path to session file."""
        return os.path.join(self.sessions_dir, f"{session_id}.json")
    
    def _load_session(self, session_id: str) -> Optional[Dict]:
        """Load a session from disk."""
        path = self._session_path(session_id)
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return None
    
    def _save_session(self, session_id: str, session: Dict):
        """Save a session to disk."""
        path = self._session_path(session_id)
        with open(path, "w") as f:
            json.dump(session, f, indent=2)
    
    def create_session(self, name: str = None, history: List = None) -> str:
        """Create a new session."""
        session_id = str(uuid.uuid4())[:8]
        
        if name is None:
            name = f"Session {datetime.now().strftime('%Y-%m-%d %H:%M')}"
        
        session = {
            "id": session_id,
            "name": name,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "history": history or [],
            "message_count": len(history) if history else 0,
        }
        
        self._save_session(session_id, session)
        return session_id
    
    def get_session(self, session_id: str) -> Optional[Dict]:
        """Get a session by ID."""
        return self._load_session(session_id)
    
    def list_sessions(self) -> List[Dict]:
        """List all sessions (metadata only, no history)."""
        sessions = []
        if os.path.isdir(self.sessions_dir):
            for f in os.listdir(self.sessions_dir):
                if f.endswith(".json"):
                    session_id = f[:-5]
                    session = self._load_session(session_id)
                    if session:
                        sessions.append({
                            "id": session["id"],
                            "name": session["name"],
                            "created_at": session.get("created_at"),
                            "updated_at": session.get("updated_at"),
                            "message_count": session.get("message_count", 0),
                        })
        
        # Sort by updated_at descending
        sessions.sort(key=lambda s: s.get("updated_at", ""), reverse=True)
        return sessions
    
    def delete_session(self, session_id: str):
        """Delete a session."""
        path = self._session_path(session_id)
        if os.path.exists(path):
            os.remove(path)
        
        # Clear active if it was the deleted session
        if self._meta.get("active_session") == session_id:
            self._meta["active_session"] = None
            self._save_meta()
    
    def rename_session(self, session_id: str, name: str):
        """Rename a session."""
        session = self._load_session(session_id)
        if session:
            session["name"] = name
            session["updated_at"] = datetime.now().isoformat()
            self._save_session(session_id, session)
    
    def get_history(self, session_id: str) -> List[Dict]:
        """Get chat history for a session."""
        session = self._load_session(session_id)
        if session:
            return session.get("history", [])
        return []
    
    def save_history(self, session_id: str, history: List[Dict]):
        """Save chat history to a session."""
        session = self._load_session(session_id)
        if session is None:
            # Auto-create session if it doesn't exist
            session = {
                "id": session_id,
                "name": f"Session {datetime.now().strftime('%Y-%m-%d %H:%M')}",
                "created_at": datetime.now().isoformat(),
            }
        
        session["history"] = history
        session["message_count"] = len(history)
        session["updated_at"] = datetime.now().isoformat()
        self._save_session(session_id, session)
    
    def count_sessions(self) -> int:
        """Count total sessions."""
        if os.path.isdir(self.sessions_dir):
            return len([f for f in os.listdir(self.sessions_dir) if f.endswith(".json")])
        return 0
    
    def get_active_session_id(self) -> Optional[str]:
        """Get current active session ID."""
        return self._meta.get("active_session")
    
    def set_active_session(self, session_id: str):
        """Set active session."""
        self._meta["active_session"] = session_id
        self._save_meta()
    
    def get_or_create_active(self) -> str:
        """Get active session or create a new one."""
        active_id = self._meta.get("active_session")
        
        if active_id and self._load_session(active_id):
            return active_id
        
        # Create new session
        session_id = self.create_session()
        self._meta["active_session"] = session_id
        self._save_meta()
        return session_id
    
    def clear_active(self):
        """Clear active session (create fresh one)."""
        self._meta["active_session"] = None
        self._save_meta()
    
    def set_meta(self, key: str, value):
        """Set a metadata value."""
        self._meta[key] = value
        self._save_meta()
    
    def get_meta(self, key: str, default=None):
        """Get a metadata value."""
        return self._meta.get(key, default)
