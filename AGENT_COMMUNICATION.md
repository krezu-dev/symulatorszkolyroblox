# 📡 HUB KOMUNIKACJI MIĘDZY AGENTAMI AI (AGENT_COMMUNICATION.md)

Projekt: **"Szkolny Detektyw" / "Symulator Szkoły: Kto zepsuł lekcję?"**  
Format rozgrywki: Asymetryczna gra deduction (Murder Mystery + Among Us w realiach polskiej szkoły).

Ten plik służy jako **centralna tablica koordynacji, podziału zadań i wymiany wiadomości** pomiędzy dwoma agentami:
- 🔵 **Agent Gabriel** (`agent-gabriel` – Host / Backend / Core Loop / Roles)
- 🟣 **Agent Antigravity** (`agent-antigravity` – Remote / Tasks Minigames / GUI / Cutscenes)

---

## 🏗️ 1. Podział obowiązków (Task Allocation)

### 🔵 Agent Gabriel (`agent-gabriel` - Backend & Gameplay Mechanics)
- [ ] **State Machine & Round Loop (`src/server/RoundManager.server.luau`)**:
  - Zarządzanie stanami gry: `Lobby` (intermission) &rarr; `InGame` (4-5 min) &rarr; `Meeting` &rarr; `Arrest` &rarr; `GameOver`.
  - Warunki zwycięstwa: Pasek zadań 100% LUB eliminacja wszystkich Rozrabiaków vs eliminacja uczniów.
- [ ] **System Ról i Ekwipunku (`src/server/RolesService.server.luau`)**:
  - Losowanie ról: Uczniowie (ukryta), Woźna (fartuch/mop), Dyrektor (napis nad głową, rzucany Dziennik), Rozrabiacy (Plastikowy Nóż).
  - Mechanika rzucania Dziennikiem przez Dyrektora (trafienie niewinnego = eliminacja Dyrektora).
  - Eliminacja przez Rozrabiakę (plastikowy nóż &rarr; zamiana ofiary w ducha).
- [ ] **System Zgłaszania i Spotkań (`src/server/MeetingService.server.luau`)**:
  - Kliknięcie dzwonka w stołówce LUB smartfona przy duchu &rarr; teleportacja żyjących do stołówki.
  - Zbieranie głosów (60s), obsługa "Pomiń", wyłonienie gracza z największą liczbą głosów.
  - Spawnowanie NPC Policjantów aresztujących gracza.

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

---

## 💬 3. Dziennik komunikacji i wiadomości (Live Agent Notes)

*Tutaj agenci zostawiają sobie notatki, pytania i informacje o zakończonych etapach prac przed każdym `git push`.*

### Format wpisu:
```markdown
### [DATA/CZAS] - [NAZWA AGENTA (Gabriel / Antigravity)]
- **Zrobione**: ...
- **W toku**: ...
- **Do zrobienia przez drugiego agenta**: ...
- **Ważne uwagi / Zmiany w API**: ...
```

---

### [2026-10-10 17:25] - Agent Gabriel
- **Zrobione**:
  - Przygotowano strukturę projektu Rojo pod wieloosobowy sync na osobnych branchach (`agent-gabriel` i `agent-antigravity`).
  - Utworzono plik `AGENT_COMMUNICATION.md` oraz bazowe kontrakty w `src/shared/GameConfig.luau` i `src/shared/Remotes.luau`.
- **W toku**:
  - Implementacja `src/server/RoundManager.server.luau` (maszyna stanów rundy, losowanie ról, timer 5 min).
  - Przygotowanie narzędzi ról (Dziennik Dyrektora, Plastikowy Nóż, Mop Woźnej).
- **Dla Agenta Antigravity**:
  - Przejmij implementację minigier zadań w `src/client/` oraz GUI spotkania i dramatycznego czarnego ekranu.
  - Wszystkie nazwy zdarzeń i teksty znajdziesz w `src/shared/GameConfig.luau`.
