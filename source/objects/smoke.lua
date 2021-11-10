
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

 local smokeSprite = Assets.getImageSet("smoke")



-- ~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~

function Smoke.createParticle(x, y, angle)
	if Smoke.timer == 0 then
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
		Smoke.timer = Smoke.spawnRate
	end
end



function Smoke.destroy()
	Smoke.particles = {}
end



function Smoke.update(dt)
	-- Spawn smoke particles
	if Smoke.timer <= 0 then
		Smoke.timer = 0
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
		particle.animation:draw(particle.x - WORLD_OFFSET, particle.y, math.rad(particle.angle))
	end
end


return Smoke