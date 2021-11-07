--[[
drawobjects module: put all your screen draws into this module
]]

local drawobjects = {}
-- put all the drawing routines in here




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
			if objectvalue == enum.basetypeFuel then
				local drawingx = xvalue - worldoffset
				local drawingy = garrGround[xvalue] - garrImages[2]:getHeight()

				-- draw gas tank
				-- draw the 'fuel level' before drawing the tank over it
				-- draw the whole gauge red then overlay the right amount of green
				love.graphics.setColor(1,0,0,1)
				love.graphics.rectangle("fill", drawingx + 40,drawingy + 84,5,40)

				-- draw green gauge
				local gaugeheight = v.totalFuel / enum.baseMaxFuel * 36		-- pixel art gauge is 36 pixels high
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

local function DrawShopMenu()
-- draws a menu to buy lander parts. This is text based. Hope to make it a full GUI at some point.
	local gameOver = garrLanders[1].gameOver
	local isOnLandingPad = Lander.isOnLandingPad(garrLanders[1], enum.basetypeFuel)
	if not gameOver and isOnLandingPad then

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

function drawobjects.DrawWorld()
-- draw the spaceship and flame and other bits

	-- adjust the world so that the lander is centred and the terrain moves under it
	local worldoffset = cf.round(garrLanders[1].x - gintOriginX,0)	-- how many pixels we have moved away from the initial spawn point (X axis)

	--DrawWallPaper()

	-- draw the surface
	Terrain.draw(worldoffset)

    -- draw world objects
	DrawObjects(worldoffset)

	-- draw the lander
    Lander.draw(worldoffset)

    -- draw HUD elements
    HUD.draw(worldoffset)

	-- draw shop overlay
	if garrLanders[1].onGround then
		DrawShopMenu()
	end

end

return drawobjects
