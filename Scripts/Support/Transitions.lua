-- See TacoShell Copyright Notice in main folder of distribution

----------------------------
-- Standard library imports
----------------------------
local assert = assert
local ipairs = ipairs
local max = math.max
local min = math.min
local remove = table.remove
local unpack =unpack

-----------
-- Imports
-----------
local APairs = iterators.APairs
local AttachToRoot = widgetops.AttachToRoot
local ClearAndRecache = varops.ClearAndRecache
local CollectArgsInto = varops.CollectArgsInto
local GetEventStream = section.GetEventStream
local GetFields = table_ex.GetFields
local GetRes = gfx.GetRes
local GetScreenSize = game.GetScreenSize
local IsType = class.IsType
local New = class.New
local NoOp = funcops.NoOp
local WithInterpolator = tasks.WithInterpolator
local ActionMap = contexts.ActionMap
local SetLocalRect = widgetops.SetLocalRect
local angle=0.1
local gfx = gfx
local math=math
local kb=0
local dummy




-- Export the transitions namespace.
module "transitions"

local function GetScreenCenter()
	local w,h = GetScreenSize()
	return w/2 , h/2		
end


local function GetResCenter()
	local w,h = GetRes()
	return w/2 , h/2		
end

-- Attachment --
do
	local Cache = {}

	-- ...: Widgets to add
	-- Returns: Batch
	------------------------
	local function MakeBatch (...)
		local args = remove(Cache) or {}

		for _, widget in APairs(...) do
			assert(IsType(widget, "Widget"), "Batch elements must be widgets")

			args[#args + 1] = widget
		end

		assert(#args > 0, "Empty batch")

		return args
	end

	-- Builds a task that attaches widgets to a layer
	-- layer: Layer handle
	-- ...: Widgets to attach
	-- Returns: Task
	--------------------------------------------------
	function Attacher (layer, ...)
		assert(IsType(layer, "Widget"), "Non-widget layer")

		local args = MakeBatch(...)

		return function()
			for _, widget in ipairs(args) do
				layer:Attach(widget)
			end

			ClearAndRecache(Cache, args)
		end
	end

	-- Builds a task that detaches widgets
	-- ...: Widgets to detach
	-- Returns: Task
	---------------------------------------
	function Detacher (...)
		local args = MakeBatch(...)

		return function()
			for _, widget in ipairs(args) do
				widget:Detach()
			end

			ClearAndRecache(Cache, args)
		end
	end
end
-- Builds an interpolator task
-- func: Interpolation routine
-- duration: Transition duration
-- options: Options set
-- quit_main: Transition-specific quit logic
-- Returns: Task function
---------------------------------------------
local function InterpolatorTask (func, duration, options, quit_main)
	local interp, center, mode, prep, quit = New("Interpolator", func, duration)

	if options then
		center, mode, prep, quit = options.center, options.mode, options.prep, options.quit

		interp:SetMap(options.map)
	end

	if center == "res" then
		center = GetResCenter
	end

	-- Configure the interpolator and bind a task.
	interp:SetContext(center or GetScreenCenter)
	interp:Start(mode or "once")

	return WithInterpolator(interp, prep, quit_main and function(arg)
		quit_main();

		(quit or NoOp)(arg)
	end or quit)
end

do
	local Cache = {}

    -- Default interpolation function
    -- cur: Current coordinate
    -- delta: Coordinate delta
    -- t: Current time
    -- Returns: Interpolated coordinate
    ------------------------------------
    local function Linear (cur, delta, t)
        return cur + delta * t
    end
    
    
	function Shake (cur, delta, t)
		--angle=angle+0.2
		--angle=math.fmod(angle,360)
		local angle = .1 + 150 * t%(2 * math.pi)
		return (cur + delta *t ) + math.sin(angle)*10 --intensity
	end 
	
	function Ease (cur, delta, t)
		local t1= (math.sin(t*math.pi-math.pi*0.5)+1)*0.5 
		return (cur + delta *t1 )
	end    
	
	function Bounce (cur, delta, t)
	    local b,c,d=cur,delta,1 --Use duration instead
	    t=t/d
		if t < (1/2.75) then
			return c*(7.5625*t*t) + b
		elseif t < (2/2.75) then
			t=t-(1.5/2.75)
			return c*(7.5625*(t)*t + .75) + b
		elseif t < (2.5/2.75) then
			t=t-(2.25/2.75)
			return c*(7.5625*(t)*t + .9375) + b
		else
			t=t-(2.625/2.75)
			return c*(7.5625*(t)*t + .984375) + b
		end
	end    

	function ElasticIn (cur, delta, t)
		local b,c,d=cur, delta*2, 2 --Use duration instead. 
		local s
		local a=0.1
		
		if t==0 then 
			return b 
		end
		t=t/(d/2)
		if t==2 then 
			return b+c 
		end
		t= t-1
		p=d*(.3*1.5)
		--
		if a < math.abs(c)  then  
			a=c 
			s= p/4 
		else 
			s = p/(2*math.pi) * math.asin(c/a)
		end 
		--
		if (t < 1) then 
			return -.5*(a*math.pow(2,10*(t)) * math.sin( (t*d-s)*(2*math.pi)/p )) + b
		end
		return a*math.pow(2,-10*(t)) * math.sin( (t*d-s)*(2*math.pi)/p )*.5 + c + b;
		--return (cur + delta *t )
	end 		
	   --
	function Elastic (cur, delta, t)
		local b,c,d=cur, delta, 1 --Use duration instead. 
		local s
		local a=0.1
		
		if t==0 then 
			return b 
		end
		t=t/(d)
		if t==1 then 
			return b+c 
		end
		--t= t-1
		p=d*(.3)
		--
		if a < math.abs(c)  then  
			a=c 
			s= p/4 
		else 
			s = p/(2*math.pi) * math.asin(c/a)
		end 
		--
		--if (t < 1) then 
		--	return -.5*(a*math.pow(2,10*(t)) * math.sin( (t*d-s)*(2*math.pi)/p )) + b
		--end
		return a*math.pow(2,-10*(t)) * math.sin( (t*d-s)*(2*math.pi)/p ) + c + b;
		--return (cur + delta *t )
	end 		


	--if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
	--if (a < Math.abs(c)) { a=c; var s=p/4; }
	--else var s = p/(2*Math.PI) * Math.asin (c/a);
	--return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
--
	function KenBurns(cur,delta, t)
		local rd=-50
		if (delta<0) then rd=50 end
		return cur+delta
	end

	-- Gets values used for widget motion
	-- widget: Widget handle
	-- desc: Motion descriptor
	-- ddx, ddy: Default motion deltas
	-- Returns: Initial coordinates; motion deltas; position functions
	-------------------------------------------------------------------
	local function GetMoveValues (widget, desc, ddx, ddy)
	   local x1, y1, x2, y2, dx, dy, xfunc, yfunc

		if desc then
			x1, y1, x2, y2, dx, dy, xfunc, yfunc = GetFields(desc, "x1", "y1", "x2", "y2", "dx", "dy", "xfunc", "yfunc")
		end

        x1, y1 = x1 or widget:GetX(), y1 or widget:GetY()

        return x1, y1, x2 and x2 - x1 or dx or ddx, y2 and y2 - y1 or dy or ddy, xfunc or Linear, yfunc or Linear
	end

	-- Gets values used for widget motion
	-- widget: Widget handle
	-- desc: Motion descriptor
	-- ddx, ddy: Default motion deltas
	-- Returns: Initial coordinates; motion deltas; position functions
	-------------------------------------------------------------------
	local function GetMoveValues (widget, desc, ddx, ddy)
	   local x1, y1, x2, y2, dx, dy, xfunc, yfunc

		if desc then
			x1, y1, x2, y2, dx, dy, xfunc, yfunc = GetFields(desc, "x1", "y1", "x2", "y2", "dx", "dy", "xfunc", "yfunc")
		end

        x1, y1 = x1 or widget:GetX(), y1 or widget:GetY()

        return x1, y1, x2 and x2 - x1 or dx or ddx, y2 and y2 - y1 or dy or ddy, xfunc or Linear, yfunc or Linear
	end

	-- Builds a task to move a widget
	-- widget: Widget handle
	-- duration: Transition duration
	-- how: Move options
	-- options: Transition options
	-- Returns: Task
	----------------------------------
    function MoveWidget (widget, duration, how, options)
		local x, y, dx, dy, xfunc, yfunc = GetMoveValues(widget, how, 0, 0)

        -- Supply an iterator to place widgets at their current positions.
        return InterpolatorTask(function(t)
--			assert(widget:IsAttached(), "Attempt to move unattached widget")

            widget:SetX(xfunc(x, dx, t))
            widget:SetY(yfunc(y, dy, t))
        end, duration, options)
    end

    -- Builds a task to move a group of widgets
    -- widgets: Widget table
    -- duration: Transition duration
    -- how: Move options
    -- options: Transition options
    -- Returns: Task
    --------------------------------------------
    function MoveWidgetBatch (widgets, duration, how, options)
        -- Build up a batch of motion tracking information.
        local motion, ddx, ddy = remove(Cache) or {}, how.dx or 0, how.dy or 0

        for i, widget in ipairs(widgets) do
            motion[i] = remove(Cache) or {}

            CollectArgsInto(motion[i], widget, GetMoveValues(widget, how[i], ddx, ddy))
        end

        -- Supply an iterator to place widgets at their current positions.
        return InterpolatorTask(function(t)
            for _, item in ipairs(motion) do
                local widget, x, y, dx, dy, xfunc, yfunc = unpack(item)

--				assert(widget:IsAttached(), "Attempt to move unattached widget")

                widget:SetX(xfunc(x, dx, t))
                widget:SetY(yfunc(y, dy, t))
            end
        end, duration, options, function()
        	for _, item in ipairs(motion) do
        		ClearAndRecache(Cache, item)
        	end

			ClearAndRecache(Cache, motion)
		end)
    end
    
    function MoveAndScaleWidget (widget, duration, how, options)
        -- Build up a batch of motion tracking information.
        local motion, ddx, ddy, dxfunc, dyfunc = {}, how.dx or 0, how.dy or 0, Linear, Linear

    	local desc, x1, y1, x2, y2, dx, dy, xfunc, yfunc, w1, h1, w2, h2 = how

        if desc then
            x1, y1, x2, y2, dx, dy, xfunc, yfunc, w1,h1,w2,h2 = GetFields(desc, "x1", "y1", "x2", "y2", "dx", "dy", "xfunc", "yfunc", "w1","h1","w2","h2")
        end

        x1, y1 = x1 or widget:GetX(), y1 or widget:GetY()
        --x1, y1 = x1 or widget:GetX(), y1 or widget:GetY()

        motion = { widget, x1, y1, x2 and x2 - x1 or dx or ddx, y2 and y2 - y1 or dy or ddy, xfunc or dxfunc, yfunc or dyfunc, w1, h1, w2-w1, h2-h1 }

        -- Supply an iterator to place widgets at their current positions.
        return InterpolatorTask(function(t)
            local widget, x, y, dx, dy, xfunc, yfunc, w,h,dw,dh = unpack(motion)
			
           -- widget:SetX(xfunc(x, dx, t))
            --widget:SetY(yfunc(y, dy, t))
            SetLocalRect(widget, xfunc(x, dx, t), xfunc(y, dy, t), xfunc(w,dw,t),xfunc(h,dh,t))
        end, duration, options)
    end
        
    function PlaceWidget (widget, x, y) 
		return function()
			widget:SetX(x)
			widget:SetY(y)
		end
    end
end


-----------------
-- View slide-in
-----------------
do
	local Update = {
		["h+"] = function(t, pane, vw)
			pane:SetViewOrigin(vw * (1 - t), 0)
		end,
		["h-"] = function(t, pane, vw)
			pane:SetViewOrigin(vw * (t - 1), 0)
		end,
		["v+"] = function(t, pane, _, vh)
			pane:SetViewOrigin(0, vh * (t - 1))
		end,
		["v-"] = function(t, pane, _, vh)
			pane:SetViewOrigin(0, vh * (1 - t))
		end
	}

	-- Builds a view slide-in transition task
	-- pane: Dialog pane handle
	-- duration: Transition duration
	-- how: Slide-in type
	-- options: Transition options
	-- Returns: Task
	------------------------------------------
	function SlideViewIn (pane, duration, how, options)
		return InterpolatorTask(function(t, _, _, size)
			Update[how](t, pane, size())
		end, duration, options)
	end
end



-- Builds a dialog resize transition task
-- pane: Dialog pane handle
-- duration: Transition duration
-- initialWidth, initialHeight: Initial dimensions
-- finalWidth, finalHeight: Final dimensions
-- how: Expansion type
-- options: Transition options
-- Returns: Task
------------------------------------------
function ResizeDialog (pane, duration, initialWidth, initialHeight, finalWidth, finalHeight, how, options, quit)
	return InterpolatorTask(function(t, _, _, center)
		-- Given special requests, transform the width and height expansion times.
		local wt, ht, vw, vh = t, t, center()

		if how == "wh" then
			wt, ht = min(2 * t, 1), max(2 * (t - .5), 0)
		elseif how == "hw" then
			wt, ht = max(2 * (t - .5), 0), min(2 * t, 1)
		end

		-- Apply the current positions and dimensions.
		local w, h = initialWidth  + (finalWidth - initialWidth) * wt, 
					 initialHeight + (finalHeight - initialHeight) * ht

		AttachToRoot(pane, vw - w / 2, vh - h / 2, w, h, true)
	end, duration, options, quit)
end


-----------------
-- Popup Window
-----------------
function PopupMessage (icon, duration, initialWidth, initialHeight, finalWidth, finalHeight, method, options)
	return InterpolatorTask(
		function(t, _, _, size)
			-- Given special requests, transform the width and height expansion times.
			local wt, ht, vw, vh = t, t, size()




			if method == "Bounce" then

				wt = wt + 0.20
				ht = ht + 0.20								

				if wt > 1.2 then
					wt = wt - 0.2
					ht = ht - 0.2								
					
				end

			
			else 

			end


			-- Apply the current positions and dimensions.
			local w, h = initialWidth  + (finalWidth - initialWidth) * wt, 
						 initialHeight + (finalHeight - initialHeight) * ht


			AttachToRoot(icon, (vw - w)/2, (vh - h)/2, w, h, true)
		end,
	 duration, options)
end

-----------------
-- Rotate Fade --
-----------------
do
	local Faded = New("Color")

	function ScaleFade (icon, duration, initialWidth, initialHeight, finalWidth, finalHeight, bounce, fadeOut, options)
		local color, color1, color2 = icon:GetColor("main") or New("Color"), Faded, "white"
		
		if mode == "fadeout" then
			color1, color2 = color2, color1
		end
		
		icon:SetColor("main", color)
	
		return InterpolatorTask(
			function(t, _, _, size)
				-- Given special requests, transform the width and height expansion times.
				local wt, ht, vw, vh = t, t, size()
				
				if fadeOut == "nofade" then
					color:SetRGBA(255,255,255,255)
				else
						
					color:Lerp(color1, color2, t)
				end
				icon:SetColor("main", color)
	
				--if fadeOut== "fadeout" then
				--	icon:SetColor("main", New("Color", 255, 255, 255, 255 - 255 * wt))
				--elseif fadeOut == "fadein" then
				--	icon:SetColor("main", New("Color", 255, 255, 255, (255 * wt)))
				--else
					
				--end ] ]
	
				if bounce == "bounce" then
	
					wt = wt + 0.20
					ht = ht + 0.20								
	
					if wt > 1.2 then
						wt = wt - 0.2
						ht = ht - 0.2								
						
					end
				end
	
	
				-- Apply the current positions and dimensions.
				local w, h = initialWidth  + (finalWidth - initialWidth) * wt, 
							 initialHeight + (finalHeight - initialHeight) * ht
	
	
				AttachToRoot(icon, (vw - (w/2)), (vh - (h/2)), w, h, true)
			end,
		 duration, options)
	end


	function FadeWidget(widget, duration, mode)
		local color, color1, color2 = widget:GetColor("main") or New("Color"), Faded, "white"

		if mode == "fadeout" then
			color1, color2 = color2, color1
		end

		widget:SetColor("main", color)

		return InterpolatorTask(
			function(t, _, _, size)
				--local color = widget:GetColor("main") or New("Color")

				--Given special requests, transform the width and height expansion times.
				--if mode == "fadeout" then
				--	messagef("%f",255 - 255 * t)
				--	color.a = 255 - 255 * t^3
				--else
				--	messagef("%f",255 * t)
				--	color.a = 255 * t^3
				--end
				--]]
				widget:SetColor("main", color)
				color:Lerp(color1, color2, t)
			end,
		 duration, options)
	end
