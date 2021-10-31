
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

	if LanderObj.lastbaseid == nil then
		LanderObj.lastbaseid, LanderObj.nextbaseid = Lander.GetLastNextBaseID(LanderObj, enum.basetypeFuel)
	end


end

function ai.DoAI(LanderObj, dt)


	
	LanderObj.aitimer = LanderObj.aitimer - dt
	if LanderObj.previousAngle == nil or LanderObj.aitimer <= 0 then
		-- decide a new action
		LanderObj.aitimer = 2		--! make this an enum later
		
		LanderObj.preferredangle, LanderObj.preferredthrust = DetermineAction(LanderObj)
	
	end
	

	
	
	Lander.MoveShip(LanderObj, dt)
	
	Lander.CheckForContact(LanderObj, dt)

end

return ai






