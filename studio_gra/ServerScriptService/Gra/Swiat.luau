-- Świat: lobby w komisariacie, autobus i brama, hulajnogi, rzucanie przedmiotami, kamery, plecaki na postaci.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local S = {}
local W, C, M
local lobby, autobus, brama
local trzymane = {}   -- [player] = część
local hulajnogi = {}  -- [player] = model
local widzowie = {}   -- kamery

------------------------------------------------------------------ LOBBY
function S.doLobby(p)
	if not lobby then return end
	local spawny = lobby:FindFirstChild("Spawny")
	local lista = spawny and spawny:GetChildren() or {}
	if #lista == 0 then return end
	local s = lista[math.random(#lista)]
	local ch = p.Character or p.CharacterAdded:Wait()
	local hrp = ch:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		hrp.Anchored = false
		ch:PivotTo(s.CFrame + Vector3.new(math.random(-3, 3), 3.5, math.random(-3, 3)))
	end
	ch:SetAttribute("Duch", nil)
end

------------------------------------------------------------------ PLECAK NA POSTACI
function S.zalozPlecak(p)
	local ch = p.Character
	if not ch then return end
	local d = M.Profil.Get(p)
	if not d then return end
	local tulow = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	if not tulow then return end
	local stary = ch:FindFirstChild("PlecakSkin")
	if stary then stary:Destroy() end
	local def
	for _, x in ipairs(C.Plecaki) do if x.id == d.plecak then def = x end end
	if not def then return end
	local m = Instance.new("Model")
	m.Name = "PlecakSkin"
	local function czesc(nazwa, size, off, kolor, mat)
		local c = Instance.new("Part")
		c.Name = nazwa
		c.Size = size
		c.Color = kolor
		c.Material = mat or Enum.Material.Fabric
		c.CanCollide = false
		c.CanQuery = false
		c.CanTouch = false
		c.Massless = true
		c.CFrame = tulow.CFrame * off
		local w = Instance.new("WeldConstraint")
		w.Part0 = tulow
		w.Part1 = c
		w.Parent = c
		c.Parent = m
		return c
	end
	local kol = def.kolor
	local ciemny = Color3.new(kol.R * 0.6, kol.G * 0.6, kol.B * 0.6)
	if def.id == "Teczka" then
		czesc("Korpus", Vector3.new(1.6, 1.2, 0.5), CFrame.new(0, -0.1, 0.8), kol, Enum.Material.Leather)
		czesc("Zapiecie", Vector3.new(0.3, 0.3, 0.1), CFrame.new(0, 0.2, 1.08), Color3.fromRGB(200, 170, 60), Enum.Material.Metal)
	elseif def.id == "WorekKapcie" then
		czesc("Korpus", Vector3.new(1.3, 1.5, 0.45), CFrame.new(0, -0.1, 0.75), kol)
		czesc("Sznurek", Vector3.new(0.08, 1.7, 0.08), CFrame.new(0.55, 0.1, 0.45) * CFrame.Angles(0, 0, 0.25), Color3.fromRGB(40, 40, 40))
	else
		local k = czesc("Korpus", Vector3.new(1.5, 1.7, 0.7), CFrame.new(0, 0, 0.85), kol, def.neon and Enum.Material.Neon or Enum.Material.Fabric)
		czesc("Kieszen", Vector3.new(1.1, 0.7, 0.25), CFrame.new(0, -0.4, 1.3), ciemny)
		czesc("Klapa", Vector3.new(1.52, 0.35, 0.72), CFrame.new(0, 0.7, 0.86), ciemny)
		if def.rgb then k:SetAttribute("RGB", true) CollectionService:AddTag(k, "PlecakRGB") end
	end
	m.Parent = ch
end

------------------------------------------------------------------ AUTOBUS + BRAMA
local function przesunBrame(otworz)
	if not brama then return end
	-- dwa skrzydła obracają się na zawiasach do środka (w stronę szkoły)
	for _, c in ipairs(brama) do
		if c.skrzydlo then
			local v = Instance.new("NumberValue")
			v.Value = otworz and 0 or 1
			local zawias = c.zawias
			local kat = c.kat
			local con = v.Changed:Connect(function(e)
				c.czesc.CFrame = zawias * CFrame.Angles(0, math.rad(kat * e), 0) * zawias:Inverse() * c.zamk
			end)
			local tw = TweenService:Create(v, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Value = otworz and 1 or 0 })
			tw:Play()
			tw.Completed:Connect(function() con:Disconnect() v:Destroy() end)
		else
			c.czesc.CanCollide = (not otworz) and c.kolizja or false
		end
	end
end

function S.cutscenkaAutobusu(lista)
	if not autobus then return end
	local trasa = workspace:FindFirstChild("Trasa")
	local start = trasa and trasa:FindFirstChild("Start")
	local stop = trasa and trasa:FindFirstChild("Stop")
	local koniec = trasa and trasa:FindFirstChild("Koniec")
	local drzwi = trasa and trasa:FindFirstChild("Drzwi")
	local brama1 = trasa and trasa:FindFirstChild("Brama")
	local plac = trasa and trasa:FindFirstChild("Plac")
	if not (start and stop and koniec and drzwi and brama1 and plac) then return end
	-- gracze „w autobusie”: ukryci i zakotwiczeni przy drzwiach
	local schowani = {}
	for _, p in ipairs(lista) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			ch:PivotTo(drzwi.CFrame + Vector3.new(0, -40, 0))
			hrp.Anchored = true
			schowani[p] = true
		end
	end
	autobus:PivotTo(start.CFrame)
	autobus.Parent = workspace
	W.wszyscy("Cutscenka", { etap = "autobus", autobus = autobus, czas = 4, brama = brama1.Position, drzwi = drzwi.Position })
	local silnik = W.dzwiek("Autobus", autobus.PrimaryPart, 1, 300)
	-- jazda: tween wartości i PivotTo (model z wieloma częściami)
	local function jedz(od, do_, czas, styl)
		local v = Instance.new("CFrameValue")
		v.Value = od
		local con = v.Changed:Connect(function(cf) autobus:PivotTo(cf) end)
		local tw = TweenService:Create(v, TweenInfo.new(czas, styl or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = do_ })
		tw:Play()
		tw.Completed:Wait()
		con:Disconnect()
		v:Destroy()
	end
	jedz(start.CFrame, stop.CFrame, 4)
	W.dzwiek("DrzwiAutobusu", autobus.PrimaryPart, 1, 200)
	przesunBrame(true)
	W.wszyscy("Cutscenka", { etap = "wysiadka", czas = 4.5, brama = brama1.Position, drzwi = drzwi.Position })
	local i = 0
	for _, p in ipairs(lista) do
		if schowani[p] and p.Character then
			i += 1
			local ch = p.Character
			local hrp = ch:FindFirstChild("HumanoidRootPart")
			local hum = ch:FindFirstChildOfClass("Humanoid")
			ch:PivotTo(drzwi.CFrame + Vector3.new(0, 3, 0))
			hrp.Anchored = false
			local cel = plac.Position + Vector3.new(math.random(-14, 14), 0, math.random(-6, 6))
			-- chodzenie robi klient (to on steruje swoją postacią)
			W.wyslij(p, "IdzDo", { punkty = { brama1.Position, cel } })
			task.wait(0.22)
		end
	end
	task.wait(math.max(0.5, 3.6 - i * 0.22))
	przesunBrame(false)
	W.wszyscy("Cutscenka", { etap = "brama", czas = 1.6, brama = brama1.Position })
	task.spawn(function()
		jedz(stop.CFrame, koniec.CFrame, 3, Enum.EasingStyle.Quad)
		if silnik then silnik:Stop() end
		autobus.Parent = game:GetService("ServerStorage")
	end)
	task.wait(1.6)
	W.wszyscy("Cutscenka", { etap = "koniec" })
end

------------------------------------------------------------------ HULAJNOGI
function S.hulajnoga(p, wsiadz)
	local g = M.Runda.info(p)
	local faza = M.Runda.faza
	if faza == "Spotkanie" or faza == "Start" then return end
	if g and (g.niesie or g.wKratce or g.wKryjowce or g.zamrozony) then return end
	local stara = hulajnogi[p]
	if stara then
		stara:Destroy()
		hulajnogi[p] = nil
		local _, humS = W.hrp(p)
		if humS and p:GetAttribute("HipPrzed") then humS.HipHeight = p:GetAttribute("HipPrzed") end
		p:SetAttribute("HipPrzed", nil)
		p:SetAttribute("NaHulajnodze", nil)
		M.Runda.odswiezPredkosc(p)
		if not wsiadz then return end
		return
	end
	if wsiadz == false then return end
	local d = M.Profil.Get(p)
	local def
	for _, x in ipairs(C.Hulajnogi) do if x.id == (d and d.hulajnoga) then def = x end end
	def = def or C.Hulajnogi[1]
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	local wzor = game:GetService("ServerStorage"):FindFirstChild("PrefabHulajnoga")
	local m
	if wzor then
		m = wzor:Clone()
	else
		m = Instance.new("Model")
		local deska = Instance.new("Part") deska.Name = "Deska" deska.Size = Vector3.new(1, 0.25, 4) deska.Parent = m
		m.PrimaryPart = deska
	end
	for _, c in ipairs(m:GetDescendants()) do
		if c:IsA("BasePart") then
			c.Anchored = false
			c.CanCollide = false
			c.CanQuery = false
			c.Massless = true
			if c.Name == "Rama" or c.Name == "Deska" or c:GetAttribute("Kolor") then c.Color = def.kolor end
		end
	end
	-- stoisz NA desce: postać idzie w górę o grubość deski, deska pod stopami, kierownica przed tobą
	local DESKA = 0.55
	p:SetAttribute("HipPrzed", hum.HipHeight)
	local stopy = -(hum.HipHeight + hrp.Size.Y / 2)
	hum.HipHeight += DESKA
	hrp.CFrame += Vector3.new(0, DESKA, 0)
	m:PivotTo(hrp.CFrame * CFrame.new(0, stopy - DESKA + 0.05, -0.6))
	for _, c in ipairs(m:GetDescendants()) do
		if c:IsA("BasePart") then
			local w = Instance.new("WeldConstraint") w.Part0 = hrp w.Part1 = c w.Parent = c
		end
	end
	m.Name = "Hulajnoga"
	m.Parent = ch
	hulajnogi[p] = m
	p:SetAttribute("NaHulajnodze", def.predkosc)
	hum.WalkSpeed = def.predkosc
	W.dzwiek("Pstryk", hrp, 0.6, 30)
end
function S.zsiadzWszyscy()
	for p in pairs(hulajnogi) do S.hulajnoga(p, false) end
end

------------------------------------------------------------------ RZUCANIE
function S.chwyc(p, obiekt)
	if typeof(obiekt) ~= "Instance" or not obiekt:IsA("BasePart") or not CollectionService:HasTag(obiekt, "Rzucalne") then return end
	if trzymane[p] then return end
	if obiekt:GetAttribute("Trzyma") then return end
	if M.Runda.faza == "Spotkanie" then return end
	local g = M.Runda.info(p)
	if g and (g.niesie or g.wKratce or g.zamrozony) then return end
	if W.dystans(p, obiekt.Position) > 10 then return end
	local ch = p.Character
	local reka = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	if not reka then return end
	obiekt:SetAttribute("Trzyma", p.UserId)
	obiekt.Anchored = false
	obiekt.CanCollide = false
	obiekt.Massless = true
	obiekt.CFrame = reka.CFrame * CFrame.new(0, -0.6 - obiekt.Size.Y / 2, 0)
	local w = Instance.new("WeldConstraint") w.Name = "Chwyt" w.Part0 = reka w.Part1 = obiekt w.Parent = obiekt
	trzymane[p] = obiekt
	W.wyslij(p, "Trzyma", { obiekt = obiekt })
end
function S.rzuc(p, kierunek)
	local o = trzymane[p]
	if not o then return end
	trzymane[p] = nil
	local w = o:FindFirstChild("Chwyt") if w then w:Destroy() end
	o.Massless = false
	o.CanCollide = true
	if typeof(kierunek) ~= "Vector3" then kierunek = Vector3.new(0, 0, -1) end
	kierunek = kierunek.Unit
	local hrp = W.hrp(p)
	if hrp then o.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 1.5, 0) + kierunek * 2.5) end
	o:SetNetworkOwner(nil)
	o.AssemblyLinearVelocity = kierunek * 85 + Vector3.new(0, 18, 0)
	o.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
	o:SetAttribute("Trzyma", nil)
	o:SetAttribute("Rzucil", p.UserId)
	o:SetAttribute("RzutCzas", os.clock())
	W.dzwiek("Rzut", o, 0.7, 50)
	W.wyslij(p, "Trzyma", { obiekt = nil })
