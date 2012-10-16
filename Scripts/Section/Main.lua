-----------
-- Imports
-----------
local ipairs = ipairs
local ActionMap = contexts.ActionMap
local AddEventBatch = tasks.AddEventBatch
local AddEventSequence = tasks.AddEventSequence
local AttachToRoot = widgetops.AttachToRoot
local CueMusic = audio.CueMusic
local FocusChain = contexts.FocusChain
local GetEventStream = section.GetEventStream
local GetLookup = section.GetLookup
local GetRenderContext = objects.GetRenderContext
local GetScreenSize = game.GetScreenSize
local Image = ui.Image
local MarkTask = section.MarkTask
local New = class.New
local NoOp = funcops.NoOp
local PurgeAttachList = widgetops.PurgeAttachList
local Picture = graphicshelpers.Picture
local SectionGroup = contexts.SectionGroup
local SetNetConfig = network.SetConfig
local String = ui.String
local UIGroup = contexts.UIGroup
local AddToPlayerCounter = Achievements.AddToPlayerCounter
local UseDemoMode = game.UseDemoMode
-- to cleanup
local AttachIcon = ui.AttachIcon

local Screen = section.Screen
local OpenScreen = section.OpenScreen
local ClientAssignPlayerIdRequest = network.ClientAssignPlayerIdRequest
local ClientPlayerSelectRequest = network.ClientPlayerSelectRequest
local SetMatchVariable = SetMatchVariable
local MapKV = table_ex.MapKV
local LevelDebug = cheat_mode
local ScaleFade = transitions.ScaleFade
local MoveWidget = transitions.MoveWidget
local MoveWidgetBatch = transitions.MoveWidgetBatch
local FadeWidget = transitions.FadeWidget
local GetStringSize = widgetops.StringSize

local StringSize = widgetops.StringSize


--extra stuff for the progress dialog
local SetupScreen = section.SetupScreen
local GetValue = persistent.GetPlayerValue
local GetLanguage = settings.GetLanguage
local GetSortedKeys = opbuilders.GetSortedKeys
local APairs = iterators.APairs

-- end

---------------------------------------
-- Snowfall effect; menu field of view
---------------------------------------
local xFOV

-----------
-- Widgets
-----------

-- Layers

local Pane
local BlockSection


local FadeLayer
local Transition, Fade

local DialogFadeLayer
local DialogTrans, DialogFade

local Logo

-- Debug
local GuiTest = cheat_mode.GuiTestMenu or false


local KeyLogic
local StoryModeBtn
local Buttons, Icons
local ExitBtn, ExitIcon
local CurrentMenu
local LeftDecor, RightDecor

local function OpenDialog( dialog )
	--we disallow everything but the dialog to be tested
	BlockSection()
	Pane:Allow("attach_list_test", false) 
	--promotion to prevent drawing order conflicts with the slide infos
	DialogFadeLayer:Promote()
	DialogFadeLayer:Allow("render", true )
	DialogFade("forward")
	GetEventStream("between_frames"):Add(function()
			SectionGroup():Open(dialog)
		end)
end

local function Exit()
	OpenDialog("WannaExit")
end

local DecorMov
local function PerformCommand(which, option)
	local vw, vh = GetScreenSize()
	FadeLayer:Promote()
	BlockSection()
	AddEventBatch("enter_update", 
			MoveWidget(Logo, .5, { dy = -512 }),
			MoveWidget(LeftDecor,	0.35,	{ dx = -DecorMov }),
			MoveWidget(RightDecor,	0.35,	{ dx = DecorMov}) )
			
	if which == 1 then
		Fade("reverse",function () Screen("LocalMatchConfig", nil, "SinglePlayer", "Main") end)
	elseif which == 2 and option == "new" then
		Fade("reverse", function () Screen("StoryMode") end)
	elseif which == 2 and option == "continue" then
		Fade("reverse", function () Screen( "StoryProgres" ) end)
	elseif which == 3 then
		Fade("reverse", function () Screen("MultiPlayer") end)
	elseif which == 4 then
		Fade("reverse", function () Screen("AchievementsMenu") end)
	elseif which == 5 then
		Fade("reverse", function () Screen("Help") end)
	elseif which == 6 then
		Fade("reverse", function () Screen("Options") end)
	elseif which == 7 then
		if GuiTest then
			Fade("reverse", function () Screen("GuiTestArea") end)
		else
			Exit()
		end
	else
		Fade("reverse", function () Screen("GuiTestArea") end)
	end
end






