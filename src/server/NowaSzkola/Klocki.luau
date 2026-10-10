--!nonstrict
-- src/server/NowaSzkola/Klocki.luau  (Agent Claude)
-- Klocki budowlane nowej szkoły: ściany z lamperią, okna, drzwi, stropy z otworami,
-- świetlówki, tabliczki/plakaty i wstawianie prefabów z Toolboxa (ServerStorage.Prefaby).

local ServerStorage = game:GetService("ServerStorage")

local K = {}

K.Kolory = {
	Bialy = Color3.fromRGB(238, 235, 225),
	Sufit = Color3.fromRGB(242, 242, 238),
	Pasek = Color3.fromRGB(58, 66, 58),
	LamperiaZielona = Color3.fromRGB(88, 132, 98),
	LamperiaBezowa = Color3.fromRGB(214, 196, 150),
	LamperiaNiebieska = Color3.fromRGB(128, 166, 196),
	LamperiaZolta = Color3.fromRGB(226, 200, 120),
	LamperiaSzara = Color3.fromRGB(150, 156, 160),
	Lastryko = Color3.fromRGB(170, 167, 158),
	Parkiet = Color3.fromRGB(150, 98, 56),
	ParkietJasny = Color3.fromRGB(206, 160, 104),
	Linoleum = Color3.fromRGB(150, 120, 96),
	Plytki = Color3.fromRGB(236, 238, 236),
	Beton = Color3.fromRGB(150, 150, 146),
	Elewacja = Color3.fromRGB(228, 214, 178),
	Cegla = Color3.fromRGB(150, 70, 52),
	Drewno = Color3.fromRGB(128, 82, 46),
	Rama = Color3.fromRGB(245, 245, 245),
	Szyba = Color3.fromRGB(170, 205, 225),
	Metal = Color3.fromRGB(120, 124, 128),
	Tablica = Color3.fromRGB(32, 72, 52),
	Kreda = Color3.fromRGB(238, 240, 230),
	Korek = Color3.fromRGB(176, 128, 82),
}

local Mat = Enum.Material
local SMOOTH = Mat.SmoothPlastic

local root: Instance = nil
local stats = { parts = 0, lights = 0, prefabs = 0, missingPrefabs = {} :: { [string]: boolean } }
local LIGHT_CAP = 90

function K.init(r: Instance)
	root = r
	stats.parts, stats.lights, stats.prefabs = 0, 0, 0
	stats.missingPrefabs = {}
end

function K.stats()
	return stats
end

function K.root()
	return root
end

-- ========================================================
-- PODSTAWOWE BRYŁY
-- ========================================================
function K.part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, parent: Instance?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or SMOOTH
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in pairs(props) do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent or root
	stats.parts += 1
	return p
end

-- Prostopadłościan podany granicami (x0..x1, y0..y1, z0..z1)
function K.box(name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3, mat: Enum.Material?, parent: Instance?, props: { [string]: any }?): Part?
	local sx, sy, sz = math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)
	if sx < 0.01 or sy < 0.01 or sz < 0.01 then
		return nil
	end
	return K.part(name, Vector3.new(sx, sy, sz), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, mat, parent, props)
end

function K.cyl(name: string, height: number, diameter: number, cf: CFrame, color: Color3, mat: Enum.Material?, parent: Instance?): Part
	-- Cylinder w Roblox leży wzdłuż osi X; obracamy, żeby stał pionowo
	local p = K.part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, parent)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function K.folder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or root
	return f
end

-- ========================================================
-- ŚCIANY Z LAMPERIĄ (dwie warstwy: każda strona ma własny styl)
-- styl = { lam = Color3?, gora = Color3, mat = Material?, lamMat = Material?, wys = number? }
-- otwory = { { a = od, b = do, lo = dół (wzgl. podłogi), hi = góra, typ = "okno"|"drzwi"|"przejscie", strona = ±1 } }
-- ========================================================
local LAM_H, PASEK_H = 4.4, 0.3

