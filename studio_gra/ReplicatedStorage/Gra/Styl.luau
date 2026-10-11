-- Styl GUI „zeszyt + komiks” (ten sam co szablon SzablonUI). Używany przez klienta w trakcie gry.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local U = {}
U.INK = Color3.fromRGB(28, 30, 48)
U.PAPER = Color3.fromRGB(246, 239, 224)
U.PAPER2 = Color3.fromRGB(232, 221, 198)
U.RED = Color3.fromRGB(214, 40, 57)
U.YEL = Color3.fromRGB(255, 212, 59)
U.LINE = Color3.fromRGB(160, 188, 226)
U.TAPE = Color3.fromRGB(238, 228, 180)
U.GREEN = Color3.fromRGB(46, 140, 90)
U.BLUE = Color3.fromRGB(52, 110, 200)
U.GREY = Color3.fromRGB(110, 112, 130)
U.CORK = Color3.fromRGB(196, 150, 100)

function U.new(c, p, par)
	local o = Instance.new(c)
	for k, v in pairs(p) do o[k] = v end
	if par then o.Parent = par end
	return o
end
local new = U.new
function U.stroke(o, t, col, tr, round)
	local s = new("UIStroke", { Thickness = t, Color = col or U.INK, Transparency = tr or 0,
		LineJoinMode = round and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	s:SetAttribute("Baza", t)
	return s
end
function U.obrysTekstu(t, grub, col)
	local s = new("UIStroke", { Thickness = grub or 2, Color = col or U.INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
	s:SetAttribute("Baza", grub or 2)
	return s
end
function U.corner(o, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 4) }, o) end
function U.txt(par, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, TextScaled = true, TextColor3 = U.INK, Font = Enum.Font.PatrickHand }, par)
	for k, v in pairs(props) do t[k] = v end
	return t
end
function U.tasma(par, pos, size, rot)
	local t = new("Frame", { Name = "Tasma", BackgroundColor3 = U.TAPE, BackgroundTransparency = 0.12, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, Rotation = rot, ZIndex = 5 }, par)
	U.stroke(t, 1, U.INK, 0.75)
	return t
end

-- animacja przycisków identyczna jak ikonki HUD
local hoverId = "rbxassetid://139719503904449"
local klikId = "rbxassetid://88442833509532"
local hover, klik
local function graj(s)
	if not s then return end
	s.TimePosition = 0
	s:Play()
end
local ostatniHover = 0
function U.feedback(button)
	if button:GetAttribute("Podpiety") then return end
	button:SetAttribute("Podpiety", true)
	if not hover then
		hover = new("Sound", { SoundId = hoverId, Volume = 0.18 }, SoundService)
		klik = new("Sound", { SoundId = klikId, Volume = 0.3 }, SoundService)
	end
	local scale = button:FindFirstChild("FeedbackScale") or new("UIScale", { Name = "FeedbackScale" }, button)
	local ikona = button:FindFirstChild("Lico")
	local bazaRot = ikona and ikona.Rotation or 0
	local hovered = false
	local seq = 0
	local function tw(o, t, p, s, d) TweenService:Create(o, TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p):Play() end
	local function spocznij()
		seq += 1
		tw(scale, 0.17, { Scale = hovered and 1.1 or 1 })
		if ikona then tw(ikona, 0.17, { Rotation = hovered and bazaRot - 4 or bazaRot }) end
	end
	button.MouseEnter:Connect(function()
		hovered = true
		if os.clock() - ostatniHover > 0.07 then ostatniHover = os.clock() graj(hover) end
		spocznij()
	end)
	button.MouseLeave:Connect(function() hovered = false spocznij() end)
	button.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			seq += 1
			local tok = seq
			tw(scale, 0.065, { Scale = 0.9 })
			task.delay(0.075, function()
				if tok ~= seq or not button.Parent then return end
				tw(scale, 0.23, { Scale = hovered and 1.1 or 1 }, Enum.EasingStyle.Back)
			end)
		end
	end)
	button.Activated:Connect(function() graj(klik) end)
end

