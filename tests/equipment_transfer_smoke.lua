local T=require("ui.equipment_transfer")
local E=require("src.equipment")
local D=require("src.deck")
local B=require("src.basic_equipment")
local Context=require("ui.backpack_context")
local Bag=require("ui.backpack")
local Q=require("ui.backpack_qol")
local source=D.newCard(4,"diamonds");source.maxSockets=8
for i=1,8 do assert(E.attach(source,E.ITEMS[B.basic[i]])) end
local target=D.newCard(7,"hearts");local duplicate=D.newCard(9,"spades")
local game={persistentDeck={source,target,duplicate},gold=88}
T.reset();assert(#T.list(game.persistentDeck)==1 and T.selectSource(source) and not T.eqIndex)
local original={};for i,eq in ipairs(source.equipments) do original[i]=eq end
T.eqIndex=2;assert(E.attach(duplicate,original[2]))
assert(#T.list(game.persistentDeck)==1 and T.list(game.persistentDeck)[1].card==target)
T.onlyCompatible=false;assert(#T.list(game.persistentDeck)==2)
assert(not T.move(game,duplicate) and #source.equipments==8)
local saves=0;assert(T.move(game,target,nil,function()saves=saves+1 end))
assert(#source.equipments==7 and target.equipments[1]==original[2] and game.gold==88 and saves==1)
assert(T.undo(game,nil,function()saves=saves+1 end))
assert(#target.equipments==0 and #source.equipments==8 and saves==2)
for i,eq in ipairs(source.equipments) do assert(eq==original[i],"undo retains equipment scoring order") end
T.eqIndex=1;assert(not T.move(game,D.newCard(2,"clubs")),"cannot transfer to an unowned card")
local solo=D.newCard(3,"hearts");assert(E.attach(solo,E.ITEMS.basic_lace));game.persistentDeck[#game.persistentDeck+1]=solo
assert(T.selectSource(solo) and T.eqIndex==1);assert(T.move(game,target));assert(not T.eqIndex and #solo.equipments==0)
for i=1,4 do assert(E.attach(solo,E.ITEMS[B.basic[i]])) end
assert(not T.undo(game) and #target.equipments==1,"blocked undo must leave both inventories intact")
solo.equipments={};assert(T.undo(game) and #solo.equipments==1 and #target.equipments==0)
local savedGame=require("src.game_state").new();savedGame.persistentDeck=game.persistentDeck;savedGame.gold=game.gold
savedGame.run=require("src.run_manager").newRun("red_deck")
local P=require("src.persistence");local loaded=assert(P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(savedGame,"shop"))))))
assert(loaded.gold==88)
for i,card in ipairs(game.persistentDeck) do
 assert(#(loaded.persistentDeck[i].equipments or {})==#(card.equipments or {}))
 for j,eq in ipairs(card.equipments or {}) do assert(loaded.persistentDeck[i].equipments[j].id==eq.id) end
end
Bag.views={};Bag.tab="consumable";Bag.open=true;Bag.page=3;Bag.loadoutOffset=6
local view=Q.state(Bag);view.query="sao";view.sort=2;view.filter=1
local origin=Context.capture(Bag);Bag.close();Q.switch(Bag,"cards");Bag.page=1
Context.restore(Bag,origin)
assert(Bag.open and Bag.tab=="consumable" and Bag.page==3 and Bag.loadoutOffset==6 and Q.state(Bag).query=="sao" and Q.state(Bag).sort==2)
Bag.close();Bag.views={};Bag.tab="spn";Bag.page=1;T.reset()
print("Equipment transfer / return context PASS: owned-only transfer, eight items, compatible filtering, exact-order undo, atomic rejection, free transfer/save and backpack page/filter restoration")
return true
