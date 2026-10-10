# 📡 HUB KOMUNIKACJI MIĘDZY AGENTAMI AI (AGENT_COMMUNICATION.md)

Projekt: **"Szkolny Detektyw" / "Symulator Szkoły: Kto zepsuł lekcję?"**  
Format rozgrywki: Asymetryczna gra deduction (Murder Mystery + Among Us w realiach polskiej szkoły).

Ten plik służy jako **centralna tablica koordynacji, podziału zadań i wymiany wiadomości** pomiędzy dwoma agentami:
- 🔵 **Agent Gabriel** (`agent-gabriel` – Host / Backend / Core Loop / Roles)
- 🟣 **Agent Antigravity** (`agent-antigravity` – Remote / Tasks Minigames / GUI / Cutscenes)

---

## 🏗️ 1. Podział obowiązków (Task Allocation)

### 🔵 Agent Gabriel (`agent-gabriel` - Backend & Gameplay Mechanics)
- [x] **State Machine & Round Loop (`src/server/RoundManager.luau`)**:
  - Zarządzanie stanami gry: `Lobby` (intermission) &rarr; `InGame` (4.5 min) &rarr; `Meeting` &rarr; `GameOver`.
  - Warunki zwycięstwa: Pasek zadań 100% LUB eliminacja wszystkich Rozrabiaków vs zdominowanie szkoły przez Rozrabiaków.
  - Generowanie mapy szkoły (`SchoolMapGenerator.luau`): Stołówka, sale lekcyjne, szafki, Wielki Dzwon.
- [x] **System Ról i Ekwipunku (`src/server/RolesService.luau` & `WeaponsService.luau`)**:
  - Losowanie ról: Uczniowie (ukryta), Woźna (fartuch/mop), Dyrektor (czerwony tag nad głową, rzucany Dziennik), Rozrabiacy (Plastikowy Nóż).
  - Mechanika rzucania Dziennikiem przez Dyrektora (trafienie Rozrabiaki = eliminacja mordercy; trafienie niewinnego = Dyrektor sam odpada!).
  - Eliminacja przez Rozrabiakę (plastikowy nóż &rarr; zamiana ofiary w ducha).
- [x] **System Zgłaszania i Spotkań (`src/server/MeetingService.luau` & `EliminationService.luau`)**:
  - Kliknięcie Wielkiego Dzwonu w stołówce LUB zgłoszenie porzuconego plecaka ofiary &rarr; teleportacja żyjących do stołówki.
  - Zbieranie głosów (60s), obsługa "Pomiń" / remisów, wyłonienie gracza z największą liczbą głosów.
  - Spawnowanie Klockowych Policjantów aresztujących gracza + rozsyłanie `MeetingResult`.

---

### 🟣 Agent Antigravity (`agent-antigravity` - Tasks Minigames, GUI & FX)
- [ ] **System Zadań Szkolnych (Minigry GUI) (`src/client/TasksClient.client.luau`)**:
  - **Matematyka**: Szybki test matematyczny z przyciskami (np. 2 + 2 = ?).
  - **Język Polski**: Przepisywanie słowa z tablicy ("kartkówka", "szkoła").
  - **Stołówka**: Klikanie talerza z pierogami 5 razy.
  - **Szafki/Korytarz**: Układanie podręczników od największego do najmniejszego.
  - Aktualizacja paska postępu zadań (0-100%) na ekranie graczy.
- [ ] **Interfejs Spotkania i Głosowania (`src/client/MeetingGui.client.luau`)**:
  - Lista żyjących graczy z przyciskami do głosowania.
  - Przycisk "Pomiń głosowanie" (Skip).
  - Timer 60 sekund.
- [ ] **Dramatyczny Ekran Podsumowania (Viral Blackout Screen) (`src/client/DramaticScreen.client.luau`)**:
  - Płynne ściemnienie ekranu do czerni po głosowaniu.
  - **Scenariusz A (Wyrzucono niewinnego)**: Smutne pianino, napis: *"[Gracz] był Niewinnym Uczniem. Woźna płacze w kącie."*
  - **Scenariusz B (Złapano Rozrabiakę)**: Radosny dzwonek, napis: *"Sukces! [Gracz] był Rozrabiaką!"*
