-- Skrzynka młotów: animacja otwierania (wynik losuje serwer) i podgląd młotów 3D.
-- Styl jak reszta UI: papier, tusz, taśma, Bangers. Bez gradientów i świecenia.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local S = {}
local K, U, C
local trwa = false

local PAPIER = Color3.fromRGB(246, 239, 224)
local PAPIER2 = Color3.fromRGB(232, 221, 198)
local TUSZ = Color3.fromRGB(28, 30, 48)
local LINIA = Color3.fromRGB(160, 188, 226)
local TASMA = Color3.fromRGB(238, 228, 180)
local CZERWONY = Color3.fromRGB(214, 40, 57)
local ZOLTY = Color3.fromRGB(255, 212, 59)

local function tw(o, t, p, styl, kier)
	local x = TweenService:Create(o, TweenInfo.new(t, styl or Enum.EasingStyle.Quad, kier or Enum.EasingDirection.Out), p)
	x:Play()
	return x
end

local function rzadkosc(id)
	for _, r in ipairs(C.RzadkosciMlotow) do if r.id == id then return r end end
	return C.RzadkosciMlotow[1]
end
local function defMlota(id)
	for _, m in ipairs(C.Mloty) do if m.id == id then return m end end
end
function S.nazwa(id)
	local f = ReplicatedStorage:FindFirstChild("Mloty")
	local t = f and f:FindFirstChild(id)
	return (t and t:GetAttribute("Nazwa")) or id
end
function S.trwa() return trwa end

local dzwieki = {}
local function graj(nazwa, glosnosc, predkosc)
	local id = C.Dzwieki[nazwa]
	if not id then return end
	local s = dzwieki[nazwa]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.SoundGroup = K.grupaSfx
		s.Parent = game:GetService("SoundService")
		dzwieki[nazwa] = s
	end
	s.Volume = glosnosc or 0.5
	s.PlaybackSpeed = predkosc or 1
	s.TimePosition = 0
	s:Play()
end

------------------------------------------------------------------ PODGLĄD 3D
-- kopia młota bez skryptów i efektów, uchwyt w środku układu
local function modelMlota(id)
	local folder = ReplicatedStorage:FindFirstChild("Mloty")
	local wzor = folder and folder:FindFirstChild(id)
	if not wzor then return end
	local kopia = wzor:Clone()
	local m = Instance.new("Model")
	for _, d in ipairs(kopia:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail")
			or d:IsA("Beam") or d:IsA("Light") or d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	for _, c in ipairs(kopia:GetChildren()) do c.Parent = m end
	kopia:Destroy()
	local h = m:FindFirstChild("Handle")
	local rel = h and h.CFrame:Inverse() or CFrame.identity
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CFrame = rel * d.CFrame
			if d.Transparency >= 0.99 then d:Destroy() end
		end
	end
	return m
end

-- opcje: size, pos, anchor, z, kat (pochylenie), zoom, sylwetka
function S.podglad(par, id, opcje)
	opcje = opcje or {}
	local stary = par:FindFirstChild("Mlot3D")
	if stary then stary:Destroy() end
	local m = modelMlota(id)
	if not m then return end
	local vp = U.new("ViewportFrame", {
		Name = "Mlot3D", BackgroundTransparency = 1,
		Size = opcje.size or UDim2.fromScale(1, 1), Position = opcje.pos or UDim2.fromScale(0, 0),
		AnchorPoint = opcje.anchor or Vector2.zero, ZIndex = opcje.z or (par.ZIndex + 1),
		Ambient = Color3.fromRGB(165, 165, 175), LightColor = Color3.fromRGB(255, 248, 235),
		LightDirection = Vector3.new(-0.5, -1, -0.7),
	}, par)
	if opcje.sylwetka then
		vp.ImageColor3 = TUSZ
		vp.Ambient = Color3.new(0, 0, 0)
		vp.LightColor = Color3.new(0, 0, 0)
	end
	local obrot = CFrame.Angles(0, 0, math.rad(opcje.kat or -32))
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.CFrame = obrot * d.CFrame end
	end
	m.Parent = vp
	local cf, size = m:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 26
	local r = math.max(size.X, size.Y) * 0.5
	local dist = r / math.tan(math.rad(cam.FieldOfView / 2)) * (opcje.zoom or 1.1)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.16, 0.1, 1).Unit * dist, cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp:SetAttribute("Mlot", id)
	return vp, cam, cf.Position, dist
