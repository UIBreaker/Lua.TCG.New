local R={entries={
    {"spirit_ashen_legacy","Tàn Linh Thừa Diệt","addDeathChips",.5,"Mỗi SPN khác thực sự bị tiêu hủy khi lá này đang trang bị và không bị khóa: tích vĩnh viễn +{value} vào hệ số Sát thương. Bắt đầu ×1; giữ qua trận và lưu game. Bán/cất không tính. Tiến hóa tăng lượng tích về sau."},
    {"spirit_unspent_fury","Dư Lực Chưa Xả","addChips",50,"Khi ghi điểm: +{value} Sát thương cho mỗi lượt bỏ bài còn lại tại ô này. Không tiêu lượt bỏ."},
    {"spirit_gilded_weight","Kim Trọng Hư Linh","addGoldChips",.25,"Khi ghi điểm: hệ số nhân Sát thương = {value} × số Vàng hiện có tại ô này. Không cộng nền ×1, không tiêu Vàng. Có thể giảm Sát thương; 0 Vàng là ×0."},
    {"spirit_open_horizon","Linh Vực Khai Thủ","addHandSize",1,"Khi trang bị và không bị khóa: kích thước tay bài +{value}. Mỗi cấp tiến hóa thêm 1 chỗ; không cộng vĩnh viễn vào kích thước gốc."},
    {"spirit_lone_procession","Độc Âm Vạn Ảnh","addSoloRepeats",1,"Chơi đúng 1 quân: tái kích hoạt thêm quân đó số lần bằng số quân đang cầm trước khi đánh ×{value}. Tính cả quân đã chọn; ngoài lần gốc. Mỗi cấp SPN thêm 1 hệ số; tổng tối đa 128 lượt kích hoạt/tay cùng các nguồn khác."},
}}
local D
local function active(game,fn)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source) fn(source,slot) end)
        end
    end
end
local function notice(game,source,slot,text)
    game.spnFeedback=game.spnFeedback or {};game.spnFeedback[#game.spnFeedback+1]={deity=source,slot=slot,text=text}
end
function R.register(deities)
    D=deities
    for _,row in ipairs(R.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[1]=="spirit_open_horizon" and "capacity" or row[1]=="spirit_lone_procession" and "repeat" or "hand",
            lore="Dị linh thu sức mạnh từ những mất mát, cơ hội chưa dùng và những quân bài còn chờ trên tay."}
        if entry.id=="spirit_ashen_legacy" then
            entry.onHandScored=function() return {deathChips=true,fixedMessage=true,message="THỪA DIỆT · SÁT THƯƠNG TÍCH LŨY"} end
        elseif entry.id=="spirit_unspent_fury" then
            entry.onHandScored=function(_,context)
                local count=math.max(0,context.discardsAvailable or context.gameState and context.gameState.discardsRemaining or context.discardsRemaining or 0)
                return {addChips=50*count,fixedMessage=true,message="DƯ LỰC · "..count.." LƯỢT BỎ CÒN LẠI"}
            end
        elseif entry.id=="spirit_gilded_weight" then
            entry.onHandScored=function(_,context)
                local gold=math.max(0,context.goldAvailable or context.gameState and context.gameState.gold or context.gold or 0)
                return {addGoldChips=.25,goldChips=gold,fixedMessage=true,message="KIM TRỌNG · "..gold.." VÀNG"}
            end
        else entry.turnGrowth=true;entry.integerEffect=true end
        entry.desc=row[5]:gsub("{value}",tostring(row[4]));entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
    end
end
function R.destroyed(game)
    active(game,function(source,slot)
        if source.id~="spirit_ashen_legacy" then return end
        local gain=D.scaleEffect(source,{addDeathChips=.5}).addDeathChips
        source.spnGrowth=source.spnGrowth or {}
        source.spnGrowth.deathChips=(source.spnGrowth.deathChips or 0)+gain
        notice(game,source,slot,"THỪA DIỆT · +"..gain.." HỆ SỐ ST · ×"..(1+source.spnGrowth.deathChips))
    end)
end
function R.scored(source,result)
    -- Saved totals and a direct gold coefficient must bypass bonus-above-one scaling.
    if result.deathChips then result.xChips=1+((source.spnGrowth or {}).deathChips or 0) end
    if result.goldChips then
        result.xChips=result.addGoldChips*result.goldChips
        result.message="KIM TRỌNG · "..result.goldChips.." VÀNG · ×"..string.format("%g",result.xChips).." ST"
    end
    return result
end
function R.handSize(game)
    D=D or require("src.deities")
    local bonus=0
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            local source,count=D.resolveDeity(game.deities,slot,game)
            if source and source.id=="spirit_open_horizon" then bonus=bonus+D.scaleEffect(source,{addHandSize=1}).addHandSize*count end
        end
    end
    return bonus
end
function R.heldCount(game,played)
    local count,seen=0,{}
    for _,pile in ipairs({game.hand or {},played or {}}) do
        for _,card in ipairs(pile) do local key=card.id or card
            if not card.destroyed and not require("src.boss_abilities").isAbilityDisabled(game,card) and not seen[key] then seen[key]=true;count=count+1 end
        end
    end
    return count
end
function R.queueRepeats(game,cards,queue,handInfo)
    local ctx=game.abilityHand
    local live=ctx and not ctx.finished
    local played=live and ctx.played or cards or {}
    local playedCount=handInfo and #(handInfo.scoringCards or {})+#(handInfo.unscoredCards or {}) or #played
    if playedCount~=1 or #(cards or {})~=1 or cards[1].destroyed or cards[1].exhausted then return end
    local held=live and ctx.spnHeldBeforePlay or R.heldCount(game,played)
    local cap=require("config.card_ability_data").maxTriggersPerHand
    active(game,function(source,slot)
        if source.id~="spirit_lone_procession" then return end
        local repeats=math.min(cap-#queue,math.floor(held*D.scaleEffect(source,{addSoloRepeats=1}).addSoloRepeats))
        for _=1,repeats do queue[#queue+1]={card=cards[1],index=1,depth=1,retrigger=true,effectiveness=1} end
        if repeats>0 then notice(game,source,slot,"ĐỘC ÂM · "..held.." QUÂN TRÊN TAY · +"..repeats.." LẦN") end
    end)
end
return R
