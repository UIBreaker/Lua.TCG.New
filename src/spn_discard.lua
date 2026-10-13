local Deck=require("src.deck")
local Boss=require("src.boss_abilities")
local S={}
local D
local function clone(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local copy={};seen[value]=copy
    for k,v in pairs(value) do copy[k]=clone(v,seen) end
    return copy
end
function S.register(deities)
    D=deities
    local entry={id="spirit_last_remnant",name="Dư Ảnh Cuối",stat="discardCopies",values={value=1},integerEffect=true,
        rarity="common",cost=4,trigger="discard",lore="Dị điểu tro bạc lưu giữ hình bóng cuối cùng trước khi nó tan biến.",
        descriptionTemplate="Lượt bỏ cuối: bỏ đúng 1 lá và tiêu lượt bỏ, tạo {value} bản sao vĩnh viễn vào cọc bỏ, giữ nâng cấp. Mỗi cấp tiến hóa thêm 1 bản sao."}
    entry.desc=entry.descriptionTemplate:gsub("{value}","1");entry.baseDesc=entry.desc
    entry.onDiscard=function(cards,context)
        if context and context.playerDiscard and not context.freeDiscard and not context.preview
            and context.remainingBefore==1 and #cards==1 and not cards[1].destroyed then
            return {discardCopies=1}
        end
    end
    D.CATALOG[entry.id]=entry
end
function S.discard(game,cards,context)
    local created={}
    if not context or not context.playerDiscard or context.preview then return created end
    context.gameState=game
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local owned=game.deities and game.deities[slot]
        require("src.spn_mimic").each(game,game.deities,slot,function(effective)
        if effective and effective.onDiscard and not Boss.isSlotLocked(game,"spn",slot) then
            local result=D.scaleEffect(effective,effective.onDiscard(cards,context,effective,slot))
            if result and result.addArmor then
                game.playerArmor=math.min(require("config.card_ability_data").armorCap,(game.playerArmor or game.playerShield or 0)+result.addArmor)
                game.playerShield=game.playerArmor
                game.spnFeedback=game.spnFeedback or {}
                game.spnFeedback[#game.spnFeedback+1]={deity=owned,slot=slot,text="ĐỦ BA MỤC TIÊU · +"..result.addArmor.." GIÁP"}
            elseif result and result.xSoulYield then
                require("src.spn_souls").harvest(game,cards[1],owned,slot,result.xSoulYield)
            elseif result and result.discardCopies then
                local source=cards[1]
                for _,card in ipairs(game.persistentDeck or {}) do if card.id==source.id then source=card;break end end
                if not source.destroyed then
                    game.discardPile=game.discardPile or {}
                    for i=1,result.discardCopies do
                        local permanent=Deck.cloneCard(source)
                        permanent.id=Deck.newCard(source.baseRank or source.rank,source.suit).id
                        permanent.selected=false;permanent.hovered=false;permanent.faceDown=false;permanent.exhausted=false
                        permanent.equipments=clone(permanent.equipments)
                        Deck.addCardToDeck(game,permanent)
                        local live=Deck.cloneCard(permanent);live.equipments=clone(permanent.equipments)
                        game.discardPile[#game.discardPile+1]=live;created[#created+1]=live
                    end
                    game.spnFeedback=game.spnFeedback or {}
                    game.spnFeedback[#game.spnFeedback+1]={deity=owned,slot=slot,text="NHÂN BẢN · "..result.discardCopies.." × "..source.rankName..source.suitSymbol}
                end
            end
        end
        end)
    end
    return created
end
return S
