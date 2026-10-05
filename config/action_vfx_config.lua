-- Small, local action accents. World combat/shopping animations retain ownership.
return {
    cap=24, maxScale=1.35,
    profiles={
        armor_gain={duration=0.52,contact=0.1,pitch=1.06,color={0.35,0.80,1},sound="equip"},
        armor_loss={duration=0.46,contact=0.025,pitch=1.35,color={0.65,0.86,1},sound="card_destroy"},
        heal={duration=0.7,contact=0.17,pitch=0.92,color={0.38,1,0.65},sound="consume"},
        hurt={duration=0.3,contact=0,pitch=1,color={1,0.27,0.35},sound="damage_hit"},
        equip={duration=0.48,contact=0,pitch=1,color={1,0.77,0.34},sound="equip"},
        destroy={duration=0.64,contact=0.045,pitch=0.88,color={1,0.43,0.16},sound="card_destroy"},
        enemy_first={duration=0.6,contact=0.04,pitch=0.9,color={1,0.37,0.29},sound="card_play",label="QUÁI RA ĐÒN TRƯỚC"},
        player_first={duration=0.58,contact=0.06,pitch=1.08,color={0.46,0.86,1},sound="card_slide",label="BẠN RA ĐÒN TRƯỚC"},
        buy={duration=0.44,contact=0,pitch=1.1,color={1,0.82,0.38},sound="shop_buy"},
        sell={duration=0.52,contact=0.08,pitch=1.04,color={1,0.66,0.27},sound="sell"},
    },
}
