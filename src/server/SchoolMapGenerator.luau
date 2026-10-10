--!strict
-- src/server/SchoolMapGenerator.luau
-- WIELKA POLSKA SZKOŁA Z LICZNYMI ZAKAMARKAMI (SOCIAL DEDUCTION MAP)
-- Specjalnie zaprojektowana pod rozgrywkę Murder Mystery / Among Us:
-- • Olbrzymi gmach (220 x 320 studów) z pełnymi korytarzami, drzwiami i 2 piętrami
-- • Brak jakichkolwiek konkretnych nazwisk/numerów (uniwersalna, klimatyczna "SZKOŁA")
-- • 8 UNIKALNYCH ZAKAMARKÓW (Hiding spots / Blind spots dla Rozrabiaki):
--   1. Magazynek sprzętu WF za salą gimnastyczną (materace, półmrok)
--   2. Schowek pod schodami (stare kartony, miotły)
--   3. Zaplecze chemiczne z tylnym wyjściem za salą 204
--   4. Ciemny zaułek za boksami siatkowymi szatni
--   5. Kabina toaletowa z tabliczką "AWARIA"
--   6. Ślepy zaułek korytarza I piętra przy drzwiach ewakuacyjnych
--   7. Archiwum akt szkolnych za gabinetem dyrektora
--   8. Zmywak kuchenny i zaplecze gospodarcze za stołówką

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HidingService = require(script.Parent:WaitForChild("HidingService"))
local RadioService = require(script.Parent:WaitForChild("RadioService"))

local SchoolMapGenerator = {}

