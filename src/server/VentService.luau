--!strict
-- src/server/VentService.luau
-- System kratek wentylacyjnych (Vents z Among Us):
-- Łączy 6 kluczowych zakamarków szkoły:
-- 1. Kanciapa Woźnej
-- 2. Magazynek Sprzętu WF
-- 3. Zaplecze Pracowni Chemicznej
-- 4. Schowek pod Schodami
-- 5. Toalety Chłopięce / Szatnia
-- 6. Zmywak w Stołówce
-- Tylko Rozrabiaka (Impostor) może wskakiwać do kratek wentylacyjnych!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local VentService = {}
local ventNodes: { { Name: string, Position: Vector3, Part: BasePart } } = {}
local ventFolder: Folder? = nil

-- Definicje pozycji kratek wentylacyjnych w zakamarkach
local VENT_DEFINITIONS = {
	{ Name = "Kanciapa Woźnej", Pos = Vector3.new(-75, 1, 25) },
	{ Name = "Magazynek WF", Pos = Vector3.new(-85, 1, -95) },
	{ Name = "Zaplecze Chemiczne", Pos = Vector3.new(75, 17, 30) },
	{ Name = "Schowek pod Schodami", Pos = Vector3.new(0, 1, 15) },
	{ Name = "Toaleta / Zakamarek", Pos = Vector3.new(85, 1, 95) },
	{ Name = "Zmywak Stołówki", Pos = Vector3.new(20, 1, -85) },
}

local playerCooldowns: { [Player]: number } = {}

function VentService.setupVents()
	if ventFolder then
		ventFolder:Destroy()
	end
	table.clear(ventNodes)

	ventFolder = Instance.new("Folder")
	ventFolder.Name = "SzkolnaWentylacja"
	ventFolder.Parent = workspace

	for i, def in ipairs(VENT_DEFINITIONS) do
		-- Metalowa kratka na podłodze
		local ventPart = Instance.new("Part")
		ventPart.Name = `Kratka_{i}_{def.Name}`
		ventPart.Size = Vector3.new(3.5, 0.2, 3.5)
		ventPart.Position = def.Pos
		ventPart.Anchored = true
		ventPart.CanCollide = true
		ventPart.Material = Enum.Material.CorrodedMetal
		ventPart.Color = Color3.fromRGB(70, 75, 80)
		ventPart.Parent = ventFolder

		-- Drobne pręty kratki (dekoracja)
		local grateCenter = Instance.new("Part")
		grateCenter.Name = "GrateSlits"
		grateCenter.Size = Vector3.new(3.1, 0.25, 3.1)
		grateCenter.Position = def.Pos + Vector3.new(0, 0.05, 0)
		grateCenter.Anchored = true
		grateCenter.CanCollide = false
		grateCenter.Material = Enum.Material.DiamondPlate
		grateCenter.Color = Color3.fromRGB(35, 35, 35)
		grateCenter.Parent = ventFolder

		-- Czerwone subtelne światełko (tajemniczy klimat)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 60, 60)
		light.Range = 6
		light.Brightness = 1.2
		light.Parent = ventPart

		-- ProximityPrompt - widoczny tylko dla Rozrabiaki
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Użyj Wentylacji"
		prompt.ObjectText = `Kratka: {def.Name}`
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = ventPart

		local nodeIndex = i
		prompt.Triggered:Connect(function(player: Player)
			if player:GetAttribute("IsAlive") ~= true then return end
			local role = player:GetAttribute("Role")
			if role ~= GameConfig.Roles.Rozrabiaka then
				-- Uczeń lub Dyrektor nie mogą wejść do wentylacji
				return
			end

			-- Sprawdzenie cooldownu
			local now = tick()
			local lastUse = playerCooldowns[player] or 0
			if now - lastUse < GameConfig.Durations.VentCooldown then
				return
			end
			playerCooldowns[player] = now

			-- Teleportacja do kolejnej kratki w cyklu
			local nextIndex = (nodeIndex % #VENT_DEFINITIONS) + 1
			local targetNode = VENT_DEFINITIONS[nextIndex]

			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(targetNode.Pos + Vector3.new(0, 3, 0))
				print(`[Wentylacja] Rozrabiaka {player.Name} przeskoczył z '{def.Name}' do '{targetNode.Name}'!`)

				-- Dźwięk przeskoku
				local sound = Instance.new("Sound")
				sound.SoundId = GameConfig.SoundIds.VentWhoosh
				sound.Volume = 0.8
				sound.Parent = root
				sound:Play()
				game:GetService("Debris"):AddItem(sound, 3)
			end
		end)

		table.insert(ventNodes, { Name = def.Name, Position = def.Pos, Part = ventPart })
	end

	print(`[Wentylacja] Zainicjalizowano {#ventNodes} kratek wentylacyjnych w zakamarkach szkoły!`)
end

function VentService.cleanup()
	if ventFolder then
		ventFolder:Destroy()
		ventFolder = nil
	end
	table.clear(ventNodes)
	table.clear(playerCooldowns)
end

return VentService
