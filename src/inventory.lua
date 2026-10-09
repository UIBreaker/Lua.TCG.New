local Inventory = {}
function Inventory.limit(game)
    return math.max(3,math.floor(tonumber(game and game.maxConsumables) or 3))
end
function Inventory.canUpgradeCard(consumable,target)
    local E=require("src.equipment")
    if not target or not target.rank or target.destroyed then return false,"Chọn một quân bài còn trong bộ." end
    if consumable.category=="socket_expansion" then
        if E.getMaxSlots(target)>=E.SOCKET_CAP then return false,"Lá đã đủ 8 hốc trang bị." end
    elseif consumable.category=="rule_break" then
        if target.allowDuplicateEquipment then return false,"Lá đã có Phá Luật." end
    else return false,"Thẻ không nâng cấp trang bị." end
    return true
end
function Inventory.useCardUpgrade(game,index,target)
    local consumable=game.consumables and game.consumables[index]
    if not consumable then return false,"Thẻ không còn trong balo." end
    local canonical
    for _,card in ipairs(game.persistentDeck or {}) do
        if card==target or target and target.id and card.id==target.id then canonical=card;break end
    end
    local allowed,reason=Inventory.canUpgradeCard(consumable,canonical)
    if not allowed then return false,reason end
    local sockets=require("src.equipment").getMaxSlots(canonical)+1
    require("src.chest_expansion").sync(game,canonical,function(card)
        if consumable.category=="socket_expansion" then card.maxSockets=sockets;card.unlockedSockets=sockets
        else card.allowDuplicateEquipment=true end
    end)
    table.remove(game.consumables,index)
    require("src.card_abilities").consumableUsed(game)
    return true,consumable.category=="socket_expansion" and ("ĐÃ MỞ HỐC · "..sockets.." HỐC") or "PHÁ LUẬT · CHO PHÉP TRANG BỊ TRÙNG"
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
