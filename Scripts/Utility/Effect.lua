-- Standard library imports --
local yield = coroutine.yield

-- Imports --
local Create = coroutine_ex.Create
local RBy = math_ex.RBy

-- Export the effect namespace.
module "effect"

local Us1, Vs1, Us2, Vs2, D1, D2, D3, D4, USize, IncU, Du = {}, {}, {}, {}, {}, {}, {}, {}
local Disps = { D1, D2, D3, D4 }

-- Fills in the u- and v-values for a row, given a v-center; u[1] = -1, u[N] = +1
-- us, vs: u- and v-row to fill
-- v, dv: v-center; allowed variation
local function GetRow (us, vs, v, dv)
	local u, nextu = -1, IncU - 1

	for c = 1, USize - 1 do
		us[c], vs[c], u, nextu = u, RBy(v, dv), RBy(nextu, Du), nextu + IncU
	end

	us[USize], vs[USize] = 1, RBy(v, dv)
end

-- Joins two neighboring rows and submits the resulting quads
-- v, dv: v-center of second row; allowed variation
-- row: Row index
local function Load (v, dv, row)
	-- Fill the next row.
	GetRow(Us2, Vs2, v, dv)

	-- Iterate over the columns, merging the current and next row.
	local u1, u3, v1, v3 = Us1[1], Us2[1], Vs1[1], Vs2[1]

	for c = 1, USize - 1 do
		local u2, u4, v2, v4 = Us1[c + 1], Us2[c + 1], Vs1[c + 1], Vs2[c + 1]

		-- Get the corner displacements, in [0, 1].
		D1[1], D1[2] = u1 / 2 + .5, v1 / 2 + .5
		D2[1], D2[2] = u2 / 2 + .5, v2 / 2 + .5
		D3[1], D3[2] = u3 / 2 + .5, v3 / 2 + .5
		D4[1], D4[2] = u4 / 2 + .5, v4 / 2 + .5

		-- Supply the centroid, in [-1, +1], and corner displacements.
		yield((u1 + u2 + u3 + u4) / 4, (v1 + v2 + v3 + v4) / 4, Disps, row, c)

		-- Advance to the right. Move the right-hand corners into the corresponding
		-- left-hand spots for the next column.
		u1, u3, v1, v3 = u2, u4, v2, v4
	end

	-- Swap the rows to retain new values on the next submission.
	Us1, Vs1, Us2, Vs2 = Us2, Vs2, Us1, Vs1
end

-- Lattice generator coroutine --
local Iter = Create(function(vcount, dv)
	-- Fill the first row, which is unaccounted for by swapping.
	GetRow(Us1, Vs1, 1, 0)

	-- Submit all rows up to the last.
	local incv = 2 / (vcount + 1)

	for r = 1, vcount do
		Load(1 - r * incv, dv, r)
	end

	-- Submit the final row.
	Load(-1, 0, vcount + 1)
end)

-- Stochastically generates a uv-point lattice
-- props: Lattice properties
-- Returns: (ucount + 2) x (vcount + 2) uv-lattice
---------------------------------------------------
function LatticeUV (props)
	local ucount = props.ucount

	USize, IncU, Du = ucount + 2, 2 / (ucount + 1), props.du

	return Iter, props.vcount, props.dv
end