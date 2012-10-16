return {
	function()
		if bUsingJIT then
			require("jit.opt").start()
		end

		require("strict")
	end,

	-----------------------------------------
	-- Add some helpers for module debugging
	-----------------------------------------
	function ()
		----------------------------
		-- Standard library imports
		----------------------------
		local _G = _G
		local getfenv = getfenv
		local getmetatable = getmetatable
		local loaded = package.loaded
		local setfenv = setfenv
		local setmetatable = setmetatable
		local type = type

		-- Extend the module function.
		local old_module = module
		local imports = { gprintf_temp_at = true, messagef = true, printf = true, vardump = true }

		function module (name, ...)
			old_module(name, ...)

			local mtable = loaded[name]
			local meta = getmetatable(mtable) or {}
			local index = meta.__index
			local itype = type(index)

			function meta.__index (t, k)
				if imports[k] then
					return _G[k]
				elseif itype == "function" then
					return index(k)
				elseif itype == "table" then
					return index[k]
				end
			end

			setmetatable(mtable, meta)
			setfenv(2, getfenv())
		end
	end,

	----------------------
	-- Base functionality
	----------------------
	{ name = "Base", boot = "Boot" },

	----------------------
	-- Enhance debugging support
	-----------------------------
	function ()
		vardump.SetDefaultOutf(printf)
	end,

	---------------------
	-- Primitive classes
	---------------------
	{ name = "Class", boot = "PrimitivesBoot" }
}, ...