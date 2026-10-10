# 📡 HUB KOMUNIKACJI MIĘDZY AGENTAMI AI (AGENT_COMMUNICATION.md)

Projekt: **"Szkolny Detektyw"** (Murder Mystery 2 + Among Us w realiach polskiej szkoły Tysiąclatki).  
Repozytorium: `https://github.com/krezu-dev/symulatorszkolyroblox.git`

---

## 👥 AKTUALNY PODZIAŁ RÓL I ZADAŃ

### 🔵 AGENT GABRIEL (`agent-gabriel` – Host / Architektura Skryptów i Mechaniki Gry):
- [x] **Projekt i Dokumentacja Game Design (`GAME_DESIGN_PLAN.md`)**:
  - Szczegółowe porównanie mechanik MM2 vs Among Us vs Szkolny Detektyw.
  - Projekt pętli gry, ról, sabotaży, upuszczania broni i wentylacji.
- [x] **Mechanika MM2 Gun-Drop (`src/server/GunDropService.luau`)**:
  - Po śmierci Dyrektora lub chybieniu w niewinnego Szkolny Dziennik upada na ziemię ze złocistym Highlightem.
  - Każdy niewinny gracz może go podnieść i zostać Zastępcą Dyrektora.
- [x] **Mechanika Among Us Vents (`src/server/VentService.luau`)**:
  - 6 kratek wentylacyjnych w kluczowych zakamarkach szkoły (Kanciapa, Magazynek WF, Zaplecze Chemii, Toalety, Schowek pod schodami, Zmywak).
  - Skakanie z dźwiękiem i cooldownem dostępne wyłącznie dla Rozrabiaki.
- [x] **Mechanika Sabotaży (`src/server/SabotageService.luau`)**:
  - "Awaria Korków": wygaszenie świateł w szkole, mgła, skrzynka bezpiecznikowa w Kanciapie Woźnej.
  - "Zablokowanie Drzwi": blokada sal lekcyjnych na 15 sekund.
- [x] **Mechanika Monet MM2 (`src/server/CoinService.luau`)**:
  - Dynamiczny spawn monet 5 zł na korytarzach, w klasach i pod ławkami.
  - Limit sakwy monet, odgłos podnoszenia, licznik w HUD.
- [x] **Grywalne Minigry Zadań (`src/client/TasksGui.luau`)**:
  - Matematyka (kartkówka z tabliczką mnożenia i opcjami do kliknięcia).
  - Język Polski (dyktando ortograficzne z wyborem pisowni).
  - Stołówka (interaktywny talerz z 5 pierogami do zjedzenia).
  - Szafki (układanie podręczników na półce).
- [x] **Mechanika Ukrywania się w Szafkach (`src/server/HidingService.luau`)**:
  - Chowanie się w szafkach na korytarzu (przezroczystość, kotwiczenie, zasadzki dla Rozrabiaki).
- [x] **Unikalna Mechanika Woźnej (`src/server/CleaningService.luau`)**:
  - Spawnowanie rozlanych plam (kompot, zupa, błoto); Woźna zmywa je mopem, nabijając postęp zadań i monety!
- [x] **Szkolny Radiowęzeł Dyrektora (`src/server/RadioService.luau`)**:
  - Mikrofon w gabinecie dyrektora umożliwiający nadawanie oficjalnych ogłoszeń z dzwonkiem do całej szkoły.
- [x] **System Sklepu i Skrzynek MM2 (`src/server/ShopService.luau`, `src/client/ShopGui.luau`)**:
  - 4 zakładki: Skrzynki ze skinami z animacją unboxingu, Ulepszenia za monety (Kondycja, Cichobiegi, Radar), Sklep Robux i Ekwipunek.
  - Skiny rzadkości: Common, Rare, Epic, Legendary, Godly z dynamicznym nakładaniem na broń!
- [x] **Monetyzacja Robux & MarketplaceService (`src/server/MonetizationService.luau`)**:
  - Bezpieczny `ProcessReceipt` dla pakietów monet za Robux (100, 500, 2000 monet).
  - Gamepassy: VIP Przewodniczący Szkoły (x2 monety, złoty tag), Adidasy (+25% prędkości), Plecak (limit 100 monet), Szansa na Rolę x2, Szkolny Boombox.
- [x] **Trwały Zapis Danych Gracza (`src/server/ProfileDataService.luau`)**:
  - DataStoreService: zapis stanu monet, wygranych, wykupionych ulepszeń i odblokowanych skinów z fallbackiem na Studio.
- [x] **System Wierzchowców KUKIRIN (`src/server/KukirinService.luau`, `src/client/MemesGui.luau`)**:
  - Mityczny Złoty Kukirin (płatny Gamepass za Robux) oraz Szkolny Kukirin (za 300 monet).
  - Dosiadanie Kukirina przyciskiem w HUD: prędkość +8 WalkSpeed, złote cząsteczki i ryk KUKIRIIIIN!
- [x] **Polskie Memy Szkolne & Soundboard (`src/server/PolishMemesService.luau`)**:
  - Dymki nad głową i dźwięki: "Dzwonek jest dla nauczyciela!", "Wyciągamy karteczki!", "Prince Polo i oranżada!", "Proszę pani, on ściąga!".
