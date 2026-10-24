local T={}
local Deck=require("src.deck")
local Boss=require("src.boss_abilities")

function T.discard(game,cards,context)
    if context and context.preview then return end
    for _,card in ipairs(cards or {}) do card.heldEmpowerment=nil;card.discardSpeedBonus=nil end
    if not context or not context.playerDiscard then return end
    local A=require("src.card_abilities")
    local discarded,suits,speed={},{},0
    local result={kind="discard",count=0,heal=0,requestedHeal=0,gold=0,armor=0,speed=0,empowerment=0,targets={}}
    for _,card in ipairs(cards or {}) do discarded[card]=true end
    for _,card in ipairs(cards or {}) do
        local d=A.definition(card)
        if d and not card.destroyed and not Boss.isAbilityDisabled(game,card) then
            result.count=result.count+1
            suits[d.suit]=(suits[d.suit] or 0)+1
            local p=A.params(card,d)
            if d.suit=="heart" then
                local amount=(game.maxPlayerHp or 100)*p.healPercent/100
                result.requestedHeal=result.requestedHeal+amount
                result.heal=result.heal+require("src.player_health").heal(game,amount)
            elseif d.suit=="diamond" then game.gold=(game.gold or 0)+p.gold;result.gold=result.gold+p.gold
            elseif d.suit=="club" then speed=speed+p.speed
            elseif d.suit=="spade" then
                local amount=(game.maxPlayerHp or 100)*p.armorPercent/100
                game.playerArmor=(game.playerArmor or game.playerShield or 0)+amount
                result.armor=result.armor+amount
                game.playerShield=game.playerArmor
            end
        end
    end
    for _,card in ipairs(game.hand or {}) do
        if not discarded[card] and not card.destroyed then
            local d=A.definition(card)
            local empowerment=d and suits[d.suit] or 0
            card.heldEmpowerment=(card.heldEmpowerment or 0)+empowerment
            local beforeSpeed=Deck.peekCardAttackSpeed(card)
            card.discardSpeedBonus=(card.discardSpeedBonus or 0)+speed
            require("ui.progression_effects").emit(card,"speed",Deck.peekCardAttackSpeed(card)-beforeSpeed)
            Deck.getCardAttackSpeed(card)
            if speed>0 or empowerment>0 then
                result.targets[#result.targets+1]={card=card,speed=speed,empowerment=empowerment}
                result.empowerment=result.empowerment+empowerment
            end
        end
    end
    result.speed=#result.targets>0 and speed or 0
    if result.speed>0 then require("ui.progression_effects").team(game.hand) end
    if result.count>0 then
        result.count=#cards
        game.potionFeedback=game.potionFeedback or {}
        game.potionFeedback[#game.potionFeedback+1]=result
    end
end

function T.finishHand(game,played)
    local seen={}
    for _,pile in ipairs({game.hand or {},game.deck or {},game.discardPile or {},played or {}}) do
        for _,card in ipairs(pile) do
            if not seen[card] then
                seen[card]=true;card.discardSpeedBonus=nil;Deck.getCardAttackSpeed(card)
            end
        end
    end
    for _,card in ipairs(played or {}) do card.heldEmpowerment=nil end
end
return T
