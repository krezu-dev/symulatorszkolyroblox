#!/usr/bin/env python3
"""
ai_agent_client.py
Narzędzie i moduł pomocniczy dla Agentów AI pracujących na zdalnych maszynach.

Umożliwia agentowi AI:
1. Pobranie najnowszego stanu gry przed edycją (sync/pull).
2. Bezkonfliktowe wysłanie zmian na GitHub (commit & push) z automatycznym --rebase.
3. Sprawdzenie statusu plików i struktury projektu.
"""

import os
import sys
import subprocess
import argparse

class RobloxProjectManager:
    def __init__(self, repo_dir="."):
        self.repo_dir = os.path.abspath(repo_dir)

    def _run_git(self, args):
        res = subprocess.run(
            ["git"] + args,
            cwd=self.repo_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False
        )
        return res.returncode, res.stdout.strip(), res.stderr.strip()

    def sync(self):
        """Pobiera najnowsze zmiany ze zdalnego repozytorium."""
        print("[AI CLIENT] Pobieranie najnowszych zmian (git pull --rebase)...")
        code, out, err = self._run_git(["pull", "--rebase"])
        if code != 0:
            print(f"[AI CLIENT] Błąd podczas synchronizacji: {err}")
            return False
        print("[AI CLIENT] Repozytorium jest aktualne!")
        return True

    def status(self):
        """Zwraca status zmodyfikowanych plików."""
        code, out, _ = self._run_git(["status", "--short"])
        return out

    def commit_and_push(self, message):
        """Dodaje zmiany z folderu src/ i wysyła na GitHub."""
        if not message.startswith("AI:"):
            message = f"AI: {message}"

        # 1. Sprawdź czy są jakiekolwiek zmiany
        st = self.status()
        if not st:
            print("[AI CLIENT] Brak zmian do wysłania.")
            return True

        print(f"[AI CLIENT] Zmiany do zatwierdzenia:\n{st}")

        # 2. git add
        code, _, err = self._run_git(["add", "src/"])
        if code != 0:
            print(f"[AI CLIENT] Błąd git add: {err}")
            return False

        # 3. git commit
        code, out, err = self._run_git(["commit", "-m", message])
        if code != 0:
            print(f"[AI CLIENT] Błąd git commit: {err}")
            return False
        print(f"[AI CLIENT] Commit utworzony: {message}")

        # 4. Pull --rebase przed pushem (na wypadek gdyby inny agent zdążył wypchnąć kod)
        code, _, err = self._run_git(["pull", "--rebase"])
        if code != 0:
            print(f"[AI CLIENT] Uwaga przy rebase: {err}")

        # 5. git push
        code, out, err = self._run_git(["push"])
        if code != 0:
            print(f"[AI CLIENT] Błąd git push: {err}")
            return False

        print("[AI CLIENT] 🚀 Zmiany pomyślnie wysłane na GitHub!")
        return True

def main():
    parser = argparse.ArgumentParser(description="Narzędzie Git dla agenta AI edytującego grę Roblox")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subkomenda: sync
    subparsers.add_parser("sync", help="Pobierz najnowszy stan projektu z GitHuba")

    # Subkomenda: status
    subparsers.add_parser("status", help="Pokaż zmodyfikowane pliki")

    # Subkomenda: push
    push_parser = subparsers.add_parser("push", help="Zatwierdź i wyślij zmiany na GitHub")
    push_parser.add_argument("message", type=str, help="Opis zmian wprowadzonych przez AI")

    args = parser.parse_args()
    mgr = RobloxProjectManager()

    if args.command == "sync":
        success = mgr.sync()
        sys.exit(0 if success else 1)
    elif args.command == "status":
        st = mgr.status()
        if st:
            print(st)
        else:
            print("Czyste drzewo robocze (brak zmian).")
    elif args.command == "push":
        success = mgr.commit_and_push(args.message)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
