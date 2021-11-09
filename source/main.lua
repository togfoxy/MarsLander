
-- ~~~~~~~~~~~~~~~~~~
-- Mars Lander (2021)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/togfoxy/MarsLander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GAME_VERSION = "0.11"
love.window.setTitle("Mars Lander " .. GAME_VERSION)

-- Directly release messages generated with e.g print for instant feedback
io.stdout:setvbuf("no")

-- Do debug stuff like display info text etc
DEBUG = true

-- Global screen dimensions
SCREEN_WIDTH = 1024 -- 1920
SCREEN_HEIGHT = 768 -- 1080



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

-- https://github.com/camchenry/sock.lua
sock = require 'lib.sock'

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
Modules		= require 'scripts.modules'		-- Lander modules
enum		= require 'scripts.enum'
-- Objects
Smoke 		= require 'objects.smoke'		-- Smoke particles for objects
Lander 		= require 'objects.lander'
Base 		= require 'objects.base'
Building	= require 'objects.building'
Terrain 	= require 'objects.terrain'
-- Other
HUD			= require 'hud'
cobjs		= require 'createobjects'
fun			= require 'functions'
menus		= require 'menus'
EnetHandler = require 'enetstuff'



-- ~~~~~~~~~~~~~~~~~
-- Global variables
-- ~~~~~~~~~~~~~~~~~

CURRENT_SCREEN = {}	-- Current screen / state the user is in

LANDERS = {}
GROUND = {}			-- stores the y value for the ground
OBJECTS = {}		-- stores objects that need to be drawn
MASS_RATIO = 0		-- for debugging only. Records current mass/default mass ratio
GAME_SETTINGS = {}	-- track game settings

-- this is the start of the world and the origin that we track as we scroll the terrain left and right
ORIGIN_X = cf.round(SCREEN_WIDTH / 2, 0)
WORLD_OFFSET = ORIGIN_X

-- this is the mass the lander starts with hence the mass the noob engines are tuned to
DEFAULT_MASS = 220

-- track speed of the lander to detect crashes etc
LANDER_VX = 0
LANDER_VY = 0

-- Default Player values
DEFAULT_PLAYER_NAME = 'Player Name'
CURRENT_PLAYER_NAME = DEFAULT_PLAYER_NAME

-- socket stuff
IS_A_CLIENT = false		-- defaults to NOT a client until the player chooses to connect to a host
IS_A_HOST = false			-- Will listen on load but is not a host until someone connects
ENET_IS_CONNECTED = false	-- Will become true when received an acknowledgement from the server
HOST_IP_ADDRESS = ""



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
	local sx = SCREEN_WIDTH / background.width
	local sy = SCREEN_HEIGHT / background.height
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
        love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, flags)
        DEBUG = false

		-- Play music
		-- true for "isLooping"
		Assets.playSound("menuTheme", true)
    else
		-- display = monitor number (1 or 2)
		local flags = {fullscreen = false,display = 1,resizable = true, borderless = false}
		love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, flags)
    end
	
	local sock = require 'socket'	-- socket is native to LOVE but needs a REQUIRE
	HOST_IP_ADDRESS = sock.dns.toip(sock.dns.gethostname())
	sock = nil	

	GAME_SETTINGS.hostPort = "22122"

	-- Load settings
	fun.LoadGameSettings()
	-- Restore full screen setting
	love.window.setFullscreen(GAME_SETTINGS.FullScreen)

	-- First screen / entry point
	fun.AddScreen("MainMenu")
	fun.ResetGame()

	-- capture the 'normal' mass of the lander into a global variable
	DEFAULT_MASS = Lander.getMass(LANDERS[1])

	lovelyToasts.options.queueEnabled = true

	-- Initalize GUI Library
	Slab.SetINIStatePath(nil)
	Slab.Initialize()
end



function love.update(dt)

	strCurrentScreen = CURRENT_SCREEN[#CURRENT_SCREEN]

	if strCurrentScreen == "MainMenu"
	or strCurrentScreen == "Credits"
	or strCurrentScreen == "Settings" then
		Slab.Update(dt)
	end

	if strCurrentScreen == "World" then
		Lander.update(LANDERS[1], dt)
		Smoke.update(dt)
		Base.update(dt)
		Building.update(dt)
	end

	EnetHandler.update(dt)

	-- can potentially move this with the Slab.Update as it is only used on the main menu
	lovelyToasts.update(dt)
end



function love.draw()
	-- this comes BEFORE the TLfres.beginRendering
	drawWallpaper()

	local strCurrentScreen = fun.CurrentScreenName()
	TLfres.beginRendering(SCREEN_WIDTH,SCREEN_HEIGHT)

	local strCurrentScreen = fun.CurrentScreenName()

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
			if LANDERS[1].gameOver then
				fun.ResetGame()
			end
		-- Pause the game
		elseif key == "p" then
			fun.AddScreen("Pause")
			-- Open options menu
		elseif key == "o" then
			fun.AddScreen("Settings")
		end
	elseif strCurrentScreen == "Pause" then
		if key == "p" then
			fun.RemoveScreen()
		end
	end

	-- update Lander keys
	Lander.keypressed(key, scancode, isrepeat)
end
