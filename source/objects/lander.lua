
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
local ship = Assets.getImageSet("newship")
local shipImage = {}
shipImage[1] = Assets.getImageSet("newship1")
shipImage[2] = Assets.getImageSet("newship2")
shipImage[3] = Assets.getImageSet("newship3")
shipImage[4] = Assets.getImageSet("newship4")
shipImage[5] = Assets.getImageSet("newship5")

local flame = Assets.getImageSet("flame")
local parachute = Assets.getImageSet("parachute")

local landingSound = Assets.getSound("landingSuccess")
local failSound = Assets.getSound("wrong")
local lowFuelSound = Assets.getSound("lowFuel")
local engineSound = Assets.getSound("engine")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~



local function recalcDefaultMass(lander)
	local result = 0
	-- all the masses are stored in this table so add them up
	for i = 1, #lander.mass do
		result = result + lander.mass[i]
	end
	-- return mass of all the components + mass of fuel
	return (result + lander.fuelCapacity)
end



local function landerHasFuelToThrust(lander, dt)
-- returns true if the lander has enough fuel for thrust
-- returns false if not enough fuel to thrust
-- Note: fuel can be > 0 but still not enough to thrust

	local hasThrusterUpgrade = Lander.hasUpgrade(lander, Modules.thrusters)
	if (lander.fuel - dt) >= 0 or (hasThrusterUpgrade and (lander.fuel - (dt * 0.80)) >= 0) then
		return true
	else
		return false
	end
end



local function parachuteIsDeployed(lander)
-- return true if lander has a parachute and it is deployed

	for _, moduleItem in pairs(lander.modules) do
		if moduleItem.id == Enum.moduleParachute then
			if moduleItem.deployed then
				return true
			end
		end
	end
	return false
end



local function deployParachute(lander)
-- sets the 'deployed' status of parachute
-- assumes the lander has a parachute

	for _, moduleItem in pairs(lander.modules) do
		if moduleItem.id == Enum.moduleParachute then
			moduleItem.deployed = true
			break
		end
	end
end



local function doThrust(lander, dt)
	local hasThrusterUpgrade = Lander.hasUpgrade(lander, Modules.thrusters)
	if landerHasFuelToThrust(lander, dt) then
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
-- TODO: consider the side thrusters moving left/right based on angle and not just movement on the X axis.
	if Lander.hasUpgrade(lander, Modules.sideThrusters) and landerHasFuelToThrust(lander, dt) then
		local forceX = 0.5 * dt
		lander.vx = lander.vx - forceX
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - forceX
	end

	-- if trying to side thrust and has parachute and descending and on the screen then ...
	if Lander.hasUpgrade(lander, Modules.parachute) and not landerHasFuelToThrust(lander, dt) then
		if lander.vy > 0 and lander.y > 15 then		-- 15 is enough to clear the fuel gauge
			-- parachutes allow left/right drifting even if no fuel and thrusters available
			deployParachute(lander)
			local forceX = 0.5 * dt
			lander.vx = lander.vx - forceX
		end
	end
end



