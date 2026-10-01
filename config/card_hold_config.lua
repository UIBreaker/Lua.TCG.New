-- All distances/velocities are in the game's logical 1280x720 space.
return {
    preset = "MEDIUM",
    presets = {
        LIGHT = { stiffness = 900, damping = 42, rotationStiffness = 180, rotationDamping = 21 },
        MEDIUM = { stiffness = 600, damping = 32, rotationStiffness = 125, rotationDamping = 15 },
        HEAVY = { stiffness = 360, damping = 24, rotationStiffness = 90, rotationDamping = 12 },
    },
    input = { smoothing = 22, maxVelocity = 3200, velocityToTilt = 0.00012, lagToTilt = 0.0008 },
    rotation = { maxAngle = 0.18, verticalResponse = 0.00018, verticalShear = 0.018 },
    sway = { enabled = true, amplitude1 = 0.006, amplitude2 = 0.003, speed1 = 2.3, speed2 = 3.7 },
    stretch = { enabled = true, maxAmount = 0.025, speedScale = 3200, response = 18 },
    pickup = { scale = 1.05, lift = 9, response = 24 },
    pivot = { x = 0.5, y = 0.75 },
    shadow = { alpha = 0.25, offset = 12 },
    maxDt = 0.05,
    step = 1 / 240,
    dragThreshold = 6,
    debugKey = "f9",
    labKey = "f10",
}
