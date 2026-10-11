-- Konfiguracja całej rozgrywki (role, zadania, ekonomia, dźwięki).
-- Wszystko w jednym miejscu, żeby łatwo stroić balans.
local C = {}

C.WERSJA = "1.0"

------------------------------------------------------------------ CZASY
C.Czasy = {
	LobbyOdliczanie = 20,     -- odliczanie w lobby, gdy jest dość graczy
	MinGraczy = 3,            -- poniżej tego runda nie startuje, czekamy w lobby
	Runda = 7 * 60,           -- długość lekcji; jak minie, wygrywa Rozrabiaka
	Dyskusja = 25,            -- jak w Among Us: najpierw rozmowa
	Glosowanie = 45,          -- potem głosowanie (można pominąć)
	WynikGlosowania = 7,
	CooldownDzwonu = 25,      -- po starcie rundy i po każdym spotkaniu
	DzwonowNaGracza = 1,
	CooldownEliminacji = 30,
	ZasiegEliminacji = 7,
	ZasiegZgloszenia = 12,
	CooldownSabotazu = 35,
	AlarmLimit = 45,          -- tyle sekund na wyłączenie alarmu
	KartkowkaCzas = 6,
	ZamknijDrzwiCzas = 12,
	KoniecRundy = 9,
}

------------------------------------------------------------------ ROLE
C.Role = {
	Uczen = {
		nazwa = "Uczeń", kolor = Color3.fromRGB(46, 140, 90), zly = false, zadan = 6,
		opis = "Zrób swoje zadania i znajdź, kto sabotuje szkołę. Na zebraniu głosuj mądrze.",
		tekst = "Nie daj się zrobić w konia.",
	},
	Nauczyciel = {
		nazwa = "Nauczyciel", kolor = Color3.fromRGB(52, 110, 200), zly = false, zadan = 6,
		opis = "Sprawdź kartkówki, zrób kawę i pilnuj porządku. Masz inne zadania niż uczniowie.",
		tekst = "Kartkówka zapowiedziana to kartkówka niezapowiedziana.",
	},
	Wozna = {
		nazwa = "Woźna", kolor = Color3.fromRGB(150, 90, 200), zly = false, zadan = 6,
		opis = "Sprzątasz szkołę. Twoje zadania to plamy, śmieci i kotłownia. Widzisz świeże plamy.",
		tekst = "Kto znowu nachlapał kompotem?!",
	},
	Dyrektor = {
		nazwa = "Dyrektor", kolor = Color3.fromRGB(230, 160, 30), zly = false, zadan = 5,
		opis = "Raz na rundę możesz WEZWAĆ KOGOŚ DO GABINETU. Trafisz Rozrabiakę – wylatuje. Pomylisz się – tracisz tę moc.",
		tekst = "Wszystko widzę, bro.",
	},
	Rozrabiaka = {
		nazwa = "Rozrabiaka", kolor = Color3.fromRGB(214, 40, 57), zly = true, zadan = 0,
		opis = "Eliminuj innych, gdy nikt nie patrzy. Możesz nosić ciała, chodzić kratkami i sabotować. Udawaj, że robisz zadania.",
		tekst = "Czas na szpont.",
	},
}
C.KolejnoscRol = { "Uczen", "Nauczyciel", "Wozna", "Dyrektor", "Rozrabiaka" }

-- Ile osób ma jaką rolę przy N graczach
function C.RozkladRol(n)
	local r = { Rozrabiaka = 1, Dyrektor = 0, Wozna = 0, Nauczyciel = 0 }
	if n >= 8 then r.Rozrabiaka = 2 end
	if n >= 3 then r.Dyrektor = 1 end
	if n >= 4 then r.Wozna = 1 end
	if n >= 5 then r.Nauczyciel = 1 end
	if n >= 9 then r.Nauczyciel = 2 end
	return r
end

