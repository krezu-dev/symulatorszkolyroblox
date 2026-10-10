#!/usr/bin/env python3
"""
auto_sync.py
Automatyczny synchronizator GitHub -> Roblox Studio przez Rojo.

Działa na komputerze hostującym Roblox Studio:
1. Pobiera na bieżąco zmiany przesyłane przez Agentów AI na GitHuba (git pull).
2. Gdy pojawią się nowe zmiany, Rojo automatycznie aktualizuje grę w otwartym Roblox Studio.
"""

import os
import sys
import time
import argparse
import subprocess
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

# Kolory terminala
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

def log(msg, color=RESET):
    timestamp = time.strftime("%H:%M:%S")
    print(f"{color}[{timestamp}] {msg}{RESET}", flush=True)

def run_git(cmd):
    """Wykonuje polecenie git i zwraca kod błędu oraz wyjście."""
    try:
        res = subprocess.run(
            ["git"] + cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False
        )
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, "", str(e)

def has_remote():
    code, out, _ = run_git(["remote"])
    return code == 0 and len(out) > 0

def check_and_pull():
    """Sprawdza czy są nowe commity na remote i robi pull."""
    if not has_remote():
        return False, "Brak skonfigurowanego 'origin'. Dodaj: git remote add origin <URL>"

    # 1. Fetch
    code, _, err = run_git(["fetch", "origin"])
    if code != 0:
        return False, f"Błąd fetch: {err}"

    # 2. Porównaj lokalny branch ze zdalnym
    code, local_head, _ = run_git(["rev-parse", "HEAD"])
    code2, remote_head, _ = run_git(["rev-parse", "@{u}"])

    if code != 0 or code2 != 0:
        # Może brakować upstream brancha
        return False, "Brak ustawionego upstream (uruchom: git push -u origin main)"

    if local_head == remote_head:
        return False, None  # Brak nowych zmian

    # 3. Są nowe zmiany! Wykonaj pull
    log(f"Wykryto nowe commity od AI! Pobieranie...", CYAN)
    code, out, err = run_git(["pull", "--rebase"])
    if code != 0:
        log(f"Błąd git pull: {err}. Spróbuj rozwiązać konflikt.", RED)
        return False, err

    # 4. Pokaż co się zmieniło
    _, log_out, _ = run_git(["log", "--oneline", f"{local_head}..{remote_head}"])
    log(f"✅ Zsynchronizowano pomyślnie z GitHub!", GREEN + BOLD)
    if log_out:
        for line in log_out.splitlines():
            log(f"   ↳ {line}", YELLOW)
    log(f"🔄 Rojo natychmiast zaktualizowało instancje w Roblox Studio!", CYAN)
    return True, None

class WebhookHandler(BaseHTTPRequestHandler):
    pull_lock = threading.Lock()

    def do_POST(self):
        log("Otrzymano powiadomienie Webhook z GitHuba! Synchronizuję...", CYAN)
        with WebhookHandler.pull_lock:
            check_and_pull()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status":"ok"}')

    def log_message(self, format, *args):
        # Wycisz domyślne logi HTTP serwera
        return

def start_webhook_server(port):
    server = HTTPServer(("0.0.0.0", port), WebhookHandler)
    log(f"Nasłuchiwanie Webhooków GitHub na porcie {port} (POST /)...", GREEN)
    server.serve_forever()

def main():
    parser = argparse.ArgumentParser(description="Synchronizator GitHub <-> Rojo dla Roblox Studio")
    parser.add_argument("--interval", type=int, default=3, help="Częstotliwość sprawdzania zmian (sekundy) [domyślnie: 3]")
    parser.add_argument("--port", type=int, default=8080, help="Port serwera webhooków [domyślnie: 8080]")
    parser.add_argument("--no-webhook", action="store_true", help="Wyłącz serwer webhooków, używaj tylko pollera")
    parser.add_argument("--no-poll", action="store_true", help="Wyłącz poller, polegaj wyłącznie na webhookach")

    args = parser.parse_args()

    print(f"{BOLD}===================================================={RESET}")
    print(f"{BOLD}{GREEN}  Roblox + Rojo + GitHub Live AI Synchronizer{RESET}")
    print(f"{BOLD}===================================================={RESET}")

    if not has_remote():
        log("UWAGA: Nie wykryto zdalnego repozytorium GitHub ('origin')!", YELLOW)
        log("Aby połączyć z GitHubem, wykonaj:", YELLOW)
        log("  git remote add origin https://github.com/<twoj-user>/<twoje-repo>.git", YELLOW)
        log("  git push -u origin main\n", YELLOW)

    if not args.no_webhook:
        t = threading.Thread(target=start_webhook_server, args=(args.port,), daemon=True)
        t.start()

    if not args.no_poll:
        log(f"Aktywny monitor GitHub (sprawdzanie co {args.interval}s)...", GREEN)
        warned_remote = False
        while True:
            try:
                if has_remote():
                    check_and_pull()
                elif not warned_remote:
                    log("Oczekiwanie na skonfigurowanie repozytorium zdalnego (origin)...", YELLOW)
                    warned_remote = True
                time.sleep(args.interval)
            except KeyboardInterrupt:
                log("Zatrzymano synchronizator.", YELLOW)
                break
            except Exception as e:
                log(f"Błąd pętli: {e}", RED)
                time.sleep(args.interval)
    else:
        # Czekaj na sygnał zakończenia jeśli tylko webhook działa
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            log("Zatrzymano synchronizator.", YELLOW)

if __name__ == "__main__":
    main()
