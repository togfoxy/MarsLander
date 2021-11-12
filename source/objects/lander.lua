
-- ~~~~~~~~~~~~
-- lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}



-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

local keyDown = love.keyboard.isDown

-- TODO: Create the spriteData with width and height automatically (except for animations)
local ship = Assets.getImageSet("ship")
local flame = Assets.getImageSet("flame")

local landingSound = Assets.getSound("landingSuccess")
local failSound = Assets.getSound("wrong")
local lowFuelSound = Assets.getSound("lowFuel")
local engineSound = Assets.getSound("engine")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function doThrust(lander, dt)
	local hasThrusterUpgrade = Lander.hasUpgrade(lander, Modules.thrusters)
	if lander.fuel - dt >= 0 or (hasThrusterUpgrade and lander.fuel - (dt * 0.80) >= 0) then
		local angleRadian = math.rad(lander.angle)
		local forceX = math.cos(angleRadian) * dt
		local forceY = math.sin(angleRadian) * dt

		-- adjust the thrust based on ship mass
		-- less mass = higher ratio = more thrust = less fuel needed to move
		local massRatio = DEFAULT_MASS / Lander.getMass(lander)
		-- for debugging only
		if DEBUG then
			MASS_RATIO = massRatio
		end

		lander.engineOn = true
		forceX = forceX * massRatio
		forceY = forceY * massRatio
		lander.vx = lander.vx + forceX
		lander.vy = lander.vy + forceY

		if hasThrusterUpgrade then
			-- efficient thrusters use 80% fuel compared to normal thrusters
			lander.fuel = lander.fuel - (dt * 0.80)
		else
			lander.fuel = lander.fuel - (dt * 1)
		end

		-- Add smoke particles if available
		if Smoke then
			Smoke.createParticle(lander.x, lander.y, lander.angle)
		end
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
	end
end



local function thrustLeft(lander, dt)
	if Lander.hasUpgrade(lander, Modules.sideThrusters) then
		local forceX = 0.5 * dt		--!
		lander.vx = lander.vx - forceX
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - forceX
	end
end



local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, Modules.sideThrusters) then
		local forceX = 0.5 * dt		--!
		lander.vx	= lander.vx + forceX
		lander.fuel = lander.fuel - forceX
		-- opposite engine is on
		lander.leftEngineOn = true
	end
end



local function moveShip(lander, dt)
	lander.x = lander.x + lander.vx
	lander.y = lander.y + lander.vy

	-- Set left boundary
	if lander.x < ORIGIN_X - (SCREEN_WIDTH / 2) then
		lander.vx = 0
		lander.x =  ORIGIN_X - (SCREEN_WIDTH / 2)
	end

	if not lander.onGround then
		-- apply gravity
		lander.vy = lander.vy + (Enum.constGravity * dt)
		-- used to determine speed right before touchdown
		LANDER_VY = lander.vy
		LANDER_VX = lander.vx
	end
	
	-- lander.x = Cf.round(lander.x,0)
end



local function refuelLander(lander, base, dt)
	-- drain fuel from the base and add it to the lander
	-- base is an object/table item from OBJECTS
	local refuelAmount = math.min(base.totalFuel, (lander.fuelCapacity - lander.fuel), dt)
	base.totalFuel	= base.totalFuel - refuelAmount
	lander.fuel		= lander.fuel + refuelAmount
	-- disable the base if the tanks are empty
	if base.totalFuel <= 0 then base.active = false end
end



local function payLanderFromBase(lander, base, baseDistance)
	-- pay some money based on distance to the base
	-- base is an object/table item from OBJECTS
	local distance = math.abs(baseDistance)
	if not base.paid then
		lander.money = Cf.round(lander.money + (100 - distance),0)
		landingSound:play()
	end
end



local function payLanderForControl(lander, base)
	if base.paid == false then
		-- pay for a good vertical speed
		lander.money = Cf.round(lander.money + ((1 - LANDER_VY) * 100),0)
		-- pay for a good horizontal speed
		lander.money = Cf.round(lander.money + (0.60 - LANDER_VX * 100),0)
	end
end



