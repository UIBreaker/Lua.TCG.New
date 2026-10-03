-- Cinematic Dark-Fantasy HD-2D Card Roguelike. Logical units: 1280x720.
return {
    quality = "HIGH", enabled = true,
    qualities = {
        LOW = { worldScale = 0.75, bloomScale = 0.125, particles = 18, bloom = false, dof = false },
        MEDIUM = { worldScale = 1, bloomScale = 0.20, particles = 36, bloom = true, dof = true },
        HIGH = { worldScale = 1.5, bloomScale = 0.25, particles = 56, bloom = true, dof = true },
    },
    effects = { bloom = true, dof = true, fog = true, particles = true, lighting = true, grading = true },
    camera = { idleX = 2.6, idleY = 1.4, speed = 0.32, response = 5, zoom = 0.018,
        focusX = 9, focusY = -5, attackZoom = 0.012, shakeDecay = 8, maxKick = 8 },
    bloom = { threshold = 0.68, knee = 0.14, strength = 0.14, eventStrength = 0.24 },
    dof = { backgroundBlur = 0.85, foregroundBlur = 0.65 },
    fog = { density = 0.095, speed = 0.065 },
    lighting = { ambient = {0.80, 0.85, 0.94}, practical = 0.13, event = 0.32 },
    boss = { breath = 0.007, sway = 1.5, shadow = 0.22, rim = 0.10, tint = 0.10 },
    ui = { veil = 0.58, surfaceAlpha = 0.89, raisedAlpha = 0.93, textureAlpha = 0.016 },
    shop = { spotlight = 0.075, focusedLight = 0.16, shadow = 0.26 },
    reward = { veil = 0.38, panelAlpha = 0.89, light = 0.20 },
    transition = { duration = 0.42 },
    debug = { key = "f1", views = {"FINAL", "LAYERS", "LIGHT", "BLOOM", "FOG", "DOF", "PARTICLES"} },
    palette = { magic = {0.28,0.70,0.95}, danger = {0.92,0.24,0.20},
        curse = {0.50,0.28,0.72}, item = {0.35,0.76,0.48}, reward = {1,0.72,0.32} },
}
