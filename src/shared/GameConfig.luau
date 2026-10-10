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
	MaxBagCapacity = 50, -- Domyślny limit monet zebranych w jednej rundzie
	VIPBagCapacity = 100, -- Limit dla posiadaczy Gamepassa Plecaka
}

-- Zadania szkolne (Tasks)
GameConfig.Tasks = {
	Matematyka = {
		Id = "Matematyka",
		Name = "Test z Matematyki",
		Location = "Klasa Matematyczna (Sala 201)",
		Description = "Rozwiąż szybkie równanie (np. 7 × 8 = ?)",
		CoinsReward = 15,
	},
	JezykPolski = {
		Id = "JezykPolski",
		Name = "Dyktando z Języka Polskiego",
		Location = "Klasa Humanistyczna (Sala 202)",
		Description = "Wybierz bezbłędną pisownię słowa",
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
		Description = "Ułóż podręczniki na półce w kolejności",
		CoinsReward = 20,
	},
	TestPizzyKsiezula = {
		Id = "TestPizzyKsiezula",
		Name = "Test Pizzy u Księciula",
		Location = "Stołówka / Sklepik Szkolny",
		Description = "Zrób test pizzy ze szkolnego sklepiku za 6 ziko i wystaw ocenę: MUALA!",
		CoinsReward = 25,
	},
}

-- ========================================================
-- MONETYZACJA, GAMEPASSY & PRODUKTY ZA ROBUX (ROBUX SHOP)
-- ========================================================
GameConfig.Gamepasses = {
	VIP = {
		Id = 1827361,
		Name = "👑 Przewodniczący Szkoły (VIP)",
		Price = 249,
		Icon = "👑",
		Description = "Złoty tag [VIP] na czacie i nad głową, stały bonus x2 monety, wstęp do Klubu Samorządu Uczniowskiego!",
	},
	RadioBoombox = {
		Id = 1827362,
		Name = "📻 Szkolny Radiomagnetofon (Boombox)",
		Price = 199,
		Icon = "📻",
		Description = "Puszczaj ulubioną muzykę na korytarzach szkoły i stołówce!",
	},
	SpeedShoes = {
		Id = 1827363,
		Name = "👟 Adidasy Wuefisty (+25% Prędkości)",
		Price = 149,
		Icon = "👟",
		Description = "Zwiększa Twoją prędkość chodzenia o +4 WalkSpeed na zawsze!",
	},
	BigCoinBag = {
		Id = 1827364,
		Name = "🎒 Plecak Turystyczny (Limit 100 monet)",
		Price = 99,
		Icon = "🎒",
		Description = "Zwiększa limit zebranych monet na rundę z 50 do 100!",
	},
	DoubleRoleChance = {
		Id = 1827365,
		Name = "🎲 Podwójna Szansa na Rolę (x2 Chance)",
		Price = 199,
		Icon = "🎲",
		Description = "Podwaja Twoją szansę na wylosowanie Dyrektora lub Rozrabiaki!",
	},
	GoldenKukirin = {
		Id = 1827366,
		Name = "🐉 Mityczny Złoty Kukirin (Mount & Pet)",
		Price = 299,
		Icon = "🐉",
		Description = "Ekskluzywny latający Kukirin wierzchowiec! Daje +50% prędkości, złote cząsteczki i ryk KUKIRIIIIN!",
	},
	ImpostorChance = {
		Id = 1827367,
		Name = "😈 3x Szansa na Rozrabiakę (Impostor Boost)",
		Price = 179,
		Icon = "😈",
		Description = "Aż potrójna szansa na bycie Rozrabiaką w każdej rundzie!",
	},
	DyrektorChance = {
		Id = 1827368,
		Name = "🎓 3x Szansa na Dyrektora (Szef Szkoły Boost)",
		Price = 179,
		Icon = "🎓",
		Description = "Aż potrójna szansa na bycie Dyrektorem ze Szkolnym Dziennikiem!",
	},
	MemeSoundboard = {
		Id = 1827369,
		Name = "📢 Polskie Memy Szkolne & Dźwięki",
		Price = 99,
		Icon = "📢",
		Description = "Odblokowuje menu kultowych polskich tekstów nauczycieli i memów!",
	},
}

