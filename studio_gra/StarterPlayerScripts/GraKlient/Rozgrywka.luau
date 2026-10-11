-- Rozgrywka po stronie klienta: rola, lista zadań, podświetlanie celu, prompty, duchy,
-- eliminacja, kratki, sabotaże (ciemność, alarm, kartkówka), naprawy.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")

local G = {}
local K, U, C, Mg, H
local szablon
local podswietlenie, belka, a0, a1
local ciemnosc

------------------------------------------------------------------ LISTA ZADAŃ (okno Zadania z szablonu)
local listaRzedy = {}
function G.odswiezListe()
	local okno = szablon:FindFirstChild("Okno_Zadania")
	if not okno then return end
	local f = okno.Lico
	-- schowaj statyczne wiersze szablonu (pierwsze uruchomienie)
	if not f:GetAttribute("Dynamiczne") then
		f:SetAttribute("Dynamiczne", true)
		for _, c in ipairs(f:GetChildren()) do
			local y = c:IsA("GuiObject") and c.Position.Y.Scale or 0
			if c:IsA("GuiObject") and y > 0.24 and c.Name ~= "Linia" and c.Name ~= "Margines" then c.Visible = false end
			if c:IsA("Frame") and c:FindFirstChildOfClass("TextLabel") and c:FindFirstChildOfClass("TextLabel").Text == "2/5" then c.Name = "Ocena" end
		end
	end
	for _, r in ipairs(listaRzedy) do r:Destroy() end
	listaRzedy = {}
	local s = K.stan
	local ocena = f:FindFirstChild("Ocena")
	local z = 0
	for _ in pairs(s.zrobione) do z += 1 end
	if ocena then
		local t = ocena:FindFirstChildOfClass("TextLabel")
		if t then t.Text = z .. "/" .. #s.zadania end
	end
	local pod = f:FindFirstChild("Podtytul")
	if pod then
		if not s.rola then pod.Text = "dostaniesz je po przyjeździe do szkoły"
		elseif K.jestZly() then pod.Text = "UDAWANE zadania – nic nie dają, ale pomagają się ukryć"
		else pod.Text = "kliknij zadanie, żeby je podświetlić" end
	end
	for i, id in ipairs(s.zadania) do
		local def = C.Zadania[id]
		local y = 0.2 + (i + 1) * 0.104 * 0.62 + 0.03
		y = 0.27 + (i - 1) * 0.085
		local rzad = U.new("TextButton", { Name = "Rzad_" .. id, Text = "", AutoButtonColor = false, BackgroundTransparency = s.wybraneZadanie == id and 0.55 or 1,
			BackgroundColor3 = U.YEL, BorderSizePixel = 0, Size = UDim2.fromScale(0.84, 0.075), Position = UDim2.fromScale(0.12, y) }, f)
		local box = U.new("Frame", { BackgroundColor3 = U.PAPER, BorderSizePixel = 0, Size = UDim2.fromScale(0.06, 0.06), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = UDim2.fromScale(0.02, 0.5), AnchorPoint = Vector2.new(0, 0.5) }, rzad)
		U.stroke(box, 2)
		local zrob = s.zrobione[id]
		if zrob then
			U.new("Frame", { BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.fromScale(0.45, 0.16), Position = UDim2.fromScale(0.08, 0.55), Rotation = 45 }, box)
			U.new("Frame", { BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.fromScale(0.95, 0.16), Position = UDim2.fromScale(0.25, 0.4), Rotation = -55 }, box)
		end
		U.txt(rzad, { RichText = true, Text = zrob and ("<s>" .. def.nazwa .. "</s>") or def.nazwa, TextTransparency = zrob and 0.45 or 0,
			Size = UDim2.fromScale(0.6, 0.85), Position = UDim2.fromScale(0.11, 0.08), TextXAlignment = Enum.TextXAlignment.Left })
		U.txt(rzad, { Text = def.gdzie, Size = UDim2.fromScale(0.3, 0.7), Position = UDim2.fromScale(0.69, 0.15), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = U.GREY })
		rzad.Activated:Connect(function()
			if s.zrobione[id] then return end
			s.wybraneZadanie = id
			K.dzwiek("Pstryk", 0.3)
			G.odswiezListe()
		end)
		table.insert(listaRzedy, rzad)
	end
