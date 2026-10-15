local G=require("src.enemy_group")
local F={}
local meters=setmetatable({}, {__mode="k"})
local function drawMeter(UI,Health,Chrome,x,y,w,h,shown,value,maximum,shield,trail)
    value=math.max(0,math.floor(value or 0));maximum=math.max(0,maximum or 0)
    local ratio=maximum>0 and math.min(1,value/maximum) or 0
    local percent=ratio>0 and ratio<.01 and "<1%" or string.format("%.0f%%",ratio*100)
    Health.draw(x,y,w,h,shown,maximum,{variant=shield and "cyan" or "red",shield=shield,
        emphasis=true,label="",trailValue=trail,trailColor=shield and {.65,.86,1} or {1,.60,.40}})
    local font=UI.fonts.small
    local rightW=font:getWidth(percent)+4
    local leftX=x+(shield and 20 or 7)
    local leftW=x+w-rightW-9-leftX
    local label=(shield and "" or "HP ")..UI.formatNumber(value).."/"..UI.formatNumber(maximum)
    if font:getWidth(label)>leftW then label=(shield and "" or "HP ")..UI.formatNumber(value) end
    if font:getWidth(label)>leftW then font=UI.fonts.tiny end
    Chrome.title(label,leftX,y+(h-font:getHeight())/2,leftW,font,{.99,.97,.94})
    Chrome.title(percent,x+w-rightW-5,y+(h-UI.fonts.small:getHeight())/2,rightW,UI.fonts.small,
        shield and {.76,.94,1} or {1,.89,.86},"right")