------------------------------------------------------------------ PYTANIA DO MINIGIER
-- ok = numer poprawnej odpowiedzi
C.Pytania = {
	Matma = {
		{ q = "Pani napisała na tablicy: 2 + 2 = 5. Ile jest naprawdę?", odp = { "4", "5", "22", "zależy od pani" }, ok = 1 },
		{ q = "Ile to 6 + 7?", odp = { "13", "67", "SIX SEVEN", "76" }, ok = 1 },
		{ q = "Ile to 3 × 4?", odp = { "12", "34", "7", "„nie było tego”" }, ok = 1 },
		{ q = "Połowa z 18 to...", odp = { "9", "8", "1 i 8", "półtora" }, ok = 1 },
		{ q = "Ile minut ma przerwa, jeśli dzwonek jest o 10:45, a lekcja o 10:55?", odp = { "10", "45", "5", "za mało" }, ok = 1 },
		{ q = "Ile to 100 − 33?", odp = { "67", "77", "33", "sto trzy" }, ok = 1 },
	},
	Memy = {
		{ q = "Co znaczy „rel”?", odp = { "też tak mam / zgadzam się", "relaks", "relikwia", "rower elektryczny" }, ok = 1 },
		{ q = "„Aura” u młodzieży to...", odp = { "klimat, charyzma", "pogoda", "rodzaj kanapki", "imię pani od fizyki" }, ok = 1 },
		{ q = "„Delulu” to ktoś, kto...", odp = { "żyje w swoich urojeniach", "się spóźnia", "je drożdżówki", "ma plecak deluxe" }, ok = 1 },
		{ q = "Ktoś mówi „six seven”. Co to znaczy?", odp = { "nic, to po prostu mem", "godzina 6:07", "ocena 6/7", "numer autobusu" }, ok = 1 },
		{ q = "„Slay” po polsku to najbliżej...", odp = { "wymiatasz", "ślimak", "sałatka", "zasypiam" }, ok = 1 },
		{ q = "„NPC” w szkole to ktoś, kto...", odp = { "zachowuje się jak tło w grze", "jest przewodniczącym", "ma nowe buty", "prowadzi sklepik" }, ok = 1 },
		{ q = "„Lowkey” znaczy...", odp = { "trochę, po cichu", "niski klucz", "leniwy kot", "lody z kiwi" }, ok = 1 },
		{ q = "„Szpont” to...", odp = { "pojechanie po bandzie", "rodzaj sportu", "szpinak", "sprawdzian" }, ok = 1 },
	},
	Angielski = {
		{ q = "„Homework” to...", odp = { "praca domowa", "robota u kolegi", "domówka", "ćwiczenia w domu" }, ok = 1 },
		{ q = "„I am bored” znaczy...", odp = { "nudzę się", "jestem deską", "jestem wiertarką", "jestem ptakiem" }, ok = 1 },
		{ q = "„Teacher is coming!” znaczy...", odp = { "Nauczyciel idzie!", "Herbata przyszła!", "Koniec lekcji!", "Kto rzucił kredą?" }, ok = 1 },
		{ q = "„Can I go to the toilet?”", odp = { "Mogę wyjść do toalety?", "Mogę iść do domu?", "Mogę zjeść tosta?", "Czy toaleta to ja?" }, ok = 1 },
		{ q = "„Lunch break” to...", odp = { "długa przerwa", "zepsuty obiad", "złamany lunch", "przerwa na sen" }, ok = 1 },
	},
	Sklepik = {
		{ q = "Masz 5 zł. Drożdżówka kosztuje 3,50 zł. Ile reszty?", odp = { "1,50 zł", "2,50 zł", "pani nie ma wydać", "0,50 zł" }, ok = 1 },
		{ q = "Kubuś 2,80 zł + baton 1,70 zł = ?", odp = { "4,50 zł", "3,50 zł", "5 zł i lizak", "4 zł" }, ok = 1 },
		{ q = "Masz 10 zł. Zapiekanka 6 zł i sok 2 zł. Zostaje?", odp = { "2 zł", "4 zł", "1 zł", "nic, pożyczyłeś koledze" }, ok = 1 },
		{ q = "Hot-dog 4 zł. Kupujesz trzy. Ile płacisz?", odp = { "12 zł", "7 zł", "43 zł", "jeden gratis" }, ok = 1 },
	},
	Kartkowki = {
		{ q = "Uczeń napisał: 2 + 2 = 5. Ocena?", odp = { "1, źle", "6 za kreatywność", "5, ładne pismo", "bz" }, ok = 1 },
		{ q = "Uczeń napisał: stolica Polski to Kraków. Ocena?", odp = { "1, to Warszawa", "6", "3 za odwagę", "nieobecny" }, ok = 1 },
		{ q = "„Woda wrze w 100°C”. Ocena?", odp = { "5, dobrze", "1", "2", "„a na Marsie?”" }, ok = 1 },
		{ q = "Uczeń napisał tylko „nie wiem ale się domyślam”. Ocena?", odp = { "1", "6", "4 za szczerość", "+ za aktywność" }, ok = 1 },
	},
	Obecnosc = {
		{ q = "„Kowalski?” – cisza. Co wpisujesz?", odp = { "nieobecny", "obecny duchem", "na wagarach w sklepiku", "6" }, ok = 1 },
		{ q = "„Nowak?” – „Jestem!” z korytarza. Co wpisujesz?", odp = { "spóźniony", "nieobecny", "obecny dwa razy", "szpont" }, ok = 1 },
	},
	Teatr = {
		{ q = "Kwestia: „Być albo nie...”", odp = { "być", "spać", "zdać", "jeść" }, ok = 1 },
		{ q = "Kostium Pana Twardowskiego to...", odp = { "płaszcz czarnoksiężnika", "dres", "strój kąpielowy", "mundurek" }, ok = 1 },
		{ q = "Na scenie gaśnie światło. Co robisz?", odp = { "gram dalej", "uciekam", "dzwonię po woźną", "śpiewam hymn" }, ok = 1 },
	},
	Budzet = {
		{ q = "Na co wydać pieniądze szkoły?", odp = { "nowe ławki", "złota toaleta dla dyrektora", "prywatny odrzutowiec", "basen z budyniem" }, ok = 1 },
		{ q = "Kuratorium pyta, gdzie poszły pieniądze na kredę.", odp = { "na kredę", "na kremówki", "na hulajnogi", "nie wiem, pytajcie woźną" }, ok = 1 },
		{ q = "Dach przecieka. Co robisz?", odp = { "wzywam dekarza", "stawiam wiadro", "mówię, że to basen", "ignoruję" }, ok = 1 },
	},
	Samorzad = {
		{ q = "Pomysł ze skrzynki: „Dzień bez plecaka”. Decyzja?", odp = { "zatwierdzam", "odrzucam", "„zobaczymy”", "zgubiłem kartkę" }, ok = 1 },
		{ q = "Pomysł: „Automat z pizzą na korytarzu”. Decyzja?", odp = { "rozważymy", "od jutra!", "tylko dla nauczycieli", "nie ma prądu" }, ok = 1 },
		{ q = "Samorząd chce dyskotekę. Kiedy?", odp = { "w piątek po lekcjach", "na matmie", "o 3 w nocy", "nigdy" }, ok = 1 },
	},
	Sanepid = {
		{ q = "W lodówce jest jogurt z 2019 roku. Co robisz?", odp = { "wyrzucam", "podaję na obiad", "zostawiam na pamiątkę", "daję dyrektorowi" }, ok = 1 },
		{ q = "Kucharka myje ręce przed...", odp = { "gotowaniem", "wakacjami", "emeryturą", "nigdy" }, ok = 1 },
		{ q = "Pierogi spadły na podłogę. Zasada 5 sekund?", odp = { "nie, do kosza", "tak", "10 sekund", "dla woźnej" }, ok = 1 },
	},
}

