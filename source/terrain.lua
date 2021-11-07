
-- ~~~~~~~~~~~~
-- terrain.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A terrain generator for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Terrain = {}



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function initialiseGround()
-- initialise the ground array to be a flat line
-- add bases to garrObjects

	-- this creates a big flat space at the start of the game
	for i = 0, (gintScreenWidth * 0.90) do
		garrGround[i] = gintScreenHeight * 0.80
	end

	Terrain.generate(gintScreenWidth * 2)

end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Terrain.initialize()
    initialiseGround()
end



function Terrain.generate(intAmountToCreate)
-- gets a predictable terrain value (deterministic) base on x

	-- create terrain
	local groundtablesize = #garrGround

	local gameID = math.pi

	local terrainmaxheight = (gintScreenHeight * 0.90)
	local terrainminheight = (gintScreenHeight * 0.65)
	local terrainstep = (terrainmaxheight - terrainminheight) / 2
	local terrainoctaves = 8

	repeat
		terrainoctaves = terrainoctaves + 1
	until 2 ^ terrainoctaves >= terrainstep

	for i = groundtablesize + 1, (groundtablesize + intAmountToCreate) do

		local newgroundaltitude
		for oct = 1, terrainoctaves do
			newgroundaltitude = garrGround[i-1] + (love.math.noise(i / 2^oct, gameID) - 0.5) * 2 ^ (terrainoctaves - oct - 1)
		end
		if newgroundaltitude < terrainminheight then newgroundaltitude = terrainminheight end
		if newgroundaltitude > terrainmaxheight then newgroundaltitude = terrainmaxheight end

		table.insert(garrGround, newgroundaltitude)
		
	end
	
	-- create fuel bases if within range of the lander
	local numOfObjects = #garrObjects
	local nextBaseX
	
	-- create the first base if it doesn't exist
	if numOfObjects == 0 then
		nextBaseX = cf.round(gintScreenWidth * 1.5,0)
		cobjs.CreateObject(enum.basetypeFuel, nextBaseX)		-- 2 = fuel base
	end
	-- create as many bases as the current terrain allows
	repeat
		numOfObjects = #garrObjects
		lastbasex = garrObjects[numOfObjects].x
		nextBaseX =  cf.round(lastbasex * 1.3,0)
		if nextBaseX <= #garrGround then
			-- create base
			cobjs.CreateObject(enum.basetypeFuel, nextBaseX)		-- 2 = fuel base
		else
			break
		end
	until false == true
	
	-- TODO: find a way to remove terrain that is behind the lander and likely never needed
	
	

end



function Terrain.draw(worldoffset)
-- draws the terrain as a bunch of lines that are 1 pixel in length

	love.graphics.setColor(1,1,1,1)
	-- ensure we have enough terrain
	if (worldoffset + gintScreenWidth) > #garrGround then
		Terrain.generate(gintScreenWidth * 2)
	end

	for i = 1, #garrGround - 1 do
		if i < worldoffset - (gintScreenWidth) or i > worldoffset + (gintScreenWidth) then
			-- don't draw. Do nothing
		else
			love.graphics.line(i - worldoffset, garrGround[i], i + 1 - worldoffset, garrGround[i+1])
			-- draw a vertical line straight down to reflect solid terra firma
			-- love.graphics.setColor(115/255,115/255,115/255,1)
			love.graphics.setColor(205/255,92/255,92/255,1)
			love.graphics.line(i - worldoffset, garrGround[i],i - worldoffset, gintScreenHeight)
			love.graphics.setColor(1,1,1,1)
		end
	end
end


return Terrain