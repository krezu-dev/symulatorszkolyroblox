-- Minigry zadań: quiz, trzymaj, plamy, klikanie, sekwencja, wyczucie, pisz, kod.
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Mg = {}
local K, U, C
local okno, otwarta
local polaczenia = {}

local function odlacz()
	for _, c in ipairs(polaczenia) do c:Disconnect() end
	polaczenia = {}
end
local function pol(c) table.insert(polaczenia, c) return c end

local function zamknijOkno(ok)
	if not otwarta then return end
	local cb = otwarta.cb
	otwarta = nil
	odlacz()
	K.stan.minigra = false
	if okno then
		local o = okno
		okno = nil
		if ok then
			-- pieczątka „ZROBIONE”
			local st = U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.5, 0.2), Position = UDim2.fromScale(0.5, 0.55),
				AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -12, ZIndex = 50 }, o.Lico)
			U.stroke(st, 4, U.GREEN)
			U.corner(st, UDim.new(0, 6))
			U.txt(st, { Text = "ZROBIONE!", Font = Enum.Font.Bangers, TextColor3 = U.GREEN, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), ZIndex = 51 })
			local sc = U.new("UIScale", { Scale = 2.2 }, st)
			K.tween(sc, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
			K.dzwiek("Sukces", 0.6)
			task.delay(0.7, function() U.pokaz(o, false) task.delay(0.3, function() o:Destroy() end) end)
		else
			U.pokaz(o, false)
			task.delay(0.3, function() o:Destroy() end)
		end
	end
	if cb then cb(ok) end
end
function Mg.zamknij() zamknijOkno(false) end
function Mg.otwarta() return otwarta ~= nil end

local function trzes(o)
	local p = o.Position
	for i = 1, 6 do
		o.Position = p + UDim2.fromOffset((i % 2 == 0) and 6 or -6, 0)
		task.wait(0.03)
	end
	o.Position = p
end
local function zle(o)
	K.dzwiek("Blad", 0.45)
	task.spawn(trzes, o)
end

local function bezOgonkow(s)
	s = string.lower(s)
	local mapa = { ["ą"] = "a", ["ć"] = "c", ["ę"] = "e", ["ł"] = "l", ["ń"] = "n", ["ó"] = "o", ["ś"] = "s", ["ź"] = "z", ["ż"] = "z",
		["Ą"] = "a", ["Ć"] = "c", ["Ę"] = "e", ["Ł"] = "l", ["Ń"] = "n", ["Ó"] = "o", ["Ś"] = "s", ["Ź"] = "z", ["Ż"] = "z" }
	for k, v in pairs(mapa) do s = string.gsub(s, k, v) end
	s = string.gsub(s, "%s+", " ")
	return string.match(s, "^%s*(.-)%s*$")
end

------------------------------------------------------------------ RODZAJE
local R = {}

R.quiz = function(pole, p, koniec, opts)
	local pula = (opts and opts.pytania) or C.Pytania[p.pula] or C.Pytania.Matma
	local kolejka = {}
	local los = table.clone(pula)
	for i = #los, 2, -1 do local j = math.random(i) los[i], los[j] = los[j], los[i] end
	for i = 1, math.min(p.ile or 2, #los) do kolejka[i] = los[i] end
	local nr = 1
	local pyt = U.txt(pole, { Name = "Pytanie", Size = UDim2.fromScale(0.9, 0.24), Position = UDim2.fromScale(0.05, 0.0), TextWrapped = true, Font = Enum.Font.PatrickHand })
	local licz = U.txt(pole, { Size = UDim2.fromScale(0.3, 0.08), Position = UDim2.fromScale(0.68, -0.1), TextColor3 = U.RED, TextXAlignment = Enum.TextXAlignment.Right })
	local przyciski = {}
	local function pokaz()
		for _, b in ipairs(przyciski) do b:Destroy() end
		przyciski = {}
		local q = kolejka[nr]
		pyt.Text = q.q
		licz.Text = nr .. "/" .. #kolejka
		local kol = {}
		for i = 1, #q.odp do kol[i] = i end
		for i = #kol, 2, -1 do local j = math.random(i) kol[i], kol[j] = kol[j], kol[i] end
		for k, i in ipairs(kol) do
			local c = (k - 1) % 2
			local r = math.floor((k - 1) / 2)
			local b = U.przyciskTekst(pole, "Odp" .. i, q.odp[i], UDim2.fromScale(0.04 + c * 0.48, 0.32 + r * 0.32), UDim2.fromScale(0.44, 0.26),
				({ U.YEL, Color3.fromRGB(245, 160, 180), Color3.fromRGB(140, 195, 240), Color3.fromRGB(150, 215, 170) })[k], U.INK, nil, 0)
			b.Lico.Tekst.Font = Enum.Font.PatrickHand
			table.insert(przyciski, b)
			b.Activated:Connect(function()
				if not otwarta then return end
				if i == q.ok then
					K.dzwiek("Pstryk", 0.5)
					nr += 1
					if nr > #kolejka then koniec(true) else pokaz() end
				else
					zle(b)
					if opts and opts.jedenRaz then koniec(false) end
				end
			end)
		end
	end
	pokaz()
end

R.trzymaj = function(pole, p, koniec, opts)
	local czas = (p.czas or 3) * ((opts and opts.mnoznik) or 1)
	U.txt(pole, { Text = p.tekst or "Trzymaj...", Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.02) })
	local pasek = U.new("Frame", { BackgroundColor3 = U.PAPER2, BorderSizePixel = 0, Size = UDim2.fromScale(0.86, 0.13), Position = UDim2.fromScale(0.07, 0.25) }, pole)
	U.stroke(pasek, 2.5)
	local fill = U.new("Frame", { BackgroundColor3 = U.YEL, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, pasek)
	for t = 1, 9 do U.new("Frame", { BackgroundColor3 = U.INK, BorderSizePixel = 0, Size = UDim2.new(0, 1, 0.4, 0), Position = UDim2.fromScale(t / 10, 0.6), BackgroundTransparency = 0.3 }, pasek) end
	local b = U.przyciskTekst(pole, "Trzymaj", "TRZYMAJ", UDim2.fromScale(0.5, 0.66), UDim2.fromScale(0.5, 0.3), U.RED, U.PAPER, Vector2.new(0.5, 0.5))
	U.txt(pole, { Text = "(albo trzymaj SPACJĘ)", TextColor3 = U.GREY, Size = UDim2.fromScale(0.6, 0.07), Position = UDim2.fromScale(0.2, 0.86) })
	local trzyma, postep = false, 0
	pol(b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then trzyma = true end end))
	pol(b.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then trzyma = false end end))
	pol(UserInputService.InputBegan:Connect(function(i, gp) if i.KeyCode == Enum.KeyCode.Space then trzyma = true end end))
	pol(UserInputService.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.Space or i.UserInputType == Enum.UserInputType.MouseButton1 then trzyma = false end end))
	pol(RunService.RenderStepped:Connect(function(dt)
		if trzyma then postep += dt / czas else postep = math.max(0, postep - dt * 0.15) end
		fill.Size = UDim2.fromScale(math.clamp(postep, 0, 1), 1)
		if postep >= 1 then koniec(true) end
	end))
