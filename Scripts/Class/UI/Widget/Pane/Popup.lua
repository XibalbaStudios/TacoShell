-- See TacoShell Copyright Notice in main folder of distribution

-----------
-- Imports
-----------
local SuperCons = class.SuperCons

--------------------------
-- Popup class definition
--------------------------
class.Define("Popup", {
	-- Adjusts the popup for minimization and the snap chain
	-- ay: Popup y-coordinate used by adjustment
	-- ah: Popup height used by adjustment
	---------------------------------------------------------
	Adjust = function(P, ay, ah)
		-- Accumulate the snap chain element heights and y-offsets.
		local sh = 0

		for pane in P:SnapChain() do
			sh = sh + pane.sy + pane:GetRect("h")
		end
		
		-- If the popup or its snap chain spills off the screen, move it up as necessary.
		ay = math.min(ay, gfx.GetYRes() - ah - sh - 1)

		P:SetRect("yh", ay, ah)
		
		-- Reposition each snap chain element relative to the popup.
		local x, y = P:GetRect("x"), ay + ah

		for pane in P:SnapChain() do
			pane:SetLocalPos(x + pane.sx, y + pane.sy)
			y = y + pane.sy + pane:GetRect("h")
		end
	end,
	
	-- Builds an iterator over the snap chain
	-- Returns: Iterator which returns handles
	-------------------------------------------
	SnapChain = function(P)
		return function(_, pane)
			return pane.snap;
		end, nil, P
	end,	

	-- Snaps the pane to the popup
	-- pane: Pane to snap
	-- x, y: Relative element coordinates
	--------------------------------------
	SnapPane = function(P, pane, x, y)
		P.snap, pane.sx, pane.sy = pane, x, y

		-- Adjust to account for the addition.
		P:Adjust(P:GetRect("yh"))
	end
},

-- Constructor
-- group: Group handle
-----------------------
function(P, group)
	SuperCons(P, "Pane", group)

	-- Signals --
	P:SetSignal("update", function(x, y, w, h)
		P:DrawPicture("B", x, y, w, h)
		P:DrawFrame("D", x, y, w, h)
	end)
end, { base = "Pane" })