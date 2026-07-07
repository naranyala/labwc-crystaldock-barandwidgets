#!/usr/bin/env python3
"""
ocws-llm-runner — Local-first LLM chat and OCR assistant
GTK3 GUI with Python server backend

Usage:
    python main.py                    # Start GUI + server
    python main.py --server-only      # Start server only
    python main.py --gui-only         # Start GUI only (connect to existing server)
    python main.py --ocr <image>      # OCR a single image
"""

import argparse
import sys
import os
import signal
import threading

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def run_server(port=5000, model_path=None, data_dir=None):
    """Run the Flask server for LLM inference."""
    from server.app import create_app
    
    app = create_app(model_path=model_path, data_dir=data_dir)
    print(f"[ocws-llm-runner] Server starting on http://127.0.0.1:{port}")
    app.run(host="127.0.0.1", port=port, debug=False, use_reloader=False)


def run_gui(port=5000):
    """Run the GTK3 GUI."""
    from gui.app import LLMRunnerApp
    
    app = LLMRunnerApp(port=port)
    app.run()


def run_ocr(image_path, lang="eng"):
    """Run OCR on a single image."""
    from server.ocr import OCRProcessor
    
    processor = OCRProcessor()
    text = processor.ocr_file(image_path, lang=lang)
    if text:
        print(text)
        return 0
    else:
        print("OCR failed or no text detected", file=sys.stderr)
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="ocws-llm-runner — Local-first LLM chat and OCR assistant"
    )
    parser.add_argument("--server-only", action="store_true",
                        help="Start server only (no GUI)")
    parser.add_argument("--gui-only", action="store_true",
                        help="Start GUI only (connect to existing server)")
    parser.add_argument("--port", type=int, default=5000,
                        help="Server port (default: 5000)")
    parser.add_argument("--model", type=str, default=None,
                        help="Path to GGUF model file")
    parser.add_argument("--data-dir", type=str, default=None,
                        help="Data directory (default: ~/.local/share/ocws/llm-runner)")
    parser.add_argument("--ocr", type=str, metavar="IMAGE",
                        help="OCR a single image and exit")
    parser.add_argument("--lang", type=str, default="eng",
                        help="OCR language (default: eng)")
    
    args = parser.parse_args()
    
    # Default data directory
    data_dir = args.data_dir or os.path.expanduser("~/.local/share/ocws/llm-runner")
    
    # Handle OCR mode
    if args.ocr:
        return run_ocr(args.ocr, lang=args.lang)
    
    # Handle signal for clean shutdown
    def signal_handler(sig, frame):
        print("\n[ocws-llm-runner] Shutting down...")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    if args.server_only:
        run_server(port=args.port, model_path=args.model, data_dir=data_dir)
    elif args.gui_only:
        run_gui(port=args.port)
    else:
        # Start server in background thread, then GUI
        server_thread = threading.Thread(
            target=run_server,
            args=(args.port, args.model, data_dir),
            daemon=True
        )
        server_thread.start()
        
        # Give server a moment to start
        import time
        time.sleep(0.5)
        
        # Run GUI (blocking)
        run_gui(port=args.port)


if __name__ == "__main__":
    sys.exit(main() or 0)
