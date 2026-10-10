--!strict
-- src/client/ShopGui.luau
-- Interaktywny Sklep w Grze (Shop & Monetization GUI):
-- Zakładka 1: Skrzynki ze skinami broni (MM2 Unboxing z animacją)
-- Zakładka 2: Ulepszenia postaci za monety (Kondycja, Cichobiegi, Radar)
-- Zakładka 3: Sklep Robux (Gamepassy i Pakiety Monet)
-- Zakładka 4: Mój Ekwipunek (Przeglądanie i zmiana skinów)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopGui = {}
local shopMainFrame: Frame? = nil
local currentTab = "Crates"
local contentArea: Frame? = nil

local latestData = {
	Coins = 0,
	Wins = 0,
	Upgrades = {} :: { [string]: number },
	Inventory = {} :: { string },
	EquippedGun = "",
	EquippedKnife = "",
}

function ShopGui.init(parentScreenGui: ScreenGui)
	-- Odbiór danych gracza z serwera
	Remotes.get(GameConfig.RemoteEvents.SyncPlayerData).OnClientEvent:Connect(function(data)
		latestData = data
		if shopMainFrame and shopMainFrame.Visible then
			ShopGui.refreshContent()
		end
	end)

	-- Okno główne sklepu
	local main = Instance.new("Frame")
	main.Name = "ShopMainModal"
	main.Size = UDim2.new(0, 680, 0, 440)
	main.Position = UDim2.new(0.5, -340, 0.5, -220)
	main.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
	main.Visible = false
	main.ZIndex = 35
	main.Parent = parentScreenGui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", main)
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2

	shopMainFrame = main

	-- Pasek tytułowy
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(32, 35, 46)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🛍️ SKLEP SZKOLNY"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
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

	-- Pasek zakładek (Tabs)
	local tabsFrame = Instance.new("Frame")
	tabsFrame.Size = UDim2.new(1, -30, 0, 36)
	tabsFrame.Position = UDim2.new(0, 15, 0, 58)
	tabsFrame.BackgroundTransparency = 1
	tabsFrame.Parent = main

	local tabButtons = {
		{ Id = "Crates", Label = "📦 Skrzynki MM2" },
		{ Id = "Upgrades", Label = "⚡ Ulepszenia za Monety" },
	}

	for i, tab in ipairs(tabButtons) do
		local btn = Instance.new("TextButton")
		btn.Name = `Tab_{tab.Id}`
		btn.Size = UDim2.new(0.48, 0, 1, 0)
		btn.Position = UDim2.new((i - 1) * 0.52, 0, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(40, 44, 58)
		btn.Text = tab.Label
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = tabsFrame

		btn.MouseButton1Click:Connect(function()
			currentTab = tab.Id
			ShopGui.refreshContent()
		end)
	end

	-- Obszar zawartości (Content Area)
	local content = Instance.new("Frame")
	content.Name = "ContentArea"
	content.Size = UDim2.new(1, -30, 1, -110)
	content.Position = UDim2.new(0, 15, 0, 100)
	content.BackgroundTransparency = 1
	content.Parent = main

	contentArea = content

	-- Podpięcie pod animację otwarcia skrzynki (CrateOpened)
	Remotes.get(GameConfig.RemoteEvents.CrateOpened).OnClientEvent:Connect(function(wonItem)
		ShopGui.showUnboxAnimation(wonItem)
	end)
end

-- ========================================================
-- 1. ZAKŁADKA: SKRZYNKI & UNBOXING (MM2 STYLE)
-- ========================================================
local function renderCratesTab(parent: Frame)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
	scroll.ScrollBarThickness = 6
	scroll.Parent = parent

	for _, crate in pairs(GameConfig.Crates) do
		local crateCard = Instance.new("Frame")
		crateCard.Size = UDim2.new(1, -10, 0, 130)
		crateCard.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
		Instance.new("UICorner", crateCard).CornerRadius = UDim.new(0, 10)
		crateCard.Parent = scroll

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 80, 0, 80)
		icon.Position = UDim2.new(0, 15, 0, 25)
		icon.BackgroundTransparency = 1
		icon.Text = crate.Icon or "📦"
		icon.TextSize = 48
		icon.Parent = crateCard

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0.5, 0, 0, 25)
		name.Position = UDim2.new(0, 105, 0, 15)
		name.BackgroundTransparency = 1
		name.Text = crate.Name
		name.TextColor3 = Color3.fromRGB(255, 215, 0)
		name.Font = Enum.Font.GothamBlack
		name.TextSize = 16
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = crateCard

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.5, 0, 0, 45)
		desc.Position = UDim2.new(0, 105, 0, 42)
		desc.BackgroundTransparency = 1
		desc.Text = "Zawiera rzadkie skiny do Szkolnego Dziennika i Plastikowego Noża (w tym mityczny Płonący Dziennik Ocen!)"
		desc.TextColor3 = Color3.fromRGB(200, 200, 200)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = crateCard

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 150, 0, 42)
		buyBtn.Position = UDim2.new(1, -165, 0.5, -21)
		buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		buyBtn.Text = `Otwórz za {crate.Cost} 🪙`
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBlack
		buyBtn.TextSize = 14
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
		buyBtn.Parent = crateCard

		buyBtn.MouseButton1Click:Connect(function()
			Remotes.get(GameConfig.RemoteEvents.BuyCrate):FireServer(crate.Id)
		end)
	end