end

------------------------------------------------------------------ PODŚWIETLENIE ZADANIA (lekko przez ściany)
local function obiektZadania(id)
	for _, pr in ipairs(CollectionService:GetTagged("PromptZadania")) do
		if pr:GetAttribute("Zadanie") == id then return pr.Parent end
	end
end
local function wybierzNastepne()
	local s = K.stan
	if s.wybraneZadanie and not s.zrobione[s.wybraneZadanie] and table.find(s.zadania, s.wybraneZadanie) then return s.wybraneZadanie end
	-- najbliższe niezrobione
	local h = K.hrp()
	local best, bd = nil, math.huge
	for _, id in ipairs(s.zadania) do
		if not s.zrobione[id] then
			local o = obiektZadania(id)
			if o and h then
				local d = (o.Position - h.Position).Magnitude
				if d < bd then best, bd = id, d end
			elseif not best then best = id end
		end
	end
	s.wybraneZadanie = best
	return best
end
function G.celZadania()
	local id = K.stan.wybraneZadanie
	return id and obiektZadania(id)
end

local function odswiezPodswietlenie()
	local s = K.stan
	local faza = K.Gra:GetAttribute("Faza")
	local id = (faza == "Gra" and s.ustawienia.podpowiedzi) and wybierzNastepne() or nil
	local czesc = id and obiektZadania(id)
	local adornee = czesc
	if czesc then
		local m = czesc:FindFirstAncestorOfClass("Model")
		if m and m:IsDescendantOf(workspace.SchoolMap) and (m:GetPivot().Position - czesc.Position).Magnitude < 12 then adornee = m end
	end
	if podswietlenie.Adornee ~= adornee then podswietlenie.Adornee = adornee end
	podswietlenie.Enabled = adornee ~= nil
	-- pulsowanie
	local t = os.clock()
	podswietlenie.FillTransparency = 0.72 + math.sin(t * 3) * 0.12
	-- belka od gracza do zadania (krótka strzałka)
	local h = K.hrp()
	if czesc and h then
		a0.Parent = h
		a1.Parent = czesc
		belka.Enabled = (czesc.Position - h.Position).Magnitude > 12
	else
		belka.Enabled = false
	end
end

------------------------------------------------------------------ PROMPTY (kto co widzi)
local function odswiezPrompty()
	local s = K.stan
	local faza = K.Gra:GetAttribute("Faza")
	for _, pr in ipairs(CollectionService:GetTagged("PromptZadania")) do
		local id = pr:GetAttribute("Zadanie")
		pr.Enabled = faza == "Gra" and table.find(s.zadania, id) ~= nil and not s.zrobione[id] and not s.minigra and not s.wKratce
	end
	for _, pr in ipairs(CollectionService:GetTagged("PromptNaprawa")) do
		local n = pr:GetAttribute("Naprawa")
		local aktywny = false
		if n == "Bezpieczniki" then aktywny = K.Gra:GetAttribute("Sab_Swiatlo") == true end
		if n == "Alarm1" or n == "Alarm2" then aktywny = K.Gra:GetAttribute("Sab_Alarm") ~= nil and not K.Gra:GetAttribute("Sab_" .. n) end
		pr.Enabled = faza == "Gra" and s.zyje and aktywny
	end
	local dzwon = workspace:FindFirstChild("SchoolMap") and workspace.SchoolMap:FindFirstChild("PromptDzwon", true)
	if dzwon then dzwon.Enabled = faza == "Gra" and s.zyje end
end

