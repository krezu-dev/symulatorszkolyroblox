-- Pętla gry: Lobby -> Start (autobus) -> Gra (zadania, eliminacje, spotkania) -> Koniec -> Lobby
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local R = {}
local W, C, M

R.faza = "Lobby"
R.gracze = {}        -- [player] = { rola, zyje, zadania = {id...}, zrobione = {id=true}, dzwony, dyrektorMoc }
R.koniecCzasu = 0
R.pauza = false
R.dzwonOd = 0        -- czas, od którego wolno dzwonić
R.zwyciezca = nil

local function ustawFaze(f, dane)
	R.faza = f
	W.Gra:SetAttribute("Faza", f)
	W.wszyscy("Faza", { faza = f, dane = dane })
end

function R.info(p) return R.gracze[p] end
function R.wGrze(p) return R.gracze[p] ~= nil end
function R.zyje(p) local g = R.gracze[p] return g and g.zyje end
function R.rola(p) local g = R.gracze[p] return g and g.rola end
function R.zly(p) local g = R.gracze[p] return g and C.Role[g.rola].zly end

function R.zywi()
	local t = {}
	for p, g in pairs(R.gracze) do if g.zyje and p.Parent then table.insert(t, p) end end
	return t
end

function R.odswiezPredkosc(p)
	local _, hum = W.hrp(p)
	if not hum then return end
	local g = R.gracze[p]
	local s = M.Profil.predkoscChodu(p)
	local hul = p:GetAttribute("NaHulajnodze")
	if hul then s = hul end
	if g and g.niesie then s *= 0.55 end
	if g and g.zamrozony then s = 0 end
	hum.WalkSpeed = s
	hum.UseJumpPower = true
	hum.JumpPower = (g and g.zamrozony) and 0 or M.Profil.skok(p)
end

-- postęp zadań całej szkoły (tylko dobrzy, łącznie z duchami)
function R.postep()
	local zrobione, wszystkie = 0, 0
	for p, g in pairs(R.gracze) do
		if not C.Role[g.rola].zly and p.Parent then
			wszystkie += #g.zadania
			for _ in pairs(g.zrobione) do zrobione += 1 end
		end
	end
	return zrobione, wszystkie
end
function R.wyslijPostep()
	local z, w = R.postep()
	W.wszyscy("Postep", { z = z, w = w })
end

