-- Shared card-local effects: weak keys keep presentation out of saves and clones.
local F={active=setmetatable({},{__mode="k"}),speeds=setmetatable({},{__mode="k"}),reduced=false}
function F.emit(card,kind,value,delay)
    if not card or (value or 0)<=0 then return end
    local effects=F.active[card] or {};F.active[card]=effects
    local previous=effects[kind]
    effects[kind]={age=-(delay or 0),value=value+(previous and previous.age<=0 and previous.value or 0),life=kind=="evolution" and 1.15 or .85}
end
function F.team(cards)
    for i,card in ipairs(cards or {}) do
        if not card.destroyed then
            local e=F.active[card] and F.active[card].speed
            if e then e.age=-math.min((i-1)*.045,.27) end
        end
    end
end
function F.update(dt,reduced)
    F.reduced=reduced==true
    for card,effects in pairs(F.active) do
        for kind,e in pairs(effects) do
            e.age=e.age+dt
            if e.age>=e.life then effects[kind]=nil end
        end
        if not next(effects) then F.active[card]=nil end
    end
end
local function glint(g,x,y,r,c,a)
    g.setColor(c[1],c[2],c[3],a)
    g.polygon("fill",x-r,y,x,y-r*2,x+r,y,x,y+r*2)
    g.setColor(1,1,1,a);g.rectangle("fill",x-.6,y-r*1.3,1.2,r*2.6)
end
function F.draw(UI,card,w,h)
    -- Catch held auras/equipment too, without changing gameplay from a stat getter.
    if card.rank and not card.faceDown then
        local speed=require("src.deck").peekCardAttackSpeed(card)
        local before=F.speeds[card];local current=F.active[card]
        if before and speed>before and not (current and (current.speed or current.evolution)) then F.emit(card,"speed",speed-before) end
        F.speeds[card]=speed
    end
    local effects=F.active[card];if not effects or card.faceDown then return end
    local g=love.graphics;g.push("all")
    for kind,e in pairs(effects) do
        if e.age>=0 then
            local p=e.age/e.life
            local a=math.min(1,e.age/.07)*math.min(1,(1-p)/.30)*(card.alpha or 1)
            local evolution=kind=="evolution"
            local c=evolution and {1,.79,.39} or {.20,.94,1}
            local rise=F.reduced and .5 or p
            -- A narrow sweep stays inside the real card, with no duplicate outline.
            local y=h*(1-rise)
            g.setBlendMode("add","alphamultiply")
            g.setColor(c[1],c[2],c[3],a*.19)
            g.rectangle("fill",3,math.max(3,y-11),w-6,math.max(0,math.min(19,h-6-math.max(3,y-11))))
            g.setColor(1,.98,.88,a*.8);g.setLineWidth(1)
            g.line(5,math.max(4,math.min(h-4,y)),w-5,math.max(4,math.min(h-4,y)))
            if evolution then
                for i=1,7 do
                    local x=8+(w-16)*((i*.618)%1)
                    local sy=h*(.90-((rise*.8+i*.113)%.82))
                    g.setColor(.78,.48,1,a*.55)
                    g.polygon("fill",x-1.5,sy+9,x,sy-9,x+1.5,sy+5)
                    glint(g,x,sy,1.2+(i%3)*.45,c,a*.8)
                end
                glint(g,w/2,h*.31,math.min(9,w*.07)*math.sin(math.pi*p),c,a)
            else
                for side=0,1 do
                    local x=side==0 and w*.17 or w*.83
                    for j=1,2 do
                        local cy=h*(.76-rise*.38)-(j-1)*h*.16
                        g.setLineWidth(j==1 and 2.3 or 1.3)
                        g.setColor(c[1],c[2],c[3],a*(j==1 and .95 or .5))
                        g.line(x-5,cy+4,x,cy-2,x+5,cy+4)
                    end
                    glint(g,x,h*(.73-rise*.45),1.6,c,a*.7)
                end
            end
            g.setBlendMode("alpha")
            local font=UI.fonts.tiny or UI.fonts.small;g.setFont(font)
            local text=(evolution and "TIẾN HÓA +" or "TỐC ĐÁNH +")..string.format("%g",e.value)
            local scale=math.min(1,(w-8)/font:getWidth(text))
            local ty=h*(evolution and .60 or .80)
            g.setColor(.025,.035,.06,a*.9);g.rectangle("fill",3,ty-3,w-6,font:getHeight()*scale+6,2,2)
            g.setColor(c[1],c[2],c[3],a)
            g.print(text,(w-font:getWidth(text)*scale)/2,ty,0,scale,scale)
        end
    end
    g.pop()
end
return F
