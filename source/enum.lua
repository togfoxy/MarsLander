module(...,package.seeall)

-- Constants --
constSmokeTimer = 0.5
constVYThreshold = 0.60
constGravity = 0.6
constSocketClientRate = 0.04		-- how frequently will client send to the host?
timerHostSendInterval = 0.1


-- enumerators --

basetypeFuel = 2
basetypeBuilding = 6		-- this is when we don't care about building1 or building2 i.e. any building (but not fuel)
basetypeBuilding1 = 7
basetypeBuilding2 = 8

baseMaxFuel = 15

-- sprites and images -- 

imageFlameSprite = 5
imageShip = 6



