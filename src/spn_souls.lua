local S={}
S.entries={
    {"spirit_dawn_reaper","Gặt Hồn Bình Minh","xSoulYield",2,"discard",
        "Trước lần đánh đầu của trận: chủ động bỏ đúng 1 lá, tiêu hủy lá đó và nhận ×{factor} giá trị linh hồn. Giữ ít nhất 1 lá."},
    {"spirit_soul_choir","Dàn Đồng Ca Linh Hồn","addMult",1,"hand",
        "Mỗi tay tính điểm: +{value} Cường hóa mỗi linh hồn đang giữ tại ô này; không tiêu linh hồn."},
}
function S.register(deities)
    for _,row in ipairs(S.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},trigger=row[5],descriptionTemplate=row[6],
            rarity="common",cost=4,lore="Dị linh của đoàn viễn chinh: linh hồn bị mất trở thành sức mạnh được gìn giữ."}
        entry.desc=row[6]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]));entry.baseDesc=entry.desc
        if entry.trigger=="discard" then
            entry.onDiscard=function(cards,context)
                if context and context.playerDiscard and not context.preview and context.handsPlayedBefore==0
                    and #cards==1 and not cards[1].destroyed then return {xSoulYield=1+entry.values.value} end
            end
        else
            entry.onHandScored=function(hand,context)
                context=context or {};local game=context.gameState or context
                local souls=math.max(0,context.soulsAvailable or game.souls or 0)
                if souls>0 then return {addMult=souls*entry.values.value,fixedMessage=true,message="ĐỒNG CA · "..souls.." LINH HỒN"} end
            end
        end
        deities.CATALOG[entry.id]=entry
    end
end
function S.harvest(game,card,owned,slot,multiplier)
    if card.destroyed or #(game.persistentDeck or {})<=1 then return false end
    local before=game.souls or 0
    if not require("src.card_abilities").destroy(game,card,nil,multiplier) then return false end
    require("src.chest_expansion").sync(game,card,function(copy) copy.destroyed=true;copy.destructionNotified=true end)
    require("src.combat").cleanupDestroyedCards(game)
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=owned,slot=slot,text="GẶT HỒN · +"..((game.souls or 0)-before).." LINH HỒN"}
    return true
end
return S
