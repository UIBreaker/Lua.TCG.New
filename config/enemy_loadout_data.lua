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
    roles={
        {name="Đấu sĩ",equipment={"itm_surveyhammer","blood_ring","basic_feather"},seal="seal_sunder",spn="spirit_echo"},
        {name="Hộ vệ",equipment={"ward_stone","crafted_guard","crafted_runner"},seal="seal_purifying",spn="spirit_ward"},
        {name="Quân y",equipment={"vitality_gem","crafted_runner","basic_feather"},seal="seal_blood",spn="spirit_ember"},
    },
}
