--!strict
-- src/server/MeetingService.luau
-- Zarządzanie zebraniami w stołówce, głosowaniem, aresztowaniem przez policję i wynikiem

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local MeetingService = {}

local isMeetingActive = false
local votes: { [Player]: string } = {} -- [Głosujący] = Cel (Nazwa gracza lub "Skip")
local meetingEndCallback: ((Player?, boolean?) -> ())?
local cafeteriaPosition = Vector3.new(0, 3, -60) -- Domyślna lokalizacja stołówki

function MeetingService.setCafeteriaPosition(pos: Vector3)
	cafeteriaPosition = pos
end

function MeetingService.setMeetingEndCallback(callback: (Player?, boolean?) -> ())
	meetingEndCallback = callback
end

function MeetingService.isMeeting()
	return isMeetingActive
end

-- Teleportacja żyjących graczy do stołówki
local function teleportPlayersToCafeteria()
	local alivePlayers = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("IsAlive") == true then
			table.insert(alivePlayers, player)
		end
	end

	local count = #alivePlayers
	local radius = math.max(6, count * 1.5)

	for i, player in ipairs(alivePlayers) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local angle = (i / count) * math.pi * 2
				local targetPos = cafeteriaPosition + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				root.CFrame = CFrame.new(targetPos, cafeteriaPosition)
			end
		end
	end
end

-- Animacja klockowych policjantów aresztujących gracza
local function spawnPoliceArrest(targetChar: Model)
	local root = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local targetPos = root.Position

	-- Tworzenie dwóch policjantów NPC
	-- Dźwięk syreny policyjnej
	local siren = Instance.new("Sound")
	siren.SoundId = GameConfig.SoundIds.Siren
	siren.Volume = 0.8
	siren.Parent = root
	siren:Play()
	Debris:AddItem(siren, GameConfig.Durations.ArrestAnimation + 2)

	-- Tworzenie dwóch policjantów NPC zbliżających się do gracza
	for i = 1, 2 do
		local officer = Instance.new("Model")
		officer.Name = `Policjant_{i}`

		local startPos = targetPos + Vector3.new(if i == 1 then -12 else 12, 0, -10)
		local endPos = targetPos + Vector3.new(if i == 1 then -2.5 else 2.5, 0, 0)

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Color = Color3.fromRGB(0, 30, 120) -- Granatowy mundur policyjny
		torso.CFrame = CFrame.new(startPos, targetPos)
		torso.Anchored = true
		torso.CanCollide = false
		torso.Parent = officer

		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Cylinder
		head.Size = Vector3.new(1.2, 1.2, 1.2)
		head.Color = Color3.fromRGB(240, 200, 150)
		head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
		head.Anchored = true
		head.Parent = officer

		-- Czapka policyjna
		local cap = Instance.new("Part")
		cap.Size = Vector3.new(1.4, 0.4, 1.4)
		cap.Color = Color3.fromRGB(0, 20, 80)
		cap.CFrame = head.CFrame * CFrame.new(0, 0.7, 0)
		cap.Anchored = true
		cap.Parent = officer

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 120, 0, 30)
		bb.StudsOffset = Vector3.new(0, 2, 0)
		bb.AlwaysOnTop = true
		bb.Parent = head

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = "👮 POLICJA"
		txt.TextColor3 = Color3.fromRGB(100, 180, 255)
		txt.TextScaled = true
		txt.Font = Enum.Font.GothamBold
		txt.Parent = bb

		officer.Parent = workspace
		Debris:AddItem(officer, GameConfig.Durations.ArrestAnimation + 2)

		-- Płynny bieg policjanta w stronę gracza
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(torso, tweenInfo, { CFrame = CFrame.new(endPos, targetPos) }):Play()
		TweenService:Create(head, tweenInfo, { CFrame = CFrame.new(endPos + Vector3.new(0, 1.6, 0), targetPos) }):Play()
		TweenService:Create(cap, tweenInfo, { CFrame = CFrame.new(endPos + Vector3.new(0, 2.3, 0), targetPos) }):Play()
	end

	-- Nałożenie wirtualnych kajdanków po dobiegnięciu
	task.delay(1.5, function()
		local cuffs = Instance.new("Part")
		cuffs.Name = "Kajdanki"
		cuffs.Size = Vector3.new(1.2, 0.4, 0.4)
		cuffs.Color = Color3.fromRGB(180, 180, 190)
		cuffs.Material = Enum.Material.Metal
		cuffs.CFrame = root.CFrame * CFrame.new(0, 0, -1)
		cuffs.Anchored = true
		cuffs.CanCollide = false
		cuffs.Parent = workspace
		Debris:AddItem(cuffs, GameConfig.Durations.ArrestAnimation)
	end)
