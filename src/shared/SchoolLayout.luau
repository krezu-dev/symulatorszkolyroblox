--!strict
-- src/shared/SchoolLayout.luau  (Agent Claude)
-- JEDNO źródło prawdy o pozycjach w nowej szkole. Serwisy (kratki, monety, plamy,
-- sabotaże) czytają pozycje stąd, więc po przebudowie mapy wystarczy zmienić ten plik.
--
-- Układ (studs):  piwnica Y=0, parter Y=10, I piętro Y=26, dach Y=42
-- Główny budynek X: -112..112, Z: -36..36, korytarz Z: -8..8
-- Sala gimnastyczna X: 112..176, Z: -40..40 (poziom parteru)
-- Plac apelowy przed wejściem (Z < -52)

local L = {}

L.Y = { Piwnica = 0, Parter = 10, Pietro = 26, Dach = 42 }
L.Budynek = { X0 = -112, X1 = 112, Z0 = -36, Z1 = 36, KorytarzZ0 = -8, KorytarzZ1 = 8 }
L.Sala = { X0 = 112, X1 = 176, Z0 = -40, Z1 = 40 }

L.Spawny = {
	Szkola = Vector3.new(0, 13, 0), -- korytarz parteru przy holu
	Stolowka = Vector3.new(-80, 13, -22), -- zebrania
	Lobby = Vector3.new(0, 3, -84), -- plac apelowy
}

-- Kratki wentylacyjne (dla Rozrabiaki) – w zakamarkach
L.Kratki = {
	{ Name = "Kanciapa Woźnej", Pos = Vector3.new(-104, 10.05, 28) },
	{ Name = "Toalety (parter)", Pos = Vector3.new(-88, 10.05, 14) },
	{ Name = "Schowek pod Schodami", Pos = Vector3.new(9, 10.05, 18) },
	{ Name = "Zmywak Kuchni", Pos = Vector3.new(-24, 10.05, -30) },
	{ Name = "Magazynek WF", Pos = Vector3.new(168, 10.05, 32) },
	{ Name = "Zaplecze Chemiczne", Pos = Vector3.new(-52, 26.05, 30) },
	{ Name = "Archiwum", Pos = Vector3.new(104, 26.05, -30) },
	{ Name = "Szatnia w Piwnicy", Pos = Vector3.new(-40, 0.25, 6) },
}

-- Strefy spawnu monet (Min/Max, Y = wysokość monety)
L.StrefyMonet = {
	{ Min = Vector3.new(-108, 12, -6), Max = Vector3.new(108, 12, 6) }, -- korytarz parteru
	{ Min = Vector3.new(-108, 28, -6), Max = Vector3.new(108, 28, 6) }, -- korytarz I piętra
	{ Min = Vector3.new(-108, 12, -34), Max = Vector3.new(-52, 12, -12) }, -- stołówka
	{ Min = Vector3.new(116, 12, -36), Max = Vector3.new(172, 12, 20) }, -- sala gimnastyczna
	{ Min = Vector3.new(-44, 2, -11), Max = Vector3.new(44, 2, 11) }, -- szatnia w piwnicy (alejka)
	{ Min = Vector3.new(-50, 2, -110), Max = Vector3.new(50, 2, -60) }, -- plac apelowy
}

-- Startowe plamy do zmycia przez Woźną
L.Plamy = {
	Vector3.new(-60, 10.05, 2),
	Vector3.new(40, 10.05, -3),
	Vector3.new(-74, 10.05, -12),
	Vector3.new(0, 26.05, 0),
	Vector3.new(140, 10.05, 4),
}

-- Skrzynka bezpieczników (Awaria Korków) – w Kanciapie Woźnej, na ścianie
L.SkrzynkaBezpiecznikow = Vector3.new(-104, 15, 35)

-- Blokady drzwi (sabotaż) – drzwi sal (rozmiar blokady 8 x 12 x 1, ściana wzdłuż X)
L.BlokadyDrzwi = {
	Vector3.new(87, 16, 8), -- Sala 12 Matematyka
	Vector3.new(-80, 16, -8), -- Stołówka
}

return L
