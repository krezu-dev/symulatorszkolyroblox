# Instrukcje dla Agenta AI (Roblox + Rojo)

Ten dokument zawiera specyfikację techniczną projektu dla Agenta AI edytującego grę Roblox z zewnętrznej maszyny.

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

- `*.server.luau` (lub `.server.lua`) -> **Script** (wykonywany wyłącznie przez serwer).
- `*.client.luau` (lub `.client.lua`) -> **LocalScript** (wykonywany wyłącznie przez klienta).
- `*.luau` (lub `.lua`) -> **ModuleScript** (moduł zwracający tabelę / funkcję).
- `init.server.luau` / `init.client.luau` / `init.luau` -> zamienia cały folder w dany typ skryptu, a pliki wewnątrz folderu stają się jego dziećmi (child instances).

---

## 3. Workflow pracy Agenta AI

Zanim przystąpisz do pisania kodu, wykonaj:

```bash
# 1. Pobierz najnowszy stan projektu
python3 ai_agent_client.py sync
# lub tradycyjnie: git pull --rebase
```

Następnie:
1. Zmodyfikuj lub utwórz odpowiednie skrypty w `src/server`, `src/client` lub `src/shared`.
2. Stosuj `--!strict` na początku plików Luau.
3. Gdy skończysz edycję, wyślij zmiany na GitHub:

```bash
# 2. Wyślij zmiany
python3 ai_agent_client.py push "Opis wprowadzonych modyfikacji"
# lub:
# git add src/
# git commit -m "AI: Opis zmian"
# git pull --rebase
# git push
```

Gdy zmiany trafią na GitHub, serwer hostujący Roblox Studio automatycznie pobierze je i zaktualizuje grę w czasie rzeczywistym.

---

## 4. Dobre praktyki Luau / Roblox

1. **Komunikacja Klient <-> Serwer**: Używaj `RemoteEvent` lub `RemoteFunction` umieszczonych w `ReplicatedStorage`.
2. **Pobieranie serwisów**: Zawsze używaj `game:GetService("NazwaSerwisu")`.
3. **Pobieranie modułów współdzielonych**:
   ```luau
   local ReplicatedStorage = game:GetService("ReplicatedStorage")
   local Shared = ReplicatedStorage:WaitForChild("Shared")
   local MyModule = require(Shared:WaitForChild("MyModule"))
   ```
4. **Zapobieganie wyciekom pamięci**: Czyść połączenia zdarzeń (`connection:Disconnect()`), gdy obiekt przestaje istnieć.
