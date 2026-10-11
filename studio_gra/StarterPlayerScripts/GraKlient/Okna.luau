-- Podpięcie okien z szablonu (SzablonUI) do prawdziwych danych: rola, ustawienia, sklepik + ulepszenia,
-- plecak, memy, ranking, hulajnoga, ogłoszenia, sabotaż.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local O = {}
local K, U, C
local sz, hud, hudGui

local function okno(n) return sz:FindFirstChild("Okno_" .. n) end
local function profil() return K.stan.profil end

------------------------------------------------------------------ MOJA ROLA
local function odswiezRole()
	local o = okno("MojaRola")
	if not o then return end
	local leg = o.Lico:FindFirstChild("Legitymacja")
	local def = K.rolaDef()
	if leg then
		local st = leg.Lico:FindFirstChild("Pieczatka")
		if st then
			st.Rola.Text = def and string.upper(def.nazwa) or "BRAK"
			st.Rola.TextColor3 = def and def.kolor or U.GREY
			local s = st:FindFirstChildOfClass("UIStroke")
			if s then s.Color = def and def.kolor or U.GREY end
		end
		local p = profil()
		if leg.Lico:FindFirstChild("Klasa") and p then leg.Lico.Klasa.Text = "lvl " .. p.lvl end
		-- VIP: złota legitymacja
		local vip = K.gracz:GetAttribute("GP_VIP") == true
		if leg:GetAttribute("BazaKolor") == nil then
			leg:SetAttribute("BazaKolor", leg.Lico.BackgroundColor3)
			local pas = leg.Lico:FindFirstChild("Pasek")
			if pas then leg:SetAttribute("BazaPasek", pas.BackgroundColor3) end
		end
		leg.Lico.BackgroundColor3 = vip and Color3.fromRGB(255, 214, 90) or leg:GetAttribute("BazaKolor")
		local pas = leg.Lico:FindFirstChild("Pasek")
		if pas then pas.BackgroundColor3 = vip and Color3.fromRGB(200, 140, 20) or (leg:GetAttribute("BazaPasek") or pas.BackgroundColor3) end
		for _, t in ipairs(leg.Lico:GetChildren()) do
			if t:IsA("TextLabel") and (t.Text == "LEGITYMACJA SZKOLNA" or t.Text == "★ LEGITYMACJA VIP ★") then
				t.Text = vip and "★ LEGITYMACJA VIP ★" or "LEGITYMACJA SZKOLNA"
			end
		end
	end
	local cel = o.Lico:FindFirstChild("Cel")
	if cel then
		cel.Text = def and def.opis or "Jesteś w lobby. Rola zostanie wylosowana, gdy autobus dowiezie cię do szkoły."
	end
end

------------------------------------------------------------------ USTAWIENIA
local muzykaLobby
local function zastosujUstawienia()
	local u = K.stan.ustawienia
	K.grupaSfx.Volume = u.dzwieki * 2
	if muzykaLobby then muzykaLobby.Volume = u.muzyka * 0.35 end
	workspace.CurrentCamera.FieldOfView = 60 + u.fov
	Lighting.GlobalShadows = not u.slaby
end
local function podepnijUstawienia()
	local o = okno("Ustawienia")
	if not o then return end
	local mapaS = { ["Suwak_Muzyka"] = "muzyka", ["Suwak_Dźwięki"] = "dzwieki", ["Suwak_Czułość kamery"] = "fovS" }
	local mapaP = { ["Przelacznik_Podpowiedzi przy zadaniach"] = "podpowiedzi", ["Przelacznik_Drżenie kamery"] = "drzenie", ["Przelacznik_Tryb słabego komputera"] = "slaby" }
	for nazwa, klucz in pairs(mapaS) do
		local s = o.Lico:FindFirstChild(nazwa)
		if s then
			local function upd()
				local v = s:GetAttribute("Wartosc") or 0.5
				if klucz == "fovS" then K.stan.ustawienia.fov = v * 30 else K.stan.ustawienia[klucz] = v end
				zastosujUstawienia()
			end
			s:GetAttributeChangedSignal("Wartosc"):Connect(upd)
			upd()
		end
	end
	for nazwa, klucz in pairs(mapaP) do
		local b = o.Lico:FindFirstChild(nazwa)
		if b then
			local function upd()
				K.stan.ustawienia[klucz] = b:GetAttribute("Wlaczone") == true
				zastosujUstawienia()
			end
			b:GetAttributeChangedSignal("Wlaczone"):Connect(upd)
			upd()
		end
	end
