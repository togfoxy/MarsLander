gstrGameVersion = "0.10"

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

-- gintScreenWidth = 1920
-- gintScreenHeight = 1080

gintScreenWidth = 1024-- 1920
gintScreenHeight = 768-- 1080

garrCurrentScreen = {}	

Lander = require("lander")
Terrain = require("terrain")

cobjs = require "createobjects"
dobjs = require "drawobjects"
fun = require "functions"
cf = require "lib.commonfunctions"
menus = require "menus"
enum = require "enum"
ss = require "socketstuff"

garrLanders = {}	
garrGround = {}				-- stores the y value for the ground so that garrGround[Lander.x] = a value from 0 -> gintScreenHeight
garrObjects = {}			-- stores an object that needs to be drawn so that garrObjects[xvalue] = an object to be drawn on the ground
garrImages = {}
garrSprites = {}			-- spritesheets for landing lights
garrSound = {}
garrMassRatio = 0			-- for debugging only. Records current mass/default mass ratio
garrSmokeSprites = {}		-- used to track and draw smoke animations
garrGameSettings = {}		-- track game settings

gintOriginX = cf.round(gintScreenWidth / 2,0)	-- this is the start of the world and the origin that we track as we scroll the terrain left and right
gintDefaultMass = 220		-- this is the mass the lander starts with hence the mass the noob engines are tuned to

gfltLandervy = 0			-- track the vertical speed of lander to detect crashes etc
gfltLandervx = 0
gfltSmokeTimer = enum.constSmokeTimer			-- track how often to capture smoke trail

gstrDefaultPlayerName = 'Player Name'
gstrCurrentPlayerName = gstrDefaultPlayerName

-- socket stuff
gstrServerIP = nil					-- server's IP address
gintServerPort = love.math.random(6000,6999)		-- this is the port each client needs to connect to
gstrClientIP = nil
gintClientPort = nil
gbolIsAClient = false            	-- defaults to NOT a client until the player chooses to connect to a host
gbolIsAHost = false                -- Will listen on load but is not a host until someone connects
gbolIsConnected = false			-- Will become true when received an acknowledgement from the server

gbolDebug = true

function love.keypressed(key, scancode, isrepeat)
--! don't like how there are keypressed events here as well as in love.update
	if key == "escape" then
		fun.RemoveScreen()
	end

	Lander.keypressed(key, scancode, isrepeat)

	if key == "r" then
		if garrLanders[1].bolGameOver then
			fun.ResetGame()
		end
	end

end

function love.load()

    if love.filesystem.isFused( ) then
        void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=true,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
        gbolDebug = false
    else
		void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=false,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
    end
	
	love.window.setTitle("Mars Lander " .. gstrGameVersion)

	fun.LoadGameSettings()
	love.window.setFullscreen(garrGameSettings.FullScreen) -- Restore full screen setting
	
	fun.AddScreen("MainMenu")
	fun.ResetGame()
	
	-- capture the 'normal' mass of the lander into a global variable
	gintDefaultMass = Lander.getMass(garrLanders[1])

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
	garrImages[9] = love.graphics.newImage("/Assets/apollo-11-clipart-9.png")
	
	-- spritesheets and animations
	garrSprites[1] = love.graphics.newImage("Assets/landinglightsnew.png")
	gGridLandingLights = anim8.newGrid(64, 8, garrSprites[1]:getWidth(), garrSprites[1]:getHeight())     -- frame width, frame height
	gLandingLightsAnimation = anim8.newAnimation(gGridLandingLights(1,'1-4'), 0.5)		-- column 1, rows 1 -> 4
	
	gSmokeSheet = love.graphics.newImage("Assets/smoke.png")
	gSmokeImages = cf.fromImageToQuads(gSmokeSheet, 30, 30)		-- w/h of each frame
	
	garrSound[1] = love.audio.newSource("Assets/wind.wav", "static")
	garrSound[2] = love.audio.newSource("Assets/387232__steaq__badge-coin-win.wav", "static")
	garrSound[3] = love.audio.newSource("Assets/Galactic-Pole-Position.mp3", "stream")
	garrSound[3]:setVolume(0.25)
	garrSound[4] = love.audio.newSource("Assets/387232__steaq__badge-coin-win.wav", "static")
	garrSound[5] = love.audio.newSource("Assets/137920__ionicsmusic__robot-voice-low-fuel1.wav", "static")
	garrSound[5]:setVolume(0.25)
	garrSound[6] = love.audio.newSource("Assets/483598__raclure__wrong.mp3", "static")
	
	-- fonts
	font20 = love.graphics.newFont(20) -- the number denotes the font size

	lovelyToasts.options.queueEnabled = true
	
	Slab.SetINIStatePath(nil)
	Slab.Initialize(args)
	
end

function love.draw()
	
	dobjs.DrawWallPaper()		-- this comes BEFORE the TLfres.beginRendering

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
	
	if strCurrentScreen == "Pause" then
		dobjs.DrawWorld() -- Still draw the world
		dobjs.DrawPause() -- Display on top of world
	end

	if strCurrentScreen == "Settings" then
		menus.DrawSettingsMenu()
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
	
	if strCurrentScreen == "MainMenu" or strCurrentScreen == "Credits" or strCurrentScreen == "Settings" then
		fun.HandleSockets()
		Slab.Update(dt)		
	end
	
	if strCurrentScreen == "World" then

		Lander.update(dt)
		
		gLandingLightsAnimation:update(dt)
		
		fun.HandleSockets()
	end
	
	lovelyToasts.update(dt)		-- can potentially move this with the Slab.Update as it is only used on the main menu

end