end

------------------------------------------------------------------ ELEMENTY
local function cien(par, z, przes)
	local s = U.new("Frame", { Name = "Cien", BackgroundColor3 = TUSZ, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(0, przes or 4, 0, (przes or 4) + 1), ZIndex = z }, par)
	U.corner(s, UDim.new(0, 6))
	return s
end

-- karta młota na taśmie: papier w linie, model, pasek rzadkości na dole
local function kartaMlota(par, id, szer, z)
	local def = defMlota(id)
	local r = rzadkosc(def and def.rzadkosc)
	local h = U.new("Frame", { Name = "Karta", BackgroundTransparency = 1, Size = UDim2.new(0, szer, 1, -22),
		AnchorPoint = Vector2.new(0, 0.5), ZIndex = z }, par)
	cien(h, z, 3)
	local lico = U.new("Frame", { Name = "Lico", BackgroundColor3 = PAPIER, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		ZIndex = z + 1, ClipsDescendants = true }, h)
	U.corner(lico, UDim.new(0, 6))
	U.stroke(lico, 2.5, TUSZ)
	for i = 1, 4 do
		U.new("Frame", { BackgroundColor3 = LINIA, BackgroundTransparency = 0.45, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.14 + i * 0.15), ZIndex = z + 1 }, lico)
	end
	local pasek = U.new("Frame", { Name = "Pasek", BackgroundColor3 = r.kolor, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.8), ZIndex = z + 2 }, lico)
	U.new("Frame", { BackgroundColor3 = TUSZ, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), ZIndex = z + 3 }, pasek)
	local t = U.txt(pasek, { Text = string.upper(r.id), Font = Enum.Font.Bangers, TextColor3 = PAPIER,
		Size = UDim2.fromScale(0.9, 0.72), Position = UDim2.fromScale(0.05, 0.18), ZIndex = z + 3 })
	U.obrysTekstu(t, 1.5, TUSZ)
	S.podglad(lico, id, { size = UDim2.fromScale(0.94, 0.76), pos = UDim2.fromScale(0.03, 0.03), z = z + 2 })
	return h, lico
end

