
-- ~~~~~~~~
-- hud.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- In-game HUD elements for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local HUD = {}
HUD.font = love.graphics.newFont(20)

-- TODO: Create variables in a init or create function
-- Fuel indicator elements
HUD.fuel = {x = 20, y = 20, width = SCREEN_WIDTH - 40, height = 50, cornerSize = 15}
HUD.fuel.middle = HUD.fuel.x + math.floor(HUD.fuel.width / 2)
HUD.fuel.bottom = HUD.fuel.y + HUD.fuel.height
HUD.fuel.text = {image=love.graphics.newText(HUD.font, "FUEL")}
HUD.fuel.text.width, HUD.fuel.text.height = HUD.fuel.text.image:getDimensions()
HUD.fuel.text.x, HUD.fuel.text.y = HUD.fuel.x + 20, HUD.fuel.y + math.floor(HUD.fuel.text.height / 2)


local tower = Assets.getImageSet("tower")
local ship = Assets.getImageSet("ship")
local flame = Assets.getImageSet("flame")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function drawFuelIndicator(lander)
	-- draws the fuel indicator across the top of the screen
	-- credit: Milon
	-- refactored by Fox

    -- Fuel indicator
    local grad = lander.fuel / lander.fuelCapacity
    local color = {1, grad, grad}
	local x, y = HUD.fuel.x, HUD.fuel.y
	local width, height = HUD.fuel.width, HUD.fuel.height
	local cornerSize = HUD.fuel.cornerSize

	love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", x, y, width, height, cornerSize, cornerSize)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, width * grad, height, cornerSize, cornerSize)
    love.graphics.setColor(0,0.5,1,1)
    love.graphics.draw(HUD.fuel.text.image, HUD.fuel.text.x, HUD.fuel.text.y)
    love.graphics.setColor(1,1,1,1)
	-- center line
    love.graphics.line(HUD.fuel.middle, y, HUD.fuel.middle, HUD.fuel.bottom)
end



local function drawOffscreenIndicator(lander)
	-- draws an indicator when the lander flies off the top of the screen
    local lineThickness = love.graphics.getLineWidth()
    love.graphics.setLineWidth(3)
    local indicatorY = 40
    local magnifier = 1.5
    local x, y = lander.x - WORLD_OFFSET, ship.height + indicatorY
    if lander.y < 0 then
        love.graphics.draw(ship.image, x, y, math.rad(lander.angle), magnifier, magnifier, ship.width/2, ship.height/2)
        love.graphics.circle("line", x, y, ship.height + 5)
        love.graphics.polygon("fill", x, lander.y, x - 10, indicatorY - 5, x + 10, indicatorY - 5)
        if lander.engineOn then
            love.graphics.draw(flame.image, x, y, math.rad(lander.angle), magnifier, magnifier, flame.width/2, flame.height/2)
        end
    end
	-- restore line thickness
    love.graphics.setLineWidth(lineThickness)
end



local function drawMoney(lander)
	Assets.setFont("font20")
	love.graphics.print("$" .. lander.money, SCREEN_WIDTH - 100, 75)
end



local function drawRangefinder(lander)
-- determine distance to nearest base and draw indicator
	local module = Modules.rangefinder
	if Lander.hasUpgrade(lander, module) then

		local rawDistance, _ = Fun.GetDistanceToClosestBase(lander.x, Enum.basetypeFuel)
		-- limit the rangefinder to a maximum distance
		if rawDistance < Enum.rangefinderMaximumDistance * -1 then
			rawDistance = Enum.rangefinderMaximumDistance * -1
		end
		if rawDistance > Enum.rangefinderMaximumDistance then
			rawDistance = Enum.rangefinderMaximumDistance
		end	
		
		local absDistance = math.abs(Cf.round(rawDistance, 0))
		
		-- don't draw if close to base
		if absDistance > 100 then
			local halfScreenW = SCREEN_WIDTH / 2
			if rawDistance <= 0 then
				Assets.setFont("font20")
				-- closest base is to the right (forward)
				love.graphics.print("--> " .. absDistance, halfScreenW - 75, SCREEN_HEIGHT * 0.90)
			else
				love.graphics.print("<-- " .. absDistance, halfScreenW - 75, SCREEN_HEIGHT * 0.90)
			end
		end
	end
end