end

local STYLE_PLAM = {
	woda = { kolor = Color3.fromRGB(120, 170, 230), tlo = Color3.fromRGB(205, 200, 190) },
	kompot = { kolor = Color3.fromRGB(190, 60, 90), tlo = Color3.fromRGB(205, 200, 190) },
	kreda = { kolor = Color3.fromRGB(240, 240, 235), tlo = Color3.fromRGB(40, 85, 60) },
	farba = { kolor = nil, tlo = Color3.fromRGB(250, 248, 240) },
	kurz = { kolor = Color3.fromRGB(150, 150, 150), tlo = Color3.fromRGB(220, 190, 110) },
	ubrania = { teksty = { "skarpetka", "koszulka", "spodenki", "but", "ręcznik", "bidon" }, tlo = Color3.fromRGB(205, 200, 190) },
	oceny = { teksty = { "5", "4+", "3", "6", "2-", "5-", "4", "1" }, tlo = Color3.fromRGB(250, 250, 245) },
	podpis = { teksty = { "świadectwo", "świadectwo", "świadectwo", "świadectwo", "świadectwo", "świadectwo" }, tlo = Color3.fromRGB(230, 220, 200) },
}
R.plamy = function(pole, p, koniec)
	local styl = STYLE_PLAM[p.styl] or STYLE_PLAM.woda
	U.txt(pole, { Text = p.tekst or "Klikaj!", Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.05, -0.02) })
	local plotno = U.new("Frame", { BackgroundColor3 = styl.tlo, BorderSizePixel = 0, Size = UDim2.fromScale(0.92, 0.82), Position = UDim2.fromScale(0.04, 0.13), ClipsDescendants = true }, pole)
	U.stroke(plotno, 2.5)
	local zostalo = p.ile or 6
	for i = 1, zostalo do
		local rozm = math.random(16, 24) / 100
		local b = U.new("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromScale(rozm, rozm), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.fromScale(math.random(5, 78) / 100, math.random(8, 72) / 100), Rotation = math.random(-25, 25) }, plotno)
		if styl.teksty then
			b.BackgroundColor3 = U.PAPER
			b.Size = UDim2.fromScale(0.2, 0.18)
			U.stroke(b, 2)
			U.txt(b, { Text = styl.teksty[(i - 1) % #styl.teksty + 1], Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.05, 0.15) })
		else
			b.BackgroundColor3 = styl.kolor or Color3.fromHSV(math.random(), 0.7, 0.9)
			b.BackgroundTransparency = 0.1
			U.corner(b, UDim.new(1, 0))
		end
		b.Activated:Connect(function()
			if b:GetAttribute("Klik") then return end
			b:SetAttribute("Klik", true)
			K.dzwiek("Pstryk", 0.35)
			if p.styl == "podpis" or p.styl == "oceny" then
				U.txt(b, { Text = p.styl == "podpis" and "~Dyr~" or "✓", TextColor3 = U.RED, Font = Enum.Font.PermanentMarker, Size = UDim2.fromScale(0.8, 0.6), Position = UDim2.fromScale(0.1, 0.3), ZIndex = 3 })
				K.tween(b, 0.3, { BackgroundTransparency = 0.4 })
			else
				K.tween(b, 0.25, { BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0) })
				for _, d in ipairs(b:GetDescendants()) do if d:IsA("TextLabel") then K.tween(d, 0.2, { TextTransparency = 1 }) end if d:IsA("UIStroke") then d.Transparency = 1 end end
			end
			zostalo -= 1
			if zostalo <= 0 then task.delay(0.25, function() koniec(true) end) end
		end)
	end
end

R.klikanie = function(pole, p, koniec)
	local ile = p.ile or 20
	U.txt(pole, { Text = p.tekst or "Klikaj!", Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.05, 0.0) })
	local pasek = U.new("Frame", { BackgroundColor3 = U.PAPER2, BorderSizePixel = 0, Size = UDim2.fromScale(0.86, 0.11), Position = UDim2.fromScale(0.07, 0.2) }, pole)
	U.stroke(pasek, 2.5)
	local fill = U.new("Frame", { BackgroundColor3 = U.GREEN, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, pasek)
	local b, f = U.przyciskTekst(pole, "Klik", "KLIK!", UDim2.fromScale(0.5, 0.64), UDim2.fromScale(0.42, 0.42), U.YEL, U.INK, Vector2.new(0.5, 0.5))
	b.SizeConstraint = Enum.SizeConstraint.RelativeYY
	U.txt(pole, { Text = "(albo SPACJA)", TextColor3 = U.GREY, Size = UDim2.fromScale(0.5, 0.07), Position = UDim2.fromScale(0.25, 0.9) })
	local wartosc = 0
	local function klik()
		wartosc += 1
		K.dzwiek("Pstryk", 0.25)
		f.Rotation = math.random(-8, 8)
		if wartosc >= ile then koniec(true) end
	end
	b.Activated:Connect(klik)
	pol(UserInputService.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.Space then klik() end end))
	pol(RunService.RenderStepped:Connect(function(dt)
		wartosc = math.max(0, wartosc - dt * ile * 0.12)
		fill.Size = UDim2.fromScale(math.clamp(wartosc / ile, 0, 1), 1)
	end))
end

R.sekwencja = function(pole, p, koniec)
	local styl = p.styl or "kolby"
	local defs
	if styl == "nuty" then
		defs = { { "C", U.PAPER }, { "D", U.PAPER }, { "E", U.PAPER }, { "F", U.PAPER }, { "G", U.PAPER } }
	elseif styl == "strzalki" then
		defs = { { "←", U.YEL }, { "↑", Color3.fromRGB(140, 195, 240) }, { "→", Color3.fromRGB(150, 215, 170) }, { "↓", Color3.fromRGB(245, 160, 180) } }
	elseif styl == "przelaczniki" then
		defs = { { "1", U.PAPER2 }, { "2", U.PAPER2 }, { "3", U.PAPER2 }, { "4", U.PAPER2 } }
	else
		defs = { { "czerw.", Color3.fromRGB(230, 80, 80) }, { "nieb.", Color3.fromRGB(90, 140, 230) }, { "ziel.", Color3.fromRGB(90, 190, 110) }, { "żółty", U.YEL } }
	end
	local info = U.txt(pole, { Text = "Patrz uważnie...", Size = UDim2.fromScale(0.9, 0.13), Position = UDim2.fromScale(0.05, 0.0) })
	local seq = {}
	for i = 1, p.dl or 4 do seq[i] = math.random(#defs) end
	local przyciski = {}
	local n = #defs
	for i, d in ipairs(defs) do
		local w = 0.86 / n
		local b, f = U.przyciskTekst(pole, "B" .. i, d[1], UDim2.fromScale(0.07 + (i - 1) * w + 0.01, 0.3), UDim2.fromScale(w - 0.02, 0.5), d[2], U.INK)
		przyciski[i] = { b = b, f = f, kolor = d[2] }
	end
	local wejscie, krok = false, 1
	local function blysk(i)
		local x = przyciski[i]
		x.f.BackgroundColor3 = Color3.new(1, 1, 1)
		K.dzwiek("Pstryk", 0.4)
		task.wait(0.32)
		x.f.BackgroundColor3 = x.kolor
		task.wait(0.15)
	end
	local function pokaz()
		wejscie = false
		info.Text = "Patrz uważnie..."
		task.wait(0.6)
		for _, i in ipairs(seq) do
			if not otwarta then return end
			blysk(i)
		end
		info.Text = "Teraz ty! (" .. #seq .. ")"
		krok = 1
		wejscie = true
	end
	for i, x in ipairs(przyciski) do
		x.b.Activated:Connect(function()
			if not wejscie or not otwarta then return end
			task.spawn(blysk, i)
			if seq[krok] == i then
				krok += 1
				if krok > #seq then wejscie = false task.delay(0.4, function() koniec(true) end) end
			else
				zle(x.b)
				task.spawn(pokaz)
			end
		end)
	end
	task.spawn(pokaz)
end

R.wyczucie = function(pole, p, koniec)
	local ile = p.ile or 3
	U.txt(pole, { Text = p.tekst or "Zatrzymaj w zielonym", Size = UDim2.fromScale(0.9, 0.13), Position = UDim2.fromScale(0.05, 0.0) })
	local pasek = U.new("Frame", { BackgroundColor3 = U.PAPER2, BorderSizePixel = 0, Size = UDim2.fromScale(0.86, 0.16), Position = UDim2.fromScale(0.07, 0.25) }, pole)
	U.stroke(pasek, 2.5)
	local szer = 0.2
	local strefa = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(110, 200, 120), BorderSizePixel = 0, Size = UDim2.fromScale(szer, 1), Position = UDim2.fromScale(0.4, 0) }, pasek)
	local wsk = U.new("Frame", { BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.new(0, 6, 1.4, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), ZIndex = 3 }, pasek)
	U.stroke(wsk, 1.5)
	local licz = U.txt(pole, { Text = "0/" .. ile, Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.3, 0.1), Position = UDim2.fromScale(0.35, 0.45) })
	local b = U.przyciskTekst(pole, "Stop", "TERAZ!", UDim2.fromScale(0.5, 0.75), UDim2.fromScale(0.4, 0.22), U.YEL, U.INK, Vector2.new(0.5, 0.5))
	local t, traf, predk = 0, 0, 1.1
	local function sprobuj()
		local x = wsk.Position.X.Scale
		local a = strefa.Position.X.Scale
		if x >= a and x <= a + strefa.Size.X.Scale then
			traf += 1
			licz.Text = traf .. "/" .. ile
			K.dzwiek("Pstryk", 0.5)
			if traf >= ile then koniec(true) return end
			szer = math.max(0.1, szer - 0.03)
			predk += 0.25
			strefa.Size = UDim2.fromScale(szer, 1)
			strefa.Position = UDim2.fromScale(math.random(5, 95 - math.floor(szer * 100)) / 100, 0)
		else
			zle(pasek)
		end
	end
	b.Activated:Connect(sprobuj)
	pol(UserInputService.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.Space then sprobuj() end end))
	pol(RunService.RenderStepped:Connect(function(dt)
		t += dt * predk
		wsk.Position = UDim2.fromScale((math.sin(t * 2) + 1) / 2, 0.5)
	end))
