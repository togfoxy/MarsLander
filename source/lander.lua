
-- ~~~~~~~~~~~~
-- Lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander Entity/Object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function DoThrust(dt)

	if garrLanders[1].fuel - dt >= 0 or (Lander.hasUpgrade(enum.moduleNamesThrusters) and garrLanders[1].fuel - (dt * 0.80) >= 0) then

		garrLanders[1].engineOn = true
		local angle_radian = math.rad(garrLanders[1].angle)
		local force_x = math.cos(angle_radian) * dt
		local force_y = math.sin(angle_radian) * dt
		
		-- adjust the thrust based on ship mass
		local massratio = gintDefaultMass / Lander.getMass()	-- less mass = higher ratio = more thrust = less fuel needed to move
		if gbolDebug then garrMassRatio = massratio end			-- for debugging only
		force_x = force_x * massratio
		force_y = force_y * massratio

		garrLanders[1].vx = garrLanders[1].vx + force_x
		garrLanders[1].vy = garrLanders[1].vy + force_y

		if Lander.hasUpgrade(enum.moduleNamesThrusters) then
			garrLanders[1].fuel = garrLanders[1].fuel - (dt * 0.80)		-- efficient thrusters use 80% fuel compared to normal thrusters
		else
			garrLanders[1].fuel = garrLanders[1].fuel - (dt * 1)
		end
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
	end
end



local function TurnLeft(dt)
-- rotate the lander anti-clockwise

	garrLanders[1].angle = garrLanders[1].angle - (90 * dt)
	if garrLanders[1].angle < 0 then garrLanders[1].angle = 360 end
end



local function TurnRight(dt)
-- rotate the lander clockwise

	garrLanders[1].angle = garrLanders[1].angle + (90 * dt)
	if garrLanders[1].angle > 360 then garrLanders[1].angle = 0 end

end



