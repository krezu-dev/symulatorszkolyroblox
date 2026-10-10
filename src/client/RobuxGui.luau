--!strict
-- src/client/RobuxGui.luau
-- Dedykowany, niezależny interfejs zakupu Gamepassów i Pakietów Monet za Robux:
-- 1. Gamepassy (VIP, Złoty Kukirin, 3x Szansa Impostor/Dyrektor, Adidasy, Plecak, Radiomagnetofon, Memy)
-- 2. Developer Products (Kieszonkowe 100 monet, Wyprawka 500 monet, Stypendium 2000 monet)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local RobuxGui = {}
local robuxMainFrame: Frame? = nil
local contentScroll: ScrollingFrame? = nil

function RobuxGui.init(parentScreenGui: ScreenGui)
	-- Okno główne sklepu Robux
	local main = Instance.new("Frame")
	main.Name = "RobuxMainModal"
	main.Size = UDim2.new(0, 680, 0, 480)
	main.Position = UDim2.new(0.5, -340, 0.5, -240)
	main.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	main.Visible = false
	main.ZIndex = 36
	main.Parent = parentScreenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", main)
	stroke.Color = Color3.fromRGB(0, 180, 255)
	stroke.Thickness = 2.5

	robuxMainFrame = main

	-- Pasek tytułowy
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 52)
	titleBar.BackgroundColor3 = Color3.fromRGB(26, 32, 45)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "💎 OFICJALNY SKLEP ROBUX & GAMEPASSY"
	titleLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Przycisk zamknięcia
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		main.Visible = false
	end)

	-- Obszar przewijania z ofertami
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "RobuxContentScroll"
	scroll.Size = UDim2.new(1, -30, 1, -70)
	scroll.Position = UDim2.new(0, 15, 0, 60)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 750)
	scroll.ScrollBarThickness = 6
	scroll.Parent = main
	contentScroll = scroll

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.Parent = scroll

	-- ========================================================
	-- SEKCJA 1: GAMEPASSY ZA ROBUX
	-- ========================================================
	local gpHeader = Instance.new("TextLabel")
	gpHeader.Size = UDim2.new(1, 0, 0, 28)
	gpHeader.BackgroundTransparency = 1
	gpHeader.Text = "⭐ NAJLEPSZE GAMEPASSY SZKOLNE:"
	gpHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
	gpHeader.Font = Enum.Font.GothamBlack
	gpHeader.TextSize = 15
	gpHeader.TextXAlignment = Enum.TextXAlignment.Left
	gpHeader.Parent = scroll

	for key, gp in pairs(GameConfig.Gamepasses) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 68)
		card.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local cardStroke = Instance.new("UIStroke", card)
		cardStroke.Color = Color3.fromRGB(50, 65, 90)
		cardStroke.Thickness = 1
		card.Parent = scroll

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 48, 1, 0)
		iconLabel.Position = UDim2.new(0, 10, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = gp.Icon or "⭐"
		iconLabel.TextSize = 28
		iconLabel.Parent = card

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.65, 0, 0, 24)
		title.Position = UDim2.new(0, 65, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = gp.Name
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.65, 0, 0, 24)
		desc.Position = UDim2.new(0, 65, 0, 34)
		desc.BackgroundTransparency = 1
		desc.Text = gp.Description
		desc.TextColor3 = Color3.fromRGB(180, 200, 225)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 125, 0, 38)
		buyBtn.Position = UDim2.new(1, -135, 0.5, -19)
		buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		buyBtn.Text = `Kup: {gp.Price} R$`
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBlack
		buyBtn.TextSize = 13
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
		buyBtn.Parent = card

		buyBtn.MouseButton1Click:Connect(function()
			Remotes.get(GameConfig.RemoteEvents.PromptGamePass):FireServer(key)
		end)
	end

	-- ========================================================
	-- SEKCJA 2: SZKOLNE MONETY ZA ROBUX
	-- ========================================================
	local coinsHeader = Instance.new("TextLabel")
	coinsHeader.Size = UDim2.new(1, 0, 0, 28)
	coinsHeader.BackgroundTransparency = 1
	coinsHeader.Text = "🪙 PAKIETY MONET NA SKRZYNKI & ULEPSZENIA:"
	coinsHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsHeader.Font = Enum.Font.GothamBlack
	coinsHeader.TextSize = 15
	coinsHeader.TextXAlignment = Enum.TextXAlignment.Left
	coinsHeader.Parent = scroll

	for key, prod in pairs(GameConfig.DevProducts) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 62)
		card.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		card.Parent = scroll

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 48, 1, 0)
		iconLabel.Position = UDim2.new(0, 10, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = prod.Icon or "🪙"
		iconLabel.TextSize = 26
		iconLabel.Parent = card

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.65, 0, 1, 0)
		title.Position = UDim2.new(0, 65, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = `{prod.Name} (+{prod.Coins} Szkolnych Monet)`
		title.TextColor3 = Color3.fromRGB(245, 245, 245)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 125, 0, 36)
		buyBtn.Position = UDim2.new(1, -135, 0.5, -18)
		buyBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
		buyBtn.Text = `Kup: {prod.Price} R$`
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBlack
		buyBtn.TextSize = 13
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
		buyBtn.Parent = card

		buyBtn.MouseButton1Click:Connect(function()
			Remotes.get(GameConfig.RemoteEvents.PromptDevProduct):FireServer(key)
		end)
	end
end

function RobuxGui.toggle()
	if not robuxMainFrame then return end
	robuxMainFrame.Visible = not robuxMainFrame.Visible
end

return RobuxGui