end

R.pisz = function(pole, p, koniec)
	U.txt(pole, { Text = "Przepisz dokładnie:", TextColor3 = U.GREY, Size = UDim2.fromScale(0.9, 0.09), Position = UDim2.fromScale(0.05, 0.0) })
	U.txt(pole, { Text = "„" .. p.fraza .. "”", Font = Enum.Font.PermanentMarker, Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.1) })
	local h, f = U.karta(pole, "Pole", UDim2.fromScale(0.07, 0.34), UDim2.fromScale(0.86, 0.2), U.PAPER, nil, 0, 2)
	local box = U.new("TextBox", { BackgroundTransparency = 1, Text = "", PlaceholderText = "pisz tutaj...", PlaceholderColor3 = U.GREY, Font = Enum.Font.PatrickHand,
		TextScaled = true, TextColor3 = U.INK, ClearTextOnFocus = false, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1) }, f)
	local b = U.przyciskTekst(pole, "OK", "GOTOWE", UDim2.fromScale(0.5, 0.75), UDim2.fromScale(0.4, 0.2), U.GREEN, U.PAPER, Vector2.new(0.5, 0.5))
	local function sprawdz()
		if bezOgonkow(box.Text) == bezOgonkow(p.fraza) then koniec(true) else zle(h) end
	end
	b.Activated:Connect(sprawdz)
	box.FocusLost:Connect(function(enter) if enter then sprawdz() end end)
	task.defer(function() box:CaptureFocus() end)
