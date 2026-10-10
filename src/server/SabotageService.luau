--!strict
-- src/server/SabotageService.luau
-- System Sabotaży (Among Us inspired):
-- 1. Awaria Korków (Blackout) - Ciemność w szkole, naprawa bezpieczników w Kanciapie Woźnej.
-- 2. Zablokowane Drzwi - Zamknięcie wejść do sal lekcyjnych na 15 sekund.
-- 3. Fałszywy Alarm Pożarowy - Rozlega się syrena, wymaga wyłączenia w korytarzu.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local __layout = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):FindFirstChild("SchoolLayout")
local SchoolLayout = __layout and (require(__layout) :: any) or nil -- agent-claude: pozycje nowej szkoły
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local SabotageService = {}
local activeSabotage: string? = nil
local sabotageModel: Instance? = nil
local sabotageCooldown = 0
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultFogEnd = Lighting.FogEnd
local defaultBrightness = Lighting.Brightness

-- Przywraca domyślne oświetlenie
local function restoreLighting()
	Lighting.OutdoorAmbient = defaultOutdoorAmbient
	Lighting.FogEnd = defaultFogEnd
	Lighting.Brightness = defaultBrightness
end

function SabotageService.getActiveSabotage(): string?
	return activeSabotage
end

-- 1. AWARIA KORKÓW (BLACKOUT)
local function triggerBlackout()
	activeSabotage = GameConfig.Sabotages.AwariaKorkow
	print("[Sabotaż] Aktywowano Awarię Korków! Szkoła pogrąża się w ciemności!")

	-- Ciemność i gęsta mgła
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 20)
	Lighting.Brightness = 0.2
	Lighting.FogColor = Color3.fromRGB(10, 10, 15)
	Lighting.FogEnd = 45
	Lighting.FogStart = 5

	-- Tworzenie skrzynki bezpiecznikowej w Kanciapie Woźnej
	local fuseBox = Instance.new("Part")
	fuseBox.Name = "SkrzynkaBezpiecznikowa"
	fuseBox.Size = Vector3.new(1.8, 2.5, 0.8)
	fuseBox.Position = (SchoolLayout and SchoolLayout.SkrzynkaBezpiecznikow) or Vector3.new(-70, 5, 29) -- Na ścianie kanciapy
	fuseBox.Color = Color3.fromRGB(80, 80, 80)
	fuseBox.Material = Enum.Material.Metal
	fuseBox.Anchored = true
	fuseBox.CanCollide = true
	fuseBox.Parent = workspace

	-- Dioda ostrzegawcza
	local redLight = Instance.new("PointLight")
	redLight.Color = Color3.fromRGB(255, 30, 30)
	redLight.Range = 10
	redLight.Brightness = 3
	redLight.Parent = fuseBox

	-- Billboard nad skrzynką
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 45)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = fuseBox

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "⚡ BEZPIECZNIKI (AWARIA!)\n[Włącz korki!]"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bb

	-- ProximityPrompt do naprawy
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Włącz korki"
	prompt.ObjectText = "Skrzynka Bezpiecznikowa"
	prompt.HoldDuration = 2.0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = fuseBox

	prompt.Triggered:Connect(function(player: Player)
		if player:GetAttribute("IsAlive") ~= true then return end
		-- Woźna naprawia natychmiast lub 2x szybciej
		print(`[Sabotaż] Gracz {player.Name} naprawił korki w szkole!`)
		SabotageService.fixSabotage(player.Name)
	end)

	sabotageModel = fuseBox

	-- Rozgłoszenie o sabotażu
	local activeRemote = Remotes.get(GameConfig.RemoteEvents.SabotageActive)
	activeRemote:FireAllClients(GameConfig.Sabotages.AwariaKorkow, "⚠️ AWARIA KORKÓW! Woźna lub Uczniowie muszą włączyć bezpieczniki w Kanciapie!")
end

-- 2. ZABLOKOWANE DRZWI
local function triggerDoorLock()
	activeSabotage = GameConfig.Sabotages.ZablokowaneDrzwi
	print("[Sabotaż] Rozrabiaka zablokował drzwi w szkole na 15 sekund!")

	local doorBlockers = Instance.new("Folder")
	doorBlockers.Name = "ZablokowaneDrzwiFolder"

	-- Przykładowe blokady wejść
	local doorPositions = {
		Vector3.new(20, 5, 0), -- Wejście do sal lekcyjnych
		Vector3.new(-20, 5, -30), -- Wejście do stołówki
	}
	if SchoolLayout then
		doorPositions = SchoolLayout.BlokadyDrzwi
	end

	for _, pos in ipairs(doorPositions) do
		local door = Instance.new("Part")
		door.Name = "MetalowaKrataDrzwi"
		door.Size = Vector3.new(8, 12, 1)
		door.Position = pos
		door.Material = Enum.Material.DiamondPlate
		door.Color = Color3.fromRGB(60, 60, 60)
		door.Anchored = true
		door.CanCollide = true
		door.Parent = doorBlockers
	end

	doorBlockers.Parent = workspace
	sabotageModel = doorBlockers

	local activeRemote = Remotes.get(GameConfig.RemoteEvents.SabotageActive)
	activeRemote:FireAllClients(GameConfig.Sabotages.ZablokowaneDrzwi, "🔒 DRZWI ZABLOKOWANE! Zamek automatycznie odblokuje się za 15 sekund!")

	task.delay(15, function()
		if activeSabotage == GameConfig.Sabotages.ZablokowaneDrzwi then
			SabotageService.fixSabotage("Automatyczny zamek")
		end
	end)
end

function SabotageService.triggerSabotage(player: Player, sabotageType: string): boolean
	-- Sprawdzenie roli
	if player:GetAttribute("Role") ~= GameConfig.Roles.Rozrabiaka then
		return false
	end
	if player:GetAttribute("IsAlive") ~= true then
		return false
	end
	if activeSabotage ~= nil then
		return false -- Już trwa inny sabotaż
	end

	local now = tick()
	if now < sabotageCooldown then
		return false -- Cooldown sabotażu
	end
	sabotageCooldown = now + 25 -- 25 sekund cooldownu między sabotażami

	if sabotageType == GameConfig.Sabotages.AwariaKorkow then
		triggerBlackout()
		return true
	elseif sabotageType == GameConfig.Sabotages.ZablokowaneDrzwi then
		triggerDoorLock()
		return true
	end

	return false
end

function SabotageService.fixSabotage(repairedBy: string)
	if not activeSabotage then return end
	print(`[Sabotaż] Sabotaż '{activeSabotage}' został naprawiony przez: {repairedBy}!`)

	if activeSabotage == GameConfig.Sabotages.AwariaKorkow then
		restoreLighting()
	end

	if sabotageModel and sabotageModel.Parent then
		sabotageModel:Destroy()
	end
	sabotageModel = nil
	activeSabotage = nil

	local fixedRemote = Remotes.get(GameConfig.RemoteEvents.SabotageFixed)
	fixedRemote:FireAllClients(repairedBy)
end

function SabotageService.cleanup()
	if activeSabotage then
		SabotageService.fixSabotage("Reset gry")
	end
	restoreLighting()
end

-- Rejestracja zdarzenia od klienta
function SabotageService.init()
	local triggerRemote = Remotes.get(GameConfig.RemoteEvents.TriggerSabotage)
	triggerRemote.OnServerEvent:Connect(function(player: Player, sabotageType: string)
		SabotageService.triggerSabotage(player, sabotageType)
	end)
end

return SabotageService
