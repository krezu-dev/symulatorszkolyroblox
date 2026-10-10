--!strict
-- src/server/RoundManager.luau
-- Pętla gry, maszyna stanów, sprawdzanie warunków wygranej i postęp zadań

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local RolesService = require(script.Parent:WaitForChild("RolesService"))
local EliminationService = require(script.Parent:WaitForChild("EliminationService"))
local MeetingService = require(script.Parent:WaitForChild("MeetingService"))
local WeaponsService = require(script.Parent:WaitForChild("WeaponsService"))
local SchoolMapGenerator = require(script.Parent:WaitForChild("SchoolMapGenerator"))
local VentService = require(script.Parent:WaitForChild("VentService"))
local SabotageService = require(script.Parent:WaitForChild("SabotageService"))
local CoinService = require(script.Parent:WaitForChild("CoinService"))
local CleaningService = require(script.Parent:WaitForChild("CleaningService"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))

local RoundManager = {}

local currentState = GameConfig.GameStates.Lobby
local taskProgress = 0 -- 0 do 100
local totalTasksNeeded = 10 -- Liczba ukończonych zadań do 100%
local completedTasksCount = 0
local roundTimeLeft = GameConfig.Durations.RoundTime

local schoolSpawn = Vector3.new(0, 5, 0)
local cafeteriaSpawn = Vector3.new(0, 5, -60)
local lobbySpawn = Vector3.new(0, 5, 100)

function RoundManager.getState()
	return currentState
end

local function setState(newState: string)
	currentState = newState
	print(`[Gra] Zmiana stanu gry na: {newState}`)
	local changeRemote = Remotes.get(GameConfig.RemoteEvents.GameStateChanged)
	changeRemote:FireAllClients(newState)
end

