
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
	local hasThrusterUpgrade = Lander.hasUpgrade(lander, enum.moduleNamesThrusters)
	if lander.fuel - dt >= 0 or (hasThrusterUpgrade and lander.fuel - (dt * 0.80) >= 0) then
		lander.engineOn = true
		local angleRadian = math.rad(lander.angle)
		local forceX = math.cos(angleRadian) * dt
		local forceY = math.sin(angleRadian) * dt

		-- adjust the thrust based on ship mass
		-- less mass = higher ratio = more thrust = less fuel needed to move
		local massRatio = gintDefaultMass / Lander.getMass(lander)
		-- for debugging only
		if gbolDebug then
			garrMassRatio = massRatio
		end

		forceX = forceX * massRatio
		forceY = forceY * massRatio

		lander.vx = lander.vx + forceX
		lander.vy = lander.vy + forceY

		if Lander.hasUpgrade(lander, enum.moduleNamesThrusters) then
			-- efficient thrusters use 80% fuel compared to normal thrusters
			lander.fuel = lander.fuel - (dt * 0.80)
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
		local forceX = 0.5 * dt		--!
		lander.vx = lander.vx - forceX
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - forceX
	end
end



local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, enum.moduleNamesSideThrusters) then
		local forceX = 0.5 * dt		--!
		lander.vx 	= lander.vx + forceX
		lander.fuel = lander.fuel - forceX
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

	if not lander.landed then
		-- used to determine speed right before touchdown
		gfltLandervy = lander.vy
		gfltLandervx = lander.vx
	end

	-- capture a new smoke location every x seconds
	gfltSmokeTimer = gfltSmokeTimer - dt

	if gfltSmokeTimer <= 0 then
		-- only produce smoke when not landed or any of the engines aren't firing
		if (lander.engineOn or lander.leftEngineOn or lander.rightEngineOn) then
			local mysmoke = {}
			mysmoke.x = lander.x
			mysmoke.y = lander.y
			-- a new 'puff' is added when this timer expires (and above conditions are met)
			gfltSmokeTimer = enum.constSmokeTimer
			-- this timer will count up and determine which sprite to display
			mysmoke.dt = 0	
			table.insert(garrSmokeSprites, mysmoke)
		end
	end
end



local function refuelLander(lander, base, dt)
	-- drain fuel from the base and add it to the lander
	-- base is an object/table item from garrObjects
	local refuelAmount = math.min(base.totalFuel, (lander.fuelCapacity - lander.fuel), dt)
	base.totalFuel	= base.totalFuel - refuelAmount
	lander.fuel 	= lander.fuel + refuelAmount
	-- disable the base if the tanks are empty
	if base.totalFuel <= 0 then base.active = false end
end



local function payLanderFromBase(lander, base, baseDistance)
	-- pay some money based on distance to the base
	-- base is an object/table item from garrObjects
	local distance = math.abs(baseDistance)
	if not base.paid then
		lander.money = cf.round(lander.money + (100 - distance),0)
		garrSound[2]:play()
	end
end



local function payLanderForControl(lander, base)
	if base.paid == false then
		-- pay for a good vertical speed
		lander.money = cf.round(lander.money + ((1 - gfltLandervy) * 100),0)
		-- pay for a good horizontal speed
		lander.money = cf.round(lander.money + (0.60 - gfltLandervx * 100),0)
	end
end



local function checkForDamage(lander)
	-- apply damage if vertical speed is too higher
	if lander.vy > enum.constVYThreshold then
		local excessSpeed = lander.vy - enum.constVYThreshold
		lander.health = lander.health - (excessSpeed * 100)
		if lander.health < 0 then lander.health = 0 end
	end
end



