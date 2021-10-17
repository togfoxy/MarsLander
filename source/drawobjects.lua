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
    local grad = garrLanders[1].fuel / 100
    local color = {1, grad, grad}
	love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w * grad, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(0,0.5,1,1)
    love.graphics.draw(HUD.fuel.text.img, HUD.fuel.text.x, HUD.fuel.text.y)
    love.graphics.setColor(1,1,1,1)
    --~ love.graphics.rectangle("line", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    --~ love.graphics.polygon("fill", HUD.fuel.x, HUD.fuel.btm, HUD.fuel.x, HUD.fuel.btm - HUD.fuel.cornerSize, HUD.fuel.x + HUD.fuel.cornerSize, HUD.fuel.btm)  -- bottom left notch
    --~ love.graphics.polygon("fill", HUD.fuel.mid, HUD.fuel.btm - HUD.fuel.cornerSize, HUD.fuel.mid - HUD.fuel.cornerSize, HUD.fuel.btm, HUD.fuel.mid + HUD.fuel.cornerSize, HUD.fuel.btm) -- bottom center notch
    --~ love.graphics.polygon("fill", HUD.fuel.x + HUD.fuel.w, HUD.fuel.btm, HUD.fuel.x + HUD.fuel.w, HUD.fuel.btm - HUD.fuel.cornerSize, HUD.fuel.x + HUD.fuel.w - HUD.fuel.cornerSize, HUD.fuel.btm) -- bottom right notch
    love.graphics.line(HUD.fuel.mid, HUD.fuel.y, HUD.fuel.mid, HUD.fuel.btm) -- center line

end

local function DrawOffscreenIndicator(worldoffset)
-- draws an indicator when the lander flies off the top of the screen

    local lineThickness = love.graphics.getLineWidth()
    love.graphics.setLineWidth(3)
    local indicatorY = 40
    local magnifier = 1.5
    local x, y = garrLanders[1].x - worldoffset, garrLanders[1].img:getHeight() + indicatorY
    if garrLanders[1].y < 0 then
        love.graphics.draw(garrLanders[1].img, x, y, math.rad(garrLanders[1].angle), magnifier, magnifier, garrLanders[1].img:getWidth()/2, garrLanders[1].img:getHeight()/2)
        love.graphics.circle("line", x, y, garrLanders[1].img:getHeight() + 5)
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
		love.graphics.line(i - worldoffset, garrGround[i], i + 1 - worldoffset, garrGround[i+1])
	end
end

local function DrawObjects(worldoffset)
-- query garrObjects table and draw them in the world

	love.graphics.setColor(1,1,1,1)
	for k,_ in pairs(garrObjects) do
		
		local xvalue = k
		local objectvalue = garrObjects[xvalue]
		
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

local function DrawDebug()

	love.graphics.print("Mass = " .. cf.round(fun.GetLanderMass(),2), 5, 15)
	love.graphics.print("Fuel = " .. cf.round(garrLanders[1].fuel,2), 5, 30)
	love.graphics.print("Mass ratio: " .. cf.round(garrMassRatio,2), 100,15)

end


local function DrawLander(worldoffset)

	-- draw the lander and flame
	for k,v in ipairs(garrLanders) do
		
		love.graphics.draw(v.img, v.x - worldoffset,v.y, math.rad(v.angle), 1, 1, v.img:getWidth()/2, v.img:getHeight()/2)

		if v.engineOn == true then
			love.graphics.draw(v.imgEngine, v.x - worldoffset, v.y, math.rad(v.angle), 1, 1, v.imgEngine:getWidth()/2, v.imgEngine:getHeight()/2)
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
