-- HUD: pasek rundy, karteczki, legitymacja (level/XP/zł), nagrody, awans, przyciski akcji i sterowanie.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local H = {}
local K, U, C
local szablon, pasek, karteczka
local przyciski = {}
local cel = { eliminacja = nil, wezwij = nil }
local podswietlCel

------------------------------------------------------------------ PASEK RUNDY
local el = {}
local function znajdzElementyPaska()
	local f = pasek.Lico
	el.czas = f:FindFirstChild("Czas")
	for _, c in ipairs(f:GetChildren()) do
		local t = c:FindFirstChildOfClass("TextLabel")
		if c:IsA("Frame") and t and c:FindFirstChildOfClass("UIStroke") and t.Text:find("LEKCJA") then el.stamp = t end
		if c:IsA("TextLabel") and c.Text:match("^%d+/%d+$") then el.licznik = c end
		if c:IsA("TextLabel") and c.Text == "Zadania klasy" then el.opis = c end
		if c:IsA("Frame") and c:FindFirstChildOfClass("UIStroke") and c.Size.X.Scale > 0.4 then
			el.bar = c
			for _, x in ipairs(c:GetChildren()) do if x:IsA("Frame") and x.Size.X.Scale > 0.05 then el.fill = x end end
		end
	end
end
local function ustawPasek()
	if not pasek then return end
	local faza = K.Gra:GetAttribute("Faza") or "Lobby"
	if faza == "Lobby" then
		if el.stamp then el.stamp.Text = "PRZERWA" end
		local od = K.Gra:GetAttribute("Odliczanie")
		local brak = K.Gra:GetAttribute("Brakuje") or 0
		if el.czas then el.czas.Text = (od and od >= 0) and string.format("0:%02d", od) or "--:--" end
		H.ustawPostep(0, 0, brak > 0 and ("Czekamy na graczy (brakuje " .. brak .. ")") or "Zaraz autobus do szkoły!")
	else
		local s = K.Gra:GetAttribute("Czas") or 0
		if el.stamp then el.stamp.Text = faza == "Spotkanie" and "ZEBRANIE" or (faza == "Koniec" and "KONIEC" or "LEKCJA") end
		if el.czas then el.czas.Text = string.format("%02d:%02d", math.floor(s / 60), s % 60) end
	end
end
function H.ustawPostep(z, w, tekst)
	if el.licznik then el.licznik.Text = w > 0 and (z .. "/" .. w) or "" end
	if el.opis then el.opis.Text = tekst or "Zadania szkoły" end
	if el.fill then K.tween(el.fill, 0.4, { Size = UDim2.fromScale(w > 0 and z / w or 0, 1) }) end
end

