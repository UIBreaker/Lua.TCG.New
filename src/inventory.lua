local Inventory = {}
function Inventory.limit(game)
    return math.max(3,math.floor(tonumber(game and game.maxConsumables) or 3))
end
function Inventory.useBed(game,index,target)
    local card=game.consumables and game.consumables[index]
    if not card or card.category~="bed" then return false end
    if target then
        local present=false
        for _,enemy in ipairs(require("src.enemy_group").members(game)) do if enemy==target then present=true end end
        if not present or target.hp<=0 or target.hasBed then return false end
        target.hasBed=true
    else
        local maximum=game.maxPlayerHp or 100
        if (game.playerHp or maximum)>=maximum then return false end
        game.playerHp=maximum
    end
    table.remove(game.consumables,index)
    return true
end
-- Returns nil for other consumables, false when no effect can be applied.
function Inventory.useUtility(game,index)
    local card=game.consumables and game.consumables[index]
    if not card then return nil end
    if card.category=="slot_expansion" then
        if card.slotType=="spn" then game.extraDeitySlots=(game.extraDeitySlots or 0)+1
        elseif card.slotType=="consumable" then game.maxConsumables=Inventory.limit(game)+1
        else return false end
    elseif card.category=="heal" then
        local maximum=game.maxPlayerHp or 100
        if (game.playerHp or maximum)>=maximum then return false end
        game.playerHp=math.min(maximum,(game.playerHp or maximum)+(card.healAmt or 25))
    elseif card.category=="armor_potion" then
        local cap=require("config.card_ability_data").armorCap
        local armor=game.playerArmor or game.playerShield or 0
        if armor>=cap then return false end
        game.playerArmor=math.min(cap,armor+(card.armorAmt or 8));game.playerShield=game.playerArmor
    else return nil end
    table.remove(game.consumables,index)
    return true
end
return Inventory
