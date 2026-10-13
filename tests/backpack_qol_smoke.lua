local Q=require("ui.backpack_qol")
local Bag=require("ui.backpack")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local D=require("src.deck")
local UI=require("src.ui")
assert(Q.normalize("TỐC ĐỘ · Băng VẢI")=="toc do · bang vai")
assert(Q.matches(E.ITEMS.basic_lace,"day toc") and not Q.matches(E.ITEMS.basic_lace,"day giap"))
local g={gold=100,backpackEquipment={},persistentDeck={D.newCard(3,"hearts"),D.newCard(5,"spades")}}
B.store(g,E.ITEMS.basic_plate,0);B.store(g,E.ITEMS.basic_lace,3);B.store(g,E.ITEMS.basic_bandage,2)
Bag.views={};Bag.tab="equipment";Bag.page=2;Bag.open=true;Bag.combat=false
local state=Q.state(Bag);state.query="day giay"
local list=Bag.list(g);assert(#list==1 and list[1].index==2 and list[1].item.id=="basic_lace")
state.query="";state.sort=2;list=Bag.list(g)
assert(#list==3 and g.backpackEquipment[1].id=="basic_plate")
for _,v in ipairs(list) do assert(B.entryId(g.backpackEquipment[v.index])==v.item.id) end
Q.switch(Bag,"cards");Q.switch(Bag,"equipment");assert(Bag.page==2 and Q.state(Bag).sort==2)
Bag.close();Bag.show();assert(Bag.page==2 and Q.state(Bag).sort==2)
Bag.searchFocus=true;assert(Bag.textinput("Giáp"));Q.erase(Bag);assert(Q.state(Bag).query=="Giá")
Bag.searchSelectAll=true;Bag.textinput("áo");assert(state.query=="áo")
Bag.searchSelectAll=true;Bag.textinput(string.rep("ắ",90));assert(require("utf8").len(state.query)==60)
state.query="";state.sort=1;Bag.page=2;Bag.selected=2
assert(E.attach(g.persistentDeck[1],E.ITEMS.basic_lace))
assert(Bag.beginEquip(g));list=Bag.list(g)
assert(#list==1 and list[1].index==2,"eligible filtering retains actual deck index")
assert(Bag.key("escape") and Bag.open and Bag.tab=="equipment" and Bag.page==2 and not Bag.pending)
Bag.selected=2;assert(Bag.beginEquip(g));assert(B.attach(g,Bag.pending,list[1].item))
assert(#g.backpackEquipment==2 and g.persistentDeck[2].equipments[1].id=="basic_lace")
Bag.cancelEquip();Bag.tab="craft";Bag.game=g;Bag.craftTier=0
state=Q.state(Bag);state.filter=2
list=Bag.recipeList();assert(#list>=1)
for _,v in ipairs(list) do assert(B.canCraft(g,v.recipe)) end
g.gold=0;assert(#Bag.recipeList()==0)
local ok,msg=B.canCraft(g,B.recipes[1]);assert(not ok and msg:find("vàng",1,true))
g.gold=100;g.backpackEquipment={}
ok,msg=B.canCraft(g,B.recipes[1]);assert(not ok and msg:find(E.ITEMS[B.recipes[1].ingredients[1]].name,1,true))
Bag.combat=true;Bag.tab="equipment";Bag.selected=1;assert(not Bag.beginEquip(g))
assert(Bag.key("5") and Bag.tab=="equipment","combat cannot open crafting with a shortcut")
Bag.close();Bag.views={};Bag.tab="spn";Bag.page=1;Bag.combat=false
print("Backpack QoL PASS: accent-insensitive multiword search, Unicode deletion, stable indices/sort, view memory, compatible targets, cancel/back, ready recipes and combat restrictions")
return true
