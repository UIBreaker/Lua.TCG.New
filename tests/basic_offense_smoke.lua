local B=require("src.basic_equipment")
local E=require("src.equipment")
local D=require("src.deck")
local S=require("src.scoring")
local Poker=require("src.poker")
local G=require("src.game_state")
local P=require("src.persistence")
local Shop=require("src.shop")
local paths=require("config.continental_asset_paths")
local c=D.newCard(2,"clubs");c.disableFactionPassives=true
local hand=Poker.evaluate({c},{high_card=true})
local baseline=S.calculate(hand,{},{});local speed=D.getCardAttackSpeed(c)
local g=G.new();g.gold=20;g.persistentDeck={c}
for _,row in ipairs({{"basic_steel_tip",3},{"basic_amber",4}}) do
 local d=assert(E.ITEMS[row[1]])
 assert(d.basic and not d.soulOnly and d.slotsNeeded==1 and d.cost==row[2])
 local art=assert(io.open(paths[d.id],"rb"),"new component needs its own art");art:close()
 assert(not d.onCardScore(c,{c},0,{}),"held cards must not trigger components")
 assert(Shop.buyItem({items={{category="equipment",equipment=d,cost=d.cost,backpack=true}}},1,g))
 assert(B.attach(g,1,c))
 assert(not E.canAttach(c,d),"ordinary duplicate rules still apply")
end
assert(g.gold==13 and D.getCardAttackSpeed(c)==speed)
for _,preview in ipairs({false,true}) do
 local result=S.calculate(hand,{}, {preview=preview})
 assert(result.totalChips==baseline.totalChips+5 and result.totalMult==baseline.totalMult+1)
end
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
local owner=loaded.persistentDeck[1]
assert(owner.equipments[1].id=="basic_steel_tip" and owner.equipments[2].id=="basic_amber")
assert(B.detach(loaded,owner,2) and B.detach(loaded,owner,1))
assert(B.count(loaded,"basic_steel_tip")==1 and B.count(loaded,"basic_amber")==1)
assert(S.calculate(Poker.evaluate({owner},{high_card=true}),{},{}).totalChips==baseline.totalChips)
-- Both shop layouts must draw from the entire catalog, without duplicate basics.
for _,mode in ipairs({"normal","equipment"}) do
 local shop=Shop.new();local seen={};local fresh=G.new();fresh.shopMode=mode
 for _=1,80 do
  Shop.refresh(shop,fresh);local unique={};local n=0
  for _,offer in ipairs(shop.items) do
   if offer.equipment and offer.equipment.basic and (mode=="equipment" or offer.section=="basic") then
    local id=offer.equipment.id;assert(not unique[id]);unique[id]=true;seen[id]=true;n=n+1
   end
  end
  assert(n==4)
 end
 assert(seen.basic_steel_tip and seen.basic_amber,"offensive basics must actually be sold in "..mode)
end
print("Basic offense PASS: purchase, +5 damage / +1 Mult scoring and preview, held guard, sockets, save/detach, both shops and unique stock")
return true