------------------------------------------------------------------ DUCH
function R.zrobDucha(p)
	local ch = p.Character
	if not ch then return end
	ch:SetAttribute("Duch", true)
	for _, d in ipairs(ch:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = math.max(d.Transparency, 0.55)
			d.CollisionGroup = "Duchy"
		elseif d:IsA("Decal") then
			d.Transparency = 0.55
		end
	end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CollisionGroup = "Duchy" end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
end

------------------------------------------------------------------ KONIEC GRY
function R.sprawdzWygrana()
	if R.faza ~= "Gra" and R.faza ~= "Spotkanie" then return end
	if R.zwyciezca then return end
	local zli, dobrzy = 0, 0
	for p, g in pairs(R.gracze) do
		if g.zyje and p.Parent then
			if C.Role[g.rola].zly then zli += 1 else dobrzy += 1 end
		end
	end
	local z, w = R.postep()
	if zli == 0 then
		R.zwyciezca = { strona = "dobrzy", powod = "Rozrabiaka złapany! Szkoła uratowana." }
	elseif zli >= dobrzy then
		R.zwyciezca = { strona = "zli", powod = "Rozrabiaka przejął szkołę!" }
	elseif w > 0 and z >= w then
		R.zwyciezca = { strona = "dobrzy", powod = "Wszystkie zadania zrobione!" }
	end
end
function R.wygrajZli(powod)
	if not R.zwyciezca then R.zwyciezca = { strona = "zli", powod = powod } end
end

------------------------------------------------------------------ START RUNDY
local function przydzielRole(lista)
	local rozklad = C.RozkladRol(#lista)
	local los = W.losowo(lista)
	local i = 1
	local function daj(rola, ile)
		for _ = 1, ile do
			if los[i] then R.gracze[los[i]].rola = rola i += 1 end
		end
	end
	-- testy w Studio: atrybut TestRola na ServerStorage wymusza rolę pierwszego gracza
	local test = game:GetService("ServerStorage"):GetAttribute("TestRola")
	if test and C.Role[test] and #lista == 1 then
		R.gracze[lista[1]].rola = test
		return
	end
	daj("Rozrabiaka", rozklad.Rozrabiaka)
	daj("Dyrektor", rozklad.Dyrektor)
	daj("Wozna", rozklad.Wozna)
	daj("Nauczyciel", rozklad.Nauczyciel)
	while los[i] do R.gracze[los[i]].rola = "Uczen" i += 1 end
end

local function przydzielZadania(p)
	local g = R.gracze[p]
	local def = C.Role[g.rola]
	g.zadania, g.zrobione = {}, {}
	local pula = {}
	local rolaZadan = def.zly and "Uczen" or g.rola
	for id, z in pairs(C.Zadania) do
		if z.rola == rolaZadan and M.Zadania.dostepne(id) then table.insert(pula, id) end
	end
	pula = W.losowo(pula)
	local ile = def.zly and 5 or def.zadan
	for k = 1, math.min(ile, #pula) do table.insert(g.zadania, pula[k]) end
	g.udawane = def.zly -- Rozrabiaka dostaje „udawane” zadania (nie liczą się)
end

local function ladujPostac(p)
	local ok = pcall(function() p:LoadCharacter() end)
	if ok then
		local t = 0
		while not p.Character and t < 5 do task.wait(0.1) t += 0.1 end
	end
end

function R.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end

------------------------------------------------------------------ GŁÓWNA PĘTLA
local function lobby()
	ustawFaze("Lobby")
	R.gracze = {}
	R.zwyciezca = nil
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			ladujPostac(p)
			M.Swiat.doLobby(p)
		end)
	end
	local minimum = RunService:IsStudio() and 1 or C.Czasy.MinGraczy
	local odliczanie = C.Czasy.LobbyOdliczanie
	if RunService:IsStudio() then odliczanie = math.min(odliczanie, game:GetService("ServerStorage"):GetAttribute("TestOdliczanie") or 15) end
	local t = odliczanie
	while true do
		local n = #Players:GetPlayers()
		if n < minimum then
			t = odliczanie
			W.Gra:SetAttribute("Odliczanie", -1)
			W.Gra:SetAttribute("Brakuje", minimum - n)
		else
			W.Gra:SetAttribute("Brakuje", 0)
			W.Gra:SetAttribute("Odliczanie", t)
			if t <= 0 then break end
			t -= 1
		end
		task.wait(1)
	end
end

local function start()
	M.Swiat.zsiadzWszyscy()
	local lista = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(lista, p) end
	end
	if #lista == 0 then return false end
	for _, p in ipairs(lista) do
		R.gracze[p] = { rola = "Uczen", zyje = true, zadania = {}, zrobione = {}, dzwony = C.Czasy.DzwonowNaGracza, dyrektorMoc = true, ostatniaEliminacja = 0 }
	end
	przydzielRole(lista)
	for _, p in ipairs(lista) do przydzielZadania(p) end
	ustawFaze("Start")
	-- cutscenka autobusu (blokuje ~10 s)
	M.Swiat.cutscenkaAutobusu(lista)
	-- role
	local wspolnicy = {}
	for p, g in pairs(R.gracze) do if C.Role[g.rola].zly then table.insert(wspolnicy, p.DisplayName) end end
	for p, g in pairs(R.gracze) do
		W.ustawGrupe(p.Character, "Gracze")
		local d = { rola = g.rola, zadania = g.zadania, udawane = g.udawane, wspolnicy = C.Role[g.rola].zly and wspolnicy or nil }
		W.wyslij(p, "Rola", d)
		p:SetAttribute("Rola", nil) -- rola NIE jest publiczna
		R.odswiezPredkosc(p)
		M.Profil.Statystyka(p, "rundy")
	end
	return true
end

local function gra()
	ustawFaze("Gra")
	R.koniecCzasu = os.clock() + C.Czasy.Runda
	R.dzwonOd = os.clock() + C.Czasy.CooldownDzwonu
	W.Gra:SetAttribute("DzwonOd", workspace:GetServerTimeNow() + C.Czasy.CooldownDzwonu)
	R.wyslijPostep()
	M.Akcje.startRundy()
	M.Sabotaze.reset()
	M.Zadania.startRundy()
	while not R.zwyciezca do
		task.wait(0.5)
		if R.faza == "Gra" then
			local zostalo = R.koniecCzasu - os.clock()
			W.Gra:SetAttribute("Czas", math.max(0, math.floor(zostalo)))
			if zostalo <= 0 then
				R.wygrajZli("Zadzwonił dzwonek na koniec lekcji, a zadania nie są zrobione!")
			end
			R.sprawdzWygrana()
		end
		-- gracze, którzy wyszli
		for p in pairs(R.gracze) do if not p.Parent then R.gracze[p] = nil end end
		if next(R.gracze) == nil then R.zwyciezca = { strona = "nikt", powod = "Wszyscy wyszli." } end
	end
end

-- spotkanie wstrzymuje zegar rundy
function R.pauzaZegara(sek) R.koniecCzasu += sek end

local function koniec()
	local wynik = R.zwyciezca
	ustawFaze("Koniec")
	M.Sabotaze.reset()
	M.Akcje.koniecRundy()
	local lista = {}
	for p, g in pairs(R.gracze) do
		if p.Parent then
			local zly = C.Role[g.rola].zly
			local wygral = (wynik.strona == "zli" and zly) or (wynik.strona == "dobrzy" and not zly)
			table.insert(lista, { nick = p.DisplayName, id = p.UserId, rola = g.rola, zyje = g.zyje, wygral = wygral })
			local n = wygral and (zly and C.Nagrody.WygranaZli or C.Nagrody.WygranaDobrzy) or C.Nagrody.Przegrana
			M.Profil.Dodaj(p, n.zl, n.xp, wygral and "Wygrana runda!" or "Za udział w rundzie")
			if g.zyje and not zly then
				M.Profil.Dodaj(p, C.Nagrody.Przetrwanie.zl, C.Nagrody.Przetrwanie.xp, "Przetrwałeś lekcję")
			end
			if wygral then
				M.Profil.Statystyka(p, "wygrane")
				if zly then M.Profil.Statystyka(p, "wygraneZli") end
			end
		end
	end
	W.wszyscy("Koniec", { strona = wynik.strona, powod = wynik.powod, gracze = lista })
	task.wait(C.Czasy.KoniecRundy)
	for p in pairs(R.gracze) do if p.Parent then task.spawn(M.Profil.Zapisz, p) end end
end

local function postac(p)
	task.wait()
	local g = R.gracze[p]
	if not g then
		M.Swiat.doLobby(p)
	else
		-- odrodzenie w trakcie gry (np. spadł z mapy): wraca na plac szkoły
		local plac = workspace:FindFirstChild("Trasa") and workspace.Trasa:FindFirstChild("Plac")
		if plac then W.teleport(p, plac.Position) end
		W.ustawGrupe(p.Character, "Gracze")
		if not g.zyje then R.zrobDucha(p) end
	end
	R.odswiezPredkosc(p)
	M.Swiat.zalozPlecak(p)
end

function R.Start()
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function() postac(p) end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		p.CharacterAdded:Connect(function() postac(p) end)
	end
	Players.PlayerRemoving:Connect(function(p)
		if R.gracze[p] then
			R.gracze[p] = nil
			R.sprawdzWygrana()
			R.wyslijPostep()
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				lobby()
				if start() then
					gra()
					koniec()
				end
			end)
			if not ok then
				warn("[Gra] błąd w pętli rundy: " .. tostring(err))
				R.zwyciezca = nil
				task.wait(3)
			end
		end
	end)
end

return R
