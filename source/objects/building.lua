
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
    for k,obj in pairs(garrObjects) do
        local objXValue = obj.x
        local objectvalue = obj.objecttype

        -- check if on-screen
 		if (objXValue > gintWorldOffset - gintScreenWidth) and objXValue < (gintWorldOffset + gintScreenWidth) then
            -- Draw building type 1
			if objectvalue == enum.basetypeBuilding1 then
				-- getting an odd 'nil' error probably means that some x value has not been rounded to zero places.

				local x = objXValue - gintWorldOffset
				local y = garrGround[objXValue] - building1.height
				love.graphics.draw(building1.image, x, y)
			end
			-- Draw building type 2
			if objectvalue == enum.basetypeBuilding2 then
				-- getting an odd 'nil' error probably means that some x value has not been rounded to zero places.
				local x = objXValue - gintWorldOffset

				local y = garrGround[objXValue] - building2.height
				love.graphics.draw(building2.image, x, y)
			end
        end
    end
end


return Building