-- Continental stamps: broad engraved silhouettes stay readable at hand-card size.
local Deck=require("src.deck")
local Emblems={}
local shapes={}
local function polygon(...) love.graphics.polygon("fill",...) end
local function line(...) love.graphics.line(...) end

function shapes.blood()
    polygon(0,-9,5,-2,6,2,4,6,0,8,-4,6,-6,2,-5,-2)
    love.graphics.arc("line","open",0,0,10,-0.45,1.15)
    polygon(5,10,8,5,3,6)
end
function shapes.anchor()
    local g=love.graphics
    g.circle("line",0,-7,2.4,16);line(0,-4,0,8);line(-5,-2,5,-2)
    line(-8,2,-6,6,0,9,6,6,8,2)
    polygon(-9,1,-9,6,-4,3);polygon(9,1,9,6,4,3)
end
function shapes.bounty()
    local g=love.graphics
    g.circle("line",0,1,7,24)
    polygon(0,-4,4,1,0,6,-4,1)
    polygon(-7,-8,-4,-6,0,-9,4,-6,7,-8,5,-3,-5,-3)
end
function shapes.purifying()
    love.graphics.polygon("line",-8,-7,0,-9,8,-7,7,2,0,9,-7,2)
    polygon(-5,-5,0,-6,5,-5,4,1,0,6,-4,1)
    line(0,-4,0,3)
end
function shapes.sunder()
    polygon(-8,-8,0,-9,-3,-2,0,1,-4,7,-7,3)
    polygon(3,-9,8,-7,7,3,0,9,3,2,0,-1)
end
function shapes.lantern()
    polygon(-3,-2,3,-2,5,8,-5,8)
    love.graphics.rectangle("line",-3.5,-6,7,4)
    polygon(0,-10,5,-7,-5,-7)
    line(-7,9,7,9);line(-6,-5,-10,-7);line(6,-5,10,-7)
    line(-6,-2,-10,0);line(6,-2,10,0)
end
function shapes.echoes()
    love.graphics.circle("line",0,0,6,24)
    polygon(0,-11,2.5,-3,0,-1,-2.5,-3)
    polygon(11,0,3,2.5,1,0,3,-2.5)
    polygon(0,11,-2.5,3,0,1,2.5,3)
    polygon(-11,0,-3,-2.5,-1,0,-3,2.5)
end
function shapes.reclaimer()
    local g=love.graphics
    g.arc("line","open",0,0,8,-0.5,4.6)
    polygon(-5,-8,2,-11,1,-4)
    g.circle("line",0,1,3.5,16);line(-1,1,1,1)
end
function shapes.gambit()
    local g=love.graphics
    g.circle("line",0,0,8,30)
    for i=1,5 do
        local a=(i-1)*math.pi*2/5-math.pi/2
        local x,y=math.cos(a),math.sin(a)
        line(x*3,y*3,x*9,y*9);g.circle("fill",x*9,y*9,1.8,8)
    end
    polygon(0,-3,3,0,0,3,-3,0)
end
function shapes.threshold()
    local g=love.graphics
    for i=0,2 do g.rectangle("fill",-7,-7+i*6,14,3,1,1) end
end
Emblems.shapes=shapes

function Emblems.draw(id,cx,cy,r,alpha)
    local d=Deck.getModifier("seal",id)
    local shape=d and shapes[d.symbol]
    if not shape then return end
    alpha=alpha or 1
    local g=love.graphics;local c=d.color
    g.push("all");g.translate(cx,cy);g.scale(r/16)
    g.setColor(0.005,0.009,0.015,alpha*0.65);g.circle("fill",0,2,17,32)
    -- Bevelled bronze rim and dark enamel, with light coming from the upper left.
    for i=1,12 do
        local a,b=(i-1)*math.pi/6-math.pi/2,i*math.pi/6-math.pi/2
        local light=0.65+0.22*math.cos((a+b)/2+2.2)
        g.setColor(light,light*0.83,light*0.56,alpha)
        polygon(0,0,math.cos(a)*16,math.sin(a)*16,math.cos(b)*16,math.sin(b)*16)
    end
    g.setColor(c[1]*0.18,c[2]*0.18,c[3]*0.18,alpha);g.circle("fill",0,0,13.6,32)
    g.setColor(c[1]*0.30,c[2]*0.30,c[3]*0.30,alpha)
    g.arc("fill","pie",0,0,13.2,math.pi,math.pi*2)
    g.setLineWidth(0.7);g.setColor(c[1],c[2],c[3],alpha*0.6);g.circle("line",0,0,12.6,32)
    g.setLineWidth(1.9);g.setLineJoin("bevel")
    g.push();g.translate(0,0.8);g.setColor(0.015,0.012,0.009,alpha);shape();g.pop()
    g.setColor(0.98,0.87,0.61,alpha);shape()
    g.setColor(1,0.94,0.78,alpha*0.65);g.setLineWidth(0.8)
    g.arc("line","open",0,0,15.1,3.45,4.95)
    g.pop()
end

return Emblems
