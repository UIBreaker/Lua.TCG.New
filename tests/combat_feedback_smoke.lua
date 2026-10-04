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
print("Combat feedback: five tiers/boundaries, gain/spend/absorption, overlap, bounded queue and expiration passed")