------------------------------------------------------------------ ZADANIA
-- obiekt: ścieżka od workspace.SchoolMap; typ: rodzaj minigry; p: parametry
C.Zadania = {
	-- ===== UCZEŃ =====
	U_Matma = { rola = "Uczen", nazwa = "Kartkówka z matmy", gdzie = "Sala 12", obiekt = "Wystroj.Sala12.Tablica", typ = "quiz", p = { pula = "Matma", ile = 3 } },
	U_Polski = { rola = "Uczen", nazwa = "Wypracowanie z polskiego", gdzie = "Sala 11", obiekt = "Wystroj.Sala11.Tablica", typ = "pisz", p = { fraza = "Litwo ojczyzno moja" } },
	U_Angielski = { rola = "Uczen", nazwa = "Słówka z angielskiego", gdzie = "Angielski", obiekt = "Wystroj.Angielski.Tablica", typ = "quiz", p = { pula = "Angielski", ile = 3 } },
	U_Biologia = { rola = "Uczen", nazwa = "Narysuj szkielet", gdzie = "Pracownia anatomii", obiekt = "Wystroj.PracowniaAnatomii.RysunekCzaszki", typ = "plamy", p = { ile = 6, styl = "kreda", tekst = "Połącz kropki szkieletu" } },
	U_Fizyka = { rola = "Uczen", nazwa = "Wahadło na fizyce", gdzie = "Fizyka", obiekt = "Wystroj.Fizyka.BiurkoNauczyciela", typ = "wyczucie", p = { ile = 3, tekst = "Zatrzymaj wahadło w zielonym" } },
	U_Muzyka = { rola = "Uczen", nazwa = "Zagraj na pianinie", gdzie = "Muzyka", obiekt = "Wystroj.Pianino", typ = "sekwencja", p = { dl = 5, styl = "nuty" } },
	U_Informatyka = { rola = "Uczen", nazwa = "Zrestartuj komputer", gdzie = "Informatyka", obiekt = "Wystroj.Informatyka.KomputerCRT", typ = "kod", p = { cyfr = 4, tekst = "Hasło admina jest na karteczce:" } },
	U_Sklepik = { rola = "Uczen", nazwa = "Kup drożdżówkę", gdzie = "Sklepik", obiekt = "Wystroj.Sklepik.Kasa", typ = "quiz", p = { pula = "Sklepik", ile = 2 } },
	U_Memy = { rola = "Uczen", nazwa = "Quiz z memów", gdzie = "Samorząd", obiekt = "Wystroj.Samorzad.Ekran", typ = "quiz", p = { pula = "Memy", ile = 3 } },
	U_Szafka = { rola = "Uczen", nazwa = "Otwórz szafkę na szyfr", gdzie = "Korytarz", obiekt = "Szafki.SzafkaZadanie", typ = "kod", p = { cyfr = 3, tekst = "Szyfr do szafki:" } },
	U_WF = { rola = "Uczen", nazwa = "Spakuj strój na WF", gdzie = "Szatnia WF", obiekt = "Wystroj.SzatniaWF.WozekPilek", typ = "plamy", p = { ile = 5, styl = "ubrania", tekst = "Pozbieraj rzeczy do worka" } },
	U_Silownia = { rola = "Uczen", nazwa = "Wyciskanie hantli", gdzie = "Siłownia", obiekt = "Liceum.Wystroj.Silownia.StojakHantli", typ = "klikanie", p = { ile = 28, tekst = "KLIKAJ! Podnoś hantle!" } },
	U_Bieznia = { rola = "Uczen", nazwa = "Kilometr na bieżni", gdzie = "Siłownia", obiekt = "Liceum.Wystroj.Silownia.Bieznia", typ = "wyczucie", p = { ile = 4, tekst = "Stawiaj kroki w rytm" } },
	U_Lektura = { rola = "Uczen", nazwa = "Oddaj lekturę", gdzie = "Biblioteka (liceum)", obiekt = "Liceum.Wystroj.Biblioteka.StosLektur", typ = "trzymaj", p = { czas = 3, tekst = "Oddajesz „Pana Tadeusza”..." } },
	U_Robot = { rola = "Uczen", nazwa = "Zaprogramuj robota", gdzie = "Robotyka", obiekt = "Liceum.Wystroj.PracowniaRobotyki.Robot", typ = "sekwencja", p = { dl = 4, styl = "strzalki" } },
	U_Chemia = { rola = "Uczen", nazwa = "Wymieszaj odczynniki", gdzie = "Chemia (liceum)", obiekt = "Liceum.Wystroj.Chemia.SzkloLaboratoryjne", typ = "sekwencja", p = { dl = 4, styl = "kolby" } },
	U_Obraz = { rola = "Uczen", nazwa = "Dokończ obraz", gdzie = "Galeria", obiekt = "Przejscia.Przejscie2_Galeria.Wystroj.NiedokonczonyObraz", typ = "plamy", p = { ile = 6, styl = "farba", tekst = "Domaluj brakujące plamy" } },
	U_Teatr = { rola = "Uczen", nazwa = "Próba kółka teatralnego", gdzie = "Hol galerii", obiekt = "Liceum.Wystroj.HolGalerii.KolkoTeatralne", typ = "quiz", p = { pula = "Teatr", ile = 2 } },
	U_Automat = { rola = "Uczen", nazwa = "Wyciągnij zaklinowany baton", gdzie = "Atrium", obiekt = "Liceum.Wystroj.Atrium.Automat", typ = "klikanie", p = { ile = 22, tekst = "Potrząsaj automatem!" } },
	U_Rece = { rola = "Uczen", nazwa = "Umyj ręce", gdzie = "Toalety", obiekt = "Wystroj.Toalety.Umywalka", typ = "trzymaj", p = { czas = 3, tekst = "Szorujesz ręce..." } },
	U_Wzrost = { rola = "Uczen", nazwa = "Zmierz się u pielęgniarki", gdzie = "Gabinet pielęgniarki", obiekt = "Wystroj.Pielegniarka.Wzrostomierz", typ = "wyczucie", p = { ile = 2, tekst = "Stań prosto (zatrzymaj w zielonym)" } },
	U_Bufet = { rola = "Uczen", nazwa = "Zakupy w bufecie", gdzie = "Bufet", obiekt = "Liceum.Wystroj.Bufet.Kasa", typ = "quiz", p = { pula = "Sklepik", ile = 2 } },
	U_Pierogi = { rola = "Uczen", nazwa = "Zjedz pierogi", gdzie = "Stołówka", obiekt = "Wystroj.Stolowka.TalerzPierogi", typ = "klikanie", p = { ile = 18, tekst = "Jedz! Mama mówiła, że do końca." } },

	-- ===== NAUCZYCIEL =====
	N_Kartkowki = { rola = "Nauczyciel", nazwa = "Sprawdź kartkówki", gdzie = "Pokój nauczycielski", obiekt = "Wystroj.PokojNauczycielski.DlugiStol", typ = "quiz", p = { pula = "Kartkowki", ile = 3 } },
	N_Kawa = { rola = "Nauczyciel", nazwa = "Zrób sobie kawę", gdzie = "Pokój nauczycielski", obiekt = "Wystroj.PokojNauczycielski.Ekspres", typ = "trzymaj", p = { czas = 4, tekst = "Ekspres mieli... powoli..." } },
	N_KawaL = { rola = "Nauczyciel", nazwa = "Kawa w liceum", gdzie = "Pokój naucz. (liceum)", obiekt = "Liceum.Wystroj.PokojNauczycielskiL.Ekspres", typ = "trzymaj", p = { czas = 3, tekst = "Druga kawa, bo 7 lekcji..." } },
	N_Tablica = { rola = "Nauczyciel", nazwa = "Zetrzyj tablicę", gdzie = "Biologia", obiekt = "Wystroj.Biologia.Tablica", typ = "plamy", p = { ile = 7, styl = "kreda", tekst = "Zetrzyj kredę gąbką" } },
	N_Ksero = { rola = "Nauczyciel", nazwa = "Skseruj sprawdziany", gdzie = "Samorząd", obiekt = "Wystroj.Samorzad.Drukarka", typ = "trzymaj", p = { czas = 4, tekst = "Ksero się zacina... trzymaj!" } },
	N_Dygestorium = { rola = "Nauczyciel", nazwa = "Przygotuj doświadczenie", gdzie = "Chemia", obiekt = "Wystroj.Chemia.Dygestorium", typ = "sekwencja", p = { dl = 5, styl = "kolby" } },
	N_Obecnosc = { rola = "Nauczyciel", nazwa = "Sprawdź obecność", gdzie = "Angielski", obiekt = "Wystroj.Angielski.Dziennik", typ = "quiz", p = { pula = "Obecnosc", ile = 2 } },
	N_Archiwum = { rola = "Nauczyciel", nazwa = "Odłóż dzienniki do archiwum", gdzie = "Archiwum (liceum)", obiekt = "Liceum.Wystroj.ArchiwumL.SzafaAkt", typ = "trzymaj", p = { czas = 3, tekst = "Układasz segregatory..." } },
	N_Mikrofon = { rola = "Nauczyciel", nazwa = "Próba mikrofonu w auli", gdzie = "Aula", obiekt = "Liceum.Wystroj.Aula.MownicaDrewniana", typ = "pisz", p = { fraza = "raz dwa trzy próba" } },
	N_Informatyka = { rola = "Nauczyciel", nazwa = "Zablokuj gry na komputerach", gdzie = "Informatyka", obiekt = "Wystroj.Informatyka.StolKomputerowy", typ = "kod", p = { cyfr = 4, tekst = "Kod blokady rodzicielskiej:" } },
	N_Muzyka = { rola = "Nauczyciel", nazwa = "Nastrój pianino", gdzie = "Muzyka", obiekt = "Wystroj.Muzyka.BiurkoNauczyciela", typ = "wyczucie", p = { ile = 3, tekst = "Złap czysty dźwięk" } },
	N_Zegar = { rola = "Nauczyciel", nazwa = "Przestaw zegar w klasie", gdzie = "Sala 11", obiekt = "Wystroj.Sala11.Zegar", typ = "wyczucie", p = { ile = 2, tekst = "Ustaw wskazówkę" } },
	N_Dziennik = { rola = "Nauczyciel", nazwa = "Wpisz oceny do dziennika", gdzie = "Sala 13", obiekt = "Wystroj.Sala13.Dziennik", typ = "plamy", p = { ile = 6, styl = "oceny", tekst = "Wpisz oceny w kratki" } },

	-- ===== WOŹNA =====
	W_PlamaParter = { rola = "Wozna", nazwa = "Umyj podłogę na korytarzu", gdzie = "Korytarz, parter", obiekt = "Zadania.PlamaParter", typ = "plamy", p = { ile = 7, styl = "woda", tekst = "Myj mopem!" } },
	W_PlamaPietro = { rola = "Wozna", nazwa = "Wytrzyj kompot z podłogi", gdzie = "Korytarz, 1. piętro", obiekt = "Zadania.PlamaPietro", typ = "plamy", p = { ile = 7, styl = "kompot", tekst = "Kto nachlapał kompotem?!" } },
	W_PlamaAtrium = { rola = "Wozna", nazwa = "Posprzątaj atrium", gdzie = "Atrium (liceum)", obiekt = "Zadania.PlamaAtrium", typ = "plamy", p = { ile = 6, styl = "woda", tekst = "Ślady butów wszędzie..." } },
	W_Smieci = { rola = "Wozna", nazwa = "Wynieś śmieci z atrium", gdzie = "Atrium", obiekt = "Liceum.Wystroj.Atrium.Kosz", typ = "trzymaj", p = { czas = 3, tekst = "Wiążesz worek..." } },
	W_SmieciKuchnia = { rola = "Wozna", nazwa = "Wynieś śmieci z kuchni", gdzie = "Kuchnia", obiekt = "Wystroj.Kuchnia.KoszKuchnia", typ = "trzymaj", p = { czas = 3, tekst = "Ale śmierdzi..." } },
	W_WC = { rola = "Wozna", nazwa = "Umyj toalety", gdzie = "Toalety, 1. piętro", obiekt = "Wystroj.Toalety2.KabinaWC", typ = "plamy", p = { ile = 6, styl = "woda", tekst = "Szoruj!" } },
	W_Graffiti = { rola = "Wozna", nazwa = "Zmyj graffiti", gdzie = "Toalety, parter", obiekt = "Wystroj.Toalety.Graffiti", typ = "plamy", p = { ile = 6, styl = "farba", tekst = "Zmywasz „GOAT 3b”..." } },
	W_Kwiatki = { rola = "Wozna", nazwa = "Podlej kwiatki", gdzie = "Sala 13", obiekt = "Wystroj.Sala13.Kwiatek", typ = "trzymaj", p = { czas = 3, tekst = "Podlewasz..." } },
	W_Palma = { rola = "Wozna", nazwa = "Podlej palmę w atrium", gdzie = "Atrium", obiekt = "Liceum.Wystroj.Atrium.Roslina", typ = "trzymaj", p = { czas = 3, tekst = "Palma pije jak smok" } },
	W_Swietlowka = { rola = "Wozna", nazwa = "Wymień świetlówkę", gdzie = "Kanciapa woźnej", obiekt = "Wystroj.Kanciapa.Regal", typ = "wyczucie", p = { ile = 3, tekst = "Wkręć świetlówkę" } },
	W_Zmywarka = { rola = "Wozna", nazwa = "Zmyj naczynia", gdzie = "Kuchnia", obiekt = "Wystroj.Kuchnia.Zmywarka", typ = "plamy", p = { ile = 6, styl = "woda", tekst = "Talerze po pierogach..." } },
	W_Kociol = { rola = "Wozna", nazwa = "Sprawdź ciśnienie w kotłowni", gdzie = "Kotłownia", obiekt = "Przejscia.Przejscie3_Kotlownia.Wystroj.Manometr", typ = "wyczucie", p = { ile = 3, tekst = "Trzymaj wskazówkę w zielonym" } },
	W_Mop = { rola = "Wozna", nazwa = "Wypłucz mop", gdzie = "Kanciapa woźnej", obiekt = "Wystroj.Kanciapa.Wiadro", typ = "klikanie", p = { ile = 15, tekst = "Wyciskaj mop!" } },
	W_Szatnia = { rola = "Wozna", nazwa = "Pozbieraj worki na kapcie", gdzie = "Szatnia (liceum)", obiekt = "Liceum.Wystroj.SzatniaLiceum.Lawka", typ = "plamy", p = { ile = 5, styl = "ubrania", tekst = "Worki leżą wszędzie" } },

	-- ===== DYREKTOR =====
	D_Swiadectwa = { rola = "Dyrektor", nazwa = "Podpisz świadectwa", gdzie = "Gabinet dyrektora", obiekt = "Wystroj.Dyrektor.BiurkoNauczyciela", typ = "plamy", p = { ile = 6, styl = "podpis", tekst = "Podpisz każde świadectwo" } },
	D_Radio = { rola = "Dyrektor", nazwa = "Ogłoszenie przez radiowęzeł", gdzie = "Radiowęzeł", obiekt = "Liceum.Wystroj.Radiowezel.Mikrofony", typ = "pisz", p = { fraza = "uwaga uczniowie" } },
	D_Budzet = { rola = "Dyrektor", nazwa = "Zatwierdź budżet szkoły", gdzie = "Sekretariat", obiekt = "Wystroj.Sekretariat.BiurkoSekretarki", typ = "quiz", p = { pula = "Budzet", ile = 2 } },
	D_Flaga = { rola = "Dyrektor", nazwa = "Wciągnij flagę", gdzie = "Gabinet dyrektora", obiekt = "Wystroj.Dyrektor.DrzewceFlagi", typ = "klikanie", p = { ile = 20, tekst = "Ciągnij linkę!" } },
	D_Apel = { rola = "Dyrektor", nazwa = "Przemowa na apelu", gdzie = "Aula", obiekt = "Liceum.Wystroj.Aula.Mownica", typ = "pisz", p = { fraza = "drodzy uczniowie" } },
	D_Pisma = { rola = "Dyrektor", nazwa = "Przejrzyj pisma z kuratorium", gdzie = "Sekretariat", obiekt = "Wystroj.Sekretariat.SzafaNaAkta", typ = "trzymaj", p = { czas = 4, tekst = "Pismo nr 4521 w sprawie pisma nr 4520..." } },
	D_Samorzad = { rola = "Dyrektor", nazwa = "Spotkanie z samorządem", gdzie = "Samorząd", obiekt = "Wystroj.Samorzad.StolZebran", typ = "quiz", p = { pula = "Samorzad", ile = 2 } },
	D_Sanepid = { rola = "Dyrektor", nazwa = "Kontrola w kuchni", gdzie = "Kuchnia", obiekt = "Wystroj.Kuchnia.Kuchenka", typ = "quiz", p = { pula = "Sanepid", ile = 2 } },
	D_Puchary = { rola = "Dyrektor", nazwa = "Odkurz puchary", gdzie = "Samorząd", obiekt = "Wystroj.Samorzad.PolkaPucharow", typ = "plamy", p = { ile = 5, styl = "kurz", tekst = "Ścieraj kurz z pucharów" } },
	D_Monitoring = { rola = "Dyrektor", nazwa = "Przejrzyj nagrania", gdzie = "Radiowęzeł", obiekt = "Liceum.Wystroj.Radiowezel.StanowiskoMontazu", typ = "trzymaj", p = { czas = 4, tekst = "Przewijasz taśmę..." } },
}

