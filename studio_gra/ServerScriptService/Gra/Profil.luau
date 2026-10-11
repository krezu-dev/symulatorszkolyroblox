-- Profil gracza: złotówki, XP, levele, ulepszenia, plecak, zakupy, ranking.
-- DataStore z zabezpieczeniem: jak nie działa (Studio bez API), trzyma dane w pamięci.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local P = {}
local W, C, M
local dane = {}      -- [player] = profil
local sesja = {}     -- [player] = statystyki z tej sesji (ranking „Dzisiaj”)
local buffy = {}     -- [player] = { szybkosc = {moc, do}, zadania = {...}, zlNastepne = 2, xpNastepne = 2 }
local store, ranking
pcall(function()
	store = DataStoreService:GetDataStore("SzkolaProfile_v1")
	ranking = DataStoreService:GetOrderedDataStore("SzkolaRanking_v1")
end)

local function domyslny()
	return {
		zl = 50, xp = 0, lvl = 1,
		ulepszenia = {}, przedmioty = {},
		hulajnogi = { Zwykla = true }, hulajnoga = "Zwykla",
		plecaki = { Klasyczny = true }, plecak = "Klasyczny",
		emotki = { Machanie = true },
		passy = {}, bilety = 0, efekt = "POW",
		staty = { rundy = 0, wygrane = 0, zadania = 0, eliminacje = 0, wygraneZli = 0 },
	}
end
local function scal(d, wzor)
	for k, v in pairs(wzor) do
		if d[k] == nil then d[k] = v
		elseif type(v) == "table" and type(d[k]) == "table" then scal(d[k], v) end
	end
	return d
end

function P.Get(p) return dane[p] end
function P.Sesja(p) return sesja[p] end

function P.tytul(lvl)
	local t = C.Tytuly[1].t
	for _, x in ipairs(C.Tytuly) do if lvl >= x.lvl then t = x.t end end
	return t
end

local function leaderstats(p)
	local d = dane[p]
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder") ls.Name = "leaderstats" ls.Parent = p
		local a = Instance.new("IntValue") a.Name = "Level" a.Parent = ls
		local b = Instance.new("IntValue") b.Name = "Zł" b.Parent = ls
		local c = Instance.new("IntValue") c.Name = "Wygrane" c.Parent = ls
	end
	ls.Level.Value = d.lvl
	ls["Zł"].Value = d.zl
	ls.Wygrane.Value = d.staty.wygrane
	p:SetAttribute("Level", d.lvl)
	p:SetAttribute("Tytul", P.tytul(d.lvl))
end

function P.wyslij(p)
	local d = dane[p]
	if not d then return end
	leaderstats(p)
	W.wyslij(p, "Profil", { d = d, xpDo = C.XpNaLevel(d.lvl), tytul = P.tytul(d.lvl) })
end

local function zaladuj(p)
	local d
	if store then
		local ok, wynik = pcall(function() return store:GetAsync("u" .. p.UserId) end)
		if ok and type(wynik) == "table" then d = wynik end
	end
	dane[p] = scal(d or domyslny(), domyslny())
	-- stare/usunięte hulajnogi -> zwykła
	local okHul = false
	for _, x in ipairs(C.Hulajnogi) do if x.id == dane[p].hulajnoga then okHul = true end end
	if not okHul then dane[p].hulajnoga = C.Hulajnogi[1].id end
	sesja[p] = { wygrane = 0, zadania = 0, eliminacje = 0 }
	buffy[p] = {}
	P.wyslij(p)
	if M.Swiat and M.Swiat.zalozPlecak then M.Swiat.zalozPlecak(p) end
end

function P.Zapisz(p)
	local d = dane[p]
	if not d or not store then return end
	pcall(function() store:SetAsync("u" .. p.UserId, d) end)
	if ranking then pcall(function() ranking:SetAsync("u" .. p.UserId, d.staty.wygrane) end) end
end

-- mnożniki z ulepszeń i buffów
function P.ulepszenie(p, id)
	local d = dane[p]
	return d and (d.ulepszenia[id] or 0) or 0
end
function P.predkoscChodu(p)
	local s = 16 + P.ulepszenie(p, "Trampki") * C.Ulepszenia.Trampki.na
	local b = buffy[p] and buffy[p].szybkosc
	if b and os.clock() < b.do_ then s += b.moc end
	return s