-- naklejka-przycisk z twardym cieniem
function U.naklejka(par, name, pos, size, col, anchor, rot)
	local b = new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = pos, Size = size,
		AnchorPoint = anchor or Vector2.new(0, 0), Rotation = rot or 0, ZIndex = 8 }, par)
	new("UIScale", { Name = "FeedbackScale" }, b)
	local s = new("Frame", { Name = "Cien", BackgroundColor3 = U.INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, 3, 0, 4), ZIndex = 8 }, b)
	U.corner(s)
	local f = new("Frame", { Name = "Lico", BackgroundColor3 = col or U.YEL, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, b)
	U.corner(f)
	U.stroke(f, 2.5)
	U.feedback(b)
	return b, f
end
function U.przyciskTekst(par, name, tekst, pos, size, col, tcol, anchor, rot)
	local b, f = U.naklejka(par, name, pos, size, col, anchor, rot)
	U.txt(f, { Name = "Tekst", Text = tekst, Font = Enum.Font.Bangers, TextColor3 = tcol or U.INK, Size = UDim2.fromScale(0.86, 0.72), Position = UDim2.fromScale(0.07, 0.14), ZIndex = 10 })
	return b, f
end
function U.karta(par, name, pos, size, col, anchor, rot, sh)
	local h = new("Frame", { Name = name, BackgroundTransparency = 1, Position = pos, Size = size, AnchorPoint = anchor or Vector2.new(0, 0), Rotation = rot or 0 }, par)
	local s = new("Frame", { Name = "Cien", BackgroundColor3 = U.INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Position = UDim2.new(0, sh or 3, 0, (sh or 3) + 1) }, h)
	U.corner(s)
	local f = new("Frame", { Name = "Lico", BackgroundColor3 = col or U.PAPER, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, h)
	U.corner(f)
	U.stroke(f, 2.5)
	return h, f
end

-- czerwony X z białym krzyżykiem
function U.zamknij(par, pos, rozmiar)
	local b = new("TextButton", { Name = "Zamknij", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Size = UDim2.fromScale(rozmiar or 0.095, rozmiar or 0.095), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = pos or UDim2.fromScale(0.985, 0.01), Rotation = 6, ZIndex = 20 }, par)
	new("UIScale", { Name = "FeedbackScale" }, b)
	local sh = new("Frame", { Name = "Cien", BackgroundColor3 = U.INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.09, 0.1), ZIndex = 20 }, b)
	U.corner(sh)
	local f = new("Frame", { Name = "Lico", BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 21 }, b)
	U.corner(f)
	U.stroke(f, 3)
	local function kreska(rot, kol, grub, dl, z)
		local k = new("Frame", { BackgroundColor3 = kol, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(dl, grub),
			Position = UDim2.fromScale(0.5, 0.5), Rotation = rot, ZIndex = z }, f)
		U.corner(k, UDim.new(0, 2))
	end
	kreska(45, U.INK, 0.27, 0.8, 22) kreska(-45, U.INK, 0.27, 0.8, 22)
	kreska(45, Color3.new(1, 1, 1), 0.15, 0.68, 23) kreska(-45, Color3.new(1, 1, 1), 0.15, 0.68, 23)
	U.feedback(b)
	return b
end

-- okno: kartka z zeszytu (to samo co w szablonie)
function U.okno(gui, name, tytul, podtytul, opts)
	opts = opts or {}
	local old = gui:FindFirstChild(name)
	if old then old:Destroy() end
	local wh = new("Frame", { Name = name, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = opts.pos or UDim2.fromScale(0.5, 0.56),
		Size = UDim2.fromScale(opts.wys or 0.62, opts.wys or 0.62), SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = opts.rot or -1, ZIndex = opts.z or 1 }, gui)
	new("UIAspectRatioConstraint", { AspectRatio = opts.aspect or 1.22 }, wh)
	new("UIScale", { Name = "Animacja" }, wh)
	local sh = new("Frame", { Name = "Cien", BackgroundColor3 = U.INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.018, 0.022) }, wh)
	U.corner(sh)
	local wf = new("Frame", { Name = "Lico", BackgroundColor3 = opts.papier or U.PAPER, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, wh)
	U.corner(wf)
	U.stroke(wf, 3)
	if not opts.bezLinii then
		for i = 1, 15 do
			new("Frame", { Name = "Linia", BackgroundColor3 = opts.liniaKolor or U.LINE, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0, 0.2 + i * 0.052), BackgroundTransparency = 0.45 }, wf)
		end
	end
	new("Frame", { Name = "Margines", BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.new(0, 2, 1, 0), Position = UDim2.fromScale(0.1, 0), BackgroundTransparency = 0.25 }, wf)
	U.tasma(wh, UDim2.fromScale(0.08, 0.02), UDim2.fromScale(0.2, 0.06), -35)
	U.tasma(wh, UDim2.fromScale(0.92, 0.02), UDim2.fromScale(0.2, 0.06), 35)
	new("Frame", { Name = "Zakreslacz", BackgroundColor3 = opts.zakreslacz or U.YEL, BorderSizePixel = 0, Size = UDim2.fromScale(math.min(0.75, 0.05 + #tytul * 0.04), 0.085),
		Position = UDim2.fromScale(0.13, 0.075), Rotation = -1.5, BackgroundTransparency = 0.15 }, wf)
	U.txt(wf, { Name = "Tytul", Text = tytul, Font = Enum.Font.Bangers, TextColor3 = opts.tytulKolor or U.INK, Size = UDim2.fromScale(0.7, 0.12),
		Position = UDim2.fromScale(0.14, 0.05), TextXAlignment = Enum.TextXAlignment.Left })
	U.txt(wf, { Name = "Podtytul", Text = podtytul or "", Size = UDim2.fromScale(0.75, 0.06), Position = UDim2.fromScale(0.14, 0.17),
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = opts.podKolor or U.GREY })
	local x
	if not opts.bezX then x = U.zamknij(wh) end
	return wh, wf, x
end

-- animacja wejścia/wyjścia okna
function U.pokaz(okno, tak, rot)
	local a = okno:FindFirstChild("Animacja") or new("UIScale", { Name = "Animacja" }, okno)
	rot = rot or 0
	if tak then
		a.Scale = 0.7
		okno.Rotation = rot - 6
		okno.Visible = true
		TweenService:Create(a, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		TweenService:Create(okno, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Rotation = rot }):Play()
	else
		local t = TweenService:Create(a, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.75 })
		t:Play()
		t.Completed:Connect(function(s) if s == Enum.PlaybackState.Completed then okno.Visible = false end end)
	end
end

return U