end

-- ========================================================
-- 2. ZAKŁADKA: ULEPSZENIA ZA MONETY
-- ========================================================
local function renderUpgradesTab(parent: Frame)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 360)
	scroll.ScrollBarThickness = 6
	scroll.Parent = parent

	local grid = Instance.new("UIListLayout")
	grid.Padding = UDim.new(0, 10)
	grid.Parent = scroll

	for _, up in pairs(GameConfig.Upgrades) do
		local currentLvl = latestData.Upgrades[up.Id] or 0
		local isMax = currentLvl >= up.MaxLevel
		local cost = up.CostPerLevel * (currentLvl + 1)

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 75)
		card.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		card.Parent = scroll

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.6, 0, 0, 25)
		title.Position = UDim2.new(0, 15, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = `{up.Icon} {up.Name} (Poz. {currentLvl} / {up.MaxLevel})`
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.6, 0, 0, 25)
		desc.Position = UDim2.new(0, 15, 0, 38)
		desc.BackgroundTransparency = 1
		desc.Text = up.Description
		desc.TextColor3 = Color3.fromRGB(180, 190, 205)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = card

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 130, 0, 38)
		btn.Position = UDim2.new(1, -145, 0.5, -19)
		btn.BackgroundColor3 = if isMax then Color3.fromRGB(70, 75, 85) else Color3.fromRGB(52, 152, 219)
		btn.Text = if isMax then "MAX" else `Ulepsz: {cost} 🪙`
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.Parent = card

		if not isMax then
			btn.MouseButton1Click:Connect(function()
				Remotes.get(GameConfig.RemoteEvents.BuyUpgrade):FireServer(up.Id)
			end)
		end
	end

	-- Karta zakupu Szkolnego Kukirina
	local hasSchoolKukirin = table.find(latestData.Inventory, "SchoolKukirin") ~= nil
	local kCard = Instance.new("Frame")
	kCard.Size = UDim2.new(1, -10, 0, 75)
	kCard.BackgroundColor3 = Color3.fromRGB(30, 45, 60)
	Instance.new("UICorner", kCard).CornerRadius = UDim.new(0, 8)
	kCard.Parent = scroll

	local kTitle = Instance.new("TextLabel")
	kTitle.Size = UDim2.new(0.6, 0, 0, 25)
	kTitle.Position = UDim2.new(0, 15, 0, 10)
	kTitle.BackgroundTransparency = 1
	kTitle.Text = "🐾 Szkolny Kukirin Biegacz (Wierzchowiec)"
	kTitle.TextColor3 = Color3.fromRGB(100, 220, 255)
	kTitle.Font = Enum.Font.GothamBold
	kTitle.TextSize = 14
	kTitle.TextXAlignment = Enum.TextXAlignment.Left
	kTitle.Parent = kCard

	local kDesc = Instance.new("TextLabel")
	kDesc.Size = UDim2.new(0.6, 0, 0, 25)
	kDesc.Position = UDim2.new(0, 15, 0, 38)
	kDesc.BackgroundTransparency = 1
	kDesc.Text = "Dosiądź szkolnego Kukirina! Daje +4 prędkości i ryk Kukirina!"
	kDesc.TextColor3 = Color3.fromRGB(180, 210, 230)
	kDesc.Font = Enum.Font.Gotham
	kDesc.TextSize = 11
	kDesc.TextXAlignment = Enum.TextXAlignment.Left
	kDesc.Parent = kCard

	local kBtn = Instance.new("TextButton")
	kBtn.Size = UDim2.new(0, 130, 0, 38)
	kBtn.Position = UDim2.new(1, -145, 0.5, -19)
	kBtn.BackgroundColor3 = if hasSchoolKukirin then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(241, 196, 15)
	kBtn.Text = if hasSchoolKukirin then "✓ POSIADANY" else "Kup: 300 🪙"
	kBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	kBtn.Font = Enum.Font.GothamBlack
	kBtn.TextSize = 12
	Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 6)
	kBtn.Parent = kCard

	if not hasSchoolKukirin then
		kBtn.MouseButton1Click:Connect(function()
			Remotes.get(GameConfig.RemoteEvents.BuyUpgrade):FireServer("SchoolKukirin")
		end)
	end
