local T={}
function T.verify()
    local Entity=require("render.entity")
    local g=love.graphics
    local image=g.newCanvas(64,96)
    local canvas=g.newCanvas(640,480)
    local card={cardRank=7,creatureCard=true}
    local preset={lightTint={1,1,1},ambientColor={1,1,1}}
    local getPosition=love.mouse.getPosition
    local mx,my=-1000,-1000
    love.mouse.getPosition=function() return mx,my end
    g.push("all");g.setCanvas(canvas);g.origin()
    local function draw(time,attack,hit,recoil,squash)
        Entity.draw(image,300,240,180,time,attack or 0,hit or 0,recoil or 0,squash or 1,preset,0,true,nil,card)
        local copy={};for i,v in ipairs(Entity.face(card)) do copy[i]=v end
        return copy
    end
    local function distance(a,b)
        local delta=0;for i=1,8 do delta=math.max(delta,math.abs(a[i]-b[i])) end;return delta
    end
    local ok,err=pcall(function()
        local idle=draw(2.5)
        for _,point in ipairs({{300,240},{250,170},{350,310},{290,300},{-1000,-1000}}) do
            mx,my=point[1],point[2]
            for _=1,20 do
                assert(distance(idle,draw(2.5))<1e-6,"Enemy card tilts/lifts/scales with the pointer")
            end
        end
        local later=draw(3.5)
        assert(distance(idle,later)>1e-4 and distance(idle,later)<4,"Idle motion stays subtle and time-driven")
        assert(distance(idle,draw(2.5,.3,.2,4,.98))>10,"Attack/recoil presentation remains active")
    end)
    g.pop();love.mouse.getPosition=getPosition
    canvas:release();image:release()
    assert(ok,err)
    print("Enemy idle render PASS: mouse sweep cannot tilt/lift/scale the card; subtle idle and attack/recoil remain")
end
return T
