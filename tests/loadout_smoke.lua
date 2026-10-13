local G=require("src.game_state")
local L=require("src.loadout")
local D=require("src.deities")
local Shop=require("src.shop")
local P=require("src.persistence")
local Combat=require("src.combat")
local Deck=require("src.deck")
local g=G.new();g.run=require("src.run_manager").newRun("red_deck");g.gold=1000
local potion=Shop.healingItem(nil,"healing_potion").consumable
local offers={items={Shop.healingItem(nil,"healing_potion"),{category="deity",deity=D.CATALOG.spirit_fleet_wind,cost=4}}}
g.consumables={potion,Shop.healingItem(nil,"armor_potion_small").consumable,Shop.healingItem(nil,"cons_speed_small").consumable}
for i=1,5 do D.addDeity(g,D.CATALOG.spirit_pebble,i) end
assert(Shop.buyItem(offers,1,g) and #g.consumables==3 and #g.backpackConsumables==1)
assert(Shop.buyItem(offers,1,g) and D.getCount(g.deities)==5 and #g.backpackDeities==1)
local bought=g.backpackConsumables[1]
assert(L.move(g,"consumable","reserve",1,2,false))
assert(L.equipped(g,"consumable",2)==bought and #g.consumables==3 and #g.backpackConsumables==1)
assert(L.move(g,"consumable","equipped",2,nil,false) and #g.consumables==2 and g.backpackConsumables[2]==bought)
assert(L.move(g,"consumable","reserve",2,3,false))
assert(L.equipped(g,"consumable",3)==bought)
assert(L.move(g,"consumable","equipped",3,2,false) and L.equipped(g,"consumable",2)==bought)
local wind=g.backpackDeities[1];wind.evolutionLevel=1;wind.edition="ancient"
assert(L.move(g,"spn","reserve",1,5,false) and g.deities[5]==wind and #g.backpackDeities==1)
assert(L.move(g,"spn","equipped",5,nil,false) and not g.deities[5])
g.persistentDeck={Deck.newCard(4,"valoria"),Deck.newCard(6,"elaris")}
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=2},1)
assert(require("src.spn_basics").speed(g)==0,"Reserved SPN has no battle effect")
assert(L.move(g,"spn","reserve",2,5,true) and require("src.spn_basics").speed(g)>0)
local before=g.handsRemaining;g.handsRemaining=0
assert(not L.move(g,"spn","equipped",5,nil,true) and g.deities[5]==wind)
g.handsRemaining=before
assert(not L.move(g,"spn","equipped",5,5,true))
assert(not L.move(g,"spn","reserve",999,1,true) and not L.move(g,"consumable","reserve",1,99,true))
local lock=require("src.boss_abilities").isSlotLocked
require("src.boss_abilities").isSlotLocked=function(_,kind,slot) return kind=="spn" and slot==5 end
assert(not L.move(g,"spn","equipped",5,nil,true) and not L.move(g,"spn","reserve",1,5,true))
require("src.boss_abilities").isSlotLocked=lock
local snapshot=P.makeSnapshot(g,"shop");local restored=assert(P.restoreSnapshot(snapshot))
assert(restored.deities[5].id==wind.id and restored.deities[5].evolutionLevel==1 and restored.deities[5].edition=="ancient")
assert(restored.deities[5].stat=="addAttackSpeed" and restored.backpackDeities[1].onHandScored and #restored.backpackDeities==1)
assert(#restored.backpackConsumables==#g.backpackConsumables and #restored.consumables==#g.consumables)
assert(L.equipped(restored,"consumable",2).id==bought.id)
snapshot.game.backpackConsumables=nil;snapshot.game.backpackDeities=nil
for _,item in ipairs(snapshot.game.consumables) do item.loadoutSlot=nil end
restored=assert(P.restoreSnapshot(snapshot))
assert(#restored.backpackConsumables==0 and #restored.backpackDeities==0 and #restored.consumables==2)
G.resetRun(g);assert(#g.backpackConsumables==0 and #g.backpackDeities==0)
print("Loadout PASS: purchases with full equipped slots, reserve/equip/swap/unequip, physical potion slots, active-only SPN effects, locks/no-turn/stale guards, callbacks/upgrades/save migration/reset")