------------------------------------------------------------------ DUCHY
local function duchy()
	local jaZyje = K.stan.zyje or (K.Gra:GetAttribute("Faza") ~= "Gra" and K.Gra:GetAttribute("Faza") ~= "Spotkanie")
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		if ch and p ~= K.gracz then
			local duch = ch:GetAttribute("Duch") == true
			local mod = (duch and jaZyje) and 1 or 0
			for _, d in ipairs(ch:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = mod end
			end
		end
	end
end

------------------------------------------------------------------ SABOTAŻE: ciemność i alarm
local alarmOverlay, alarmDzwiek, alarmTekst
local function sabotaze()
	local zly = K.jestZly()
	local swiatlo = K.Gra:GetAttribute("Sab_Swiatlo") == true
	local ciemno = swiatlo and not zly and K.stan.zyje
	K.tween(ciemnosc, 0.6, { Brightness = ciemno and -0.55 or 0, Contrast = ciemno and 0.3 or 0, Saturation = ciemno and -0.6 or 0 })
	local alarm = K.Gra:GetAttribute("Sab_Alarm")
	alarmOverlay.Visible = alarm ~= nil
	if alarm then
		if not alarmDzwiek.IsPlaying then alarmDzwiek:Play() end
		local zost = math.max(0, math.ceil(alarm - K.czasSerwera()))
		local a1z = K.Gra:GetAttribute("Sab_Alarm1") and "✓" or "✗"
		local a2z = K.Gra:GetAttribute("Sab_Alarm2") and "✓" or "✗"
		alarmTekst.Text = "ALARM POŻAROWY! " .. zost .. " s   [sekretariat " .. a1z .. "]  [atrium " .. a2z .. "]"
		alarmOverlay.BackgroundTransparency = 0.82 + math.sin(os.clock() * 8) * 0.08
	elseif alarmDzwiek.IsPlaying then
		alarmDzwiek:Stop()
	end
end

------------------------------------------------------------------ EKRAN ELIMINACJI
local function ekranEliminacji(d)
	K.stan.zyje = false
	Mg.zamknij()
	local f = U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), ZIndex = 80 }, K.nad)
	local t = U.txt(f, { Text = d.powod or "WYELIMINOWANY!", Font = Enum.Font.Bangers, TextColor3 = U.RED, Size = UDim2.fromScale(0.8, 0.14),
		Position = UDim2.fromScale(0.1, 0.36), ZIndex = 81 })
	U.txt(f, { Text = "Jesteś teraz duchem. Inni cię nie widzą. Dalej rób zadania – liczą się dla szkoły!", TextColor3 = U.PAPER,
		Size = UDim2.fromScale(0.7, 0.06), Position = UDim2.fromScale(0.15, 0.54), ZIndex = 81 })
	K.dzwiek("Cios", 0.9)
	K.dzwiek("Smutny", 0.4)
	task.wait(2.6)
	K.tween(f, 0.6, { BackgroundTransparency = 1 })
	for _, x in ipairs(f:GetChildren()) do if x:IsA("TextLabel") then K.tween(x, 0.6, { TextTransparency = 1 }) end end
	task.wait(0.7)
	f:Destroy()
	G.odswiezListe()
end

