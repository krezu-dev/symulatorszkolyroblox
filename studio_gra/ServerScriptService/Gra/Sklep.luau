-- Sklep za Robuxy: gamepassy (VIP, memy, tańce, efekty, hulajnogi) i produkty (złotówki, bilet Rozrabiaki).
-- ID są w Config (Gamepassy/Produkty). Gdy ID = 0, w Studio zakup działa testowo (bez płacenia).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local S = {}
local W, C, M

-- ma gamepass? (atrybut na graczu: GP_<klucz>)
function S.ma(p, klucz)
	return p:GetAttribute("GP_" .. klucz) == true
end

local function nadajPass(p, klucz, nowy)
	p:SetAttribute("GP_" .. klucz, true)
	local d = M.Profil.Get(p)
	if d then
		d.passy = d.passy or {}
		d.passy[klucz] = true -- zapis (dla testów w Studio i szybkiego startu)
	end
	if klucz == "VIP" then S.znaczekVIP(p) end
	W.wyslij(p, "Gamepass", { klucz = klucz, nowy = nowy })
	M.Profil.wyslij(p)
end

local function sprawdzPassy(p)
	local d = M.Profil.Get(p)
	for klucz, gp in pairs(C.Gamepassy) do
		local ma = false
		if gp.id ~= 0 then
			local ok, w = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(p.UserId, gp.id) end)
			ma = ok and w
		elseif d and d.passy and d.passy[klucz] then
			ma = true -- kupione testowo w Studio
		end
		if ma then nadajPass(p, klucz) end
	end
end

-- znaczek VIP nad głową
function S.znaczekVIP(p)
	local ch = p.Character
	local glowa = ch and ch:FindFirstChild("Head")
	if not glowa or glowa:FindFirstChild("VIPZnaczek") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "VIPZnaczek"
	bb.Size = UDim2.fromScale(2.6, 0.9)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 60
	bb.AlwaysOnTop = false
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 205, 50)
	f.Parent = bb
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.3, 0) c.Parent = f
	local s = Instance.new("UIStroke") s.Thickness = 2 s.Color = Color3.fromRGB(28, 30, 48) s.Parent = f
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Bangers
	t.TextScaled = true
	t.Text = "VIP"
	t.TextColor3 = Color3.fromRGB(28, 30, 48)
	t.Parent = f
	bb.Parent = glowa
end

-- zakup: klucz z Gamepassy albo Produkty
function S.kup(p, klucz)
	local gp = C.Gamepassy[klucz]
	local pr = C.Produkty[klucz]
	if gp then
		if S.ma(p, klucz) then return true, "Już to masz!" end
		if gp.id == 0 then
			if RunService:IsStudio() then
				nadajPass(p, klucz, true)
				return true, gp.nazwa .. " – kupione TESTOWO (Studio, brak ID)"
			end
			return false, "Ten gamepass nie ma jeszcze ID z Creator Hub."
		end
		MarketplaceService:PromptGamePassPurchase(p, gp.id)
		return true, nil
	elseif pr then
		if pr.id == 0 then
			if RunService:IsStudio() then
				S.przyznajProdukt(p, klucz)
				return true, pr.nazwa .. " – kupione TESTOWO (Studio, brak ID)"
			end
			return false, "Ten produkt nie ma jeszcze ID z Creator Hub."
		end
		MarketplaceService:PromptProductPurchase(p, pr.id)
		return true, nil
	end
	return false, "Nie ma takiego produktu"
end

function S.przyznajProdukt(p, klucz)
	local pr = C.Produkty[klucz]
	local d = M.Profil.Get(p)
	if not pr or not d then return false end
	if pr.zl then
		d.zl += pr.zl
		W.wyslij(p, "Nagroda", { zl = pr.zl, xp = 0, powod = "Zakup: " .. pr.nazwa })
	elseif klucz == "Bilet" then
		d.bilety = (d.bilety or 0) + 1
		W.karteczka(p, "Bilet Rozrabiaki", "Masz biletów: " .. d.bilety .. ". Zużyje się w następnej rundzie.", "zielony")
	end
	M.Profil.wyslij(p)
	task.spawn(M.Profil.Zapisz, p)
	return true
end

