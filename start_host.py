#!/usr/bin/env python3
"""
start_host.py
Uruchamia jednym poleceniem:
1. Serwer Rojo (rojo serve) -> nasłuchuje na dedykowanym porcie (domyślnie 34873, aby NIE kolidować z inną grą na 34872).
2. Synchronizator GitHub (auto_sync.py) -> pobiera zmiany od AI w tle.
"""

import sys
import os
import signal
import socket
import subprocess
import threading
import shutil
import argparse

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

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('127.0.0.1', port)) == 0

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
    parser = argparse.ArgumentParser(description="Uruchom środowisko Rojo + GitHub Sync")
    parser.add_argument("--port", type=int, default=34873, help="Port serwera Rojo (domyślnie 34873)")
    args = parser.parse_args()

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
    print(f"Port Rojo: {BOLD}{args.port}{RESET}")

    # Sprawdzenie portu 34872 (innej gry)
    if is_port_in_use(34872):
        print(f"{YELLOW}ℹ️  Wykryto inną grę/serwer na domyślnym porcie 34872.{RESET}")
        print(f"{GREEN}🔒 Bez obaw: ten projekt używa portu {args.port}, więc nic z tamtej gry nie zostanie zmienione ani usunięte!{RESET}")

    if is_port_in_use(args.port):
        print(f"{RED}UWAGA: Port {args.port} jest już zajęty! Możesz podać inny port: python3 start_host.py --port 34874{RESET}")
        sys.exit(1)

    print(f"\n{CYAN}👉 W Roblox Studio we wtyczce Rojo wpisz port: {BOLD}{args.port}{RESET}{CYAN} i kliknij Connect.{RESET}")
    print("Naciśnij Ctrl+C, aby zatrzymać.\n")

    # 1. Start Rojo serve
    try:
        rojo_proc = subprocess.Popen(
            [rojo_path, "serve", "--port", str(args.port)],
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
        import time
        while True:
            for p in processes:
                if p.poll() is not None:
                    print(f"{YELLOW}Jeden z procesów zakończył działanie.{RESET}")
                    cleanup()
            time.sleep(1)
    except KeyboardInterrupt:
        cleanup()

if __name__ == "__main__":
    main()
