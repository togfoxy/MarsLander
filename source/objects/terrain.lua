
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
-- scans the OBJECTS array and returns the index (id) of the last object in the array of type baseType
-- returns 0 if no base of that type found
-- accepts basetypeBuilding meaning any building

	local lastBaseID = 0
	for i = 1, #OBJECTS do
		-- if the object type == base type then capture ID
		-- if the baseType is any building then test for building1 or building2
		if (OBJECTS[i].objecttype == baseType) or
			(baseType == Enum.basetypeBuilding and (OBJECTS[i].objecttype == Enum.basetypeBuilding1 or OBJECTS[i].objecttype == Enum.basetypeBuilding2)) then
			lastBaseID = i
		end
	end
	return lastBaseID
end


local function addBuildings(groundTableSize)
-- add some buildings
	repeat
		local lastBuildingIndex
		local nextBuildingX

		-- get the index/id of the last building
		lastBuildingIndex = getLastBaseID(Enum.basetypeBuilding)

		if lastBuildingIndex < 1 then
			nextBuildingX = ORIGIN_X + love.math.random((SCREEN_WIDTH / 2),SCREEN_WIDTH)
		else
			-- the next building is between one screenwidth and 1.66 away from the last building
			local nextBuildingDistance = SCREEN_WIDTH + love.math.random((SCREEN_WIDTH * 0.66),SCREEN_WIDTH)
			nextBuildingX = OBJECTS[lastBuildingIndex].x + nextBuildingDistance
		end	
		nextBuildingX = Cf.round(nextBuildingX,0)
		if nextBuildingX <= groundTableSize then
			local newBaseType = love.math.random(7,8)		-- hack
			Cobjs.CreateObject(newBaseType, nextBuildingX)
		else
			break
		end
	until not true	-- infinite loop using a break statement
end

local function addFuelBases(groundTableSize)
	-- create as many fuel bases as the current terrain allows
	repeat
		local lastFuelBaseIndex
		local nextBaseX

		lastFuelBaseIndex = getLastBaseID(Enum.basetypeFuel)
		if lastFuelBaseIndex == 0 then
			nextBaseX = Cf.round(SCREEN_WIDTH * 1.5,0)	--! this should probably use originX and not screenwidth
		else
			nextBaseX = Cf.round(OBJECTS[lastFuelBaseIndex].x * 1.3,0)
		end

		if nextBaseX <= groundTableSize then
			-- create base
			Cobjs.CreateObject(Enum.basetypeFuel, nextBaseX)
		else
			break
		end
	until not true	-- infinite loop using a break statement
end


-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Terrain.init()
-- initialise the ground array to be a flat line
-- add bases to OBJECTS

	-- this creates a big flat space at the start of the game
	for i = 0, (SCREEN_WIDTH * 0.90) do
		GROUND[i] = SCREEN_HEIGHT * 0.80
	end

	Terrain.generate(SCREEN_WIDTH * 2)
	-- TODO: Proper fix for crash when lander.update is called before a fuel base is spawned
	addFuelBases(#GROUND)
	addBuildings(#GROUND)
end



function Terrain.generate(intAmountToCreate)
-- gets a predictable terrain value (deterministic) base on x

	-- create terrain

	-- capture the original array size for use later on
	local originalGroundTableSize = #GROUND
	local gameID = math.pi

	local terrainmaxheight = (SCREEN_HEIGHT * 0.90)
	local terrainminheight = (SCREEN_HEIGHT * 0.65)
	local terrainstep = (terrainmaxheight - terrainminheight) / 2
	local terrainoctaves = 8

	repeat
		terrainoctaves = terrainoctaves + 1
	until 2 ^ terrainoctaves >= terrainstep

	for i = originalGroundTableSize + 1, (originalGroundTableSize + intAmountToCreate) do

		local newgroundaltitude
		for oct = 1, terrainoctaves do
			newgroundaltitude = GROUND[i-1] + (love.math.noise(i / 2^oct, gameID) - 0.5) * 2 ^ (terrainoctaves - oct - 1)
		end
		if newgroundaltitude < terrainminheight then newgroundaltitude = terrainminheight end
		if newgroundaltitude > terrainmaxheight then newgroundaltitude = terrainmaxheight end

		table.insert(GROUND, newgroundaltitude)

	end

	-- add some buildings before adding fuel
	if LANDERS[1] == nil then
	
	else
		addBuildings(LANDERS[1].x + 6000)	-- an arbitrary 'draw ahead' distance
		-- add fuel bases after the buildings so they can draw layered if need be
		addFuelBases(LANDERS[1].x + 6000)	-- an arbitrary 'draw ahead' distance
	end

	-- TODO: find a way to remove terrain that is behind the lander and likely never needed

end


-- TODO: Draw all lines to a canvas once in a while to save drawcalls
-- draws the terrain as a bunch of lines that are 1 pixel in length
function Terrain.draw()
	-- ensure we have enough terrain
	if (WORLD_OFFSET + SCREEN_WIDTH) > #GROUND then
		Terrain.generate(SCREEN_WIDTH * 2)
	end

	for i = 1, #GROUND - 1 do
		if i >= WORLD_OFFSET - (SCREEN_WIDTH) and i <= WORLD_OFFSET + (SCREEN_WIDTH) then
			-- only draw what is visible on the screen
			love.graphics.line(i - WORLD_OFFSET, GROUND[i], i + 1 - WORLD_OFFSET, GROUND[i+1])
			-- draw a vertical line straight down to reflect solid terra firma
			love.graphics.setColor(0.8, 0.35, 0.35, 1)
			love.graphics.line(i - WORLD_OFFSET, GROUND[i],i - WORLD_OFFSET, SCREEN_HEIGHT)
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end


return Terrain