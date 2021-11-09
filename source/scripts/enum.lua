
return {
    -- Constants
    constSmokeTimer = 0.5,
    constVYThreshold = 0.60,
    constGravity = 0.6,

    -- how frequently will client send to the host?
    TIMER_CLIENT_SEND_INTERVAL = 0.04,
    TIMER_HOST_SEND_INTERVAL = 0.04,

    -- enumerators
    basetypeFuel = 2,

    -- TODO: Get rid of those by doing something similar to scripts/modules.lua
    -- this is when we don't care about building1 or building2 i.e. any building (but not fuel)
    basetypeBuilding = 6,
    basetypeBuilding1 = 7,
    basetypeBuilding2 = 8,
    baseMaxFuel = 15,
	
	
}
