# 🟣 PLAN AGENTA CLAUDE (`agent-claude`)

Zakres wg `AI_AGENT_INSTRUCTIONS.md`: **świat 3D, zakamarki, VFX, SFX, animacje, stylizacja GUI**
plus **kontrola jakości kodu Agenta Gabriela** (naprawianie błędów, które psują grę).

---

## ⚙️ Zasady pracy (żeby nie rozwalić auto-merge)

`auto_sync.py` u hosta (branch `agent-gabriel`) sam scala `origin/agent-claude`.
**Przy konflikcie robi `merge --abort` i po cichu pomija moje zmiany.** Dlatego:

1. **Nowe rzeczy = nowe pliki.** Dekoracje, VFX, SFX, animacje lądują w osobnych modułach
   (`SchoolDecor.luau`, `VfxService.luau`, `SfxLibrary.luau`…), a nie w środku plików Gabriela.
2. **Poprawki w plikach Gabriela = minimalne łatki** (kilka linii), każda opisana w commicie
   `fix(gabriel): …` i w sekcji „Naprawione błędy” na dole tego pliku.
3. Przed każdym pushem: `git merge origin/agent-gabriel` i test w Studio (Play + konsola bez błędów).
4. **Toolbox:** modele z Creator Store trafiają do `ServerStorage/Prefaby` w plejsie
   (Rojo ich nie rusza dzięki `$ignoreUnknownInstances`). Kod szuka prefabu po nazwie,
   a jak go nie ma, buduje prosty zamiennik z Partów, więc gra działa też bez nich.
   Każdy wstawiony model jest czyszczony ze skryptów (darmowe modele bywają zawirusowane).
   ID dźwięków trzymam w kodzie (`SfxLibrary.luau`), więc są w gicie.

---

## 🚨 ETAP 0: Naprawy krytyczne (gra teraz nie działa)

| # | Problem | Skąd wiem | Naprawa |
|---|---|---|---|
| 0.1 | **Mapa wywala się w kroku 6/8**: `SchoolMapGenerator.luau:453: attempt to call a nil value`. Wywołuje `ceilingLight()`, której nie ma. Bez mapy nie ma I piętra, gabinetu, mikrofonu radiowęzła, sal lekcyjnych ani zadań. | Konsola Studio + `luau-analyze` | Dodać lokalną funkcję `ceilingLight` (oparta na istniejącej `light()`) |
| 0.2 | `MonetizationService.luau:94`: odwołanie do `Coins` w tabeli, która go nie ma | `luau-analyze` | Sprawdzić strukturę i poprawić klucz |
| 0.3 | DataStore w Studio rzuca błędy | Konsola | Włączyć „Enable Studio Access to API Services” w Game Settings (zrobi to właściciel plejsu) |
| 0.4 | Plejs `wersjafinal` ma w logu dziesiątki „Infinite yield” ze **starej, innej gry** (SafeZone, Guardian, Farm…) | Konsola | Sprawdzić, czy te stare skrypty dalej siedzą w plejsie, i jeśli tak, usunąć je za zgodą kolegi |

| 0.5 | Skrzynki (losowe skiny za monety, a monety da się kupić za Robuxy) **nie pokazują szans**. Roblox wymaga ujawniania szans w płatnych losowaniach | `GameConfig.Crates` (Weight) vs `ShopGui` | Wyświetlić % szans przy każdej skrzynce (liczone z `Weight`) |
| 0.6 | Dźwięki memów (`rbxassetid://91142…`) wyglądają na wpisane z głowy, a nie sprawdzone | `GameConfig.Memes` | Sprawdzić każde ID w Toolboxie i podmienić na pasujące darmowe dźwięki |
| 0.7 | Nazwy prawdziwych marek w grze („Kukirin”, „Prince Polo”) mogą zostać zgłoszone na Robloxie | `GameConfig.Memes`, `KukirinService` | Zostawić klimat, ale zmienić nazwy na parodie („Kukurin”, „Książę Polo”) – do decyzji właściciela |

Po etapie 0: pełny test rundy (Lobby → InGame → zebranie → werdykt) i lista kolejnych błędów.

---

## 🏫 ETAP 1: Szkoła, która wygląda jak polska szkoła

Na podstawie zdjęć i wspomnień szkół z lat 60.–2000. (typowa „Tysiąclatka”):

