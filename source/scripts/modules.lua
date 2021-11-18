
-- ~~~~~~~~~~~~
-- modules.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Modules script containing ship modules for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Modules =  {
    thrusters = {
        id = Enum.moduleEfficientThrusters,
        name = "Efficient Thrusters",
        cost = 225,
        mass = 20,
    },
    largeTank = {
        id = Enum.moduleLargeTank,
        name = "Large Fuel Tank",
        cost = 200,
        mass = 10,
        fuelCapacity = 32,
		allowed = false
    },
    rangefinder = {
        id = Enum.moduleRangefinder,
        name = "Rangefinder",
        cost = 175,
        mass = 5,
    },
    sideThrusters = {
        id = Enum.moduleSideThrusters,
        name = "Side Thrusters",
        cost = 185,
        mass = 20,
    },
	parachute = {
		id = Enum.moduleParachute,
		name = "Parachute (single use)",
		cost = 100,
		mass = 10,
		deployed = false,
		allowed = true,
	},
}

return Modules