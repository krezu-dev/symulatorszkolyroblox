-- Efekty: dymki NPC/memów, gwiazdki i „BONK”, plecaki RGB, lampki kamer, prompty do łapania przedmiotów.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TextChatService = game:GetService("TextChatService")
local Debris = game:GetService("Debris")

local E = {}
local K, U, C

local function dymek(d)
	local kto = d.npc or (d.kto and d.kto.Character)
	local glowa = kto and kto:FindFirstChild("Head")
	if not glowa then return end
	local ok = pcall(function() TextChatService:DisplayBubble(glowa, d.tekst) end)
	if not ok then
		-- zapas: własny dymek
		local bb = U.new("BillboardGui", { Size = UDim2.fromScale(8, 2), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, MaxDistance = 80 }, glowa)
		local h, f = U.karta(bb, "D", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), U.PAPER)
		U.txt(f, { Text = d.tekst, TextWrapped = true, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
		Debris:AddItem(bb, 4)
	end
end

local function efekt(d)
	if not d.pos then return end
	if K.stan.ustawienia.slaby then return end
	local p = U.new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.new(1, 1, 1), Position = d.pos + Vector3.new(0, 2, 0) }, workspace)
	local a = U.new("Attachment", {}, p)
	local pe = U.new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(d.typ == "bonk" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 212, 59)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(180, 180), Rate = 0, LightEmission = 1,
	}, a)
	pe:Emit(d.typ == "bonk" and 14 or 26)
	-- komiksowy napis
	local bb = U.new("BillboardGui", { Size = UDim2.fromScale(6, 3), AlwaysOnTop = true, MaxDistance = 90 }, p)
	local t = U.txt(bb, { Text = d.typ == "bonk" and "BONK!" or "POW!", Font = Enum.Font.Bangers, TextColor3 = d.typ == "bonk" and U.YEL or U.RED, Size = UDim2.fromScale(1, 1) })
	U.obrysTekstu(t, 3)
	local sc = U.new("UIScale", { Scale = 0.2 }, t)
	K.tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.8, function() K.tween(t, 0.3, { TextTransparency = 1 }) end)
	Debris:AddItem(p, 2)
end

-- prompty „Podnieś” na przedmiotach do rzucania (lokalne)
local function promptRzucalne(o)
	if not o:IsA("BasePart") or o:FindFirstChild("PromptChwyc") then return end
	local pr = U.new("ProximityPrompt", { Name = "PromptChwyc", ActionText = "Podnieś", ObjectText = o:GetAttribute("Nazwa") or "przedmiot", MaxActivationDistance = 8,
		RequiresLineOfSight = false, KeyboardKeyCode = Enum.KeyCode.E, HoldDuration = 0 }, o)
	pr.Triggered:Connect(function() K.wyslij("chwyc", { obiekt = o }) end)
end

-- jazda na hulajnodze: zamiast animacji chodzenia stoisz na desce (lekko pochylony), dźwięk silniczka
local jazdaTrack, jazdaDzwiek
local function jazda()
	local ch = K.gracz.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animate = ch:FindFirstChild("Animate")
	local an = hum:FindFirstChildOfClass("Animator")
	local naHul = K.gracz:GetAttribute("NaHulajnodze") ~= nil
	if naHul then
		if animate then animate.Disabled = true end
		if an then
			for _, t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0.1) end
			local a = Instance.new("Animation")
			a.AnimationId = "rbxassetid://507766388" -- stanie (idle R15)
			jazdaTrack = an:LoadAnimation(a)
			jazdaTrack.Priority = Enum.AnimationPriority.Action
			jazdaTrack.Looped = true
			jazdaTrack:Play(0.15)
		end
		if not jazdaDzwiek then
			jazdaDzwiek = U.new("Sound", { SoundId = "rbxassetid://123671758687889", Looped = true, Volume = 0, SoundGroup = K.grupaSfx }, ch:FindFirstChild("HumanoidRootPart"))
			jazdaDzwiek:Play()
		end
	else
		if jazdaTrack then jazdaTrack:Stop(0.15) jazdaTrack = nil end
		if animate then animate.Disabled = false end
		if jazdaDzwiek then jazdaDzwiek:Destroy() jazdaDzwiek = nil end
	end
end

function E.Init(k)
	K = k
	U = K.Styl
	C = K.C
	K.gracz:GetAttributeChangedSignal("NaHulajnodze"):Connect(jazda)
	K.gracz.CharacterAdded:Connect(function() jazdaTrack = nil jazdaDzwiek = nil end)
	RunService.RenderStepped:Connect(function()
		if not jazdaDzwiek then return end
		local h = K.hrp()
		if not h then return end
		local v = (h.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
		jazdaDzwiek.Volume = math.clamp(v / 40, 0, 0.35)
		jazdaDzwiek.PlaybackSpeed = 0.8 + math.clamp(v / 40, 0, 0.6)
	end)
	K.na("Dymek", dymek)
	K.na("Efekt", efekt)
	for _, o in ipairs(CollectionService:GetTagged("Rzucalne")) do promptRzucalne(o) end
	CollectionService:GetInstanceAddedSignal("Rzucalne"):Connect(promptRzucalne)
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		-- plecaki RGB
		for _, c in ipairs(CollectionService:GetTagged("PlecakRGB")) do
			c.Color = Color3.fromHSV((os.clock() * 0.25) % 1, 0.8, 1)
		end
		if t < 0.25 then return end
		t = 0
		-- prompty chwytania: nie gdy coś trzymasz albo trwa zebranie
		local mozna = K.stan.trzyma == nil and K.Gra:GetAttribute("Faza") ~= "Spotkanie"
		for _, o in ipairs(CollectionService:GetTagged("Rzucalne")) do
			local pr = o:FindFirstChild("PromptChwyc")
			if pr then pr.Enabled = mozna and not o:GetAttribute("Trzyma") end
		end
		-- lampki kamer świecą, gdy ktoś ogląda monitoring
		local ogl = (K.Gra:GetAttribute("KameryOgladane") or 0) > 0
		local f = workspace:FindFirstChild("SchoolMap") and workspace.SchoolMap:FindFirstChild("Kamery")
		if f then
			for _, c in ipairs(f:GetDescendants()) do
				if c.Name == "Lampka" and c:IsA("BasePart") then
					c.Color = ogl and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(60, 20, 20)
					c.Material = ogl and Enum.Material.Neon or Enum.Material.SmoothPlastic
				end
			end
		end
	end)
end

return E
