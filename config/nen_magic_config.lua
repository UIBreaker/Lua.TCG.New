-- Attack presentation only. Scoring and damage-popup tiers are owned elsewhere.
local C={order={},hands={},aura={reference=1000,thresholds={.7,1.8,4},cap=32},
    quality={low={segments=12,particles=8},medium={segments=20,particles=16},high={segments=32,particles=24}},
    levels={"NORMAL","ENHANCED","OVERDRIVE","MAXIMUM"},bloom={threshold=.68,radius=1.5,intensity=.32}}
local cyan={.16,.78,1};local gold={1,.69,.16};local teal={.12,1,.69};local violet={.62,.29,1}
local colors={cyan,gold,{1,.25,.12},teal,violet}
local function add(id,name,weapon,count,motion,explosion,palette,particle,size)
    local index=#C.order+1;C.order[index]=id
    C.hands[id]={handId=id,name=require("config.nen_vfx_config").hands[id].name,attackName=name,
        projectileType=weapon,projectileCount=count,spawnPattern=motion,movementPattern=motion,
        travelDuration="existing combat timeline",colorPalette=palette,impactType=explosion,
        explosionType=explosion,explosionIndex=index,particleParameters={kind=particle},
        glowParameters={core=.82,halo=.28},auraScale=1,size=size or 42,soundId="nen_"..id.."_impact"}
end
add("high_card","KIẾM NIỆM","sword",1,"thrust","blade_ring",{cyan},"energy",58)
add("pair","SONG KIẾM NIỆM","sword",2,"cross","crossed_blades",{cyan,gold},"energy",48)
add("two_pair","SONG NHẬN","crescent",2,"pincer","wing_blades",{{1,.3,.13},teal},"energy",43)
add("three_of_a_kind","TAM THƯƠNG","spear",3,"volley","triangle",{{.52,.75,1}},"energy",51)
add("straight","VẠN TIỄN","arrow",7,"arrows","arrow_fan",{gold},"gold",34)
add("flush","PHONG NHẬN","crescent",1,"wind","vortex",{teal},"magic",60)
add("full_house","NGŨ THẠCH","stone",5,"stones","magma",{{1,.33,.07}},"fire",31)
add("four_of_a_kind","TỨ TRỤ","pillar",4,"inward","crystal_cross",{{.39,.85,1}},"ice",41)
add("straight_flush","THÁNH THƯƠNG","spear",1,"judgement","holy_column",{gold},"gold",76)
add("tesla_369","TAM LÔI","lightning",3,"lightning","plasma",{cyan,violet},"electric",44)
add("jackpot_777","KIM TIỀN","coin",3,"coins","coin_stars",{gold},"gold",29)
add("fibonacci","SINH MỆNH XOÁY","ribbon",2,"helix","life_flower",{teal},"magic",36)
add("prime","NGŨ TINH","star5",5,"stars","five_star",{{.69,.5,1}},"star",30)
add("odd_star","CỬU QUANG","ray",9,"sunfall","solar_ring",{{1,.55,.08}},"fire",45)
add("even_frost","BĂNG TIỄN","ice",7,"ice","ice_shatter",{{.39,.83,1}},"ice",38)
add("crimson_tide","HỒNG TRIỀU","wave",1,"wave","liquid_ring",{{1,.08,.25}},"liquid",73)
add("obsidian_tide","HẮC THẠCH","stone",5,"obsidian","obsidian_shatter",{violet},"stone",32)
add("eclipse_duality","NHẬT NGUYỆT","orb",2,"eclipse","eclipse",{{1,.13,.18},violet},"magic",42)
add("four_kingdom_prism","TỨ SẮC QUANG","ray",4,"prism","prism_shatter",{colors[3],cyan,gold,teal},"crystal",50)
add("four_kingdom_expedition","TỨ KIẾM","sword",4,"orbit","kingdom_vortex",{colors[3],cyan,gold,teal},"energy",44)
add("destiny_crown","HOÀNG QUANG","crown",1,"crown","royal_halo",{gold,violet},"gold",59)
add("continental_gate","CỔNG HƯ KHÔNG","orb",1,"portal","spatial_ring",{teal},"magic",37)
add("answer_42","THIÊN LA BÀN","arrow",1,"compass","compass_fracture",{gold,cyan},"energy",49)
add("sealed_gate","THỨC TỈNH QUANG","ray",1,"gate","light_wings",{{.45,.9,1}},"magic",66)
add("seven_stars","THẤT TINH","star7",7,"starfall","seven_star",{cyan,gold},"star",28)
add("five_ley_lines","NGŨ MẠCH","orb",1,"ley","five_elements",colors,"electric",45)
add("endless_cycle","VÔ TẬN LUÂN","infinity",1,"infinity","infinite_waves",{violet,gold,cyan},"magic",64)
return C
