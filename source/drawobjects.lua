local drawobjects = {}
-- put all the drawing routines in here

local function DrawSurface()
	--love.graphics.line(0,600, gintScreenWidth,600)	
	
	for i = 1, gintScreenWidth do
		love.graphics.points(i,garrGround[i])
	end
end

function drawobjects.DrawWorld()

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

end

return drawobjects