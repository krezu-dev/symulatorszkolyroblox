#!/usr/bin/env python3
"""
run_blender.py
Uruchamia Blender w trybie headless w celu wygenerowania modeli 3D i animacji.
"""

import os
import sys
import subprocess
import shutil

def find_blender():
    candidates = [
        "/Applications/Blender.app/Contents/MacOS/Blender",
        shutil.which("blender"),
        os.path.expanduser("~/Applications/Blender.app/Contents/MacOS/Blender"),
    ]
    for c in candidates:
        if c and os.path.exists(c):
            return c
    return None

def main():
    blender_bin = find_blender()
    if not blender_bin:
        print("❌ Nie znaleziono zainstalowanego Blendera w /Applications/Blender.app!")
        sys.exit(1)

    script_path = os.path.join(os.path.dirname(__file__), "generate_school_assets.py")
    print(f"🎨 Uruchamianie Blendera: {blender_bin}")
    print(f"📦 Skrypt generatora: {script_path}")

    res = subprocess.run([
        blender_bin,
        "--background",
        "--python", script_path
    ])
    sys.exit(res.returncode)

if __name__ == "__main__":
    main()
