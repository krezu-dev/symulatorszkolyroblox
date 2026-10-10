--!strict
-- src/server/MonetizationService.luau
-- Obsługa płatności Robux przez MarketplaceService:
-- 1. Gamepassy (VIP, Boombox, Adidasy +25% Speed, Duży Plecak, Szansa na Rolę x2)
-- 2. Produkty Deweloperskie / Pakiety Monet (ProcessReceipt)
-- 3. Złoty czat i tagi VIP

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local ProfileDataService = require(script.Parent:WaitForChild("ProfileDataService"))

local MonetizationService = {}
local playerGamepasses: { [Player]: { [string]: boolean } } = {}

-- Sprawdza czy gracz posiada dany gamepass (z pamięcią podręczną)
function MonetizationService.hasGamepass(player: Player, passKey: string): boolean
	local cached = playerGamepasses[player]
	if cached and cached[passKey] ~= nil then
		return cached[passKey]
	end

	local passDef = GameConfig.Gamepasses[passKey]
	if not passDef then return false end

	local hasPass = false
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passDef.Id)
	end)
	if success then
		hasPass = (result == true)
	end

	if not playerGamepasses[player] then
		playerGamepasses[player] = {}
	end
	playerGamepasses[player][passKey] = hasPass
	return hasPass
end

-- Daje bonusy gamepassów po wejściu do gry
local function applyGamepassPerks(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then return end

	-- 1. Adidasy Wuefisty (+4 WalkSpeed)
	if MonetizationService.hasGamepass(player, "SpeedShoes") then
		hum.WalkSpeed = math.max(hum.WalkSpeed, 20)
		print(`[Monetization] Gracz {player.Name} otrzymał bonus prędkości z Gamepassa Adidasów!`)
	end

	-- 2. Tag VIP nad głową
	if MonetizationService.hasGamepass(player, "VIP") then
		local head = character:WaitForChild("Head", 5) :: BasePart?
		if head and not head:FindFirstChild("VIPTag") then
			local bb = Instance.new("BillboardGui")
			bb.Name = "VIPTag"
			bb.Size = UDim2.new(0, 140, 0, 30)
			bb.StudsOffset = Vector3.new(0, 3.2, 0)
			bb.AlwaysOnTop = true
			bb.Parent = head

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "👑 PRZEWODNICZĄCY (VIP)"
			label.TextColor3 = Color3.fromRGB(255, 215, 0)
			label.TextStrokeTransparency = 0.2
			label.TextScaled = true
			label.Font = Enum.Font.GothamBlack
			label.Parent = bb
		end
	end
end

-- ========================================================
-- TRANSAKCJE DEWELOPERSKIE (PROCESS RECEIPT ZA ROBUX)
-- ========================================================
local function processReceipt(receiptInfo: { PlayerId: number, ProductId: number, PurchaseId: string }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local awardedCoins = 0

	-- Wyszukanie zakupionego pakietu
	for _, prod in pairs(GameConfig.DevProducts) do
		if prod.Id == productId then
			awardedCoins = prod.Coins
			break
		end
	end

	if awardedCoins > 0 then
		local data = ProfileDataService.getData(player)
		data.Coins += awardedCoins

		-- Aktualizacja w leaderstats
		local stats = player:FindFirstChild("leaderstats")
		local coinsVal = stats and stats:FindFirstChild("Monety") :: IntValue?
		if coinsVal then coinsVal.Value = data.Coins end

		ProfileDataService.syncToClient(player)
		print(`[Robux Shop] Gracz {player.Name} zakupił pakiet: +{awardedCoins} Monet za Robux!`)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.init()
	-- Rejestracja callbacku bezpiecznych transakcji Robux
	MarketplaceService.ProcessReceipt = processReceipt

	-- Obsługa żądań zakupu z interfejsu klienta
	Remotes.get(GameConfig.RemoteEvents.PromptGamePass).OnServerEvent:Connect(function(player: Player, passKey: string)
		local passDef = GameConfig.Gamepasses[passKey]
		if passDef then
			MarketplaceService:PromptGamePassPurchase(player, passDef.Id)
		end
	end)

	Remotes.get(GameConfig.RemoteEvents.PromptDevProduct).OnServerEvent:Connect(function(player: Player, prodKey: string)
		local prodDef = GameConfig.DevProducts[prodKey]
		if prodDef then
			MarketplaceService:PromptProductPurchase(player, prodDef.Id)
		end
	end)

	-- Podpięcie pod wejście gracza
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.delay(0.5, function()
				applyGamepassPerks(player, char)
			end)
		end)
	end)

	print("[MonetizationService] Moduł płatności Robux i MarketplaceService uruchomiony!")
end

return MonetizationService
