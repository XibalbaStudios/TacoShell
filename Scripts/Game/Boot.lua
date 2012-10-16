return function(prefix, env, _, ext, loader)
	return {
		"Persistent",
		"UI",
		"Effects",
		"Event",
		"Physics",
		{
			name = "Events",

			"Moves",
			"Snowball"
		},
		"Trail",
		"Game",
		{
			name = "Hud",

			"Hud",
			"ScreenMessages",	
			"AchieveWindow",
			"Player",
			"PopupScores",
			"Reticle",
			"Timer",			
			"TrafficLight",
			"minimap"
		},
		"Action",
		"Mode",
		{
			name = "Effects/Break",

			"Crumble",
			"Fold",
			"Scatter"
		}, {
			name = "Messages",

            "ObjectMessages",
            "Feelers",
			"Monkey",
			"Player",
			"Object"
		}, {
			name = "Modes",

			"BattleRoyale",
			"CaptureTheFlag",
			"CaptureTheMonkey",
			"Rings",
			"Snake"
		}, {
			name = "Moves",

			"BallOfAngst",
			"Fire",
			"Glove",
			"Jump",
			"Laser",
			"Pucks",
			"Ray",
			"SaltBomb"
		},
		"SoundPreloader",
		{
			name = "Phases",

			"After",
			"Before",
			"Main",
			"Shutdown"
		}
	}, prefix, env, { events = class.New("Stream"), hud = {}, modes = {}, phase_events = {} }, ext, loader
end, ...