# Instrukcje dla Agentów AI (Multi-Agent Roblox + Rojo)

Ten dokument zawiera specyfikację techniczną projektu dla Agentów AI współpracujących nad tą samą grą Roblox na różnych komputerach.

---

## 🔀 Przydział gałęzi (Branches)

Projekt został podzielony na dwie niezależne gałęzie robocze:

1. **`agent-gabriel`** &rarr; Gałąź dla Agenta AI Gabriela (Host / komputer główny)
2. **`agent-antigravity`** &rarr; Gałąź dla Agenta AI Kolegi (Zdalny komputer)
3. **`main`** &rarr; Główna gałąź stabilna

Dzięki temu agenci nigdy nie nadpisują sobie kodu ani nie blokują się nawzajem. Każdy agent commituje i pushuje na swój dedykowany branch!

---

## 1. Architektura i mapowanie folderów Rojo

Kod gry znajduje się w katalogu `src/` i jest automatycznie mapowany przez Rojo na serwisy Roblox Studio:

| Folder lokalny | Serwis Roblox Studio | Typ instancji | Zastosowanie |
| :--- | :--- | :--- | :--- |
| `src/server/` | `game.ServerScriptService.Server` | Folder / Scripts | Logika po stronie serwera (zapis bazy, autoryzacja, mechaniki gry) |
| `src/client/` | `game.StarterPlayer.StarterPlayerScripts.Client` | Folder / LocalScripts | Logika po stronie klienta (UI, animacje, lokalny input) |
| `src/shared/` | `game.ReplicatedStorage.Shared` | Folder / Modules | Współdzielone moduły dostępne dla Serwera i Klienta |

---

## 2. Konwencja nazewnictwa plików

Rojo rozpoznaje przeznaczenie pliku na podstawie rozszerzenia:

- `*.server.luau` &rarr; **Script** (wykonywany wyłącznie przez serwer).
- `*.client.luau` &rarr; **LocalScript** (wykonywany wyłącznie przez klienta).
- `*.luau` &rarr; **ModuleScript** (moduł zwracający tabelę / klasę / funkcję).
- `init.server.luau` / `init.client.luau` / `init.luau` &rarr; zamienia cały folder w dany typ skryptu.

---

## 3. Workflow pracy Agenta AI

### Dla Agenta Kolegi (`agent-antigravity`):
Po sklonowaniu repozytorium przełącz się na swój branch:
```bash
python3 ai_agent_client.py switch agent-antigravity
```

### Codzienna praca:
1. **Pobierz najnowszy stan (swój i partnera):**
   ```bash
   python3 ai_agent_client.py sync
   ```
   *(Pobiera Twoje commity oraz automatycznie scala najnowszy kod partnera)*.

2. **Pisz kod w folderze `src/`** (np. `src/server/` lub `src/shared/`).

3. **Wyślij zmiany na swój branch:**
   ```bash
   python3 ai_agent_client.py push "Dodano system zadań i questów"
   ```

---

## 4. Dobre praktyki Luau / Roblox

1. **Komunikacja Klient <-> Serwer**: Używaj `RemoteEvent` lub `RemoteFunction` w `ReplicatedStorage`.
2. **Pobieranie serwisów**: Zawsze używaj `game:GetService("NazwaSerwisu")`.
3. **Pobieranie modułów współdzielonych**:
   ```luau
   local ReplicatedStorage = game:GetService("ReplicatedStorage")
   local Shared = ReplicatedStorage:WaitForChild("Shared")
   local MyModule = require(Shared:WaitForChild("MyModule"))
   ```
4. **Rozdzielność plików**: Aby uniknąć jakichkolwiek konfliktów merge, staraj się tworzyć nowe skrypty i moduły w dedykowanych plikach.
