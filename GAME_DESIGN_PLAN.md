# 🎮 DOKUMENT PROJEKTOWY I PLAN ROZWOJU GRY (GAME DESIGN DOCUMENT)
# Projekt: "Szkolny Detektyw" (MM2 + Among Us w realiach polskiej szkoły Tysiąclatki)

---

## 📌 1. STRESZCZENIE PROJEKTU (EXECUTIVE SUMMARY)
**"Szkolny Detektyw"** to asymetryczna gra social deduction i przetrwania dla platformy Roblox, łącząca najlepsze i najbardziej wciągające mechaniki z dwóch światowych hitów:
1. **Murder Mystery 2 (MM2)**:
   - Dynamiczna akcja w czasie rzeczywistym.
   - Mechanika **Upuszczanej Broni (Gun-Drop)**: gdy Dyrektor (Sheriff) zginie lub rzuci w niewinnego, jego Szkolny Dziennik ląduje na podłodze, a każdy niewinny uczeń może go podnieść i zostać nowym bohaterem ("Zastępcą Dyrektora")!
   - Kary za chybienie w niewinnego (misfire penalty).
   - Zbieranie monet (Szkolne Monety 5 zł) rozrzuconych po korytarzach i klasach, dających graczom stałą motywację do ruchu.
   - Ukrywanie się w zakamarkach, szafkach i ciemnych kątach.
2. **Among Us**:
   - Pasek postępu zadań (Task Bar 0-100%): uczniowie wykonują szkolne minigry (matematyka, dyktando, obiad na stołówce, porządki w szafce), dając drużynie niewinnych alternatywny warunek zwycięstwa.
   - System Sabotaży (Sabotage): Rozrabiaka (Impostor) może wywołać **Awarię Korków** (wyłączenie świateł w całej szkole, gęsta mgła), zablokować drzwi sal lekcyjnych lub wywołać fałszywy alarm.
   - Kratki Wentylacyjne (Vents): Rozrabiaka może wskakiwać do kratek wentylacyjnych łączących 8 szkolnych zakamarków (kanciapa, magazynek WF, toalety, zaplecze chemiczne).
   - Zgłaszanie ciał (porzuconych plecaków) oraz Awaryjny Dzwon (Wielki Złoty Dzwon na Stołówce).
   - Faza narady, czatu i głosowania, zakończona komicznym aresztowaniem przez Klockową Policję i memicznym czarnym ekranem.

Wszystko osadzone w unikalnym klimacie polskiej szkoły podstawowej z lat 90./2000. (zielona lamperia olejna, pierogi z okrasą, Ludwik w kanciapie woźnej, szafki metalowe, dzwonki na przerwę).

---

## ⚔️ 2. ANALIZA MECHANIK: MM2 vs AMONG US vs SZKOLNY DETEKTYW

| Element rozgrywki | Murder Mystery 2 (MM2) | Among Us | "Szkolny Detektyw" (Nasz Projekt) |
|---|---|---|---|
| **Role główne** | Sheriff, Murderer, Innocents | Crewmates, Impostors | Dyrektor, Woźna, Rozrabiaka, Uczniowie (+ Zastępca Dyrektora) |
| **Broń detektywa** | Rewolwer (celowanie i strzał) | Brak (tylko głosowanie) | **Szkolny Dziennik Ocen** (rzucany pocisk z fizyką i rotacją) |
| **Co po śmierci detektywa?** | Pistolet upada na ziemię, uczeń może go podnieść | N/A | **Gun-Drop**: Dziennik świeci złotym blaskiem; uczeń podbiega i staje się **Zastępcą Dyrektora**! |
| **Strzał w niewinnego** | Sheriff i niewinny giną | N/A | Dyrektor odpada ze wstydu, Dziennik upada na ziemię! |
| **Cicha eliminacja** | Nóż z bliska | Kill button (animacja) | **Plastikowy Nóż Zabawkowy** (15s cooldown, 100% Roblox safe) |
| **Ukryte przejścia** | Brak (lub rzadkie) | Vents (kratki) | **Kratki wentylacyjne** łączące 8 zakamarków szkoły dla Rozrabiaki |
| **Sabotaż** | Brak | Światła, reaktor, tlen, drzwi | **Awaria Korków** (ciemność), **Zablokowanie Drzwi**, naprawa w Kanciapie |
| **Aktywność niewinnych** | Zbieranie monet (Coin Bag) | Zadania (Tasks) | **OBIE RZECZY**: Szkolne Zadania (0-100%) + Zbieranie Szkolnych Monet 5 zł! |
| **Zwoływanie zebrania** | Brak | Report body / Emergency Button | **Raport Plecaka** smartfonem LUB uderzenie w **Wielki Złoty Dzwon** |
| **Eliminacja w głosowaniu** | Brak | Wyrzucenie w kosmos / lawę | **Klockowi Policjanci z syreną i kajdankami** + memiczny czarny ekran |

