-- Akcje graczy: eliminacja, ciała, noszenie, zgłaszanie, kratki, kryjówki, Dyrektor,
-- memy, ogłoszenia, przedmioty. Tu też jest jedno wejście dla wszystkich RemoteEventów.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")

local A = {}
local W, C, M
local ciala = {}      -- [model] = { ofiara = player, niesie = player|nil }
local folderCial
local kratki = {}     -- lista { czesc, siec, nazwa }
local cooldown = {}   -- [player][klucz] = czas

local function cd(p, klucz, sek)
	cooldown[p] = cooldown[p] or {}
	local t = cooldown[p][klucz] or 0
	if os.clock() < t then return false end
	cooldown[p][klucz] = os.clock() + sek
	return true
end

------------------------------------------------------------------ CIAŁA
local function zrobCialo(ofiara)
	local ch = ofiara.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	ch.Archivable = true
	local kopia = ch:Clone()
	kopia.Name = "Cialo_" .. ofiara.Name
	for _, d in ipairs(kopia:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Sound") then d:Destroy()
		elseif d:IsA("Humanoid") then d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CollisionGroup = "Ciala"
			if d.Name == "HumanoidRootPart" then d.Transparency = 1 end
		end
	end
	-- leży na plecach, na podłodze
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { ch, folderCial }
	local wynik = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
	local y = wynik and wynik.Position.Y or (hrp.Position.Y - 3)
	local _, ry = hrp.CFrame:ToOrientation()
	kopia:PivotTo(CFrame.new(hrp.Position.X, y + 0.55, hrp.Position.Z) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-math.pi / 2, 0, 0))
	-- gwiazdki nad głową
	local glowa = kopia:FindFirstChild("Head")
	if glowa then
		local bb = Instance.new("BillboardGui")
		bb.Name = "Gwiazdki"
		bb.Size = UDim2.fromScale(3, 1.4)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
		bb.AlwaysOnTop = false
		bb.MaxDistance = 60
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.Bangers
		t.TextScaled = true
		t.Text = "✦ ✧ ✦"
		t.TextColor3 = Color3.fromRGB(255, 212, 59)
		t.TextStrokeTransparency = 0
		t.Parent = bb
		bb.Parent = glowa
	end
	kopia:SetAttribute("Cialo", true)
	kopia:SetAttribute("Ofiara", ofiara.UserId)
	kopia.Parent = folderCial
	CollectionService:AddTag(kopia, "Cialo")
	ciala[kopia] = { ofiara = ofiara }
	return kopia
end

local function upusc(p)
	local g = M.Runda.info(p)
	if not g or not g.niesie then return end
	local cialo = g.niesie
	g.niesie = nil
	if ciala[cialo] then ciala[cialo].niesie = nil end
	local hrp = W.hrp(p)
	if hrp and cialo.Parent then
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { p.Character, folderCial }
		local wynik = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
		local y = wynik and wynik.Position.Y or (hrp.Position.Y - 3)
		local pos = hrp.Position - hrp.CFrame.LookVector * 2.5
		local _, ry = hrp.CFrame:ToOrientation()
		cialo:PivotTo(CFrame.new(pos.X, y + 0.55, pos.Z) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-math.pi / 2, 0, 0))
	end
	M.Runda.odswiezPredkosc(p)
	W.wyslij(p, "Niesie", { niesie = false })
end

local function najblizszeCialo(p, zasieg)
	local best, bd = nil, zasieg
	for model in pairs(ciala) do
		if model.Parent then
			local d = W.dystans(p, model:GetPivot().Position)
			if d <= bd then best, bd = model, d end
		end
	end
	return best
end

function A.usunCiala()
	for _, p in ipairs(Players:GetPlayers()) do upusc(p) end
	for model in pairs(ciala) do model:Destroy() end
	ciala = {}
end