local function ThrustLeft(dt)

	if Lander.hasUpgrade(enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		garrLanders[1].vx = garrLanders[1].vx - force_x
		garrLanders[1].enginerighton = true						-- opposite engine is on
		
		garrLanders[1].fuel = garrLanders[1].fuel - force_x
	end
end



local function ThrustRight(dt)

	if Lander.hasUpgrade(enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		garrLanders[1].vx = garrLanders[1].vx + force_x
		garrLanders[1].enginelefton = true						-- opposite engine is on
		
		garrLanders[1].fuel = garrLanders[1].fuel - force_x
	end

end



local function MoveShip(landerObj, dt)

	landerObj.x = landerObj.x + landerObj.vx
	landerObj.y = landerObj.y + landerObj.vy
	
	local leftedge = gintOriginX - (gintScreenWidth / 2)
	if landerObj.x < leftedge then landerObj.x = leftedge end
	
	-- apply gravity
	if landerObj.landed == false then
		landerObj.vy = landerObj.vy + (enum.constGravity * dt)
	end
	
	if landerObj.airborne then
		gfltLandervy = landerObj.vy		-- used to determine speed right before touchdown
		gfltLandervx = landerObj.vx
	end
	
	-- capture a new smoke location every x seconds
	gfltSmokeTimer = gfltSmokeTimer - dt
	if gfltSmokeTimer <= 0 then
		-- only produce smoke when not landed or any of the engines aren't firing
		if (landerObj.landed == false) and (landerObj.engineOn or landerObj.enginelefton or landerObj.enginerighton) then
			
			gfltSmokeTimer = enum.constSmokeTimer	-- a new 'puff' is added when this timer expires (and above conditions are met)
			
			local mysmoke = {}
			mysmoke.x = landerObj.x
			mysmoke.y = landerObj.y
			mysmoke.dt = 0			-- this timer will count up and determine which sprite to display
			
			table.insert(garrSmokeSprites, mysmoke)
		end
	end
	
end



local function RefuelLander(objBase, dt)
-- drain fuel from the base and add it to the lander
-- objBase is an object/table item from garrObjects

	local refuelamt = math.min(objBase.fuelqty, (garrLanders[1].fueltanksize - garrLanders[1].fuel), dt)

	objBase.fuelqty = objBase.fuelqty - refuelamt
	garrLanders[1].fuel = garrLanders[1].fuel + refuelamt
	
	-- disable the base if the tanks are empty
	if objBase.fuelqty <= 0 then objBase.active = false end

end



local function PayLanderFromBase(objBase, fltDist)
-- pay some wealth based on distance to the base
-- objBase is an object/table item from garrObjects
-- fltDist is the distance from the base

	local dist = math.abs(fltDist)
	if objBase.paid == false then
		garrLanders[1].wealth = cf.round(garrLanders[1].wealth + (100 - dist),0)
		garrSound[4]:play()
	end

end



local function PayLanderForControl(objBase)

	if objBase.paid == false then
		-- pay for a good vertical speed
		garrLanders[1].wealth = cf.round(garrLanders[1].wealth + ((1 - gfltLandervy) * 100),0)
		
		-- pay for a good horizontal speed
		garrLanders[1].wealth = cf.round(garrLanders[1].wealth + (0.60 - gfltLandervx * 100),0)
		
	end
end



local function CheckForDamage()
-- apply damage if vertical speed is too higher
	
	if garrLanders[1].vy > enum.constVYThreshold then
		local excessspeed = garrLanders[1].vy - enum.constVYThreshold
		garrLanders[1].health = garrLanders[1].health - (excessspeed * 100)
	
		if garrLanders[1].health < 0 then garrLanders[1].health = 0 end
	end

end



local function CheckForContact(landerObj,dt)
-- see if lander has contacted the ground

	local LanderXValue = cf.round(landerObj.x)
	local groundYvalue
	local onbase = Lander.isOnLandingPad(enum.basetypeFuel)

	-- see if landed near a fuel base
	-- bestdist could be a negative number meaning not yet past the base (but maybe really close to it)
	local bestdist, bestbase = fun.GetDistanceToClosestBase(landerObj.x, 2)		-- 2 = type of base = fuel
	-- bestbase is an object/table item
	-- add wealth based on alignment to centre of landing pad
	if bestdist >= -80 and bestdist <= 40 then
		onbase = true
	end

	-- get the height of the terrain under the lander
	groundYvalue = cf.round(garrGround[LanderXValue],0)

	-- check if lander is at or below the terrain
	if landerObj.y > groundYvalue - 8 then		-- the offset is the size of the lander image
		landerObj.landed = true

		if onbase then
			RefuelLander(bestbase,dt)
			PayLanderFromBase(bestbase, bestdist)
			
			-- if lander was airborne then track that now it's not.
			if landerObj.airborne then
				-- this is the first landing on this base so pay wealth based on vertical and horizontal speed
				PayLanderForControl(bestbase)
				bestbase.paid = true
			end				
		end
		
		if landerObj.airborne then
			-- a heavy landing will cause damage
			CheckForDamage()
			
			landerObj.airborne = false
		end

		landerObj.vx = 0
		if landerObj.vy > 0 then landerObj.vy = 0 end			
		
		-- check for game-over conditions
		if landerObj.fuel <= 1 and landerObj.landed == true and onbase == false then
			landerObj.bolGameOver = true
		end
	else
		landerObj.landed = false
		landerObj.airborne = true
	end
end



local function PlaySoundEffects()

	if garrLanders[1].engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
	end
	
	local fuelpercent = garrLanders[1].fuel / garrLanders[1].fueltanksize
	
	-- play alert if fuel is low (but not empty because that's just annoying)
	if fuelpercent <= 0.33 and fuelpercent > 0.01 then		-- 1% because rounding (fuel is never actually zero)
		garrSound[5]:play()
	end
end



local function RecalcDefaultMass()
-- need to recalc the default mass
-- usually called after buying a module
		local result = 0
		-- all the masses are stored in this table so add them up
		for i = 1, #garrLanders[1].mass do
			result = result + garrLanders[1].mass[i]
		end
		return (result + garrLanders[1].fueltanksize)		-- mass of all the components + mass of fuel if the tank was full (i.e. fueltanksize)

end



local function PurchaseThrusters()
-- add fuel efficient thrusters to the lander

	if garrLanders[1].wealth >= enum.moduleCostsThrusters then
		for i = 1, #garrLanders[1].modules do
			if garrLanders[1].modules[i] == enum.moduleNamesThrusters then
				-- this module is already purchased. Abort
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase thrusters
		
		table.insert(garrLanders[1].modules, enum.moduleNamesThrusters)
		garrLanders[1].wealth = garrLanders[1].wealth - enum.moduleCostsThrusters
		
		garrLanders[1].mass[1] = 115
		
		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass()
	else
		-- play 'failed' sound
		garrSound[6]:play()
	end
end



local function PurchaseLargeTank()
-- add a larger tank to carry more fuelqty

	if garrLanders[1].wealth >= enum.moduleCostsLargeTank then
		for i = 1, #garrLanders[1].modules do
			if garrLanders[1].modules[i] == enum.moduleNamesLargeTank then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase item
		
		table.insert(garrLanders[1].modules, enum.moduleNamesLargeTank)
		garrLanders[1].wealth = garrLanders[1].wealth - enum.moduleCostsLargeTank
		
		garrLanders[1].fueltanksize = 32		-- an increase from the default (25)
		garrLanders[1].mass[2] = 23
		
		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass()
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end

end



local function PurchaseRangeFinder()
-- the rangefinder points to the nearest base

	if garrLanders[1].wealth >= enum.moduleCostsRangeFinder then
		for i = 1, #garrLanders[1].modules do
			if garrLanders[1].modules[i] == enum.moduleNamesRangeFinder then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase item
		
		table.insert(garrLanders[1].modules, enum.moduleNamesRangeFinder)
		garrLanders[1].wealth = garrLanders[1].wealth - enum.moduleCostsRangeFinder

		garrLanders[1].mass[3] = 2	-- this is the mass of the rangefinder

		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass()		
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end

end



local function PurchaseSideThrusters()

	if garrLanders[1].wealth >= enum.moduleCostSideThrusters then
		if not Lander.hasUpgrade(enum.moduleNamesSideThrusters) then
			table.insert(garrLanders[1].modules, enum.moduleNamesSideThrusters)
			garrLanders[1].wealth = garrLanders[1].wealth - enum.moduleCostSideThrusters

			garrLanders[1].mass[4] = enum.moduleMassSideThrusters	-- this is the mass of the side thrusters

			-- need to recalc the default mass
			gintDefaultMass = RecalcDefaultMass()	
		end
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end
end



function Lander.handleSockets()
	
	-- add lander info to the outgoing queue
	local msg = {}
	msg.x = garrLanders[1].x
	msg.y = garrLanders[1].y
	msg.angle = garrLanders[1].angle
	msg.name = garrLanders[1].name
	-- ** msg is set here and sent below
	
	if gbolIsAHost then
		ss.HostListenPort()
		
		-- get just one item from the queue and process it
		repeat
			local incoming = ss.GetItemInHostQueue()		-- could be nil
			if incoming ~= nil then
				if incoming.name == "ConnectionRequest" then
					gbolIsConnected = true
					msg = {}
					msg.name = "ConnectionAccepted"

				else
					garrLanders[2] = {}			--! super big flaw: this hardcodes garrLanders[2]. 
					garrLanders[2].x = incoming.x
					garrLanders[2].y = incoming.y
					garrLanders[2].angle = incoming.angle
					garrLanders[2].name = incoming.name
				end	
			end
		until incoming == nil
			
		ss.AddItemToHostOutgoingQueue(msg)
		ss.SendToClients()
		msg = {}
	end
	
	if gbolIsAClient then
		ss.ClientListenPort()
		
		-- get item from the queue and process it
		repeat
			local incoming = ss.GetItemInClientQueue()		-- could be nil
			if incoming ~= nil then
				if incoming.name == "ConnectionAccepted" then
					gbolIsConnected = true
					if garrCurrentScreen[#garrCurrentScreen] == "MainMenu" then
						fun.SaveGameSettings()
						fun.AddScreen("World")
					end
				else	
					garrLanders[2] = {}
					garrLanders[2].x = incoming.x
					garrLanders[2].y = incoming.y
					garrLanders[2].angle = incoming.angle
					garrLanders[2].name = incoming.name
				end
			end
		until incoming == nil

		ss.AddItemToClientOutgoingQueue(msg)	-- Lander[1]
		ss.SendToHost()
		msg = {}
	end
end



local function UpdateSmoke(dt)
-- each entry in the smoke table tracks it's own life (dt) so it knows when to expire

	for k,v in pairs(garrSmokeSprites) do
		v.dt = v.dt + (dt * 6)	-- 6 seems to give a good effect
		if v.dt > 8 then		-- the sprite sheet has 8 images
			table.remove(garrSmokeSprites,k)
		end
	end
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Lander.create()
-- create a lander and return it to the calling sub

    local newLander = {}
    newLander.x = gintOriginX
    newLander.y = 500
    newLander.y = garrGround[newLander.x] - 8
    newLander.angle = 270		-- 270 = up
    newLander.vx = 0
    newLander.vy = 0
    newLander.engineOn = false
    newLander.enginelefton = false
    newLander.enginerighton = false
    newLander.landed = false			-- true = on the ground
    newLander.airborne = false			-- false = on the ground FOR THE FIRST TIME
    newLander.wealth = 0
    newLander.health = 100				-- this is % meaning 100 = no damage
    newLander.bolGameOver = false
    newLander.name = gstrCurrentPlayerName	
    
    -- mass	
    newLander.mass = {}
    table.insert(newLander.mass, 100)	-- base mass of lander

    newLander.fueltanksize = 25		-- volume in arbitrary units
    newLander.fuel = newLander.fueltanksize	-- start with a full tank
    table.insert(newLander.mass, 20)	-- this is the mass of an empty tank
    table.insert(newLander.mass, 0)	-- this is the mass of the rangefinder (not yet purchased)
    
    -- modules
    newLander.modules = {}		-- this will be strings/names of modules
    
    return newLander

end



function Lander.getMass()
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



function Lander.isOnLandingPad(intBaseType)
-- returns a true / false value

    local mydist, _ = fun.GetDistanceToClosestBase(garrLanders[1].x, intBaseType)
    if mydist >= -80 and mydist <= 40 then
        return true
    else
        return false
    end
end



function Lander.hasUpgrade(strModuleName)

	for i = 1, #garrLanders[1].modules do
		if garrLanders[1].modules[i] == strModuleName then
			return true
		end
	end
	return false
end



function Lander.update(dt)
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("kp8") then
        DoThrust(dt)
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") or love.keyboard.isDown("kp4") then
        TurnLeft(dt)
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") or love.keyboard.isDown("kp6") then
        TurnRight(dt)
    end
    if love.keyboard.isDown("q") or love.keyboard.isDown("kp7") then
        ThrustLeft(dt)
    end
    if love.keyboard.isDown("e") or love.keyboard.isDown("kp9") then
        ThrustRight(dt)
    end		
    if love.keyboard.isDown("p") then
        fun.AddScreen("Pause")
    end
    if love.keyboard.isDown("o") then
        fun.AddScreen("Settings")
    end

    MoveShip(garrLanders[1], dt)		--! some really inconsistent use of parameters here
    
    UpdateSmoke(dt)
    
    PlaySoundEffects()
    
    CheckForContact(garrLanders[1], dt)
end



function Lander.draw(worldoffset)

	-- draw the lander and flame
	for k,v in ipairs(garrLanders) do

		local drawingx = v.x - worldoffset
		local drawingy = v.y
		
		if drawingx < -200 or drawingx > (gintScreenWidth * 1.1) then
			-- off screen. do nothing.
		else
		
			-- fade other landers in multiplayer mode
			if k == 1 then
				love.graphics.setColor(1,1,1,1)
			else
				love.graphics.setColor(1,1,1,0.5)
			end
			
			love.graphics.draw(garrImages[5], drawingx,drawingy, math.rad(v.angle), 1.5, 1.5, garrImages[5]:getWidth()/2, garrImages[5]:getHeight()/2)

			-- draw flames
			if v.engineOn == true then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(v.angle), 1.5, 1.5, garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				v.engineOn = false
			end	
			if v.enginelefton == true then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(v.angle + 90), 1.5,1.5,  garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				v.enginelefton = false
			end
			if v.enginerighton == true then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(v.angle - 90), 1.5,1.5,  garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				v.enginerighton = false
			end	

			-- draw smoke trail
			for q,w in pairs(garrSmokeSprites) do
				local drawingx = w.x - worldoffset
				local drawingy = w.y

				local intSpriteNum = cf.round(w.dt)
				if intSpriteNum < 1 then intSpriteNum = 1 end
				
				-- not sure why the smoke sprite needs to be rotate +135. Suspect the image is drawn wrong. This works but!
				love.graphics.draw(gSmokeSheet,gSmokeImages[intSpriteNum], drawingx, drawingy, math.rad(v.angle + 135))

			end
			
			-- draw label
			love.graphics.setNewFont(10)
			local offsetX, offsetY = 14, 10
			love.graphics.print(v.name, drawingx + offsetX, drawingy - offsetY)

			love.graphics.setColor(1,1,1,1)
		end
	end
end



function Lander.keypressed(key, scancode, isrepeat)
	if Lander.isOnLandingPad(2) then	-- 2 = base type (fuel)
		if key == "1" then			 
			PurchaseThrusters()
		end
	
		if key == "2" then			
			PurchaseLargeTank()
		end	
		
		if key == "3" then			
			PurchaseRangeFinder()
		end

		if key == "4" then			
			PurchaseSideThrusters()
		end		
	end
end


return Lander