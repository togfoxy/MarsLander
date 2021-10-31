
--[[
]]

local ai = {}

local function DetermineAction(LanderObj)

	local preferredthrust, preferredangle = true, 270
	local landerx = cf.round(LanderObj.x, 0)
	local besty		-- will be set further down and reflects the 'slope'
	
	-- get some important stats
	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
	end
	local lastbasex
	if LanderObj.lastbaseid == 0 then
		lastbasex = gintOriginX
	else
		lastbasex = garrObjects[LanderObj.lastbaseid].x 	
	end
	local nextbasex = garrObjects[LanderObj.nextbaseid].x 		
	local midpointx, midpointy
	if LanderObj.lastbaseid == 0 then
		midpointx = ((nextbasex - gintOriginX) / 2) + gintOriginX
	else
		midpointx = ((nextbasex - garrObjects[LanderObj.lastbaseid].x) / 2) + garrObjects[LanderObj.lastbaseid].x
	end
	midpointx = midpointx - 150		-- the 'goal' is before the apex
	midpointy = garrGround[midpointx] - (nextbasex - midpointx)
	
	-- no do some smarts
	
	if landerx < midpointx then
		-- lander is before the midpoint
		
		-- determine vertical position relative to slope
		besty = garrGround[lastbasex] - (landerx - lastbasex)
		
		if LanderObj.y > besty then
			QIndex1 = "low"
		else
			QIndex1 = "high"
		end
		
		-- determine vertical movement
		if LanderObj.vy < 0 then
			-- gaining altiude
			QIndex2 = "rising"
		else
			QIndex2 = "falling"
		end
		
		if love.math.random(1,5) == 1 then
			-- do random exploratory moves
		
			-- choose random actions - exploratory
			if love.math.random(1,2) == 1 then
				preferredthrust = true
			else
				preferredthrust = false
			end
			
			preferredangle = 255 + love.math.random(1,4) * 15		-- exploratory
			-- preferredangle = 270
		else
			-- explotive
			-- query best result from QTable1
			local strTemp = QIndex1 .. QIndex2

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
				

				if strThrust == '0' then 
					preferredthrust = false 
				end
				if strThrust == '1' then 
					preferredthrust = true 
				end
				
				-- print(QIndex1, QIndex2, preferredangle, preferredthrust)
			end
		end

	else	-- after midpoint. Use different logic
	
		-- ensure vertical velocity is appropriate relative to the ground
		preferredangle = 240
		preferredthrust = false
		
		besty = garrGround[nextbasex] - (nextbasex - landerx)
		
		if not LanderObj.landed then
		
		
			-- determine vertical position relative to slope
			besty = garrGround[nextbasex] - (nextbasex - landerx)
			
			if LanderObj.y > besty then
				QIndex1 = "toolow"
			else
				QIndex1 = "toohigh"
			end			
		
			-- determine appropriate vx
			local disttonextbase = nextbasex + 125 - landerx			-- 85 is for the landing lights + 50 for margin
			local bestvx = disttonextbase / 200

			if LanderObj.vx > bestvx then
				QIndex2 = "toofast"
			else
				QIndex2 = "tooslow"
			end
			
			if love.math.random(1,5) == 1 then
				-- do random exploratory moves
			
				-- choose random actions - exploratory
				if love.math.random(1,2) == 1 then
					preferredthrust = true
				else
					preferredthrust = false
				end
				
				preferredangle = 180 + love.math.random(1,11) * 15		-- exploratory

			else			
				-- explotive
				-- query best result from QTable1
				local strTemp = QIndex1 .. QIndex2

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
					

					if strThrust == '0' then 
						preferredthrust = false 
					end
					if strThrust == '1' then 
						preferredthrust = true 
					end
					
					--print(QIndex1, QIndex2, preferredangle, preferredthrust)
			
				end				

			end
			
			-- automatically apply thrusters if close to ground. This overwrites any AI decision
			local bestvy = (garrGround[nextbasex] - LanderObj.y) / 240

print(LanderObj.vy , bestvy)
			
			if LanderObj.vy > bestvy then
				preferredthrust = true
print("delta")
			end

		end

	end
	
	-- automatically set direction if clearly wrong
	if landerx < nextbasex and LanderObj.vx < 0 and LanderObj.preferredangle < 285 then 
		LanderObj.preferredangle = 285 
print("alpha")
	end
	if landerx > nextbasex and LanderObj.vx > 0 and LanderObj.preferredangle > 255 then 
		LanderObj.preferredangle = 255 
print("bravo")
	end	
	
	if LanderObj.y < 0 then 
		preferredthrust = false
print("charlie")
	end
	
	
	-- capture this now to determine rewards later
	LanderObj.previousydelta = math.abs(besty - LanderObj.y)
	LanderObj.previousangle = preferredangle
	
	LanderObj.QIndex1 = QIndex1
	LanderObj.QIndex2 = QIndex2
	if preferredthrust then		-- convert true/false into 1/0
		LanderObj.previousthrust = 1
	else
		LanderObj.previousthrust = 0
	end	
			
	return preferredangle, preferredthrust


end

local function ComputeRewards(LanderObj)
-- calculate and assign rewards

	local landerx = cf.round(LanderObj.x, 0)
	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
	end
	local lastbasex
	if LanderObj.lastbaseid == 0 then
		lastbasex = gintOriginX
	else
		lastbasex = garrObjects[LanderObj.lastbaseid].x 	
	end
	
	local besty = garrGround[lastbasex] - (landerx - lastbasex)	
	local currentydelta = math.abs(besty - LanderObj.y)
	local previousydelta = LanderObj.previousydelta
	
	if LanderObj.QIndex1 ~= nil and LanderObj.QIndex2 ~= nil and LanderObj.previousangle ~= nil then

		local strTemp1 = tostring(LanderObj.QIndex1 .. LanderObj.QIndex2)
		local strTemp2 = tostring(LanderObj.previousangle .. LanderObj.previousthrust)
		
		if QTable1 == nil then QTable1 = {} end
		if QTable1[strTemp1] == nil then QTable1[strTemp1] = {} end
		if QTable1[strTemp1][strTemp2] == nil then
			QTable1[strTemp1][strTemp2] = {}
			QTable1[strTemp1][strTemp2] = 0
		end
		
		if currentydelta < previousydelta then
			-- reward
			QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] + 1
print("REWARD")
		else
			-- negative reward
			QTable1[strTemp1][strTemp2] = QTable1[strTemp1][strTemp2] - 1
		end
		fun.SaveQTable1()
	end
end

function ai.DoAI(LanderObj, dt)

	if QTable1 == nil then
		QTable1 = {}
	end

	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.aitimer <= 0 then
		-- decide a new action
		LanderObj.aitimer = 2		--! make this an enum later
		
		ComputeRewards(LanderObj)
		LanderObj.preferredangle, LanderObj.preferredthrust = DetermineAction(LanderObj)
		
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