end

------------------------------------------------------------------ SKLEPIK + ULEPSZENIA + ROBUX
local tryb = "sklepik" -- "sklepik" | "ulepszenia" | "robux"
local kartyUlepszen = {}
local kartyRobux = {}
local przyciskiTrybu = {}
local function maPass(klucz) return K.gracz:GetAttribute("GP_" .. klucz) == true end
local KOLEJNOSC_ROBUX = {
	{ "VIP", true }, { "Memy", true }, { "Tance", true }, { "Efekty", true }, { "HulajnogaTurbo", true }, { "HulajnogaRakieta", true },
	{ "Zl100" }, { "Zl500" }, { "Zl1500" }, { "Bilet" },
}
local function odswiezSklepik()
	local o = okno("Sklepik")
	if not o then return end
	local f = o.Lico
	local p = profil()
	local kw = f:FindFirstChild("Kieszonkowe")
	if kw and p then kw.Lico.Kwota.Text = p.zl .. " zł" end
	for i = 1, 6 do
		local pr = f:FindFirstChild("Produkt_" .. i)
		if pr then pr.Visible = tryb == "sklepik" end
	end
	for _, k in ipairs(kartyUlepszen) do k.h.Visible = tryb == "ulepszenia" end
	for _, k in ipairs(kartyRobux) do k.h.Visible = tryb == "robux" end
	for t, b in pairs(przyciskiTrybu) do
		b.bf.BackgroundColor3 = t == tryb and U.YEL or b.kolor
	end
	if tryb == "ulepszenia" and p then
		for _, k in ipairs(kartyUlepszen) do
			local u = C.Ulepszenia[k.id]
			local poz = p.ulepszenia[k.id] or 0
			k.poz.Text = "poziom " .. poz .. "/" .. #u.ceny
			k.cena.Text = poz >= #u.ceny and "MAX" or (u.ceny[poz + 1] .. " zł")
			for j, kr in ipairs(k.kropki) do kr.BackgroundColor3 = j <= poz and U.GREEN or U.PAPER2 end
		end
	end
	if tryb == "robux" then
		for _, k in ipairs(kartyRobux) do
			if k.pass then
				local ma = maPass(k.id)
				k.kupTekst.Text = ma and "MASZ ✓" or "KUP"
				k.kupLico.BackgroundColor3 = ma and U.GREEN or U.YEL
			elseif k.id == "Bilet" and p then
				k.opis.Text = (C.Produkty.Bilet.opis or "") .. "  (masz: " .. (p.bilety or 0) .. ")"
			end
		end
	end
	-- nazwy i ilości w plecaku przy produktach
	if p then
		for i, x in ipairs(C.Sklepik) do
			local pr = f:FindFirstChild("Produkt_" .. i)
			if pr then
				local nz = pr.Lico:FindFirstChild("Nazwa")
				local ile = p.przedmioty[x.id] or 0
				if nz then nz.Text = x.nazwa .. (ile > 0 and (" (masz " .. ile .. ")") or "") end
				local brak = pr.Lico:FindFirstChild("Slot") and pr.Lico.Slot:FindFirstChild("Brak")
				if brak then brak.Text = x.opis brak.TextWrapped = true brak.Size = UDim2.fromScale(0.9, 0.8) brak.Position = UDim2.fromScale(0.05, 0.1) end
			end
		end
	end
