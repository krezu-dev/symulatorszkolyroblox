--!strict
-- src/client/init.client.luau
-- Kompletny interfejs klienta dla gry "Szkolny Detektyw" (MM2 + Among Us w polskiej szkole):
-- 1. Górny pasek HUD (Postęp zadań 0-100%, Szkolne Monety, Stan gry)
-- 2. Karta Roli na początku rundy (Dyrektor, Rozrabiaka, Woźna, Uczeń)
-- 3. Panel Sabotaży dla Rozrabiaki (Awaria Korków, Zablokowanie Drzwi)
-- 4. Ostrzeżenia o sabotażach na ekranie
-- 5. Interfejs Zebrania i Głosowania w Stołówce (lista graczy, timer 60s, przycisk Pomiń)
-- 6. Viralowy Czarny Ekran Wyniku z muzyką (smutne pianino / dzwonek)
-- 7. Interaktywne minigry zadań szkolnych

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local tasksGuiModule = script:FindFirstChild("TasksGui") or (script.Parent and script.Parent:FindFirstChild("TasksGui")) or script:WaitForChild("TasksGui")
local TasksGui = require(tasksGuiModule :: ModuleScript)

local shopGuiModule = script:FindFirstChild("ShopGui") or (script.Parent and script.Parent:FindFirstChild("ShopGui")) or script:WaitForChild("ShopGui")
local ShopGui = require(shopGuiModule :: ModuleScript)

local memesGuiModule = script:FindFirstChild("MemesGui") or (script.Parent and script.Parent:FindFirstChild("MemesGui")) or script:WaitForChild("MemesGui")
local MemesGui = require(memesGuiModule :: ModuleScript)

-- Główny ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SzkolnyDetektywGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Inicjalizacja minigier zadań szkolnych
TasksGui.init(screenGui)

-- Inicjalizacja sklepu i monetyzacji Robux
ShopGui.init(screenGui)

-- Inicjalizacja Kukirinów, Polskich Memów i Preferencji Ról
MemesGui.init(screenGui)

-- Pływający przycisk Sklepu (dolny lewy róg)
local shopFloatingBtn = Instance.new("TextButton")
shopFloatingBtn.Name = "ShopFloatingBtn"
shopFloatingBtn.Size = UDim2.new(0, 160, 0, 42)
shopFloatingBtn.Position = UDim2.new(0, 15, 1, -55)
shopFloatingBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
shopFloatingBtn.Text = "🛍️ SKLEP & ROBUX"
shopFloatingBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
shopFloatingBtn.Font = Enum.Font.GothamBlack
shopFloatingBtn.TextSize = 13
shopFloatingBtn.ZIndex = 25
shopFloatingBtn.Parent = screenGui
Instance.new("UICorner", shopFloatingBtn).CornerRadius = UDim.new(0, 8)
local sStroke = Instance.new("UIStroke", shopFloatingBtn)
sStroke.Color = Color3.fromRGB(255, 255, 255)
sStroke.Thickness = 1.5

shopFloatingBtn.MouseButton1Click:Connect(function()
	ShopGui.toggle()
end)

-- ========================================================
-- 1. GÓRNY PASEK HUD (TOP HUD)
-- ========================================================
local topHudFrame = Instance.new("Frame")
topHudFrame.Name = "TopHudFrame"
topHudFrame.Size = UDim2.new(0, 520, 0, 75)
topHudFrame.Position = UDim2.new(0.5, -260, 0, 10)
topHudFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
topHudFrame.BackgroundTransparency = 0.25
topHudFrame.BorderSizePixel = 0
topHudFrame.Parent = screenGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topHudFrame

local topStroke = Instance.new("UIStroke")
topStroke.Color = Color3.fromRGB(60, 70, 90)
topStroke.Thickness = 1.5
topStroke.Parent = topHudFrame

