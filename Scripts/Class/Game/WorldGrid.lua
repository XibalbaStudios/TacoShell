-----------
-- Imports
-----------
local yield = coroutine.yield
local abs, floor = math.abs, math.floor
local insert, remove = table.insert, table.remove
local AARectIter
local LineIter

-- G: Grid handle
-- x: x-value
-- Returns: Column x-value occupies
------------------------------------
local function GetColumn (G, x)
	return floor((x - G.x) / G.cellw) + 1
end

-- G: Grid handle
-- row, col: Cell row, column
-- Returns: Cell index
------------------------------
local function GetIndex (G, row, col)
	return (row - 1) * G.cols + col
end

-- G: Grid handle
-- y: y-value
-- Returns: Row y-value occupies
---------------------------------
local function GetRow (G, y)
	return floor((y - G.y) / G.cellh) + 1
end

-- G: Grid handle
-- index: Cell index
-- bBuild: If true, build missing cell
-- Returns: Cell
---------------------------------------
local function GetCell (G, index, bBuild)
	local cell = G.cells[index]

	if not cell and bBuild then
		cell = {}

		G.cells[index] = cell
	end

	return cell
end

-- Yields a cell if available
-- G: Grid handle
-- area: Area, in cells
-- index: Cell index
-- cell: Cell handle
-- row, col: Cell row, column
-- bBuild: If true, build missing cell
---------------------------------------
local function YieldCell (G, area, index, row, col, bBuild)
	if index >= 1 and index <= area then
		local cell = GetCell(G, index, bBuild)

		if cell then
			yield(cell, row, col)
		end
	end
end

-----------------
-- Grid iterator
-----------------
local Iter = coroutine_ex.Create(function(func, G)
	func(G)
end)

do
	local Center, W, H, bTemp

	-- Axis-aligned rect iterator body
	-- G: Grid handle
	-----------------------------------
	local function AuxIter (G)
		local x, y, bBuild = Center.x, Center.y, bTemp
		local c1, r1 = GetColumn(G, x - W / 2), GetRow(G, y - H / 2)
		local c2, r2 = GetColumn(G, x + W / 2), GetRow(G, y + H / 2)
		local area, index, iinc = G.cols * G.rows, GetIndex(G, r1, c1), G.cols - (c2 - c1 + 1)

		for r = r1, r2 do
			for c = c1, c2 do
				YieldCell(G, area, index, r, c, bBuild)

				index = index + 1
			end

			index = index + iinc
		end
	end

	-- Builds an iterator over cells on or within an axis-aligned rect
	-- G: Grid handle
	-- center: Center position
	-- w, h: Box dimensions
	-- bBuild: If true, build missing cells
	-- Returns: Iterator that supplies cell, row, and column
	-------------------------------------------------------------------
	function AARectIter (G, center, w, h, bBuild)
		Center, W, H, bTemp = center, w, h, bBuild

		-- Supply the iterator routine.
		return Iter, AuxIter, G
	end
end

