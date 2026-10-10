--!strict
-- src/server/KukirinService.luau
-- System Wierzchowców i Zwierzaków KUKIRIN (Płatny Złoty Kukirin i Szkolny Kukirin):
-- Gracz może wsiąść na Kukirina lub mieć go jako latającego zwierzaka!
-- Daje potężny boost do prędkości, złote/błękitne cząsteczki i ryk KUKIRIIIIN!

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local ProfileDataService = require(script.Parent:WaitForChild("ProfileDataService"))

local KukirinService = {}
local activeKukirins: { [Player]: Model } = {}

-- Buduje trójwymiarowy model Kukirina
local function buildKukirinModel(kDef: any): Model
	local model = Instance.new("Model")
	model.Name = kDef.Name

	-- Tułów Kukirina
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(3, 2, 4.5)
	body.Color = kDef.Color
	body.Material = Enum.Material.Neon
	body.CanCollide = false
	body.Parent = model

	-- Głowa ze złotymi rogami
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2.4)
	head.CFrame = body.CFrame * CFrame.new(0, 1.4, -2.6)
	head.Color = kDef.Color
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = body

	-- Oczy i rogi
	for i = -1, 1, 2 do
		local horn = Instance.new("Part")
		horn.Name = "Horn"
		horn.Size = Vector3.new(0.4, 1.6, 0.4)
		horn.CFrame = head.CFrame * CFrame.new(i * 0.8, 1.2, -0.4) * CFrame.Angles(math.rad(-25), 0, math.rad(i * 15))
		horn.Color = Color3.fromRGB(255, 235, 120)
		horn.Material = Enum.Material.Neon
		horn.CanCollide = false
		horn.Parent = model

		local hornWeld = Instance.new("WeldConstraint")
		hornWeld.Part0 = head
		hornWeld.Part1 = horn
		hornWeld.Parent = head
	end

	-- Skrzydła / dopalacze
	for i = -1, 1, 2 do
		local wing = Instance.new("Part")
		wing.Name = "Wing"
		wing.Size = Vector3.new(2.8, 0.3, 2)
		wing.CFrame = body.CFrame * CFrame.new(i * 2.2, 0.8, 0.2) * CFrame.Angles(0, 0, math.rad(i * 20))
		wing.Color = kDef.ParticleColor
		wing.Material = Enum.Material.Glass
		wing.CanCollide = false
		wing.Parent = model

		local wingWeld = Instance.new("WeldConstraint")
		wingWeld.Part0 = body
		wingWeld.Part1 = wing
		wingWeld.Parent = body
	end

	-- Cząsteczki iskier / blasku
	local attachment = Instance.new("Attachment")
	attachment.Parent = body

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(kDef.ParticleColor)
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Lifetime = NumberRange.new(0.5, 1.2)
	sparkles.Rate = 25
	sparkles.Speed = NumberRange.new(2, 5)
	sparkles.SpreadAngle = Vector2.new(45, 45)
	sparkles.Parent = attachment

	-- Billboard z okrzykiem
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = kDef.RoarText
	label.TextColor3 = kDef.Color
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = bb

	model.PrimaryPart = body
	return model
end

-- Włącza lub wyłącza wierzchowca Kukirina dla danego gracza
function KukirinService.toggleKukirin(player: Player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	-- Jeśli gracz ma już aktywnego Kukirina -> schowaj
	if activeKukirins[player] then
		activeKukirins[player]:Destroy()
		activeKukirins[player] = nil
		hum.WalkSpeed = 16
		print(`[Kukirin] Gracz {player.Name} schował swojego Kukirina.`)
		return
	end

	-- Sprawdzenie uprawnień: Płatny Złoty Kukirin (Gamepass) lub Szkolny Kukirin
	local hasGolden = MonetizationService.hasGamepass(player, "GoldenKukirin")
	local data = ProfileDataService.getData(player)
	local hasSchool = table.find(data.Inventory, "SchoolKukirin") ~= nil

	local chosenKukirinDef = nil
	if hasGolden then
		chosenKukirinDef = GameConfig.Kukirins.GoldenKukirin
	elseif hasSchool then
		chosenKukirinDef = GameConfig.Kukirins.SchoolKukirin
	else
		print(`[Kukirin] Gracz {player.Name} nie posiada jeszcze żadnego Kukirina!`)
		-- Wyślij monit o zakup
		local promptRemote = Remotes.get(GameConfig.RemoteEvents.PromptGamePass)
		promptRemote:FireClient(player, "GoldenKukirin")
		return
	end

	-- Tworzenie modelu Kukirina
	local kukirinModel = buildKukirinModel(chosenKukirinDef)
	kukirinModel.PrimaryPart.CFrame = root.CFrame * CFrame.new(0, -1.2, 0)
	kukirinModel.Parent = char

	-- Przyczepienie do gracza (Weld do korpusu)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = kukirinModel.PrimaryPart
	weld.Parent = kukirinModel.PrimaryPart

	-- Zwiększenie prędkości
	hum.WalkSpeed = 16 + chosenKukirinDef.SpeedBoost

	-- Dźwięk ryku Kukirina
	local roarSound = Instance.new("Sound")
	roarSound.SoundId = GameConfig.SoundIds.UnboxChime
	roarSound.Volume = 0.8
	roarSound.Pitch = 1.3
	roarSound.Parent = root
	roarSound:Play()
	Debris:AddItem(roarSound, 3)

	activeKukirins[player] = kukirinModel
	print(`[Kukirin] Gracz {player.Name} dosiadł: {chosenKukirinDef.Name}! Prędkość: {hum.WalkSpeed}`)
end

function KukirinService.cleanupPlayer(player: Player)
	if activeKukirins[player] then
		activeKukirins[player]:Destroy()
		activeKukirins[player] = nil
	end
end

function KukirinService.init()
	-- Zdarzenie od klienta
	Remotes.get(GameConfig.RemoteEvents.ToggleKukirin).OnServerEvent:Connect(function(player: Player)
		KukirinService.toggleKukirin(player)
	end)

	Players.PlayerRemoving:Connect(KukirinService.cleanupPlayer)

	print("[KukirinService] System mitycznych wierzchowców Kukirin pomyślnie uruchomiony!")
end

return KukirinService