------------------------------------------------------------------ ELIMINACJA
function A.wyeliminuj(ofiara, sprawca, bezCiala, powod)
	local R = M.Runda
	local g = R.info(ofiara)
	if not g or not g.zyje then return end
	g.zyje = false
	M.Zadania.anuluj(ofiara)
	upusc(ofiara)
	A.wyjdzZKratki(ofiara, true)
	if not bezCiala then zrobCialo(ofiara) end
	R.zrobDucha(ofiara)
	W.wyslij(ofiara, "Wyeliminowany", { przez = sprawca and sprawca.DisplayName or nil, powod = powod })
	if sprawca then
		local hrp = W.hrp(ofiara)
		W.dzwiek("Cios", hrp, 1, 60)
		W.wszyscy("Efekt", { typ = "gwiazdki", pos = hrp and hrp.Position })
	end
	R.sprawdzWygrana()
end

local function eliminuj(p, cel)
	local R = M.Runda
	if R.faza ~= "Gra" or typeof(cel) ~= "Instance" or not cel:IsA("Player") then return end
	local g, gc = R.info(p), R.info(cel)
	if not g or not gc or not g.zyje or not gc.zyje then return end
	if not C.Role[g.rola].zly or C.Role[gc.rola].zly then return end
	if g.niesie or g.wKratce or gc.wKryjowce or p:GetAttribute("NaHulajnodze") then return end
	if W.dystans(p, cel) > C.Czasy.ZasiegEliminacji + 1.5 then return end
	if os.clock() - (g.ostatniaEliminacja or 0) < C.Czasy.CooldownEliminacji then return end
	g.ostatniaEliminacja = os.clock()
	-- sprawca doskakuje do ofiary (jak w Among Us)
	local hp = W.hrp(cel)
	if hp then p.Character:PivotTo(hp.CFrame * CFrame.new(0, 0, 2.5)) end
	A.wyeliminuj(cel, p)
	M.Profil.Dodaj(p, C.Nagrody.Eliminacja.zl, C.Nagrody.Eliminacja.xp, "Eliminacja")
	M.Profil.Statystyka(p, "eliminacje")
	W.wyslij(p, "Cooldown", { klucz = "eliminacja", do_ = workspace:GetServerTimeNow() + C.Czasy.CooldownEliminacji })
end

------------------------------------------------------------------ NOSZENIE CIAŁA
local function nies(p)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje or not C.Role[g.rola].zly or g.wKratce then return end
	if g.niesie then upusc(p) return end
	local cialo = najblizszeCialo(p, 7)
	if not cialo or ciala[cialo].niesie then return end
	g.niesie = cialo
	ciala[cialo].niesie = p
	R.odswiezPredkosc(p)
	W.wyslij(p, "Niesie", { niesie = true })
end
RunService.Heartbeat:Connect(function()
	for model, info in pairs(ciala) do
		local p = info.niesie
		if p and model.Parent then
			local hrp = W.hrp(p)
			if hrp then
				model:PivotTo(hrp.CFrame * CFrame.new(0, 1.6, 0.9) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.pi / 2))
			end
		end
	end
end)

------------------------------------------------------------------ ZGŁOSZENIE
local function zglos(p)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje or g.wKratce then return end
	local cialo = najblizszeCialo(p, C.Czasy.ZasiegZgloszenia)
	if not cialo then return end
	if ciala[cialo].niesie then return end
	local ofiara = ciala[cialo].ofiara
	M.Spotkania.zwolaj(p, "cialo", ofiara)
end

