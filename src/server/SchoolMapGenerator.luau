--!strict
-- src/server/SchoolMapGenerator.luau
-- Generowanie mapy szkoły i interaktywnych punktów zadań (jeśli jeszcze nie istnieją)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local SchoolMapGenerator = {}

function SchoolMapGenerator.setupMap(onBellRing: (Player) -> ()): (Vector3, Vector3)
	local mapFolder = workspace:FindFirstChild("SchoolMap") :: Folder?
	if mapFolder then
		-- Mapa już istnieje, zwróć pozycje spawnu i stołówki
		return Vector3.new(0, 5, 0), Vector3.new(0, 5, -60)
	end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "SchoolMap"
	mapFolder.Parent = workspace

	-- Pomocnicza funkcja do tworzenia ścian/podłóg
	local function createPart(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.Parent = mapFolder
		return p
	end

	-- 1. Podłoga Korytarza Głównego (Spawn szkoły)
	local schoolSpawnPos = Vector3.new(0, 0.5, 0)
	createPart("PodlogaKorytarz", Vector3.new(40, 1, 140), Vector3.new(0, 0, 0), Color3.fromRGB(200, 200, 190), Enum.Material.Concrete)

	-- 2. Stołówka (Kafeteria na południu: z = -60)
	local cafeteriaPos = Vector3.new(0, 0.5, -60)
	createPart("PodlogaStolowka", Vector3.new(80, 1, 60), cafeteriaPos, Color3.fromRGB(180, 160, 140), Enum.Material.WoodPlanks)

	-- Stół w stołówce
	local tablePart = createPart("StolKafeteria", Vector3.new(16, 2.5, 30), cafeteriaPos + Vector3.new(0, 1.5, 0), Color3.fromRGB(100, 60, 30), Enum.Material.Wood)

	-- WIELKI SZKOLNY DZWON (do zwoływania zebrań)
	local bell = Instance.new("Part")
	bell.Name = "WielkiDzwonSzkolny"
	bell.Shape = Enum.PartType.Cylinder
	bell.Size = Vector3.new(3, 3, 3)
	bell.CFrame = CFrame.new(cafeteriaPos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bell.Color = Color3.fromRGB(255, 215, 0) -- Złoty dzwon
	bell.Material = Enum.Material.Metal
	bell.Anchored = true
	bell.Parent = mapFolder

	local bellTag = Instance.new("BillboardGui")
	bellTag.Size = UDim2.new(0, 200, 0, 40)
	bellTag.StudsOffset = Vector3.new(0, 2.5, 0)
	bellTag.AlwaysOnTop = true
	bellTag.Parent = bell

	local bellLabel = Instance.new("TextLabel")
	bellLabel.Size = UDim2.new(1, 0, 1, 0)
	bellLabel.BackgroundTransparency = 1
	bellLabel.Text = "🔔 WIELKI DZWON SZKOLNY\n(Zwołaj Zebranie)"
	bellLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
	bellLabel.TextScaled = true
	bellLabel.Font = Enum.Font.GothamBold
	bellLabel.Parent = bellTag

	local bellPrompt = Instance.new("ProximityPrompt")
	bellPrompt.ActionText = "Uderz w Dzwon!"
	bellPrompt.ObjectText = "Zebranie w Stołówce"
	bellPrompt.HoldDuration = 1
	bellPrompt.MaxActivationDistance = 12
	bellPrompt.Parent = bell

	bellPrompt.Triggered:Connect(function(player)
		if onBellRing then
			onBellRing(player)
		end
	end)

	-- 3. Klasa Matematyczna (z = 30, x = -35)
	local mathClassPos = Vector3.new(-35, 0.5, 30)
	createPart("PodlogaMatematyka", Vector3.new(30, 1, 40), mathClassPos, Color3.fromRGB(210, 220, 210))

	local mathBoard = createPart("TablicaMatematyka", Vector3.new(1, 8, 16), mathClassPos + Vector3.new(-14, 5, 0), Color3.fromRGB(30, 60, 40))
	local mathPrompt = Instance.new("ProximityPrompt")
	mathPrompt.ActionText = "Rozwiąż zadanie z Matematyki"
	mathPrompt.ObjectText = "Tablica Matematyczna"
	mathPrompt.MaxActivationDistance = 10
	mathPrompt.Parent = mathBoard

	-- 4. Klasa Humanistyczna (z = 30, x = 35)
	local polishClassPos = Vector3.new(35, 0.5, 30)
	createPart("PodlogaPolski", Vector3.new(30, 1, 40), polishClassPos, Color3.fromRGB(220, 210, 210))

	local polishBoard = createPart("TablicaPolski", Vector3.new(1, 8, 16), polishClassPos + Vector3.new(14, 5, 0), Color3.fromRGB(40, 40, 50))
	local polishPrompt = Instance.new("ProximityPrompt")
	polishPrompt.ActionText = "Napisz dyktando z Polskiego"
	polishPrompt.ObjectText = "Tablica Języka Polskiego"
	polishPrompt.MaxActivationDistance = 10
	polishPrompt.Parent = polishBoard

	-- 5. Korytarz z Szafkami (z = -10, x = 0)
	local lockersPart = createPart("SzafkiSzkolne", Vector3.new(2, 6, 24), Vector3.new(-18, 3.5, -10), Color3.fromRGB(50, 120, 200), Enum.Material.Metal)
	local lockersPrompt = Instance.new("ProximityPrompt")
	lockersPrompt.ActionText = "Uporządkuj podręczniki w szafce"
	lockersPrompt.ObjectText = "Szafka Uczniowska"
	lockersPrompt.MaxActivationDistance = 10
	lockersPrompt.Parent = lockersPart

	-- Podpięcie aktywacji zadań (otwarcie GUI zadania na kliencie)
	local function bindTaskPrompt(prompt: ProximityPrompt, taskId: string)
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("IsAlive") == true then
				-- Otwórz minigrę na kliencie
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

	bindTaskPrompt(mathPrompt, GameConfig.Tasks.Matematyka.Id)
	bindTaskPrompt(polishPrompt, GameConfig.Tasks.JezykPolski.Id)
	bindTaskPrompt(lockersPrompt, GameConfig.Tasks.SzafkiKsiazki.Id)

	print("[Mapa] Pomyślnie wygenerowano szkolne sale, zadania oraz Wielki Dzwon!")
	return schoolSpawnPos + Vector3.new(0, 3, 0), cafeteriaPos + Vector3.new(0, 3, 0)
end

return SchoolMapGenerator