------------------------------------------------------------------ KARTECZKA
local kolejka, pokazuje = {}, false
local function nastepna()
	if pokazuje or #kolejka == 0 or not karteczka then return end
	pokazuje = true
	local d = table.remove(kolejka, 1)
	local f = karteczka.Lico
	local lab = {}
	for _, c in ipairs(f:GetChildren()) do if c:IsA("TextLabel") then table.insert(lab, c) end end
	table.sort(lab, function(a, b) return a.Position.X.Scale < b.Position.X.Scale end)
	if lab[1] then lab[1].Text = string.upper(d.tytul or "UWAGA!") end
	if lab[2] then lab[2].Text = d.tekst or "" end
	f.BackgroundColor3 = d.kolor == "czerwony" and Color3.fromRGB(255, 150, 150) or (d.kolor == "zielony" and Color3.fromRGB(170, 230, 170) or U.YEL)
	karteczka.Visible = true
	karteczka.Position = UDim2.fromScale(0.5, -0.12)
	K.tween(karteczka, 0.35, { Position = UDim2.fromScale(0.5, 0.135) }, Enum.EasingStyle.Back)
	K.dzwiek("Pstryk", 0.3)
	task.delay(d.czas or 3.6, function()
		K.tween(karteczka, 0.25, { Position = UDim2.fromScale(0.5, -0.12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.3)
		karteczka.Visible = false
		pokazuje = false
		nastepna()
	end)
end
function H.karteczka(tytul, tekst, kolor, czas)
	table.insert(kolejka, { tytul = tytul, tekst = tekst, kolor = kolor, czas = czas })
	nastepna()
end

------------------------------------------------------------------ LEGITYMACJA (level, XP, zł)
local leg
local function zbudujLegitymacje()
	local h, f = U.karta(K.gui, "Legitymacja", UDim2.fromScale(0.012, 0.025), UDim2.fromScale(0.3, 0.095), U.PAPER, nil, 0)
	h.SizeConstraint = Enum.SizeConstraint.RelativeYY
	U.new("UIAspectRatioConstraint", { AspectRatio = 3.4 }, h)
	local kolo = U.new("Frame", { Name = "Level", BackgroundColor3 = U.RED, Size = UDim2.fromScale(0.27, 0.27), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		Position = UDim2.fromScale(0.04, 0.5), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 3 }, f)
	U.corner(kolo, UDim.new(1, 0))
	U.stroke(kolo, 2.5, U.INK, 0, true)
	local lvl = U.txt(kolo, { Name = "Nr", Text = "1", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.7, 0.62), Position = UDim2.fromScale(0.15, 0.19), ZIndex = 4 })
	U.obrysTekstu(lvl, 1.5)
	local tyt = U.txt(f, { Name = "Tytul", Text = "Pierwszak", Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.62, 0.3), Position = UDim2.fromScale(0.35, 0.08), TextXAlignment = Enum.TextXAlignment.Left })
	local bar = U.new("Frame", { Name = "XP", BackgroundColor3 = U.PAPER2, BorderSizePixel = 0, Size = UDim2.fromScale(0.6, 0.18), Position = UDim2.fromScale(0.35, 0.44) }, f)
	U.stroke(bar, 1.5)
	local fill = U.new("Frame", { Name = "Fill", BackgroundColor3 = U.BLUE, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, bar)
	local xpT = U.txt(bar, { Name = "T", Text = "", Size = UDim2.fromScale(1, 1.2), Position = UDim2.fromScale(0, -0.1), ZIndex = 3 })
	local zl = U.txt(f, { Name = "Zl", Text = "50 zł", Font = Enum.Font.Bangers, TextColor3 = U.GREEN, Size = UDim2.fromScale(0.4, 0.28), Position = UDim2.fromScale(0.35, 0.66), TextXAlignment = Enum.TextXAlignment.Left })
	leg = { h = h, lvl = lvl, tyt = tyt, fill = fill, xpT = xpT, zl = zl }
end
local function odswiezProfil(d)
	if not leg or not d or not d.d then return end
	local p = d.d
	leg.lvl.Text = tostring(p.lvl)
	leg.tyt.Text = d.tytul or ""
	leg.xpT.Text = p.xp .. " / " .. d.xpDo .. " XP"
	K.tween(leg.fill, 0.4, { Size = UDim2.fromScale(math.clamp(p.xp / d.xpDo, 0, 1), 1) })
	leg.zl.Text = p.zl .. " zł"
end

------------------------------------------------------------------ NAGRODY I AWANS
local function wyskakujace(tekst, kolor)
	local t = U.txt(K.gui, { Text = tekst, Font = Enum.Font.Bangers, TextColor3 = kolor or U.YEL, Size = UDim2.fromScale(0.3, 0.05),
		Position = UDim2.fromScale(0.5, 0.78), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 40 })
	U.obrysTekstu(t, 2.5)
	local sc = U.new("UIScale", { Scale = 0.4 }, t)
	K.tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	K.tween(t, 1.6, { Position = UDim2.fromScale(0.5, 0.66) })
	task.delay(1.2, function() K.tween(t, 0.4, { TextTransparency = 1 }) end)
	task.delay(1.7, function() t:Destroy() end)
end
local function awans(d)
	K.dzwiek("Level", 0.7)
	local h, f = U.karta(K.nad, "Awans", UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.42, 0.2), U.YEL, Vector2.new(0.5, 0.5), -3)
	h.SizeConstraint = Enum.SizeConstraint.RelativeYY
	U.new("UIAspectRatioConstraint", { AspectRatio = 2.6 }, h)
	U.txt(f, { Text = "LEVEL " .. d.lvl .. "!", Font = Enum.Font.Bangers, TextColor3 = U.RED, Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.05, 0.05) })
	U.txt(f, { Text = d.tytul .. "   +" .. d.bonus .. " zł", Font = Enum.Font.PatrickHand, Size = UDim2.fromScale(0.9, 0.3), Position = UDim2.fromScale(0.05, 0.6) })
	local sc = U.new("UIScale", { Scale = 2.5 }, h)
	K.tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	-- konfetti
	for i = 1, 40 do
		local c = U.new("Frame", { BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0.01, 0.02),
			Position = UDim2.fromScale(0.5, 0.42), Rotation = math.random(0, 360), ZIndex = 60 }, K.nad)
		K.tween(c, 1.4, { Position = UDim2.fromScale(math.random(5, 95) / 100, math.random(60, 110) / 100), Rotation = math.random(-720, 720) }, Enum.EasingStyle.Quad)
		task.delay(1.5, function() c:Destroy() end)
	end
	task.delay(2.6, function()
		K.tween(sc, 0.2, { Scale = 0 })
		task.wait(0.25)
		h:Destroy()
	end)
