-- Standard library imports --
local min = math.min

-- Imports --
local New = class.New
local SuperCons = class.SuperCons

-- Unique member keys --
local _divisor = {}
local _lapse = {}
local _limit = {}
local _pos = {}
local _prev1 = {}
local _prev2 = {}
local _wait = {}

-- Next position in Catmull-Rom curve --
local Next = New("Vec3D")

-- Catmull-Rom curve state --
local Curve = New("CubicCurve", "catmull_rom")

-- TrailStream class definition --
class.Define("TrailStream", function(TrailStream)
	--- Accessor.
	-- @param pos Vector that is filled with the position.
	function TrailStream:GetPos (pos)
		pos:Set(self[_pos])
	end

	--- Status.
	-- @return If true, the stream is active.
	function TrailStream:IsActive ()
		return self[_lapse]:GetDuration() ~= nil
	end

	--- Resets the stream.<br><br>
	-- The stream is sent a signal as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>reset(S, arg)</i></b>,<br><br>
	-- where <i>arg</i> is the parameter.<br><br>
	-- The emit timer is reset and the velocity cleared.<br><br>
	-- @param arg Signal argument.
	function TrailStream:Reset (arg)
		self[_lapse]:Start(self[_wait])

		self:Signal("reset", arg)
	end

	-- Stops the stream.<br><br>
	-- The stream is first sent a signal as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>stop(S, how, arg)</i></b>,<br><br>
	-- where <i>how</i> and <i>arg</i> are the parameters.
	-- @param how Stop description.
	-- @param arg Signal argument.
	function TrailStream:Stop (how, arg)
		if self:IsActive() then
			self:Signal("stop", how, arg)

			self[_pos] = nil

			self[_lapse]:Stop()
		end
	end

	--- Updates the stream.<br><br>
	-- The stream is first sent a signal as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>enter_update(S)</i></b>.<br><br>
	-- For each timeout, the current position is updated and the stream is sent a signal
	-- as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>emit(S, t, arg)</i></b>,<br><br>
	-- where <i>t</i> is the emit time (n.b. if multiple emissions occur, these will be
	-- from newest to oldest) and <i>arg</i> is the parameter.<br><br>
	-- The stream position and velocity are then updated to reflect the input parameters,
	-- and the stream is sent a signal as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>leave_update(S, t)</i></b>,<br><br>
	-- where <i>t</i> is the current counter of the emit timer, which is then updated.<br><br>
	-- If the stream is inactive, this is a no-op.
	-- @param pos Emitter position.
	-- @param dir Emitter heading.
	-- @param arg Signal argument.
	function TrailStream:Update (pos, dir, arg)
		if self:IsActive() then
			-- Set up the default state if the emitter was stopped.
			if not self[_pos] then
				self[_pos] = pos:Dup()

				self[_prev1]:Set(pos)
				self[_prev2]:Set(pos)
			end

			-- Do any pre-update logic.
			self:Signal("enter_update")

			-- Cache the current previous positions. Use the distance from the most recent
			-- previous position to the current position to find a displacement in the emitter
			-- heading direction for a guess at the curve's next point.
			local curp = self[_pos]
			local prev1 = self[_prev1]
			local prev2 = self[_prev2]

			Next:SetBasePlusScaled(pos, dir, min(prev1:DistanceTo(pos), self[_limit]))

			-- Compute an approximate curve distance and emit a trail for each emit distance
			-- crossed, doing any emit logic. The recent previous point becomes the old previous
			-- point, and the new recent point is made coincident with the emit point.
			Curve:SetCoeffs(prev2, prev1, pos, Next)

			self[_lapse]:SetCounter(Curve:BezierLen() / self[_divisor])

			for i, count, _, tally, total in self[_lapse]:WithTimeouts() do
				Curve:Eval(i / count, curp)

				prev2:Set(prev1)
				prev1:Set(curp)

				self:Signal("emit", total - tally, arg)
			end

			-- Update the emitter position.
			curp:Set(pos)

			-- Do any post-update logic.
			self:Signal("leave_update", self[_lapse]:GetCounter())
		end
	end
end,

--- Class constructor.
-- @class function
-- @name Constructor
-- @param wait Wait between emits.
-- @param divisor Speed to time scale factor.
-- @param limit Distance limit in computation of next point.
function(T, wait, divisor, limit)
	SuperCons(T, "Signalable")

	-- Speed to time scale --
	T[_divisor] = divisor

	-- Distance limit --
	T[_limit] = limit

	-- Previous vectors for Catmull-Rom state --
	T[_prev1] = New("Vec3D")
	T[_prev2] = New("Vec3D")

	-- Wait between emits --
	T[_wait] = wait

	-- Emit timer --
	T[_lapse] = New("Timer")
end, { base = "Signalable" })