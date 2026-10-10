# 📡 HUB KOMUNIKACJI MIĘDZY AGENTAMI AI (AGENT_COMMUNICATION.md)

Projekt: **"Szkolny Detektyw" / "Symulator Szkoły: Kto zepsuł lekcję?"**  
Gatunek: Asymetryczna gra deduction (Murder Mystery + Among Us w realiach polskiej szkoły Tysiąclatki).

---

## 👥 NOWY ŚCISŁY PODZIAŁ PRAC (ROLE AGENTÓW)

### 🎨 🔵 AGENT GABRIEL (`agent-gabriel` – 3D Modeling, Blender & Architektura Świata):
- [x] **Blender 3D Asset Pipeline (`tools/run_blender.py`, `tools/generate_school_assets.py`)**:
  - Automatyczny generator headless w Blenderze 5.2.2.
  - Wygenerowano 14 profesjonalnych modeli FBX i OBJ w `assets/models/`:
    1. `wielki_dzwon` (z animacją kołysania)
    2. `szkolny_dziennik` (z animacją rotacji pocisku w locie)
    3. `szkolna_lawka` (klasyczna z zielonym stelażem)
    4. `szkolne_krzeslo` (krzesełko ze sklejki)
    5. `szafka_szkolna` (rząd szafek korytarzowych)
    6. `talerz_pierogi` (szkolny obiad z pierogami i okrasą)
    7. `szkolny_plecak` (plecak ofiary - dowód w grze)
    8. `kajdanki_policja` (metalowe kajdanki policyjne)
    9. `czapka_policyjna` (czapka posterunkowego z orzełkiem)
    10. `automat_przekaski` (automat z wafelkami Prince Polo i napojami)
    11. `komputer_crt` (monitor kineskopowy z pracowni informatycznej)
    12. `kaloryfer_szkolny` (żeliwny kaloryfer żeberkowy)
    13. `stojak_chemia` (stojak z probówkami laboratoryjnymi)
    14. `bramka_boisko` (bramka na boisku szkolnym Orlik)
- [x] **Wielka Szkoła Podstawowa Tysiąclatka (`src/server/SchoolMapGenerator.luau`)**:
  - **Plac Apelowy / Lobby Zewnętrzne**: Maszt z flagą Polski, ławki, wielka tablica wejściowa, spawn początkowy.
  - **Parter**:
    - Główny korytarz (210 studów) z zieloną lamperią olejną, szafkami i automatami.
    - Wielka Stołówka (80x80) z ladą wydawania obiadów, pierogami i ołtarzem z Wielkim Złotym Dzwonem.
    - Pełnowymiarowa Sala Gimnastyczna (90x90, h=26) z parkietem, koszami i drabinkami.
    - Kanciapa Woźnej z regałami Ludwika i plamą do zmycia.
  - **I Piętro (dwubiegowe schody)**:
    - Gabinet Dyrektora z mahoniowym biurkiem i słynnym czerwonym dywanikiem.
    - Pracownia Matematyczna (Sala 201) z tablicą i ławkami.
    - Pracownia Języka Polskiego (Sala 202) z lekturami i portretem Mickiewicza.
    - Pracownia Informatyczna (Sala 203) ze stanowiskami komputerów CRT.

---

### 💻 🟣 AGENT ANTIGRAVITY (`agent-antigravity` – Skrypty, Logika Gry, SFX, VFX, Animacje & GUI):
- [ ] **Skrypty i Logika Gry**:
  - Obsługa zadań i interakcji minigier (`OpenTaskGui`).
  - Logika zgłaszania ciał smartfonem i uderzania w Wielki Dzwon.
  - Licznik postępu zadań (0-100%) i warunki wygranej.
- [ ] **VFX i Efekty Cząsteczkowe**:
  - Bąbelki mydlane i piana przy myciu podłogi mopem przez Woźną.
  - Efekt komiksowego pyłu i uderzenia przy rzucie Dziennikiem Dyrektora.
  - Błysk i fala uderzeniowa przy uderzeniu w Wielki Dzwon.
  - Efekt rozbłysków kogutów policyjnych (niebiesko-czerwone światła).
- [ ] **SFX i Udźwiękowienie**:
  - **Smutne przerysowane pianino** na czarnym ekranie (wyrzucenie niewinnego).
  - **Radosny dzwonek na przerwę** (złapanie Rozrabiaki).
  - Syrena radiowozu przy wbieganiu Klockowych Policjantów.
  - Dźwięki zjadania pierogów (chrupanie/mlaskanie), pisania kredą po tablicy, otwierania szafek.
- [ ] **Animacje Postaci i Rekwizytów**:
  - Animacja rzutu Dziennikiem przez Dyrektora.
  - Animacja ataku plastikowym nożem Rozrabiaki.
  - Animacja wbiegania policjantów i nakładania kajdanek.
  - Animacja kołysania dzwonu.
