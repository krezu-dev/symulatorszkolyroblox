--!strict
-- src/server/WeaponsService.luau
-- Zarządzanie narzędziami i mechanikami broni dla ról:
-- - Szkolny Dziennik (Dyrektor - broń dystansowa)
-- - Plastikowy Nóż-Zabawka (Rozrabiaka - cicha eliminacja)
-- - Mop i Wiadro (Woźna)
-- - Szkolny Smartfon (Uczeń)

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GunDropService = require(script.Parent:WaitForChild("GunDropService"))

local WeaponsService = {}
local eliminationCallback: ((Player, Player?, string?) -> ())?

function WeaponsService.setEliminationCallback(callback: (Player, Player?, string?) -> ())
	eliminationCallback = callback
end

-- ========================================================
-- 1. TWORZENIE NARZĘDZI (TOOLS)
-- ========================================================

-- A) Szkolny Dziennik dla Dyrektora
function WeaponsService.createDyrektorDziennik(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Szkolny Dziennik"
	tool.CanBeDropped = false
	tool.ToolTip = "Rzuć w podejrzanego! Pomyłka = sam odpadasz!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.2, 0.4, 1.6)
	handle.Color = Color3.fromRGB(180, 20, 20) -- Czerwona okładka dziennika
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool

	-- Napis na dzienniku
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.Parent = handle

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "DZIENNIK"
	text.TextColor3 = Color3.fromRGB(255, 215, 0)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = gui

	-- Logika rzutu po aktywacji
	local debounce = false
	tool.Activated:Connect(function()
		if debounce then return end
		local player = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
		if not player then return end

		local character = player.Character
		if not character then return end
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if not rootPart then return end

		debounce = true
		task.delay(3, function() debounce = false end)

		-- Tworzenie lecącego dziennika (pocisku)
		local projectile = handle:Clone()
		projectile.CanCollide = true
		projectile.CFrame = rootPart.CFrame * CFrame.new(0, 1, -2)
		projectile.Parent = workspace

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = rootPart.CFrame.LookVector * 70 + Vector3.new(0, 10, 0)
		bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bodyVelocity.Parent = projectile

		Debris:AddItem(projectile, 5)

		-- Wykrywanie trafienia
		local hitConnection: RBXScriptConnection?
		hitConnection = projectile.Touched:Connect(function(hit)
			local hitChar = hit.Parent
			local hitPlayer = hitChar and Players:GetPlayerFromCharacter(hitChar)
			if hitPlayer and hitPlayer ~= player then
				if hitConnection then
					hitConnection:Disconnect()
					hitConnection = nil
				end
				projectile:Destroy()

				-- Sprawdzenie roli trafionego
				local hitRole = hitPlayer:GetAttribute("Role")
				if hitRole == GameConfig.Roles.Rozrabiaka then
					-- Sukces: Dyrektor trafił Rozrabiakę!
					print(`[Dyrektor] {player.Name} trafił Rozrabiakę: {hitPlayer.Name}!`)
					if eliminationCallback then
						eliminationCallback(hitPlayer, player, "Trafiony Dziennikiem Dyrektora")
					end
				else
					-- Błąd: Dyrektor trafił niewinnego! Dyrektor sam odpada i upuszcza Dziennik
					print(`[Dyrektor] {player.Name} trafił niewinnego {hitPlayer.Name}! Dyrektor sam odpada!`)
					GunDropService.dropDziennik(rootPart.Position)
					if eliminationCallback then
						eliminationCallback(player, nil, GameConfig.SummaryTexts.DyrektorMiss)
					end
				end
			end
		end)
	end)

	return tool
end

-- B) Plastikowy Nóż dla Rozrabiaki
function WeaponsService.createRozrabiakaNoz(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Plastikowy Nóż-Zabawka"
	tool.CanBeDropped = false
	tool.ToolTip = "Podejdź i po cichu wyeliminuj ucznia!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 1.8)
	handle.Color = Color3.fromRGB(255, 105, 180) -- Różowy plastikowy nóż zabawkowy (100% Roblox safe)
	handle.Material = Enum.Material.Plastic
	handle.CanCollide = false
	handle.Parent = tool

	local debounce = false
	tool.Activated:Connect(function()
		if debounce then return end
		local player = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
		if not player then return end

		local character = player.Character
		if not character then return end
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if not rootPart then return end

		-- Szukaj graczy w zasięgu 7 studów
		local closestPlayer: Player? = nil
		local minDistance = 7

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer:GetAttribute("IsAlive") == true then
				if otherPlayer:GetAttribute("Role") ~= GameConfig.Roles.Rozrabiaka then
					local otherChar = otherPlayer.Character
					local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
					if otherRoot then
						local dist = (rootPart.Position - otherRoot.Position).Magnitude
						if dist <= minDistance then
							minDistance = dist
							closestPlayer = otherPlayer
						end
					end
				end
			end
		end

		if closestPlayer then
			debounce = true
			task.delay(15, function() debounce = false end) -- Cooldown zabójstwa

			print(`[Rozrabiaka] {player.Name} wyeliminował {closestPlayer.Name}!`)
			if eliminationCallback then
				eliminationCallback(closestPlayer, player, "Zabawkowy atak Rozrabiaki")
			end
		end
	end)

	return tool
end

-- C) Mop i Wiadro dla Woźnej
function WeaponsService.createWoznaMop(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Mop i Wiadro"
	tool.CanBeDropped = false
	tool.ToolTip = "Zmywaj plamy i ślady po Rozrabiakach!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 4.5, 0.4)
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.CanCollide = false
	handle.Parent = tool

	local sponge = Instance.new("Part")
	sponge.Name = "MopHead"
	sponge.Size = Vector3.new(1.2, 0.6, 0.8)
	sponge.Color = Color3.fromRGB(220, 220, 220)
	sponge.CanCollide = false
	sponge.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = sponge
	weld.Parent = handle
	sponge.CFrame = handle.CFrame * CFrame.new(0, -2, 0)

	return tool
end

-- D) Smartfon dla Ucznia (do raportowania)
function WeaponsService.createStudentSmartphone(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Szkolny Smartfon"
	tool.CanBeDropped = false
	tool.ToolTip = "Użyj, aby zgłosić znaleziony plecak / ciało!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.1, 1.4)
	handle.Color = Color3.fromRGB(30, 30, 30)
	handle.Material = Enum.Material.Glass
	handle.CanCollide = false
	handle.Parent = tool

	return tool
end

-- Połączenie z GunDropService
GunDropService.setCreateToolFunction(WeaponsService.createDyrektorDziennik)

return WeaponsService