-- Etykieta stanu gry
local stateLabel = Instance.new("TextLabel")
stateLabel.Name = "StateLabel"
stateLabel.Size = UDim2.new(1, -20, 0, 22)
stateLabel.Position = UDim2.new(0, 10, 0, 5)
stateLabel.BackgroundTransparency = 1
stateLabel.Text = "PRZERWA (LOBBY) - DZWONEK WKRÓTCE"
stateLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
stateLabel.Font = Enum.Font.GothamBold
stateLabel.TextSize = 14
stateLabel.Parent = topHudFrame

-- Pasek postępu zadań (Among Us Task Bar)
local taskBarBg = Instance.new("Frame")
taskBarBg.Name = "TaskBarBg"
taskBarBg.Size = UDim2.new(0.68, 0, 0, 16)
taskBarBg.Position = UDim2.new(0, 10, 0, 32)
taskBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
taskBarBg.BorderSizePixel = 0
taskBarBg.Parent = topHudFrame

local taskBarBgCorner = Instance.new("UICorner")
taskBarBgCorner.CornerRadius = UDim.new(0, 5)
taskBarBgCorner.Parent = taskBarBg

local taskBarFill = Instance.new("Frame")
taskBarFill.Name = "TaskBarFill"
taskBarFill.Size = UDim2.new(0, 0, 1, 0)
taskBarFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Zielony pasek zadań
taskBarFill.BorderSizePixel = 0
taskBarFill.Parent = taskBarBg

local taskBarFillCorner = Instance.new("UICorner")
taskBarFillCorner.CornerRadius = UDim.new(0, 5)
taskBarFillCorner.Parent = taskBarFill

local taskBarText = Instance.new("TextLabel")
taskBarText.Name = "TaskBarText"
taskBarText.Size = UDim2.new(1, 0, 1, 0)
taskBarText.BackgroundTransparency = 1
taskBarText.Text = "Zadania Szkolne: 0%"
taskBarText.TextColor3 = Color3.fromRGB(255, 255, 255)
taskBarText.Font = Enum.Font.GothamBold
taskBarText.TextSize = 11
taskBarText.Parent = taskBarBg

-- Licznik monet (MM2 Coin Bag)
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinFrame"
coinFrame.Size = UDim2.new(0.28, 0, 0, 30)
coinFrame.Position = UDim2.new(0.70, 5, 0, 26)
coinFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
coinFrame.BorderSizePixel = 0
coinFrame.Parent = topHudFrame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 6)
coinCorner.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "🪙 0 / 50 zł"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 13
coinLabel.Parent = coinFrame

-- Etykieta twojej roli
local myRoleLabel = Instance.new("TextLabel")
myRoleLabel.Name = "MyRoleLabel"
myRoleLabel.Size = UDim2.new(1, -20, 0, 16)
myRoleLabel.Position = UDim2.new(0, 10, 0, 53)
myRoleLabel.BackgroundTransparency = 1
myRoleLabel.Text = "Rola: Oczekiwanie na przydział..."
myRoleLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
myRoleLabel.Font = Enum.Font.Gotham
myRoleLabel.TextSize = 12
myRoleLabel.Parent = topHudFrame

-- ========================================================
-- 2. KARTA PREZENTACJI ROLI (ROLE CARD)
-- ========================================================
local roleCard = Instance.new("Frame")
roleCard.Name = "RoleCard"
roleCard.Size = UDim2.new(0, 420, 0, 140)
roleCard.Position = UDim2.new(0.5, -210, 0.35, 0)
roleCard.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
roleCard.BackgroundTransparency = 0.1
roleCard.Visible = false
roleCard.Parent = screenGui

local roleCardCorner = Instance.new("UICorner")
roleCardCorner.CornerRadius = UDim.new(0, 14)
roleCardCorner.Parent = roleCard

local roleCardStroke = Instance.new("UIStroke")
roleCardStroke.Color = Color3.fromRGB(255, 215, 0)
roleCardStroke.Thickness = 2
roleCardStroke.Parent = roleCard

