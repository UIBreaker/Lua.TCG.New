local F={entries={
    {"spirit_soft_chant","Hồn Vũ","addMult",5,"Mỗi tay tính điểm: +{value} Cường hóa."},
    {"spirit_stone_fist","Thạch Quyền","addChips",20,"Mỗi tay tính điểm: +{value} Sát thương."},
    {"spirit_lightning_choice","Lôi Chỉ","addAttackSpeed",20,"Một lần đầu trận: một quân ngẫu nhiên trên tay nhận +{value} Tốc đánh tạm trong trận. Không tăng vĩnh viễn và không chọn lại mỗi lượt."},
    {"spirit_twin_oath","Song Hồn Đồng Ước","addMult",10,"Tay Đôi: +{value} Cường hóa; nếu hai quân tạo Đôi cùng chất, thay bằng +{double} Cường hóa. Không cộng hai thưởng; chỉ xét hai quân tạo Đôi."},
    {"spirit_second_wave","Dư Ảnh Nhị Khúc","addTwoRepeats",1,"Mỗi quân rank 2 ghi điểm kích hoạt tổng cộng {factor} lần, gồm lần gốc. Mỗi cấp SPN thêm 1 lần; dùng chung giới hạn 128 lượt kích hoạt/tay."},
}}
local Deck=require("src.deck")
local D
local function wild(card)
    return require("src.card_effects").getEffectName(card)=="astral"
        or not card.disableFactionPassives and (card.isWildSuit or ((card.rank==1 or card.rank==14) and (card.suit=="elaris" or card.suit=="clubs")))
end
function F.register(deities)
    D=deities
    for _,row in ipairs(F.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[1]=="spirit_lightning_choice" and "opening_hand" or row[1]=="spirit_second_wave" and "repeat" or "hand",
            lore="Một hộ linh giản dị dẫn nhịp, tăng lực hoặc tạo một tiếng vọng trong viễn chinh."}
        if entry.id=="spirit_second_wave" then entry.turnGrowth=true;entry.integerEffect=true
        elseif entry.trigger=="hand" then
            entry.onHandScored=function(hand)
                local amount=entry.values.value
                if entry.id=="spirit_twin_oath" then
                    local pair=hand and hand.scoringCards or {}
                    if not hand or not hand.type or hand.type.id~="pair" or #pair~=2 then return end
                    local first=Deck.SUITS[pair[1].suit] or pair[1].suit
                    local second=Deck.SUITS[pair[2].suit] or pair[2].suit
                    if first==second or wild(pair[1]) or wild(pair[2]) then amount=amount*2 end
                end
                return {[entry.stat]=amount,fixedMessage=true,message=entry.name.." · THƯỞNG TAY BÀI"}
            end
        end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4])):gsub("{double}",tostring(row[4]*2));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
function F.openingSpeed(game)
    D=D or require("src.deities")
    game.spnCombat=game.spnCombat or {}
    for slot=1,D.getMaxSlots(game) do
        local physical=game.deities and game.deities[slot]
        local memory=physical and game.spnCombat[physical] or {}
        if physical and not (memory and memory.openingSpeedGranted)
            and not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            local granted=false
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if source.id~="spirit_lightning_choice" then return end
                granted=true
                local pool={}
                for _,card in ipairs(game.hand or {}) do if not card.destroyed then pool[#pool+1]=card end end
                if #pool==0 then return end
                local target=pool[require("src.rng").random(#pool)]
                local speed=D.scaleEffect(source,{addAttackSpeed=20}).addAttackSpeed
                Deck.applyTemporaryAttackSpeedBonus(target,speed)
                game.spnFeedback=game.spnFeedback or {}
                game.spnFeedback[#game.spnFeedback+1]={deity=physical,slot=slot,text="LÔI CHỈ · "..target.rankName..target.suitSymbol.." +"..speed.." TỐC TẠM"}
            end)
            if granted then
                memory=memory or {};memory.openingSpeedGranted=true;game.spnCombat[physical]=memory
            end
        end
    end
end
return F
