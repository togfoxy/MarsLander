gstrGameVersion = "0.01"

inspect = require 'inspect'
-- https://github.com/kikito/inspect.lua

TLfres = require "tlfres"
-- https://love2d.org/wiki/TLfres

cobjs = require "createobjects"
dobjs = require "drawobjects"
fun = require "functions"
cf = require "commonfunctions"

gintScreenWidth = 1440-- 1920
gintScreenHeight = 900-- 1080
garrCurrentScreen = {}	

garrLanders = {}	
garrGround = {}

local function DoThrust(dt)

	garrLanders[1].engineOn = true
	local angle_radian = math.rad(garrLanders[1].angle)
	local force_x = math.cos(angle_radian) * dt
	local force_y = math.sin(angle_radian) * dt

	garrLanders[1].vx = garrLanders[1].vx + force_x
	garrLanders[1].vy = garrLanders[1].vy + force_y
end

local function TurnLeft(dt)

	if garrLanders[1].landed == false then
		garrLanders[1].angle = garrLanders[1].angle - (90 * dt)
		if garrLanders[1].angle < 0 then garrLanders[1].angle = 360 end
	end
	
end

local function TurnRight(dt)

	if garrLanders[1].landed == false then
		garrLanders[1].angle = garrLanders[1].angle + (90 * dt)
		if garrLanders[1].angle > 360 then garrLanders[1].angle = 0 end
	end
end

local function MoveShip(Lander, dt)
	Lander.x = Lander.x + Lander.vx 
	Lander.y = Lander.y + Lander.vy
	
	-- apply gravity
	if garrLanders[1].landed == false then
		Lander.vy = Lander.vy + (0.6 * dt)
	end
end

local function InitialiseGround()
-- initialie the ground array to be a flat line

	for i = 0, gintScreenWidth do
		garrGround[i] = 600
	end
end

local function CheckForContact(Lander)
-- see if lander has contacted the ground

	local LanderXValue = cf.round(Lander.x)
	local groundYvalue = cf.round(garrGround[LanderXValue],0)
	
	if Lander.y > groundYvalue - 8 then
		Lander.landed = true
		Lander.vx = 0
		Lander.vy = 0
	else
		Lander.landed = false
	end

end

function love.keypressed( key, scancode, isrepeat)
	if key == "escape" then
		fun.RemoveScreen()
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

	fun.AddScreen("World")
	
	-- create one lander and add it to the global array
	table.insert(garrLanders, cobjs.CreateLander())
	
	--love.keyboard.setKeyRepeat( true )
	
	InitialiseGround()
	
	
end

function love.draw()

	TLfres.beginRendering(gintScreenWidth,gintScreenHeight)
	
	dobjs.DrawWorld()
	
	
	TLfres.endRendering({0, 0, 0, 1})

end


function love.update(dt)

	if love.keyboard.isDown("up") then
		DoThrust(dt)
	end

	if love.keyboard.isDown("left") then
		TurnLeft(dt)
	end
	if love.keyboard.isDown("right") then
		TurnRight(dt)
	end
	
	MoveShip(garrLanders[1], dt)
	CheckForContact(garrLanders[1])


end












