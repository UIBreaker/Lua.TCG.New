-- All distances/velocities are in the game's logical 1280x720 space.
return {
    preset = "MEDIUM",
    presets = {
        LIGHT = { stiffness = 1600, damping = 72, rotationStiffness = 260, rotationDamping = 23 },
        MEDIUM = { stiffness = 1100, damping = 58, rotationStiffness = 210, rotationDamping = 19 },
        HEAVY = { stiffness = 360, damping = 24, rotationStiffness = 90, rotationDamping = 12 },
    },
    input = { smoothing = 26, maxVelocity = 3200, velocityToTilt = 0.00019, lagToTilt = 0.0010 },
    rotation = { maxAngle = 0.38, verticalResponse = 0.00018, verticalShear = 0.018 },
    sway = { enabled = true, amplitude1 = 0.006, amplitude2 = 0.003, speed1 = 2.3, speed2 = 3.7 },
    stretch = { enabled = true, maxAmount = 0.025, speedScale = 3200, response = 18 },
    idle = { angle = 0.010, bob = 0.65, speed = 1.15 },
    hover = { angle = 0.075, lift = 3, scale = 1.025, response = 14 },
    pickup = { scale = 1.07, lift = 10, response = 24 },
    pivot = { x = 0.5, y = 0.75 },
    shadow = { alpha = 0.30, offset = 18, softness = 8, layers = 8 },
    maxDt = 0.05,
    step = 1 / 240,
    dragThreshold = 6,
    debugKey = "f9",
    labKey = "f10",
}