---

## 🎭 3. ROLE W GRZE I ICH ZDOLNOŚCI

### 1. 🎓 Dyrektor Szkoły (Odpowiednik: Sheriff z MM2)
- **Ekwipunek**: *Szkolny Dziennik Ocen* (broń miotana).
- **Zadanie**: Obserwować podejrzane zachowania, patrolować korytarze i rzucić Dziennikiem w Rozrabiakę.
- **Ryzyko**: Rzucenie w niewinnego ucznia skutkuje natychmiastowym odpadnięciem Dyrektora i upuszczeniem Dziennika na ziemię.
- **Oznaczenie**: Złoty tytuł nad głową *"Dyrektor Szkoły"*.

### 2. 🌟 Zastępca Dyrektora (Bohater awaryjny - mechanika Gun-Drop)
- Gdy Dyrektor zginie lub odpadnie, na ziemi pojawia się rotujący, złocisty Szkolny Dziennik.
- Pierwszy żywy Niewinny Uczeń lub Woźna, który podejdzie i przytrzyma interakcję (E), otrzymuje Dziennik i zostaje mianowany **Zastępcą Dyrektora**.
- Cały serwer otrzymuje powiadomienie dźwiękowe i baner: *"Uczeń [Nick] podniósł Dziennik i został Zastępcą Dyrektora!"*.

### 3. 🧹 Woźna (Klasa wsparcia / Support)
- **Ekwipunek**: *Mop i Wiadro z Ludwikiem*.
- **Zdolności**:
  - Usuwa ślady, plamy i bałagan zostawiony przez Rozrabiakę.
  - Naprawia sabotaże (np. Awarię Korków) **2x szybciej** niż zwykli uczniowie.
  - Jako jedyna ma klucz do skrótu przez Kanciapę.
- **Oznaczenie**: Niebieski tytuł *"Woźna"*.

### 4. 🎒 Uczniowie (Niewinni / Crewmates / Innocents)
- **Cel**: Wykonać zadania szkolne do 100% LUB przetrwać do końca lekcji (4.5 min) LUB pomóc wytypować Rozrabiakę na zebraniu.
- **Aktywności**:
  - Rozwiązywanie zadań w klasach (Matematyka, Polski, Obiad, Szafki).
  - Zbieranie Szkolnych Monet 5 zł na korytarzach.
  - Zgłaszanie znalezionych plecaków za pomocą Szkolnego Smartfona.
  - Podnoszenie upuszczonego Dziennika Dyrektora.

### 5. 😈 Rozrabiaka (Zabójca / Impostor / Murderer)
- **Ekwipunek**: *Plastikowy Nóż-Zabawka* (zasięg 7 studów, 15 sekund cooldownu).
- **Zdolności specjalne**:
  - **Kratki wentylacyjne**: Wskakiwanie do wentylacji w zakamarkach i natychmiastowe przemieszczanie się po szkole.
  - **Awaria Korków**: Wyłączenie oświetlenia szkoły (gracze tracą widoczność).
  - **Zablokowanie Drzwi**: Zamknięcie sal lekcyjnych na 15 sekund.
  - Ukrywanie się w 8 szkolnych zakamarkach (magazynek WF za materacami, kanciapa za Ludwikiem, zaplecze chemiczne, toalety).

---

## 🔄 4. KOMPLETNA PĘTLA GRY (GAME LOOP ARCHITECTURE)

