
-- ~~~~~~~~~~~
-- Smoke.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Smoke Particles for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Smoke = {}
Smoke.spawnRate = .25
Smoke.timer		= 0
Smoke.particles = {}


-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

-- TODO: Create the spriteData with width and height automatically (except for animations)
 local smokeSprite = Assets.getImageSet("smoke")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

function Smoke.createParticle(x, y, angle)
	local particle = {}
	particle.x = x
	particle.y = y
	-- FIXME: not sure why the smoke sprite needs to be rotate +135. Suspect the image is drawn wrong. This works but!
	particle.angle = (angle or 0) + 135
    local onLoop = function()
        particle.animation:pauseAtEnd()
        particle.removed = true
    end
    particle.animation = Assets.newAnimation("smoke", smokeSprite.image, 30, 30, '1-8', 1, 0.4, onLoop)
	table.insert(Smoke.particles, particle)
end



function Smoke.update(dt)
	-- TODO: Don't hardcode the lander into smoke particle creation
	local lander = garrLanders[1]
	-- Spawn smoke particles
	local engineFiring = lander.engineOn or lander.leftEngineOn or lander.rightEngineOn
	if Smoke.timer <= 0 and engineFiring then
		Smoke.createParticle(lander.x, lander.y, lander.angle)
		Smoke.timer = Smoke.spawnRate
	else
		Smoke.timer = Smoke.timer - dt
	end
	-- update smoke particles
	for key = #Smoke.particles, 1, -1 do
        local particle = Smoke.particles[key]
        if particle.removed then
            table.remove(Smoke.particles, key)
        else
            particle.animation:update(dt)
        end
    end
end



function Smoke.draw()
	-- draw smoke trail
	for key, particle in ipairs(Smoke.particles) do
		--[[ TODO: currently the sprite rotates around it's top left corner and kinda works visually because of the way
				the frames of the animation are drawn in the actual image file.
				It would be better to rotate around a center point of the frame and then adjust the position of the
				sprite to be fixed at a certain location. Some adjustments to the sprite itself might be nessecary.
		--]]
		particle.animation:draw(particle.x - gintWorldOffset, particle.y, math.rad(particle.angle))
	end
end


return Smoke