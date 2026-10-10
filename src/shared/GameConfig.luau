--!strict
-- src/shared/GameConfig.luau
-- Centralna konfiguracja i stałe gry "Szkolny Detektyw" (MM2 + Among Us w realiach polskiej szkoły)

local GameConfig = {}

-- Role w grze
GameConfig.Roles = {
	Student = "Uczen",
	Wozna = "Wozna",
	Dyrektor = "Dyrektor",
	Rozrabiaka = "Rozrabiaka",
	ZastepcaDyrektora = "ZastepcaDyrektora", -- Gracz, który podniósł upuszczony Dziennik po śmierci Dyrektora!
}

-- Stany gry
GameConfig.GameStates = {
	Lobby = "Lobby",
	InGame = "InGame",
	Meeting = "Meeting",
	ArrestAnimation = "ArrestAnimation",
	SummaryScreen = "SummaryScreen",
	GameOver = "GameOver",
}

-- Czasy trwania etapów (w sekundach)
GameConfig.Durations = {
	LobbyTime = 15,
	RoundTime = 270, -- 4.5 minuty
	MeetingDiscussion = 60, -- czas na dyskusję i głosowanie
	ArrestAnimation = 4,
	SummaryBlackout = 5,
	KillCooldown = 15, -- Cooldown plastikowego noża Rozrabiaki
	VentCooldown = 4, -- Cooldown skakania po kratkach wentylacyjnych
}

-- Rodzaje Sabotaży (Among Us inspired)
GameConfig.Sabotages = {
	AwariaKorkow = "AwariaKorkow", -- Wyłączenie świateł w całej szkole; Woźna lub Uczniowie naprawiają skrzynkę bezpiecznikową
	ZablokowaneDrzwi = "ZablokowaneDrzwi", -- Zablokowanie sal lekcyjnych na 15s
	FalszywyAlarm = "FalszywyAlarm", -- Włączenie syreny alarmowej; wymaga wyłączenia w 30s
}

-- Mechanika Monet (MM2 inspired)
GameConfig.Coins = {
	MaxSpawns = 35, -- Maksymalna liczba monet na mapie
	SpawnInterval = 12, -- Co ile sekund pojawiają się nowe monety
	CoinValue = 5, -- Każda moneta to 5 Szkolnych Złotych
	MaxBagCapacity = 50, -- Limit monet zebranych w jednej rundzie
}

-- Zadania szkolne (Tasks)
GameConfig.Tasks = {
	Matematyka = {
		Id = "Matematyka",
		Name = "Test z Matematyki",
		Location = "Klasa Matematyczna (Sala 201)",
		Description = "Rozwiąż szybkie równanie (np. 2 + 2 = ?)",
		CoinsReward = 15,
	},
	JezykPolski = {
		Id = "JezykPolski",
		Name = "Dyktando z Języka Polskiego",
		Location = "Klasa Humanistyczna (Sala 202)",
		Description = "Przepisz słowo z tablicy bez błędu",
		CoinsReward = 15,
	},
	StolowkaPierogi = {
		Id = "StolowkaPierogi",
		Name = "Zjedz Szkolny Obiad",
		Location = "Stołówka Szkolna",
		Description = "Zjedz porcję pierogów (5 kliknięć)",
		CoinsReward = 20,
	},
	SzafkiKsiazki = {
		Id = "SzafkiKsiazki",
		Name = "Uporządkuj Szafkę",
		Location = "Główny Korytarz",
		Description = "Ułóż podręczniki od największego do najmniejszego",
		CoinsReward = 20,
	},
}

-- Memiczne teksty dramatycznego ekranu podsumowania
GameConfig.SummaryTexts = {
	InnocentEjected = "%s był Niewinnym Uczniem. Woźna płacze w kącie.",
	RozrabiakaEjected = "Sukces! %s był Rozrabiaką!",
	TieOrSkipped = "Głosowanie nierozstrzygnięte. Klockowa Policja nikogo nie aresztowała.",
	DyrektorMiss = "Dyrektor rzucił Dziennikiem w niewinnego ucznia i ze wstydu poszedł do gabinetu!",
	DziennikDropped = "Dziennik Dyrektora leży na podłodze! Ktoś może go podnieść!",
}

-- Dźwięki (Roblox Sound IDs)
GameConfig.SoundIds = {
	SadPiano = "rbxassetid://9114223171", -- Smutne, przerysowane pianino
	SchoolBell = "rbxassetid://9114223847", -- Wesoły szkolny dzwonek
	Siren = "rbxassetid://9114224522", -- Syrena policyjna
	CoinPickup = "rbxassetid://9114225010", -- Dźwięk podniesienia monety
	VentWhoosh = "rbxassetid://9114225890", -- Skrzypnięcie kratki wentylacyjnej
	Blackout = "rbxassetid://9114226340", -- Wyłączenie korków / trzask bezpiecznika
}

-- Nazwy RemoteEvents
GameConfig.RemoteEvents = {
	StartMeeting = "StartMeeting",
	CastVote = "CastVote",
	MeetingResult = "MeetingResult",
	TaskCompleted = "TaskCompleted",
	UpdateTaskProgress = "UpdateTaskProgress",
	RoleAssigned = "RoleAssigned",
	GameStateChanged = "GameStateChanged",
	ReportBody = "ReportBody",
	-- Nowe mechaniki MM2 + Among Us:
	TriggerSabotage = "TriggerSabotage",
	SabotageActive = "SabotageActive",
	SabotageFixed = "SabotageFixed",
	UseVent = "UseVent",
	DziennikDropped = "DziennikDropped",
	DziennikPickedUp = "DziennikPickedUp",
	CollectCoin = "CollectCoin",
	UpdateCoins = "UpdateCoins",
	OpenTaskGui = "OpenTaskGui",
}

return GameConfig
