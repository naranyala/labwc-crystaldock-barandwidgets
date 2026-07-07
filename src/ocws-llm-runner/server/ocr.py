"""
OCR processor for ocws-llm-runner.
Uses Tesseract via pytesseract, with fallback to ocws-ocr binary.
"""

import os
import subprocess
import tempfile
from typing import Optional


class OCRProcessor:
    """OCR processor with multiple backend support."""
    
    def __init__(self):
        self.tesseract_available = self._check_tesseract()
        self.ocws_ocr_available = self._check_ocws_ocr()
    
    def _check_tesseract(self) -> bool:
        """Check if pytesseract is available."""
        try:
            import pytesseract
            # Test if tesseract binary exists
            pytesseract.get_tesseract_version()
            return True
        except Exception:
            return False
    
    def _check_ocws_ocr(self) -> bool:
        """Check if ocws-ocr binary is available."""
        try:
            result = subprocess.run(
                ["which", "ocws-ocr"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception:
            return False
    
    def ocr_file(self, image_path: str, lang: str = "eng") -> Optional[str]:
        """OCR an image file."""
        if not os.path.exists(image_path):
            print(f"[ocr] Image not found: {image_path}")
            return None
        
        # Try pytesseract first
        if self.tesseract_available:
            return self._ocr_tesseract(image_path, lang)
        
        # Fallback to ocws-ocr
        if self.ocws_ocr_available:
            return self._ocr_ocws(image_path, lang)
        
        print("[ocr] No OCR backend available")
        print("[ocr] Install pytesseract: pip install pytesseract")
        print("[ocr] Or install ocws-ocr from OCWS")
        return None
    
    def _ocr_tesseract(self, image_path: str, lang: str) -> Optional[str]:
        """OCR using pytesseract."""
        try:
            import pytesseract
            from PIL import Image
            
            image = Image.open(image_path)
            text = pytesseract.image_to_string(image, lang=lang)
            return text.strip() if text else None
            
        except Exception as e:
            print(f"[ocr] Tesseract error: {e}")
            return None
    
    def _ocr_ocws(self, image_path: str, lang: str) -> Optional[str]:
        """OCR using ocws-ocr binary."""
        try:
            result = subprocess.run(
                ["ocws-ocr", "-l", lang, image_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
            return None
            
        except Exception as e:
            print(f"[ocr] ocws-ocr error: {e}")
            return None
    
    def capture_region(self, lang: str = "eng") -> Optional[str]:
        """Capture screen region and OCR it."""
        # Try ocws-ocr first (has region capture built-in)
        if self.ocws_ocr_available:
            try:
                result = subprocess.run(
                    ["ocws-ocr", "-l", lang],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode == 0 and result.stdout.strip():
                    return result.stdout.strip()
                    
            except Exception as e:
                print(f"[ocr] ocws-ocr capture error: {e}")
        
        # Fallback: use grim+slurp then OCR
        try:
            # Check for screenshot tools
            grim_available = subprocess.run(
                ["which", "grim"], capture_output=True
            ).returncode == 0
            
            slurp_available = subprocess.run(
                ["which", "slurp"], capture_output=True
            ).returncode == 0
            
            if not (grim_available and slurp_available):
                print("[ocr] No screenshot tools found (need grim+slurp)")
                return None
            
            # Capture region
            with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
                tmp_path = tmp.name
            
            result = subprocess.run(
                f'grim -g "$(slurp)" {tmp_path}',
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0 or not os.path.exists(tmp_path):
                print("[ocr] Screenshot capture failed")
                return None
            
            # OCR the captured image
            text = self.ocr_file(tmp_path, lang=lang)
            
            # Cleanup
            os.unlink(tmp_path)
            
            return text
            
        except Exception as e:
            print(f"[ocr] Region capture error: {e}")
            return None
