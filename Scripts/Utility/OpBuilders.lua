-- Standard library imports --
local pairs = pairs
local sort = table.sort

-- Imports --
local GetLanguage = settings.GetLanguage
local Identity = funcops.Identity

-- Cached routines --

-- Export operation builders namespace.
module "opbuilders"

--- Gets and sorts a table's keys.
-- @param t Source table.
-- @param map Optional mapping function, called as<br><br>
-- &nbsp&nbsp&nbsp<b><i>map(k, v)</i></b>,<br><br>
-- where <i>k</i> is the key and <i>v</i> the value. The return
-- value is appended to the key array.<br><br>
-- If absent, this is <b>funcops.Identity</b>.
-- @param comp Optional key compare function for table sorting.
-- @return Key array.
function GetSortedKeys (t, map, comp)
    local dt = {}
   
	map = map or Identity

	for k, v in pairs(t) do
		dt[#dt + 1] = map(k, v)
	end

	sort(dt, comp)

	return dt
end

do
    -- i1, i2: Items to compare
    -- Returns: If true, i1 precedes i2
    local function Compare (i1, i2)
        return i1.name < i2.name
    end

	--- Builds a list sorter function.<br><br>
	-- The returned function takes no arguments. When called, it processes the list and
	-- returns an array of tables, ordered according to key order.<br><br>
	-- The <b>name</b> field of each table will contain the key. If present in the subtables
	-- returned by <i>getentry</i>, the language-specific fields <b>name_cur</b>, <b>desc</b>,
	-- and <b>hdesc</b> will be copied over as well; the last will be an empty string if absent.
    -- @param list List to sort. All keys must be comparable via the <b><</b> operator.
    -- @param getentry Entry lookup function, called as<br><br>
	-- &nbsp&nbsp&nbsp<b><i>getentry(list, name, item)</i></b>,<br><br>
	-- where <i>list</i> is the parameter, <i>name</i>is the key of the current item in the
	-- list, and <i>item</i> is the value of said item. This should return a table, where each
	-- key is a language name string, and each value is a tables,
	-- where each key is a valid language name string.
    -- @return Function which returns ordered list of named items.
    function NamedListSorter (list, getentry)
        

        local function Map(name, item)
			--messagef("name: %s", name )
            local entry = getentry(list, name, item)

            return { name = name, name_cur = entry.name, desc = entry.desc, hdesc = entry.hdesc or "" }
        end

        return function()
            return GetSortedKeys_(list, Map, Compare)
        end
    end
end

-- Cache some routines.
GetSortedKeys_ = GetSortedKeys