local function pasma(styl, ylo: number, yhi: number)
	if not styl.lam then
		return { { ylo, yhi, styl.gora, styl.mat or SMOOTH } }
	end
	local lh = styl.wys or LAM_H
	local out = {}
	local ciecia = {
		{ 0, lh, styl.lam, styl.lamMat or SMOOTH },
		{ lh, lh + PASEK_H, styl.pasek or K.Kolory.Pasek, SMOOTH },
		{ lh + PASEK_H, math.huge, styl.gora, styl.mat or SMOOTH },
	}
	for _, c in ipairs(ciecia) do
		local a, b = math.max(ylo, c[1]), math.min(yhi, c[2])
		if b - a > 0.01 then
			table.insert(out, { a, b, c[3], c[4] })
		end
	end
	return out
end

local function wallBox(axis: string, fixed: number, a: number, b: number, y0: number, y1: number, off0: number, off1: number, color: Color3, mat: Enum.Material, parent: Instance?)
	if axis == "X" then
		return K.box("Sciana", a, b, y0, y1, fixed + off0, fixed + off1, color, mat, parent)
	else
		return K.box("Sciana", fixed + off0, fixed + off1, y0, y1, a, b, color, mat, parent)
	end
end

-- Ściana wzdłuż osi `axis` ("X" = biegnie wzdłuż X przy stałym z; "Z" = wzdłuż Z przy stałym x)
-- stylMinus: strona o mniejszej współrzędnej, stylPlus: strona o większej.
function K.wall(axis: string, fixed: number, a0: number, a1: number, y0: number, h: number, otwory: { any }?, stylMinus, stylPlus, parent: Instance?, grubosc: number?)
	local t = grubosc or 1
	if a1 < a0 then
		a0, a1 = a1, a0
	end
	local ops = table.clone(otwory or {})
	table.sort(ops, function(p, q)
		return p.a < q.a
	end)

	local segs = {}
	local cur = a0
	for _, o in ipairs(ops) do
		if o.a > cur then
			table.insert(segs, { cur, o.a, 0, h })
		end
		if o.lo > 0 then
			table.insert(segs, { o.a, o.b, 0, o.lo })
		end
		if o.hi < h then
			table.insert(segs, { o.a, o.b, o.hi, h })
		end
		cur = math.max(cur, o.b)
	end
	if cur < a1 then
		table.insert(segs, { cur, a1, 0, h })
	end

	for _, s in ipairs(segs) do
		for side, styl in ipairs({ stylMinus, stylPlus }) do
			local off0, off1 = (side == 1) and -t / 2 or 0, (side == 1) and 0 or t / 2
			if styl.plaska then
				local p = wallBox(axis, fixed, s[1], s[2], y0 + s[3], y0 + s[4], off0, off1, styl.gora, styl.mat or SMOOTH, parent)
			else
				for _, pb in ipairs(pasma(styl, s[3], s[4])) do
					wallBox(axis, fixed, s[1], s[2], y0 + pb[1], y0 + pb[2], off0, off1, pb[3], pb[4], parent)
				end
			end
		end
	end

	for _, o in ipairs(ops) do
		if o.typ == "okno" then
			K.okno(axis, fixed, o.a, o.b, y0 + o.lo, y0 + o.hi, t, parent, o.ciemne)
		elseif o.typ == "drzwi" then
			K.drzwi(axis, fixed, o.a, o.b, y0, y0 + o.hi, t, o.strona or 1, parent, o.podwojne)
		end
	end
end

-- Okno: szyba + biała rama ze słupkiem i ślemieniem + parapety
function K.okno(axis: string, fixed: number, a: number, b: number, ylo: number, yhi: number, t: number, parent: Instance?, ciemne: boolean?)
	local f = parent or root
	local rama = 0.3
	local function bx(name, aa, bb, y0, y1, d0, d1, col, mat, props)
		if axis == "X" then
			return K.box(name, aa, bb, y0, y1, fixed + d0, fixed + d1, col, mat, f, props)
		else
			return K.box(name, fixed + d0, fixed + d1, y0, y1, aa, bb, col, mat, f, props)
		end
	end
	bx("Szyba", a, b, ylo, yhi, -0.08, 0.08, ciemne and Color3.fromRGB(40, 50, 60) or K.Kolory.Szyba, Mat.Glass, { Transparency = ciemne and 0.2 or 0.55, CastShadow = false })
	bx("RamaOkna", a, b, yhi - rama, yhi, -0.2, 0.2, K.Kolory.Rama, SMOOTH)
	bx("RamaOkna", a, b, ylo, ylo + rama, -0.2, 0.2, K.Kolory.Rama, SMOOTH)
	bx("RamaOkna", a, a + rama, ylo, yhi, -0.2, 0.2, K.Kolory.Rama, SMOOTH)
	bx("RamaOkna", b - rama, b, ylo, yhi, -0.2, 0.2, K.Kolory.Rama, SMOOTH)
	if (b - a) > 3 then
		local m = (a + b) / 2
		bx("Slupek", m - 0.12, m + 0.12, ylo, yhi, -0.18, 0.18, K.Kolory.Rama, SMOOTH)
	end
	if (yhi - ylo) > 4 then
		local y = yhi - (yhi - ylo) * 0.28
		bx("Slemie", a, b, y - 0.12, y + 0.12, -0.18, 0.18, K.Kolory.Rama, SMOOTH)
	end
	-- parapety z obu stron
	bx("Parapet", a - 0.3, b + 0.3, ylo - 0.2, ylo, -t / 2 - 0.6, t / 2 + 0.6, K.Kolory.Bialy, Mat.Marble)
