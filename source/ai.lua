
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
	end
	
	if love.math.random(1,4) == 1 then
		-- exploratory
		preferredangle = 180 + love.math.random(1,11) * 15
		preferredthrust = love.math.random(1,2)
	
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

			print("Agent option: " .. strTemp, preferredangle, preferredthrust, "score : " .. largestValue)
		else
			-- go random
			-- exploratory
			preferredangle = 180 + love.math.random(1,11) * 15
			preferredthrust = love.math.random(1,2)			
		end		
	end
	
	-- capture some stuff to determine rewards later
	LanderObj.olddistance = cf.round(LanderObj.nextbasex - LanderObj.x,0)
	LanderObj.previousdistance = mapdistance(cf.round(LanderObj.nextbasex - LanderObj.x,0))
	LanderObj.previousy = mapy(LanderObj.y)
	LanderObj.previousvx = mapvx(LanderObj.vx)
	LanderObj.previousvy = mapvy(LanderObj.vx)
	
	LanderObj.previousangle = preferredangle
	LanderObj.previousthrust = preferredthrust		-- 1 or 2
	
	
	-- convert to boolean just prior to RETURN
	if preferredthrust == 1 then 
		preferredthrust = false
	else
		preferredthrust = true
	end
	return preferredangle, preferredthrust
end

local function newComputeRewards(LanderObj)

	-- is agent closer to base?
	local olddistance = LanderObj.olddistance
	local newdistance = cf.round(LanderObj.nextbasex - LanderObj.x,0)
	
	local strTemp1 = tostring(LanderObj.previousdistance) .. tostring(LanderObj.previousy) .. tostring(LanderObj.previousvx) .. tostring(LanderObj.previousvy)
	local strTemp2 = tostring(LanderObj.previousangle .. LanderObj.previousthrust)
	
	-- initialise QTable1
	if QTable1 == nil then QTable1 = {} end
	if QTable1[strTemp1] == nil then QTable1[strTemp1] = {} end
	if QTable1[strTemp1][strTemp2] == nil then
		QTable1[strTemp1][strTemp2] = {}
		QTable1[strTemp1][strTemp2] = 0
	end
		
	if newdistance < olddistance then
		-- reward
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] + 1
-- print("REWARD")
	elseif newdistance > olddistance then
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] - 1
	end
	
	-- is agent off the top of the screen?
	if LanderObj.y <= 0 then
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] - 1
	end
	
	-- is agent on base?
	if LanderObj.x >= LanderObj.nextbasex and LanderObj.x <= LanderObj.nextbasex + 85 then
		-- on base
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] + 10
		LanderObj.lastbaseid = nil
	end

	fun.SaveQTable1()

end

function ai.DoAI(LanderObj, dt)

	if QTable1 == nil then
		QTable1 = {}
	end

	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.aitimer <= 0 and LanderObj.fuel > 1 then
		-- decide a new action
		LanderObj.aitimer = 2		--! make this an enum later
		
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