end

function ShopGui.refreshContent()
	if not contentArea then return end
	contentArea:ClearAllChildren()

	if currentTab == "Crates" then
		renderCratesTab(contentArea)
	elseif currentTab == "Upgrades" then
		renderUpgradesTab(contentArea)
	end
end

-- ========================================================
-- ANIMACJA OTWARCIA SKRZYNKI (MM2 UNBOXING ANIMATION)
-- ========================================================
function ShopGui.showUnboxAnimation(wonItem: any)
	if not shopMainFrame then return end

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.ZIndex = 50
	overlay.Parent = shopMainFrame
	Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 14)

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 260, 0, 220)
	card.Position = UDim2.new(0.5, -130, 0.5, -110)
	card.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	card.ZIndex = 51
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = wonItem.Color
	stroke.Thickness = 3
	card.Parent = overlay

	local unboxTitle = Instance.new("TextLabel")
	unboxTitle.Size = UDim2.new(1, 0, 0, 30)
	unboxTitle.Position = UDim2.new(0, 0, 0, 10)
	unboxTitle.BackgroundTransparency = 1
	unboxTitle.Text = "🎉 NOWY PRZEDMIOT!"
	unboxTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	unboxTitle.Font = Enum.Font.GothamBlack
	unboxTitle.TextSize = 16
	unboxTitle.ZIndex = 52
	unboxTitle.Parent = card

	local itemName = Instance.new("TextLabel")
	itemName.Size = UDim2.new(1, -20, 0, 40)
	itemName.Position = UDim2.new(0, 10, 0, 60)
	itemName.BackgroundTransparency = 1
	itemName.Text = wonItem.Name
	itemName.TextColor3 = wonItem.Color
	itemName.Font = Enum.Font.GothamBlack
	itemName.TextSize = 20
	itemName.TextScaled = true
	itemName.ZIndex = 52
	itemName.Parent = card

	local itemRarity = Instance.new("TextLabel")
	itemRarity.Size = UDim2.new(1, 0, 0, 25)
	itemRarity.Position = UDim2.new(0, 0, 0, 110)
	itemRarity.BackgroundTransparency = 1
	itemRarity.Text = `Rzadkość: {wonItem.Rarity}`
	itemRarity.TextColor3 = Color3.fromRGB(220, 220, 220)
	itemRarity.Font = Enum.Font.GothamBold
	itemRarity.TextSize = 14
	itemRarity.ZIndex = 52
	itemRarity.Parent = card

	local okBtn = Instance.new("TextButton")
	okBtn.Size = UDim2.new(0, 140, 0, 38)
	okBtn.Position = UDim2.new(0.5, -70, 1, -48)
	okBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	okBtn.Text = "Odbierz!"
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.Font = Enum.Font.GothamBold
	okBtn.TextSize = 14
	okBtn.ZIndex = 52
	Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 8)
	okBtn.Parent = card

	okBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
		ShopGui.refreshContent()
	end)
end

function ShopGui.toggle()
	if not shopMainFrame then return end
	shopMainFrame.Visible = not shopMainFrame.Visible
	if shopMainFrame.Visible then
		ShopGui.refreshContent()
	end
end

return ShopGui