end

-- Drzwi: drewniana ościeżnica + otwarte skrzydło z przeszkleniem (strona = ±1: w którą stronę otwiera się skrzydło)
function K.drzwi(axis: string, fixed: number, a: number, b: number, ylo: number, yhi: number, t: number, strona: number, parent: Instance?, podwojne: boolean?)
	local f = parent or root
	local o = 0.35
	local function bx(name, aa, bb, y0, y1, d0, d1, col, mat, props)
		if axis == "X" then
			return K.box(name, aa, bb, y0, y1, fixed + d0, fixed + d1, col, mat, f, props)
		else
			return K.box(name, fixed + d0, fixed + d1, y0, y1, aa, bb, col, mat, f, props)
		end
	end
	local d = t / 2 + 0.12
	bx("Oscieznica", a, a + o, ylo, yhi, -d, d, K.Kolory.Drewno, Mat.Wood)
	bx("Oscieznica", b - o, b, ylo, yhi, -d, d, K.Kolory.Drewno, Mat.Wood)
	bx("Oscieznica", a, b, yhi - o, yhi, -d, d, K.Kolory.Drewno, Mat.Wood)

	local function skrzydlo(hinge: number, szer: number)
		-- skrzydło stoi prostopadle do ściany, przy zawiasie
		local h = yhi - ylo - 0.4
		local s0, s1 = t / 2 * strona, (t / 2 + szer) * strona
		local lo, hi = math.min(s0, s1), math.max(s0, s1)
		local leaf = bx("SkrzydloDrzwi", hinge - 0.15, hinge + 0.15, ylo + 0.1, ylo + 0.1 + h, lo, hi, Color3.fromRGB(160, 110, 62), Mat.Wood)
		bx("SzybkaDrzwi", hinge - 0.17, hinge + 0.17, ylo + h * 0.62, ylo + h * 0.92, lo + szer * 0.2, hi - szer * 0.2, K.Kolory.Szyba, Mat.Glass, { Transparency = 0.5 })
		return leaf
	end
	local w = (b - a) - 2 * o
	if podwojne then
		skrzydlo(a + o + 0.2, w / 2 - 0.1)
		skrzydlo(b - o - 0.2, w / 2 - 0.1)
	else
		skrzydlo(a + o + 0.2, w - 0.2)
	end
end

-- ========================================================
-- STROPY Z OTWORAMI (prostokąty x0,x1,z0,z1)
-- ========================================================
local function odejmij(r, h)
	if h[2] <= r[1] or h[1] >= r[2] or h[4] <= r[3] or h[3] >= r[4] then
		return { r }
	end
	local out = {}
	if h[1] > r[1] then
		table.insert(out, { r[1], h[1], r[3], r[4] })
	end
	if h[2] < r[2] then
		table.insert(out, { h[2], r[2], r[3], r[4] })
	end
	local mx0, mx1 = math.max(r[1], h[1]), math.min(r[2], h[2])
	if h[3] > r[3] then
		table.insert(out, { mx0, mx1, r[3], h[3] })
	end
	if h[4] < r[4] then
		table.insert(out, { mx0, mx1, h[4], r[4] })
	end
	return out
end

