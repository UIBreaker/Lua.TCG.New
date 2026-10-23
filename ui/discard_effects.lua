local D={}
local Core=require("ui.components.core")
local Motion=require("src.motion")
local Lighting=require("render.lighting")
local colors={heal={.37,.94,.61},gold={1,.79,.32},armor={.43,.72,1},speed={.29,.88,1},empower={.79,.59,1}}
local function number(n) return (string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")) end

function D.pose(e,index,reduced)
    local t=(e.age-math.min((index-1)*.035,.18))/.82
    if reduced or e.reduced or t<=0 or t>=1 then return 0,0,0 end
    local envelope=math.sin(t*math.pi)*(1-t)
    return math.sin(t*math.pi*18)*1.7*envelope,
        -11*math.sin(t*math.pi)-math.sin(t*math.pi*16)*.8*envelope,
        math.sin(t*math.pi*14)*.018*envelope
end

function D.cardPose(card,reduced)
    for _,e in ipairs(require("ui.potion_effects").active) do
        if e.kind=="discard" then
            for i,target in ipairs(e.targets) do
                if target.card==card and not card.destroyed
                    and ((target.speed>0 and (card.discardSpeedBonus or 0)>0)
                    or (target.empowerment>0 and (card.heldEmpowerment or 0)>0)) then
                    return D.pose(e,i,reduced)
                end
            end
        end
    end
    return 0,0,0
end

function D.rows(e)
    local rows={}
    local function add(kind,title,value,note) rows[#rows+1]={kind=kind,title=title,value=value,note=note} end
    if e.requestedHeal>0 then
        add("heal","HỒI MÁU","+"..number(e.heal).." HP",e.heal==0 and "Máu đã đầy" or e.heal<e.requestedHeal and "Đã chạm máu tối đa" or "Máu thực hồi cho bạn")
    end
    if e.gold>0 then add("gold","NHẬN VÀNG","+"..number(e.gold),"Đã thêm vào túi vàng") end
    if e.armor>0 then add("armor","THÊM GIÁP","+"..number(e.armor),"Lá chắn của bạn") end
    if e.speed>0 then add("speed","TĂNG TỐC","+"..number(e.speed),#e.targets.." lá · 1 lượt đánh") end
    if e.empowerment>0 then
        local count=0;for _,t in ipairs(e.targets) do if t.empowerment>0 then count=count+1 end end
        add("empower","CƯỜNG HÓA","+"..number(e.empowerment),"Tổng trên "..count.." lá cùng chất")
    end
    return rows
end

local function color(c,a) love.graphics.setColor(c[1],c[2],c[3],a) end
local function icon(kind,x,y,c,a)
    local g=love.graphics
    color(c,a);g.setLineWidth(1.7)
    if kind=="heal" then
        g.circle("fill",x-4,y-3,5,16);g.circle("fill",x+4,y-3,5,16)
        g.polygon("fill",x-8.5,y-1,x+8.5,y-1,x,y+9)
    elseif kind=="gold" then
        g.circle("line",x,y,9,24);g.circle("line",x,y,6,24)
        g.line(x,y-4,x,y+4);g.line(x-2,y-4,x+2,y-4);g.line(x-2,y+4,x+2,y+4)
    elseif kind=="armor" then
        g.polygon("line",x-8,y-7,x,y-10,x+8,y-7,x+7,y+3,x,y+10,x-7,y+3)
        g.line(x,y-6,x,y+5)
    elseif kind=="speed" then
        for i=0,1 do local dy=i*9;g.line(x-7,y+2-dy,x,y-4-dy,x+7,y+2-dy) end
    else
        g.polygon("line",x,y-11,x+8,y,x,y+11,x-8,y)
        g.line(x,y-5,x,y+5);g.line(x-4,y,x+4,y)
    end
end

local function tag(UI,label,x,y,w,c,a,e)
    local g=love.graphics;local font=UI.fonts.tiny
    local points={x+4,y,x+w-4,y,x+w,y+4,x+w,y+14,x+w-4,y+18,x+4,y+18,x,y+14,x,y+4}
    g.setColor(.018,.029,.041,.97*a);g.polygon("fill",points)
    color(c,.18*a);g.rectangle("fill",x+4,y+1,w-8,4)
    color(c,.72*a);g.setLineWidth(.8);g.polygon("line",points)
    color(c,a);g.polygon("fill",x+6,y+9,x+8,y+6,x+10,y+9,x+8,y+12)
    local scale=math.min(1,(w-19)/math.max(1,font:getWidth(label)))
    g.push();g.translate(x+(w+9)/2,y+3);g.scale(scale)
    g.setColor(.95,.97,1,a);g.setFont(font);g.print(label,-font:getWidth(label)/2,0);g.pop()
    if not e.reduced then
        local sheen=math.min(1,e.age/.7)
        color(c,a*(1-sheen));g.setLineWidth(1.3)
        local sx=x+4+(w-8)*sheen;g.line(math.max(x+4,sx-16),y+1,sx,y+1)
    end
end

function D.receipt(game,state)
    if state~="playing" or #(game.selectedIndices or {})>0 then return end
    for _,e in ipairs(require("ui.potion_effects").active) do
        if e.kind=="discard" and e.combat==game.abilityCombat and e.age<e.life and #D.rows(e)>0 then return e end
    end
end

function D.panelLayout(count,slot)
    local scale=math.min(1,slot.w/222,slot.h/(54+5*46))
    return {x=slot.x+(slot.w-222*scale)/2,y=slot.y,w=222*scale,h=(54+count*46)*scale,scale=scale}
end

function D.drawReceipt(UI,e,slot)
    local rows=D.rows(e)
    if #rows==0 then return end
    local a=math.min(1,e.age/.12,math.max(0,(e.life-e.age)/.5))
    if a<=0 then return end
    local layout=D.panelLayout(#rows,slot)
    local g=love.graphics;g.push("all");g.setShader();g.setBlendMode("alpha")
    g.translate(layout.x,layout.y);g.scale(layout.scale)
    local x,y,w=0,0,222
    local h=54+#rows*46
    g.setColor(0,0,0,.30*a);g.rectangle("fill",x+4,y+5,w,h,7,7)
    g.setColor(.025,.039,.048,.96*a);g.rectangle("fill",x,y,w,h,7,7)
    g.setColor(.76,.61,.36,.65*a);g.setLineWidth(1);g.rectangle("line",x+.5,y+.5,w-1,h-1,7,7)
    g.setColor(.76,.61,.36,.11*a);g.rectangle("fill",x+1,y+1,w-2,46,7,7)
    color({.91,.76,.46},.9*a);g.setLineWidth(1.5)
    for _,corner in ipairs({{x+5,y+5,1,1},{x+w-5,y+5,-1,1},{x+5,y+h-5,1,-1},{x+w-5,y+h-5,-1,-1}}) do
        local cx,cy,sx,sy=unpack(corner);g.line(cx,cy+sy*9,cx,cy,cx+sx*12,cy)
    end
    Core.textLine("BỎ BÀI",x+15,y+9,130,UI.fonts.small,{.98,.88,.68,a})
    Core.textLine(e.count.." LÁ",x+148,y+11,58,UI.fonts.tiny,{.88,.79,.61,a},"right")
    Core.textLine("HIỆU ỨNG NHẬN ĐƯỢC",x+15,y+30,w-30,UI.fonts.tiny,{.62,.69,.72,a})
    for i,row in ipairs(rows) do
        local cy=y+49+(i-1)*46;local c=colors[row.kind]
        local reveal=e.reduced and 1 or Motion.settle(math.max(0,e.age-(i-1)*.025),.18)
        local ra=a*reveal
        for band=0,7 do
            color(c,(.11-band*.012)*ra);g.rectangle("fill",x+8+band*(w-16)/8,cy,(w-16)/8,43)
        end
        color(c,.6*a);g.rectangle("fill",x+8,cy+8,2,29,1,1)
        color(c,.10*ra);g.circle("fill",x+31,cy+23,16,24)
        color(c,.28*ra);g.setLineWidth(.7);g.circle("line",x+31,cy+23,15,24)
        icon(row.kind,x+31,cy+23,c,ra)
        Core.textLine(row.title,x+53,cy+6,112,UI.fonts.tiny,{c[1],c[2],c[3],a})
        color(c,.09*ra);g.rectangle("fill",x+156,cy+2,51,25,4,4)
        local font=UI.fonts.regular;local valueW=font:getWidth(row.value)
        g.push();g.translate(x+205,cy+3);g.scale(math.min(1,49/math.max(1,valueW)))
        g.setFont(font);g.setColor(.98,.97,.89,ra);g.print(row.value,-valueW,0);g.pop()
        Core.textLine(row.note,x+53,cy+30,153,UI.fonts.tiny,{.70,.76,.79,a})
    end
    g.pop()
    return layout
end

function D.draw(UI,e,game,state)
    if state~="playing" and state~="scoring" then return end
    local g=love.graphics
    local a=math.min(1,e.age/.12,math.max(0,(e.life-e.age)/.5))
    if a<=0 then return end
    g.push("all");g.setShader();g.setBlendMode("alpha")
    local held={};for _,card in ipairs(game.hand or {}) do held[card]=true end
    for _,target in ipairs(e.targets) do
        local card=target.card
        if held[card] and not card.destroyed and ((target.speed>0 and (card.discardSpeedBonus or 0)>0)
            or (target.empowerment>0 and (card.heldEmpowerment or 0)>0)) then
            local r=UI.Polish.rect(UI,card)
            local lift=e.reduced and 0 or 6*Motion.settle(e.age,.35)
            local width=math.max(64,math.min(128,r.w-4))
            local tx=r.x+(r.w-width)/2
            local ty=math.max(78,r.y-23-lift-(target.speed>0 and target.empowerment>0 and 20 or 0))
            local tagBottom=ty
            if target.speed>0 and (card.discardSpeedBonus or 0)>0 then
                tag(UI,"+"..number(target.speed).." TỐC · 1 LƯỢT",tx,ty,width,colors.speed,a,e)
                tagBottom=ty+18
                ty=ty+20
            end
            if target.empowerment>0 and (card.heldEmpowerment or 0)>0 then
                tag(UI,"+"..number(target.empowerment).." CƯỜNG HÓA",tx,ty,width,colors.empower,a,e)
                tagBottom=ty+18
            end
            local accent=target.empowerment>0 and colors.empower or colors.speed
            color(accent,.42*a);g.setLineWidth(.8)
            g.line(r.x+r.w/2,tagBottom,r.x+r.w/2,r.y-3)
            if not e.reduced then
                local pulse=math.max(0,1-e.age/1.3)
                local floorY=r.y+r.h+3
                Lighting.glow(r.x+r.w/2,floorY,55,accent,.22*pulse*a)
                color(accent,.32*pulse*a);g.setLineWidth(1)
                g.ellipse("line",r.x+r.w/2,floorY,r.w*(.42+e.age*.08),4+e.age*3)
                for _,kind in ipairs({"speed","empower"}) do
                    local amount=kind=="speed" and target.speed or target.empowerment
                    if amount>0 then
                        local c=colors[kind];local px=r.x+r.w*.82
                        local py=r.y+r.h*(kind=="speed" and .12 or .91)
                        Lighting.glow(px,py,28,c,.24*pulse*a)
                        for j=1,3 do
                            local phase=(e.age*.7+j/3)%1
                            color(c,a*(1-phase)*pulse)
                            g.circle("fill",px+(j-2)*9,py-phase*32,1.5)
                        end
                    end
                end
            end
        end
    end
    g.pop()
end
return D