- [x] **Zwiększone Szanse na Role & Preferencje (`src/server/RolesService.luau`)**:
  - Pasek wyboru preferowanej roli w Lobby (`[Dyrektor] [Rozrabiaka] [Woźna] [Losowo]`).
  - Gamepassy 3x Szansa na Rozrabiakę (Impostor Boost) oraz 3x Szansa na Dyrektora (Szef Szkoły).
- [x] **Pętla Gry i Stan Maszyny (`src/server/RoundManager.luau`)**:
  - Obsługa Lobby, InGame, Meeting, GameOver, zadań (0-100%) i warunków wygranej.
- [x] **Rozbudowany Interfejs Klienta (`src/client/init.client.luau`)**:
  - Pasek zadań, licznik monet, karta roli, menu sabotaży dla Rozrabiaki, ekran zebrania i czarny ekran werdyktu.
- [x] **Synchronizatory Git (`auto_sync.py`, `ai_agent_client.py`)**:
  - Pełne wsparcie dla gałęzi `agent-claude`.

---

### 🟣 AGENT CLAUDE (`agent-claude` – Zdalny / Świat 3D, Detale Zakamarków, VFX, SFX, Animacje & Stylizacja UI):
- [ ] **Rozbudowa i Dekoracja 3D Szkoły**:
  - Dalsze ubogacanie wielkiej mapy szkoły o rekwizyty z `assets/models/` (szafki, ławki, automaty, kaloryfery, komputery CRT).
  - Dodanie klimatycznych zakamarków (ukryte pomieszczenia, magazynki, schowki na szczotki, antresole).
  - Oznaczenia na ścianach: uniwersalne tabliczki ("GABINET DYREKTORA", "STOŁÓWKA", "SALA GIMNASTYCZNA", "SZATNIA", "WYJŚCIE EWAKUACYJNE").
- [ ] **Efekty Cząsteczkowe (VFX)**:
  - Cząsteczki bąbelków i mydlin przy zmywaniu podłogi mopem przez Woźną.
  - Komiksowy pył i gwiazdki przy uderzeniu Dziennikiem rzuconym przez Dyrektora.
  - Niebiesko-czerwone światła kogutów policyjnych przy aresztowaniu.
  - Iskry i dym ze skrzynki bezpiecznikowej podczas Awarii Korków.
- [ ] **Udźwiękowienie (SFX)**:
  - Podpięcie dźwięków pod akcje: smutne przerysowane pianino przy wyrzuceniu niewinnego, dzwonek szkolny przy złapaniu Rozrabiaki, syrena policyjna.
- [ ] **Animacje Postaci**:
  - Płynny rzut Dziennikiem przez Dyrektora.
  - Animacja ataku plastikowym nożem Rozrabiaki.
  - Animacja zmywania podłogi mopem.
  - Komiczna animacja klockowych policjantów nakładających kajdanki.
- [ ] **Dopracowanie Stylu Graficznego UI**:
  - Stylizacja ramek zebrania (np. drewniana teczka dyrektora / tablica korkowa).
  - Minigry zadań szkolnych (kartka z zeszytu w kratkę do zadań z matematyki, talerz z pierogami).

---

## 🚀 SZYBKI START DLA AGENTA CLAUDE

Kolega uruchamiający Agenta Claude wykonuje na swoim komputerze:

```bash
# 1. Klonowanie repozytorium (jeśli jeszcze nie sklonowano)
git clone https://github.com/krezu-dev/symulatorszkolyroblox.git
cd symulatorszkolyroblox

# 2. Przełączenie na gałąź agent-claude
python3 ai_agent_client.py switch agent-claude

# 3. Pobranie najnowszego kodu od Gabriela
python3 ai_agent_client.py sync

# 4. Po wykonaniu prac nad mapą / VFX / SFX:
python3 ai_agent_client.py push "Opis zrobionych modeli / efektów"
```

---

## 💬 DZIENNIK ZMIAN (LIVE NOTES)

### [2026-10-10 17:50] - Agent Gabriel
- Wdrożono pełną fuzję mechanik Murder Mystery 2 i Among Us:
  - Dodano `GAME_DESIGN_PLAN.md` z pełnym projektem gry i analizą porównawczą.
  - Dodano `GunDropService.luau` (upuszczanie Dziennika przez Dyrektora i awans ucznia na Zastępcę Dyrektora).
  - Dodano `VentService.luau` (kratki wentylacyjne w 6 zakamarkach szkoły dla Rozrabiaki).
  - Dodano `SabotageService.luau` (Awaria Korków z ciemnością i naprawą w kanciapie, blokada drzwi sal).
  - Dodano `CoinService.luau` (złote monety 5 zł na korytarzach i ławkach).
  - Zbudowano responsywny HUD i GUI klienta w `src/client/init.client.luau`.
  - Zaktualizowano `auto_sync.py` i `ai_agent_client.py` pod gałąź `agent-claude`.
- **Dla Agenta Claude**:
  - Cała logika gry, skrypty, networking i architektura są gotowe, modularne i przetestowane.
  - Możesz w pełni skupić się na warstwie wizualnej, mapie, zakamarkach, VFX, SFX i animacjach!
