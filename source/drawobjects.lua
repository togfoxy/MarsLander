--[[
drawobjects module: put all your screen draws into this module


]]

local drawobjects = {}
-- put all the drawing routines in here


-- HUD elements
local HUD = {}
HUD.font = love.graphics.newFont(20)

-- Fuel indicator elements
HUD.fuel = {x=20, y=20, w=gintScreenWidth - 40, h=50, cornerSize=15}
HUD.fuel.mid = HUD.fuel.x + math.floor(HUD.fuel.w / 2)
HUD.fuel.btm = HUD.fuel.y + HUD.fuel.h
HUD.fuel.text = {img=love.graphics.newText(HUD.font, "FUEL")}
HUD.fuel.text.w, HUD.fuel.text.h = HUD.fuel.text.img:getDimensions()
HUD.fuel.text.x, HUD.fuel.text.y = HUD.fuel.x + 20, HUD.fuel.y + math.floor(HUD.fuel.text.h / 2)

local function DrawFuelIndicator()
-- draws the fuel indicator across the top of the screen
-- credit: Milon
-- refactored by Fox

    -- Fuel indicator
    local grad = garrLanders[1].fuel / garrLanders[1].fueltanksize
    local color = {1, grad, grad}
	love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", HUD.fuel.x, HUD.fuel.y, HUD.fuel.w * grad, HUD.fuel.h, HUD.fuel.cornerSize, HUD.fuel.cornerSize)
    love.graphics.setColor(0,0.5,1,1)
    love.graphics.draw(HUD.fuel.text.img, HUD.fuel.text.x, HUD.fuel.text.y)
    love.graphics.setColor(1,1,1,1)
    love.graphics.line(HUD.fuel.mid, HUD.fuel.y, HUD.fuel.mid, HUD.fuel.btm) -- center line

end

local function DrawOffscreenIndicator(worldoffset)
-- draws an indicator when the lander flies off the top of the screen

    local lineThickness = love.graphics.getLineWidth()
    love.graphics.setLineWidth(3)
    local indicatorY = 40
    local magnifier = 1.5
    local x, y = garrLanders[1].x - worldoffset, garrImages[5]:getHeight() + indicatorY
    if garrLanders[1].y < 0 then
        love.graphics.draw(garrImages[5], x, y, math.rad(garrLanders[1].angle), magnifier, magnifier, garrImages[5]:getWidth()/2, garrImages[5]:getHeight()/2)
        love.graphics.circle("line", x, y, garrImages[5]:getHeight() + 5)
        love.graphics.polygon("fill", x, garrLanders[1].y, x - 10, indicatorY - 5, x + 10, indicatorY - 5)
        if garrLanders[1].engineOn then
            love.graphics.draw(garrImages[4], x, y, math.rad(garrLanders[1].angle), magnifier, magnifier, garrImages[4]:getWidth()/2, garrImages[4]:getHeight()/2)
        end
    end
    love.graphics.setLineWidth(lineThickness) -- restore line thickness

end

local function DrawWealth()

	love.graphics.setNewFont(20)
	love.graphics.print("$" .. garrLanders[1].wealth, gintScreenWidth - 100, 75)
end

local function DrawNearestBase(landerObj)
-- determine distance to nearest base and draw indicator

	if Lander.hasUpgrade(landerObj, enum.moduleNamesRangeFinder) then

		local mydist, _ = fun.GetDistanceToClosestBase(landerObj.x, enum.basetypeFuel)
		mydist = cf.round(mydist,0)
		
		-- don't draw if close to base
		if math.abs(mydist) > 100 then
		
			if mydist <= 0 then
				-- closest base is to the right (forward)
				love.graphics.print("--> " .. math.abs(mydist), (gintScreenWidth / 2) - 75, gintScreenHeight * 0.90)
			else
				love.graphics.print("<-- " .. math.abs(mydist), (gintScreenWidth / 2) - 75, gintScreenHeight * 0.90)
			end
		end
	end

end

