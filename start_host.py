#!/usr/bin/env python3
"""
start_host.py
Uruchamia jednym poleceniem:
1. Serwer Rojo (rojo serve) -> nasłuchuje na połączenie z wtyczki Roblox Studio.
2. Synchronizator GitHub (auto_sync.py) -> pobiera zmiany od AI w tle.
"""

import sys
import os
import signal
import subprocess
import threading
import shutil

CYAN = "\033[96m"
MAGENTA = "\033[95m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

processes = []

def stream_output(pipe, prefix, color):
    try:
        for line in iter(pipe.readline, ''):
            if not line:
                break
            print(f"{color}{BOLD}[{prefix}]{RESET} {line.rstrip()}", flush=True)
    except Exception:
        pass

def find_rojo():
    # 1. Sprawdź PATH
    rojo = shutil.which("rojo")
    if rojo:
        return rojo
    # 2. Sprawdź Homebrew na macOS
    brew_rojo = "/opt/homebrew/bin/rojo"
    if os.path.exists(brew_rojo):
        return brew_rojo
    # 3. Sprawdź rokit / aftman
    home = os.path.expanduser("~")
    for candidate in [f"{home}/.rokit/bin/rojo", f"{home}/.aftman/bin/rojo", f"{home}/.cargo/bin/rojo"]:
        if os.path.exists(candidate):
            return candidate
    return None

def cleanup(sig=None, frame=None):
    print(f"\n{YELLOW}Zamykanie serwera Rojo i synchronizatora...{RESET}")
    for p in processes:
        if p.poll() is None:
            p.terminate()
            try:
                p.wait(timeout=2)
            except subprocess.TimeoutExpired:
                p.kill()
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    rojo_path = find_rojo()
    if not rojo_path:
        print(f"{RED}BŁĄD: Nie znaleziono zainstalowanego Rojo!{RESET}")
        print("Zainstaluj Rojo poleceniem: brew install rojo")
        sys.exit(1)

    print(f"{BOLD}{GREEN}======================================================{RESET}")
    print(f"{BOLD}{GREEN}  URUCHAMIANIE ŚRODOWISKA ROBLOX HOST + AI SYNC{RESET}")
    print(f"{BOLD}{GREEN}======================================================{RESET}")
    print(f"Rojo binary: {rojo_path}")
    print(f"Katalog roboczy: {os.getcwd()}")
    print("Naciśnij Ctrl+C, aby zatrzymać.\n")

    # 1. Start Rojo serve
    try:
        rojo_proc = subprocess.Popen(
            [rojo_path, "serve"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(rojo_proc)
        threading.Thread(target=stream_output, args=(rojo_proc.stdout, "ROJO", CYAN), daemon=True).start()
        threading.Thread(target=stream_output, args=(rojo_proc.stderr, "ROJO-ERR", RED), daemon=True).start()
    except Exception as e:
        print(f"{RED}Nie udało się uruchomić Rojo: {e}{RESET}")
        sys.exit(1)

    # 2. Start Auto Sync
    try:
        sync_proc = subprocess.Popen(
            [sys.executable, "auto_sync.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        processes.append(sync_proc)
        threading.Thread(target=stream_output, args=(sync_proc.stdout, "AI-SYNC", MAGENTA), daemon=True).start()
        threading.Thread(target=stream_output, args=(sync_proc.stderr, "AI-SYNC-ERR", RED), daemon=True).start()
    except Exception as e:
        print(f"{RED}Nie udało się uruchomić synchronizatora: {e}{RESET}")
        cleanup()
        sys.exit(1)

    # Czekaj na zakończenie dowolnego procesu
    try:
        while True:
            for p in processes:
                if p.poll() is not None:
                    print(f"{YELLOW}Jeden z procesów zakończył działanie.{RESET}")
                    cleanup()
            signal.pause()
    except (KeyboardInterrupt, AttributeError):
        # signal.pause() nie działa na wszystkich platformach w ten sam sposób, fallback pętli:
        import time
        while True:
            try:
                for p in processes:
                    if p.poll() is not None:
                        cleanup()
                time.sleep(1)
            except KeyboardInterrupt:
                cleanup()

if __name__ == "__main__":
    main()
