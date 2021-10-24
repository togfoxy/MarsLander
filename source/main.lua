gstrGameVersion = "0.08"

inspect = require 'lib.inspect'
-- https://github.com/kikito/inspect.lua

TLfres = require "lib.tlfres"
-- https://love2d.org/wiki/TLfres

Slab = require 'lib.Slab.Slab'
-- https://github.com/coding-jackalope/Slab/wiki

bitser = require 'lib.bitser'
-- https://github.com/gvx/bitser

nativefs = require("lib.nativefs")
-- https://github.com/megagrump/nativefs

anim8 = require 'lib.anim8'
-- https://github.com/kikito/anim8

-- socket it native to LOVE2D
socket = require "socket"
-- https://love2d.org/wiki/Tutorial:Networking_with_UDP
-- http://w3.impa.br/~diego/software/luasocket/reference.html

lovelyToasts = require("lib.lovelyToasts")
-- https://github.com/Loucee/Lovely-Toasts

gintScreenWidth = 1024-- 1920
gintScreenHeight = 768-- 1080

garrCurrentScreen = {}	

cobjs = require "createobjects"
dobjs = require "drawobjects"
fun = require "functions"
cf = require "lib.commonfunctions"
menus = require "menus"
enum = require "enum"
ss = require "socketstuff"

garrLanders = {}	
garrGround = {}		-- stores the y value for the ground so that garrGround[Lander.x] = a value from 0 -> gintScreenHeight
garrObjects = {}	-- stores an object that needs to be drawn so that garrObjects[xvalue] = an object to be drawn on the ground
garrImages = {}
garrSprites = {}	-- spritesheets
garrSound = {}
garrMassRatio = 0			-- for debugging only. Records current mass/default mass ratio

gintOriginX = cf.round(gintScreenWidth / 2,0)	-- this is the start of the world and the origin that we track as we scroll the terrain left and right
gintDefaultMass = 220		-- this is the mass the lander starts with hence the mass the noob engines are tuned to

gfltLandervy = 0			-- track the vertical speed of lander to detect crashes etc
gfltLandervx = 0

-- socket stuff
gintServerPort = love.math.random(6000,6999)		-- this is the port each client needs to connect to
gbolIsAClient = false            	-- defaults to NOT a client until the player chooses to connect to a host
gbolIsAHost = false                -- Will listen on load but is not a host until someone connects

gbolDebug = true

