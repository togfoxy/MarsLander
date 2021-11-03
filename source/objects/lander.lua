
-- ~~~~~~~~~~~~
-- Lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}


local keyDown = love.keyboard.isDown



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function doThrust(lander, dt)
	-- FIXME: This statement potentially doesn't work as expected. Check and verify!
	if lander.fuel - dt >= 0 or (Lander.hasUpgrade(lander, enum.moduleNamesThrusters) and lander.fuel - (dt * 0.80) >= 0) then
		lander.engineOn = true
		local angle_radian = math.rad(lander.angle)
		local force_x = math.cos(angle_radian) * dt
		local force_y = math.sin(angle_radian) * dt

		-- adjust the thrust based on ship mass
		-- less mass = higher ratio = more thrust = less fuel needed to move
		local massratio = gintDefaultMass / Lander.getMass(lander)
		-- for debugging only
		if gbolDebug then
			garrMassRatio = massratio
		end

		force_x = force_x * massratio
		force_y = force_y * massratio

		lander.vx = lander.vx + force_x
		lander.vy = lander.vy + force_y

		if Lander.hasUpgrade(lander, enum.moduleNamesThrusters) then
			lander.fuel = lander.fuel - (dt * 0.80)		-- efficient thrusters use 80% fuel compared to normal thrusters
		else
			lander.fuel = lander.fuel - (dt * 1)
		end
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
	end
end



