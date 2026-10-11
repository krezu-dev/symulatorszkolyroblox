-- Śmieszne postacie NPC: chodzą po szkole i lobby, gadają, reagują na trafienie przedmiotem.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

local N = {}
local W, C, M

local DEF = {
	{
		nazwa = "Pani Halinka (woźna)", skora = Color3.fromRGB(234, 192, 160), gora = Color3.fromRGB(120, 80, 160), dol = Color3.fromRGB(60, 60, 80),
		rekwizyt = "mop", szybkosc = 7,
		trasa = { Vector3.new(-90, 11, 0), Vector3.new(-30, 11, 1), Vector3.new(30, 11, -1), Vector3.new(95, 11, 0) },
		teksty = { "Kto znowu nachlapał kompotem?!", "Po mytym nie chodzić!", "Kapcie! Gdzie są kapcie?!", "Za moich czasów to się szanowało szkołę.", "Ja tu jestem od 1987 roku, kochaneczku." },
	},
	{
		nazwa = "Pan Zbyszek od WF", skora = Color3.fromRGB(220, 170, 130), gora = Color3.fromRGB(200, 30, 40), dol = Color3.fromRGB(30, 30, 120),
		rekwizyt = "gwizdek", szybkosc = 10, gwizdze = true,
		trasa = { Vector3.new(120, 1, -30), Vector3.new(165, 1, -30), Vector3.new(165, 1, 30), Vector3.new(120, 1, 30) },
		teksty = { "Jeszcze pięć okrążeń!", "Kto nie ma stroju, ten ćwiczy w tym, co ma!", "Za moich czasów to się biegało w śniegu!", "Dwa ognie na ostatniej lekcji? Zobaczymy...", "Zwolnienie od mamy? Akurat." },
	},
	{
		nazwa = "Pani Krysia ze sklepiku", skora = Color3.fromRGB(240, 200, 170), gora = Color3.fromRGB(240, 240, 240), dol = Color3.fromRGB(70, 70, 70),
		rekwizyt = "fartuch", szybkosc = 0, stoi = "Wystroj.Sklepik.Lada",
		teksty = { "Drożdżówki się skończyły.", "Wydać nie mam, masz drobne?", "Hot-dog dopiero po trzeciej lekcji.", "Tylko jeden lizak na osobę!", "Kubuś? Jest. Ciepły, ale jest." },
	},
	{
		nazwa = "Kujon Staś", skora = Color3.fromRGB(250, 220, 190), gora = Color3.fromRGB(90, 140, 90), dol = Color3.fromRGB(110, 90, 70),
		rekwizyt = "ksiazka", szybkosc = 6,
		trasa = { Vector3.new(-70, 27, 150), Vector3.new(-45, 27, 160), Vector3.new(-60, 27, 147) },
		teksty = { "A pani nie zadała nic na jutro!", "Czy ktoś wie, czy będzie kartkówka? Bo ja się uczyłem.", "Pi to 3,14159265...", "Mogę wyjść do tablicy?", "Przeczytałem całego „Pana Tadeusza”. Dwa razy." },
	},
	{
		nazwa = "Policjant Mirek", skora = Color3.fromRGB(230, 180, 150), gora = Color3.fromRGB(30, 50, 110), dol = Color3.fromRGB(25, 30, 60),
		rekwizyt = "czapka", szybkosc = 8, lobby = true,
		trasa = { "Lobby.Punkty.P1", "Lobby.Punkty.P2", "Lobby.Punkty.P3" },
		teksty = { "Masz prawo jazdy na hulajnogę?", "Proszę nie rzucać piłką w radiowóz.", "Dokumenty do kontroli! Legitymacja wystarczy.", "Autobus do szkoły zaraz będzie.", "Mandat za bieganie po korytarzu: 5 zł." },
	},
	{
		nazwa = "Pani Basia od matmy", skora = Color3.fromRGB(240, 205, 180), gora = Color3.fromRGB(180, 60, 90), dol = Color3.fromRGB(40, 40, 50),
		rekwizyt = "dziennik", szybkosc = 6,
		trasa = { Vector3.new(-80, 27, 0), Vector3.new(0, 27, 2), Vector3.new(80, 27, -1) },
		teksty = { "2 + 2 to cztery. Zawsze. Nawet w piątek.", "Kartkówka! Karteczki wyjąć!", "Kto się nie nauczył, ten się nie zgłasza.", "Dzwonek jest dla nauczyciela!", "Nie liczymy na palcach!" },
	},
}

local function podloga(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace:FindFirstChild("NPC") }
	local r = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
	return r and r.Position or pos
end

