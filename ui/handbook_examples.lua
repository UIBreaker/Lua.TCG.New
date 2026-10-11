-- Illustrations use ordinary cards, without faction passives or equipment.
local E = {}
local suits = {"hearts", "clubs", "spades", "diamonds", "hearts"}
local presets = {
    straight_flush={{6,7,8,9,10},{"hearts","hearts","hearts","hearts","hearts"}},
    four_of_a_kind={{9,9,9,9,2},{"hearts","clubs","spades","diamonds","hearts"}},
    full_house={{9,9,9,4,4}}, flush={{2,5,8,11,13},{"hearts","hearts","hearts","hearts","hearts"}},
    straight={{6,7,8,9,10}}, three_of_a_kind={{9,9,9,4,2}},
    two_pair={{9,9,4,4,2}}, pair={{9,9,5,3,2}}, high_card={{14,11,8,5,2}},
    tesla_369={{3,6,9,2,4},{"hearts","hearts","hearts","clubs","spades"}},
    jackpot_777={{7,7,7,2,4}}, fibonacci={{14,2,3,5,8}}, prime={{2,3,5,7,11}},
    odd_star={{14,3,5,7,9}}, even_frost={{2,4,6,8,10}},
    crimson_tide={{3,5,7,9,11},{"hearts","diamonds","hearts","diamonds","hearts"}},
    obsidian_tide={{3,5,7,9,11},{"spades","clubs","spades","clubs","spades"}},
    eclipse_duality={{2,4,9,4,2},{"hearts","diamonds","hearts","clubs","spades"}},
    four_kingdom_prism={{2,4,6,9,13}}, four_kingdom_expedition={{14,2,4,6,13}},
    destiny_crown={{10,11,12,13,14}}, continental_gate={{14,14,14,14,13}},
    answer_42={{4,6,9,10,13}}, sealed_gate={{14,14,14,13,13}},
    seven_stars={{7,7,7,14,13}}, five_ley_lines={{14,4,8,10,13}},
    endless_cycle={{2,3,4,5,6},{"hearts","clubs","spades","diamonds","hearts"}},
}
E.conditions = {
    straight_flush="5 lá liên tiếp và cùng chất.", four_of_a_kind="4 lá cùng số.",
    full_house="3 lá cùng số và 2 lá cùng số khác.", flush="5 lá cùng chất.",
    straight="5 lá liên tiếp; cũng có thể đánh Sảnh bằng đúng 3 lá liên tiếp. A đứng đầu hoặc cuối sảnh.",
    three_of_a_kind="3 lá cùng số.", two_pair="2 đôi khác số nhau.", pair="2 lá cùng số.",
    high_card="Khi không tạo thế cao hơn, chỉ lá có số lớn nhất ghi điểm.",
}
function E.get(id)
    local preset=assert(presets[id],"Missing handbook example: "..tostring(id))
    local cards={}
    for i,rank in ipairs(preset[1]) do
        cards[i]={rank=rank,suit=(preset[2] or suits)[i],disableFactionPassives=true}
    end
    local result=require("src.poker").evaluate(cards,{[id]=true,high_card=true})
    assert(result.type.id==id,"Invalid handbook example: "..id)
    local scored={}
    for _,card in ipairs(result.scoringCards) do scored[card]=true end
    return cards,scored
end
return E