- [ ] **Kompletny Interfejs (GUI)**:
  - Minigra Matematyka (okno z przyciskami 2+2=?).
  - Minigra Język Polski (dyktando z wpisywaniem słowa na klawiaturze).
  - Minigra Stołówka (klikanie pierogów 5 razy).
  - Minigra Szafka (przeciąganie podręczników).
  - Interfejs Zebrania w Stołówce (głosowanie, lista graczy, timer 60s, przycisk Pomiń).
  - **Viralowy Czarny Ekran Podsumowania**: pełne wygaszenie ekranu z memicznym tekstem i muzyką.

---

## 🔄 PEŁNY PLAN ROZGRYWKI OD POCZĄTKU DO KOŃCA (GAME LOOP)

1. **FAZA 1: LOBBY (Przerwa na Placu Apelowym)**:
   - Gracze spawnują się na Placu Apelowym przed szkołą.
   - Mogą eksplorować dziedziniec, biegać wokół masztu, oglądać tablicę.
   - Timer odlicza 15 sekund: *"Dzwonek na lekcję za: X s"*.

2. **FAZA 2: DZWONEK I ROZDANIE RÓL ("DZWONEK NA LEKCJĘ")**:
   - Rozlega się głośny dzwonek szkolny.
   - Ekran na 2 sekundy wyświetla rolę gracza z polskim opisem:
     - **Dyrektor**: *"Patroluj szkołę! Masz Dziennik Ocen, rzuć w Rozrabiakę!"*
     - **Woźna**: *"Zmywaj rozlane plamy i pomagaj uczniom!"*
     - **Rozrabiaka**: *"Eliminuj po cichu uczniów plastikowym nożem, nie daj się złapać Dyrektorowi!"*
     - **Uczeń**: *"Wykonuj zadania w salach lekcyjnych, by zapełnić pasek w 100%!"*
   - Wszyscy gracze teleportują się na parter szkoły.

3. **FAZA 3: ROZGRYWKA W WIELKIEJ SZKOLE (4.5 min)**:
   - Uczniowie biegają po parterze i I piętrze, robiąc zadania:
     - Sala 201: Rozwiązują równanie na tablicy.
     - Sala 202: Piszą dyktando.
     - Korytarz: Układają książki w szafkach.
     - Stołówka: Jedzą pierogi.
     - Kanciapa: Woźna zmywa rozlaną zupę.
   - Rozrabiaka poluje w zakamarkach (np. szatnie, sala gimnastyczna, toalety).
   - Wyeliminowany gracz upuszcza plecak i staje się przezroczystym duchem.

4. **FAZA 4: ALARM SZKOLNY I ZEBRANIE W STOŁÓWCE**:
   - Aktywacja: Ktoś uderzy w **Wielki Złoty Dzwon** w stołówce LUB zgłosi plecak ofiary.
   - Wszyscy żyjący są teleportowani do stołówki wokół ołtarza dzwonu.
   - 60 sekund na czat i głosowanie w interfejsie.
   - Gracz z największą liczbą głosów zostaje wyłoniony.

5. **FAZA 5: AREWSZTOWANIE I CZARNY EKRAN (VIRAL MOMENT)**:
   - Wbiegają Klockowi Policjanci, rozlega się syrena, gracz dostaje kajdanki.
   - Ekran gaśnie do czerni:
     - Niewinny: Smutne pianino + *"Kamil był Niewinnym Uczniem. Woźna płacze w kącie."*
     - Rozrabiaka: Radosny dzwonek + *"Sukces! Igor był Rozrabiaką!"*

6. **FAZA 6: KONIEC RUNDY I WYPŁATA OCEN**:
   - Ekran zwycięstwa (Uczniowie vs Rozrabiacy).
   - Przyznanie Szkolnych Monet, powrót na Plac Apelowy do Lobby.

---

## 💬 DZIENNIK AGENTÓW (LIVE NOTES)

### [2026-10-10 17:40] - Agent Gabriel
- **Zrobione (Full 3D & World Architecture)**:
  - Zbudowano całą wielką 2-piętrową szkołę "Tysiąclatka" w `src/server/SchoolMapGenerator.luau`:
    - Plac Apelowy / Lobby z masztem i flagą
    - Korytarz parteru (210 studów) z szafkami i automatami
    - Stołówka 80x80 z ladą kuchenną i Wielkim Złotym Dzwonem
    - Sala Gimnastyczna 90x90 z koszami i drabinkami
    - Schody dwubiegowe na I piętro
    - Gabinet Dyrektora z mahoniowym biurkiem i dywanikiem
    - Sale 201 (Matematyka), 202 (Polski), 203 (Informatyka)
  - Zaktualizowano generator Blendera `tools/generate_school_assets.py` do 14 modeli FBX/OBJ w `assets/models/`.
- **Dla Agenta Antigravity**:
  - Masz teraz pełną kontrolę nad:
    1. Interfejsami (minigry zadań w salach, ekran głosowania, czarny ekran).
    2. Dźwiękami (SFX) i muzyką (smutne pianino, dzwonek, syrena).
    3. Efektami cząsteczkowymi (VFX).
    4. Animacjami postaci.
  - Wszystkie punkty zadań mają już w świecie gotowe `ProximityPrompt`y podpięte pod event `OpenTaskGui(taskId)`!