local function rekwizyt(model, rodzaj)
	local reka = model:FindFirstChild("RightHand")
	local tulow = model:FindFirstChild("UpperTorso")
	local glowa = model:FindFirstChild("Head")
	local function part(size, kolor, cf, rodzic, mat)
		local p = Instance.new("Part")
		p.Size = size p.Color = kolor p.Material = mat or Enum.Material.SmoothPlastic
		p.CanCollide = false p.Massless = true p.CanQuery = false
		p.CFrame = rodzic.CFrame * cf
		local w = Instance.new("WeldConstraint") w.Part0 = rodzic w.Part1 = p w.Parent = p
		p.Parent = model
		return p
	end
	if rodzaj == "mop" and reka then
		part(Vector3.new(0.2, 5, 0.2), Color3.fromRGB(150, 110, 70), CFrame.new(0, -0.5, -0.4), reka, Enum.Material.Wood)
		part(Vector3.new(1.4, 0.4, 0.8), Color3.fromRGB(230, 230, 220), CFrame.new(0, -3, -0.4), reka, Enum.Material.Fabric)
	elseif rodzaj == "gwizdek" and tulow then
		part(Vector3.new(0.3, 0.2, 0.4), Color3.fromRGB(200, 200, 210), CFrame.new(0, 0.4, -0.6), tulow, Enum.Material.Metal)
	elseif rodzaj == "fartuch" and tulow then
		part(Vector3.new(1.9, 1.8, 0.1), Color3.fromRGB(250, 250, 250), CFrame.new(0, -0.3, -0.55), tulow, Enum.Material.Fabric)
	elseif (rodzaj == "ksiazka" or rodzaj == "dziennik") and reka then
		part(Vector3.new(1.1, 1.4, 0.3), rodzaj == "ksiazka" and Color3.fromRGB(40, 80, 160) or Color3.fromRGB(30, 90, 50), CFrame.new(0, -0.6, -0.3), reka)
	elseif rodzaj == "czapka" and glowa then
		part(Vector3.new(1.4, 0.5, 1.4), Color3.fromRGB(25, 35, 80), CFrame.new(0, 0.75, 0), glowa)
		part(Vector3.new(1.4, 0.1, 0.6), Color3.fromRGB(15, 15, 20), CFrame.new(0, 0.55, -0.85), glowa)
	end
end

local function powiedz(model, tekst)
	W.wszyscy("Dymek", { npc = model, tekst = tekst })
end

local function zrobNPC(def)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = def.skora desc.LeftArmColor = def.skora desc.RightArmColor = def.skora
	desc.TorsoColor = def.gora desc.LeftLegColor = def.dol desc.RightLegColor = def.dol
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok or not model then return end
	model.Name = def.nazwa
	model:SetAttribute("NPC", true)
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = def.nazwa
	hum.WalkSpeed = def.szybkosc
	hum.NameDisplayDistance = 40
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	-- start
	local start
	if def.stoi then
		local o = W.znajdz(def.stoi)
		local pos = W.pozycja(o)
		if pos then start = podloga(pos + Vector3.new(-2.5, 0, 0)) end
	elseif def.trasa then
		local t = def.trasa[1]
		if typeof(t) == "string" then
			local o = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Punkty") and workspace.Lobby.Punkty:FindFirstChild(string.match(t, "[^%.]+$"))
			start = o and o.Position
		else
			start = podloga(t)
		end
	end
	if not start then return end
	model:PivotTo(CFrame.new(start + Vector3.new(0, 3, 0)))
	model.Parent = workspace:FindFirstChild("NPC")
	rekwizyt(model, def.rekwizyt)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.CollisionGroup = "Ciala" end -- nie blokują graczy w drzwiach
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	pcall(function() hrp:SetNetworkOwner(nil) end)
	-- rozmowa
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Pogadaj"
	pr.ObjectText = def.nazwa
	pr.MaxActivationDistance = 9
	pr.KeyboardKeyCode = Enum.KeyCode.F
	pr.RequiresLineOfSight = false
	pr.Parent = hrp
	pr.Triggered:Connect(function()
		powiedz(model, def.teksty[math.random(#def.teksty)])
	end)
	-- chodzenie po trasie
	local punkty = {}
	if def.trasa and not def.stoi then
		for _, t in ipairs(def.trasa) do
			if typeof(t) == "string" then
				local o = workspace.Lobby.Punkty:FindFirstChild(string.match(t, "[^%.]+$"))
				if o then table.insert(punkty, o.Position) end
			else
				table.insert(punkty, podloga(t))
			end
		end
	end
	task.spawn(function()
		local i = 1
		local ostatniTekst = os.clock()
		while model.Parent do
			-- trafiony przedmiotem?
			local tr = model:GetAttribute("Trafiony")
			if tr and os.clock() - tr < 0.5 then
				model:SetAttribute("Trafiony", nil)
				local zle = { "AŁA!", "Kto to rzucił?!", "Do dyrektora z tym!", "Uwaga, bo wpiszę uwagę!" }
				powiedz(model, zle[math.random(#zle)])
			end
			if os.clock() - ostatniTekst > math.random(18, 35) then
				ostatniTekst = os.clock()
				powiedz(model, def.teksty[math.random(#def.teksty)])
				if def.gwizdze then W.dzwiek("Gwizdek", hrp, 0.7, 90) end
			end
			if #punkty > 1 and def.szybkosc > 0 then
				local cel = punkty[i]
				local sciezka = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
				local ok2 = pcall(function() sciezka:ComputeAsync(hrp.Position, cel) end)
				if ok2 and sciezka.Status == Enum.PathStatus.Success then
					for _, wp in ipairs(sciezka:GetWaypoints()) do
						if not model.Parent then return end
						hum:MoveTo(wp.Position)
						local doszedl = hum.MoveToFinished:Wait()
						if not doszedl then break end
					end
				else
					hum:MoveTo(cel)
					hum.MoveToFinished:Wait()
				end
				i = i % #punkty + 1
				task.wait(math.random(2, 5))
			else
				task.wait(2)
			end
		end
	end)
	return model
end

function N.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end
function N.Start()
	local f = workspace:FindFirstChild("NPC") or Instance.new("Folder")
	f.Name = "NPC"
	f.Parent = workspace
	for _, def in ipairs(DEF) do
		task.spawn(function()
			local ok, err = pcall(zrobNPC, def)
			if not ok then warn("[NPC] " .. def.nazwa .. ": " .. tostring(err)) end
		end)
	end
end

return N
