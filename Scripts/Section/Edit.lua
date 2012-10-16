-- Standard library imports --
local atan2 = math.atan2
local format = string.format
local ipairs = ipairs
local max = math.max
local min = math.min
local pi = math.pi
local sqrt = math.sqrt

-- Imports --
local ActionMap = contexts.ActionMap
local APairs = iterators.APairs
local Characters = Characters
local ClampIn = numericops.ClampIn
local CosSin = math_ex.CosSin
local FocusChain = contexts.FocusChain
local ForEachI_Cond = table_ex.ForEachI_Cond
local GetCamera = objects.GetCamera
local GetEntity = objects.GetEntity
local GetPlayer = objects.GetPlayer
local GetRenderContext = objects.GetRenderContext
local GetScreenSize = game.GetScreenSize
local GetFOV = gfx.GetFOV
local GetMouseDeltas = input.GetMouseDeltas
local GetPhase = GetPhase
local GetRes = gfx.GetRes
local IsKeyPressed = input.IsKeyPressed
local Line2D = gfx.Line2D
local LookAt = math_ex.LookAt
local New = class.New
local NewEntity = objects.NewEntity
local PurgeAttachList = widgetops.PurgeAttachList
local SectionGroup = contexts.SectionGroup
local SetFOV = gfx.SetFOV
local SetResolveLogic = contexts.SetResolveLogic
local SetupScreen = section.SetupScreen
local ToggleMouseMode = contexts.ToggleMouseMode
local UIGroup = contexts.UIGroup
local Unbind = objects.Unbind
local UpdateKeys = input.UpdateKeys
 

-- Common open logic
-- data: Section data
local function CommonOpen (data)
	SetupScreen(data, true)
end

-- Edit widgets --
local u_EditWidgets = {}

do
	local Info, HeldColor, LastColor, Held, Last, Dx, Dy = ui.String(), New("Color", 128, 0, 0), New("Color", 0, 0, 128)

	-- Moves a widget
	-- widget: Widget handle
	-- x, y: New coordinates
	local function Move (widget, x, y)
		-- Clamp the position so the widget lies on either its parent or against the frame.
		local parent, pw, ph = widget:GetParent(), GetScreenSize()

		if parent then
			pw, ph = parent:GetW(), parent:GetH()
		end

		widget:SetX(ClampIn(x, 0, pw - widget:GetW()))
		widget:SetY(ClampIn(y, 0, ph - widget:GetH()))

		-- Report the new position, which may ignore the changes.
		Info:SetString(format("Local pos of last dragged widget: %f, %f", widget:GetX(), widget:GetY()))
	end

	-- Abort-based capture logic for widget editor
	-- candidate: Candidate widget handle
	-- state: Execution state
	-- Returns: If true, issue an abort
	local function Capture (_, candidate, state)
		-- If a widget is held and still pressed, update it. Otherwise, drop it.
		if Held and state("is_pressed") then
			local cx, cy = state("cursor")

			-- Displace the widget from its current local position based on the cursor
			-- and off-center grab coordinates.
			Move(Held, cx - Dx, cy - Dy)

			-- Abort in order to avoid tests.
			return true
		end

		Held = nil

		-- If a press was issued over a candidate, grab it.
		if candidate and state("is_pressed") then
			Held = candidate:GetOwner() or candidate
			Last = Held

			-- Get the off-center grab coordinates.
			local cx, cy = state("cursor")

			Dx, Dy = cx - Held:GetX(), cy - Held:GetY()

			-- Abort, as no further testing is needed.
			return true
		end
	end

	-- Install the edit widgets dialog.
	section.Load(u_EditWidgets, function(state, data, ...)
		-- Load --
		if state == "load" then
			data.pane = ui.Backdrop(false)
			data.exit = ui.String("$B$ to exit")

		-- Open --
		elseif state == "open" then
			CommonOpen(data)

			-- Reset the info string and put it in the upper corner.
			Info:SetString("")

			data.pane:Attach(Info, 25, 25)

			-- Forbid dragging of dialog widgets.
			for w in data.pane:AttachListIter() do
				w:Allow("test", false)
			end

			data.pane:Allow("test", false)

			-- Prepare to trap drags.
			SetResolveLogic(Capture)

		-- Render --
		elseif state == "render" then
			local widget = Held or Last

			if widget then
				local color, x1, y1, w, h = widget == Held and HeldColor or LastColor, widget:GetRect(true)

				Info:SetColor("string", color)

				-- Box the widget.
				local x2, y2 = x1 + w, y1 + h

				Line2D(x1, y1, x2, y1, color)
				Line2D(x1, y2, x2, y2, color)
				Line2D(x1, y1, x1, y2, color)
				Line2D(x2, y1, x2, y2, color)
			end

		-- Trap --
		elseif state == "trap" then
			if ActionMap():GetButtonState("cancel") == "justpressed" then
				SectionGroup():Close()

			elseif Last then
				UpdateKeys()

				-- Update position of the last held widget.
				-- 28, 29, 30, 31: Up, down, left, right
				local x, y = Last:GetX(), Last:GetY()

				if IsKeyPressed(28) then
					y = y - .25
				end

				if IsKeyPressed(29) then
					y = y + .25
				end

				if IsKeyPressed(30) then
					x = x - .25
				end

				if IsKeyPressed(31) then
					x = x + .25
				end

				Move(Last, x, y)
			end

		-- Close --
		elseif state == "close" then
			Held, Last = nil
		end
	end)
