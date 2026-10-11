-- Zebrania w stołówce: dzwon (z cooldownem) albo zgłoszenie ciała -> cutscenka -> dyskusja -> głosowanie -> wynik.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local S = {}
local W, C, M
local glosy = {}       -- [glosujacy] = cel (player) albo "pomin"
local faza = nil       -- "dyskusja" | "glosowanie" | nil
local miejsca = {}     -- CFrame-y krzeseł w stołówce
local dzwonCzesc

local function przygotujMiejsca()
	-- krzesła wokół stołów w stołówce
	local stolowka = W.znajdz("Wystroj.Stolowka")
	local stoly = {}
	if stolowka then
		for _, s in ipairs(stolowka:GetChildren()) do
			if s.Name == "StolStolowka" then table.insert(stoly, s) end
		end
	end
	for _, s in ipairs(stoly) do
		local cf, size = s:IsA("Model") and s:GetBoundingBox() or s.CFrame, s:IsA("Model") and select(2, s:GetBoundingBox()) or s.Size
		local dl = math.max(size.X, size.Z)
		local wzdluzX = size.X >= size.Z
		local n = math.max(2, math.floor(dl / 3))
		for i = 1, n do
			local t = (i - 0.5) / n - 0.5
			for strona = -1, 1, 2 do
				local off = wzdluzX and Vector3.new(t * dl, 0, strona * (size.Z / 2 + 1.8)) or Vector3.new(strona * (size.X / 2 + 1.8), 0, t * dl)
				local pos = cf.Position + off
				local podloga = pos.Y - size.Y / 2
				table.insert(miejsca, CFrame.lookAt(Vector3.new(pos.X, podloga + 0.5, pos.Z), Vector3.new(cf.Position.X, podloga + 0.5, cf.Position.Z)))
			end
		end
	end
	if #miejsca == 0 then
		for i = 1, 20 do table.insert(miejsca, CFrame.new(-80 + (i % 5) * 4, 10.5, -25 + math.floor(i / 5) * 4)) end
	end
end

local function zamroz(p, tak)
	local g = M.Runda.info(p)
	if g then g.zamrozony = tak end
	M.Runda.odswiezPredkosc(p)
end

-- dzwon w stołówce
function S.dzwon(p)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje then return end
	if os.clock() < R.dzwonOd then
		W.karteczka(p, "Dzwon", "Jeszcze nie możesz dzwonić! Poczekaj " .. math.ceil(R.dzwonOd - os.clock()) .. " s.")
		return
	end
	if (g.dzwony or 0) <= 0 then
		W.karteczka(p, "Dzwon", "Już dzwoniłeś w tej rundzie.")
		return
	end
	if M.Sabotaze.krytyczny() then
		W.karteczka(p, "Dzwon", "Najpierw wyłączcie alarm pożarowy!")
		return
	end
	g.dzwony -= 1
	S.zwolaj(p, "dzwon")
end

