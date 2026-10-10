--!strict
-- src/server/PolishMemesService.luau
-- System Polskich Memów Szkolnych (Soundboard & Memiczne Teksty Nauczycieli):
-- Pozwala graczom puszczać kultowe polskie memy szkolne na korytarzach!

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))

local PolishMemesService = {}
local memeCooldowns: { [Player]: number } = {}

function PolishMemesService.playMeme(player: Player, memeId: string)
	local now = tick()
	local last = memeCooldowns[player] or 0
	if now - last < 5 then return end -- 5s cooldown
	memeCooldowns[player] = now

	-- Szukaj definicji mema
	local foundMeme: any = nil
	for _, m in ipairs(GameConfig.PolishMemes) do
		if m.Id == memeId then
			foundMeme = m
			break
		end
	end
	if not foundMeme then return end

	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	-- Dźwięk mema
	local sound = Instance.new("Sound")
	sound.SoundId = foundMeme.Sound
	sound.Volume = 0.8
	sound.Parent = head
	sound:Play()
	Debris:AddItem(sound, 4)

	-- Dymek z tekstem nad głową
	local bb = Instance.new("BillboardGui")
	bb.Name = "MemeChatBubble"
	bb.Size = UDim2.new(0, 240, 0, 50)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(255, 245, 180)
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
	bg.Parent = bb

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.new(0, 5, 0, 3)
	label.BackgroundTransparency = 1
	label.Text = `🗣️ {player.Name}:\n"{foundMeme.Text}"`
	label.TextColor3 = Color3.fromRGB(30, 30, 30)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bg

	Debris:AddItem(bb, 4)

	-- Rozgłoszenie do wszystkich klientów (dla powiadomienia na czacie)
	local broadcast = Remotes.get(GameConfig.RemoteEvents.BroadcastMeme)
	broadcast:FireAllClients(player.Name, foundMeme.Text)
	print(`[PolishMemes] {player.Name} wykrzyczał: '{foundMeme.Title}'`)
end

function PolishMemesService.init()
	Remotes.get(GameConfig.RemoteEvents.PlayMemeQuote).OnServerEvent:Connect(function(player: Player, memeId: string)
		PolishMemesService.playMeme(player, memeId)
	end)

	print("[PolishMemesService] System polskich memów szkolnych zainicjalizowany!")
end

return PolishMemesService