local function checkForContact(lander, dt)
	-- see if lander has contacted the ground
	local roundedLanderX = cf.round(lander.x)
	local roundedGroundY
	local onBase = Lander.isOnLandingPad(lander, enum.basetypeFuel)

	-- see if landed near a fuel base
	-- bestDistance could be a negative number meaning not yet past the base (but maybe really close to it)
	-- FIXME: Couldn't baseType be a string like "fuelStation" instead of numbers?
	-- 2 = type of base = fuel
	local bestDistance, bestBase = fun.GetDistanceToClosestBase(lander.x, 2)
	-- bestBase is an object/table item
	-- add money based on alignment to centre of landing pad
	if bestDistance >= -80 and bestDistance <= 40 then
		onBase = true
	end

	-- get the height of the terrain under the lander
	roundedGroundY = cf.round(garrGround[roundedLanderX],0)

	-- check if lander is at or below the terrain
	-- the offset is the size of the lander image
	if lander.y > roundedGroundY - 8 then
		lander.landed = true

		if onBase then
			refuelLander(lander, bestBase,dt)
			payLanderFromBase(lander, bestBase, bestDistance)
			-- pay the lander on first visit on the base
			if not bestBase.paid then
				-- this is the first landing on this base so pay money based on vertical and horizontal speed
				payLanderForControl(lander, bestBase)
				bestBase.paid = true
			end
		end

		if not lander.landed then
			-- a heavy landing will cause damage
			checkForDamage(lander)
			lander.landed = true
		end

		lander.vx = 0
		if lander.vy > 0 then
			lander.vy = 0
		end

		-- check for game-over conditions
		if lander.fuel <= 1 and lander.landed then
			lander.gameOver = true
		end
	else
		lander.landed = false
	end
end



