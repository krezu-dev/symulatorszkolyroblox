--!strict
-- src/server/CoinService.luau
-- Mechanika monet z Murder Mystery 2 (MM2 Coin Spawning):
-- Na korytarzach, pod ławkami i w zakamarkach pojawiają się złociste "Szkolne Monety 5 zł".
-- Gracze (zwłaszcza Niewinni Uczniowie) mogą je zbierać, aby zdobywać walutę i mieć cel podczas eksploracji!

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local CoinService = {}
local activeCoins: { BasePart } = {}
local playerCoins: { [Player]: number } = {}
local coinFolder: Folder? = nil
local isSpawning = false

-- Punkty orientacyjne do spawnowania monet na mapie szkoły
local COIN_ZONES = {
	-- Korytarz parteru
	{ Min = Vector3.new(-90, 2, -10), Max = Vector3.new(90, 2, 10) },
	-- Stołówka
	{ Min = Vector3.new(-35, 2, -90), Max = Vector3.new(35, 2, -45) },
	-- Sala Gimnastyczna
	{ Min = Vector3.new(-80, 2, -90), Max = Vector3.new(-50, 2, -50) },
	-- Piętro I - Korytarz
	{ Min = Vector3.new(-90, 18, -10), Max = Vector3.new(90, 18, 10) },
	-- Sale lekcyjne
	{ Min = Vector3.new(30, 18, -30), Max = Vector3.new(80, 18, 30) },
}

local function spawnSingleCoin(pos: Vector3)
	if not coinFolder then return end

	local coin = Instance.new("Part")
	coin.Name = "SzkolnaMoneta"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.3, 1.8, 1.8)
	-- Orientacja cylindra w pionie
	coin.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	coin.Color = Color3.fromRGB(255, 215, 0) -- Złoty kolor polskiej monety 5 zł
	coin.Material = Enum.Material.Metal
	coin.Anchored = true
	coin.CanCollide = false
	coin.Parent = coinFolder

	-- Złote światełko
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 230, 100)
	light.Range = 6
	light.Brightness = 2
	light.Parent = coin

	-- Płynny obrót monety (Tween)
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
	local tween = TweenService:Create(coin, tweenInfo, {
		CFrame = coin.CFrame * CFrame.Angles(math.rad(360), 0, 0),
	})
	tween:Play()

	-- Podnoszenie monety
	local debounce = false
	coin.Touched:Connect(function(hit)
		if debounce then return end
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if player and player:GetAttribute("IsAlive") == true then
			debounce = true

			local current = playerCoins[player] or 0
			if current < GameConfig.Coins.MaxBagCapacity then
				current += GameConfig.Coins.CoinValue
				playerCoins[player] = current

				-- Powiadomienie klienta o stanie monet
				local updateRemote = Remotes.get(GameConfig.RemoteEvents.UpdateCoins)
				updateRemote:FireClient(player, current)
			end

			-- Dźwięk podniesienia
			local sound = Instance.new("Sound")
			sound.SoundId = GameConfig.SoundIds.CoinPickup
			sound.Volume = 0.6
			sound.Parent = char:FindFirstChild("HumanoidRootPart") or workspace
			sound:Play()
			Debris:AddItem(sound, 2)

			-- Usunięcie z listy
			local idx = table.find(activeCoins, coin)
			if idx then
				table.remove(activeCoins, idx)
			end
			coin:Destroy()
		end
	end)

	table.insert(activeCoins, coin)
end

function CoinService.startSpawning()
	isSpawning = true
	if coinFolder then
		coinFolder:Destroy()
	end
	coinFolder = Instance.new("Folder")
	coinFolder.Name = "SzkolneMonetyFolder"
	coinFolder.Parent = workspace

	task.spawn(function()
		while isSpawning do
			if #activeCoins < GameConfig.Coins.MaxSpawns then
				-- Wybierz losową strefę
				local zone = COIN_ZONES[math.random(1, #COIN_ZONES)]
				local rx = math.random(math.floor(zone.Min.X), math.floor(zone.Max.X))
				local ry = zone.Min.Y
				local rz = math.random(math.floor(zone.Min.Z), math.floor(zone.Max.Z))
				spawnSingleCoin(Vector3.new(rx, ry, rz))
			end
			task.wait(GameConfig.Coins.SpawnInterval)
		end
	end)
end

function CoinService.stopSpawning()
	isSpawning = false
	if coinFolder then
		coinFolder:Destroy()
		coinFolder = nil
	end
	table.clear(activeCoins)
end

function CoinService.resetPlayerCoins()
	table.clear(playerCoins)
	for _, player in ipairs(Players:GetPlayers()) do
		local updateRemote = Remotes.get(GameConfig.RemoteEvents.UpdateCoins)
		updateRemote:FireClient(player, 0)
	end
end

function CoinService.getPlayerCoins(player: Player): number
	return playerCoins[player] or 0
end

return CoinService
