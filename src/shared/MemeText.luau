--!strict
-- src/shared/MemeText.luau  (Agent Claude)
-- Wszystkie memiczne teksty w jednym miejscu (łatwo dorzucać nowe trendy).
-- Źródło słownictwa: finał Młodzieżowego Słowa Roku 2025 (zwycięzca: "szponcić / szpont").
-- Zasady: bez prawdziwych osób, bez marek, bez przekleństw.

local MemeText = {}

MemeText.Graffiti = {
	"GOAT 3b",
	"fr fr",
	"bro tu był",
	"twin <3",
	"6 7",
	"lowkey nudno",
	"SZPONT 2026",
	"skibidi?",
	"tuff",
	"OKPA",
	"slay 8a",
	"kto czyta ten szponci",
}

MemeText.Gazetki = {
	Samorzad = {
		tytul = "SAMORZĄD UCZNIOWSKI",
		kartki = {
			"Zakaz mówienia\n„6 7”\nna lekcjach!",
			"Słowo miesiąca:\nTUFF",
			"Konkurs: kto\npierwszy powie\nskibidi do\ndyrektora",
			"Dyskoteka\nw piątek\n(bez szpontu)",
		},
	},
	Ogloszenia = {
		tytul = "OGŁOSZENIA",
		kartki = {
			"Zgubiono worek\nna kapcie\n(zielony)",
			"Kółko\nszachowe:\nwt. 14:30",
			"Brainrot\nzakazany\nod poniedziałku",
			"Zbiórka\nmakulatury!",
		},
	},
	Bhp = {
		tytul = "BEZPIECZNA SZKOŁA",
		kartki = {
			"Nie biegamy\npo korytarzu!",
			"Hulajnogi\nzostawiamy\nprzed szkołą",
			"Myj ręce\nprzed\nobiadem",
		},
	},
	Sport = {
		tytul = "SPORT SZKOLNY",
		kartki = {
			"Turniej\nzbijaka\n3a vs 3b",
			"Strój na WF\nobowiązkowy!\n(bez wymówek)",
			"GOAT\ntygodnia:\n7c",
		},
	},
}

MemeText.TabliceSal = {
	Matematyka = "Temat: Tabliczka mnożenia\n\n6 · 7 = 42\n(nie 67!!!)\n\nPraca domowa: str. 67, zad. 1–6",
	Polski = "Temat: Ortografia\n\nrz / ż, ó / u, h / ch\n\nSłowo roku: szponcić\nDyktando w piątek!",
	Geografia = "Temat: Mapa Polski\n\nNajwyższy szczyt: Rysy\nNajdłuższa rzeka: Wisła",
	Historia = "Temat: Chrzest Polski\n\n966 r.\n(nie 967!!)",
	Biologia = "Temat: Komórka\n\njądro, cytoplazma,\nbłona komórkowa",
	Fizyka = "Temat: Prędkość\n\nv = s / t\nhulajnoga po korytarzu = zakazane",
	Angielski = "Topic: Present Simple\n\nI go, you go,\nhe goes\nlowkey easy fr",
	Chemia = "Temat: Układ okresowy\n\nH₂O – woda\nNaCl – sól\nNIE WĄCHAĆ ODCZYNNIKÓW",
	Muzyka = "Temat: Hymn i nuty\n\ndo re mi fa sol la si do",
	Informatyka = "Temat: Algorytmy\n\nif (dzwonek) then\n   przerwa()\nend",
}

MemeText.Plakaty = {
	"TABLICZKA MNOŻENIA\n2·2=4  3·3=9  6·7=42",
	"ALFABET\nA Ą B C Ć D E Ę\nF G H I J K L Ł",
	"CISZA!\nTrwa lekcja",
	"Kto pyta,\nnie błądzi",
	"Nie rozmawiamy\nna lekcji, bro",
}

MemeText.Werdykty = {
	Rozrabiaka = "%s był Rozrabiaką. Totalny szpont.",
	Niewinny = "%s NIE był Rozrabiaką… lowkey słabo, bro",
}

function MemeText.losuj<T>(lista: { T }): T
	return lista[math.random(1, #lista)]
end

-- Szczęśliwy numerek: zwykle 1–30, czasem legendarne 67
function MemeText.szczesliwyNumerek(): number
	if math.random() < 0.12 then
		return 67
	end
	return math.random(1, 30)
end

return MemeText
