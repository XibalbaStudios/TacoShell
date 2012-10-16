-- Standard library imports --
local pairs = pairs
local pi = math.pi

-- Imports --
local AddParticleEffect = AddParticleEffect
local LatticeUV = effect.LatticeUV
local New = class.New
local Rand = math_ex.Rand
local RBy = math_ex.RBy
local GetPlayer = objects.GetPlayer

local ParticleNames = { Adrian = "scatter_adrian.xml", Ashley = "scatter_ashley.xml", Billy = "scatter_billy.xml", Bones = "scatter_bones.xml", Enrique = "scatter_enrique.xml", Hanna = "scatter_hannah.xml", JeanClaude = "scatter_jeanclaude.xml", SpaceMonkey = "scatter_spacemonkey.xml", White = "scatter_white.xml" }

-- Cached effect state --
local ScatterFile = {}

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

-- Scatter break effect definition --
DefineEffect("Break_Scatter", function(trail, killer, life, props)
	local speed

	if props.use_velocity then
		killer:GetVelocity(Dir)

		speed = #Dir

		Dir:Scale(1 / speed)

	else
		speed = killer:GetSpeed() / 2

		killer:GetDir(Dir)
	end

    trail:GetPoints(P1, P2)

	-- particles for trail breaking effect
	Pos:SetAverage(P1, P2)

	if trail:GetAge(true) > 0.8 then
		AddParticleEffect(ScatterFile["White"], Pos, Ori)
	else
		AddParticleEffect(ScatterFile[GetPlayer(trail:GetID()):GetName()], Pos, Ori)
	end
	

	-- Break the quad up into a jittered lattice. Generate shards from the lattice, basing
	-- velocities and axes on grid position.
	for cx, cy, disps in LatticeUV(props) do
		local vx, vy, vz = Rand(.8, 1.5) * cx, Rand(.8, 1.5) * cy, Rand(.75, 2)

		-- Map the velocity with the impact direction.
		Vel:Set(vx, vy, vz)
--		Vel:Map(map)
		Vel:Add(Dir)
		Vel:Scale(Vel * Dir / (Vel * Vel) * Rand(1.5 * speed, 2 * speed))

		-- Provide damping and gravity.
		Acc:Set(Rand(-Vel.x / 2, 0), Rand(-Vel.y / 2, 0), Vel.z * Rand(-.15, -.05) - Rand(5.5, 7.5))

		-- Commit the shard with a random lifetime and spin.
		trail:AddShardProfile(Vel, Acc, disps, Rand(.6 * life, life), Rand(-2.5, 2.5), 0, RBy(pi / 2, .1))
	end

	return trail
end)

-- Cache effect resources.
RegisterPhaseEvents{
	before_enter = function()
		for i, pname in pairs(ParticleNames) do
			ScatterFile[i] = New("ParticleEffectFile", "Particles/" .. pname);
			
		end
	end,
	shutdown_leave = function()
		ScatterFile = {}
	end
}