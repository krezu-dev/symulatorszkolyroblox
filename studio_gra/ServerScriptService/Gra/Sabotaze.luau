-- Sabotaże Rozrabiaki: światło, drzwi, alarm pożarowy (krytyczny), niezapowiedziana kartkówka.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local S = {}
local W, C, M
local aktywne = {}      -- [typ] = { ... }
local ostatni = 0
local punktyNaprawy = {} -- [nazwa] = czesc

function S.krytyczny() return aktywne.Alarm ~= nil end

local function ustaw(typ, wartosc)
	W.Gra:SetAttribute("Sab_" .. typ, wartosc)
end

function S.reset()
	for typ in pairs(aktywne) do ustaw(typ, nil) end
	aktywne = {}
	ostatni = 0
	W.Gra:SetAttribute("SabotazOd", 0)
	for _, d in ipairs(CollectionService:GetTagged("SzkolaDrzwi")) do d:SetAttribute("Zablokowane", nil) end
end
function S.przedSpotkaniem()
	-- spotkanie kończy światło i drzwi (alarm blokuje dzwon, ale zgłoszenie ciała go kończy)
	for typ in pairs(aktywne) do ustaw(typ, nil) end
	aktywne = {}
	for _, d in ipairs(CollectionService:GetTagged("SzkolaDrzwi")) do d:SetAttribute("Zablokowane", nil) end
end

local function drzwiWszystkie(zamknij)
	local ev = ServerStorage:FindFirstChild("DrzwiUstaw")
	for _, d in ipairs(CollectionService:GetTagged("SzkolaDrzwi")) do
		if zamknij then
			if ev then ev:Fire(d, false) end
			d:SetAttribute("Zablokowane", true)
		else
			d:SetAttribute("Zablokowane", nil)
		end
	end
end

