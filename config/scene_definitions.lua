-- The supplied paintings remain ONE base layer, never fabricated cut-out assets.
local D = {}
-- Layers can replace a procedural fallback with an authored texture path.
-- All texture paths are optional and are loaded once, only when present.
D.layers = {
    {id="base",kind="base",stage="before",depth=0.92,parallaxFactor=0.05,offset={0,0},scale=1.035,blurAmount=0.85,brightness=1,tint={1,1,1}},
    {id="distant_arches",kind="arches",stage="before",depth=0.75,parallaxFactor=0.15,offset={0,0},scale=1,blurAmount=0.4,brightness=0.6,tint={0.15,0.20,0.27}},
    {id="midground",kind="columns",stage="before",depth=0.48,parallaxFactor=0.30,offset={0,0},scale=1,blurAmount=0,brightness=0.8,tint={0.10,0.14,0.19}},
    {id="arena",kind="arena",stage="before",depth=0.32,parallaxFactor=0.40,offset={0,0},scale=1,blurAmount=0,brightness=1,tint={0.52,0.43,0.30}},
    {id="ground_mist",kind="fog",stage="after",depth=0.24,parallaxFactor=0.55,offset={0,0},scale=1,blurAmount=0,brightness=1,tint={1,1,1}},
    {id="particles",kind="particles",stage="after",depth=0.18,parallaxFactor=0.65,offset={0,0},scale=1,blurAmount=0,brightness=1,tint={1,1,1}},
    {id="foreground",kind="foreground",stage="after",depth=0.05,parallaxFactor=1.05,offset={0,0},scale=1,blurAmount=0.65,brightness=0.8,tint={0.035,0.048,0.066}},
}
D.presets = {
    RUINS = {ambientColor={0.82,0.88,1}, fogColor={0.30,0.40,0.52}, fogDensity=1,
        particleType="dust", bloomStrength=1, lightTint={1,0.61,0.28}, colorGrade={0.92,0.98,1.07}, cameraIdle=1, vignette=0.17},
    ICE = {ambientColor={0.73,0.87,1}, fogColor={0.48,0.64,0.75}, fogDensity=1.15,
        particleType="snow", bloomStrength=0.8, lightTint={0.42,0.74,1}, colorGrade={0.90,1,1.10}, cameraIdle=0.8, vignette=0.15},
    FOREST = {ambientColor={0.76,0.90,0.83}, fogColor={0.30,0.46,0.38}, fogDensity=1.1,
        particleType="motes", bloomStrength=0.8, lightTint={0.58,0.83,0.45}, colorGrade={0.93,1.04,0.98}, cameraIdle=1, vignette=0.19},
    DESERT = {ambientColor={0.96,0.86,0.73}, fogColor={0.52,0.43,0.31}, fogDensity=0.6,
        particleType="dust", bloomStrength=0.8, lightTint={1,0.72,0.38}, colorGrade={1.08,1,0.88}, cameraIdle=0.8, vignette=0.16},
    VOID = {ambientColor={0.78,0.73,0.94}, fogColor={0.32,0.25,0.46}, fogDensity=1.1,
        particleType="motes", bloomStrength=1.1, lightTint={0.67,0.40,1}, colorGrade={1,0.91,1.10}, cameraIdle=0.7, vignette=0.22},
    VOLCANIC = {ambientColor={0.98,0.73,0.62}, fogColor={0.38,0.22,0.20}, fogDensity=0.7,
        particleType="embers", bloomStrength=1.1, lightTint={1,0.34,0.12}, colorGrade={1.10,0.92,0.85}, cameraIdle=0.9, vignette=0.20},
    MYSTIC = {ambientColor={0.82,0.79,1}, fogColor={0.34,0.32,0.54}, fogDensity=0.9,
        particleType="motes", bloomStrength=1.1, lightTint={0.42,0.69,1}, colorGrade={0.98,0.94,1.10}, cameraIdle=0.8, vignette=0.19},
}
D.scenes = {
    battle = {preset="RUINS", base="background", brightness=0.82},
    menu = {preset="MYSTIC", base="menuWorld", brightness=0.92, video=true},
    shop = {preset="RUINS", base="background", brightness=0.70},
    reward = {preset="RUINS", base="background", brightness=0.63},
    map = {preset="FOREST", base="background", brightness=0.59},
    rest = {preset="FOREST", base="background", brightness=0.65},
    archive = {preset="MYSTIC", base="background", brightness=0.62},
}
D.states = {playing="battle", scoring="battle", menu="menu", shop="shop", CASH_OUT="reward",
    victory="reward", treasure="reward", chest="reward", map="map", rest="rest", gameover="battle",
    BLIND_SELECT="archive", event="archive", socketing="archive", boss_deity="archive"}
-- Landscape menus do not acquire indoor columns or a combat floor.
D.scenes.menu.layers={D.layers[1],D.layers[5],D.layers[6],D.layers[7]}
D.bossPresets = {echo_knight="ICE",taxman="DESERT",gem_devourer="MYSTIC",executioner="VOLCANIC",
    faceless="VOID",the_needle="RUINS",the_water="ICE",the_hook="RUINS",the_fish="FOREST",the_arm="VOLCANIC"}
function D.resolve(state, monster)
    local name = D.states[state] or "archive"
    local definition = D.scenes[name]
    local bossPreset=monster and monster.bossData and D.bossPresets[monster.bossData.id]
    local preset = monster and name=="battle" and (monster.environmentPreset or bossPreset) or definition.preset
    return name, definition, D.presets[preset] or D.presets.RUINS
end
return D
