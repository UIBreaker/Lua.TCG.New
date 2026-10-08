local B=require("src.basic_equipment")
local E=require("src.equipment")
local D=require("src.deck")
local Shop=require("src.shop")
local c=D.newCard(2,"clubs")
local g={gold=100,backpackEquipment={"basic_bandage","basic_plate","basic_lace"},persistentDeck={c}}
assert(#B.basic==12 and #B.recipes==6)
assert(B.craft(g,B.recipes[1]));assert(g.gold==98 and B.count(g,"crafted_guard")==1 and B.count(g,"basic_bandage")==0)
local before=#g.backpackEquipment;assert(not B.craft(g,B.recipes[1]));assert(#g.backpackEquipment==before and g.gold==98)
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
  if item.section=="discount" then sales=sales+1;assert(item.cost<item.originalCost and math.floor(item.equipment.cost/3)<=item.cost) end
 end
 assert(basics==4 and sales==2)
end
local f=assert(io.open("docs/basic_equipment_catalog.tsv","wb"))
for _,d in ipairs(B.definitions) do f:write(table.concat({d.id,d.name,d.desc,d.concept,tostring(d.cost)},"\t"),"\n") end
f:close()
print("Backpack PASS: 12 basics, 6 recipes, atomic crafting, ownership, attach/detach speed, economy cap, discounted purchase and duplicate-click protection")
return true
