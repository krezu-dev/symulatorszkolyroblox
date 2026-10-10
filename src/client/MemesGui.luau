--!strict
-- src/client/MemesGui.luau
-- Interfejs Polskich Memów Szkolnych, Wierzchowca KUKIRIN i Preferencji Ról:
-- 1. Pływający przycisk 🐉 KUKIRIN (Dosiadanie / zsiadanie z wierzchowca)
-- 2. Pływający przycisk 📢 POLSKIE MEMY (Soundboard szkolny i dymki tekstowe)
-- 3. Selektor Preferencji Roli w Lobby (Zwiększanie szansy na Dyrektora / Rozrabiakę / Woźną)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MemesGui = {}
local memeModal: Frame? = nil
local rolePrefFrame: Frame? = nil
local currentPreference = "Random"

function MemesGui.init(parentScreenGui: ScreenGui)
	-- ========================================================
	-- 1. PRZYCISK: 🐉 KUKIRIN (LEWY DOLNY RÓG)
	-- ========================================================
	local kukirinBtn = Instance.new("TextButton")
	kukirinBtn.Name = "KukirinMountBtn"
	kukirinBtn.Size = UDim2.new(0, 160, 0, 42)
	kukirinBtn.Position = UDim2.new(0, 15, 1, -105)
	kukirinBtn.BackgroundColor3 = Color3.fromRGB(240, 185, 20)
	kukirinBtn.Text = "🐉 KUKIRIN (JAZDA)"
	kukirinBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
	kukirinBtn.Font = Enum.Font.GothamBlack
	kukirinBtn.TextSize = 13
	kukirinBtn.ZIndex = 25
	kukirinBtn.Parent = parentScreenGui
	Instance.new("UICorner", kukirinBtn).CornerRadius = UDim.new(0, 8)
	local kStroke = Instance.new("UIStroke", kukirinBtn)
	kStroke.Color = Color3.fromRGB(255, 255, 255)
	kStroke.Thickness = 1.5

	kukirinBtn.MouseButton1Click:Connect(function()
		Remotes.get(GameConfig.RemoteEvents.ToggleKukirin):FireServer()
	end)

	-- ========================================================
	-- 2. PRZYCISK: 📢 MEMY SZKOLNE
	-- ========================================================
	local memeSoundboardBtn = Instance.new("TextButton")
	memeSoundboardBtn.Name = "MemeSoundboardBtn"
	memeSoundboardBtn.Size = UDim2.new(0, 160, 0, 42)
	memeSoundboardBtn.Position = UDim2.new(0, 15, 1, -155)
	memeSoundboardBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
	memeSoundboardBtn.Text = "📢 POLSKIE MEMY"
	memeSoundboardBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	memeSoundboardBtn.Font = Enum.Font.GothamBlack
	memeSoundboardBtn.TextSize = 13
	memeSoundboardBtn.ZIndex = 25
	memeSoundboardBtn.Parent = parentScreenGui
	Instance.new("UICorner", memeSoundboardBtn).CornerRadius = UDim.new(0, 8)
	local mStroke = Instance.new("UIStroke", memeSoundboardBtn)
	mStroke.Color = Color3.fromRGB(255, 255, 255)
	mStroke.Thickness = 1.5

	-- Modal Soundboardu Polskich Memów
	local soundboard = Instance.new("Frame")
	soundboard.Name = "SoundboardModal"
	soundboard.Size = UDim2.new(0, 420, 0, 320)
	soundboard.Position = UDim2.new(0.5, -210, 0.5, -160)
	soundboard.BackgroundColor3 = Color3.fromRGB(26, 22, 34)
	soundboard.Visible = false
	soundboard.ZIndex = 40
	soundboard.Parent = parentScreenGui
	Instance.new("UICorner", soundboard).CornerRadius = UDim.new(0, 12)
	local sbStroke = Instance.new("UIStroke", soundboard)
	sbStroke.Color = Color3.fromRGB(155, 89, 182)
	sbStroke.Thickness = 2

	memeModal = soundboard

	local sbTitle = Instance.new("TextLabel")
	sbTitle.Size = UDim2.new(1, -50, 0, 40)
	sbTitle.Position = UDim2.new(0, 15, 0, 5)
	sbTitle.BackgroundTransparency = 1
	sbTitle.Text = "📢 POLSKIE MEMY SZKOLNE (SOUNDBOARD)"
	sbTitle.TextColor3 = Color3.fromRGB(255, 215, 120)
	sbTitle.Font = Enum.Font.GothamBlack
	sbTitle.TextSize = 15
	sbTitle.TextXAlignment = Enum.TextXAlignment.Left
	sbTitle.Parent = soundboard

	local sbClose = Instance.new("TextButton")
	sbClose.Size = UDim2.new(0, 28, 0, 28)
	sbClose.Position = UDim2.new(1, -38, 0, 10)
	sbClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	sbClose.Text = "✕"
	sbClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	sbClose.Font = Enum.Font.GothamBold
	sbClose.TextSize = 14
	Instance.new("UICorner", sbClose).CornerRadius = UDim.new(0, 6)
	sbClose.Parent = soundboard

	sbClose.MouseButton1Click:Connect(function()
		soundboard.Visible = false
	end)

	local memeScroll = Instance.new("ScrollingFrame")
	memeScroll.Size = UDim2.new(1, -20, 1, -55)
	memeScroll.Position = UDim2.new(0, 10, 0, 45)
	memeScroll.BackgroundTransparency = 1
	memeScroll.CanvasSize = UDim2.new(0, 0, 0, 340)
	memeScroll.ScrollBarThickness = 5
	memeScroll.Parent = soundboard

	local memeList = Instance.new("UIListLayout")
	memeList.Padding = UDim.new(0, 8)
	memeList.Parent = memeScroll

	for _, meme in ipairs(GameConfig.PolishMemes) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 45)
		btn.BackgroundColor3 = Color3.fromRGB(42, 35, 55)
		btn.Text = meme.Title
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.Parent = memeScroll

		btn.MouseButton1Click:Connect(function()
			Remotes.get(GameConfig.RemoteEvents.PlayMemeQuote):FireServer(meme.Id)
			soundboard.Visible = false
		end)
	end

	memeSoundboardBtn.MouseButton1Click:Connect(function()
		soundboard.Visible = not soundboard.Visible
	end)

	-- ========================================================
	-- 3. SELEKTOR PREFERENCJI ROLI W LOBBY
	-- ========================================================
	local prefFrame = Instance.new("Frame")
	prefFrame.Name = "RolePreferenceBar"
	prefFrame.Size = UDim2.new(0, 480, 0, 36)
	prefFrame.Position = UDim2.new(0.5, -240, 0, 90)
	prefFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
	prefFrame.BackgroundTransparency = 0.2
	prefFrame.Visible = true
	prefFrame.Parent = parentScreenGui
	Instance.new("UICorner", prefFrame).CornerRadius = UDim.new(0, 8)

	rolePrefFrame = prefFrame

	local pLabel = Instance.new("TextLabel")
	pLabel.Size = UDim2.new(0, 130, 1, 0)
	pLabel.Position = UDim2.new(0, 10, 0, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "🎯 Wybierz rolę:"
	pLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	pLabel.Font = Enum.Font.GothamBold
	pLabel.TextSize = 12
	pLabel.TextXAlignment = Enum.TextXAlignment.Left
	pLabel.Parent = prefFrame

	local rolesOptions = {
		{ Id = "Random", Label = "🎲 Losowo", Color = Color3.fromRGB(120, 130, 150) },
		{ Id = GameConfig.Roles.Dyrektor, Label = "👑 Dyrektor", Color = Color3.fromRGB(230, 60, 60) },
		{ Id = GameConfig.Roles.Rozrabiaka, Label = "😈 Rozrabiaka", Color = Color3.fromRGB(150, 40, 40) },
		{ Id = GameConfig.Roles.Wozna, Label = "🧹 Woźna", Color = Color3.fromRGB(40, 120, 200) },
	}

	for i, opt in ipairs(rolesOptions) do
		local btn = Instance.new("TextButton")
		btn.Name = `Pref_{opt.Id}`
		btn.Size = UDim2.new(0, 80, 0, 26)
		btn.Position = UDim2.new(0, 135 + (i - 1) * 85, 0.5, -13)
		btn.BackgroundColor3 = if opt.Id == currentPreference then opt.Color else Color3.fromRGB(50, 54, 68)
		btn.Text = opt.Label
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.Parent = prefFrame

		btn.MouseButton1Click:Connect(function()
			currentPreference = opt.Id
			Remotes.get(GameConfig.RemoteEvents.SetRolePreference):FireServer(opt.Id)

			-- Odśwież podświetlenie
			for _, child in ipairs(prefFrame:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Color3.fromRGB(50, 54, 68)
				end
			end
			btn.BackgroundColor3 = opt.Color
		end)
	end

	-- Ukrywanie paska preferencji podczas samej gry
	Remotes.get(GameConfig.RemoteEvents.GameStateChanged).OnClientEvent:Connect(function(newState: string)
		if newState == GameConfig.GameStates.Lobby then
			prefFrame.Visible = true
		else
			prefFrame.Visible = false
		end
	end)
end

return MemesGui
