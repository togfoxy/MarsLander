
--[[
]]

local ai = {}

local function newDetermineAction(LanderObj)

	local preferredangle, preferredthrust
	
	-- get some important stats
	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
		LanderObj.nextbasex = garrObjects[LanderObj.nextbaseid].x
	end
	
	if love.math.random(1,2) == 1 then
		-- exploratory
		preferredangle = 180 + love.math.random(1,11) * 15
		preferredthrust = love.math.random(1,2)
	
	else
		-- exploitive
		local distance = cf.round(math.abs(LanderObj.nextbasex - LanderObj.x),0)
		local strTemp = tostring(distance) .. tostring(LanderObj.y) .. tostring(LanderObj.vx) .. tostring(LanderObj.vy)
	
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

print("Found an option: " .. strTemp, preferredangle, preferredthrust)
		else
			-- go random
			-- exploratory
			preferredangle = 180 + love.math.random(1,11) * 15
			preferredthrust = love.math.random(1,2)			
		end		
	end
	
	-- capture this now to determine rewards later
	LanderObj.previousdistance = cf.round(math.abs(LanderObj.nextbasex - LanderObj.x),0)
	LanderObj.previousy = cf.round(LanderObj.y)
	LanderObj.previousvx = cf.round(LanderObj.vx,1)
	LanderObj.previousvy = cf.round(LanderObj.vy,1)
	
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
	local olddistance = LanderObj.previousdistance
	local newdistance = math.abs(LanderObj.nextbasex - LanderObj.x)
	
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
	elseif newdistance > olddistance then
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] - 1
	end
	
	-- is agent off the top of the screen?
	if LanderObj.y <= 0 then
		QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] - 1
	end
	
	
	
	
	fun.SaveQTable1()

end

function ai.DoAI(LanderObj, dt)

	if QTable1 == nil then
		QTable1 = {}
	end

	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.aitimer <= 0 then
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

end

return ai






