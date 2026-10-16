local F={entries={
    {"spirit_march_covenant","Quân Lộ Sinh Linh","addChips",50,"Đánh thế Đường Hành Quân: +{value} Sát thương và hồi {heal}% máu tối đa. Chỉ thế Sảnh đang được tính điểm; không tính thế khác chứa Sảnh."},
    {"spirit_vanguard_reprise","Tiên Quân Hồi Trận","addFormationRepeats",1,"Đánh đúng 5 quân: mỗi quân ghi điểm kích hoạt tổng cộng giá trị quân đầu theo thứ tự đánh ×{value} lần, gồm lần gốc. A=1, J=11, Q=12, K=13. Không lặp điểm nền/SPN theo tay; chung trần 128 lượt/tay."},
    {"spirit_breath_of_mercy","Từ Tức Sinh Linh","addHealPct",5,"Mỗi tay đánh: hồi {value}% máu tối đa. Không vượt máu tối đa; không hồi máu ảo. Tái kích hoạt quân không hồi thêm."},
    {"spirit_fourfold_edge","Tứ Ảnh Chiến Phong","xChips",1,"Đánh đúng 4 quân: mỗi lần một quân ghi điểm, nhân ×{factor} phần Sát thương đóng góp của riêng quân đó, gồm thưởng thuốc, trang bị và SPN theo quân. Không nhân điểm nền thế hay SPN theo tay; không đổi chỉ số vĩnh viễn."},
    {"spirit_quartet_oath","Tứ Trụ Đồng Tâm","xMult",3,"Đánh đúng 4 quân cùng số: cùng chất thì ×{factor} Sát thương; khác chất thì ×{factor} Cường hóa. Chỉ một nhánh, không cộng dồn. Tính quân đã chơi, gồm cả quân không ghi điểm."},
}}
local D
local function each(game,list,fn)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game or list) do
        if not game or not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,list,slot,function(source) fn(source,slot) end)
        end
    end
end
function F.played(hand)
    if hand.playedCards then return hand.playedCards end
    local cards={}
    for _,pile in ipairs({hand.scoringCards or {},hand.unscoredCards or {}}) do for _,card in ipairs(pile) do cards[#cards+1]=card end end
    return cards
end
local function rank(card) return card.rank==14 and 1 or card.rank end
local function sameSuit(cards)
    local suit
    for _,card in ipairs(cards) do
        local wild=require("src.card_effects").getEffectName(card)=="astral"
            or not card.disableFactionPassives and (card.isWildSuit or rank(card)==1 and (card.suit=="clubs" or card.suit=="elaris"))
        if not wild then
            local id=require("src.deck").SUITS[card.suit] or card.suit
            if suit and suit~=id then return false end;suit=id
        end
    end
    return true
end
function F.register(deities)
    D=deities
    for _,row in ipairs(F.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[1]=="spirit_vanguard_reprise" and "repeat" or row[1]=="spirit_fourfold_edge" and "card" or "hand",
            lore="Dị linh của đoàn viễn chinh biến đội hình, tiếng vọng và lòng đồng đội thành sức mạnh."}
        if entry.id=="spirit_vanguard_reprise" then entry.turnGrowth=true;entry.integerEffect=true
        elseif entry.id=="spirit_march_covenant" or entry.id=="spirit_breath_of_mercy" then
            entry.onHandScored=function(hand,context)
                if entry.id=="spirit_march_covenant" and (not hand.type or hand.type.id~="straight") then return end
                local hp=(context.gameState or context).maxPlayerHp or 100
                return {addChips=entry.id=="spirit_march_covenant" and 50 or nil,addHealHp=hp*.05,
                    fixedMessage=true,message=entry.name.." · HỒI MÁU THEO HP TỐI ĐA"}
            end
        elseif entry.id=="spirit_quartet_oath" then
            entry.onHandScored=function(hand)
                local cards=F.played(hand);if #cards~=4 then return end
                for i=2,4 do if rank(cards[i])~=rank(cards[1]) then return end end
                if sameSuit(cards) then return {xChips=4,fixedMessage=true,message="TỨ TRỤ · CÙNG SỐ CÙNG CHẤT · NHÂN ST"} end
                return {xMult=4,fixedMessage=true,message="TỨ TRỤ · CÙNG SỐ KHÁC CHẤT · NHÂN CƯỜNG HÓA"}
            end
        end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4])):gsub("{heal}","5");entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
    end
end
function F.queueRepeats(game,cards,queue,hand)
    if not game then return end
    local ctx=game.abilityHand;local live=ctx and not ctx.finished
    local played=live and ctx.played or hand and F.played(hand) or cards or {}
    if #played~=5 then return end
    local first=math.max(1,math.min(13,rank(played[1]) or 1))
    local cap=require("config.card_ability_data").maxTriggersPerHand
    each(game,game.deities,function(source,slot)
        if source.id~="spirit_vanguard_reprise" then return end
        local total=math.max(1,math.floor(first*D.scaleEffect(source,{addFormationRepeats=1}).addFormationRepeats))
        for _=1,math.min(total-1,cap) do
            for index,card in ipairs(cards or {}) do
                if #queue>=cap then return end
                if not card.destroyed and not card.exhausted then queue[#queue+1]={card=card,index=index,depth=1,retrigger=true,effectiveness=1} end
            end
        end
    end)
end
function F.scaleCard(hand,list,game,card,index,event,before,amount)
    if #F.played(hand)~=4 then return amount end
    each(game,list,function(source,slot)
        if source.id~="spirit_fourfold_edge" then return end
        local factor=D.scaleEffect(source,{xChips=2}).xChips
        local extra=(amount-before)*(factor-1);amount=amount+extra
        event.addedChips=event.addedChips+extra
        event.presentationTriggers=event.presentationTriggers or {}
        event.presentationTriggers[#event.presentationTriggers+1]={type="deity_card",card=card,cardIndex=index,slotIndex=slot,
            deity=list[slot],addedChips=extra,xChips=factor,message="TỨ ẢNH · ×"..factor.." ST CỦA QUÂN"}
    end)
    return amount
end
return F
