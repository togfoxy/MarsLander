module(...,package.seeall)

-- Constants --
constSmokeTimer = 0.5
constVYThreshold = 0.60
constGravity = 0.6
constSocketClientRate = 0.04		-- how frequently will client send to the host?
constSocketHostRate = 0.1


-- enumerators -- 

basetypeFuel = 2
basetypeBuilding1 = 7

baseMaxFuel = 15

moduleCostsThrusters = 225
moduleCostsLargeTank = 200
moduleCostsRangeFinder = 175
moduleCostSideThrusters = 185

moduleNamesThrusters = "Fuel efficient thrusters"
moduleNamesLargeTank = "Large tank"
moduleNamesRangeFinder = "Rangefinder"
moduleNamesSideThrusters = "Side thrusters"

moduleMassSideThrusters = 20