-- Each hand has its own material, contact rhythm and interval pattern.
local function score(material,body,tone,rhythm,notes,label,tail,density)
    return {material=material,body=body,tone=tone,rhythm=rhythm,notes=notes,label=label,tail=tail or .32,density=density}
end
return {
    high_card=score("lance",94,460,{0},{1},"Một mũi giáo xuyên giáp, vó ngựa trầm"),
    pair=score("metal",78,580,{0,.085},{1,1.5},"Hai hộ vệ giao binh, hai tiếng thép đối đáp"),
    two_pair=score("blade",83,760,{0,.038,.115,.153},{1,1.33,.89,1.5},"Bốn nhát kẹp sườn trái phải"),
    three_of_a_kind=score("shot",88,1120,{0,.065,.13},{1,1.25,1.5},"Ba mũi giáo phóng xuyên, ba nhát khí nén"),
    straight=score("hoof",105,260,{0,.044,.088,.132,.176},{1,1.12,1.25,1.33,1.5},"Năm nhịp hành quân tăng dần"),
    flush=score("banner",72,340,{0,.16},{1,1.5},"Lá cờ quật gió, sóng khí rộng",.46),
    full_house=score("cannon",57,145,{0,.12},{1,.75},"Pháo đài khai hỏa, gạch đá đổ vỡ",.52),
    four_of_a_kind=score("pillar",64,210,{0,.052,.104,.156},{1,.84,.75,.63},"Bốn trụ đá giáng xuống, nhịp trầm đi dần",.40),
    straight_flush=score("royal",76,293.66,{0,.11},{1,2},"Giáo hoàng gia xuyên dọc hợp âm kèn",.58),
    tesla_369=score("lightning",62,1680,{0,.059,.139},{1,1.28,.77},"Ba hồ quang nổ điện, sấm theo sau",.43),
    jackpot_777=score("coin",97,1174.66,{0,.075,.15},{1,1.5,2},"Ba khóa vàng bật mở, tiền kim loại ngân",.45),
    fibonacci=score("growth",88,392,{0,.038,.100,.200,.360},{1,1.12,1.33,1.5,2},"Năm vòng sự sống nở theo khoảng giãn",.33),
    prime=score("star",102,1320,{0,.043,.137,.251,.389},{1,1.17,1.41,1.73,2.09},"Năm ngôi sao độc lập, nhịp rời và sắc",.22),
    odd_star=score("sun",86,660,{0,.027,.054,.081,.108,.135,.162,.189,.216},{1,1.12,1.25,1.33,1.5,1.67,1.88,2,2.25},"Chín tia bình minh xòe thành quầng sáng",.29),
    even_frost=score("ice",91,980,{0,.035,.09,.19},{1,1.9,1.26,2.02},"Mũi khoan băng nghiền rồi vỡ giòn",.38),
    crimson_tide=score("blood",108,180,{0,.145,.28},{1,.84,.75},"Ba lớp sóng đặc, bọt trầm và hút ngược",.43),
    obsidian_tide=score("obsidian",59,320,{0,.065,.145,.21},{1,1.41,.79,1.12},"Đá đen cào sắc và vỡ thành mảnh",.35),
    eclipse_duality=score("eclipse",68,183,{0,.23},{1,1.022},"Hai đĩa cộng hưởng lệch pha rồi hội tụ",.62),
    four_kingdom_prism=score("prism",112,880,{0,.037,.075,.11},{1,1.5,2.25,3},"Bốn tia lăng kính, bốn tiếng thủy tinh",.38),
    four_kingdom_expedition=score("army",81,196,{0,.085,.17,.255},{1,1.5,1.33,2},"Bốn hồi quân hiệu trên tiếng trống trận",.34),
    destiny_crown=score("judgement",66,349.23,{0,.135},{1,1.5},"Lưỡi kiếm phán quyết, chuông và hợp âm uy nghi",.60),
    continental_gate=score("gate",49,138.59,{0,.18,.39},{1,.75,.5},"Cổng đá cổ nghiến và đóng sập, vang sâu",.65,{.18,.65,.95}),
    answer_42=score("map",117,740,{0,.04,.08,.12,.23,.34},{1,1.25,1.5,2,1.33,1},"Bản đồ phát tín hiệu bốn nhịp cộng hai",.25),
    sealed_gate=score("forge",73,164.81,{0,.075,.22},{1,2.76,1.5},"Rút đại kiếm khỏi cổng sắt, chốt khóa bật",.48),
    seven_stars=score("falling",98,1760,{0,.04,.09,.15,.22,.30,.39},{1,.94,.84,.75,.67,.59,.5},"Bảy sao rít xuống, cao độ rơi từng nhịp",.28),
    five_ley_lines=score("earth",54,130.81,{0,.055,.11,.18,.27},{1,1.12,1.33,1.5,2},"Năm mạch đất trồi, đá và năng lượng trầm",.44),
    endless_cycle=score("vortex",61,246.94,{0,.21,.42},{1,.75,.5},"Hai vòng xoáy hút vào, khép bằng cú nén không gian",.44,{.18,1.3,1.7}),
}