end
function P.mnoznikTrzymania(p)
	local m = 1 - P.ulepszenie(p, "SzybkieRece") * C.Ulepszenia.SzybkieRece.na
	local b = buffy[p] and buffy[p].zadania
	if b and os.clock() < b.do_ then m *= b.moc end
	return math.max(0.25, m)
end

-- Dodaj nagrodę. powod: tekst do powiadomienia
function P.Dodaj(p, zl, xp, powod)
	local d = dane[p]
	if not d then return end
	local vip = (M.Sklep and M.Sklep.ma(p, "VIP")) and 0.2 or 0
	zl = math.floor((zl or 0) * (1 + P.ulepszenie(p, "Kieszonkowe") * C.Ulepszenia.Kieszonkowe.na + vip) + 0.5)
	xp = math.floor((xp or 0) * (1 + P.ulepszenie(p, "Kujon") * C.Ulepszenia.Kujon.na) + 0.5)
	local b = buffy[p]
	if b and b.zlNastepne and zl > 0 then zl *= b.zlNastepne; b.zlNastepne = nil end
	if b and b.xpNastepne and xp > 0 then xp *= b.xpNastepne; b.xpNastepne = nil end
	d.zl += zl
	d.xp += xp
	local awans = false
	while d.xp >= C.XpNaLevel(d.lvl) do
		d.xp -= C.XpNaLevel(d.lvl)
		d.lvl += 1
		d.zl += C.Nagrody.NaLevel.zl
		awans = true
	end
	W.wyslij(p, "Nagroda", { zl = zl, xp = xp, powod = powod })
	if awans then
		W.wyslij(p, "Awans", { lvl = d.lvl, tytul = P.tytul(d.lvl), bonus = C.Nagrody.NaLevel.zl })
		W.wszyscy("Czat", { tekst = p.DisplayName .. " awansował na level " .. d.lvl .. "! (" .. P.tytul(d.lvl) .. ")" })
	end
	P.wyslij(p)
end

function P.Statystyka(p, klucz, ile)
	local d = dane[p]
	if not d then return end
	d.staty[klucz] = (d.staty[klucz] or 0) + (ile or 1)
	local s = sesja[p]
	if s and s[klucz] then s[klucz] += (ile or 1) end
end

------------------------------------------------------------------ ZAKUPY
local function znajdzW(lista, id) for _, x in ipairs(lista) do if x.id == id then return x end end end

function P.Kup(p, rodzaj, id)
	local d = dane[p]
	if not d then return false, "brak profilu" end
	local cena, dodaj
	if rodzaj == "sklepik" then
		local x = znajdzW(C.Sklepik, id) if not x then return false end
		cena = x.cena
		dodaj = function() d.przedmioty[id] = (d.przedmioty[id] or 0) + 1 end
	elseif rodzaj == "hulajnoga" then
		local x = znajdzW(C.Hulajnogi, id) if not x then return false end
		if x.robux then
			if not M.Sklep.ma(p, x.robux) then return M.Sklep.kup(p, x.robux) end
		end
		d.hulajnoga = id
		P.wyslij(p)
		return true, "Wybrana: " .. x.nazwa
	elseif rodzaj == "plecak" then
		local x = znajdzW(C.Plecaki, id) if not x then return false end
		if d.plecaki[id] then d.plecak = id P.wyslij(p) M.Swiat.zalozPlecak(p) return true, "Założony: " .. x.nazwa end
		cena = x.cena
		dodaj = function() d.plecaki[id] = true d.plecak = id end
	elseif rodzaj == "emotka" then
		local x = znajdzW(C.Emotki, id) if not x then return false end
		if x.premium then
			if M.Sklep.ma(p, x.premium) then return true, "Masz to w paczce tańców" end
			return M.Sklep.kup(p, x.premium)
		end
		if d.emotki[id] then return true, "Masz już tę emotkę" end
		cena = x.cena
		dodaj = function() d.emotki[id] = true end
	elseif rodzaj == "efekt" then
		local x = znajdzW(C.EfektyEliminacji, id) if not x then return false end
		if not x.darmowy and not M.Sklep.ma(p, "Efekty") then return M.Sklep.kup(p, "Efekty") end
		d.efekt = id
		P.wyslij(p)
		return true, "Efekt eliminacji: " .. x.nazwa
	elseif rodzaj == "robux" then
		return M.Sklep.kup(p, id)
	elseif rodzaj == "ulepszenie" then
		local u = C.Ulepszenia[id] if not u then return false end
		local poz = d.ulepszenia[id] or 0
		if poz >= #u.ceny then return false, "Maksymalny poziom" end
		cena = u.ceny[poz + 1]
		dodaj = function() d.ulepszenia[id] = poz + 1 end
	else
		return false
	end
	if d.zl < cena then return false, "Za mało kieszonkowego!" end
	d.zl -= cena
	dodaj()
	P.wyslij(p)
	if rodzaj == "plecak" then M.Swiat.zalozPlecak(p) end
	if rodzaj == "ulepszenie" then M.Runda.odswiezPredkosc(p) end
	return true, "Kupione!"
