-- Zebranie w stołówce: cutscenka dzwonu / zgłoszenia, tablica korkowa z głosowaniem, wynik i wyrzucenie.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local S = {}
local K, U, C, Mg
local tablica, karty = nil, {}
local doKonca, fazaZebrania = 0, nil
local mojGlos = nil
local zegarT, fazaT

local function zablokujSterowanie(tak)
	local ok, pm = pcall(function() return require(K.gracz.PlayerScripts:WaitForChild("PlayerModule")) end)
	if ok and pm then
		local c = pm:GetControls()
		if tak then c:Disable() else c:Enable() end
	end
end

------------------------------------------------------------------ CUTSCENKA STARTU
local function cutscenka(d)
	Mg.zamknij()
	local cam = workspace.CurrentCamera
	local stary = cam.CameraType
	local f = U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, K.nad)
	-- pasy kinowe
	local g1 = U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), ZIndex = 71 }, f)
	local g2 = U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), ZIndex = 71 }, f)
	K.tween(g1, 0.3, { Size = UDim2.fromScale(1, 0.12) })
	K.tween(g2, 0.3, { Size = UDim2.fromScale(1, 0.12) })
	local napis
	if d.powod == "dzwon" and d.dzwon then
		cam.CameraType = Enum.CameraType.Scriptable
		local cel = d.dzwon
		local start = os.clock()
		local con = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			local drz = K.stan.ustawienia.drzenie and 0.25 or 0.08
			cam.CFrame = CFrame.lookAt(cel + Vector3.new(6 - t * 0.8, 2 + t * 0.3, 6), cel) * CFrame.Angles(math.sin(t * 40) * drz * 0.1, math.cos(t * 37) * drz * 0.1, 0)
		end)
		napis = U.txt(f, { Text = "DRYŃŃŃ! ZEBRANIE!", Font = Enum.Font.Bangers, TextColor3 = U.YEL, Size = UDim2.fromScale(0.8, 0.13), Position = UDim2.fromScale(0.1, 0.7), ZIndex = 72 })
		U.txt(f, { Text = (d.kto or "?") .. " zadzwonił dzwonem w stołówce", Font = Enum.Font.PatrickHand, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.6, 0.05), Position = UDim2.fromScale(0.2, 0.84), ZIndex = 72 })
		task.wait(2.8)
		con:Disconnect()
	else
		local tlo = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(120, 10, 20), BackgroundTransparency = 0.15, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, f)
		napis = U.txt(f, { Text = "ZNALEZIONO CIAŁO!", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.8, 0.16), Position = UDim2.fromScale(0.1, 0.36), ZIndex = 72 })
		U.txt(f, { Text = (d.kto or "?") .. " znalazł: " .. (d.ofiara or "?"), Font = Enum.Font.PatrickHand, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.6, 0.06), Position = UDim2.fromScale(0.2, 0.54), ZIndex = 72 })
		local sc = U.new("UIScale", { Scale = 3 }, napis)
		K.tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		task.wait(2.8)
	end
	U.obrysTekstu(napis, 3)
	cam.CameraType = Enum.CameraType.Custom
	f:Destroy()
end

