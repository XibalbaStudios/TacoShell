return {
	"Colors",
	"Contexts",
	"Actions",
	"Cheats",
	"CutscenePreview",
	"Sounds",
	"Views","Version",
	function(prefix, env, arg, ext, loader, load)
		for _, key in iterators.APairs("AIParams", "PhysicsParams", "BreakablePieces", "Characters", "GameModes", "Levels", "TrailSettings" ) do
			rawset(env, key, {})

			load(key, prefix, env[key], _G, ext, loader)
		end
	end
}, ...