**Korytarze**
- **Lamperia olejna** do ok. 1,5 m (zieleń, beż albo błękit), powyżej biała ściana, na granicy ciemny pasek
- Podłoga z **lastryko** (szaro-nakrapiane) albo płytki PCV w szachownicę, przy ścianach cokół
- **Kaloryfery żeberkowe** pod oknami (model z `assets/models`), duże okna z parapetami i doniczkami
- Drewniane drzwi do sal z **przeszkleniem u góry** i tabliczką z numerem sali („Sala 12, Matematyka”)
- **Gazetki ścienne** (tablice korkowe: „Samorząd Uczniowski”, „Plan lekcji”, „Szczęśliwy numerek”)
- Ławki korytarzowe, kosze na śmieci, gaśnice i zielone tabliczki „WYJŚCIE EWAKUACYJNE”
- **Dzwonek elektryczny** na ścianie (grzybek), a przy nim głośnik radiowęzła

**Sale lekcyjne**
- **Zielona tablica kredowa** z półką na kredę i gąbkę, nad nią **godło Polski**
- Dwuosobowe ławki w trzech rzędach, biurko nauczyciela na podeście
- Szafy z pomocami naukowymi; w pracowni geografii mapy, w pracowni chemii dygestorium
- Plakaty tematyczne (tabliczka mnożenia, układ okresowy, alfabet)

**Szatnia (piwnica)**: boksy z **siatki stalowej** dla klas, wieszaki i **worki na kapcie**.
To naturalny zakamarek do chowania się.

**Pozostałe**: stołówka z okienkiem wydawania, gabinet pielęgniarki (waga i tablica do badania wzroku),
pokój nauczycielski, biblioteka, **sklepik szkolny**, sala gimnastyczna z drabinkami, materacami,
kozłem i proporcami. Na zewnątrz plac apelowy z masztem i boisko.

**Zadania techniczne**
- Nowy moduł `SchoolDecor.luau` wywoływany po `setupMap()`, który dekoruje istniejące pomieszczenia
- Wykorzystanie 15 modeli z `assets/models/` (zaimportowanych jako MeshParty) i prefabów z Toolboxa
- Oświetlenie: świetlówki pod sufitem (lekko zimne światło), `Atmosphere` i `ColorCorrection`
- 8 zakamarków wg GDD: sprawdzić, czy są dostępne i czy ich pozycje zgadzają się z `VentService` i `HidingService`

---

## ✨ ETAP 2: VFX (`src/client/VfxService.luau` + zdarzenia z serwera)
- Piana i bąbelki przy zmywaniu mopem (ParticleEmitter na plamie)
- Komiksowe gwiazdki i pył przy trafieniu Dziennikiem
- Niebiesko-czerwone koguty (PointLight + tween) przy aresztowaniu
- Iskry i dym ze skrzynki bezpieczników przy Awarii Korków; po naprawie świetlówki migają i się zapalają
- Złota poświata i obrót upuszczonego Dziennika (uzupełnienie `GunDropService`)

## 🔊 ETAP 3: SFX (`src/shared/SfxLibrary.luau`)
- Dźwięki z Toolboxa (darmowe, zweryfikowane): dzwonek szkolny, syrena, skrzypienie kratki, kroki
  na lastryko, kreda na tablicy, smutne pianino, wesoły dzwonek
- Ambient: gwar przerwy w lobby, cisza z echem w trakcie lekcji, brzęczenie świetlówek

## 🕺 ETAP 4: Animacje
- Rzut Dziennikiem, atak plastikowym nożem, zmywanie mopem, zakładanie kajdanek przez policję
- Z Toolboxa jako Animation, a jeśli nic nie pasuje, proceduralnie (Motor6D + tween), tak jak `ProceduralAnimations`

## 🎨 ETAP 5: Stylizacja GUI
- Ekran zebrania jako **tablica korkowa** z kartkami-zdjęciami graczy przypiętymi pinezkami
- Minigra z matematyki na **kartce w kratkę** z marginesem, pismo jak odręczne
- Pasek zadań jako **dziennik ocen** (rubryki), licznik monet jako **5 zł**
- Spójne fonty i kolory w HUD, sklepie i minigrach

---

## 🤪 ETAP 6: Memy i język młodzieży (XXI wiek, 2025/26)

Gra ma być „szkoła z lat 90. + dzisiejsza młodzież”. Źródło słownictwa: finał
**Młodzieżowego Słowa Roku 2025** (wygrał **„szponcić / szpont”**).

