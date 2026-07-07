# ocws-llm-runner

Local-first LLM chat and OCR assistant for OCWS desktop shell.

## Features

- **Local LLM Chat**: Chat with local GGUF models via llama-cpp-python
- **Model Management**: Load, eject, switch, download models easily
- **Session Manager**: Multiple conversations, persistence, export/import
- **OCR Integration**: Capture screen regions or OCR image files
- **GTK3 GUI**: Native glassmorphic interface matching OCWS theme
- **Server Controls**: Start/stop server from GUI
- **REST API**: Full API for headless/scripted usage

## Requirements

- Python 3.8+
- GTK3 development files (`libgtk-3-dev` on Debian/Ubuntu)
- Tesseract OCR (`tesseract-ocr` package)

## Installation

```bash
pip install -r requirements.txt
sudo apt install tesseract-ocr
```

## Usage

```bash
# Start with GUI + server
./ocws-llm-runner

# Start server only
./ocws-llm-runner --server-only

# Start GUI only (connect to existing server)
./ocws-llm-runner --gui-only

# OCR a single image
./ocws-llm-runner --ocr image.png

# Specify model on startup
./ocws-llm-runner --model ~/.local/share/ocws/models/model.gguf
```

## GUI Features

### Left Sidebar
- **Sessions**: Create, switch, rename, delete, export sessions
- **Model Management**: Load, eject, switch models quickly
- **Quick Switch**: Dropdown to switch between downloaded models
- **System Prompt**: Edit system prompt for the AI

### Header Bar
- **Server Status**: Green/red indicator showing server state
- **Start/Stop**: Control server from GUI
- **Refresh**: Update all status info

### Chat Area
- **Messages**: User (blue), Assistant (gray), System (yellow)
- **Input**: Enter to send, Shift+Enter for newline
- **OCR Button**: Quick access to screen region OCR

## API Endpoints

### Model Management
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/models` | GET | List available models |
| `/api/model/load` | POST | Load a GGUF model |
| `/api/model/eject` | POST | Unload current model |
| `/api/model/switch` | POST | Switch to different model |
| `/api/model/download` | POST | Download model from URL |
| `/api/model/delete` | POST | Delete a model file |

### Session Management
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sessions` | GET | List all sessions |
| `/api/sessions` | POST | Create new session |
| `/api/sessions/<id>` | GET | Get session details |
| `/api/sessions/<id>` | PUT | Update session name |
| `/api/sessions/<id>` | DELETE | Delete session |
| `/api/sessions/<id>/history` | GET | Get chat history |
| `/api/sessions/<id>/history` | DELETE | Clear chat history |
| `/api/sessions/active` | GET | Get active session |
| `/api/sessions/active` | PUT | Set active session |

### Chat
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/chat` | POST | Send message |
| `/api/chat/stream` | POST | Stream response |

### OCR
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/ocr` | POST | OCR uploaded image |
| `/api/ocr/region` | POST | Capture region and OCR |

### Export/Import
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/export/session/<id>` | GET | Export session as JSON |
| `/api/import/session` | POST | Import session from JSON |

## Recommended Models

### For Coding
| Model | RAM | Best For |
|-------|-----|----------|
| Qwen2.5-Coder-1.5B | ~2GB | Code completion, debugging |
| DeepSeek-Coder-V2-Lite | ~3GB | Code generation, refactoring |
| Phi-3-mini-4k | ~4GB | General coding, reasoning |

### For OCR/Vision
| Model | RAM | Best For |
|-------|-----|----------|
| Llama-3.2-1B-Vision | ~2GB | Image understanding |
| LLaVA-1.6-7B | ~6GB | Visual QA, screenshots |

### Lightweight
| Model | RAM | Best For |
|-------|-----|----------|
| TinyLlama-1.1B | ~1GB | Quick tests, low RAM |

## Project Structure

```
ocws-llm-runner/
├── main.py              # Entry point
├── requirements.txt     # Python dependencies
├── ocws-llm-runner     # Launcher script
├── server/
│   ├── app.py           # Flask REST API
│   ├── llm.py           # LLM inference engine
│   ├── ocr.py           # OCR processor
│   └── sessions.py      # Session manager
├── gui/
│   └── app.py           # GTK3 GUI
└── utils/
    └── __init__.py
```

## Data Storage

Sessions and settings are stored in:
```
~/.local/share/ocws/llm-runner/
├── meta.json           # Active session, last model
├── sessions/           # Session files
│   ├── abc123.json
│   └── def456.json
└── models/             # Downloaded models
    └── model.gguf
```

## License

Part of the OCWS desktop shell project.
