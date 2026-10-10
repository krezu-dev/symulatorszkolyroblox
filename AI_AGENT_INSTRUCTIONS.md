# Instrukcje dla Agentów AI (Multi-Agent Roblox + Rojo)
# Zespół: Agent Gabriel (Host / Skrypty) & Agent Claude (Zdalny / Mapa, 3D, VFX/SFX)

Ten dokument zawiera specyfikację techniczną projektu dla Agentów AI współpracujących nad grą Roblox "Szkolny Detektyw" na dwóch różnych komputerach.

---

## 🔀 Przydział gałęzi (Branches)

Projekt posiada dedykowane gałęzie robocze:

1. **`agent-gabriel`** &rarr; Gałąź dla Agenta Gabriel (Host / Skrypty, Architektura, MM2/Among Us logika)
2. **`agent-claude`** &rarr; Gałąź dla Agenta Claude (Zdalny komputer / Mapa 3D, Zakamarki, VFX, SFX, Animacje)
3. **`main`** &rarr; Główna gałąź stabilna / integracyjna

Dzięki temu agenci nigdy nie nadpisują sobie kodu ani nie blokują się nawzajem. Każdy agent commituje i pushuje na swój dedykowany branch!

---

## 👥 Podział Ról

### 🔵 AGENT GABRIEL (Gałąź `agent-gabriel`):
- Architektura skryptów Luau w `src/server`, `src/shared`, `src/client`
- Pętla gry (`RoundManager`), role (`RolesService`), uzbrojenie (`WeaponsService`)
- Mechanika Murder Mystery 2 **Gun-Drop** (`GunDropService`)
- Mechanika Among Us **Kratki Wentylacyjne** (`VentService`)
- Mechanika Among Us **Sabotaże** (`SabotageService` - Awaria Korków, Blokada Drzwi)
- Mechanika MM2 **Monety Szkolne** (`CoinService`)
- Zadania i warunki zwycięstwa, RemoteEvents (`Remotes.luau`)
- Podstawowy responsywny interfejs użytkownika w `src/client/init.client.luau`

### 🟣 AGENT CLAUDE (Gałąź `agent-claude`):
- **Wielka Szkoła 3D i Zakamarki**: Dalsza rozbudowa i dekoracja mapy (szatnie, toalety, strychy, zakamarki za materacami w sali gimnastycznej, zaplecze chemiczne)
- **Efekty cząsteczkowe (VFX)**: Bąbelki z mopa Woźnej, dym po uderzeniu Dziennikiem, koguty radiowozu policyjnego, iskry ze skrzynki bezpiecznikowej
- **Efekty dźwiękowe (SFX)**: Smutne pianino, dzwonki, syreny, skrzypnięcia kratek, odgłosy kroków
- **Animacje Postaci**: Rzut dziennikiem, zmywanie mopem, zakładanie kajdanek przez Klockową Policję
- **Stylizacja GUI**: Wygląd teczki szkolnej, kartki w kratkę dla minigier matematycznych

---

## 1. Architektura i mapowanie folderów Rojo

Kod gry znajduje się w katalogu `src/` i jest automatycznie mapowany przez Rojo na serwisy Roblox Studio:

| Folder lokalny | Serwis Roblox Studio | Typ instancji | Zastosowanie |
| :--- | :--- | :--- | :--- |
| `src/server/` | `game.ServerScriptService.Server` | Folder / Scripts | Logika po stronie serwera (RoundManager, Services, Generatory) |
| `src/client/` | `game.StarterPlayer.StarterPlayerScripts.Client` | Folder / LocalScripts | Logika po stronie klienta (UI, HUD, Animacje, Minigry) |
| `src/shared/` | `game.ReplicatedStorage.Shared` | Folder / Modules | Współdzielone moduły (GameConfig, Remotes) |

---

## 2. Konwencja nazewnictwa plików

Rojo rozpoznaje przeznaczenie pliku na podstawie rozszerzenia:
- `*.server.luau` &rarr; **Script** (wykonywany wyłącznie przez serwer).
- `*.client.luau` &rarr; **LocalScript** (wykonywany wyłącznie przez klienta).
- `*.luau` &rarr; **ModuleScript** (moduł zwracający tabelę / klasę / funkcję).
- `init.server.luau` / `init.client.luau` / `init.luau` &rarr; zamienia cały folder w dany typ skryptu.

---

## 3. Workflow pracy dla Agenta Claude (`agent-claude`)

### Pierwsze uruchomienie po sklonowaniu repozytorium:
```bash
python3 ai_agent_client.py switch agent-claude
```

### Codzienna praca:
1. **Pobierz najnowszy stan (swój i Gabriela):**
   ```bash
   python3 ai_agent_client.py sync
   ```
   *(Pobiera Twoje commity oraz automatycznie scala najnowszy kod Gabriela)*.

2. **Wprowadzaj zmiany w mapie, efektach lub UI**.

3. **Wyślij zmiany na swój branch:**
   ```bash
   python3 ai_agent_client.py push "Dodano detale zakamarków i efekty cząsteczkowe VFX"
   ```

---

## 4. Dobre praktyki Luau / Roblox

1. **Komunikacja Sieciowa**: Wszystkie zdarzenia są zdefiniowane w `GameConfig.RemoteEvents` i pobierane przez `Remotes.get(nazwa)`.
2. **Niezmienniki Portu Rojo**: Projekt działa na dedykowanym porcie **`34873`** (nie domyślnym `34872`), z flagą `$ignoreUnknownInstances: true`.
3. **Kultura i Humor**: Gra operuje klimatem polskiej szkoły ("Tysiąclatka"), zachowując 100% zgodność z zasadami Roblox (zero brutalności, plastikowe noże, policyjne aresztowania klockowe).
