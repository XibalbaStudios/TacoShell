-- See TacoShell Copyright Notice in main folder of distribution

-- Standard library imports --
local assert = assert
local pairs = pairs
local setmetatable = setmetatable
local unpack = unpack

-- Imports --
local APairs = iterators.APairs
local AttachToRoot = widgetops.AttachToRoot
local CallOrGet = funcops.CallOrGet
local CollectArgsInto = varops.CollectArgsInto
local CueSound = audio.CueSound
local Execute = contexts.Execute
local FocusChain = contexts.FocusChain
local GetLanguage = settings.GetLanguage
local GetRes = gfx.GetRes
local GetScreenSize = game.GetScreenSize
local IsCallable = varops.IsCallable
local New = class.New
local NoOp = funcops.NoOp
local PurgeAttachList = widgetops.PurgeAttachList
local Render = contexts.Render
local SectionGroup = contexts.SectionGroup
local Type = class.Type
local UIGroup = contexts.UIGroup
local WaitUntil = coroutineops.WaitUntil
local GetFileTable = dictionaries.GetFileTable

-- Cached routines --
local CleanupEventStreams_
local Closer_
local GetEventStream_
local GetLookup_
local SetLookupTable_

-- String table preprocessor --
local Preprocessor

-- Event streams --
local Streams = {}

for _, when in APairs("enter_render", "leave_render", "enter_trap", "leave_trap", "enter_update", "leave_update", "between_frames") do
	Streams[when] = {}
end

-- Export section namespace.
module "section"

-- Section lookup tables --
local Lookups = {}

do
	local Arg, How, DefFunc
	local Marks = setmetatable({}, {
		__index = function()
			return DefFunc
		end,
		__mode = "k"
	})

	-- Stream cleanup helper
	-- task: Stream task
	-- Returns: Task, or nil
	local function Cleanup (task)
		return (Marks[task](task, How, Arg))
	end

	-- streams: Stream set
	-- all_groups: If true, get streams in all section groups
	-- Returns: Cleanup iterator
	local function GetIterator (streams, all_groups)
		if all_groups then
			return pairs(streams)
		else
			local stream = streams[SectionGroup()]

			if stream then
				return APairs(stream)
			else
				return NoOp
			end
		end
	end

	-- Cleans up event streams before major switches
	-- how: Event cleanup descriptor
	-- all_groups: If true, cleanup streams in all section groups
	-- def_func: Optional function to call on unmarked events
	-- omit: Optional stream to ignore during cleanup
	-- arg: Cleanup argument
	--------------------------------------------------------------
	function CleanupEventStreams (how, all_groups, def_func, omit, arg)
		assert(def_func == nil or IsCallable(def_func), "Invalid default function")

		Arg, How, DefFunc = arg, how, def_func ~= nil and def_func or NoOp

		for name, streams in pairs(Streams) do
			if name ~= omit then
				for _, stream in GetIterator(streams, all_groups) do
					stream:Map(Cleanup, true)
				end
			end
		end
	end

	-- Marks a task with a function to call on cleanup
	-- task: Task to mark
	-- cleanup: Cleanup function
	---------------------------------------------------
	function MarkTask (task, cleanup)
		assert(IsCallable(task), "Uncallable task")
		assert(IsCallable(cleanup), "Uncallable cleanup function")

		Marks[task] = cleanup
	end
end

-- Helper to get the between-frames stream and collect arguments
local function GetStreamAndArgs (...)
	return GetEventStream_("between_frames"), CollectArgsInto(nil, ...)
end

-- Helper to close a section
local function CloseSection (name, count, args)
	SectionGroup():Close(CallOrGet(name), unpack(args, 1, count))
end

--- Closes a section.
-- @param name Section name
-- @param ... Arguments to section close
function Close (name, ...)
	local stream, count, args = GetStreamAndArgs(...)

	stream:Add(function()
		CloseSection(name, count, args)
	end)
end

-- Builds a section close routine
-- name: Section name
-- ...: Arguments to section close
-- Returns: Closure to close section
-------------------------------------
function Closer (name, ...)
	local stream, count, args = GetStreamAndArgs(...)

	return function()
		stream:Add(function()
			CloseSection(name, count, args)
		end)
	end
end

-- Builds a conditional section close routine
-- name: Section name
-- test: Condition test
-- otherwise: Optional action if test fails
-- ...: Arguments to section close
-- Returns: Closure to close section
----------------------------------------------
function CloserIf (name, test, otherwise, ...)
	local closer = Closer_(name, ...)

	return function()
		if test() then
			closer()
		else
			(otherwise or NoOp)()
		end
	end
end

-- Gets a section group's event stream
-- event: Event name
-- index: Optional group index
-- Returns: Stream handle
---------------------------------------
function GetEventStream (event, index)
	local sg, set = SectionGroup(index), assert(Streams[event], "Invalid event stream")

	set[sg] = set[sg] or New("Stream")

	return set[sg]
end

-- Gets a section's lookup set
-- data: Section data
-- Returns: Lookup set in the current language
-----------------------------------------------
function GetLookup (data)
	local table = GetFileTable( Lookups[data] )

	return table and table or nil
end

