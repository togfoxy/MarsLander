gstrGameVersion = "0.10"

io.stdout:setvbuf("no")

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
-- https://aiq0.github.io/luasocket/reference.html
-- https://github.com/camchenry/sock.lua

lovelyToasts = require("lib.lovelyToasts")
-- https://github.com/Loucee/Lovely-Toasts

-- gintScreenWidth = 1920
-- gintScreenHeight = 1080

gintScreenWidth = 1024-- 1920
gintScreenHeight = 768-- 1080

garrCurrentScreen = {}

Lander = require "objects.lander"
Terrain = require "terrain"

HUD = require "hud"
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
gfltSocketClientTimer = 0 -- enum.constSocketClientRate
gfltSocketHostTimer = enum.constSocketHostRate

gstrDefaultPlayerName = 'Player Name'
gstrCurrentPlayerName = gstrDefaultPlayerName

-- socket stuff
gstrServerIP = nil					-- server's IP address
gintServerPort = 6666 -- love.math.random(6000,6999)		-- this is the port each client needs to connect to
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
		if garrLanders[1].gameOver then
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

	-- stills/images
	--! should make these numbers enums one day
	local newImage	= love.graphics.newImage
	local path 		= "assets/images/"
	garrImages[1] = newImage(path .. "tower.png")
	garrImages[2] = newImage(path .. "gastank1.png")
	garrImages[3] = newImage(path .. "background1.png")
	garrImages[4] = newImage(path .. "flame.png")
	garrImages[enum.imageFlameSprite] = newImage(path .. "flame.png")
	garrImages[enum.imageShip] = newImage(path .. "ship.png")
	garrImages[7] = newImage(path .. "building1.png")
	garrImages[8] = newImage(path .. "building2.png")
	garrImages[9] = newImage(path .. "logo_lander.png")

	-- spritesheets and animations
	garrSprites[1] = newImage(path .. "landingLights.png")
	gGridLandingLights = anim8.newGrid(64, 8, garrSprites[1]:getWidth(), garrSprites[1]:getHeight())     -- frame width, frame height
	gLandingLightsAnimation = anim8.newAnimation(gGridLandingLights(1,'1-4'), 0.5)		-- column 1, rows 1 -> 4

	gSmokeSheet = newImage(path .. "smoke.png")
	gSmokeImages = cf.fromImageToQuads(gSmokeSheet, 30, 30)		-- w/h of each frame

	local newSource = love.audio.newSource
	local path 		= "assets/sounds/"
	garrSound[1] = newSource(path .. "wind.ogg", "static")
	garrSound[2] = newSource(path .. "landingSuccess.ogg", "static")
	garrSound[5] = newSource(path .. "lowFuel.ogg", "static")
	garrSound[5]:setVolume(0.25)
	garrSound[6] = newSource(path .. "wrong.ogg", "static")

	local path = "assets/music/"
	garrSound[3] = newSource(path .. "menuTheme.mp3", "stream")
	garrSound[3]:setVolume(0.25)

	-- fonts
	font20 = love.graphics.newFont(20) -- the number denotes the font size

	fun.LoadGameSettings()
	love.window.setFullscreen(garrGameSettings.FullScreen) -- Restore full screen setting

	fun.AddScreen("MainMenu")
	fun.ResetGame()

	-- capture the 'normal' mass of the lander into a global variable
	gintDefaultMass = Lander.getMass(garrLanders[1])

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
		HUD.DrawPause() -- Display on top of world
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
		
		Slab.Update(dt)
	end

	if strCurrentScreen == "World" then

		Lander.update(garrLanders[1], dt)

		gLandingLightsAnimation:update(dt)

	end
	
	fun.HandleSockets()
	lovelyToasts.update(dt)		-- can potentially move this with the Slab.Update as it is only used on the main menu

end
