----------------------------
-- Standard library imports
----------------------------
local ipairs = ipairs
local pairs = pairs
local type = type

-----------
-- Imports
-----------
local Load2DTexture = gfx.Load2DTexture
local LoadAnimTexture = gfx.LoadAnimTexture
local LoadVideoTexture = gfx.LoadVideoTexture
local LoadRotTexture = gfx.LoadRotTexture
local LoadFont = gfx.LoadFont
local New = class.New

-------------------
-- Cached routines
-------------------
local Picture_
local Texture_

-- Export graphics helpers namespace.
module "graphicshelpers"

-- Helper to load animated textures
-- input: Texture name/handle table
-- mode: Animation mode
-- phase: Animation phase
-- ...: Texture flags
-- Returns: Animated texture handle
------------------------------------
function AnimTexture (input, mode, phase, ...)
	for i, entry in ipairs(input) do
		input[i] = Texture_(entry, ...)
	end

	return LoadAnimTexture(input, mode, phase)
end

-- Helper to load multipictures
-- input: Texture name/handle table
-- mode: Multipicture mode
-- thresholds: Threshold values
-- props: Optional external property set
-- ...: Texture flags
-- Returns: Multipicture handle
-----------------------------------------
function MultiPicture (input, mode, thresholds, props, ...)
	local multi = New("MultiPicture", mode, props)

	for k, v in pairs(thresholds) do
		multi:SetThreshold(k, v)
	end

	for i, entry in ipairs(input) do
		multi:SetPicture(i, Picture_(entry, nil, ...))
	end

	return multi
end

-- Helper to build a picture
-- texture: Texture name/handle
-- props: Optional external property set
-- ...: Texture flags
-- Returns: Picture handle
-----------------------------------------
function Picture (texture, props, ...)
	return New("Picture", Texture_(texture, ...), props)
end

function RotTexture(input, ...)
	return type(input) == "string" and LoadRotTexture(input, ...) or input
end 

function RotPicture(texture, props, ...)
	return New("Picture", RotTexture(texture, ...), props)
end

-- Helper to load picture textures
-- input: Texture name/handle
-- ...: Texture flags
-- Returns: Texture handle
-----------------------------------
function Texture (input, ...)
	return type(input) == "string" and Load2DTexture(input, ...) or input
end

-- Helper to load video textures
-- input: Video filename
-- w, h: Texture width and height
-- Returnes: Texture handle ( a 2d texture that gets updated with the video info )
function VideoTexture( input, w, h, loop, framerate )
	return type( input ) == "string" and LoadVideoTexture( input, w , h, loop, framerate  ) or input
end

-- Cache some routines.
Picture_ = Picture
Texture_ = Texture