-- strefa VIP w komisariacie: kącik z kanapami i telewizorem odgrodzony aksamitną liną.
-- Bramka koliduje dla wszystkich; klient VIP-a wyłącza sobie kolizję lokalnie.
local function strefaVIP()
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby or lobby:FindFirstChild("StrefaVIP") then return end
	local m = Instance.new("Model")
	m.Name = "StrefaVIP"
	local function czesc(nazwa, size, cf, kolor, mat, props)
		local c = Instance.new("Part")
		c.Name = nazwa
		c.Anchored = true
		c.Size = size
		c.CFrame = cf
		c.Color = kolor
		c.Material = mat or Enum.Material.SmoothPlastic
		c.TopSurface = Enum.SurfaceType.Smooth
		c.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props or {}) do c[k] = v end
		c.Parent = m
		return c
	end
	local X, Z0, Z1 = 85, -246.5, -269.5
	local zMid = (Z0 + Z1) / 2
	local dl = math.abs(Z1 - Z0)
	-- niewidzialna bramka (po całej szerokości wejścia)
	czesc("Bramka", Vector3.new(1, 10, dl), CFrame.new(X - 1, 5, zMid), Color3.new(1, 1, 1), nil, { Transparency = 1, CanQuery = false })
	-- złote słupki i czerwona lina
	local slupki = 5
	for i = 0, slupki - 1 do
		local z = Z0 + (Z1 - Z0) * i / (slupki - 1)
		czesc("Slupek", Vector3.new(0.5, 3.4, 0.5), CFrame.new(X - 1, 1.7, z), Color3.fromRGB(230, 180, 40), Enum.Material.Metal, { CanCollide = false })
		czesc("Glowka", Vector3.new(0.8, 0.8, 0.8), CFrame.new(X - 1, 3.5, z), Color3.fromRGB(240, 195, 60), Enum.Material.Metal, { Shape = Enum.PartType.Ball, CanCollide = false })
		if i < slupki - 1 then
			local z2 = Z0 + (Z1 - Z0) * (i + 1) / (slupki - 1)
			czesc("Lina", Vector3.new(0.25, 0.25, math.abs(z2 - z)), CFrame.new(X - 1, 2.9, (z + z2) / 2), Color3.fromRGB(170, 20, 40), Enum.Material.Fabric, { CanCollide = false })
		end
	end
	-- czerwony dywan w strefie
	czesc("Dywan", Vector3.new(16, 0.1, dl - 1), CFrame.new(X + 9, 0.6, zMid), Color3.fromRGB(150, 20, 35), Enum.Material.Fabric, { CanCollide = false })
	-- szyld
	local sz = czesc("SzyldVIP", Vector3.new(0.3, 2.4, 10), CFrame.new(X - 1.2, 8.5, zMid), Color3.fromRGB(28, 30, 48), nil, { CanCollide = false })
	for _, strona in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local g = Instance.new("SurfaceGui")
		g.Face = strona
		g.PixelsPerStud = 40
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.Parent = sz
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.Bangers
		t.TextScaled = true
		t.Text = "★ STREFA VIP ★"
		t.TextColor3 = Color3.fromRGB(255, 205, 50)
		t.Parent = g
	end
	local sw = Instance.new("PointLight")
	sw.Color = Color3.fromRGB(255, 200, 90)
	sw.Brightness = 1.2
	sw.Range = 14
	sw.Parent = sz
	-- prompt dla nie-VIP (klient go chowa VIP-om)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "PromptVIP"
	pr.ActionText = "Kup VIP Legitymację"
	pr.ObjectText = "Strefa VIP"
	pr.HoldDuration = 0
	pr.MaxActivationDistance = 8
	pr.RequiresLineOfSight = false
	pr.Parent = m.Bramka
	pr.Triggered:Connect(function(p)
		if not S.ma(p, "VIP") then S.kup(p, "VIP") end
	end)
	m.Parent = lobby
end

function S.Init(moduly)
	M = moduly
	W = M.Wspolne
	C = W.C
end

function S.Start()
	pcall(strefaVIP)
	MarketplaceService.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId)
		if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for klucz, pr in pairs(C.Produkty) do
			if pr.id ~= 0 and pr.id == info.ProductId then
				-- poczekaj, aż profil się wczyta
				local t = 0
				while not M.Profil.Get(p) and t < 10 do task.wait(0.5) t += 0.5 end
				if S.przyznajProdukt(p, klucz) then return Enum.ProductPurchaseDecision.PurchaseGranted end
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, id, kupil)
		if not kupil then return end
		for klucz, gp in pairs(C.Gamepassy) do
			if gp.id == id then nadajPass(p, klucz, true) end
		end
	end)
	local function wejscie(p)
		local t = 0
		while not M.Profil.Get(p) and t < 15 do task.wait(0.5) t += 0.5 end
		sprawdzPassy(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if S.ma(p, "VIP") then S.znaczekVIP(p) end
		end)
	end
	Players.PlayerAdded:Connect(wejscie)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(wejscie, p) end
end

return S