end
local function trafienie(o, hit)
	local t = o:GetAttribute("RzutCzas")
	if not t or os.clock() - t > 2 then return end
	local ch = hit:FindFirstAncestorOfClass("Model")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum or ch:GetAttribute("Duch") then return end
	local kto = Players:GetPlayerFromCharacter(ch)
	if kto and kto.UserId == o:GetAttribute("Rzucil") then return end
	o:SetAttribute("RzutCzas", nil)
	W.dzwiek("Cios", o, 0.8, 50)
	W.wszyscy("Efekt", { typ = "bonk", pos = o.Position })
	if M.Runda.faza ~= "Spotkanie" then
		hum.PlatformStand = true
		task.delay(1.2, function() if hum.Parent then hum.PlatformStand = false end end)
	end
	if ch:GetAttribute("NPC") then ch:SetAttribute("Trafiony", os.clock()) end
end

------------------------------------------------------------------ KAMERY (radiowęzeł)
function S.kamery(p, w)
	local g = M.Runda.info(p)
	if w then
		if M.Runda.faza ~= "Gra" or (g and not g.zyje) then return end
		widzowie[p] = true
	else
		widzowie[p] = nil
	end
	local n = 0
	for q in pairs(widzowie) do if q.Parent then n += 1 end end
	W.Gra:SetAttribute("KameryOgladane", n)
