-- One solid motif per utility; shared by the rail and the actual impact.
local I={}
function I.draw(grade,x,y,size,c,alpha)
    local g=love.graphics;g.push("all");g.translate(x,y);g.scale(size/10)
    g.setColor(c[1],c[2],c[3],alpha or 1);g.setLineWidth(2.4);g.setLineJoin("bevel")
    if grade=="siphon" then
        g.polygon("fill",0,-11,7,0,6,6,0,10,-6,6,-7,0)
    elseif grade=="pierce" then
        g.polygon("fill",-13,3,5,-2,3,-6,14,0,3,6,5,2,-13,5)
    elseif grade=="haste" then
        for i=0,1 do local y=5-i*9;g.line(-8,y+3,0,y-4,8,y+3) end
    elseif grade=="mend" then
        g.rectangle("fill",-3,-10,6,20);g.rectangle("fill",-10,-3,20,6)
    elseif grade=="reserve" then
        g.polygon("fill",-7,-10,3,-10,8,-5,8,10,-7,10)
        g.setColor(.06,.04,.015,alpha or 1);g.rectangle("fill",-4,-1,9,2);g.rectangle("fill",0,-4,2,8)
    elseif grade=="rebound" then
        g.line(-8,8,-8,0,6,0,6,-8)
        g.polygon("fill",0,-5,6,-12,12,-5)
    end
    g.pop()
end
return I
