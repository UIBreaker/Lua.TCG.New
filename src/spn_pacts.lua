local P={entries={
    {"spirit_fated_mark","Ấn Mệnh","xMult",9,"Chơi đúng 1 quân bài được chỉ định từ bộ bài đầu trận: ×{factor} Cường hóa. Mục tiêu là quân bài cụ thể, không chỉ rank/chất."},
    {"spirit_threefold_ward","Tam Vật Hộ Mệnh","addArmor",40,"Bỏ đúng 3 quân bài được chỉ định từ bộ bài đầu trận trong cùng một lần: +{value} Giáp. Chỉ tính bỏ bài chủ động."},
    {"spirit_awakened_echo","Vọng Âm Tiến Hóa","repeatsPerLevel",1,"Mỗi quân bài ghi điểm kích hoạt tổng cộng cấp tiến hóa ×{value} lần, gồm lần gốc; cấp 0 vẫn 1 lần. Mỗi cấp SPN thêm 1 hệ số. Tối đa 128 lượt kích hoạt/tay cùng mọi nguồn khác."},
    {"spirit_blood_bargain","Huyết Khế Đổi Vận","uqChancePct",0.5,"Hết lượt bỏ: trả 20 HP để bỏ bài, cần còn hơn 20 HP. Mỗi lần bỏ bằng máu: {value}% nâng 1 SPN trang bị ngẫu nhiên lên đúng UQ, giữ cấp tiến hóa. Tiến hóa tăng xác suất; tối đa 100%."},
}}
local Boss=require("src.boss_abilities")
local Rng=require("src.rng")
local D
local function active(game,fn)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local physical=game.deities and game.deities[slot]
        if physical and not Boss.isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source) fn(source,slot,physical) end)
        end
    end
end
local function targetSize(owned)
    return owned.id=="spirit_fated_mark" and 1 or owned.id=="spirit_threefold_ward" and 3 or nil
