-- efekty eliminacji (wybierane w plecaku; konfetti/kreda/kartki/dzwonek z gamepassa)
-- Bez napisów. Dźwięk efektu słyszy tylko ten, kto eliminował (d.kto).
local TEX_ISKRY = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_DYM = "rbxasset://textures/particles/smoke_main.dds"
local TEX_FALA = "rbxasset://textures/particles/explosion01_shockwave_main.dds"
local TEX_RDZEN = "rbxasset://textures/particles/explosion01_core_main.dds"

local function podlogaPod(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local wyklucz = { workspace:FindFirstChild("Ciala") }
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl.Character then table.insert(wyklucz, pl.Character) end end
	params.FilterDescendantsInstances = wyklucz
	local r = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -25, 0), params)
	return r and r.Position.Y or (pos.Y - 3)
end

-- kawałki (konfetti, kartki, kreda): ruch liczony lokalnie, bez fizyki Robloxa; lądują na podłodze i bledną
local kawalki = {}
local function kawalek(p, v, w, o)
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Parent = workspace
	table.insert(kawalki, { p = p, v = v, w = w, t = 0, zycie = o.zycie or 2.6, g = o.g or 40, opor = o.opor or 0.6,
		podloga = o.podloga, kolys = o.kolys, faza = math.random() * 6.28, baza = p.Transparency })
end
RunService.RenderStepped:Connect(function(dt)
	for i = #kawalki, 1, -1 do
		local k = kawalki[i]
		k.t += dt
		if not k.p.Parent or k.t > k.zycie then
			k.p:Destroy()
			table.remove(kawalki, i)
		else
			local pol = k.p.Size.Y / 2
			if not k.lezy then
				k.v = k.v * math.max(0, 1 - k.opor * dt) + Vector3.new(0, -k.g * dt, 0)
				local dryf = Vector3.zero
				if k.kolys then
					dryf = Vector3.new(math.sin(k.t * k.kolys.f + k.faza), 0, math.cos(k.t * k.kolys.f * 0.8 + k.faza)) * k.kolys.a
				end
				local nowa = k.p.Position + (k.v + dryf) * dt
				if nowa.Y <= k.podloga + pol and k.v.Y < 0 then
					k.lezy = true
					k.p.CFrame = CFrame.new(nowa.X, k.podloga + pol + 0.01, nowa.Z) * CFrame.Angles(0, math.random() * 6.28, 0)
				else
					k.p.CFrame = CFrame.new(nowa) * k.p.CFrame.Rotation * CFrame.Angles(k.w.X * dt, k.w.Y * dt, k.w.Z * dt)
				end
			end
			local zost = k.zycie - k.t
			if zost < 0.5 then k.p.Transparency = k.baza + (1 - k.baza) * (1 - zost / 0.5) end
		end
	end
end)

local function czesc(props)
	local p = Instance.new("Part")
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k2, v in pairs(props) do p[k2] = v end
	return p
end

-- błysk: neonowa kula, która rośnie i znika, plus krótkie światło
local function blysk(pos, kolor, rozmiar, czas, slaby)
	local s = czesc({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = kolor, Size = Vector3.one * 0.6, Position = pos, Transparency = 0.05 })
	s.Parent = workspace
	K.tween(s, czas, { Size = Vector3.one * rozmiar, Transparency = 1 }, Enum.EasingStyle.Quint)
	if not slaby then
		local l = U.new("PointLight", { Color = kolor, Brightness = 8, Range = rozmiar * 3, Shadows = false }, s)
		K.tween(l, czas * 1.3, { Brightness = 0 })
	end
	Debris:AddItem(s, czas + 0.2)
end

-- fala uderzeniowa płasko na podłodze (tekstura fali leży poziomo)
local function fala(pos, podlogaY, kolor, rozmiar, czas)
	local p = czesc({ Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), Position = Vector3.new(pos.X, podlogaY + 0.15, pos.Z) })
	p.Parent = workspace
	local a = Instance.new("Attachment") a.Parent = p
	local pe = U.new("ParticleEmitter", {
		Texture = TEX_FALA, Color = ColorSequence.new(kolor), LightEmission = 0.6, LightInfluence = 0,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(0.01), Lifetime = NumberRange.new(czas), Rate = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, rozmiar) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1) }),
	}, a)
	pe:Emit(1)
	Debris:AddItem(p, czas + 0.3)
end