function S.uruchom(p, typ)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje or not C.Role[g.rola].zly then return end
	if not C.Sabotaze[typ] then return end
	if os.clock() < ostatni then return end
	if aktywne[typ] or aktywne.Alarm then return end
	ostatni = os.clock() + C.Czasy.CooldownSabotazu
	W.Gra:SetAttribute("SabotazOd", workspace:GetServerTimeNow() + C.Czasy.CooldownSabotazu)
	if typ == "Swiatlo" then
		aktywne.Swiatlo = true
		ustaw("Swiatlo", true)
		W.dzwiek2D("Pstryk", nil, 0.8)
		W.karteczka(nil, "AWARIA KORKÓW!", "Zgasło światło. Napraw bezpieczniki w kanciapie woźnej.", "czerwony")
	elseif typ == "Drzwi" then
		aktywne.Drzwi = true
		ustaw("Drzwi", true)
		drzwiWszystkie(true)
		W.karteczka(nil, "DRZWI ZAMKNIĘTE", "Ktoś zamknął wszystkie drzwi w szkole!", "czerwony")
		task.delay(C.Czasy.ZamknijDrzwiCzas, function()
			if aktywne.Drzwi then aktywne.Drzwi = nil ustaw("Drzwi", nil) drzwiWszystkie(false) end
		end)
	elseif typ == "Alarm" then
		local koniec = workspace:GetServerTimeNow() + C.Czasy.AlarmLimit
		aktywne.Alarm = { koniec = koniec, zrobione = {} }
		ustaw("Alarm", koniec)
		W.karteczka(nil, "ALARM POŻAROWY!", "Wyłączcie go w 2 miejscach: sekretariat i atrium liceum. Macie " .. C.Czasy.AlarmLimit .. " s!", "czerwony")
		task.spawn(function()
			local a = aktywne.Alarm
			while aktywne.Alarm == a do
				if workspace:GetServerTimeNow() >= a.koniec then
					aktywne.Alarm = nil
					ustaw("Alarm", nil)
					R.wygrajZli("Alarm pożarowy nie został wyłączony. Ewakuacja – lekcje odwołane!")
					break
				end
				task.wait(0.5)
			end
		end)
	elseif typ == "Kartkowka" then
		aktywne.Kartkowka = { czekaja = {} }
		for q, gq in pairs(R.gracze) do
			if gq.zyje and not C.Role[gq.rola].zly and q.Parent then
				aktywne.Kartkowka.czekaja[q] = true
				gq.zamrozony = true
				R.odswiezPredkosc(q)
				local pyt = C.Pytania.Matma[math.random(#C.Pytania.Matma)]
				W.wyslij(q, "Kartkowka", { pytanie = pyt, czas = C.Czasy.KartkowkaCzas })
			end
		end
		W.dzwiek2D("Gwizdek", nil, 0.7)
		task.delay(C.Czasy.KartkowkaCzas + 0.5, function()
			local k = aktywne.Kartkowka
			if not k then return end
			for q in pairs(k.czekaja) do
				local gq = R.info(q)
				if gq then gq.zamrozony = false R.odswiezPredkosc(q) end
			end
			aktywne.Kartkowka = nil
		end)
	end
	W.wyslij(p, "Cooldown", { klucz = "sabotaz", do_ = workspace:GetServerTimeNow() + C.Czasy.CooldownSabotazu })
end

function S.odpowiedzKartkowka(p, ok)
	local k = aktywne.Kartkowka
	if not k or not k.czekaja[p] then return end
	k.czekaja[p] = nil
	local g = M.Runda.info(p)
	if g then g.zamrozony = false M.Runda.odswiezPredkosc(p) end
	if ok then W.dzwiek2D("Sukces", p, 0.5) else W.dzwiek2D("Blad", p, 0.5) end
end

-- naprawy: punkt = "Bezpieczniki" | "Alarm1" | "Alarm2"
function S.napraw(p, punkt, ok)
	local R = M.Runda
	local g = R.info(p)
	if R.faza ~= "Gra" or not g or not g.zyje or not ok then return end
	local czesc = punktyNaprawy[punkt]
	if not czesc or W.dystans(p, czesc.Position) > 16 then return end
	if punkt == "Bezpieczniki" and aktywne.Swiatlo then
		aktywne.Swiatlo = nil
		ustaw("Swiatlo", nil)
		W.dzwiek2D("Pstryk", nil, 0.8)
		W.karteczka(nil, "Światło wróciło", p.DisplayName .. " naprawił korki.", "zielony")
	elseif (punkt == "Alarm1" or punkt == "Alarm2") and aktywne.Alarm then
		aktywne.Alarm.zrobione[punkt] = true
		W.Gra:SetAttribute("Sab_" .. punkt, true)
		if aktywne.Alarm.zrobione.Alarm1 and aktywne.Alarm.zrobione.Alarm2 then
			aktywne.Alarm = nil
			ustaw("Alarm", nil)
			W.Gra:SetAttribute("Sab_Alarm1", nil)
			W.Gra:SetAttribute("Sab_Alarm2", nil)
			W.karteczka(nil, "Alarm wyłączony", "Uff... Fałszywy alarm.", "zielony")
		end
	end
end

function S.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end
function S.Start()
	local f = W.Mapa:FindFirstChild("Naprawy")
	if f then
		for _, c in ipairs(f:GetChildren()) do
			if c:IsA("BasePart") then punktyNaprawy[c.Name] = c end
		end
	end
	for nazwa, czesc in pairs(punktyNaprawy) do
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "PromptNaprawa"
		pr.ActionText = nazwa == "Bezpieczniki" and "Napraw bezpieczniki" or "Wyłącz alarm"
		pr.ObjectText = nazwa == "Bezpieczniki" and "Skrzynka" or "Panel alarmu"
		pr.MaxActivationDistance = 9
		pr.RequiresLineOfSight = false
		pr.Enabled = false -- klient włącza, gdy sabotaż trwa
		pr:SetAttribute("Naprawa", nazwa)
		pr.Parent = czesc
		CollectionService:AddTag(pr, "PromptNaprawa")
	end
end

return S
