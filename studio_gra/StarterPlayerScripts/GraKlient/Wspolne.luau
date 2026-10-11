-- Wspólne dla klienta: stan gry, zdarzenia z serwera, dźwięki, styl GUI.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local K = {}
K.gracz = Players.LocalPlayer
K.Gra = RS:WaitForChild("Gra")
K.C = require(K.Gra:WaitForChild("Config"))
K.Styl = require(K.Gra:WaitForChild("Styl"))
K.Zdalne = K.Gra:WaitForChild("Zdalne")
K.Od = K.Zdalne:WaitForChild("Od")
K.Do = K.Zdalne:WaitForChild("Do")
K.Pytaj = K.Zdalne:WaitForChild("Pytaj")
K.PlayerGui = K.gracz:WaitForChild("PlayerGui")

-- stan po stronie klienta
K.stan = {
	faza = "Lobby",
	rola = nil,
	zadania = {},
	zrobione = {},
	zyje = true,
	profil = nil,
	cooldown = {},
	niesie = false,
	wKratce = false,
	wKryjowce = false,
	trzyma = nil,
	dyrektorMoc = false,
	wybraneZadanie = nil,
	minigra = false,
	ustawienia = { muzyka = 0.7, dzwieki = 0.5, fov = 70, podpowiedzi = true, drzenie = false, slaby = false },
}

-- prosta szyna zdarzeń
local sluchacze = {}
function K.na(typ, f)
	sluchacze[typ] = sluchacze[typ] or {}
	table.insert(sluchacze[typ], f)
end
function K.emituj(typ, dane)
	for _, f in ipairs(sluchacze[typ] or {}) do
		task.spawn(f, dane)
	end
end
K.Od.OnClientEvent:Connect(function(typ, dane)
	K.emituj(typ, dane or {})
end)

function K.wyslij(typ, dane) K.Do:FireServer(typ, dane or {}) end

-- dźwięki 2D
local grupaSfx = Instance.new("SoundGroup")
grupaSfx.Name = "Efekty"
grupaSfx.Volume = 1
grupaSfx.Parent = SoundService
K.grupaSfx = grupaSfx
local cache = {}
function K.dzwiek(nazwa, glosnosc)
	local id = K.C.Dzwieki[nazwa]
	if not id then return end
	local s = cache[nazwa]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.SoundGroup = grupaSfx
		s.Parent = SoundService
		cache[nazwa] = s
	end
	s.Volume = glosnosc or 0.6
	s.TimePosition = 0
	s:Play()
	return s
end
K.na("Dzwiek", function(d) K.dzwiek(d.nazwa, d.glosnosc) end)

function K.tween(o, czas, props, styl, kierunek)
	local t = TweenService:Create(o, TweenInfo.new(czas, styl or Enum.EasingStyle.Quad, kierunek or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function K.hrp()
	local ch = K.gracz.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end

function K.czasSerwera() return workspace:GetServerTimeNow() end

-- blokada sterowania (cutscenki, zebrania, kamery). Działa bez PlayerModule.
local CAS = game:GetService("ContextActionService")
local blokady = {}
function K.sterowanie(wlacz, powod)
	powod = powod or "ogolny"
	blokady[powod] = (not wlacz) or nil
	local zablokowane = next(blokady) ~= nil
	if zablokowane then
		CAS:BindActionAtPriority("GraBlokadaRuchu", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value + 50,
			Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	else
		CAS:UnbindAction("GraBlokadaRuchu")
	end
	local pm = K.gracz:FindFirstChild("PlayerScripts") and K.gracz.PlayerScripts:FindFirstChild("PlayerModule")
	if pm then
		local ok, mod = pcall(require, pm)
		if ok and mod then
			local c = mod:GetControls()
			if zablokowane then c:Disable() else c:Enable() end
		end
	end
end

function K.rolaDef() return K.stan.rola and K.C.Role[K.stan.rola] end
function K.jestZly() local r = K.rolaDef() return r and r.zly end

-- główny ScreenGui na rzeczy rysowane kodem
local gui = Instance.new("ScreenGui")
gui.Name = "GraGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 5
gui.Parent = K.PlayerGui
K.gui = gui
-- warstwa nad wszystkim (cutscenki, ekrany końca)
local nad = Instance.new("ScreenGui")
nad.Name = "GraNad"
nad.ResetOnSpawn = false
nad.IgnoreGuiInset = true
nad.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
nad.DisplayOrder = 20
nad.Parent = K.PlayerGui
K.nad = nad

-- skalowanie obwódek jak w HUD
local function skalujObwodki(root)
	local cam = workspace.CurrentCamera
	local function upd()
		local k = cam.ViewportSize.X / 1400
		for _, s in ipairs(root:GetDescendants()) do
			if s:IsA("UIStroke") then s.Thickness = (s:GetAttribute("Baza") or s.Thickness) * k end
		end
	end
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(upd)
	root.DescendantAdded:Connect(function(d)
		if d:IsA("UIStroke") then
			task.defer(function()
				if not d:GetAttribute("Baza") then d:SetAttribute("Baza", d.Thickness) end
				d.Thickness = d:GetAttribute("Baza") * cam.ViewportSize.X / 1400
			end)
		end
	end)
	upd()
end
skalujObwodki(gui)
skalujObwodki(nad)

return K
