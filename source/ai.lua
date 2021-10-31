
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
	

	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
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
		-- ensure vertical velocity is appropriate relative to the midpoint
		local ydelta = LanderObj.y - midpointy
		local bestvy = (ydelta / 1000) * -1

		if LanderObj.vy >= bestvy then
			preferredthrust = true
		end
		
		preferredangle = 300
	else
		-- ensure vertical velocity is appropriate relative to the ground
		preferredangle = 240
		
		local distfromnextbase = nextbasex + 85 - landerx			-- 85 is for the landing lights
		
		local besty
		if distfromnextbase < 0 then
			besty = garrGround[landerx] + 50
		else
			besty = garrGround[landerx] - distfromnextbase
		end
		
		if LanderObj.y > besty then
			preferredthrust = true
		end

		local landeralt = garrGround[landerx] - LanderObj.y
		local bestvy = landeralt / 175
		if LanderObj.vy > bestvy then
			preferredthrust = true
		end
		
		if LanderObj.vx > 0 and LanderObj.x > nextbasex + 85 then		-- the landing lights are actually past the base/object
			-- drifting too far to the right
			preferredangle = 240
		end
		if LanderObj.vx < 0 and LanderObj.x < nextbasex + 85 then
			-- drifting too far to the right
			preferredangle = 300
		end		

	end

	return preferredangle, preferredthrust


end

function ai.DoAI(LanderObj, dt)

	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.previousAngle == nil or LanderObj.aitimer <= 0 then
		-- decide a new action
		LanderObj.aitimer = 2		--! make this an enum later
		
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
	
	if LanderObj.landed == true and LanderObj.fuel == LanderObj.fueltanksize then 
		-- set new targets
		DetermineAction(LanderObj)
	end

end

return ai