end

-- użycie przedmiotu z plecaka (Sklepik)
function P.Uzyj(p, id)
	local d = dane[p]
	local x = znajdzW(C.Sklepik, id)
	if not d or not x or (d.przedmioty[id] or 0) <= 0 then return false, "Nie masz tego" end
	d.przedmioty[id] -= 1
	if d.przedmioty[id] <= 0 then d.przedmioty[id] = nil end
	local b = buffy[p]
	if x.efekt == "szybkosc" then b.szybkosc = { moc = x.moc, do_ = os.clock() + x.czas }
	elseif x.efekt == "zadania" then b.zadania = { moc = x.moc, do_ = os.clock() + x.czas }
	elseif x.efekt == "zl" then b.zlNastepne = x.moc
	elseif x.efekt == "xp" then b.xpNastepne = x.moc
	elseif x.efekt == "skok" then b.skok = { moc = x.moc, do_ = os.clock() + x.czas } end
	M.Runda.odswiezPredkosc(p)
	if x.czas > 0 then
		task.delay(x.czas + 0.1, function() if p.Parent then M.Runda.odswiezPredkosc(p) end end)
	end
	P.wyslij(p)
	W.dzwiek("Moneta", p.Character and p.Character:FindFirstChild("Head"), 0.6, 40)
	return true, x.nazwa .. ": " .. x.opis
end
function P.skok(p)
	local b = buffy[p] and buffy[p].skok
	if b and os.clock() < b.do_ then return 50 + b.moc end
	return 50
end

------------------------------------------------------------------ RANKING
local cacheRanking, cacheCzas = nil, 0
function P.Ranking(typ)
	if typ == "Dzisiaj" then
		local t = {}
		for p, s in pairs(sesja) do
			if p.Parent then table.insert(t, { nick = p.DisplayName, wygrane = s.wygrane, zadania = s.zadania, lvl = dane[p] and dane[p].lvl or 1 }) end
		end
		table.sort(t, function(a, b) if a.wygrane ~= b.wygrane then return a.wygrane > b.wygrane end return a.zadania > b.zadania end)
		return t
	end
	if os.clock() - cacheCzas < 60 and cacheRanking then return cacheRanking end
	local t = {}
	if ranking then
		local ok, strona = pcall(function() return ranking:GetSortedAsync(false, 10):GetCurrentPage() end)
		if ok then
			for _, w in ipairs(strona) do
				local id = tonumber(string.sub(w.key, 2))
				local nick = "?"
				pcall(function() nick = Players:GetNameFromUserIdAsync(id) end)
				table.insert(t, { nick = nick, wygrane = w.value })
			end
		end
	end
	if #t == 0 then -- brak DataStore (Studio): pokaż graczy z serwera
		for p, d in pairs(dane) do if p.Parent then table.insert(t, { nick = p.DisplayName, wygrane = d.staty.wygrane, lvl = d.lvl }) end end
		table.sort(t, function(a, b) return a.wygrane > b.wygrane end)
	end
	cacheRanking, cacheCzas = t, os.clock()
	return t
end

function P.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end

function P.Start()
	Players.PlayerAdded:Connect(zaladuj)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(zaladuj, p) end
	Players.PlayerRemoving:Connect(function(p)
		P.Zapisz(p)
		dane[p] = nil sesja[p] = nil buffy[p] = nil
	end)
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do P.Zapisz(p) end
	end)
	task.spawn(function()
		while true do
			task.wait(120)
			for _, p in ipairs(Players:GetPlayers()) do P.Zapisz(p) end
		end
	end)
end

return P
