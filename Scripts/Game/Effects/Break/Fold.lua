-- Standard library imports --
local abs = math.abs
local atan2 = math.atan2
local min = math.min
local sqrt = math.sqrt

-- Imports --
local AddParticleEffect = AddParticleEffect
local LatticeUV = effect.LatticeUV
local New = class.New
local Rand = math_ex.Rand
local RBy = math_ex.RBy
local GetPlayer = objects.GetPlayer

-- Cached effect state --
local FoldFile = {}
local ParticleNames = { Adrian = "scatter_adrian.xml", Ashley = "scatter_ashley.xml", Billy = "scatter_billy.xml", Bones = "scatter_bones.xml", Enrique = "scatter_enrique.xml", Hanna = "scatter_hannah.xml", JeanClaude = "scatter_jeanclaude.xml", SpaceMonkey = "scatter_spacemonkey.xml", White = "scatter_white.xml" }

-- Impact direction --
local Dir = New("Vec3D")

-- Velocity, acceleration --
local Vel = New("Vec3D")
local Acc = New("Vec3D")

-- Trail points --
local P1, P2 = New("Vec3D"), New("Vec3D")

-- Scatter position, orientation --
local Pos = New("Vec3D")
local Ori = New("Vec3D", 0, 90, 0)

-- Magic numbers --

-- Offset helper
local function Offset (v, numv)
	return numv - v + 1
end

-- Random point helper
local function Mid ()
	return RBy(.5, .1)
end

-- Scale helper
local function Scale (v, midv)
	return min(1 - abs(v - midv) / midv, 1) * Rand(.8, 1.5)
end

-- Fold break effect definition --
DefineEffect("Break_Fold", function(trail, killer, life, props)
	killer:GetDir(Dir)

	local speed = killer:GetSpeed() / 2

    trail:GetPoints(P1, P2)

	-- particles for trail breaking effect
	Pos:SetAverage(P1, P2)

	if trail:GetAge(true) > 0.8 then
		AddParticleEffect(FoldFile["White"], Pos, Ori)
	else
		AddParticleEffect(FoldFile[GetPlayer(trail:GetID()):GetName()], Pos, Ori)
	end
	-- Break the quad up into a jittered lattice. Generate shards from the lattice, basing
	-- velocities and axes on grid position.
	local ncols, nrows = props.ucount + 1, props.vcount + 1
	local mid_c, mid_r = ncols / 2, nrows / 2
	local pivot = min(mid_c, mid_r)

	for cx, cy, disps, r, c in LatticeUV(props) do
		local coffset, roffset = Offset(c, ncols), Offset(r, nrows)
		local u1, u2, v1, v2

		-- Upper left --
		if c <= pivot and c == r then
			u2, v1 = 1, 0

		-- Lower left --
		elseif c <= pivot and c == roffset then
			u2, v1 = 1, 1

		-- Upper right --
		elseif coffset <= pivot and coffset == r then
			u2, v1 = 0, 0

		-- Lower right --
		elseif coffset <= pivot and coffset == roffset then
			u2, v1 = 0, 1

		-- Off-diagonal --
		else
			local o1, o2 = Offset(r, ncols), Offset(roffset, ncols)

			-- Upper and lower side --
			if (c > r and c < o1) or (c > roffset and c < o2) then
				u1, u2 = 0, 1

			-- Left and right side --
			elseif (c < r or c > o1) or (c < roffset or c > o2) then
				v1, v2 = 0, 1

			-- Interior --
			else
				u1, v1 = RBy(.25, .075), RBy(.25, .075)
				u2, v2 = RBy(.75, .075), RBy(.75, .075)
			end
		end

		-- Compute an axis.
		local du, dv = (u2 or Mid()) - (u1 or Mid()), (v2 or Mid()) - (v1 or Mid())

		-- Map the velocity with the impact direction.
		local vx, vy, vz = cx * Scale(c, mid_c), cy * Scale(r, mid_r), Rand(.75, 2)

		Vel:Set(vx, vy, vz)
--		Vel:Map(map)
		Vel:Add(Dir)
		Vel:Scale(Vel * Dir / (Vel * Vel) * Rand(1.5 * speed, 2 * speed))

		-- Provide damping and gravity.
		Acc:Set(Rand(-Vel.x / 2, 0), Rand(-Vel.y / 2, 0), Vel.z * Rand(-.15, -.05) - Rand(5.5, 7.5))

		-- Commit the shard with a random lifetime and spin.
		trail:AddShardProfile(Vel, Acc, disps, Rand(.6 * life, life), Rand(-2.5, 2.5), RBy(.1, .05), atan2(dv, du))
	end

	return trail
end)

-- Cache effect resources --
RegisterPhaseEvents{
	before_enter = function()
		for i, pname in pairs(ParticleNames) do
			FoldFile[i] = New("ParticleEffectFile", "Particles/" .. pname)
		end
	end,
	shutdown_leave = function()
		FoldFile = {}
	end
}