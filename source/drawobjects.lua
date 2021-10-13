local drawobjects = {}
-- put all the drawing routines in here

local function DrawSurface()
	--love.graphics.line(0,600, gintScreenWidth,600)	
	
	for i = 1, gintScreenWidth do
		love.graphics.points(i,garrGround[i])
	end
end

local function DrawObjects()
-- query garrObjects table and draw them in the world

	for k,_ in pairs(garrObjects) do
		
		local xvalue = k
		local objectvalue = garrObjects[xvalue]
		
		if objectvalue == 1 then
			love.graphics.draw(garrImages[1], xvalue, garrGround[xvalue] - garrImages[1]:getHeight())
		end
	end
end

function drawobjects.DrawWorld()
-- draw the spaceship and flame and other bits

	love.graphics.setColor(1,1,1,1)
	for k,v in ipairs(garrLanders) do
		
		love.graphics.draw(v.img, v.x,v.y, math.rad(v.angle), 1, 1, v.img:getWidth()/2, v.img:getHeight()/2)

		if v.engineOn == true then
			love.graphics.draw(v.imgEngine, v.x, v.y, math.rad(v.angle), 1, 1, v.imgEngine:getWidth()/2, v.imgEngine:getHeight()/2)
			v.engineOn = false
		end		
	
	end
	
	-- draw the surface
	DrawSurface()
	
	DrawObjects()

end

return drawobjects