-- Standard library imports --
local pi = math.pi
local type = type
local unpack = unpack

-- Imports --
local AddParticleEffect = AddParticleEffect
local LatticeUV = effect.LatticeUV
local New = class.New
local Rand = math_ex.Rand
local RBy = math_ex.RBy
local GetPlayer = objects.GetPlayer

-- Cached effect state --
local CrumbleFile = {}

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

-- Crumble break effect definition --
DefineEffect("Break_Crumble", function(trail, killer, life, props)
    killer:GetDir(Dir)

	trail:GetPoints(P1, P2)

	-- particles for trail breaking effect
	Pos:SetAverage(P1, P2)

	if trail:GetAge(true) > 0.8 then
		AddParticleEffect(CrumbleFile["White"], Pos, Ori)
	else
		AddParticleEffect(CrumbleFile[GetPlayer(trail:GetID()):GetName()], Pos, Ori)
	end

	-- Break the quad up into a jittered lattice. Generate shards from the lattice, basing
	-- velocities and axes on grid position.
	for cx, cy, disps in LatticeUV(props) do
		local vx, vy, vz = Rand(.8, 1.5) * cx, Rand(.8, 1.5) * cy, Rand(.75, 2)

		-- Map the velocity with the direction.
		Vel:Set(vx, vy, vz)
--		Vel:Map(map)
		Vel:Add(Dir)
		Vel:Scale(Vel * Dir / (Vel * Vel))

		-- Provide damping and gravity.
		Acc:Set(Vel.x * Rand(-.15, -.05), Vel.y * Rand(-.15, -.05), Vel.z * Rand(-.15, -.05) - Rand(7.5, 9.5))

		-- Commit the shard with a random lifetime and spin.
		trail:AddShardProfile(Vel, Acc, disps, Rand(.6 * life, life), Rand(-.6, .6), RBy(pi, .4 * pi), RBy(pi / 2, .1))
	end

	return trail
end)

-- Cache effect resources.
RegisterPhaseEvents{
	before_enter = function()
		for i, pname in pairs(ParticleNames) do
			CrumbleFile[i] = New("ParticleEffectFile", "Particles/" .. pname)
		end
	end,
	shutdown_leave = function()
		CrumbleFile = {}
	end
}