local drawobjects = {}
-- put all the drawing routines in here


-- HUD elements
local HUD = {}
HUD.font = love.graphics.newFont(20)

-- Fuel indicator elements
HUD.fuel = {x=20, y=50, w=gintScreenWidth - 40, h=50, cornerSize=15}
HUD.fuel.mid = HUD.fuel.x + math.floor(HUD.fuel.w / 2)
HUD.fuel.btm = HUD.fuel.y + HUD.fuel.h
HUD.fuel.text = {img=love.graphics.newText(HUD.font, "FUEL")}
HUD.fuel.text.w, HUD.fuel.text.h = HUD.fuel.text.img:getDimensions()
HUD.fuel.text.x, HUD.fuel.text.y = HUD.fuel.x + 20, HUD.fuel.y + math.floor(HUD.fuel.text.h / 2)

local function DrawFuelIndicator()
-- draws the fuel indicator across the top of the screen
-- credit: Milon
-- refactored by Fox

    -- Fuel indicator
    local grad = garrLanders[1].fuel / garrLanders[1].fueltanksize
    local color = {1, grad, grad}
	love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w * grad, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(0,0.5,1,1)
    love.graphics.draw(HUD.fuel.text.img, HUD.fuel.text.x, HUD.fuel.text.y)
    love.graphics.setColor(1,1,1,1)
    love.graphics.line(HUD.fuel.mid, HUD.fuel.y, HUD.fuel.mid, HUD.fuel.btm) -- center line

end

local function DrawOffscreenIndicator(worldoffset)
-- draws an indicator when the lander flies off the top of the screen

    local lineThickness = love.graphics.getLineWidth()
    love.graphics.setLineWidth(3)
    local indicatorY = 40
    local magnifier = 1.5
    local x, y = garrLanders[1].x - worldoffset, garrImages[5]:getHeight() + indicatorY
    if garrLanders[1].y < 0 then
        love.graphics.draw(garrImages[5], x, y, math.rad(garrLanders[1].angle), magnifier, magnifier, garrImages[5]:getWidth()/2, garrImages[5]:getHeight()/2)
        love.graphics.circle("line", x, y, garrImages[5]:getHeight() + 5)
        love.graphics.polygon("fill", x, garrLanders[1].y, x - 10, indicatorY - 5, x + 10, indicatorY - 5)
        if garrLanders[1].engineOn then
            love.graphics.draw(garrLanders[1].imgEngine, x, y, math.rad(garrLanders[1].angle), magnifier, magnifier, garrLanders[1].imgEngine:getWidth()/2, garrLanders[1].imgEngine:getHeight()/2)
        end
    end
    love.graphics.setLineWidth(lineThickness) -- restore line thickness

end

function HUD.draw(worldoffset)
    
	DrawFuelIndicator()
    
    -- offscreen indicator
	DrawOffscreenIndicator(worldoffset)
	
end

local function DrawSurface(worldoffset)
-- draws the terrain as a bunch of lines that are 1 pixel in length	

	love.graphics.setColor(1,1,1,1)
	-- ensure we have enough terrain
	if (worldoffset + gintScreenWidth) > #garrGround then
		fun.GetMoreTerrain(gintScreenWidth * 2)
	end
	
	for i = 1, #garrGround - 1 do
		if i < worldoffset - gintScreenWidth or i > worldoffset + gintScreenWidth then
			-- don't draw. Do nothing
		else
			love.graphics.line(i - worldoffset, garrGround[i], i + 1 - worldoffset, garrGround[i+1])
			-- draw a vertical line straight down to reflect solid terra firma
			love.graphics.setColor(115/255,115/255,115/255,1)
			love.graphics.line(i - worldoffset, garrGround[i],i - worldoffset, gintScreenHeight)
			love.graphics.setColor(1,1,1,1)
		end
	end
end

local function DrawObjects(worldoffset)
-- query garrObjects table and draw them in the world

	
	for k,v in pairs(garrObjects) do
	
		local xvalue = v.x
		local objectvalue = v.objecttype
		
		-- check if on-screen
		if xvalue < worldoffset - gintScreenWidth or xvalue > worldoffset + gintScreenWidth then
			-- don't draw. Do nothing
		else
			-- set colour based on ACTIVE status
			if v.active then
				love.graphics.setColor(1,1,1,1)
			else
				love.graphics.setColor(1,1,1,0.5)
			end
			
			-- draw image based on object type
			if objectvalue == 1 then
				love.graphics.draw(garrImages[1], xvalue - worldoffset, garrGround[xvalue] - garrImages[1]:getHeight())
			end
			if objectvalue == 2 then
				if garrGround[xvalue - worldoffset] ~= nil then
					love.graphics.draw(garrImages[2], xvalue - worldoffset, garrGround[xvalue] - garrImages[2]:getHeight())
				end
			end
		end
		
	end
end

local function DrawDebug()

	love.graphics.print("Mass = " .. cf.round(fun.GetLanderMass(),2), 5, 15)
	love.graphics.print("Fuel = " .. cf.round(garrLanders[1].fuel,2), 5, 30)
	love.graphics.print("Mass ratio: " .. cf.round(garrMassRatio,2), 125,15)

end

local function DrawLander(worldoffset)

	-- draw the lander and flame
	for k,v in ipairs(garrLanders) do
		
		love.graphics.draw(garrImages[5], v.x - worldoffset,v.y, math.rad(v.angle), 1.5, 1.5, garrImages[5]:getWidth()/2, garrImages[5]:getHeight()/2)

		if v.engineOn == true then
			love.graphics.draw(garrImages[4], v.x - worldoffset, v.y, math.rad(v.angle), 1.5, 1.5, garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
			v.engineOn = false
		end			
	
	end
end

local function DrawWallPaper()
	love.graphics.setColor(1,1,1,0.25)
	love.graphics.draw(garrImages[3],0,0)
end



function drawobjects.DrawWorld()
-- draw the spaceship and flame and other bits

	-- adjust the world so that the lander is centred and the terrain moves under it
	local worldoffset = cf.round(garrLanders[1].x - gintOriginX,0)	-- how many pixels we have moved away from the initial spawn point (X axis)

	
	DrawWallPaper()
	
	-- draw the surface
	DrawSurface(worldoffset)
	
    -- draw world objects
	DrawObjects(worldoffset)
	
    -- draw HUD elements
    HUD.draw(worldoffset)
	
	-- draw the lander
    DrawLander(worldoffset)
    
    
	if gbolDebug then
		DrawDebug()
	end	

end

return drawobjects
