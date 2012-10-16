-- See TacoShell Copyright Notice in main folder of distribution

-----------
-- Imports
-----------
local SuperCons = class.SuperCons

--------------------------
-- Title class definition
--------------------------
class.Define("Title", {	
	-- Docks a widget in a given region of the body
	-- widget: Widget handle
	-- x, y: Widget coordinates
	-- w, h: Widget dimensions
	------------------------------------------------
	DockInBody = function(T, widget, x, y, w, h)
		T.body:Dock(widget, x, y, w, h)
	end,
	
	-- Minimizes a popup
	---------------------
	Minimize = function(T)
		-- Toggle the minimize state.
		T.bMin = not T.bMin
		
		-- Disallow widget draws and hit tests on minimization; allow them otherwise.
		T.body:AllowDockTest(not T.bMin)
		T.body:AllowDockUpdate(not T.bMin)
		
		-- Adjust to account for the new height.
		local y, h = T:GetRect("yh")

		T:Adjust(y, T.bMin and T.min or h)
	end,
	
	-- h: Height to assign
	-----------------------
	SetTitleHeight = function(T, h)
		T.min = h

		-- Dock features.
		if T:IsLoaded() then
			T("onDock")
		end
	end
},

-- Constructor
-- group: Group handle
-----------------------
function(T, group)
	SuperCons(T, "Popup", group)

	-- Grabbable part of popup.
	T.banner = T:CreatePart()
					
	-- Signals --
	T:SetSignal{
		event = function(event)
			-- Turn the cursor into an open hand when hovering over the banner, and into a
			-- clenched hand while the banner is caught.
			if event == WE.GrabPart then
				SetCursor("gh")
				
				-- Record what part of the banner was grabbed.
				local x, y = T:GetRect("xy")
				T.grab = { x = cx - x, y = cy - y }
			elseif event == WE.EnterPart and not T.banner:IsGrabbed() then
				SetCursor("oh")
			elseif event == WE.LeavePart and not T.banner:IsGrabbed() then
				SetCursor("std")
			elseif event == WE.DropPart then
				SetCursor(T.banner:IsEntered() and "oh" or "std")
				
			-- Adjust to account for drags.
			elseif event == WE.PostUpkeep and T.banner:IsGrabbed() then
				T:SetLocalPos(cx - T.grab.x, cy - T.grab.y)
				T:Adjust(T:GetRect("yh"))
			end
		end,
		test = function(cx, cy, x, y, w, h)
			if cy < y + T.min then
				return T.banner
			end
			return T
		end,
		update = function(x, y, w, h)
			if not T.bMin then
				T:DrawPicture("B", x, y, w, h)
				T:DrawFrame("D", x, y, w, h)
			end

			-- Draw the banner.
			T:DrawPicture("C", x, y, w, T.min)
			T:StringF(T:GetString(), "vo", x, y, w, T.min)
			T:DrawFrame("B", x, y, w, T.min)
		end,
		onDock = function()
			T.body:Dock(T, "Normal", 0, T.min, T.w, T.h - T.min)
			if T.minimize then
				T.minimize:Dock(T, "Normal", .85 * T.w, .05 * T.min, .1 * T.w, .85 * T.min)
			end
		end
	}
end, { base = "Popup" })