------------------------------------------------------------------ EKONOMIA
C.Nagrody = {
	Zadanie = { zl = 6, xp = 12 },
	WygranaDobrzy = { zl = 40, xp = 60 },
	WygranaZli = { zl = 60, xp = 80 },
	Przegrana = { zl = 10, xp = 25 },
	Eliminacja = { zl = 8, xp = 10 },
	TrafnyGlos = { zl = 12, xp = 15 },
	Przetrwanie = { zl = 10, xp = 10 },
	DyrektorTrafil = { zl = 25, xp = 30 },
	NaLevel = { zl = 25 },
}
function C.XpNaLevel(lvl) return 100 + (lvl - 1) * 60 end

C.Tytuly = { -- tytuł wyświetlany nad głową wg levelu
	{ lvl = 1, t = "Pierwszak" }, { lvl = 3, t = "Uczeń" }, { lvl = 5, t = "Wagarowicz" },
	{ lvl = 8, t = "Kujon" }, { lvl = 12, t = "Przewodniczący" }, { lvl = 16, t = "Postrach korytarza" },
	{ lvl = 20, t = "Legenda szkoły" }, { lvl = 30, t = "GOAT" },
}

-- Ulepszenia na stałe (5 poziomów)
C.Ulepszenia = {
	SzybkieRece = { nazwa = "Szybkie ręce", opis = "Zadania z trzymaniem idą szybciej", ceny = { 80, 160, 300, 500, 800 }, na = 0.08 },
	Trampki = { nazwa = "Nowe trampki", opis = "Chodzisz szybciej", ceny = { 100, 200, 350, 550, 900 }, na = 0.6 },
	Kieszonkowe = { nazwa = "Kieszonkowe+", opis = "Więcej złotówek z każdej rundy", ceny = { 120, 240, 400, 650, 1000 }, na = 0.1 },
	Kujon = { nazwa = "Kujon", opis = "Więcej XP", ceny = { 120, 240, 400, 650, 1000 }, na = 0.1 },
}