local roleTitle = Instance.new("TextLabel")
roleTitle.Name = "RoleTitle"
roleTitle.Size = UDim2.new(1, 0, 0, 40)
roleTitle.Position = UDim2.new(0, 0, 0, 10)
roleTitle.BackgroundTransparency = 1
roleTitle.Text = "TWOJA ROLA"
roleTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
roleTitle.Font = Enum.Font.GothamBlack
roleTitle.TextSize = 24
roleTitle.Parent = roleCard

local roleDesc = Instance.new("TextLabel")
roleDesc.Name = "RoleDesc"
roleDesc.Size = UDim2.new(1, -30, 0, 70)
roleDesc.Position = UDim2.new(0, 15, 0, 55)
roleDesc.BackgroundTransparency = 1
roleDesc.Text = "Opis roli..."
roleDesc.TextColor3 = Color3.fromRGB(230, 230, 230)
roleDesc.Font = Enum.Font.Gotham
roleDesc.TextSize = 14
roleDesc.TextWrapped = true
roleDesc.Parent = roleCard

-- ========================================================
-- 3. BANER SABOTAŻU (SABOTAGE BANNER)
-- ========================================================
local sabotageBanner = Instance.new("Frame")
sabotageBanner.Name = "SabotageBanner"
sabotageBanner.Size = UDim2.new(0, 480, 0, 40)
sabotageBanner.Position = UDim2.new(0.5, -240, 0, 95)
sabotageBanner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
sabotageBanner.Visible = false
sabotageBanner.Parent = screenGui

local sabotageCorner = Instance.new("UICorner")
sabotageCorner.CornerRadius = UDim.new(0, 8)
sabotageCorner.Parent = sabotageBanner

local sabotageText = Instance.new("TextLabel")
sabotageText.Name = "SabotageText"
sabotageText.Size = UDim2.new(1, 0, 1, 0)
sabotageText.BackgroundTransparency = 1
sabotageText.Text = "⚠️ AWARIA KORKÓW! Napraw bezpieczniki w Kanciapie!"
sabotageText.TextColor3 = Color3.fromRGB(255, 255, 255)
sabotageText.Font = Enum.Font.GothamBold
sabotageText.TextSize = 13
sabotageText.Parent = sabotageBanner

-- ========================================================
-- 4. MENU SABOTAŻY DLA ROZRABIAKI (SABOTAGE ACTION MENU)
-- ========================================================
local sabotageMenu = Instance.new("Frame")
sabotageMenu.Name = "SabotageMenu"
sabotageMenu.Size = UDim2.new(0, 180, 0, 100)
sabotageMenu.Position = UDim2.new(1, -195, 1, -115)
sabotageMenu.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
sabotageMenu.BackgroundTransparency = 0.2
sabotageMenu.Visible = false
sabotageMenu.Parent = screenGui

local smCorner = Instance.new("UICorner")
smCorner.CornerRadius = UDim.new(0, 8)
smCorner.Parent = sabotageMenu

local smTitle = Instance.new("TextLabel")
smTitle.Size = UDim2.new(1, 0, 0, 22)
smTitle.BackgroundTransparency = 1
smTitle.Text = "😈 SABOTAŻE"
smTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
smTitle.Font = Enum.Font.GothamBold
smTitle.TextSize = 12
smTitle.Parent = sabotageMenu

local blackoutBtn = Instance.new("TextButton")
blackoutBtn.Name = "BlackoutBtn"
blackoutBtn.Size = UDim2.new(1, -16, 0, 30)
blackoutBtn.Position = UDim2.new(0, 8, 0, 26)
blackoutBtn.BackgroundColor3 = Color3.fromRGB(150, 25, 25)
blackoutBtn.Text = "⚡ Awaria Korków"
blackoutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
blackoutBtn.Font = Enum.Font.GothamBold
blackoutBtn.TextSize = 12
blackoutBtn.Parent = sabotageMenu
Instance.new("UICorner", blackoutBtn).CornerRadius = UDim.new(0, 6)