local function drawHealthIndicator(lander)
	-- lander.health reports health from 0 (dead) to 100 (best health)
	local indicatorLength = lander.health * -1
	local x  = SCREEN_WIDTH - 30
	local y  = SCREEN_HEIGHT * 0.33
	local width = 10
	local height = indicatorLength

	Assets.setFont("font14")
	love.graphics.print("Health", x - 20, y)
	-- Draw rectangle
	love.graphics.setColor(1,0,0,1)
	love.graphics.rectangle("fill", x, y + 120, width, height)
	love.graphics.setColor(1,1,1,1)
end



local function drawShopMenu()
	-- draws a menu to buy lander parts. This is text based. Hope to make it a full GUI at some point.
	local gameOver = LANDERS[1].gameOver
	local isOnLandingPad = Lander.isOnLandingPad(LANDERS[1], Enum.basetypeFuel)
	if not gameOver and isOnLandingPad then

		Assets.setFont("font20")

		-- Create List of available modules
		for _, module in pairs(Modules) do
			local string = "%s. Buy '%s' - %s $\n"
			itemListString = string.format(string, module.id, module.name, module.cost)
			-- Draw list of modules
			local color = {1, 1, 1, 1}
			local y = SCREEN_HEIGHT * 0.33
			if Lander.hasUpgrade(LANDERS[1], module) then
				color = {.8, .1, .1, .5}
			end
			love.graphics.setColor(color)
			love.graphics.printf(itemListString, 0, y + (20*module.id), SCREEN_WIDTH, "center")
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end



local function drawGameOver()
    Assets.setFont("font16")
    local text = "You are out of fuel. Game over. Press R to reset"

	-- try to get centre of screen
    local x = (SCREEN_WIDTH / 2) - 150
    local y = SCREEN_HEIGHT * 0.33
    love.graphics.print(text, x, y)
end



local function drawScore()
	-- score is simply the amount of forward distance travelled (lander.x)
	local roundedScore = Cf.round(Fun.CalculateScore())
	local score = Cf.strFormatThousand(roundedScore)
	local highScore = Cf.strFormatThousand(tonumber(Cf.round(GAME_SETTINGS.HighScore)))

	Assets.setFont("font14")
	love.graphics.printf("Score: " .. score, 0, 75, SCREEN_WIDTH, "center")
	love.graphics.printf("High Score: " .. highScore, 0, 90, SCREEN_WIDTH, "center")
end



local function drawDebug()
	Assets.setFont("font14")
	local lander = LANDERS[1]

	love.graphics.print("Mass = " .. Cf.round(Lander.getMass(lander), 2), 5, 75)
	love.graphics.print("Fuel = " .. Cf.round(lander.fuel, 2), 5, 90)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 120)
	love.graphics.print("MEM: " .. Cf.round(collectgarbage("count")), 10, 140)
	love.graphics.print("Ground: " .. #GROUND, 10, 160)
	love.graphics.print("Objects: " .. #OBJECTS, 10, 180)
	love.graphics.print("WorldOffsetX: " .. WORLD_OFFSET, 10, 200)
	--love.graphics.print(Cf.round(LANDERS[1].x,0), LANDERS[1].x - WORLD_OFFSET, LANDERS[1].y + 25)
end



local function drawPortInformation()
	if IS_A_HOST then
		love.graphics.setColor(1,1,1,0.50)
		Assets.setFont("font14")
		local txt = "Hosting on port: " .. HOST_IP_ADDRESS .. ":" .. GAME_SETTINGS.hostPort
		love.graphics.printf(txt, 0, 5, SCREEN_WIDTH, "center")
		love.graphics.setColor(1, 1, 1, 1)
	end
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function HUD.drawPause()
    -- Simple text based pause screen
    Assets.setFont("font18")
    love.graphics.setColor(1,1,1,1)
    local text = "GAME PAUSED: PRESS <ESC> OR <P> TO RESUME"
    love.graphics.print(text, SCREEN_WIDTH / 2 - 200, SCREEN_HEIGHT /2)
end



function HUD.draw()
	local lander = LANDERS[1]
	drawFuelIndicator(lander)
	drawHealthIndicator(lander)
	drawScore()
	drawOffscreenIndicator(lander)
	drawMoney(lander)
	drawRangefinder(lander)
    drawPortInformation()

	if lander.gameOver then
		drawGameOver()
	elseif lander.onGround then
		drawShopMenu()
	end

	if DEBUG then
		drawDebug()
	end
end


return HUD