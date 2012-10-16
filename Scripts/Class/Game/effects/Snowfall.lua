-----------
-- Imports
-----------
local ipairs = ipairs
local ceil, min, random, sqrt = math.ceil, math.min, math.random, math.sqrt
local remove = table.remove
local EnterRender2D = gfx.EnterRender2D
local _G = _G
local GetScreenSize = game.GetScreenSize
local GetTimeDifference = engine.GetTimeDifference
local LeaveRender2D = gfx.LeaveRender2D
local New = class.New
local NewArray = class.NewArray
local Rand = math_ex.Rand
local RBy = math_ex.RBy
local RotateIndex = numericops.RotateIndex

-----------------------------------
-- Modulation color; path position
-----------------------------------
local Color, Pos = New("Color", "white"), New("Vec3D")

-----------------------------
-- Snowfall class definition
-----------------------------
class.Define("Snowfall", function(MT)
	-- Gets a state, building a fresh one if necessary
	-- S: Snowfall handle
	-- Returns: State, path handle, path node count
	---------------------------------------------------
	local function GetState (S)
		local state, path, count = remove(S.statecache)

		if state then
			path = state.path

			count = #path

			path:DeleteAllPathNodes()

		else
			count = random(3, 8)

			path = New("Path", count)

			state = { da = 0, path = path, timer = New("Timer"), index = 0 }
		end

		return state, path, count
	end

	-- data: Section data
	-- Returns: If true, snowfall is still alive
	---------------------------------------------
	function MT:__call (data)
		local collection = self.collection

		if collection then
			-- Handle section switches.
			if self.attach:GetParent() ~= data.pane then
				data.pane:Attach(self.attach, 0, 0, data.pane:GetW(), data.pane:GetH())

				self.attach:Promote()
			end

			-- Divide the screen up into slots. Update the flakes.
			local nslots, count, cache, statecache, states, lapse, vw, vh = ceil(#collection / 3), self.count, self.cache, self.statecache, self.states, GetTimeDifference(), GetScreenSize()
			local sw = vw / (nslots - 1)

			for i, flake in collection:Masks() do
				if flake:IsShowing() then
					local state = states[i]

					if state.timer:Check() > 0 then
						flake:Show(false)

						-- Cache and remove the state.
						statecache[#statecache + 1], states[i] = state

					else
						local counter = state.timer:GetCounter()

						state.path(counter / state.timer:GetDuration(), true, Pos)

						-- Put the snowflake at the current positions on its curve and spin.
						flake:SetPos(Pos.x, Pos.y)
						flake:SetRotationAngle(state.da * counter)

						-- Update the snowflake age.
						state.timer:Update(lapse)
					end

				-- Replace a dead flake if desired.
				elseif states[i] == nil and i <= count then
					-- Assign a random alpha to the flake, and pick a horizontal slot.
					Color.a, self.slot = random(32, 100), RotateIndex(self.slot, nslots)

					-- Choose a position above the screen at the current slot. Choose another
					-- below the screen, displaced a bit horizontally from the first. Assign a
					-- random square size to the flake.
					local size, state, path, count = random(32, 110), GetState(self)
					local x1, y1 = RBy(sw * (self.slot - .5), sw), -size * Rand(2, 6)
					local x2, y2 = RBy(x1, size * 3), vh + size * 2

					-- Build a random curve between the top and bottom positions.
					local dx, dy = x2 - x1, y2 - y1
					local mag = sqrt(dx * dx + dy * dy)
					local u_dx, u_dy = dx / mag, dy / mag

					path:AddPathNode(x1, y1, 0)

					for i = 2, count - 1 do
						local t = (i - 1) / (count - 1)

						path:AddPathNode(x1 + dx * t - u_dy * Rand(-1.5, 1.5), y1 + dy * t + u_dx * Rand(-1.5, 1.5), 0)
					end

					path:AddPathNode(x2, y2, 0)

					-- Assign a random speed/lifetime to the flake.
					state.timer:Start(Rand(2, 7))

					-- Assign flake mask properties.
					flake:SetColor(Color)
					flake:SetRotationCenter(Rand(0, size), Rand(0, size))
					flake:SetPos(x1, y1, 0)
					flake:SetTargetSize(size, size)

					-- Cache a snowflake with random spin and speed/lifetime.
					cache[#cache + 1], state.da, state.index, states[i] = state, Rand(-25, 25), i, false
				end
			end

			-- Put a few cached flakes into play.
			local newflake = self.newflake

			for _ = 1, min(#cache, newflake:Check("continue")) do
				local item = remove(cache)

				-- Transfer the state from the cache.
				states[item.index] = item

				-- Display the flake.
				collection:GetMask(item.index):Show(true)
			end

			-- If there are more flakes waiting, update the timer. Otherwise, reset it.
			if #cache > 0 then
				newflake:Update(lapse)
			else
				newflake:SetCounter(0)
			end

			return true
		end
	end

	-- Returns: Flake capacity
	---------------------------
	function MT:GetMax ()
		return #assert(self.collection, "Dead snowfall effect")
	end

	-- Returns: If true, effect is alive
	-------------------------------------
	function MT:IsAlive ()
		return not not self.collection
	end

	-- Kills the effect
	--------------------
	function MT:Kill ()
		local cache, states = self.statecache, self.states

		for i = 1, #self.collection do
			cache[#cache + 1] = states[i]
		end

		for _, state in ipairs(cache) do
			if state then
				state.path:Set(nil)
			end
		end

		self.count, self.cache, self.collection, self.pane, self.statecache, self.states = 0

        self.attach:GetGroup():AddDeferredTask(function()
		    self.attach:Detach()
        end)
	end

	-- Returns: Flake capacity
	---------------------------
	function MT:__len ()
		return self.count
	end

	-- count: Flake count to assign
	--------------------------------
	function MT:SetCount (count)
		assert(self.collection, "Dead snowfall effect")

		self.count = count
	end
end, 

-- Constructor
-- count: Count of active flakes
-- max: Flake capacity
---------------------------------
function(S, count, max)
	S.cache, S.count, S.slot, S.statecache, S.states, S.newflake = {}, count or 0, 0, {}, {}, New("Timer")

	-- Set a timer to manage flake generation.
	S.newflake:Start(.035)

	-- Apply constant state to masks.
	S.collection = New("ScreenMaskCollection", NewArray("ScreenMask", max, "Textures/snow_flake.png"))

	for _, flake in S.collection:Masks() do
		flake:SetTransparency("alpha")
		flake:SetVisible(false)

		-- Initially, hide flake.
		flake:Show(false)
	end

	-- TODO: De-hack, generalize for multiple textures?
	S.collection:GetMask(1):GetTexture():EnsureLoaded()

	-- Add an attachment widget to display the snowfall above the current section's pane.
	S.attach = _G.ui.Widget("render", function()
		local collection = S.collection

		if collection then
			LeaveRender2D()

			collection:Render()

			EnterRender2D(true)
		end
	end)

	S.attach:Allow("test", false)
end)