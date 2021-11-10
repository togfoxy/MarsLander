local functions = {}

function functions.AddScreen(strNewScreen)
	table.insert(CURRENT_SCREEN, strNewScreen)
end


function functions.RemoveScreen()
	table.remove(CURRENT_SCREEN)
	if #CURRENT_SCREEN < 1 then

		--if success then
			love.event.quit()       --! this doesn't dothe same as the EXIT button
		--end
	end
end


function functions.CurrentScreenName()
-- returns the current active screen
	return CURRENT_SCREEN[#CURRENT_SCREEN]
end


function functions.SwapScreen(newscreen)
-- swaps screens so that the old screen is removed from the stack
-- this adds the new screen then removes the 2nd last screen.

    Fun.AddScreen(newscreen)
    table.remove(CURRENT_SCREEN, #CURRENT_SCREEN - 1)
end


function functions.SaveGameSettings()
-- save game settings so they can be autoloaded next session
	local savefile
	local serialisedString
	local success, message
	local savedir = love.filesystem.getSource()

    savefile = savedir .. "/" .. "settings.dat"
    serialisedString = Bitser.dumps(GAME_SETTINGS)
    success, message = Nativefs.write(savefile, serialisedString )
end


function functions.LoadGameSettings()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile, contents

    savefile = savedir .. "/" .. "settings.dat"
    contents, _ = Nativefs.read(savefile)
	local success
    success, GAME_SETTINGS = pcall(Bitser.loads, contents)		--! should do pcall on all the "load" functions

	if success == false then
		GAME_SETTINGS = {}
	end

	--[[ FIXME:
	-- This is horrible bugfix and needs refactoring. If a player doesn't have
	-- a settings.dat already then all the values in GAME_SETTINGS table are
	-- nil. This sets some reasonable defaults to stop nil value crashes.
	]]--
	if GAME_SETTINGS.PlayerName == nil then
		GAME_SETTINGS.PlayerName = DEFAULT_PLAYER_NAME
	end
	if GAME_SETTINGS.hostIP == nil then
		GAME_SETTINGS.hostIP = HOST_IP_ADDRESS
	end
	if GAME_SETTINGS.hostPort == nil then
		GAME_SETTINGS.hostPort = "22122"
	end
	if GAME_SETTINGS.FullScreen == nil then
		GAME_SETTINGS.FullScreen = false
	end
	if GAME_SETTINGS.HighScore == nil then
		GAME_SETTINGS.HighScore = 0
	end

	-- Set the gloal player name to the new value
	CURRENT_PLAYER_NAME = GAME_SETTINGS.PlayerName
end


function functions.SaveGame()
-- uses the globals because too hard to pass params

--! for some reason bitser throws runtime error when serialising true / false values.

    local savefile
    local contents
    local success, message
    local savedir = love.filesystem.getSource()

    savefile = savedir .. "/" .. "landers.dat"
    serialisedString = Bitser.dumps(LANDERS)
    success, message = Nativefs.write(savefile, serialisedString )

    savefile = savedir .. "/" .. "ground.dat"
    serialisedString = Bitser.dumps(GROUND)
    success, message = Nativefs.write(savefile, serialisedString )

    savefile = savedir .. "/" .. "objects.dat"
    serialisedString = Bitser.dumps(OBJECTS)
    success, message = Nativefs.write(savefile, serialisedString )

	LovelyToasts.show("Game saved",3, "middle")

end


function functions.LoadGame()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile
    local contents
	local size
	local error = false

	savefile = savedir .. "/" .. "ground.dat"
	if Nativefs.getInfo(savefile) then
		contents, size = Nativefs.read(savefile)
	    GROUND = bitser.loads(contents)
	else
		error = true
	end

    savefile = savedir .. "/" .. "objects.dat"
	if Nativefs.getInfo(savefile) then
		contents, size = Nativefs.read(savefile)
	    OBJECTS = bitser.loads(contents)
	else
		error = true
	end

    savefile = savedir .. "/" .. "landers.dat"
	if Nativefs.getInfo(savefile) then
	    contents, size = Nativefs.read(savefile)
	    LANDERS = bitser.loads(contents)
	else
		error = true
	end

	if error then
		-- a file is missing, so display a popup on a new game
		Fun.ResetGame()
		LovelyToasts.show("ERROR: Unable to load game!", 3, "middle")
	end
end


function functions.CalculateScore()
	local score = LANDERS[1].x - ORIGIN_X

	if score > GAME_SETTINGS.HighScore then
		GAME_SETTINGS.HighScore = score
		Fun.SaveGameSettings() -- this needs to be refactored somehow, not save every change
	end

	return score
end


function functions.GetDistanceToClosestBase(xvalue, intBaseType)
-- returns two values: the distance to the closest base, and the object/table item for that base
-- if there are no bases (impossible) then the distance value returned will be -1
-- note: if distance is a negative value then the Lander has not yet passed the base

	local closestdistance = 0
	local closestbase
	local absdist
	local dist
	local realdist

	for k,v in pairs(OBJECTS) do
		if v.objecttype == intBaseType then
			-- the + bit is an offset to calculate the landing pad and not the image
			absdist = math.abs(xvalue - (v.x + 85))
			-- same but without the math.abs
			dist = (xvalue - (v.x + 85))
			if closestdistance == 0 or absdist <= closestdistance then
				closestdistance = absdist
				closestbase = v
			end
		end
	end

	-- now we have the closest base, work out the distance to the landing pad for that base
	if closestbase then
		-- the + bit is an offset to calculate the landing pad and not the image
		realdist = xvalue - (closestbase.x + 85)
	end

	return  realdist, closestbase

end


function functions.HandleSockets(dt)

	-- add lander info to the outgoing queue
	local msg = {}
	msg.x = LANDERS[1].x
	msg.y = LANDERS[1].y
	msg.angle = LANDERS[1].angle
	msg.name = LANDERS[1].name
	-- ** msg is set here and sent across UDP below

	if IS_A_HOST then

		ss.hostListenPort()

		repeat
			if incoming ~= nil then
				if incoming.name == "ConnectionRequest" then
					gbolIsConnected = true
					msg = {}
					msg.name = "ConnectionAccepted"
				else
					LANDERS[2] = {}			--! super big flaw: this hardcodes LANDERS[2]
					LANDERS[2].x = incoming.x
					LANDERS[2].y = incoming.y
					LANDERS[2].angle = incoming.angle
					LANDERS[2].name = incoming.name
				end
			end
		until incoming == nil

		msg = {}
	end

	if IS_A_CLIENT then
		repeat
			if incoming ~= nil then
				if incoming.name == "ConnectionAccepted" then
					gbolIsConnected = true
					if CURRENT_SCREEN[#CURRENT_SCREEN] == "MainMenu" then
						Fun.SaveGameSettings()
						Fun.AddScreen("World")
					end
				else
					LANDERS[2] = {}
					LANDERS[2].x = incoming.x
					LANDERS[2].y = incoming.y
					LANDERS[2].angle = incoming.angle
					LANDERS[2].name = incoming.name
				end
			end
		until incoming == nil
	end
end


function functions.ResetGame()

	GROUND = {}
	OBJECTS = {}

	-- ensure Terrain.init appears before Lander.create
	Terrain.init()

	LANDERS = {}
	table.insert(LANDERS, Lander.create())

end

return functions