-- ~~~~~~~~
-- HUD.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- In-game HUD elements for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local HUD = {}

HUD.font = love.graphics.newFont(20)

-- Fuel indicator elements
HUD.fuel = {x=20, y=20, w=gintScreenWidth - 40, h=50, cornerSize=15}
HUD.fuel.mid = HUD.fuel.x + math.floor(HUD.fuel.w / 2)
HUD.fuel.btm = HUD.fuel.y + HUD.fuel.h
HUD.fuel.text = {img=love.graphics.newText(HUD.font, "FUEL")}
HUD.fuel.text.w, HUD.fuel.text.h = HUD.fuel.text.img:getDimensions()
HUD.fuel.text.x, HUD.fuel.text.y = HUD.fuel.x + 20, HUD.fuel.y + math.floor(HUD.fuel.text.h / 2)



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function DrawFuelIndicator()
-- draws the fuel indicator across the top of the screen
-- credit: Milon
-- refactored by Fox

    -- Fuel indicator
    local grad = garrLanders[1].fuel / garrLanders[1].fuelCapacity
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



local function DrawRangefinder(landerObj)
-- determine distance to nearest base and draw indicator

	if Lander.hasUpgrade(landerObj, enum.moduleNamesRangeFinder) then

		local mydist, _ = fun.GetDistanceToClosestBase(landerObj.x, enum.basetypeFuel)
		mydist = cf.round(mydist,0)
		
		love.graphics.setNewFont(20)

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
	local drawingx  = gintScreenWidth - 30
	local drawingy  = gintScreenHeight * 0.33
	local width     = 10
	local height    = indicatorlength
	
	love.graphics.setNewFont(14)

	love.graphics.print("Health", drawingx - 20, drawingy)

	love.graphics.setColor(1,0,0,1)
	love.graphics.rectangle("fill", drawingx, drawingy + 120,width,height)
	love.graphics.setColor(1,1,1,1)

end



local function DrawGameOver()
    
    love.graphics.setNewFont(16)

    local strText 	= "You are out of fuel. Game over. Press R to reset"	
    local drawingx 	= (gintScreenWidth / 2) - 150		-- try to get centre of screen
    local drawingy 	= gintScreenHeight * 0.33
    love.graphics.print(strText, drawingx, drawingy)
end



local function DrawScore()
-- score is simply the amount of forward distance travelled (lander.x)
	
	local score = cf.strFormatThousand(tonumber(cf.round(fun.calculateScore())))
	local highscore = cf.strFormatThousand(tonumber(cf.round(garrGameSettings.HighScore)))

	love.graphics.setNewFont(14)

	love.graphics.setColor(1,1,1,1)

	love.graphics.printf("Score: " .. score, 0, 75, gintScreenWidth, "center")
	love.graphics.printf("High Score: " .. highscore, 0, 90, gintScreenWidth, "center")
end



local function DrawDebug(worldoffset)

	love.graphics.setNewFont(14)

	love.graphics.print("Mass = " .. cf.round(Lander.getMass(garrLanders[1]),2), 5, 75)
	love.graphics.print("Fuel = " .. cf.round(garrLanders[1].fuel,2), 5, 90)
	love.graphics.print("Mass ratio: " .. cf.round(garrMassRatio,2), 125,75)
	
	--love.graphics.print(cf.round(garrLanders[1].x,0), garrLanders[1].x - worldoffset, garrLanders[1].y + 25)

end



local function DrawPortInformation()

	if gbolIsAHost then

		love.graphics.setColor(1,1,1,0.50)

		love.graphics.setNewFont(12)
		
		love.graphics.print("Hosting on port: " .. gintServerPort, (gintScreenWidth / 2) - 60, 5)
	end

end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function HUD.DrawPause()
    -- Simple text based pause screen

    love.graphics.setNewFont(18)
    love.graphics.setColor(1,1,1,1)
    local strText = "GAME PAUSED: PRESS <ESC> TO RESUME"
    love.graphics.print(strText, gintScreenWidth / 2 - 200, gintScreenHeight /2)

end



function HUD.draw(worldoffset)

	DrawFuelIndicator()
	DrawHealthIndicator()
	DrawScore()
	DrawOffscreenIndicator(worldoffset)
	DrawWealth()
	DrawRangefinder(garrLanders[1])
    DrawPortInformation()
	
	if garrLanders[1].bolGameOver then
		DrawGameOver()
	end
    
	if gbolDebug then
		DrawDebug(worldoffset)
	end

end


return HUD