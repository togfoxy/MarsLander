
-- ~~~~~~~~~~~~
-- Lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}

-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

function Lander.DoThrust(landerObj, dt)

-- print(landerObj.fuel)
-- print(Lander.hasUpgrade(landerObj, enum.moduleNamesThrusters))

	if landerObj.fuel - dt >= 0 or (Lander.hasUpgrade(landerObj, enum.moduleNamesThrusters) and landerObj.fuel - (dt * 0.80) >= 0) then

		landerObj.engineOn = true
		local angle_radian = math.rad(landerObj.angle)
		local force_x = math.cos(angle_radian) * dt
		local force_y = math.sin(angle_radian) * dt
		
		-- adjust the thrust based on ship mass
		local massratio = gintDefaultMass / Lander.getMass(landerObj)	-- less mass = higher ratio = more thrust = less fuel needed to move
		garrMassRatio = massratio		-- for debugging only
		force_x = force_x * massratio
		force_y = force_y * massratio

		landerObj.vx = landerObj.vx + force_x
		landerObj.vy = landerObj.vy + force_y

		if Lander.hasUpgrade(landerObj, enum.moduleNamesThrusters) then
			landerObj.fuel = landerObj.fuel - (dt * 0.80)		-- efficient thrusters use 80% fuel compared to normal thrusters
		else
			landerObj.fuel = landerObj.fuel - (dt * 1)
		end
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
print("no fuel")
	end
end

function Lander.TurnLeft(landerObj, dt)
-- rotate the lander anti-clockwise

	landerObj.angle = landerObj.angle - (90 * dt)
	if landerObj.angle < 0 then landerObj.angle = 360 end
end

function Lander.TurnRight(landerObj, dt)
-- rotate the lander clockwise

	landerObj.angle = landerObj.angle + (90 * dt)
	if landerObj.angle > 360 then landerObj.angle = 0 end

end

