--!strict
-- src/server/ShopService.luau
-- Zarządzanie sklepem w grze:
-- - Otwieranie skrzynek ze skinami (Unboxing MM2)
-- - Zakup ulepszeń za monety (Kondycja, Cichobiegi, Radar)
-- - Zmiana ekwipowanych skinów do broni

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local ProfileDataService = require(script.Parent:WaitForChild("ProfileDataService"))

local ShopService = {}

-- Losowanie przedmiotu na podstawie wag rzadkości
local function rollCrateItem(crateDef: any)
	local totalWeight = 0
	for _, it in ipairs(crateDef.Items) do
		totalWeight += (it.Weight or 10)
	end

	local rand = math.random(1, totalWeight)
	local current = 0
	for _, it in ipairs(crateDef.Items) do
		current += (it.Weight or 10)
		if rand <= current then
			return it
		end
	end
	return crateDef.Items[1]
end

-- Aplikuje aktywne ulepszenia na postać gracza
function ShopService.applyUpgradesToCharacter(player: Player, character: Model)
	local data = ProfileDataService.getData(player)
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then return end

	local speedLvl = data.Upgrades["Speed"] or 0
	if speedLvl > 0 then
		hum.WalkSpeed = 16 + (speedLvl * 1.5)
	else
		hum.WalkSpeed = 16
	end
end

function ShopService.init()
	-- 1. Zakup skrzynki (BuyCrate)
	Remotes.get(GameConfig.RemoteEvents.BuyCrate).OnServerEvent:Connect(function(player: Player, crateId: string)
		local crateDef = GameConfig.Crates[crateId]
		if not crateDef then return end

		local data = ProfileDataService.getData(player)
		if data.Coins < crateDef.Cost then
			print(`[Shop] Gracz {player.Name} ma za mało monet ({data.Coins}/{crateDef.Cost})!`)
			return
		end

		-- Pobranie opłaty
		data.Coins -= crateDef.Cost
		local stats = player:FindFirstChild("leaderstats")
		local coinsVal = stats and stats:FindFirstChild("Monety") :: IntValue?
		if coinsVal then coinsVal.Value = data.Coins end

		-- Losowanie skina
		local wonItem = rollCrateItem(crateDef)
		if not table.find(data.Inventory, wonItem.Id) then
			table.insert(data.Inventory, wonItem.Id)
		end

		print(`[Shop] Gracz {player.Name} otworzył '{crateDef.Name}' i wylosował: {wonItem.Name} ({wonItem.Rarity})!`)

		-- Powiadomienie klienta (do animacji ruletki / unboxingu)
		Remotes.get(GameConfig.RemoteEvents.CrateOpened):FireClient(player, wonItem)
		ProfileDataService.syncToClient(player)
	end)

	-- 2. Zakup ulepszenia lub Szkolnego Kukirina (BuyUpgrade)
	Remotes.get(GameConfig.RemoteEvents.BuyUpgrade).OnServerEvent:Connect(function(player: Player, upgradeId: string)
		local data = ProfileDataService.getData(player)

		-- Zakup Szkolnego Kukirina za 300 monet (F2P)
		if upgradeId == "SchoolKukirin" then
			local kDef = GameConfig.Kukirins.SchoolKukirin
			if data.Coins < (kDef.Cost or 300) then return end
			if table.find(data.Inventory, "SchoolKukirin") then return end

			data.Coins -= (kDef.Cost or 300)
			table.insert(data.Inventory, "SchoolKukirin")
			local stats = player:FindFirstChild("leaderstats")
			local coinsVal = stats and stats:FindFirstChild("Monety") :: IntValue?
			if coinsVal then coinsVal.Value = data.Coins end
			ProfileDataService.syncToClient(player)
			print(`[Shop] Gracz {player.Name} zakupił Szkolnego Kukirina za 300 monet!`)
			return
		end

		local upDef = GameConfig.Upgrades[upgradeId]
		if not upDef then return end

		local data = ProfileDataService.getData(player)
		local currentLvl = data.Upgrades[upgradeId] or 0
		if currentLvl >= upDef.MaxLevel then return end

		local cost = upDef.CostPerLevel * (currentLvl + 1)
		if data.Coins < cost then return end

		data.Coins -= cost
		data.Upgrades[upgradeId] = currentLvl + 1

		local stats = player:FindFirstChild("leaderstats")
		local coinsVal = stats and stats:FindFirstChild("Monety") :: IntValue?
		if coinsVal then coinsVal.Value = data.Coins end

		print(`[Shop] Gracz {player.Name} ulepszył '{upDef.Name}' do poziomu {currentLvl + 1}!`)

		-- Zastosowanie bonusu
		if player.Character then
			ShopService.applyUpgradesToCharacter(player, player.Character)
		end

		ProfileDataService.syncToClient(player)
	end)

	-- 3. Założenie skina (EquipSkin)
	Remotes.get(GameConfig.RemoteEvents.EquipSkin).OnServerEvent:Connect(function(player: Player, skinId: string)
		local data = ProfileDataService.getData(player)
		if not table.find(data.Inventory, skinId) then return end

		-- Sprawdzenie typu skina
		for _, crate in pairs(GameConfig.Crates) do
			for _, item in ipairs(crate.Items) do
				if item.Id == skinId then
					if item.Type == "Gun" then
						data.EquippedGun = skinId
					elseif item.Type == "Knife" then
						data.EquippedKnife = skinId
					end
					print(`[Shop] Gracz {player.Name} założył skin: {item.Name}!`)
					ProfileDataService.syncToClient(player)
					return
				end
			end
		end
	end)

	-- Podpięcie pod respawn postaci (aplikowanie prędkości z ulepszeń)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.delay(0.5, function()
				ShopService.applyUpgradesToCharacter(player, char)
			end)
		end)
	end)

	print("[ShopService] Sklep ze skrzynkami i ulepszeniami pomyślnie zainicjalizowany!")
end

return ShopService