-- Sklepik: rzeczy jednorazowe (do plecaka), używasz w grze
C.Sklepik = {
	{ id = "Drozdzowka", nazwa = "Drożdżówka", cena = 15, efekt = "szybkosc", moc = 4, czas = 20, opis = "Biegasz szybciej przez 20 s" },
	{ id = "Kubus", nazwa = "Kubuś", cena = 10, efekt = "zadania", moc = 0.5, czas = 30, opis = "Zadania z trzymaniem 2× szybciej przez 30 s" },
	{ id = "Zapiekanka", nazwa = "Zapiekanka", cena = 40, efekt = "zl", moc = 2, czas = 0, opis = "Podwójne złotówki za następne zadanie" },
	{ id = "GumaTurbo", nazwa = "Guma Turbo", cena = 5, efekt = "skok", moc = 15, czas = 20, opis = "Skaczesz wyżej przez 20 s" },
	{ id = "BloxyCola", nazwa = "Bloxy Cola", cena = 20, efekt = "xp", moc = 2, czas = 0, opis = "Podwójne XP za następne zadanie" },
	{ id = "Hotdog", nazwa = "Hot-dog", cena = 25, efekt = "szybkosc", moc = 7, czas = 10, opis = "Krótki, mocny sprint" },
}

-- Hulajnogi (Kukurin)
C.Hulajnogi = {
	{ id = "Zwykla", nazwa = "Zwykła", cena = 0, predkosc = 26, kolor = Color3.fromRGB(40, 40, 45), opis = "darmowa" },
	{ id = "Turbo", nazwa = "Turbo", cena = 150, predkosc = 32, kolor = Color3.fromRGB(214, 40, 57), opis = "150 zł" },
	{ id = "Zlota", nazwa = "Złota", cena = 500, predkosc = 38, kolor = Color3.fromRGB(230, 180, 40), opis = "500 zł" },
}

