
--[[
]]

local ai = {}

local function mapdistance(intDist)

	if intDist > 0 and intDist <= 10 then retval = cf.round(((10 - 0) / 2) + 0) end
	if intDist > 10 and intDist <= 35 then retval = cf.round(((35 - 10) / 2) + 10) end
	if intDist > 35 and intDist <= 80 then retval = cf.round(((80 - 35) / 2) + 35) end
	if intDist > 80 and intDist <= 200 then retval = cf.round(((200 - 80) / 2) + 80) end
	if intDist > 200 and intDist <= 500 then retval = cf.round(((500 - 200) / 2) + 200) end
	if intDist > 500 and intDist <= 2000 then retval = cf.round(((2000 - 500) / 2) + 500) end
	if intDist > 2000 then intDist = 5000 end
	
	if intDist < 0 and intDist >= -10 then retval = cf.round(((-10 + 0) / 2) - 0) end
	if intDist < -10 and intDist >= -35 then retval = cf.round(((-35 + 10) / 2) - 10) end
	if intDist < -35 and intDist >= -80 then retval = cf.round(((-80 + 35) / 2) - 35) end
	if intDist < -80 and intDist >= -200 then retval = cf.round(((-200 + 80) / 2) - 80) end
	if intDist < -200 and intDist >= -500 then retval = cf.round(((-500 + 200) / 2) - 200) end
	if intDist < -500 and intDist >= -2000 then retval = cf.round(((-2000 + 500) / 2) - 500) end
	if intDist < -2000 then intDist = -5000 end

	return retval
end

local function mapy(intY)
	return cf.round(intY / 100) * 100
end

local function mapvx(fltvy)
	return cf.round(fltvy * 5) 
end

local function mapvy(fltvy)
	return cf.round(fltvy * 5) 
end

local function newDetermineAction(LanderObj)

	local preferredangle, preferredthrust = 270, 1
	
	-- get some important stats
	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
		LanderObj.nextbasex = garrObjects[LanderObj.nextbaseid].x
		LanderObj.nextbasey = garrGround[LanderObj.nextbasex]
		
print("New base is " .. LanderObj.nextbaseid)
 
	end
	
	if love.math.random(1,10) == 1 then
		-- exploratory
		preferredangle = 180 + love.math.random(1,11) * 15
		preferredthrust = love.math.random(1,2)
print("Exploring")
	
	else
		-- exploitive
		local distance = mapdistance(cf.round(LanderObj.nextbasex - LanderObj.x,0))
		local strTemp = tostring(distance) .. tostring(mapy(LanderObj.y)) .. tostring(mapvx(LanderObj.vx)) .. tostring(mapvy(LanderObj.vx))
	
		-- query best result from QTable1
		if QTable1[strTemp] ~= nil then
			local largestValue, key1, key2 = -999, "", ""
			for k1,v1 in pairs(QTable1[strTemp]) do
				if v1 > largestValue then
					key1 = k1
					largestValue = v1
				end
			end
			
			-- preferred action is key1
			preferredangle = string.sub(key1, 1,3)
			preferredangle = tonumber(preferredangle)
			strThrust = string.sub(key1, 4,4)
			preferredthrust = tonumber(strThrust)

			-- print("Agent option: " .. strTemp, preferredangle, preferredthrust, "score : " .. largestValue)
		else
			-- go random
			-- exploratory
			preferredangle = 180 + love.math.random(1,11) * 15
			preferredthrust = love.math.random(1,2)	
print("Exploring")			
		end		
	end
	
	-- capture some stuff to determine rewards later
	LanderObj.olddistance = math.abs(cf.GetDistance(LanderObj.x, LanderObj.y, LanderObj.nextbasex, LanderObj.nextbasey))
	LanderObj.previousfuel = LanderObj.fuel
	LanderObj.previousdistance = mapdistance(cf.round(LanderObj.nextbasex - LanderObj.x,0))
	LanderObj.previousy = mapy(LanderObj.y)
	LanderObj.previousvx = mapvx(LanderObj.vx)
	LanderObj.previousvy = mapvy(LanderObj.vx)
	
	LanderObj.previousangle = preferredangle
	LanderObj.previousthrust = preferredthrust		-- 1 or 2
	
	
	-- convert to boolean just prior to RETURN
	if preferredthrust == 1 then 
		preferredthrust = false		-- 1
	else
		preferredthrust = true		-- 2
	end
	return preferredangle, preferredthrust
end