-- Pakiety Szkolnych Monet za Robux (Developer Products)
GameConfig.DevProducts = {
	CoinsSmall = {
		Id = 2938471,
		Name = "🪙 Kieszonkowe (100 Monet)",
		Price = 49,
		Coins = 100,
		Icon = "🪙",
	},
	CoinsMedium = {
		Id = 2938472,
		Name = "💰 Wyprawka Szkolna (500 Monet)",
		Price = 149,
		Coins = 500,
		Icon = "💰",
	},
	CoinsLarge = {
		Id = 2938473,
		Name = "💎 Stypendium Dyrektora (2000 Monet)",
		Price = 399,
		Coins = 2000,
		Icon = "💎",
	},
}

-- Ulepszenia postaci za Szkolne Monety (In-game Upgrades)
GameConfig.Upgrades = {
	Speed = {
		Id = "Speed",
		Name = "Kondycja z WF",
		MaxLevel = 3,
		CostPerLevel = 120,
		Stat = "WalkSpeed",
		BoostPerLevel = 1.0,
		Icon = "🏃",
		Description = "+1.0 do Prędkości za każdy poziom",
	},
	Stealth = {
		Id = "Stealth",
		Name = "Cichobiegi na Korytarzu",
		MaxLevel = 2,
		CostPerLevel = 160,
		Stat = "FootstepQuiet",
		BoostPerLevel = 0.5,
		Icon = "🤫",
		Description = "Cichszy odgłos kroków - trudniej cię wytropić!",
	},
	CoinRadar = {
		Id = "CoinRadar",
		Name = "Wzrok Sokoli na Monety",
		MaxLevel = 1,
		CostPerLevel = 250,
		Stat = "CoinRadar",
		BoostPerLevel = 1.0,
		Icon = "👁️",
		Description = "Podświetla złote monety w zasięgu wzroku!",
	},
	PizzaKsiezula = {
		Id = "PizzaKsiezula",
		Name = "Pizza Księciula (MUALA!)",
		MaxLevel = 1,
		CostPerLevel = 150,
		Stat = "PizzaEnergy",
		BoostPerLevel = 1.0,
		Icon = "🍕",
		Description = "Ciepły trójkąt pizzy ze szkolnego sklepiku! Daje okrzyk MUALA i stałe +1 do prędkości!",
	},
}

-- ========================================================
-- SYSTEM KUKIRINÓW (PET & MOUNT SYSTEM)
-- ========================================================
GameConfig.Kukirins = {
	GoldenKukirin = {
		Id = "GoldenKukirin",
		Name = "Mityczny Złoty Kukirin",
		IsGamepass = true,
		GamepassKey = "GoldenKukirin",
		SpeedBoost = 8,
		Color = Color3.fromRGB(255, 215, 0),
		ParticleColor = Color3.fromRGB(255, 235, 100),
		RoarText = "✨ KUKIRIIIIIN! ✨",
		Icon = "🐉",
	},
	SchoolKukirin = {
		Id = "SchoolKukirin",
		Name = "Szkolny Kukirin Biegacz",
		IsGamepass = false,
		Cost = 300, -- Koszt 300 monet w sklepie F2P
		SpeedBoost = 4,
		Color = Color3.fromRGB(50, 160, 220),
		ParticleColor = Color3.fromRGB(100, 200, 255),
		RoarText = "💨 KUKIRIN JEDZIE! 💨",
		Icon = "🐾",
	},
}

