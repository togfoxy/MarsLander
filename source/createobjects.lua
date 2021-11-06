local createobjects = {}


function createobjects.CreateObject(intType, intXValue)
-- creates a base and appends it to the garrObjects table

	local mybase = {}
	mybase.x = intXValue			-- where on the map this object is positioned.
	mybase.objecttype = intType		-- 2 = a fuel base
	mybase.totalFuel = 0
	mybase.active = true
	mybase.paid = false				-- set true when lander lands and pays player. Ensures bases only pay once

	if intType == enum.basetypeFuel then
		mybase.totalFuel = enum.baseMaxFuel

		-- smooth the terrain around the base
		for i = 1, 125 do
			local myindex = intXValue + i
			garrGround[myindex] = garrGround[intXValue]
		end
	end
	if intType == enum.basetypeBuilding1 then
		-- smooth the terrain around the base
		for i = intXValue - 25, intXValue + 75 do
			garrGround[i] = garrGround[intXValue]
		end
	end
	if intType == enum.basetypeBuilding2 then
		-- smooth the terrain around the base
		for i = intXValue - 25, intXValue + 75 do
			garrGround[i] = garrGround[intXValue]
		end
	end

	table.insert(garrObjects, mybase)

end

return createobjects
