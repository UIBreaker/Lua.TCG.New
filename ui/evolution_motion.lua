local Motion=require("src.motion")
local E={duration=.96,contactAt=.44}
local function clamp(t) return math.max(0,math.min(1,t)) end
function E.pose(r)
    local flip=clamp((r.age-.30)/.28)
    local pulse=Motion.impact(r.age-E.contactAt,.36)
    local lift=Motion.impact(r.age,E.duration)
    return {old=r.reduced and r.age<E.contactAt or not r.reduced and flip<.5,
        scaleX=r.reduced and 1 or math.max(.025,math.abs(math.cos(flip*math.pi))),
        scale=r.reduced and 1 or 1+.035*lift,y=r.reduced and 0 or -8*lift,
        glow=pulse*(r.reduced and .25 or .65),travel=clamp(r.age/E.contactAt)}
end
function E.card(UI,m,x,y,w,h,draw)
    local r=m.ritual
    if not r then return draw(m.selected,x,y,w,h) end
    local p=E.pose(r);local g=love.graphics
    UI.CardPhysics.suspend();g.push("all")
    g.translate(x+w/2,y+h/2+p.y);g.scale(p.scale*p.scaleX,p.scale);g.translate(-x-w/2,-y-h/2)
    draw(p.old and r.before or m.selected,x,y,w,h)
    if p.glow>0 then UI.drawCardBorder(x,y,w,h,{.78,.62,1,p.glow},p.glow,p.old and r.before or m.selected) end
    g.pop();UI.CardPhysics.resume()
end
function E.draw(UI,m)
    local r=m.ritual;if not r then return end
    local rect=m.cardRects and m.cardRects[m.selected];if not rect then return end
    local g=love.graphics;local p=E.pose(r);local x,y=rect.x+rect.w/2,rect.y+rect.h/2+p.y
    g.push("all");g.setColor(.77,.61,1,p.glow);g.setLineWidth(1.5)
    local radius=rect.w*.68
    for i=1,4 do
        local angle=(i-1)*math.pi/2+(r.reduced and 0 or r.age*.7)
        g.arc("line","open",x,y,radius,angle,angle+.8,14)
    end
    if not r.reduced and r.age<E.contactAt and m.sourceRect then
        local from=m.sourceRect;local travel=Motion.settle(p.travel,1)
        local sx,sy=from.x+from.w/2,from.y+from.h/2
        local px,py=sx+(x-sx)*travel,sy+(y-sy)*travel-math.sin(p.travel*math.pi)^2*32
        local w,h=from.w*(1-.55*travel),from.h*(1-.55*travel)
        g.setColor(.76,.60,1,.3*math.sin(p.travel*math.pi));g.line(sx,sy,px,py)
        UI.Polish.dissolve(UI,px-w/2,py-h/2,w,h,clamp((p.travel-.72)/.28),{.78,.62,1},function(cx,cy,cw,ch)
            UI.Polish.renderItem(UI,m.consumable,cx,cy,cw,ch)
        end)
    end
    g.pop()
end
return E