end
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
function F.hud(game,UI,mx,my,turn,sequence)
    local g=love.graphics;local list=G.members(game)
    local Health=require("ui.components.health_bar")
    local Core=require("ui.components.core")
    g.push("all")
    local Style=require("ui.backpack_style");local Chrome=require("ui.combat_chrome")
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list);local target=m==game.monster;local alive=m.hp>0
        local moving=turn and turn.attackers[turn.index]==m and turn.phase~="pause"
        local c=target and {0.95,0.78,0.39} or {0.49,0.62,0.71}
        if turn and turn.attackers[turn.index]==m then
            c={1,0.67,0.34}
        end
        local title=m.human and not m.neutralHuman and (m.kingdom.." • "..require("src.expedition").rankName(m.cardRank)) or m.name
        local armor = m.creatureArmor or 0
        local state=meters[m] or {}
        local hasArmor=armor>0 or state.armor and state.armor.trail>0.05
        local hx,hy,hw,hh=F.headerRect(i,#list,hasArmor)
        Style.panel(hx,hy,hw,hh,c,target,.92)
        local titleWidth=alive and m.enemyInventory and w-22 or w+14
        Core.textLine(title,x-7,hy+7,titleWidth,UI.fonts.small,c,"left",UI.fonts.tiny)
        local ability=require("src.enemy_abilities")
        if alive then
            Chrome.title("ST "..UI.formatNumber(ability.attack(m)),x-7,hy+26,68,UI.fonts.small,{1,.36,.35})
            Chrome.title("TỐC "..UI.formatNumber(ability.speed(m)),x+65,hy+26,w-58,UI.fonts.small,{.28,.78,1})
        else Core.textLine("ĐÃ HẠ",x-7,hy+26,w+14,UI.fonts.small,{.48,.51,.54},"left") end
        if alive and m.enemyInventory then
            local bx,by,bw,bh=F.bagRect(i,#list,hasArmor)
            local hover=mx>=bx and mx<=bx+bw and my>=by and my<=by+bh
            if hover then
                Core.color(c,.12);g.rectangle("fill",bx,by,bw,bh,5)
                UI.descriptionCandidate={name="Kho đồ · "..m.name,
                    desc="Nhấn để xem trang bị, ấn bản, dấu ấn, SPN và đồ dự trữ.",hoverKey=m.enemyInventory}
            end
            Style.glyph("bag",bx+bw/2,by+bh/2,7,hover and {1,.9,.65} or {.74,.65,.45})
        end
        if hasArmor then
            drawMeter(UI,Health,Chrome,x-9,120,w+18,20,armor,armor,math.max(armor,m.creatureArmorMax or 0),true,state.armor and state.armor.trail)
        end
        local scoring=target and sequence
        local shownHp=scoring and scoring.hp or state.hp and state.hp.shown or m.hp
        drawMeter(UI,Health,Chrome,x-9,142,w+18,22,shownHp,scoring and scoring.hp or m.hp,m.maxHp,false,
            scoring and scoring.hpTrail or state.hp and state.hp.trail)
        if not moving then
            Style.glow(x+w/2,y+h+4,69,c,target and .16 or .06)
            local cy=y+h+4
            g.setColor(.004,.01,.015,.55);g.ellipse("fill",x+w/2,cy+5,w*.57,10)
            g.setColor(.12,.11,.085,.85);g.ellipse("fill",x+w/2,cy+2,w*.55,8)
            g.setColor(.34,.28,.18,.85);g.ellipse("fill",x+w/2,cy,w*.55,6)
            Core.color(c,target and .82 or .30);g.setLineWidth(1.5);g.ellipse("line",x+w/2,cy,w*.55,6)
            if target and alive then
                Core.color(c,.85);g.polygon("fill",x+w/2,y+h+7,x+w/2+4,y+h+11,x+w/2,y+h+15,x+w/2-4,y+h+11)
            end
            if alive and #list>1 then
                local intent=m.intent or {}
                local names={attack="Tấn công",armor="Gia cố",speed="Tăng tốc",heal="Hồi máu",damage="Cường hóa",equip="Đổi đồ",equip_spn="Triệu hồi SPN",consume="Dùng tiêu hao"}
                local to=intent.targetIndex and intent.targetIndex~=i and (" · #"..intent.targetIndex) or ""
                local label=(names[intent.type] or "Tấn công")..to
                if (m.spnFrozen or 0)>0 then label="ĐÓNG BĂNG · "..m.spnFrozen.." LƯỢT"
                elseif #(m.spnAuraBurns or {})>0 then label="THIÊU ĐỐT · "..#m.spnAuraBurns.." NGUỒN" end
                Core.textLine(label,x-9,y+h+20,w+18,UI.fonts.tiny,{.01,.016,.021},"center")
                Core.textLine(label,x-9,y+h+19,w+18,UI.fonts.tiny,{.72,.80,.83},"center")
            end
        end
        if alive and not moving and m.hasBed then
                local image=UI.getConsumableImage({id="cons_bed"})
                if image then g.setColor(1,1,1,1);UI.CardFrame.image(image,x+w-30,y+h-46,28,42);UI.drawCardBorder(x+w-30,y+h-46,28,42) end
        end
    end
    if (game.enemyPoison or 0)>0 then
        Chrome.panel(250,82,138,26,{.54,.89,.45})
        Core.textLine("ĐỘC "..game.enemyPoison.." · −1 / TAY",260,88,118,UI.fonts.tiny,{.54,.89,.45},"center")
    end
    g.pop()
end
function F.headerRect(index,count,armor)
    local x,y,w,h=G.rect(index,count)
    return x-16,armor and 76 or 94,w+32,armor and 92 or 74
end
function F.bagRect(index,count,armor)
    local x,y,w,h=G.rect(index,count)
    return x+w-16,(armor and 76 or 94)+1,28,28
end
function F.inventoryAt(game,x,y,onCard)
    local list=G.members(game)
    for i,m in ipairs(list) do
        local bx,by,w,h
        if onCard then bx,by,w,h=G.rect(i,#list)
        else
            local state=meters[m] or {}
            local armor=(m.creatureArmor or 0)>0 or state.armor and state.armor.trail>0.05
            bx,by,w,h=F.headerRect(i,#list,armor)
        end
        if m.enemyInventory and m.hp>0 and x>=bx and x<=bx+w and y>=by and y<=by+h then return m end
    end
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
