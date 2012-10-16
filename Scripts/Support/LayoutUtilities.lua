
-- Layout Shortcuts for coodinates



local GetScreenSize = game.GetScreenSize
local LayoutTable = {}

module "LayoutUtilities"




function HorizontalWidth()
	if LayoutTable["HorizontalWidth"] then
		return LayoutTable["HorizontalWidth"]
	else
		local x , _ = GetScreenSize()
		LayoutTable["HorizontalWidth"] = x
		return LayoutTable["HorizontalWidth"]
	end
end

function VerticalHeight()
	if LayoutTable["VerticalHeight"] then
		return LayoutTable["VerticalHeight"]
	else
		local _ , y = GetScreenSize()
		LayoutTable["VerticalHeight"] = y
		return LayoutTable["VerticalHeight"]
	end
end



function CenterX()
	if LayoutTable["centerx"] then
		return LayoutTable["centerx"]
	else
		local x , y = GetScreenSize()
		LayoutTable["centerx"] = x / 2
		
		return LayoutTable["centerx"]
	end
end

function CenterY()
	if LayoutTable["centery"] then
		return LayoutTable["centery"]
	else
		local x , y = GetScreenSize()
		LayoutTable["centery"] = y / 2
		
		return LayoutTable["centery"]
	end
end

function TopLeft()
	if LayoutTable["topleft"] then
		return LayoutTable["topleft"]
	else
		LayoutTable["topleft"] = 0
		return LayoutTable["topleft"]
	end
end

function TopRight()
	if LayoutTable["topright"] then
		return LayoutTable["topright"]
	else
		local x , y = GetScreenSize()
		LayoutTable["topright"] = x 
		return LayoutTable["topright"]
	end
end

function BottomLeft()
	if LayoutTable["bottomleft"] then
		return LayoutTable["bottomleft"]
	else
		local x , y = GetScreenSize()
		LayoutTable["bottomleft"] = x 
		return LayoutTable["bottomleft"]
	end
end

function BottomRight()
	if LayoutTable["bottomright"] then
		return LayoutTable["bottomright"]
	else
		LayoutTable["bottomright"] = GetScreenSize() 
		return LayoutTable["bottomright"]
	end
end
