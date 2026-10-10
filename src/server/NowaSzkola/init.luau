--!nonstrict
-- src/server/NowaSzkola/init.luau  (Agent Claude)
-- NOWA SZKOŁA "TYSIĄCLATKA" (Szkoła Podstawowa nr 67)
--
-- • NowaSzkola.zbuduj()  – buduje szkołę jako STATYCZNE modele w workspace.SchoolMap.
--                          Uruchamiane raz w trybie edycji Studio (szkoła zostaje zapisana w plejsie).
-- • NowaSzkola.setupMap(onBellRing) – w trakcie gry NIC nie buduje, tylko podpina
--                          zadania, dzwon, szafki-kryjówki, radiowęzeł i migające świetlówki.
--                          Jeśli mapy brak (np. pusty plejs), buduje ją awaryjnie.
--
-- Wygląd na podstawie typowych polskich szkół (tysiąclatki): wysoki parter z kamiennymi
-- schodami, lamperia olejna, lastryko na korytarzach, parkiet w salach, zielone tablice
-- z godłem, szatnia z boksami z siatki w piwnicy, gazetki ścienne, sklepik, gabinet pielęgniarki.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local function modul(nazwa: string)
	return require(script:FindFirstChild(nazwa) or Shared:WaitForChild(nazwa))
end
local L = modul("SchoolLayout")
local MemeText = modul("MemeText")
local K = require(script:WaitForChild("Klocki"))
local C = K.Kolory
local Mat = Enum.Material

local NowaSzkola = {}

local WERSJA = 1
local GODLO_TEKSTURA = "rbxassetid://130518454145773" -- obraz z decala Toolbox 112300454073912
do
	local pf = ServerStorage:FindFirstChild("Prefaby")
	local g = pf and pf:FindFirstChild("Godlo")
	if g and g:IsA("Decal") and g.Texture ~= "" then
		GODLO_TEKSTURA = g.Texture
	end
end

-- Wymiary
local X0, X1 = L.Budynek.X0, L.Budynek.X1
local Z0, Z1 = L.Budynek.Z0, L.Budynek.Z1
local KZ0, KZ1 = L.Budynek.KorytarzZ0, L.Budynek.KorytarzZ1
local YB, YP, Y1, YD = L.Y.Piwnica, L.Y.Parter, L.Y.Pietro, L.Y.Dach
local H = 16 -- wysokość kondygnacji

-- Style ścian
local function styl(lam, gora, extra)
	local s = { lam = lam, gora = gora or C.Bialy }
	if extra then
		for k, v in pairs(extra) do
			s[k] = v
		end
	end
	return s
end
local S = {
	Korytarz = styl(C.LamperiaZielona),
	Sala = styl(C.LamperiaBezowa),
	SalaNieb = styl(C.LamperiaNiebieska),
	SalaZolta = styl(C.LamperiaZolta),
	Szatnia = styl(C.LamperiaSzara),
	Plytki = { gora = C.Plytki, mat = Mat.CeramicTiles, plaska = true },
	Elewacja = { gora = C.Elewacja, mat = Mat.Plaster, plaska = true },
	Cegla = { gora = C.Cegla, mat = Mat.Brick, plaska = true },
	Gym = styl(C.LamperiaNiebieska, C.Bialy, { wys = 6 }),
	Bialy = { gora = C.Bialy, plaska = true },
}

-- Tag do podpinania rozgrywki (statyczna mapa nie ma skryptów)
local function tag(inst: Instance, nazwa: string)
	CollectionService:AddTag(inst, nazwa)
end

-- Prompt zadania (podpinany w setupMap przez atrybut "Zadanie")
local function promptZadania(p: BasePart, zadanieId: string, akcja: string, obiekt: string, czas: number?, dystans: number?)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "PromptZadania"
	pr.ActionText = akcja
	pr.ObjectText = obiekt
	pr.HoldDuration = czas or 0.5
	pr.MaxActivationDistance = dystans or 10
	pr.RequiresLineOfSight = false
	pr:SetAttribute("Zadanie", zadanieId)
	pr.Parent = p
	tag(pr, "SzkolaZadanie")
	return pr
end

-- ============================================================
-- ELEMENTY WYPOSAŻENIA
-- ============================================================

-- Ławka szkolna dwuosobowa + 2 krzesła. cf.LookVector = kierunek, w który patrzą uczniowie.
local function lawkaPodwojna(cf: CFrame, f: Instance)
	local blat = K.part("BlatLawki", Vector3.new(5.6, 0.25, 2.2), cf * CFrame.new(0, 2.65, 0), C.ParkietJasny, Mat.Wood, f)
	K.part("NogaLawki", Vector3.new(0.25, 2.5, 2), cf * CFrame.new(-2.5, 1.27, 0), C.Metal, Mat.Metal, f)
	K.part("NogaLawki", Vector3.new(0.25, 2.5, 2), cf * CFrame.new(2.5, 1.27, 0), C.Metal, Mat.Metal, f)
	K.part("PolkaLawki", Vector3.new(5.2, 0.15, 1.6), cf * CFrame.new(0, 2.2, -0.1), C.Metal, Mat.Metal, f)
	for _, x in ipairs({ -1.4, 1.4 }) do
		local kolor = Color3.fromRGB(46, 110, 70)
		K.part("Siedzisko", Vector3.new(1.7, 0.2, 1.6), cf * CFrame.new(x, 1.6, 2.0), C.ParkietJasny, Mat.Wood, f)
		K.part("Oparcie", Vector3.new(1.7, 1.0, 0.15), cf * CFrame.new(x, 2.7, 2.8), C.ParkietJasny, Mat.Wood, f)
		K.part("RamaKrzesla", Vector3.new(1.5, 1.5, 0.15), cf * CFrame.new(x, 0.75, 2.75), kolor, Mat.Metal, f)
		K.part("RamaKrzesla", Vector3.new(1.5, 1.5, 0.15), cf * CFrame.new(x, 0.75, 1.25), kolor, Mat.Metal, f)
	end
	return blat
end

-- Tablica kredowa z napisem + godło nad nią. pos = środek tablicy na ścianie, n = normalna (do klasy)
local function tablicaZGodlem(pos: Vector3, n: Vector3, tekst: string, f: Instance): BasePart
	local cf = K.patrz(pos, n)
	-- prefab z Toolboxa (lub zamiennik)
	local m = K.prefab("Tablica", cf * CFrame.new(0, -3.1, 0), Vector3.new(15, 6.5, 0.6), f)
	if not m then
		K.part("Tablica", Vector3.new(15, 6.2, 0.3), cf, C.Tablica, Mat.Slate, f)
		K.part("RamaTablicy", Vector3.new(15.6, 6.8, 0.2), cf * CFrame.new(0, 0, 0.12), C.Drewno, Mat.Wood, f)
	end
	-- półka na kredę
	K.part("PolkaNaKrede", Vector3.new(14, 0.2, 0.6), cf * CFrame.new(0, -3.3, -0.35), C.Drewno, Mat.Wood, f)
	K.part("Gabka", Vector3.new(0.9, 0.35, 0.45), cf * CFrame.new(4.5, -3.05, -0.4), Color3.fromRGB(230, 200, 60), Mat.Fabric, f)
	-- napis kredą
	local kreda = K.part("NapisKreda", Vector3.new(13.6, 5.4, 0.05), cf * CFrame.new(0, 0.1, -0.45), C.Tablica, Mat.SmoothPlastic, f, { Transparency = 1, CanCollide = false, CastShadow = false })
	K.napis(kreda, Enum.NormalId.Front, tekst, nil, C.Kreda, Enum.Font.PatrickHand, { przezroczyste = true })
	-- godło
	local godlo = K.part("Godlo", Vector3.new(2.2, 2.7, 0.1), cf * CFrame.new(0, 5.2, -0.1), Color3.fromRGB(200, 30, 40), Mat.SmoothPlastic, f, { CanCollide = false })
	local d = Instance.new("Decal")
	d.Texture = GODLO_TEKSTURA
	d.Face = Enum.NormalId.Front
	d.Parent = godlo
	return kreda
end

local function kaloryfer(pos: Vector3, n: Vector3, f: Instance)
	local cf = K.patrz(pos, n)
	local m = K.prefab("Kaloryfer", cf, Vector3.new(5, 2.8, 0.6), f)
	if not m then
		for i = -2, 2 do
			K.part("Zeberko", Vector3.new(0.6, 2.6, 0.5), cf * CFrame.new(i * 0.9, 1.3, 0), Color3.fromRGB(235, 235, 230), Mat.Metal, f)
		end
	end
end

local function kwiatek(pos: Vector3, f: Instance)
	local m = K.prefab("Kwiatek", CFrame.new(pos) * CFrame.Angles(0, math.random() * 6.28, 0), Vector3.new(1.4, 2.4, 1.4), f)
	if not m then
		K.cyl("Doniczka", 0.8, 0.9, CFrame.new(pos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(170, 80, 50), Mat.Slate, f)
		K.part("Lisc", Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 1.3, 0)), Color3.fromRGB(60, 140, 60), Mat.Grass, f, { Shape = Enum.PartType.Ball })
	end
end

local function zegar(pos: Vector3, n: Vector3, f: Instance)
	local cf = K.patrz(pos, n)
	local m = K.prefab("Zegar", cf * CFrame.new(0, -1, 0), Vector3.new(1.8, 1.8, 0.3), f)
	if not m then
		local t = K.cyl("Zegar", 0.15, 1.8, cf, Color3.fromRGB(245, 245, 245), Mat.SmoothPlastic, f)
	end
	-- wskazówki (zawsze za pięć dzwonek)
	K.part("WskazowkaG", Vector3.new(0.1, 0.55, 0.05), cf * CFrame.new(0.12, 0.2, -0.25) * CFrame.Angles(0, 0, math.rad(-30)), Color3.fromRGB(20, 20, 20), Mat.SmoothPlastic, f, { CanCollide = false })
	K.part("WskazowkaM", Vector3.new(0.07, 0.75, 0.05), cf * CFrame.new(-0.1, 0.32, -0.26) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(20, 20, 20), Mat.SmoothPlastic, f, { CanCollide = false })
end

