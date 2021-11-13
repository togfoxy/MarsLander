
-- ~~~~~~~~~~
-- base.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Bases to land on for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Base = {}



-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

local landingLights     = Assets.getImageSet("landingLights")
landingLights.animation = Assets.newAnimation("landingLights", landingLights.image, 64, 8, 1, '1-4', 0.5)

local baseOn    = Assets.getImageSet("fuelbaseOn")
local baseOff   = Assets.getImageSet("fuelbaseOff")



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Base.init()
end


-- TODO: Move base related functions from lander.lua
function Base.update(dt)
    landingLights.animation:update(dt)
end



function Base.draw()
    for k,v in pairs(OBJECTS) do
        local xvalue = v.x
        local objectvalue = v.objecttype

        -- check if on-screen
        if (xvalue > WORLD_OFFSET - SCREEN_WIDTH) and (xvalue < WORLD_OFFSET + SCREEN_WIDTH) then
            -- draw image based on object type
            if objectvalue == Enum.basetypeFuel then
                local baseX = xvalue - WORLD_OFFSET
                local baseY = GROUND[xvalue] - baseOn.height

                -- draw gas tank
                -- draw the 'fuel level' before drawing the tank over it
                -- draw the whole gauge red then overlay the right amount of green
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle("fill", baseX + 40, baseY + 84, 5, 40)

                -- draw green gauge
                -- pixel art gauge is 36 pixels high
                local gaugeheight = v.totalFuel / Enum.baseMaxFuel * 36
                local gaugebottom = 120
                love.graphics.setColor(0, 1, 0, 1)
                love.graphics.rectangle("fill", baseX + 40, baseY + gaugebottom - gaugeheight, 5, gaugeheight)

                -- set colour based on ACTIVE status
                love.graphics.setColor(1, 1, 1, 1)
                if v.active then
                    love.graphics.draw(baseOn.image, baseX, baseY)
                else
                    love.graphics.draw(baseOff.image, baseX, baseY)
                end

                -- draw landing lights
                -- the image is white so the colour can be controlled here at runtime
                if v.paid then
                    love.graphics.setColor(1, 0, 0, 1)
                else
                    love.graphics.setColor(0, 1, 0, 1)
                end
                local x = baseX + baseOn.width - 10
                local y = baseY + baseOn.height
                landingLights.animation:draw(x, y)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end
end


return Base