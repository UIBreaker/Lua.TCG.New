-- Seconds at normal speed; presentation only, never used by scoring math.
return {
    maxFrameDt = 0.05, -- Keep short beats visible after a stalled render/asset frame.
    speed = { normal = 1, fast = 2, forward = 3 },
    timing = {
        button = 0.10, lift = 0.07, travel = 0.24, stagger = 0.055,
        hand = 0.18, base = 0.14, card = 0.21, modifier = 0.16,
        spn = 0.23, multiplyAnticipation = 0.06, gap = 0.025,
        formula = 0.16, countMin = 0.25, countMax = 0.65,
        peak = 0.10, conversion = 0.25, convergence = 0.18,
        releaseMin = 0.03, releaseMax = 0.08, beam = 0.18,
        impact = 0.12, hp = 0.28, trailDelay = 0.10, trail = 0.28,
        settle = 0.50, camera = 0.24,
    },
    aura = { expectedMagnitude = 6, convergenceThreshold = 10000, maxScale = 1.32 },
    pulse = { cardX = 1.04, cardY = 1.06, damage = 1.15, enhance = 1.18,
        multiply = 1.23, spn = 1.13 },
    impact = { minHitStop = 0.025, maxHitStop = 0.075, minKick = 0.65, maxKick = 3.0,
        minParticles = 10, maxParticles = 38, particleCap = 100, maxKnockback = 12 },
    color = { damage = {0.32, 0.80, 1, 1}, enhance = {1, 0.34, 0.43, 1},
        aura = {1, 0.77, 0.34, 1} },
    audio = { minPitch = 0.92, maxPitch = 1.28, pitchStep = 0.014,
        hand = "equip", damage = "chip_tick", enhance = "mult_pop", multiply = "xmult_boom",
        count = "chip_tick", peak = "jackpot", charge = "consume", release = "card_play",
        impact = "damage_hit", heavyImpact = "damage_heavy" },
    debugKey = "f5", labKey = "f6",
}