end

------------------------------------------------------------------ PRZYCISKI AKCJI
local DEF_PRZYCISKOW = {
	{ id = "zglos", tekst = "ZGŁOŚ", klawisz = "R", kolor = Color3.fromRGB(240, 120, 40) },
	{ id = "zabij", tekst = "ELIMINUJ", klawisz = "Q", kolor = U and U.RED or Color3.fromRGB(214, 40, 57) },
	{ id = "nies", tekst = "NIEŚ", klawisz = "G", kolor = Color3.fromRGB(150, 90, 200) },
	{ id = "kratka", tekst = "KRATKA", klawisz = "V", kolor = Color3.fromRGB(110, 110, 120) },
	{ id = "wezwij", tekst = "DO GABINETU", klawisz = "B", kolor = Color3.fromRGB(230, 160, 30) },
	{ id = "schowaj", tekst = "SCHOWAJ SIĘ", klawisz = "C", kolor = Color3.fromRGB(90, 140, 200) },
	{ id = "hulajnoga", tekst = "HULAJNOGA", klawisz = "X", kolor = Color3.fromRGB(46, 140, 90) },
	{ id = "rzuc", tekst = "RZUĆ", klawisz = "LPM", kolor = Color3.fromRGB(240, 200, 60) },
}
local pasekAkcji
local function zbudujPrzyciski()
	pasekAkcji = U.new("Frame", { Name = "Akcje", BackgroundTransparency = 1, Size = UDim2.fromScale(0.7, 0.12), Position = UDim2.fromScale(0.5, 0.965), AnchorPoint = Vector2.new(0.5, 1) }, K.gui)
	U.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.012, 0), VerticalAlignment = Enum.VerticalAlignment.Bottom }, pasekAkcji)
	for i, d in ipairs(DEF_PRZYCISKOW) do
		local b, f = U.naklejka(pasekAkcji, d.id, UDim2.new(), UDim2.fromScale(1, 1), d.kolor)
		b.SizeConstraint = Enum.SizeConstraint.RelativeYY
		b.LayoutOrder = i
		b.Visible = false
		local t = U.txt(f, { Name = "Tekst", Text = d.tekst, Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.9, 0.38), Position = UDim2.fromScale(0.05, 0.3), ZIndex = 10 })
		U.obrysTekstu(t, 1.5)
		local kl = U.new("Frame", { Name = "Klawisz", BackgroundColor3 = U.PAPER, Size = UDim2.fromScale(0.34, 0.24), Position = UDim2.fromScale(0.62, -0.08), ZIndex = 12 }, b)
		U.corner(kl, UDim.new(0, 3))
		U.stroke(kl, 1.5)
		U.txt(kl, { Text = d.klawisz, Font = Enum.Font.GothamBold, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), ZIndex = 13 })
		local cd = U.new("Frame", { Name = "CD", BackgroundColor3 = U.INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1), ZIndex = 11 }, f)
		U.txt(cd, { Name = "T", Text = "", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(1, 0), ZIndex = 12 })
		local cdT = U.txt(f, { Name = "CDT", Text = "", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.8, 0.5), Position = UDim2.fromScale(0.1, 0.25), ZIndex = 12 })
		U.obrysTekstu(cdT, 2)
		przyciski[d.id] = { b = b, f = f, cd = cd, cdT = cdT, def = d }
		b.Activated:Connect(function() H.akcja(d.id) end)
	end
end

local function najblizszyGracz(zasieg, filtr)
	local h = K.hrp()
	if not h then return nil end
	local best, bd = nil, zasieg
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= K.gracz and p.Character and not p.Character:GetAttribute("Duch") then
			local ph = p.Character:FindFirstChild("HumanoidRootPart")
			if ph and (not filtr or filtr(p)) then
				local d = (ph.Position - h.Position).Magnitude
				if d < bd and ph.Transparency < 1 then best, bd = p, d end
			end
		end
	end
	return best
