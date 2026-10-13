local G={entries={
    {"spirit_battle_memory","Dư Hồn Chiến Tích",4,"Mỗi quân ghi điểm nhận vĩnh viễn +{value} Sát thương cơ bản, đúng một lần mỗi quân trong mỗi tay. Tái kích hoạt không nhận thêm; tăng có hiệu lực ngay và giữ qua các trận."},
    {"spirit_golden_tithe","Kim Hồn Tụ Lực",10,"Mỗi tay tính điểm: +{value} Sát thương cho mỗi nhóm đủ 5 Vàng đang giữ. Không tiêu Vàng; phần lẻ không tính."},
}}
function G.register(D)
    for _,row in ipairs(G.entries) do
        local entry={id=row[1],name=row[2],stat="addChips",values={value=row[3]},descriptionTemplate=row[4],rarity="common",cost=4,
            trigger=row[1]=="spirit_battle_memory" and "card" or "hand",
            lore="Dị linh lưu giữ chiến tích hoặc kết sức mạnh từ của cải trên đường viễn chinh."}
        if entry.trigger=="card" then
            entry.onCardScored=function() return {addChips=4,permanentCardDamage=true,message="CHIẾN TÍCH · SÁT THƯƠNG VĨNH VIỄN"} end
        else
            entry.onHandScored=function(_,context)
                local gold=context.goldAvailable
                if gold==nil then gold=context.gameState and context.gameState.gold or context.gold or 0 end
                local groups=math.floor(math.max(0,gold)/5)
                if groups>0 then return {addChips=10*groups,message="KIM HỒN · "..groups.." NHÓM VÀNG"} end
            end
        end
        entry.desc=row[4]:gsub("{value}",tostring(row[3]));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
-- One claim per physical SPN activation and card identity, shared across the entire score queue.
-- Copied SPN activations stack; repeated card jobs never grant the same claim again.
function G.claim(game,card,result,claims,slot,activation)
    claims[slot]=claims[slot] or {};local source=claims[slot]
    source[activation]=source[activation] or {};local seen=source[activation]
    local key=card.id or card
    if seen[key] then return end
    seen[key]=true
    local amount=result.addChips
    require("src.chest_expansion").sync(game or {},card,function(c)
        c.baseChips=(c.baseChips or (c.isPrimalDrone and 50+(c.spnPermanentDamage or 0) or require("src.deck").getChipValue(c.rank)+(c.bonusBaseChips or 0)))+amount
        c.bonusBaseChips=(c.bonusBaseChips or 0)+amount
        c.spnPermanentDamage=(c.spnPermanentDamage or 0)+amount
    end)
    result.message="CHIẾN TÍCH · +"..amount.." ST VĨNH VIỄN"
    return result
end
return G
