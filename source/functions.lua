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

function functions.LoadGame()
    
    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )
    
    local savefile
    local contents

    savefile = savedir .. "/" .. "landers.dat"
    contents, _ = nativefs.read( savefile) 
    garrLanders = bitser.loads(contents)    

    savefile = savedir .. "/" .. "ground.dat"
    contents, _ = nativefs.read( savefile) 
    garrGround = bitser.loads(contents)   
   
    savefile = savedir .. "/" .. "objects.dat"
    contents, _ = nativefs.read(savefile) 
    garrObjects = bitser.loads(contents)  
    
  
end

function functions.GetDistanceToClosestBase(xvalue, intBaseType)
-- returns two values: the distance to the closest base, and the object/table item for that base
-- if there are no bases (impossible) then the distance value returned will be -1
-- note: if distance is a negative value then the Lander has not yet passed the base

	local closestdistance = 0
	local closestbase = {}
	local absdist
	local dist
	
	for k,v in pairs(garrObjects) do
		if v.objecttype == intBaseType then
			absdist = math.abs(xvalue - (v.x + 85))			-- the + bit is an offset to calculate the landing pad and not the image
			dist = (xvalue - (v.x + 85))						-- same but without the math.abs
			if closestdistance == 0 or absdist <= closestdistance then
				closestdistance = absdist
				closestbase = v
			end
		end
	end
	
	-- now we have the closest base, work out the distance to the landing pad for that base
	local realdist = xvalue - (closestbase.x + 85)			-- the + bit is an offset to calculate the landing pad and not the image

	return  realdist, closestbase

end

function functions.IsOnLandingPad(intBaseType)
-- returns a true / false value

	local mydist, _ = fun.GetDistanceToClosestBase(garrLanders[1].x, intBaseType)
	if mydist >= -80 and mydist <= 40 then
		return true
	else
		return false
	end
end

function functions.InitialiseGround()
-- initialise the ground array to be a flat line
-- add bases to garrObjects

	-- this creates a big flat space at the start of the game
	for i = 0, (gintScreenWidth * 0.90) do
		garrGround[i] = gintScreenHeight * 0.80
	end
	
	fun.GetMoreTerrain(gintScreenWidth * 2)

	-- Place bases
	local basedistance = cf.round(gintScreenWidth * 1.5,0)
	for i = 1, 20 do
		cobjs.CreateObject(enum.basetypeFuel, basedistance)		-- 2 = fuel base
		basedistance = cf.round(basedistance * 1.3,0)
		if basedistance > #garrGround then fun.GetMoreTerrain(basedistance * 2) end
	end
	
	-- place random buildings
	for i = 1, 50 do
		local bolPlacementOkay = false
		local rndnum
		repeat
			rndnum = love.math.random(1, #garrGround)
			local disttobase, _ = fun.GetDistanceToClosestBase(rndnum, enum.basetypeFuel)
			if disttobase <= 250 and disttobase >= -250 then
				-- too close to fuel base
			else
				bolPlacementOkay = true
			end
		until bolPlacementOkay
		cobjs.CreateObject(enum.basetypeBuilding1, rndnum)
	end
	
	-- place random buildings
	for i = 1, 50 do
		local bolPlacementOkay = false
		local rndnum
		repeat
			rndnum = love.math.random(1, #garrGround)
			local disttobase, _ = fun.GetDistanceToClosestBase(rndnum, enum.basetypeFuel)
			if disttobase <= 250 and disttobase >= -250 then
				-- too close to fuel base
			else
				bolPlacementOkay = true
			end
		until bolPlacementOkay
		cobjs.CreateObject(enum.basetypeBuilding2, rndnum)
	end
	
	--! Place spikes
	
end

function functions.ResetGame()

	garrGround = {}
	garrObjects = {}
	fun.InitialiseGround()

	garrLanders = {}
	table.insert(garrLanders, cobjs.CreateLander())
	




end

function functions.LanderHasEfficentThrusters()
-- return TRUE if the lander has fuel efficien thrusters

	for i = 1, #garrLanders[1].modules do
		if garrLanders[1].modules[i] == enum.moduleNamesThrusters then
			return true
		end
	end
	return false
end

function functions.LanderHasLargeTanks()
-- return TRUE if the lander has large tanks

	for i = 1, #garrLanders[1].modules do
		if garrLanders[1].modules[i] == enum.moduleNamesLargeTank then
			return true
		end
	end
	return false
end

function functions.LanderHasRangefinder()
-- return TRUE if the lander has a rangefinder

	for i = 1, #garrLanders[1].modules do
		if garrLanders[1].modules[i] == enum.moduleNamesRangeFinder then
			return true
		end
	end
	return false
end


return functions










