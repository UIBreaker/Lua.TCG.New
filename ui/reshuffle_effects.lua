local F={}
local active=setmetatable({},{__mode="k"})
function F.clear() active=setmetatable({},{__mode="k"}) end
function F.emit(card,before)
    local D=require("src.deck");before=before or {}
    active[card]={age=0,loss={math.max(0,(before.speed or 0)-D.peekCardAttackSpeed(card)),
        math.max(0,(before.damage or 0)-D.getCardDamage(card)),
        math.max(0,(before.empowerment or 0)-D.getCardEmpowerment(card))}}
end
function F.update(dt)
    for card,e in pairs(active) do
        if card.destroyed then active[card]=nil
        elseif not require("src.hand_motion").isDealing(card) then
            e.age=e.age+math.max(0,dt)
            if e.age>=1.15 then active[card]=nil end
        end
    end
end
function F.pose(card,reduced)
    local e=active[card]
    if not e or reduced or require("src.hand_motion").isDealing(card) then return 0 end
    return 4*math.sin(math.min(1,e.age/.32)*math.pi)
end
function F.draw(UI,card,w,h)
    local e=active[card]
    if not e or card.faceDown or require("src.hand_motion").isDealing(card) then return end
    local g=love.graphics;local t=e.age
    local a=math.min(1,t/.045)*math.max(0,1-t/1.15)*(card.alpha or 1)
    local reduced=UI.HandMotion.reducedMotion
    g.push("all");g.setShader();g.setBlendMode("alpha")
    g.setColor(.20,.065,.08,a*.24);g.rectangle("fill",3,3,w-6,h-6,3)
    g.setFont(UI.fonts.tiny)
    for i,name in ipairs({"TỐC","ST","CH"}) do
        local x=(i==1 and .67 or i==2 and .08 or .56)*w
        local y=(i==1 and .24 or .70)*h+(reduced and 0 or t*13)
        local text=e.loss[i]>0 and ("−"..e.loss[i].." "..name) or (name.." ≥0")
        local tw=g.getFont():getWidth(text)+8
        x=math.max(3,math.min(x,w-tw))
        g.setColor(.065,.018,.028,a*.93);g.rectangle("fill",x-3,y-2,tw,17,3)
        g.setColor(1,.48,.36,a);g.print(text,x+1,y)
    end
    if not reduced then
        for i=1,6 do
            local x=w*(.1+i*.115)+math.sin(i*2)*t*8
            local y=h*(.27+(i%3)*.17)+t*37+t*t*22
            local r=(1.8+i%2)*math.max(0,1-t/.85)
            g.setColor(.98,.46,.29,a*.85)
            g.polygon("fill",x-r,y-r,x+r,y,x,y+r*2)
        end
    end
    g.pop()
end
return F
