
return {
    -- Constants
    constSmokeTimer = 0.5,
    constVYThreshold = 0.60,
    constGravity = 0.6,

    -- enumerators
    basetypeFuel = 2,

    -- TODO: Get rid of those by doing something similar to scripts/modules.lua
    -- this is when we don't care about building1 or building2 i.e. any building (but not fuel)
    basetypeBuilding = 6,
    basetypeBuilding1 = 7,
    basetypeBuilding2 = 8,
    baseMaxFuel = 15,

	-- miscellaneous
	rangefinderMaximumDistance = 4000,
	
	-- module ID's
	moduleEfficientThrusters = 1,
	moduleLargeTank = 2,
	moduleRangefinder = 3,
	moduleSideThrusters = 4,
	moduleParachute = 5
}
