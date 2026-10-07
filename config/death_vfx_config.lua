-- Logical 1280x720 coordinates. All sequence tuning lives here.
return {
    chest = {duration=1.02, stop=0.05, count=0.65, kick=2, size=310,
        cardsAt=0.80, cardsTravel=0.55, flipAt=1.08, flipDuration=0.64, stagger=0.11,
        cardW=218, cardH=316, gap=82, cardY=176, buttonH=34},
    enemy = {
        mini = {duration=1.08, stop=0.045, count=0.65, kick=3, size=290},
        elite = {duration=1.25, stop=0.055, count=0.85, kick=4, size=325},
        boss = {duration=1.48, stop=0.070, count=1, kick=5, size=355},
        crackAt=0.07, breakAt=0.16, dissolvedAt=0.70, burstAt=0.22,
        ember={1,0.46,0.13}, crack={1,0.83,0.48}, ash={0.26,0.24,0.27},
        smoke={0.19,0.16,0.22}, recoil=18, rotation=0.07, fallbackGrid=18,
        driftX=48, driftY=-36, floorY=414, floorRadius=110,
    },
    player = {
        duration=1.70, stop=0.075, collapseAt=0.22, ambienceAt=0.55,
        textAt=0.98, textFade=0.30, buttonsAt=1.42,
        cardDrop=32, cardTilt=0.065, drift=9, zoom=0.014, torchDim=0.72,
        soul={0.51,0.67,0.82}, shadow={0.018,0.014,0.029},
        coreX=640, coreY=535, coreRadius=74, dim=0.70,
    },
    particles = {LOW=40, MEDIUM=78, HIGH=120, max=120,
        ashLife=0.78, emberLife=0.60, smokeLife=0.95},
    overlay = {title="THẤT BẠI", textY=176, sigilY=260, vignette=0.48, dust=16},
}
