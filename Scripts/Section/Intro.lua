local ipairs = ipairs
local ActionMap = contexts.ActionMap
local AttachToRoot = widgetops.AttachToRoot
local CueMusic = audio.CueMusic
local GetEventStream = section.GetEventStream

local Screen = section.Screen


local video

-- Layout Cache Test
local Transition, Fade
local FadeLayer

local function  ToMain()
	audio.StopAllMusic()
	contexts.SectionGroup(0):Send("Loading", "about_to_load")
	game.LoadScene("select.vscene")
	section.OpenScreen("Main")()	
	
	
end

local test = false
local musicVol
local VW, VH = 512, 512
section.Load("Intro", function(state, data, ...)
	


	-- intro load
	if state == "load" then
		data.pane = ui.Backdrop( false, graphicshelpers.Picture(gfx.DrawSolidQuad, { color = class.New("Color",218,218,218 ) } ) )
		FadeLayer, Transition, Fade = ui.FadePane{ duration = 0.75, color1 = "black", color2 = "white" }
		video = ui.Video( "Video/LogoXibalba.ogg", VW , VH, false, 30 )
		--trying to detect a mouse click
		--video:SetSignal( "grab", ToMain )
		

	-- Open --
	elseif state == "open" then
		musicVol = audio.GetMusicVolume()
		audio.SetMusicVolume( 0.5 )
		CueMusic("logo_sound.ogg", 1)

		local x , y = gfx.GetRes()
		AttachToRoot(data.pane,0,0, x,y)
		data.pane:Attach( FadeLayer, 0, 0,x,y  )
		data.pane:Attach( video, (x - VW )/2, (y - VH )/2, VW, VH )
		--data.pane:Attach( video, 0,0,x,y )
		--video:GetPicture("main"):GetGraphic():EnterFullScreen()
		
		Fade("forward")
		
		--tasks.AddEventSequence("enter_update",
			--function()
				--return not video:GetPicture("main"):GetGraphic():IsDone() or nil
			--end,
			--function () data.blocked = true end,
			--function () 
				--test = true
				----ToMain()
			--end
		--)
			--
	
	
	-- keyboard input
	elseif state == "trap" then
		if   ActionMap():GetButtonState( "confirm" ) == "justpressed" or test then
			ToMain()
		end
	-- end of menu
	elseif state == "update" then
		if video:GetPicture("main"):GetGraphic():IsDone() then
			test = true
		end
	elseif state == "close" then
		musicVol = musicVol > 0.5 and 0.5 or musicVol
		audio.SetMusicVolume( musicVol )
		--video:GetPicture("main"):GetGraphic():LeaveFullScreen()
		video:Detach()
			
		video = nil

	end

end)


