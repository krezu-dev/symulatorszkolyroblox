-- Cutscenki: przyjazd autobusu i wejście przez bramę, karta roli, ekran końca rundy.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Cs = {}
local K, U, C
local kino, con

local function sterowanie(tak)
	local ok, pm = pcall(function() return require(K.gracz.PlayerScripts:WaitForChild("PlayerModule")) end)
	if ok and pm then
		local c = pm:GetControls()
		if tak then c:Enable() else c:Disable() end
	end
end

local function pasy(pokaz)
	if pokaz and not kino then
		kino = U.new("Frame", { Name = "Kino", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 60 }, K.nad)
		local g1 = U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), ZIndex = 61 }, kino)
		local g2 = U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), ZIndex = 61 }, kino)
		K.tween(g1, 0.4, { Size = UDim2.fromScale(1, 0.11) })
		K.tween(g2, 0.4, { Size = UDim2.fromScale(1, 0.11) })
		local t = U.txt(kino, { Name = "Napis", Text = "", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.8, 0.07), Position = UDim2.fromScale(0.1, 0.9), ZIndex = 62 })
		U.obrysTekstu(t, 2)
	elseif not pokaz and kino then
		local k = kino
		kino = nil
		for _, f in ipairs(k:GetChildren()) do if f:IsA("Frame") then K.tween(f, 0.3, { Size = UDim2.fromScale(1, 0) }) end end
		task.delay(0.35, function() k:Destroy() end)
	end
end
local function napis(t)
	if kino and kino:FindFirstChild("Napis") then kino.Napis.Text = t end
end

local function kamera(fn)
	if con then con:Disconnect() con = nil end
	local cam = workspace.CurrentCamera
	if not fn then
		cam.CameraType = Enum.CameraType.Custom
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	con = RunService.RenderStepped:Connect(function()
		cam.CFrame = fn(os.clock() - start)
	end)
end

local function autobus(d)
	if d.etap == "autobus" then
		sterowanie(false)
		pasy(true)
		napis("Poniedziałek, 7:55. Gimbus pod szkołę...")
		local bus = d.autobus
		local brama = d.brama
		kamera(function(t)
			local cel = (bus and bus.Parent and bus:GetPivot().Position) or brama
			local oko = brama + Vector3.new(-6, 9, -26)
			return CFrame.lookAt(oko, cel + Vector3.new(0, 3, 0))
		end)
	elseif d.etap == "wysiadka" then
		napis("Wszyscy wysiadać! Brama otwarta!")
		local brama = d.brama
		kamera(function(t)
			local oko = brama + Vector3.new(10 - t * 2, 8 + t * 0.6, 18 + t * 1.5)
			return CFrame.lookAt(oko, brama + Vector3.new(0, 2, -6))
		end)
	elseif d.etap == "brama" then
		napis("...i brama się zamyka. Nie ma odwrotu.")
	elseif d.etap == "koniec" then
		pasy(false)
		kamera(nil)
		sterowanie(true)
	end
end

