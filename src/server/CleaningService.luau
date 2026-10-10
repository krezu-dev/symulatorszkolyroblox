--!strict
-- src/server/CleaningService.luau
-- Specjalna mechanika dla Woźnej (i uczniów):
-- Na korytarzach pojawiają się rozlane plamy (kompot ze stołówki, zupa pomidorowa, błoto z butów).
-- Zmycie plamy mopem przez Woźną daje postęp zadań szkolnych i monety!

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local CleaningService = {}
local activePuddles: { BasePart } = {}
local puddleFolder: Folder? = nil
local isRunning = false
local onTaskProgressCallback: ((number) -> ())?

function CleaningService.setProgressCallback(cb: (number) -> ())
	onTaskProgressCallback = cb
end

local PUDDLE_TYPES = {
	{ Name = "Rozlany Kompot Truskawkowy", Color = Color3.fromRGB(220, 60, 80) },
	{ Name = "Zupa Pomidorowa ze Stołówki", Color = Color3.fromRGB(230, 90, 40) },
	{ Name = "Błoto z Korytarza", Color = Color3.fromRGB(90, 70, 50) },
	{ Name = "Plama po Tłustym Obiedzie", Color = Color3.fromRGB(210, 180, 50) },
}

local function spawnPuddle(pos: Vector3)
	if not puddleFolder then return end

	local pType = PUDDLE_TYPES[math.random(1, #PUDDLE_TYPES)]

	local puddle = Instance.new("Part")
	puddle.Name = "PlamaDoZmycia"
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Size = Vector3.new(0.1, 4.5, 4.5)
	puddle.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	puddle.Color = pType.Color
	puddle.Material = Enum.Material.Glass
	puddle.Transparency = 0.3
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.Parent = puddleFolder

	-- ProximityPrompt do zmywania
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Zmyj plamę mopem"
	prompt.ObjectText = pType.Name
	prompt.HoldDuration = 1.0
	prompt.MaxActivationDistance = 8
	prompt.Parent = puddle

	prompt.Triggered:Connect(function(player: Player)
		if player:GetAttribute("IsAlive") ~= true then return end
		local isWozna = player:GetAttribute("Role") == GameConfig.Roles.Wozna

		print(`[CleaningService] {player.Name} (Woźna: {isWozna}) zmył: {pType.Name}!`)

		-- Dźwięk chlupotu wody
		local splash = Instance.new("Sound")
		splash.SoundId = "rbxassetid://9114227000" -- Splash sound
		splash.Volume = 0.7
		splash.Parent = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
		splash:Play()
		Debris:AddItem(splash, 2)

		-- Usunięcie plamy
		local idx = table.find(activePuddles, puddle)
		if idx then table.remove(activePuddles, idx) end
		puddle:Destroy()

		-- Zgłoszenie wykonania zadania (nabija pasek zadań)
		Remotes.get(GameConfig.RemoteEvents.TaskCompleted):FireServer("ZmywaniePlam")
	end)

	-- Spowolnienie po wejściu w plamę (gracz się ślizga)
	puddle.Touched:Connect(function(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.WalkSpeed > 10 then
			local oldSpeed = hum.WalkSpeed
			hum.WalkSpeed = 10 -- Chwilowe spowolnienie
			task.delay(1.5, function()
				if hum then hum.WalkSpeed = oldSpeed end
			end)
		end
	end)

	table.insert(activePuddles, puddle)
end

function CleaningService.start()
	isRunning = true
	if puddleFolder then puddleFolder:Destroy() end
	puddleFolder = Instance.new("Folder")
	puddleFolder.Name = "SzkolnePlamyFolder"
	puddleFolder.Parent = workspace

	-- Spawnowanie początkowych plam
	local samplePositions = {
		Vector3.new(-40, 1.05, 0),
		Vector3.new(30, 1.05, 0),
		Vector3.new(0, 1.05, -50),
		Vector3.new(-60, 1.05, -30),
		Vector3.new(50, 17.05, 0),
	}

	for _, pos in ipairs(samplePositions) do
		spawnPuddle(pos)
	end

	-- Cykliczne spawnowanie nowych plam
	task.spawn(function()
		while isRunning do
			task.wait(20)
			if #activePuddles < 8 then
				local rx = math.random(-80, 80)
				local rz = math.random(-40, 40)
				spawnPuddle(Vector3.new(rx, 1.05, rz))
			end
		end
	end)
end

function CleaningService.stop()
	isRunning = false
	if puddleFolder then
		puddleFolder:Destroy()
		puddleFolder = nil
	end
	table.clear(activePuddles)
end

return CleaningService
