--!strict
-- src/shared/GameConfig.luau
-- Centralna konfiguracja i stałe gry "Szkolny Detektyw"

local GameConfig = {}

-- Role w grze
GameConfig.Roles = {
	Student = "Uczen",
	Wozna = "Wozna",
	Dyrektor = "Dyrektor",
	Rozrabiaka = "Rozrabiaka",
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
}

-- Zadania szkolne (Tasks)
GameConfig.Tasks = {
	Matematyka = {
		Id = "Matematyka",
		Name = "Test z Matematyki",
		Location = "Klasa Matematyczna",
		Description = "Rozwiąż szybkie równanie (np. 2 + 2 = ?)",
		CoinsReward = 15,
	},
	JezykPolski = {
		Id = "JezykPolski",
		Name = "Dyktando z Języka Polskiego",
		Location = "Klasa Humanistyczna",
		Description = "Przepisz słowo z tablicy bez błędu",
		CoinsReward = 15,
	},
	StolowkaPierogi = {
		Id = "StolowkaPierogi",
		Name = "Zjedz Szkolny Obiad",
		Location = "Stołówka",
		Description = "Zjedz porcję pierogów (5 kliknięć)",
		CoinsReward = 20,
	},
	SzafkiKsiazki = {
		Id = "SzafkiKsiazki",
		Name = "Uporządkuj Szafkę",
		Location = "Korytarz",
		Description = "Ułóż podręczniki od największego do najmniejszego",
		CoinsReward = 20,
	},
}

-- Memiczne teksty dramatycznego ekranu podsumowania
GameConfig.SummaryTexts = {
	InnocentEjected = "%s był Niewinnym Uczniem. Woźna płacze w kącie.",
	RozrabiakaEjected = "Sukces! %s był Rozrabiaką!",
	TieOrSkipped = "Głosowanie nierozstrzygnięte. Policja nikogo nie aresztowała.",
	DyrektorMiss = "Dyrektor rzucił Dziennikiem w niewinnego ucznia i sam poniósł konsekwencje!",
}

-- Dźwięki (Roblox Sound IDs)
GameConfig.SoundIds = {
	SadPiano = "rbxassetid://9114223171", -- Smutne, przerysowane pianino
	SchoolBell = "rbxassetid://9114223847", -- Wesoły szkolny dzwonek
	Siren = "rbxassetid://9114224522", -- Syrena policyjna
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
}

return GameConfig
