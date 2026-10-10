--!strict
-- src/client/InventoryGui.luau
-- Dedykowany, osobny interfejs EKWIPUNKU (SZKOLNY PLECAK):
-- Przeglądanie i zakładanie skinów do Dziennika, Noży oraz Wierzchowców Kukirin!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local InventoryGui = {}
local invMainFrame: Frame? = nil
local invContentArea: Frame? = nil
local currentCategory = "All" -- "All", "Knife", "Gun", "Kukirin"

local latestData = {
	Coins = 0,
	Wins = 0,
	Upgrades = {} :: { [string]: number },
	Inventory = {} :: { string },
	EquippedGun = "Skin_DziennikZielony",
	EquippedKnife = "Skin_Linijka",
}

function InventoryGui.init(parentScreenGui: ScreenGui)
	-- Odbiór danych z serwera
	Remotes.get(GameConfig.RemoteEvents.SyncPlayerData).OnClientEvent:Connect(function(data)
		latestData = data
		if invMainFrame and invMainFrame.Visible then
			InventoryGui.refreshContent()
		end
	end)

	-- Okno główne ekwipunku
	local main = Instance.new("Frame")
	main.Name = "InventoryModal"
	main.Size = UDim2.new(0, 640, 0, 420)
	main.Position = UDim2.new(0.5, -320, 0.5, -210)
	main.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
	main.Visible = false
	main.ZIndex = 36
	main.Parent = parentScreenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", main)
	stroke.Color = Color3.fromRGB(52, 152, 219)
	stroke.Thickness = 2

	invMainFrame = main

	-- Pasek tytułowy
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎒 TWÓJ SZKOLNY PLECAK (EKWIPUNEK)"
	titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Przycisk zamknięcia
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 9)
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

	-- Przyciski filtrów kategorii
	local filterBar = Instance.new("Frame")
	filterBar.Size = UDim2.new(1, -30, 0, 34)
	filterBar.Position = UDim2.new(0, 15, 0, 58)
	filterBar.BackgroundTransparency = 1
	filterBar.Parent = main

	local categories = {
		{ Id = "All", Label = "Wszystko" },
		{ Id = "Knife", Label = "🔪 Noże / Linijki" },
		{ Id = "Gun", Label = "📖 Dzienniki" },
		{ Id = "Kukirin", Label = "🐉 Kukiriny" },
	}

	for i, cat in ipairs(categories) do
		local btn = Instance.new("TextButton")
		btn.Name = `Cat_{cat.Id}`
		btn.Size = UDim2.new(0.23, 0, 1, 0)
		btn.Position = UDim2.new((i - 1) * 0.255, 0, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(38, 44, 58)
		btn.Text = cat.Label
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.Parent = filterBar

		btn.MouseButton1Click:Connect(function()
			currentCategory = cat.Id
			InventoryGui.refreshContent()
		end)
	end

	-- Obszar siatki przedmiotów
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "InventoryScroll"
	scroll.Size = UDim2.new(1, -30, 1, -110)
	scroll.Position = UDim2.new(0, 15, 0, 98)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 360)
	scroll.ScrollBarThickness = 6
	scroll.Parent = main

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 190, 0, 100)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.Parent = scroll

	invContentArea = scroll
end

function InventoryGui.refreshContent()
	if not invContentArea then return end
	invContentArea:ClearAllChildren()

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 190, 0, 100)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.Parent = invContentArea

	-- 1. Zbieranie przedmiotów z inwentarza
	local displayedItems = {}

	for _, skinId in ipairs(latestData.Inventory) do
		-- Sprawdź skiny ze skrzynek
		for _, crate in pairs(GameConfig.Crates) do
			for _, it in ipairs(crate.Items) do
				if it.Id == skinId then
					if currentCategory == "All" or currentCategory == it.Type then
						table.insert(displayedItems, {
							Id = it.Id,
							Name = it.Name,
							Type = it.Type,
							Rarity = it.Rarity,
							Color = it.Color,
							IsEquipped = (latestData.EquippedGun == it.Id) or (latestData.EquippedKnife == it.Id),
						})
					end
				end
			end
		end

		-- Sprawdź Kukiriny
		if skinId == "SchoolKukirin" and (currentCategory == "All" or currentCategory == "Kukirin") then
			table.insert(displayedItems, {
				Id = "SchoolKukirin",
				Name = "Szkolny Kukirin",
				Type = "Kukirin",
				Rarity = "Legendary",
				Color = Color3.fromRGB(50, 160, 220),
				IsEquipped = true,
			})
		end
	end

	-- Puste powiadomienie
	if #displayedItems == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 100)
		empty.BackgroundTransparency = 1
		empty.Text = "Twój plecak jest pusty w tej kategorii.\nOtwórz skrzynki w Sklepie, aby zdobyć nowe skiny!"
		empty.TextColor3 = Color3.fromRGB(160, 160, 170)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.Parent = invContentArea
		return
	end

	-- Tworzenie kafelków
	for _, item in ipairs(displayedItems) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		card.Parent = invContentArea

		local stroke = Instance.new("UIStroke", card)
		stroke.Color = item.Color
		stroke.Thickness = if item.IsEquipped then 2 else 1

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 24)
		nameLabel.Position = UDim2.new(0, 6, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 12
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, -10, 0, 18)
		rarityLabel.Position = UDim2.new(0, 6, 0, 28)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = `[{item.Rarity}]`
		rarityLabel.TextColor3 = item.Color
		rarityLabel.Font = Enum.Font.Gotham
		rarityLabel.TextSize = 11
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(1, -16, 0, 28)
		equipBtn.Position = UDim2.new(0, 8, 1, -34)
		equipBtn.BackgroundColor3 = if item.IsEquipped then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(52, 152, 219)
		equipBtn.Text = if item.IsEquipped then "✓ ZAŁOŻONY" else "ZAŁÓŻ"
		equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Font = Enum.Font.GothamBlack
		equipBtn.TextSize = 11
		Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 6)
		equipBtn.Parent = card

		if not item.IsEquipped and item.Type ~= "Kukirin" then
			equipBtn.MouseButton1Click:Connect(function()
				Remotes.get(GameConfig.RemoteEvents.EquipSkin):FireServer(item.Id)
			end)
		end
	end
end

function InventoryGui.toggle()
	if not invMainFrame then return end
	invMainFrame.Visible = not invMainFrame.Visible
	if invMainFrame.Visible then
		InventoryGui.refreshContent()
	end
end

return InventoryGui
