local G=require("src.enemy_group")
local F={}
local meters=setmetatable({}, {__mode="k"})
local faces=setmetatable({}, {__mode="k"})
local gold,cyan={1,.83,.40,1},{.42,.91,1,1}
local function pendingReflection(turn,m)
    return turn and turn.result and (turn.result.reflectedAttack or 0)>0 and turn.reactions and turn.reactions[m] and (turn.reflectionAge or 0)<.22
end
local function inside(x,y,bx,by,w,h) return x>=bx and y>=by and x<=bx+w and y<=by+h end

function F.targetAt(game,mx,my)
    local list=G.members(game)
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list)
        if m.hp>0 and inside(mx,my,x-12,76,w+24,h+y+24-76) then return m,i end
    end
end

local function reticle(points,color)
    if not points then return end
    local g=love.graphics;local cx,cy=0,0
    for i=1,8,2 do cx,cy=cx+points[i]/4,cy+points[i+1]/4 end
    for i=1,8,2 do
        local prev=i==1 and 7 or i-2;local next=i==7 and 1 or i+2
        local x,y=cx+(points[i]-cx)*1.07,cy+(points[i+1]-cy)*1.045
        local ax,ay=x+(points[prev]-points[i])*.13,y+(points[prev+1]-points[i+1])*.13
        local bx,by=x+(points[next]-points[i])*.13,y+(points[next+1]-points[i+1])*.13
        g.setColor(.008,.014,.02,.98);g.setLineWidth(7);g.line(ax,ay,x,y,bx,by)
        g.setColor(color);g.setLineWidth(3);g.line(ax,ay,x,y,bx,by)
    end
end
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
    if font:getWidth(label)>leftW then font=UI.fonts.tiny end
    if font:getWidth(label)>leftW then label=(shield and "" or "HP ")..UI.formatNumber(value) end
    Chrome.title(label,leftX,y+(h-font:getHeight())/2,leftW,font,{.99,.97,.94})
    Chrome.title(percent,x+w-rightW-5,y+(h-UI.fonts.small:getHeight())/2,rightW,UI.fonts.small,
        shield and {.76,.94,1} or {1,.89,.86},"right")
end
function F.update(game,dt,sequence,turn)
    local Feedback=require("src.combat_feedback")
    for _,m in ipairs(G.members(game)) do
        local state=meters[m] or {};meters[m]=state
        local scoring=sequence and (sequence.enemy==m or not sequence.enemy and game.monster==m)
        local reflected=turn and turn.reactions and turn.reactions[m]
        if state.scoring and not scoring or state.reflected and not reflected then state.hp=nil;state.armor=nil end
        state.scoring=scoring
        state.reflected=reflected
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
        if m.hp>0 or pendingReflection(turn,m) then
            local target=m==game.monster
            local recoil,squash,flash=0,1,0
            local reacting=not turn and scoring and (scoring.sequence.enemy==m or not scoring.sequence.enemy and target)
            if reacting then recoil,squash,flash=UI.ScoringFeel.enemyReaction(scoring) end
            if turn and turn.reactions and turn.reactions[m] then
                recoil,squash,flash=require("src.enemy_attack_presentation").reaction(turn,m)
            end
            local bx,by,bhit=require("src.bed_explosion").reaction(cx)
            local hit=math.max(target and motion.hit/0.35 or 0,bhit)
            if reacting and scoring.sequence.damageApplied then hit=math.max(math.abs(1-squash)*8,bhit) end
            if turn then hit=math.max(flash,bhit) end
            Renderer.entity.draw(img,cx+bx,cy+by+math.sin(time*1.1+i)*1.0,h,time,
                turn and require("src.enemy_attack_presentation").motion(turn,m) or motion.attack/0.42,hit,recoil,squash,Renderer.scene.preset,Renderer.eventStrength,m.human or m.creatureCard,
                target and {0.95,0.78,0.39,1} or nil,m)
            local face=Renderer.entity.face and Renderer.entity.face(m)
            if face then
                local points=faces[m] or {};faces[m]=points
                for j=1,8,2 do
                    if Renderer.world then points[j],points[j+1]=face[j]/Renderer.worldScale,face[j+1]/Renderer.worldScale
                    elseif Renderer.worldRoot then points[j],points[j+1]=Renderer.worldRoot:inverseTransformPoint(face[j],face[j+1])
                    else points[j],points[j+1]=face[j],face[j+1] end
                end
            end
        elseif Death.enemyActive(m) then Death.drawEnemy(img,cx,cy,h,(m.human or m.creatureCard) and m or nil) end
    end