function Lander.ThrustLeft(landerObj, dt)

	if Lander.hasUpgrade(landerObj, enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		landerObj.vx = landerObj.vx - force_x
		landerObj.enginerighton = true						-- opposite engine is on
		
		landerObj.fuel = landerObj.fuel - force_x
	end
end

function Lander.ThrustRight(landerObj, dt)

	if Lander.hasUpgrade(landerObj, enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		landerObj.vx = landerObj.vx + force_x
		landerObj.enginelefton = true						-- opposite engine is on
		
		landerObj.fuel = landerObj.fuel - force_x
	end

end

function Lander.MoveShip(landerObj, dt)

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
	gfltSmokeTimer = gfltSmokeTimer - dt		--! The AI bit make this fail for some reason
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

local function RefuelLander(landerObj, objBase, bolIsPlayerVessel, dt)
-- drain fuel from the base and add it to the lander
-- objBase is an object/table item from garrObjects

	if bolIsPlayerVessel then
		local refuelamt = math.min(objBase.fuelqty, (landerObj.fueltanksize - landerObj.fuel), dt)

		objBase.fuelqty = objBase.fuelqty - refuelamt
		landerObj.fuel = landerObj.fuel + refuelamt
		
		-- disable the base if the tanks are empty
		if objBase.fuelqty <= 0 then objBase.active = false end
	else
		local refuelamt = math.min((landerObj.fueltanksize - landerObj.fuel), dt)
		landerObj.fuel = landerObj.fuel + refuelamt
	end
end

local function PayLanderFromBase(landerObj, objBase, fltDist)
-- pay some wealth based on distance to the base
-- objBase is an object/table item from garrObjects
-- fltDist is the distance from the base

	local dist = math.abs(fltDist)
	if objBase.paid == false then
		landerObj.wealth = cf.round(landerObj.wealth + (100 - dist),0)
		garrSound[4]:play()
	end

end

local function PayLanderForControl(landerObj, objBase)

	if objBase.paid == false then
		-- pay for a good vertical speed
		landerObj.wealth = cf.round(landerObj.wealth + ((1 - gfltLandervy) * 100),0)
		
		-- pay for a good horizontal speed
		landerObj.wealth = cf.round(landerObj.wealth + (0.60 - gfltLandervx * 100),0)
		
	end
end

local function CheckForDamage(landerObj)
-- apply damage if vertical speed is too higher
	
	if landerObj.vy > enum.constVYThreshold then
		local excessspeed = landerObj.vy - enum.constVYThreshold
		landerObj.health = landerObj.health - (excessspeed * 100)
	
		if landerObj.health < 0 then landerObj.health = 0 end
	end

end

function Lander.CheckForContact(landerObj, bolIsPlayerVessel, dt)
-- see if lander has contacted the ground

	local LanderXValue = cf.round(landerObj.x)
	local groundYvalue
	local onbase = Lander.isOnLandingPad(landerObj, enum.basetypeFuel)

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
	if landerObj.y > groundYvalue - enum.constLanderImageYOffset then		-- the offset is the size of the lander image
		landerObj.landed = true

		if onbase then
			RefuelLander(landerObj, bestbase, bolIsPlayerVessel, dt)
			
			if bolIsPlayerVessel then
				PayLanderFromBase(landerObj, bestbase, bestdist)
			end
			
			-- if lander was airborne then track that now it's not.
			if landerObj.airborne and bolIsPlayerVessel then
				-- this is the first landing on this base so pay wealth based on vertical and horizontal speed
				PayLanderForControl(landerObj, bestbase)
				bestbase.paid = true
			end				
		end
		
		if landerObj.airborne then
			-- a heavy landing will cause damage
			CheckForDamage(landerObj)
			
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

local function PlaySoundEffects(landerObj)

	if landerObj.engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
	end
	
	local fuelpercent = landerObj.fuel / landerObj.fueltanksize
	
	-- play alert if fuel is low (but not empty because that's just annoying)
	if fuelpercent <= 0.33 and fuelpercent > 0.01 then		-- 1% because rounding (fuel is never actually zero)
		garrSound[5]:play()
	end
end

local function RecalcDefaultMass(landerObj)
-- need to recalc the default mass
-- usually called after buying a module
		local result = 0
		-- all the masses are stored in this table so add them up
		for i = 1, #landerObj.mass do
			result = result + landerObj.mass[i]
		end
		return (result + landerObj.fueltanksize)		-- mass of all the components + mass of fuel if the tank was full (i.e. fueltanksize)

end

local function PurchaseThrusters(landerObj)
-- add fuel efficient thrusters to the lander

	if landerObj.wealth >= enum.moduleCostsThrusters then
		for i = 1, #landerObj.modules do
			if landerObj.modules[i] == enum.moduleNamesThrusters then
				-- this module is already purchased. Abort
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase thrusters
		
		table.insert(landerObj.modules, enum.moduleNamesThrusters)
		landerObj.wealth = landerObj.wealth - enum.moduleCostsThrusters
		
		landerObj.mass[1] = 115
		
		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass(landerObj)
	else
		-- play 'failed' sound
		garrSound[6]:play()
	end
end

local function PurchaseLargeTank(landerObj)
-- add a larger tank to carry more fuelqty

	if landerObj.wealth >= enum.moduleCostsLargeTank then
		for i = 1, #landerObj.modules do
			if landerObj.modules[i] == enum.moduleNamesLargeTank then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase item
		
		table.insert(landerObj.modules, enum.moduleNamesLargeTank)
		landerObj.wealth = landerObj.wealth - enum.moduleCostsLargeTank
		
		landerObj.fueltanksize = 32		-- an increase from the default (25)
		landerObj.mass[2] = 23
		
		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass(landerObj)
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end

end

local function PurchaseRangeFinder(landerObj)
-- the rangefinder points to the nearest base

	if landerObj.wealth >= enum.moduleCostsRangeFinder then
		for i = 1, #landerObj.modules do
			if landerObj.modules[i] == enum.moduleNamesRangeFinder then
				-- this module is already purchased. Abort.
				--! make a 'wrong' sound		
				return
			end
		end
		-- can purchase item
		
		table.insert(landerObj.modules, enum.moduleNamesRangeFinder)
		landerObj.wealth = landerObj.wealth - enum.moduleCostsRangeFinder

		landerObj.mass[3] = 2	-- this is the mass of the rangefinder

		-- need to recalc the default mass
		gintDefaultMass = RecalcDefaultMass(landerObj)		
	else
		-- play 'failed' sound
		garrSound[6]:play()		
	end

end

local function PurchaseSideThrusters(landerObj)

	if landerObj.wealth >= enum.moduleCostSideThrusters then
		if not Lander.hasUpgrade(landerObj, enum.moduleNamesSideThrusters) then
			table.insert(landerObj.modules, enum.moduleNamesSideThrusters)
			landerObj.wealth = landerObj.wealth - enum.moduleCostSideThrusters

			landerObj.mass[4] = enum.moduleMassSideThrusters	-- this is the mass of the side thrusters

			-- need to recalc the default mass
			gintDefaultMass = RecalcDefaultMass(landerObj)	
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

    local landerObj = {}
    landerObj.x = gintOriginX
    landerObj.y = 500
    landerObj.y = garrGround[landerObj.x] - 8
    landerObj.angle = 270		-- 270 = up
	landerObj.preferredangle = 270
	landerObj.preferredthrust = true
    landerObj.vx = 0
    landerObj.vy = 0
    landerObj.engineOn = false
    landerObj.enginelefton = false
    landerObj.enginerighton = false
    landerObj.landed = false			-- true = on the ground
    landerObj.airborne = false			-- false = on the ground FOR THE FIRST TIME
    landerObj.wealth = 0
    landerObj.health = 100				-- this is % meaning 100 = no damage
    landerObj.bolGameOver = false
	landerObj.score = landerObj.x - gintOriginX
    landerObj.name = gstrCurrentPlayerName	
    
    -- mass	
    landerObj.mass = {}
    table.insert(landerObj.mass, 100)	-- base mass of lander

    landerObj.fueltanksize = 25		-- volume in arbitrary units
    landerObj.fuel = landerObj.fueltanksize	-- start with a full tank
    table.insert(landerObj.mass, 20)	-- this is the mass of an empty tank
    table.insert(landerObj.mass, 0)	-- this is the mass of the rangefinder (not yet purchased)
    
    -- modules
    landerObj.modules = {}		-- this will be strings/names of modules
	
	landerObj.aitimer = 1
    
    return landerObj

end

function Lander.getMass(landerObj)
-- return the mass of all the bits on the lander

    local result = 0

    -- all the masses are stored in this table so add them up
    for i = 1, #landerObj.mass do
        result = result + landerObj.mass[i]
    end
    
    -- add the mass of the fuel
    result = result + landerObj.fuel
    
    return result
end

function Lander.isOnLandingPad(landerObj, intBaseType)
-- returns a true / false value

    local mydist, _ = fun.GetDistanceToClosestBase(landerObj.x, intBaseType)
    if mydist >= -80 and mydist <= 40 then
        return true
    else
        return false
    end
end

function Lander.hasUpgrade(landerObj, strModuleName)

	for i = 1, #landerObj.modules do
		if landerObj.modules[i] == strModuleName then
			return true
		end
	end
	return false
end

function Lander.GetLastNextBaseID(landerObj, intBaseType)
-- return the index of the most recently passed base + the next based

	local previousid = 0		-- table index of the base the lander just passed
	local nextid = 1			
	
	for k,v in pairs(garrObjects) do
		if v.objecttype == intBaseType then
			if v.x < landerObj.x then
				previousid = k
			else
				previousid = k - 1
				nextid = k
				return previousid, nextid
			end
		end
	end

end

function Lander.update(dt)

    if love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("kp8") then
        Lander.DoThrust(garrLanders[1], dt)
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") or love.keyboard.isDown("kp4") then
        Lander.TurnLeft(garrLanders[1], dt)
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") or love.keyboard.isDown("kp6") then
        Lander.TurnRight(garrLanders[1], dt)
    end
    if love.keyboard.isDown("q") or love.keyboard.isDown("kp7") then
        Lander.ThrustLeft(garrLanders[1], dt)
    end
    if love.keyboard.isDown("e") or love.keyboard.isDown("kp9") then
        Lander.ThrustRight(garrLanders[1], dt)
    end		
    if love.keyboard.isDown("p") then
        fun.AddScreen("Pause")
    end
    if love.keyboard.isDown("o") then
        fun.AddScreen("Settings")
    end

    Lander.MoveShip(garrLanders[1], dt)
    
    UpdateSmoke(dt)
    
    PlaySoundEffects(garrLanders[1])
    
    Lander.CheckForContact(garrLanders[1], true, dt)
	
	if #garrLanders < 2 then
		local newLander = {}
		newLander = Lander.create()
		newLander.name = "AI"
		newLander.aitimer = 1		--! make an enum later
		newLander.angle = 270
		newLander.preferredangle = 270
		newLander.preferredthrust = true
		newLander.previousydelta = 0
		table.insert(garrLanders, newLander)
	end	
	
	-- ai.DoAI(garrLanders[1], dt)
	ai.DoAI(garrLanders[2], dt)
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
	if Lander.isOnLandingPad(garrLanders[1], 2) then	-- 2 = base type (fuel)
		if key == "1" then			 
			PurchaseThrusters(garrLanders[1])
		end
	
		if key == "2" then			
			PurchaseLargeTank(garrLanders[1])
		end	
		
		if key == "3" then			
			PurchaseRangeFinder(garrLanders[1])
		end

		if key == "4" then			
			PurchaseSideThrusters(garrLanders[1])
		end		
	end
end


return Lander