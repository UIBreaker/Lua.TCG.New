local G=require("src.enemy_group")
local F={}
function F.world(game,UI,Renderer,Art,Death,art,time,motion,scoring,turn)
    local list=G.members(game)
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list);local cx,cy=x+w/2,y+h/2
        m.screenX=cx
        local img=Art.image(m,art)
        if m.hp>0 then
            local target=m==game.monster
            local recoil,squash,flash=0,1,0
            if target and scoring then recoil,squash,flash=UI.ScoringFeel.enemyReaction(scoring) end
            Renderer.entity.draw(img,cx,cy+math.sin(time*1.1+i)*1.0,h,time,
                turn and require("src.enemy_attack_presentation").motion(turn,m) or motion.attack/0.42,target and motion.hit/0.35 or 0,recoil,squash,Renderer.scene.preset,Renderer.eventStrength,m.human or m.creatureCard,
                target and {0.95,0.78,0.39,1} or nil,m)
        elseif Death.enemyActive(m) then Death.drawEnemy(img,cx,cy,h) end
    end
end
function F.hud(game,UI,mx,my,turn)
    local g=love.graphics;local list=G.members(game)
    local Health=require("ui.components.health_bar")
    local Core=require("ui.components.core")
    g.push("all")
    Core.text("ĐỐI THỦ "..G.alive(list).."/"..#list.."  •  BẤM LÁ BÀI ĐỂ CHỌN MỤC TIÊU",310,89,640,UI.fonts.small,{0.89,0.79,0.57},"center")
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list);local target=m==game.monster;local alive=m.hp>0
        local moving=turn and turn.attackers[turn.index]==m and turn.phase~="pause"
        local c=target and {0.95,0.78,0.39} or {0.49,0.62,0.71}
        if turn and turn.attackers[turn.index]==m then
            c={1,0.67,0.34}
        end
        local title=m.human and (m.kingdom.." • "..require("src.expedition").rankName(m.cardRank)) or UI.truncateUtf8(m.name,21)
        Core.textLine(title,x-24,120,w+48,UI.fonts.small,c,"center",UI.fonts.tiny)
        Health.draw(x-12,144,w+24,18,target and (m.damageLagHp or m.hp) or m.hp,m.maxHp,{variant="red",font=UI.fonts.tiny,label=UI.formatNumber(m.hp).."/"..UI.formatNumber(m.maxHp)})
        if not moving then
            Core.textLine(alive and ((target and "MỤC TIÊU  •  " or "").."ATK "..m.attack.." / TĐ "..m.attackSpeed) or "ĐÃ HẠ",x-24,y+h+14,w+48,UI.fonts.tiny,alive and c or {0.48,0.51,0.54},"center",UI.fonts.tiny)
        end
        if alive and not moving then
            local ability=m.enemyAbility and m.enemyAbility.name or m.isBoss and "NỘI TẠI / KỸ NĂNG" or "NHÀ THÁM HIỂM"
            if (m.creatureArmor or 0)>0 then ability=ability.." / GIÁP "..UI.formatNumber(m.creatureArmor)
            elseif m.reassembled then ability=ability.." / ĐÃ TÁI SINH" end
            Core.textLine(ability,x-24,y+h+35,w+48,UI.fonts.tiny,{0.65,0.74,0.78},"center",UI.fonts.tiny)
        end
    end
    if (game.enemyPoison or 0)>0 then Core.text("ĐỘC "..game.enemyPoison.." • GIẢM 1 TẦNG / TAY",310,423,640,UI.fonts.tiny,{0.54,0.89,0.45},"center") end
    g.pop()
end
function F.press(game,x,y)
    local list=game.enemies or {}
    for i,m in ipairs(list) do
        local bx,by,w,h=G.rect(i,#list)
        if x>=bx-8 and x<=bx+w+8 and y>=by and y<=by+h then return G.select(game,i) end
    end
    return false
end
return F
