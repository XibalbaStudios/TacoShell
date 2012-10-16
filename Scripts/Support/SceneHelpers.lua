----------------------------
-- Standard library imports
----------------------------
local assert = assert
local insert = table.insert
local ipairs = ipairs
local pairs = pairs

-----------
-- Imports
-----------
local ActionMap = contexts.ActionMap
local APairs = iterators.APairs
local Copy = table_ex.Copy
local _G = _G
local GetFM_Loader = game.GetFM_Loader
local GetLanguage = settings.GetLanguage
local GetScreenSize = game.GetScreenSize
local GetTimeDifference = engine.GetTimeDifference
local Load = Load
local MoveWidgetBatch = transitions.MoveWidgetBatch
local MoveWidgetsOrSkip = transitions.MoveWidgetsOrSkip
local MultiPicture = graphicshelpers.MultiPicture
local New = class.New
local Texture = graphicshelpers.Texture
local WaitForMultipleSignals = coroutineops.WaitForMultipleSignals
local WaitForSignal = coroutineops.WaitForSignal
local WaitWhile = coroutineops.WaitWhile
local WaitWhile_Method = coroutineops.WaitWhile_Method


local GetEventStream=section.GetEventStream
local ResizeDialog=transitions.ResizeDialog
local CueMusic = audio.CueMusic
local ScaleMove=transitions.ScaleMove
local MoveWidget=transitions.MoveWidget
local PlaceWidget=transitions.PlaceWidget
local FadeWidget= transitions.FadeWidget

local WithTimer = tasks.WithTimer
local GetScreenSize=game.GetScreenSize
local Screen = section.Screen

-------------------
-- Delayed imports
-------------------
local String
local Textbox

-- Export scene helpers namespace.
module "scenehelpers"

---------------
-- Scene state
---------------
local State

--
------------------------
function Setup (layers, state, pane)
    State = state

    for _, name in ipairs(layers) do
        -- STUFF
    end
end

-- Waits while putting widgets into position
-- widgets, time, how, options: Transition arguments
-----------------------------------------------------
function MoveWidgetsAndWait (widgets, time, how, options)
    options = Copy(options or {})

    if not options.bNoSkip then
        function options.prep (interp)
            if State.bDoneWaiting then
                interp:RunTo(1)
                interp:Stop()

                State.bDoneWaiting = false
            end
        end
    end

    WaitWhile(MoveWidgetBatch(widgets, time, how, options))
end

do
    -- Attaches a string to await confirmation to proceed
    -- pane: Pane handle
    -- x, y: String coordinates
    -- bFromRight: If true, x-coordinate is counted from right-to-left
    -- bFromBottom: If true, y-coordinate is counted bottom-to-top
    -- Returns: String handle
    -------------------------------------------------------------------
    function PostNextString (pane, x, y, bFromRight, bFromBottom)
		String = String or _G.ui.String

        local S, vw, vh = String(strs[GetLanguage()]), GetScreenSize()

        pane:Attach(S, bFromRight and vw - (S:GetW() + x) or x, bFromBottom and vh - (S:GetH() + y) or y)

        return S
    end
end

-- Attaches a textbox, optionally waiting for it to fill
-- pane: Pane handle
-- options: Language options for string
-- x, y: Textbox coordinates
-- w, h: Textbox dimensions
-- bWait: If true, wait for textbox to fill
-- emitrate: Optional delay between character emissions
-- Returns: Textbox handle
---------------------------------------------------------
function PostTextbox (pane, options, x, y, w, h, bWait, emitrate)
	Textbox = Textbox or _G.ui.Textbox

    local T = Textbox(emitrate or .02)

    T:SetString(options[GetLanguage()])

    pane:Attach(T, x, y, w, h)

    if bWait then
        WaitWhile_Method(T, "IsActive")
    end

    return T
end

-- Idles until a confirmation is received
-- duration: Optional timeout duration
-- ...: Widgets to unload after wait
-- Returns: If true, confirmation occurred
-------------------------------------------
function WaitForConfirmation (duration, ...)
    State.bDoneWaiting = false

	local timer

	if duration then
		timer = New("Timer")

		timer:Start(duration)
	end

    local bDone = WaitForMultipleSignals(function(index)
		if index == 1 then
			return State.bDoneWaiting
		else
			return duration and timer:Check() > 0
		end
	end, 2, "any", timer and function()
		timer:Update(GetTimeDifference())
	end or nil)

    for _, widget in APairs(...) do
        widget:Detach()
    end

    return bDone
end

--Returns fadein or fadeout functions for a widget
--
function FadeWidgetForOptions(col)
    return function(t) --Fade In
            col.a=t*255
        end,
    function(t)	--Fade Out
            col.a=(1-t)*255
    end		
end

-- Loads script variables
-- name: Script name
-- Returns: Variables table
----------------------------
function LoadVars (name)
	local vars = {}

	Load(name, "Scenes/", vars, _G, nil, GetFM_Loader())--"../Scripts/Scenes/", vars, _G)

	return vars
end


