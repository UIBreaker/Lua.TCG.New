local L=require("src.loadout")
local Shop=require("src.shop")
local G=require("src.game_state")
local P=require("src.persistence")
local Bag=require("ui.backpack")
local function potion()return Shop.healingItem(nil,"healing_potion").consumable end
local function total(stacks)local n=0;for _,s in ipairs(stacks) do assert(s.count>=1 and s.count<=99);n=n+s.count end;return n end
for _,count in ipairs({1,98,99,100,198,199,299,1000}) do
 local g=G.new();for i=1,count do local p=potion();p.victoryRewardReceipt="receipt"..i;L.storeConsumable(g,p) end
 local stacks=L.consumableStacks(g)
 assert(#stacks==math.ceil(count/99) and total(stacks)==count and #g.backpackConsumables==count)
 assert(stacks[1].index==1 and stacks[#stacks].index==1+99*(#stacks-1))
end
local g=G.new();g.run=require("src.run_manager").newRun("red_deck")
for _=1,100 do L.storeConsumable(g,potion()) end
local stacks=L.consumableStacks(g);assert(stacks[1].count==99 and stacks[2].count==1)
assert(L.move(g,"consumable","reserve",stacks[2].index,2,false))
assert(#g.backpackConsumables==99 and #g.consumables==1 and L.equipped(g,"consumable",2))
assert(L.move(g,"consumable","equipped",2,nil,false));assert(total(L.consumableStacks(g))==100)
local gold=g.gold;assert(Shop.sellStoredItem(g,"reserve_consumable",L.consumableStacks(g)[1].index))
assert(#g.backpackConsumables==99 and g.gold>gold and L.consumableStacks(g)[1].count==99)
local loaded=assert(P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"shop"))))))
assert(total(L.consumableStacks(loaded))==99 and #loaded.backpackConsumables==99)
local variant=potion();variant.healAmt=50;L.storeConsumable(g,variant)
variant=potion();variant.permanentSpeed=true;L.storeConsumable(g,variant)
variant=potion();variant.params={heal=75};L.storeConsumable(g,variant)
assert(#L.consumableStacks(g)==4,"different effects must stay separate")
Bag.tab="consumable";Bag.views={}
local list=Bag.list(g);assert(#list==4 and list[1].count==99)
require("ui.backpack_qol").state(Bag).query="hoi mau"
for _,v in ipairs(Bag.list(g)) do assert(g.backpackConsumables[v.index]==v.item) end
Bag.views={};Bag.tab="spn"
local shared=potion();local old=G.new();old.backpackConsumables={shared,shared,shared}
assert(L.move(old,"consumable","reserve",1,1,false));assert(L.move(old,"consumable","reserve",1,2,false))
assert(L.equipped(old,"consumable",1)~=L.equipped(old,"consumable",2) and total(L.consumableStacks(old))==1)
old.handsRemaining=0;assert(not L.move(old,"consumable","reserve",1,3,true) and #old.backpackConsumables==1)
print("Consumable stacks PASS: 99 cap/overflow, variant isolation, individual equip/return/sale, stable filtered indices, old-save round-trip, shared legacy instances and no-turn guard")
return true
