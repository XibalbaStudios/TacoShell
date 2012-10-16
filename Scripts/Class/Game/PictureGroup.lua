-----------
-- Imports
-----------
local ipairs = ipairs
local format = string.format
local Picture = graphicshelpers.Picture
local Texture = graphicshelpers.Texture

---------------------------------
-- PictureGroup class definition
---------------------------------
class.Define("PictureGroup", {
	-- Caches a picture
	-- name: Texture filename
	-- props: Optional external property set
	-- ...: Texture load arguments
	-- Returns: Picture handle
	-----------------------------------------
	Picture = function(G, name, props, ...)
		return Picture(G:Texture(name, ...), props)	
	end,

	-- Caches a range of pictures
	-- name: Texture filename format string
	-- first, last: Mapping range
	-- aprops: Optional external property set array
	-- ...: Texture load arguments
	-- Returns: Array of picture handles
	------------------------------------------------
	PictureRange = function(G, name, first, last, aprops, ...)
		local group, props = {}

		for i = first, last do
			props = aprops and aprops[#group + 1] or nil

			group[#group + 1] = G:Picture(format(name, i), props, ...)
		end

		return group
	end,

	-- Refreshes cached textures
	-----------------------------
	Refresh = function(G)
		for _, texture in ipairs(G.set) do
			texture:EnsureLoaded()
		end
	end,

	-- Caches a texture
	-- name: Texture filename
	-- ...: Texture load arguments
	-- Returns: Texture handle
	-------------------------------
	Texture = function(G, name, ...)
		local tex = Texture(name, "no_upload", ...)

		G.set[#G.set + 1] = tex

		return tex
	end,

	-- Caches a range of textures
	-- name: Texture filename format string
	-- first, last: Mapping range
	-- ...: Texture load arguments
	-- Returns: Array of texture handles
	----------------------------------------
	TextureRange = function(G, name, first, last, ...)
		local group = {}

		for i = first, last do
			group[#group + 1] = G:Texture(format(name, i), ...)
		end

		return group
	end,
},

-- Constructor
---------------
function(G)
	G.set = {}
end)