end

function S.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end
function S.Start()
	lobby = workspace:FindFirstChild("Lobby")
	autobus = game:GetService("ServerStorage"):FindFirstChild("Autobus")
	-- brama: dwa skrzydła (pręty + rama + kłódka), blokada wyłączana przy otwarciu
	local b = W.znajdz("Otoczenie.Ogrodzenie.Brama")
	if b then
		brama = {}
		for _, d in ipairs(b:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.Name == "Pret" or string.sub(d.Name, 1, 4) == "Rama" or d.Name == "Klodka" then
					local lewe = d.Position.X <= 0.05
					local zawias = CFrame.new(lewe and -8 or 8, d.Position.Y, d.Position.Z)
					table.insert(brama, { czesc = d, zamk = d.CFrame, skrzydlo = true, zawias = zawias, kat = lewe and -100 or 100 })
					d.Anchored = true
				elseif d.Name == "BlokadaBramy" then
					table.insert(brama, { czesc = d, kolizja = d.CanCollide })
				end
			end
		end
	end
	-- dziura w niewidzialnej ścianie przy bramie (brama sama blokuje, gdy zamknięta)
	local ns = W.Mapa:FindFirstChild("NiewidzialneSciany")
	if ns then
		for _, g in ipairs(ns:GetChildren()) do
			if g:IsA("BasePart") and g.Size.X > 200 and g.Position.Z < -100 and not g:GetAttribute("Podzielona") then
				local x0, x1 = g.Position.X - g.Size.X / 2, g.Position.X + g.Size.X / 2
				local l = g:Clone() l.Size = Vector3.new(-9 - x0, g.Size.Y, g.Size.Z) l.Position = Vector3.new((x0 - 9) / 2, g.Position.Y, g.Position.Z) l:SetAttribute("Podzielona", true) l.Parent = ns
				local p = g:Clone() p.Size = Vector3.new(x1 - 9, g.Size.Y, g.Size.Z) p.Position = Vector3.new((x1 + 9) / 2, g.Position.Y, g.Position.Z) p:SetAttribute("Podzielona", true) p.Parent = ns
				g:Destroy()
			end
		end
	end
	for _, o in ipairs(CollectionService:GetTagged("Rzucalne")) do
		if o:IsA("BasePart") then
			o.Touched:Connect(function(hit) trafienie(o, hit) end)
			o:SetAttribute("Start", o.Position)
		end
	end
	CollectionService:GetInstanceAddedSignal("Rzucalne"):Connect(function(o)
		if o:IsA("BasePart") then o.Touched:Connect(function(hit) trafienie(o, hit) end) end
	end)
	-- przedmioty, które spadły z mapy, wracają
	task.spawn(function()
		while true do
			task.wait(10)
			for _, o in ipairs(CollectionService:GetTagged("Rzucalne")) do
				local s = o:GetAttribute("Start")
				if s and o.Position.Y < -30 and not o:GetAttribute("Trzyma") then
					o.AssemblyLinearVelocity = Vector3.zero
					o.CFrame = CFrame.new(s)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if trzymane[p] then S.rzuc(p, Vector3.new(0, -1, 0)) end
		if hulajnogi[p] then hulajnogi[p]:Destroy() hulajnogi[p] = nil end
		widzowie[p] = nil
	end)
end

return S