local function checkForDamage(lander)
	-- apply damage if vertical speed is too higher
	if lander.vy > Enum.constVYThreshold then
		local excessSpeed = lander.vy - Enum.constVYThreshold
		lander.health = lander.health - (excessSpeed * 100)
		if lander.health < 0 then lander.health = 0 end
	end
end



local function checkForContact(lander, dt)
	-- see if lander has contacted the ground
	local roundedLanderX = Cf.round(lander.x)
	local roundedGroundY
	local onBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

	-- see if onGround near a fuel base
	-- bestDistance could be a negative number meaning not yet past the base (but maybe really close to it)
	-- FIXME: Couldn't baseType be a string like "fuelStation" instead of numbers?
	-- 2 = type of base = fuel
	local bestDistance, bestBase = Fun.GetDistanceToClosestBase(lander.x, 2)
	-- bestBase is an object/table item
	-- add money based on alignment to centre of landing pad
	if bestDistance >= -80 and bestDistance <= 40 then
		onBase = true
	end

	-- get the height of the terrain under the lander
	roundedGroundY = Cf.round(GROUND[roundedLanderX],0)

	-- check if lander is at or below the terrain
	-- the offset is the size of the lander image
	if lander.y > roundedGroundY - 8 then
		-- a heavy landing will cause damage
		checkForDamage(lander)
		-- Lander is on ground
		lander.onGround = true
		-- Stop x, y movement
		lander.vx = 0
		if lander.vy > 0 then
			lander.vy = 0
		end

		-- TODO: Move some of the fuel base logic to objects/base.lua
		if onBase and not lander.gameOver then
			refuelLander(lander, bestBase,dt)
			payLanderFromBase(lander, bestBase, bestDistance)
			-- pay the lander on first visit on the base
			-- this is the first landing on this base so pay money based on vertical and horizontal speed
			if not bestBase.paid then
				payLanderForControl(lander, bestBase)
				bestBase.paid = true
			-- check for game-over conditions
			elseif not bestBase.active and lander.fuel <= 1 then
				lander.gameOver = true
			end
		end
		-- check for game-over conditions
		if not onBase and lander.fuel <= 1 then
			lander.gameOver = true
		end
	else
		lander.onGround = false
	end
end