do
	local X1, Y1, X2, Y2, C1, R1, C2, R2, Area, Index, bTemp

	-- Column iterator body
	-- G: Grid handle
	------------------------
	local function Column (G)
		local bBuild, iinc, rinc = bTemp, R1 < R2 and G.cols or -G.cols, R1 < R2 and 1 or -1

		for _ = 1, abs(R2 - R1) + 1 do
			YieldCell(G, Area, Index, R1, C1, bBuild)

			Index, R1 = Index + iinc, R1 + rinc
		end
	end

	-- Row iterator body
	-- G: Grid handle
	---------------------
	local function Row (G)
		local bBuild, cinc = bTemp, C1 < C2 and 1 or -1

		for _ = 1, abs(C2 - C1) + 1 do
			YieldCell(G, Area, Index, R1, C1, bBuild)

			Index, C1 = Index + cinc, C1 + cinc
		end
	end

	-- Diagonal iterator body
	-- G: Grid handle
	--------------------------
	local function Diagonal (G)
		local bBuild, cinc, rinc, iinc, xoffinc = bTemp, 1, 1, G.cols, G.cellw
		local slope, xoff = (Y2 - Y1) / (X2 - X1), G.x + C1 * xoffinc - X1

		-- If the line tends left, adjust horizontal values.
		if C2 < C1 then
			cinc, xoff, xoffinc = -1, xoff - xoffinc, -xoffinc
		end

		-- If the line tends down, adjust vertical values.
		if R2 < R1 then
			rinc, iinc = -1, -iinc
		end

		-- On each column, go from the current to the final row. The final row
		-- becomes current at the end of each pass.
		local rlast

		while C1 ~= C2 do
			rlast = GetRow(G, Y1 + slope * xoff)

			while true do
				YieldCell(G, Area, Index, R1, C1, bBuild)

				if R1 == rlast then
					break
				end

				Index, R1 = Index + iinc, R1 + rinc
			end

			Index, C1, xoff = Index + cinc, C1 + cinc, xoff + xoffinc
		end

		-- Treat the final column separately, since the line could cover several
		-- more rows than desired while in this column.
		while rlast ~= R2 do
			YieldCell(G, Area, Index, rlast, C2, bBuild)

			Index, rlast = Index + iinc, rlast + rinc
		end	
	end

	-- Visits cells along a line
	-- G: Grid handle
	-- p1, p2: Start, end positions
	-- bBuild: If true, build missing cells
	----------------------------------------
	function LineIter (G, p1, p2, bBuild)
		X1, Y1, X2, Y2, bTemp = p1.x, p1.y, p2.x, p2.y, bBuild

		C1, R1 = GetColumn(G, X1), GetRow(G, Y1)
		C2, R2 = GetColumn(G, X2), GetRow(G, Y2)

		Area, Index = G.cols * G.rows, GetIndex(G, R1, C1)

		-- By default, traverse algorithmically. On column or row matches, do spans.
		local func = Diagonal

		if C1 == C2 then
			func = Column

		elseif R1 == R2 then
			func = Row
		end

		return Iter, func, G
	end
end

------------------------------
-- WorldGrid class definition
------------------------------
class.Define("WorldGrid", {
	AARectIter = AARectIter,
	GetColumn = GetColumn,
	GetIndex = GetIndex,
	GetRow = GetRow,
	LineIter = LineIter,

	-- Clears the grid
	-------------------
	Clear = function(G)
		local cells = {}

		for i = 1, G.cols * G.rows do
			cells[i] = false
		end

		G.cells = cells
	end,

	-- row, col: Cell row, column
	-- bBuild: If true, build missing cell
	-- Returns: Cell matching row and column
	-----------------------------------------
	GetCell = function(G, row, col, bBuild)
		if row >= 1 and row <= G.rows and col >= 1 and col <= G.cols then
			return GetCell(G, GetIndex(G, row, col), bBuild)
		end
	end,

	-- index: Cell index
	-- bBuild: If true, build missing cell
	-- Returns: Cell matching index
	---------------------------------------
	GetCellFromIndex = function(G, index, bBuild)
		if index >= 1 and index <= G.cols * G.rows then
			return GetCell(G, index, bBuild)
		end
	end,

	-- x, y: Coordinates in cell
	-- bBuild: If true, build missing cell
	-- Returns: Cell matching x and y
	---------------------------------------
	GetCellFromXY = function(G, x, y, bBuild)
		return G:GetCell(GetRow(G, y), GetColumn(G, x), bBuild)
	end
},

-- Constructor
-- x, y: Grid coordinates
-- w, h: Grid dimensions
-- cols: Column count
-- rows: Row count
--------------------------
function(G, x, y, w, h, cols, rows)
	G.cellw, G.cellh, G.x, G.y, G.cols, G.rows = w / cols, h / rows, x, y, cols, rows

	G:Clear()
end)