-- See TacoShell Copyright Notice in main folder of distribution

-----------
-- Imports
-----------
local SuperCons = class.SuperCons

-------------------------
-- Grid class definition
-------------------------
class.Define("Grid", {
	-- Gets dimension cut counts
	-- Returns: Horizontal, vertical cuts
	--------------------------------------
	GetCuts = function(G, format)
		return G.hCuts or 0, G.vCuts or 0
	end,

	-- Computes the index of a column, row pair
	-- column, row: Column, row indices
	-- Returns: Index to which column, row pair maps
	-------------------------------------------------
	Index = function(G, column, row)
		return (row - 1) * (G:GetCuts() + 1) + column
	end,

	-- Indicates whether a cell is in use
	-- column, row: Column, row indices
	-- Returns: Results of usage routine
	--------------------------------------
	InUse = function(G, column, row)
		return G.used(column, row)
	end,

	-- Builds an iterator over the valid cells
	-- Returns: Iterator which supplies column, row
	------------------------------------------------
	Iter = function(G)
		-- Iterate through the cells, returning non-nil entries.
		local column, row, hCuts, vCuts = 1, 1, G:GetCuts()
		return function()
			while row <= vCuts + 1 do
				local rc, rr, data = column, row, G.used(column, row)
				if column == hCuts + 1 then
					column, row = 1, row + 1
				else
					column = column + 1
				end
				if data then
					return rc, rr, data
				end
			end
		end
	end,

	-- hCuts, vCuts: Horizontal, vertical cuts to assign
	-----------------------------------------------------
	SetCuts = function(G, hCuts, vCuts)
		G.hCuts, G.vCuts = hCuts, vCuts
	end
}, 

-- Constructor
-- group: Group handle
-- set: Method used to set a cell
-- used: Method used to indicate cell use
-- draw: Method used to draw a cell
------------------------------------------
function(G, group, set, used, draw)
	SuperCons(G, "Widget", group)

	-- Assign format parameters.
	G.used = used

	-- Signals --
	G:SetSignal{
		event = function(event)
			if event == WE.Grab then
				set(G.cc, G.cr)
			end
		end,
		test = function(cx, cy, x, y, w, h)	
			-- Determine which cell is the candidate.
			local hCuts, vCuts = G:GetCuts()
			local hp, vp = Misc.Partition(x, w, hCuts), Misc.Partition(y, h, vCuts)
			for column, part in ipairs(hp) do
				if cx >= part.value and cx < part.value + part.dim then
					G.cc = column
				end
			end
			for row, part in ipairs(vp) do
				if cy >= part.value and cy < part.value + part.dim then
					G.cr = row
				end			
			end
			return G
		end,
		update = function(x, y, w, h)
			-- Draw all valid entries.
			G:ApplyColor("C")
			local hCuts, vCuts = G:GetCuts()
			local hp, vp = Misc.Partition(x, w, hCuts), Misc.Partition(y, h, vCuts)
			for column, row, data in G:Iter() do
				draw(column, row, data, hp[column].value, vp[row].value, hp[column].dim + 1, vp[row].dim + 1)
			end

			-- Render the grid itself.
			G:ApplyColor("G")
			gfx.DrawGrid(x, y, w, h, hCuts, vCuts)
		end
	}
end, { base = "Widget" })