local function DrawHealthIndicator()
-- lander.health reports health from 0 (dead) to 100 (best health)

	local indicatorlength = garrLanders[1].health * -1
	local drawingx = gintScreenWidth - 30
	local drawingy = gintScreenHeight * 0.33
	local width = 10
	local height = indicatorlength
	
	love.graphics.print("Health", drawingx - 20, drawingy)
	
	love.graphics.setColor(1,0,0,1)
	love.graphics.rectangle("fill", drawingx, drawingy + 120,width,height)
	love.graphics.setColor(1,1,1,1)

end

local function DrawScore()
-- score is simply the amount of forward distance travelled (lander.x)
	
	local score = cf.strFormatThousand(tonumber(cf.round(garrLanders[1].x - gintOriginX,0)))
	love.graphics.setColor(1,1,1,1)
	
	love.graphics.print("score: " .. score, (gintScreenWidth / 2) - 50,75)

end

function HUD.draw(worldoffset)
    
	DrawFuelIndicator()
	
	DrawHealthIndicator()
	
	DrawScore()
    
    -- offscreen indicator
	DrawOffscreenIndicator(worldoffset)
	
	DrawWealth()
	
	DrawNearestBase(garrLanders[1])
	
	if gbolIsAHost then
		love.graphics.setColor(1,1,1,0.50)
		love.graphics.setNewFont(12)
		love.graphics.print("Hosting on port: " .. gintServerPort, (gintScreenWidth / 2) - 60, 5)
	end
end

local function DrawObjects(worldoffset)
-- query garrObjects table and draw them in the world

	for k,v in pairs(garrObjects) do
	
		local xvalue = v.x
		local objectvalue = v.objecttype
		
		-- check if on-screen
		if xvalue < worldoffset - 100 or xvalue > worldoffset + (gintScreenWidth) then
			-- don't draw. Do nothing
		else

			-- draw image based on object type
			if objectvalue == 1 then
				love.graphics.draw(garrImages[1], xvalue - worldoffset, garrGround[xvalue] - garrImages[1]:getHeight())
			end
			if objectvalue == 2 then
				local drawingx = xvalue - worldoffset
				local drawingy = garrGround[xvalue] - garrImages[2]:getHeight()

				-- draw gas tank
				-- draw the 'fuel level' before drawing the tank over it
				-- draw the whole gauge red then overlay the right amount of green
				love.graphics.setColor(1,0,0,1)
				love.graphics.rectangle("fill", drawingx + 40,drawingy + 84,5,40)
				
				-- draw green gauge
				local gaugeheight = v.fuelqty / enum.baseMaxFuel * 36		-- pixel art gauge is 36 pixels high
				local gaugebottom = 120
				love.graphics.setColor(0,1,0,1)
				love.graphics.rectangle("fill", drawingx + 40, drawingy + gaugebottom - gaugeheight, 5, gaugeheight)

				-- set colour based on ACTIVE status
				love.graphics.setColor(1,1,1,1)
				if v.active then
					love.graphics.draw(garrImages[2], drawingx, drawingy)
				else
					love.graphics.draw(garrImages[6], drawingx, drawingy)
				end

				-- draw landing lights
				-- the image is white so the colour can be controlled here at runtime
				if v.paid then
					love.graphics.setColor(1,0,0,1)
				else
					love.graphics.setColor(0,1,0,1)
				end
				gLandingLightsAnimation:draw(garrSprites[1], drawingx + (garrImages[2]:getWidth() - 10 ), drawingy + garrImages[2]:getHeight())		-- the -10 bit is a small adjustment as the png file is not quite right
			end
			if objectvalue == enum.basetypeBuilding1 then
				local drawingx = xvalue - worldoffset
				local drawingy = garrGround[xvalue] - garrImages[7]:getHeight()			
				love.graphics.setColor(1,1,1,1)
				love.graphics.draw(garrImages[7], drawingx, drawingy)
			end
			if objectvalue == enum.basetypeBuilding2 then
				local drawingx = xvalue - worldoffset
				local drawingy = garrGround[xvalue] - garrImages[8]:getHeight()			
				love.graphics.setColor(1,1,1,1)
				love.graphics.draw(garrImages[8], drawingx, drawingy)
			end
			
		end
	end
end

