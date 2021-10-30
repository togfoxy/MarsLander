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


function functions.SaveGameSettings()
-- save game settings so they can be autoloaded next session
	local savefile
	local serialisedString
	local success, message
	local savedir = love.filesystem.getSource()
	
    savefile = savedir .. "/" .. "settings.dat"
    serialisedString = bitser.dumps(garrGameSettings)
    success, message = nativefs.write(savefile, serialisedString )
end


function functions.LoadGameSettings()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )
    
    local savefile, contents

    savefile = savedir .. "/" .. "settings.dat"
    contents, _ = nativefs.read(savefile) 
	local success
    success, garrGameSettings = pcall(bitser.loads, contents)		--! should do pcall on all the "load" functions
	
	if success == false then
		garrGameSettings = {}
	end
	
	--[[ FIXME:
	-- This is horrible bugfix and needs refactoring. If a player doesn't have
	-- a settings.dat already then all the values in garrGameSettings table are 
	-- nil. This sets some reasonable defaults to stop nil value crashes.
	]]--
	if garrGameSettings.PlayerName == nil then
		garrGameSettings.PlayerName = gstrDefaultPlayerName
	end
	if garrGameSettings.PreviousIP == nil then
		garrGameSettings.PreviousIP = "127.0.0.1"
	end
	if garrGameSettings.PreviousPort == nil then
		garrGameSettings.PreviousPort = "6000"
	end
	if garrGameSettings.FullScreen == nil then
		garrGameSettings.FullScreen = false
	end
end


function functions.SaveGame()
-- uses the globals because too hard to pass params

--! for some reason bitser throws runtime error when serialising true / false values.

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
	
	lovelyToasts.show("Game saved",3, "middle")
    
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


function functions.ResetGame()

	garrGround = {}
	garrObjects = {}

	Terrain.initialize()

	garrLanders = {}
	table.insert(garrLanders, Lander.create())

end

return functions