local function teleportPlayers(pos: Vector3, aliveOnly: boolean)
	for _, player in ipairs(Players:GetPlayers()) do
		if not aliveOnly or player:GetAttribute("IsAlive") == true then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(pos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
			end
		end
	end
end

-- Sprawdzenie czy którakolwiek ze stron wygrała
local function checkWinConditions(): (boolean, string?)
	if currentState ~= GameConfig.GameStates.InGame and currentState ~= GameConfig.GameStates.Meeting then
		return false, nil
	end

	-- 1. Pasek zadań 100%
	if taskProgress >= 100 then
		return true, "Uczniowie wygrywają! Wszystkie zadania szkolne zostały ukończone w 100%!"
	end

	-- 2. Zliczanie żywych graczy
	local aliveRozrabiacy = 0
	local aliveInnocents = 0

	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("IsAlive") == true then
			if p:GetAttribute("Role") == GameConfig.Roles.Rozrabiaka then
				aliveRozrabiacy += 1
			else
				aliveInnocents += 1
			end
		end
	end

	-- Wszyscy Rozrabiacy odpadli
	if aliveRozrabiacy == 0 then
		return true, "Uczniowie, Woźna i Dyrektor wygrywają! Wszyscy Rozrabiacy zostali zdemaskowani!"
	end

	-- Rozrabiacy zdominowali szkołę (liczba rozrabiaków >= niewinnych)
	if aliveRozrabiacy >= aliveInnocents then
		return true, "Rozrabiacy wygrywają! Szkoła została całkowicie zsabotowana!"
	end

	return false, nil
end

local function endRound(winnerMessage: string)
	setState(GameConfig.GameStates.GameOver)
	print(`[Gra] Koniec rundy: {winnerMessage}`)

	CoinService.stopSpawning()
	CleaningService.stop()
	SabotageService.cleanup()
	EliminationService.clearBackpacks()
	RolesService.cleanupRoles(Players:GetPlayers())

	-- Nagrody dla graczy (Szkolne Monety i Wygrane w Leaderstats)
	for _, p in ipairs(Players:GetPlayers()) do
		LeaderboardService.addCoins(p, 30)
		if p:GetAttribute("IsAlive") == true then
			LeaderboardService.addWin(p)
		end
	end

	task.wait(6)
	RoundManager.startLobby()
end

-- Callback eliminacji (z broni lub rzutu dziennikiem)
local function onPlayerEliminated(victim: Player, killer: Player?, reason: string?)
	EliminationService.eliminatePlayer(victim, killer, reason)
	local isOver, msg = checkWinConditions()
	if isOver and msg then
		endRound(msg)
	end
end

-- Callback zebrania w stołówce
local function onMeetingEnd(ejectedPlayer: Player?, isTroublemaker: boolean?)
	if ejectedPlayer then
		EliminationService.eliminatePlayer(ejectedPlayer, nil, "Wyrzucony w głosowaniu")
	end

	local isOver, msg = checkWinConditions()
	if isOver and msg then
		endRound(msg)
	else
		-- Powrót do gry po zebraniu
		setState(GameConfig.GameStates.InGame)
		teleportPlayers(schoolSpawn, true)
	end
end

-- Callback uderzenia w Wielki Dzwon Szkolny
local function onBellRing(player: Player)
	if currentState == GameConfig.GameStates.InGame and player:GetAttribute("IsAlive") == true then
		MeetingService.triggerMeeting(player, "Uderzono w Wielki Dzwon w Stołówce!")
	end
end

-- Rejestracja wykonania zadania (TaskCompleted)
Remotes.get(GameConfig.RemoteEvents.TaskCompleted).OnServerEvent:Connect(function(player: Player, taskId: string)
	if currentState ~= GameConfig.GameStates.InGame then return end

	completedTasksCount += 1
	taskProgress = math.clamp(math.floor((completedTasksCount / totalTasksNeeded) * 100), 0, 100)
	print(`[Zadania] {player.Name} ukończył zadanie '{taskId}'! Postęp: {taskProgress}%`)

	Remotes.get(GameConfig.RemoteEvents.UpdateTaskProgress):FireAllClients(taskProgress)

	local isOver, msg = checkWinConditions()
	if isOver and msg then
		endRound(msg)
	end
end)

function RoundManager.startLobby()
	setState(GameConfig.GameStates.Lobby)
	taskProgress = 0
	completedTasksCount = 0
	Remotes.get(GameConfig.RemoteEvents.UpdateTaskProgress):FireAllClients(0)
	CoinService.resetPlayerCoins()

	teleportPlayers(lobbySpawn, false)

	task.spawn(function()
		local countdown = GameConfig.Durations.LobbyTime
		while countdown > 0 do
			local currentPlayers = Players:GetPlayers()
			if #currentPlayers >= 1 then -- Można testować od 1 gracza w Studio!
				task.wait(1)
				countdown -= 1
			else
				task.wait(1)
			end
		end

		RoundManager.startRound()
	end)
end

function RoundManager.startRound()
	local activePlayers = Players:GetPlayers()
	if #activePlayers == 0 then
		RoundManager.startLobby()
		return
	end

	setState(GameConfig.GameStates.InGame)
	roundTimeLeft = GameConfig.Durations.RoundTime
	totalTasksNeeded = math.max(6, #activePlayers * 4)

	-- Losowanie ról
	RolesService.assignRoles(activePlayers)

	-- Spawnowanie monet na korytarzach (MM2)
	CoinService.startSpawning()

	-- Spawnowanie plam do zmycia dla Woźnej
	CleaningService.start()

	-- Teleportacja do szkoły
	teleportPlayers(schoolSpawn, true)

	-- Pętla odliczania rundy (4.5 minuty)
	task.spawn(function()
		while roundTimeLeft > 0 and currentState == GameConfig.GameStates.InGame do
			task.wait(1)
			roundTimeLeft -= 1
		end

		if currentState == GameConfig.GameStates.InGame then
			endRound("Koniec lekcji! Uczniowie przetrwali próbę czasu i wygrywają!")
		end
	end)
end

function RoundManager.init()
	-- Konfiguracja mapy i callbacków
	local sSpawn, cSpawn, lSpawn = SchoolMapGenerator.setupMap(onBellRing)
	schoolSpawn = sSpawn
	cafeteriaSpawn = cSpawn
	lobbySpawn = lSpawn
	MeetingService.setCafeteriaPosition(cSpawn)

	-- Inicjalizacja kratek wentylacyjnych w zakamarkach (Among Us)
	VentService.setupVents()

	-- Inicjalizacja systemu sabotaży (Among Us)
	SabotageService.init()

	WeaponsService.setEliminationCallback(onPlayerEliminated)
	EliminationService.setMeetingCallback(function(reporter, reason)
		if currentState == GameConfig.GameStates.InGame then
			MeetingService.triggerMeeting(reporter, reason)
		end
	end)
	MeetingService.setMeetingEndCallback(onMeetingEnd)

	-- Start pierwszej pętli
	task.delay(2, function()
		RoundManager.startLobby()
	end)
end

return RoundManager