blackoutBtn.MouseButton1Click:Connect(function()
	Remotes.get(GameConfig.RemoteEvents.TriggerSabotage):FireServer(GameConfig.Sabotages.AwariaKorkow)
end)

local lockBtn = Instance.new("TextButton")
lockBtn.Name = "LockBtn"
lockBtn.Size = UDim2.new(1, -16, 0, 30)
lockBtn.Position = UDim2.new(0, 8, 0, 60)
lockBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
lockBtn.Text = "🔒 Zablokuj Drzwi"
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 12
lockBtn.Parent = sabotageMenu
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

lockBtn.MouseButton1Click:Connect(function()
	Remotes.get(GameConfig.RemoteEvents.TriggerSabotage):FireServer(GameConfig.Sabotages.ZablokowaneDrzwi)
end)

-- ========================================================
-- 5. INTERFEJS GŁOSOWANIA W STOŁÓWCE (MEETING SCREEN)
-- ========================================================
local meetingFrame = Instance.new("Frame")
meetingFrame.Name = "MeetingFrame"
meetingFrame.Size = UDim2.new(0, 560, 0, 360)
meetingFrame.Position = UDim2.new(0.5, -280, 0.5, -180)
meetingFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
meetingFrame.Visible = false
meetingFrame.Parent = screenGui
Instance.new("UICorner", meetingFrame).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", meetingFrame)
mStroke.Color = Color3.fromRGB(230, 160, 40)
mStroke.Thickness = 2

local meetingHeader = Instance.new("TextLabel")
meetingHeader.Size = UDim2.new(1, 0, 0, 40)
meetingHeader.BackgroundTransparency = 1
meetingHeader.Text = "🔔 ALARM SZKOLNY - ZEBRANIE W STOŁÓWCE"
meetingHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
meetingHeader.Font = Enum.Font.GothamBlack
meetingHeader.TextSize = 16
meetingHeader.Parent = meetingFrame

local meetingTimerLabel = Instance.new("TextLabel")
meetingTimerLabel.Size = UDim2.new(1, 0, 0, 20)
meetingTimerLabel.Position = UDim2.new(0, 0, 0, 38)
meetingTimerLabel.BackgroundTransparency = 1
meetingTimerLabel.Text = "Czas na głosowanie: 60 s"
meetingTimerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
meetingTimerLabel.Font = Enum.Font.Gotham
meetingTimerLabel.TextSize = 13
meetingTimerLabel.Parent = meetingFrame

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, -30, 0, 220)
playersScroll.Position = UDim2.new(0, 15, 0, 65)
playersScroll.BackgroundTransparency = 1
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.ScrollBarThickness = 6
playersScroll.Parent = meetingFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 165, 0, 45)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.Parent = playersScroll

local skipBtn = Instance.new("TextButton")
skipBtn.Name = "SkipBtn"
skipBtn.Size = UDim2.new(0, 180, 0, 35)
skipBtn.Position = UDim2.new(0.5, -90, 1, -45)
skipBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
skipBtn.Text = "Pomiń głosowanie"
skipBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
skipBtn.Font = Enum.Font.GothamBold
skipBtn.TextSize = 13
skipBtn.Parent = meetingFrame
Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)

local hasVoted = false
skipBtn.MouseButton1Click:Connect(function()
	if hasVoted then return end
	hasVoted = true
	skipBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
	skipBtn.Text = "Oddano głos (Pominięto)"
	Remotes.get(GameConfig.RemoteEvents.CastVote):FireServer(nil)
end)

-- ========================================================
-- 6. CZARNY EKRAN WYNIKU (VIRAL BLACKOUT SCREEN)
-- ========================================================
local blackoutScreen = Instance.new("Frame")
blackoutScreen.Name = "BlackoutScreen"
blackoutScreen.Size = UDim2.new(1, 0, 1, 0)
blackoutScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackoutScreen.BackgroundTransparency = 1
blackoutScreen.Visible = false
blackoutScreen.ZIndex = 50
blackoutScreen.Parent = screenGui

