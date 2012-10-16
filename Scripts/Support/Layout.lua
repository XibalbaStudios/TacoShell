----------------------------
-- Standard library imports
----------------------------
local assert = assert
local ipairs = ipairs
local max = math.max
local pairs = pairs

-----------
-- Imports
-----------
local GetScreenSize = game.GetScreenSize
local NoOp = funcops.NoOp
local StringGetH = widgetops.StringGetH
local StringSize = widgetops.StringSize
local GetRes = gfx.GetRes

-------------------
-- Cached routines
-------------------
local GetMaxStringSize_

-- Export the layout namespace.
module "layout"

-- Formats and attaches a column of text-bearing widgets
-- pane: Attachment pane
-- widgets: Widget set
-- x, y: Attachment corner coordinates
-- padding: Padding added to the column width
-- align: Member alignment
-- sep: Item separation as a multiple of string height
-- count: Optional attach height as multiple of string height
-- func: Optional function called on items after attachment
-- context: Optional input to function
-- Returns: Padded column width, height
--------------------------------------------------------------
function Column (pane, widgets, x, y, padding, align, sep, count, func, context)
	local sep, y0, w, vw = sep + (count or 0), y, GetMaxStringSize_(widgets) + padding, GetScreenSize()

	-- Perform alignment adjustments.
	if align == "center" then
		x = x + (vw - w) / 2
	end


	-- Attach each widget.
	func = func or NoOp

	for i, widget in ipairs(widgets) do
		local font, string = widget:GetFont(), widget:GetString() 

		if font and string then
			local xcur, ww, wh, strw, strh = x, nil, nil, StringSize(widget, string)

			if count then
				ww, wh = w, strh * count
			elseif align == "center" then
				xcur = xcur + (w - strw) / 2
			end

			
			pane:Attach(widget, xcur, y, ww, wh)

			func(i, widget, xcur, y, ww, wh, context)
			y = y + sep * strh
		end
	end

	return w, y - y0
end

-- Formats and attaches a Row of text-bearing widgets
-- pane: Attachment pane
-- widgets: Widget set
-- x, y: Attachment corner coordinates
-- padding: Padding added to the column width
-- align: Member alignment
-- sep: Item separation as a multiple of string height
-- count: Optional attach height as multiple of string height
-- func: Optional function called on items after attachment
-- context: Optional input to function
-- bwidth: Optional button width 
-- bheight: Optional button height
-- Returns: Padded column width, height
--------------------------------------------------------------
function Row (pane, widgets, x, y, padding, align, sep, count, func, context,bwidth,bheight)
	local sep, y0, vw = sep + (count or 0), y, GetScreenSize()
	local w = GetMaxStringSize_(widgets) + padding

	-- Perform alignment adjustments.
	if align == "center" then
		x = x + (vw - w) / 2
	end


	-- Attach each widget.
	func = func or NoOp

	-- get button widths,heights
	local bw,bh = bwidth or 128, bheight or 128

	for i, widget in ipairs(widgets) do
		local font, string = widget:GetFont(), "widget:GetString()"

		if font and string then

			--pane:Attach(widget, x, y, 128, 128)
			pane:Attach(widget, x, y, bw, bh)
			
			func(i, widget, context)

			x = x + sep * 51
		end
	end
	-- return the new cummulative width
	return x
end

--Attaches a Row, without considering if the widgets have text
--pane: attachment pane
--widgets: widgets list
-- x, y: start coordinates of the row
--w,h: dimentions of each button
--sep: separation between buttons
--wLookup: optional table for variable sized widgets

function SimpleRow( pane, widgets, x, y, w, h, sep, wLookup )
	assert(wLookup and (#widgets == #wLookup) or true, "Lookup size is not correct" )
	
	for i, widget in ipairs( widgets ) do
		w = wLookup == nil and w or wLookup[i]
		pane:Attach( widget, x, y, w ,h )
		x = x + w + sep
	end
end


--Attaches a Column,
--pane: attachment pane
--widgets: widgets list
-- x, y: start coordinates of the row
--w,h: optional dimentions of each widget ( GetW and GetH are used if these are nil )
--sep: optional separation between buttons
function SimpleColumn( pane, widgets, x, y, w, h , sep )
	for _, widget in ipairs( widgets ) do
		h = h or widget:GetH()
		pane:Attach( widget,	x,	y,	w or widget:GetW()	,	h )
		y = y + h + ( sep or 0 )
	end
end



-- Gets the height of a column of text-bearing widgets
-- widgets: Widget set
-- sep: Item separation as a multiple of string height
-- count: Optional attach height as multiple of string height
-- Returns: Height
--------------------------------------------------------------
function GetColumnHeight (widgets, sep, count)
	local h, sep = 0, sep + (count or 0)

	for _, widget in ipairs(widgets) do
		h = h + sep * StringGetH(widget, widget:GetString())
	end

	return h
end

-- Gets the maximum dimensions to use for a set of strings
-- widgets: Widgets with relevant strings
-- Returns: Maximum dimensions
-----------------------------------------------------------
function GetMaxStringSize (widgets)
	local w, h = 0, 0

	for _, widget in pairs(widgets) do
		local sw, sh = StringSize(widget, widget:GetString())

		w, h = max(w, sw or 0), max(h, sh or 0)
	end

	return w, h
end

-- Loads a set of widget strings
-- widgets: Widgets to load
-- strings: Strings to assign
-- bArray: If true, treat tables as arrays
-------------------------------------------
function LoadStrings (widgets, strings, bArray)
	assert(#strings == #widgets, "[Loadstrings] widget and strings size mismatch")
	for k, string in (bArray and ipairs or pairs)(strings) do
		widgets[k]:SetString(string)
	end
end

-- simple Utility functions

-- Return the X percentage of the screen
-- 0 - 100%
function GetPX(percentage)
	local x , _ = GetRes()
	return percentage / 100 * x
end

-- Return the Y percentage of the screen
-- 0 - 100%
function GetPY(percentage)
	local _ , y = GetRes()
	return percentage / 100 * y
end

function RelativeCoord( originalcoord, originalW, newW)
	return newW * originalcoord / originalW
end



-- Cache some routines.
GetMaxStringSize_ = GetMaxStringSize