local function DrawDebug(worldoffset)

	love.graphics.setNewFont(14)
	love.graphics.print("Mass = " .. cf.round(Lander.getMass(garrLanders[1]),2), 5, 75)
	love.graphics.print("Fuel = " .. cf.round(garrLanders[1].fuel,2), 5, 90)
	love.graphics.print("Mass ratio: " .. cf.round(garrMassRatio,2), 125,75)
	
	--love.graphics.print(cf.round(garrLanders[1].x,0), garrLanders[1].x - worldoffset, garrLanders[1].y + 25)

end

function drawobjects.DrawWallPaper()
-- scale the wallpaper to be full screen

	-- this is the physical size of the wallpaper
	local wpwidth = 1600
	local wpheight = 1200
	
	-- this is the size of the window
	local screenwidth, screenheight = love.graphics.getDimensions( )
	
	-- stretch or shrink the image to fit the window
	local scalex = screenwidth / wpwidth
	local scaley = screenheight / wpheight

	love.graphics.setColor(1,1,1,0.25)
	love.graphics.draw(garrImages[3],0,0,0,scalex,scaley)
end

local function DrawShopMenu()
-- draws a menu to buy lander parts. This is text based. Hope to make it a full GUI at some point.

	if Lander.isOnLandingPad(garrLanders[1], enum.basetypeFuel) then			-- 2 = base type (fuel)

		love.graphics.setNewFont(16)
		
		local strText = ""

		if not Lander.hasUpgrade(garrLanders[1], enum.moduleNamesThrusters) then
			strText = strText .. "1. Buy fuel efficient thrusters  ($" .. enum.moduleCostsThrusters .. ")" .. "\n"
		end
		if not Lander.hasUpgrade(garrLanders[1], enum.moduleNamesLargeTank) then
			strText = strText .. "2. Buy a larger fuel tanks         ($" .. enum.moduleCostsLargeTank .. ")" .. "\n"
		end
		if not Lander.hasUpgrade(garrLanders[1], enum.moduleNamesRangeFinder) then
			strText = strText .. "3. Buy a rangefinder                 ($" .. enum.moduleCostsRangeFinder .. ")" .. "\n"
		end
		if not Lander.hasUpgrade(garrLanders[1], enum.moduleNamesSideThrusters) then
			strText = strText .. "4. Buy side-thrusters                 ($" .. enum.moduleCostSideThrusters .. ")" .. "\n"
		end
		
		local drawingx = (gintScreenWidth / 2 ) - 125		-- try to get centre of screen
		local drawingy = gintScreenHeight * 0.33
		love.graphics.print(strText, drawingx, drawingy)

	end
end

function drawobjects.DrawPause()
	-- Simple text based pause screen
	love.graphics.setNewFont(18)
	love.graphics.setColor(1,1,1,1)
	local strText = "GAME PAUSED: PRESS <ESC> TO RESUME"
	love.graphics.print(strText, gintScreenWidth / 2 - 200, gintScreenHeight /2)
end

local function DrawGameOver()
	
	love.graphics.setNewFont(16)

	local strText = "You are out of fuel. Game over. Press R to reset"	
	local drawingx = (gintScreenWidth / 2 ) - 150		-- try to get centre of screen
	local drawingy = gintScreenHeight * 0.33
	love.graphics.print(strText, drawingx, drawingy)
end

function drawobjects.DrawWorld()
-- draw the spaceship and flame and other bits

	-- adjust the world so that the lander is centred and the terrain moves under it
	local worldoffset = cf.round(garrLanders[1].x - gintOriginX,0)	-- how many pixels we have moved away from the initial spawn point (X axis)
	
	--DrawWallPaper()
	
	-- draw the surface
	Terrain.draw(worldoffset)	
	
    -- draw world objects
	DrawObjects(worldoffset)
	
    -- draw HUD elements
    HUD.draw(worldoffset)
	
	-- draw the lander
    Lander.draw(worldoffset)
	
	if garrLanders[1].landed then
		DrawShopMenu()
	end
	
	if garrLanders[1].bolGameOver then
		DrawGameOver()
	end
    
	if gbolDebug then
		DrawDebug(worldoffset)
	end	

end

return drawobjects
