#!/usr/bin/env python3
"""
auto_sync.py
Automatyczny synchronizator GitHub -> Roblox Studio przez Rojo.
Obsługuje współpracę wieloagentową na osobnych branchach:
- agent-gabriel
- agent-antigravity
- main
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

def get_current_branch():
    code, out, _ = run_git(["rev-parse", "--abbrev-ref", "HEAD"])
    return out if code == 0 else "main"

def check_and_pull():
    """Sprawdza czy są nowe commity na remote i robi pull/merge."""
    if not has_remote():
        return False, "Brak skonfigurowanego 'origin'."

    # 1. Fetch wszystkich branchy
    code, _, err = run_git(["fetch", "--all"])
    if code != 0:
        return False, f"Błąd fetch: {err}"

    current_branch = get_current_branch()

    # 2. Porównaj lokalny branch ze zdalnym upstream
    code, local_head, _ = run_git(["rev-parse", "HEAD"])
    code2, remote_head, _ = run_git(["rev-parse", "@{u}"])

    if code == 0 and code2 == 0 and local_head != remote_head:
        # Są nowe zmiany na bieżącym branchu
        log(f"Wykryto nowe commity na branchu '{current_branch}'! Pobieranie...", CYAN)
        code, out, err = run_git(["pull", "--rebase"])
        if code != 0:
            log(f"Błąd git pull ({current_branch}): {err}", RED)
        else:
            _, log_out, _ = run_git(["log", "--oneline", f"{local_head}..{remote_head}"])
            log(f"✅ Zaktualizowano branch '{current_branch}' z GitHub!", GREEN + BOLD)
            if log_out:
                for line in log_out.splitlines():
                    log(f"   ↳ {line}", YELLOW)
            log(f"🔄 Rojo natychmiast zaktualizowało Roblox Studio!", CYAN)

    # 3. Sprawdź gałąź partnera (drugiego agenta) i wykonaj bezpieczny auto-merge
    sibling_branch = "agent-antigravity" if current_branch == "agent-gabriel" else ("agent-gabriel" if current_branch == "agent-antigravity" else None)
    if sibling_branch:
        code, count_out, _ = run_git(["rev-list", f"HEAD..origin/{sibling_branch}", "--count"])
        if code == 0 and count_out.isdigit() and int(count_out) > 0:
            log(f"Wykryto {count_out} nowych zmian z gałęzi partnera ('{sibling_branch}')! Scalanie...", CYAN)
            code, out, err = run_git(["merge", f"origin/{sibling_branch}", "--no-edit", "-m", f"Auto-merge zmian od {sibling_branch}"])
            if code == 0:
                log(f"✅ Pomyślnie zintegrowano zmiany od agenta '{sibling_branch}'!", GREEN + BOLD)
                log(f"🔄 Rojo natychmiast zaaplikowało nowy kod kolegi w Roblox Studio!", CYAN)
            else:
                log(f"⚠️ Konflikt przy próbie scalenia z '{sibling_branch}': {err}", YELLOW)
                # Anuluj nieudany merge, aby nie uszkodzić drzewa roboczego
                run_git(["merge", "--abort"])

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
        return

def start_webhook_server(port):
    server = HTTPServer(("0.0.0.0", port), WebhookHandler)
    log(f"Nasłuchiwanie Webhooków GitHub na porcie {port} (POST /)...", GREEN)
    server.serve_forever()

def main():
    parser = argparse.ArgumentParser(description="Synchronizator GitHub <-> Rojo dla Roblox Studio")
    parser.add_argument("--interval", type=int, default=3, help="Częstotliwość sprawdzania zmian (sekundy) [domyślnie: 3]")
    parser.add_argument("--port", type=int, default=8080, help="Port serwera webhooków [domyślnie: 8080]")
    parser.add_argument("--no-webhook", action="store_true", help="Wyłącz serwer webhooków")
    parser.add_argument("--no-poll", action="store_true", help="Wyłącz poller")

    args = parser.parse_args()

    print(f"{BOLD}===================================================={RESET}")
    print(f"{BOLD}{GREEN}  Roblox + Rojo + Multi-Branch AI Synchronizer{RESET}")
    print(f"{BOLD}===================================================={RESET}")
    cur_b = get_current_branch()
    print(f"Aktywna gałąź robocza: {BOLD}{CYAN}{cur_b}{RESET}")
    if cur_b == "agent-gabriel":
        print(f"Partner AI: {BOLD}{YELLOW}agent-antigravity{RESET} (automatyczne scalanie aktywne)")
    elif cur_b == "agent-antigravity":
        print(f"Partner AI: {BOLD}{YELLOW}agent-gabriel{RESET} (automatyczne scalanie aktywne)")
    print(f"----------------------------------------------------\n")

    if not args.no_webhook:
        t = threading.Thread(target=start_webhook_server, args=(args.port,), daemon=True)
        t.start()

    if not args.no_poll:
        log(f"Aktywny monitor GitHub (sprawdzanie co {args.interval}s)...", GREEN)
        while True:
            try:
                check_and_pull()
                time.sleep(args.interval)
            except KeyboardInterrupt:
                log("Zatrzymano synchronizator.", YELLOW)
                break
            except Exception as e:
                log(f"Błąd pętli: {e}", RED)
                time.sleep(args.interval)

if __name__ == "__main__":
    main()
