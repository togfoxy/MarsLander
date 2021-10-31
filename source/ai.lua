
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

	local preferredthrust
	local landerx = cf.round(LanderObj.x, 0)

	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
	end
	
	local disttopreviousbase = landerx - gintOriginX
	if LanderObj.lastbaseid > 0 then
		disttopreviousbase = landerx - garrObjects[LanderObj.lastbaseid].x
	end
	local disttonextbase = garrObjects[LanderObj.nextbaseid].x - landerx
	
	-- if before the midpoint then best slope is rising 
	if disttonextbase > disttopreviousbase then
		-- not yet at midpoint. Best slope is a rising slope
		
		-- determine rising slope y value
		local previousbasex 
		if LanderObj.lastbaseid >  0 then
			previousbasex = garrObjects[LanderObj.lastbaseid].x
		else
			previousbasex = gintOriginX
		end
		
		besty = garrGround[landerx] - (landerx - previousbasex) - 8		-- the image size is 8 high (offset)
		--besty = besty - 20		-- aim above the slope
		
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle("fill", landerx, besty, 5)
		
		
		
		
		
		
		
		if LanderObj.y > besty then
			preferredthrust = true
		else
			preferredthrust = false
		end
			
		
	else
		-- past midpoint. Best slope is a falling slope
	end
	
	return 300, preferredthrust


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
	
	Lander.MoveShip(LanderObj, dt)
	
	Lander.CheckForContact(LanderObj, dt)

end

return ai






