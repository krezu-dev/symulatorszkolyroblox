--!strict
-- src/server/EliminationService.luau
-- Obsługa eliminacji graczy: zamiana w ducha, tworzenie porzuconego plecaka i zgłaszanie

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local EliminationService = {}
local spawnedBackpacks: {Instance} = {}
local meetingTriggerCallback: ((Player, string) -> ())?

function EliminationService.setMeetingCallback(callback: (Player, string) -> ())
	meetingTriggerCallback = callback
end

-- Zamienia gracza w ducha
local function makeGhost(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.6
			part.CanCollide = false
		elseif part:IsA("Decal") then
			part.Transparency = 0.6
		end
	end

	-- Zmniejsz prędkość chodzenia lub wyłącz obrażenia
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 20
	end
end

-- Tworzy porzucony szkolny plecak w miejscu eliminacji
local function spawnBackpack(position: Vector3, victimName: string)
	local backpack = Instance.new("Part")
	backpack.Name = `Plecak_{victimName}`
	backpack.Size = Vector3.new(1.4, 1.8, 1)
	backpack.Position = position + Vector3.new(0, 0.9, 0)
	backpack.Color = Color3.fromRGB(40, 90, 180) -- Niebieski szkolny plecak
	backpack.Material = Enum.Material.Fabric
	backpack.Anchored = true
	backpack.CanCollide = true

	-- Billboard z podpisem
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 150, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = backpack

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = `🎒 Plecak: {victimName}`
	text.TextColor3 = Color3.fromRGB(255, 255, 100)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = bb

	-- ProximityPrompt do zgłoszenia
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Zgłoś do Dyrekcji!"
	prompt.ObjectText = `Plecak ({victimName})`
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = backpack

	prompt.Triggered:Connect(function(reportingPlayer)
		if reportingPlayer:GetAttribute("IsAlive") == true then
			print(`[Zgłoszenie] {reportingPlayer.Name} zgłasza plecak gracza {victimName}!`)
			if meetingTriggerCallback then
				meetingTriggerCallback(reportingPlayer, `Znaleziono porzucony plecak ucznia {victimName}!`)
			end
		end
	end)

	backpack.Parent = workspace
	table.insert(spawnedBackpacks, backpack)
end

function EliminationService.eliminatePlayer(victim: Player, killer: Player?, reason: string?)
	if victim:GetAttribute("IsAlive") ~= true then
		return
	end

	victim:SetAttribute("IsAlive", false)
	print(`[Eliminacja] Gracz {victim.Name} został wyeliminowany! Powód: {reason or "brak"}`)

	local char = victim.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			spawnBackpack(root.Position, victim.Name)
		end

		-- Oczyszczenie narzędzi
		victim.Backpack:ClearAllChildren()
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end

		makeGhost(char)
	end
end

-- Czyści wszystkie plecaki po zakończeniu zebrania lub rundy
function EliminationService.clearBackpacks()
	for _, bp in ipairs(spawnedBackpacks) do
		if bp and bp.Parent then
			bp:Destroy()
		end
	end
	table.clear(spawnedBackpacks)
end

return EliminationService