end

-- Zliczanie głosów
local function tallyVotes(): (string?, boolean)
	local voteCounts: { [string]: number } = {}

	for _, targetName in pairs(votes) do
		voteCounts[targetName] = (voteCounts[targetName] or 0) + 1
	end

	local highestTarget: string? = nil
	local highestVotes = 0
	local isTie = false

	for targetName, count in pairs(voteCounts) do
		if count > highestVotes then
			highestVotes = count
			highestTarget = targetName
			isTie = false
		elseif count == highestVotes then
			isTie = true
		end
	end

	if isTie or highestTarget == "Skip" or not highestTarget then
		return nil, false -- Nikt nie został wyrzucony
	end

	return highestTarget, true
end

-- Główna funkcja wywołania spotkania
function MeetingService.triggerMeeting(caller: Player, reason: string)
	if isMeetingActive then return end
	isMeetingActive = true
	table.clear(votes)

	print(`[Spotkanie] Rozpoczęto zebranie! Wywołał: {caller.Name}, Powód: {reason}`)

	-- 1. Teleportacja do stołówki
	teleportPlayersToCafeteria()

	-- 2. Wysłanie powiadomienia do klientów (otwarcie GUI głosowania)
	Remotes.get(GameConfig.RemoteEvents.StartMeeting):FireAllClients(caller.Name, reason)

	-- 3. Odliczanie czasu na dyskusję i zbieranie głosów (60s)
	task.spawn(function()
		local timeLeft = GameConfig.Durations.MeetingDiscussion

		while timeLeft > 0 and isMeetingActive do
			-- Sprawdź czy wszyscy żyjący zagłosowali
			local aliveCount = 0
			local voteCount = 0
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("IsAlive") == true then
					aliveCount += 1
					if votes[p] then
						voteCount += 1
					end
				end
			end

			if aliveCount > 0 and voteCount >= aliveCount then
				print("[Spotkanie] Wszyscy żyjący gracze oddali głos przed czasem!")
				break
			end

			task.wait(1)
			timeLeft -= 1
		end

		-- 4. Podliczenie głosów
		local ejectedName, hasEjection = tallyVotes()
		local ejectedPlayer: Player? = nil

		if hasEjection and ejectedName then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Name == ejectedName then
					ejectedPlayer = p
					break
				end
			end
		end

		-- 5. Animacja policji i aresztowanie
		local isTroublemaker = false
		if ejectedPlayer then
			local role = ejectedPlayer:GetAttribute("Role")
			isTroublemaker = (role == GameConfig.Roles.Rozrabiaka)

			if ejectedPlayer.Character then
				spawnPoliceArrest(ejectedPlayer.Character)
			end
			task.wait(GameConfig.Durations.ArrestAnimation)
		end

		-- 6. Dramatyczny czarny ekran podsumowania
		local finalName = if ejectedPlayer then ejectedPlayer.Name else "Nikt"
		local finalRole = if ejectedPlayer then ejectedPlayer:GetAttribute("Role") else "Brak"

		Remotes.get(GameConfig.RemoteEvents.MeetingResult):FireAllClients(
			finalName,
			finalRole,
			isTroublemaker
		)

		task.wait(GameConfig.Durations.SummaryBlackout)

		isMeetingActive = false

		-- 7. Przekazanie wyniku do RoundManager
		if meetingEndCallback then
			meetingEndCallback(ejectedPlayer, isTroublemaker)
		end
	end)
end

-- Rejestracja oddania głosu przez gracza
Remotes.get(GameConfig.RemoteEvents.CastVote).OnServerEvent:Connect(function(player: Player, targetName: string)
	if not isMeetingActive then return end
	if player:GetAttribute("IsAlive") ~= true then return end
	if votes[player] then return end -- Gracz już głosował

	votes[player] = targetName
	print(`[Głosowanie] {player.Name} oddał głos na: {targetName}`)
end)

return MeetingService
