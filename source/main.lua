
-- ~~~~~~~~~~~~~~~~~~
-- Mars Lander (2021)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/togfoxy/MarsLander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

gstrGameVersion = "0.11"
love.window.setTitle("Mars Lander " .. gstrGameVersion)

-- Directly release messages generated with e.g print for instant feedback
io.stdout:setvbuf("no")

-- Do debug stuff like display info text etc
gbolDebug = true

-- Global screen dimensions
gintScreenWidth = 1024 -- 1920
gintScreenHeight = 768 -- 1080



-- ~~~~~~~~~~~
-- Libraries
-- ~~~~~~~~~~~

inspect = require 'lib.inspect'
-- https://github.com/kikito/inspect.lua

-- https://love2d.org/wiki/TLfres
TLfres = require 'lib.tlfres'

-- https://github.com/coding-jackalope/Slab/wiki
Slab = require 'lib.Slab.Slab'

-- https://github.com/gvx/bitser
bitser = require 'lib.bitser'

-- https://github.com/megagrump/nativefs
nativefs = require 'lib.nativefs'

-- socket it native to LOVE2D
-- https://love2d.org/wiki/Tutorial:Networking_with_UDP
-- http://w3.impa.br/~diego/software/luasocket/reference.html
-- https://aiq0.github.io/luasocket/reference.html
-- https://github.com/camchenry/sock.lua
socket = require 'socket'

-- https://github.com/Loucee/Lovely-Toasts
lovelyToasts = require 'lib.lovelyToasts'

-- Common functions
cf = require 'lib.commonfunctions'

-- Our asset-loader
Assets = require 'lib.assetloader'



-- ~~~~~~~~
-- Assets
-- ~~~~~~~~~

-- Load assets
-- FIXME: assetloader doesn't check if the file to load is actually an image/sound file
Assets.loadDirectory("assets/images", "image")
Assets.loadDirectory("assets/sounds", "sound")
Assets.loadDirectory("assets/music", "music")

-- Load fonts
Assets.newFont(14)
Assets.newFont(16)
Assets.newFont(18)
Assets.newFont(20)



-- ~~~~~~~~~~~~~~~~~~
-- Modules / Classes
-- ~~~~~~~~~~~~~~~~~~

-- TODO: Turn global modules / objects to local ones
-- Scripts
Modules		= require "scripts.modules"		-- Lander modules
enum		= require "scripts.enum"
-- Objects
Smoke 		= require "objects.smoke"		-- Smoke particles for objects
Lander 		= require "objects.lander"
Base 		= require "objects.base"
Building	= require "objects.building"
Terrain 	= require "objects.terrain"
-- Other
HUD			= require "hud"
cobjs		= require "createobjects"
fun			= require "functions"
menus		= require "menus"
ss			= require "socketstuff"



-- ~~~~~~~~~~~~~~~~~
-- Global variables
-- ~~~~~~~~~~~~~~~~~

garrCurrentScreen = {}	-- Current screen / state the user is in

garrLanders = {}
garrGround = {}			-- stores the y value for the ground
garrObjects = {}		-- stores objects that need to be drawn
garrMassRatio = 0		-- for debugging only. Records current mass/default mass ratio
garrGameSettings = {}	-- track game settings

-- this is the start of the world and the origin that we track as we scroll the terrain left and right
gintOriginX = cf.round(gintScreenWidth / 2, 0)
-- this is the mass the lander starts with hence the mass the noob engines are tuned to
gintDefaultMass = 220

-- track speed of the lander to detect crashes etc
gfltLandervy = 0
gfltLandervx = 0

-- Default Player values
gstrDefaultPlayerName = 'Player Name'
gstrCurrentPlayerName = gstrDefaultPlayerName

-- socket stuff
gfltSocketHostTimer = enum.constSocketHostRate
gfltSocketClientTimer = 0	-- enum.constSocketClientRate
gstrServerIP = nil			-- server's IP address
gintServerPort = 6000		-- this is the port each client needs to connect to
gstrClientIP = nil
gintClientPort = nil
gbolIsAClient = false		-- defaults to NOT a client until the player chooses to connect to a host
gbolIsAHost = false			-- Will listen on load but is not a host until someone connects
gbolIsConnected = false		-- Will become true when received an acknowledgement from the server



