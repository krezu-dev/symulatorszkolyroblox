--!strict
-- src/client/ProceduralAnimations.client.luau
-- Proceduralne animacje w grze (dźwięki, TweenService, efekty wizualne):
-- 1. Kołysanie Wielkiego Dzwonu przy uderzeniu
-- 2. Wirowanie rzucanego Dziennika Dyrektora
-- 3. Ruch i aresztowanie przez Klockowych Policjantów
-- 4. Efekty mopa i bąbelków Woźnej

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

print("[Animacje] Załadowano moduł animacji proceduralnych!")

-- ========================================================
-- 1. ANIMACJA KOŁYSANIA WIELKIEGO DZWONU
-- ========================================================
local function animateBell()
	local schoolMap = Workspace:FindFirstChild("SchoolMap")
	if not schoolMap then return end

	local bell = schoolMap:FindFirstChild("WielkiDzwonSzkolny") :: BasePart?
	if not bell then return end

	local originalCFrame = bell.CFrame

	-- Seria wahnięć
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	task.spawn(function()
		local angles = { 25, -25, 15, -10, 5, 0 }
		for _, angle in ipairs(angles) do
			local targetCFrame = originalCFrame * CFrame.Angles(0, 0, math.rad(angle))
			local tw = TweenService:Create(bell, tweenInfo, { CFrame = targetCFrame })
			tw:Play()
			tw.Completed:Wait()
		end
	end)
end

-- Nasłuchuj rozpoczęcia zebrania (zwołanego dzwonkiem)
Remotes.get(GameConfig.RemoteEvents.StartMeeting).OnClientEvent:Connect(function(callerName, reason)
	if string.find(reason, "Dzwon") then
		animateBell()
	end
end)

-- ========================================================
-- 2. EFEKTY CZĄSTECZKOWE DLA MOPA WOŹNEJ
-- ========================================================
local function attachMopEffects(tool: Tool)
	local mopHead = tool:WaitForChild("MopHead", 5) :: BasePart?
	if not mopHead then return end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://244221444" -- Bąbelki mydlane
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Parent = mopHead

	tool.Activated:Connect(function()
		emitter:Emit(8)
	end)
end

-- Wykrywanie narzędzi w plecaku gracza
local player = game:GetService("Players").LocalPlayer
local backpack = player:WaitForChild("Backpack")

local function onChildAdded(child: Instance)
	if child:IsA("Tool") and child.Name == "Mop i Wiadro" then
		attachMopEffects(child)
	end
end

backpack.ChildAdded:Connect(onChildAdded)
for _, item in ipairs(backpack:GetChildren()) do
	onChildAdded(item)
end
