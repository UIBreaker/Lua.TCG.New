-- Presentation only. Hand IDs match Poker.HAND_TYPES; no gameplay values here.
local C = {
    auraTiers = {0.5, 1, 2, 4}, tierNames = {"NORMAL", "STRONG", "POWERFUL", "EXTREME", "TRANSCEND"},
    fallbackTarget = 1000, silence = 0.06, convergence = 0.04, hitStop = {0.025, 0.035, 0.050, 0.065, 0.090},
    quality = {low = 8, medium = 16, high = 28},
    camera = {duration = 0.27, maxKick = 9, maxRecoil = 22, zoom = 0.018},
    trail = {segments = 16, length = 0.30, glow = 2.8},
    shockwave = {radius = 128, thickness = 4, distortionStrength = 0.012},
    particle = {count = 20, length = 66}, bloom = {gain = 1},
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
profile("high_card", "KỴ SĨ TIÊN PHONG", "edge_spear", "spear", "pierce", {0.17,0.09,0.14,0.11,0.30}, {0.55,0.82,1}, {"highcard_compress"}, 0.1)
profile("pair", "CẶP HỘ VỆ", "split", "twin_blades", "cross", {0.20,0.13,0.24,0.13,0.30}, {0.4,0.85,1}, {"pair_slash_1","pair_slash_2"}, 0.8)
profile("two_pair", "HAI CÁNH TẤN CÔNG", "orbit_pairs", "orbital_blades", "collapse", {0.22,0.15,0.25,0.14,0.31}, {0.48,0.95,0.82}, {"twopair_orbit_a","twopair_orbit_b"}, -0.7)
profile("three_of_a_kind", "MŨI GIÁO BA NGƯỜI", "triangle_nodes", "triangle", "triangle_seal", {0.22,0.16,0.20,0.14,0.31}, {0.74,0.56,1}, {"threekind_node_1","threekind_node_2","threekind_node_3"}, 0)
profile("straight", "ĐƯỜNG HÀNH QUÂN", "rank_chain", "chain", "long_wave", {0.25,0.10,0.32,0.12,0.33}, {1,0.72,0.34}, {"straight_step_1","straight_step_2","straight_step_3","straight_step_4","straight_step_5"}, 0.5)
profile("flush", "CHUNG MỘT NGỌN CỜ", "ribbons", "wave", "tidal_wave", {0.24,0.17,0.26,0.15,0.35}, {0.4,0.75,1}, {"flush_wave"}, -0.3)
profile("full_house", "PHÁO ĐÀI NĂM NGƯỜI", "dual_clusters", "fusion", "detonation", {0.24,0.24,0.16,0.16,0.35}, {1,0.58,0.32}, {"fullhouse_core_a","fullhouse_core_b","fullhouse_core_merge"}, -0.5)
profile("four_of_a_kind", "BỐN TRỤ THÀNH TRÌ", "cardinal", "crossfire", "square_seal", {0.22,0.21,0.22,0.15,0.35}, {0.96,0.47,0.38}, {"fourkind_seal_1","fourkind_seal_2","fourkind_seal_3","fourkind_seal_4"}, 0.2)
profile("straight_flush", "MŨI GIÁO HOÀNG GIA", "blade_fragments", "blade_storm", "grand_convergence", {0.25,0.28,0.30,0.16,0.35}, {0.92,0.82,1}, {"straightflush_blade_summon","straightflush_barrage","straightflush_final"}, 0.35)
C.hands.straight_flush.blades={7,11,16,22,28}
C.hands.three_of_a_kind.rhythmPhase="ANTICIPATION"
C.hands.full_house.rhythmPhase="ANTICIPATION"
C.hands.four_of_a_kind.rhythmPhase="ANTICIPATION"
local beatTimes={high_card={0},pair={0,0.30},two_pair={0,0.25},three_of_a_kind={0,0.3,0.6},straight={0,0.13,0.26,0.39,0.52},flush={0},full_house={0,0.30,0.85},four_of_a_kind={0,0.2,0.4,0.6},straight_flush={0,0.24,0.78}}
for id,times in pairs(beatTimes) do C.hands[id].soundHooks.beatTimes=times end
-- Each move keeps its own cadence. Long universal pauses made the original feel rigid.
C.motion={pullback=18, drift=4, releasePower=2.6, impactExpansion=3, coreAlpha=0.75}
local source={triangle="three_of_a_kind",orbital_blades="two_pair",fusion="full_house",crossfire="four_of_a_kind",blade_storm="straight_flush",wave="flush",twin_blades="pair",chain="straight"}
-- Each advanced move has its own formation, release cadence and contact seal.
local advanced={
 tesla_369={3,1.02,2.9,.18,.11,.19}, jackpot_777={3,1.10,2.5,.20,.12,.22},
 fibonacci={2,1.12,2.3,.23,.15,.24}, prime={5,1.04,3.0,.20,.12,.21},
 odd_star={9,1.17,2.8,.23,.14,.25}, even_frost={5,1.13,2.1,.21,.12,.24},
 crimson_tide={5,1.23,1.8,.22,.12,.26}, obsidian_tide={5,1.07,3.2,.20,.15,.20},
 eclipse_duality={2,1.24,2.5,.22,.14,.23}, four_kingdom_prism={4,1.15,2.8,.23,.13,.23},
 four_kingdom_expedition={5,1.10,2.7,.22,.10,.27}, destiny_crown={12,1.19,3.0,.24,.17,.25},
 continental_gate={2,1.23,3.1,.24,.19,.19}, answer_42={5,1.15,2.4,.23,.12,.27},
 sealed_gate={2,1.27,3.3,.25,.19,.18}, seven_stars={7,1.22,2.8,.24,.16,.24},
 five_ley_lines={5,1.20,2.9,.24,.16,.22}, endless_cycle={8,1.15,2.2,.23,.13,.26},
}
local previews={tesla_369={3,6,9,2,4},jackpot_777={7,7,7,2,4},fibonacci={14,2,3,5,8},prime={2,3,5,7,11},odd_star={14,3,5,7,9},even_frost={2,4,6,8,10},crimson_tide={3,5,7,9,11},obsidian_tide={3,5,7,9,11},eclipse_duality={2,4,9,4,2},four_kingdom_prism={2,4,6,9,13},four_kingdom_expedition={14,2,4,6,13},destiny_crown={10,11,12,13,14},continental_gate={14,14,14,14,13},answer_42={4,6,9,10,13},sealed_gate={14,14,14,13,13},seven_stars={7,7,7,14,13},five_ley_lines={14,4,8,10,13},endless_cycle={2,3,4,5,6}}
C.labOrder={};for _,id in ipairs(C.order) do C.labOrder[#C.labOrder+1]=id end
for _,hand in ipairs(require("src.advanced_hands").ordered) do
    local base=C.hands[source[hand.shape]];local p={}
    for key,value in pairs(base) do p[key]=value end
    local v=assert(advanced[hand.id])
    p.id=hand.id;p.name=hand.vnName;p.advanced=true;p.colorProfile=hand.color;p.previewCards=previews[hand.id]
    p.emitters=v[1];p.spread=v[2];p.releasePower=v[3];p.mythic=hand.mythic
    p.timing={v[4],v[5],v[6],.15,.32}
    if p.blades then p.blades={math.min(5,v[1]),math.min(7,v[1]),v[1],v[1],v[1]} end
    C.hands[hand.id]=p;C.labOrder[#C.labOrder+1]=hand.id
end
return C
