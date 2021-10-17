local functions = {}

function functions.AddScreen(strNewScreen)
	table.insert(garrCurrentScreen, strNewScreen)
end

function functions.RemoveScreen()
	table.remove(garrCurrentScreen)
	if #garrCurrentScreen < 1 then
	
		--if success then
			love.event.quit()       --! this doesn't dothe same as the EXIT button
		--end
	end
end

function functions.SwapScreen(newscreen)
-- swaps screens so that the old screen is removed from the stack
-- this adds the new screen then removes the 2nd last screen.

    fun.AddScreen(newscreen)
    table.remove(garrCurrentScreen, #garrCurrentScreen - 1)
end

function functions.GetMoreTerrain(intAmountToCreate)
-- determines the next bit of terrain and adds that to the terrain table
-- will create intAmountToCreate number of ground items/elements/pixels

	local groundtablesize = #garrGround

	for i = groundtablesize + 1, groundtablesize + intAmountToCreate do
	
		local newgroundaltitude = garrGround[i-1] + love.math.random (-5,5)
		
		if newgroundaltitude > (gintScreenHeight * 0.90) then newgroundaltitude = (gintScreenHeight * 0.90) end
		if newgroundaltitude < (gintScreenHeight * 0.65) then newgroundaltitude = (gintScreenHeight * 0.65) end
	
		table.insert(garrGround, newgroundaltitude)
	end
	
	-- reapply smoothing around the base
	for i = groundtablesize + 1, groundtablesize + intAmountToCreate do
		if garrObjects[i] ~= nil then
			fun.CreateBase(garrObjects[i],i)
		end
	end
end

function functions.GetLanderMass()
-- return the mass of all the bits on the lander

	local result = 0

	-- all the masses are stored in this table so add them up
	for i = 1, #garrLanders[1].mass do
		result = result + garrLanders[1].mass[i]
	end
	
	-- add the mass of the fuel
	result = result + garrLanders[1].fuel
	
	return result
end

function functions.SaveGame()
-- uses the globals because too hard to pass params

--! for some reason bitser throws runtime error when serialising true/false values.

    local savefile
    local contents
    local success, message
    local savedir = love.filesystem.getSource()
    
    savefile = savedir .. "/" .. "landers.dat"
    serialisedString = bitser.dumps(garrLanders)
    success, message = nativefs.write(savefile, serialisedString )
    
    savefile = savedir .. "/" .. "ground.dat"
    serialisedString = bitser.dumps(garrGround)
    success, message = nativefs.write(savefile, serialisedString )
    
    savefile = savedir .. "/" .. "objects.dat"
    serialisedString = bitser.dumps(garrObjects)    -- 
    success, message = nativefs.write(savefile, serialisedString )   
    
end


function functions.GetDistanceToClosestBase(intBaseType)
-- returns two values: the distance to the closest base, and the object/table item for that base
-- if there are no bases (impossible) then the distance value returned will be -1
-- note: if distance is a negative value then the Lander has not yet passed the base

	local closestdistance = -1
	local closestbase = {}
	
	for k,v in pairs(garrObjects) do
		if v.objecttype == intBaseType then
			local dist = math.abs(garrLanders[1].x - v.x)
			if closestdistance < 0 or dist <= closestdistance then
				closestdistance = dist
				closestbase = v
			end
		end
	end

	return garrLanders[1].x - closestbase.x, closestbase

end


return functions