local blackoutText = Instance.new("TextLabel")
blackoutText.Size = UDim2.new(0.8, 0, 0.4, 0)
blackoutText.Position = UDim2.new(0.1, 0, 0.3, 0)
blackoutText.BackgroundTransparency = 1
blackoutText.Text = ""
blackoutText.TextColor3 = Color3.fromRGB(255, 255, 255)
blackoutText.Font = Enum.Font.GothamBlack
blackoutText.TextSize = 22
blackoutText.TextWrapped = true
blackoutText.ZIndex = 51
blackoutText.Parent = blackoutScreen

-- ========================================================
-- OBSŁUGA ZDARZEŃ SIECIOWYCH (NETWORK LISTENERS)
-- ========================================================

-- Aktualizacja stanu gry
Remotes.get(GameConfig.RemoteEvents.GameStateChanged).OnClientEvent:Connect(function(newState: string)
	if newState == GameConfig.GameStates.Lobby then
		stateLabel.Text = "PRZERWA (LOBBY) - DZWONEK WKRÓTCE"
		sabotageMenu.Visible = false
		sabotageBanner.Visible = false
		meetingFrame.Visible = false
		blackoutScreen.Visible = false
	elseif newState == GameConfig.GameStates.InGame then
		stateLabel.Text = "LEKCJA TRWA - WYKONUJ ZADANIA I PRZETRWAJ"
		meetingFrame.Visible = false
		blackoutScreen.Visible = false
		if localPlayer:GetAttribute("Role") == GameConfig.Roles.Rozrabiaka then
			sabotageMenu.Visible = true
		end
	elseif newState == GameConfig.GameStates.Meeting then
		stateLabel.Text = "ZEBRANIE W STOŁÓWCE - TRWA GŁOSOWANIE"
		sabotageMenu.Visible = false
	elseif newState == GameConfig.GameStates.GameOver then
		stateLabel.Text = "KONIEC LEKCJI"
		sabotageMenu.Visible = false
		meetingFrame.Visible = false
	end
end)

-- Aktualizacja paska zadań
Remotes.get(GameConfig.RemoteEvents.UpdateTaskProgress).OnClientEvent:Connect(function(progress: number)
	taskBarText.Text = `Zadania Szkolne: {progress}%`
	TweenService:Create(taskBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(progress / 100, 0, 1, 0),
	}):Play()
end)

-- Aktualizacja monet
Remotes.get(GameConfig.RemoteEvents.UpdateCoins).OnClientEvent:Connect(function(coins: number)
	coinLabel.Text = `🪙 {coins} / 50 zł`
end)

-- Przydział roli
Remotes.get(GameConfig.RemoteEvents.RoleAssigned).OnClientEvent:Connect(function(role: string)
	myRoleLabel.Text = `Twoja Rola: {role}`

	roleCard.Visible = true
	roleTitle.Text = `JESTEŚ: {string.upper(role)}`

	if role == GameConfig.Roles.Dyrektor then
		roleTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		roleDesc.Text = "Patroluj korytarze! Masz Szkolny Dziennik Ocen - rzuć nim w Rozrabiakę! Jeśli trafisz niewinnego, sam poniesiesz konsekwencje!"
		sabotageMenu.Visible = false
	elseif role == GameConfig.Roles.Rozrabiaka then
		roleTitle.TextColor3 = Color3.fromRGB(255, 60, 60)
		roleDesc.Text = "Eliminuj po cichu uczniów plastikowym nożem! Używaj kratek wentylacyjnych w zakamarkach oraz wyłączaj korki w szkole!"
		sabotageMenu.Visible = true
	elseif role == GameConfig.Roles.Wozna then
		roleTitle.TextColor3 = Color3.fromRGB(70, 180, 255)
		roleDesc.Text = "Zmywaj plamy i ślady po Rozrabiace! Naprawiasz sabotaże 2x szybciej niż zwykli uczniowie!"
		sabotageMenu.Visible = false
	else
		roleTitle.TextColor3 = Color3.fromRGB(100, 255, 120)
		roleDesc.Text = "Wykonuj zadania w salach lekcyjnych, aby zapełnić pasek w 100%! Zbieraj monety i wypatruj podejrzanych zachowań!"
		sabotageMenu.Visible = false
	end

	task.delay(4, function()
		roleCard.Visible = false
	end)
end)