local MusicVol
local FirstTime = true
local PlayerLabel, PlayerStr
-- Install the main screen.
section.Load("Main", function(state, data, ...)
	local vw, vh = GetScreenSize()
	-- Load --
	if state == "load" then
		
		Pane =		ui.Backdrop(true, Picture("Textures/gui/menu/home_ice_background.jpg"))
		LeftDecor =		ui.Image("Textures/gui/menu/home_ice_left.png")
		RightDecor =	ui.Image("Textures/gui/menu/home_ice_right.png")

		local logo_pics = table_ex.Weak("k")

		Logo =			ui.Image ( function ()
			local _, vh = GetScreenSize()
			local file

			if ui.WhichSize( vw ) ~= "normal" then
				if UseDemoMode() then
					file = "Textures/gui/Menu/Main/main_logo_demo_sm.png"
				else
					file = "Textures/gui/Menu/Main/main_logo_sm.png"
				end
			else
				if UseDemoMode() then
					file = "Textures/gui/Menu/Main/main_logo_demo.png"
				else
					file = "Textures/gui/Menu/Main/main_logo.png"
				end
			end

			logo_pics[file] = logo_pics[file] or Picture(file)

			return logo_pics[file]
		end)

		-- Layers for fade effects
		FadeLayer, Transition, Fade = ui.FadePane{ duration = .45, color1 = "black", color2 = "white" }
		-- Layer for "highlighting dialogs 
		local dialogFadeColor =  UseDemoMode() == true and New("Color", 32,32,32 ) or New("Color", 128,128,128 )
		DialogFadeLayer, DialogTrans, DialogFade = ui.FadePane{ duration = 0.35, color1 = "white", color2 = dialogFadeColor }
		DialogFadeLayer:Allow("render", false )
		DialogFadeLayer:Allow("test", false )
		FadeLayer:Allow("test", false )
		Pane:Allow("attach_list_test", true )


		-- cache default FOV
		xFOV = GetRenderContext():GetFOV()

		-- Load buttons and their icons.
		if not UseDemoMode() then
			StoryModeBtn = ui.SlideInfo( function (font) return font:GetOps().format(" %s", GetLookup(data).storymode) end, 2)
			StoryModeBtn:Append( function () return GetLookup(data).newgame end )
			StoryModeBtn:Append( function () return GetLookup(data).continue end )
			
			
			StoryModeBtn:SetSignal("switch_to", function ( S, what )
				if what == "set_heading" then
					local which = S:Heading()
					if which == 1 then
						PerformCommand( 2, "new" )
					else
						PerformCommand( 2, "continue" )
					end
					
				end
			end)
		else
			StoryModeBtn = ui.PushButton(nil , function (font) return font:GetOps().format(" %s", GetLookup(data).storymode) end)
		end
		
		Buttons = table_ex.Map(
					{ function () PerformCommand(1) end ,
					  NoOp,
  					  function () PerformCommand(3) end,
					  function () PerformCommand(4) end,
					  function () PerformCommand(5) end,
					  function () PerformCommand(6) end
					 },ui.PushButton)
		Buttons[2] = StoryModeBtn
		
		Icons = table_ex.Map({
					  "Textures/gui/menu/main/icon_single.jpg",
					  "Textures/gui/menu/main/icon_story.jpg",
					  "Textures/gui/menu/main/icon_multiplayer.jpg",
					  "Textures/gui/menu/main/icon_street.jpg",
					  "Textures/gui/menu/main/icon_help.jpg",
					  "Textures/gui/menu/main/icon_options.jpg"
					  }, ui.Image)

		--TODO this can be done with an iterator, but right now with the guitestarea it's messy
		Buttons[1]:SetString( function (font) return font:GetOps().format(" %s", GetLookup(data).singleplayer) end )
		Buttons[3]:SetString( function (font) return font:GetOps().format(" %s", GetLookup(data).multiplayer) end )
		Buttons[4]:SetString( function (font) return font:GetOps().format(" %s", GetLookup(data).streetcred) end )
		Buttons[5]:SetString( function (font) return font:GetOps().format(" %s", GetLookup(data).help )end )
		Buttons[6]:SetString( function (font) return font:GetOps().format(" %s", GetLookup(data).option) end)
		
		if GuiTest then
			local GuiTestIndex = #Buttons + 1
			Buttons[GuiTestIndex] = ui.PushButton( function () PerformCommand(GuiTestIndex) end,  "GuiTest" )
			Icons[GuiTestIndex] = ui.Image("Textures/gui/menu/main/icon_options.jpg")
		end
		
		
		
		--
		
		PlayerLabel = ui.String( function () return GetLookup(data).player end )
		PlayerStr = ui.String( function () return persistent.GetCurrentPlayer() end )
		PlayerStr:SetColor( "string", HighlightedText ) 
		
		
		
		ExitBtn = ui.ExitPushButton( Exit, function () return GetLookup(data).exit end  )
		Buttons[#Buttons + 1] = ExitBtn
		for i, button in ipairs( Buttons ) do
			ui.EnterSignalHandler( button, FocusChain( data) )
		end
		CurrentMenu = 1
		KeyLogic = ui.KeyLogic(.5)

		-- Seed the Tausworthe generator.
		math.randomseed(os.time())

	-- Open --
	elseif state == "open" then
		BlockSection = ui.InputBlocker( data )
		BlockSection()
		
		if not contexts.InMouseMode() then
			contexts.ToggleMouseMode()
		end
		
		if FirstTime then
			CueMusic("398_GameTheme.ogg")
			FirstTime = false
		end
		
		--Reset the dialog fading and stop it from rendering,
		--Ensure that the main pane can be tested
		DialogTrans:Stop(true)
		DialogFadeLayer:Allow("render", false )
		Pane:Allow("attach_list_test", true )
		-- restore default FOV
		GetRenderContext():SetFOV(xFOV, 0)

		-- Default network setup
		SetNetConfig("offline")

		AttachToRoot(Pane, 0, 0, vw, vh, true)
		Pane:Attach( FadeLayer, 0,0, vw, vh )
		Pane:Attach( DialogFadeLayer, 0, 0, vw, vh )
		Fade("forward")
		
		 
		local rowsep = vh / 30		-- separation between rows
		local buttonw = ui.WhichSize( vw ) == "micro" and 256 or ( ui.WhichSize( vw ) == "small"  and 256 or 448)
		local buttonh = ui.WhichSize( vw ) ~= "normal" and 32 or 64	-- button height
		local rowoff = buttonh		-- offset for each new row
		local buttonsep = buttonh	-- button separation
		
		local startx, starty = vw - buttonw - buttonsep, vh* 9 / 16
				
		-- #Buttons - 1 is because the exit button doesn't follow the same rules for spacing,
		local y
		for i = 1, #Buttons - 1 do
			local row = math.floor((i-1) / 2)
			local placeinrow = (i)%2 == 1 and 1 or 2
			local x = startx + (rowoff * ( row )) + ((buttonw + buttonsep) * (placeinrow - 1))
			y = starty + ((buttonh + rowsep )* row)
			Pane:Attach( Buttons[ i ], x, y, buttonw, buttonh )
			ui.AttachIcon( i, Buttons[ i ], Icons, buttonh, buttonh )
			Buttons[ i ]:SetTextSetup("left", buttonh, 0 )
		end
				
		ui.AttachExitButtonToPane( Pane, Buttons[#Buttons], nil, nil , vw/2 )
		
		-- if, for whatever reason, the game is crippled, we block the story mode,
		-- multiplayer and achievements 
		if UseDemoMode() then
			for _, i in APairs( 2, 4 )do
				Buttons[i]:SetPicture("main",		Picture("Textures/gui/menu/main/button_grey.jpg"))
				Buttons[i]:SetPicture("entered",	Picture("Textures/gui/menu/main/button_grey_high.jpg"))
				Buttons[i]:SetPicture("grabbed",	Picture("Textures/gui/menu/main/button_grey_high.jpg"))
				
				if class.Type(Buttons[i]) == "PushButton" then
					Buttons[i]:SetAction(function() end )
				else
					Buttons[i]:SetSignal("switch_to", function(S, what) end )
				end
				
			end
			
			local CrippleString = ui.String( function () return GetLookup(data).cripple or "Activate the game in order to use this feature"end, "MicroMessage" )
			CrippleString:SetSignal("render", function ( S, x,y,w,h )
				local index = FocusChain(data):GetIndex()
				if index == 2 or index == 4 then
					widgetops.DrawString(S, S:GetString(), nil, nil, x, y, w, h)
				end
			end)
			--Pane:Attach( CrippleString, (vw - CrippleString:GetW()) / 2, vh * 0.9 )
		end
		
		-- Attach the logo and decorations.
		local logodim	= ui.WhichSize( vw ) == "micro" and 256 or 512
		local DecorW	= ui.WhichSize( vw ) == "micro" and 256 or 512
		local DecorH	= DecorW * 2
		local DecorY	= ui.WhichSize( vw ) == "small" and ((vh/2- DecorH/2) + vh * 0.1 ) or vh/2- DecorH/2
		
		Pane:Attach( Logo, vw/2 - (logodim / 2) , -logodim, logodim, logodim )
		
		Pane:Attach( LeftDecor,	0 - DecorW, DecorY, DecorW, DecorH)
		Pane:Attach( RightDecor,	 vw,		DecorY, DecorW, DecorH)
		
		-- Move Sequences for Logo , Buttons and Foreground Characters
			-- Buttons
		AddEventSequence("enter_update",
			MoveWidgetBatch(Buttons, .4, { dx = -vw/2 }),
			function()
				
				FocusChain(data):Load(Buttons)
				FocusChain(data):SetFocus(CurrentMenu)
			end,
			function ()
				if not UseDemoMode() then
					ui.AttachCompositeString( PlayerLabel, PlayerStr, Pane, "center", 0, y + buttonh * 1.5 )
				end
			end,
			section.Unblock
		)
		
			--  logo and decorations movement
		
		DecorMov = ui.WhichSize( vw ) == "small" and DecorW * 0.85 or DecorW
		AddEventBatch("enter_update",
			MoveWidget(Logo,		0.7,	{ dy = ui.WhichSize( vw ) == "micro" and 256 or 512  , yfunc=transitions.Bounce }),
			MoveWidget(LeftDecor,	0.35,	{ dx = DecorMov }),
			MoveWidget(RightDecor,	0.35,	{ dx = -DecorMov})
		)
		
		
		-- Check for users, if there are none, we force the player to input a gamer tag, 
		-- if there are, we log-in the last known user
		local LastUser = UseDemoMode() and "Demo" or persistent.GetGlobalValue("LastUserSession")
		if not LastUser then
			OpenDialog("NewGamerTag")
		else
			persistent.SetCurrentPlayer( LastUser )
			Achievements.LoadAchievementData()
			persistent.Save()
		end
		
	-- Trap --
	elseif state== "resume" then 
		
		BlockSection()
		
		DialogFade("reverse", function ()
			Pane:Allow("attach_list_test", true ) 
			section.Unblock(data) 
			end )

	elseif state == "update" then
		KeyLogic( FocusChain(data),...)
		
	elseif state == "trap" then
		
		local AM = ActionMap()
		local chain = FocusChain(data)
		local index = chain:GetIndex()
		local dy = AM:GetAnalogValue("movey")
		local focus = chain:GetFocus()
		-- The SetFocus logic is a little complex because of the way it need to behave
		-- with the exit button
		if dy ~= 0 then
			if  class.Type(focus) ~= "SlideInfo" or not focus:IsOpen() then
				if dy < 0 then
					chain:SetFocus( index + 2 <= #chain and index + 2 or( index + 1 <= #chain and index + 1 or index ))
				else
					chain:SetFocus( index - 2 > 0 and ( index == #chain and index - 1 or index -2 )or index)
				end
			end			
		end
		
		local dx = ActionMap():GetAnalogValue("movex")
		if dx ~= 0 then
			
			if  class.Type(focus) ~= "SlideInfo" or not focus:IsOpen() then
				if dx > 0 then
					chain:SetFocus( index % 2 == 0 and index or (index + 1 > #chain and index or index + 1 ) )
				else
					chain:SetFocus( index % 2 == 0 and index - 1 or (index == #chain and index -1 or index))
				end	
			end
		end
		
		if AM:GetButtonState( "confirm" ) == "justpressed" then
			if class.Type( focus ) == "PushButton" then
				focus:GetAction()()
			else 
				if focus:IsOpen() then
					if not UseDemoMode() then
						PerformCommand( index, focus:Heading() == 1 and "new" or "continue" )
					end
				end
			end
		end
		
		CurrentMenu = chain:GetIndex()
			
		--end
		
---------------
--   Debug   --
---------------

		if ActionMap():GetButtonState("debugger") == "justpressed" then
		
					
					
					SetMatchVariable("map_id",LevelDebug.MapId)
					SetMatchVariable("map_music",LevelDebug.MapId)
					SetMatchVariable("mode_id",LevelDebug.ModeId)
					SetMatchVariable("map_name",LevelDebug.MapName)
					SetMatchVariable("mode_name",LevelDebug.ModeName)
					SetMatchVariable("model_name",LevelDebug.ModelName)
					AddToPlayerCounter(LevelDebug.ModelName)
					ClientAssignPlayerIdRequest(1, LevelDebug.GameTag)

					ClientPlayerSelectRequest(1, LevelDebug.ModelName)
					SetMatchVariable( "StoryGame",false )
					LaunchMatch() 
					

					
		end


---------------
-- End Debug --
---------------
	-- Close --
	elseif state == "close" then
			PurgeAttachList(Pane)
			Pane:Detach()
			Transition:Stop(true)
			DialogTrans:Stop(true)
	end
end, "Main_lua")