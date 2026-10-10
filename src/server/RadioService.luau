--!strict
-- src/server/RadioService.luau
-- Szkolny Radiowęzeł (PA System):
-- Unikalna zdolność Dyrektora w jego gabinecie:
-- Może nadać oficjalny komunikat radiowęzła do wszystkich uczniów na korytarzach!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local RadioService = {}
local radioMicPart: BasePart? = nil
local lastAnnouncementTime = 0

local ANNOUNCEMENTS = {
	"📢 [RADIOWĘZEŁ] Uwaga uczniowie! Dyrekcja przypomina o zakazie biegania po korytarzu!",
	"📢 [RADIOWĘZEŁ] Kto nie zmienił obuwia, proszony jest do szatni!",
	"📢 [RADIOWĘZEŁ] Uwaga! Zauważono podejrzaną aktywność w okolicach sali gimnastycznej!",
	"📢 [RADIOWĘZEŁ] Woźna pilnie poszukiwana na parterze!",
}

function RadioService.setupMicrophone(deskPosition: Vector3)
	if radioMicPart then radioMicPart:Destroy() end

	local mic = Instance.new("Part")
	mic.Name = "MikrofonRadiowezla"
	mic.Size = Vector3.new(0.6, 1.4, 0.6)
	mic.Position = deskPosition + Vector3.new(1.5, 2.2, 0)
	mic.Color = Color3.fromRGB(50, 50, 50)
	mic.Material = Enum.Material.Metal
	mic.Anchored = true
	mic.CanCollide = false
	mic.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Nadaj Komunikat przez Radiowęzeł"
	prompt.ObjectText = "Mikrofon Gabinetu"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 7
	prompt.Parent = mic

	prompt.Triggered:Connect(function(player: Player)
		local role = player:GetAttribute("Role")
		if role ~= GameConfig.Roles.Dyrektor and role ~= GameConfig.Roles.ZastepcaDyrektora then
			return
		end

		local now = tick()
		if now - lastAnnouncementTime < 20 then
			return -- 20 sekund cooldownu
		end
		lastAnnouncementTime = now

		local msg = ANNOUNCEMENTS[math.random(1, #ANNOUNCEMENTS)]
		print(`[Radiowęzeł] Dyrektor {player.Name} nadał komunikat: {msg}`)

		-- Gong radiowęzła i komunikat dla wszystkich
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local bell = Instance.new("Sound")
				bell.SoundId = GameConfig.SoundIds.SchoolBell
				bell.Volume = 0.5
				bell.Parent = root
				bell:Play()
				Debris:AddItem(bell, 3)
			end
		end

		local activeRemote = Remotes.get(GameConfig.RemoteEvents.SabotageActive)
		activeRemote:FireAllClients("Radiowezel", msg)

		task.delay(6, function()
			local fixedRemote = Remotes.get(GameConfig.RemoteEvents.SabotageFixed)
			fixedRemote:FireAllClients("Koniec komunikatu")
		end)
	end)

	radioMicPart = mic
end

return RadioService