end

R.kod = function(pole, p, koniec)
	local cyfr = p.cyfr or 4
	local kod = ""
	for _ = 1, cyfr do kod ..= tostring(math.random(0, 9)) end
	-- żółta karteczka z kodem
	local kh, kf = U.karta(pole, "Karteczka", UDim2.fromScale(0.62, 0.0), UDim2.fromScale(0.34, 0.3), U.YEL, nil, 4, 2)
	U.txt(kf, { Text = p.tekst or "Kod:", Size = UDim2.fromScale(0.9, 0.35), Position = UDim2.fromScale(0.05, 0.05) })
	U.txt(kf, { Text = kod, Font = Enum.Font.PermanentMarker, Size = UDim2.fromScale(0.9, 0.55), Position = UDim2.fromScale(0.05, 0.4) })
	local ekranH, ekran = U.karta(pole, "Ekran", UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.52, 0.2), Color3.fromRGB(30, 40, 35), nil, 0, 2)
	local wpis = U.txt(ekran, { Text = "", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(110, 230, 120), Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.05, 0.15) })
	local wpisane = ""
	local klaw = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK" }
	for i, k in ipairs(klaw) do
		local c = (i - 1) % 3
		local r = math.floor((i - 1) / 3)
		local b = U.przyciskTekst(pole, "K" .. k, k, UDim2.fromScale(0.08 + c * 0.17, 0.3 + r * 0.17), UDim2.fromScale(0.15, 0.15),
			k == "OK" and U.GREEN or (k == "C" and U.RED or U.PAPER), (k == "OK" or k == "C") and U.PAPER or U.INK)
		b.Activated:Connect(function()
			if k == "C" then wpisane = ""
			elseif k == "OK" then
				if wpisane == kod then koniec(true) return else zle(ekranH) wpisane = "" end
			elseif #wpisane < cyfr then wpisane ..= k end
			wpis.Text = wpisane
		end)
	end