**Co już jest od Gabriela** (commit `defb275`): hulajnogi Kukirin jako wierzchowce, soundboard polskich memów
(„Dzwonek jest dla nauczyciela!”, kartkówka, sklepik, „NP”, ściąga). **Mój wkład:** model 3D hulajnogi
(Toolbox albo własny), VFX i dźwięk jazdy, miejsce parkowania pod szkołą i tablica „ZAKAZ JAZDY NA HULAJNODZE PO KORYTARZU”,
której wszyscy nie przestrzegają. Do tego nowe memy z listy poniżej, podpięte pod soundboard Gabriela (bez przepisywania jego GUI).

**Gdzie memy siedzą w grze (wszystko w `src/shared/MemeText.luau`, losowane, łatwe do podmiany):**
- **Szczęśliwy numerek** na tablicy w korytarzu. Gracz z tym numerem ma bonus +5 zł. A jak wypadnie **67**: konfetti, dźwięk i napis „SIX SEVEN 🤲”
- **E-dziennik** zamiast powiadomień: „🔔 Nowa ocena: 1 (Kartkówka z szpontu)”, „Uwaga: uczeń szponcił na przerwie”
- **Werdykt zebrania**: „[Nick] był Rozrabiaką. Totalny szpont.” / „[Nick] NIE był Rozrabiaką… lowkey słabo, bro”
- **Gazetki ścienne**: „Samorząd Uczniowski: zakaz mówienia 67 na lekcjach”, „Konkurs: kto pierwszy powie skibidi do dyrektora”, „Słowo miesiąca: TUFF”
- **Napisy na ławkach i ścianach w toalecie** (zakamarek): „GOAT 3b”, „fr fr”, „bro tu był”, „twin <3”
- **Radiowęzeł Dyrektora**: gotowe ogłoszenia do wyboru („Proszę przestać mówić sześć siedem”, „Brainrot zakazany od poniedziałku”)
- **Teksty ról** na karcie roli: Rozrabiaka „Czas na szpont 😈”, Woźna „Kto znowu nachlapał kompotem?!”, Dyrektor „Wszystko widzę, bro.”
- **Ekran ładowania i wskazówki**: „Pani, a będzie to na sprawdzianie?”, „Kartkówka zapowiedziana = kartkówka niezapowiedziana”
- **OKPA** jako tekst przy wyjściu z gry / po rundzie, **klasa** i **slay** jako pochwała za zadanie, **szacun** za złapanie Rozrabiaki
- **Sklepik szkolny** (monety 5 zł): drożdżówka, hot-dog ze sklepiku, kanapka od mamy, „gorący kubek”

**Zasady memów (Roblox + zdrowy rozsądek):**
- Bez prawdziwych osób (influencerów, polityków, nauczycieli), bez marek i postaci chronionych prawem autorskim (np. konkretnych postaci „brainrot”), bez przekleństw i 2137
- Teksty muszą przejść filtr Roblox (używamy `TextService`, tam gdzie tekst pochodzi od graczy)
- Wszystkie teksty w jednym pliku, żeby łatwo dorzucać nowe trendy

---

## ✅ Definicja „zrobione” dla każdego etapu
- Zero błędów i ostrzeżeń z naszych skryptów w konsoli przy pełnej rundzie
- Screenshot z Studio dołączony do opisu w `AGENT_COMMUNICATION.md` (sekcję dopisze Gabriel albo właściciel)
- Zmiany na `agent-claude`, czysto scalone z `agent-gabriel`

---

## 🛠️ Naprawione błędy Agenta Gabriela (log)
_(uzupełniane na bieżąco)_

- **0.1 `SchoolMapGenerator.luau`**: dodana brakująca funkcja `ceilingLight`, więc mapa buduje się już dalej niż krok 6/8.
- **0.2 `MonetizationService.luau:94`**: fałszywy alarm analizatora typów, nic nie psuje. **Za to:** ID produktów w `GameConfig.DevProducts` (2938471–2938473) są zmyślone. Właściciel musi utworzyć prawdziwe Developer Products w Creator Hub i wpisać ich ID.
- **Nowa szkoła (zamiast starej mapy):** `workspace.SchoolMap` jest teraz STATYCZNA (zbudowana w Studio modułem `src/server/NowaSzkola`, zapisana w plejsie). `SchoolMapGenerator.setupMap` przekierowuje do `NowaSzkola.setupMap`, które w trakcie gry tylko podpina zadania, dzwon, kryjówki, radiowęzeł i migające światła. Pozycje kratek, monet, plam, skrzynki bezpieczników i blokad drzwi są w `src/shared/SchoolLayout.luau` (wcześniej były wpisane na sztywno i nie pasowały do żadnej mapy).
- **0.5 `ShopGui.luau`**: przy każdej skrzynce są teraz pokazane szanse w % (liczone z `Weight`).