local function newComputeRewards(LanderObj)
	
	local totalreward = 0
	local strTemp1 = tostring(LanderObj.previousdistance) .. tostring(LanderObj.previousy) .. tostring(LanderObj.previousvx) .. tostring(LanderObj.previousvy)
	local strTemp2 = tostring(LanderObj.previousangle .. LanderObj.previousthrust)
	
	if LanderObj.preferredangleangle == nil then LanderObj.preferredangleangle = 270 end
	if LanderObj.preferredthrust == nil then LanderObj.preferredthrust = 1 end

	-- is agent closer to base?
	local olddistance = LanderObj.olddistance
	local newdistance = math.abs(cf.GetDistance(LanderObj.x, LanderObj.y, LanderObj.nextbasex, LanderObj.nextbasey))
	
	if newdistance < olddistance then
		-- reward
		totalreward = totalreward + 1
	elseif newdistance > olddistance then
		totalreward = totalreward - 1
	end
	
	-- is agent off the top of the screen?
	if LanderObj.y <= 0 then
		totalreward = totalreward - 1
	end
	
	-- did agent touch terrain?
	-- get the height of the terrain under the lander
	local LanderXValue = cf.round(LanderObj.x)
	local groundYvalue = garrGround[LanderXValue]
	if LanderObj.y > (groundYvalue - enum.constLanderImageYOffset) then		-- the offset is the size of the lander image
		if Lander.isOnLandingPad(LanderObj, 2) then
			-- on base
			totalreward = totalreward + 1
			LanderObj.fuel = LanderObj.fueltanksize
			
			-- but is it the right base?
			if math.abs(LanderObj.nextbasex - LanderObj.x) < 200 then
				totalreward = totalreward + 10
				LanderObj.lastbaseid = nil
			end
		else
			-- off base
			totalreward = totalreward - 10
		end
	end

	-- is bad motion being corrected?
	if LanderObj.x > LanderObj.nextbasex and LanderObj.vx > 0 and LanderObj.preferredangleangle <= 270 and LanderObj.preferredthrust == 2 then
		totalreward = totalreward + 1
	end
	if LanderObj.x < LanderObj.nextbasex and LanderObj.vx < 0 and LanderObj.preferredangleangle >= 270 and LanderObj.preferredthrust == 2 then
		totalreward = totalreward + 1
	end	
	
	-- is lander fuel efficient?
	if LanderObj.previousfuel ~= nil then
		local fuelused = LanderObj.previousfuel - LanderObj.fuel
		local distancemoved = olddistance - newdistance
		local distperfuel = cf.round(distancemoved / fuelused, 0)
		
		-- globals
		gfltfuelused = gfltfuelused + fuelused
		gfltdistancemoved = gfltdistancemoved + distancemoved
		gfltavgdistperfuel = cf.round(gfltdistancemoved / gfltfuelused)
		
-- print(gfltavgdistperfuel)
		
		if fuelused == 0 then distperfuel = 99 end
		if distancemoved == 0 then distperfuel = -99 end

		if distperfuel < 0 then
			--totalreward = totalreward - 1
		end
		if distperfuel > 0 then 
			totalreward = totalreward + 1
		end
		if distperfuel > gfltavgdistperfuel then
			totalreward = totalreward + 1
		end
	end
	
	-- commit learnings to table

	if QTable1[strTemp1] == nil then QTable1[strTemp1] = {} end
	if QTable1[strTemp1][strTemp2] == nil then
		QTable1[strTemp1][strTemp2] = {}
		QTable1[strTemp1][strTemp2] = 0
	end	
	
	-- QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] + totalreward
	
	-- add steps to long memory
	if garrAIHistory == nil then garrAIHistory = {} end
	
	local strTemp3 = strTemp1 .. ":" .. strTemp2
	mystep = {}
	mystep.key = strTemp3
	mystep.reward = totalreward
	table.insert(garrAIHistory, mystep)

	-- reward long memory
	if #garrAIHistory > 2 then
		-- check the reward over the last 3 steps
		local tempreward = 0
		local lowestreward = math.min(garrAIHistory[1].reward,garrAIHistory[2].reward,garrAIHistory[3].reward)
		
		if lowestreward < 0 then
			-- at least one thing bad happened.
			-- punish the whole chain
			tempreward = lowestreward
		else
			tempreward = garrAIHistory[1].reward + garrAIHistory[2].reward + garrAIHistory[3].reward
		end
		
print("Reward = " .. tempreward)		
		
		-- now loop and apply the reward
		for i = 1,3 do
			-- unpack the state and action
			local pos = string.find(garrAIHistory[i].key, ":")
			strTemp1 = string.sub(garrAIHistory[i].key, 1, pos - 1)
			strTemp2 = string.sub(garrAIHistory[i].key, pos + 1)
			QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] + tempreward
		end
		
		table.remove(garrAIHistory, 1)		-- remove the oldest entry
	end
	
	if QTable1[strTemp1][strTemp2] > 50 then QTable1[strTemp1][strTemp2] = 50 end
	if QTable1[strTemp1][strTemp2] < -50 then QTable1[strTemp1][strTemp2] = -50 end
	
	fun.SaveQTable1()
end

function ai.DoAI(LanderObj, dt)

	-- initialise QTable1
	if QTable1 == nil then QTable1 = {} end
	if gfltfuelused == nil then gfltfuelused = 0 end
	if gfltdistancemoved == nil then gfltdistancemoved = 0 end
	if gfltavgdistperfuel == nil then gfltavgdistperfuel = 0 end

	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.aitimer <= 0 and LanderObj.fuel > 1 then
		-- decide a new action
		LanderObj.aitimer = 1		--! make this an enum later
		
		if LanderObj.nextbaseid ~= nil then		-- these will be set on the first 'DetermineAction'
			newComputeRewards(LanderObj)
		end
		LanderObj.preferredangle, LanderObj.preferredthrust = newDetermineAction(LanderObj)
	end

	if LanderObj.preferredthrust == true then
		Lander.DoThrust(LanderObj, dt)
	end
	
	if LanderObj.preferredangle ~= nil then
		if LanderObj.angle < LanderObj.preferredangle then
			Lander.TurnRight(LanderObj,dt)
		end

		if LanderObj.angle > LanderObj.preferredangle then
			Lander.TurnLeft(LanderObj,dt)
		end	
	end
	
	Lander.MoveShip(LanderObj, dt)
	
	Lander.CheckForContact(LanderObj, false, dt)
	
	-- if LanderObj.landed == true and LanderObj.fuel == LanderObj.fueltanksize then 
		-- -- set new targets
		-- DetermineAction(LanderObj)
	-- end
	
	if LanderObj.fuel <= 1 then
		fun.ResetGame()
	end

end

return ai






