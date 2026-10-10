--!strict
-- src/server/ProfileDataService.luau
-- Bezpieczny zapis i odczyt danych gracza (DataStoreService):
-- - Szkolne Monety i Wygrane
-- - Zakupione Ulepszenia (Kondycja, Cichobiegi, Wzrok Sokoli)
-- - Odblokowane Skiny do Dziennika i Noża
-- - Założone przedmioty kosmetyczne (Equipped)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local ProfileDataService = {}
local profileDataStore: GlobalDataStore? = nil

-- Próba połączenia z DataStore (z fallbackiem na pamięć RAM w Studio)
local success, ds = pcall(function()
	return DataStoreService:GetDataStore("SzkolnyDetektyw_UserData_v1")
end)
if success and ds then
	profileDataStore = ds
end

export type PlayerData = {
	Coins: number,
	Wins: number,
	Upgrades: { [string]: number },
	Inventory: { string },
	EquippedGun: string,
	EquippedKnife: string,
}

local sessionData: { [Player]: PlayerData } = {}

local function getDefaultData(): PlayerData
	return {
		Coins = 100, -- 100 monet na start na powitanie!
		Wins = 0,
		Upgrades = { Speed = 0, Stealth = 0, CoinRadar = 0 },
		Inventory = { "Skin_Linijka", "Skin_DziennikZielony" },
		EquippedGun = "Skin_DziennikZielony",
		EquippedKnife = "Skin_Linijka",
	}
end

function ProfileDataService.getData(player: Player): PlayerData
	if not sessionData[player] then
		sessionData[player] = getDefaultData()
	end
	return sessionData[player]
end

function ProfileDataService.syncToClient(player: Player)
	local data = ProfileDataService.getData(player)
	local syncRemote = Remotes.get(GameConfig.RemoteEvents.SyncPlayerData)
	syncRemote:FireClient(player, data)
end

function ProfileDataService.loadData(player: Player)
	local key = `Player_{player.UserId}`
	local data: PlayerData? = nil

	if profileDataStore then
		local loadSuccess, result = pcall(function()
			return profileDataStore:GetAsync(key)
		end)
		if loadSuccess and result then
			data = result :: PlayerData
		end
	end

	if not data then
		data = getDefaultData()
	end

	sessionData[player] = data

	-- Synchronizacja z leaderstats
	local stats = player:WaitForChild("leaderstats", 5)
	if stats then
		local coinsVal = stats:FindFirstChild("Monety") :: IntValue?
		if coinsVal then coinsVal.Value = data.Coins end
		local winsVal = stats:FindFirstChild("Wygrane") :: IntValue?
		if winsVal then winsVal.Value = data.Wins end
	end

	ProfileDataService.syncToClient(player)
	print(`[ProfileData] Załadowano dane dla gracza: {player.Name} (Monety: {data.Coins})`)
end

function ProfileDataService.saveData(player: Player)
	local data = sessionData[player]
	if not data then return end

	local key = `Player_{player.UserId}`
	if profileDataStore then
		pcall(function()
			profileDataStore:SetAsync(key, data)
		end)
	end
	print(`[ProfileData] Zapisano dane gracza: {player.Name}`)
end

function ProfileDataService.init()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(ProfileDataService.loadData, player)
	end

	Players.PlayerAdded:Connect(function(player)
		ProfileDataService.loadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ProfileDataService.saveData(player)
		sessionData[player] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			ProfileDataService.saveData(player)
		end
	end)

	print("[ProfileDataService] Moduł zapisu i profilu gracza pomyślnie uruchomiony!")
end

return ProfileDataService
