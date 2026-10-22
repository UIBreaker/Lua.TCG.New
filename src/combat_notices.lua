-- Presentation state stays outside the run and preview sandbox.
local N={}
local Boss=require("src.boss_abilities")
local states=setmetatable({}, {__mode="k"})
local function state(game)
    local s=states[game]
    if not s or s.combat~=game.spnCombat then s={combat=game.spnCombat,hits=setmetatable({}, {__mode="k"}),ghosts={},statuses=setmetatable({}, {__mode="k"})};states[game]=s end
    return s
end
function N.inspect(game) return state(game) end
function N.activate(card,text)
    if not N.game or not N.active or not card then return end
    local s=state(N.game);s.hits[card]={age=0,text=text or "KÍCH HOẠT"}
    local first
    for slot,d in pairs(N.game.deities or {}) do if type(slot)=="number" and d and (not first or slot<first) then first=slot end end
    if first and N.game.deities[first]==card then
        for slot,d in pairs(N.game.deities) do
            local source=require("src.deities").resolveDeity(N.game.deities,slot,N.game)
            if source and source.id=="spirit_left_refrain" and not Boss.isSlotLocked(N.game,"spn",slot) then
                s.hits[d]={age=0,text="TÁI KÍCH HOẠT"}
            end
        end
    end
end
function N.threat(game,card)
    local m=game and game.monster;local s=m and Boss.state(m)
    local a=m and m.bossData and m.bossData.active
    return card and card.id and m and m.hp>0 and s and a and s.activeCountdown==1 and s.activeUntil<s.handIndex
        and (a.op:find("silence") or a.op=="face") and s.targetId==card.id
end
function N.warning(game,card)
    if N.threat(game,card) then return "BOSS NHẮM","Boss sắp nhắm vào lá này" end
    for slot,d in pairs(game and game.deities or {}) do
        if d==card and slot>1 and not Boss.isSlotLocked(game,"spn",slot) and not Boss.isSlotLocked(game,"spn",slot-1) then
            local left=require("src.deities").resolveDeity(game.deities,slot-1,game)
            if left and left.id=="spirit_right_offering" then return "SẮP HIẾN TẾ","Sẽ bị "..left.name.." tiêu hủy khi ghi điểm" end
        end
    end
end
function N.restriction(game,card)
    if not game or not card or card.destroyed then return end
    if card.rank then
        if card.exhausted then return "KIỆT SỨC","Không ghi điểm trong tay này" end
        local reason=Boss.scoreBlockReason(game.monster,card)
        if reason then return "VÔ HIỆU",reason.." · 0 điểm" end
        if Boss.isAbilityDisabled(game,card) then return "KHÓA KỸ NĂNG","Boss vô hiệu khả năng; vẫn tính chỉ số bài" end
        if card.faceDown then return "ÚP MẶT","Boss che mặt lá bài" end
    else
        for slot,d in pairs(game.deities or {}) do if d==card and Boss.isSlotLocked(game,"spn",slot) then
            if require("src.free_human_bosses").spnBlocked(game.monster,card) then return "PHONG ẤN BẬC","Boss vô hiệu hóa SPN bậc "..require("src.deities").getRarityBadge(card) end
            return "SPN BỊ KHÓA","Boss khóa ô SPN #"..slot
        end end
        for i,c in ipairs(game.consumables or {}) do if c==card and Boss.isSlotLocked(game,"consumable",c.loadoutSlot or i) then return "Ô BỊ KHÓA","Boss khóa ô tiêu hao" end end
    end
