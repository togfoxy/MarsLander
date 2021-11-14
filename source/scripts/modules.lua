
-- ~~~~~~~~~~~~
-- modules.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Modules script containing ship modules for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Modules =  {
    thrusters = {
        id = 1,
        name = "Efficent Thrusters",
        cost = 225,
        mass = 20,
    },
    largeTank = {
        id = 2,
        name = "Large Fuel Tank",
        cost = 200,
        mass = 10,
        fuelCapacity = 32,
    },
    rangefinder = {
        id = 3,
        name = "Rangefinder",
        cost = 175,
        mass = 5,
    },
    sideThrusters = {
        id = 4,
        name = "Side Thrusters",
        cost = 185,
        mass = 20,
    },
	parachute = {
		id = 5,
		name = "Parachute (single use)",
		cost = 100,
		mass = 10,
		deployed = false,
	},
}


return Modules