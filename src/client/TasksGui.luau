--!strict
-- src/client/TasksGui.luau
-- Interaktywne minigry szkolne (Among Us Tasks w klimacie polskiej szkoły):
-- 1. Matematyka (Równanie na tablicy)
-- 2. Język Polski (Dyktando ortograficzne)
-- 3. Stołówka (Zjadanie pierogów z talerza)
-- 4. Szafki (Układanie podręczników)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local TasksGui = {}
local mainTaskContainer: Frame? = nil

function TasksGui.init(parentScreenGui: ScreenGui)
	-- Główny kontener na aktywne okno minigry
	local container = Instance.new("Frame")
	container.Name = "ActiveTaskContainer"
	container.Size = UDim2.new(0, 480, 0, 340)
	container.Position = UDim2.new(0.5, -240, 0.5, -170)
	container.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
	container.Visible = false
	container.ZIndex = 30
	container.Parent = parentScreenGui

	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", container)
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2

	mainTaskContainer = container

	-- Podpięcie pod zdarzenie otwierania minigry
	local openTaskRemote = Remotes.get(GameConfig.RemoteEvents.OpenTaskGui)
	openTaskRemote.OnClientEvent:Connect(function(taskId: string)
		TasksGui.openTask(taskId)
	end)
end

local function finishTask(taskId: string, rewardMsg: string)
	if not mainTaskContainer then return end

	-- Sukces i powiadomienie serwera
	Remotes.get(GameConfig.RemoteEvents.TaskCompleted):FireServer(taskId)

	mainTaskContainer:ClearAllChildren()
	Instance.new("UICorner", mainTaskContainer).CornerRadius = UDim.new(0, 14)

	local successLabel = Instance.new("TextLabel")
	successLabel.Size = UDim2.new(1, 0, 1, 0)
	successLabel.BackgroundTransparency = 1
	successLabel.Text = `✅ ZADANIE UKOŃCZONE!\n{rewardMsg}`
	successLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
	successLabel.Font = Enum.Font.GothamBold
	successLabel.TextSize = 20
	successLabel.Parent = mainTaskContainer

	task.delay(1.5, function()
		if mainTaskContainer then
			mainTaskContainer.Visible = false
			mainTaskContainer:ClearAllChildren()
		end
	end)
end

local function addCloseButton(container: Frame)
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 32, 0, 32)
	close.Position = UDim2.new(1, -40, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	close.Text = "✕"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.Parent = container
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

	close.MouseButton1Click:Connect(function()
		container.Visible = false
		container:ClearAllChildren()
	end)
end

-- 1. MINIGRA: MATEMATYKA (TABLICA SZKOLNA)
local function buildMatematykaTask(container: Frame)
	container.BackgroundColor3 = Color3.fromRGB(25, 45, 30) -- Zielona tablica szkolna

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 35)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "📐 KARTKÓWKA Z MATEMATYKI (SALA 201)"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = container

	local question = Instance.new("TextLabel")
	question.Size = UDim2.new(1, -40, 0, 60)
	question.Position = UDim2.new(0, 20, 0, 55)
	question.BackgroundTransparency = 1
	question.Text = "Oblicz wynik równania:\n7 × 8 = ?"
	question.TextColor3 = Color3.fromRGB(255, 255, 200)
	question.Font = Enum.Font.GothamBlack
	question.TextSize = 22
	question.Parent = container

	local options = {
		{ Text = "48", Correct = false },
		{ Text = "54", Correct = false },
		{ Text = "56", Correct = true },
		{ Text = "63", Correct = false },
	}

	for i, opt in ipairs(options) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 95, 0, 50)
		btn.Position = UDim2.new(0, 25 + (i - 1) * 110, 0, 150)
		btn.BackgroundColor3 = Color3.fromRGB(40, 70, 50)
		btn.Text = opt.Text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 20
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = container

		btn.MouseButton1Click:Connect(function()
			if opt.Correct then
				btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				finishTask("Matematyka", "Ocena: Celujący (6)! +15 Szkolnych Złotych")
			else
				btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				btn.Text = "Źle!"
			end
		end)
	end
end