function K.strop(name: string, x0: number, x1: number, z0: number, z1: number, yTop: number, th: number, color: Color3, mat: Enum.Material?, otwory: { any }?, parent: Instance?)
	local rects = { { x0, x1, z0, z1 } }
	for _, h in ipairs(otwory or {}) do
		local nowe = {}
		for _, r in ipairs(rects) do
			for _, s in ipairs(odejmij(r, h)) do
				table.insert(nowe, s)
			end
		end
		rects = nowe
	end
	for _, r in ipairs(rects) do
		K.box(name, r[1], r[2], yTop - th, yTop, r[3], r[4], color, mat, parent)
	end
end

-- ========================================================
-- ŚWIETLÓWKI
-- ========================================================
function K.swietlowka(pos: Vector3, zeSwiatlem: boolean?, opts: { zasieg: number?, jasnosc: number?, migocze: boolean?, obrot: boolean? }?, parent: Instance?): BasePart
	local o = opts or {}
	local f = parent or root
	local rot = o.obrot and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()
	local base = CFrame.new(pos) * rot
	K.part("Oprawa", Vector3.new(6, 0.3, 1.6), base, K.Kolory.Rama, Mat.Metal, f)
	local tuba = K.part("Swietlowka", Vector3.new(5.6, 0.18, 0.7), base * CFrame.new(0, -0.22, 0), Color3.fromRGB(250, 252, 255), Mat.Neon, f, { CastShadow = false })
	if zeSwiatlem and stats.lights < LIGHT_CAP then
		stats.lights += 1
		local pl = Instance.new("PointLight")
		pl.Range = o.zasieg or 22
		pl.Brightness = o.jasnosc or 0.9
		pl.Color = Color3.fromRGB(240, 246, 255)
		pl.Shadows = false
		pl.Parent = tuba
		if o.migocze then
			-- miganie uruchamia NowaSzkola.setupMap w trakcie gry (mapa jest statyczna)
			tuba:SetAttribute("Migocze", true)
		end
	end
	return tuba
end

-- ========================================================
-- NAPISY, TABLICZKI, PLAKATY
-- ========================================================
function K.napis(p: BasePart, face: Enum.NormalId, tekst: string, tlo: Color3?, kolor: Color3?, font: Enum.Font?, opts: { przezroczyste: boolean?, ramka: Color3?, wyrownanie: Enum.TextXAlignment? }?)
	local o = opts or {}
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0.6
	sg.Parent = p
	local fr = Instance.new("Frame")
	fr.Size = UDim2.fromScale(1, 1)
	fr.BackgroundColor3 = tlo or K.Kolory.Bialy
	fr.BackgroundTransparency = o.przezroczyste and 1 or 0
	fr.BorderSizePixel = 0
	fr.Parent = sg
	if o.ramka then
		local st = Instance.new("UIStroke")
		st.Color = o.ramka
		st.Thickness = 6
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = fr
	end
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 1, -12)
	lbl.Position = UDim2.fromOffset(8, 6)
	lbl.BackgroundTransparency = 1
	lbl.Text = tekst
	lbl.TextColor3 = kolor or Color3.fromRGB(25, 25, 25)
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.Font = font or Enum.Font.GothamBold
	lbl.TextXAlignment = o.wyrownanie or Enum.TextXAlignment.Center
	lbl.Parent = fr
	return sg
end

-- Tabliczka/plakat na ścianie: pos = środek, normalna = kierunek, w który patrzy napis
function K.plakat(name: string, pos: Vector3, normalna: Vector3, w: number, h: number, tekst: string, tlo: Color3?, kolor: Color3?, font: Enum.Font?, parent: Instance?, opts: any?): Part
	local cf = CFrame.lookAt(pos, pos + normalna)
	local p = K.part(name, Vector3.new(w, h, 0.12), cf, tlo or K.Kolory.Bialy, SMOOTH, parent, { CanCollide = false, CastShadow = false })
	K.napis(p, Enum.NormalId.Front, tekst, tlo, kolor, font, opts)
	return p
end

