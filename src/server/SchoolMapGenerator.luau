--!strict
-- src/server/SchoolMapGenerator.luau
-- Kompletny generator mapy szkoły "Szkolny Detektyw"
-- Buduje pełną, szczegółową szkołę z polskim klimatem i memami:
-- 1. Korytarz Główny z szafkami, lamperią i tablicami ogłoszeń
-- 2. Stołówka z okienkiem wydawania posiłków, talerzami pierogów i Wielkim Dzwonem
-- 3. Klasa Matematyczna (Sala 101) z tablicą i ławkami
-- 4. Klasa Języka Polskiego (Sala 102) z lekturami i portretem Mickiewicza
-- 5. Gabinet Dyrektora ze słynnym dywanikiem i pucharami
-- 6. Kanciapa Woźnej ze środkami czystości i mopami
-- 7. Sala Gimnastyczna z parkietem, drabinkami i koszem
-- 8. Toalety Szkolne

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local SchoolMapGenerator = {}

function SchoolMapGenerator.setupMap(onBellRing: (Player) -> ()): (Vector3, Vector3)
	local mapFolder = workspace:FindFirstChild("SchoolMap") :: Folder?
	if mapFolder then
		mapFolder:ClearAllChildren()
	else
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "SchoolMap"
		mapFolder.Parent = workspace
	end

	-- Pomocnik do tworzenia części
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

	-- Pomocnik do tabliczek i napisów (SurfaceGui)
	local function sign(parentPart: BasePart, face: Enum.NormalId, textStr: string, bgCol: Color3, textCol: Color3, fontSize: number?)
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.AlwaysOnTop = false
		sg.Parent = parentPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = bgCol
		frame.BorderSizePixel = 2
		frame.Parent = sg

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -8, 1, -8)
		lbl.Position = UDim2.new(0, 4, 0, 4)
		lbl.BackgroundTransparency = 1
		lbl.Text = textStr
		lbl.TextColor3 = textCol
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = frame
	end

	-- Pomocnik do jarzeniówek / oświetlenia
	local function ceilingLight(pos: Vector3)
		local fixture = part("LampaJarzeniowa", Vector3.new(6, 0.4, 1.2), CFrame.new(pos), Color3.fromRGB(240, 240, 240))
		local tube = part("RuraSwietlna", Vector3.new(5.6, 0.2, 0.6), CFrame.new(pos - Vector3.new(0, 0.2, 0)), Color3.fromRGB(255, 255, 245), Enum.Material.Neon, fixture)
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.2
		pl.Range = 26
		pl.Color = Color3.fromRGB(255, 250, 235)
		pl.Parent = tube
	end

	-- Pomocnik do ławek i krzeseł szkolnych
	local function schoolDeskAndChair(pos: Vector3, rotY: number)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)

		-- Blat ławki
		part("Blat", Vector3.new(6, 0.2, 3), cf * CFrame.new(0, 2.8, 0), Color3.fromRGB(210, 175, 125), Enum.Material.Wood)
		-- Nogi ławki (zielone rurki)
		part("NogiLawki", Vector3.new(5.6, 2.7, 2.6), cf * CFrame.new(0, 1.35, 0), Color3.fromRGB(30, 90, 40))

		-- 2 Krzesła za ławką
		for _, xOffset in ipairs({ -1.8, 1.8 }) do
			local chairCf = cf * CFrame.new(xOffset, 0, 2.4)
			-- Siedzisko
			part("Siedzisko", Vector3.new(1.8, 0.15, 1.8), chairCf * CFrame.new(0, 1.8, 0), Color3.fromRGB(210, 175, 125), Enum.Material.Wood)
			-- Oparcie
			part("Oparcie", Vector3.new(1.8, 1.2, 0.15), chairCf * CFrame.new(0, 2.8, 0.8), Color3.fromRGB(210, 175, 125), Enum.Material.Wood)
			-- Nogi krzesła
			part("NogiKrzesla", Vector3.new(1.6, 1.7, 1.6), chairCf * CFrame.new(0, 0.85, 0), Color3.fromRGB(30, 90, 40))
		end
	end

	print("[Mapa] Generowanie Korytarza Głównego...")
	-- ========================================================
	-- 1. KORYTARZ GŁÓWNY (x: 0, z: -80 do 80, szerokość 24, wysokość 16)
	-- ========================================================
	-- Podłoga korytarza (linoleum szkolne)
	part("PodlogaKorytarz", Vector3.new(24, 1, 160), CFrame.new(0, 0.5, 0), Color3.fromRGB(185, 185, 175), Enum.Material.Concrete)
	-- Sufit korytarza
	part("SufitKorytarz", Vector3.new(24, 1, 160), CFrame.new(0, 16.5, 0), Color3.fromRGB(230, 230, 230))

	-- Światła na korytarzu
	for z = -60, 60, 30 do
		ceilingLight(Vector3.new(0, 16, z))
	end

	-- Lamperia i ściany boczne korytarza
	-- Ściana Lewa (x = -12) i Prawa (x = 12) z drzwiami do sal
	local function hallwayWall(x: number, faceNormal: Enum.NormalId)
		-- Dolna lamperia (olejna zielona/oliwkowa - klasyk polskiej szkoły)
		part("Lamperia", Vector3.new(1, 4, 160), CFrame.new(x, 2.5, 0), Color3.fromRGB(70, 110, 85))
		-- Górna ściana kremowa
		part("ScianaGorna", Vector3.new(1, 10, 160), CFrame.new(x, 9.5, 0), Color3.fromRGB(240, 238, 220))
	end
	hallwayWall(-12, Enum.NormalId.Right)
	hallwayWall(12, Enum.NormalId.Left)

	-- Tablica ogłoszeń na korytarzu
	local noticeBoard = part("TablicaOgloszen", Vector3.new(0.4, 5, 12), CFrame.new(-11.4, 7, 0), Color3.fromRGB(160, 120, 70), Enum.Material.Wood)
	sign(noticeBoard, Enum.NormalId.Right, "📌 OGŁOSZENIA SZKOLNE\n1. Zakaz biegania po korytarzu!\n2. Zmiana obuwia obowiązkowa.\n3. Szczęśliwy numerek dziś: 17!", Color3.fromRGB(255, 250, 230), Color3.fromRGB(20, 20, 20))

	-- Rząd szafek szkolnych (zadanie z szafkami)
	for i = 1, 6 do
		local zPos = -35 + (i * 3.5)
		local locker = part(`Szafka_{i}`, Vector3.new(2, 8, 3), CFrame.new(10.5, 4.5, zPos), Color3.fromRGB(30, 90, 180), Enum.Material.Metal)
		sign(locker, Enum.NormalId.Left, `SZAFKA\n#{100 + i}`, Color3.fromRGB(20, 50, 120), Color3.fromRGB(255, 255, 255))
	end

	-- Prompt zadania szafek na korytarzu
	local lockersPromptPart = part("InterakcjaSzafki", Vector3.new(3, 8, 22), CFrame.new(10.5, 4.5, -23), Color3.fromRGB(30, 90, 180), Enum.Material.Metal)
	lockersPromptPart.Transparency = 1
	local lockerPrompt = Instance.new("ProximityPrompt")
	lockerPrompt.ActionText = "Uporządkuj podręczniki w szafce"
	lockerPrompt.ObjectText = "Szafka Szkolna"
	lockerPrompt.HoldDuration = 0.5
	lockerPrompt.MaxActivationDistance = 9
	lockerPrompt.Parent = lockersPromptPart

	-- ========================================================
	-- 2. STOŁÓWKA SZKOLNA (Kafeteria - Spotkania i Głosowanie)
	-- Położenie: z = -110, szerokość 60, długość 60, wysokość 16
	-- ========================================================
	print("[Mapa] Generowanie Stołówki Szkolnej i Wielkiego Dzwonu...")
	local cafCenter = Vector3.new(0, 0, -110)
	-- Podłoga kafle stołówkowe
	part("PodlogaStolowka", Vector3.new(60, 1, 60), CFrame.new(cafCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(215, 205, 190), Enum.Material.Marble)
	part("SufitStolowka", Vector3.new(60, 1, 60), CFrame.new(cafCenter + Vector3.new(0, 16.5, 0)), Color3.fromRGB(230, 230, 230))

	-- Ściany stołówki
	part("ScianaStolowka_N", Vector3.new(60, 16, 1), CFrame.new(cafCenter + Vector3.new(0, 8.5, -30)), Color3.fromRGB(240, 235, 215))
	part("ScianaStolowka_W", Vector3.new(1, 16, 60), CFrame.new(cafCenter + Vector3.new(-30, 8.5, 0)), Color3.fromRGB(240, 235, 215))
	part("ScianaStolowka_E", Vector3.new(1, 16, 60), CFrame.new(cafCenter + Vector3.new(30, 8.5, 0)), Color3.fromRGB(240, 235, 215))

	-- Okienko wydawania obiadów
	local kitchenWall = part("KuchniaLada", Vector3.new(30, 4, 3), CFrame.new(cafCenter + Vector3.new(0, 2.5, -27)), Color3.fromRGB(160, 140, 120), Enum.Material.Wood)
	sign(kitchenWall, Enum.NormalId.Back, "🍲 WYDAWANIE OBIADÓW\nDZIŚ W MENU: PIEROGI RUSKIE Ze Skwarkami", Color3.fromRGB(220, 200, 160), Color3.fromRGB(80, 20, 20))

	-- Talerz z pierogami (Zadanie: Zjedz Obiad)
	local platePart = part("TalerzPierogow", Vector3.new(3, 0.4, 3), CFrame.new(cafCenter + Vector3.new(0, 4.7, -27)), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic)
	local pierogiPrompt = Instance.new("ProximityPrompt")
	pierogiPrompt.ActionText = "Zjedz szkolny obiad (Pierogi!)"
	pierogiPrompt.ObjectText = "Talerz Pierogów"
	pierogiPrompt.HoldDuration = 0.4
	pierogiPrompt.MaxActivationDistance = 8
	pierogiPrompt.Parent = platePart

	-- Stoły stołówkowe dookoła sali
	for _, xOff in ipairs({ -16, 16 }) do
		for _, zOff in ipairs({ -10, 12 }) do
			local tableCf = CFrame.new(cafCenter + Vector3.new(xOff, 2.5, zOff))
			part("StolStolowkowy", Vector3.new(8, 0.2, 14), tableCf, Color3.fromRGB(170, 120, 80), Enum.Material.Wood)
			part("NogiStolu", Vector3.new(7.6, 2.4, 13.6), tableCf * CFrame.new(0, -1.2, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
		end
	end

	-- Centralny postument pod WIELKI SZKOLNY DZWON
	local altar = part("OltarzDzwonu", Vector3.new(8, 2, 8), CFrame.new(cafCenter + Vector3.new(0, 1.5, 0)), Color3.fromRGB(180, 50, 50), Enum.Material.Marble)
	sign(altar, Enum.NormalId.Top, "🔔 WIELKI SZKOLNY DZWON 🔔", Color3.fromRGB(180, 50, 50), Color3.fromRGB(255, 230, 80))

	-- WIELKI SZKOLNY DZWON
	local bell = Instance.new("Part")
	bell.Name = "WielkiDzwonSzkolny"
	bell.Shape = Enum.PartType.Cylinder
	bell.Size = Vector3.new(3.5, 3.5, 3.5)
	bell.CFrame = CFrame.new(cafCenter + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bell.Color = Color3.fromRGB(255, 215, 0) -- Złoto
	bell.Material = Enum.Material.Metal
	bell.Anchored = true
	bell.Parent = mapFolder

	local bellGlow = Instance.new("PointLight")
	bellGlow.Color = Color3.fromRGB(255, 220, 100)
	bellGlow.Brightness = 2
	bellGlow.Range = 20
	bellGlow.Parent = bell

	local bellTag = Instance.new("BillboardGui")
	bellTag.Size = UDim2.new(0, 220, 0, 45)
	bellTag.StudsOffset = Vector3.new(0, 3, 0)
	bellTag.AlwaysOnTop = true
	bellTag.Parent = bell

	local bellLabel = Instance.new("TextLabel")
	bellLabel.Size = UDim2.new(1, 0, 1, 0)
	bellLabel.BackgroundTransparency = 1
	bellLabel.Text = "🔔 WIELKI DZWON SZKOLNY\n(Zwołaj Zebranie!)"
	bellLabel.TextColor3 = Color3.fromRGB(255, 235, 70)
	bellLabel.TextScaled = true
	bellLabel.Font = Enum.Font.GothamBlack
	bellLabel.Parent = bellTag

	local bellPrompt = Instance.new("ProximityPrompt")
	bellPrompt.ActionText = "Uderz w Dzwon Szkolny!"
	bellPrompt.ObjectText = "Alarm Szkolny"
	bellPrompt.HoldDuration = 1.0
	bellPrompt.MaxActivationDistance = 14
	bellPrompt.Parent = bell

	bellPrompt.Triggered:Connect(function(player)
		if onBellRing then
			onBellRing(player)
		end
	end)

	-- ========================================================
	-- 3. SALA 101: KLASA MATEMATYCZNA (x = 35, z = 30)
	-- ========================================================
	print("[Mapa] Generowanie Klasy Matematycznej (Sala 101)...")
	local mathCenter = Vector3.new(35, 0, 30)
	part("PodlogaMatematyka", Vector3.new(44, 1, 38), CFrame.new(mathCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(200, 215, 200))
	part("SufitMatematyka", Vector3.new(44, 1, 38), CFrame.new(mathCenter + Vector3.new(0, 16.5, 0)), Color3.fromRGB(230, 230, 230))
	part("ScianaMath_E", Vector3.new(1, 16, 38), CFrame.new(mathCenter + Vector3.new(22, 8.5, 0)), Color3.fromRGB(235, 240, 230))
	part("ScianaMath_N", Vector3.new(44, 16, 1), CFrame.new(mathCenter + Vector3.new(0, 8.5, 19)), Color3.fromRGB(235, 240, 230))
	part("ScianaMath_S", Vector3.new(44, 16, 1), CFrame.new(mathCenter + Vector3.new(0, 8.5, -19)), Color3.fromRGB(235, 240, 230))

	-- Tablica matematyczna z zadaniem
	local mathBoard = part("TablicaMatematyka", Vector3.new(1, 8, 18), CFrame.new(mathCenter + Vector3.new(21.4, 7, 0)), Color3.fromRGB(35, 65, 45))
	sign(mathBoard, Enum.NormalId.Left, "📐 KLASA MATEMATYCZNA (SALA 101)\n\nKARTKÓWKA Z MATEMATYKI:\nOblicz: 2 + 2 = ?\na) 3   b) 4   c) 5", Color3.fromRGB(35, 65, 45), Color3.fromRGB(255, 255, 255))

	local mathPrompt = Instance.new("ProximityPrompt")
	mathPrompt.ActionText = "Rozwiąż zadanie z Matematyki"
	mathPrompt.ObjectText = "Tablica Matematyczna"
	mathPrompt.HoldDuration = 0.5
	mathPrompt.MaxActivationDistance = 10
	mathPrompt.Parent = mathBoard

	-- Ławki w klasie matematycznej
	for _, rowZ in ipairs({ -10, 0, 10 }) do
		for _, colX in ipairs({ 24, 34 }) do
			schoolDeskAndChair(Vector3.new(colX, 0.5, rowZ + 30), -90)
		end
	end

	-- ========================================================
	-- 4. SALA 102: KLASA JĘZYKA POLSKIEGO (x = 35, z = -30)
	-- ========================================================
	print("[Mapa] Generowanie Klasy Języka Polskiego (Sala 102)...")
	local polCenter = Vector3.new(35, 0, -30)
	part("PodlogaPolski", Vector3.new(44, 1, 38), CFrame.new(polCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 215, 205))
	part("SufitPolski", Vector3.new(44, 1, 38), CFrame.new(polCenter + Vector3.new(0, 16.5, 0)), Color3.fromRGB(230, 230, 230))
	part("ScianaPol_E", Vector3.new(1, 16, 38), CFrame.new(polCenter + Vector3.new(22, 8.5, 0)), Color3.fromRGB(245, 235, 230))
	part("ScianaPol_N", Vector3.new(44, 16, 1), CFrame.new(polCenter + Vector3.new(0, 8.5, 19)), Color3.fromRGB(245, 235, 230))
	part("ScianaPol_S", Vector3.new(44, 16, 1), CFrame.new(polCenter + Vector3.new(0, 8.5, -19)), Color3.fromRGB(245, 235, 230))

	-- Tablica polonistyczna z zadaniem
	local polBoard = part("TablicaPolski", Vector3.new(1, 8, 18), CFrame.new(polCenter + Vector3.new(21.4, 7, 0)), Color3.fromRGB(40, 40, 45))
	sign(polBoard, Enum.NormalId.Left, "📖 JĘZYK POLSKI (SALA 102)\n\nDYKTANDO:\nPrzepisz bezbłędnie słowo: 'szkoła' lub 'kartkówka'!", Color3.fromRGB(40, 40, 45), Color3.fromRGB(255, 255, 255))

	-- Portret Adama Mickiewicza
	local portrait = part("PortretMickiewicz", Vector3.new(1, 6, 4.5), CFrame.new(polCenter + Vector3.new(21.4, 12, 12)), Color3.fromRGB(80, 50, 30), Enum.Material.Wood)
	sign(portrait, Enum.NormalId.Left, "PORTRET:\nAdam Mickiewicz\n(1798–1855)", Color3.fromRGB(240, 230, 210), Color3.fromRGB(30, 30, 30))

	local polishPrompt = Instance.new("ProximityPrompt")
	polishPrompt.ActionText = "Napisz dyktando z Polskiego"
	polishPrompt.ObjectText = "Tablica Języka Polskiego"
	polishPrompt.HoldDuration = 0.5
	polishPrompt.MaxActivationDistance = 10
	polishPrompt.Parent = polBoard

	-- Ławki w klasie polskiego
	for _, rowZ in ipairs({ -10, 0, 10 }) do
		for _, colX in ipairs({ 24, 34 }) do
			schoolDeskAndChair(Vector3.new(colX, 0.5, rowZ - 30), -90)
		end
	end

	-- ========================================================
	-- 5. GABINET DYREKTORA SZKOŁY (x = -35, z = -30)
	-- ========================================================
	print("[Mapa] Generowanie Gabinetu Dyrektora...")
	local dirCenter = Vector3.new(-35, 0, -30)
	part("PodlogaDyrektor", Vector3.new(44, 1, 38), CFrame.new(dirCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(130, 70, 40), Enum.Material.WoodPlanks)
	part("SufitDyrektor", Vector3.new(44, 1, 38), CFrame.new(dirCenter + Vector3.new(0, 16.5, 0)), Color3.fromRGB(230, 230, 230))
	part("ScianaDir_W", Vector3.new(1, 16, 38), CFrame.new(dirCenter + Vector3.new(-22, 8.5, 0)), Color3.fromRGB(240, 230, 210))
	part("ScianaDir_N", Vector3.new(44, 16, 1), CFrame.new(dirCenter + Vector3.new(0, 8.5, 19)), Color3.fromRGB(240, 230, 210))
	part("ScianaDir_S", Vector3.new(44, 16, 1), CFrame.new(dirCenter + Vector3.new(0, 8.5, -19)), Color3.fromRGB(240, 230, 210))

	-- Słynny czerwony "DYWANIK U DYREKTORA"
	part("DywanikDyrektora", Vector3.new(16, 0.1, 24), CFrame.new(dirCenter + Vector3.new(0, 1.05, 0)), Color3.fromRGB(180, 20, 20), Enum.Material.Fabric)

	-- Wielkie mahoniowe biurko Dyrektora
	local dirDesk = part("BiurkoDyrektora", Vector3.new(12, 3, 5), CFrame.new(dirCenter + Vector3.new(-12, 2.5, 0)), Color3.fromRGB(60, 30, 15), Enum.Material.Wood)
	sign(dirDesk, Enum.NormalId.Right, "👑 GABINET DYREKTORA SZKOŁY\n'Wszystko widzę, wszystko wiem!'", Color3.fromRGB(60, 30, 15), Color3.fromRGB(255, 215, 0))

	-- Gablota z pucharami szkolnymi
	local trophyCase = part("GablotaPuchary", Vector3.new(1.2, 10, 14), CFrame.new(dirCenter + Vector3.new(-21.2, 6, 8)), Color3.fromRGB(20, 20, 20), Enum.Material.Glass)
	sign(trophyCase, Enum.NormalId.Right, "🏆 PUCHARY SZKOŁY:\n1. Zwycięstwo w Turnieju Zbijaka\n2. I Miejsce w Konkursie Ortograficznym", Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 230, 80))

	-- ========================================================
	-- 6. KANCIAPA WOŹNEJ (x = -35, z = 30)
	-- ========================================================
	print("[Mapa] Generowanie Kanciapy Woźnej...")
	local janCenter = Vector3.new(-35, 0, 30)
	part("PodlogaWozna", Vector3.new(44, 1, 38), CFrame.new(janCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(140, 140, 140), Enum.Material.Concrete)
	part("SufitWozna", Vector3.new(44, 1, 38), CFrame.new(janCenter + Vector3.new(0, 16.5, 0)), Color3.fromRGB(230, 230, 230))
	part("ScianaJan_W", Vector3.new(1, 16, 38), CFrame.new(janCenter + Vector3.new(-22, 8.5, 0)), Color3.fromRGB(210, 210, 210))
	part("ScianaJan_N", Vector3.new(44, 16, 1), CFrame.new(janCenter + Vector3.new(0, 8.5, 19)), Color3.fromRGB(210, 210, 210))
	part("ScianaJan_S", Vector3.new(44, 16, 1), CFrame.new(janCenter + Vector3.new(0, 8.5, -19)), Color3.fromRGB(210, 210, 210))

	-- Półka ze środkami czystości
	local shelfJan = part("PolkaLudwik", Vector3.new(2, 8, 16), CFrame.new(janCenter + Vector3.new(-20, 5, 0)), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	sign(shelfJan, Enum.NormalId.Right, "🧹 KANCIAPA PANI WOŹNEJ\nŚrodki czystości: PŁYN LUDWIK, MOPY, WIADRA\nUWAGA: NIE DEPTAĆ PO ŚWIEŻO ZMYTYM!", Color3.fromRGB(40, 80, 120), Color3.fromRGB(255, 255, 255))

	-- Plama do zmycia dla Woźnej (Zadanie Woźnej)
	local puddle = part("PlamaDoZmycia", Vector3.new(8, 0.05, 8), CFrame.new(janCenter + Vector3.new(-6, 1.05, 0)), Color3.fromRGB(160, 100, 40), Enum.Material.Glass)
	local puddlePrompt = Instance.new("ProximityPrompt")
	puddlePrompt.ActionText = "Zmyj rozlaną zupę mopem!"
	puddlePrompt.ObjectText = "Śliska Plama"
	puddlePrompt.HoldDuration = 0.8
	puddlePrompt.MaxActivationDistance = 9
	puddlePrompt.Parent = puddle

	-- ========================================================
	-- 7. SALA GIMNASTYCZNA (x = 0, z = 130, 70x70 studs)
	-- ========================================================
	print("[Mapa] Generowanie Sali Gimnastycznej...")
	local gymCenter = Vector3.new(0, 0, 130)
	-- Parkiet gimnastyczny
	part("ParkietGimnastyczny", Vector3.new(70, 1, 70), CFrame.new(gymCenter + Vector3.new(0, 0.5, 0)), Color3.fromRGB(225, 175, 110), Enum.Material.WoodPlanks)
	part("SufitGym", Vector3.new(70, 1, 70), CFrame.new(gymCenter + Vector3.new(0, 22.5, 0)), Color3.fromRGB(220, 220, 220))

	-- Ściany sali gimnastycznej (wysokie 22 study)
	part("ScianaGym_N", Vector3.new(70, 22, 1), CFrame.new(gymCenter + Vector3.new(0, 11.5, 35)), Color3.fromRGB(235, 230, 210))
	part("ScianaGym_W", Vector3.new(1, 22, 70), CFrame.new(gymCenter + Vector3.new(-35, 11.5, 0)), Color3.fromRGB(235, 230, 210))
	part("ScianaGym_E", Vector3.new(1, 22, 70), CFrame.new(gymCenter + Vector3.new(35, 11.5, 0)), Color3.fromRGB(235, 230, 210))

	-- Tablica i kosz do koszykówki
	local hoopBoard = part("TablicaKosz", Vector3.new(6, 4, 0.4), CFrame.new(gymCenter + Vector3.new(0, 14, 34.2)), Color3.fromRGB(250, 250, 250))
	local hoopRing = part("ObreczKosza", Vector3.new(2.4, 0.3, 2.4), CFrame.new(gymCenter + Vector3.new(0, 12.5, 32.5)), Color3.fromRGB(220, 60, 20), Enum.Material.Metal)

	-- Drabinki gimnastyczne na ścianie bocznej
	for i = 1, 8 do
		part(`DrabinkaSzczebel_{i}`, Vector3.new(0.3, 0.3, 24), CFrame.new(gymCenter + Vector3.new(-34.2, i * 2, 0)), Color3.fromRGB(200, 150, 90), Enum.Material.Wood)
	end

	-- Baner motywacyjny na WF-ie
	local gymBanner = part("BanerWF", Vector3.new(24, 4, 0.4), CFrame.new(gymCenter + Vector3.new(0, 19, 34.2)), Color3.fromRGB(20, 70, 140))
	sign(gymBanner, Enum.NormalId.Back, "🏀 SALA GIMNASTYCZNA\nW ZDROWYM CIELE ZDROWY DUCH!\nZMIANA OBUWIA SUROWO WYMAGANA!", Color3.fromRGB(20, 70, 140), Color3.fromRGB(255, 255, 255))

	-- ========================================================
	-- 8. PODPIĘCIE WSZYSTKICH PROMPTÓW ZADAŃ DO EVENTÓW
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

	print("✨ Pomyślnie wygenerowano kompletną, memiczną mapę polskiej szkoły z salami i zadaniami!")

	-- Zwracamy pozycję spawnu szkoły (Korytarz Główny) oraz Stołówki (Kafeteria na zebrania)
	return Vector3.new(0, 3.5, 0), cafCenter + Vector3.new(0, 3.5, 0)
end

return SchoolMapGenerator
