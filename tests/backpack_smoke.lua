local B=require("src.basic_equipment")
local E=require("src.equipment")
local D=require("src.deck")
local Shop=require("src.shop")
local c=D.newCard(2,"clubs")
local g={gold=100,backpackEquipment={"basic_bandage","basic_plate","basic_lace"},persistentDeck={c}}
assert(#B.basic==12 and #B.recipes==35)
assert(B.craft(g,B.recipes[1]));assert(g.gold==96 and B.count(g,"crafted_guard")==1 and B.count(g,"basic_bandage")==0)
local before=#g.backpackEquipment;assert(not B.craft(g,B.recipes[1]));assert(#g.backpackEquipment==before and g.gold==96)
local base=D.getCardAttackSpeed(c);assert(B.attach(g,1,c));assert(D.getCardAttackSpeed(c)==base+1)
assert(not B.attach(g,1,D.newCard(3,"clubs")));assert(B.detach(g,c,1));assert(D.getCardAttackSpeed(c)==base)
local context={};local total=0
for i=1,10 do total=total+E.ITEMS.basic_stamp.onCardScore(c,{c},1,context).addGold end
assert(total==6);assert(not E.ITEMS.basic_stamp.onCardScore(c,{c},0,{}))
local Poker=require("src.poker");local Score=require("src.scoring")
local resourceCard=D.newCard(2,"clubs");resourceCard.equipments={E.ITEMS.crafted_guard}
local info=Poker.evaluate({resourceCard},{high_card=true})
local preview=Score.calculate(info,{}, {preview=true});local actual=Score.calculate(info,{}, {})
assert(preview.healHp==2 and actual.healHp==2 and preview.addArmor==4 and actual.addArmor==4)
local paid={}
for i=1,4 do paid[i]=D.newCard(4,({"hearts","diamonds","clubs","spades"})[i]);paid[i].equipments={E.ITEMS.basic_stamp} end
local hand=Poker.evaluate(paid,{four_of_a_kind=true,high_card=true})
local repeatedContext={preview=true}
local income=Score.calculate(hand,{},repeatedContext);local again=Score.calculate(hand,{},repeatedContext)
assert(income.bonusGoldAwarded==6 and again.bonusGoldAwarded==6,"economy cap resets on every calculation")
local stock={items={{category="equipment",backpack=true,equipment=E.ITEMS.basic_bandage,cost=1}}}
local coins=g.gold;assert(Shop.buyItem(stock,1,g));assert(g.gold==coins-1 and B.count(g,"basic_bandage")==1 and #stock.items==0)
assert(not Shop.buyItem(stock,1,g));assert(g.gold==coins-1)
local G=require("src.game_state");local P=require("src.persistence")
local savedGame=G.new();savedGame.backpackEquipment={"basic_lace","crafted_guard"};savedGame.persistentDeck={c}
c.equipments={E.ITEMS.crafted_runner}
local restored=assert(P.restoreSnapshot(P.makeSnapshot(savedGame,"shop")))
assert(restored.backpackEquipment[2]=="crafted_guard" and restored.persistentDeck[1].equipments[1].onCardScore)
assert(D.getCardAttackSpeed(restored.persistentDeck[1])==D.getAttackSpeed(c.rank)+2)
G.resetRun(restored);assert(#restored.backpackEquipment==0)
local normal=Shop.new();local fresh=G.new();fresh.gold=100
for _=1,25 do
 Shop.refresh(normal,fresh);local basics,sales,seen=0,0,{}
 for _,item in ipairs(normal.items) do
  if item.backpack then assert(not seen[item.equipment.id]);seen[item.equipment.id]=true end
  if item.section=="basic" then basics=basics+1 end
  if item.section=="discount" then sales=sales+1;assert(item.cost<item.originalCost and not item.equipment.soulOnly) end
 end
 assert(basics==4 and sales==2)
end
-- Every finished ordinary item is reachable exclusively from basic materials.
local covered=0
local function make(game,id)
 local d=E.ITEMS[id];assert(d and not d.soulOnly)
 if d.basic then B.store(game,d,d.cost);return end
 local r=assert(B.byResult[id]);for _,part in ipairs(r.ingredients) do make(game,part) end
 assert(B.craft(game,r));assert(d.cost==math.ceil(r.craftCost*1.5) and d.cost>d.legacyCost)
end
for id,item in pairs(E.ITEMS) do
 if item.soulOnly then assert(not B.byResult[id])
 elseif not item.basic then
  local build={gold=10000,backpackEquipment={}};make(build,id)
  assert(#build.backpackEquipment==1 and B.count(build,id)==1)
  assert(B.investment(build.backpackEquipment[1])==item.craftCost);covered=covered+1
 end
end
assert(covered==35)
-- Repeated ingredients require actual quantities; failures spend nothing.
local repeated={gold=100,backpackEquipment={"basic_plate","basic_spur"}}
assert(not B.craft(repeated,B.byResult.gem_blast));assert(repeated.gold==100 and #repeated.backpackEquipment==2)
repeated.backpackEquipment[3]="basic_spur";assert(B.craft(repeated,B.byResult.gem_blast))
local noFee={gold=0,backpackEquipment={"basic_bandage","basic_plate"}};assert(not B.craft(noFee,B.recipes[1]));assert(#noFee.backpackEquipment==2)
-- A free offer is genuinely free, one-use, and keeps its zero resale basis through save/attach/detach.
local free=Shop.discountedEquipment(E.ITEMS.void_catalyst,1,0)
assert(free.cost==0 and Shop.discountedEquipment(E.ITEMS.basic_plate,1,.079).cost==0)
assert(Shop.discountedEquipment(E.ITEMS.basic_plate,1,.08).cost>0)
local zero=G.new();zero.gold=0;zero.persistentDeck={D.newCard(3,"hearts")}
local offers={items={free}};assert(Shop.buyItem(offers,1,zero));assert(zero.gold==0 and B.resale(zero.backpackEquipment[1])==0)
assert(not Shop.buyItem(offers,1,zero));zero=assert(P.restoreSnapshot(P.makeSnapshot(zero,"shop")));assert(B.count(zero,"void_catalyst")==1 and B.resale(zero.backpackEquipment[1])==0);assert(B.attach(zero,1,zero.persistentDeck[1]))
zero=assert(P.restoreSnapshot(P.makeSnapshot(zero,"shop")));assert(B.detach(zero,zero.persistentDeck[1],1));assert(B.resale(zero.backpackEquipment[1])==0)
local cheap={gold=4,backpackEquipment={}};B.store(cheap,E.ITEMS.basic_plate,0);B.store(cheap,E.ITEMS.basic_bandage,0)
assert(B.craft(cheap,B.recipes[1]));assert(B.investment(cheap.backpackEquipment[1])==4 and B.resale(cheap.backpackEquipment[1])==1)
local Display=require("ui.shop_display")
local _,_,sw,sh=Display.position({section="upper",category="deity"},1,0)
for _,kind in ipairs({"basic","discount"}) do local _,_,w,h=Display.position({section=kind,bay=1},1,0);assert(w==sw and h==sh) end
local Bag=require("ui.backpack");Bag.open=true;Bag.tab="craft"
local inspected;Bag.mouse(require("src.ui"),fresh,{{id="bag_recipe_35",x=0,y=0,w=100,h=100}},50,50,2,{inspect=function(item) inspected=item end})
assert(inspected==E.ITEMS.void_catalyst);Bag.close()
local f=assert(io.open("docs/basic_equipment_catalog.tsv","wb"))
for _,d in ipairs(B.definitions) do f:write(table.concat({d.id,d.name,d.desc,d.concept,tostring(d.cost)},"\t"),"\n") end
f:close()
local recipeDoc=assert(io.open("docs/equipment_recipe_catalog.tsv","wb"))
recipeDoc:write("id\tname\ttier\tingredients\tfee\tcraft_cost\tshop_cost\treason\n")
for _,r in ipairs(B.recipes) do local names={};for _,id in ipairs(r.ingredients) do names[#names+1]=E.ITEMS[id].name end;recipeDoc:write(table.concat({r.id,E.ITEMS[r.id].name,r.tier,table.concat(names," + "),r.fee,r.craftCost,E.ITEMS[r.id].cost,r.reason},"\t"),"\n") end
recipeDoc:close()
print("Backpack PASS: 12 basics, all 35 ordinary recipes, recursive reachability/prices, atomic quantity/fee checks, free purchase/save/attach/detach resale, cap, purchases and equal card dimensions")
return true