-- ========================================================
-- POLSKIE MEMY SZKOLNE (MEME SOUNDBOARD & QUOTES)
-- ========================================================
GameConfig.PolishMemes = {
	{ Id = "Dzwonek", Title = "🔔 Dzwonek jest dla nauczyciela!", Text = "Dzwonek jest dla nauczyciela, a nie dla was! Siadać na miejsca!", Sound = "rbxassetid://9114223847" },
	{ Id = "Kukirin", Title = "🐉 KUKIRIIIIN!", Text = "KUKIRIIIIIN! Giga Kukirin wjeżdża do polskiej szkoły!", Sound = "rbxassetid://9114227555" },
	{ Id = "Kartkowka", Title = "📝 Niezapowiedziana kartkóweczka!", Text = "Wyciągamy karteczki, trzy pytania, rząd pierwszy i drugi!", Sound = "rbxassetid://9114223171" },
	{ Id = "Sklepik", Title = "🍫 Jedno Prince Polo proszę!", Text = "Dzień dobry, poproszę jedno Prince Polo i oranżadę ze szklanej butelki!", Sound = "rbxassetid://9114225010" },
	{ Id = "Nieprzygotowanie", Title = "🙋 Kto zgłasza 'NP'?", Text = "Proszę pani, ja zgłaszam nieprzygotowanie z wczoraj!", Sound = "rbxassetid://9114226340" },
	{ Id = "Sciaga", Title = "👀 On ściąga!", Text = "Proszę pani, a Igor ma ściągę w piórniku i pod ławką!", Sound = "rbxassetid://9114224522" },
	{ Id = "PizzaKsiezula", Title = "🍕 Pizza Księciula: MUALA!", Text = "MUALA! Testujemy pizzę ze szkolnego sklepiku za 6 ziko! Czysta poezja czy zakalec?!", Sound = "rbxassetid://9114227555" },
}

-- Skrzynki ze skinami broni (MM2 Mystery Crates)
GameConfig.Crates = {
	PiornikCrate = {
		Id = "PiornikCrate",
		Name = "Skrzynka Piórnikowa",
		Cost = 50, -- 50 monet
		Icon = "✏️",
		Items = {
			{ Id = "Skin_Linijka", Name = "Drewniana Linijka", Type = "Knife", Rarity = "Common", Color = Color3.fromRGB(180, 140, 90), Weight = 50 },
			{ Id = "Skin_DziennikZielony", Name = "Dziennik Przyrodniczy", Type = "Gun", Rarity = "Common", Color = Color3.fromRGB(34, 139, 34), Weight = 50 },
			{ Id = "Skin_Ekierka", Name = "Aluminiowa Ekierka", Type = "Knife", Rarity = "Rare", Color = Color3.fromRGB(160, 170, 190), Weight = 30 },
			{ Id = "Skin_DziennikZloty", Name = "Złoty Dziennik Laureata", Type = "Gun", Rarity = "Epic", Color = Color3.fromRGB(255, 215, 0), Weight = 15 },
			{ Id = "Skin_CyrkielLaserowy", Name = "Laserowy Cyrkiel Zabójcy", Type = "Knife", Rarity = "Legendary", Color = Color3.fromRGB(255, 40, 160), Weight = 4 },
			{ Id = "Skin_PizzaKsiezula", Name = "Kawałek Pizzy Księciula", Type = "Knife", Rarity = "Legendary", Color = Color3.fromRGB(243, 156, 18), Weight = 4 },
			{ Id = "Skin_DziennikOgnisty", Name = "Płonący Dziennik Dyrekcji", Type = "Gun", Rarity = "Godly", Color = Color3.fromRGB(255, 80, 0), Weight = 1 },
		},
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
	UnboxChime = "rbxassetid://9114227555", -- Dźwięk otwarcia skrzynki MM2
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
	TriggerSabotage = "TriggerSabotage",
	SabotageActive = "SabotageActive",
	SabotageFixed = "SabotageFixed",
	UseVent = "UseVent",
	DziennikDropped = "DziennikDropped",
	DziennikPickedUp = "DziennikPickedUp",
	CollectCoin = "CollectCoin",
	UpdateCoins = "UpdateCoins",
	OpenTaskGui = "OpenTaskGui",
	-- Sklep i Monetyzacja:
	OpenShop = "OpenShop",
	BuyCrate = "BuyCrate",
	CrateOpened = "CrateOpened",
	BuyUpgrade = "BuyUpgrade",
	EquipSkin = "EquipSkin",
	PromptGamePass = "PromptGamePass",
	PromptDevProduct = "PromptDevProduct",
	SyncPlayerData = "SyncPlayerData",
	-- Kukiriny, Memy i Preferencje Ról:
	ToggleKukirin = "ToggleKukirin",
	SetRolePreference = "SetRolePreference",
	PlayMemeQuote = "PlayMemeQuote",
	BroadcastMeme = "BroadcastMeme",
}

return GameConfig
