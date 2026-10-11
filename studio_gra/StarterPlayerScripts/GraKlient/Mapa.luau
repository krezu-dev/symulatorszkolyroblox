-- Minimapa w prawym górnym rogu: sale z nazwami, piętra, ty (strzałka), twoje zadania (żółte), naprawy (czerwone).
-- Klawisz M powiększa mapę.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Mp = {}
local K, U, C
local dane
local ramka, plotno, strzalka, pietroT
local warstwy = {}     -- [pietro] = Frame z salami
local znaczniki = {}
local duza = false
local SKALA = 1.25     -- px na stud przy małej mapie (liczone względem 260 px)

local function pietroDla(pos)
	if pos.Y >= 25.5 then return "Pietro" end
	if pos.Y < 8.5 and dane then
		-- piwnica tylko pod budynkami z piwnicą (na zewnątrz poziom 0 to parter)
		for _, b in ipairs(dane.budynki) do
			if b.pietro == "Piwnica" and pos.X >= b.x0 and pos.X <= b.x1 and pos.Z >= b.z0 and pos.Z <= b.z1 then return "Piwnica" end
		end
	end
	return "Parter"
end
local NAZWY_PIETER = { Piwnica = "PIWNICA / KOTŁOWNIA", Parter = "PARTER", Pietro = "1. PIĘTRO" }