-- 2. MINIGRA: JĘZYK POLSKI (DYKTANDO)
local function buildJezykPolskiTask(container: Frame)
	container.BackgroundColor3 = Color3.fromRGB(35, 30, 45)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 35)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "📖 DYKTANDO Z POLSKIEGO (SALA 202)"
	title.TextColor3 = Color3.fromRGB(255, 220, 150)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = container

	local question = Instance.new("TextLabel")
	question.Size = UDim2.new(1, -40, 0, 50)
	question.Position = UDim2.new(0, 20, 0, 55)
	question.BackgroundTransparency = 1
	question.Text = "Wybierz w 100% poprawną pisownię:"
	question.TextColor3 = Color3.fromRGB(255, 255, 255)
	question.Font = Enum.Font.GothamBold
	question.TextSize = 16
	question.Parent = container

	local options = {
		{ Text = "Gżegżółka", Correct = true },
		{ Text = "Grzegżułka", Correct = false },
		{ Text = "Gżegżułka", Correct = false },
		{ Text = "Grzegżółka", Correct = false },
	}

	for i, opt in ipairs(options) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 200, 0, 40)
		local col = if i % 2 == 1 then 30 else 250
		local row = if i <= 2 then 120 else 175
		btn.Position = UDim2.new(0, col, 0, row)
		btn.BackgroundColor3 = Color3.fromRGB(60, 50, 80)
		btn.Text = opt.Text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 15
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = container

		btn.MouseButton1Click:Connect(function()
			if opt.Correct then
				btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				finishTask("JezykPolski", "Bez błędu ortograficznego! +15 Szkolnych Złotych")
			else
				btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				btn.Text = "Błąd ortograficzny!"
			end
		end)
	end
end

-- 3. MINIGRA: STOŁÓWKA (PIEROGI)
local function buildStolowkaTask(container: Frame)
	container.BackgroundColor3 = Color3.fromRGB(45, 35, 25)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 35)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🥟 SZKOLNY OBIAD (STOŁÓWKA)"
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = container

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 25)
	sub.Position = UDim2.new(0, 0, 0, 45)
	sub.BackgroundTransparency = 1
	sub.Text = "Kliknij pierogi, aby zjeść cały obiad!"
	sub.TextColor3 = Color3.fromRGB(230, 230, 230)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 13
	sub.Parent = container

	local pierogiLeft = 5
	local counterLabel = Instance.new("TextLabel")
	counterLabel.Size = UDim2.new(1, 0, 0, 30)
	counterLabel.Position = UDim2.new(0, 0, 0, 75)
	counterLabel.BackgroundTransparency = 1
	counterLabel.Text = `Pozostało pierogów: {pierogiLeft} / 5`
	counterLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	counterLabel.Font = Enum.Font.GothamBold
	counterLabel.TextSize = 16
	counterLabel.Parent = container

	local plate = Instance.new("Frame")
	plate.Size = UDim2.new(0, 140, 0, 140)
	plate.Position = UDim2.new(0.5, -70, 0, 120)
	plate.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
	Instance.new("UICorner", plate).CornerRadius = UDim.new(1, 0)
	plate.Parent = container

	local eatBtn = Instance.new("TextButton")
	eatBtn.Size = UDim2.new(1, 0, 1, 0)
	eatBtn.BackgroundTransparency = 1
	eatBtn.Text = "🥟🥟\n🥟🥟🥟"
	eatBtn.TextSize = 32
	eatBtn.Parent = plate

	eatBtn.MouseButton1Click:Connect(function()
		pierogiLeft -= 1
		counterLabel.Text = `Pozostało pierogów: {pierogiLeft} / 5`

		if pierogiLeft <= 0 then
			eatBtn.Text = "Pusty talerz!"
			finishTask("StolowkaPierogi", "Obiad zjedzony! Kompot wypity! +20 Szkolnych Złotych")
		else
			local icons = string.rep("🥟", pierogiLeft)
			eatBtn.Text = icons
		end
	end)
end

-- 4. MINIGRA: SZAFKA (UPORZĄDKUJ KSIĄŻKI)
local function buildSzafkiTask(container: Frame)
	container.BackgroundColor3 = Color3.fromRGB(35, 40, 48)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 35)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "📚 PORZĄDEK W SZAFCE (KORYTARZ)"
	title.TextColor3 = Color3.fromRGB(150, 220, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = container

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 30)
	desc.Position = UDim2.new(0, 0, 0, 50)
	desc.BackgroundTransparency = 1
	desc.Text = "Kliknij książki w kolejności, aby ułożyć je na półce!"
	desc.TextColor3 = Color3.fromRGB(220, 220, 220)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 13
	desc.Parent = container

	local books = { "1. Matematyka", "2. Język Polski", "3. Historia", "4. Biologia" }
	local currentStep = 1

	for i, bName in ipairs(books) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 190, 0, 42)
		local col = if i % 2 == 1 then 35 else 255
		local row = if i <= 2 then 100 else 155
		btn.Position = UDim2.new(0, col, 0, row)
		btn.BackgroundColor3 = Color3.fromRGB(55, 65, 80)
		btn.Text = bName
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = container

		btn.MouseButton1Click:Connect(function()
			if i == currentStep then
				btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				currentStep += 1
				if currentStep > #books then
					finishTask("SzafkiKsiazki", "Szafka lśni czystością! +20 Szkolnych Złotych")
				end
			else
				btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
				task.delay(0.5, function()
					if btn and btn.Parent then
						btn.BackgroundColor3 = Color3.fromRGB(55, 65, 80)
					end
				end)
			end
		end)
	end
