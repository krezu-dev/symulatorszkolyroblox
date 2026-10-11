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

-- narzędzia do testów w Studio (nie działają na prawdziwym serwerze)
if game:GetService("RunService"):IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "GraDebug"
	bf.Parent = game:GetService("ServerStorage")
	bf.OnInvoke = function(cmd, a, b)
		local p = game:GetService("Players"):GetPlayers()[1]
		local R = M.Runda
		if cmd == "info" then
			local g = R.info(p)
			return { faza = R.faza, rola = g and g.rola, zadania = g and g.zadania, zrobione = g and g.zrobione, zyje = g and g.zyje }
		elseif cmd == "doZadania" then
			local g = R.info(p)
			local id = a or (g and g.zadania[1])
			local pos = M.Zadania.pozycja(id)
			if pos then p.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.new(3, 0, 0)) end
			task.wait(0.4)
			M.Zadania.otworz(p, id)
			return id
		elseif cmd == "spotkanie" then
			task.spawn(M.Spotkania.zwolaj, p, a or "dzwon")
			return true
		elseif cmd == "sabotaz" then
			local g = R.info(p)
			local stara = g.rola
			g.rola = "Rozrabiaka"
			M.Sabotaze.uruchom(p, a)
			g.rola = stara
			return true
		elseif cmd == "koniec" then
			R.zwyciezca = { strona = a or "dobrzy", powod = "test" }
			return true
		elseif cmd == "teleport" then
			p.Character:PivotTo(CFrame.new(a))
			return true
		end
	end
end