function SchoolMapGenerator.setupMap(onBellRing: (Player) -> ()): (Vector3, Vector3, Vector3)
	local mapFolder = workspace:FindFirstChild("SchoolMap") :: Folder?
	if mapFolder then
		mapFolder:ClearAllChildren()
	else
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "SchoolMap"
		mapFolder.Parent = workspace
	end

	-- Pomocnik tworzenia stabilnych, zakotwiczonych elementów
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, parent: Instance?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or mapFolder
		return p
	end

	-- Tabliczki i szyldy (uniwersalne, bez konkretnych nazw własnych)
	local function sign(parentPart: BasePart, face: Enum.NormalId, textStr: string, bgCol: Color3, textCol: Color3, borderCol: Color3?)
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.AlwaysOnTop = false
		sg.Parent = parentPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = bgCol
		frame.BorderSizePixel = 3
		frame.BorderColor3 = borderCol or Color3.fromRGB(20, 20, 20)
		frame.Parent = sg

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 1, -12)
		lbl.Position = UDim2.new(0, 6, 0, 6)
		lbl.BackgroundTransparency = 1
		lbl.Text = textStr
		lbl.TextColor3 = textCol
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = frame
	end

	-- Oświetlenie jarzeniowe
	local function light(pos: Vector3, range: number?, brightness: number?, isFlickering: boolean?)
		local frame = part("KasetonLampa", Vector3.new(6.5, 0.3, 2.5), CFrame.new(pos), Color3.fromRGB(230, 230, 230), Enum.Material.Metal)
		local neon = part("RuraJarzeniowa", Vector3.new(6.0, 0.15, 2.0), CFrame.new(pos - Vector3.new(0, 0.18, 0)), Color3.fromRGB(255, 255, 245), Enum.Material.Neon, frame)
		local pl = Instance.new("PointLight")
		pl.Brightness = brightness or 1.5
		pl.Range = range or 30
		pl.Color = Color3.fromRGB(255, 250, 235)
		pl.Parent = neon

		if isFlickering then
			-- Klimatyczne migotanie światła w zakamarkach
			task.spawn(function()
				while pl and pl.Parent do
					task.wait(math.random(2, 6))
					pl.Enabled = false
					neon.Color = Color3.fromRGB(120, 120, 110)
					task.wait(0.1)
					pl.Enabled = true
					neon.Color = Color3.fromRGB(255, 255, 245)
					task.wait(0.08)
					pl.Enabled = false
					task.wait(0.05)
					pl.Enabled = true
				end
			end)
		end
	end

	-- fix(agent-claude): ceilingLight było wywoływane w kroku 6/8, ale nigdy nie zdefiniowane -> crash mapy
	local function ceilingLight(pos: Vector3)
		light(pos, 40, 1.4)
	end

	-- Ściana z wyciętym przejściem drzwiowym (brak zablokowanych przejść!)
	local function wallWithDoor(name: string, totalWidth: number, height: number, cf: CFrame, doorOffset: number, color: Color3, mat: Enum.Material?)
		local wallModel = Instance.new("Model")
		wallModel.Name = name
		wallModel.Parent = mapFolder

		local doorW = 7.5
		local doorH = 10
		local leftW = math.max(1, (totalWidth / 2) + doorOffset - (doorW / 2))
		local rightW = math.max(1, (totalWidth / 2) - doorOffset - (doorW / 2))
		local topH = height - doorH

		-- Lewa część
		local leftCf = cf * CFrame.new(-totalWidth / 2 + leftW / 2, height / 2, 0)
		part("ScianaL", Vector3.new(leftW, height, 1.2), leftCf, color, mat, wallModel)

		-- Prawa część
		local rightCf = cf * CFrame.new(totalWidth / 2 - rightW / 2, height / 2, 0)
		part("ScianaP", Vector3.new(rightW, height, 1.2), rightCf, color, mat, wallModel)

		-- Nadproże
		local topCf = cf * CFrame.new(doorOffset, doorH + topH / 2, 0)
		part("Nadproze", Vector3.new(doorW, topH, 1.2), topCf, color, mat, wallModel)

		-- Ościeżnica z ciemnego drewna
		local frameCol = Color3.fromRGB(100, 60, 25)
		part("OscieznicaL", Vector3.new(0.5, doorH, 1.4), cf * CFrame.new(doorOffset - doorW / 2, doorH / 2, 0), frameCol, Enum.Material.Wood, wallModel)
		part("OscieznicaP", Vector3.new(0.5, doorH, 1.4), cf * CFrame.new(doorOffset + doorW / 2, doorH / 2, 0), frameCol, Enum.Material.Wood, wallModel)
		part("OscieznicaG", Vector3.new(doorW, 0.5, 1.4), cf * CFrame.new(doorOffset, doorH, 0), frameCol, Enum.Material.Wood, wallModel)
	end

	-- Ławka szkolna z krzesłami, zeszytem i piórnikiem
	local function deskSet(pos: Vector3, rotY: number)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
		local deskModel = Instance.new("Model")
		deskModel.Name = "Lawka"
		deskModel.Parent = mapFolder

		part("Blat", Vector3.new(6.6, 0.25, 3.4), cf * CFrame.new(0, 3.0, 0), Color3.fromRGB(220, 180, 130), Enum.Material.Wood, deskModel)
		part("Polka", Vector3.new(6.2, 0.15, 3.0), cf * CFrame.new(0, 2.4, 0), Color3.fromRGB(200, 160, 110), Enum.Material.Wood, deskModel)
		part("Stelaz", Vector3.new(6.2, 2.9, 3.0), cf * CFrame.new(0, 1.45, 0), Color3.fromRGB(30, 85, 40), Enum.Material.Metal, deskModel)

		-- Zeszyt i długopis
		part("Zeszyt", Vector3.new(1.5, 0.05, 2.0), cf * CFrame.new(-1.6, 3.15, 0.2), Color3.fromRGB(110, 170, 245), Enum.Material.SmoothPlastic, deskModel)
		part("Dlugopis", Vector3.new(0.1, 0.05, 1.2), cf * CFrame.new(-0.5, 3.15, 0.2), Color3.fromRGB(20, 20, 20), Enum.Material.Plastic, deskModel)

		for _, xOff in ipairs({ -1.9, 1.9 }) do
			local cCf = cf * CFrame.new(xOff, 0, 2.8)
			part("Siedzisko", Vector3.new(1.8, 0.15, 1.8), cCf * CFrame.new(0, 1.8, 0), Color3.fromRGB(215, 175, 125), Enum.Material.Wood, deskModel)
			part("Oparcie", Vector3.new(1.8, 1.2, 0.15), cCf * CFrame.new(0, 2.8, 0.8), Color3.fromRGB(215, 175, 125), Enum.Material.Wood, deskModel)
			part("Nogi", Vector3.new(1.6, 1.7, 1.6), cCf * CFrame.new(0, 0.85, 0), Color3.fromRGB(30, 85, 40), Enum.Material.Metal, deskModel)
		end
	end

	print("🏛️ [Budowa Wielkiej Szkoły] 1/8: Fasada monolityczna (220 x 320 studów) i Plac Apelowy...")
	-- ========================================================
	-- 1. ZEWNĘTRZNA ELEWACJA I DZIEDZINIEC (220 x 320)
	-- ========================================================
	local brickCol = Color3.fromRGB(155, 60, 45)
	local wallCol = Color3.fromRGB(245, 242, 230)
	local lamperiaCol = Color3.fromRGB(50, 95, 70) -- Klasyczna zielona lamperia

	-- Płyta fundamentowa (beton)
	part("Fundament", Vector3.new(220, 2, 320), CFrame.new(0, -1, 0), Color3.fromRGB(85, 85, 85), Enum.Material.Concrete)

	-- Ściany obwodowe budynku
	part("FasadaPolnocna", Vector3.new(220, 36, 2), CFrame.new(0, 17, -160), brickCol, Enum.Material.Brick)
	part("FasadaWschodnia", Vector3.new(2, 36, 320), CFrame.new(110, 17, 0), brickCol, Enum.Material.Brick)
	part("FasadaZachodnia", Vector3.new(2, 36, 320), CFrame.new(-110, 17, 0), brickCol, Enum.Material.Brick)
	wallWithDoor("FasadaPoludniowaWejscie", 220, 36, CFrame.new(0, 0, 160), 0, brickCol, Enum.Material.Brick)

	-- Dach główny
	part("DachGlowny", Vector3.new(222, 1.5, 322), CFrame.new(0, 35.5, 0), Color3.fromRGB(65, 65, 70), Enum.Material.Granite)

	-- DZIEDZINIEC / PLAC APELOWY (Lobby przed szkołą, Z = 230)
	local lobbyCenter = Vector3.new(0, 0, 230)
	part("BrukPlacApelowy", Vector3.new(140, 1, 100), CFrame.new(lobbyCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(150, 150, 145), Enum.Material.Cobblestone)

	-- Maszt z Flagą Polski
	part("Maszt", Vector3.new(0.6, 30, 0.6), CFrame.new(lobbyCenter + Vector3.new(0, 15.5, 25)), Color3.fromRGB(230, 230, 230), Enum.Material.Metal)
	part("FlagaBiala", Vector3.new(0.1, 3.5, 6), CFrame.new(lobbyCenter + Vector3.new(0, 27, 28)), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	part("FlagaCzerwona", Vector3.new(0.1, 3.5, 6), CFrame.new(lobbyCenter + Vector3.new(0, 23.5, 28)), Color3.fromRGB(210, 25, 25), Enum.Material.Fabric)

	-- Prosty, uniwersalny szyld szkoły (bez wymyślonych nazwisk ani numerów!)
	local mainSign = part("SzyldGlowny", Vector3.new(26, 6, 0.6), CFrame.new(0, 22, 161.2), Color3.fromRGB(20, 45, 90))
	sign(mainSign, Enum.NormalId.Back, "🏫 SZKOŁA\n'Wiedza to potęga, Rozrabiaki do raportu!'", Color3.fromRGB(20, 45, 90), Color3.fromRGB(255, 225, 65))

	-- Ławki na placu apelowym
	for _, xOff in ipairs({ -35, 35 }) do
		part("LawkaPlac", Vector3.new(16, 1.8, 2.8), CFrame.new(lobbyCenter + Vector3.new(xOff, 1.4, 0)), Color3.fromRGB(105, 60, 30), Enum.Material.Wood)
	end

	print("🏛️ [Budowa Wielkiej Szkoły] 2/8: Główny Korytarz Parteru (32 study szerokości) ze Szachownicą...")
	-- ========================================================
	-- 2. GŁÓWNY KORYTARZ PARTERU (X: -16 do +16, Z: -160 do 160)
	-- ========================================================
	part("PosadzkaKorytarzP", Vector3.new(32, 1, 320), CFrame.new(0, 0.5, 0), Color3.fromRGB(195, 195, 190), Enum.Material.Marble)
	part("StropKondygnacji", Vector3.new(220, 1, 320), CFrame.new(0, 17.5, 0), Color3.fromRGB(230, 230, 230))

	-- Oświetlenie korytarza parteru
	for z = -140, 140, 24 do
		light(Vector3.new(0, 17, z))
	end

	-- Lamperia i ściany wewnętrzne korytarza
	for _, side in ipairs({ -16, 16 }) do
		part("LamperiaKorytarzP", Vector3.new(1.2, 4.5, 320), CFrame.new(side, 2.75, 0), lamperiaCol)
	end

	-- Ściany oddzielające korytarz od sal z DRZWIAMI:
	-- ZACHODNIA ŚCIANA (X = -16):
	-- Wejście do Stołówki (z = -100)
	wallWithDoor("Drzwi_DoStolowki", 90, 17, CFrame.new(-16, 0, -100) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	-- Wejście do Toalet (z = -30)
	wallWithDoor("Drzwi_DoToalet", 60, 17, CFrame.new(-16, 0, -30) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	-- Wejście do Kanciapy Woźnej (z = 40)
	wallWithDoor("Drzwi_DoWoznej", 60, 17, CFrame.new(-16, 0, 40) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, Enum.Material.SmoothPlastic)

	-- WSCHODNIA ŚCIANA (X = 16):
	-- Wejście do Sali Gimnastycznej (z = -90)
	wallWithDoor("Drzwi_DoGym", 100, 17, CFrame.new(16, 0, -90) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	-- Wejście do Szatni Boksów (z = 0)
	wallWithDoor("Drzwi_DoSzatniBoks", 60, 17, CFrame.new(16, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	-- Wejście do Portierni / Szatni (z = 60)
	wallWithDoor("Drzwi_DoPortierni", 60, 17, CFrame.new(16, 0, 60) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, Enum.Material.SmoothPlastic)

	-- Rząd szafek na korytarzu (Zadanie: Uporządkuj Szafkę oraz Kryjówki)
	for i = 1, 10 do
		local zPos = -20 + (i * 3.8)
		local locker = part(`Szafka_{i}`, Vector3.new(2, 9, 3.4), CFrame.new(14.8, 5, zPos), Color3.fromRGB(30, 90, 185), Enum.Material.Metal)
		sign(locker, Enum.NormalId.Left, `SZAFKA\n#{100 + i}`, Color3.fromRGB(20, 50, 120), Color3.fromRGB(255, 255, 255))
		HidingService.registerLocker(locker)
	end

	local lockerPromptPart = part("InterakcjaSzafki", Vector3.new(3, 9, 38), CFrame.new(14.8, 5, -3), Color3.fromRGB(30, 90, 185), Enum.Material.Metal)
	lockerPromptPart.Transparency = 1
	local lockerPrompt = Instance.new("ProximityPrompt")
	lockerPrompt.ActionText = "Uporządkuj podręczniki w szafce"
	lockerPrompt.ObjectText = "Szafka Szkolna"
	lockerPrompt.HoldDuration = 0.5
	lockerPrompt.MaxActivationDistance = 9
	lockerPrompt.Parent = lockerPromptPart

	-- Automat z przekąskami
	local vending = part("AutomatPrzekaski", Vector3.new(3.2, 9, 5), CFrame.new(-14.4, 5, -5), Color3.fromRGB(180, 25, 25), Enum.Material.Metal)
	sign(vending, Enum.NormalId.Right, "🍫 AUTOMAT SZKOLNY\n- Wafel Prince Polo: 2.50 zł\n- Rogal 7 Days: 3.20 zł\n- Sok Tymbark: 2.80 zł", Color3.fromRGB(180, 25, 25), Color3.fromRGB(255, 255, 255))

	-- 🔍 ZAKAMAREK 1: Schowek pod schodami (ciemna wnęka pod klatką schodową)
	local cubbyUnderStairs = part("SchowekPodSchodami", Vector3.new(12, 6, 12), CFrame.new(0, 3.5, 22), Color3.fromRGB(40, 40, 40))
	cubbyUnderStairs.Transparency = 1
	-- Stare kartony i graty w schowku
	part("KartonGraty1", Vector3.new(3, 3, 3), CFrame.new(-3, 1.5, 22), Color3.fromRGB(140, 105, 65), Enum.Material.Wood)
	part("KartonGraty2", Vector3.new(2.5, 2.5, 2.5), CFrame.new(3, 1.25, 23), Color3.fromRGB(150, 115, 75), Enum.Material.Wood)

	print("🏛️ [Budowa Wielkiej Szkoły] 3/8: Szatnia w Boksach Siatkowych i Zakamarek 2...")
	-- ========================================================
	-- 3. SZATNIA W BOKSACH SIATKOWYCH (X: 16 do 110, Z: -20 do 40)
	-- ========================================================
	local szatniaCenter = Vector3.new(63, 0, 10)
	part("PosadzkaSzatnia", Vector3.new(94, 1, 60), CFrame.new(szatniaCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(140, 140, 140), Enum.Material.Concrete)
	part("ScianaSzatnia_S", Vector3.new(94, 17, 1.2), CFrame.new(szatniaCenter + Vector3.new(0, 8.5, 30)), wallCol, Enum.Material.SmoothPlastic)

	-- Boksy z metalowej siatki z wieszakami na kurtki i worki na buty
	for b = 1, 3 do
		local bZ = -10 + (b * 16)
		local meshFence = part(`SiatkaBoks_{b}`, Vector3.new(70, 9, 0.4), CFrame.new(63, 5, bZ), Color3.fromRGB(120, 120, 125), Enum.Material.Metal)
		meshFence.Transparency = 0.3
		-- Ławka z wieszakiem
		part(`LawkaBoks_{b}`, Vector3.new(65, 1.6, 2), CFrame.new(63, 1.3, bZ - 2), Color3.fromRGB(110, 70, 35), Enum.Material.Wood)
	end

	-- 🔍 ZAKAMAREK 2: Ciemny narożnik za ostatnim boksem szatni
	local darkLockerCorner = part("CiemnyNaronikSzatni", Vector3.new(18, 17, 18), CFrame.new(98, 8.5, -10), Color3.fromRGB(30, 30, 30))
	darkLockerCorner.Transparency = 1
	light(Vector3.new(98, 16, -10), 16, 0.4, true) -- Bardzo słabe, migoczące światło

	print("🏛️ [Budowa Wielkiej Szkoły] 4/8: Wielka Stołówka, Zmywak (Zakamarek 3) i Dzwon...")
	-- ========================================================
	-- 4. WIELKA STOŁÓWKA SZKOLNA (X: -110 do -16, Z: -160 do -60, Wymiary: 94 x 100)
	-- ========================================================
	local cafCenter = Vector3.new(-63, 0, -110)
	part("PosadzkaStolowka", Vector3.new(94, 1, 100), CFrame.new(cafCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(220, 210, 195), Enum.Material.Marble)
	part("ScianaStolowka_S", Vector3.new(94, 17, 1.2), CFrame.new(cafCenter + Vector3.new(0, 8.5, 50)), wallCol, Enum.Material.SmoothPlastic)

	for cx = -95, -35, 30 do
		for cz = -140, -80, 30 do
			light(Vector3.new(cx, 17, cz), 34, 1.6)
		end
	end

	-- Lada kuchenna (Okienko wydawania obiadów)
	local kitchenBar = part("LadaKuchnia", Vector3.new(46, 4.5, 4), CFrame.new(cafCenter + Vector3.new(0, 2.75, -44)), Color3.fromRGB(155, 130, 105), Enum.Material.Wood)
	sign(kitchenBar, Enum.NormalId.Back, "🍲 KUCHNIA SZKOLNA - OBIADY\nDZIŚ W MENU: PIEROGI RUSKIE ZE SKWARKAMI I KOMPOT", Color3.fromRGB(225, 205, 165), Color3.fromRGB(80, 20, 20))

	-- Talerz z pierogami (Zadanie)
	local platePart = part("TalerzPierogi", Vector3.new(4, 0.4, 4), CFrame.new(cafCenter + Vector3.new(0, 5.1, -44)), Color3.fromRGB(250, 250, 250))
	local pierogiPrompt = Instance.new("ProximityPrompt")
	pierogiPrompt.ActionText = "Zjedz szkolny obiad (Pierogi!)"
	pierogiPrompt.ObjectText = "Talerz Pierogów"
	pierogiPrompt.HoldDuration = 0.4
	pierogiPrompt.MaxActivationDistance = 9
	pierogiPrompt.Parent = platePart

	-- Długie stoły stołówkowe z ławkami
	for _, xOff in ipairs({ -22, 22 }) do
		for _, zOff in ipairs({ -20, 15 }) do
			local tCf = CFrame.new(cafCenter + Vector3.new(xOff, 2.8, zOff))
			part("StolStolowka", Vector3.new(12, 0.25, 20), tCf, Color3.fromRGB(180, 130, 85), Enum.Material.Wood)
			part("NogiStolowka", Vector3.new(11.5, 2.6, 19.5), tCf * CFrame.new(0, -1.35, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
		end
	end

	-- 🔍 ZAKAMAREK 3: Zmywak i zaplecze kuchenne za ladą stołówki
	local kitchenBackroom = part("ZapleczeKuchni", Vector3.new(46, 17, 10), CFrame.new(cafCenter + Vector3.new(0, 8.5, -50)), Color3.fromRGB(30, 30, 30))
	kitchenBackroom.Transparency = 1
	-- Zlew ze stali nierdzewnej na zapleczu
	part("ZlewStal", Vector3.new(8, 3, 3), CFrame.new(cafCenter + Vector3.new(-14, 1.5, -48)), Color3.fromRGB(180, 180, 185), Enum.Material.Metal)

	-- Ołtarz z czerwonego marmuru i WIELKI ZŁOTY DZWON
	local altar = part("OltarzDzwonu", Vector3.new(11, 2.5, 11), CFrame.new(cafCenter + Vector3.new(0, 1.75, 0)), Color3.fromRGB(165, 30, 30), Enum.Material.Marble)
	sign(altar, Enum.NormalId.Top, "🔔 WIELKI SZKOLNY DZWON ALARMOWY 🔔", Color3.fromRGB(165, 30, 30), Color3.fromRGB(255, 230, 80))

	local bell = Instance.new("Part")
	bell.Name = "WielkiDzwonSzkolny"
	bell.Shape = Enum.PartType.Cylinder
	bell.Size = Vector3.new(4.5, 4.5, 4.5)
	bell.CFrame = CFrame.new(cafCenter + Vector3.new(0, 7.0, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bell.Color = Color3.fromRGB(255, 215, 0)
	bell.Material = Enum.Material.Metal
	bell.Anchored = true
	bell.Parent = mapFolder

	local bellGlow = Instance.new("PointLight")
	bellGlow.Color = Color3.fromRGB(255, 230, 100)
	bellGlow.Brightness = 3.2
	bellGlow.Range = 36
	bellGlow.Parent = bell

	local bellTag = Instance.new("BillboardGui")
	bellTag.Size = UDim2.new(0, 260, 0, 55)
	bellTag.StudsOffset = Vector3.new(0, 4.0, 0)
	bellTag.AlwaysOnTop = true
	bellTag.Parent = bell

	local bellLabel = Instance.new("TextLabel")
	bellLabel.Size = UDim2.new(1, 0, 1, 0)
	bellLabel.BackgroundTransparency = 1
	bellLabel.Text = "🔔 WIELKI DZWON SZKOLNY\n(Zwołaj Zebranie w Stołówce!)"
	bellLabel.TextColor3 = Color3.fromRGB(255, 235, 70)
	bellLabel.TextScaled = true
	bellLabel.Font = Enum.Font.GothamBlack
	bellLabel.Parent = bellTag

	local bellPrompt = Instance.new("ProximityPrompt")
	bellPrompt.ActionText = "Uderz w Dzwon Szkolny!"
	bellPrompt.ObjectText = "Alarm Szkolny"
	bellPrompt.HoldDuration = 1.0
	bellPrompt.MaxActivationDistance = 16
	bellPrompt.Parent = bell

	bellPrompt.Triggered:Connect(function(player)
		if onBellRing then
			onBellRing(player)
		end
	end)

	print("🏛️ [Budowa Wielkiej Szkoły] 5/8: Sala Gimnastyczna, Magazynek WF (Zakamarek 4)...")
	-- ========================================================
	-- 5. SALA GIMNASTYCZNA (X: 16 do 110, Z: -160 do -40, Wymiary: 94 x 120, h=34)
	-- ========================================================
	local gymCenter = Vector3.new(63, 0, -100)
	part("ParkietGym", Vector3.new(94, 1, 120), CFrame.new(gymCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 175, 105), Enum.Material.WoodPlanks)
	part("ScianaGym_S", Vector3.new(94, 34, 1.2), CFrame.new(gymCenter + Vector3.new(0, 17, 60)), wallCol, Enum.Material.SmoothPlastic)

	for _, zEnd in ipairs({ -58, 40 }) do
		local rot = if zEnd < 0 then 0 else 180
		local backboard = part("TablicaKosz", Vector3.new(9, 6, 0.4), CFrame.new(gymCenter + Vector3.new(0, 19, zEnd)) * CFrame.Angles(0, math.rad(rot), 0), Color3.fromRGB(250, 250, 250))
		part("KoszObrecz", Vector3.new(3.2, 0.3, 3.2), backboard.CFrame * CFrame.new(0, -2.2, 2.2), Color3.fromRGB(220, 50, 20), Enum.Material.Metal)
	end

	-- Drabinki ścienne
	for i = 1, 14 do
		part(`Drabinka_{i}`, Vector3.new(0.3, 0.3, 50), CFrame.new(108.8, i * 2.3, -100), Color3.fromRGB(200, 150, 90), Enum.Material.Wood)
	end

	-- 🔍 ZAKAMAREK 4: Magazynek sprzętu WF (ciemny schowek ze stosem materacy za salą)
	local gymStorage = part("MagazynekWF", Vector3.new(24, 14, 20), CFrame.new(95, 7, -145), Color3.fromRGB(30, 30, 30))
	gymStorage.Transparency = 1
	wallWithDoor("DrzwiMagazynekWF", 24, 14, CFrame.new(95, 0, -135), 0, wallCol, Enum.Material.SmoothPlastic)

	-- Stos niebieskich materacy gimnastycznych w magazynku
	for m = 1, 4 do
		part(`Materac_{m}`, Vector3.new(8, 0.8, 12), CFrame.new(95, 0.5 + (m * 0.8), -145), Color3.fromRGB(35, 95, 200), Enum.Material.Fabric)
	end
	light(Vector3.new(95, 13, -145), 14, 0.5, true) -- Bardzo nastrojowe, ciemne światło w magazynku

	-- TOALETY SZKOLNE (Z: -50 do -10, X: -110 do -16)
	local toiletsCenter = Vector3.new(-63, 0, -30)
	part("PosadzkaToalety", Vector3.new(94, 1, 40), CFrame.new(toiletsCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(205, 215, 225), Enum.Material.Marble)
	part("ScianaToalety_S", Vector3.new(94, 17, 1.2), CFrame.new(toiletsCenter + Vector3.new(0, 8.5, 20)), wallCol, Enum.Material.SmoothPlastic)

	-- Kabiny toaletowe
	for c = 1, 4 do
		local cX = -85 + (c * 12)
		part(`KabinaBok_{c}`, Vector3.new(0.3, 10, 8), CFrame.new(cX, 5.5, -35), Color3.fromRGB(210, 210, 210), Enum.Material.Wood)
		local door = part(`KabinaDrzwi_{c}`, Vector3.new(6, 9, 0.3), CFrame.new(cX + 3, 5.5, -31), Color3.fromRGB(200, 200, 200), Enum.Material.Wood)
		if c == 4 then
			-- 🔍 ZAKAMAREK 5: Ostatnia kabina z tabliczką "AWARIA"
			sign(door, Enum.NormalId.Back, "⛔ AWARIA\nNIE WCHODZIĆ!", Color3.fromRGB(180, 30, 30), Color3.fromRGB(255, 255, 255))
		end
	end

	-- KANCIAPA WOŹNEJ (Z: 20 do 60, X: -110 do -16)
	local janCenter = Vector3.new(-63, 0, 40)
	part("PosadzkaWozna", Vector3.new(94, 1, 40), CFrame.new(janCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(130, 130, 130), Enum.Material.Concrete)
	local shelfJan = part("PolkaLudwik", Vector3.new(2, 9, 26), CFrame.new(janCenter + Vector3.new(-40, 5.5, 0)), Color3.fromRGB(90, 65, 45), Enum.Material.Wood)
	sign(shelfJan, Enum.NormalId.Right, "🧹 KANCIAPA WOŹNEJ\nŚRODKI CZYSTOŚCI: PŁYN LUDWIK, MOPY, WIADRA\nUWAGA: NIE DEPTAĆ PO ŚWIEŻO ZMYTYM!", Color3.fromRGB(35, 75, 120), Color3.fromRGB(255, 255, 255))

	-- Plama do zmycia
	local puddle = part("PlamaDoZmycia", Vector3.new(10, 0.05, 10), CFrame.new(janCenter + Vector3.new(-5, 1.05, 0)), Color3.fromRGB(150, 95, 35), Enum.Material.Glass)
	local puddlePrompt = Instance.new("ProximityPrompt")
	puddlePrompt.ActionText = "Zmyj rozlaną zupę mopem!"
	puddlePrompt.ObjectText = "Śliska Plama"
	puddlePrompt.HoldDuration = 0.8
	puddlePrompt.MaxActivationDistance = 9
	puddlePrompt.Parent = puddle

	print("🏛️ [Budowa Wielkiej Szkoły] 6/8: Schody Korytarzowe i I Piętro (Sale Lekcyjne)...")
	-- ========================================================
	-- 6. SCHODY DWUBIEGOWE NA I PIĘTRO (Z: 60 do 110, wejście na Y = 17.5)
	-- ========================================================
	local stairsSteps = 24
	local stepHeight = 17.0 / stairsSteps
	local stepDepth = 40.0 / stairsSteps

	for s = 1, stairsSteps do
		local sY = (s * stepHeight) - (stepHeight / 2)
		local sZ = 65 + (s * stepDepth)
		part(`Stopien_{s}`, Vector3.new(16, stepHeight, stepDepth + 0.1), CFrame.new(0, sY, sZ), Color3.fromRGB(170, 170, 160), Enum.Material.Concrete)
	end
	part("PoreczL", Vector3.new(0.5, 3.8, 44), CFrame.new(-8.2, 11, 85) * CFrame.Angles(math.rad(-26), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	part("PoreczP", Vector3.new(0.5, 3.8, 44), CFrame.new(8.2, 11, 85) * CFrame.Angles(math.rad(-26), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)

	-- ========================================================
	-- 7. I PIĘTRO: SALE LEKCYJNE I GABINETY (Y = 17.5 do 35)
	-- ========================================================
	for z = -140, 140, 24 do
		ceilingLight(Vector3.new(0, 34, z))
	end

	-- A) GABINET DYREKTORA Z SEKRETARIATEM (I Piętro, X: 16 do 110, Z: 20 do 80)
	local dirCenter = Vector3.new(63, 17.5, 50)
	wallWithDoor("Drzwi_DoDyrektora", 60, 17, CFrame.new(16, 17.5, 50) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	part("PodlogaDyrektor", Vector3.new(94, 1, 60), CFrame.new(dirCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(120, 60, 30), Enum.Material.WoodPlanks)

	-- Czerwony dywanik u Dyrektora
	part("DywanikDyrektora", Vector3.new(20, 0.1, 28), CFrame.new(dirCenter + Vector3.new(0, 1.05, 0)), Color3.fromRGB(180, 20, 20), Enum.Material.Fabric)

	-- Mahoniowe biurko i mikrofon radiowęzła
	local dirDesk = part("BiurkoDyrektora", Vector3.new(14, 3.4, 6), CFrame.new(dirCenter + Vector3.new(18, 2.7, 0)), Color3.fromRGB(60, 30, 15), Enum.Material.Wood)
	sign(dirDesk, Enum.NormalId.Left, "👑 GABINET DYREKTORA\n'Wszystko widzę, wszystko wiem!'", Color3.fromRGB(60, 30, 15), Color3.fromRGB(255, 215, 0))
	RadioService.setupMicrophone(dirDesk.Position)

	-- 🔍 ZAKAMAREK 6: Archiwum akt szkolnych za parawanem w gabinecie dyrektora
	local archiveAlcove = part("ArchiwumAkt", Vector3.new(16, 16, 14), CFrame.new(dirCenter + Vector3.new(38, 8, 20)), Color3.fromRGB(30, 30, 30))
	archiveAlcove.Transparency = 1
	-- Szafa pancerna na akta
	part("SzafaPancerna", Vector3.new(4, 9, 8), CFrame.new(dirCenter + Vector3.new(42, 4.5, 20)), Color3.fromRGB(40, 45, 50), Enum.Material.Metal)

	-- B) PRACOWNIA MATEMATYCZNA (Sala 201, I Piętro, X: -110 do -16, Z: -120 do -60)
	local mathCenter = Vector3.new(-63, 17.5, -90)
	wallWithDoor("Drzwi_DoMatmy", 60, 17, CFrame.new(-16, 17.5, -90) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	part("PodlogaMatma", Vector3.new(94, 1, 60), CFrame.new(mathCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(210, 225, 210))

	local mathBoard = part("TablicaMatematyka", Vector3.new(1, 8, 24), CFrame.new(-108.8, 24.5, -90), Color3.fromRGB(35, 65, 45))
	sign(mathBoard, Enum.NormalId.Right, "📐 PRACOWNIA MATEMATYCZNA (SALA 201)\n\nKARTKÓWKA Z MATEMATYKI:\nRozwiąż równanie: 2 + 2 = ?\na) 3   b) 4   c) 5", Color3.fromRGB(35, 65, 45), Color3.fromRGB(255, 255, 255))

	local mathPrompt = Instance.new("ProximityPrompt")
	mathPrompt.ActionText = "Rozwiąż zadanie z Matematyki"
	mathPrompt.ObjectText = "Tablica Matematyczna"
	mathPrompt.HoldDuration = 0.5
	mathPrompt.MaxActivationDistance = 10
	mathPrompt.Parent = mathBoard

	for _, rZ in ipairs({ -16, 0, 16 }) do
		for _, cX in ipairs({ -45, -65, -85 }) do
			deskSet(Vector3.new(cX, 18, rZ - 90), -90)
		end
	end

	-- C) PRACOWNIA JĘZYKA POLSKIEGO (Sala 202, I Piętro, X: -110 do -16, Z: -50 do 10)
	local polCenter = Vector3.new(-63, 17.5, -20)
	wallWithDoor("Drzwi_DoPolskiego", 60, 17, CFrame.new(-16, 17.5, -20) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	part("PodlogaPolski", Vector3.new(94, 1, 60), CFrame.new(polCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(230, 215, 205))

	local polBoard = part("TablicaPolski", Vector3.new(1, 8, 24), CFrame.new(-108.8, 24.5, -20), Color3.fromRGB(40, 40, 45))
	sign(polBoard, Enum.NormalId.Right, "📖 PRACOWNIA JĘZYKA POLSKIEGO (SALA 202)\n\nDYKTANDO SZKOLNE:\nPrzepisz bezbłędnie słowo: 'szkoła' lub 'kartkówka'!", Color3.fromRGB(40, 40, 45), Color3.fromRGB(255, 255, 255))

	local polishPrompt = Instance.new("ProximityPrompt")
	polishPrompt.ActionText = "Napisz dyktando z Polskiego"
	polishPrompt.ObjectText = "Tablica Języka Polskiego"
	polishPrompt.HoldDuration = 0.5
	polishPrompt.MaxActivationDistance = 10
	polishPrompt.Parent = polBoard

	for _, rZ in ipairs({ -16, 0, 16 }) do
		for _, cX in ipairs({ -45, -65, -85 }) do
			deskSet(Vector3.new(cX, 18, rZ - 20), -90)
		end
	end

	-- D) PRACOWNIA CHEMICZNA Z ZAPLECZEM (Sala 204, I Piętro, X: 16 do 110, Z: -120 do -60)
	local chemCenter = Vector3.new(63, 17.5, -90)
	wallWithDoor("Drzwi_DoChemii", 60, 17, CFrame.new(16, 17.5, -90) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, Enum.Material.SmoothPlastic)
	part("PodlogaChemia", Vector3.new(94, 1, 60), CFrame.new(chemCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(200, 220, 230))

	local chemBoard = part("TablicaChemia", Vector3.new(1, 8, 24), CFrame.new(108.8, 24.5, -90), Color3.fromRGB(25, 45, 70))
	sign(chemBoard, Enum.NormalId.Left, "🧪 PRACOWNIA CHEMICZNA (SALA 204)\nUKŁAD OKRESOWY PIERWIASTKÓW\nZakaz wąchania odczynników laboratoryjnych!", Color3.fromRGB(25, 45, 70), Color3.fromRGB(255, 255, 255))

	-- 🔍 ZAKAMAREK 7: Ciemne zaplecze chemiczne z tylnym wyjściem awaryjnym
	local chemBackroom = part("ZapleczeChemii", Vector3.new(20, 16, 26), CFrame.new(chemCenter + Vector3.new(35, 8, 14)), Color3.fromRGB(30, 30, 30))
	chemBackroom.Transparency = 1
	wallWithDoor("DrzwiZapleczeChemii", 20, 16, CFrame.new(chemCenter + Vector3.new(25, 8, 14)), 0, wallCol, Enum.Material.SmoothPlastic)

	-- 🔍 ZAKAMAREK 8: Ślepy zaułek korytarza I piętra przy zamkniętych drzwiach ewakuacyjnych
	local blindAlley = part("SlepyZaulekKorytarza", Vector3.new(32, 16, 24), CFrame.new(0, 25.5, -148), Color3.fromRGB(30, 30, 30))
	blindAlley.Transparency = 1
	local fireDoor = part("DrzwiPozarowe", Vector3.new(12, 10, 0.8), CFrame.new(0, 22.5, -159), Color3.fromRGB(190, 30, 30))
	sign(fireDoor, Enum.NormalId.Back, "🚨 WYJŚCIE EWAKUACYJNE\nZAMKNIĘTE NA KLUCZ W TRAKCIE LEKCJI", Color3.fromRGB(190, 30, 30), Color3.fromRGB(255, 255, 255))
	light(Vector3.new(0, 33, -145), 14, 0.4, true) -- Bardzo ciemny zaułek, migotanie

	print("🏛️ [Budowa Wielkiej Szkoły] 7/8: Podłączanie interakcji zadań...")
	-- ========================================================
	-- 8. REJESTRACJA INTERAKCJI Z ZADANIAMI
	-- ========================================================
	local function bindTask(prompt: ProximityPrompt, taskId: string)
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("IsAlive") == true then
				local rem = ReplicatedStorage:FindFirstChild("Events")
				local taskEvent = rem and rem:FindFirstChild("OpenTaskGui")
				if not taskEvent then
					taskEvent = Instance.new("RemoteEvent")
					taskEvent.Name = "OpenTaskGui"
					taskEvent.Parent = rem
				end
				(taskEvent :: RemoteEvent):FireClient(player, taskId)
			end
		end)
	end

	bindTask(mathPrompt, GameConfig.Tasks.Matematyka.Id)
	bindTask(polishPrompt, GameConfig.Tasks.JezykPolski.Id)
	bindTask(lockerPrompt, GameConfig.Tasks.SzafkiKsiazki.Id)
	bindTask(pierogiPrompt, GameConfig.Tasks.StolowkaPierogi.Id)

	print("✨ [SUKCES] Ogromna, klimatyczna polska szkoła (220x320 studów) z 8 zakamarkami została w pełni wygenerowana!")

	local schoolSpawnPos = Vector3.new(0, 3.5, 120)
	local cafeteriaPos = cafCenter + Vector3.new(0, 3.5, 0)
	local lobbySpawnPos = lobbyCenter + Vector3.new(0, 3.5, 0)

	return schoolSpawnPos, cafeteriaPos, lobbySpawnPos
end

return SchoolMapGenerator
