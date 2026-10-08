local UI=require("src.ui");local P=UI.Polish;local Bag=require("ui.backpack")
local B=require("src.basic_equipment");local E=require("src.equipment");local D=require("src.deck")
local card=D.newCard(7,"hearts");local speed=D.getCardAttackSpeed(card)
local g={gold=20,persistentDeck={card},backpackEquipment={{id="basic_lace",investment=3}}}
local callbacks={save=function() end};local rect={x=380,y=191,w=96,h=144,item=card,index=1}
Bag.open=true;Bag.tab="cards";Bag.pending=1;Bag.cells={rect};P.applications={}
Bag.mouse(UI,g,{},428,260,1,callbacks)
assert(#P.applications==1 and P.applications[1].kind=="equip" and P.applications[1].fixedRect.x==380)
assert(P.applications[1].text:find("ĐÃ GẮN",1,true) and D.getCardAttackSpeed(card)==speed+1)
Bag.mouse(UI,g,{{id="bag_detach_1",x=380,y=560,w=178,h=36}},420,579,1,callbacks)
assert(#P.applications==2 and P.applications[2].kind=="unequip" and D.getCardAttackSpeed(card)==speed)
assert(#g.backpackEquipment==1 and B.investment(g.backpackEquipment[1])==3)
-- Failed duplicate attachment must not animate or remove inventory.
card.equipments={E.ITEMS.basic_lace};Bag.pending=1
Bag.mouse(UI,g,{},428,260,1,callbacks)
assert(#P.applications==2 and #g.backpackEquipment==1)
for _,fps in ipairs({30,60,144}) do
 P.applications={};P.application(UI,E.ITEMS.basic_lace,card,"1/3 hốc",rect,rect,"equip")
 for _=1,math.ceil(2.1*fps) do P.update(1/fps,false,"playing") end
 assert(#P.applications==0)
end
Bag.close();P.applications={}
require("tests.action_vfx_smoke")
print("Equipment feedback PASS: attach/detach dispatch, failure silence, inventory/speed, expiry at 30/60/144 FPS and action regressions")
return true