end
function P.targets(game,owned)
    local need=targetSize(owned)
    if not game or not need then return {} end
    game.spnCombat=game.spnCombat or {}
    local state=game.spnCombat[owned]
    if state and state.pactTargets then return state.pactTargets end
    local pool,seen={},{}
    for _,card in ipairs(game.persistentDeck or game.masterDeck or {}) do
        if card.id and not card.destroyed and not seen[card.id] then pool[#pool+1]=card.id;seen[card.id]=true end
    end
    local ids={}
    if #pool>=need then
        for i=1,need do ids[i]=table.remove(pool,Rng.random(#pool)) end
    end
    state=state or {};state.pactTargets=ids;game.spnCombat[owned]=state
    return ids
end
function P.prepare(game)
    active(game,function(source) if targetSize(source) then P.targets(game,source) end end)
end
function P.register(deities)
    D=deities
    for _,row in ipairs(P.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            lore="Dị linh lục địa buộc vận mệnh vào một quân bài, một tiếng vọng hoặc một khế ước bằng máu."}
        if entry.id=="spirit_fated_mark" then
            entry.trigger="hand"
            entry.onHandScored=function(hand,context,owned)
                if #(hand.scoringCards or {})+#(hand.unscoredCards or {})~=1 then return end
                local card=(hand.scoringCards or {})[1] or (hand.unscoredCards or {})[1]
                local ids=P.targets(context and context.gameState,owned or entry)
                if card and card.id==ids[1] then return {xMult=10,fixedMessage=true,message="ẤN MỆNH · ĐÚNG QUÂN ĐƯỢC CHỌN"} end
            end
        elseif entry.id=="spirit_threefold_ward" then
            entry.trigger="discard"
            entry.onDiscard=function(cards,context,owned)
                if not context or not context.playerDiscard or context.preview or #cards~=3 then return end
                local ids=P.targets(context.gameState,owned or entry)
                if #ids~=3 then return end
                local selected={};for _,card in ipairs(cards) do selected[card.id]=true end
                for _,id in ipairs(ids) do if not selected[id] then return end end
                return {addArmor=40}
            end
        elseif entry.id=="spirit_awakened_echo" then entry.trigger="repeat";entry.integerEffect=true
        else entry.trigger="blood_discard" end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
function P.queueRepeats(game,cards,queue,handInfo)
    if not game then return end
    local cap=require("config.card_ability_data").maxTriggersPerHand
    active(game,function(source)
        if source.id=="spirit_awakened_echo" or source.id=="spirit_second_wave" then
            local coefficient=source.id=="spirit_awakened_echo"
                and D.scaleEffect(source,{repeatsPerLevel=1}).repeatsPerLevel
                or D.scaleEffect(source,{addTwoRepeats=1}).addTwoRepeats
            for index,card in ipairs(cards or {}) do
                local level=math.max(0,math.floor(tonumber(card.evolutionLevel) or 0))
                local repeats=source.id=="spirit_awakened_echo" and math.max(0,level*coefficient-1) or (card.rank==2 and coefficient or 0)
                if not card.destroyed and not card.exhausted then
                    for i=1,repeats do
                        if #queue>=cap then break end
                        -- This SPN queues once per hand; repeated jobs never queue more copies.
                        queue[#queue+1]={card=card,index=index,depth=1,retrigger=true,effectiveness=1}
                    end
                end
            end
        end
    end)
    require("src.spn_reserves").queueRepeats(game,cards,queue,handInfo)
    require("src.spn_formations").queueRepeats(game,cards,queue,handInfo)
end
function P.bloodEnabled(game)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local source=D.resolveDeity(game.deities,slot,game)
        if source and source.id=="spirit_blood_bargain" and not Boss.isSlotLocked(game,"spn",slot) then
            return true,slot,game.deities[slot]
        end
    end
    return false
end
function P.canDiscard(game)
    return require("src.deck").freeSealDiscard(game) or (game.discardsRemaining or 0)>0 or (game.playerHp or 0)>20 and P.bloodEnabled(game)
end
function P.payDiscard(game)
    if require("src.deck").freeSealDiscard(game) then return false end
    if (game.discardsRemaining or 0)>0 then return false end
    if not P.canDiscard(game) then return nil end
    local _,slot,physical=P.bloodEnabled(game)
    game.playerHp=game.playerHp-20
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=physical,slot=slot,text="HUYẾT KHẾ · -20 HP ĐỂ BỎ BÀI"}
    require("src.potions").payBlood(game,game.playerHp+20)
    return true
end
function P.bloodReward(game)
    -- Keep physical candidates outside mimic's temporary source substitution.
    local equipped={}
    for slot=1,D.getMaxSlots(game) do
        local owned=game.deities and game.deities[slot]
        if owned then equipped[#equipped+1]=owned end
    end
    active(game,function(source,slot,physical)
        if source.id=="spirit_blood_bargain" then
            local eligible={}
            for _,owned in ipairs(equipped) do if D.getRarityTier(owned)<8 then eligible[#eligible+1]=owned end end
            if #eligible==0 then return end
            local chance=D.scaleEffect(source,{uqChancePct=.5}).uqChancePct
            if Rng.random()*100<chance then
                local target=eligible[Rng.random(#eligible)]
                local level=math.max(0,math.floor(tonumber(target.evolutionLevel) or 0))
                D.setRarity(target,D.RARITIES[8-level].id);target.rarity="unique"
                game.spnFeedback=game.spnFeedback or {}
                game.spnFeedback[#game.spnFeedback+1]={deity=physical,slot=slot,text="HUYẾT KHẾ · "..target.name.." → UQ"}
            end
        end
    end)
end
local function names(game,ids)
    local list={}
    for _,id in ipairs(ids) do
        local label="Quân #"..id.." (đã mất)"
        for _,card in ipairs(game.persistentDeck or {}) do if card.id==id then label=(card.rankName or card.rank)..(card.suitSymbol or card.suit).." #"..id;break end end
        list[#list+1]=label
    end
    return table.concat(list,", ")
end
function P.describe(game,item)
    if not game or not targetSize(item) then return nil end
    local state=game.spnCombat and game.spnCombat[item]
    if not state then return "Mục tiêu được chọn ngẫu nhiên từ bộ bài khi vào trận hoặc trang bị trong trận." end
    if #state.pactTargets==0 then return "Không đủ quân bài khác nhau để chỉ định mục tiêu trong trận này." end
    return "CHỈ ĐỊNH · "..names(game,state.pactTargets)
end
function P.cardMark(game,card)
    if not game then return nil end
    local matches={}
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local source=D.resolveDeity(game.deities,slot,game)
        local physical=game.deities and game.deities[slot]
        local state=game.spnCombat and game.spnCombat[source]
        for _,id in ipairs(state and state.pactTargets or {}) do
            if id==card.id and not Boss.isSlotLocked(game,"spn",slot) then matches[#matches+1]=physical.name.." (ô "..slot..")" end
        end
    end
    return #matches>0 and ("CHỈ ĐỊNH · "..table.concat(matches,", ")) or nil
end
return P
