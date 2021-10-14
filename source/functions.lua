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

function functions.GetMoreTerrain()
-- determines the next bit of terrain and adds that to the terrain table

	local groundtablesize = #garrGround

	for i = groundtablesize + 1, groundtablesize + 2000 do
	
		local newgroundaltitude = garrGround[i-1] + love.math.random (-5,5)
		
		if newgroundaltitude > (gintScreenHeight * 0.90) then newgroundaltitude = (gintScreenHeight * 0.90) end
		if newgroundaltitude < (gintScreenHeight * 0.65) then newgroundaltitude = (gintScreenHeight * 0.65) end
	
		table.insert(garrGround, newgroundaltitude)
	end
	
	-- reapply bases and smoothing
	for i = groundtablesize + 1, groundtablesize + 2000 do
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

function functions.CreateBase(intType, intXValue)

	garrObjects[intXValue] = intType
	
	-- smooth the terrain around the base
	for i = 1, 125 do
		garrGround[intXValue + i] = garrGround[intXValue]
	end

end


return functions