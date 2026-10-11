-- Start klienta gry „Szkolny Detektyw”.
local folder = script.Parent
local K = require(folder:WaitForChild("Wspolne"))
local KOLEJNOSC = { "Minigry", "HUD", "Rozgrywka", "Spotkanie", "Cutscenki", "Okna", "Mapa", "Kamery", "Efekty" }
local M = {}
for _, n in ipairs(KOLEJNOSC) do
	M[n] = require(folder:WaitForChild(n))
end
for _, n in ipairs(KOLEJNOSC) do
	local ok, err = pcall(M[n].Init, K, M)
	if not ok then warn("[GraKlient] " .. n .. ": " .. tostring(err)) end
end
