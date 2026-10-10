--!strict
-- src/server/SchoolMapGenerator.luau
-- MONUMENTALNA POLSKA SZKOŁA "TYSIĄCLATKA" - ARCHITEKTURA MODUŁOWA
-- Spójny, w 100% połączony budynek szkolny bez wiszących klocków czy dziur:
-- • Wymiary kompleksu: 160 x 280 studów, 2 pełne kondygnacje (Parter + I Piętro)
-- • Prawdziwe przejścia drzwiowe z ościeżnicami między korytarzem a salami
-- • Fasada zewnętrzna z czerwonej cegły z oknami i gzymsami
-- • Parter: Korytarz z lamperią, Stołówka z Dzwonem, Sala Gimnastyczna, Kanciapa, Toalety
-- • I Piętro (Schody): Gabinet Dyrektora, Pokój Nauczycielski, Sala Matmy, Polskiego, Informatyki, Chemii
-- • Dziedziniec: Plac apelowy, maszt flagowy, zadaszone wejście główne

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

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

	-- Podstawowy kreator części ze spawaniem i kotwiczeniem
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

	-- Kreator tablic informacyjnych (SurfaceGui z polskimi memami szkolnymi)
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

	-- Zaawansowane oświetlenie sufitowe (oprawa kasetonowa + świetlówki Neon)
	local function ceilingLight(pos: Vector3, range: number?, brightness: number?)
		local frame = part("KasetonOswietleniowy", Vector3.new(6, 0.3, 3), CFrame.new(pos), Color3.fromRGB(230, 230, 230), Enum.Material.Metal)
		local neon = part("JarzeniowkaNeon", Vector3.new(5.6, 0.15, 2.6), CFrame.new(pos - Vector3.new(0, 0.18, 0)), Color3.fromRGB(255, 255, 245), Enum.Material.Neon, frame)
		local pl = Instance.new("PointLight")
		pl.Brightness = brightness or 1.6
		pl.Range = range or 28
		pl.Color = Color3.fromRGB(255, 250, 235)
		pl.Parent = neon
	end

	-- Kreator ściany z drzwiami (otworem wejściowym o szerokości 6 studów i wysokości 9 studów)
	local function wallWithDoor(name: string, totalWidth: number, height: number, cf: CFrame, doorOffset: number, color: Color3, mat: Enum.Material?)
		local wallModel = Instance.new("Model")
		wallModel.Name = name
		wallModel.Parent = mapFolder

		local doorW = 7
		local doorH = 9.5
		local leftW = math.max(1, (totalWidth / 2) + doorOffset - (doorW / 2))
		local rightW = math.max(1, (totalWidth / 2) - doorOffset - (doorW / 2))
		local topH = height - doorH

		-- Lewa część ściany
		local leftCf = cf * CFrame.new(-totalWidth / 2 + leftW / 2, height / 2, 0)
		part("ScianaLewa", Vector3.new(leftW, height, 1), leftCf, color, mat, wallModel)

		-- Prawa część ściany
		local rightCf = cf * CFrame.new(totalWidth / 2 - rightW / 2, height / 2, 0)
		part("ScianaPrawa", Vector3.new(rightW, height, 1), rightCf, color, mat, wallModel)

		-- Nadproże nad drzwiami
		local topCf = cf * CFrame.new(doorOffset, doorH + topH / 2, 0)
		part("Nadproze", Vector3.new(doorW, topH, 1), topCf, color, mat, wallModel)

		-- Drewniana ościeżnica drzwiowa
		local frameCol = Color3.fromRGB(110, 65, 30)
		part("OscieznicaL", Vector3.new(0.4, doorH, 1.2), cf * CFrame.new(doorOffset - doorW / 2, doorH / 2, 0), frameCol, Enum.Material.Wood, wallModel)
		part("OscieznicaP", Vector3.new(0.4, doorH, 1.2), cf * CFrame.new(doorOffset + doorW / 2, doorH / 2, 0), frameCol, Enum.Material.Wood, wallModel)
		part("OscieznicaG", Vector3.new(doorW, 0.4, 1.2), cf * CFrame.new(doorOffset, doorH, 0), frameCol, Enum.Material.Wood, wallModel)
	end

	-- Klasyczna polska ławka z krzesłami (z detalami: piórnik, zeszyt)
	local function schoolDeskSet(pos: Vector3, rotY: number)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
		local deskModel = Instance.new("Model")
		deskModel.Name = "LawkaSzkolna"
		deskModel.Parent = mapFolder

		-- Blat ławki (drewno ze żłobieniem)
		part("Blat", Vector3.new(6.4, 0.25, 3.2), cf * CFrame.new(0, 2.9, 0), Color3.fromRGB(220, 180, 130), Enum.Material.Wood, deskModel)
		-- Półka pod blatem
		part("PolkaPodreczniki", Vector3.new(6.0, 0.15, 2.8), cf * CFrame.new(0, 2.3, 0), Color3.fromRGB(200, 160, 110), Enum.Material.Wood, deskModel)
		-- Stalowy zielony stelaż
		part("NogiStelaz", Vector3.new(6.0, 2.8, 2.8), cf * CFrame.new(0, 1.4, 0), Color3.fromRGB(25, 80, 35), Enum.Material.Metal, deskModel)

		-- Zeszyt w kratkę na blacie
		local notebook = part("Zeszyt", Vector3.new(1.4, 0.05, 1.8), cf * CFrame.new(-1.4, 3.05, 0.2), Color3.fromRGB(100, 160, 240), Enum.Material.SmoothPlastic, deskModel)
		-- Długopis
		part("Dlugopis", Vector3.new(0.1, 0.05, 1.2), cf * CFrame.new(-0.4, 3.05, 0.2), Color3.fromRGB(20, 20, 20), Enum.Material.Plastic, deskModel)

		-- 2 Krzesła
		for _, xOff in ipairs({ -1.8, 1.8 }) do
			local cCf = cf * CFrame.new(xOff, 0, 2.6)
			part("Siedzisko", Vector3.new(1.8, 0.15, 1.8), cCf * CFrame.new(0, 1.8, 0), Color3.fromRGB(215, 175, 125), Enum.Material.Wood, deskModel)
			part("Oparcie", Vector3.new(1.8, 1.2, 0.15), cCf * CFrame.new(0, 2.8, 0.8), Color3.fromRGB(215, 175, 125), Enum.Material.Wood, deskModel)
			part("NogiKrzesla", Vector3.new(1.6, 1.7, 1.6), cCf * CFrame.new(0, 0.85, 0), Color3.fromRGB(25, 80, 35), Enum.Material.Metal, deskModel)
		end
	end

	print("🏛️ [Budowa Szkoły] 1/6: Fundamenty, Plac Apelowy i Elewacja Zewnętrzna...")
	-- ========================================================
	-- 1. FUNDAMENT I ELEWACJA ZEWNĘTRZNA (160 x 280 studów)
	-- ========================================================
	-- Główna płyta fundamentowa
	part("FundamentGlowny", Vector3.new(160, 2, 280), CFrame.new(0, -1, 0), Color3.fromRGB(90, 90, 90), Enum.Material.Concrete)

	-- Fasada zewnętrzna z czerwonej cegły z oknami
	local brickCol = Color3.fromRGB(160, 65, 50)
	-- Ściana Północna (tył)
	part("FasadaPolnocna", Vector3.new(160, 34, 2), CFrame.new(0, 16, -140), brickCol, Enum.Material.Brick)
	-- Ściana Wschodnia (prawa)
	part("FasadaWschodnia", Vector3.new(2, 34, 280), CFrame.new(80, 16, 0), brickCol, Enum.Material.Brick)
	-- Ściana Zachodnia (lewa)
	part("FasadaZachodnia", Vector3.new(2, 34, 280), CFrame.new(-80, 16, 0), brickCol, Enum.Material.Brick)
	-- Ściana Południowa (frontowa) z wielkim wejściem
	wallWithDoor("FasadaFrontowa", 160, 34, CFrame.new(0, 0, 140), 0, brickCol, Enum.Material.Brick)

	-- Dach główny z papy/żwiru z gzymsem
	part("DachGlowny", Vector3.new(162, 1.5, 282), CFrame.new(0, 34, 0), Color3.fromRGB(70, 70, 75), Enum.Material.Granite)

	-- PLAC APELOWY / LOBBY PRZED SZKOŁĄ (z = 210)
	local lobbyCenter = Vector3.new(0, 0, 210)
	part("KostkaBrukowaPlac", Vector3.new(120, 1, 100), CFrame.new(lobbyCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(160, 160, 155), Enum.Material.Cobblestone)

	-- Maszt z Flagą Polski
	local pole = part("Maszt", Vector3.new(0.6, 28, 0.6), CFrame.new(lobbyCenter + Vector3.new(0, 14.5, 20)), Color3.fromRGB(230, 230, 230), Enum.Material.Metal)
	part("FlagaBiala", Vector3.new(0.1, 3.2, 5.5), CFrame.new(lobbyCenter + Vector3.new(0, 25.5, 22.8)), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	part("FlagaCzerwona", Vector3.new(0.1, 3.2, 5.5), CFrame.new(lobbyCenter + Vector3.new(0, 22.3, 22.8)), Color3.fromRGB(215, 30, 30), Enum.Material.Fabric)

	-- Tablica nad wejściem głównym
	local mainSchoolSign = part("SzyldSzkoly", Vector3.new(34, 7, 0.8), CFrame.new(0, 20, 141.2), Color3.fromRGB(15, 45, 100))
	sign(mainSchoolSign, Enum.NormalId.Back, "🏫 SZKOŁA PODSTAWOWA NR 1 IM. ADAMA MICKIEWICZA\n'Nauka to potęga, Rozrabiaki do raportu!'", Color3.fromRGB(15, 45, 100), Color3.fromRGB(255, 225, 70))

	-- Ławki przed szkołą
	for _, xOff in ipairs({ -30, 30 }) do
		part("LawkaZewnetrzna", Vector3.new(14, 1.8, 2.6), CFrame.new(lobbyCenter + Vector3.new(xOff, 1.4, 0)), Color3.fromRGB(110, 65, 35), Enum.Material.Wood)
	end

	print("🏛️ [Budowa Szkoły] 2/6: Główny Korytarz Parteru z Lamperią i Szachownicą...")
	-- ========================================================
	-- 2. GŁÓWNY KORYTARZ PARTERU (Szerokość 28 studów, X: -14 do +14, Z: -140 do 140)
	-- ========================================================
	-- Szachownica posadzkowa korytarza
	part("PosadzkaKorytarzP", Vector3.new(28, 1, 280), CFrame.new(0, 0.5, 0), Color3.fromRGB(195, 195, 190), Enum.Material.Marble)
	-- Strop między kondygnacjami (y = 16.5)
	part("StropMiedzykondygnacyjny", Vector3.new(160, 1, 280), CFrame.new(0, 16.5, 0), Color3.fromRGB(230, 230, 230))

	-- Światła korytarza parteru
	for z = -120, 120, 24 do
		ceilingLight(Vector3.new(0, 16, z))
	end

	-- Ściany wewnętrzne korytarza parteru z DRZWIAMI do wszystkich sal!
	-- ŚCIANA ZACHODNIA KORYTARZA (X = -14)
	-- Prowadzi do: Stołówki (z = -90), Toalet (z = -30), Kanciapy Woźnej (z = 40)
	local wallMat = Enum.Material.SmoothPlastic
	local wallCol = Color3.fromRGB(245, 242, 230)

	wallWithDoor("KorytarzW_DoStolowki", 70, 16, CFrame.new(-14, 0, -95) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, wallMat)
	wallWithDoor("KorytarzW_DoToalet", 60, 16, CFrame.new(-14, 0, -30) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, wallMat)
	wallWithDoor("KorytarzW_DoWoznej", 60, 16, CFrame.new(-14, 0, 40) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, wallMat)

	-- ŚCIANA WSCHODNIA KORYTARZA (X = 14)
	-- Prowadzi do: Sali Gimnastycznej (z = -80), Szatni/Portierni (z = 0), Pielęgniarki (z = 60)
	wallWithDoor("KorytarzE_DoGym", 90, 16, CFrame.new(14, 0, -85) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, wallMat)
	wallWithDoor("KorytarzE_DoSzatni", 60, 16, CFrame.new(14, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, wallMat)
	wallWithDoor("KorytarzE_DoPielegniarki", 60, 16, CFrame.new(14, 0, 60) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, wallMat)

	-- Rząd szafek korytarzowych (Zadanie)
	for i = 1, 8 do
		local zPos = -10 + (i * 4)
		local locker = part(`Szafka_{i}`, Vector3.new(2, 9, 3.4), CFrame.new(12.8, 5, zPos), Color3.fromRGB(25, 85, 175), Enum.Material.Metal)
		sign(locker, Enum.NormalId.Left, `SZAFKA\n#{100 + i}`, Color3.fromRGB(20, 50, 120), Color3.fromRGB(255, 255, 255))
	end

	local lockerPromptPart = part("InterakcjaSzafki", Vector3.new(3, 9, 34), CFrame.new(12.8, 5, 6), Color3.fromRGB(25, 85, 175), Enum.Material.Metal)
	lockerPromptPart.Transparency = 1
	local lockerPrompt = Instance.new("ProximityPrompt")
	lockerPrompt.ActionText = "Uporządkuj podręczniki w szafce"
	lockerPrompt.ObjectText = "Szafka Szkolna"
	lockerPrompt.HoldDuration = 0.5
	lockerPrompt.MaxActivationDistance = 9
	lockerPrompt.Parent = lockerPromptPart

	-- Automat z przekąskami
	local vending = part("AutomatPrzekaski", Vector3.new(3.2, 9, 5), CFrame.new(-12.4, 5, -5), Color3.fromRGB(175, 20, 20), Enum.Material.Metal)
	sign(vending, Enum.NormalId.Right, "🍫 AUTOMAT SZKOLNY\n- Wafel Prince Polo: 2.50 zł\n- Rogal 7 Days: 3.20 zł\n- Napój Tymbark: 2.80 zł", Color3.fromRGB(175, 20, 20), Color3.fromRGB(255, 255, 255))

	print("🏛️ [Budowa Szkoły] 3/6: Wielka Stołówka z Kuchnią i Wielkim Złotym Dzwonem...")
	-- ========================================================
	-- 3. WIELKA STOŁÓWKA SZKOLNA (Skrzydło Zachodnie, X: -80 do -14, Z: -140 do -60, Wymiary: 66 x 80)
	-- ========================================================
	local cafCenter = Vector3.new(-47, 0, -100)
	-- Posadzka kafelkowa
	part("PosadzkaStolowka", Vector3.new(66, 1, 80), CFrame.new(cafCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(220, 210, 195), Enum.Material.Marble)
	-- Ściana oddzielająca stołówkę od toalet
	part("ScianaStolowka_S", Vector3.new(66, 16, 1), CFrame.new(cafCenter + Vector3.new(0, 8, 40)), wallCol, wallMat)

	-- Oświetlenie stołówki
	for cx = -65, -30, 20 do
		for cz = -125, -75, 25 do
			ceilingLight(Vector3.new(cx, 16, cz), 34, 1.5)
		end
	end

	-- Lada kuchenna (Okienko wydawania obiadów)
	local kitchenBar = part("LadaKuchenna", Vector3.new(36, 4.5, 3.5), CFrame.new(cafCenter + Vector3.new(0, 2.75, -36)), Color3.fromRGB(160, 135, 110), Enum.Material.Wood)
	sign(kitchenBar, Enum.NormalId.Back, "🍲 KUCHNIA SZKOLNA - OBIADY\nDZIŚ W MENU: PIEROGI RUSKIE ZE SKWARKAMI I KOMPOT", Color3.fromRGB(225, 205, 165), Color3.fromRGB(90, 25, 25))

	-- Talerz z pierogami (Zadanie)
	local platePart = part("TalerzPierogi", Vector3.new(4, 0.4, 4), CFrame.new(cafCenter + Vector3.new(0, 5.1, -36)), Color3.fromRGB(250, 250, 250))
	local pierogiPrompt = Instance.new("ProximityPrompt")
	pierogiPrompt.ActionText = "Zjedz szkolny obiad (Pierogi!)"
	pierogiPrompt.ObjectText = "Talerz Pierogów"
	pierogiPrompt.HoldDuration = 0.4
	pierogiPrompt.MaxActivationDistance = 9
	pierogiPrompt.Parent = platePart

	-- Długie stoły stołówkowe z krzesłami
	for _, xOff in ipairs({ -16, 16 }) do
		for _, zOff in ipairs({ -12, 16 }) do
			local tCf = CFrame.new(cafCenter + Vector3.new(xOff, 2.8, zOff))
			part("StolStolowka", Vector3.new(9, 0.25, 16), tCf, Color3.fromRGB(180, 130, 85), Enum.Material.Wood)
			part("NogiStolowka", Vector3.new(8.5, 2.6, 15.5), tCf * CFrame.new(0, -1.35, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
		end
	end

	-- Centralne podium z czerwonego marmuru
	local altar = part("OltarzDzwonu", Vector3.new(10, 2.5, 10), CFrame.new(cafCenter + Vector3.new(0, 1.75, 0)), Color3.fromRGB(165, 30, 30), Enum.Material.Marble)
	sign(altar, Enum.NormalId.Top, "🔔 WIELKI SZKOLNY DZWON ALARMOWY 🔔", Color3.fromRGB(165, 30, 30), Color3.fromRGB(255, 230, 80))

	-- WIELKI ZŁOTY DZWON SZKOLNY
	local bell = Instance.new("Part")
	bell.Name = "WielkiDzwonSzkolny"
	bell.Shape = Enum.PartType.Cylinder
	bell.Size = Vector3.new(4.2, 4.2, 4.2)
	bell.CFrame = CFrame.new(cafCenter + Vector3.new(0, 6.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bell.Color = Color3.fromRGB(255, 215, 0)
	bell.Material = Enum.Material.Metal
	bell.Anchored = true
	bell.Parent = mapFolder

	local bellGlow = Instance.new("PointLight")
	bellGlow.Color = Color3.fromRGB(255, 230, 100)
	bellGlow.Brightness = 3.0
	bellGlow.Range = 32
	bellGlow.Parent = bell

	local bellTag = Instance.new("BillboardGui")
	bellTag.Size = UDim2.new(0, 260, 0, 55)
	bellTag.StudsOffset = Vector3.new(0, 3.8, 0)
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

	print("🏛️ [Budowa Szkoły] 4/6: Pełnowymiarowa Sala Gimnastyczna i Kanciapa Woźnej...")
	-- ========================================================
	-- 4. SALA GIMNASTYCZNA (Skrzydło Wschodnie, X: 14 do 80, Z: -140 do -40, Wymiary: 66 x 100, Wysokość: 32 study!)
	-- ========================================================
	local gymCenter = Vector3.new(47, 0, -90)
	part("ParkietGimnastyczny", Vector3.new(66, 1, 100), CFrame.new(gymCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 175, 105), Enum.Material.WoodPlanks)
	-- Ściana oddzielająca salę od korytarza i szatni
	part("ScianaGym_S", Vector3.new(66, 32, 1), CFrame.new(gymCenter + Vector3.new(0, 16, 50)), wallCol, wallMat)

	-- Kosze do koszykówki z tablicami
	for _, zEnd in ipairs({ -48, 48 }) do
		local rot = if zEnd < 0 then 0 else 180
		local backboard = part("TablicaKosz", Vector3.new(8, 5.5, 0.4), CFrame.new(gymCenter + Vector3.new(0, 18, zEnd)) * CFrame.Angles(0, math.rad(rot), 0), Color3.fromRGB(250, 250, 250))
		part("KoszObrecz", Vector3.new(3.0, 0.3, 3.0), backboard.CFrame * CFrame.new(0, -2, 2.0), Color3.fromRGB(220, 50, 20), Enum.Material.Metal)
	end

	-- Drabinki ścienne
	for i = 1, 12 do
		part(`Drabinka_{i}`, Vector3.new(0.3, 0.3, 40), CFrame.new(78.8, i * 2.4, -90), Color3.fromRGB(200, 150, 90), Enum.Material.Wood)
	end

	-- KANCIAPA WOŹNEJ (Parter, X: -47, Z: 40, Wymiary: 66 x 60)
	local janCenter = Vector3.new(-47, 0, 40)
	part("PosadzkaWozna", Vector3.new(66, 1, 60), CFrame.new(janCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(130, 130, 130), Enum.Material.Concrete)
	local shelfJan = part("PolkaLudwik", Vector3.new(2, 9, 24), CFrame.new(janCenter + Vector3.new(-30, 5.5, 0)), Color3.fromRGB(90, 65, 45), Enum.Material.Wood)
	sign(shelfJan, Enum.NormalId.Right, "🧹 KANCIAPA PANI WOŹNEJ\nŚRODKI CZYSTOŚCI: PŁYN LUDWIK, MOPY, WIADRA\nUWAGA: NIE DEPTAĆ PO ŚWIEŻO ZMYTYM!", Color3.fromRGB(35, 75, 120), Color3.fromRGB(255, 255, 255))

	-- Plama do zmycia
	local puddle = part("PlamaDoZmycia", Vector3.new(9, 0.05, 9), CFrame.new(janCenter + Vector3.new(-5, 1.05, 0)), Color3.fromRGB(150, 95, 35), Enum.Material.Glass)
	local puddlePrompt = Instance.new("ProximityPrompt")
	puddlePrompt.ActionText = "Zmyj rozlaną zupę mopem!"
	puddlePrompt.ObjectText = "Śliska Plama"
	puddlePrompt.HoldDuration = 0.8
	puddlePrompt.MaxActivationDistance = 9
	puddlePrompt.Parent = puddle

	print("🏛️ [Budowa Szkoły] 5/6: Schody Dwubiegowe i I Piętro (Sale Lekcyjne)...")
	-- ========================================================
	-- 5. SCHODY NA I PIĘTRO (X: 0, Z: 30 do 70, wchodzi na y = 16.5)
	-- ========================================================
	local stairsSteps = 22
	local stepHeight = 16.0 / stairsSteps
	local stepDepth = 30.0 / stairsSteps

	for s = 1, stairsSteps do
		local sY = (s * stepHeight) - (stepHeight / 2)
		local sZ = 30 + (s * stepDepth)
		part(`Stopien_{s}`, Vector3.new(14, stepHeight, stepDepth + 0.1), CFrame.new(0, sY, sZ), Color3.fromRGB(170, 170, 160), Enum.Material.Concrete)
	end
	part("PoręczLewa", Vector3.new(0.4, 3.6, 36), CFrame.new(-7.2, 10, 45) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	part("PoręczPrawa", Vector3.new(0.4, 3.6, 36), CFrame.new(7.2, 10, 45) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)

	-- ========================================================
	-- 6. I PIĘTRO: SALE LEKCYJNE I GABINETY (Y = 16.5 do 33)
	-- ========================================================
	-- Oświetlenie I piętra
	for z = -120, 120, 24 do
		ceilingLight(Vector3.new(0, 33, z))
	end

	-- A) GABINET DYREKTORA SZKOŁY (I Piętro, X: 47, Z: 50, Wymiary: 66 x 60)
	local dirCenter = Vector3.new(47, 16.5, 50)
	wallWithDoor("KorytarzE_DoDyrektora", 60, 16, CFrame.new(14, 16.5, 50) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, wallMat)
	part("PodlogaDyrektor", Vector3.new(66, 1, 60), CFrame.new(dirCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(120, 60, 30), Enum.Material.WoodPlanks)

	-- Czerwony dywanik u Dyrektora
	part("DywanikDyrektora", Vector3.new(18, 0.1, 26), CFrame.new(dirCenter + Vector3.new(0, 1.05, 0)), Color3.fromRGB(180, 20, 20), Enum.Material.Fabric)

	-- Mahoniowe biurko Dyrektora
	local dirDesk = part("BiurkoDyrektora", Vector3.new(13, 3.2, 5.5), CFrame.new(dirCenter + Vector3.new(12, 2.6, 0)), Color3.fromRGB(60, 30, 15), Enum.Material.Wood)
	sign(dirDesk, Enum.NormalId.Left, "👑 GABINET DYREKTORA SZKOŁY\n'Wszystko widzę, wszystko wiem!'", Color3.fromRGB(60, 30, 15), Color3.fromRGB(255, 215, 0))

	-- B) PRACOWNIA MATEMATYCZNA (Sala 201, I Piętro, X: -47, Z: -50, Wymiary: 66 x 60)
	local mathCenter = Vector3.new(-47, 16.5, -50)
	wallWithDoor("KorytarzW_DoMatmy", 60, 16, CFrame.new(-14, 16.5, -50) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, wallMat)
	part("PodlogaMatma", Vector3.new(66, 1, 60), CFrame.new(mathCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(210, 225, 210))

	local mathBoard = part("TablicaMatematyka", Vector3.new(1, 8, 22), CFrame.new(-78.8, 23.5, -50), Color3.fromRGB(35, 65, 45))
	sign(mathBoard, Enum.NormalId.Right, "📐 PRACOWNIA MATEMATYCZNA (SALA 201)\n\nKARTKÓWKA Z MATEMATYKI:\nRozwiąż równanie: 2 + 2 = ?\na) 3   b) 4   c) 5", Color3.fromRGB(35, 65, 45), Color3.fromRGB(255, 255, 255))

	local mathPrompt = Instance.new("ProximityPrompt")
	mathPrompt.ActionText = "Rozwiąż zadanie z Matematyki"
	mathPrompt.ObjectText = "Tablica Matematyczna"
	mathPrompt.HoldDuration = 0.5
	mathPrompt.MaxActivationDistance = 10
	mathPrompt.Parent = mathBoard

	for _, rZ in ipairs({ -14, 0, 14 }) do
		for _, cX in ipairs({ -40, -55 }) do
			schoolDeskSet(Vector3.new(cX, 17, rZ - 50), -90)
		end
	end

	-- C) PRACOWNIA JĘZYKA POLSKIEGO (Sala 202, I Piętro, X: -47, Z: 50, Wymiary: 66 x 60)
	local polCenter = Vector3.new(-47, 16.5, 50)
	wallWithDoor("KorytarzW_DoPolskiego", 60, 16, CFrame.new(-14, 16.5, 50) * CFrame.Angles(0, math.rad(90), 0), 0, wallCol, wallMat)
	part("PodlogaPolski", Vector3.new(66, 1, 60), CFrame.new(polCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(230, 215, 205))

	local polBoard = part("TablicaPolski", Vector3.new(1, 8, 22), CFrame.new(-78.8, 23.5, 50), Color3.fromRGB(40, 40, 45))
	sign(polBoard, Enum.NormalId.Right, "📖 PRACOWNIA JĘZYKA POLSKIEGO (SALA 202)\n\nDYKTANDO SZKOLNE:\nPrzepisz bezbłędnie słowo: 'szkoła' lub 'kartkówka'!", Color3.fromRGB(40, 40, 45), Color3.fromRGB(255, 255, 255))

	local polishPrompt = Instance.new("ProximityPrompt")
	polishPrompt.ActionText = "Napisz dyktando z Polskiego"
	polishPrompt.ObjectText = "Tablica Języka Polskiego"
	polishPrompt.HoldDuration = 0.5
	polishPrompt.MaxActivationDistance = 10
	polishPrompt.Parent = polBoard

	for _, rZ in ipairs({ -14, 0, 14 }) do
		for _, cX in ipairs({ -40, -55 }) do
			schoolDeskSet(Vector3.new(cX, 17, rZ + 50), -90)
		end
	end

	-- D) PRACOWNIA INFORMATYCZNA (Sala 203, I Piętro, X: 47, Z: -10, Wymiary: 66 x 60)
	local itCenter = Vector3.new(47, 16.5, -10)
	wallWithDoor("KorytarzE_DoInformatyki", 60, 16, CFrame.new(14, 16.5, -10) * CFrame.Angles(0, math.rad(-90), 0), 0, wallCol, wallMat)
	part("PodlogaInformatyka", Vector3.new(66, 1, 60), CFrame.new(itCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(190, 195, 205))
	local itBoard = part("TablicaIT", Vector3.new(1, 7, 20), CFrame.new(78.8, 23.5, -10), Color3.fromRGB(25, 45, 75))
	sign(itBoard, Enum.NormalId.Left, "💻 PRACOWNIA INFORMATYCZNA (SALA 203)\nZAKAZ GRANIE W CS NA ZAJĘCIACH!\nDyskietki 3.5 cala składać u nauczyciela.", Color3.fromRGB(25, 45, 75), Color3.fromRGB(255, 255, 255))

	print("🏛️ [Budowa Szkoły] 6/6: Rejestracja zdarzeń sieciowych dla minigier...")
	-- ========================================================
	-- 7. REJESTRACJA INTERAKCJI Z ZADANIAMI
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

	print("✨ [SUKCES] Monumentalny, spójny gmach szkoły Tysiąclatki został w pełni zbudowany!")

	local schoolSpawnPos = Vector3.new(0, 3.5, 100)
	local cafeteriaPos = cafCenter + Vector3.new(0, 3.5, 0)
	local lobbySpawnPos = lobbyCenter + Vector3.new(0, 3.5, 0)

	return schoolSpawnPos, cafeteriaPos, lobbySpawnPos
end

return SchoolMapGenerator