-- ~~~~~~~~~~~~~~~~
-- Local variables
-- ~~~~~~~~~~~~~~~

local strCurrentScreen
local background = Assets.getImageSet("background1")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function drawWallpaper()
	-- stretch or shrink the image to fit the window
	local sx = gintScreenWidth / background.width
	local sy = gintScreenHeight / background.height
	love.graphics.setColor(1, 1, 1, 0.25)
	love.graphics.draw(background.image, 0, 0, 0, sx, sy)
	love.graphics.setColor(1, 1, 1, 1)
end



-- TODO: Add some sort of gamestate manager
-- Used to be able to draw in pause AND world screen
local function drawWorld()
	-- draw the surface
	Terrain.draw()
	-- draw world objects
	Building.draw()
	Base.draw()
	-- draw the lander
	Lander.draw()
	-- Draw smoke particles
	Smoke.draw()
	-- draw HUD elements
	HUD.draw()
end


-- ~~~~~~~~~~~~~~~
-- main callbacks
-- ~~~~~~~~~~~~~~~

function love.load()
    if love.filesystem.isFused() then
		-- display = monitor number (1 or 2)
		local flags = {fullscreen = true,display = 1,resizable = true, borderless = false}
        love.window.setMode(gintScreenWidth, gintScreenHeight, flags)
        gbolDebug = false

		-- Play music
		-- true for "isLooping"
		Assets.playSound("menuTheme", true)
    else
		-- display = monitor number (1 or 2)
		local flags = {fullscreen = false,display = 1,resizable = true, borderless = false}
		love.window.setMode(gintScreenWidth, gintScreenHeight, flags)
    end

	-- Load settings
	fun.LoadGameSettings()
	-- Restore full screen setting
	love.window.setFullscreen(garrGameSettings.FullScreen)

	-- First screen / entry point
	fun.AddScreen("MainMenu")
	fun.ResetGame()

	-- capture the 'normal' mass of the lander into a global variable
	gintDefaultMass = Lander.getMass(garrLanders[1])

	lovelyToasts.options.queueEnabled = true

	-- Initalize GUI Library
	Slab.SetINIStatePath(nil)
	Slab.Initialize()
end



function love.update(dt)

	strCurrentScreen = garrCurrentScreen[#garrCurrentScreen]

	if strCurrentScreen == "MainMenu"
	or strCurrentScreen == "Credits"
	or strCurrentScreen == "Settings" then
		Slab.Update(dt)
	end

	if strCurrentScreen == "World" then
		Lander.update(garrLanders[1], dt)
		Smoke.update(dt)
		Base.update(dt)
		Building.update(dt)
	end

	fun.HandleSockets()

	-- can potentially move this with the Slab.Update as it is only used on the main menu
	lovelyToasts.update(dt)
end



function love.draw()
	-- this comes BEFORE the TLfres.beginRendering
	drawWallpaper()

	TLfres.beginRendering(gintScreenWidth,gintScreenHeight)

	-- TODO: Add a Scene / Screen manager
	if strCurrentScreen == "MainMenu" then
		menus.DrawMainMenu()
	end

	if strCurrentScreen == "World" then
		drawWorld()
	end

	if strCurrentScreen == "Credits" then
		menus.DrawCredits()
	end

	if strCurrentScreen == "Pause" then
		drawWorld()
		HUD.drawPause() -- Display on top of world
	end

	if strCurrentScreen == "Settings" then
		menus.DrawSettingsMenu()
	end

	--! can this be in an 'if' statement and not drawn if not on a SLAB screen?
	Slab.Draw()

	--* Put this AFTER the slab so that it draws over the slab
	lovelyToasts.draw()

	TLfres.endRendering({0, 0, 0, 1})
end



function love.keypressed(key, scancode, isrepeat)
	-- Back to previous screen
	if key == "escape" then
		fun.RemoveScreen()
	elseif strCurrentScreen == "World" then
		-- Restart the game
		if key == "r" then
			if garrLanders[1].gameOver then
				fun.ResetGame()
			end
		-- Pause the game
		elseif key == "p" then
			fun.AddScreen("Pause")
		-- Open options menu
		elseif key == "o" then
			fun.AddScreen("Settings")
		end
	end
	-- update Lander keys
	Lander.keypressed(key, scancode, isrepeat)
end