end

------------------------------------------------------------------ OTWIERANIE
-- def = { nazwa, gdzie, typ, p }, opts = { mnoznik, pytania, jedenRaz, bezX }
function Mg.otworz(def, opts, cb)
	if otwarta then zamknijOkno(false) end
	otwarta = { cb = cb }
	K.stan.minigra = true
	local o, f, x = U.okno(K.gui, "Minigra", string.upper(def.nazwa), def.gdzie or "", { bezLinii = true, z = 30, rot = 0, bezX = opts and opts.bezX })
	okno = o
	o.ZIndex = 30
	if x then x.Activated:Connect(function() zamknijOkno(false) end) end
	local pole = U.new("Frame", { Name = "Pole", BackgroundTransparency = 1, Size = UDim2.fromScale(0.8, 0.66), Position = UDim2.fromScale(0.14, 0.29) }, f)
	local fn = R[def.typ] or R.trzymaj
	local skonczone = false
	local function koniec(ok)
		if skonczone then return end
		skonczone = true
		zamknijOkno(ok)
	end
	U.pokaz(o, true, 0)
	fn(pole, def.p or {}, koniec, opts)
	-- odejście za daleko zamyka minigrę
	local start = K.hrp() and K.hrp().Position
	pol(RunService.Heartbeat:Connect(function()
		local h = K.hrp()
		if start and h and (h.Position - start).Magnitude > 16 then koniec(false) end
	end))
end

function Mg.Init(k)
	K = k
	U = K.Styl
	C = K.C
	UserInputService.InputBegan:Connect(function(i, gp)
		if i.KeyCode == Enum.KeyCode.Escape and otwarta then zamknijOkno(false) end
	end)
end

return Mg