------------------------------------------------------------------ KRATKI (menu)
local menuKratki
local function kratkaMenu(d)
	K.stan.wKratce = d.w
	if menuKratki then menuKratki:Destroy() menuKratki = nil end
	if not d.w then return end
	local h, f = U.karta(K.gui, "MenuKratki", UDim2.fromScale(0.5, 0.25), UDim2.fromScale(0.32, 0.1 + #d.inne * 0.06), Color3.fromRGB(60, 62, 75), Vector2.new(0.5, 0), 0)
	menuKratki = h
	U.txt(f, { Text = "W KRATCE: " .. d.nazwa, Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.9, 0.06 / (0.1 + #d.inne * 0.06) * 1.2),
		Position = UDim2.fromScale(0.05, 0.03) })
	for i, k in ipairs(d.inne) do
		local b = U.przyciskTekst(f, "K" .. i, "→ " .. k.nazwa, UDim2.fromScale(0.06, (0.08 + (i - 1) * 0.06) / (0.1 + #d.inne * 0.06)), UDim2.fromScale(0.88, 0.05 / (0.1 + #d.inne * 0.06)), U.PAPER2)
		b.Activated:Connect(function() K.wyslij("kratka", { akcja = "przejdz", cel = k.i }) end)
	end
end

------------------------------------------------------------------ KARTKÓWKA (sabotaż)
local function kartkowka(d)
	Mg.otworz({ nazwa = "Niezapowiedziana kartkówka!", gdzie = "Odpowiedz, żeby iść dalej", typ = "quiz", p = { ile = 1 } },
		{ pytania = { d.pytanie }, jedenRaz = true, bezX = true },
		function(ok) K.wyslij("kartkowka", { ok = ok }) end)
	task.delay(d.czas or 6, function() if Mg.otwarta() then Mg.zamknij() end end)
end

------------------------------------------------------------------ NAPRAWY
local function naprawa(pr)
	local n = pr:GetAttribute("Naprawa")
	if n == "Bezpieczniki" then
		Mg.otworz({ nazwa = "Napraw bezpieczniki", gdzie = "Kanciapa woźnej", typ = "sekwencja", p = { dl = 4, styl = "przelaczniki" } }, {}, function(ok)
			K.wyslij("naprawa", { punkt = n, ok = ok })
		end)
	else
		Mg.otworz({ nazwa = "Wyłącz alarm", gdzie = n == "Alarm1" and "Sekretariat" or "Atrium liceum", typ = "trzymaj", p = { czas = 2.5, tekst = "Trzymaj przycisk RESET..." } }, {}, function(ok)
			K.wyslij("naprawa", { punkt = n, ok = ok })
		end)
	end
end

function G.Init(k, moduly)
	K = k
	U = K.Styl
	C = K.C
	Mg = moduly.Minigry
	H = moduly.HUD
	szablon = K.PlayerGui:WaitForChild("SzablonUI")

	podswietlenie = U.new("Highlight", { Name = "CelZadania", FillColor = U.YEL, OutlineColor = U.YEL, FillTransparency = 0.75, OutlineTransparency = 0.15,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, K.gui)
	a0 = U.new("Attachment", { Name = "BelkaA0", Position = Vector3.new(0, -2.5, 0) })
	a1 = U.new("Attachment", { Name = "BelkaA1" })
	belka = U.new("Beam", { Attachment0 = a0, Attachment1 = a1, Color = ColorSequence.new(U.YEL), Width0 = 0.4, Width1 = 0.1, FaceCamera = true,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.15, 0.7), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(1, 1) }),
		LightEmission = 1, Enabled = false, Segments = 2 }, workspace.Terrain)
	ciemnosc = U.new("ColorCorrectionEffect", { Name = "Sabotaz" }, Lighting)
	alarmOverlay = U.new("Frame", { Name = "Alarm", BackgroundColor3 = Color3.fromRGB(255, 0, 0), BackgroundTransparency = 0.85, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 0 }, K.gui)
	alarmTekst = U.txt(alarmOverlay, { Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.7, 0.05), Position = UDim2.fromScale(0.15, 0.2), ZIndex = 2 })
	U.obrysTekstu(alarmTekst, 2.5)
	alarmDzwiek = U.new("Sound", { SoundId = C.Dzwieki.AlarmPozarowy, Looped = true, Volume = 0.35 }, game:GetService("SoundService"))

	K.na("Rola", function(d)
		local s = K.stan
		s.rola = d.rola
		s.zadania = d.zadania or {}
		s.zrobione = {}
		s.zyje = true
		s.wybraneZadanie = nil
		H.ustawWspolnikow(d.wspolnicy)
		G.odswiezListe()
	end)
	K.na("ZadanieOtworz", function(d)
		local def = C.Zadania[d.id]
		if not def then return end
		Mg.otworz(def, { mnoznik = d.mnoznik }, function(ok)
			if ok then K.wyslij("zadanieKoniec", { id = d.id, ok = true }) else K.wyslij("zadanieAnuluj") end
		end)
	end)
	K.na("ZadanieZrobione", function(d)
		K.stan.zrobione[d.id] = true
		if K.stan.wybraneZadanie == d.id then K.stan.wybraneZadanie = nil end
		G.odswiezListe()
	end)
	K.na("Wyeliminowany", ekranEliminacji)
	K.na("Kratka", kratkaMenu)
	K.na("Kartkowka", kartkowka)
	K.na("Faza", function(d)
		if d.faza == "Lobby" then
			K.stan.rola = nil
			K.stan.zadania = {}
			K.stan.zrobione = {}
			K.stan.zyje = true
			K.stan.dyrektorMoc = false
			K.stan.cooldown = {}
			G.odswiezListe()
			Mg.zamknij()
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(pr, kto)
		if kto ~= K.gracz then return end
		if CollectionService:HasTag(pr, "PromptNaprawa") then naprawa(pr) end
	end)
	G.odswiezListe()
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		odswiezPodswietlenie()
		duchy()
		t += dt
		if t > 0.2 then
			t = 0
			odswiezPrompty()
			sabotaze()
		end
	end)
end

return G