end

-- 5. MINIGRA: TEST PIZZY U KSIĘCIULA (MUALA!)
local function buildPizzaTask(container: Frame)
	container.BackgroundColor3 = Color3.fromRGB(36, 28, 24)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 32)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🍕 WIELKI TEST PIZZY KSIĘCIULA (MUALA!)"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -30, 0, 20)
	subtitle.Position = UDim2.new(0, 15, 0, 42)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Sklepik Szkolny • Cena: 6,00 zł • 'Czy to jest warte swojej ceny?!'"
	subtitle.TextColor3 = Color3.fromRGB(200, 210, 220)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = container

	-- Karta podglądu pizzy
	local pizzaFrame = Instance.new("Frame")
	pizzaFrame.Size = UDim2.new(0, 130, 0, 130)
	pizzaFrame.Position = UDim2.new(0.5, -65, 0, 70)
	pizzaFrame.BackgroundColor3 = Color3.fromRGB(50, 40, 35)
	Instance.new("UICorner", pizzaFrame).CornerRadius = UDim.new(0, 14)
	local pStroke = Instance.new("UIStroke", pizzaFrame)
	pStroke.Color = Color3.fromRGB(243, 156, 18)
	pStroke.Thickness = 2
	pizzaFrame.Parent = container

	local pizzaIcon = Instance.new("TextLabel")
	pizzaIcon.Size = UDim2.new(1, 0, 1, 0)
	pizzaIcon.BackgroundTransparency = 1
	pizzaIcon.Text = "🍕"
	pizzaIcon.TextSize = 75
	pizzaIcon.Parent = pizzaFrame

	-- Podpis pod pizzą
	local verdictPrompt = Instance.new("TextLabel")
	verdictPrompt.Size = UDim2.new(1, -30, 0, 24)
	verdictPrompt.Position = UDim2.new(0, 15, 0, 210)
	verdictPrompt.BackgroundTransparency = 1
	verdictPrompt.Text = "Wystaw ostateczny werdykt w teście smaku:"
	verdictPrompt.TextColor3 = Color3.fromRGB(255, 230, 150)
	verdictPrompt.Font = Enum.Font.GothamBold
	verdictPrompt.TextSize = 13
	verdictPrompt.Parent = container

	-- Przyciski oceny
	local choices = {
		{ Text = "Zimne ciasto i guma (3/10)", Correct = false },
		{ Text = "🍕 CZYSTA MUALA! (10/10)", Correct = true },
		{ Text = "Za dużo ketchupu (5/10)", Correct = false },
	}

	for i, ch in ipairs(choices) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 140, 0, 44)
		btn.Position = UDim2.new(0, 15 + (i - 1) * 150, 0, 245)
		btn.BackgroundColor3 = if ch.Correct then Color3.fromRGB(230, 126, 34) else Color3.fromRGB(60, 50, 50)
		btn.Text = ch.Text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextWrapped = true
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = container

		btn.MouseButton1Click:Connect(function()
			if ch.Correct then
				btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				btn.Text = "✨ MUALA! 10/10 ✨"
				finishTask("TestPizzyKsiezula", "MUALA! Pizza Księciula przetestowana! +25 Szkolnych Złotych")
			else
				btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
				task.delay(0.5, function()
					if btn and btn.Parent then
						btn.BackgroundColor3 = Color3.fromRGB(60, 50, 50)
					end
				end)
			end
		end)
	end
end

function TasksGui.openTask(taskId: string)
	if not mainTaskContainer then return end

	mainTaskContainer:ClearAllChildren()
	Instance.new("UICorner", mainTaskContainer).CornerRadius = UDim.new(0, 14)
	addCloseButton(mainTaskContainer)

	if taskId == "Matematyka" then
		buildMatematykaTask(mainTaskContainer)
	elseif taskId == "JezykPolski" then
		buildJezykPolskiTask(mainTaskContainer)
	elseif taskId == "StolowkaPierogi" then
		buildStolowkaTask(mainTaskContainer)
	elseif taskId == "SzafkiKsiazki" then
		buildSzafkiTask(mainTaskContainer)
	elseif taskId == "TestPizzyKsiezula" then
		buildPizzaTask(mainTaskContainer)
	else
		-- Domyślne szybkie zadanie
		buildMatematykaTask(mainTaskContainer)
	end

	mainTaskContainer.Visible = true
end

return TasksGui