------------------------------------------------------------------ KARTA ROLI
local function kartaRoli(d)
	local def = C.Role[d.rola]
	if not def then return end
	K.dzwiek(def.zly and "Alarm" or "Dzwon", 0.35)
	local tlo = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(12, 14, 24), BackgroundTransparency = 0.25, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, K.nad)
	local h, f = U.karta(tlo, "Karta", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.56), Color3.fromRGB(222, 236, 222), Vector2.new(0.5, 0.5), -2, 5)
	h.SizeConstraint = Enum.SizeConstraint.RelativeYY
	U.new("UIAspectRatioConstraint", { AspectRatio = 1.6 }, h)
	h.ZIndex = 71
	U.new("Frame", { BackgroundColor3 = def.kolor, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.16), ZIndex = 72 }, f)
	U.txt(f, { Text = "LEGITYMACJA SZKOLNA", Font = Enum.Font.Bangers, TextColor3 = U.PAPER, Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.05, 0.02), ZIndex = 73 })
	local foto = U.new("ImageLabel", { BackgroundColor3 = U.PAPER2, Size = UDim2.fromScale(0.26, 0.5), Position = UDim2.fromScale(0.05, 0.24),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. K.gracz.UserId .. "&w=150&h=150", ZIndex = 72 }, f)
	U.stroke(foto, 2)
	U.txt(f, { Text = K.gracz.DisplayName, Size = UDim2.fromScale(0.6, 0.1), Position = UDim2.fromScale(0.35, 0.24), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
	U.txt(f, { Text = def.opis, TextWrapped = true, Size = UDim2.fromScale(0.6, 0.26), Position = UDim2.fromScale(0.35, 0.36), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 72 })
	if d.wspolnicy and #d.wspolnicy > 1 then
		U.txt(f, { Text = "Wspólnicy: " .. table.concat(d.wspolnicy, ", "), TextColor3 = U.RED, Size = UDim2.fromScale(0.6, 0.07), Position = UDim2.fromScale(0.35, 0.64), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72 })
	end
	U.txt(f, { Text = "„" .. def.tekst .. "”", Font = Enum.Font.PatrickHand, TextColor3 = U.GREY, Size = UDim2.fromScale(0.86, 0.08), Position = UDim2.fromScale(0.07, 0.86), ZIndex = 72 })
	local st = U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.42, 0.2), Position = UDim2.fromScale(0.52, 0.68), Rotation = -12, ZIndex = 74 }, f)
	U.stroke(st, 5, def.kolor)
	U.corner(st, UDim.new(0, 6))
	U.txt(st, { Text = string.upper(def.nazwa), Font = Enum.Font.Bangers, TextColor3 = def.kolor, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), ZIndex = 75 })
	local sc = U.new("UIScale", { Scale = 0.2 }, h)
	K.tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	local ssc = U.new("UIScale", { Scale = 4 }, st)
	task.delay(0.7, function()
		K.tween(ssc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		K.dzwiek("Cios", 0.5)
	end)
	task.wait(4.2)
	K.tween(sc, 0.25, { Scale = 0 })
	K.tween(tlo, 0.3, { BackgroundTransparency = 1 })
	task.wait(0.35)
	tlo:Destroy()
end

------------------------------------------------------------------ KONIEC RUNDY
local function koniec(d)
	local mojaRola = K.stan.rola
	local wygralem = false
	for _, g in ipairs(d.gracze) do if g.id == K.gracz.UserId then wygralem = g.wygral end end
	K.dzwiek(wygralem and "Wygrana" or "Smutny", 0.6)
	local tlo = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(12, 14, 24), BackgroundTransparency = 0.2, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, K.nad)
	local tytul = d.strona == "zli" and "WYGRAŁ ROZRABIAKA!" or (d.strona == "dobrzy" and "WYGRAŁA SZKOŁA!" or "KONIEC RUNDY")
	local t = U.txt(tlo, { Text = tytul, Font = Enum.Font.Bangers, TextColor3 = d.strona == "zli" and U.RED or U.GREEN, Size = UDim2.fromScale(0.8, 0.13), Position = UDim2.fromScale(0.1, 0.06), ZIndex = 71 })
	U.obrysTekstu(t, 3)
	U.txt(tlo, { Text = d.powod or "", TextColor3 = U.PAPER, Size = UDim2.fromScale(0.7, 0.05), Position = UDim2.fromScale(0.15, 0.2), ZIndex = 71 })
	U.txt(tlo, { Text = wygralem and "Wygrałeś! Lecą złotówki i XP." or "Tym razem przegrana. Następnym razem!", Font = Enum.Font.Bangers, TextColor3 = U.YEL,
		Size = UDim2.fromScale(0.6, 0.05), Position = UDim2.fromScale(0.2, 0.26), ZIndex = 71 })
	-- karty graczy z rolami
	for i, g in ipairs(d.gracze) do
		local c = (i - 1) % 5
		local r = math.floor((i - 1) / 5)
		local def = C.Role[g.rola]
		local h, f = U.karta(tlo, "G" .. i, UDim2.fromScale(0.08 + c * 0.17, 0.36 + r * 0.26), UDim2.fromScale(0.15, 0.22), g.wygral and U.PAPER or Color3.fromRGB(190, 185, 180), nil, ((i * 31) % 7 - 3) * 0.8)
		h.ZIndex = 71
		local foto = U.new("ImageLabel", { BackgroundColor3 = U.PAPER2, Size = UDim2.fromScale(0.5, 0.5), SizeConstraint = Enum.SizeConstraint.RelativeXX, Position = UDim2.fromScale(0.25, 0.06),
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. g.id .. "&w=150&h=150", ZIndex = 72 }, f)
		U.stroke(foto, 1.5)
		U.txt(f, { Text = g.nick, Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.6), ZIndex = 72 })
		U.txt(f, { Text = def and def.nazwa or g.rola, Font = Enum.Font.Bangers, TextColor3 = def and def.kolor or U.INK, Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.78), ZIndex = 72 })
		if not g.zyje then
			U.txt(f, { Text = "duch", Font = Enum.Font.Bangers, TextColor3 = U.RED, Rotation = -20, Size = UDim2.fromScale(0.5, 0.18), Position = UDim2.fromScale(0.5, 0.02), ZIndex = 73 })
		end
	end
	task.wait(C.Czasy.KoniecRundy - 0.6)
	K.tween(tlo, 0.4, { BackgroundTransparency = 1 })
	task.wait(0.4)
	tlo:Destroy()
end

function Cs.Init(k)
	K = k
	U = K.Styl
	C = K.C
	K.na("Cutscenka", autobus)
	K.na("Rola", kartaRoli)
	K.na("Koniec", koniec)
	K.na("Faza", function(d)
		if d.faza == "Lobby" then pasy(false) kamera(nil) sterowanie(true) end
	end)
end

return Cs
