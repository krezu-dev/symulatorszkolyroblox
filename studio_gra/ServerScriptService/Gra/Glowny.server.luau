-- Start serwera gry „Szkolny Detektyw”: zdalne zdarzenia + moduły w kolejności.
local RS = game:GetService("ReplicatedStorage")
local gra = RS:WaitForChild("Gra")
local zdalne = gra:FindFirstChild("Zdalne") or Instance.new("Folder")
zdalne.Name = "Zdalne"
zdalne.Parent = gra
for nazwa, klasa in pairs({ Do = "RemoteEvent", Od = "RemoteEvent", Pytaj = "RemoteFunction" }) do
	if not zdalne:FindFirstChild(nazwa) then
		local r = Instance.new(klasa)
		r.Name = nazwa
		r.Parent = zdalne
	end
end

local KOLEJNOSC = { "Wspolne", "Profil", "Zadania", "Akcje", "Spotkania", "Sabotaze", "Swiat", "NPC", "Runda" }
local M = {}
for _, n in ipairs(KOLEJNOSC) do
	M[n] = require(script.Parent:WaitForChild(n))
end
for _, n in ipairs(KOLEJNOSC) do
	if M[n].Init then M[n].Init(M) end
end
for _, n in ipairs(KOLEJNOSC) do
	if M[n].Start then
		local ok, err = pcall(M[n].Start)
		if not ok then warn("[Gra] Start " .. n .. ": " .. tostring(err)) end
	end
end
gra:SetAttribute("SerwerGotowy", true)
