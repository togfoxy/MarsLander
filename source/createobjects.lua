
local createobjects = {}


function createobjects.CreateLander()
-- create a lander and return it to the calling sub

	local Lander = {}
    Lander.x = 150
    Lander.y = 500
	Lander.angle = 270		-- 270 = up
	Lander.vx = 0
	Lander.vy = 0
	-- Lander.speed = 1
	Lander.engineOn = false
	Lander.landed = false
	Lander.imgEngine = love.graphics.newImage("/Assets/engine.png")
	Lander.img = love.graphics.newImage("/Assets/ship.png")
	
	Lander.bolGameOver = false
	
	return Lander


end

return createobjects