local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, Modules.sideThrusters) and landerHasFuelToThrust(lander, dt) then
		local forceX = 0.5 * dt
		lander.vx	= lander.vx + forceX
		lander.fuel = lander.fuel - forceX
		-- opposite engine is on
		lander.leftEngineOn = true
	end

	-- if trying to side thrust and has parachute and descending and on the screen then ...
	if Lander.hasUpgrade(lander, Modules.parachute) and not landerHasFuelToThrust(lander, dt) then
		if lander.vy > 0 and lander.y > 15 then		-- 15 is enough to clear the fuel gauge
			deployParachute(lander)
			local forceX = 0.5 * dt
			lander.vx = lander.vx + forceX
		end
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

		-- parachutes slow descent
		if parachuteIsDeployed(lander) and lander.vy > 0.5 then
			lander.vy = 0.5
		end

		-- used to determine speed right before touchdown
		LANDER_VY = lander.vy
		LANDER_VX = lander.vx
	end
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

		if GAME_CONFIG.easyMode and lander.money < 0 then
			lander.money = 0
		end
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
	local bestDistance, bestBase = Fun.GetDistanceToClosestBase(lander.x, Enum.basetypeFuel)
	-- bestBase is an object/table item
	-- add money based on alignment to centre of landing pad
	if bestDistance >= -80 and bestDistance <= 40 then
		onBase = true
	end

	-- get the height of the terrain under the lander
	roundedGroundY = Cf.round(GROUND[roundedLanderX],0)

	-- check if lander is at or below the terrain
	-- the offset is the size of the lander image
	if lander.y > roundedGroundY - ship.image:getHeight() then		-- 8 = the image offset for visual effect
		-- a heavy landing will cause damage
		checkForDamage(lander)

		if not lander.onGround then

			-- destroy the single use parachute
			if parachuteIsDeployed(lander) then
				-- need to destroy this single-use module
				local moduleIndexToDestroy = 0
				for moduleIndex, moduleItem in pairs(lander.modules) do
					if moduleItem.id == 5 and moduleItem.deployed then	-- 5 = parachute
						moduleIndexToDestroy = moduleIndex
						moduleItem.deployed = false
						break
					end
				end
				assert(moduleIndexToDestroy > 0)
				table.remove(lander.modules, moduleIndexToDestroy)
				-- adjust new mass
				DEFAULT_MASS = recalcDefaultMass(lander)
			end
		end

		-- NOTE: if you need to check things on first contact with terrain (like receiving damage) then place
		-- that code above lander.onGround = true

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



local function buyModule(module, lander)
	-- Enough money to purchase the module ?
	if module.allowed == nil or module.allowed == true then
		if lander.money >= module.cost then
			if Lander.hasUpgrade(lander, module) then
				-- this module is already purchased
				failSound:play()
				return
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
end



local function altitude(lander)
-- returns the lander's distance above the ground
	local landerYValue = lander.y
	local groundYValue = GROUND[Cf.round(lander.x,0)]
	return groundYValue - landerYValue
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
	updateScore(lander)
end



function Lander.draw()
	-- draw the lander and flame
	for landerId, lander in pairs(LANDERS) do
		-- guard against connecting mplayer clients not having complete data
		if landerId == 1 or lander.x ~= nil then
			local sx, sy = 1.5, 1.5
			local x = lander.x - WORLD_OFFSET
			local y = lander.y
			local ox = shipImage[1].image:getWidth() / 2
			local oy = shipImage[1].image:getHeight() / 2

			-- fade other landers in multiplayer mode
			if landerId == 1 then
				love.graphics.setColor(1,1,1,1)
			else
				love.graphics.setColor(1,1,1,0.5)
			end

			-- draw parachute before drawing the lander
			if parachuteIsDeployed(lander) then
				local parachuteYOffset = y - parachute.image:getHeight()
				local parachuteXOffset = x - parachute.image:getWidth() / 2
				love.graphics.draw(parachute.image, parachuteXOffset, parachuteYOffset)
			end

			-- draw the legs based on distance above the ground (altitude)
			local landerAltitude = altitude(lander)
			local drawImage
			if landerAltitude < 15 then
				drawImage = shipImage[5]
			elseif landerAltitude < 25 then
				drawImage = shipImage[4]
			elseif landerAltitude < 35 then
				drawImage = shipImage[3]
			elseif landerAltitude < 45 then
				drawImage = shipImage[2]
			else
				drawImage = shipImage[1]
			end

			-- TODO: work out why ship.width doesn't work in mplayer mode
			--love.graphics.draw(ship.image, x,y, math.rad(lander.angle), sx, sy, ox, oy)
			love.graphics.draw(drawImage.image, x,y, math.rad(lander.angle), sx, sy, ox, oy)

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
end



function Lander.keypressed(key, scancode, isrepeat)
	-- Let the player buy upgrades when landed on a fuel base
	local lander = LANDERS[1]

	if Lander.isOnLandingPad(lander, Enum.basetypeFuel) then
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