------------------------------------------------------------------ TABLICA KORKOWA
local function zbudujTablice(d)
	if tablica then tablica:Destroy() end
	karty = {}
	mojGlos = nil
	local h, f = U.karta(K.gui, "Zebranie", UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.86, 0.8), U.CORK, Vector2.new(0.5, 0.5), 0, 5)
	h.SizeConstraint = Enum.SizeConstraint.RelativeYY
	U.new("UIAspectRatioConstraint", { AspectRatio = 1.45 }, h)
	h.ZIndex = 40
	tablica = h
	-- rama tablicy
	local rama = f:FindFirstChildOfClass("UIStroke")
	if rama then rama.Color = Color3.fromRGB(110, 70, 35) rama:SetAttribute("Baza", 8) end
	-- tytuł na kartce
	local th, tf = U.karta(f, "Naglowek", UDim2.fromScale(0.5, 0.02), UDim2.fromScale(0.5, 0.11), U.PAPER, Vector2.new(0.5, 0), -1.5, 2)
	U.txt(tf, { Text = d.powod == "dzwon" and "ZEBRANIE KLASOWE" or "ZEBRANIE: ZNALEZIONO CIAŁO", Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.9, 0.6), Position = UDim2.fromScale(0.05, 0.05) })
	fazaT = U.txt(tf, { Text = "", Font = Enum.Font.PatrickHand, TextColor3 = U.RED, Size = UDim2.fromScale(0.9, 0.35), Position = UDim2.fromScale(0.05, 0.62) })
	U.tasma(th, UDim2.fromScale(0.5, -0.05), UDim2.fromScale(0.3, 0.3), 3)
	-- zegar
	local zh, zf = U.karta(f, "Zegar", UDim2.fromScale(0.86, 0.03), UDim2.fromScale(0.11, 0.1), U.YEL, nil, 4, 2)
	zegarT = U.txt(zf, { Text = "", Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	-- karty graczy
	local n = #d.gracze
	local kol = n <= 6 and 3 or 4
	for i, g in ipairs(d.gracze) do
		local c = (i - 1) % kol
		local r = math.floor((i - 1) / kol)
		local w = 0.86 / kol
		local kh, kf = U.naklejka(f, "Karta_" .. g.id, UDim2.fromScale(0.07 + c * w, 0.17 + r * 0.17), UDim2.fromScale(w - 0.025, 0.15), g.zyje and U.PAPER or Color3.fromRGB(170, 165, 160), nil, ((i * 37) % 7 - 3) * 0.6)
		-- pinezka
		local pin = U.new("Frame", { BackgroundColor3 = U.RED, Size = UDim2.fromScale(0.08, 0.08), SizeConstraint = Enum.SizeConstraint.RelativeXX, Position = UDim2.fromScale(0.46, -0.06), ZIndex = 12 }, kh)
		U.corner(pin, UDim.new(1, 0))
		U.stroke(pin, 1.5, U.INK, 0, true)
		local foto = U.new("ImageLabel", { BackgroundColor3 = U.PAPER2, Size = UDim2.fromScale(0.26, 0.8), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.04, 0.1),
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. g.id .. "&w=150&h=150", ZIndex = 10 }, kf)
		U.stroke(foto, 1.5)
		U.txt(kf, { Text = g.nick, Size = UDim2.fromScale(0.62, 0.45), Position = UDim2.fromScale(0.34, 0.08), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10 })
		local status = U.txt(kf, { Name = "Status", Text = g.zyje and "" or "duch", TextColor3 = U.RED, Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.62, 0.35),
			Position = UDim2.fromScale(0.34, 0.55), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10 })
		local glosy = U.new("Frame", { Name = "Glosy", BackgroundTransparency = 1, Size = UDim2.fromScale(0.6, 0.3), Position = UDim2.fromScale(0.34, 0.62), ZIndex = 11 }, kf)
		U.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0) }, glosy)
		if not g.zyje then
			-- przekreślenie
			U.new("Frame", { BackgroundColor3 = U.RED, BorderSizePixel = 0, Size = UDim2.fromScale(1.05, 0.06), Position = UDim2.fromScale(-0.02, 0.47), Rotation = -12, ZIndex = 13 }, kf)
		end
		karty[g.id] = { b = kh, f = kf, status = status, glosy = glosy, gracz = g.gracz, zyje = g.zyje }
		kh.Activated:Connect(function()
			if fazaZebrania ~= "glosowanie" or mojGlos or not K.stan.zyje or not g.zyje then return end
			S.potwierdz(g)
		end)
	end
	-- pomiń
	local skip = U.przyciskTekst(f, "Pomin", "POMIŃ GŁOS", UDim2.fromScale(0.07, 0.88), UDim2.fromScale(0.22, 0.08), U.PAPER2, U.INK)
	skip.Activated:Connect(function()
		if fazaZebrania ~= "glosowanie" or mojGlos or not K.stan.zyje then return end
		mojGlos = "pomin"
		K.wyslij("glos", { cel = "pomin" })
	end)
	U.txt(f, { Name = "Info", Text = K.stan.zyje and "Rozmawiajcie na czacie! Kto jest sus?" or "Jesteś duchem – możesz tylko patrzeć.", Font = Enum.Font.PatrickHand,
		TextColor3 = U.PAPER, Size = UDim2.fromScale(0.6, 0.06), Position = UDim2.fromScale(0.33, 0.89), TextXAlignment = Enum.TextXAlignment.Left })
	U.pokaz(h, true, 0)
end

local potwierdzenie
function S.potwierdz(g)
	if potwierdzenie then potwierdzenie:Destroy() end
	local k = karty[g.id]
	if not k then return end
	local tak = U.przyciskTekst(k.b, "Tak", "GŁOSUJ ✓", UDim2.fromScale(0.5, 1.05), UDim2.fromScale(0.7, 0.45), U.GREEN, U.PAPER, Vector2.new(0.5, 0))
	tak.ZIndex = 30
	potwierdzenie = tak
	tak.Activated:Connect(function()
		if mojGlos then return end
		mojGlos = g.id
		K.wyslij("glos", { cel = g.gracz })
		tak:Destroy()
		potwierdzenie = nil
	end)
	task.delay(3, function() if potwierdzenie == tak then tak:Destroy() potwierdzenie = nil end end)
