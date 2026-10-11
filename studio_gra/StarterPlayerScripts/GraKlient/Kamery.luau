-- Monitoring w radiowęźle: konsola -> podgląd z kamer w całej szkole (jak w Among Us).
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Km = {}
local K, U, C
local kamery = {}
local nr = 1
local ogladam = false
local ekran, nazwaT, czasT, rec
local prompt

local function ustawKamere()
	local k = kamery[nr]
	if not k then return end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = k.CFrame
	nazwaT.Text = "KAM " .. nr .. " – " .. (k:GetAttribute("Nazwa") or k.Name)
	K.dzwiek("Pstryk", 0.3)
end

function Km.zamknij()
	if not ogladam then return end
	ogladam = false
	ekran.Visible = false
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	K.wyslij("kamery", { w = false })
	K.sterowanie(true, "kamery")
end
function Km.otworz()
	if ogladam or #kamery == 0 then return end
	ogladam = true
	ekran.Visible = true
	K.wyslij("kamery", { w = true })
	K.sterowanie(false, "kamery")
	ustawKamere()
end

local function zbuduj()
	ekran = U.new("Frame", { Name = "Monitoring", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 50 }, K.gui)
	-- ramka monitora
	for _, r in ipairs({ { 0, 0, 1, 0.06 }, { 0, 0.94, 1, 0.06 }, { 0, 0, 0.04, 1 }, { 0.96, 0, 0.04, 1 } }) do
		U.new("Frame", { BackgroundColor3 = Color3.fromRGB(35, 35, 40), BorderSizePixel = 0, Position = UDim2.fromScale(r[1], r[2]), Size = UDim2.fromScale(r[3], r[4]), ZIndex = 51 }, ekran)
	end
	-- linie skanowania
	for i = 1, 40 do
		U.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.88, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromScale(0, i / 40), ZIndex = 52 }, ekran)
	end
	U.new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 120, 60), BackgroundTransparency = 0.88, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 52 }, ekran)
	nazwaT = U.txt(ekran, { Font = Enum.Font.Code, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(0.5, 0.05), Position = UDim2.fromScale(0.06, 0.08), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53 })
	czasT = U.txt(ekran, { Font = Enum.Font.Code, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(0.3, 0.04), Position = UDim2.fromScale(0.64, 0.08), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 53 })
	rec = U.txt(ekran, { Text = "● REC", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(255, 40, 40), Size = UDim2.fromScale(0.12, 0.05), Position = UDim2.fromScale(0.06, 0.86), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53 })
	local lewo = U.przyciskTekst(ekran, "Lewo", "◀", UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.06, 0.1), U.PAPER, U.INK, Vector2.new(0, 0.5))
	local prawo = U.przyciskTekst(ekran, "Prawo", "▶", UDim2.fromScale(0.94, 0.5), UDim2.fromScale(0.06, 0.1), U.PAPER, U.INK, Vector2.new(1, 0.5))
	lewo.SizeConstraint = Enum.SizeConstraint.RelativeYY
	prawo.SizeConstraint = Enum.SizeConstraint.RelativeYY
	lewo.ZIndex = 55 prawo.ZIndex = 55
	lewo.Activated:Connect(function() nr = (nr - 2) % #kamery + 1 ustawKamere() end)
	prawo.Activated:Connect(function() nr = nr % #kamery + 1 ustawKamere() end)
	local x = U.zamknij(ekran, UDim2.fromScale(0.94, 0.12), 0.04)
	x.ZIndex = 56
	x.Activated:Connect(Km.zamknij)
	U.txt(ekran, { Text = "A/D lub strzałki – zmiana kamery, ESC – wyjście", Font = Enum.Font.Code, TextColor3 = Color3.fromRGB(200, 200, 200), Size = UDim2.fromScale(0.5, 0.035),
		Position = UDim2.fromScale(0.25, 0.88), ZIndex = 53 })
end

function Km.Init(k)
	K = k
	U = K.Styl
	C = K.C
	zbuduj()
	local f = workspace:WaitForChild("SchoolMap"):WaitForChild("Kamery", 20)
	if f then
		for _, c in ipairs(f:GetChildren()) do if c:IsA("BasePart") then table.insert(kamery, c) end end
		table.sort(kamery, function(a, b) return a.Name < b.Name end)
	end
	-- prompt przy konsoli radiowęzła (lokalny)
	local konsola = workspace.SchoolMap:FindFirstChild("Monitoring", true)
	if konsola and konsola:IsA("BasePart") then
		prompt = U.new("ProximityPrompt", { ActionText = "Oglądaj kamery", ObjectText = "Monitoring", MaxActivationDistance = 9, RequiresLineOfSight = false, KeyboardKeyCode = Enum.KeyCode.E }, konsola)
		prompt.Triggered:Connect(Km.otworz)
	end
	UserInputService.InputBegan:Connect(function(i, gp)
		if not ogladam then return end
		if i.KeyCode == Enum.KeyCode.Escape then Km.zamknij()
		elseif i.KeyCode == Enum.KeyCode.A or i.KeyCode == Enum.KeyCode.Left then nr = (nr - 2) % #kamery + 1 ustawKamere()
		elseif i.KeyCode == Enum.KeyCode.D or i.KeyCode == Enum.KeyCode.Right then nr = nr % #kamery + 1 ustawKamere() end
	end)
	RunService.Heartbeat:Connect(function()
		if prompt then prompt.Enabled = K.Gra:GetAttribute("Faza") == "Gra" and K.stan.zyje end
		if ogladam then
			czasT.Text = os.date("%H:%M:%S")
			rec.TextTransparency = (math.floor(os.clock() * 2) % 2 == 0) and 0 or 1
			if K.Gra:GetAttribute("Faza") ~= "Gra" then Km.zamknij() end
		end
	end)
end

return Km