local function gasnica(pos: Vector3, n: Vector3, f: Instance)
	local m = K.prefab("Gasnica", K.patrz(pos, n), Vector3.new(1.4, 2.6, 0.9), f)
	if not m then
		K.cyl("Gasnica", 2.4, 0.8, CFrame.new(pos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(200, 20, 20), Mat.Metal, f)
	end
end

local function dzwonekNaScianie(pos: Vector3, n: Vector3, f: Instance)
	local cf = K.patrz(pos, n)
	K.cyl("DzwonekElektryczny", 0.35, 1.1, cf * CFrame.new(0, 0, -0.2) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(190, 40, 40), Mat.Metal, f)
end

local function lampyWSali(x0, x1, z0, z1, y, f, swiatla)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local dx = (x1 - x0) / 4
	K.swietlowka(Vector3.new(cx - dx, y + 14.8, cz), swiatla ~= false, { zasieg = 26, jasnosc = 0.85 }, f)
	K.swietlowka(Vector3.new(cx + dx, y + 14.8, cz), swiatla ~= false, { zasieg = 26, jasnosc = 0.85 }, f)
end

-- Podłoga pomieszczenia (warstwa wykończeniowa 0.2)
local function podloga(nazwa, x0, x1, z0, z1, y, kolor, mat, f, otwory)
	K.strop(nazwa, x0, x1, z0, z1, y, 0.2, kolor, mat, otwory, f)
end

-- ============================================================
-- SALA LEKCYJNA (uniwersalna)
-- r = { x0, x1, z0, z1, y, strona = "N"/"S", numer, przedmiot, styl, tekst, zadanie? }
-- Tablica na ścianie zachodniej (x0), uczniowie patrzą na -X. Drzwi od korytarza przy tablicy.
-- ============================================================
local function salaLekcyjna(r, f)
	local cz = (r.z0 + r.z1) / 2
	local kierDoKlasy = K.PLUS_X
	podloga("Parkiet", r.x0, r.x1, r.z0, r.z1, r.y, C.Parkiet, Mat.WoodPlanks, f)

	local kreda = tablicaZGodlem(Vector3.new(r.x0 + 0.85, r.y + 6.6, cz), kierDoKlasy, r.tekst or "", f)
	if r.zadanie then
		promptZadania(kreda, r.zadanie.id, r.zadanie.akcja, r.zadanie.obiekt)
	end

	-- podest i biurko nauczyciela
	K.box("Podest", r.x0 + 0.5, r.x0 + 9, r.y, r.y + 0.6, r.z0 + 3, r.z1 - 3, Color3.fromRGB(120, 78, 44), Mat.WoodPlanks, f)
	local biurkoCf = K.patrz(Vector3.new(r.x0 + 6, r.y + 0.6, cz + 4), kierDoKlasy)
	if not K.prefab("BiurkoNauczyciela", biurkoCf, Vector3.new(6.5, 3.2, 3), f) then
		K.part("BiurkoNauczyciela", Vector3.new(3, 3, 6.5), CFrame.new(r.x0 + 6, r.y + 2.1, cz + 4), C.Drewno, Mat.Wood, f)
	end
	K.part("Dziennik", Vector3.new(1.2, 0.25, 1.6), CFrame.new(r.x0 + 6, r.y + 3.95, cz + 3), Color3.fromRGB(30, 80, 40), Mat.Fabric, f)

	-- 4 rzędy x 3 kolumny ławek dwuosobowych, przodem do tablicy
	for row = 0, 3 do
		for col = -1, 1 do
			local p = Vector3.new(r.x0 + 12 + row * 4.8, r.y, cz + col * 8)
			lawkaPodwojna(K.patrz(p, K.MINUS_X), f)
		end
	end

	-- szafa z pomocami naukowymi i zegar z tyłu klasy
	K.prefab("Regal", K.patrz(Vector3.new(r.x1 - 1.4, r.y, r.z0 + 5 + (r.strona == "S" and (r.z1 - r.z0 - 10) or 0)), K.MINUS_X), Vector3.new(5, 9, 1.4), f)
	zegar(Vector3.new(r.x1 - 0.6, r.y + 11.5, cz), K.MINUS_X, f)

	-- plakaty na ścianie korytarzowej (od środka)
	local scianaKor = (r.strona == "N") and r.z0 or r.z1
	local nKor = (r.strona == "N") and K.PLUS_Z or K.MINUS_Z
	K.plakat("Plakat", Vector3.new(r.x0 + 20, r.y + 8, scianaKor + nKor.Z * 0.62), nKor, 7, 3.6, r.plakat or MemeText.losuj(MemeText.Plakaty), Color3.fromRGB(255, 252, 235), Color3.fromRGB(40, 40, 90), Enum.Font.FredokaOne, f)

	-- tabliczka nad drzwiami (od strony korytarza)
	local nZew = -nKor
	K.plakat("TabliczkaSali", Vector3.new(r.x0 + 7, r.y + 10.6, scianaKor + nZew.Z * 0.62), nZew, 6.5, 1.4, `SALA {r.numer}\n{string.upper(r.przedmiot)}`, Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)

	lampyWSali(r.x0, r.x1, r.z0, r.z1, r.y, f)
end

-- ============================================================
-- BUDOWA
-- ============================================================
local function budujPomieszczenia(map: Folder)
	local rng = Random.new(67)

	-- ---------- definicje pomieszczeń (x0, x1, strona, kondygnacja) ----------
	-- Każde: nazwa, styl ścian (do ścianek działowych), drzwi od korytarza (środek, szerokość) lub otwarte
	local POM = {
		-- PARTER (y = YP)
		{ id = "Kanciapa", x0 = -112, x1 = -96, s = "N", y = YP, styl = S.Szatnia, drzwi = -104 },
		{ id = "Toalety", x0 = -96, x1 = -80, s = "N", y = YP, styl = S.Plytki, drzwi = -88 },
		{ id = "Sklepik", x0 = -80, x1 = -48, s = "N", y = YP, styl = S.SalaZolta, drzwi = -60, okienkoSklepu = true },
		{ id = "Pielegniarka", x0 = -48, x1 = -16, s = "N", y = YP, styl = S.Plytki, drzwi = -24 },
		{ id = "Klatka", x0 = -16, x1 = 16, s = "N", y = YP, styl = S.Korytarz, otwarte = { -15, 15 } },
		{ id = "Biblioteka", x0 = 16, x1 = 48, s = "N", y = YP, styl = S.SalaNieb, drzwi = 23 },
		{ id = "Sala11", x0 = 48, x1 = 80, s = "N", y = YP, styl = S.Sala, drzwi = 55 },
		{ id = "Sala12", x0 = 80, x1 = 112, s = "N", y = YP, styl = S.SalaZolta, drzwi = 87 },
		{ id = "Stolowka", x0 = -112, x1 = -48, s = "S", y = YP, styl = S.SalaZolta, drzwi = -80, podwojne = true },
		{ id = "Kuchnia", x0 = -48, x1 = -16, s = "S", y = YP, styl = S.Plytki, drzwi = -24 },
		{ id = "Hol", x0 = -16, x1 = 16, s = "S", y = YP, styl = S.Korytarz, otwarte = { -15, 15 } },
		{ id = "PokojNauczycielski", x0 = 16, x1 = 48, s = "S", y = YP, styl = S.SalaNieb, drzwi = 23 },
		{ id = "Sala13", x0 = 48, x1 = 80, s = "S", y = YP, styl = S.SalaNieb, drzwi = 55 },
		{ id = "SzatniaWF", x0 = 80, x1 = 112, s = "S", y = YP, styl = S.Szatnia, drzwi = 87 },
		-- I PIĘTRO (y = Y1)
		{ id = "Toalety2", x0 = -112, x1 = -80, s = "N", y = Y1, styl = S.Plytki, drzwi = -96 },
		{ id = "Chemia", x0 = -80, x1 = -56, s = "N", y = Y1, styl = S.SalaNieb, drzwi = -73 },
		{ id = "ZapleczeChem", x0 = -56, x1 = -48, s = "N", y = Y1, styl = S.Szatnia },
		{ id = "Biologia", x0 = -48, x1 = -16, s = "N", y = Y1, styl = S.Sala, drzwi = -41 },
		{ id = "Klatka2", x0 = -16, x1 = 16, s = "N", y = Y1, styl = S.Korytarz, otwarte = { -16, 16 } },
		{ id = "Informatyka", x0 = 16, x1 = 48, s = "N", y = Y1, styl = S.SalaNieb, drzwi = 23 },
		{ id = "Historia", x0 = 48, x1 = 80, s = "N", y = Y1, styl = S.SalaZolta, drzwi = 55 },
		{ id = "Sekretariat", x0 = 80, x1 = 112, s = "N", y = Y1, styl = S.Sala, drzwi = 87 },
		{ id = "Muzyka", x0 = -112, x1 = -80, s = "S", y = Y1, styl = S.SalaZolta, drzwi = -105 },
		{ id = "Fizyka", x0 = -80, x1 = -48, s = "S", y = Y1, styl = S.Sala, drzwi = -73 },
		{ id = "Angielski", x0 = -48, x1 = -16, s = "S", y = Y1, styl = S.SalaNieb, drzwi = -41 },
		{ id = "Hol2", x0 = -16, x1 = 16, s = "S", y = Y1, styl = S.Korytarz, otwarte = { -16, 16 } },
		{ id = "Samorzad", x0 = 16, x1 = 48, s = "S", y = Y1, styl = S.SalaZolta, drzwi = 23 },
		{ id = "Dyrektor", x0 = 48, x1 = 80, s = "S", y = Y1, styl = S.Sala, drzwi = 55 },
		{ id = "Archiwum", x0 = 80, x1 = 112, s = "S", y = Y1, styl = S.Szatnia, drzwi = 105 },
	}
	local byId = {}
	for _, p in ipairs(POM) do
		p.z0 = (p.s == "N") and KZ1 or Z0
		p.z1 = (p.s == "N") and Z1 or KZ0
		byId[p.id] = p
	end

	local fKonstr = K.folder("Konstrukcja", map)
	local fWystroj = K.folder("Wystroj", map)

	-- ---------- PIWNICA / COKÓŁ / STROPY ----------
	-- fundament pod budynkiem poza szatnią (pełny blok)
	K.box("Fundament", X0, -48, YB, YP - 1, Z0, Z1, C.Beton, Mat.Concrete, fKonstr)
	K.box("Fundament", 48, X1, YB, YP - 1, Z0, Z1, C.Beton, Mat.Concrete, fKonstr)
	-- cokół z cegły (z zewnątrz), małe okienka piwniczne
	local okienkaPiwnicy = {}
	for x = -40, 40, 16 do
		table.insert(okienkaPiwnicy, { a = x - 2.5, b = x + 2.5, lo = 6.4, hi = 9, typ = "okno", ciemne = true })
	end
	for _, z in ipairs({ Z0, Z1 }) do
		local zew = (z == Z0) and -1 or 1
		K.wall("X", z + zew * 0.5, X0 - 1, -48, YB, YP - 0.2, {}, S.Cegla, S.Cegla, fKonstr)
		K.wall("X", z + zew * 0.5, 48, X1 + 1, YB, YP - 0.2, {}, S.Cegla, S.Cegla, fKonstr)
		local wew = styl(C.LamperiaSzara)
		K.wall("X", z + zew * 0.5, -48, 48, YB, YP - 0.2, okienkaPiwnicy, (zew < 0) and S.Cegla or wew, (zew < 0) and wew or S.Cegla, fKonstr)
	end
	for _, x in ipairs({ X0, X1 }) do
		K.wall("Z", x + ((x < 0) and -0.5 or 0.5), Z0, Z1, YB, YP - 0.2, {}, S.Cegla, S.Cegla, fKonstr)
	end
	-- ściany szatni w piwnicy (x = ±48)
	K.wall("Z", -48.5, Z0, Z1, YB, YP - 0.2, {}, S.Cegla, styl(C.LamperiaSzara), fKonstr)
	K.wall("Z", 48.5, Z0, Z1, YB, YP - 0.2, {}, styl(C.LamperiaSzara), S.Cegla, fKonstr)

	-- stropy (biały sufit), otwory na klatkę schodową i zejście do piwnicy
	local otworPiwnica = { 6, 14, -30, -14 }
	K.strop("StropParter", X0, X1, Z0, Z1, YP - 0.2, 0.8, C.Sufit, Mat.SmoothPlastic, { otworPiwnica }, fKonstr)
	K.strop("StropPietro", X0, X1, Z0, Z1, Y1 - 0.2, 0.8, C.Sufit, Mat.SmoothPlastic, { { -16, 2, 8, 36 }, { 2, 16, 10, 36 } }, fKonstr)
	-- dach z attyką
	K.box("Dach", X0 - 1.5, X1 + 1.5, YD, YD + 1, Z0 - 1.5, Z1 + 1.5, Color3.fromRGB(90, 90, 92), Mat.Concrete, fKonstr)
	K.box("Attyka", X0 - 1.5, X1 + 1.5, YD + 1, YD + 2.5, Z0 - 1.5, Z0 - 0.8, C.Elewacja, Mat.Plaster, fKonstr)
	K.box("Attyka", X0 - 1.5, X1 + 1.5, YD + 1, YD + 2.5, Z1 + 0.8, Z1 + 1.5, C.Elewacja, Mat.Plaster, fKonstr)
	K.box("Attyka", X0 - 1.5, X0 - 0.8, YD + 1, YD + 2.5, Z0 - 1.5, Z1 + 1.5, C.Elewacja, Mat.Plaster, fKonstr)
	K.box("Attyka", X1 + 0.8, X1 + 1.5, YD + 1, YD + 2.5, Z0 - 1.5, Z1 + 1.5, C.Elewacja, Mat.Plaster, fKonstr)
	K.box("BelkaStropowa", X0 - 0.8, X1 + 0.8, Y1 - 1, Y1, Z0 - 0.8, Z0 - 0.5, Color3.fromRGB(200, 190, 160), Mat.Plaster, fKonstr)
	K.box("BelkaStropowa", X0 - 0.8, X1 + 0.8, Y1 - 1, Y1, Z1 + 0.5, Z1 + 0.8, Color3.fromRGB(200, 190, 160), Mat.Plaster, fKonstr)

	-- ---------- KORYTARZE ----------
	for _, y in ipairs({ YP, Y1 }) do
		podloga("Lastryko", X0, X1, KZ0, KZ1, y, C.Lastryko, Mat.Granite, fKonstr)
		for x = X0 + 8, X1 - 8, 16 do
			K.swietlowka(Vector3.new(x, y + 14.8, 0), ((x // 16) % 2 == 0), { zasieg = 24, jasnosc = 0.8, obrot = true }, fKonstr)
		end
	end
	-- ściany szczytowe korytarza
	local oknoSzczyt = { { a = -5, b = 5, lo = 3, hi = 13, typ = "okno" } }
	for _, y in ipairs({ YP, Y1 }) do
		K.wall("Z", X0, KZ0, KZ1, y, H, oknoSzczyt, S.Elewacja, S.Korytarz, fKonstr)
	end
	-- wschód: parter – wejście do sali gimnastycznej, piętro – okno
	K.wall("Z", X1, KZ0, KZ1, YP, H, { { a = -4, b = 4, lo = 0, hi = 9.5, typ = "drzwi", strona = 1, podwojne = true } }, S.Korytarz, S.Gym, fKonstr)
	K.wall("Z", X1, KZ0, KZ1, Y1, H, oknoSzczyt, S.Korytarz, S.Elewacja, fKonstr)

	-- ---------- ŚCIANY POMIESZCZEŃ ----------
	for _, p in ipairs(POM) do
		-- ściana od korytarza
		local zKor = (p.s == "N") and KZ1 or KZ0
		local ops = {}
		if p.otwarte then
			table.insert(ops, { a = p.otwarte[1], b = p.otwarte[2], lo = 0, hi = 11, typ = "przejscie" })
		elseif p.drzwi then
			local w = p.podwojne and 8 or 6
			table.insert(ops, { a = p.drzwi - w / 2, b = p.drzwi + w / 2, lo = 0, hi = 9, typ = "drzwi", strona = (p.s == "N") and 1 or -1, podwojne = p.podwojne })
		end
		if p.okienkoSklepu then
			table.insert(ops, { a = -74, b = -66, lo = 3.4, hi = 7.5, typ = "przejscie" })
		end
		local stylKor = (p.s == "N") and { S.Korytarz, p.styl } or { p.styl, S.Korytarz }
		K.wall("X", zKor, p.x0, p.x1, p.y, H, ops, stylKor[1], stylKor[2], fKonstr)

		-- ściana zewnętrzna z oknami (elewacja od zewnątrz)
		local zZew = (p.s == "N") and Z1 or Z0
		local okna = {}
		local szer = p.x1 - p.x0
		if p.id == "Hol" then
			okna = {
				{ a = -6, b = 6, lo = 0, hi = 10, typ = "drzwi", strona = 1, podwojne = true },
				{ a = -14, b = -9, lo = 3, hi = 13, typ = "okno" },
				{ a = 9, b = 14, lo = 3, hi = 13, typ = "okno" },
			}
		elseif p.id == "Klatka" or p.id == "Klatka2" then
			okna = { { a = -4, b = 4, lo = 4, hi = 14, typ = "okno" } }
		elseif szer <= 8 then
			okna = { { a = p.x0 + 2, b = p.x1 - 2, lo = 7, hi = 13, typ = "okno" } }
		elseif szer <= 16 then
			okna = { { a = p.x0 + 4, b = p.x1 - 4, lo = (p.id == "Toalety") and 7 or 3.5, hi = 13, typ = "okno" } }
		else
			local n = math.floor(szer / 11)
			local krok = szer / n
			for i = 0, n - 1 do
				local c = p.x0 + krok * (i + 0.5)
				table.insert(okna, { a = c - 3.2, b = c + 3.2, lo = 3.5, hi = 13, typ = "okno" })
			end
		end
		local stylZew = (p.s == "N") and { p.styl, S.Elewacja } or { S.Elewacja, p.styl }
		K.wall("X", zZew, p.x0 - ((p.x0 == X0) and 0.5 or 0), p.x1 + ((p.x1 == X1) and 0.5 or 0), p.y, H, okna, stylZew[1], stylZew[2], fKonstr)
		-- kaloryfery pod oknami
		if p.styl ~= S.Plytki and not p.otwarte then
			for _, o in ipairs(okna) do
				if o.typ == "okno" and o.lo < 5 then
					local nIn = (p.s == "N") and K.MINUS_Z or K.PLUS_Z
					kaloryfer(Vector3.new((o.a + o.b) / 2, p.y + 0.4, zZew + nIn.Z * 0.85), nIn, fWystroj)
				end
			end
		end

		-- ściany szczytowe budynku (x = ±112) dla skrajnych pomieszczeń
		if p.x0 == X0 then
			K.wall("Z", X0, p.z0, p.z1, p.y, H, { { a = (p.z0 + p.z1) / 2 - 3, b = (p.z0 + p.z1) / 2 + 3, lo = 4, hi = 13, typ = "okno" } }, S.Elewacja, p.styl, fKonstr)
		end
		if p.x1 == X1 then
			if p.y == YP then
				K.wall("Z", X1, p.z0, p.z1, p.y, H, {}, p.styl, S.Gym, fKonstr)
			else
				K.wall("Z", X1, p.z0, p.z1, p.y, H, { { a = (p.z0 + p.z1) / 2 - 3, b = (p.z0 + p.z1) / 2 + 3, lo = 4, hi = 13, typ = "okno" } }, p.styl, S.Elewacja, fKonstr)
			end
		end
	end

	-- ścianki działowe między sąsiadami
	for _, p in ipairs(POM) do
		for _, q in ipairs(POM) do
			if q.y == p.y and q.s == p.s and q.x0 == p.x1 then
				local ops = {}
				if p.id == "Chemia" and q.id == "ZapleczeChem" then
					ops = { { a = p.z0 + 16, b = p.z0 + 21, lo = 0, hi = 9, typ = "drzwi", strona = 1 } }
				end
				K.wall("Z", p.x1, p.z0, p.z1, p.y, H, ops, p.styl, q.styl, fKonstr)
			end
		end
	end

	-- ============================================================
	-- WYSTRÓJ POMIESZCZEŃ
	-- ============================================================
	local function w(id)
		return byId[id]
	end

	-- --- Sale lekcyjne ---
	local Tasks = nil
	pcall(function()
		Tasks = require(Shared:WaitForChild("GameConfig")).Tasks
	end)
	local function taskId(nazwa, zapas)
		return (Tasks and Tasks[nazwa] and Tasks[nazwa].Id) or zapas
	end

	local sale = {
		{ id = "Sala11", numer = 11, przedmiot = "Język polski", tekst = MemeText.TabliceSal.Polski, zadanie = { id = taskId("JezykPolski", "JezykPolski"), akcja = "Napisz dyktando", obiekt = "Tablica – Język polski" } },
		{ id = "Sala12", numer = 12, przedmiot = "Matematyka", tekst = MemeText.TabliceSal.Matematyka, zadanie = { id = taskId("Matematyka", "Matematyka"), akcja = "Rozwiąż kartkówkę", obiekt = "Tablica – Matematyka" } },
		{ id = "Sala13", numer = 13, przedmiot = "Geografia", tekst = MemeText.TabliceSal.Geografia },
		{ id = "Biologia", numer = 21, przedmiot = "Biologia", tekst = MemeText.TabliceSal.Biologia },
		{ id = "Historia", numer = 25, przedmiot = "Historia", tekst = MemeText.TabliceSal.Historia },
		{ id = "Fizyka", numer = 22, przedmiot = "Fizyka", tekst = MemeText.TabliceSal.Fizyka },
		{ id = "Angielski", numer = 23, przedmiot = "Język angielski", tekst = MemeText.TabliceSal.Angielski, plakat = "ENGLISH ONLY!\n(no cap)" },
		{ id = "Muzyka", numer = 20, przedmiot = "Muzyka", tekst = MemeText.TabliceSal.Muzyka },
	}
	for _, s in ipairs(sale) do
		local p = w(s.id)
		local f = K.folder(s.id, fWystroj)
		salaLekcyjna({ x0 = p.x0, x1 = p.x1, z0 = p.z0, z1 = p.z1, y = p.y, strona = p.s, numer = s.numer, przedmiot = s.przedmiot, tekst = s.tekst, zadanie = s.zadanie, plakat = s.plakat }, f)
		-- kwiatki na parapetach
		local zZew = (p.s == "N") and Z1 or Z0
		local nIn = (p.s == "N") and -1 or 1
		for i = 1, 2 do
			kwiatek(Vector3.new(p.x0 + 8 + i * 9, p.y + 3.5, zZew + nIn * 0.9), f)
		end
	end
	-- mapa Polski w geografii
	do
		local p = w("Sala13")
		K.plakat("MapaPolski", Vector3.new(p.x1 - 0.62, p.y + 7, (p.z0 + p.z1) / 2 + 6), K.MINUS_X, 8, 6, "🗺️ MAPA POLSKI\n\nGdańsk • Warszawa\nKraków • Wrocław\nRysy 2499 m", Color3.fromRGB(205, 225, 175), Color3.fromRGB(40, 70, 40), Enum.Font.FredokaOne, fWystroj)
	end
	-- pianino w muzycznej
	do
		local p = w("Muzyka")
		local f = fWystroj
		local cx = p.x1 - 6
		K.box("Pianino", cx - 2, cx + 1, p.y, p.y + 5, p.z0 + 3, p.z0 + 11, Color3.fromRGB(25, 20, 18), Mat.Wood, f)
		K.box("Klawiatura", cx - 3.2, cx - 2, p.y + 2.8, p.y + 3.1, p.z0 + 3.3, p.z0 + 10.7, Color3.fromRGB(245, 245, 240), Mat.SmoothPlastic, f)
	end

	-- --- Pracownia chemiczna + zaplecze (zakamarek) ---
	do
		local p = w("Chemia")
		local f = K.folder("Chemia", fWystroj)
		podloga("Linoleum", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(120, 140, 130), Mat.Plastic, f)
		tablicaZGodlem(Vector3.new(p.x0 + 0.85, p.y + 6.6, (p.z0 + p.z1) / 2), K.PLUS_X, MemeText.TabliceSal.Chemia, f)
		for row = 0, 2 do
			local x = p.x0 + 9 + row * 5
			K.box("StolLab", x - 1.4, x + 1.4, p.y, p.y + 3, p.z0 + 4, p.z1 - 4, Color3.fromRGB(230, 230, 225), Mat.SmoothPlastic, f)
			K.box("BlatLab", x - 1.5, x + 1.5, p.y + 3, p.y + 3.25, p.z0 + 3.9, p.z1 - 3.9, Color3.fromRGB(30, 30, 32), Mat.Slate, f)
			for i = 0, 3 do
				local z = p.z0 + 6 + i * 5
				K.cyl("Kolba", 1, 0.6, CFrame.new(x, p.y + 3.75, z), Color3.fromRGB(120, 220, 140), Mat.Glass, f).Transparency = 0.3
			end
		end
		K.box("Dygestorium", p.x1 - 3.5, p.x1 - 0.5, p.y, p.y + 8, p.z1 - 9, p.z1 - 3, Color3.fromRGB(220, 222, 215), Mat.SmoothPlastic, f)
		K.plakat("UkladOkresowy", Vector3.new(p.x0 + 12, p.y + 8, p.z0 + 0.62), K.PLUS_Z, 8, 4, "UKŁAD OKRESOWY\nH He Li Be B C N O F Ne\nNa Mg Al Si P S Cl Ar", Color3.fromRGB(240, 245, 255), Color3.fromRGB(20, 40, 90), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
		K.plakat("TabliczkaSali", Vector3.new(p.x0 + 7, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6.5, 1.4, "SALA 24\nCHEMIA", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)

		local zp = w("ZapleczeChem")
		podloga("Beton", zp.x0, zp.x1, zp.z0, zp.z1, zp.y, C.Beton, Mat.Concrete, f)
		K.box("RegalOdczynniki", zp.x1 - 2, zp.x1 - 0.5, zp.y, zp.y + 9, zp.z0 + 2, zp.z1 - 10, Color3.fromRGB(110, 80, 50), Mat.Wood, f)
		for i = 0, 5 do
			K.cyl("Sloik", 0.8, 0.5, CFrame.new(zp.x1 - 1.2, zp.y + 3 + (i % 3) * 2.5, zp.z0 + 4 + i * 1.6), Color3.fromRGB(150 + i * 15, 90, 200 - i * 20), Mat.Glass, f)
		end
		K.swietlowka(Vector3.new((zp.x0 + zp.x1) / 2, zp.y + 14.8, (zp.z0 + zp.z1) / 2), true, { zasieg = 12, jasnosc = 0.35, migocze = true, obrot = true }, f)
	end

	-- --- Informatyka (komputery CRT) ---
	do
		local p = w("Informatyka")
		local f = K.folder("Informatyka", fWystroj)
		podloga("Linoleum", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(110, 120, 140), Mat.Plastic, f)
		tablicaZGodlem(Vector3.new(p.x0 + 0.85, p.y + 6.6, (p.z0 + p.z1) / 2), K.PLUS_X, MemeText.TabliceSal.Informatyka, f)
		for row = 0, 1 do
			local x = p.x0 + 12 + row * 9
			K.box("StolKomputerowy", x - 1.6, x + 1.6, p.y + 2.6, p.y + 2.9, p.z0 + 3, p.z1 - 3, Color3.fromRGB(200, 195, 185), Mat.Wood, f)
			K.box("NogiStolu", x - 1.4, x + 1.4, p.y, p.y + 2.6, p.z0 + 3.5, p.z0 + 4, C.Metal, Mat.Metal, f)
			K.box("NogiStolu", x - 1.4, x + 1.4, p.y, p.y + 2.6, p.z1 - 4, p.z1 - 3.5, C.Metal, Mat.Metal, f)
			for i = 0, 3 do
				local z = p.z0 + 6 + i * 5
				if not K.prefab("KomputerCRT", K.patrz(Vector3.new(x, p.y + 2.9, z), K.PLUS_X), Vector3.new(2.6, 2.4, 2.6), f) then
					K.box("Monitor", x - 1, x + 1, p.y + 2.9, p.y + 4.9, z - 1, z + 1, Color3.fromRGB(215, 210, 190), Mat.SmoothPlastic, f)
				end
			end
		end
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
		K.plakat("TabliczkaSali", Vector3.new(p.x0 + 7, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6.5, 1.4, "SALA 26\nINFORMATYKA", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
	end

	-- --- Biblioteka ---
	do
		local p = w("Biblioteka")
		local f = K.folder("Biblioteka", fWystroj)
		podloga("Parkiet", p.x0, p.x1, p.z0, p.z1, p.y, C.Parkiet, Mat.WoodPlanks, f)
		for i = 0, 3 do
			local x = p.x0 + 12 + i * 5
			K.prefab("Regal", K.patrz(Vector3.new(x, p.y, p.z1 - 7), K.MINUS_X), Vector3.new(6, 9, 1.6), f)
			K.prefab("Regal", K.patrz(Vector3.new(x + 0.9, p.y, p.z1 - 7), K.PLUS_X), Vector3.new(6, 9, 1.6), f)
		end
		K.box("LadaBibliotekarki", p.x0 + 3, p.x0 + 9, p.y, p.y + 3.4, p.z0 + 3, p.z0 + 5, C.Drewno, Mat.Wood, f)
		K.prefab("KomputerCRT", K.patrz(Vector3.new(p.x0 + 6, p.y + 3.4, p.z0 + 4), K.PLUS_Z), Vector3.new(2.2, 2, 2.2), f)
		for i = 0, 1 do
			local x = p.x0 + 14 + i * 9
			K.box("StolikCzytelni", x - 2.5, x + 2.5, p.y + 2.5, p.y + 2.8, p.z0 + 4, p.z0 + 9, C.ParkietJasny, Mat.Wood, f)
			K.box("NogaStolika", x - 0.3, x + 0.3, p.y, p.y + 2.5, p.z0 + 6.2, p.z0 + 6.8, C.Metal, Mat.Metal, f)
		end
		K.plakat("Cisza", Vector3.new(p.x1 - 0.62, p.y + 9, (p.z0 + p.z1) / 2), K.MINUS_X, 6, 2.5, "🤫 CISZA!\nBIBLIOTEKA SZKOLNA", Color3.fromRGB(255, 255, 240), Color3.fromRGB(150, 30, 30), Enum.Font.FredokaOne, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
		K.plakat("Tabliczka", Vector3.new(p.x0 + 7, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6.5, 1.4, "BIBLIOTEKA", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
	end

	-- --- Kanciapa Woźnej (zakamarek) ---
	do
		local p = w("Kanciapa")
		local f = K.folder("Kanciapa", fWystroj)
		podloga("Beton", p.x0, p.x1, p.z0, p.z1, p.y, C.Beton, Mat.Concrete, f)
		K.prefab("Regal", K.patrz(Vector3.new(p.x0 + 1.2, p.y, p.z0 + 16), K.PLUS_X), Vector3.new(6, 8, 1.6), f)
		for i = 0, 2 do
			K.cyl("Wiadro", 1.4, 1.3, CFrame.new(p.x1 - 2, p.y + 0.7, p.z0 + 6 + i * 2), Color3.fromRGB(40, 90, 200), Mat.Plastic, f)
			K.part("KijMopa", Vector3.new(0.2, 6, 0.2), CFrame.new(p.x1 - 1.2, p.y + 3, p.z0 + 12 + i) * CFrame.Angles(0, 0, math.rad(8)), Color3.fromRGB(180, 140, 90), Mat.Wood, f)
		end
		K.plakat("TabliczkaWozna", Vector3.new(p.x0 + 3, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6, 1.4, "KANCIAPA\nWSTĘP WZBRONIONY", Color3.fromRGB(120, 30, 30), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		K.plakat("NieDeptac", Vector3.new(p.x1 - 0.62, p.y + 7, p.z0 + 20), K.MINUS_X, 5, 2.5, "NIE DEPTAĆ\nPO MOKRYM!!!", Color3.fromRGB(255, 230, 60), Color3.fromRGB(30, 30, 30), Enum.Font.GothamBlack, f)
		K.swietlowka(Vector3.new((p.x0 + p.x1) / 2, p.y + 14.8, (p.z0 + p.z1) / 2), true, { zasieg = 14, jasnosc = 0.45, migocze = true, obrot = true }, f)
	end

	-- --- Toalety (parter i piętro) – z graffiti i kabiną "AWARIA" ---
	for _, id in ipairs({ "Toalety", "Toalety2" }) do
		local p = w(id)
		local f = K.folder(id, fWystroj)
		podloga("Plytki", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(205, 210, 205), Mat.CeramicTiles, f)
		local n = math.floor((p.x1 - p.x0 - 2) / 8)
		for i = 0, n - 1 do
			local x = p.x0 + 4.5 + i * 8
			local m = K.prefab("KabinaWC", K.patrz(Vector3.new(x, p.y, p.z1 - 4.2), K.MINUS_Z), Vector3.new(7.5, 8.2, 7.5), f)
			if not m then
				K.box("Kabina", x - 3.5, x + 3.5, p.y, p.y + 8, p.z1 - 8, p.z1 - 1, Color3.fromRGB(200, 200, 205), Mat.SmoothPlastic, f, { Transparency = 0.1 })
			end
			if i == n - 1 then
				K.plakat("Awaria", Vector3.new(x, p.y + 6, p.z1 - 8.05), K.MINUS_Z, 3, 1.2, "AWARIA\nNIE UŻYWAĆ", Color3.fromRGB(255, 240, 0), Color3.fromRGB(200, 0, 0), Enum.Font.GothamBlack, f)
			end
		end
		-- umywalki i lustro
		for i = 0, 1 do
			local x = p.x0 + 4 + i * 5
			K.box("Umywalka", x - 1.3, x + 1.3, p.y + 3, p.y + 3.8, p.z0 + 0.5, p.z0 + 2.3, Color3.fromRGB(250, 250, 250), Mat.Marble, f)
			K.box("Lustro", x - 1.2, x + 1.2, p.y + 5, p.y + 8, p.z0 + 0.5, p.z0 + 0.6, Color3.fromRGB(200, 220, 230), Mat.Glass, f, { Reflectance = 0.4 })
		end
		-- graffiti
		for i = 1, 4 do
			local txt = MemeText.Graffiti[rng:NextInteger(1, #MemeText.Graffiti)]
			local zz = p.z0 + 4 + i * 4
			K.plakat("Graffiti", Vector3.new(p.x0 + 0.62, p.y + 3 + (i % 2) * 2.5, zz), K.PLUS_X, 3.2, 1.3, txt, Color3.new(1, 1, 1), Color3.fromRGB(rng:NextInteger(20, 200), 30, rng:NextInteger(60, 220)), Enum.Font.PermanentMarker, f, { przezroczyste = true })
		end
		K.plakat("TabliczkaWC", Vector3.new((p.x0 + p.x1) / 2, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 4, 1.4, "🚻 WC", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		K.swietlowka(Vector3.new((p.x0 + p.x1) / 2, p.y + 14.8, (p.z0 + p.z1) / 2), true, { zasieg = 18, jasnosc = 0.6, migocze = (id == "Toalety2"), obrot = true }, f)
	end

	-- --- Sklepik szkolny (okienko na korytarz) ---
	do
		local p = w("Sklepik")
		local f = K.folder("Sklepik", fWystroj)
		podloga("Linoleum", p.x0, p.x1, p.z0, p.z1, p.y, C.Linoleum, Mat.Plastic, f)
		K.box("LadaSklepiku", -75, -65, p.y, p.y + 3.4, KZ1 + 0.6, KZ1 + 2.6, Color3.fromRGB(190, 60, 40), Mat.Wood, f)
		K.plakat("SzyldSklepik", Vector3.new(-70, p.y + 9, KZ1 - 0.62), K.MINUS_Z, 10, 1.8, "🥐 SKLEPIK SZKOLNY", Color3.fromRGB(255, 220, 60), Color3.fromRGB(150, 30, 20), Enum.Font.FredokaOne, f)
		K.plakat("Cennik", Vector3.new(-57, p.y + 6.5, KZ1 - 0.62), K.MINUS_Z, 6, 4.5, "CENNIK\nDrożdżówka – 3 zł\nHot-dog – 5 zł\nKanapka od mamy – 0 zł\nGorący kubek – 4 zł\nLizak – 1 zł", Color3.fromRGB(255, 255, 245), Color3.fromRGB(30, 30, 30), Enum.Font.PatrickHand, f)
		for i = 0, 3 do
			K.box("PolkaSklepu", p.x0 + 2, p.x1 - 2, p.y + 3 + i * 2.2, p.y + 3.2 + i * 2.2, p.z1 - 2.5, p.z1 - 0.5, C.Drewno, Mat.Wood, f)
			for j = 0, 9 do
				local x = p.x0 + 4 + j * 2.6
				K.box("Towar", x - 0.5, x + 0.5, p.y + 3.2 + i * 2.2, p.y + 4.2 + i * 2.2, p.z1 - 2.1, p.z1 - 1.1, Color3.fromHSV(rng:NextNumber(), 0.6, 0.9), Mat.SmoothPlastic, f)
			end
		end
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Gabinet pielęgniarki ---
	do
		local p = w("Pielegniarka")
		local f = K.folder("Pielegniarka", fWystroj)
		podloga("Linoleum", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(190, 200, 205), Mat.Plastic, f)
		K.box("Lezanka", p.x0 + 2, p.x0 + 9, p.y + 2, p.y + 2.8, p.z1 - 5, p.z1 - 2, Color3.fromRGB(120, 170, 160), Mat.Leather, f)
		K.box("NogiLezanki", p.x0 + 2.3, p.x0 + 8.7, p.y, p.y + 2, p.z1 - 4.7, p.z1 - 2.3, C.Metal, Mat.Metal, f)
		K.box("Waga", p.x0 + 14, p.x0 + 16, p.y, p.y + 0.4, p.z1 - 4, p.z1 - 2, Color3.fromRGB(240, 240, 240), Mat.Metal, f)
		K.box("SlupekWagi", p.x0 + 14.8, p.x0 + 15.2, p.y, p.y + 6, p.z1 - 2.2, p.z1 - 1.8, C.Metal, Mat.Metal, f)
		K.plakat("TablicaSnellena", Vector3.new(p.x1 - 0.62, p.y + 7, (p.z0 + p.z1) / 2), K.MINUS_X, 3.2, 5, "E\nF P\nT O Z\nL P E D\nP E C F D", Color3.fromRGB(255, 255, 255), Color3.fromRGB(10, 10, 10), Enum.Font.GothamBold, f)
		K.plakat("MyjRece", Vector3.new(p.x0 + 20, p.y + 7, p.z1 - 0.62), K.MINUS_Z, 5, 3, "🧼 MYJ RĘCE!\n30 sekund", Color3.fromRGB(220, 245, 255), Color3.fromRGB(20, 80, 140), Enum.Font.FredokaOne, f)
		K.box("Apteczka", p.x0 + 24, p.x0 + 27, p.y + 6, p.y + 9, p.z1 - 1, p.z1 - 0.5, Color3.fromRGB(245, 245, 245), Mat.SmoothPlastic, f)
		K.plakat("Krzyz", Vector3.new(p.x0 + 25.5, p.y + 7.5, p.z1 - 1.08), K.MINUS_Z, 1.5, 1.5, "✚", Color3.fromRGB(245, 245, 245), Color3.fromRGB(220, 30, 30), Enum.Font.GothamBlack, f)
		K.plakat("Tabliczka", Vector3.new(-24, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6.5, 1.4, "GABINET\nPIELĘGNIARKI", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Stołówka + Wielki Dzwon + zadania obiadowe ---
	do
		local p = w("Stolowka")
		local f = K.folder("Stolowka", fWystroj)
		podloga("Plytki", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(205, 190, 165), Mat.CeramicTiles, f)
		for i = 0, 2 do
			for j = 0, 1 do
				local pos = Vector3.new(p.x0 + 18 + i * 14, p.y, p.z0 + 8 + j * 11)
				if not K.prefab("StolStolowka", K.patrz(pos, K.MINUS_Z), Vector3.new(12, 3.2, 5.5), f) then
					K.box("Stol", pos.X - 6, pos.X + 6, p.y + 2.6, p.y + 2.9, pos.Z - 2, pos.Z + 2, C.ParkietJasny, Mat.Wood, f)
				end
			end
		end
		-- okienko wydawania + lada (od strony stołówki, przy ścianie z kuchnią x = -48)
		local lada = K.box("LadaWydawania", p.x1 - 4, p.x1 - 0.5, p.y, p.y + 3.6, p.z0 + 6, p.z1 - 6, Color3.fromRGB(175, 175, 180), Mat.Metal, f)
		K.plakat("Menu", Vector3.new(p.x1 - 0.62, p.y + 10, (p.z0 + p.z1) / 2), K.MINUS_X, 9, 3.6, "DZIŚ W MENU\nPierogi ruskie • Kompot\nPizza Księciula (piątek)", Color3.fromRGB(30, 50, 40), C.Kreda, Enum.Font.PatrickHand, f)
		local talerz = K.cyl("TalerzPierogi", 0.25, 2.4, CFrame.new(p.x1 - 2.2, p.y + 3.75, -20), Color3.fromRGB(250, 250, 250), Mat.SmoothPlastic, f)
		for i = 0, 4 do
			K.part("Pierog", Vector3.new(0.7, 0.3, 0.45), CFrame.new(p.x1 - 2.2 + math.cos(i * 1.25) * 0.6, p.y + 4.0, -20 + math.sin(i * 1.25) * 0.6), Color3.fromRGB(240, 225, 180), Mat.SmoothPlastic, f)
		end
		promptZadania(talerz, taskId("StolowkaPierogi", "StolowkaPierogi"), "Zjedz szkolny obiad (pierogi!)", "Talerz pierogów", 0.4, 9)
		local pizza = K.part("PizzaKsiezulaPudelko", Vector3.new(2.8, 0.5, 2.8), CFrame.new(p.x1 - 2.2, p.y + 3.85, -26), Color3.fromRGB(220, 140, 60), Mat.Cardboard, f)
		K.napis(pizza, Enum.NormalId.Top, "🍕 PIZZA KSIĘCIULA", Color3.fromRGB(255, 235, 180), Color3.fromRGB(160, 40, 20), Enum.Font.FredokaOne)
		promptZadania(pizza, taskId("TestPizzyKsiezula", "TestPizzyKsiezula"), "Zrób test pizzy (MUALA!)", "Pizza Księciula", 0.4, 9)

		-- podest z Wielkim Dzwonem (zebrania)
		local cz = (p.z0 + p.z1) / 2
		K.box("PodestDzwonu", p.x0 + 1, p.x0 + 9, p.y, p.y + 1, cz - 5, cz + 5, Color3.fromRGB(120, 30, 30), Mat.Fabric, f)
		K.box("Belka", p.x0 + 4.6, p.x0 + 5.4, p.y + 1, p.y + 10, cz - 3.4, cz - 2.8, C.Drewno, Mat.Wood, f)
		K.box("Belka", p.x0 + 4.6, p.x0 + 5.4, p.y + 1, p.y + 10, cz + 2.8, cz + 3.4, C.Drewno, Mat.Wood, f)
		K.box("Belka", p.x0 + 4.6, p.x0 + 5.4, p.y + 9.4, p.y + 10, cz - 3.4, cz + 3.4, C.Drewno, Mat.Wood, f)
		local dzwon = K.part("WielkiDzwonSzkolny", Vector3.new(3.4, 3.6, 3.4), CFrame.new(p.x0 + 5, p.y + 7.4, cz), Color3.fromRGB(225, 180, 40), Mat.Metal, map, { Reflectance = 0.15 })
		dzwon.Shape = Enum.PartType.Ball
		K.cyl("RanteDzwonu", 0.5, 4.2, CFrame.new(p.x0 + 5, p.y + 5.8, cz), Color3.fromRGB(200, 155, 30), Mat.Metal, f)
		K.part("SerceDzwonu", Vector3.new(0.7, 0.7, 0.7), CFrame.new(p.x0 + 5, p.y + 5.3, cz), Color3.fromRGB(90, 70, 30), Mat.Metal, f, { Shape = Enum.PartType.Ball })
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "PromptDzwonu"
		pr.ActionText = "Uderz w Dzwon Szkolny!"
		pr.ObjectText = "Zebranie w stołówce"
		pr.HoldDuration = 1
		pr.MaxActivationDistance = 16
		pr.RequiresLineOfSight = false
		pr.Parent = dzwon
		tag(dzwon, "SzkolaDzwon")
		K.plakat("TabliczkaDzwonu", Vector3.new(p.x0 + 9.2, p.y + 2.5, cz), K.PLUS_X, 6, 1.4, "🔔 WIELKI DZWON\nzwołaj zebranie", Color3.fromRGB(120, 30, 30), Color3.fromRGB(255, 225, 90), Enum.Font.GothamBlack, f)
		for i = 0, 2 do
			K.swietlowka(Vector3.new(p.x0 + 12 + i * 20, p.y + 14.8, cz), true, { zasieg = 26, jasnosc = 0.9 }, f)
		end
		K.plakat("SzyldStolowka", Vector3.new(-80, p.y + 11.2, KZ0 + 0.62), K.PLUS_Z, 8, 1.4, "🍲 STOŁÓWKA", Color3.fromRGB(150, 40, 30), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
	end

	-- --- Kuchnia + zmywak (zakamarek) ---
	do
		local p = w("Kuchnia")
		local f = K.folder("Kuchnia", fWystroj)
		podloga("Plytki", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(180, 185, 185), Mat.CeramicTiles, f)
		K.box("BlatKuchenny", p.x0 + 0.5, p.x0 + 3.5, p.y, p.y + 3.6, p.z0 + 6, p.z1 - 6, Color3.fromRGB(175, 175, 180), Mat.Metal, f)
		K.box("Kuchenka", p.x0 + 10, p.x0 + 18, p.y, p.y + 3.4, p.z0 + 1, p.z0 + 5, Color3.fromRGB(70, 70, 75), Mat.Metal, f)
		for i = 0, 2 do
			K.cyl("Gar", 2, 2.4, CFrame.new(p.x0 + 11.5 + i * 2.6, p.y + 4.4, p.z0 + 3), Color3.fromRGB(200, 200, 205), Mat.Metal, f)
		end
		K.box("Zmywak", p.x1 - 12, p.x1 - 4, p.y, p.y + 3.4, p.z0 + 0.5, p.z0 + 3.5, Color3.fromRGB(200, 205, 210), Mat.Metal, f)
		K.plakat("Tabliczka", Vector3.new(-24, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "KUCHNIA\nTYLKO PERSONEL", Color3.fromRGB(120, 30, 30), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		K.swietlowka(Vector3.new(p.x0 + 16, p.y + 14.8, (p.z0 + p.z1) / 2), true, { zasieg = 18, jasnosc = 0.6 }, f)
	end

	-- --- Pokój nauczycielski ---
	do
		local p = w("PokojNauczycielski")
		local f = K.folder("PokojNauczycielski", fWystroj)
		podloga("Wykladzina", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(110, 60, 60), Mat.Carpet, f)
		local cz = (p.z0 + p.z1) / 2
		K.box("DlugiStol", p.x0 + 6, p.x1 - 6, p.y + 2.6, p.y + 2.9, cz - 2.5, cz + 2.5, C.Drewno, Mat.Wood, f)
		K.box("NogiStolu", p.x0 + 7, p.x1 - 7, p.y, p.y + 2.6, cz - 0.3, cz + 0.3, C.Drewno, Mat.Wood, f)
		for i = 0, 4 do
			for _, s in ipairs({ -1, 1 }) do
				local x = p.x0 + 8 + i * 4
				K.box("Krzeslo", x - 0.8, x + 0.8, p.y + 1.5, p.y + 1.7, cz + s * 4 - 0.8, cz + s * 4 + 0.8, Color3.fromRGB(70, 90, 140), Mat.Fabric, f)
			end
		end
		K.cyl("KubekKawy", 0.6, 0.5, CFrame.new(p.x0 + 12, p.y + 3.2, cz), Color3.fromRGB(240, 240, 240), Mat.SmoothPlastic, f)
		K.box("Ekspres", p.x1 - 3, p.x1 - 1, p.y + 3.6, p.y + 5.6, p.z0 + 2, p.z0 + 4, Color3.fromRGB(30, 30, 30), Mat.Metal, f)
		K.box("SzafkaPodEkspres", p.x1 - 3.5, p.x1 - 0.5, p.y, p.y + 3.6, p.z0 + 1, p.z0 + 6, C.Drewno, Mat.Wood, f)
		K.plakat("Tabliczka", Vector3.new(23, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "POKÓJ\nNAUCZYCIELSKI", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		K.plakat("NieWchodzic", Vector3.new(29, p.y + 6, p.z1 + 0.62), K.PLUS_Z, 3.5, 1.6, "UCZNIOM\nWSTĘP\nWZBRONIONY", Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 20, 20), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Szatnia WF (przebieralnia) ---
	do
		local p = w("SzatniaWF")
		local f = K.folder("SzatniaWF", fWystroj)
		podloga("Plytki", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(170, 175, 180), Mat.CeramicTiles, f)
		for _, z in ipairs({ p.z0 + 2, p.z0 + 26 }) do
			K.box("LawkaSzatni", p.x0 + 2, p.x1 - 2, p.y + 1.5, p.y + 1.8, z - 1, z + 1, C.ParkietJasny, Mat.Wood, f)
			for x = p.x0 + 3, p.x1 - 3, 2.5 do
				K.box("Wieszak", x - 0.1, x + 0.1, p.y + 6, p.y + 6.6, z - 0.1, z + 0.4, C.Metal, Mat.Metal, f)
				if rng:NextNumber() < 0.5 then
					K.box("Bluza", x - 0.7, x + 0.7, p.y + 3.5, p.y + 6, z, z + 0.4, Color3.fromHSV(rng:NextNumber(), 0.6, 0.7), Mat.Fabric, f)
				end
			end
		end
		K.plakat("Tabliczka", Vector3.new(87, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "SZATNIA WF", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Sekretariat ---
	do
		local p = w("Sekretariat")
		local f = K.folder("Sekretariat", fWystroj)
		podloga("Wykladzina", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(90, 100, 120), Mat.Carpet, f)
		K.box("BiurkoSekretarki", p.x0 + 8, p.x0 + 18, p.y, p.y + 3.2, p.z0 + 10, p.z0 + 14, C.Drewno, Mat.Wood, f)
		K.prefab("KomputerCRT", K.patrz(Vector3.new(p.x0 + 12, p.y + 3.2, p.z0 + 12.5), K.MINUS_Z), Vector3.new(2.6, 2.4, 2.6), f)
		for i = 0, 3 do
			K.box("SzafaNaAkta", p.x1 - 2.5, p.x1 - 0.5, p.y, p.y + 7, p.z0 + 3 + i * 5, p.z0 + 7.5 + i * 5, Color3.fromRGB(140, 140, 135), Mat.Metal, f)
		end
		K.plakat("Tabliczka", Vector3.new(87, p.y + 10.6, p.z0 - 0.62), K.MINUS_Z, 6.5, 1.4, "SEKRETARIAT\n9:00–11:00", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Gabinet Dyrektora (radiowęzeł) ---
	do
		local p = w("Dyrektor")
		local f = K.folder("Dyrektor", fWystroj)
		podloga("Parkiet", p.x0, p.x1, p.z0, p.z1, p.y, C.Parkiet, Mat.WoodPlanks, f)
		local cx, cz = (p.x0 + p.x1) / 2, (p.z0 + p.z1) / 2
		K.box("CzerwonyDywan", cx - 8, cx + 8, p.y, p.y + 0.08, cz - 6, cz + 6, Color3.fromRGB(160, 20, 30), Mat.Fabric, f)
		local deskPos = Vector3.new(cx, p.y, p.z0 + 7)
		local biurko = K.prefab("BiurkoNauczyciela", K.patrz(deskPos, K.PLUS_Z), Vector3.new(9, 3.3, 4), f)
		if not biurko then
			K.box("BiurkoDyrektora", cx - 4.5, cx + 4.5, p.y, p.y + 3.3, p.z0 + 5, p.z0 + 9, Color3.fromRGB(70, 35, 18), Mat.Wood, f)
		end
		local znacznik = K.part("BiurkoDyrektora", Vector3.new(1, 1, 1), CFrame.new(cx, p.y + 1.65, p.z0 + 7), Color3.new(), Mat.SmoothPlastic, map, { Transparency = 1, CanCollide = false, CanQuery = false })
		tag(znacznik, "SzkolaBiurkoDyrektora")
		K.box("FotelDyrektora", cx - 1.3, cx + 1.3, p.y, p.y + 5, p.z0 + 2, p.z0 + 4, Color3.fromRGB(40, 20, 15), Mat.Leather, f)
		-- godło + flaga
		local godlo = K.part("Godlo", Vector3.new(2.6, 3.2, 0.1), CFrame.lookAt(Vector3.new(cx, p.y + 10, p.z0 + 0.62), Vector3.new(cx, p.y + 10, p.z0 + 2)), Color3.fromRGB(200, 30, 40), Mat.SmoothPlastic, f, { CanCollide = false })
		local d = Instance.new("Decal")
		d.Texture = GODLO_TEKSTURA
		d.Parent = godlo
		K.cyl("DrzewceFlagi", 8, 0.25, CFrame.new(p.x0 + 3, p.y + 4, p.z0 + 2), C.Drewno, Mat.Wood, f)
		K.box("FlagaBiala", p.x0 + 3.1, p.x0 + 6.5, p.y + 6.2, p.y + 7.2, p.z0 + 1.95, p.z0 + 2.05, Color3.fromRGB(250, 250, 250), Mat.Fabric, f)
		K.box("FlagaCzerwona", p.x0 + 3.1, p.x0 + 6.5, p.y + 5.2, p.y + 6.2, p.z0 + 1.95, p.z0 + 2.05, Color3.fromRGB(215, 20, 40), Mat.Fabric, f)
		K.prefab("Regal", K.patrz(Vector3.new(p.x1 - 1.2, p.y, cz), K.MINUS_X), Vector3.new(6, 9, 1.6), f)
		K.plakat("Motto", Vector3.new(p.x0 + 0.62, p.y + 8, cz), K.PLUS_X, 7, 2.2, "„Wszystko widzę,\nwszystko wiem”", Color3.fromRGB(60, 30, 15), Color3.fromRGB(255, 215, 0), Enum.Font.Garamond, f)
		K.plakat("Tabliczka", Vector3.new(55, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "DYREKTOR\nSZKOŁY", Color3.fromRGB(120, 20, 20), Color3.fromRGB(255, 215, 0), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Archiwum (zakamarek) ---
	do
		local p = w("Archiwum")
		local f = K.folder("Archiwum", fWystroj)
		podloga("Beton", p.x0, p.x1, p.z0, p.z1, p.y, C.Beton, Mat.Concrete, f)
		for i = 0, 3 do
			local x = p.x0 + 5 + i * 6
			K.prefab("Regal", K.patrz(Vector3.new(x, p.y, p.z0 + 10), K.PLUS_Z), Vector3.new(5, 9, 1.6), f)
			for j = 0, 2 do
				K.box("Karton", x - 1.2, x + 1.2, p.y, p.y + 1.8, p.z0 + 16 + j * 2.4, p.z0 + 18 + j * 2.4, Color3.fromRGB(170, 130, 80), Mat.Cardboard, f)
			end
		end
		K.plakat("Tabliczka", Vector3.new(105, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "ARCHIWUM\nAKT", Color3.fromRGB(60, 60, 60), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		K.swietlowka(Vector3.new((p.x0 + p.x1) / 2, p.y + 14.8, (p.z0 + p.z1) / 2), true, { zasieg = 14, jasnosc = 0.35, migocze = true }, f)
	end

	-- --- Samorząd uczniowski (memy) ---
	do
		local p = w("Samorzad")
		local f = K.folder("Samorzad", fWystroj)
		podloga("Wykladzina", p.x0, p.x1, p.z0, p.z1, p.y, Color3.fromRGB(70, 110, 160), Mat.Carpet, f)
		local g = MemeText.Gazetki.Samorzad
		K.gazetka(Vector3.new((p.x0 + p.x1) / 2, p.y + 7, p.z0 + 0.75), K.PLUS_Z, 18, 7, g.tytul, g.kartki, f)
		K.box("Kanapa", p.x0 + 6, p.x0 + 18, p.y, p.y + 2, p.z1 - 5, p.z1 - 1.5, Color3.fromRGB(200, 70, 60), Mat.Fabric, f)
		K.box("OparcieKanapy", p.x0 + 6, p.x0 + 18, p.y + 2, p.y + 4.2, p.z1 - 2.2, p.z1 - 1.5, Color3.fromRGB(200, 70, 60), Mat.Fabric, f)
		K.plakat("Tabliczka", Vector3.new(23, p.y + 10.6, p.z1 + 0.62), K.PLUS_Z, 6.5, 1.4, "SAMORZĄD\nUCZNIOWSKI", Color3.fromRGB(30, 120, 60), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		lampyWSali(p.x0, p.x1, p.z0, p.z1, p.y, f)
	end

	-- --- Podłogi pozostałych (hole, klatki) ---
	podloga("Lastryko", -16, 16, Z0, KZ0, YP, C.Lastryko, Mat.Granite, fKonstr, { otworPiwnica })
	podloga("Lastryko", -16, 16, KZ1, Z1, YP, C.Lastryko, Mat.Granite, fKonstr)
	podloga("Lastryko", -16, 16, Z0, KZ0, Y1, C.Lastryko, Mat.Granite, fKonstr)
	podloga("Lastryko", 2, 16, KZ1, KZ1 + 2, Y1, C.Lastryko, Mat.Granite, fKonstr)

	return byId
end

-- ============================================================
-- KORYTARZE: SZAFKI (KRYJÓWKI), GAZETKI, GAŚNICE, DZWONKI, NUMEREK
-- ============================================================
local function budujKorytarze(map: Folder)
	local f = K.folder("Korytarz", map)
	local fSzafki = K.folder("Szafki", map)

	-- szafki na ścianie południowej parteru (front w stronę korytarza = +Z)
	local pozycjeSzafek = { 32.5, 44, 65, 77, 101 }
	for i, x in ipairs(pozycjeSzafek) do
		local base = Vector3.new(x, YP, KZ0 + 1.9)
		local m = K.prefab("Szafki", K.patrz(base, K.PLUS_Z), Vector3.new(11, 8.6, 2.6), fSzafki)
		if not m then
			for j = -2, 2 do
				local s = K.box("SzafkaMetalowa", x + j * 2.1 - 1, x + j * 2.1 + 1, YP, YP + 8.5, KZ0 + 0.6, KZ0 + 3.2, Color3.fromRGB(40, 100, 180), Mat.Metal, fSzafki)
			end
		end
		-- niewidzialna kryjówka (HidingService: wyjście = +Z lokalnie = korytarz)
		local kryj = K.part("SzafkaKryjowka", Vector3.new(10, 8, 1.5), CFrame.new(x, YP + 4.2, KZ0 + 2.3), Color3.new(), Enum.Material.SmoothPlastic, fSzafki, { Transparency = 1, CanCollide = false })
		tag(kryj, "SzkolaKryjowka")
		if i == 2 then
			local zad = K.part("SzafkaZadanie", Vector3.new(4, 4, 1), CFrame.new(x, YP + 4, KZ0 + 3.6), Color3.new(), Enum.Material.SmoothPlastic, fSzafki, { Transparency = 1, CanCollide = false })
			local Tasks = nil
			pcall(function()
				Tasks = require(ReplicatedStorage.Shared.GameConfig).Tasks
			end)
			promptZadania(zad, (Tasks and Tasks.SzafkiKsiazki and Tasks.SzafkiKsiazki.Id) or "SzafkiKsiazki", "Uporządkuj podręczniki w szafce", "Szafka szkolna", 0.5, 9)
		end
	end

	-- automat z przekąskami przy sklepiku
	if not K.prefab("Automat", K.patrz(Vector3.new(-50.5, YP, KZ1 - 2.2), K.MINUS_Z), Vector3.new(4, 7.6, 3.6), f) then
		K.box("Automat", -52.5, -48.5, YP, YP + 7.6, KZ1 - 4, KZ1 - 0.5, Color3.fromRGB(160, 20, 20), Mat.Metal, f)
	end

	-- gazetki ścienne
	local G = MemeText.Gazetki
	K.gazetka(Vector3.new(-36, YP + 7, KZ0 + 0.75), K.PLUS_Z, 12, 6, G.Ogloszenia.tytul, G.Ogloszenia.kartki, f)
	K.gazetka(Vector3.new(36, YP + 7, KZ1 - 0.75), K.MINUS_Z, 12, 6, G.Bhp.tytul, G.Bhp.kartki, f)
	K.gazetka(Vector3.new(94, Y1 + 7, KZ0 + 0.75), K.PLUS_Z, 12, 6, G.Sport.tytul, G.Sport.kartki, f)
	K.gazetka(Vector3.new(-30, Y1 + 7, KZ1 - 0.75), K.MINUS_Z, 12, 6, G.Ogloszenia.tytul, { "Wycieczka\ndo muzeum\n(zgody!)", "Kartkówka\nzapowiedziana =\nniezapowiedziana", "Zakaz\nszpontu na\nprzerwach" }, f)

	-- gaśnice, dzwonki, zakaz hulajnóg
	for _, y in ipairs({ YP, Y1 }) do
		gasnica(Vector3.new(-110, y, KZ1 - 0.9), K.MINUS_Z, f)
		gasnica(Vector3.new(109, y, KZ0 + 0.9), K.PLUS_Z, f)
		dzwonekNaScianie(Vector3.new(-30, y + 12.5, KZ1 - 0.55), K.MINUS_Z, f)
		dzwonekNaScianie(Vector3.new(60, y + 12.5, KZ0 + 0.55), K.PLUS_Z, f)
		zegar(Vector3.new(X0 + 0.6, y + 13.5, 6), K.PLUS_X, f)
		K.plakat("WyjscieEwak", Vector3.new(X0 + 0.62, y + 13.4, -6), K.PLUS_X, 3.4, 1.2, "🏃 WYJŚCIE EWAKUACYJNE", Color3.fromRGB(20, 150, 70), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
		-- ławki korytarzowe
		for _, x in ipairs({ -34, 36, 70 }) do
			K.box("LawkaKorytarz", x - 3, x + 3, y + 1.6, y + 1.9, KZ1 - 2, KZ1 - 0.6, C.ParkietJasny, Mat.Wood, f)
			K.box("NogaLawki", x - 2.6, x + 2.6, y, y + 1.6, KZ1 - 1.5, KZ1 - 1.1, C.Metal, Mat.Metal, f)
		end
	end
	K.plakat("ZakazHulajnog", Vector3.new(-56, YP + 7, KZ0 + 0.62), K.PLUS_Z, 5, 3.4, "🛴❌\nZAKAZ JAZDY\nNA HULAJNODZE\nPO KORYTARZU", Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 20, 20), Enum.Font.GothamBlack, f, { ramka = Color3.fromRGB(190, 20, 20) })

	-- hol: godło, szczęśliwy numerek, gablota z pucharami, plan lekcji
	local numer = MemeText.szczesliwyNumerek()
	local nr = K.plakat("SzczesliwyNumerek", Vector3.new(-15.4, YP + 7, -22), K.PLUS_X, 6, 4, numer == 67 and "SZCZĘŚLIWY\nNUMEREK\n67 🤲" or `SZCZĘŚLIWY\nNUMEREK\n{numer}`, Color3.fromRGB(30, 70, 50), C.Kreda, Enum.Font.PatrickHand, f)
	tag(nr, "SzkolaSzczesliwyNumerek")
	K.plakat("PlanLekcji", Vector3.new(15.4, YP + 7, -16), K.MINUS_X, 6, 5, "PLAN LEKCJI 7c\nPON: mat, pol, ang, WF\nWT: hist, bio, mat\nŚR: pol, chem, inf\nCZW: fiz, mat, muz\nPT: WF, pol, godz. wych.", Color3.fromRGB(255, 255, 245), Color3.fromRGB(30, 30, 30), Enum.Font.PatrickHand, f)
	K.box("GablotaPucharow", 13.5, 15.5, YP, YP + 7, -35.5, -31, Color3.fromRGB(120, 80, 45), Mat.Wood, f)
	for i = 0, 2 do
		K.cyl("Puchar", 1.2, 0.7, CFrame.new(12.9, YP + 2.6 + i * 1.8, -33.2 + (i - 1) * 1.2), Color3.fromRGB(230, 190, 50), Mat.Metal, f)
	end
	local godlo = K.part("GodloHol", Vector3.new(2.8, 3.4, 0.1), CFrame.lookAt(Vector3.new(0, YP + 12.5, Z0 + 0.62), Vector3.new(0, YP + 12.5, 0)), Color3.fromRGB(200, 30, 40), Mat.SmoothPlastic, f, { CanCollide = false })
	local d = Instance.new("Decal")
	d.Texture = GODLO_TEKSTURA
	d.Parent = godlo
	-- balustrady przy zejściu do piwnicy
	local bal = Color3.fromRGB(60, 60, 60)
	K.box("Balustrada", 5.8, 6.1, YP, YP + 3.4, -30, -14, bal, Mat.Metal, f, { Transparency = 0.1 })
	K.box("Balustrada", 6, 14, YP, YP + 3.4, -30.1, -29.8, bal, Mat.Metal, f)
	K.box("PoreczBalustrady", 5.7, 6.2, YP + 3.4, YP + 3.7, -30, -14, C.Drewno, Mat.Wood, f)
	K.box("Balustrada", 13.9, 14.2, YP, YP + 3.4, -30, -14, bal, Mat.Metal, f)
	K.plakat("DoSzatni", Vector3.new(15.4, YP + 6.5, -11), K.MINUS_X, 5, 1.4, "⬇ SZATNIA", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)

	-- hol piętra: balustrada nad klatką
	K.box("BalustradaKlatki", -16, 2, Y1, Y1 + 3.5, KZ1 + 0.2, KZ1 + 0.5, bal, Mat.Metal, f)
	K.box("PoreczKlatki", -16, 2, Y1 + 3.5, Y1 + 3.8, KZ1 + 0.1, KZ1 + 0.6, C.Drewno, Mat.Wood, f)
	K.gazetka(Vector3.new(0, Y1 + 7, Z0 + 0.75), K.PLUS_Z, 14, 6.5, "GAZETKA KLASY 7c", { "Szczęśliwy\nnumerek\nnie działa\nna sprawdzian", "Pani, a będzie\nto na\nsprawdzianie?", "GOAT\nmiesiąca:\nwoźna", "fr fr\nwracamy\nna lekcje" }, f)
end

-- ============================================================
-- KLATKA SCHODOWA, SCHOWEK POD SCHODAMI, ZEJŚCIE DO PIWNICY, SZATNIA
-- ============================================================
local function budujSchodyISzatnie(map: Folder)
	local f = K.folder("Schody", map)
	local stopien = Color3.fromRGB(165, 162, 152)
	-- bieg A: x[-14,-2], w górę +Z od z=10 (YP) do z=26 (YP+8)
	for k = 1, 8 do
		K.box("StopienA", -14, -2, YP, YP + k, 10 + (k - 1) * 2, 10 + k * 2, stopien, Mat.Granite, f)
	end
	-- spocznik
	K.box("Spocznik", -15.5, 15.5, YP + 7, YP + 8, 26, 35.5, stopien, Mat.Granite, f)
	-- bieg B: x[2,14], w górę -Z od z=26 (YP+8) do z=10 (Y1)
	for k = 1, 8 do
		K.box("StopienB", 2, 14, YP + 8 + k - 1.2, YP + 8 + k, 26 - k * 2, 26 - (k - 1) * 2, stopien, Mat.Granite, f)
	end
	-- dusza schodów (ściana między biegami) + poręcze
	K.box("DuszaSchodow", -2, 2, YP, Y1 + 3.5, 10, 26, C.LamperiaZielona, Mat.SmoothPlastic, f)
	K.box("Porecz", -2.3, 2.3, Y1 + 3.5, Y1 + 3.8, 9.8, 26, C.Drewno, Mat.Wood, f)
	-- ścianki klatki (x = ±16) na obu kondygnacjach już stoją jako działowe; schowek pod biegiem B
	K.wall("X", 10.5, 2, 16, YP, 8, { { a = 6, b = 9.5, lo = 0, hi = 6.5, typ = "drzwi", strona = 1 } }, S.Korytarz, S.Szatnia, f)
	K.plakat("Schowek", Vector3.new(12.6, YP + 4.5, 9.9), K.MINUS_Z, 2.6, 1, "SCHOWEK", Color3.fromRGB(80, 80, 80), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
	K.box("KartonySchowek", 3, 6, YP, YP + 3, 18, 22, Color3.fromRGB(160, 120, 70), Mat.Cardboard, f)
	K.box("KartonySchowek", 11, 14, YP, YP + 2, 20, 23, Color3.fromRGB(150, 115, 70), Mat.Cardboard, f)
	K.swietlowka(Vector3.new(9, YP + 7.4, 16), true, { zasieg = 10, jasnosc = 0.3, migocze = true }, f)
	K.swietlowka(Vector3.new(0, YP + 14.8, 31), true, { zasieg = 22, jasnosc = 0.7 }, f)
	K.swietlowka(Vector3.new(0, Y1 + 14.8, 22), true, { zasieg = 26, jasnosc = 0.8 }, f)

	-- zejście do piwnicy (otwór x[6,14], z[-30,-14]): z z=-14 (YP) w dół do z=-29.5
	for k = 1, 9 do
		K.box("StopienPiwnica", 6, 14, YB, YP - k, -14 - k * 1.55, -14 - (k - 1) * 1.55, stopien, Mat.Concrete, f)
	end

	-- SZATNIA W PIWNICY (x[-48,48], z[-36,36]) – boksy z siatki dla klas
	local fs = K.folder("Szatnia", map)
	K.strop("PosadzkaSzatni", -48, 48, Z0, Z1, YB + 0.2, 0.2, Color3.fromRGB(130, 130, 128), Mat.Concrete, nil, fs)
	local klasy = { "1a", "2b", "3a", "4c", "5b", "6a", "7c", "8a" }
	local idx = 0
	local siatka = Color3.fromRGB(150, 155, 160)
	for _, zrow in ipairs({ { 14, 34 }, { -34, -14 } }) do
		for bx = -44, 28, 12 do
			idx += 1
			local x0, x1 = bx, bx + 11
			local z0, z1 = zrow[1], zrow[2]
			if z0 < 0 and x0 < 15 and x1 > 5 then
				continue -- tu schodzą schody z holu
			end
			local front = (z0 > 0) and z0 or z1
			-- ścianki z siatki (przezroczyste)
			K.box("Siatka", x0, x0 + 0.15, YB + 0.2, YB + 8, z0, z1, siatka, Mat.DiamondPlate, fs, { Transparency = 0.72 })
			K.box("Siatka", x0, x1, YB + 0.2, YB + 8, front - 0.07, front + 0.07, siatka, Mat.DiamondPlate, fs, { Transparency = 0.72 })
			K.box("Furtka", x0 + 4, x0 + 7.5, YB + 0.2, YB + 7.5, front - 0.12, front + 0.12, siatka, Mat.DiamondPlate, fs, { Transparency = 0.6 })
			-- wieszaki z kurtkami i workami na kapcie
			local back = (z0 > 0) and z1 - 1 or z0 + 1
			K.box("DrazekWieszaka", x0 + 0.5, x1 - 0.5, YB + 6.4, YB + 6.6, back - 0.1, back + 0.1, C.Metal, Mat.Metal, fs)
			for i = 0, 3 do
				local xx = x0 + 1.5 + i * 2.6
				K.box("Kurtka", xx - 0.8, xx + 0.8, YB + 3.6, YB + 6.4, back - 0.35, back + 0.35, Color3.fromHSV((idx * 0.13 + i * 0.27) % 1, 0.55, 0.65), Mat.Fabric, fs)
				K.box("WorekNaKapcie", xx + 0.7, xx + 1.3, YB + 2.2, YB + 3.6, back - 0.25, back + 0.25, Color3.fromHSV((idx * 0.31 + i * 0.17) % 1, 0.7, 0.85), Mat.Fabric, fs)
			end
			K.plakat("NumerKlasy", Vector3.new(x0 + 5.5, YB + 8.6, front), (z0 > 0) and K.MINUS_Z or K.PLUS_Z, 2.6, 1, `KLASA {klasy[(idx - 1) % #klasy + 1]}`, Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 20), Enum.Font.GothamBold, fs)
		end
	end
	-- ławki w alejce
	for x = -40, 40, 16 do
		K.box("LawkaSzatnia", x - 3, x + 3, YB + 1.5, YB + 1.8, -1, 1, C.ParkietJasny, Mat.Wood, fs)
	end
	for x = -40, 40, 20 do
		K.swietlowka(Vector3.new(x, YB + 8.7, 0), (x % 40 == 0), { zasieg = 22, jasnosc = 0.55 }, fs)
	end
	-- ZAKAMAREK: ciemny kąt za boksami
	K.swietlowka(Vector3.new(42, YB + 8.7, 30), true, { zasieg = 10, jasnosc = 0.25, migocze = true }, fs)
	K.plakat("TabliczkaSzatnia", Vector3.new(-47.4, YB + 6, 0), K.PLUS_X, 6, 1.6, "SZATNIA\nZmień obuwie!", Color3.fromRGB(20, 60, 120), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, fs)
end

-- ============================================================
-- SALA GIMNASTYCZNA + MAGAZYNEK WF
-- ============================================================
local function budujSaleGimnastyczna(map: Folder)
	local f = K.folder("SalaGimnastyczna", map)
	local sx0, sx1, sz0, sz1 = L.Sala.X0, L.Sala.X1, L.Sala.Z0, L.Sala.Z1
	local hG = 22
	K.box("FundamentSali", sx0, sx1, YB, YP - 0.2, sz0, sz1, C.Beton, Mat.Concrete, f)
	podloga("ParkietSali", sx0, sx1, sz0, sz1, YP, C.ParkietJasny, Mat.WoodPlanks, f)
	-- cokół
	for _, z in ipairs({ sz0, sz1 }) do
		K.box("Cokol", sx0, sx1 + 0.5, YB, YP, z - 0.5, z + 0.5, C.Cegla, Mat.Brick, f)
	end
	K.box("Cokol", sx1 - 0.5, sx1 + 0.5, YB, YP, sz0, sz1, C.Cegla, Mat.Brick, f)
	-- ściany z wysokimi oknami
	local okna = {}
	for x = sx0 + 8, sx1 - 8, 12 do
		table.insert(okna, { a = x - 4, b = x + 4, lo = 11, hi = 19, typ = "okno" })
	end
	K.wall("X", sz0, sx0, sx1 + 0.5, YP, hG, okna, S.Elewacja, S.Gym, f)
	K.wall("X", sz1, sx0, sx1 + 0.5, YP, hG, okna, S.Gym, S.Elewacja, f)
	K.wall("Z", sx1, sz0, sz1, YP, hG, {}, S.Gym, S.Elewacja, f)
	-- domknięcie ściany zachodniej ponad budynkiem i na końcach
	K.wall("Z", sx0, sz0, Z0, YP, hG, {}, S.Elewacja, S.Gym, f)
	K.wall("Z", sx0, Z1, sz1, YP, hG, {}, S.Elewacja, S.Gym, f)
	K.box("DachSali", sx0, sx1 + 1, YP + hG, YP + hG + 1, sz0 - 1, sz1 + 1, Color3.fromRGB(90, 90, 92), Mat.Concrete, f)
	K.box("SufitSali", sx0, sx1, YP + hG - 0.4, YP + hG, sz0, sz1, C.Sufit, Mat.SmoothPlastic, f)

	-- linie boiska
	local lin = Color3.fromRGB(245, 245, 245)
	local function linia(x0, x1, z0, z1)
		K.box("Linia", x0, x1, YP, YP + 0.03, z0, z1, lin, Mat.SmoothPlastic, f, { CanCollide = false })
	end
	linia(sx0 + 6, sx1 - 6, sz0 + 6, sz0 + 6.3)
	linia(sx0 + 6, sx1 - 6, sz1 - 6.3, sz1 - 6)
	linia(sx0 + 6, sx0 + 6.3, sz0 + 6, sz1 - 6)
	linia(sx1 - 6.3, sx1 - 6, sz0 + 6, sz1 - 6)
	linia((sx0 + sx1) / 2 - 0.15, (sx0 + sx1) / 2 + 0.15, sz0 + 6, sz1 - 6)
	-- kosze z Toolboxa
	for _, cfg in ipairs({ { x = sx0 + 3, n = K.PLUS_X }, { x = sx1 - 3, n = K.MINUS_X } }) do
		if not K.prefab("KoszDoKosza", K.patrz(Vector3.new(cfg.x, YP, 0), cfg.n), Vector3.new(6, 13, 8), f) then
			K.box("Tablica", cfg.x - 0.2, cfg.x + 0.2, YP + 10, YP + 14, -3, 3, Color3.fromRGB(240, 240, 240), Mat.SmoothPlastic, f)
		end
	end
	-- drabinki na ścianie wschodniej
	for i = 0, 5 do
		local zc = sz0 + 10 + i * 5
		K.box("DrabinkaBok", sx1 - 1.2, sx1 - 0.6, YP, YP + 14, zc - 1.8, zc - 1.6, C.ParkietJasny, Mat.Wood, f)
		K.box("DrabinkaBok", sx1 - 1.2, sx1 - 0.6, YP, YP + 14, zc + 1.6, zc + 1.8, C.ParkietJasny, Mat.Wood, f)
		for k = 1, 12 do
			K.box("Szczebel", sx1 - 1.1, sx1 - 0.7, YP + k * 1.1, YP + k * 1.1 + 0.2, zc - 1.6, zc + 1.6, C.ParkietJasny, Mat.Wood, f)
		end
	end
	-- kozioł i skrzynia gimnastyczna
	K.box("Skrzynia", sx0 + 20, sx0 + 26, YP, YP + 3.6, sz0 + 10, sz0 + 13, C.ParkietJasny, Mat.Wood, f)
	K.box("SkrzyniaGora", sx0 + 20, sx0 + 26, YP + 3.6, YP + 4.1, sz0 + 10, sz0 + 13, Color3.fromRGB(160, 40, 30), Mat.Leather, f)
	K.box("Koziol", sx0 + 30, sx0 + 33, YP + 3, YP + 4, sz0 + 10.5, sz0 + 12.5, Color3.fromRGB(110, 60, 30), Mat.Leather, f)
	K.box("NogaKozla", sx0 + 31.3, sx0 + 31.7, YP, YP + 3, sz0 + 11.3, sz0 + 11.7, C.Metal, Mat.Metal, f)
	-- proporczyki pod sufitem
	for i = 0, 20 do
		local x = sx0 + 4 + i * 2.8
		local kol = ({ Color3.fromRGB(230, 30, 40), Color3.fromRGB(250, 250, 250), Color3.fromRGB(30, 80, 200) })[i % 3 + 1]
		local w = Instance.new("WedgePart")
		w.Name = "Proporczyk"
		w.Size = Vector3.new(0.1, 1.6, 1.4)
		w.CFrame = CFrame.new(x, YP + 18, sz1 - 3) * CFrame.Angles(math.rad(180), 0, 0)
		w.Color = kol
		w.Material = Mat.Fabric
		w.Anchored = true
		w.CanCollide = false
		w.Parent = f
	end
	-- świetlówki z kratkami ochronnymi
	for x = sx0 + 10, sx1 - 10, 14 do
		for _, z in ipairs({ -20, 0, 20 }) do
			K.swietlowka(Vector3.new(x, YP + hG - 0.8, z), (z == 0) or (x % 28 == 0), { zasieg = 30, jasnosc = 0.9 }, f)
		end
	end
	K.plakat("SzyldSali", Vector3.new(sx0 + 0.62, YP + 11, 0), K.PLUS_X, 10, 1.6, "SALA GIMNASTYCZNA", Color3.fromRGB(30, 80, 160), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack, f)
	K.plakat("StrojWF", Vector3.new(sx0 + 0.62, YP + 6.5, 14), K.PLUS_X, 5, 3, "BRAK STROJU =\nNIEĆWICZENIE\n(i tak ćwiczysz)", Color3.fromRGB(255, 255, 240), Color3.fromRGB(150, 30, 30), Enum.Font.PatrickHand, f)

	-- MAGAZYNEK WF (zakamarek za materacami): x[160,176], z[24,40]
	K.wall("Z", 160, 24, sz1, YP, 10, { { a = 29, b = 34, lo = 0, hi = 8, typ = "drzwi", strona = -1 } }, S.Gym, S.Szatnia, f)
	K.wall("X", 24, 160, sx1, YP, 10, {}, S.Gym, S.Szatnia, f)
	K.box("SufitMagazynku", 160, sx1, YP + 10, YP + 10.4, 24, sz1, C.Sufit, Mat.SmoothPlastic, f)
	for i = 0, 4 do
		K.box("Materac", 166, 175, YP + i * 0.9, YP + (i + 1) * 0.9, 35, 39.5, Color3.fromRGB(40, 80, 170), Mat.Fabric, f)
	end
	for i = 0, 5 do
		local b = K.part("Pilka", Vector3.new(1.5, 1.5, 1.5), CFrame.new(162 + (i % 3) * 1.7, YP + 0.75 + (i // 3) * 1.4, 26.5), Color3.fromHSV(i * 0.15, 0.8, 0.9), Mat.Plastic, f, { Shape = Enum.PartType.Ball })
	end
	K.plakat("TabliczkaMagazynek", Vector3.new(159.4, YP + 8.6, 31.5), K.MINUS_X, 4.6, 1, "MAGAZYNEK WF", Color3.fromRGB(60, 60, 60), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)
	K.swietlowka(Vector3.new(168, YP + 9.6, 32), true, { zasieg = 10, jasnosc = 0.3, migocze = true, obrot = true }, f)
end

-- ============================================================
-- OTOCZENIE: PLAC APELOWY, SCHODY WEJŚCIOWE, MASZT, PARKING HULAJNÓG, BOISKO
-- ============================================================
local function budujOtoczenie(map: Folder)
	local f = K.folder("Otoczenie", map)
	K.box("Trawnik", -220, 280, YB - 0.1, YB + 0.05, -200, 140, Color3.fromRGB(86, 140, 70), Mat.Grass, f)
	K.box("PlacApelowy", -70, 70, YB, YB + 0.15, -122, -52, Color3.fromRGB(150, 148, 142), Mat.Pavement, f)
	K.box("Chodnik", -9, 9, YB, YB + 0.15, -52, -36, Color3.fromRGB(150, 148, 142), Mat.Pavement, f)

	-- wysoki parter: podest + schody wejściowe
	local schodyKol = Color3.fromRGB(175, 172, 165)
	K.box("PodestWejscia", -9, 9, YB, YP, -40, Z0 - 0.5, schodyKol, Mat.Granite, f)
	for k = 1, 9 do
		K.box("StopienWejscia", -9, 9, YB, YP - k, -40 - k * 1.5, -40 - (k - 1) * 1.5, schodyKol, Mat.Granite, f)
	end
	K.box("Policzek", -9.8, -9, YB, YP + 3, -53.5, Z0 - 0.5, C.Elewacja, Mat.Plaster, f)
	K.box("Policzek", 9, 9.8, YB, YP + 3, -53.5, Z0 - 0.5, C.Elewacja, Mat.Plaster, f)
	-- daszek nad wejściem
	K.box("Daszek", -10, 10, YP + 11, YP + 11.8, -43, Z0 - 0.5, Color3.fromRGB(120, 120, 125), Mat.Concrete, f)
	for _, x in ipairs({ -8.5, 8.5 }) do
		K.box("Slup", x - 0.5, x + 0.5, YP, YP + 11, -42.5, -41.5, C.Bialy, Mat.Concrete, f)
	end
	-- napis na elewacji
	K.plakat("NazwaSzkoly", Vector3.new(0, YP + 14.2, Z0 - 0.8), K.MINUS_Z, 26, 2.2, "SZKOŁA PODSTAWOWA NR 67", Color3.fromRGB(228, 214, 178), Color3.fromRGB(25, 45, 100), Enum.Font.GothamBlack, f, { przezroczyste = true })
	K.plakat("Tablica1000", Vector3.new(-14, YP + 5, Z0 - 0.8), K.MINUS_Z, 4, 2.6, "SZKOŁA-POMNIK\nTYSIĄCLECIA\nPAŃSTWA\nPOLSKIEGO", Color3.fromRGB(70, 70, 70), Color3.fromRGB(230, 200, 120), Enum.Font.Garamond, f)

	-- maszt z flagą
	K.cyl("Maszt", 30, 0.6, CFrame.new(0, 15, -104), Color3.fromRGB(235, 235, 235), Mat.Metal, f)
	K.box("FlagaBiala", 0.3, 7, 26, 28, -104.05, -103.95, Color3.fromRGB(250, 250, 250), Mat.Fabric, f)
	K.box("FlagaCzerwona", 0.3, 7, 24, 26, -104.05, -103.95, Color3.fromRGB(215, 20, 40), Mat.Fabric, f)
	K.box("PodstawaMasztu", -2, 2, 0, 0.8, -106, -102, Color3.fromRGB(140, 140, 140), Mat.Concrete, f)
	-- ławki na placu
	for _, x in ipairs({ -50, -30, 30, 50 }) do
		K.box("LawkaPlac", x - 3, x + 3, 1.6, 1.9, -61, -59.5, C.Drewno, Mat.Wood, f)
		K.box("NogaLawki", x - 2.5, x + 2.5, 0, 1.6, -60.5, -60, Color3.fromRGB(60, 60, 60), Mat.Metal, f)
	end

	-- parking hulajnóg
	K.box("StojakHulajnog", 18, 30, 0, 2.2, -56.2, -55.8, Color3.fromRGB(110, 110, 115), Mat.Metal, f)
	for i = 0, 3 do
		local x = 19.5 + i * 3
		K.box("Hulajnoga", x - 0.3, x + 0.3, 0.4, 0.7, -59, -55.5, Color3.fromRGB(30, 30, 35), Mat.Metal, f)
		K.box("KierownicaHulajnogi", x - 0.15, x + 0.15, 0.7, 4, -55.7, -55.4, Color3.fromRGB(30, 30, 35), Mat.Metal, f)
		K.box("Uchwyt", x - 1, x + 1, 3.9, 4.1, -55.7, -55.4, Color3.fromRGB(40, 40, 40), Mat.Rubber, f)
	end
	K.plakat("ParkingHulajnog", Vector3.new(24, 4.5, -55.4), K.MINUS_Z, 7, 1.6, "🛴 PARKING HULAJNÓG", Color3.fromRGB(30, 110, 200), Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, f)

	-- boisko asfaltowe z bramkami
	K.box("Boisko", 90, 170, YB, YB + 0.15, -125, -60, Color3.fromRGB(80, 82, 86), Mat.Asphalt, f)
	for _, x in ipairs({ 93, 167 }) do
		K.box("SlupekBramki", x - 0.3, x + 0.3, 0, 7, -96.5, -96, Color3.new(1, 1, 1), Mat.Metal, f)
		K.box("SlupekBramki", x - 0.3, x + 0.3, 0, 7, -89, -88.5, Color3.new(1, 1, 1), Mat.Metal, f)
		K.box("Poprzeczka", x - 0.3, x + 0.3, 7, 7.5, -96.5, -88.5, Color3.new(1, 1, 1), Mat.Metal, f)
	end
	K.box("LiniaSrodkowa", 129.8, 130.2, 0.15, 0.18, -125, -60, Color3.new(1, 1, 1), Mat.SmoothPlastic, f)

	-- latarnie
	for _, x in ipairs({ -60, 60 }) do
		K.cyl("Latarnia", 14, 0.5, CFrame.new(x, 7, -70), Color3.fromRGB(50, 50, 55), Mat.Metal, f)
		local l = K.part("KloszLatarni", Vector3.new(1.4, 0.6, 1.4), CFrame.new(x, 14.2, -70), Color3.fromRGB(255, 240, 200), Mat.Neon, f)
		local pl = Instance.new("PointLight")
		pl.Range = 30
		pl.Brightness = 0.6
		pl.Parent = l
	end
end

-- ============================================================
-- API
-- ============================================================

-- Buduje całą szkołę do workspace.SchoolMap (zastępuje poprzednią zawartość).
function NowaSzkola.zbuduj(): Folder
	local stara = workspace:FindFirstChild("SchoolMap")
	if stara then
		stara:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "SchoolMap"
	map:SetAttribute("NowaSzkola", WERSJA)
	map:SetAttribute("Autor", "Agent Claude (NowaSzkola)")
	K.init(map)

	budujPomieszczenia(map)
	budujKorytarze(map)
	budujSchodyISzatnie(map)
	budujSaleGimnastyczna(map)
	budujOtoczenie(map)

	map.Parent = workspace
	local st = K.stats()
	local brak = {}
	for n in pairs(st.missingPrefabs) do
		table.insert(brak, n)
	end
	print(`🏫 [NowaSzkola] Zbudowano szkołę: {st.parts} części, {st.lights} świateł, {st.prefabs} prefabów z Toolboxa.` .. (#brak > 0 and (" Brak prefabów: " .. table.concat(brak, ", ")) or ""))
	return map
end

-- Migające świetlówki (statyczna mapa nie ma skryptów – uruchamiamy w trakcie gry)
local function uruchomMiganie(map: Instance)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("PointLight") and d.Parent and d.Parent:GetAttribute("Migocze") then
			local tuba = d.Parent :: BasePart
			task.spawn(function()
				while tuba.Parent do
					task.wait(math.random(20, 60) / 10)
					d.Enabled = false
					tuba.Color = Color3.fromRGB(90, 92, 96)
					task.wait(0.08)
					d.Enabled = true
					tuba.Color = Color3.fromRGB(250, 252, 255)
					task.wait(0.06)
					d.Enabled = false
					task.wait(0.05)
					d.Enabled = true
				end
			end)
		end
	end
end

-- Wywoływane przez SchoolMapGenerator.setupMap w trakcie gry.
function NowaSzkola.setupMap(onBellRing: (Player) -> ()): (Vector3, Vector3, Vector3)
	local map = workspace:FindFirstChild("SchoolMap")
	if not (map and map:GetAttribute("NowaSzkola")) then
		warn("[NowaSzkola] Brak statycznej szkoły w Workspace – buduję awaryjnie w trakcie gry.")
		map = NowaSzkola.zbuduj()
	end

	local HidingService = require(script.Parent:WaitForChild("HidingService"))
	local RadioService = require(script.Parent:WaitForChild("RadioService"))

	-- zadania
	for _, pr in ipairs(CollectionService:GetTagged("SzkolaZadanie")) do
		if pr:IsA("ProximityPrompt") and pr:IsDescendantOf(map) and not pr:GetAttribute("Podpiete") then
			pr:SetAttribute("Podpiete", true)
			local zadanieId = pr:GetAttribute("Zadanie")
			pr.Triggered:Connect(function(player)
				if player:GetAttribute("IsAlive") ~= true then
					return
				end
				local ok, Remotes = pcall(function()
					return require(Shared:WaitForChild("Remotes"))
				end)
				local GameConfig = require(Shared:WaitForChild("GameConfig"))
				local remote = ok and Remotes.get(GameConfig.RemoteEvents.OpenTaskGui)
				if remote then
					remote:FireClient(player, zadanieId)
				end
			end)
		end
	end

	-- dzwon (zebranie)
	for _, dz in ipairs(CollectionService:GetTagged("SzkolaDzwon")) do
		if dz:IsDescendantOf(map) and not dz:GetAttribute("Podpiete") then
			dz:SetAttribute("Podpiete", true)
			local pr = dz:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.Triggered:Connect(function(player)
					if onBellRing then
						onBellRing(player)
					end
				end)
			end
		end
	end

	-- szafki-kryjówki
	for _, s in ipairs(CollectionService:GetTagged("SzkolaKryjowka")) do
		if s:IsA("BasePart") and s:IsDescendantOf(map) and not s:GetAttribute("Podpiete") then
			s:SetAttribute("Podpiete", true)
			HidingService.registerLocker(s)
		end
	end

	-- radiowęzeł w gabinecie dyrektora
	for _, b in ipairs(CollectionService:GetTagged("SzkolaBiurkoDyrektora")) do
		if b:IsA("BasePart") and b:IsDescendantOf(map) and not b:GetAttribute("Podpiete") then
			b:SetAttribute("Podpiete", true)
			RadioService.setupMicrophone(b.Position)
		end
	end

	-- szczęśliwy numerek losowany na każdy serwer
	for _, n in ipairs(CollectionService:GetTagged("SzkolaSzczesliwyNumerek")) do
		local lbl = n:FindFirstChildWhichIsA("TextLabel", true)
		if lbl then
			local num = MemeText.szczesliwyNumerek()
			lbl.Text = num == 67 and "SZCZĘŚLIWY\nNUMEREK\n67 🤲" or `SZCZĘŚLIWY\nNUMEREK\n{num}`
		end
	end

	uruchomMiganie(map)
	print("🏫 [NowaSzkola] Podpięto rozgrywkę do statycznej szkoły.")
	return L.Spawny.Szkola, L.Spawny.Stolowka, L.Spawny.Lobby
end

return NowaSzkola
