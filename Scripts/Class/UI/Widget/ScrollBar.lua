-- See TacoShell Copyright Notice in main folder of distribution

-----------
-- Imports
-----------
local New = class.New
local SuperCons = class.SuperCons

----------------------
-- Stock signal table
----------------------
local Signals = {
	drop = function(S)
	end,
	grab = function(S)
	end,
	update = function(S)
	end
}

------------------------------
-- ScrollBar class definition
------------------------------
class.Define("ScrollBar", {

},

-- Constructor
-- group: Group handle
-----------------------
function(S, group)
	SuperCons(S, "Widget", group)

	-- Install a scroll timer.
	S.timer = New("Timer")

	-- Signals --
	S:SetMultipleSignals(Signals)
end, { base = "Widget" })

-- Gets the scroll bar part rectangle
-- S: Scroll bar handle
-- bVert: If true, scroll bar is vertical
-- Returns: Bar rectangle
------------------------------------------
local function GetBarRect (S, bVert)
	local offset = S:GetOffset()
--	local bx, by = 
--	return offset
end
--[[
------------------------------
-- ScrollBar class definition
------------------------------
class.Define("ScrollBar", {},

-- Constructor
-- group: Group handle
-- as: Arrow size
-- ms: Minimum bar size
------------------------
function(S, group, as, ms)
	SuperCons(S, "Widget", group)
	
	-- Assign format parameters.
	S.as, S.ms = as, ms

	-- Bar used to manipulate scroll bar.
	S.bar = S:CreatePart()
	
	-- Arrows used to manipulate scroll bar.
	S.garrow, S.larrow = S:CreatePart(), S:CreatePart()

	-- Key press timer.
	S.press = class.New("Timer", function()
		if S:IsPressed() and S:IsEntered() then
			-- Approach snap point
		elseif S.larrow:IsPressed() and S.larrow:IsEntered() then
			-- Scroll up/left
		elseif S.garrow:IsPressed() and S.garrow:IsEntered() then
			-- Scroll down/right
		end
	end)
			
	-- Signals --
	S:SetSignal{
		event = function(event)
			-- On grabs, cue the snap timer.
			if event == WE.Grab then
			--	
						
			-- Get the off-center position on bar grabs. Cue the scroll timer otherwise.
			elseif event == WE.GrabPart then
				if S.bar:IsGrabbed() then
--					S.dOffset = Offset(S, GetThumbPosition(S, bVert, false), bVert)
				else
				--	
				end
	
			-- Fit the offset to account for drags.
			elseif event == WE.PostUpkeep and S.bar:IsGrabbed() then
--				S:SetOffset(Offset(S, S.sc, bVert) - S.dOffset)
			end		
		end,
		test = function(cx, cy, x, y, w, h)
			-- If the cursor hits the slider, find the box centered at the current offset. If
			-- the cursor hits this box as well, it is over the thumb.
--			local tx, ty = GetThumbPosition(S, bVert, true)
--			if PointInBox(cx, cy, x + tx * w, y + ty * h, S.tw * w, S.th * h) then
--				return S.thumb
--			end
			return S
		end,
		update = function(x, y, w, h)
			S:DrawPicture("B", x, y, w, h)
			
			-- Draw the part graphics.
			for _, part in ipairs{ "bar", "larrow", "garrow" } do
				local bG, bE, suffix = S[part]:IsGrabbed(), S[part]:IsEntered(), "D"
				if bG and bE then
					suffix = "G"
				elseif bG or bE then
					suffix = "E"
				end
--				S:DrawPicture(part .. suffix, x + tx * w, y + ty * h, S.tw * w, S.th * h)
			end
		end
	}
end, { base = "Widget" })]]