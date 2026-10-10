#!/usr/bin/env python3
"""
ai_agent_client.py
Narzędzie i moduł pomocniczy dla Agentów AI pracujących na gałęziach:
- agent-gabriel
- agent-antigravity
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

    def get_branch(self):
        code, out, _ = self._run_git(["rev-parse", "--abbrev-ref", "HEAD"])
        return out if code == 0 else "unknown"

    def switch_branch(self, branch_name):
        print(f"[AI CLIENT] Przełączanie na branch '{branch_name}'...")
        code, out, err = self._run_git(["checkout", branch_name])
        if code != 0:
            # Może trzeba utworzyć z remote
            code2, out2, err2 = self._run_git(["checkout", "-b", branch_name, f"origin/{branch_name}"])
            if code2 != 0:
                print(f"[AI CLIENT] Błąd przełączania brancha: {err}")
                return False
        print(f"[AI CLIENT] Jesteś teraz na branchu: {branch_name}")
        return True

    def sync(self):
        """Pobiera najnowsze zmiany ze swojego brancha oraz brancha partnera."""
        current_b = self.get_branch()
        print(f"[AI CLIENT] Synchronizacja brancha '{current_b}'...")
        
        # 1. Fetch
        code, _, err = self._run_git(["fetch", "--all"])
        if code != 0:
            print(f"[AI CLIENT] Błąd fetch: {err}")
            return False

        # 2. Pull rebase na własnym branchu
        code, _, err = self._run_git(["pull", "--rebase"])
        if code != 0:
            print(f"[AI CLIENT] Błąd podczas synchronizacji własnego brancha: {err}")
            return False

        # 3. Scalenie zmian z brancha partnera
        sibling = "agent-antigravity" if current_b == "agent-gabriel" else ("agent-gabriel" if current_b == "agent-antigravity" else None)
        if sibling:
            print(f"[AI CLIENT] Sprawdzanie zmian od partnera ('{sibling}')...")
            code, count, _ = self._run_git(["rev-list", f"HEAD..origin/{sibling}", "--count"])
            if code == 0 and count.isdigit() and int(count) > 0:
                print(f"[AI CLIENT] Scalanie {count} commitów z brancha '{sibling}'...")
                code_m, _, err_m = self._run_git(["merge", f"origin/{sibling}", "--no-edit", "-m", f"Merge zmian od partnera {sibling}"])
                if code_m != 0:
                    print(f"[AI CLIENT] Konflikt merge z '{sibling}': {err_m}")
                    self._run_git(["merge", "--abort"])
                else:
                    print(f"[AI CLIENT] Pomyślnie zintegrowano zmiany z '{sibling}'!")

        print(f"[AI CLIENT] Repozytorium jest w pełni zaktualizowane!")
        return True

    def status(self):
        """Zwraca status zmodyfikowanych plików."""
        current_b = self.get_branch()
        code, out, _ = self._run_git(["status", "--short"])
        return f"Branch: {current_b}\n" + (out if out else "Czyste drzewo robocze.")

    def commit_and_push(self, message):
        """Dodaje zmiany z folderu src/ i wysyła na bieżący branch na GitHub."""
        current_b = self.get_branch()
        if not message.startswith("AI:"):
            message = f"AI [{current_b}]: {message}"

        # 1. Sprawdź czy są jakiekolwiek zmiany
        code, out, _ = self._run_git(["status", "--short"])
        if not out:
            print("[AI CLIENT] Brak zmian w plikach do zatwierdzenia.")
            return True

        print(f"[AI CLIENT] ({current_b}) Zmiany do zatwierdzenia:\n{out}")

        # 2. git add src/
        code, _, err = self._run_git(["add", "src/"])
        if code != 0:
            print(f"[AI CLIENT] Błąd git add: {err}")
            return False

        # 3. git commit
        code, _, err = self._run_git(["commit", "-m", message])
        if code != 0:
            print(f"[AI CLIENT] Błąd git commit: {err}")
            return False
        print(f"[AI CLIENT] Commit utworzony na branchu '{current_b}': {message}")

        # 4. Pull --rebase przed pushem
        self._run_git(["pull", "--rebase"])

        # 5. git push na ten sam branch
        code, out, err = self._run_git(["push", "origin", current_b])
        if code != 0:
            print(f"[AI CLIENT] Błąd git push: {err}")
            return False

        print(f"[AI CLIENT] 🚀 Zmiany pomyślnie wysłane na branch '{current_b}' na GitHubie!")
        return True

def main():
    parser = argparse.ArgumentParser(description="Narzędzie Git dla agentów AI (Multi-Branch)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("sync", help="Pobierz najnowszy stan projektu i brancha partnera")
    subparsers.add_parser("status", help="Pokaż aktywny branch i zmodyfikowane pliki")
    
    switch_parser = subparsers.add_parser("switch", help="Przełącz aktywny branch")
    switch_parser.add_argument("branch", type=str, help="Nazwa brancha (np. agent-gabriel lub agent-antigravity)")

    push_parser = subparsers.add_parser("push", help="Zatwierdź i wyślij zmiany na bieżący branch")
    push_parser.add_argument("message", type=str, help="Opis zmian wprowadzonych przez AI")

    args = parser.parse_args()
    mgr = RobloxProjectManager()

    if args.command == "sync":
        success = mgr.sync()
        sys.exit(0 if success else 1)
    elif args.command == "status":
        print(mgr.status())
    elif args.command == "switch":
        success = mgr.switch_branch(args.branch)
        sys.exit(0 if success else 1)
    elif args.command == "push":
        success = mgr.commit_and_push(args.message)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
