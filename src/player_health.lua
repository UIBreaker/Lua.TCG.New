local H={}
function H.heal(game,amount)
    local before=game.playerHp or 0
    game.playerHp=math.min(game.maxPlayerHp or 100,before+math.max(0,amount or 0))
    local gain=game.playerHp-before
    if gain>0 then
        for _,m in ipairs(require("src.enemy_group").members(game)) do
            if m.bloodSovereign and m.hp>0 and require("src.boss_abilities").passiveEnabled(m) then
                m.hp=m.hp*2;m.maxHp=m.maxHp*2;m.damageLagHp=m.hp
                m.attack=m.attack*2;m.attackSpeed=m.attackSpeed*2
                if m.spnStolenSpeed then m.spnStolenSpeed=m.spnStolenSpeed*2 end
                for _,kind in ipairs({"speed","damage"}) do
                    local buff=(m.combatBuffs or {})[kind];if buff then buff.value=buff.value*2 end
                end
                m.bloodHealTriggers=(m.bloodHealTriggers or 0)+1
                if m.intent then m.intent.value=m.attack;m.intent.label="VƯƠNG HUYẾT · TẤN CÔNG "..m.attack end
                require("src.potions").emit(game,"damage","VƯƠNG HUYẾT · MÁU / TỐC / SÁT THƯƠNG ×2",nil,m)
            end
        end
    end
    return gain
end
function H.revive(game,hp)
    game.playerHp=0;return H.heal(game,hp)
end
function H.bloodTurn(game)
    for _,m in ipairs(require("src.enemy_group").members(game)) do
        if m.bloodSovereign and m.hp>0 and (game.playerHp or 0)>0 and require("src.boss_abilities").passiveEnabled(m) then
            local loss=game.playerHp*.02;game.playerHp=game.playerHp-loss
            require("src.potions").emit(game,"gold_blood",string.format("HUYẾT THỰC · −%.2f HP",loss),loss,m)
            return loss
        end
    end
    return 0
end
return H