-- Awans na Zastępcę Dyrektora (Gun-Drop)
Remotes.get(GameConfig.RemoteEvents.DziennikPickedUp).OnClientEvent:Connect(function(pickerName: string)
	if pickerName == localPlayer.Name then
		myRoleLabel.Text = "Twoja Rola: Zastępca Dyrektora"
		roleTitle.Text = "ZOSTAŁEŚ ZASTĘPCĄ DYREKTORA!"
		roleTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		roleDesc.Text = "Podniosłeś Szkolny Dziennik! Teraz to Ty masz broń i musisz powstrzymać Rozrabiakę!"
		roleCard.Visible = true
		task.delay(4, function() roleCard.Visible = false end)
	end
end)

-- Sabotaże
Remotes.get(GameConfig.RemoteEvents.SabotageActive).OnClientEvent:Connect(function(sabType: string, msg: string)
	sabotageBanner.Visible = true
	sabotageText.Text = msg
end)

Remotes.get(GameConfig.RemoteEvents.SabotageFixed).OnClientEvent:Connect(function(repairedBy: string)
	sabotageBanner.Visible = false
end)

-- Otwarcie Zebrania (StartMeeting)
Remotes.get(GameConfig.RemoteEvents.StartMeeting).OnClientEvent:Connect(function(timeLimit: number)
	hasVoted = false
	skipBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
	skipBtn.Text = "Pomiń głosowanie"
	meetingFrame.Visible = true

	-- Czyszczenie starych kafelków
	for _, child in ipairs(playersScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Tworzenie przycisków dla żywych graczy
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("IsAlive") == true then
			local btn = Instance.new("TextButton")
			btn.Name = `Vote_{p.Name}`
			btn.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
			btn.Text = `👤 {p.Name}`
			btn.TextColor3 = Color3.fromRGB(240, 240, 240)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 12
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			btn.Parent = playersScroll

			btn.MouseButton1Click:Connect(function()
				if hasVoted then return end
				hasVoted = true
				btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
				btn.Text = `Zagłosowano na: {p.Name}`
				Remotes.get(GameConfig.RemoteEvents.CastVote):FireServer(p)
			end)
		end
	end

	-- Odliczanie czasu
	task.spawn(function()
		local left = timeLimit or 60
		while left > 0 and meetingFrame.Visible do
			meetingTimerLabel.Text = `Czas na głosowanie: {left} s`
			task.wait(1)
			left -= 1
		end
	end)
end)

-- Wynik zebrania i czarny ekran (MeetingResult)
Remotes.get(GameConfig.RemoteEvents.MeetingResult).OnClientEvent:Connect(function(ejectedName: string?, isTroublemaker: boolean?)
	meetingFrame.Visible = false
	blackoutScreen.Visible = true
	blackoutScreen.BackgroundTransparency = 0

	local resultText = ""
	if ejectedName then
		if isTroublemaker then
			resultText = string.format(GameConfig.SummaryTexts.RozrabiakaEjected, ejectedName)
		else
			resultText = string.format(GameConfig.SummaryTexts.InnocentEjected, ejectedName)
		end
	else
		resultText = GameConfig.SummaryTexts.TieOrSkipped
	end

	blackoutText.Text = resultText

	task.delay(GameConfig.Durations.SummaryBlackout, function()
		TweenService:Create(blackoutScreen, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()
		task.wait(1)
		blackoutScreen.Visible = false
	end)
end)

print("[SzkolnyDetektyw] Interfejs klienta pomyślnie załadowany!")
