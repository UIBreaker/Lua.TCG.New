local M=require("src.nen_magic")
local C=M.config
local seen,explosions={},{}
assert(#C.order==27)
for _,id in ipairs(C.order) do
    assert(not seen[id]);seen[id]=true
    local h=C.hands[id];assert(not explosions[h.explosionType]);explosions[h.explosionType]=true
    assert(h.projectileCount>=1 and h.projectileCount<=9 and h.colorPalette[1])
    for _,aura in ipairs({0,200,1000,2500,8000,1e308,math.huge,-1,0/0}) do
        local a=M.play(id,aura,{x=500,y=440},{x=660,y=290})
        local s=M.state(a);assert(s.scale.level>=1 and s.scale.level<=4 and s.scale.size<=1.45 and s.scale.particles<=24)
        for i=1,h.projectileCount do
            for step=0,100 do local x,y=M.position(s,i,step/100);assert(x==x and y==y and math.abs(x)<2000 and math.abs(y)<2000) end
            local x,y=M.position(s,i,1);assert(math.abs(x-660)+math.abs(y-290)<.001,id.." contact")
        end
        M.clear(a);assert(not M.state(a))
    end
    local a=M.play(id,1000,{x=500,y=440},{x=660,y=290});a.nen.snapshot.dead=true;assert(not M.state(a))
    for _,fps in ipairs({30,60,144}) do
        local a=M.play(id,1000,{x=500,y=440},{x=660,y=290});local completed=false
        for i=1,math.ceil(fps*1.5) do if M.update(a,1/fps) then completed=true;break end end
        assert(completed,id.." delta-time completion")
    end
end
for i,value in ipairs({200,1000,2500,8000}) do assert(M.scale(value,1000).level==i) end
local source,target={x=500,y=440},{x=660,y=290}
local frozen=M.play("high_card",1000,source,target);local x,y=M.position(M.state(frozen),1,0)
assert(x==source.x and y==source.y,"source anchor")
target.x,target.y=-1000,-1000;target=nil
x,y=M.position(M.state(frozen),1,1);assert(x==660 and y==290,"removed/moved target keeps frozen contact")
M.clear(frozen)
print("NEN MAGIC pure: 27 unique profiles/explosions, bounded AURA, 101 path samples/projectile, arrival, dead target, cancellation, 30/60/144 FPS PASS")
return true