end
local function najblizszeCialo(zasieg)
	local h = K.hrp()
	if not h then return nil end
	for _, c in ipairs(CollectionService:GetTagged("Cialo")) do
		if c.Parent and (c:GetPivot().Position - h.Position).Magnitude <= zasieg then return c end
	end
end
local kratkiPoz
local function blisko_kratki()
	local h = K.hrp()
	if not h then return false end
	if not kratkiPoz then
		local ok, w = pcall(function() return K.Pytaj:InvokeServer("kratki") end)
		kratkiPoz = ok and w or {}
	end
	for _, k in ipairs(kratkiPoz) do
		if (k.pos - h.Position).Magnitude < 8 then return true end
	end
	return false
end
local function blisko_kryjowki()
	local h = K.hrp()
	if not h then return false end
	for _, o in ipairs(CollectionService:GetTagged("SzkolaKryjowka")) do
		local pos = o:IsA("Model") and o:GetPivot().Position or (o:IsA("BasePart") and o.Position)
		if pos and (pos - h.Position).Magnitude < 7 then return true end
	end
	return false
end

local wspolnicyId = {}
function H.ustawWspolnikow(lista)
	wspolnicyId = {}
	for _, n in ipairs(lista or {}) do wspolnicyId[n] = true end
end

function H.akcja(id)
	local s = K.stan
	if s.minigra then return end
	if id == "zglos" then K.wyslij("zglos")
	elseif id == "zabij" and cel.eliminacja then K.wyslij("zabij", { cel = cel.eliminacja })
	elseif id == "nies" then K.wyslij("nies")
	elseif id == "kratka" then
		if s.wKratce then K.wyslij("kratka", { akcja = "wyjdz" }) else K.wyslij("kratka", { akcja = "wejdz" }) end
	elseif id == "wezwij" and cel.wezwij then K.wyslij("wezwij", { cel = cel.wezwij })
	elseif id == "schowaj" then K.wyslij("kryjowka", { w = not s.wKryjowce })
	elseif id == "hulajnoga" then K.wyslij("hulajnoga", { w = not K.gracz:GetAttribute("NaHulajnodze") })
	elseif id == "rzuc" and s.trzyma then
		local cam = workspace.CurrentCamera
		K.wyslij("rzuc", { kierunek = cam.CFrame.LookVector })
	end
end

local function odswiezPrzyciski()
	local s = K.stan
	local faza = K.Gra:GetAttribute("Faza") or "Lobby"
	local gra = faza == "Gra" and s.rola ~= nil
	local zly = K.jestZly()
	local widoczne = {}
	if gra and s.zyje then
		widoczne.zglos = najblizszeCialo(K.C.Czasy.ZasiegZgloszenia) ~= nil and not s.niesie
		if zly then
			cel.eliminacja = (not s.niesie and not s.wKratce) and najblizszyGracz(K.C.Czasy.ZasiegEliminacji, function(p) return not wspolnicyId[p.DisplayName] end) or nil
			widoczne.zabij = true
			widoczne.nies = s.niesie or najblizszeCialo(7) ~= nil
			widoczne.kratka = s.wKratce or blisko_kratki()
		end
		if s.rola == "Dyrektor" and s.dyrektorMoc then
			cel.wezwij = najblizszyGracz(12)
			widoczne.wezwij = true
		end
		widoczne.schowaj = s.wKryjowce or blisko_kryjowki()
	else
		cel.eliminacja = nil
		cel.wezwij = nil
	end
	widoczne.hulajnoga = (faza == "Lobby" or faza == "Gra" or faza == "Koniec") and not s.wKratce and not s.niesie and (s.zyje or faza ~= "Gra")
	widoczne.rzuc = s.trzyma ~= nil
	for id, x in pairs(przyciski) do
		x.b.Visible = widoczne[id] == true
	end
	-- teksty i cooldowny
	local p = przyciski
	if p.nies then p.nies.f.Tekst.Text = s.niesie and "UPUŚĆ" or "NIEŚ" end
	if p.kratka then p.kratka.f.Tekst.Text = s.wKratce and "WYJDŹ" or "KRATKA" end
	if p.schowaj then p.schowaj.f.Tekst.Text = s.wKryjowce and "WYJDŹ" or "SCHOWAJ SIĘ" end
	if p.hulajnoga then p.hulajnoga.f.Tekst.Text = K.gracz:GetAttribute("NaHulajnodze") and "ZSIĄDŹ" or "HULAJNOGA" end
	local teraz = K.czasSerwera()
	local cdE = s.cooldown.eliminacja or 0
	if p.zabij then
		local zostalo = cdE - teraz
		if zostalo > 0 then
			p.zabij.cd.Size = UDim2.fromScale(1, math.clamp(zostalo / K.C.Czasy.CooldownEliminacji, 0, 1))
			p.zabij.cdT.Text = tostring(math.ceil(zostalo))
		else
			p.zabij.cd.Size = UDim2.fromScale(1, 0)
			p.zabij.cdT.Text = ""
		end
		p.zabij.f.BackgroundTransparency = (cel.eliminacja and zostalo <= 0) and 0 or 0.55
	end
	if p.wezwij then p.wezwij.f.BackgroundTransparency = cel.wezwij and 0 or 0.55 end
	-- czerwona obwódka na celu eliminacji
	local c = cel.eliminacja and cel.eliminacja.Character
	if podswietlCel.Adornee ~= c then podswietlCel.Adornee = c end
	podswietlCel.Enabled = c ~= nil and (cdE - teraz) <= 0