-- Gazetka ścienna: korkowa tablica z ramą i kilkoma "przypiętymi" kartkami
function K.gazetka(pos: Vector3, normalna: Vector3, w: number, h: number, tytul: string, kartki: { string }, parent: Instance?)
	local f = parent or root
	local cf = CFrame.lookAt(pos, pos + normalna)
	local korek = K.part("Gazetka", Vector3.new(w, h, 0.25), cf, K.Kolory.Korek, Mat.Cardboard, f, { CanCollide = false })
	K.part("RamaGazetki", Vector3.new(w + 0.5, h + 0.5, 0.2), cf * CFrame.new(0, 0, 0.06), K.Kolory.Drewno, Mat.Wood, f, { CanCollide = false })
	K.plakat("TytulGazetki", (cf * CFrame.new(0, h / 2 - 0.75, -0.16)).Position, normalna, w * 0.8, 1.1, tytul, Color3.fromRGB(250, 250, 240), Color3.fromRGB(170, 30, 30), Enum.Font.FredokaOne, f)
	local n = #kartki
	local kolory = { Color3.fromRGB(255, 250, 200), Color3.fromRGB(210, 240, 255), Color3.fromRGB(255, 220, 230), Color3.fromRGB(220, 255, 215), Color3.fromRGB(255, 255, 255) }
	local kw = math.min(3.4, (w - 1) / math.max(n, 1) - 0.3)
	for i, txt in ipairs(kartki) do
		local x = -w / 2 + 0.5 + (i - 0.5) * ((w - 1) / n)
		local tilt = math.rad(((i % 3) - 1) * 4)
		local kcf = cf * CFrame.new(x, -0.4, -0.18) * CFrame.Angles(0, 0, tilt)
		local kartka = K.part("Kartka", Vector3.new(kw, h - 2.4, 0.05), kcf, kolory[(i - 1) % #kolory + 1], SMOOTH, f, { CanCollide = false, CastShadow = false })
		K.napis(kartka, Enum.NormalId.Front, txt, kolory[(i - 1) % #kolory + 1], Color3.fromRGB(30, 30, 50), Enum.Font.PatrickHand)
		K.part("Pinezka", Vector3.new(0.2, 0.2, 0.2), kcf * CFrame.new(0, (h - 2.4) / 2 - 0.25, -0.08), Color3.fromRGB(220, 30, 30), Mat.Plastic, f, { CanCollide = false, Shape = Enum.PartType.Ball })
	end
	return korek
end

-- ========================================================
-- PREFABY Z TOOLBOXA (ServerStorage.Prefaby). Zwraca nil, jeśli prefabu brak.
-- cf: pozycja (dół-środek) i orientacja; "przód" prefabu będzie patrzył w LookVector cf.
-- dopasuj: maks. wymiary (szer X, wys Y, głęb Z) – skalowanie jednolite.
-- ========================================================
function K.prefab(name: string, cf: CFrame, dopasuj: Vector3?, parent: Instance?): (Model?, Vector3?)
	local folder = ServerStorage:FindFirstChild("Prefaby")
	local src = folder and folder:FindFirstChild(name)
	if not src or not src:IsA("Model") then
		stats.missingPrefabs[name] = true
		return nil, nil
	end
	local m = src:Clone()
	local yaw = math.rad(m:GetAttribute("Yaw") or 0)

	if dopasuj then
		local _, sz = m:GetBoundingBox()
		-- wymiary po obrocie korekcyjnym
		local sx, sz2 = sz.X, sz.Z
		if math.abs(math.sin(yaw)) > 0.7 then
			sx, sz2 = sz.Z, sz.X
		end
		local s = math.min(dopasuj.X / sx, dopasuj.Y / sz.Y, dopasuj.Z / sz2)
		if s > 0 and math.abs(s - 1) > 0.01 then
			m:ScaleTo(m:GetScale() * s)
		end
	end

	local bbCf, size = m:GetBoundingBox()
	local offset = bbCf:Inverse() * m:GetPivot()
	local target = CFrame.new(cf.Position) * cf.Rotation * CFrame.Angles(0, yaw, 0) * CFrame.new(0, size.Y / 2, 0)
	m:PivotTo(target * offset)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			stats.parts += 1
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	m.Parent = parent or root
	stats.prefabs += 1
	return m, size
end

-- Kierunki pomocnicze
K.PLUS_X = Vector3.new(1, 0, 0)
K.MINUS_X = Vector3.new(-1, 0, 0)
K.PLUS_Z = Vector3.new(0, 0, 1)
K.MINUS_Z = Vector3.new(0, 0, -1)

function K.patrz(pos: Vector3, kierunek: Vector3): CFrame
	return CFrame.lookAt(pos, pos + kierunek)
end

return K