local function zbuduj()
	local h, f = U.karta(K.gui, "Minimapa", UDim2.fromScale(0.985, 0.02), UDim2.fromScale(0.26, 0.26), U.PAPER, Vector2.new(1, 0), 0)
	h.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ramka = h
	f.ClipsDescendants = true
	plotno = U.new("Frame", { Name = "Plotno", BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Position = UDim2.fromScale(0.5, 0.5) }, f)
	-- siatka w kratkę (zeszyt)
	for i = 1, 9 do
		U.new("Frame", { BackgroundColor3 = U.LINE, BackgroundTransparency = 0.6, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, i / 10), ZIndex = 0 }, f)
		U.new("Frame", { BackgroundColor3 = U.LINE, BackgroundTransparency = 0.6, BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(i / 10, 0), ZIndex = 0 }, f)
	end
	for _, p in ipairs({ "Piwnica", "Parter", "Pietro" }) do
		warstwy[p] = U.new("Frame", { Name = p, BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Visible = false }, plotno)
	end
	local function prost(rodzic, x0, z0, x1, z1, kolor, tr, nazwa, z, obrys)
		local fr = U.new("Frame", { BackgroundColor3 = kolor, BackgroundTransparency = tr, BorderSizePixel = 0,
			Position = UDim2.fromOffset(x0, z0), Size = UDim2.fromOffset(x1 - x0, z1 - z0), ZIndex = z or 1 }, rodzic)
		fr:SetAttribute("x0", x0) fr:SetAttribute("z0", z0) fr:SetAttribute("x1", x1) fr:SetAttribute("z1", z1)
		if obrys then U.stroke(fr, 1, U.INK, 0.3) end
		if nazwa then
			local t = U.txt(fr, { Name = "N", Text = nazwa, TextScaled = true, Font = Enum.Font.PatrickHand, Size = UDim2.fromScale(0.95, 0.6), Position = UDim2.fromScale(0.025, 0.2), ZIndex = (z or 1) + 1 })
			U.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 6 }, t)
		end
		return fr
	end
	for _, b in ipairs(dane.budynki) do
		prost(warstwy[b.pietro], b.x0, b.z0, b.x1, b.z1, Color3.fromRGB(215, 205, 185), 0.1, nil, 1, true)
	end
	local kolory = { Color3.fromRGB(190, 215, 240), Color3.fromRGB(210, 235, 200), Color3.fromRGB(245, 215, 200), Color3.fromRGB(235, 225, 170) }
	for i, s in ipairs(dane.sale) do
		prost(warstwy[s.pietro], s.x0, s.z0, s.x1, s.z1, kolory[i % #kolory + 1], 0.05, s.nazwa, 2, true)
	end
	strzalka = U.new("Frame", { Name = "Ja", BackgroundTransparency = 1, Size = UDim2.fromScale(0.09, 0.09), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 20 }, f)
	local kolo = U.new("Frame", { BackgroundColor3 = U.RED, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), ZIndex = 21 }, strzalka)
	U.corner(kolo, UDim.new(1, 0))
	U.stroke(kolo, 2, U.PAPER, 0, true)
	local nos = U.new("Frame", { BackgroundColor3 = U.RED, Size = UDim2.fromScale(0.26, 0.26), Position = UDim2.fromScale(0.35, -0.1), Rotation = 45, ZIndex = 20 }, strzalka)
	pietroT = U.txt(f, { Name = "Pietro", Text = "", Font = Enum.Font.Bangers, Size = UDim2.fromScale(0.9, 0.09), Position = UDim2.fromScale(0.05, 0.015), ZIndex = 30, TextXAlignment = Enum.TextXAlignment.Left })
	U.obrysTekstu(pietroT, 1.5, U.PAPER)
	U.txt(f, { Text = "M – duża mapa", TextColor3 = U.GREY, Size = UDim2.fromScale(0.5, 0.06), Position = UDim2.fromScale(0.48, 0.93), ZIndex = 30, TextXAlignment = Enum.TextXAlignment.Right })
	U.tasma(h, UDim2.fromScale(0.5, 0), UDim2.fromScale(0.3, 0.07), -4)
end

local function znacznik(i, kolor)
	local z = znaczniki[i]
	if not z then
		z = U.new("Frame", { BackgroundColor3 = kolor, Size = UDim2.fromOffset(9, 9), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 15 }, plotno)
		U.corner(z, UDim.new(1, 0))
		U.stroke(z, 1.5, U.INK, 0, true)
		znaczniki[i] = z
	end
	z.BackgroundColor3 = kolor
	z.Visible = true
	return z
end

local function aktualizuj()
	local h = K.hrp()
	if not h or not ramka then return end
	local f = ramka.Lico
	local w = f.AbsoluteSize.X
	local skala = duza and (w / 330) or (w / 260 * SKALA)
	local pos = h.Position
	local pietro = pietroDla(pos)
	local wLobby = pos.Z < -170
	for p, l in pairs(warstwy) do l.Visible = p == pietro end
	pietroT.Text = wLobby and "LOBBY – KOMISARIAT" or NAZWY_PIETER[pietro]
	-- skala: przeliczamy pozycje dzieci (raz na zmianę skali)
	if plotno:GetAttribute("Skala") ~= skala then
		plotno:SetAttribute("Skala", skala)
		for _, l in pairs(warstwy) do
			for _, fr in ipairs(l:GetChildren()) do
				local x0, z0, x1, z1 = fr:GetAttribute("x0"), fr:GetAttribute("z0"), fr:GetAttribute("x1"), fr:GetAttribute("z1")
				if x0 then
					fr.Position = UDim2.fromOffset(x0 * skala, z0 * skala)
					fr.Size = UDim2.fromOffset((x1 - x0) * skala, (z1 - z0) * skala)
				end
			end
		end
	end
	-- mapa: północ w górę (−Z do góry), środek = gracz (albo cała szkoła na dużej)
	local srodek = duza and Vector3.new(30, 0, 70) or pos
	plotno.Position = UDim2.new(0.5, -srodek.X * skala, 0.5, -srodek.Z * skala)
	-- strzałka
	local look = h.CFrame.LookVector
	strzalka.Rotation = math.deg(math.atan2(look.X, -look.Z))
	strzalka.Position = UDim2.new(0.5, (pos.X - srodek.X) * skala, 0.5, (pos.Z - srodek.Z) * skala)
	-- znaczniki zadań
	local i = 0
	local s = K.stan
	if K.Gra:GetAttribute("Faza") == "Gra" then
		for _, pr in ipairs(CollectionService:GetTagged("PromptZadania")) do
			local id = pr:GetAttribute("Zadanie")
			if table.find(s.zadania, id) and not s.zrobione[id] and pr.Parent:IsA("BasePart") then
				local pp = pr.Parent.Position
				if pietroDla(pp) == pietro then
					i += 1
					local z = znacznik(i, id == s.wybraneZadanie and Color3.fromRGB(255, 120, 0) or U.YEL)
					z.Position = UDim2.fromOffset(pp.X * skala, pp.Z * skala)
				end
			end
		end
		for _, pr in ipairs(CollectionService:GetTagged("PromptNaprawa")) do
			if pr.Enabled and pr.Parent:IsA("BasePart") then
				local pp = pr.Parent.Position
				if pietroDla(pp) == pietro then
					i += 1
					local z = znacznik(i, U.RED)
					z.Position = UDim2.fromOffset(pp.X * skala, pp.Z * skala)
				end
			end
		end
	end
	for j = i + 1, #znaczniki do znaczniki[j].Visible = false end
end

function Mp.Init(k)
	K = k
	U = K.Styl
	C = K.C
	local ok, d = pcall(function() return require(K.Gra:WaitForChild("MapaDane", 10)) end)
	if not ok or not d then warn("[Mapa] brak danych mapy") return end
	dane = d
	zbuduj()
	UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == Enum.KeyCode.M then
			duza = not duza
			K.tween(ramka, 0.25, {
				Size = duza and UDim2.fromScale(0.8, 0.8) or UDim2.fromScale(0.26, 0.26),
				Position = duza and UDim2.fromScale(0.5, 0.1) or UDim2.fromScale(0.985, 0.02),
				AnchorPoint = duza and Vector2.new(0.5, 0) or Vector2.new(1, 0),
			}, Enum.EasingStyle.Back)
		end
	end)
	RunService.RenderStepped:Connect(aktualizuj)
end

return Mp