-- wybuch cząsteczek z jednego punktu
local function wybuch(pos, o)
	local p = czesc({ Transparency = 1, Size = Vector3.one * 0.2, Position = pos })
	p.Parent = workspace
	local a = Instance.new("Attachment") a.Parent = p
	for _, kol in ipairs(o.kolory) do
		local pe = U.new("ParticleEmitter", {
			Texture = o.tekstura, Color = ColorSequence.new(kol), Rate = 0, SpreadAngle = Vector2.new(180, 180),
			Lifetime = o.zycie, Speed = o.szybkosc, Drag = o.opor or 4, Acceleration = o.grawitacja or Vector3.zero,
			Size = o.rozmiar, Transparency = o.przezr or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 1) }),
			Rotation = NumberRange.new(0, 360), RotSpeed = o.obrot or NumberRange.new(-90, 90),
			LightEmission = o.swiatlo or 0, LightInfluence = o.swiatlo and 0 or 1, ZOffset = o.z or 0,
		}, a)
		pe:Emit(math.max(1, math.floor(o.ile / #o.kolory)))
	end
	Debris:AddItem(p, (o.zycie.Max or 2) + 0.5)
end

local function sekw(lista) return NumberSequence.new(lista) end
local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end

local WARIANTY = {}
WARIANTY.POW = { dzwiek = "Bonk", gra = function(pos, y, slaby)
	local zolty, pom = Color3.fromRGB(255, 214, 60), Color3.fromRGB(255, 120, 30)
	blysk(pos, Color3.fromRGB(255, 245, 200), 7, 0.25, slaby)
	fala(pos, y, zolty, 16, 0.5)
	wybuch(pos, { tekstura = TEX_ISKRY, kolory = { zolty, pom, Color3.new(1, 1, 1) }, ile = slaby and 18 or 40, swiatlo = 1,
		zycie = NumberRange.new(0.35, 0.7), szybkosc = NumberRange.new(28, 46), opor = 7, rozmiar = sekw({ kp(0, 1.6), kp(1, 0) }) })
	wybuch(pos, { tekstura = TEX_RDZEN, kolory = { pom }, ile = 6, swiatlo = 0.5,
		zycie = NumberRange.new(0.25, 0.4), szybkosc = NumberRange.new(2, 5), rozmiar = sekw({ kp(0, 3), kp(1, 7) }),
		przezr = sekw({ kp(0, 0.2), kp(1, 1) }) })
end }
WARIANTY.Konfetti = { dzwiek = "Fajerwerk", gra = function(pos, y, slaby)
	local kolory = { Color3.fromRGB(255, 70, 90), Color3.fromRGB(60, 170, 255), Color3.fromRGB(255, 215, 50), Color3.fromRGB(90, 220, 120), Color3.fromRGB(200, 110, 255), Color3.fromRGB(255, 140, 40) }
	blysk(pos, Color3.new(1, 1, 1), 4, 0.18, slaby)
	for _ = 1, (slaby and 30 or 70) do
		local kol = kolory[math.random(#kolory)]
		local p = czesc({ Size = Vector3.new(0.34, 0.04, 0.2), Color = kol, Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6.28, math.random() * 6.28, 0) })
		local kat = math.random() * 6.28
		local v = Vector3.new(math.cos(kat), 0, math.sin(kat)) * (5 + math.random() * 11) + Vector3.new(0, 20 + math.random() * 16, 0)
		kawalek(p, v, Vector3.new(math.random(-14, 14), math.random(-14, 14), math.random(-14, 14)),
			{ g = 30, opor = 1.6, podloga = y, zycie = 2.6 + math.random(), kolys = { a = 1.6, f = 7 } })
	end
	wybuch(pos, { tekstura = TEX_ISKRY, kolory = kolory, ile = slaby and 12 or 30, swiatlo = 1,
		zycie = NumberRange.new(0.4, 0.8), szybkosc = NumberRange.new(14, 24), opor = 5, rozmiar = sekw({ kp(0, 0.9), kp(1, 0) }) })
end }
WARIANTY.Kreda = { dzwiek = "Boing", gra = function(pos, y, slaby)
	local bialy, niebieski = Color3.fromRGB(250, 250, 245), Color3.fromRGB(225, 235, 255)
	-- gęsty obłok kredy
	wybuch(pos, { tekstura = TEX_DYM, kolory = { bialy, niebieski, bialy }, ile = slaby and 14 or 34,
		zycie = NumberRange.new(1.4, 2.4), szybkosc = NumberRange.new(9, 16), opor = 3.5, grawitacja = Vector3.new(0, 1.5, 0),
		rozmiar = sekw({ kp(0, 2.2), kp(0.3, 5), kp(1, 7.5) }), przezr = sekw({ kp(0, 0.15), kp(0.5, 0.45), kp(1, 1) }), obrot = NumberRange.new(-25, 25) })
	-- unoszący się pył
	if not slaby then
		wybuch(pos + Vector3.new(0, 1, 0), { tekstura = TEX_ISKRY, kolory = { bialy }, ile = 26,
			zycie = NumberRange.new(1.5, 2.5), szybkosc = NumberRange.new(3, 7), opor = 1.5, grawitacja = Vector3.new(0, 2, 0),
			rozmiar = sekw({ kp(0, 0.35), kp(1, 0) }) })
	end
	fala(pos, y, bialy, 14, 0.7)
	-- kawałki kredy odbijają się po podłodze
	for _ = 1, (slaby and 4 or 9) do
		local p = czesc({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 0.22, 0.22), Color = bialy, Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(pos) * CFrame.Angles(0, math.random() * 6.28, math.random() * 6.28) })
		local kat = math.random() * 6.28
		kawalek(p, Vector3.new(math.cos(kat), 0, math.sin(kat)) * (8 + math.random() * 8) + Vector3.new(0, 12 + math.random() * 8, 0),
			Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)), { g = 55, opor = 0.4, podloga = y, zycie = 2.4 })
	end
end }
WARIANTY.Kartki = { dzwiek = "Werbel", gra = function(pos, y, slaby)
	blysk(pos, Color3.new(1, 1, 1), 5, 0.2, slaby)
	fala(pos, y, Color3.fromRGB(255, 255, 255), 12, 0.5)
	for i = 1, (slaby and 9 or 20) do
		local odcien = 235 + math.random(0, 20)
		local p = czesc({ Size = Vector3.new(0.85, 0.03, 1.15), Color = Color3.fromRGB(odcien, odcien, odcien - 8), Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(math.random() * 0.8, math.random() * 6.28, math.random() * 0.8) })
		-- co trzecia kartka z czerwoną „jedynką” (pasek oceny)
		if i % 3 == 0 then
			local o = czesc({ Size = Vector3.new(0.22, 0.035, 0.5), Color = Color3.fromRGB(214, 40, 57), Material = Enum.Material.SmoothPlastic })
			o.Anchored = false
			o.Massless = true
			o.CFrame = p.CFrame * CFrame.new(0.2, 0, -0.2)
			local w = Instance.new("WeldConstraint") w.Part0 = p w.Part1 = o w.Parent = o
			o.Parent = p
		end
		local kat = math.random() * 6.28
		kawalek(p, Vector3.new(math.cos(kat), 0, math.sin(kat)) * (6 + math.random() * 7) + Vector3.new(0, 16 + math.random() * 10, 0),
			Vector3.new(math.random(-5, 5), math.random(-6, 6), math.random(-5, 5)), { g = 9, opor = 2.2, podloga = y, zycie = 3.2 + math.random(), kolys = { a = 3, f = 4 } })
	end
end }
WARIANTY.Dzwonek = { dzwiek = "Dzwon", gra = function(pos, y, slaby)
	local zloty, jasny = Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 240, 170)
	blysk(pos, jasny, 6, 0.3, slaby)
	for i = 0, 2 do
		task.delay(i * 0.14, function() fala(pos, y, i == 1 and jasny or zloty, 18 + i * 6, 0.7) end)
	end
	wybuch(pos, { tekstura = TEX_ISKRY, kolory = { zloty, jasny }, ile = slaby and 16 or 36, swiatlo = 1,
		zycie = NumberRange.new(0.6, 1.1), szybkosc = NumberRange.new(16, 30), opor = 4, grawitacja = Vector3.new(0, -12, 0),
		rozmiar = sekw({ kp(0, 1.1), kp(1, 0) }) })
	-- pionowe „fale dźwięku” wokół miejsca
	if not slaby then
		for i = 0, 1 do
			task.delay(0.1 + i * 0.22, function()
				local r = czesc({ Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Color = zloty, Size = Vector3.one * 2, Position = pos, Transparency = 0 })
				r.Parent = workspace
				K.tween(r, 0.6, { Size = Vector3.one * 14, Transparency = 1 }, Enum.EasingStyle.Quad)
				Debris:AddItem(r, 0.7)
			end)
		end
	end
end }

local function eliminacja(d)
	local w = WARIANTY[d.efekt or ""] or WARIANTY.POW
	local slaby = K.stan.ustawienia.slaby
	if d.kto == K.gracz.UserId and C.Dzwieki[w.dzwiek] then K.dzwiek(w.dzwiek, 0.75) end
	local pos = d.pos + Vector3.new(0, 1, 0)
	local y = podlogaPod(d.pos)
	w.gra(pos, y, slaby)
	return true
end
