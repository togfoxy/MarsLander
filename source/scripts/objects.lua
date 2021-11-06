

local Objects = {}

Objects.lander = {
    name        = "Mars Lander",
    type        = "Object",
    id          = 1,
    smokeTimer  = 0.5,
    yVelocityDamageThreshold = 0.6, -- Max y velocity before taking damage
}

Objects.landingZone = {
    name    = "Landing Zone",
    type    = "Object",
    id      = 2,
}

Objects.building1 = {
    name    = "Building 1",
    type    = "Object",
    id      = 7,
}

return Objects