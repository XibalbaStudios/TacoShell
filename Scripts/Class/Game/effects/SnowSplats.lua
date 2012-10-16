-- Imports --
local _G = _G
local GetScreenSize = game.GetScreenSize
local GetTimeDifference = engine.GetTimeDifference
local New = class.New
local Rand = math_ex.Rand
local RBy = math_ex.RBy

-- Splat picture properties --
local Color = New("Color", "white")
local Props = { color = Color }
local Tex = graphicshelpers.Texture("Textures/hud/snowball_smashed2.png")

-- SnowSplats class definition --
class.Define("SnowSplats", function(SnowSplats)
    -- Adds a new random splat
    ---------------------------
    function SnowSplats:AddSplat ()
		local splat = self.splats:PopExtra() or {}
        local w, h = GetScreenSize()

		splat.age = 0
		splat.drip = Rand(50, 90)
		splat.grow = Rand(.1, .25)
		splat.stay = Rand(1.2, 1.8)
		splat.fade = Rand(.9, 1.4)
		splat.x = RBy(w / 2, w / 4)
		splat.y = RBy(h / 2, h / 4)

		self.splats:Add(splat)
    end

	-- Returns: True, to persist in stream
	---------------------------------------
	function SnowSplats:__call ()
        local splats = self.splats
		local diff = GetTimeDifference()

        for i, splat in splats:IPairs() do
            local age = splat.age
            local grow_until = splat.grow
            local stay_until = grow_until + splat.stay
            local fade_until = stay_until + splat.fade

            if age < fade_until then
                if age < grow_until then
                    splat.state = "growing"
					splat.t = age / grow_until
                elseif age < stay_until then
                    splat.state = "steady"
					splat.t = (age - grow_until) / (stay_until - grow_until)
                else
                    splat.state = "fading"
					splat.t = (age - stay_until) / (fade_until - stay_until)
                end

                splat.age = age + diff

			else
				splats:Remove(i)
            end
        end

		return true
	end

    -- Returns: Widget handle
    --------------------------
    function SnowSplats:GetAttachWidget ()
        return self.attach
    end
end, 

-- Constructor
---------------
function(S)
    S.splats = New("OrderlessArray")

	-- Add an attachment widget to display the splats.
	S.attach = _G.ui.Widget("render", function(A, x, y, w, h)
	    local tw, th = Tex:GetWidth(), Tex:GetHeight()

        for _, splat in S.splats:IPairs() do
            local state = splat.state
			local splat_y = splat.y
			local t = splat.t or 0
			local scale = 1

            if state == "steady" then
                Color.a = 255
            elseif state == "fading" then
                Color.a = 255 * (1 - t)

				splat_y = splat_y + splat.drip * t
            else
                Color.a = 255

				scale = .5 * (1 + t)
            end

            local sw, sh = scale * tw * .75, scale * th * .75

            Tex(x + splat.x - sw / 2, y + splat_y - sh / 2, sw, sh, Props)
        end
	end)

	S.attach:Allow("test", false)
end)