end

------------------------------------------------------------------ WYNIK
local function wynik(d)
	fazaZebrania = nil
	if fazaT then fazaT.Text = "Wyniki głosowania" end
	-- naklejki głosów
	for _, g in ipairs(d.glosy) do
		local k = (g.na ~= "pomin") and karty[g.na]
		local cel = k and k.glosy
		if cel then
			local im = U.new("ImageLabel", { BackgroundColor3 = U.PAPER2, Size = UDim2.fromScale(0.8, 0.8), SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. g.od .. "&w=48&h=48", ZIndex = 12 }, cel)
			U.corner(im, UDim.new(1, 0))
			local sc = U.new("UIScale", { Scale = 0 }, im)
			K.tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			K.dzwiek("Pstryk", 0.3)
			task.wait(0.15)
		end
	end
	task.wait(1.6)
	-- ekran wyrzucenia
	local f = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 12, 25), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 90 }, K.nad)
	K.tween(f, 0.5, { BackgroundTransparency = 0 })
	task.wait(0.5)
	local tekst
	if d.wyrzucony then
		tekst = d.wyrzucony .. " został wyrzucony ze szkoły."
	elseif d.remis then
		tekst = "Remis. Nikt nie został wyrzucony."
	else
		tekst = "Nikt nie został wyrzucony. (pominięto)"
	end
	local t1 = U.txt(f, { Text = "", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.86, 0.1), Position = UDim2.fromScale(0.07, 0.38), ZIndex = 91 })
	for i = 1, utf8.len(tekst) do
		t1.Text = string.sub(tekst, 1, utf8.offset(tekst, i + 1) - 1)
		if i % 2 == 0 then K.dzwiek("Pstryk", 0.15) end
		task.wait(0.035)
	end
	if d.wyrzucony then
		task.wait(0.4)
		local t2 = U.txt(f, { Text = d.byl and (d.wyrzucony .. " BYŁ Rozrabiaką!") or (d.wyrzucony .. " NIE był Rozrabiaką..."), Font = Enum.Font.Bangers,
			TextColor3 = d.byl and U.GREEN or U.RED, Size = UDim2.fromScale(0.7, 0.08), Position = UDim2.fromScale(0.15, 0.5), ZIndex = 91 })
		K.dzwiek(d.byl and "Wygrana" or "Smutny", 0.5)
	end
	U.txt(f, { Text = "Zostało Rozrabiaków: " .. tostring(d.zostaloZlych), Font = Enum.Font.PatrickHand, TextColor3 = U.GREY, Size = UDim2.fromScale(0.5, 0.05), Position = UDim2.fromScale(0.25, 0.6), ZIndex = 91 })
	task.wait(3)
	K.tween(f, 0.5, { BackgroundTransparency = 1 })
	for _, x in ipairs(f:GetChildren()) do if x:IsA("TextLabel") then K.tween(x, 0.5, { TextTransparency = 1 }) end end
	task.wait(0.6)
	f:Destroy()
end

function S.Init(k, moduly)
	K = k
	U = K.Styl
	C = K.C
	Mg = moduly.Minigry
	K.na("SpotkanieStart", function(d)
		zablokujSterowanie(true)
		cutscenka(d)
	end)
	K.na("Zebranie", function(d)
		fazaZebrania = d.faza
		doKonca = d.do_
		if d.faza == "dyskusja" or not tablica then zbudujTablice(d) end
		if fazaT then fazaT.Text = d.faza == "dyskusja" and "Dyskusja – głosowanie za chwilę" or "GŁOSOWANIE! Kliknij kartkę gracza" end
		if d.faza == "glosowanie" then K.dzwiek("Gwizdek", 0.4) end
	end)
	K.na("Zaglosowal", function(d)
		local k2 = karty[d.id]
		if k2 then k2.status.Text = "zagłosował ✓" k2.status.TextColor3 = U.GREEN end
	end)
	K.na("WynikGlosowania", wynik)
	K.na("SpotkanieKoniec", function()
		zablokujSterowanie(false)
		if tablica then
			local t = tablica
			tablica = nil
			U.pokaz(t, false)
			task.delay(0.3, function() t:Destroy() end)
		end
	end)
	K.na("Faza", function(d)
		if d.faza ~= "Spotkanie" and tablica and K.Gra:GetAttribute("Faza") ~= "Spotkanie" then
			-- awaryjnie
		end
	end)
	RunService.Heartbeat:Connect(function()
		if zegarT and tablica then
			zegarT.Text = tostring(math.max(0, math.ceil(doKonca - K.czasSerwera())))
		end
	end)
end

return S