-- Loads a section, handling common functionality
-- name: Section name
-- proc: Section procedure
-- lookup: Optional lookup table
-- arg1, ...: Load arguments
--------------------------------------------------
function Load (name, proc, lookup, ...)
	local sg, uig, data = SectionGroup(), UIGroup(), {}

	-- Wrap the procedure in a routine that handles common logic. Load the section.
	sg:Load(name, function(state, arg1, ...)
		-- On close, detach the pane.
		if state == "close" then
			if data.pane then
				PurgeAttachList(data.pane)

				data.pane:Detach()
			end

			-- Remove current focus items.
			local chain = FocusChain(data, true)

			if chain then
				chain:Clear()
			end

			-- Sift out section-specific messages.
			if arg1 then
				CleanupEventStreams_("close_section", false, nil, "between_frames", name)
			end

		-- On load, register any lookup table.
		elseif state == "load" then
			SetLookupTable_(data, lookup)

		-- On render, draw the UI.
		elseif state == "render" then
			(Streams.enter_render[sg] or NoOp)(data)

			Render(uig);

			(Streams.leave_render[sg] or NoOp)(data)

		-- On trap, direct input to the UI.
		elseif state == "trap" then
			(Streams.enter_trap[sg] or NoOp)(data)

			if not data.blocked then
				Execute(uig, data)
			end

			(Streams.leave_trap[sg] or NoOp)(data)

		-- On update, update the UI.
		elseif state == "update" then
			(Streams.enter_update[sg] or NoOp)(data)

			uig:Update(arg1);

			(Streams.leave_update[sg] or NoOp)(data)
		end

		-- Do section-specific logic.
		if state ~= "trap" or not data.blocked then
			return proc(state, data, arg1, ...)
		end
	end, ...)
end

-- Helper to open a section
local function OpenSection (name, count, args, clear_sections)
	UIGroup():Clear()

	local sg = SectionGroup()
	local from = sg:Current()
	local to = CallOrGet(name)

	if from then
		sg:Send(from, "message:going_to", to)
	end

	if clear_sections then
		sg:Clear()
	end

	sg:Send(to, "message:coming_from", from)
	sg:Open(to, unpack(args, 1, count))
end

-- Opens a section dialog and waits for it to close
-- name: Section name
-- ...: Arguments to section enter
----------------------------------------------------
function OpenAndWait (name, ...)
	local is_done
	local stream, count, args = GetStreamAndArgs(function()
        is_done = true
    end, ...)

    stream:Add(function()
		OpenSection(name, count, args)
	end)

    WaitUntil(function()
        return is_done
    end)
end

-- Builds a section dialog open routine
-- name: Section name
-- ...: Arguments to section enter
-- Returns: Closure to open dialog
----------------------------------------
function OpenDialog (name, ...)
	local stream, count, args = GetStreamAndArgs(...)

	return function()
		stream:Add(function()
			OpenSection(name, count, args)
		end)
	end
end

-- Builds a section screen open routine
-- name: Section name
-- ...: Arguments to section enter
-- Returns: Closure to open screen
----------------------------------------
function OpenScreen (name, ...)
	local stream, count, args = GetStreamAndArgs(...)

	return function()
		stream:Add(function()
			OpenSection(name, count, args, true)
		end)
	end
end

-- Opens a single-layer section; closes other sections
-- name: Section name
-- sound: Sound to play on transition
-- ...: Arguments to section enter
-------------------------------------------------------
function Screen (name, sound, ...)
	local stream, count, args = GetStreamAndArgs(...)

	stream:Add(function()
		-- Play transition sound.
		if sound then
			CueSound(sound)
		end

		-- Open the section.
		OpenSection(name, count, args, true)
	end)
end

-- Sets the section's lookup table
-- data: Section data
-- lookup: Lookup table
-----------------------------------
function SetLookupTable (data, lookup)
	--(Preprocessor or NoOp)(lookup)
	
	Lookups[data] = lookup
end

--- Sets a string preprocessor.
-- @param func Preprocess function.
function SetPreprocessor (func)
	Preprocessor = func
end

-- Does standard setup for screen sections
-- data: Section data
-- use_res: If true, use the resolution size
-- Returns: Lookup set in the current language
-----------------------------------------------
function SetupScreen (data, use_res)
	local vw, vh = (use_res and GetRes or GetScreenSize)()

	-- Do a full-context frame for the pane.
	AttachToRoot(data.pane, 0, 0, vw, vh, true)

	-- Put any requests in the corners.
	local lookup = GetLookup_(data)

	for _, name in APairs("exit", "go") do
		local string = data[name]

		if string then
			if lookup then
				string:SetString(lookup[name])
			end

			local w, h = string:GetSize()

			data.pane:Attach(string, name == "exit" and vw - (w + 50) or 50, vh - (h + 50))
		end
	end

	return lookup
end

-- Unblocks the section
-- data: Section data
------------------------
function Unblock (data)
	data.blocked = false
end

-- Cache some routines.
CleanupEventStreams_ = CleanupEventStreams
Closer_ = Closer
GetEventStream_ = GetEventStream
GetLookup_ = GetLookup
SetLookupTable_ = SetLookupTable