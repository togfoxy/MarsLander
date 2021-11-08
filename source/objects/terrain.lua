
-- ~~~~~~~~~~~~
-- terrain.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A terrain generator for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Terrain = {}



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function getLastBaseID(baseType)
-- scans the garrObjects array and returns the index (id) of the last object in the array of type baseType
-- returns 0 if no base of that type found
-- accepts basetypeBuilding meaning any building

	local lastBaseID = 0
	for i = 1, #garrObjects do
		-- if the object type == base type then capture ID
		-- if the baseType is any building then test for building1 or building2
		if (garrObjects[i].objecttype == baseType) or
			(baseType == enum.basetypeBuilding and (garrObjects[i].objecttype == enum.basetypeBuilding1 or garrObjects[i].objecttype == enum.basetypeBuilding2)) then
			lastBaseID = i
		end
	end
	return lastBaseID
end


-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Terrain.init()
-- initialise the ground array to be a flat line
-- add bases to garrObjects

	-- this creates a big flat space at the start of the game
	for i = 0, (gintScreenWidth * 0.90) do
		garrGround[i] = gintScreenHeight * 0.80
	end

	Terrain.generate(gintScreenWidth * 2)
end



function Terrain.generate(intAmountToCreate)
-- gets a predictable terrain value (deterministic) base on x

	-- create terrain

	-- capture the original array size for use later on
	local originalGroundTableSize = #garrGround
	local gameID = math.pi

	local terrainmaxheight = (gintScreenHeight * 0.90)
	local terrainminheight = (gintScreenHeight * 0.65)
	local terrainstep = (terrainmaxheight - terrainminheight) / 2
	local terrainoctaves = 8

	repeat
		terrainoctaves = terrainoctaves + 1
	until 2 ^ terrainoctaves >= terrainstep

	for i = originalGroundTableSize + 1, (originalGroundTableSize + intAmountToCreate) do

		local newgroundaltitude
		for oct = 1, terrainoctaves do
			newgroundaltitude = garrGround[i-1] + (love.math.noise(i / 2^oct, gameID) - 0.5) * 2 ^ (terrainoctaves - oct - 1)
		end
		if newgroundaltitude < terrainminheight then newgroundaltitude = terrainminheight end
		if newgroundaltitude > terrainmaxheight then newgroundaltitude = terrainmaxheight end

		table.insert(garrGround, newgroundaltitude)

	end

	groundTableSize = #garrGround

	-- add some buildings before adding fuel

	repeat
		local lastBuildingIndex
		local nextBuildingX

		-- get the index/id of the last building
		lastBuildingIndex = getLastBaseID(enum.basetypeBuilding)

		if lastBuildingIndex < 1 then
			nextBuildingX = gintOriginX + love.math.random((gintScreenWidth / 2),gintScreenWidth)
		else
			-- the next building is between one screenwidth and 1.66 away from the last building
			local nextBuildingDistance = gintScreenWidth + love.math.random((gintScreenWidth * 0.66),gintScreenWidth)
			nextBuildingX = garrObjects[lastBuildingIndex].x + nextBuildingDistance
		end	
		nextBuildingX = cf.round(nextBuildingX,0)
		if nextBuildingX <= groundTableSize then
			local newBaseType = love.math.random(7,8)		-- hack
			cobjs.CreateObject(newBaseType, nextBuildingX)
		else
			break
		end
	until not true	-- infinite loop using a break statement

	-- add fuel bases after the buildings so they can draw layered if need be

	-- create as many fuel bases as the current terrain allows
	repeat
		local lastFuelBaseIndex
		local nextBaseX

		lastFuelBaseIndex = getLastBaseID(enum.basetypeFuel)
		if lastFuelBaseIndex == 0 then
			nextBaseX = cf.round(gintScreenWidth * 1.5,0)	--! this should probably use originX and not screenwidth
		else
			nextBaseX = cf.round(garrObjects[lastFuelBaseIndex].x * 1.3,0)
		end

		if nextBaseX <= groundTableSize then
			-- create base
			cobjs.CreateObject(enum.basetypeFuel, nextBaseX)
		else
			break
		end
	until not true	-- infinite loop using a break statement

	-- TODO: find a way to remove terrain that is behind the lander and likely never needed

end


-- TODO: Draw all lines to a canvas once in a while to save drawcalls
-- draws the terrain as a bunch of lines that are 1 pixel in length
function Terrain.draw()
	-- ensure we have enough terrain
	if (gintWorldOffset + gintScreenWidth) > #garrGround then
		Terrain.generate(gintScreenWidth * 2)
	end

	for i = 1, #garrGround - 1 do
		if i >= gintWorldOffset - (gintScreenWidth) and i <= gintWorldOffset + (gintScreenWidth) then
			-- only draw what is visible on the screen
			love.graphics.line(i - gintWorldOffset, garrGround[i], i + 1 - gintWorldOffset, garrGround[i+1])
			-- draw a vertical line straight down to reflect solid terra firma
			love.graphics.setColor(0.8, 0.35, 0.35,1)
			love.graphics.line(i - gintWorldOffset, garrGround[i],i - gintWorldOffset, gintScreenHeight)
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end


return Terrain