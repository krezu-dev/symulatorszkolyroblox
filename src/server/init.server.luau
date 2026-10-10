--!strict
-- src/server/init.server.luau
-- Główny punkt wejścia serwera gry "Szkolny Detektyw"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("==================================================")
print("🎒 INICJALIZACJA GRY: SZKOLNY DETEKTYW (SERVER)")
print("==================================================")

-- 1. Załaduj wspólne kontrakty i zdarzenia sieciowe
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- 2. Uruchom menedżer rundy
local RoundManager = require(script:WaitForChild("RoundManager"))
RoundManager.init()

print("✅ Serwer gry wystartował pomyślnie!")
