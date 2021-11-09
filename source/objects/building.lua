
-- ~~~~~~~~~~~~~
-- building.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Buildings to land on for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Building = {}



-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

local building1 = Assets.getImageSet("building1")
local building2 = Assets.getImageSet("building2")



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Building.init()
end



function Building.update(dt)
end



function Building.draw()
    for k,v in pairs(OBJECTS) do
        local xvalue = v.x
        local objectvalue = v.objecttype

        -- check if on-screen
        if xvalue > WORLD_OFFSET - 100 or xvalue < WORLD_OFFSET + SCREEN_WIDTH then
            -- Draw building type 1
			if objectvalue == enum.basetypeBuilding1 then
				-- getting an odd 'nil' error probably means that some x value has not been rounded to zero places.
				local x = xvalue - WORLD_OFFSET
				local y = GROUND[xvalue] - building1.height
				love.graphics.draw(building1.image, x, y)
			end
			-- Draw building type 2
			if objectvalue == enum.basetypeBuilding2 then
				-- getting an odd 'nil' error probably means that some x value has not been rounded to zero places.
				local x = xvalue - WORLD_OFFSET
				local y = GROUND[xvalue] - building2.height
				love.graphics.draw(building2.image, x, y)
			end
        end
    end
end


return Building