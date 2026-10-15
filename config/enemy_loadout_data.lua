-- Enemy adapters use the existing card identities/art with percentage effects.
return {
    caps={hp=.20,damage=.40,speed=.20,armor=.20,heal=.08},
    editions={
        foil={name="Foil",power=.10,color={.65,.85,1}},
        holographic={name="Holographic",power=.20,color={.75,.55,1}},
        polychrome={name="Polychrome",power=.25,color={1,.65,.85}},
    },
    equipment={
        {id="itm_surveyhammer",cost=2,stats={damage=.15}},
        {id="blood_ring",cost=2,stats={damage=.20}},
        {id="ward_stone",cost=2,stats={armor=.10}},
        {id="crafted_guard",cost=2,stats={hp=.12}},
        {id="basic_feather",cost=1,stats={speed=.10}},
        {id="vitality_gem",cost=2,stats={heal=.04}},
        {id="crafted_runner",cost=2,stats={hp=.06,speed=.08}},
    },
    seals={
        {id="seal_purifying",cost=2,stat="supportArmor",pct=.06},
        {id="seal_blood",cost=2,stat="leech",pct=.04},
        {id="seal_sunder",cost=2,stat="pierce",pct=.15},
    },
    spns={
        {id="spirit_ember",cost=3,stat="support",pct=.20},
        {id="spirit_ward",cost=3,stat="supportArmor",pct=.06},
        {id="spirit_echo",cost=3,stat="echo",pct=.20},
    },
    consumables={
        {id="healing_potion",name="Bình Máu",cost=1,effect="heal",pct=.12},
        {id="armor_potion_small",name="Bình Giáp Nhỏ",cost=1,effect="armor",pct=.15},
        {id="cons_damage",name="Thuốc Sát Thương",cost=1,effect="damage",pct=.25},
        {id="cons_speed_single",name="Tăng Tốc Đơn",cost=1,effect="speed",pct=.25},
        {id="cons_speed_team",name="Tăng Tốc Đội",cost=2,effect="speed",pct=.15,team=true},
        {id="cons_accuracy",name="Thuốc Chính Xác",cost=1,effect="accuracy"},
    },
    roles={
        {name="Đấu sĩ",equipment={"itm_surveyhammer","blood_ring","basic_feather"},seal="seal_sunder",spn="spirit_echo",
            supplies={"cons_damage","cons_accuracy","cons_speed_single","healing_potion"}},
        {name="Hộ vệ",equipment={"ward_stone","crafted_guard","crafted_runner"},seal="seal_purifying",spn="spirit_ward",
            supplies={"armor_potion_small","healing_potion","cons_speed_single","cons_accuracy"}},
        {name="Quân y",equipment={"vitality_gem","crafted_runner","basic_feather"},seal="seal_blood",spn="spirit_ember",
            supplies={"healing_potion","cons_speed_team","armor_potion_small","cons_accuracy"}},
    },
}
