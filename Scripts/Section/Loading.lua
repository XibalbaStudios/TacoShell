-- Imports --
local EnterCaptureMode = EnterCaptureMode
local LeaveCaptureMode = LeaveCaptureMode
local Reset = coroutine_ex.Reset
local SetupScreen = section.SetupScreen
local Wait = coroutineops.Wait

-- Widgets --
local vehImage

-- Name lookup --
local Names = { "adrian", "ashley", "billy", "bones", "enrique", "hanna" }

-- No unload flag --
local NoUnload

-- Loading coroutine --
local Run = coroutine_ex.Create(function(data)
	while true do
		Wait(8, function(time, duration)
			local vw, vh = gfx.GetRes()

			vehImage:SetX(-1024 + vw * 2  * time / duration)
			vehImage:SetY(vh / 2)
		end)
	end
end)

-- Install the loading screen.
section.Load("Loading", function(state, data, ...)
	-- Load --
	if state == "load" then
		data.pane = ui.Backdrop(false)
		data.exit = ui.String()

	-- About to load --
	elseif state == "about_to_load" then
		NoUnload = game.WantsToRetry()

	-- Open / Update --
	elseif state == "open" or state == "update" then
		if state == "open" then
			SetupScreen(data, true)

			data.exit:SetColor("string", HighlightedText)

			vehImage = vehImage or ui.Image(string.format("Textures/gui/menu/loadings/%s_trail_load.png", Names[math.random( 1, 6 )]))

			data.pane:Attach(vehImage)
			data.pane:Attach(ui.Image("Textures/Gui/Menu/home_ice_background.jpg"), 0, 0, gfx.GetRes())

			LeaveCaptureMode()

			contexts.TurnMouseOff()
		end

		-- Common update logic.
		Run(data)

	-- Close --
	elseif state == "close" then
		-- If the level has been loaded, ditch the character image and state.
		if not NoUnload then
			Reset(Run)

			vehImage = nil

		-- Otherwise, cover up the background scene.
		else
			EnterCaptureMode()
		end

		NoUnload = false
	end
end, "Loading_lua")