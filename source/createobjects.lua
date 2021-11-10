local createobjects = {}


function createobjects.CreateObject(intType, intXValue)
-- creates a base and appends it to the OBJECTS table

	local mybase = {}
	mybase.x = intXValue			-- where on the map this object is positioned.
	mybase.objecttype = intType		-- 2 = a fuel base
	mybase.totalFuel = 0
	mybase.active = true
	mybase.paid = false				-- set true when lander lands and pays player. Ensures bases only pay once

	if intType == Enum.basetypeFuel then
		mybase.totalFuel = Enum.baseMaxFuel

		-- smooth the terrain around the base
		for i = 1, 125 do
			local myindex = intXValue + i
			GROUND[myindex] = GROUND[intXValue]
		end
	end
	if intType == Enum.basetypeBuilding1 then
		-- smooth the terrain around the base
		for i = intXValue - 25, intXValue + 75 do
			GROUND[i] = GROUND[intXValue]
		end
	end
	if intType == Enum.basetypeBuilding2 then
		-- smooth the terrain around the base
		for i = intXValue - 25, intXValue + 75 do
			GROUND[i] = GROUND[intXValue]
		end
	end

	table.insert(OBJECTS, mybase)

end

return createobjects
