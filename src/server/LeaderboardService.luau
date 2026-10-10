--!strict
-- src/server/LeaderboardService.luau
-- System statystyk gracza i tabeli wyników (Leaderboard / leaderstats):
-- - Szkolne Monety (waluta za zbieranie i zadania)
-- - Wygrane (liczba wygranych lekcji)
-- - Zachowanie (punkty wzorowego zachowania: 100 pkt)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local LeaderboardService = {}

local function setupPlayerLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Monety"
	coinsVal.Value = 0
	coinsVal.Parent = leaderstats

	local winsVal = Instance.new("IntValue")
	winsVal.Name = "Wygrane"
	winsVal.Value = 0
	winsVal.Parent = leaderstats

	local behaviorVal = Instance.new("IntValue")
	behaviorVal.Name = "Zachowanie"
	behaviorVal.Value = 100 -- 100 punktów wzorowego ucznia
	behaviorVal.Parent = leaderstats

	leaderstats.Parent = player
end

function LeaderboardService.addCoins(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local coinsVal = stats and stats:FindFirstChild("Monety") :: IntValue?
	if coinsVal then
		coinsVal.Value += amount
		local updateRemote = Remotes.get(GameConfig.RemoteEvents.UpdateCoins)
		updateRemote:FireClient(player, coinsVal.Value)
	end
end

function LeaderboardService.addWin(player: Player)
	local stats = player:FindFirstChild("leaderstats")
	local winsVal = stats and stats:FindFirstChild("Wygrane") :: IntValue?
	if winsVal then
		winsVal.Value += 1
	end
end

function LeaderboardService.penalizeBehavior(player: Player, penalty: number)
	local stats = player:FindFirstChild("leaderstats")
	local bVal = stats and stats:FindFirstChild("Zachowanie") :: IntValue?
	if bVal then
		bVal.Value = math.max(0, bVal.Value - penalty)
	end
end

function LeaderboardService.init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerLeaderstats(player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		setupPlayerLeaderstats(player)
	end)

	print("[LeaderboardService] System statystyk szkolnych zainicjalizowany!")
end

return LeaderboardService