local function playSoundEffects(lander)
	if lander.engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
	end

	local fuelPercent = lander.fuel / lander.fuelCapacity

	-- play alert if fuel is low (but not empty because that's just annoying)
	-- 1% because rounding (fuel is never actually zero)
	if fuelPercent <= 0.33 and fuelPercent > 0.01 then
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
	-- return mass of all the components + mass of fuel if the tank was full (i.e. fuelCapacity)
	return (result + lander.fuelCapacity)
end



local function buyThrusters(lander)
	-- add fuel efficient thrusters to the lander
	if lander.money >= enum.moduleCostsThrusters then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesThrusters then
				-- this module is already purchased. Abort
				--! make a 'wrong' sound
				return
			end
		end

		-- can purchase thrusters

		table.insert(lander.modules, enum.moduleNamesThrusters)
		lander.money = lander.money - enum.moduleCostsThrusters

		lander.mass[1] = 115

		-- need to recalc the default mass
		gintDefaultMass = recalcDefaultMass(lander)
	else
		-- play 'failed' sound
		garrSound[6]:play()
	end
end



local function buyLargeTank(lander)
	-- add a larger tank to carry more totalFuel
	if lander.money >= enum.moduleCostsLargeTank then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesLargeTank then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound
				return
			end
		end

		-- can purchase item

		table.insert(lander.modules, enum.moduleNamesLargeTank)
		lander.money = lander.money - enum.moduleCostsLargeTank

		lander.fuelCapacity = 32		-- an increase from the default (25)
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
	if lander.money >= enum.moduleCostsRangeFinder then
		for i = 1, #lander.modules do
			if lander.modules[i] == enum.moduleNamesRangeFinder then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound
				return
			end
		end

		-- can purchase item

		table.insert(lander.modules, enum.moduleNamesRangeFinder)
		lander.money = lander.money - enum.moduleCostsRangeFinder

		lander.mass[3] = 2	-- this is the mass of the rangefinder

		-- need to recalc the default mass
		gintDefaultMass = recalcDefaultMass(lander)		
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end
end



local function buySideThrusters(lander)
	if lander.money >= enum.moduleCostSideThrusters then
		if not Lander.hasUpgrade(lander, enum.moduleNamesSideThrusters) then
			table.insert(lander.modules, enum.moduleNamesSideThrusters)
			lander.money = lander.money - enum.moduleCostSideThrusters
			-- this is the mass of the side thrusters
			lander.mass[4] = enum.moduleMassSideThrusters	

			-- need to recalc the default mass
			gintDefaultMass = recalcDefaultMass(lander)	
		end
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end
end



local function updateSmoke(dt)
	-- each entry in the smoke table tracks it's own life (dt) so it knows when to expire
	for key, smoke in pairs(garrSmokeSprites) do
		-- 6 seems to give a good effect
		smoke.dt = smoke.dt + (dt * 6)
		-- the sprite sheet has 8 images
		if smoke.dt > 8 then		
			table.remove(garrSmokeSprites,key)
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
    lander.y = garrGround[lander.x] - 8
	lander.sprite = garrImages[5]
	lander.width = lander.sprite:getWidth()
	lander.height = lander.sprite:getHeight()
    lander.angle = 270		-- 270 = up
    lander.vx = 0
    lander.vy = 0
    lander.engineOn = false
    lander.leftEngineOn = false
    lander.rightEngineOn = false
	-- true = on the ground
    lander.landed = false
	-- false = on the ground FOR THE FIRST TIME
    lander.money = 0
	-- this is % meaning 100 = no damage
    lander.health = 100
    lander.gameOver = false
	lander.score = lander.x - gintOriginX
    lander.name = gstrCurrentPlayerName

    -- mass	
    lander.mass = {}
	-- base mass of lander
    table.insert(lander.mass, 100)
	-- volume in arbitrary units
    lander.fuelCapacity = 25
	-- start with a full tank
    lander.fuel = lander.fuelCapacity
	-- this is the mass of an empty tank
    table.insert(lander.mass, 20)
	-- this is the mass of the rangefinder (not yet purchased)
    table.insert(lander.mass, 0)

    -- modules
	-- this will be strings/names of modules
    lander.modules = {}
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



function Lander.isOnLandingPad(lander, baseId)
	-- returns a true / false value
    local baseDistance, _ = fun.GetDistanceToClosestBase(lander.x, baseId)
    if baseDistance >= -80 and baseDistance <= 40 then
        return true
    else
        return false
    end
end



function Lander.hasUpgrade(lander, moduleName)
	for i = 1, #lander.modules do
		if lander.modules[i] == moduleName then
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
    updateSmoke(dt)
    playSoundEffects(lander)
    checkForContact(lander, dt)
end



function Lander.draw(worldOffset)
	-- draw the lander and flame
	for landerId, lander in ipairs(garrLanders) do
		local drawingX = lander.x - worldOffset
		local drawingY = lander.y

		-- fade other landers in multiplayer mode
		if landerId == 1 then
			love.graphics.setColor(1,1,1,1)
		else
			love.graphics.setColor(1,1,1,0.5)
		end

		local ox = lander.width / 2
		local oy = lander.height / 2
		love.graphics.draw(garrImages[5], drawingX,drawingY, math.rad(lander.angle), 1.5, 1.5, ox, oy)

		--[[
			FIXME:
			It would be better to avoid creating these variables every tick. This will likely
			be resolved with further code improvements in the future.
		--]]
		-- draw flames
		local flameSprite	= garrImages[4]
		local flameWidth	= flameSprite:getWidth()
		local flameHeight	= flameSprite:getHeight()
		local ox 			= flameWidth / 2
		local oy 			= flameHeight / 2

		if lander.engineOn then
			local angle = math.rad(lander.angle)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, 1.5, 1.5, ox, oy)
			lander.engineOn = false
		end
		if lander.leftEngineOn then
			local angle = math.rad(lander.angle + 90)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, 1.5,1.5, ox, oy)
			lander.leftEngineOn = false
		end
		if lander.rightEngineOn then
			local angle = math.rad(lander.angle - 90)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, 1.5,1.5, ox, oy)
			lander.rightEngineOn = false
		end

		-- draw smoke trail
		for _, smoke in pairs(garrSmokeSprites) do
			-- FIXME: All images / frames should have a width/height variable to avoid hardcoded numbers!
			-- 8 = smokeFrameWidth / 2
			local drawingX = smoke.x - worldOffset - lander.width / 2 - 8
			local drawingY = smoke.y

			local spriteId = cf.round(smoke.dt)
			if spriteId < 1 then spriteId = 1 end

			love.graphics.draw(gSmokeSheet,gSmokeImages[spriteId], drawingX, drawingY)
		end

		-- draw label
		love.graphics.setNewFont(10)
		local offsetX, offsetY = 14, 10
		love.graphics.print(lander.name, drawingX + offsetX, drawingY - offsetY)
		love.graphics.setColor(1,1,1,1)
	end
end



function Lander.keypressed(key, scancode, isrepeat)
	local lander = garrLanders[1]
	-- 2 = base type (fuel)
	if Lander.isOnLandingPad(lander, 2) then
		if key == "1" then
			buyThrusters(lander)
		elseif key == "2" then
			buyLargeTank(lander)
		elseif key == "3" then
			buyRangefinder(lander)
		elseif key == "4" then
			buySideThrusters(lander)
		end
	end
end


return Lander