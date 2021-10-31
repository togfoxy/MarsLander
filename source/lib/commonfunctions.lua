module(...,package.seeall)

function round(num, idp)
	--Input: number to round; decimal places required
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function deepcopy(orig, copies)
	-- copies one array to another array
	-- ** important **
	-- copies parameter is not meant to be passed in. Just send in orig as a single parameter
	-- returns a new array/table
	
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- rotate 2D tables
function rotate_CCW_90(m)
   local rotated = {}
   for c, m_1_c in ipairs(m[1]) do
      local col = {m_1_c}
      for r = 2, #m do
         col[r] = m[r][c]
      end
      table.insert(rotated, 1, col)
   end
   return rotated
end
function rotate_CW_90(m)
   return rotate_CCW_90(rotate_CCW_90(rotate_CCW_90(m)))
end
function rotate_180(m)
   return rotate_CCW_90(rotate_CCW_90(m))
end

function GetDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
	-- receives two coordinate pairs (not vectors)
	-- returns a single number
	
	if (x1 == nil) or (y1 == nil) or (x2 == nil) or (y2 == nil) then return 0 end
	
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance

end
function SubtractVectors(x1,y1,x2,y2)
	-- subtracts vector2 from vector1 i.e. v1 - v2
	-- returns a vector (an x/y pair)
	return (x1-x2),(y1-y2)
end
function dotVectors(x1,y1,x2,y2)
	-- receives two vectors (deltas) and assumes same origin
	-- eg: guard is looking in direction x1/y1. His looking vector is 1,1
	-- thief vector from guard is 2,-1  (he's on the right side of the guard)
	-- dot product is 1. This is positive so thief is infront of guard (assuming 180 deg viewing angle)
	return (x1*x2)+(y1*y2)
end
function ScaleVector(x,y,fctor)
	-- Receive a vector (0,0, -> x,y) and scale/multiply it by factor
	-- returns a new vector (assuming origin)
	return x * fctor, y * fctor
	--! should create a vector module
end
function Getuuid()
	local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function DeDupeArray(myarray)
-- dedupes myarray and returns same array (not a new array)
	local seen = {}
	for index,item in ipairs(myarray) do
		if seen[item] then
			table.remove(myarray, index)
		else
			seen[item] = true
		end
	end
	
end

function fltAbsoluteTileDistance(x1,y1,x2,y2)
-- given two tiles, determine the distance between those tiles
-- this returns the number of steps or tiles in whole numbers and not in diagonals

	return math.max (math.abs(x2-x1), math.abs(y2-y1))

end

function strFormatThousand(v)
    local s = string.format("%d", math.floor(math.abs(v)))
	local sign = ""

	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	
	-- special case for negative numbers
	if v < 0 then sign = "-" end
	
    return sign .. string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
end

local function GetCollisionMap(objMap)
-- used by jumper. Don't call this directly
-- set up colmap to be the same as map but slightly tweak tiles that are occupied by players

	local row,col
	local colmap = {}
	-- set up a 2D array
	for rows = 1,#objMap do
		colmap[rows] = {}
	end
	for rows = 1,#objMap do
		for cols = 1,#objMap[rows] do
			colmap[rows][cols] = {}
			colmap[rows][cols] = objMap[rows][cols].tiletype
		end
	end	
	
-- print(inspect(colmap[2]))
	
	
	-- -- after colmap is established, tweak individual tiles that occupy a player
	-- for i = 1 , #parray do
        -- if parray[i].health > 0 then
            -- if parray[i].ismoving == false then
                -- -- player is not moving so the tile they are on is obstructed
                -- row = parray[i].row
                -- col = parray[i].col
            -- else
                -- -- the tile the player is moving too is obstructed
                -- row = parray[i].row
                -- col = parray[i].col			
            -- end
              -- colmap[row][col] = enum.tilePlayer
		-- end
	-- end

	return colmap
end

function Findpath(m, starttilerow,starttilecol,stoptilerow, stoptilecol )
	-- receives x/y tile start and stop and returns an array of paths
	-- returns col/row format (x,y) and not row/col!!

	mymap = GetCollisionMap(m)

-- print(inspect(mymap[1]))	
-- print(inspect(mymap[2]))	

	-- Value for walkable tiles
	local walkable = enum.tileInitialised		-- see below - actually looking for < 10

	-- Library setup
	local Pathfinder = require ("jumper.pathfinder") -- The pathfinder class

	-- Creates a grid object
	local grid = Grid(mymap) 
	-- Creates a pathfinder object using Jump Point Search
	local myFinder = Pathfinder(grid, 'JPS', walkable) 
	--local myFinder = Pathfinder(grid, 'JPS', (function(value) return value == 1 end)) 

	-- Calculates the path, and its length
	local path, length = myFinder:getPath(starttilerow, starttilecol, stoptilerow, stoptilecol)
	-- path.x and path.y

	--[[
	if path then
	  print(('Path found! Length: %.2f'):format(length))
		for node, count in path:iter() do
			print(('Step: %d - x: %d - y: %d'):format(count, node.x, node.y))
	  
		end
	else
		print("No path found.")
	end	
	]]--

	return path

end

function bolTableHasValue (tab, val)
-- returns true if tab contains val
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function beep()
--** doesn't seem to work

	local samplerate = 44100 -- Hz
	local duration = 1 -- second
	local frequency = 440.00 -- Hz
	local data = love.sound.newSoundData(math.floor(samplerate/duration), samplerate, 16, 1) -- duration, sampling rate, bit depth, channel count
	for i=0, data:getSampleCount()-1 do
	  data:setSample(i, math.sin(i * frequency * math.pi * 2)) -- sine wave
	end
	local source = love.audio.newSource(data)
	source:play()
end

function fromImageToQuads(spritesheet, spritewidth, spriteheight)
-- Where spritesheet is an image and spritewidth is the width
-- and height of your textures
  local quadtiles = {} -- A table containing the quads to return
  local imageWidth = spritesheet:getWidth()
  local imageHeight = spritesheet:getHeight()
  -- Loop trough the image and extract the quads
  for i = 0, imageHeight - 1, spriteheight do
    for j = 0, imageWidth - 1, spritewidth do
      table.insert(quadtiles,love.graphics.newQuad(j, i, spritewidth, spriteheight, imageWidth, imageHeight))
    end
  end
  -- Return the table of quads
  return quadtiles
end