-- wypełnienie taśmy: losowo wg tych samych szans co serwer (bez podkręcania „prawie wygranych”)
local function losowyMlot()
	local szanse = C.SkrzynkaMlotow.szanse
	local suma = 0
	for _, r in ipairs(C.RzadkosciMlotow) do suma += szanse[r.id] or 0 end
	local los = math.random() * suma
	local wybrana = "Rzadki"
	for _, r in ipairs(C.RzadkosciMlotow) do
		local w = szanse[r.id] or 0
		if w > 0 then
			if los < w then wybrana = r.id break end
			los -= w
		end
	end
	local pula = {}
	for _, m in ipairs(C.Mloty) do if m.rzadkosc == wybrana and not m.domyslny then table.insert(pula, m.id) end end
	return pula[math.random(#pula)]
end

local function trzes(o, sila, czas)
	local baza = o.Position
	local t0 = os.clock()
	while os.clock() - t0 < czas do
		local k = 1 - (os.clock() - t0) / czas
		o.Position = baza + UDim2.fromOffset(math.random(-sila, sila) * k, math.random(-sila, sila) * k)
		RunService.RenderStepped:Wait()
	end
	o.Position = baza
end

-- paski papieru i taśmy rozlatujące się z otwartej skrzynki (neutralne kolory – nie zdradzają rzadkości)
local function scinki(par, srodek, z)
	for i = 1, 16 do
		local kol = ({ PAPIER, PAPIER2, TASMA, PAPIER })[i % 4 + 1]
		local f = U.new("Frame", { BackgroundColor3 = kol, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.random(10, 22), math.random(26, 46)), Position = UDim2.fromOffset(srodek.X, srodek.Y),
			Rotation = math.random(0, 360), ZIndex = z }, par)
		U.stroke(f, 1.5, TUSZ)
		local kat = math.rad(i * (360 / 16) + math.random(-10, 10))
		local dl = math.random(160, 300)
		tw(f, 0.7, { Position = UDim2.fromOffset(srodek.X + math.cos(kat) * dl, srodek.Y + math.sin(kat) * dl + 60),
			Rotation = f.Rotation + math.random(-200, 200), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
		local s = f:FindFirstChildOfClass("UIStroke")
		if s then tw(s, 0.7, { Transparency = 1 }, Enum.EasingStyle.Quart) end
		task.delay(0.75, function() f:Destroy() end)
	end
end

------------------------------------------------------------------ ANIMACJA
local function otworz(wynik)
	if trwa then return end
	trwa = true
	pcall(K.sterowanie, false, "Skrzynka")
	local r = rzadkosc(wynik.rzadkosc)
	local poziom = 1
	for i, x in ipairs(C.RzadkosciMlotow) do if x.id == r.id then poziom = i end end
	local wysoka = poziom >= 4 -- Legendarny i wyżej

	local gui = U.new("ScreenGui", { Name = "SkrzynkaGUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, K.PlayerGui)
	local root = U.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
	local tlo = U.new("TextButton", { Name = "Tlo", Text = "", AutoButtonColor = false, BackgroundColor3 = TUSZ,
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 1, Modal = true }, root)
	tw(tlo, 0.25, { BackgroundTransparency = 0.22 })
	local W, H = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local pominiete = false

	-- taśma z kartami (budowana od razu, pokazywana po skrzynce)
	local pas = U.new("Frame", { Name = "Pas", BackgroundColor3 = PAPIER2, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, math.floor(H * 0.3)), Position = UDim2.fromScale(0.5, 1.35), ZIndex = 10 }, root)
	U.stroke(pas, 3, TUSZ)
	U.tasma(pas, UDim2.fromScale(0.02, 0.06), UDim2.fromOffset(70, 22), -24).ZIndex = 30
	U.tasma(pas, UDim2.fromScale(0.98, 0.94), UDim2.fromOffset(70, 22), -24).ZIndex = 30
	local okno = U.new("Frame", { Name = "Okno", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0), ZIndex = 11 }, pas)
	local tasma = U.new("Frame", { Name = "Tasma", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11 }, okno)
	local pasW = W * 0.9 - 12
	local szer = math.floor(H * 0.3 * 0.78)
	local krok = szer + 14
	local ILE = 34
	local WYGRANA = 29
	local karty = {}
	-- wskaźnik: czerwona kreska jak flamastrem, z „zadziorami” u góry i dołu
	local wsk = U.new("Frame", { Name = "Wskaznik", BackgroundColor3 = CZERWONY, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 4, 1, 26), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 40 }, pas)
	U.stroke(wsk, 1.5, TUSZ)
	for _, y in ipairs({ 0, 1 }) do
		local g = U.new("Frame", { BackgroundColor3 = CZERWONY, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0.5, 0, y, y == 0 and -12 or 12), Rotation = 45, ZIndex = 41 }, pas)
		U.stroke(g, 2, TUSZ)
	end
	task.spawn(function()
		for i = 1, ILE do
			local id = i == WYGRANA and wynik.mlot or losowyMlot()
			local k = kartaMlota(tasma, id, szer, 12)
			k.Position = UDim2.new(0, (i - 1) * krok, 0.5, 0)
			karty[i] = k
			if i % 3 == 0 then task.wait() end
		end
	end)

	-- skrzynka spada
	local Ikony = require(ReplicatedStorage.Gra:WaitForChild("Ikony"))
	local bok = math.floor(H * 0.34)
	local cienSk = U.new("Frame", { BackgroundColor3 = TUSZ, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(bok * 0.2, bok * 0.06), Position = UDim2.new(0.5, 0, 0.5, bok * 0.48), ZIndex = 5 }, root)
	U.corner(cienSk, UDim.new(1, 0))
	local sk = U.new("ImageLabel", { Name = "Skrzynka", BackgroundTransparency = 1, Image = Ikony.SkrzynkaMlotkow or "",
		ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(bok, bok),
		Position = UDim2.new(0.5, 0, -0.1, 0), ZIndex = 6 }, root)
	local podpis = U.txt(root, { Text = "SKRZYNKA MŁOTÓW", Font = Enum.Font.Bangers, TextColor3 = PAPIER, AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(bok * 1.4, bok * 0.18), Position = UDim2.new(0.5, 0, 0.5, bok * 0.58), TextTransparency = 1, ZIndex = 6 })
	U.obrysTekstu(podpis, 2, TUSZ)
	tw(sk, 0.42, { Position = UDim2.new(0.5, 0, 0.5, bok * 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(cienSk, 0.42, { Size = UDim2.fromOffset(bok * 0.9, bok * 0.12), BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.42)
	graj("Bonk", 0.55, 0.8)
	-- zgniecenie przy lądowaniu
	sk.Size = UDim2.fromOffset(bok * 1.14, bok * 0.84)
	tw(sk, 0.35, { Size = UDim2.fromOffset(bok, bok) }, Enum.EasingStyle.Back)
	tw(podpis, 0.3, { TextTransparency = 0 })
	task.spawn(trzes, root, 6, 0.18)
	task.wait(0.45)

	-- trzy szarpnięcia, coraz mocniejsze
	for n, sila in ipairs({ 7, 11, 16 }) do
		if pominiete then break end
		for j = 1, 4 do
			local kat = (j % 2 == 0) and -sila or sila
			tw(sk, 0.05, { Rotation = kat })
			task.wait(0.05)
		end
		tw(sk, 0.08, { Rotation = 0 })
		graj("Pstryk", 0.5, 0.9 + n * 0.12)
		task.wait(n < 3 and 0.32 or 0.18)
	end

	-- otwarcie: skrzynka wyskakuje i znika, lecą ścinki
	graj("Boing", 0.5, 1.1)
	local srodek = Vector2.new(sk.AbsolutePosition.X + sk.AbsoluteSize.X / 2 - root.AbsolutePosition.X, sk.AbsolutePosition.Y + sk.AbsoluteSize.Y * 0.55 - root.AbsolutePosition.Y)
	scinki(root, srodek, 8)
	tw(sk, 0.2, { Size = UDim2.fromOffset(bok * 1.35, bok * 1.35), ImageTransparency = 1 })
	tw(cienSk, 0.2, { BackgroundTransparency = 1 })
	tw(podpis, 0.15, { TextTransparency = 1 })
	task.wait(0.15)

	-- taśma wjeżdża i się kręci
	while #karty < ILE do task.wait() end
	tw(pas, 0.4, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
	task.wait(0.35)
	local start = pasW / 2 - szer / 2
	local cel = pasW / 2 - ((WYGRANA - 1) * krok + szer / 2) + math.random(-math.floor(szer * 0.32), math.floor(szer * 0.32))
	local czas = wysoka and 6.4 or 5.4
	local t0 = os.clock()
	local ostatniIdx, ostatniTyk = 0, 0
	local polaczenie
	tlo.Activated:Connect(function() pominiete = true end)
	local koniec = Instance.new("BindableEvent")
	polaczenie = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - t0) / czas, 0, 1)
		if pominiete then t = 1 end
		local e = 1 - (1 - t) ^ 4
		local x = start + (cel - start) * e
		tasma.Position = UDim2.fromOffset(x, 0)
		local idx = math.floor((pasW / 2 - x) / krok)
		if idx ~= ostatniIdx and os.clock() - ostatniTyk > 0.035 and not pominiete then
			ostatniIdx = idx
			ostatniTyk = os.clock()
			graj("Klik", 0.32, 0.95 + math.random() * 0.15)
		end
		if t >= 1 then
			polaczenie:Disconnect()
			koniec:Fire()
		end
	end)
	koniec.Event:Wait()
	koniec:Destroy()

	-- wygrana karta podskakuje, reszta taśmy zjeżdża
	local wk = karty[WYGRANA]
	local skal = U.new("UIScale", {}, wk)
	tw(skal, 0.12, { Scale = 1.1 })
	graj("Pstryk", 0.6, 0.8)
	task.wait(0.3)
	local absPos, absSize = wk.AbsolutePosition - root.AbsolutePosition, wk.AbsoluteSize
	wk.Visible = false
	tw(pas, 0.35, { Position = UDim2.fromScale(0.5, 1.4) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)

	-- promienie za kartą: cienkie paski papieru w kolorze rzadkości
	local promienie = U.new("Frame", { Name = "Promienie", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(H * 1.1, H * 1.1), Position = UDim2.fromScale(0.5, 0.44), ZIndex = 3 }, root)
	local paski = {}
	for i = 1, 12 do
		local p = U.new("Frame", { BackgroundColor3 = r.kolor, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, math.floor(H * 0.06), 1, 0), Position = UDim2.fromScale(0.5, 0.5), Rotation = i * 15, ZIndex = 3 }, promienie)
		table.insert(paski, p)
		tw(p, 0.4, { BackgroundTransparency = wysoka and 0.55 or 0.72 })
	end
	local skalaP = U.new("UIScale", { Scale = 0.2 }, promienie)
	tw(skalaP, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	local obrotPol = RunService.RenderStepped:Connect(function(dt)
		promienie.Rotation += dt * (wysoka and 14 or 8)
		if r.id == "Sekretny" then
			local hue = (os.clock() * 0.18) % 1
			for i, p in ipairs(paski) do p.BackgroundColor3 = Color3.fromHSV((hue + i / #paski) % 1, 0.55, 1) end
		end
	end)

	-- duża karta leci na środek
	local duzaW = math.floor(H * 0.34)
	local duza = U.new("Frame", { Name = "Wygrana", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(absSize.X, absSize.Y), Position = UDim2.fromOffset(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2), ZIndex = 20 }, root)
	cien(duza, 20, 6)
	local lico = U.new("Frame", { BackgroundColor3 = PAPIER, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 21, ClipsDescendants = true }, duza)
	U.corner(lico, UDim.new(0, 8))
	U.stroke(lico, 4, TUSZ)
	for i = 1, 5 do
		U.new("Frame", { BackgroundColor3 = LINIA, BackgroundTransparency = 0.45, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.1 + i * 0.13), ZIndex = 21 }, lico)
	end
	U.new("Frame", { BackgroundColor3 = CZERWONY, BackgroundTransparency = 0.35, BorderSizePixel = 0,
		Size = UDim2.new(0, 2, 1, 0), Position = UDim2.fromScale(0.12, 0), ZIndex = 21 }, lico)
	local pasekD = U.new("Frame", { BackgroundColor3 = r.kolor, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.16), Position = UDim2.fromScale(0, 0.84), ZIndex = 22 }, lico)
	U.new("Frame", { BackgroundColor3 = TUSZ, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 3), ZIndex = 23 }, pasekD)
	local vp, cam, srodekM, dist = S.podglad(lico, wynik.mlot, { size = UDim2.fromScale(0.96, 0.82), pos = UDim2.fromScale(0.02, 0.02), z = 22, zoom = 1.05 })
	U.tasma(duza, UDim2.fromScale(0.5, 0), UDim2.fromOffset(duzaW * 0.42, 24), -4).ZIndex = 30
	tw(duza, 0.5, { Size = UDim2.fromOffset(duzaW, math.floor(duzaW * 1.2)), Position = UDim2.fromScale(0.5, 0.44) }, Enum.EasingStyle.Quint)
	-- model lekko kołysze się w lewo i prawo
	local obrotMod
	if cam then
		local tStart = os.clock()
		obrotMod = RunService.RenderStepped:Connect(function()
			local a = math.sin((os.clock() - tStart) * 0.9) * 0.55
			cam.CFrame = CFrame.lookAt(srodekM + Vector3.new(math.sin(a) * dist, 0.1 * dist, math.cos(a) * dist), srodekM)
		end)
	end
	task.wait(0.45)

	-- pieczątka z rzadkością
	if poziom >= 5 then
		local blysk = U.new("Frame", { BackgroundColor3 = PAPIER, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 50 }, root)
		tw(blysk, 0.45, { BackgroundTransparency = 1 })
		task.delay(0.5, function() blysk:Destroy() end)
	end
	local piecz = U.txt(root, { Text = string.upper(r.id) .. "!", Font = Enum.Font.Bangers, TextColor3 = r.kolor, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(duzaW * 1.6, duzaW * 0.34), Position = UDim2.new(0.5, 0, 0.44, -duzaW * 0.72), Rotation = -7,
		TextTransparency = 1, ZIndex = 35 })
	U.obrysTekstu(piecz, 4, TUSZ)
	local skalaPiecz = U.new("UIScale", { Scale = 2.6 }, piecz)
	tw(skalaPiecz, 0.16, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(piecz, 0.12, { TextTransparency = 0 })
	task.wait(0.16)
	graj(wysoka and "Fajerwerk" or "Bonk", wysoka and 0.6 or 0.5, wysoka and 1 or 0.7)
	if poziom >= 3 then graj("Sukces", 0.4) end
	task.spawn(trzes, root, wysoka and 14 or 7, wysoka and 0.4 or 0.2)

	-- nazwa i status
	local nazwa = U.txt(root, { Text = S.nazwa(wynik.mlot), Font = Enum.Font.Bangers, TextColor3 = PAPIER, AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(duzaW * 2, duzaW * 0.16), Position = UDim2.new(0.5, 0, 0.44, duzaW * 0.66), TextTransparency = 1, ZIndex = 35 })
	U.obrysTekstu(nazwa, 2.5, TUSZ)
	tw(nazwa, 0.25, { TextTransparency = 0 })
	local naklejka, nf = U.karta(root, "Status", UDim2.new(0.5, 0, 0.44, duzaW * 0.86), UDim2.fromOffset(duzaW * 1.1, duzaW * 0.14),
		wynik.duplikat and PAPIER2 or ZOLTY, Vector2.new(0.5, 0), wynik.duplikat and 1.5 or -2.5)
	for _, d in ipairs(naklejka:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 36 end end
	naklejka.ZIndex = 36
	U.txt(nf, { Text = wynik.duplikat and ("MASZ JUŻ GO · +" .. (wynik.zwrot or 0) .. " zł") or "NOWY MŁOT!", Font = Enum.Font.Bangers,
		Size = UDim2.fromScale(0.9, 0.78), Position = UDim2.fromScale(0.05, 0.11), ZIndex = 37 })
	local skalaN = U.new("UIScale", { Scale = 0 }, naklejka)
	tw(skalaN, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	if wynik.duplikat then task.delay(0.2, function() graj("Moneta", 0.6) end) end
	task.wait(0.35)

	-- przyciski
	local zamkniete = false
	local function zamknij()
		if zamkniete then return end
		zamkniete = true
		if obrotPol then obrotPol:Disconnect() end
		if obrotMod then obrotMod:Disconnect() end
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") then tw(d, 0.2, { TextTransparency = 1 }) end
			if d:IsA("ImageLabel") or d:IsA("ViewportFrame") then tw(d, 0.2, { ImageTransparency = 1 }) end
			if d:IsA("Frame") or d:IsA("TextButton") then tw(d, 0.2, { BackgroundTransparency = 1 }) end
			if d:IsA("UIStroke") then tw(d, 0.2, { Transparency = 1 }) end
		end
		task.delay(0.25, function()
			gui:Destroy()
			trwa = false
			pcall(K.sterowanie, true, "Skrzynka")
		end)
	end
	local yBt = UDim2.new(0.5, 0, 0.44, duzaW * 1.12)
	local profil = K.stan.profil
	local zalozony = profil and profil.mlot == wynik.mlot
	if not zalozony then
		local zb = U.przyciskTekst(root, "Zaloz", "ZAŁÓŻ", yBt + UDim2.fromOffset(-duzaW * 0.33, 0), UDim2.fromOffset(duzaW * 0.6, duzaW * 0.17), ZOLTY, TUSZ, Vector2.new(0.5, 0), -2)
		for _, d in ipairs(zb:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex += 30 end end
		zb.ZIndex = 38
		zb.Activated:Connect(function()
			K.wyslij("kup", { rodzaj = "mlot", id = wynik.mlot })
			zamknij()
		end)
	end
	local ob = U.przyciskTekst(root, "Ok", "SUPER", yBt + UDim2.fromOffset(zalozony and 0 or duzaW * 0.33, 0), UDim2.fromOffset(duzaW * 0.6, duzaW * 0.17), PAPIER, TUSZ, Vector2.new(0.5, 0), 2)
	for _, d in ipairs(ob:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex += 30 end end
	ob.ZIndex = 38
	ob.Activated:Connect(zamknij)
end

function S.Init(k)
	K = k
	U = K.Styl
	C = K.C
	K.na("Skrzynka", function(d)
		local ok, err = pcall(otworz, d)
		if not ok then
			warn("[Skrzynka] " .. tostring(err))
			local g = K.PlayerGui:FindFirstChild("SkrzynkaGUI")
			if g then g:Destroy() end
			trwa = false
			pcall(K.sterowanie, true, "Skrzynka")
		end
	end)
end

return S
