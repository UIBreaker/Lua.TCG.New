-- A near miss passes the target; it never creates a contact flash or camera kick.
local M={}
local scores=require("config.attack_audio")
local function tierOf(a) return a.nen and a.nen.tier or math.min(3,a.tier or 1) end
function M.duration(a) return ({.38,.52,.70})[tierOf(a)] end
local function clamp(p) return math.max(0,math.min(1,p)) end
local function side(a)
    local n=0;for i=1,#a.profile.id do n=n+a.profile.id:byte(i) end
    return n%2==0 and 1 or -1
end
function M.pose(a,age)
    if a.nen and a.nen.reducedMotion or a.reducedMotion then return 0,1,0 end
    local p=clamp((age or 0)/M.duration(a))
    return -side(a)*(12+tierOf(a)*4)*math.sin(p*math.pi)^.8,1,0
end
function M.draw(a,age)
    local n=a.nen
    if n then n.particleCount=0 end
    if not age or age<0 or age>=M.duration(a) or n and n.cancelled then return end
    local g=love.graphics;local p=clamp(age/M.duration(a));local sign=side(a)
    local reduced=n and n.reducedMotion or a.reducedMotion
    local color=a.color or {.45,.85,1};local cx=a.cx or 640
    local alpha=(1-p)^1.4
    g.push("all");g.setShader();g.setBlendMode("alpha")
    local l,t=g.transformPoint(242,150);local r,b=g.transformPoint(1022,565)
    g.intersectScissor(l,t,r-l,b-t)
    if reduced then
        g.setColor(color[1],color[2],color[3],alpha*.6);g.setLineWidth(2)
        g.line(cx+sign*90,285,cx+sign*119,277);g.line(cx+sign*95,294,cx+sign*116,289)
    else
        local tier=tierOf(a)
        local score=scores[a.profile.id] or scores.high_card
        local material=score.material
        local reach=155+tier*42
        local lanes=({2,3,5})[tier]
        local function point(k,lane)
            local ripple=material=="lightning" and math.sin(k*79+lane*2)*7
                or (material=="ice" or material=="prism" or material=="obsidian") and math.abs(math.sin(k*19))*8
                or material=="eclipse" and math.sin(k*math.pi*2+lane)*12 or 0
            return cx+sign*(45+reach*k+lane*3),300-math.sin(k*math.pi)*(22+tier*8+lane*4)-k*30+lane*7+ripple
        end
        for lane=0,lanes-1 do
            local points={};local head=clamp(.08+p*1.65-lane*.035);local tail=math.max(0,head-(.23+tier*.06)*(1-p))
            for j=0,12 do local x,y=point(tail+(head-tail)*j/12,lane);points[#points+1]=x;points[#points+1]=y end
            g.setColor(color[1],color[2],color[3],alpha*(lane==0 and .26 or .12));g.setLineWidth(8+tier)
            g.line(points)
            g.setColor(.25+color[1]*.75,.25+color[2]*.75,.25+color[3]*.75,alpha*(lane==0 and .95 or .45));g.setLineWidth(lane==0 and 2.5 or 1)
            g.line(points)
        end
        local count=a.quality=="low" and 4 or 4+tier*2
        for i=1,count do
            local beat=score.rhythm[(i-1)%#score.rhythm+1]
            local k=clamp(p*1.65-i*.025-beat*.2);local x,y=point(k,0)
            local drift=math.sin(i*2.399)*p*(14+tier*7)
            g.setColor(color[1],color[2],color[3],alpha*.50)
            local length=3+score.notes[(i-1)%#score.notes+1]*tier*2
            g.setLineWidth(1);g.line(x,y+drift,x-sign*length,y+drift-3)
            if material=="ice" or material=="prism" then
                g.line(x-sign*length,y+drift-3,x-sign*length*.6,y+drift+3)
            end
        end
        if n then n.particleCount=count end
    end
    g.pop()
end
return M
