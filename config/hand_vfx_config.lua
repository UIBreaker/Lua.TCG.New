-- Presentation only. Hand IDs match Poker.HAND_TYPES; no gameplay values here.
local C = {
    auraTiers = {0.5, 1, 2, 4}, tierNames = {"NORMAL", "STRONG", "POWERFUL", "EXTREME", "TRANSCEND"},
    fallbackTarget = 1000, silence = 0.06, convergence = 0.04, hitStop = {0.055, 0.070, 0.085, 0.105, 0.130},
    quality = {low = 8, medium = 16, high = 28},
    camera = {duration = 0.28, maxKick = 5, maxRecoil = 16, zoom = 0.018},
    trail = {segments = 12, length = 0.24, glow = 2.8},
    shockwave = {radius = 100, thickness = 3, distortionStrength = 0.012},
    particle = {count = 18, length = 48}, bloom = {gain = 1},
    arena = {left = 242, top = 155, width = 780, height = 405, targetY = 270, coreY = 365},
    hands = {}, order = {"high_card", "pair", "two_pair", "three_of_a_kind", "straight", "flush", "full_house", "four_of_a_kind", "straight_flush"},
    suitColors = {spades={0.52,0.68,1}, hearts={1,0.32,0.42}, clubs={0.32,1,0.65}, diamonds={1,0.73,0.3}},
}
C.suitColors.vharos=C.suitColors.spades
C.suitColors.valoria=C.suitColors.hearts
C.suitColors.elaris=C.suitColors.clubs
C.suitColors.aurelia=C.suitColors.diamonds
local function profile(id, name, conversion, projectile, impact, timing, color, beats, kick)
    C.hands[id] = {id=id, name=name, cardConversion=conversion, timing=timing,
        projectile=projectile, impact=impact, camera={x=kick, y=-1}, hitStop=C.hitStop,
        particle=C.particle, shader="existing world bloom + card dissolve", colorProfile=color,
        soundHooks={charge=id.."_charge", release=id.."_release", impact=id.."_impact", beats=beats}}
end
profile("high_card", "ĐƠN THỦ", "edge_spear", "spear", "pierce", {0.14,0.09,0.10,0.10,0.32}, {0.55,0.82,1}, {"highcard_compress"}, 0.1)
profile("pair", "SONG ĐAO", "split", "twin_blades", "cross", {0.17,0.12,0.23,0.12,0.32}, {0.4,0.85,1}, {"pair_slash_1","pair_slash_2"}, 0.8)
profile("two_pair", "SONG ĐÔI", "orbit_pairs", "orbital_blades", "collapse", {0.20,0.15,0.25,0.13,0.34}, {0.48,0.95,0.82}, {"twopair_orbit_a","twopair_orbit_b"}, -0.7)
profile("three_of_a_kind", "TAM HOA", "triangle_nodes", "triangle", "triangle_seal", {0.22,0.19,0.18,0.14,0.34}, {0.74,0.56,1}, {"threekind_node_1","threekind_node_2","threekind_node_3"}, 0)
profile("straight", "TRƯỜNG LONG", "rank_chain", "chain", "long_wave", {0.25,0.08,0.30,0.12,0.33}, {1,0.72,0.34}, {"straight_step_1","straight_step_2","straight_step_3","straight_step_4","straight_step_5"}, 0.5)
profile("flush", "ĐỒNG KHÍ", "ribbons", "wave", "tidal_wave", {0.23,0.14,0.24,0.15,0.35}, {0.4,0.75,1}, {"flush_wave"}, -0.3)
profile("full_house", "HỖN NGUYÊN", "dual_clusters", "fusion", "detonation", {0.24,0.24,0.16,0.16,0.35}, {1,0.58,0.32}, {"fullhouse_core_a","fullhouse_core_b","fullhouse_core_merge"}, -0.5)
profile("four_of_a_kind", "TỨ TƯỢNG", "cardinal", "crossfire", "square_seal", {0.22,0.21,0.22,0.15,0.35}, {0.96,0.47,0.38}, {"fourkind_seal_1","fourkind_seal_2","fourkind_seal_3","fourkind_seal_4"}, 0.2)
profile("straight_flush", "VẠN KIẾM QUY TÔNG", "blade_fragments", "blade_storm", "grand_convergence", {0.25,0.28,0.30,0.16,0.35}, {0.92,0.82,1}, {"straightflush_blade_summon","straightflush_barrage","straightflush_final"}, 0.35)
C.hands.straight_flush.blades={7,11,16,22,28}
C.hands.three_of_a_kind.rhythmPhase="ANTICIPATION"
C.hands.full_house.rhythmPhase="ANTICIPATION"
C.hands.four_of_a_kind.rhythmPhase="ANTICIPATION"
local beatTimes={high_card={0},pair={0,0.30},two_pair={0,0.25},three_of_a_kind={0,0.3,0.6},straight={0,0.13,0.26,0.39,0.52},flush={0},full_house={0,0.30,0.85},four_of_a_kind={0,0.2,0.4,0.6},straight_flush={0,0.24,0.78}}
for id,times in pairs(beatTimes) do C.hands[id].soundHooks.beatTimes=times end
for _, hand in pairs(C.hands) do
    hand.timing[2] = math.max(0.30, hand.timing[2]) -- Readable windup before release.
    hand.timing[3] = math.max(0.26, hand.timing[3])
    hand.timing[4] = math.max(0.22, hand.timing[4])
    hand.timing[5] = math.max(0.55, hand.timing[5])
end
return C
