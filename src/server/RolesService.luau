--!strict
-- src/server/RolesService.luau
-- Losowanie, przydział ról, wizualne identyfikatory i rozdawanie narzędzi

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local WeaponsService = require(script.Parent:WaitForChild("WeaponsService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local ProfileDataService = require(script.Parent:WaitForChild("ProfileDataService"))

local RolesService = {}

-- Tworzy identyfikator nad głową (dla ról publicznych: Dyrektor i Woźna)
local function applyPublicTag(character: Model, text: string, color: Color3)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then return end

	local existing = head:FindFirstChild("RoleTag")
	if existing then existing:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "RoleTag"
	bb.Size = UDim2.new(0, 180, 0, 45)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = bb
end

local playerRolePreferences: { [Player]: string } = {}

function RolesService.setPreference(player: Player, role: string)
	playerRolePreferences[player] = role
	print(`[Roles] Gracz {player.Name} ustawił preferencję roli: {role}`)
end

function RolesService.assignRoles(playerList: {Player})
	local count = #playerList
	if count == 0 then return end

	-- Ważona pula graczy uwzględniająca Gamepassy (3x szansa) oraz preferencje graczy
	local pool: {Player} = {}
	for _, p in ipairs(playerList) do
		local weight = 1
		local pref = playerRolePreferences[p]

		if MonetizationService.hasGamepass(p, "DoubleRoleChance") then
			weight += 1
		end
		if MonetizationService.hasGamepass(p, "ImpostorChance") or MonetizationService.hasGamepass(p, "DyrektorChance") then
			weight += 3 -- Potrójny boost z Gamepassa!
		end
		if pref and pref ~= "Random" then
			weight += 1 -- Dodatkowy punkt za wybraną preferencję
		end

		for _ = 1, weight do
			table.insert(pool, p)
		end
	end

	local shuffled: {Player} = {}
	while #pool > 0 do
		local idx = math.random(1, #pool)
		local picked = pool[idx]
		if not table.find(shuffled, picked) then
			table.insert(shuffled, picked)
		end
		table.remove(pool, idx)
	end
	for _, p in ipairs(playerList) do
		if not table.find(shuffled, p) then
			table.insert(shuffled, p)
		end
	end

	-- Wyznacz role w zależności od liczby graczy
	-- 1. Dyrektor (zawsze 1)
	-- 2. Woźna (jeśli >= 2 graczy)
	-- 3. Rozrabiaka (1 przy < 6 graczy, 2 przy >= 6)
	-- 4. Reszta to Uczniowie

	local rolesDistribution = {}

	if count == 1 then
		-- Tryb testowy jednoosobowy w Studio
		rolesDistribution[1] = GameConfig.Roles.Rozrabiaka
	elseif count == 2 then
		rolesDistribution[1] = GameConfig.Roles.Dyrektor
		rolesDistribution[2] = GameConfig.Roles.Rozrabiaka
	elseif count == 3 then
		rolesDistribution[1] = GameConfig.Roles.Dyrektor
		rolesDistribution[2] = GameConfig.Roles.Rozrabiaka
		rolesDistribution[3] = GameConfig.Roles.Wozna
	else
		rolesDistribution[1] = GameConfig.Roles.Dyrektor
		rolesDistribution[2] = GameConfig.Roles.Wozna
		rolesDistribution[3] = GameConfig.Roles.Rozrabiaka
		if count >= 6 then
			rolesDistribution[4] = GameConfig.Roles.Rozrabiaka
			for i = 5, count do
				rolesDistribution[i] = GameConfig.Roles.Student
			end
		else
			for i = 4, count do
				rolesDistribution[i] = GameConfig.Roles.Student
			end
		end
	end

	-- Przypisanie ról i narzędzi
	for i, player in ipairs(shuffled) do
		local role = rolesDistribution[i] or GameConfig.Roles.Student
		player:SetAttribute("Role", role)
		player:SetAttribute("IsAlive", true)

		local char = player.Character
		player.Backpack:ClearAllChildren()

		local data = ProfileDataService.getData(player)

		-- Przydział narzędzi i tagów
		if role == GameConfig.Roles.Dyrektor then
			local gunSkinId = data.EquippedGun
			local gunDef: any = nil
			for _, cr in pairs(GameConfig.Crates) do
				for _, it in ipairs(cr.Items) do
					if it.Id == gunSkinId then gunDef = it break end
				end
			end

			local dziennik = WeaponsService.createDyrektorDziennik(gunDef and gunDef.Color, gunDef and gunDef.Name)
			dziennik.Parent = player.Backpack
			if char then
				applyPublicTag(char, "👑 [DYREKTOR SZKOŁY]", Color3.fromRGB(255, 60, 60))
			end

		elseif role == GameConfig.Roles.Wozna then
			local mop = WeaponsService.createWoznaMop()
			mop.Parent = player.Backpack
			if char then
				applyPublicTag(char, "🧹 [PANI WOŹNA]", Color3.fromRGB(80, 200, 255))
			end

		elseif role == GameConfig.Roles.Rozrabiaka then
			local knifeSkinId = data.EquippedKnife
			local knifeDef: any = nil
			for _, cr in pairs(GameConfig.Crates) do
				for _, it in ipairs(cr.Items) do
					if it.Id == knifeSkinId then knifeDef = it break end
				end
			end

			local noz = WeaponsService.createRozrabiakaNoz(knifeDef and knifeDef.Color, knifeDef and knifeDef.Name)
			noz.Parent = player.Backpack
			-- Brak publicznego taga (rola ukryta!)

		else -- Uczeń
			local phone = WeaponsService.createStudentSmartphone()
			phone.Parent = player.Backpack
			-- Brak publicznego taga (rola ukryta!)
		end

		-- Wysłanie informacji do klienta gracza
		Remotes.get(GameConfig.RemoteEvents.RoleAssigned):FireClient(player, role)
		print(`[Role] Gracz {player.Name} otrzymał rolę: {role}`)
	end
end

function RolesService.cleanupRoles(playerList: {Player})
	for _, player in ipairs(playerList) do
		player:SetAttribute("Role", nil)
		player:SetAttribute("IsAlive", false)
		player.Backpack:ClearAllChildren()

		local char = player.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				local tag = head:FindFirstChild("RoleTag")
				if tag then tag:Destroy() end
			end
		end
	end
end

function RolesService.init()
	Remotes.get(GameConfig.RemoteEvents.SetRolePreference).OnServerEvent:Connect(function(player: Player, role: string)
		RolesService.setPreference(player, role)
	end)
end

return RolesService