```
[1. LOBBY NA PLACU APELOWYM (15s)]
         │
         ▼
[2. DZWONEK NA LEKCJĘ & ROZDANIE RÓL (3s)]
         │
         ▼
[3. FAZA GŁÓWNA W WIELKIEJ SZKOLE (4.5 MIN)]
   ├─► Uczniowie robią zadania (Pasek 0-100%)
   ├─► Zbieranie Szkolnych Monet 5 zł
   ├─► Rozrabiaka eliminuje & używa wentylacji / sabotaży
   ├─► Dyrektor patroluje z Dziennikiem (Gun-Drop w razie śmierci!)
   │
   ├────────► Ciało/Plecak znaleziony LUB Uderzenie w Wielki Dzwon ──┐
   │                                                                 │
   ▼                                                                 ▼
[KONIEC CZASU (4.5 min)]                                   [4. ZEBRANIE W STOŁÓWCE (60s)]
Uczniowie wygrywają!                                       Dyskusja na czacie & Głosowanie
                                                                     │
                                                                     ▼
                                                           [5. WERDYKT & ARESZTOWANIE (4s)]
                                                           Policja z syrenami i kajdankami
                                                                     │
                                                                     ▼
                                                           [6. MEMICZNY CZARNY EKRAN (5s)]
                                                           Smutne pianino / Wesoły dzwonek
                                                                     │
                                                                     ▼
                                                           Czy ktoś wygrał?
                                                           ├─ NIE ─► Powrót do Fazy 3
                                                           └─ TAK ─► [7. PODSUMOWANIE & LOBBY]
```

---

## 🤝 5. PODZIAŁ ODPOWIEDZIALNOŚCI MIĘDZY AGENTAMI

### 🔵 AGENT GABRIEL (Ten agent – Architektura Skryptów i Logika Gry):
1. **Rdzeń Luau i State Machine**:
   - `RoundManager.luau`: zarządzanie stanami gry, timerami i warunkami zwycięstwa.
   - `RolesService.luau`: bezpieczny podział ról, tagowanie billboardów, ekwipunek.
   - `WeaponsService.luau`: fizyka rzutu Dziennikiem, misfire penalty, zasięg noża.
   - `GunDropService.luau`: mechanika upuszczania Dziennika ze świecącym Highlightem i awansu na Zastępcę Dyrektora.
   - `SabotageService.luau`: logika awarii korków (oświetlenie, skrzynka bezpiecznikowa) i blokady drzwi.
   - `VentService.luau`: system kratek wentylacyjnych tylko dla Rozrabiaki.
   - `CoinService.luau`: losowe spawnowanie monet i licznik monet gracza.
   - `EliminationService.luau`: plecaki ofiar, zamiana w duchy, wywołanie zebrania.
   - `MeetingService.luau`: zliczanie głosów, wyłanianie aresztowanego.
   - `Remotes.luau` & `GameConfig.luau`: pełna konfiguracja sieciowa.
   - Podstawowe GUI w `src/client/init.client.luau`.

### 🟣 AGENT CLAUDE (Drugi agent na komputerze kolegi – Świat 3D, Mapy, VFX, SFX, Animacje & Stylizacja):
1. **3D School Detailing & Polish Architecture**:
   - Dalsze ubogacanie wielkiej szkoły (meble z `assets/models/`, plakaty BHP, portrety na ścianach, proporce sportowe w sali gimnastycznej).
   - Budowa klimatycznych zakamarków (schowki, kratki ściekowe, szafy wnękowe).
2. **Efekty Wizualne (VFX)**:
   - Cząsteczki piany i bąbelków dla Woźnej.
   - Komiksowy dym/gwiazdki przy uderzeniu Dziennikiem.
   - Koguty policyjne (niebiesko-czerwone światła punktowe) przy aresztowaniu.
   - Błysk i iskry przy naprawie skrzynki bezpiecznikowej.
3. **Efekty Dźwiękowe (SFX)**:
   - Smutne przerysowane pianino (porażka na czarnym ekranie).
   - Wesoły dzwonek szkolny (sukces).
   - Syrena radiowozu, dźwięk skrzypiącej kratki wentylacyjnej, szelest kartek dziennika.
4. **Animacje R15/R6**:
   - Animacja zamachu i rzutu Dziennikiem.
   - Animacja zmywania mopem.
   - Animacja aresztowania przez Klockowych Policjantów.
5. **Dopracowanie Stylu GUI**:
   - Stylizacja interfejsu głosowania (drewniana teczka szkolna / tablica korkowa).
   - Stylizowane okna minigier (kartka w kratkę z zeszytu do matematyki, talerz pierogów).
