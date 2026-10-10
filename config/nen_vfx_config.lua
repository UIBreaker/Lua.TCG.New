-- Visual taxonomy only: IDs and conditions remain owned by Poker/AdvancedHands.
local C={
    types={
        {id="enhancement",name="CƯỜNG HÓA",material=1},
        {id="transmutation",name="BIẾN HÓA",material=2},
        {id="emission",name="PHÓNG XUẤT",material=3},
        {id="conjuration",name="HIỆN HÓA",material=4},
        {id="manipulation",name="THAO TÚNG",material=5},
        {id="specialization",name="ĐẶC CHẤT",material=6},
    },
    tierNames={"BÌNH THƯỜNG","MẠNH","CỰC MẠNH"},
    power={normal=0,strong=.70,extreme=1.80,encounterHands=2,fallbackReference=1000,maxRatio=64},
    quality={low={segments=10,particles=8,branches=1},medium={segments=16,particles=16,branches=2},high={segments=24,particles=24,branches=3}},
    hitStop={.025,.050,.075}, camera={kick={2,5,8},recoil={8,17,26},zoom={0,.009,.018},duration=.32},
    repeatAcceleration={window=9,step=.08,max=.24},
    stages={"PREPARE","ANTICIPATION","NEN_AWAKENING","CARD_TRANSFORMATION","CHARGE","RELEASE","TRAVEL","ENEMY_IMPACT","AFTERSHOCK","SETTLE"},
    -- Base durations: .72 / 1.08 / 1.52 s, before the HP settle floor; scoring runs beforehand.
    timing={{.035,.065,.055,.115,.060,.025,.165,.045,.080,.075},
        {.040,.100,.075,.155,.110,.030,.245,.060,.140,.125},
        {.050,.145,.100,.210,.170,.035,.330,.080,.215,.185}},
    hands={},order={},samples={"high_card","even_frost","tesla_369","pair","straight","eclipse_duality"},
}
local function profile(id,name,kind,signature,conversion,variants,ready)
    local p={id=id,name=name,nenType=kind,signature=signature,conversion=conversion,ready=ready~=false,tiers={}}
    for tier=1,3 do p.tiers[tier]={choreography=variants[tier],tier=tier} end
    C.hands[id]=p;C.order[#C.order+1]=id
end
profile("high_card","Kỵ Sĩ Tiên Phong","enhancement","single_charge","aura_extraction",{"reinforced_card","lancer_charge","colossal_lancer"},true)
profile("pair","Cặp Hộ Vệ","conjuration","guardians_cross","formation_construction",{"twin_guardians","shield_and_lance","giant_guardians"},true)
profile("two_pair","Hai Cánh Tấn Công","manipulation","pincer","formation_construction",{"paired_flanks","counter_flanks","army_pincer"},true)
profile("three_of_a_kind","Mũi Giáo Ba Người","emission","three_spears","weapon_construction",{"staggered_spears","triangle_spears","merged_spear"},true)
profile("straight","Đường Hành Quân","manipulation","rank_march","formation_construction",{"rank_trails","infantry_march","cavalry_charge"},true)
profile("flush","Chung Một Ngọn Cờ","transmutation","banner_wave","material_transformation",{"suit_ribbon","aura_banner","great_banner_vortex"},true)
profile("full_house","Pháo Đài Năm Người","conjuration","fortress","formation_construction",{"small_fort","twin_towers","fortress_barrage"},true)
profile("four_of_a_kind","Bốn Trụ Thành Trì","enhancement","four_pillars","formation_construction",{"pillar_press","staggered_pillars","four_weighted_beats"},true)
profile("straight_flush","Mũi Giáo Hoàng Gia","specialization","royal_spear","weapon_construction",{"royal_spear","segmented_spear","absolute_spear"},true)
profile("tesla_369","Ba Cột Sấm Sét","emission","369_lightning","rune_conversion",{"three_arcs","linked_branching_arcs","tesla_convergence"},true)
profile("jackpot_777","Kho Báu Ba Số Bảy","conjuration","jackpot","rune_conversion",{"gold_seals","treasure_lock","ancient_coin_engine"})
profile("fibonacci","Xoắn Ốc Sự Sống","enhancement","growth_spiral","aura_extraction",{"life_spiral","five_pulses","golden_collapse"})
profile("prime","Năm Sao Đơn Độc","emission","independent_stars","energy_dissolve",{"five_shots","independent_orbits","star_lock"})
profile("odd_star","Chín Tia Bình Minh","emission","nine_rays","aura_extraction",{"dawn_burst","nine_ray_sun","accelerating_dawn"})
profile("even_frost","Phòng Tuyến Băng Giá","transmutation","ice_drill","material_transformation",{"five_ice_lances","assembled_drill","citadel_drill"},true)
profile("crimson_tide","Sóng Triều Đỏ","transmutation","red_tide","material_transformation",{"red_wave","twin_red_streams","blood_moon_tide"})
profile("obsidian_tide","Sóng Triều Đá Đen","transmutation","obsidian_tide","material_transformation",{"obsidian_shards","serrated_waves","geological_spear"})
profile("eclipse_duality","Hai Mặt Nhật Thực","specialization","eclipse","spatial_collapse",{"opposing_halos","celestial_eclipse","corona_compression"},true)
profile("four_kingdom_prism","Lăng Kính Bốn Màu","transmutation","prism","material_transformation",{"prism_ray","refracted_paths","spectral_lance"})
profile("four_kingdom_expedition","Liên Minh Viễn Chinh","manipulation","four_armies","formation_construction",{"alliance_streams","four_banners","battlefield_routes"})
profile("destiny_crown","Vương Miện Định Mệnh","specialization","judgement","weapon_construction",{"crown_sword","five_swords","royal_judgement"})
profile("continental_gate","Cổng Lục Địa Thất Lạc","conjuration","world_gate","rune_conversion",{"four_seals_key","ancient_gate","continental_aperture"})
profile("answer_42","Bản Đồ Chân Trời","manipulation","coordinate_route","rune_conversion",{"five_coordinates","guided_map","star_navigation"})
profile("sealed_gate","Cánh Cổng Thức Tỉnh","conjuration","summoned_gate_sword","weapon_construction",{"gate_sword","sword_formation","ritual_greatsword"})
profile("seven_stars","Bảy Sao Dẫn Lối","emission","seven_falling_stars","energy_dissolve",{"curved_stars","constellation","seven_starfall"})
profile("five_ley_lines","Năm Mạch Năng Lượng","enhancement","ley_eruption","aura_extraction",{"five_veins","layered_veins","central_eruption"})
profile("endless_cycle","Vòng Xoay Bất Tận","specialization","endless_orbit","spatial_collapse",{"closed_ring","counter_orbits","spatial_collapse"})
return C
