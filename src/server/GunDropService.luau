--!strict
-- src/server/GunDropService.luau
-- Mechanika Gun-Drop z Murder Mystery 2:
-- Gdy Dyrektor zginie lub odpadnie, upuszcza Szkolny Dziennik na podłogę.
-- Każdy żywy Niewinny Uczeń lub Woźna może go podnieść i zostać Zastępcą Dyrektora!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local GunDropService = {}
local currentDroppedDziennik: Instance? = nil

-- Callback tworzenia narzędzia dziennika (wstrzykiwany z WeaponsService)
local createDziennikToolFn: (() -> Tool)?

function GunDropService.setCreateToolFunction(fn: () -> Tool)
	createDziennikToolFn = fn
end

function GunDropService.clearDroppedDziennik()
	if currentDroppedDziennik and currentDroppedDziennik.Parent then
		currentDroppedDziennik:Destroy()
	end
	currentDroppedDziennik = nil
end

function GunDropService.dropDziennik(position: Vector3)
	-- Usuń poprzedni upuszczony dziennik, jeśli istniał
	GunDropService.clearDroppedDziennik()

	local dziennikPart = Instance.new("Part")
	dziennikPart.Name = "UpuszczonyDziennik"
	dziennikPart.Size = Vector3.new(1.4, 0.4, 1.8)
	dziennikPart.Position = position + Vector3.new(0, 0.5, 0)
	dziennikPart.Color = Color3.fromRGB(220, 20, 20)
	dziennikPart.Material = Enum.Material.SmoothPlastic
	dziennikPart.Anchored = true
	dziennikPart.CanCollide = false

	-- Złota poświata (MM2 gun highlight effect)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 215, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent = dziennikPart

	-- Złoty promień światła / efekt punktowy
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 100)
	light.Range = 12
	light.Brightness = 3
	light.Parent = dziennikPart

	-- Pływający napis nad dziennikiem
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 45)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = dziennikPart

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "📖 DZIENNIK DYREKTORA\n[Podnieś, aby zostać Zastępcą!]"
	text.TextColor3 = Color3.fromRGB(255, 235, 50)
	text.TextStrokeTransparency = 0.2
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = bb

	-- ProximityPrompt do podniesienia
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Zostań Zastępcą Dyrektora"
	prompt.ObjectText = "Szkolny Dziennik"
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = dziennikPart

	prompt.Triggered:Connect(function(player: Player)
		if player:GetAttribute("IsAlive") ~= true then return end
		local role = player:GetAttribute("Role")
		if role == GameConfig.Roles.Rozrabiaka then
			-- Rozrabiaka nie może podnieść dziennika
			return
		end

		-- Sukces: Gracz podnosi dziennik!
		GunDropService.clearDroppedDziennik()

		player:SetAttribute("Role", GameConfig.Roles.ZastepcaDyrektora)
		print(`[GunDrop] Gracz {player.Name} podniósł Dziennik i został Zastępcą Dyrektora!`)

		-- Nadanie narzędzia
		if createDziennikToolFn then
			local tool = createDziennikToolFn()
			tool.Parent = player.Backpack
		end

		-- Aktualizacja etykiety nad głową
		local char = player.Character
		local head = char and char:FindFirstChild("Head") :: BasePart?
		if head then
			local existing = head:FindFirstChild("RoleBillboard")
			if existing then existing:Destroy() end

			local roleBb = Instance.new("BillboardGui")
			roleBb.Name = "RoleBillboard"
			roleBb.Size = UDim2.new(0, 170, 0, 35)
			roleBb.StudsOffset = Vector3.new(0, 2.5, 0)
			roleBb.AlwaysOnTop = true
			roleBb.Parent = head

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "⭐ ZASTĘPCA DYREKTORA ⭐"
			label.TextColor3 = Color3.fromRGB(255, 215, 0)
			label.TextStrokeTransparency = 0.2
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.Parent = roleBb
		end

		-- Rozgłoszenie do wszystkich klientów
		local pickupRemote = Remotes.get(GameConfig.RemoteEvents.DziennikPickedUp)
		pickupRemote:FireAllClients(player.Name)
	end)

	dziennikPart.Parent = workspace
	currentDroppedDziennik = dziennikPart

	-- Powiadomienie wszystkich o upuszczeniu
	local dropRemote = Remotes.get(GameConfig.RemoteEvents.DziennikDropped)
	dropRemote:FireAllClients(position)
end

return GunDropService
