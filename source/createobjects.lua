
local createobjects = {}


function createobjects.CreateLander()
-- create a lander and return it to the calling sub

	local Lander = {}
    Lander.x = gintOriginX
    Lander.y = 500
	Lander.y = garrGround[Lander.x] - 8
	Lander.angle = 270		-- 270 = up
	Lander.vx = 0
	Lander.vy = 0
	Lander.engineOn = false
	Lander.landed = false
	Lander.mass = {}
	table.insert(Lander.mass, 100)	-- base mass of lander

	Lander.fueltanksize = 100		-- volume in arbitrary units
	Lander.fuel = Lander.fueltanksize	-- start with a full tank
	table.insert(Lander.mass, 20)	-- this is the mass of an empty tank
	
	
	Lander.imgEngine = love.graphics.newImage("/Assets/engine.png")
	Lander.img = love.graphics.newImage("/Assets/ship.png")
	
	Lander.bolGameOver = false
	
	return Lander


end

return createobjects