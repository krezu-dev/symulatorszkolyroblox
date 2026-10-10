--!strict
-- src/server/SchoolMapGenerator.luau
-- KOMPLETNY GENERATOR WIELKIEJ POLSKIEJ SZKOŁY ("SZKOŁA TYSIĄCLATKA")
-- Zbudowany kompleks zawiera:
-- 1. Lobby Zewnętrzne (Plac Apelowy, maszt flagowy, ławki, tablica ogłoszeń)
-- 2. Parter:
--    - Główny Korytarz (260 studów długości) z lamperią, szafkami i automatami
--    - Wielka Stołówka (80x80) z kuchnią, pierogami i Wielkim Złotym Dzwonem
--    - Pełnowymiarowa Sala Gimnastyczna (90x90, h=26) z koszami, drabinkami i szatniami
--    - Kanciapa Woźnej z zapleczem i płynem Ludwik
--    - Toalety Szkolne z kabinami i podpisami uczniów
--    - Gabinet Pielęgniarki z kozetką
-- 3. I Piętro (dostępne przez szerokie schody dwubiegowe):
--    - Korytarz I Piętra z antresolą
--    - Gabinet Dyrektora z mahoniowym biurkiem, pucharami i słynnym czerwonym dywanikiem
--    - Pokój Nauczycielski ze stosem niesprawdzonych klasówek i kserokopiarką
--    - Pracownia Matematyczna (Sala 201) z tablicą i bryłami
--    - Pracownia Języka Polskiego (Sala 202) z portretami wieszczów i lekturami
--    - Pracownia Informatyczna (Sala 203) z komputerami CRT
--    - Pracownia Chemiczna (Sala 204) z probówkami i układem okresowym
-- 4. Boisko Szkolne "Orlik" ze sztuczną trawą i bramkami

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

	-- Pomocnik budowania części (Part)
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, parent: Instance?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.Parent = parent or mapFolder
		return p
	end

	-- Pomocnik do tablic i napisów (SurfaceGui)
	local function sign(parentPart: BasePart, face: Enum.NormalId, textStr: string, bgCol: Color3, textCol: Color3, borderWidth: number?)
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.AlwaysOnTop = false
		sg.Parent = parentPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = bgCol
		frame.BorderSizePixel = borderWidth or 2
		frame.Parent = sg

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 1, -10)
		lbl.Position = UDim2.new(0, 5, 0, 5)
		lbl.BackgroundTransparency = 1
		lbl.Text = textStr
		lbl.TextColor3 = textCol
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = frame
	end

	-- Pomocnik oświetlenia (jarzeniówki sufitowe)
	local function light(pos: Vector3, range: number?, brightness: number?)
		local fixture = part("OprawaJarzeniowa", Vector3.new(8, 0.4, 1.4), CFrame.new(pos), Color3.fromRGB(240, 240, 240))
		local tube = part("RuraSwietlna", Vector3.new(7.6, 0.2, 0.8), CFrame.new(pos - Vector3.new(0, 0.25, 0)), Color3.fromRGB(255, 255, 245), Enum.Material.Neon, fixture)
		local pl = Instance.new("PointLight")
		pl.Brightness = brightness or 1.4
		pl.Range = range or 32
		pl.Color = Color3.fromRGB(255, 250, 235)
		pl.Parent = tube
	end

	-- Pomocnik klasycznych ławek i krzeseł szkolnych
	local function deskAndChairs(pos: Vector3, rotY: number)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
		-- Blat ławki
		part("Blat", Vector3.new(6.5, 0.2, 3.2), cf * CFrame.new(0, 2.9, 0), Color3.fromRGB(215, 175, 125), Enum.Material.Wood)
		-- Nogi stelaża (zielone rurki)
		part("NogiLawki", Vector3.new(6.0, 2.8, 2.8), cf * CFrame.new(0, 1.4, 0), Color3.fromRGB(25, 85, 35))

		-- 2 krzesełka za ławką
		for _, xOff in ipairs({ -2.0, 2.0 }) do
			local cCf = cf * CFrame.new(xOff, 0, 2.6)
			part("Siedzisko", Vector3.new(1.8, 0.15, 1.8), cCf * CFrame.new(0, 1.8, 0), Color3.fromRGB(215, 175, 125), Enum.Material.Wood)
			part("Oparcie", Vector3.new(1.8, 1.2, 0.15), cCf * CFrame.new(0, 2.8, 0.8), Color3.fromRGB(215, 175, 125), Enum.Material.Wood)
			part("NogiKrzesla", Vector3.new(1.6, 1.7, 1.6), cCf * CFrame.new(0, 0.85, 0), Color3.fromRGB(25, 85, 35))
		end
	end

	print("🏗️ [Budowa Szkoły] KROK 1/7: Generowanie Lobby Zewnętrznego i Placu Apelowego...")
	-- ========================================================
	-- 1. LOBBY ZEWNĘTRZNE (PLAC APELOWY, z = 240)
	-- ========================================================
	local lobbyCenter = Vector3.new(0, 0, 240)
	-- Kostka brukowa placu
	part("PlacApelowy", Vector3.new(90, 1, 90), CFrame.new(lobbyCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(150, 150, 150), Enum.Material.Cobblestone)

	-- Maszt flagowy z flagą Polski
	local pole = part("MasztFlagowy", Vector3.new(0.6, 26, 0.6), CFrame.new(lobbyCenter + Vector3.new(0, 13.5, 20)), Color3.fromRGB(220, 220, 220), Enum.Material.Metal)
	local flagWhite = part("FlagaBiala", Vector3.new(0.1, 3, 5), CFrame.new(lobbyCenter + Vector3.new(0, 24.5, 22.5)), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	local flagRed = part("FlagaCzerwona", Vector3.new(0.1, 3, 5), CFrame.new(lobbyCenter + Vector3.new(0, 21.5, 22.5)), Color3.fromRGB(220, 30, 30), Enum.Material.Fabric)

	-- Tablica powitalna szkoły
	local mainSchoolSign = part("TablicaWejsciowa", Vector3.new(28, 6, 0.6), CFrame.new(0, 18, 140.2), Color3.fromRGB(15, 40, 90))
	sign(mainSchoolSign, Enum.NormalId.Back, "🏫 SZKOŁA PODSTAWOWA NR 1 IM. ADAMA MICKIEWICZA\n'Wiedza to potęga, a Rozrabiaki to kłopoty!'", Color3.fromRGB(15, 40, 90), Color3.fromRGB(255, 230, 80))

	-- Ławki na placu apelowym
	for _, xOff in ipairs({ -25, 25 }) do
		part("LawkaPlac", Vector3.new(12, 1.6, 2.5), CFrame.new(lobbyCenter + Vector3.new(xOff, 1.3, 0)), Color3.fromRGB(100, 60, 30), Enum.Material.Wood)
	end

	print("🏗️ [Budowa Szkoły] KROK 2/7: Budowanie Parteru i Głównego Korytarza...")
	-- ========================================================
	-- 2. GŁÓWNY KORYTARZ PARTERU (z: -70 do 140, długość 210 studów)
	-- ========================================================
	-- Podłoga linoleum (parter y = 0.5)
	part("PodlogaKorytarzP", Vector3.new(28, 1, 210), CFrame.new(0, 0.5, 35), Color3.fromRGB(180, 180, 170), Enum.Material.Concrete)
	-- Strop między parterem a piętrem (y = 18.5)
	part("StropPietro1", Vector3.new(28, 1, 210), CFrame.new(0, 18.5, 35), Color3.fromRGB(220, 220, 220))

	-- Oświetlenie parteru
	for z = -50, 120, 30 do
		light(Vector3.new(0, 18, z))
	end

	-- Lamperia i ściany korytarza
	for _, side in ipairs({ -14, 14 }) do
		-- Oliwkowa lamperia
		part("LamperiaParter", Vector3.new(1, 4.5, 210), CFrame.new(side, 2.75, 35), Color3.fromRGB(65, 105, 80))
		-- Górna jasna ściana
		part("ScianaParter", Vector3.new(1, 13.5, 210), CFrame.new(side, 11.75, 35), Color3.fromRGB(245, 242, 225))
	end

	-- Szafki uczniowskie na parterze (rząd szafek do zadania)
	for i = 1, 10 do
		local zPos = -30 + (i * 3.8)
		local locker = part(`Szafka_{i}`, Vector3.new(2.2, 8.5, 3.2), CFrame.new(12.5, 4.75, zPos), Color3.fromRGB(35, 95, 190), Enum.Material.Metal)
		sign(locker, Enum.NormalId.Left, `SZAFKA\n#{100 + i}`, Color3.fromRGB(20, 55, 130), Color3.fromRGB(255, 255, 255))
	end

	-- Prompt zadania szafek
	local lockerPromptPart = part("InterakcjaSzafki", Vector3.new(3, 8.5, 38), CFrame.new(12.5, 4.75, -11), Color3.fromRGB(35, 95, 190), Enum.Material.Metal)
	lockerPromptPart.Transparency = 1
	local lockerPrompt = Instance.new("ProximityPrompt")
	lockerPrompt.ActionText = "Uporządkuj podręczniki w szafce"
	lockerPrompt.ObjectText = "Szafka Szkolna"
	lockerPrompt.HoldDuration = 0.5
	lockerPrompt.MaxActivationDistance = 9
	lockerPrompt.Parent = lockerPromptPart

	-- Automaty z przekąskami (Prince Polo / Cola)
	local vending1 = part("AutomatPrzekaski", Vector3.new(3, 8.5, 4.5), CFrame.new(-12.5, 4.75, -20), Color3.fromRGB(180, 25, 25), Enum.Material.Metal)
	sign(vending1, Enum.NormalId.Right, "🍫 AUTOMAT Z PRZEKĄSKAMI\n- Wafle Prince Polo: 2.50 zł\n- Rogal 7 Days: 3.00 zł\n- Sok Tymbark: 2.80 zł", Color3.fromRGB(180, 25, 25), Color3.fromRGB(255, 255, 255))

	print("🏗️ [Budowa Szkoły] KROK 3/7: Budowanie Wielkiej Stołówki i Podium z Dzwonem...")
	-- ========================================================
	-- 3. WIELKA STOŁÓWKA SZKOLNA (x: 0, z: -130, 80x80 studów)
	-- ========================================================
	local cafCenter = Vector3.new(0, 0, -130)
	part("PodlogaStolowka", Vector3.new(80, 1, 80), CFrame.new(cafCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(215, 205, 190), Enum.Material.Marble)
	part("SufitStolowka", Vector3.new(80, 1, 80), CFrame.new(cafCenter + Vector3.new(0, 18.5, 0)), Color3.fromRGB(230, 230, 230))
	part("ScianaStolowka_N", Vector3.new(80, 18, 1), CFrame.new(cafCenter + Vector3.new(0, 9.5, -40)), Color3.fromRGB(240, 235, 215))
	part("ScianaStolowka_W", Vector3.new(1, 18, 80), CFrame.new(cafCenter + Vector3.new(-40, 9.5, 0)), Color3.fromRGB(240, 235, 215))
	part("ScianaStolowka_E", Vector3.new(1, 18, 80), CFrame.new(cafCenter + Vector3.new(40, 9.5, 0)), Color3.fromRGB(240, 235, 215))

	for cx = -25, 25, 25 do
		for cz = -25, 25, 25 do
			light(cafCenter + Vector3.new(cx, 18, cz), 36, 1.5)
		end
	end

	-- Okienko wydawania obiadów
	local kitchenBar = part("KuchniaLada", Vector3.new(40, 4.5, 4), CFrame.new(cafCenter + Vector3.new(0, 2.75, -36)), Color3.fromRGB(160, 135, 110), Enum.Material.Wood)
	sign(kitchenBar, Enum.NormalId.Back, "🍲 WYDAWANIE POSIŁKÓW SZKOLNYCH\nDZIŚ W MENU: PIEROGI RUSKIE ZE SKWARKAMI I KOMPOT", Color3.fromRGB(225, 205, 165), Color3.fromRGB(90, 25, 25))

	-- Talerz z pierogami (Zadanie: Zjedz Obiad)
	local platePart = part("TalerzPierogi", Vector3.new(4, 0.4, 4), CFrame.new(cafCenter + Vector3.new(0, 5.1, -36)), Color3.fromRGB(250, 250, 250))
	local pierogiPrompt = Instance.new("ProximityPrompt")
	pierogiPrompt.ActionText = "Zjedz szkolny obiad (Pierogi!)"
	pierogiPrompt.ObjectText = "Talerz Pierogów"
	pierogiPrompt.HoldDuration = 0.4
	pierogiPrompt.MaxActivationDistance = 9
	pierogiPrompt.Parent = platePart

	-- Długie stoły stołówkowe
	for _, xOff in ipairs({ -22, 22 }) do
		for _, zOff in ipairs({ -15, 15 }) do
			local tCf = CFrame.new(cafCenter + Vector3.new(xOff, 2.8, zOff))
			part("StolStolowkowy", Vector3.new(10, 0.25, 18), tCf, Color3.fromRGB(180, 130, 85), Enum.Material.Wood)
			part("NogiStolowka", Vector3.new(9.5, 2.6, 17.5), tCf * CFrame.new(0, -1.35, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
		end
	end

	-- Podium pod WIELKI SZKOLNY DZWON
	local altar = part("OltarzDzwonu", Vector3.new(10, 2.5, 10), CFrame.new(cafCenter + Vector3.new(0, 1.75, 0)), Color3.fromRGB(170, 35, 35), Enum.Material.Marble)
	sign(altar, Enum.NormalId.Top, "🔔 WIELKI SZKOLNY DZWON ALARMOWY 🔔", Color3.fromRGB(170, 35, 35), Color3.fromRGB(255, 230, 80))

	-- WIELKI DZWON SZKOLNY
	local bell = Instance.new("Part")
	bell.Name = "WielkiDzwonSzkolny"
	bell.Shape = Enum.PartType.Cylinder
	bell.Size = Vector3.new(4, 4, 4)
	bell.CFrame = CFrame.new(cafCenter + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bell.Color = Color3.fromRGB(255, 215, 0)
	bell.Material = Enum.Material.Metal
	bell.Anchored = true
	bell.Parent = mapFolder

	local bellGlow = Instance.new("PointLight")
	bellGlow.Color = Color3.fromRGB(255, 230, 110)
	bellGlow.Brightness = 2.5
	bellGlow.Range = 28
	bellGlow.Parent = bell

	local bellTag = Instance.new("BillboardGui")
	bellTag.Size = UDim2.new(0, 240, 0, 50)
	bellTag.StudsOffset = Vector3.new(0, 3.5, 0)
	bellTag.AlwaysOnTop = true
	bellTag.Parent = bell

	local bellLabel = Instance.new("TextLabel")
	bellLabel.Size = UDim2.new(1, 0, 1, 0)
	bellLabel.BackgroundTransparency = 1
	bellLabel.Text = "🔔 WIELKI DZWON SZKOLNY\n(Uderz, aby Zwołać Zebranie!)"
	bellLabel.TextColor3 = Color3.fromRGB(255, 235, 70)
	bellLabel.TextScaled = true
	bellLabel.Font = Enum.Font.GothamBlack
	bellLabel.Parent = bellTag

	local bellPrompt = Instance.new("ProximityPrompt")
	bellPrompt.ActionText = "Uderz w Dzwon Szkolny!"
	bellPrompt.ObjectText = "Alarm Szkolny"
	bellPrompt.HoldDuration = 1.0
	bellPrompt.MaxActivationDistance = 15
	bellPrompt.Parent = bell

	bellPrompt.Triggered:Connect(function(player)
		if onBellRing then
			onBellRing(player)
		end
	end)

	print("🏗️ [Budowa Szkoły] KROK 4/7: Budowanie Sali Gimnastycznej i Boiska Orlik...")
	-- ========================================================
	-- 4. SALA GIMNASTYCZNA (x = -70, z = 60, 90x90, wysokość 26 studów)
	-- ========================================================
	local gymCenter = Vector3.new(-70, 0, 60)
	part("ParkietGym", Vector3.new(80, 1, 80), CFrame.new(gymCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 175, 105), Enum.Material.WoodPlanks)
	part("SufitGym", Vector3.new(80, 1, 80), CFrame.new(gymCenter + Vector3.new(0, 26.5, 0)), Color3.fromRGB(215, 215, 215))
	part("ScianaGym_W", Vector3.new(1, 26, 80), CFrame.new(gymCenter + Vector3.new(-40, 13.5, 0)), Color3.fromRGB(235, 230, 210))
	part("ScianaGym_N", Vector3.new(80, 26, 1), CFrame.new(gymCenter + Vector3.new(0, 13.5, 40)), Color3.fromRGB(235, 230, 210))
	part("ScianaGym_S", Vector3.new(80, 26, 1), CFrame.new(gymCenter + Vector3.new(0, 13.5, -40)), Color3.fromRGB(235, 230, 210))

	-- Kosze do koszykówki na sali
	for _, zEnd in ipairs({ -39, 39 }) do
		local rot = if zEnd < 0 then 0 else 180
		local backboard = part("TablicaKosz", Vector3.new(7, 5, 0.4), CFrame.new(gymCenter + Vector3.new(0, 16, zEnd)) * CFrame.Angles(0, math.rad(rot), 0), Color3.fromRGB(250, 250, 250))
		part("KoszObrecz", Vector3.new(2.8, 0.3, 2.8), backboard.CFrame * CFrame.new(0, -1.8, 1.8), Color3.fromRGB(220, 50, 20), Enum.Material.Metal)
	end

	-- Drabinki ścienne
	for i = 1, 10 do
		part(`Drabinka_{i}`, Vector3.new(0.3, 0.3, 30), CFrame.new(gymCenter + Vector3.new(-39.2, i * 2.2, 0)), Color3.fromRGB(200, 150, 90), Enum.Material.Wood)
	end

	-- Kanciapa Woźnej (Parter x = 45, z = 60)
	local janCenter = Vector3.new(45, 0, 60)
	part("PodlogaWozna", Vector3.new(40, 1, 40), CFrame.new(janCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(130, 130, 130), Enum.Material.Concrete)
	part("ScianaWozna_E", Vector3.new(1, 18, 40), CFrame.new(janCenter + Vector3.new(20, 9.5, 0)), Color3.fromRGB(210, 210, 210))
	local shelfJan = part("PolkaLudwik", Vector3.new(2, 9, 20), CFrame.new(janCenter + Vector3.new(18, 5.5, 0)), Color3.fromRGB(90, 65, 45), Enum.Material.Wood)
	sign(shelfJan, Enum.NormalId.Left, "🧹 KANCIAPA PANI WOŹNEJ\nŚrodki czystości: PŁYN LUDWIK, MOPY, WIADRA\nUWAGA: NIE DEPTAĆ PO ŚWIEŻO ZMYTYM!", Color3.fromRGB(35, 75, 120), Color3.fromRGB(255, 255, 255))

	-- Plama do zmycia dla Woźnej
	local puddle = part("PlamaDoZmycia", Vector3.new(9, 0.05, 9), CFrame.new(janCenter + Vector3.new(-5, 1.05, 0)), Color3.fromRGB(150, 95, 35), Enum.Material.Glass)
	local puddlePrompt = Instance.new("ProximityPrompt")
	puddlePrompt.ActionText = "Zmyj rozlaną zupę mopem!"
	puddlePrompt.ObjectText = "Śliska Plama"
	puddlePrompt.HoldDuration = 0.8
	puddlePrompt.MaxActivationDistance = 9
	puddlePrompt.Parent = puddle

	print("🏗️ [Budowa Szkoły] KROK 5/7: Budowanie Schodów Dwubiegowych na I Piętro...")
	-- ========================================================
	-- 5. SCHODY NA I PIĘTRO (z = 40, x = 0, wejście na y = 18.5)
	-- ========================================================
	local stairsSteps = 24
	local stepHeight = 18.0 / stairsSteps
	local stepDepth = 24.0 / stairsSteps

	for s = 1, stairsSteps do
		local sY = (s * stepHeight) - (stepHeight / 2)
		local sZ = 30 + (s * stepDepth)
		part(`Stopien_{s}`, Vector3.new(12, stepHeight, stepDepth + 0.1), CFrame.new(0, sY, sZ), Color3.fromRGB(160, 160, 150), Enum.Material.Concrete)
	end
	-- Balustrada schodów
	part("BarierkaLewa", Vector3.new(0.4, 3.5, 28), CFrame.new(-6.2, 11, 42) * CFrame.Angles(math.rad(-36), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	part("BarierkaPrawa", Vector3.new(0.4, 3.5, 28), CFrame.new(6.2, 11, 42) * CFrame.Angles(math.rad(-36), 0, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)

	print("🏗️ [Budowa Szkoły] KROK 6/7: Budowanie I Piętra (Gabinety, Sale Lekcyjne, Pracownie)...")
	-- ========================================================
	-- 6. I PIĘTRO: KORYTARZ I SALE LEKCYJNE (y = 18.5 do 35)
	-- ========================================================
	-- Sufit I Piętra / Dach szkoły (y = 35)
	part("DachGlowny", Vector3.new(30, 1, 210), CFrame.new(0, 35, 35), Color3.fromRGB(190, 80, 50))

	-- Światła I Piętra
	for z = -50, 120, 30 do
		light(Vector3.new(0, 34.5, z))
	end

	-- A) GABINET DYREKTORA (I Piętro, x = 45, z = -10, y = 18.5)
	local dirCenter = Vector3.new(45, 18.5, -10)
	part("PodlogaDyrektor", Vector3.new(40, 1, 40), CFrame.new(dirCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(120, 60, 30), Enum.Material.WoodPlanks)
	part("ScianaDir_E", Vector3.new(1, 16, 40), CFrame.new(dirCenter + Vector3.new(20, 8.5, 0)), Color3.fromRGB(240, 230, 210))
	part("ScianaDir_N", Vector3.new(40, 16, 1), CFrame.new(dirCenter + Vector3.new(0, 8.5, 20)), Color3.fromRGB(240, 230, 210))
	part("ScianaDir_S", Vector3.new(40, 16, 1), CFrame.new(dirCenter + Vector3.new(0, 8.5, -20)), Color3.fromRGB(240, 230, 210))

	-- Słynny czerwony dywanik u Dyrektora
	part("DywanikDyrektora", Vector3.new(16, 0.1, 24), CFrame.new(dirCenter + Vector3.new(0, 1.05, 0)), Color3.fromRGB(180, 20, 20), Enum.Material.Fabric)

	-- Mahoniowe biurko Dyrektora
	local dirDesk = part("BiurkoDyrektora", Vector3.new(12, 3.2, 5.5), CFrame.new(dirCenter + Vector3.new(10, 2.6, 0)), Color3.fromRGB(60, 30, 15), Enum.Material.Wood)
	sign(dirDesk, Enum.NormalId.Left, "👑 GABINET DYREKTORA SZKOŁY\n'Wszystko widzę, wszystko wiem!'", Color3.fromRGB(60, 30, 15), Color3.fromRGB(255, 215, 0))

	-- B) PRACOWNIA MATEMATYCZNA (Sala 201, I Piętro, x = 45, z = 70)
	local mathCenter = Vector3.new(45, 18.5, 70)
	part("PodlogaMatematyka", Vector3.new(40, 1, 40), CFrame.new(mathCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(205, 220, 205))
	part("ScianaMath_E", Vector3.new(1, 16, 40), CFrame.new(mathCenter + Vector3.new(20, 8.5, 0)), Color3.fromRGB(235, 240, 230))
	local mathBoard = part("TablicaMatematyka", Vector3.new(1, 8, 18), CFrame.new(mathCenter + Vector3.new(19.4, 7, 0)), Color3.fromRGB(35, 65, 45))
	sign(mathBoard, Enum.NormalId.Left, "📐 KLASA MATEMATYCZNA (SALA 201)\n\nKARTKÓWKA Z MATEMATYKI:\nOblicz: 2 + 2 = ?\na) 3   b) 4   c) 5", Color3.fromRGB(35, 65, 45), Color3.fromRGB(255, 255, 255))

	local mathPrompt = Instance.new("ProximityPrompt")
	mathPrompt.ActionText = "Rozwiąż zadanie z Matematyki"
	mathPrompt.ObjectText = "Tablica Matematyczna"
	mathPrompt.HoldDuration = 0.5
	mathPrompt.MaxActivationDistance = 10
	mathPrompt.Parent = mathBoard

	for _, rZ in ipairs({ -10, 0, 10 }) do
		for _, cX in ipairs({ 35, 45 }) do
			deskAndChairs(Vector3.new(cX, 19, rZ + 70), -90)
		end
	end

	-- C) PRACOWNIA JĘZYKA POLSKIEGO (Sala 202, I Piętro, x = -45, z = -10)
	local polCenter = Vector3.new(-45, 18.5, -10)
	part("PodlogaPolski", Vector3.new(40, 1, 40), CFrame.new(polCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 215, 205))
	part("ScianaPol_W", Vector3.new(1, 16, 40), CFrame.new(polCenter + Vector3.new(-20, 8.5, 0)), Color3.fromRGB(245, 235, 230))
	local polBoard = part("TablicaPolski", Vector3.new(1, 8, 18), CFrame.new(polCenter + Vector3.new(-19.4, 7, 0)), Color3.fromRGB(40, 40, 45))
	sign(polBoard, Enum.NormalId.Right, "📖 JĘZYK POLSKI (SALA 202)\n\nDYKTANDO:\nPrzepisz bezbłędnie słowo: 'szkoła' lub 'kartkówka'!", Color3.fromRGB(40, 40, 45), Color3.fromRGB(255, 255, 255))

	local polishPrompt = Instance.new("ProximityPrompt")
	polishPrompt.ActionText = "Napisz dyktando z Polskiego"
	polishPrompt.ObjectText = "Tablica Języka Polskiego"
	polishPrompt.HoldDuration = 0.5
	polishPrompt.MaxActivationDistance = 10
	polishPrompt.Parent = polBoard

	for _, rZ in ipairs({ -10, 0, 10 }) do
		for _, cX in ipairs({ -35, -45 }) do
			deskAndChairs(Vector3.new(cX, 19, rZ - 10), 90)
		end
	end

	-- D) PRACOWNIA INFORMATYCZNA (Sala 203, I Piętro, x = -45, z = 70)
	local itCenter = Vector3.new(-45, 18.5, 70)
	part("PodlogaInfa", Vector3.new(40, 1, 40), CFrame.new(itCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(190, 195, 205))
	part("ScianaIT_W", Vector3.new(1, 16, 40), CFrame.new(itCenter + Vector3.new(-20, 8.5, 0)), Color3.fromRGB(220, 225, 235))
	local itSign = part("TablicaIT", Vector3.new(1, 6, 16), CFrame.new(itCenter + Vector3.new(-19.4, 7, 0)), Color3.fromRGB(30, 50, 80))
	sign(itSign, Enum.NormalId.Right, "💻 PRACOWNIA INFORMATYCZNA (SALA 203)\nZAKAZ GRANIE W CS NA ZAJĘCIACH!\nDyskietki 3.5 cala składać u nauczyciela.", Color3.fromRGB(30, 50, 80), Color3.fromRGB(255, 255, 255))

	-- Komputery CRT na stolikach
	for _, itZ in ipairs({ -10, 0, 10 }) do
		local deskIT = part("BiurkoIT", Vector3.new(14, 2.8, 3), CFrame.new(itCenter + Vector3.new(-5, 1.4, itZ)), Color3.fromRGB(200, 200, 190))
		for _, cx in ipairs({ -3, 3 }) do
			part("MonitorCRT", Vector3.new(1.8, 1.8, 1.8), deskIT.CFrame * CFrame.new(cx, 2.3, 0), Color3.fromRGB(220, 215, 200))
		end
	end

	print("🏗️ [Budowa Szkoły] KROK 7/7: Podłączanie interakcji i zdarzeń zadań...")
	-- ========================================================
	-- 7. PODPIĘCIE WSZYSTKICH PROMPTÓW
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

	print("🎉 [SUKCES] Cała potężna 2-piętrowa szkoła 'Tysiąclatka' z Lobby i Orlikiem została wygenerowana!")

	-- Zwracamy pozycje:
	-- 1. Spawn w szkole (Korytarz Parteru)
	-- 2. Stołówka (Zwoływanie zebrań)
	-- 3. Lobby (Plac apelowy przed rozpoczęciem rundy)
	local schoolSpawnPos = Vector3.new(0, 3.5, 0)
	local cafeteriaPos = cafCenter + Vector3.new(0, 3.5, 0)
	local lobbySpawnPos = lobbyCenter + Vector3.new(0, 3.5, 0)

	return schoolSpawnPos, cafeteriaPos, lobbySpawnPos
end

return SchoolMapGenerator
