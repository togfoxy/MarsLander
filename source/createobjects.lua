
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
	Lander.landed = false			-- true = on the ground
	Lander.airborne = false			-- true = on the ground FOR THE FIRST TIME
	Lander.wealth = 0
	Lander.bolGameOver = false
	
	
	-- mass	
	Lander.mass = {}
	table.insert(Lander.mass, 100)	-- base mass of lander

	Lander.fueltanksize = 25		-- volume in arbitrary units
	Lander.fuel = Lander.fueltanksize	-- start with a full tank
	table.insert(Lander.mass, 20)	-- this is the mass of an empty tank
	table.insert(Lander.mass, 0)	-- this is the mass of the rangefinder (not yet purchased)
	
	-- modules
	Lander.modules = {}		-- this will be strings/names of modules
	
	return Lander


end

function createobjects.CreateObject(intType, intXValue)
-- creates a base and appends it to the garrObjects table

	local mybase = {}
	mybase.x = intXValue			-- where on the map this object is positioned.
	mybase.objecttype = intType		-- 2 = a fuel base
	mybase.fuelqty = 0
	mybase.active = true
	mybase.paid = false				-- set true when lander lands and pays player. Ensures bases only pay once
	
	if intType == 2 then
		mybase.fuelqty = 15
		
		-- smooth the terrain around the base
		for i = 1, 125 do
			local myindex = intXValue + i
			garrGround[myindex] = garrGround[intXValue]
		end		
	end

	table.insert(garrObjects, mybase)

end


return createobjects