------------------------------------------------------------------ KRATKI (tylko Rozrabiaka)
function A.wyjdzZKratki(p, cicho)
	local g = M.Runda.info(p)
	if not g or not g.wKratce then return end
	local k = g.wKratce
	g.wKratce = nil
	local hrp = W.hrp(p)
	if hrp then
		hrp.Anchored = false
		p.Character:PivotTo(CFrame.new(k.czesc.Position + Vector3.new(0, 3.5, 0)))
		for _, d in ipairs(p.Character:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Transparency = d:GetAttribute("PrzedKratka") or 0 end
			if d:IsA("Decal") then d.Transparency = 0 end
		end
		if p.Character:GetAttribute("Duch") then M.Runda.zrobDucha(p) end
	end
	if not cicho then W.dzwiek("Pstryk", k.czesc, 0.8, 35) end
	W.wyslij(p, "Kratka", { w = false })
end
local function wejdzDoKratki(p, k)
	local g = M.Runda.info(p)
	if not g or g.niesie then return end
	g.wKratce = k
	local hrp = W.hrp(p)
	for _, d in ipairs(p.Character:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d:SetAttribute("PrzedKratka", d.Transparency) d.Transparency = 1 end
		if d:IsA("Decal") then d.Transparency = 1 end
	end
	p.Character:PivotTo(CFrame.new(k.czesc.Position - Vector3.new(0, 1, 0)))
	hrp.Anchored = true
	W.dzwiek("Pstryk", k.czesc, 0.8, 35)
	local inne = {}
	for i, x in ipairs(kratki) do if x.siec == k.siec and x ~= k then table.insert(inne, { i = i, nazwa = x.nazwa }) end end
	W.wyslij(p, "Kratka", { w = true, nazwa = k.nazwa, inne = inne })
end
local function kratka(p, akcja, cel)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje or not C.Role[g.rola].zly then return end
	if akcja == "wejdz" then
		if g.wKratce then return end
		local best, bd = nil, 8
		for _, k in ipairs(kratki) do
			local d = W.dystans(p, k.czesc.Position)
			if d < bd then best, bd = k, d end
		end
		if best then wejdzDoKratki(p, best) end
	elseif akcja == "przejdz" and g.wKratce then
		local k = kratki[tonumber(cel) or 0]
		if k and k.siec == g.wKratce.siec then
			g.wKratce = k
			p.Character:PivotTo(CFrame.new(k.czesc.Position - Vector3.new(0, 1, 0)))
			local hrp = W.hrp(p) if hrp then hrp.Anchored = true end
			local inne = {}
			for i, x in ipairs(kratki) do if x.siec == k.siec and x ~= k then table.insert(inne, { i = i, nazwa = x.nazwa }) end end
			W.wyslij(p, "Kratka", { w = true, nazwa = k.nazwa, inne = inne })
		end
	elseif akcja == "wyjdz" then
		A.wyjdzZKratki(p)
	end
end

------------------------------------------------------------------ KRYJÓWKI (szafki – każdy)
local function kryjowka(p, wejdz)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje then return end
	if wejdz and not g.wKryjowce then
		local best, bd = nil, 7
		for _, o in ipairs(CollectionService:GetTagged("SzkolaKryjowka")) do
			local pos = W.pozycja(o)
			if pos then local d = W.dystans(p, pos) if d < bd then best, bd = o, d end end
		end
		if not best or g.niesie then return end
		g.wKryjowce = { obiekt = best, wrocDo = W.hrp(p).CFrame }
		for _, d in ipairs(p.Character:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d:SetAttribute("PrzedKryjowka", d.Transparency) d.Transparency = 1 end
			if d:IsA("Decal") then d.Transparency = 1 end
		end
		W.hrp(p).Anchored = true
		W.dzwiek("Pstryk", W.pozycja(best), 0.6, 30)
		W.wyslij(p, "Kryjowka", { w = true })
		task.delay(15, function() -- w szafce max 15 s
			if g.wKryjowce and g.wKryjowce.obiekt == best then kryjowka(p, false) end
		end)
	elseif not wejdz and g.wKryjowce then
		local k = g.wKryjowce
		g.wKryjowce = nil
		local hrp = W.hrp(p)
		if hrp then
			hrp.Anchored = false
			for _, d in ipairs(p.Character:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Transparency = d:GetAttribute("PrzedKryjowka") or 0 end
				if d:IsA("Decal") then d.Transparency = 0 end
			end
		end
		W.wyslij(p, "Kryjowka", { w = false })
	end
end

------------------------------------------------------------------ DYREKTOR: WEZWIJ DO GABINETU
local function wezwij(p, cel)
	local R = M.Runda
	if R.faza ~= "Gra" or typeof(cel) ~= "Instance" or not cel:IsA("Player") then return end
	local g, gc = R.info(p), R.info(cel)
	if not g or not gc or not g.zyje or not gc.zyje or g.rola ~= "Dyrektor" or not g.dyrektorMoc then return end
	if W.dystans(p, cel) > 12 then return end
	g.dyrektorMoc = false
	W.dzwiek("Gwizdek", W.hrp(p), 1, 80)
	if C.Role[gc.rola].zly then
		A.wyeliminuj(cel, nil, true, "Dyrektor wezwał cię do gabinetu. Zawieszony!")
		W.karteczka(nil, "DO GABINETU!", p.DisplayName .. " (Dyrektor) złapał Rozrabiakę: " .. cel.DisplayName .. "!", "zielony")
		M.Profil.Dodaj(p, C.Nagrody.DyrektorTrafil.zl, C.Nagrody.DyrektorTrafil.xp, "Złapany Rozrabiaka")
	else
		W.karteczka(nil, "POMYŁKA DYREKTORA", "Dyrektor wezwał niewinnego ucznia. Traci autorytet!", "czerwony")
		W.wyslij(p, "Karteczka", { tytul = "Ups...", tekst = cel.DisplayName .. " był niewinny. Straciłeś moc wzywania.", kolor = "czerwony" })
	end
	W.wyslij(p, "DyrektorMoc", { ma = false })
end

------------------------------------------------------------------ MEMY I OGŁOSZENIA
local function mem(p, id)
	local x
	for _, m in ipairs(C.Memy) do if m.id == id then x = m end end
	if not x or not cd(p, "mem", 5) then return end
	local glowa = p.Character and p.Character:FindFirstChild("Head")
	if not glowa then return end
	W.dzwiek(x.dzwiek, glowa, 0.9, 70)
	W.wszyscy("Dymek", { kto = p, tekst = x.tekst })
end
local function ogloszenie(p, tekst)
	if type(tekst) ~= "string" then return end
	tekst = string.sub(tekst, 1, 80)
	if #tekst < 2 then return end
	if not cd(p, "ogloszenie", 30) then
		W.karteczka(p, "Radiowęzeł", "Poczekaj chwilę przed następnym ogłoszeniem.")
		return
	end
	local ok, wynik = pcall(function()
		local f = TextService:FilterStringAsync(tekst, p.UserId)
		return f:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then W.karteczka(p, "Radiowęzeł", "Nie udało się nadać ogłoszenia.") return end
	W.wszyscy("Ogloszenie", { kto = p.DisplayName, tekst = wynik })
	W.dzwiek2D("Dzwon", nil, 0.25)
end

------------------------------------------------------------------ START/KONIEC RUNDY
function A.startRundy()
	A.usunCiala()
	cooldown = {}
	for p, g in pairs(M.Runda.gracze) do
		if C.Role[g.rola].zly then
			g.ostatniaEliminacja = os.clock() - C.Czasy.CooldownEliminacji + 15 -- pierwsza eliminacja po 15 s
			W.wyslij(p, "Cooldown", { klucz = "eliminacja", do_ = workspace:GetServerTimeNow() + 15 })
		end
		if g.rola == "Dyrektor" then W.wyslij(p, "DyrektorMoc", { ma = true }) end
	end
end
function A.koniecRundy()
	for _, p in ipairs(Players:GetPlayers()) do
		A.wyjdzZKratki(p, true)
		kryjowka(p, false)
	end
	A.usunCiala()
end
-- przed spotkaniem: wszyscy z kratek, kryjówek, puszczają ciała
function A.przedSpotkaniem()
	for _, p in ipairs(Players:GetPlayers()) do
		A.wyjdzZKratki(p, true)
		kryjowka(p, false)
		upusc(p)
		M.Zadania.anuluj(p)
	end
	M.Swiat.zsiadzWszyscy()
end

------------------------------------------------------------------ WEJŚCIE Z KLIENTA
local obsluga = {}
obsluga.zabij = function(p, d) eliminuj(p, d.cel) end
obsluga.zglos = function(p) zglos(p) end
obsluga.nies = function(p) nies(p) end
obsluga.kratka = function(p, d) kratka(p, d.akcja, d.cel) end
obsluga.kryjowka = function(p, d) kryjowka(p, d.w) end
obsluga.wezwij = function(p, d) wezwij(p, d.cel) end
obsluga.mem = function(p, d) mem(p, d.id) end
obsluga.ogloszenie = function(p, d) ogloszenie(p, d.tekst) end
obsluga.zadanieKoniec = function(p, d) M.Zadania.zakoncz(p, d.id, d.ok) end
obsluga.zadanieAnuluj = function(p) M.Zadania.anuluj(p) end
obsluga.glos = function(p, d) M.Spotkania.glosuj(p, d.cel) end
obsluga.sabotaz = function(p, d) M.Sabotaze.uruchom(p, d.typ) end
obsluga.naprawa = function(p, d) M.Sabotaze.napraw(p, d.punkt, d.ok) end
obsluga.kartkowka = function(p, d) M.Sabotaze.odpowiedzKartkowka(p, d.ok) end
obsluga.kup = function(p, d)
	local ok, msg = M.Profil.Kup(p, d.rodzaj, d.id)
	W.wyslij(p, "Zakup", { ok = ok, msg = msg, rodzaj = d.rodzaj, id = d.id })
	if ok then W.dzwiek2D("Moneta", p, 0.7) else W.dzwiek2D("Blad", p, 0.5) end
end
obsluga.uzyj = function(p, d)
	local ok, msg = M.Profil.Uzyj(p, d.id)
	W.wyslij(p, "Zakup", { ok = ok, msg = msg })
end
obsluga.hulajnoga = function(p, d) M.Swiat.hulajnoga(p, d.w) end
obsluga.chwyc = function(p, d) M.Swiat.chwyc(p, d.obiekt) end
obsluga.rzuc = function(p, d) M.Swiat.rzuc(p, d.kierunek) end
obsluga.kamery = function(p, d) M.Swiat.kamery(p, d.w) end
obsluga.dzwon = function(p) M.Spotkania.dzwon(p) end

function A.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end

function A.Start()
	folderCial = workspace:FindFirstChild("Ciala") or Instance.new("Folder")
	folderCial.Name = "Ciala"
	folderCial.Parent = workspace
	for _, o in ipairs(CollectionService:GetTagged("SzkolaKratka")) do
		local czesc = W.pierwszaCzesc(o)
		if czesc then table.insert(kratki, { czesc = czesc, siec = o:GetAttribute("Siec") or "A", nazwa = o:GetAttribute("Nazwa") or o.Name }) end
	end
	W.Do.OnServerEvent:Connect(function(p, typ, dane)
		local f = obsluga[typ]
		if f then
			local ok, err = pcall(f, p, type(dane) == "table" and dane or {})
			if not ok then warn("[Akcje] " .. tostring(typ) .. ": " .. tostring(err)) end
		end
	end)
	W.Pytaj.OnServerInvoke = function(p, typ, dane)
		if typ == "ranking" then return M.Profil.Ranking(dane) end
		if typ == "profil" then return M.Profil.Get(p) end
		if typ == "kratki" then
			local t = {}
			for i, k in ipairs(kratki) do t[i] = { pos = k.czesc.Position, nazwa = k.nazwa, siec = k.siec } end
			return t
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		upusc(p)
		cooldown[p] = nil
	end)
end

return A
