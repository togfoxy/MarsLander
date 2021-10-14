local drawobjects = {}
-- put all the drawing routines in here

local function DrawSurface(worldoffset)
-- draws the terrain as a bunch of lines that are 1 pixel in length	

	love.graphics.setColor(1,1,1,1)
	-- ensure we have enough terrain
	if (worldoffset + gintScreenWidth) > #garrGround then
		fun.GetMoreTerrain()
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

end

local function DrawLander(worldoffset)

	-- draw the lander and flame
	love.graphics.setColor(1,1,1,1)
	for k,v in ipairs(garrLanders) do
		
		love.graphics.draw(v.img, v.x - worldoffset,v.y, math.rad(v.angle), 1, 1, v.img:getWidth()/2, v.img:getHeight()/2)

		if v.engineOn == true then
			love.graphics.draw(v.imgEngine, v.x - worldoffset, v.y, math.rad(v.angle), 1, 1, v.imgEngine:getWidth()/2, v.imgEngine:getHeight()/2)
			v.engineOn = false
		end		
	
	end

end

function drawobjects.DrawWorld()
-- draw the spaceship and flame and other bits

	-- adjust the world so that the lander is centred and the terrain moves under it
	local worldoffset = cf.round(garrLanders[1].x - gintOriginX,0)	-- how many pixels we have moved away from the initial spawn point (X axis)

	-- draw the surface
	DrawSurface(worldoffset)
	
	DrawObjects(worldoffset)
	
	DrawLander(worldoffset)
	
	if gbolDebug then
		DrawDebug()
	end	

end

return drawobjects