--!strict
-- src/server/HidingService.luau
-- Mechanika chowania się w szafkach szkolnych (Lockers / Hiding Spots):
-- Uczniowie mogą ukrywać się przed Rozrabiaką, a Rozrabiaka może szykować zasadzki!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HidingService = {}
local hidingPlayers: { [Player]: { OriginalCFrame: CFrame, LockerPart: BasePart } } = {}

-- Ukrywa gracza w szafce
function HidingService.hideInLocker(player: Player, lockerPart: BasePart)
	if hidingPlayers[player] then return end
	if player:GetAttribute("IsAlive") ~= true then return end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	hidingPlayers[player] = {
		OriginalCFrame = root.CFrame,
		LockerPart = lockerPart,
	}

	-- Schowaj postać wewnątrz szafki
	root.CFrame = lockerPart.CFrame
	root.Anchored = true

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 1
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
	end

	print(`[HidingService] Gracz {player.Name} schował się w szafce: {lockerPart.Name}`)
end

-- Wypuszcza gracza z szafki
function HidingService.exitLocker(player: Player)
	local data = hidingPlayers[player]
	if not data then return end

	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.Anchored = false
			-- Wypchnij przed szafkę
			root.CFrame = data.LockerPart.CFrame * CFrame.new(0, 0, 3.5)
		end

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
			elseif part:IsA("Decal") then
				part.Transparency = 0
			end
		end
	end

	hidingPlayers[player] = nil
	print(`[HidingService] Gracz {player.Name} opuścił szafkę!`)
end

-- Rejestracja szafki jako kryjówki
function HidingService.registerLocker(lockerPart: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Schowaj się w szafce"
	prompt.ObjectText = "Szafka Szkolna"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = lockerPart

	prompt.Triggered:Connect(function(player: Player)
		if hidingPlayers[player] then
			HidingService.exitLocker(player)
			prompt.ActionText = "Schowaj się w szafce"
		else
			HidingService.hideInLocker(player, lockerPart)
			prompt.ActionText = "Opuść szafkę"
		end
	end)
end

function HidingService.cleanup()
	for player, _ in pairs(hidingPlayers) do
		HidingService.exitLocker(player)
	end
	table.clear(hidingPlayers)
end

return HidingService
