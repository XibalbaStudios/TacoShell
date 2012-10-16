-- See TacoShell Copyright Notice in main folder of distribution

----------------------------
-- Standard library imports
----------------------------
local abs = math.abs
local assert = assert
local ceil = math.ceil
local ipairs = ipairs
local pairs = pairs

-----------
-- Imports
-----------
local AnalogValue = input.AnalogValue
local ActionStatus = input.ActionStatus
local ClampIn = numericops.ClampIn

-- Discretization logic body
-- item: Action to discretize
-- count: Number of cuts in (0, 1) (nil = undiscretize)
-- low: Value at which to begin discretization
--------------------------------------------------------
local function Discretize (item, count, low)
	item.cuts, item.low = count, count and low or nil
end

-- Gets the current mode data
-- A: Action map handle
-- Returns: Mode data
------------------------------
local function GetModeData (A)
	local current = A.current

	return current ~= nil and A.modes[current] or nil
end

-- Get repeat delay logic body
-- item: Action to which repeat delay belongs
-- Returns: Repeat delay
----------------------------------------------
local function GetRepeatDelay (item)
	return item.delay
end

-- Invokes a function within the current mode, group, and item
-- A: Action map handle
-- group: Group name
-- action: Action belonging to item
-- func: Function to perform
-- ...: Function arguments
-- Returns: Function results
---------------------------------------------------------------
local function InItem (A, group, action, func, ...)
	local mode = GetModeData(A)

	if mode then
		for _, item in pairs(mode[group]) do
			if item.action == action then
				return func(item, ...)
			end
		end
	end
end

-- Set repeat delay logic body
-- item: Action to which repeat delay belongs
-- delay: Delay to assign
----------------------------------------------
local function SetRepeatDelay (item, delay)
	item.delay = delay
end

-- Updates an item against a repeat delay
-- item: Item to update
-- step: Time step
------------------------------------------
local function UpdateDelay (item, step)
	item.time = (item.time or 0) + step

	if item.time >= item.delay then
		item.time = nil
	end
end

-- Update logic body
-- A: Action map handle
-- mode: Action mode
-- device: Device
-- step: Time step
------------------------
local function Update (A, mode, device, step)
	-- Update controller analog states.
	local analogs = A.analogs

	for item, analog in pairs(mode.analogs) do
		local value = AnalogValue(device, item)

		-- If no analog value is dead, cancel any delay.
		if value == 0 then
			analog.time = nil

		-- Otherwise, check whether a delay is in effect. If so, cancel any motion.
		-- Update any delay.
		else
			if analog.time then
				value = 0
			end

			if analog.delay then
				UpdateDelay(analog, step)
			end
		end

		-- Apply any discretization to the analog value.
		local cuts = analog.cuts

		if value ~= 0 and cuts then
			local bNeg, low = value < 0, analog.low
			local rest = 1 - low

			--value = low + ceil(cuts * (ClampIn(abs(value), low, 1) - low) / rest) * rest / cuts
			value = ceil(cuts * abs(value)) / cuts

			if bNeg then
				value = -value
			end
		end

		-- Assign the analog action value.
		analogs[analog.action] = value
	end

	-- Update controller button states.
	local buttons = A.buttons

	for item, button in pairs(mode.buttons) do
		local status = ActionStatus(device, item)

		-- Reset delays if the button is released.
		if status == "justreleased" then
			button.time = nil

		-- During a press, check whether a delay is in effect. If so, issue a wait;
		-- otherwise, issue a normal press. Update any delay.
		elseif status == "pressed" then
			if button.time then
				status = "wait"
			end

			if button.delay then
				UpdateDelay(button, step)
			end
		end

		-- Assign the button action value.
		buttons[button.action] = status
	end
end

------------------------------
-- ActionMap class definition
------------------------------
class.Define("ActionMap", {
	-- Indicates whether an action button is pressed
	-- action: Action to query
	-- Returns: If true, action button is pressed
	-------------------------------------------------
	ButtonIsPressed = function(A, action)
		local state = A.buttons[action]

		return state == "pressed" or state == "justpressed"
	end,

	-- what: Analog action
	-- Returns: Analog action value
	--------------------------------
	GetAnalogValue = function(A, what)
		assert(what ~= nil, "nil action")

		return A.analogs[what] or 0
	end,

	-- what: Button action
	-- Returns: Button action state
	--------------------------------
	GetButtonState = function(A, what)
		assert(what ~= nil, "nil action")

		return A.buttons[what] or "none"
	end,

	-- Discretizes an analog action
	-- action: Action to discretize
	-- count: Number of cuts in (0, 1) (nil = undiscretize)
	-- low: Value at which to begin discretization
	--------------------------------------------------------
	Discretize = function(A, action, count, low)
		InItem(A, "analogs", action, Discretize, count, low)
	end,

	-- Returns: Device
	-------------------
	GetDevice = function(A)
		return A.device
	end,

	-- Returns: Current mode name
	------------------------------
	GetMode = function(A)
		return A.current
	end,

	-- action: Action to query on delay
	-- name: Name of action's group
	-- Returns: Repeat delay
	------------------------------------
	GetRepeatDelay = function(A, action, name)
		return InItem(A, name, action, GetRepeatDelay) or 0
	end,

	-- Maps an item to an action
	-- item: Value of item
	-- name: Name of action's group
	-- action: Action to map to item
	---------------------------------
	Map = function(A, item, name, action)
		local mode = GetModeData(A)

		if mode then
			mode[name][item] = { action = action }
		end
	end,

	-- device: Device to assign
	----------------------------
	SetDevice = function(A, device)
		A.device = device
	end,

	-- name: Mode name to assign
	-----------------------------
	SetMode = function(A, name)
		if name ~= nil and name ~= A.current then
			A.analogs, A.buttons = {}, {}

			-- If not present, prepare the mode.
			A.modes[name] = A.modes[name] or { analogs = {}, buttons = {} }

			-- Do item setup.
			for _, analog in pairs(A.modes[name].analogs) do
				analog.time = nil
			end

			for _, button in pairs(A.modes[name].buttons) do
				button.time = nil
			end
		end

		A.current = name
	end,

	-- action: Action to delay
	-- name: Name of action's group
	-- delay: Repeat delay to assign (nil = 0)
	-------------------------------------------
	SetRepeatDelay = function(A, action, name, delay)
		InItem(A, name, action, SetRepeatDelay, delay)
	end,

	-- Updates the action map
	-- step: Time step
	--------------------------
	Update = function(A, step)
		-- Update the action map if it has a device and valid mode.
		local device, mode = A.device, GetModeData(A)

		if device and mode then
			Update(A, mode, device, step)
		end
	end
},

-- Constructor
-- device: Device to use with map
----------------------------------
function(A, device)
	A.analogs, A.buttons, A.modes = {}, {}, {}

	A:SetDevice(device)
end)