function S.zwolaj(kto, powod, ofiara)
	local R = M.Runda
	if R.faza ~= "Gra" then return end
	R.faza = "Spotkanie"
	W.Gra:SetAttribute("Faza", "Spotkanie")
	local start = os.clock()
	M.Akcje.przedSpotkaniem()
	M.Sabotaze.przedSpotkaniem()
	-- cutscenka
	W.wszyscy("SpotkanieStart", {
		powod = powod, kto = kto and kto.DisplayName, ofiara = ofiara and ofiara.DisplayName,
		dzwon = dzwonCzesc and dzwonCzesc.Position,
	})
	if powod == "dzwon" then
		W.dzwiek("Dzwon", dzwonCzesc, 1, 400)
	else
		W.dzwiek2D("Alarm", nil, 0.6)
	end
	task.wait(3)
	M.Akcje.usunCiala()
	-- wszyscy do stołówki
	local i = 0
	local lista = {}
	for p, g in pairs(R.gracze) do
		if p.Parent then
			table.insert(lista, p)
		end
	end
	table.sort(lista, function(a, b) return a.UserId < b.UserId end)
	for _, p in ipairs(lista) do
		i += 1
		local cf = miejsca[((i - 1) % #miejsca) + 1]
		local hrp = W.hrp(p)
		if hrp then
			hrp.Anchored = false
			p.Character:PivotTo(cf + Vector3.new(0, 3, 0))
		end
		zamroz(p, true)
	end
	-- lista do tablicy
	local gracze = {}
	for _, p in ipairs(lista) do
		local g = R.info(p)
		table.insert(gracze, { id = p.UserId, nick = p.DisplayName, zyje = g.zyje, gracz = p })
	end
	glosy = {}
	faza = "dyskusja"
	local doKonca = workspace:GetServerTimeNow() + C.Czasy.Dyskusja
	W.wszyscy("Zebranie", { faza = "dyskusja", do_ = doKonca, gracze = gracze, powod = powod, kto = kto and kto.DisplayName, ofiara = ofiara and ofiara.DisplayName })
	task.wait(C.Czasy.Dyskusja)
	faza = "glosowanie"
	doKonca = workspace:GetServerTimeNow() + C.Czasy.Glosowanie
	W.wszyscy("Zebranie", { faza = "glosowanie", do_ = doKonca, gracze = gracze })
	local t0 = os.clock()
	while os.clock() - t0 < C.Czasy.Glosowanie do
		task.wait(0.25)
		-- wszyscy żywi zagłosowali?
		local brak = false
		for _, p in ipairs(lista) do
			local g = R.info(p)
			if g and g.zyje and p.Parent and glosy[p] == nil then brak = true break end
		end
		if not brak then break end
	end
	faza = nil
	-- liczenie
	local licz, pomin = {}, 0
	local kto_na_kogo = {}
	for glosujacy, cel in pairs(glosy) do
		if cel == "pomin" then pomin += 1
		elseif typeof(cel) == "Instance" then licz[cel] = (licz[cel] or 0) + 1 end
		table.insert(kto_na_kogo, { od = glosujacy.UserId, na = typeof(cel) == "Instance" and cel.UserId or "pomin" })
	end
	local max, wyrzucony, remis = 0, nil, false
	for p, n in pairs(licz) do
		if n > max then max, wyrzucony, remis = n, p, false
		elseif n == max then remis = true end
	end
	if remis or max <= pomin then wyrzucony = nil end
	local byl = wyrzucony and R.zly(wyrzucony)
	-- nagrody za trafny głos
	if wyrzucony and byl then
		for glosujacy, cel in pairs(glosy) do
			if cel == wyrzucony and glosujacy.Parent then
				M.Profil.Dodaj(glosujacy, C.Nagrody.TrafnyGlos.zl, C.Nagrody.TrafnyGlos.xp, "Trafny głos")
			end
		end
	end
	local zostalo = 0
	for p, g in pairs(R.gracze) do if g.zyje and C.Role[g.rola].zly and p ~= wyrzucony then zostalo += 1 end end
	W.wszyscy("WynikGlosowania", {
		glosy = kto_na_kogo,
		wyrzucony = wyrzucony and wyrzucony.DisplayName, wyrzuconyId = wyrzucony and wyrzucony.UserId,
		byl = byl, remis = remis, pomin = pomin, zostaloZlych = zostalo,
	})
	task.wait(C.Czasy.WynikGlosowania)
	if wyrzucony then
		M.Akcje.wyeliminuj(wyrzucony, nil, true, "Klasa wyrzuciła cię ze szkoły.")
	end
	for _, p in ipairs(lista) do if p.Parent then zamroz(p, false) end end
	R.pauzaZegara(os.clock() - start)
	R.dzwonOd = os.clock() + C.Czasy.CooldownDzwonu
	W.Gra:SetAttribute("DzwonOd", workspace:GetServerTimeNow() + C.Czasy.CooldownDzwonu)
	if R.faza == "Spotkanie" then
		R.faza = "Gra"
		W.Gra:SetAttribute("Faza", "Gra")
	end
	W.wszyscy("SpotkanieKoniec", {})
	R.sprawdzWygrana()
end

function S.glosuj(p, cel)
	local R = M.Runda
	if faza ~= "glosowanie" then return end
	local g = R.info(p)
	if not g or not g.zyje or glosy[p] ~= nil then return end
	if cel == "pomin" then
		glosy[p] = "pomin"
	elseif typeof(cel) == "Instance" and cel:IsA("Player") and R.zyje(cel) then
		glosy[p] = cel
	else
		return
	end
	W.wszyscy("Zaglosowal", { id = p.UserId })
	W.dzwiek2D("Pstryk", nil, 0.4)
end

function S.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end
function S.Start()
	przygotujMiejsca()
	-- dzwon: stanowisko w stołówce
	local st = W.znajdz("Wystroj.Stolowka.StanowiskoDzwonu") or W.znajdz("WielkiDzwonSzkolny")
	dzwonCzesc = W.pierwszaCzesc(st) or W.pierwszaCzesc(W.znajdz("WielkiDzwonSzkolny"))
	local zaczep = W.pierwszaCzesc(W.znajdz("WielkiDzwonSzkolny")) or dzwonCzesc
	if zaczep then
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "PromptDzwon"
		pr.ActionText = "Zadzwoń na zebranie"
		pr.ObjectText = "Dzwon szkolny"
		pr.HoldDuration = 0.6
		pr.MaxActivationDistance = 10
		pr.RequiresLineOfSight = false
		pr.KeyboardKeyCode = Enum.KeyCode.E
		pr.Parent = zaczep
		pr.Triggered:Connect(function(p) S.dzwon(p) end)
		dzwonCzesc = zaczep
	end
end

return S