end
function N.push(game,event)
    local s=state(game)
    local card=event.deity or event.card
    local text=event.text or "KÍCH HOẠT"
    if card then s.hits[card]={age=0,text=text,kind=event.kind} end
    if event.kind=="destroy" and event.deity then s.ghosts[#s.ghosts+1]={card=card,slot=event.slot,age=0,text=text} end
end
function N.update(dt,game,screen,reduced,paused)
    N.game=game;N.active=screen=="playing" or screen=="scoring";N.reduced=reduced
    if not game then return end
    local s=state(game)
    if paused then return end
    if not N.active and screen~="CASH_OUT" then s.ghosts={};s.statuses=setmetatable({}, {__mode="k"});return end
    for card,hit in pairs(s.hits) do hit.age=hit.age+dt;if hit.age>1.35 then s.hits[card]=nil end end
    for i=#s.ghosts,1,-1 do local e=s.ghosts[i];e.age=e.age+dt;if e.age>=2.2 then table.remove(s.ghosts,i) end end
    if not N.active then return end
    local function scan(card)
        local label,reason=N.restriction(game,card)
        if not label then label,reason=N.warning(game,card) end
        local old=s.statuses[card]
        if label and old~=reason then N.push(game,{card=card,title=card.name or (card.rankName or "")..(card.suitSymbol or ""),text=reason,kind=(label=="BOSS NHẮM" or label=="SẮP HIẾN TẾ") and "warning" or "lock"})
        elseif old and not reason then N.push(game,{card=card,text="ĐÃ GỠ KHÓA · Có thể hoạt động trở lại",kind="release"}) end
        s.statuses[card]=reason
    end
    for _,c in ipairs(game.hand or {}) do scan(c) end
    for _,d in pairs(game.deities or {}) do scan(d) end
    for _,c in ipairs(game.consumables or {}) do scan(c) end
end
function N.pose(card)
    local s=N.game and states[N.game];local hit=s and s.hits[card]
    if not N.active or not hit then return 0,0,0 end
    local t=hit.age;local p=math.max(0,1-t/.65)
    return N.reduced and 0 or math.sin(t*38)*p*.045,N.reduced and 0 or -math.sin(math.min(1,t/.65)*math.pi)*9,p
end
local function badge(hit)
    if not hit then return "KÍCH HOẠT" end
    if hit.kind=="boss" then return "BOSS ĐÁNH" end
    if hit.kind=="release" then return "MỞ KHÓA" end
    if hit.text=="TÁI KÍCH HOẠT" then return "LẶP SPN" end
    local number=hit.text:match("%+[%d%.]+")
    if number then
        for _,pair in ipairs({{"TẦNG","TẦNG"},{"Sát thương","ST"},{" ST","ST"},{"Cường hóa","CH"},{"GIÁP","GIÁP"},{"Giáp","GIÁP"},{"Vàng","VÀNG"}}) do
            if hit.text:find(pair[1],1,true) then return number.." "..pair[2] end
        end
    end
    return nil
end
local function pill(UI,text,x,y,w,color,alpha)
    local g=love.graphics;local font=UI.fonts.tiny
    local width=math.min(w-8,font:getWidth(text)+14)
    local _,rows=font:getWrap(text,width-8);local height=math.min(2,#rows)*font:getHeight()+6
    local left=x+(w-width)/2
    g.setColor(.025,.035,.043,.86*(alpha or 1));g.rectangle("fill",left,y,width,height,5,5)
    g.setColor(color[1],color[2],color[3],.45*(alpha or 1));g.setLineWidth(1);g.rectangle("line",left,y,width,height,5,5)
    for row=1,math.min(2,#rows) do require("ui.components.core").textLine(rows[row],left+4,y+3+(row-1)*font:getHeight(),width-8,font,{color[1],color[2],color[3],alpha or 1},"center") end
end
function N.overlay(UI,card,x,y,w,h)
    if not N.active or card and card.destroyed then return end
    local label=N.restriction(N.game,card)
    local threat=N.warning(N.game,card)
    local s=states[N.game];local hit=s and s.hits[card]
    if not label and not threat and not hit then return end
    local g=love.graphics;g.push("all");g.setShader();g.setBlendMode("alpha")
    if not label then
        local color=threat and {1,.66,.22,1} or hit and hit.kind=="boss" and {1,.46,.36,1} or {.6,.9,1,1}
        local title=threat or badge(hit)
        local fade=threat and 1 or math.min(1,(1.35-hit.age)/.35)
        if title then pill(UI,title,x,y+h-31,w,color,fade) end
        local strength=threat and .8 or math.max(0,1-hit.age/.8)
        g.setColor(color[1],color[2],color[3],strength);g.setLineWidth(2)
        for _,corner in ipairs({{x+3,y+3,1,1},{x+w-3,y+3,-1,1},{x+3,y+h-3,1,-1},{x+w-3,y+h-3,-1,-1}}) do
            local cx,cy,sx,sy=unpack(corner);g.line(cx,cy+sy*9,cx,cy,cx+sx*9,cy)
        end
        g.pop();return
    end
    g.setColor(.035,.015,.025,.25);g.rectangle("fill",x,y,w,h,4,4)
    for _,line in ipairs({{x+w*.18,y+h*.18,x+w*.82,y+h*.78},{x+w*.82,y+h*.18,x+w*.18,y+h*.78}}) do
        g.setLineWidth(5);g.setColor(.055,.012,.02,.75);g.line(unpack(line))
        g.setLineWidth(2);g.setColor(.96,.43,.39,.9);g.line(unpack(line))
    end
    pill(UI,label,x,y+h*.60,w,{1,.77,.71})
    g.pop()
end
function N.draw(UI,game)
    local s=states[game];if not s then return end
    local g=love.graphics;g.push("all");g.setShader();g.setBlendMode("alpha")
    for _,e in ipairs(s.ghosts) do
        local x,y,w,h=require("ui.inventory_rail").rect("spn",e.slot,game)
        if e.slot<=0 or game.deities[e.slot] then x,y,w,h=855,235,92,138 end
        local fade=math.max(0,math.min(1,(2.2-e.age)/.8))
        local image=UI.getDeityImage(e.card.id)
        g.push("all");g.translate(x+w/2,y+h/2-(N.reduced and 0 or (1-fade)*12));g.rotate(N.reduced and 0 or math.sin(e.age*23)*.018*fade)
        g.setColor(1,.65,.65,fade)
        if image then UI.CardFrame.image(image,-w/2,-h/2,w,h) end
        UI.CardFrame.draw(-w/2,-h/2,w,h,{1,.35,.3,fade},fade,e.card,0,true)
        g.setColor(1,.55,.42,fade);g.setLineWidth(1.5);g.line(-w*.35,-h*.38,w*.35,h*.38);g.line(w*.35,-h*.38,-w*.35,h*.38)
        if not N.reduced then for i=1,8 do
            local angle=i*math.pi/4;local distance=12+e.age*28
            g.setColor(1,.65,.38,fade*.65);g.circle("fill",math.cos(angle)*(w*.3+distance),math.sin(angle)*(h*.3+distance),1.5)
        end end
        g.pop()
        pill(UI,"TAN BIẾN",x,y+h*.62,w,{1,.73,.58},fade)
    end
    g.pop()
end
return N