end
O.odswiezSklepik = odswiezSklepik
local function podepnijSklepik()
	local o = okno("Sklepik")
	if not o then return end
	local f = o.Lico
	for i, x in ipairs(C.Sklepik) do
		local pr = f:FindFirstChild("Produkt_" .. i)
		local kup = pr and pr.Lico:FindFirstChild("Kup")
		if kup then kup.Activated:Connect(function() K.wyslij("kup", { rodzaj = "sklepik", id = x.id }) end) end
	end
	-- przełączniki trybu: ULEPSZENIA / ROBUX (kliknięcie aktywnego wraca do sklepiku)
	local function przelacznik(t, tekst, poz, rozm, kolor, kolorTekstu)
		local b, bf = U.przyciskTekst(f, t .. "Btn", tekst, poz, rozm, kolor, kolorTekstu, nil, 0)
		przyciskiTrybu[t] = { bf = bf, kolor = kolor }
		b.Activated:Connect(function()
			tryb = tryb == t and "sklepik" or t
			odswiezSklepik()
		end)
	end
	przelacznik("ulepszenia", "ULEPSZENIA", UDim2.fromScale(0.43, 0.085), UDim2.fromScale(0.21, 0.08), Color3.fromRGB(140, 195, 240), U.INK)
	przelacznik("robux", "R$ ROBUX", UDim2.fromScale(0.7, 0.195), UDim2.fromScale(0.2, 0.065), Color3.fromRGB(90, 200, 110), U.INK)
	local i = 0
	for id, u in pairs(C.Ulepszenia) do
		i += 1
		local c = (i - 1) % 2
		local r = math.floor((i - 1) / 2)
		local h, kf = U.karta(f, "Ulep_" .. id, UDim2.fromScale(0.14 + c * 0.41, 0.3 + r * 0.33), UDim2.fromScale(0.38, 0.3), U.PAPER, nil, 0)
		h.Visible = false
		U.txt(kf, { Text = u.nazwa, Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.04), TextXAlignment = Enum.TextXAlignment.Left })
		U.txt(kf, { Text = u.opis, TextColor3 = U.GREY, Size = UDim2.fromScale(0.9, 0.15), Position = UDim2.fromScale(0.05, 0.25), TextXAlignment = Enum.TextXAlignment.Left })
		local poz = U.txt(kf, { Text = "", Size = UDim2.fromScale(0.5, 0.14), Position = UDim2.fromScale(0.05, 0.42), TextXAlignment = Enum.TextXAlignment.Left })
		local kropki = {}
		for j = 1, #u.ceny do
			local kr = U.new("Frame", { BackgroundColor3 = U.PAPER2, Size = UDim2.fromScale(0.08, 0.08), SizeConstraint = Enum.SizeConstraint.RelativeXX, Position = UDim2.fromScale(0.5 + (j - 1) * 0.09, 0.44) }, kf)
			U.stroke(kr, 1.5)
			kropki[j] = kr
		end
		local cena = U.txt(kf, { Text = "", Font = Enum.Font.Bangers, TextColor3 = U.RED, Size = UDim2.fromScale(0.4, 0.18), Position = UDim2.fromScale(0.05, 0.74), TextXAlignment = Enum.TextXAlignment.Left })
		local kup = U.przyciskTekst(kf, "Kup", "KUP", UDim2.fromScale(0.72, 0.82), UDim2.fromScale(0.42, 0.22), U.YEL, U.INK, Vector2.new(0.5, 0.5))
		kup.Activated:Connect(function() K.wyslij("kup", { rodzaj = "ulepszenie", id = id }) end)
		table.insert(kartyUlepszen, { id = id, h = h, poz = poz, cena = cena, kropki = kropki })
	end
	-- karty za Robuxy: 2 rzędy gamepassów (po 3) + rząd produktów (4)
	for n, wpis in ipairs(KOLEJNOSC_ROBUX) do
		local id, pass = wpis[1], wpis[2]
		local x = pass and C.Gamepassy[id] or C.Produkty[id]
		if x then
			local pos, size
			if pass then
				local c = (n - 1) % 3
				local r = math.floor((n - 1) / 3)
				pos, size = UDim2.fromScale(0.14 + c * 0.275, 0.29 + r * 0.225), UDim2.fromScale(0.255, 0.205)
			else
				local c = n - 7
				pos, size = UDim2.fromScale(0.14 + c * 0.205, 0.75), UDim2.fromScale(0.19, 0.2)
			end
			local kolor = id == "VIP" and Color3.fromRGB(255, 214, 90) or U.PAPER
			local h, kf = U.karta(f, "Robux_" .. id, pos, size, kolor, nil, 0)
			h.Visible = false
			U.txt(kf, { Text = x.nazwa, Font = Enum.Font.Bangers, TextWrapped = true, Size = UDim2.fromScale(0.9, 0.24), Position = UDim2.fromScale(0.05, 0.04), TextXAlignment = Enum.TextXAlignment.Left })
			local opis = U.txt(kf, { Text = x.opis or (x.zl and ("+" .. x.zl .. " złotówek") or ""), TextColor3 = U.GREY, TextWrapped = true, Size = UDim2.fromScale(0.9, 0.36), Position = UDim2.fromScale(0.05, 0.29), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
			U.txt(kf, { Text = "R$ " .. x.cena, Font = Enum.Font.Bangers, TextColor3 = Color3.fromRGB(30, 140, 60), Size = UDim2.fromScale(0.45, 0.24), Position = UDim2.fromScale(0.05, 0.71), TextXAlignment = Enum.TextXAlignment.Left })
			local kup, kupF = U.przyciskTekst(kf, "Kup", "KUP", UDim2.fromScale(0.74, 0.83), UDim2.fromScale(0.44, 0.26), U.YEL, U.INK, Vector2.new(0.5, 0.5))
			kup.Activated:Connect(function()
				if pass and maPass(id) then return end
				K.wyslij("kup", { rodzaj = "robux", id = id })
			end)
			table.insert(kartyRobux, { id = id, pass = pass, h = h, opis = opis, kupTekst = kupF.Tekst, kupLico = kupF })
		end
	end
	K.gracz.AttributeChanged:Connect(function(a) if a:sub(1, 3) == "GP_" then odswiezSklepik() end end)
end

------------------------------------------------------------------ PLECAK
local zakladkaPlecaka = "Rzeczy"
local function slotUstaw(slot, tekst, pod, kolor, akcja)
	for _, c in ipairs(slot:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	slot:SetAttribute("Akcja", nil)
	slot.BackgroundColor3 = kolor or U.PAPER2
	if tekst then
		U.txt(slot, { Name = "Nazwa", Text = tekst, TextWrapped = true, Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.05, 0.08) })
		U.txt(slot, { Name = "Pod", Text = pod or "", Font = Enum.Font.Bangers, TextColor3 = U.RED, Size = UDim2.fromScale(0.9, 0.3), Position = UDim2.fromScale(0.05, 0.62) })
	end
	O.akcjeSlotow[slot] = akcja
end
O.akcjeSlotow = {}
local function odswiezPlecak()
	local o = okno("Plecak")
	local p = profil()
	if not o or not p then return end
	local f = o.Lico
	for _, z in ipairs({ "Rzeczy", "Skórki", "Emotki" }) do
		local b = f:FindFirstChild("Zakladka_" .. z)
		if b and b:GetAttribute("Aktywna") then zakladkaPlecaka = z end
	end
	local lista = {}
	if zakladkaPlecaka == "Rzeczy" then
		for _, x in ipairs(C.Sklepik) do
			local ile = p.przedmioty[x.id] or 0
			if ile > 0 then
				table.insert(lista, { t = x.nazwa, pod = "×" .. ile .. "  UŻYJ", kolor = U.PAPER, akcja = function() K.wyslij("uzyj", { id = x.id }) end })
			end
		end
		if #lista == 0 then table.insert(lista, { t = "Pusto. Kup coś w Sklepiku!", pod = "", kolor = U.PAPER2 }) end
	elseif zakladkaPlecaka == "Skórki" then
		for _, x in ipairs(C.Plecaki) do
			local ma = p.plecaki[x.id]
			local zal = p.plecak == x.id
			table.insert(lista, { t = x.nazwa, pod = zal and "ZAŁOŻONY" or (ma and "ZAŁÓŻ" or (x.cena .. " zł")), kolor = zal and U.YEL or (ma and U.PAPER or U.PAPER2),
				akcja = function() K.wyslij("kup", { rodzaj = "plecak", id = x.id }) end })
		end
	else
		for _, x in ipairs(C.Emotki) do
			local ma = (x.premium and maPass(x.premium)) or (not x.premium and p.emotki[x.id])
			local pod = ma and "ZAGRAJ" or (x.premium and ("R$ " .. C.Gamepassy[x.premium].cena) or (x.cena .. " zł"))
			table.insert(lista, { t = (x.premium and "★ " or "") .. x.nazwa, pod = pod, kolor = ma and U.PAPER or U.PAPER2,
				akcja = function()
					local ma2 = (x.premium and maPass(x.premium)) or (not x.premium and profil().emotki[x.id])
					if ma2 then O.emotka(x) else K.wyslij("kup", { rodzaj = "emotka", id = x.id }) end
				end })
		end
		-- efekty eliminacji (widać je, gdy jesteś Rozrabiaką)
		for _, x in ipairs(C.EfektyEliminacji) do
			local ma = x.darmowy or maPass("Efekty")
			local wyb = (p.efekt or "POW") == x.id
			table.insert(lista, { t = "Efekt: " .. x.nazwa, pod = wyb and "WYBRANY" or (ma and "WYBIERZ" or ("R$ " .. C.Gamepassy.Efekty.cena)),
				kolor = wyb and U.YEL or (ma and U.PAPER or U.PAPER2),
				akcja = function() K.wyslij("kup", { rodzaj = "efekt", id = x.id }) end })
		end
	end
	for i = 1, 15 do
		local slot = f:FindFirstChild("Slot_" .. i)
		if slot then
			local x = lista[i]
			if x then slotUstaw(slot, x.t, x.pod, x.kolor, x.akcja) else slotUstaw(slot, nil, nil, U.PAPER2, nil) end
		end
	end
	local poj = f:FindFirstChild("Pojemnosc")
	if poj then poj.Text = zakladkaPlecaka == "Rzeczy" and ("rzeczy: " .. #lista) or "" end
	-- etykieta „założone” tylko w skórkach
	for _, c in ipairs(f:GetChildren()) do
		if c.Name == "Tasma" then c.Visible = false end
	end
end
local animTrack
function O.emotka(x)
	local _, hum = K.hrp()
	if not hum then return end
	local an = hum:FindFirstChildOfClass("Animator")
	if not an then return end
	if animTrack then animTrack:Stop() end
	local a = Instance.new("Animation")
	a.AnimationId = x.anim
	animTrack = an:LoadAnimation(a)
	animTrack:Play()
	if x.speed then animTrack:AdjustSpeed(x.speed) end
end
local function podepnijPlecak()
	local o = okno("Plecak")
	if not o then return end
	for i = 1, 15 do
		local slot = o.Lico:FindFirstChild("Slot_" .. i)
		if slot then
			slot.Activated:Connect(function()
				local a = O.akcjeSlotow[slot]
				if a then a() end
			end)
		end
	end
	for _, z in ipairs({ "Rzeczy", "Skórki", "Emotki" }) do
		local b = o.Lico:FindFirstChild("Zakladka_" .. z)
		if b then b:GetAttributeChangedSignal("Aktywna"):Connect(function() task.defer(odswiezPlecak) end) end
	end
end

------------------------------------------------------------------ MEMY
-- 16 przycisków w siatce 4×4; 8 ostatnich z paczki memów (gamepass)
local przyciskiMemow = {}
local function odswiezMemy()
	local ma = maPass("Memy")
	for _, x in ipairs(przyciskiMemow) do
		if x.m.premium then
			x.b.Lico.BackgroundColor3 = ma and Color3.fromRGB(255, 225, 120) or U.PAPER2
			x.klodka.Visible = not ma
		end
	end
end
local function podepnijMemy()
	local o = okno("Memy")
	if not o then return end
	local f = o.Lico
	local wzor = f:FindFirstChild("Mem_SUS") or f:FindFirstChild("Mem_BRUH")
	for i, m in ipairs(C.Memy) do
		local b = f:FindFirstChild("Mem_" .. m.id)
		if not b and wzor then
			b = wzor:Clone()
			b.Name = "Mem_" .. m.id
			b:SetAttribute("Podpiety", nil)
			b.Parent = f
			U.feedback(b)
			local t = b.Lico:FindFirstChildOfClass("TextLabel")
			if t then t.Text = m.id end
		end
		if b then
			local c = (i - 1) % 4
			local r = math.floor((i - 1) / 4)
			b.Position = UDim2.fromScale(0.14 + c * 0.205, 0.255 + r * 0.15)
			b.Size = UDim2.fromScale(0.18, 0.13)
			local klodka = U.txt(b.Lico, { Name = "Klodka", Text = "R$", Font = Enum.Font.Bangers, TextColor3 = Color3.fromRGB(30, 140, 60), Size = UDim2.fromScale(0.4, 0.4), Position = UDim2.fromScale(0.04, 0.06), TextXAlignment = Enum.TextXAlignment.Left, Visible = false })
			table.insert(przyciskiMemow, { m = m, b = b, klodka = klodka })
			b.Activated:Connect(function()
				if m.premium and not maPass("Memy") then
					K.wyslij("kup", { rodzaj = "robux", id = "Memy" })
				else
					K.wyslij("mem", { id = m.id })
				end
			end)
		end
	end
	odswiezMemy()
	K.gracz.AttributeChanged:Connect(function(a) if a == "GP_Memy" then odswiezMemy() end end)
end

------------------------------------------------------------------ RANKING
local rzedyRankingu = {}
local typRankingu = "Dzisiaj"
local function odswiezRanking()
	local o = okno("Ranking")
	if not o then return end
	local f = o.Lico
	if not f:GetAttribute("Dynamiczne") then
		f:SetAttribute("Dynamiczne", true)
		for _, c in ipairs(f:GetChildren()) do
			if c:IsA("TextLabel") and c.Position.Y.Scale > 0.33 then c.Visible = false end
			if c.Name == "Ty" then c.Visible = false end
		end
	end
	for _, r in ipairs(rzedyRankingu) do r:Destroy() end
	rzedyRankingu = {}
	local ok, dane = pcall(function() return K.Pytaj:InvokeServer("ranking", typRankingu) end)
	if not ok or type(dane) ~= "table" then return end
	for i = 1, math.min(7, #dane) do
		local d = dane[i]
		local y = 0.3 + i * 0.078
		local ja = d.nick == K.gracz.DisplayName
		local rz = U.new("Frame", { BackgroundColor3 = U.YEL, BackgroundTransparency = ja and 0.35 or 1, BorderSizePixel = 0, Size = UDim2.fromScale(0.84, 0.066), Position = UDim2.fromScale(0.12, y - 0.004) }, f)
		table.insert(rzedyRankingu, rz)
		U.txt(rz, { Text = i .. ".", Size = UDim2.fromScale(0.1, 0.9), Position = UDim2.fromScale(0.02, 0.05) })
		U.txt(rz, { Text = d.nick, Size = UDim2.fromScale(0.45, 0.9), Position = UDim2.fromScale(0.13, 0.05), TextXAlignment = Enum.TextXAlignment.Left })
		U.txt(rz, { Text = tostring(d.wygrane or 0), Size = UDim2.fromScale(0.15, 0.9), Position = UDim2.fromScale(0.62, 0.05), TextXAlignment = Enum.TextXAlignment.Left })
		U.txt(rz, { Text = d.lvl and ("lvl " .. d.lvl) or "", TextColor3 = U.RED, Size = UDim2.fromScale(0.15, 0.9), Position = UDim2.fromScale(0.82, 0.05), TextXAlignment = Enum.TextXAlignment.Left })
	end
end
local function podepnijRanking()
	local o = okno("Ranking")
	if not o then return end
	for _, z in ipairs({ "Dzisiaj", "Ogólnie" }) do
		local b = o.Lico:FindFirstChild("Zakladka_" .. z)
		if b then b.Activated:Connect(function() typRankingu = z == "Ogólnie" and "Ogolnie" or "Dzisiaj" task.defer(odswiezRanking) end) end
	end
	o:GetPropertyChangedSignal("Visible"):Connect(function() if o.Visible then task.spawn(odswiezRanking) end end)
end

------------------------------------------------------------------ HULAJNOGA
local wybranaHul = 1
local function odswiezHulajnoge()
	local o = okno("Hulajnoga")
	local p = profil()
	if not o or not p then return end
	local f = o.Lico
	for i, x in ipairs(C.Hulajnogi) do
		local b = f:FindFirstChild("Hulajnoga_" .. i)
		if b then
			local ma = (not x.robux) or maPass(x.robux)
			local zal = p.hulajnoga == x.id
			if zal then wybranaHul = i end
			b.Lico.BackgroundColor3 = zal and U.YEL or (x.robux and Color3.fromRGB(205, 245, 225) or U.PAPER)
			local teksty = {}
			for _, t in ipairs(b.Lico:GetChildren()) do if t:IsA("TextLabel") then table.insert(teksty, t) end end
			table.sort(teksty, function(a, c) return a.Position.Y.Scale < c.Position.Y.Scale end)
			if teksty[1] then teksty[1].Text = x.nazwa end
			if teksty[2] then
				teksty[2].Text = zal and "wybrana" or (ma and (x.robux and "masz – wybierz" or "darmowa – wybierz") or ("R$ " .. C.Gamepassy[x.robux].cena))
				teksty[2].TextColor3 = ma and U.GREEN or U.RED
			end
		end
	end
	-- statystyki
	local x = C.Hulajnogi[wybranaHul]
	local kw = {}
	for _, c in ipairs(f:GetChildren()) do
		if c:IsA("Frame") and math.abs(c.Size.X.Scale - 0.035) < 0.001 then table.insert(kw, c) end
	end
	table.sort(kw, function(a, b) if math.abs(a.Position.Y.Scale - b.Position.Y.Scale) > 0.01 then return a.Position.Y.Scale < b.Position.Y.Scale end return a.Position.X.Scale < b.Position.X.Scale end)
	local pr = math.clamp(math.floor((x.predkosc - 16) / 16 * 6 + 0.5), 1, 6)
	local skret = x.robux and 6 or 3
	for i, c in ipairs(kw) do
		local wiersz = i <= 6 and pr or skret
		local k = (i - 1) % 6 + 1
		c.BackgroundColor3 = k <= wiersz and U.YEL or U.PAPER2
	end
	-- podgląd
	local pod = f:FindFirstChild("Podglad")
	local vp = pod and pod.Lico:FindFirstChild("Model")
	local wzor = K.Gra:FindFirstChild("Prefaby") and K.Gra.Prefaby:FindFirstChild("Hulajnoga")
	if vp and wzor then
		vp:ClearAllChildren()
		local m = wzor:Clone()
		for _, c in ipairs(m:GetDescendants()) do
			if c:IsA("BasePart") and (c.Name == "Rama" or c.Name == "Deska" or c:GetAttribute("Kolor")) then
				c.Color = x.kolor
				if x.neon then c.Material = Enum.Material.Neon end
			end
		end
		m.Parent = vp
		local cam = Instance.new("Camera")
		local cf, size = m:GetBoundingBox()
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(size.Magnitude * 0.9, size.Magnitude * 0.35, size.Magnitude * 0.6), cf.Position)
		cam.Parent = vp
		vp.CurrentCamera = cam
		local brak = pod.Lico:FindFirstChild("Brak")
		if brak then brak.Visible = false end
	end
end
local function podepnijHulajnoge()
	local o = okno("Hulajnoga")
	if not o then return end
	local wzor = o.Lico:FindFirstChild("Hulajnoga_3")
	for i, x in ipairs(C.Hulajnogi) do
		local b = o.Lico:FindFirstChild("Hulajnoga_" .. i)
		if not b and wzor then
			b = wzor:Clone()
			b.Name = "Hulajnoga_" .. i
			b:SetAttribute("Podpiety", nil)
			b.Parent = o.Lico
			U.feedback(b)
		end
		if b then
			b.Position = UDim2.fromScale(0.63, 0.25 + (i - 1) * 0.1)
			b.Size = UDim2.fromScale(0.32, 0.088)
			b.Activated:Connect(function() wybranaHul = i K.wyslij("kup", { rodzaj = "hulajnoga", id = x.id }) odswiezHulajnoge() end)
		end
	end
	K.gracz.AttributeChanged:Connect(function(a) if a:sub(1, 3) == "GP_" then odswiezHulajnoge() end end)
	local w = o.Lico:FindFirstChild("Wsiadaj")
	if w then w.Activated:Connect(function() K.wyslij("hulajnoga", { w = not K.gracz:GetAttribute("NaHulajnodze") }) end) end
end

------------------------------------------------------------------ OGŁOSZENIA
local ostatnie = {}
local function odswiezOgloszenia()
	local o = okno("Ogloszenia")
	if not o then return end
	for i = 1, 3 do
		local k = o.Lico:FindFirstChild("Ogloszenie_" .. i)
		local d = ostatnie[i]
		if k and d then
			local t = {}
			for _, x in ipairs(k.Lico:GetChildren()) do if x:IsA("TextLabel") then table.insert(t, x) end end
			table.sort(t, function(a, b) return a.Position.Y.Scale < b.Position.Y.Scale end)
			if t[1] then t[1].Text = d.kto end
			if t[2] then t[2].Text = d.tekst end
		end
	end
end
local function podepnijOgloszenia()
	local o = okno("Ogloszenia")
	if not o then return end
	local pole = o.Lico:FindFirstChild("Pole")
	local box = pole and pole.Lico:FindFirstChild("Tekst")
	local nadaj = o.Lico:FindFirstChild("Nadaj")
	if nadaj and box then
		nadaj.Activated:Connect(function()
			if #box.Text >= 2 then K.wyslij("ogloszenie", { tekst = box.Text }) box.Text = "" end
		end)
	end
	K.na("Ogloszenie", function(d)
		table.insert(ostatnie, 1, d)
		while #ostatnie > 3 do table.remove(ostatnie) end
		odswiezOgloszenia()
		hud.karteczka("Radiowęzeł: " .. d.kto, d.tekst, nil, 5)
	end)
end

------------------------------------------------------------------ SABOTAŻ
local TYPY = { "Swiatlo", "Drzwi", "Alarm", "Kartkowka" }
local function odswiezSabotaz()
	local o = okno("Sabotaz")
	if not o then return end
	local od = K.Gra:GetAttribute("SabotazOd") or 0
	local zost = math.ceil(od - K.czasSerwera())
	for i, typ in ipairs(TYPY) do
		local b = o.Lico:FindFirstChild("Sabotaz_" .. i)
		if b then
			local def = C.Sabotaze[typ]
			local t = {}
			for _, x in ipairs(b.Lico:GetChildren()) do if x:IsA("TextLabel") then table.insert(t, x) end end
			table.sort(t, function(a, c) return a.Position.Y.Scale < c.Position.Y.Scale end)
			if t[1] then t[1].Text = def.nazwa end
			if t[2] then t[2].Text = def.opis end
			local trwa = K.Gra:GetAttribute("Sab_" .. typ) ~= nil
			local gotowe = zost <= 0 and not trwa and K.Gra:GetAttribute("Sab_Alarm") == nil
			local st = b.Lico:FindFirstChild("Stan")
			if st then
				local tx = st:FindFirstChildOfClass("TextLabel")
				tx.Text = trwa and "TRWA" or (gotowe and "GOTOWE" or (zost > 0 and ("0:" .. string.format("%02d", zost)) or "CZEKAJ"))
				tx.TextColor3 = gotowe and U.RED or U.INK
				local s = st:FindFirstChildOfClass("UIStroke")
				if s then s.Color = gotowe and U.RED or U.INK end
			end
			b.Lico.BackgroundColor3 = gotowe and U.PAPER or Color3.fromRGB(150, 150, 160)
		end
	end
end
local function podepnijSabotaz()
	local o = okno("Sabotaz")
	if not o then return end
	for i, typ in ipairs(TYPY) do
		local b = o.Lico:FindFirstChild("Sabotaz_" .. i)
		if b then b.Activated:Connect(function() K.wyslij("sabotaz", { typ = typ }) end) end
	end
end
local function widocznoscIkon()
	local ikona = hudGui:FindFirstChild("BottomAction")
	local zly = K.jestZly() and K.stan.zyje
	local faza = K.Gra:GetAttribute("Faza")
	if ikona then ikona.Visible = zly == true and faza == "Gra" end
	if not (zly and faza == "Gra") then
		local o = okno("Sabotaz")
		if o and o.Visible then o.Visible = false end
	end
end

function O.Init(k, moduly)
	K = k
	U = K.Styl
	C = K.C
	sz = K.PlayerGui:WaitForChild("SzablonUI")
	hudGui = K.PlayerGui:WaitForChild("SchoolIconHUD")
	hud = moduly.HUD
	muzykaLobby = U.new("Sound", { Name = "MuzykaLobby", SoundId = "rbxassetid://1836473422", Looped = false, Volume = 0.25 }, SoundService)
	podepnijUstawienia()
	podepnijSklepik()
	podepnijPlecak()
	podepnijMemy()
	podepnijRanking()
	podepnijHulajnoge()
	podepnijOgloszenia()
	podepnijSabotaz()
	K.na("Profil", function()
		odswiezSklepik()
		odswiezPlecak()
		odswiezHulajnoge()
		odswiezRole()
	end)
	K.na("Rola", function() odswiezRole() widocznoscIkon() end)
	-- strefa VIP: VIP przechodzi przez linę (kolizja wyłączona lokalnie), reszta widzi prompt „Kup”
	local function strefaVIP()
		local s = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("StrefaVIP")
		local br = s and s:FindFirstChild("Bramka")
		if not br then return end
		local vip = K.gracz:GetAttribute("GP_VIP") == true
		br.CanCollide = not vip
		local pr = br:FindFirstChild("PromptVIP")
		if pr then pr.Enabled = not vip end
	end
	task.spawn(function()
		local l = workspace:WaitForChild("Lobby", 30)
		if l and l:WaitForChild("StrefaVIP", 30) then l.StrefaVIP:WaitForChild("Bramka", 10) strefaVIP() end
	end)
	K.gracz:GetAttributeChangedSignal("GP_VIP"):Connect(function() odswiezRole() strefaVIP() end)
	K.na("Gamepass", function(d)
		local gp = C.Gamepassy[d.klucz]
		if gp and d.nowy then moduly.HUD.karteczka("Dzięki! ★", gp.nazwa .. " jest twoje.", "zielony", 3) end
		odswiezSklepik() odswiezPlecak() odswiezHulajnoge()
	end)
	K.na("Faza", function() odswiezRole() widocznoscIkon() end)
	K.na("Wyeliminowany", widocznoscIkon)
	K.na("Zakup", function(d)
		if d.msg then moduly.HUD.karteczka(d.ok and "Sklepik" or "Ups!", d.msg, d.ok and "zielony" or "czerwony", 2) end
	end)
	K.Gra:GetAttributeChangedSignal("Faza"):Connect(widocznoscIkon)
	odswiezRole()
	widocznoscIkon()
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t > 0.5 then
			t = 0
			local o = okno("Sabotaz")
			if o and o.Visible then odswiezSabotaz() end
		end
	end)
end

return O