local function DoThrust(dt)

	if garrLanders[1].fuel - dt >= 0 or (fun.LanderHasUpgrade(enum.moduleNamesThrusters) and garrLanders[1].fuel - (dt * 0.80) >= 0) then

		garrLanders[1].engineOn = true
		local angle_radian = math.rad(garrLanders[1].angle)
		local force_x = math.cos(angle_radian) * dt
		local force_y = math.sin(angle_radian) * dt
		
		-- adjust the thrust based on ship mass
		local massratio = gintDefaultMass / fun.GetLanderMass()	-- less mass = higher ratio = more thrust = less fuel needed to move
		if gbolDebug then garrMassRatio = massratio end			-- for debugging only
		force_x = force_x * massratio
		force_y = force_y * massratio

		garrLanders[1].vx = garrLanders[1].vx + force_x
		garrLanders[1].vy = garrLanders[1].vy + force_y

		if fun.LanderHasUpgrade(enum.moduleNamesThrusters) then
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

	if fun.LanderHasUpgrade(enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		garrLanders[1].vx = garrLanders[1].vx - force_x
		garrLanders[1].enginerighton = true						-- opposite engine is on
		
		garrLanders[1].fuel = garrLanders[1].fuel - force_x
	end
end

local function ThrustRight(dt)

	if fun.LanderHasUpgrade(enum.moduleNamesSideThrusters) then
		local force_x = 0.5 * dt		--!
		garrLanders[1].vx = garrLanders[1].vx + force_x
		garrLanders[1].enginelefton = true						-- opposite engine is on
		
		garrLanders[1].fuel = garrLanders[1].fuel - force_x
	end

end

local function MoveShip(Lander, dt)

	local myalt = Lander.y		-- need to capture vertical movement here and check it later on

	Lander.x = Lander.x + Lander.vx
	Lander.y = Lander.y + Lander.vy
	
	local leftedge = gintOriginX - (gintScreenWidth / 2)
	if Lander.x < leftedge then Lander.x = leftedge end
	
	-- apply gravity
	if Lander.landed == false then
		Lander.vy = Lander.vy + (0.6 * dt)
	end
	
	if Lander.airborne then
		gfltLandervy = Lander.vy		-- used to determine speed right before touchdown
		gfltLandervx = Lander.vx
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

local function CheckForContact(Lander,dt)
-- see if lander has contacted the ground

	local LanderXValue = cf.round(Lander.x)
	local groundYvalue
	
	Lander.landed = false
	
	if garrGround[LanderXValue] ~= nil then
		groundYvalue = cf.round(garrGround[LanderXValue],0)
	
		if Lander.y > groundYvalue - 8 then
			Lander.landed = true
	
			-- see if landed near a fuel base
			-- bestdist could be a negative number meaning not yet past the base (but maybe really close to it)
			local bestdist, bestbase = fun.GetDistanceToClosestBase(garrLanders[1].x, 2)		-- 2 = type of base = fuel

			-- bestbase is an object/table item
			-- add wealth based on alignment to centre of landing pad
			if bestdist >= -80 and bestdist <= 40 then
				RefuelLander(bestbase,dt)
				PayLanderFromBase(bestbase, bestdist)
				if Lander.airborne then
					Lander.airborne = false
					PayLanderForControl(bestbase)
				end				
				bestbase.paid = true
			end

			Lander.vx = 0
			if Lander.vy > 0 then Lander.vy = 0 end			
			
		else
			Lander.landed = false
			if Lander.airborne == false then
				Lander.airborne = true
			end
		end
	end
end

local function PlaySoundEffects()
--! aweful function name

	if garrLanders[1].engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
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
		
	end

end

local function PurchaseSideThrusters()

	if garrLanders[1].wealth >= enum.moduleCostSideThrusters then
		if not fun.LanderHasUpgrade(enum.moduleNamesSideThrusters) then
			table.insert(garrLanders[1].modules, enum.moduleNamesSideThrusters)
			garrLanders[1].wealth = garrLanders[1].wealth - enum.moduleCostSideThrusters

			garrLanders[1].mass[4] = enum.moduleMassSideThrusters	-- this is the mass of the side thrusters

			-- need to recalc the default mass
			gintDefaultMass = RecalcDefaultMass()	
		end
	end
end

local function HandleSockets()
	
	-- add lander info to the outgoing queue
	local msg = {}
	msg.x = garrLanders[1].x
	msg.y = garrLanders[1].y
	msg.angle = garrLanders[1].angle
	-- ** msg is set here and sent below
	
	if gbolIsAHost then
		ss.HostListenPort()
		
		-- get just one item from the queue and process it
		repeat
			local incoming = ss.GetItemInHostQueue()		-- could be nil
			if incoming ~= nil then

				garrLanders[2] = {}
				garrLanders[2].x = incoming.x
				garrLanders[2].y = incoming.y
				garrLanders[2].angle = incoming.angle
			end	
		until incoming == nil
			
		ss.AddItemToHostOutgoingQueue(msg)
		ss.SendToClients()
		msg = {}
	end
	
	if gbolIsAClient then
		ss.ClientListenPort()
		
		-- get just one item from the queue and process it
		repeat
			local incoming = ss.GetItemInClientQueue()		-- could be nil
			if incoming ~= nil then
				garrLanders[2] = {}
				garrLanders[2].x = incoming.x
				garrLanders[2].y = incoming.y
				garrLanders[2].angle = incoming.angle
			end
		until incoming == nil

		ss.AddItemToClientOutgoingQueue(msg)	-- Lander[1]
		ss.SendToHost()
		msg = {}
	end
		
end

function love.keypressed( key, scancode, isrepeat)
	if key == "escape" then
		fun.RemoveScreen()
	end
	
	if fun.IsOnLandingPad(2) then	-- 2 = base type (fuel)
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

function love.load()

    if love.filesystem.isFused( ) then
        void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=false,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
        gbolDebug = false
    else
        void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=false,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
    end
	
	love.window.setTitle("Mars Lander " .. gstrGameVersion)

	fun.AddScreen("MainMenu")
	-- fun.AddScreen("World")
	
	fun.InitialiseGround()

	-- create one lander and add it to the global array
	-- ** this needs to be called AFTER InitialiseGround()
	table.insert(garrLanders, cobjs.CreateLander())
	
	-- capture the 'normal' mass of the lander into a global variable
	gintDefaultMass = fun.GetLanderMass()
	
	-- stills/images
	--! should make these numbers enums one day
	garrImages[1] = love.graphics.newImage("/Assets/tower.png")
	garrImages[2] = love.graphics.newImage("/Assets/gastank1.png")
	garrImages[3] = love.graphics.newImage("/Assets/Background-4.png")
	garrImages[4] = love.graphics.newImage("/Assets/engine.png")
	garrImages[5] = love.graphics.newImage("/Assets/ship.png")
	garrImages[6] = love.graphics.newImage("/Assets/gastank1off.png")
	garrImages[7] = love.graphics.newImage("/Assets/building1.png")
	garrImages[8] = love.graphics.newImage("/Assets/building2.png")
	
	-- spritesheets and animations
	garrSprites[1] = love.graphics.newImage("Assets/landinglightsnew.png")
	gGridLandingLights = anim8.newGrid(64, 8, garrSprites[1]:getWidth(), garrSprites[1]:getHeight())     -- frame width, frame height
	gLandingLightsAnimation = anim8.newAnimation(gGridLandingLights(1,'1-4'), 0.5)		-- column 1, rows 1 -> 4
	
	
	garrSound[1] = love.audio.newSource("Assets/wind.wav", "static")
	garrSound[2] = love.audio.newSource("Assets/387232__steaq__badge-coin-win.wav", "static")
	garrSound[3] = love.audio.newSource("Assets/Galactic-Pole-Position.mp3", "stream")
	garrSound[3]:setVolume(0.25)
	garrSound[4] = love.audio.newSource("Assets/387232__steaq__badge-coin-win.wav", "static")
	
	-- fonts
	font20 = love.graphics.newFont(20) -- the number denotes the font size

	lovelyToasts.options.queueEnabled = true
	
	Slab.SetINIStatePath(nil)
	Slab.Initialize(args)
	
end

function love.draw()

	TLfres.beginRendering(gintScreenWidth,gintScreenHeight)
	
	local strCurrentScreen = garrCurrentScreen[#garrCurrentScreen]
	
	if strCurrentScreen == "MainMenu" then
		menus.DrawMainMenu()
	end
	
	if strCurrentScreen == "World" then
		dobjs.DrawWorld()
	end
	
	if strCurrentScreen == "Credits" then
		menus.DrawCredits()
	end	
		

	Slab.Draw()		--! can this be in an 'if' statement and not drawn if not on a SLAB screen?
	lovelyToasts.draw()		--* Put this AFTER the slab so that it draws over the slab
	TLfres.endRendering({0, 0, 0, 1})

end

function love.update(dt)

	if love.filesystem.isFused( ) then
		-- not played when in 'dev' mode to save my sanity
		garrSound[3]:play()
	end

	local strCurrentScreen = garrCurrentScreen[#garrCurrentScreen]
	
	if strCurrentScreen == "MainMenu" or strCurrentScreen == "Credits" then
		Slab.Update(dt)		--! should this be called only when the main menu is current?
	end
	
	if strCurrentScreen == "World" then

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
		
		
		MoveShip(garrLanders[1], dt)
		
		PlaySoundEffects()
		
		CheckForContact(garrLanders[1], dt)
		
		gLandingLightsAnimation:update(dt)
		
		HandleSockets()
	end
	
	lovelyToasts.update(dt)

end