end

function WidgetWait( widget, duration )
	return InterpolatorTask( function ( t ) end, duration )
end

function SlideDissolve(widget, duration, how, options)
        -- Build up a batch of motion tracking information.
		local dx = how.dx
		local x = 0
		local sy,sx
		  sx = widget:GetW()
		  sy = widget:GetH()
--        for i, widget in ipairs(widget) do
--            local desc, x1, y1, x2, y2, dx, dy, xfunc, yfunc = how

  --          if desc then
    --            x1, y1, x2, y2, dx, dy, xfunc, yfunc = GetFields(desc, "x1", "y1", "x2", --"y--2", "dx", "dy", "xfunc", "yfunc")
        --    end

--         local x1, y1 = x1 or widget:GetX(), y1 or widget:GetY()

--            motion = { widget, x1, y1, x2 and x2 - x1 or dx or ddx, y2 and y2 - y1 or dy or ddy, xfunc or dxfunc, yfunc or dyfunc }
--        end
		
        -- Supply an iterator to place widgets at their current positions.
        return InterpolatorTask(function(t)
    --        for _, item in ipairs(motion) do
                --local widget, x, y, dx, dy, xfunc, yfunc = unpack(item)
--				  sx = sx -1
--				  sy = sy -1
				  --x = x+1
--				  widget:SetX(x)
--				  widget:SetW(sx)
--				  widget:SetH(sy)	
  --              widget:SetX(xfunc(x, dx, t))
  --          end
        end, duration, options)

end

--[
--	Widget will move towards an area while scaling back

--]]

function ScaleMove(widget,duration,destination,options)
	return InterpolatorTask(
		function(t, _, _, size)
			-- Given special requests, transform the width and height expansion times.
			local wt, ht, vw, vh = t, t, size()
			local x, y = 0,0



			-- Apply the current positions and dimensions.
			local w, h = destination.w1  + (destination.w2 - destination.w1) * wt, 
						 destination.h1  + (destination.h2 - destination.h1) * ht

			if destination.x1 == nil then
				local w,h = GetScreenSize()
				x,y = w/2-widget:GetW()/2, h/2-widget:GetH()/2
			
			else
				x, y = destination.x1 + (destination.x2 - destination.x1) * wt,
					   destination.y1 + (destination.y2 - destination.y1) * ht
			end			
			if widget:IsAttached() then
				SetLocalRect(widget, x, y, w, h)
			else
				AttachToRoot(widget, x, y, w, h, true)
			end
		end,
	 duration, options)
end

