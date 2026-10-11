-- Zadania: punkty w salach (ProximityPrompt), start minigry u klienta, weryfikacja i nagrody.
local CollectionService = game:GetService("CollectionService")

local Z = {}
local W, C, M
local punkty = {}      -- [id] = { obiekt, czesc, prompt }
local otwarte = {}     -- [player] = { id, czas }

function Z.dostepne(id) return punkty[id] ~= nil end
function Z.pozycja(id) local p = punkty[id] return p and W.pozycja(p.obiekt) end

local function minimalnyCzas(p, def)
	if def.typ == "trzymaj" then return def.p.czas * M.Profil.mnoznikTrzymania(p) - 0.6 end
	if def.typ == "klikanie" then return 1.5 end
	return 1.0
end

local function zbuduj()
	-- stare prompty z poprzedniej wersji mapy
	for _, o in ipairs(CollectionService:GetTagged("SzkolaZadanie")) do
		if o:IsA("ProximityPrompt") then o:Destroy() else CollectionService:RemoveTag(o, "SzkolaZadanie") end
	end
	for id, def in pairs(W.C.Zadania) do
		local o = W.znajdz(def.obiekt)
		local czesc = W.pierwszaCzesc(o)
		if o and czesc then
			local pr = Instance.new("ProximityPrompt")
			pr.Name = "PromptZadania"
			pr.ActionText = def.nazwa
			pr.ObjectText = def.gdzie
			pr.KeyboardKeyCode = Enum.KeyCode.E
			pr.MaxActivationDistance = 9
			pr.RequiresLineOfSight = false
			pr.HoldDuration = 0
			pr.Style = Enum.ProximityPromptStyle.Default
			pr.Enabled = true
			pr:SetAttribute("Zadanie", id)
			pr.Parent = czesc
			CollectionService:AddTag(pr, "PromptZadania")
			punkty[id] = { obiekt = o, czesc = czesc, prompt = pr }
			pr.Triggered:Connect(function(p) Z.otworz(p, id) end)
			o:SetAttribute("ZadanieId", id)
		else
			warn("[Zadania] nie znaleziono obiektu dla " .. id .. " (" .. def.obiekt .. ")")
		end
	end
	W.Gra:SetAttribute("ZadaniaGotowe", true)
end

function Z.otworz(p, id)
	local R = M.Runda
	if R.faza ~= "Gra" then return end
	local g = R.info(p)
	if not g or g.zamrozony or g.wKratce then return end
	if not table.find(g.zadania, id) or g.zrobione[id] then return end
	if W.dystans(p, W.pozycja(punkty[id].obiekt)) > 18 then return end
	otwarte[p] = { id = id, czas = os.clock() }
	local def = W.C.Zadania[id]
	W.wyslij(p, "ZadanieOtworz", { id = id, mnoznik = M.Profil.mnoznikTrzymania(p) })
	-- Rozrabiaka może „udawać” zadanie, ale wtedy stoi przy nim jak inni
	if def then
		local czesc = punkty[id].czesc
		p.Character:SetAttribute("RobiZadanie", id)
	end
end

function Z.zakoncz(p, id, sukces)
	local R = M.Runda
	local o = otwarte[p]
	otwarte[p] = nil
	if p.Character then p.Character:SetAttribute("RobiZadanie", nil) end
	if not sukces or not o or o.id ~= id then return end
	local g = R.info(p)
	if not g or g.zrobione[id] or R.faza ~= "Gra" then return end
	local def = W.C.Zadania[id]
	if os.clock() - o.czas < minimalnyCzas(p, def) then return end
	if W.dystans(p, W.pozycja(punkty[id].obiekt)) > 22 then return end
	g.zrobione[id] = true
	W.wyslij(p, "ZadanieZrobione", { id = id })
	if not g.udawane then
		local n = W.C.Nagrody.Zadanie
		-- COMBO: kolejne zadanie w ciągu 45 s daje mnożnik (max x3)
		local teraz = os.clock()
		if g.ostatnieZadanie and teraz - g.ostatnieZadanie < 45 then g.combo = math.min(3, (g.combo or 1) + 1) else g.combo = 1 end
		g.ostatnieZadanie = teraz
		local mn = g.combo
		if g.szczesliwy then mn += 1 end
		if g.combo > 1 then W.wyslij(p, "Combo", { x = g.combo }) end
		M.Profil.Dodaj(p, n.zl * mn, n.xp * mn, "Zadanie: " .. def.nazwa)
		M.Profil.Statystyka(p, "zadania")
		R.wyslijPostep()
		R.sprawdzWygrana()
		W.dzwiek("Sukces", punkty[id].czesc, 0.5, 25)
	end
end

function Z.anuluj(p)
	otwarte[p] = nil
	if p.Character then p.Character:SetAttribute("RobiZadanie", nil) end
end

function Z.startRundy()
	otwarte = {}
end

function Z.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end
function Z.Start()
	zbuduj()
end

return Z