local function playSoundEffects(lander)
	if lander.engineOn then
		engineSound:play()
	else
		engineSound:stop()
	end

	local fuelPercent = lander.fuel / lander.fuelCapacity
	-- play alert if fuel is low (but not empty because that's just annoying)
	if fuelPercent <= 0.33 and fuelPercent > 0.01 then
		lowFuelSound:play()
	end
end



local function recalcDefaultMass(lander)
	local result = 0
	-- all the masses are stored in this table so add them up
	for i = 1, #lander.mass do
		result = result + lander.mass[i]
	end
	-- return mass of all the components + mass of fuel
	return (result + lander.fuelCapacity)
end



local function buyModule(module, lander)
	-- Enough money to purchase the module ?
	if lander.money >= module.cost then
		for i = 1, #lander.modules do
			if lander.modules[i] == module then
				-- this module is already purchased
				failSound:play()
				return
			end
		end

		-- TODO: Switch this temporary solution to something more dynamic
		if module.fuelCapacity then
			if module.fuelCapacity > lander.fuelCapacity then
				lander.fuelCapacity = module.fuelCapacity
			else
				-- Downgrading wouldn't be that fun
				return
			end
		end

		-- can purchase this module
		table.insert(lander.modules, module)
		-- pay for it
		lander.money = lander.money - module.cost
		-- add and calculate new mass
		lander.mass[#lander.mass+1] = module.mass
		DEFAULT_MASS = recalcDefaultMass(lander)
	else
		-- play 'failed' sound
		failSound:play()
	end
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Lander.create(name)
	-- create a lander and return it to the calling sub
	local lander = {}
	lander.x = Cf.round(ORIGIN_X,0)
	lander.y = GROUND[lander.x] - 8
	lander.connectionID = nil	-- used by enet
	-- 270 = up
	lander.angle = 270
	lander.vx = 0
	lander.vy = 0
	lander.engineOn = false
	lander.leftEngineOn = false
	lander.rightEngineOn = false
	lander.onGround = false
	-- Health in percent
	lander.health = 100
	lander.money = 0
	lander.gameOver = false
	lander.score = lander.x - ORIGIN_X
	lander.name = name or CURRENT_PLAYER_NAME

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



function Lander.reset(lander)
-- resets a single lander. Used in multiplayer mode when you don't want to reset every lander.
-- this function largely follows same behaviour as the CREATE function

	lander.x = Cf.round(ORIGIN_X,0)
	lander.y = GROUND[lander.x] - 8
	-- lander.connectionID = nil	-- used by enet
	-- 270 = up
	lander.angle = 270
	lander.vx = 0
	lander.vy = 0
	lander.engineOn = false
	lander.leftEngineOn = false
	lander.rightEngineOn = false
	lander.onGround = false
	-- Health in percent
	lander.health = 100
	lander.money = 0
	lander.gameOver = false
	lander.score = lander.x - ORIGIN_X
	-- lander.name = name or CURRENT_PLAYER_NAME

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

    local baseDistance, _ = Fun.GetDistanceToClosestBase(lander.x, baseId)
    if baseDistance >= -80 and baseDistance <= 40 then
        return true
    else
        return false
    end
end



function Lander.hasUpgrade(lander, module)
	for i = 1, #lander.modules do
		if lander.modules[i] == module then
			return true
		end
	end
	return false
end



local function updateScore(lander)
-- updates the lander score that is saved in the lander table
-- this is the same as functions.CalculateScore(). Intention is to deprecate and remove that function and use this.
-- this procedure does not return the score. It updates the lander table
	
	lander.score = lander.x - ORIGIN_X

	if lander.score > GAME_SETTINGS.HighScore then
		GAME_SETTINGS.HighScore = lander.score
		Fun.SaveGameSettings() -- this needs to be refactored somehow, not save every change
	end
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

	-- TODO: Calculate the offset so that it doesn't need to be global
	-- Calculate worldOffset for everyone based on lander x position
	WORLD_OFFSET = Cf.round(lander.x) - ORIGIN_X
	-- Reset angle if > 360 degree
	if math.max(lander.angle) > 360 then lander.angle = 0 end
	-- Update ship
    moveShip(lander, dt)
    playSoundEffects(lander)
    checkForContact(lander, dt)
assert(GAME_SETTINGS.HighScore ~= nil)
	updateScore(lander)
assert(GAME_SETTINGS.HighScore ~= nil)	
	
end



function Lander.draw()
	-- draw the lander and flame
	for landerId, lander in pairs(LANDERS) do
		local sx, sy = 1.5, 1.5

		assert(lander.x ~= nil)

		local x = lander.x - WORLD_OFFSET
		local y = lander.y
		local ox = ship.width / 2
		local oy = ship.height / 2

		-- fade other landers in multiplayer mode
		if landerId == 1 then
			love.graphics.setColor(1,1,1,1)
		else
			love.graphics.setColor(1,1,1,0.5)
		end

		-- TODO: work out why ship.width doesn't work in mplayer mode
		love.graphics.draw(ship.image, x,y, math.rad(lander.angle), sx, sy, ox, oy)

		-- draw flames
		local ox = flame.width / 2
		local oy = flame.height / 2
		if lander.engineOn then
			local angle = math.rad(lander.angle)
			love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
			lander.engineOn = false
		end
		if lander.leftEngineOn then
			local angle = math.rad(lander.angle + 90)
			love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
			lander.leftEngineOn = false
		end
		if lander.rightEngineOn then
			local angle = math.rad(lander.angle - 90)
			love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
			lander.rightEngineOn = false
		end

		-- draw label
		love.graphics.setNewFont(10)
		love.graphics.print(lander.name, x + 14, y - 10)
		love.graphics.setColor(1,1,1,1)
	end
end



function Lander.keypressed(key, scancode, isrepeat)
	-- Let the player buy upgrades when landed on a fuel base
	local lander = LANDERS[1]
	-- 2 = base type (fuel)
	if Lander.isOnLandingPad(lander, 2) then
		-- Iterate all available modules
		for _, module in pairs(Modules) do
			-- Press key assigned to the module by its id
			if key == tostring(module.id) then
				buyModule(module, lander)
			end
		end
	end
end


return Lander