-- Plecaki (skórki widoczne na postaci)
C.Plecaki = {
	{ id = "Klasyczny", nazwa = "Klasyczny", cena = 0, kolor = Color3.fromRGB(52, 110, 200) },
	{ id = "Czerwony", nazwa = "Czerwony", cena = 60, kolor = Color3.fromRGB(214, 40, 57) },
	{ id = "Gamingowy", nazwa = "Gamingowy RGB", cena = 250, kolor = Color3.fromRGB(120, 40, 220), rgb = true },
	{ id = "Teczka", nazwa = "Teczka kujona", cena = 180, kolor = Color3.fromRGB(110, 70, 40) },
	{ id = "WorekKapcie", nazwa = "Worek na kapcie", cena = 30, kolor = Color3.fromRGB(240, 240, 230) },
	{ id = "Zloty", nazwa = "Złoty plecak", cena = 900, kolor = Color3.fromRGB(240, 190, 40), neon = true },
}

-- Emotki (domyślne animacje Robloxa R15)
C.Emotki = {
	{ id = "Machanie", nazwa = "Machanie", cena = 0, anim = "rbxassetid://507770239" },
	{ id = "Taniec", nazwa = "Taniec", cena = 50, anim = "rbxassetid://507771019" },
	{ id = "Wiwat", nazwa = "Wiwat", cena = 30, anim = "rbxassetid://507770677" },
	{ id = "Smiech", nazwa = "Śmiech", cena = 40, anim = "rbxassetid://507770818" },
	{ id = "Wskazanie", nazwa = "Wskazanie", cena = 20, anim = "rbxassetid://507770453" },
}