local function thrustLeft(lander, dt)
	if Lander.hasUpgrade(lander, enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		lander.vx = lander.vx - force_x
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - force_x
	end
end



local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		lander.vx = lander.vx + force_x
		lander.fuel = lander.fuel - force_x
		-- opposite engine is on
		lander.leftEngineOn = true
	end
end



local function moveShip(lander, dt)
	lander.x = lander.x + lander.vx
	lander.y = lander.y + lander.vy

	local leftedge = gintOriginX - (gintScreenWidth / 2)
	if lander.x < leftedge then
		lander.x = leftedge
	end

	-- apply gravity
	if not lander.landed then
		lander.vy = lander.vy + (enum.constGravity * dt)
	end

	if lander.airborne then
		-- used to determine speed right before touchdown
		gfltLandervy = lander.vy
		gfltLandervx = lander.vx
	end

	-- capture a new smoke location every x seconds
	gfltSmokeTimer = gfltSmokeTimer - dt

	if gfltSmokeTimer <= 0 then
		-- only produce smoke when not landed or any of the engines aren't firing
		if lander.landed and (lander.engineOn or lander.leftEngineOn or lander.rightEngineOn) then
			gfltSmokeTimer = enum.constSmokeTimer	-- a new 'puff' is added when this timer expires (and above conditions are met)

			local mysmoke = {}
			mysmoke.x = lander.x
			mysmoke.y = lander.y
			mysmoke.dt = 0			-- this timer will count up and determine which sprite to display
			table.insert(garrSmokeSprites, mysmoke)
		end
	end
end



local function refuelLander(lander, objBase, dt)
	-- drain fuel from the base and add it to the lander
	-- objBase is an object/table item from garrObjects
	local refuelamt = math.min(objBase.fuelqty, (lander.fueltanksize - lander.fuel), dt)
	objBase.fuelqty = objBase.fuelqty - refuelamt
	lander.fuel 	= lander.fuel + refuelamt
	-- disable the base if the tanks are empty
	if objBase.fuelqty <= 0 then objBase.active = false end
end



local function payLanderFromBase(lander, objBase, fltDist)
	-- pay some wealth based on distance to the base
	-- objBase is an object/table item from garrObjects
	-- fltDist is the distance from the base
	local dist = math.abs(fltDist)
	if not objBase.paid then
		lander.wealth = cf.round(lander.wealth + (100 - dist),0)
		garrSound[2]:play()
	end
end



local function payLanderForControl(lander, objBase)
	if objBase.paid == false then
		-- pay for a good vertical speed
		lander.wealth = cf.round(lander.wealth + ((1 - gfltLandervy) * 100),0)
		-- pay for a good horizontal speed
		lander.wealth = cf.round(lander.wealth + (0.60 - gfltLandervx * 100),0)
	end
end



local function checkForDamage(lander)
	-- apply damage if vertical speed is too higher
	if lander.vy > enum.constVYThreshold then
		local excessspeed = lander.vy - enum.constVYThreshold
		lander.health = lander.health - (excessspeed * 100)
		if lander.health < 0 then lander.health = 0 end
	end
end



local function checkForContact(lander, dt)
	-- see if lander has contacted the ground
	local LanderXValue = cf.round(lander.x)
	local groundYvalue
	local onbase = Lander.isOnLandingPad(lander, enum.basetypeFuel)

	-- see if landed near a fuel base
	-- bestdist could be a negative number meaning not yet past the base (but maybe really close to it)
	local bestdist, bestbase = fun.GetDistanceToClosestBase(lander.x, 2)		-- 2 = type of base = fuel
	-- bestbase is an object/table item
	-- add wealth based on alignment to centre of landing pad
	if bestdist >= -80 and bestdist <= 40 then
		onbase = true
	end

	-- get the height of the terrain under the lander
	groundYvalue = cf.round(garrGround[LanderXValue],0)

	-- check if lander is at or below the terrain
	if lander.y > groundYvalue - 8 then		-- the offset is the size of the lander image
		lander.landed = true

		if onbase then
			refuelLander(lander, bestbase,dt)
			payLanderFromBase(lander, bestbase, bestdist)
			-- if lander was airborne then track that now it's not.
			if lander.airborne then
				-- this is the first landing on this base so pay wealth based on vertical and horizontal speed
				payLanderForControl(lander, bestbase)
				bestbase.paid = true
			end				
		end

		if lander.airborne then
			-- a heavy landing will cause damage
			checkForDamage(lander)
			lander.airborne = false
		end

		lander.vx = 0
		if lander.vy > 0 then lander.vy = 0 end			

		-- check for game-over conditions
		if lander.fuel <= 1 and lander.landed and onbase then
			lander.bolGameOver = true
		end
	else
		lander.landed = false
		lander.airborne = true
	end
end



local function playSoundEffects(lander)
	if lander.engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
	end

	local fuelpercent = lander.fuel / lander.fueltanksize

	-- play alert if fuel is low (but not empty because that's just annoying)
	if fuelpercent <= 0.33 and fuelpercent > 0.01 then		-- 1% because rounding (fuel is never actually zero)
		garrSound[5]:play()
	end
end



local function recalcDefaultMass(lander)
	-- need to recalc the default mass
	-- usually called after buying a module
	local result = 0
	-- all the masses are stored in this table so add them up
	for i = 1, #lander.mass do
		result = result + lander.mass[i]
	end
	return (result + lander.fueltanksize)		-- mass of all the components + mass of fuel if the tank was full (i.e. fueltanksize)
end



local function buyThrusters(lander)
	-- add fuel efficient thrusters to the lander
	if lander.wealth >= enum.moduleCostsThrusters then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesThrusters then
				-- this module is already purchased. Abort
				--! make a 'wrong' sound		
				return
			end
		end

		-- can purchase thrusters

		table.insert(lander.modules, enum.moduleNamesThrusters)
		lander.wealth = lander.wealth - enum.moduleCostsThrusters

		lander.mass[1] = 115

		-- need to recalc the default mass
		gintDefaultMass = recalcDefaultMass(lander)
	else
		-- play 'failed' sound
		garrSound[6]:play()
	end
end



local function buyLargeTank(lander)
	-- add a larger tank to carry more fuelqty
	if lander.wealth >= enum.moduleCostsLargeTank then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesLargeTank then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end

		-- can purchase item

		table.insert(lander.modules, enum.moduleNamesLargeTank)
		lander.wealth = lander.wealth - enum.moduleCostsLargeTank

		lander.fueltanksize = 32		-- an increase from the default (25)
		lander.mass[2] = 23

		-- need to recalc the default mass
		gintDefaultMass = recalcDefaultMass(lander)
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end
end



local function buyRangefinder(lander)
	-- the rangefinder points to the nearest base
	if lander.wealth >= enum.moduleCostsRangeFinder then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesRangeFinder then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end

		-- can purchase item

		table.insert(lander.modules, enum.moduleNamesRangeFinder)
		lander.wealth = lander.wealth - enum.moduleCostsRangeFinder

		lander.mass[3] = 2	-- this is the mass of the rangefinder

		-- need to recalc the default mass
		gintDefaultMass = recalcDefaultMass(lander)		
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end
end



local function buySideThrusters(lander)
	if lander.wealth >= enum.moduleCostSideThrusters then
		if not Lander.hasUpgrade(lander, enum.moduleNamesSideThrusters) then
			table.insert(lander.modules, enum.moduleNamesSideThrusters)
			lander.wealth	= lander.wealth - enum.moduleCostSideThrusters
			lander.mass[4]	= enum.moduleMassSideThrusters	-- this is the mass of the side thrusters

			-- need to recalc the default mass
			gintDefaultMass = recalcDefaultMass(lander)	
		end
	else
		-- play 'failed' sound
		garrSound[6]:play()		
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
    local lander = {}
    lander.x = gintOriginX
    lander.y = 500
    lander.y = garrGround[lander.x] - 8
    lander.angle = 270		-- 270 = up
    lander.vx = 0
    lander.vy = 0
    lander.engineOn = false
    lander.leftEngineOn = false
    lander.rightEngineOn = false
    lander.landed = false			-- true = on the ground
    lander.airborne = false			-- false = on the ground FOR THE FIRST TIME
    lander.wealth = 0
    lander.health = 100				-- this is % meaning 100 = no damage
    lander.bolGameOver = false
	lander.score = lander.x - gintOriginX
    lander.name = gstrCurrentPlayerName

    -- mass	
    lander.mass = {}
    table.insert(lander.mass, 100)	-- base mass of lander

    lander.fueltanksize = 25		-- volume in arbitrary units
    lander.fuel = lander.fueltanksize	-- start with a full tank
    table.insert(lander.mass, 20)	-- this is the mass of an empty tank
    table.insert(lander.mass, 0)	-- this is the mass of the rangefinder (not yet purchased)

    -- modules
    lander.modules = {}		-- this will be strings/names of modules
    return lander
end



function Lander.getMass(lander)
	-- return the mass of all the bits on the lander
    local result = 0

    -- all the masses are stored in this table so add them up
    for i = 1, #lander.mass do
        result = result + lander.mass[i]
    end

    -- add the mass of the fuel
    result = result + lander.fuel

    return result
end



function Lander.isOnLandingPad(lander, intBaseType)
	-- returns a true / false value
    local mydist, _ = fun.GetDistanceToClosestBase(lander.x, intBaseType)
    if mydist >= -80 and mydist <= 40 then
        return true
    else
        return false
    end
end



function Lander.hasUpgrade(lander, strModuleName)
	for i = 1, #lander.modules do
		if lander.modules[i] == strModuleName then
			return true
		end
	end
	return false
end



function Lander.update(lander, dt)
    if keyDown("up") or keyDown("w") or keyDown("kp8") then
        doThrust(lander, dt)
    end
	-- rotate the lander anti-clockwise
    if keyDown("left") or keyDown("a") or keyDown("kp4") then
		lander.angle = lander.angle - (90 * dt)
    end
	-- rotate the lander clockwise
    if keyDown("right") or keyDown("d") or keyDown("kp6") then
		lander.angle = lander.angle + (90 * dt)
    end
    if keyDown("q") or keyDown("kp7") then
        thrustLeft(lander, dt)
    end
    if keyDown("e") or keyDown("kp9") then
        thrustRight(lander, dt)
    end

    if keyDown("p") then
        fun.AddScreen("Pause")
	elseif keyDown("o") then
        fun.AddScreen("Settings")
    end

	-- Rest angle
	if math.max(lander.angle) > 360 then lander.angle = 0 end
	
	-- Update ship
    moveShip(lander, dt)
    UpdateSmoke(dt)
    playSoundEffects(lander)
    checkForContact(lander, dt)
end



function Lander.draw(worldoffset)
	-- draw the lander and flame
	for landerId, lander in ipairs(garrLanders) do
		local drawingx = lander.x - worldoffset
		local drawingy = lander.y

		if drawingx < -200 or drawingx > (gintScreenWidth * 1.1) then
			-- off screen. do nothing.
		else
			-- fade other landers in multiplayer mode
			if landerId == 1 then
				love.graphics.setColor(1,1,1,1)
			else
				love.graphics.setColor(1,1,1,0.5)
			end

			love.graphics.draw(garrImages[5], drawingx,drawingy, math.rad(lander.angle), 1.5, 1.5, garrImages[5]:getWidth()/2, garrImages[5]:getHeight()/2)

			-- draw flames
			if lander.engineOn then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(lander.angle), 1.5, 1.5, garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				lander.engineOn = false
			end
			if lander.leftEngineOn then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(lander.angle + 90), 1.5,1.5,  garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				lander.leftEngineOn = false
			end
			if lander.rightEngineOn then
				love.graphics.draw(garrImages[4], drawingx, drawingy, math.rad(lander.angle - 90), 1.5,1.5,  garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
				lander.rightEngineOn = false
			end

			-- draw smoke trail
			for _, smoke in pairs(garrSmokeSprites) do
				local drawingx = smoke.x - worldoffset
				local drawingy = smoke.y

				local intSpriteNum = cf.round(smoke.dt)
				if intSpriteNum < 1 then intSpriteNum = 1 end

				-- not sure why the smoke sprite needs to be rotate +135. Suspect the image is drawn wrong. This works but!
				love.graphics.draw(gSmokeSheet,gSmokeImages[intSpriteNum], drawingx, drawingy, math.rad(lander.angle + 135))
			end

			-- draw label
			love.graphics.setNewFont(10)
			local offsetX, offsetY = 14, 10
			love.graphics.print(lander.name, drawingx + offsetX, drawingy - offsetY)
			love.graphics.setColor(1,1,1,1)
		end
	end
end



function Lander.keypressed(key, scancode, isrepeat)
	if Lander.isOnLandingPad(garrLanders[1], 2) then	-- 2 = base type (fuel)
		if key == "1" then
			buyThrusters(garrLanders[1])
		elseif key == "2" then
			buyLargeTank(garrLanders[1])
		elseif key == "3" then
			buyRangefinder(garrLanders[1])
		elseif key == "4" then
			buySideThrusters(garrLanders[1])
		end		
	end
end


return Lander