end
function F.hud(game,UI,mx,my,turn,sequence,locked)
    local g=love.graphics;local list=G.members(game)
    local Health=require("ui.components.health_bar")
    local Core=require("ui.components.core")
    g.push("all");g.setShader();g.setBlendMode("alpha")
    local Style=require("ui.backpack_style");local Chrome=require("ui.combat_chrome")
    local hovered=not locked and F.targetAt(game,mx,my)
    for i,m in ipairs(list) do
        local x,y,w,h=G.rect(i,#list);local target=m==game.monster;local alive=m.hp>0 or pendingReflection(turn,m)
        local moving=turn and turn.attackers[turn.index]==m and turn.phase~="pause"
        local c=target and gold or hovered==m and cyan or {0.68,0.76,0.82,1}
        if turn and turn.attackers[turn.index]==m then
            c={1,0.67,0.34}
        end
        local title=m.human and not m.neutralHuman and (m.kingdom.." • "..require("src.expedition").rankName(m.cardRank)) or m.name
        local scoring=sequence and (sequence.enemy==m or not sequence.enemy and target) and sequence
        local reflected=turn and turn.reactions and turn.reactions[m]
        local armor = reflected and reflected.armor.shown or scoring and scoring.armor or m.creatureArmor or 0
        local state=meters[m] or {}
        if state.scoring and not scoring or state.reflected and not reflected then state={} end -- The unlock frame must not revive the slower ambient meter.
        local hasArmor=armor>0 or reflected and reflected.armor.trail>0.05 or scoring and scoring.armorTrail>0.05 or not scoring and state.armor and state.armor.trail>0.05
        local hx,hy,hw,hh=F.headerRect(i,#list,hasArmor)
        Style.panel(hx,hy,hw,hh,c,target,.98)
        local titleWidth=alive and m.enemyInventory and w-20 or w+14
        local _,lines=UI.fonts.tiny:getWrap(title,titleWidth)
        for row=1,math.min(2,#lines) do Chrome.title(lines[row],x-7,hy+5+(row-1)*13,titleWidth,UI.fonts.tiny,c) end
        local ability=require("src.enemy_abilities")
        if alive then
            Chrome.title("ST "..UI.formatNumber(ability.attack(m)),x-7,106,68,UI.fonts.small,{1,.51,.49})
            Chrome.title("TỐC "..UI.formatNumber(ability.speed(m)),x+65,106,w-58,UI.fonts.small,{.48,.87,1})
        else Core.textLine("ĐÃ HẠ",x-7,106,w+14,UI.fonts.small,{.65,.68,.71},"left") end
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
            drawMeter(UI,Health,Chrome,x-9,120,w+18,20,armor,armor,math.max(armor,m.creatureArmorMax or 0,scoring and scoring.armorBefore or 0),true,reflected and reflected.armor.trail or scoring and scoring.armorTrail or state.armor and state.armor.trail)
        end
        local shownHp=reflected and reflected.hp.shown or scoring and scoring.hp or state.hp and state.hp.shown or m.hp
        drawMeter(UI,Health,Chrome,x-9,142,w+18,22,shownHp,pendingReflection(turn,m) and shownHp or scoring and scoring.hp or m.hp,m.maxHp,false,
            reflected and reflected.hp.trail or scoring and scoring.hpTrail or state.hp and state.hp.trail)
        if not moving then
            Style.glow(x+w/2,y+h+4,69,c,target and .16 or .06)
            local cy=y+h+4
            g.setColor(.004,.01,.015,.55);g.ellipse("fill",x+w/2,cy+5,w*.57,10)
            g.setColor(.12,.11,.085,.85);g.ellipse("fill",x+w/2,cy+2,w*.55,8)
            g.setColor(.34,.28,.18,.85);g.ellipse("fill",x+w/2,cy,w*.55,6)
            Core.color(c,target and .82 or .30);g.setLineWidth(1.5);g.ellipse("line",x+w/2,cy,w*.55,6)
            if alive then
                local label=target and ("ĐANG NHẮM #"..i) or hovered==m and ("CHỌN #"..i) or ("ĐỐI THỦ #"..i)
                local badgeY=y+h+5
                g.setColor(.009,.019,.027,.98);g.rectangle("fill",x-9,badgeY,w+18,22,4,4)
                Core.color(target and gold or hovered==m and cyan or {.4,.49,.55,1});g.setLineWidth(target and 2 or 1)
                g.rectangle("line",x-9,badgeY,w+18,22,4,4)
                Chrome.title(label,x-6,badgeY+4,w+12,UI.fonts.tiny,target and gold or hovered==m and cyan or {.76,.81,.85,1},"center")
            end
            if alive and #list>1 then
                local intent=m.intent or {}
                local names={attack="Tấn công",armor="Gia cố",speed="Tăng tốc",heal="Hồi máu",damage="Cường hóa",equip="Đổi đồ",equip_spn="Triệu hồi SPN",consume="Dùng tiêu hao"}
                local to=intent.targetIndex and intent.targetIndex~=i and (" · #"..intent.targetIndex) or ""
                local label=(intent.type=="human_skill" and "Đoạn Mệnh · 1 lần" or names[intent.type] or "Tấn công")..to
                if (m.spnFrozen or 0)>0 then label="ĐÓNG BĂNG · "..m.spnFrozen.." LƯỢT"
                elseif #(m.spnAuraBurns or {})>0 then label="THIÊU ĐỐT · "..#m.spnAuraBurns.." NGUỒN" end
                g.setColor(.009,.019,.027,.93);g.rectangle("fill",x-9,y+h+31,w+18,20,3,3)
                Chrome.title(label,x-6,y+h+34,w+12,UI.fonts.tiny,{.88,.92,.95},"center")
            end
        end
        if alive and (target or hovered==m) then reticle(faces[m],target and gold or cyan) end
        if alive and not moving and m.hasBed then
                local image=UI.getConsumableImage({id="cons_bed"})
                if image then g.setColor(1,1,1,1);UI.CardFrame.image(image,x+w-30,y+h-46,28,42);UI.drawCardBorder(x+w-30,y+h-46,28,42) end
        end
    end
    local notice=require("src.human_bosses").notice(game)
    if notice then
        g.setColor(.012,.025,.034,.97);g.rectangle("fill",340,397,580,23,4,4)
        Chrome.title(notice,352,402,556,UI.fonts.tiny,gold,"center")
    end
    if (game.enemyPoison or 0)>0 then
        Chrome.panel(250,82,138,26,{.54,.89,.45})
        Core.textLine("ĐỘC "..game.enemyPoison.." · −1 / TAY",260,88,118,UI.fonts.tiny,{.54,.89,.45},"center")
    end
    g.pop()
end
function F.headerRect(index,count,armor)
    local x,y,w,h=G.rect(index,count)
    return x-16,76,w+32,92
end
function F.bagRect(index,count,armor)
    local x,y,w,h=G.rect(index,count)
    return x+w-16,77,28,28
end
function F.inventoryAt(game,x,y,onCard)
    local list=G.members(game)
    for i,m in ipairs(list) do
        local bx,by,w,h
        if onCard then bx,by,w,h=G.rect(i,#list)
        else
            local state=meters[m] or {}
            local armor=(m.creatureArmor or 0)>0 or state.armor and state.armor.trail>0.05
            bx,by,w,h=F.bagRect(i,#list,armor)
        end
        if m.enemyInventory and m.hp>0 and x>=bx and x<=bx+w and y>=by and y<=by+h then return m end
    end
end
function F.press(game,x,y)
    local _,index=F.targetAt(game,x,y)
    if index then return G.select(game,index) end
    return false
end
return F
