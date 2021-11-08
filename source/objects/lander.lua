
-- ~~~~~~~~~~~~
-- lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}


-- ~~~~~~~~~~~~~
-- Dependencies
-- ~~~~~~~~~~~~~

local modules = require "scripts.modules"



-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

local keyDown = love.keyboard.isDown



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function doThrust(lander, dt)
	local hasThrusterUpgrade = Lander.hasUpgrade(lander, modules.thrusters)
	if lander.fuel - dt >= 0 or (hasThrusterUpgrade and lander.fuel - (dt * 0.80) >= 0) then
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
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
	end
end



local function thrustLeft(lander, dt)
	if Lander.hasUpgrade(lander, modules.sideThrusters) then
		local forceX = 0.5 * dt		--!
		lander.vx = lander.vx - forceX
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - forceX
	end
end



local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, modules.sideThrusters) then
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
	if lander.x < gintOriginX - (gintScreenWidth / 2) then
		lander.vx = 0
		lander.x =  gintOriginX - (gintScreenWidth / 2)
	end

	if not lander.onGround then
		-- apply gravity
		lander.vy = lander.vy + (enum.constGravity * dt)
		-- used to determine speed right before touchdown
		gfltLandervy = lander.vy
		gfltLandervx = lander.vx
	end

	-- TODO: Smoke related stuff should be in it's own local function
	-- capture a new smoke location every x seconds
	gfltSmokeTimer = gfltSmokeTimer - dt

	if gfltSmokeTimer <= 0 then
		-- only produce smoke when the engines are firing
		if (lander.engineOn or lander.leftEngineOn or lander.rightEngineOn) then
			local smoke = {}
			smoke.x = lander.x
			smoke.y = lander.y
			-- a new 'puff' is added when this timer expires (and above conditions are met)
			gfltSmokeTimer = enum.constSmokeTimer
			-- this timer will count up and determine which sprite to display
			smoke.dt = 0
			table.insert(garrSmokeSprites, smoke)
		end
	end
end



local function refuelLander(lander, base, dt)
	-- drain fuel from the base and add it to the lander
	-- base is an object/table item from garrObjects
	local refuelAmount = math.min(base.totalFuel, (lander.fuelCapacity - lander.fuel), dt)
	base.totalFuel	= base.totalFuel - refuelAmount
	lander.fuel		= lander.fuel + refuelAmount
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
	-- FIXME: Health isn't calculated. Possibly caused by removing airborne variable.
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

	-- see if onGround near a fuel base
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
		-- a heavy landing will cause damage
		checkForDamage(lander)
		-- Lander is on ground
		lander.onGround = true
		-- Stop x, y movement
		lander.vx = 0
		if lander.vy > 0 then
			lander.vy = 0
		end

		if onBase and not lander.gameOver then
			refuelLander(lander, bestBase,dt)
			payLanderFromBase(lander, bestBase, bestDistance)
			-- pay the lander on first visit on the base
			if not bestBase.paid then
				-- this is the first landing on this base so pay money based on vertical and horizontal speed
				payLanderForControl(lander, bestBase)
				bestBase.paid = true
			end
		end

		-- check for game-over conditions
		if lander.fuel <= 1 and not onBase then
			lander.gameOver = true
		end
	else
		lander.onGround = false
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
	if fuelPercent <= 0.33 and fuelPercent > 0.01 then
		garrSound[5]:play()
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
				-- this module is already purchased. Abort
				--! make a 'wrong' sound
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
		gintDefaultMass = recalcDefaultMass(lander)
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
	--lander.sprite = garrImages[5]
	--lander.width = lander.sprite:getWidth()
	--lander.height = lander.sprite:getHeight()
	
	lander.spriteenum = enum.imageShip
	lander.width = garrImages[lander.spriteenum]:getWidth()
	lander.height = garrImages[lander.spriteenum]:getHeight()

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



function Lander.hasUpgrade(lander, module)
	for i = 1, #lander.modules do
		if lander.modules[i] == module then
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

	if keyDown("o") then
        fun.AddScreen("Settings")
    end

	-- Reset angle if > 360 degree
	if math.max(lander.angle) > 360 then lander.angle = 0 end
	
	-- Update ship
    moveShip(lander, dt)
    updateSmoke(dt)
    playSoundEffects(lander)
    checkForContact(lander, dt)
end



function Lander.draw(worldOffset)
	-- draw the lander and flame
	for landerId, lander in pairs(garrLanders) do
		local sx, sy = 1.5, 1.5
		local drawingX = lander.x - worldOffset
		local drawingY = lander.y

		-- fade other landers in multiplayer mode
		if landerId == 1 then
			love.graphics.setColor(1,1,1,1)
		else
			love.graphics.setColor(1,1,1,0.5)
		end

		-- TODO: work out why lander.width doesn't work in mplayer mode
		local ox = lander.width / 2
		local oy = lander.height / 2
		
		love.graphics.draw(garrImages[5], drawingX,drawingY, math.rad(lander.angle), sx, sy, ox, oy)


		--[[
			TODO:
			It would be better to avoid creating variables every tick. This will likely
			resolve itself with more code improvements.
			As a quick & dirty solution we could create the variables at the top of this
			file and just use them here without the local keyword.
		--]]
		-- draw flames
		local flameSprite	= garrImages[enum.imageFlameSprite]
		local flameWidth	= flameSprite:getWidth()
		local flameHeight	= flameSprite:getHeight()
		local ox 			= flameWidth / 2
		local oy 			= flameHeight / 2

		if lander.engineOn then
			local angle = math.rad(lander.angle)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, sx, sy, ox, oy)
			lander.engineOn = false
		end
		if lander.leftEngineOn then
			local angle = math.rad(lander.angle + 90)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, sx, sy, ox, oy)
			lander.leftEngineOn = false
		end
		if lander.rightEngineOn then
			local angle = math.rad(lander.angle - 90)
			love.graphics.draw(flameSprite, drawingX, drawingY, angle, sx, sy, ox, oy)
			lander.rightEngineOn = false
		end

		-- draw smoke trail
		for _, smoke in pairs(garrSmokeSprites) do
			-- TODO: Smoke related stuff should be in it's own local function
			local drawingX = smoke.x - worldOffset
			local drawingY = smoke.y
			local spriteId = cf.round(smoke.dt)
			if spriteId < 1 then spriteId = 1 end
			--[[ TODO: currently the sprite rotates around it's top left corner and kinda works visually because of the way
				 the frames of the animation are drawn in the actual image file.
				 It would be better to rotate around a center point of the frame and then adjust the position of the
				 sprite to be fixed at a certain location. Some adjustments to the sprite itself might be nessecary.
			--]]
			-- not sure why the smoke sprite needs to be rotate +135. Suspect the image is drawn wrong. This works but!
			love.graphics.draw(gSmokeSheet,gSmokeImages[spriteId], drawingX, drawingY, math.rad(lander.angle + 135))
		end

		-- draw label
		love.graphics.setNewFont(10)
		local offsetX, offsetY = 14, 10
		love.graphics.print(lander.name, drawingX + offsetX, drawingY - offsetY)
		love.graphics.setColor(1,1,1,1)
	end
end



function Lander.keypressed(key, scancode, isrepeat)
	-- Let the player buy upgrades when landed on a fuel base
	local lander = garrLanders[1]
	-- 2 = base type (fuel)
	if Lander.isOnLandingPad(lander, 2) then
		-- Iterate all available modules
		for _, module in pairs(modules) do
			-- Press key assigned to the module by its id
			if key == tostring(module.id) then
				buyModule(module, lander)
			end
		end
	end
end


return Lander
