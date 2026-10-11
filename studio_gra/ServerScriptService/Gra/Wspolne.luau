-- Wspólne narzędzia serwera: zdalne zdarzenia, dźwięki, powiadomienia, szukanie obiektów.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local W = {}
W.Gra = RS:WaitForChild("Gra")
W.C = require(W.Gra:WaitForChild("Config"))
W.Zdalne = W.Gra:WaitForChild("Zdalne")
W.Od = W.Zdalne:WaitForChild("Od")
W.Do = W.Zdalne:WaitForChild("Do")
W.Pytaj = W.Zdalne:WaitForChild("Pytaj")
W.Mapa = workspace:WaitForChild("SchoolMap")

function W.wyslij(p, typ, dane)
	if p and p.Parent then W.Od:FireClient(p, typ, dane) end
end
function W.wszyscy(typ, dane)
	W.Od:FireAllClients(typ, dane)
end
-- krótka karteczka na ekranie (tytul + tekst)
function W.karteczka(p, tytul, tekst, kolor)
	local d = { tytul = tytul, tekst = tekst, kolor = kolor }
	if p then W.wyslij(p, "Karteczka", d) else W.wszyscy("Karteczka", d) end
end

-- dźwięk 3D w miejscu albo przyczepiony do części
function W.dzwiek(nazwa, gdzie, glosnosc, zasieg)
	local id = W.C.Dzwieki[nazwa]
	if not id then return end
	local nosnik = gdzie
	if typeof(gdzie) == "Vector3" then
		nosnik = Instance.new("Part")
		nosnik.Anchored = true
		nosnik.CanCollide = false
		nosnik.CanQuery = false
		nosnik.Transparency = 1
		nosnik.Size = Vector3.new(1, 1, 1)
		nosnik.Position = gdzie
		nosnik.Parent = workspace
		Debris:AddItem(nosnik, 12)
	end
	if not nosnik then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = glosnosc or 0.8
	s.RollOffMaxDistance = zasieg or 120
	s.Parent = nosnik
	s:Play()
	Debris:AddItem(s, 12)
	return s
end
-- dźwięk 2D u wybranych graczy (albo wszystkich)
function W.dzwiek2D(nazwa, p, glosnosc)
	local d = { nazwa = nazwa, glosnosc = glosnosc }
	if p then W.wyslij(p, "Dzwiek", d) else W.wszyscy("Dzwiek", d) end
end

-- obiekt po ścieżce „A.B.C” od SchoolMap
function W.znajdz(sciezka)
	local o = W.Mapa
	for czesc in string.gmatch(sciezka, "[^%.]+") do
		o = o and o:FindFirstChild(czesc)
		if not o then return nil end
	end
	return o
end
function W.pozycja(o)
	if not o then return nil end
	if o:IsA("BasePart") then return o.Position end
	if o:IsA("Model") then return o:GetPivot().Position end
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	local n = 0
	for _, d in ipairs(o:GetDescendants()) do
		if d:IsA("BasePart") then n += 1; mn = mn:Min(d.Position); mx = mx:Max(d.Position) end
	end
	if n == 0 then return nil end
	return (mn + mx) / 2
end
function W.pierwszaCzesc(o)
	if not o then return nil end
	if o:IsA("BasePart") then return o end
	if o:IsA("Model") and o.PrimaryPart then return o.PrimaryPart end
	local best, vol = nil, -1
	for _, d in ipairs(o:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > vol then best, vol = d, v end
		end
	end
	return best
end

function W.hrp(p)
	local ch = p and p.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end
function W.dystans(a, b)
	if typeof(a) == "Instance" then local h = W.hrp(a) a = h and h.Position end
	if typeof(b) == "Instance" then local h = W.hrp(b) b = h and h.Position end
	if not a or not b then return math.huge end
	return (a - b).Magnitude
end
function W.teleport(p, cf)
	local h = W.hrp(p)
	if h then
		if typeof(cf) == "Vector3" then cf = CFrame.new(cf) end
		p.Character:PivotTo(cf + Vector3.new(0, 3, 0))
	end
end

-- grupy kolizji: żywi gracze, duchy (przenikają przez graczy), ciała
local PhysicsService = game:GetService("PhysicsService")
local function grupa(n) pcall(function() PhysicsService:RegisterCollisionGroup(n) end) end
grupa("Gracze") grupa("Duchy") grupa("Ciala")
PhysicsService:CollisionGroupSetCollidable("Duchy", "Gracze", false)
PhysicsService:CollisionGroupSetCollidable("Duchy", "Duchy", false)
PhysicsService:CollisionGroupSetCollidable("Ciala", "Gracze", false)
PhysicsService:CollisionGroupSetCollidable("Ciala", "Duchy", false)
function W.ustawGrupe(model, nazwa)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.CollisionGroup = nazwa end
	end
end

function W.losowo(t)
	local k = table.clone(t)
	for i = #k, 2, -1 do local j = math.random(i) k[i], k[j] = k[j], k[i] end
	return k
end

return W