- [ ] **Główny HUD Gracza (`src/client/GameHUD.client.luau`)**:
  - Pasek zadań drużyny, wskaźnik własnej roli, przycisk smartfona ("Zgłoś").

---

## 📜 2. Wspólny kontrakt techniczny (Single Source of Truth)

Obaj agenci muszą bezwzględnie przestrzegać definicji z pliku:
👉 `src/shared/GameConfig.luau` oraz `src/shared/Remotes.luau`.

### Zdefiniowane RemoteEvents:
1. `StartMeeting(callerName, reason)` – Serwer informuje klientów o zebraniu.
2. `CastVote(targetPlayerNameOrSkip)` – Klient wysyła swój głos do serwera.
3. `MeetingResult(ejectedPlayerName, role, isTroublemaker)` – Serwer przesyła wynik do czarnego ekranu.
4. `TaskCompleted(taskName)` – Klient informuje serwer o ukończeniu minigry (+ postęp paska zadań).
5. `UpdateTaskProgress(currentPercent)` – Serwer rozsyła aktualny procent zadań do wszystkich HUD-ów.
6. `RoleAssigned(roleName)` – Serwer przesyła graczowi jego rolę na początku rundy.
7. `GameStateChanged(stateName)` – Serwer informuje o zmianie stanu (Lobby, InGame, Meeting, GameOver).
8. `OpenTaskGui(taskId)` – Serwer otwiera okno zadania na kliencie po podejściu do tablicy/szafki.

---

## 💬 3. Dziennik komunikacji i wiadomości (Live Agent Notes)

### [2026-10-10 17:25] - Agent Gabriel
- **Zrobione**:
  - Zbudowano pełny backend gry po stronie serwera:
    - `src/server/RoundManager.luau`: Maszyna stanów rundy (Lobby -> InGame -> Meeting -> GameOver), warunki zwycięstwa, postęp zadań.
    - `src/server/RolesService.luau`: Losowanie ról (Dyrektor, Woźna, Rozrabiaka, Uczniowie), tagi nad głową dla ról publicznych, rozdawanie narzędzi.
    - `src/server/WeaponsService.luau`:
      - **Szkolny Dziennik**: Fizyczny rzut książką przez Dyrektora (trafienie Rozrabiaki = eliminacja; trafienie niewinnego = Dyrektor sam odpada!).
      - **Plastikowy Nóż**: Cicha eliminacja dla Rozrabiaki z cooldownem.
      - **Mop i Wiadro** dla Woźnej.
      - **Smartfon** dla Ucznia.
    - `src/server/EliminationService.luau`: Zamiana wyeliminowanego gracza w przezroczystego ducha (`Transparency = 0.6`), tworzenie porzuconego plecaka ofiary z ProximityPrompt do zgłoszenia.
    - `src/server/MeetingService.luau`: Zwoływanie zebrania, teleportacja do stołówki, zliczanie głosów, animacja aresztowania przez Klockowych Policjantów, wywołanie czarnego ekranu z wynikami.
    - `src/server/SchoolMapGenerator.luau`: Automatyczne generowanie mapy szkoły (Stołówka z Wielkim Dzwonem, Klasa Matematyczna, Klasa Humanistyczna, Korytarz z Szafkami).
- **Dla Agenta Antigravity**:
  - Cały backend i wszystkie zdarzenia sieciowe są w 100% gotowe i przetestowane.
  - Możesz teraz skupić się na warstwie wizualnej w `src/client/`:
    1. Minigry GUI po odebraniu `OpenTaskGui(taskId)`.
    2. Ekran zebrania i lista głosowania po odebraniu `StartMeeting`.
    3. Czarny ekran podsumowania z muzyką po odebraniu `MeetingResult`.
    4. HUD paska zadań i wskaźnika roli.

