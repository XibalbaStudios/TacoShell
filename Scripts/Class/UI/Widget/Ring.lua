-- See TacoShell Copyright Notice in main folder of distribution

-- Standard library imports --
local ipairs = ipairs
local min = math.min
local pi = math.pi

-- Imports --
local CosSin = math_ex.CosSin
local New = class.New
local RotateIndex = numericops.RotateIndex
local StateSwitch = widgetops.StateSwitch
local SuperCons = class.SuperCons

-- Unique member keys --
local _clockwise = {}
local _elements = {}
local _incline = {}
local _index = {}
local _set = {}
local _timer = {}

-- Basis vectors --
local BasisF = New("Vec3D")
local BasisR = New("Vec3D", 0, -1, 0)
local Up = New("Vec3D")

-- Transformed vectors --
local MappedF = New("Vec3D")
local MappedR = New("Vec3D")

-- Angle --
local A = New("Complex")

-- Angle delta --
local DA = New("Complex")

-- Basis setup
-- R: Ring handle
local function SetupBasis (R)
	-- Partition the ring into equal arcs and compute the angle of the indexed element.
	local da = 2 * pi / #R[_elements]
	local duration = R[_timer]:GetDuration()
	local a = da * (R[_index] - 1)

	-- If the ring is turning, adjust the angle.
	if duration then
		a = a + (R[_clockwise] and -da or da) * min(R[_timer]:GetCounter() / duration, 1)
	end

	-- Convert the angles to complex numbers on the unit circle.
	A:Set(1, a, true)
	DA:Set(1, -da, true)

	-- Prepare a basis for the elements, inclined as desired.
	local ci, si = CosSin(R[_incline])

	BasisF:Set(ci, 0, si)
	Up:Set(-si, 0, ci)
end

-- Sets ring elements
-- R: Ring handle
local function SetElements (R)
	-- Get the basis in home orientation.
	SetupBasis(R)

	-- Update each element, building its basis from the current angle.
	for _, element in ipairs(R[_elements]) do
		MappedF:SetScaledSum(BasisR, A.i, BasisF, A.r)
		MappedR:SetScaledSum(BasisR, A.r, BasisF, -A.i)

		R[_set](element, MappedF, MappedR, Up)

		-- Rotate through one arc.
		A:Mul(DA)
	end
end

-- R: Ring handle
-- index: Index to assign
local function SetIndex (R, index)
	R[_index] = index

	SetElements(R)
end

-- R: Ring handle
-- dt: Time lapse
local function Update (R, dt)
	if R:IsTurning() then
		if R[_timer]:Check() > 0 then
			StateSwitch(R, #R[_elements] > 1, false, SetIndex, "turn", RotateIndex(R[_index], #R[_elements], R[_clockwise]))

		else
			SetElements(R)

			R[_timer]:Update(dt)
		end
	end
end

-- Ring class definition --
class.Define("Ring", function(Ring)
	-- Adds an element to the ring
	-- element: Element to add
	-------------------------------
	function Ring:AddElement (element)
		self[_elements][#self[_elements] + 1] = element

		-- If this is the first entry, invoke a switch.
		if #self[_elements] == 1 then
			self:Signal("switch_to", "first")
		end

		-- Update the elements to reflect the addition.
		SetElements(self)
	end

	--- Clears the ring.
	function Ring:Clear ()
		self[_elements], self[_index] = {}, 1

		self[_timer]:Stop()
	end

	--- Gets the basis for a given element.
	-- @param index Element index.
	-- @return Forward vector.
	-- @return Right vector.
	-- @return Up vector.
	function Ring:GetBasisAt (index)
		SetupBasis(self)

		for i = 1, index - 1 do
			A:Mul(DA)
		end

		MappedF:SetScaledSum(BasisR, A.i, BasisF, A.r)
		MappedR:SetScaledSum(BasisR, A.r, BasisF, -A.i)

		return MappedF, MappedR, Up
	end

	--- Accessor.
	-- @return Current element, or <b>nil</b> if the ring is empty.
	function Ring:GetCurrent ()
		return self[_elements][self[_index]]
	end

	--- Accessor.
	-- @param Element index.
	-- @return Ring element at index, or <b>nil</b> if element does not exist.
	function Ring:GetElement (index)
		return self[_elements][index]
	end

	--- Accessor.
	-- @return Ring incline.
	function Ring:GetIncline ()
		return self[_incline]
	end

	--- Accessor.
	-- @return Ring index.
	function Ring:GetIndex ()
		return self[_index]
	end

	--- Status.
	-- @return If true, ring is turning.
	function Ring:IsTurning ()
		return self[_timer]:GetDuration() ~= nil
	end

    --- Metamethod.
    -- @return Element count.
    function Ring:__len ()
        return #self[_elements]
    end

	--- Accessor.
	-- @param incline Incline to assign.
	function Ring:SetIncline (incline)
		self[_incline] = incline
	end

	-- index: Index to assign
	-- always_refresh: If true, refresh on no change
	-------------------------------------------------
	function Ring:SetIndex (index, always_refresh)
		StateSwitch(self, index ~= self[_index], always_refresh, SetIndex, "set_index", index)
	end
	function Ring:GetCount()
		return #self[_elements]
	end

	-- Initiates a turn
	-- duration: Turn duration
	-- clockwise: If true, turn clockwise
	--------------------------------------
	function Ring:Turn (duration, clockwise)
		self[_clockwise] = not not clockwise

		if #self[_elements] ~= 0 then
			self[_timer]:Start(duration / #self[_elements])
		end
	end
end,

--- Class onstructor.
-- @class function
-- @name Constructor
-- @param group Group handle.
-- @param set Element set routine.
function(R, group, set)
	SuperCons(R, "Widget", group)

	-- Ring elements --
	R[_elements] = {}

	-- Ring incline --
	R[_incline] = 0

	-- Element index --
	R[_index] = 1

	-- Element setter --
	R[_set] = set

	-- Turn timer --
	R[_timer] = New("Timer")

	-- Signals --
	R:SetSignal("update", Update)
end, { base = "Widget" })