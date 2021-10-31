
--[[
timer = timer - dt
if x seconds since last decision or no previous action then
	Reset timer
	if no previous action then
		DetermineAction

		Record action in lander
	else
		Reward if y = closer to slope
		Reward if x = closer to base
		Reward if vx = reasonable range
		
		DetermineAction
	end
end

MoveShip()

function DetermineAction()
	Ensure the previous base is understood							Lander.previousbaseid (int)
	Ensure the next base is understood								Lander.nextbaseid (int)
	Determine if before or after the midway point
	Determine best slope
	Determine to explore or exploit
	If explore then
		Determine new angle											Lander.desiredangle (int)
		Determine if thrust											Lander.desiredthrust (bol)
	else
		Determine if above or below slope
		Determine if targetx is in-front or behind
		Look up QTable
		Slope / direction
		[above slope / below slope] = thrust on / thrust off
		
		[before next base / after next base ] = angle (1 - 7)
		
		Determine new angle											Lander.desiredangle (int)
		Determine if thrust											Lander.desiredthrust (bol)
	end
end

]]

local ai = {}

local function DetermineAction(LanderObj)

	local preferredthrust, preferredangle
	local landerx = cf.round(LanderObj.x, 0)
	
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
	
	if landerx < midpointx then
		-- lander is before the midpoint
		
		-- determine position relative to slope
		local besty = garrGround[lastbasex] + (landerx - lastbasex)
		if LanderObj.y > besty then
			QIndex1 = "low"
		else
			QIndex1 = "high"
		end
		
		-- determine movement relative to slope
		if LanderObj.vy < 0 then
			-- gaining altiude
			QIndex2 = "rising"
		else
			QIndex2 = "falling"
		end
		
print(QIndex1,QIndex2)
		
		-- choose random actions
		if love.math.random(1,2) == 1 then
			preferredthrust = true
		else
			preferredthrust = false
		end
		
		preferredangle = 265 + love.math.random(1,4) * 15
		
		-- capture this now to determine rewards later
		LanderObj.previousydelta = math.abs(besty - LanderObj.y)
		LanderObj.previousangle = preferredangle
		LanderObj.previousthrust = preferredthrust
		LanderObj.QIndex1 = QIndex1
		LanderObj.QIndex2 = QIndex2
		
		preferredangle = 270+15
		
		-- ensure vertical velocity is appropriate relative to the midpoint
		-- local ydelta = LanderObj.y - midpointy
		-- local bestvy = (ydelta / 1000) * -1

		-- if LanderObj.vy >= bestvy then
			-- preferredthrust = true
		-- end
	
	else
		-- ensure vertical velocity is appropriate relative to the ground
		preferredangle = 240
		
		-- calculate vy relative to slope
		-- calculate vy relative to ground
		-- calculate vx relative to slope
		
		
		
		
		-- local distfromnextbase = nextbasex + 125 - landerx			-- 85 is for the landing lights + 50 for margin
		
		-- local besty
		-- if distfromnextbase < 0 then
			-- -- gone past the base
			-- besty = garrGround[landerx] + 50		-- set preferred altitude to above the base
		-- else
			-- besty = garrGround[landerx] - distfromnextbase
		-- end
		
		-- if LanderObj.y > besty then
			-- preferredthrust = true
		-- end

		-- local landeralt = garrGround[landerx] - LanderObj.y
		-- local bestvy = landeralt / 175
		-- if LanderObj.vy > bestvy then
			-- preferredthrust = true
		-- end
		
		-- if LanderObj.x > nextbasex + 125 then		-- the landing lights are actually past the base/object
			-- -- drifting too far to the right
			-- preferredangle = 240
		-- end
		-- if LanderObj.x < nextbasex + 125 then
			-- preferredangle = 300
		-- end		

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
	
	local besty = garrGround[lastbasex] + (landerx - lastbasex)
	local currentydelta = math.abs(besty - LanderObj.y)
	local previousydelta = LanderObj.previousydelta

-- print(previousydelta,currentydelta)
	
	if currentydelta < previousydelta then
		-- reward
		QTable1[LanderObj.QIndex1][LanderObj.QIndex2][LanderObj.previousangle][LanderObj.previousthrust] = QTable1[LanderObj.QIndex1][LanderObj.QIndex2][LanderObj.previousangle][LanderObj.previousthrust] + 1
	
print(inspect(QTable1))	
	else
	
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
	
	if LanderObj.angle < LanderObj.preferredangle then
		Lander.TurnRight(LanderObj,dt)
	end
	if LanderObj.angle > LanderObj.preferredangle then
		Lander.TurnLeft(LanderObj,dt)
	end	
	
	Lander.MoveShip(LanderObj, dt)
	
	Lander.CheckForContact(LanderObj, false, dt)
	
	-- if LanderObj.landed == true and LanderObj.fuel == LanderObj.fueltanksize then 
		-- -- set new targets
		-- DetermineAction(LanderObj)
	-- end

end

return ai