end

local KLAWISZE = { [Enum.KeyCode.R] = "zglos", [Enum.KeyCode.Q] = "zabij", [Enum.KeyCode.G] = "nies", [Enum.KeyCode.V] = "kratka",
	[Enum.KeyCode.B] = "wezwij", [Enum.KeyCode.C] = "schowaj", [Enum.KeyCode.X] = "hulajnoga" }

function H.Init(k)
	K = k
	U = K.Styl
	C = K.C
	szablon = K.PlayerGui:WaitForChild("SzablonUI")
	pasek = szablon:WaitForChild("PasekRundy")
	karteczka = szablon:WaitForChild("Karteczka")
	karteczka.Visible = false
	znajdzElementyPaska()
	zbudujLegitymacje()
	zbudujPrzyciski()
	podswietlCel = U.new("Highlight", { Name = "CelEliminacji", FillTransparency = 1, OutlineColor = U.RED, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.Occluded, Enabled = false }, K.gui)

	for _, a in ipairs({ "Faza", "Odliczanie", "Brakuje", "Czas" }) do
		K.Gra:GetAttributeChangedSignal(a):Connect(ustawPasek)
	end
	ustawPasek()
	K.na("Postep", function(d) H.ustawPostep(d.z, d.w, "Zadania szkoły") end)
	K.na("Karteczka", function(d) H.karteczka(d.tytul, d.tekst, d.kolor) end)
	K.na("Profil", function(d) K.stan.profil = d.d odswiezProfil(d) end)
	K.na("Nagroda", function(d)
		local t = {}
		if d.zl and d.zl > 0 then table.insert(t, "+" .. d.zl .. " zł") end
		if d.xp and d.xp > 0 then table.insert(t, "+" .. d.xp .. " XP") end
		if #t > 0 then
			wyskakujace(table.concat(t, "   "), U.YEL)
			K.dzwiek("Moneta", 0.4)
		end
	end)
	K.na("Awans", awans)
	K.na("Cooldown", function(d) K.stan.cooldown[d.klucz] = d.do_ end)
	K.na("Niesie", function(d) K.stan.niesie = d.niesie end)
	K.na("Trzyma", function(d) K.stan.trzyma = d.obiekt end)
	K.na("Kryjowka", function(d) K.stan.wKryjowce = d.w end)
	K.na("DyrektorMoc", function(d) K.stan.dyrektorMoc = d.ma end)
	K.na("Czat", function(d) H.karteczka("Szkoła", d.tekst, "zielony", 2.5) end)

	UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		local id = KLAWISZE[i.KeyCode]
		if id and przyciski[id] and przyciski[id].b.Visible then H.akcja(id) end
		if i.UserInputType == Enum.UserInputType.MouseButton1 and K.stan.trzyma then H.akcja("rzuc") end
	end)
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t < 0.1 then return end
		t = 0
		odswiezPrzyciski()
	end)
	K.gracz.CharacterAdded:Connect(function()
		K.stan.niesie = false
		K.stan.trzyma = nil
		K.stan.wKryjowce = false
	end)
end

return H
