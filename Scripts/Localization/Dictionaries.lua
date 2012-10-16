local loadfile = loadfile
local char = string.char
local tonumber = tonumber
local assert = assert
local pairs = pairs
local type = type
local gsub = string.gsub
local Load = Load
local APairs = iterators.APairs
local Find = table_ex.Find
local Weak = table_ex.Weak
local GetLanguage = settings.GetLanguage
local SetLanguage = settings.SetLanguage
local GetFM_Loader  = game.GetFM_Loader
local Languages = Languages
--local Preprocess = ui.Preprocess

module "dictionaries"

local Dictionary
local CurrentKey

do
	-- Replace helper
	local function AuxReplace (n1, n2)
		return char(tonumber(n1 .. n2, 16))
	end

	-- Preprocess helper
	local function AuxPreprocess (t, sub_with)
		for k, v in pairs(t) do
			if type(v) == "table" then
				AuxPreprocess(v, sub_with)
			else
				t[k] = gsub(v, sub_with, AuxReplace)
			end
		end
	end

	--- Preprocesses a language string table
	-- @param str_table Table of strings in each language.
	-- @param control Control character; '%' by default.
	function Preprocess (str_table, control)
		if str_table then
			local sub_with = (control or "%%") .. "(%x)(%x)"

			AuxPreprocess(str_table, sub_with)
		end
	end

	-- Install the preprocessor in the section logic.
	--SetPreprocessor(Preprocess)
end

function SetDictionary( lang )
	Dictionary = Dictionary or Weak( "k" )
	CurrentKey = {}
	Dictionary[ CurrentKey ] = {}
	
	if Find (Languages, lang, true) == nil then
		lang = Languages[1]
	end
	-- Load (item, prefix, env, arg, ext, loader)
	--Load(name, "Scenes/", vars, _G, nil, )--"../Scripts/Scenes/", vars, _G)
	Load( lang, "Localization/", Dictionary[ CurrentKey ], nil, nil,GetFM_Loader() )
	
	if lang == "chinese" or lang == "japanese" or lang == "korean" then
		Preprocess( Dictionary[ CurrentKey ] )
	end
end

function GetFileTable( file )
	
	return Dictionary[ CurrentKey ][file]
end

if Find (Languages,  GetLanguage(), true) == nil then
	SetLanguage( Languages[1] )
end

SetDictionary( GetLanguage() )