end

-- Adjust FOV --
local u_AdjustFOV = {}

do
	local FOV

	-- Install the adjust FOV dialog.
	section.Load(u_AdjustFOV, function(state, data, ...)
		-- Load --
		if state == "load" then
			data.pane = ui.Backdrop(false)
		data.exit = ui.String("$B$ to exit")


			--
			FOV = ui.SliderHorz()

			FOV:SetSignal("switch_to", function(S)
				GetRenderContext(1):SetFOV(35 + 125 * S:GetOffset())
			end)

		-- Open --
		elseif state == "open" then
			CommonOpen(data)

			--
			FOV:SetOffset((GetRenderContext(1):GetFOV() - 35) / 125)

			data.pane:Attach(FOV, 25, 50, 300, 32)

		-- Trap --
		elseif state == "trap" then
			if ActionMap():GetButtonState("cancel") == "justpressed" then
				SectionGroup():Close()
			end
		end
	end)
end

-- Adjust inset --
local u_AdjustInset = {}

do
	local Min, Range, Sliders, Text, Pos, Target = -150, 300, {}, {}, New("Vec3D"), New("Vec3D")

	-- Install the adjust inset dialog.
	section.Load(u_AdjustInset, function(state, data, ...)
		-- Load --
		if state == "load" then
			data.pane = ui.Backdrop(false)
			data.exit = ui.String("$B$ to exit")


			--
			for i, comp in APairs("x", "y", "z", "x", "y", "z", "fov") do
				Sliders[i] = ui.SliderHorz()

				--
				if comp ~= "fov" then
					local comp, fstr, target = comp

					if i <= 3 then
						fstr, target = "Pos." .. comp, Pos
					else
						fstr, target = "Target." .. comp, Target
					end

					--
					Sliders[i]:SetSignal("switch_to", function(S)
						target[comp] = Min + S:GetOffset() * Range

						GetCamera(1, true):AttachToEntity(GetPlayer(1, true), Pos, LookAt(Pos, Target))				
					end)

					--
					Text[i] = ui.String(function()
						return format("%s = %.3f", fstr, target[comp])
					end)

				--
				else
					--
					Sliders[i]:SetSignal("switch_to", function(S)
						GetRenderContext(1, true):SetFOV(35 + S:GetOffset() * 125, (35 + S:GetOffset() * 125) / 2)
					end)

					--
					Text[i] = ui.String(function()
						return format("FOV = %.3f", GetRenderContext(1, true):GetFOV())
					end)
				end
			end

		-- Open --
		elseif state == "open" then
			CommonOpen(data)

			--
			local view = Characters[GetPlayer(1, true):GetName()].view

			Pos:Set(view.pos)
			Target:Set(view.target)

			--
			for i, comp in APairs("x", "y", "z") do
				Sliders[i]:SetOffset((Pos[comp] - Min) / Range)
				Sliders[i + 3]:SetOffset((Target[comp] - Min) / Range)
			end

			Sliders[#Sliders]:SetOffset((view.fov - 35) / 125)

			--
			for i, slider in ipairs(Sliders) do
				data.pane:Attach(slider, 25, 50 * i, 300, 32)
				data.pane:Attach(Text[i], 350, 50 * i)
			end

		-- Trap --
		elseif state == "trap" then
			if ActionMap():GetButtonState("cancel") == "justpressed" then
				SectionGroup():Close()
			end
		end
	end)
end

-- Roam --
local u_Roam = {}

do
	local DSide, DDir, Dummy, AHorz, AVert, Speed, SpeedStr = 0, 0
	-- backup dummy
	local backupDummy

	-- Install the roam dialog.
	section.Load(u_Roam, function(state, data, ...)
		-- Load --
		if state == "load" then
			data.pane = ui.Backdrop(false)
			data.exit = ui.String("")


			-- Provide a speed display.
			SpeedStr = ui.String(function()
				return format("Speed: %.2f, adjust with mouse wheel", Speed)
			end)

		-- Open --
		elseif state == "open" then
			CommonOpen(data)

			-- Get initial angles from the matrix. Set a reasonable speed.
			local camera = GetCamera(1)
			local matrix = camera:GetRotationMatrix()
			local dir, up = matrix:GetDir(), matrix:GetUp()

			AHorz, AVert, Speed = atan2(dir.y, dir.x), atan2(sqrt(up.x * up.x + up.y * up.y), up.z), 4.75

			-- Install a camera controller.
			Dummy = NewEntity()

			Dummy:SetRotationMatrix(matrix)
			Dummy:SetPos(camera:GetPos())
			Dummy:SetVisibleBitmask("invisible")

			-- backup camera dummy and attach it to a new one
			backupDummy = camera:GetParent()
			camera:AttachToEntity(Dummy)
 
			-- Hide the cursor.
			ToggleMouseMode()

			-- Attach the speed string.
			--data.pane:Attach(SpeedStr, 25, 25)

		-- Trap --
		elseif state == "trap" then
			if ActionMap():GetButtonState("cancel") == "justpressed" then
				SectionGroup():Close()

			else
				UpdateKeys()

				-- Update forward and strafe motion.
				-- 28, 29, 30, 31: Up, down, left, right
				if IsKeyPressed(28) then
					DDir = DDir + Speed
				end

				if IsKeyPressed(29) then
					DDir = DDir - Speed
				end

				if IsKeyPressed(30) then
					DSide = DSide + 3.25
				end

				if IsKeyPressed(31) then
					DSide = DSide - 3.25
				end

				-- Update view angles.
				local dx, dy, dwheel = GetMouseDeltas()

				AHorz, AVert = AHorz + ClampIn(-dx * .035, -pi / 16, pi / 16), ClampIn(AVert - dy * .035, -.375 * pi, .375 * pi)

				-- Update speed.
				Speed = ClampIn(Speed + .25 * dwheel, .25, 35)
			end

		-- Update --
		elseif state == "update" then
			-- Compute the camera basis with new angles.
			local cosh, sinh = CosSin(AHorz)
			local planev, cosv, sinv = New("Vec3D", cosh, sinh, 0), CosSin(AVert)
			local dir, up = planev * cosv + New("Vec3D", 0, 0, sinv), New("Vec3D", 0, 0, cosv) - planev * sinv

			dir, up = dir / #dir, up / #up

			local side = up ^ dir

			side = side / #side

			-- Update camera. Reset motion tracking.
			Dummy:SetRotationMatrix(New("Matrix", dir, side, up))
			Dummy:SetPos(Dummy:GetPos() + dir * DDir + side * DSide)

			DSide, DDir = 0, 0

		-- Close --
		elseif state == "close" then
			GetPlayer(1).view:Toggle()
			-- reattach camera to original dummy
			local camera = GetCamera(1)
			camera:AttachToEntity(backupDummy)
			
			-- Show the cursor.
			ToggleMouseMode()

			-- Remove the camera controller.
			Unbind(Dummy, true)
		end
	end)
end

-- Edit page choices --
local Check = newproxy()
local Choices = {
	{ "Edit widgets", u_EditWidgets },

	-- In-game --
	Check, GetPhase,

	{ "Adjust FOV", u_AdjustFOV },
	{ "Adjust inset", u_AdjustInset },
	{ "Roam", u_Roam }
}

-- Action map modes --
local AModes = {}

-- Widgets --
local Go, Pages, SU, SD

-- Install the edit dialog.
section.Load("Edit", function(state, data, ...)
	-- Load --
	if state == "load" then
		data.pane = ui.Backdrop(false)
		data.exit = ui.String("$B$ to exit")


		-- Set up some navigation buttons.
		Go = ui.PushButton(section.OpenDialog(function()
			local _, page = Pages:GetHeading()

			return page
		end))

		Go:SetString("Go to menu")

		-- Set up page list.
		Pages, SU, SD = ui.Dropdown(10), ui.ScrollButton("up"), ui.ScrollButton("down")

		SU:SetTarget(Pages, "up")
		SD:SetTarget(Pages, "down")

	-- Open / Resume --
	elseif state == "open" or state == "resume" then
		CommonOpen(data)

		-- Build a fresh page list on entry.
		if state == "open" then
			local bAvailable = true

			-- Clear page list.
			while #Pages > 0 do
				Pages:RemoveEntry(#Pages)
			end

			-- Enumerate available pages.
			ForEachI_Cond(Choices, Check, function(page)
				Pages:Append(page[1], page[2])
			end, true)

			-- Use the mouse while editing.
			ToggleMouseMode()

			-- Save the current modes and put each action map into UI mode.
			for i = 1, 4 do
				AModes[i] = ActionMap(i):GetMode()

				ActionMap(i):SetMode("UI")
			end
		end

		-- Attach widgets.
		data.pane:Attach(Pages, 25, 25, 250, 60)
		data.pane:Attach(SU, 290, 85, 25, 25)
		data.pane:Attach(SD, 290, 25 + (#Pages + 1) * 60 - 25, 25, 25)
		data.pane:Attach(Go, 290, 25, 225, 60)

		-- Cancel custom resolves.
		SetResolveLogic(nil)

	-- Suspend --
	elseif state == "suspend" then
		Pages:SetOpen(false)

		PurgeAttachList(data.pane)

	-- Trap --
	elseif state == "trap" then
		if ActionMap():GetButtonState("cancel") == "justpressed" then
			SectionGroup():Close()
		end

	-- Close --
	elseif state == "close" then
		ToggleMouseMode()

		-- Restore action map modes.
		for i = 1, 4 do
			ActionMap(i):SetMode(AModes[i])
		end
	end
end)