local F = require("src.combat_feedback")
for tier,value in ipairs({25,250,2500,25000,250000}) do
    assert(F.tier(value)==tier)
    local ft = F.new("damage",value,640,214,tostring)
    assert(ft.label and ft.tier==tier)
    F.update(ft,0.12)
    assert(ft.alpha==1 and ft.life>0)
    assert(F.update(ft,3) and ft.alpha==0)
end
assert(F.tier(99)==1 and F.tier(100)==2 and F.tier(999)==2 and F.tier(1000)==3)
assert(F.tier(9999)==3 and F.tier(10000)==4 and F.tier(100000)==5 and F.tier(1e15)==5)
local list={}
F.add(list,"damage",50,640,214)
F.add(list,"damage",50,640,214)
assert(list[1].x~=list[2].x and list[1].y~=list[2].y)
for i=1,100 do F.add(list,"gold",i,475,96) end
assert(#list==24)
assert(F.new("gold",-20,0,0).text=="−20 VÀNG")
assert(F.new("armor",-12,0,0).text=="−12 GIÁP")
assert(F.new("gold",3,0,0).rewardLevel==1 and F.new("gold",120,0,0).rewardLevel==4)
local rng=require("src.rng");local before=rng.getState()
for _,fps in ipairs({30,60,120,144}) do
    local meter=F.updateMeter(nil,100,0)
    meter=F.updateMeter(meter,40,1/fps)
    assert(meter.value==40 and meter.shown>40 and meter.trail==100,"damage has a visible delayed trail")
    for _=1,fps do
        meter=F.updateMeter(meter,40,1/fps)
        assert(meter.shown>=40 and meter.shown<=100 and meter.trail>=meter.shown-1e-9)
    end
    assert(meter.shown==40 and meter.trail==40)
    meter=F.updateMeter(meter,90,1/fps,0.58)
    assert(meter.shown>40 and meter.shown<90 and meter.trail==meter.shown)
    -- New gains/spends can arrive while a previous count is still moving.
    for _,amount in ipairs({5,120,0,12,0}) do
        meter=F.updateMeter(meter,amount,1/fps,0.58)
        assert(meter.shown>=0 and meter.shown<=120)
    end
    meter=F.updateMeter(meter,0,2,0.58)
    assert(meter.shown==0 and meter.trail==0,"armor depletion and interrupted counts settle exactly")
end
assert(rng.getState()==before,"feedback must not consume gameplay RNG")
print("Combat feedback PASS: five tiers through 1e15, reward intensity, 30/60/120/144 FPS resource gain/loss/reversal, delayed armor/HP trails, exact settle, overlap, bounded queue, no gameplay RNG")
