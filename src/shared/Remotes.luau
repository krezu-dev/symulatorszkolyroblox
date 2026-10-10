--!strict
-- src/shared/Remotes.luau
-- Automatyczne inicjalizowanie i pobieranie RemoteEvents

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local Remotes = {}

local eventsFolder: Folder
if RunService:IsServer() then
	eventsFolder = ReplicatedStorage:FindFirstChild("Events") :: Folder
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	-- Tworzenie RemoteEvents na serwerze
	for _, eventName in pairs(GameConfig.RemoteEvents) do
		if not eventsFolder:FindFirstChild(eventName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = eventsFolder
		end
	end
else
	-- Po stronie klienta czekamy na folder
	eventsFolder = ReplicatedStorage:WaitForChild("Events", 10) :: Folder
end

function Remotes.get(name: string): RemoteEvent
	if eventsFolder then
		local remote = eventsFolder:WaitForChild(name, 10)
		if remote and remote:IsA("RemoteEvent") then
			return remote
		end
	end
	error("[Remotes] Nie znaleziono RemoteEvent: " .. tostring(name))
end

return Remotes