------------------------------------------------------------------ DŹWIĘKI
C.Dzwieki = {
	Dzwon = "rbxassetid://2783281207",
	Autobus = "rbxassetid://93894279029996",
	DrzwiAutobusu = "rbxassetid://84422926311395",
	Alarm = "rbxassetid://7084812679",
	Cios = "rbxassetid://109316755832781",
	Sukces = "rbxassetid://18448089848",
	Level = "rbxassetid://112485797063762",
	Moneta = "rbxassetid://113730061669739",
	AlarmPozarowy = "rbxassetid://9125557781",
	Rzut = "rbxassetid://125346857027000",
	Blad = "rbxassetid://72577143736585",
	Pstryk = "rbxassetid://129921942229278",
	Gwizdek = "rbxassetid://9118114334",
	Smutny = "rbxassetid://190705984",
	Wygrana = "rbxassetid://9067124098",
	Hover = "rbxassetid://139719503904449",
	Klik = "rbxassetid://88442833509532",
}

------------------------------------------------------------------ MEMY (soundboard)
C.Memy = {
	{ id = "BRUH", tekst = "bruh", dzwiek = "Blad" },
	{ id = "DZWONEK", tekst = "Dzwonek jest dla nauczyciela!", dzwiek = "Dzwon" },
	{ id = "WRR", tekst = "wrrrr", dzwiek = "Autobus" },
	{ id = "OOF", tekst = "oof", dzwiek = "Cios" },
	{ id = "CISZA!", tekst = "CISZAAA!", dzwiek = "Gwizdek" },
	{ id = "KARTKÓWKA", tekst = "Kartkówka! Karteczki wyjąć!", dzwiek = "Alarm" },
	{ id = "HAHA", tekst = "hahaha", dzwiek = "Wygrana" },
	{ id = "SUS", tekst = "ten jest sus...", dzwiek = "Smutny" },
}

------------------------------------------------------------------ SABOTAŻE
C.Sabotaze = {
	Swiatlo = { nazwa = "Zgaś światło", opis = "całe piętro w ciemności" },
	Drzwi = { nazwa = "Zamknij drzwi", opis = "wszystkie drzwi na 12 s" },
	Alarm = { nazwa = "Alarm pożarowy", opis = "45 s na wyłączenie w 2 miejscach" },
	Kartkowka = { nazwa = "Niezapowiedziana kartkówka", opis = "wszyscy muszą odpowiedzieć" },
}

------------------------------------------------------------------ TEKSTY
C.Wskazowki = {
	"Pani, a będzie to na sprawdzianie?",
	"Kartkówka zapowiedziana = kartkówka niezapowiedziana.",
	"Dzwonek jest dla nauczyciela!",
	"Kto nie ma kapci, ten w kapciach z sali gimnastycznej.",
	"Zakaz jazdy na hulajnodze po korytarzu. (Wszyscy jeżdżą.)",
	"Szczęśliwy numerek dzisiaj: 67.",
}

return C
