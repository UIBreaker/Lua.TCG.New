local V={}
local D
function V.register(deities)
    D=deities
    local entry={id="spirit_armor_vitality",name="Giáp Hóa Sinh",stat="addArmorToHpPct",values={value=100},rarity="common",cost=4,
        trigger="combat_win",lore="Lớp giáp của dị linh tan vào tim, trở thành sinh lực còn lại sau viễn chinh.",
        descriptionTemplate="Khi thắng trận: tiêu toàn bộ Giáp còn lại, chuyển {value}% thành Máu tối đa vĩnh viễn và hồi lượng HP tương ứng. Làm tròn xuống; chỉ chuyển một lần cuối trận theo thứ tự ô SPN."}
    entry.desc=entry.descriptionTemplate:gsub("{value}","100");entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
end
function V.finish(game)
    if not game or require("src.combat").getOutcome(game)~="victory" then return 0 end
    game.spnCombat=game.spnCombat or {}
    if game.spnCombat.vitalityClaimed then return 0 end
    game.spnCombat.vitalityClaimed=true
    D=D or require("src.deities")
    local total=0
    for slot=1,D.getMaxSlots(game) do
        local physical=game.deities and game.deities[slot]
        if physical and not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if source.id=="spirit_armor_vitality" then
                    local armor=math.max(0,game.playerArmor or game.playerShield or 0)
                    if armor<=0 then return end
                    local rate=D.scaleEffect(source,{addArmorToHpPct=100}).addArmorToHpPct
                    local gain=math.floor(armor*rate/100)
                    game.playerArmor=0;game.playerShield=0
                    game.maxPlayerHp=(game.maxPlayerHp or 100)+gain
                    game.playerHp=math.min(game.maxPlayerHp,(game.playerHp or 100)+gain)
                    total=total+gain
                    game.spnFeedback=game.spnFeedback or {}
                    game.spnFeedback[#game.spnFeedback+1]={deity=physical,slot=slot,text="GIÁP HÓA SINH · +"..gain.." MÁU TỐI ĐA / HP"}
                end
            end)
        end
    end
    return total
end
return V
