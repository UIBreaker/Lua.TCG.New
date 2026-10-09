local E=require("src.equipment")
local D=require("src.deck")
local S=require("src.scoring")
local Poker=require("src.poker")
local P=require("src.persistence")
local I=require("src.inventory")
local Run=require("src.run_manager")
local Frame=require("ui.components.card_frame")
assert(E.MAX_SLOTS==4 and E.SOCKET_CAP==8)
local a,b=D.newCard(10,"clubs"),D.newCard(10,"spades")
assert(a.maxSockets==4 and a.unlockedSockets==4)
assert(E.attach(a,E.ITEMS.basic_plate) and E.attach(b,E.ITEMS.basic_plate))
local hand=Poker.evaluate({a,b},{pair=true,high_card=true})
local ctx={preview=true}
for _=1,2 do
    local result=S.calculate(hand,{},ctx)
    assert(result.addArmor==4,"10 clubs + 10 spades with +2 armor each must award +4")
    local triggers={}
    for _,step in ipairs(result.steps) do
        for _,child in ipairs(step.presentationTriggers or {}) do
            if child.type=="equipment_trigger" then
                assert(child.equipmentIndex==1 and child.addArmor==2)
                triggers[child.card]=true
            end
        end
    end
    assert(triggers[a] and triggers[b],"each owner's equipment must have a separate presentation")
end
-- Identity comes from the owner, so even legacy cards with missing IDs stay separate.
a.id,b.id=nil,nil
local missingIds={}
assert(E.ITEMS.basic_plate.onCardScore(a,{a,b},1,missingIds).addArmor==2)
assert(E.ITEMS.basic_plate.onCardScore(b,{a,b},2,missingIds).addArmor==2)
local c=D.newCard(10,"clubs")
local g={persistentDeck={c},hand={D.cloneCard(c)},consumables={}}
for capacity=5,8 do
    g.consumables={Run.createSocketCard()}
    assert(I.useCardUpgrade(g,1,g.hand[1]) and E.getMaxSlots(c)==capacity)
    assert(g.hand[1].maxSockets==capacity)
end
g.consumables={Run.createSocketCard()}
assert(not I.useCardUpgrade(g,1,c) and #g.consumables==1)
c.allowDuplicateEquipment=true
for _=1,8 do assert(E.attach(c,E.ITEMS.basic_plate)) end
assert(not E.attach(c,E.ITEMS.basic_plate))
local result=S.calculate(Poker.evaluate({c},{high_card=true}),{},{})
assert(result.addArmor==16,"all eight installed equipment instances must activate separately")
local count=0
for _,step in ipairs(result.steps) do for _,child in ipairs(step.presentationTriggers or {}) do
    if child.type=="equipment_trigger" then count=count+1;assert(child.equipmentIndex==count and child.addArmor==2) end
end end
assert(count==8)
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"playing"))).persistentDeck[1]
assert(loaded.maxSockets==8 and #loaded.equipments==8)
local old=D.newCard(3,"hearts");old.maxSockets=3
assert(E.getMaxSlots(old)==4,"legacy cards get the new minimum without losing equipment")
local multi={equipments={E.ITEMS.void_catalyst,E.ITEMS.basic_plate}}
local entries=E.getSocketEntries(multi)
assert(#entries==3 and entries[2].linked and entries[1].equipmentIndex==entries[2].equipmentIndex)
assert(entries[3].equipmentIndex==2)
for i=1,8 do local x,y=Frame.socketPosition(i,100,150);assert(x>0 and y>0 and x<100 and y<150) end
local Effects=require("src.card_effects")
Effects.triggerEquipmentPulse(c,8);assert(Effects.getEquipmentPulse(c,8)==1 and Effects.getEquipmentPulse(c,1)==0)
Effects.update(0.5);assert(Effects.getEquipmentPulse(c,8)==0)
print("Equipment sockets PASS: default 4 / maximum 8, expansion and persistence, per-owner +4 armor, all 8 instances, linked sockets and independent jewel pulse")
return true
