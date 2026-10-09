local G=require("src.enemy_group")
local F={}
local meters=setmetatable({}, {__mode="k"})
function F.update(game,dt)
    local Feedback=require("src.combat_feedback")
    for _,m in ipairs(G.members(game)) do
        local state=meters[m] or {};meters[m]=state
        state.hp=Feedback.updateMeter(state.hp,m.hp,dt)
        state.armor=Feedback.updateMeter(state.armor,m.creatureArmor,dt)
    end
end
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
            local bx,by,bhit=require("src.bed_explosion").reaction(cx)
            Renderer.entity.draw(img,cx+bx,cy+by+math.sin(time*1.1+i)*1.0,h,time,
                turn and require("src.enemy_attack_presentation").motion(turn,m) or motion.attack/0.42,math.max(target and motion.hit/0.35 or 0,bhit),recoil,squash,Renderer.scene.preset,Renderer.eventStrength,m.human or m.creatureCard,
                target and {0.95,0.78,0.39,1} or nil,m)
        elseif Death.enemyActive(m) then Death.drawEnemy(img,cx,cy,h,(m.human or m.creatureCard) and m or nil) end
    end
end
function F.hud(game,UI,mx,my,turn)
    local g=love.graphics;local list=G.members(game)
    local Health=require("ui.components.health_bar")
    local Core=require("ui.components.core")
    g.push("all")
    local Style=require("ui.backpack_style");local Chrome=require("ui.combat_chrome")
    Chrome.panel(400,82,460,26,{.86,.68,.39})
    Core.text("ĐẤU TRƯỜNG  ·  "..G.alive(list).." / "..#list.." ĐỐI THỦ  ·  NHẤN ĐỂ CHỌN MỤC TIÊU",414,88,432,UI.fonts.tiny,{.86,.76,.57},"center")
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list);local target=m==game.monster;local alive=m.hp>0
        local moving=turn and turn.attackers[turn.index]==m and turn.phase~="pause"
        local c=target and {0.95,0.78,0.39} or {0.49,0.62,0.71}
        if turn and turn.attackers[turn.index]==m then
            c={1,0.67,0.34}
        end
        local title=m.human and (m.kingdom.." • "..require("src.expedition").rankName(m.cardRank)) or UI.truncateUtf8(m.name,21)
        local armor = m.creatureArmor or 0
        local state=meters[m] or {}
        local hasArmor=armor>0 or state.armor and state.armor.trail>0.05
        Chrome.panel(x-18,hasArmor and 110 or 117,w+36,hasArmor and 54 or 47,c)
        Core.textLine(title,x-24,hasArmor and 116 or 123,w+48,UI.fonts.small,c,"center",UI.fonts.tiny)
        if hasArmor then
            Health.draw(x-12,130,w+24,12,armor,m.creatureArmorMax or armor,
                {variant="cyan",shield=true,font=UI.fonts.tiny,trailValue=state.armor and state.armor.trail,
                    trailColor={0.65,0.86,1},label="GIÁP "..UI.formatNumber(armor)})
        end
        Health.draw(x-12,144,w+24,18,state.hp and state.hp.shown or m.hp,m.maxHp,{variant="red",font=UI.fonts.tiny,
            trailValue=state.hp and state.hp.trail,label=UI.formatNumber(m.hp).."/"..UI.formatNumber(m.maxHp)})
        if not moving then
            Style.glow(x+w/2,y+h+4,69,c,target and .16 or .06)
            local cy=y+h+4
            g.setColor(.004,.01,.015,.55);g.ellipse("fill",x+w/2,cy+5,w*.57,10)
            g.setColor(.12,.11,.085,.85);g.ellipse("fill",x+w/2,cy+2,w*.55,8)
            g.setColor(.34,.28,.18,.85);g.ellipse("fill",x+w/2,cy,w*.55,6)
            Core.color(c,target and .82 or .30);g.setLineWidth(1.5);g.ellipse("line",x+w/2,cy,w*.55,6)
            Chrome.panel(x-18,y+h+12,w+36,m.hasBed and 65 or 49,c)
            if target and alive then
                Core.color(c,.85);g.polygon("fill",x+w/2,y+h+7,x+w/2+4,y+h+11,x+w/2,y+h+15,x+w/2-4,y+h+11)
            end
            Core.textLine(alive and ((target and "MỤC TIÊU  •  " or "").."ATK "..m.attack.." / TĐ "..m.attackSpeed) or "ĐÃ HẠ",x-24,y+h+19,w+48,UI.fonts.tiny,alive and c or {0.48,0.51,0.54},"center",UI.fonts.tiny)
        end
        if alive and not moving then
            local ability=m.enemyAbility and m.enemyAbility.name or m.isBoss and "NỘI TẠI / KỸ NĂNG" or "NHÀ THÁM HIỂM"
            if (m.creatureArmor or 0)>0 then ability=ability.." / GIÁP "..UI.formatNumber(m.creatureArmor)
            elseif m.reassembled then ability=ability.." / ĐÃ TÁI SINH" end
            Core.textLine(ability,x-24,y+h+37,w+48,UI.fonts.tiny,{0.65,0.74,0.78},"center",UI.fonts.tiny)
            if m.hasBed then
                local image=UI.getConsumableImage({id="cons_bed"})
                if image then g.setColor(1,1,1,1);UI.CardFrame.image(image,x+w-30,y+h-46,28,42);UI.drawCardBorder(x+w-30,y+h-46,28,42) end
                Core.textLine("ĐANG CẦM GIƯỜNG",x-24,y+h+53,w+48,UI.fonts.tiny,{.55,.95,.68},"center",UI.fonts.tiny)
            end
        end
    end
    if (game.enemyPoison or 0)>0 then
        Chrome.panel(250,82,138,26,{.54,.89,.45})
        Core.textLine("ĐỘC "..game.enemyPoison.." · −1 / TAY",260,88,118,UI.fonts.tiny,{.54,.89,.45},"center")
    end
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
