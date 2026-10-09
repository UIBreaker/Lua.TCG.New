local E=require("src.equipment")
local B=require("src.basic_equipment")
local T=require("src.tier_equipment")
local D=require("src.deck")
local Depth=require("src.chest_depth")
local S=require("src.scoring")
local Poker=require("src.poker")
local P=require("src.persistence")
local caps={
 {addChips=24,addMult=5,addArmor=7,healHp=3,speed=2,addGold=1,extraDamagePct=0,xMultBonus=0},
 {addChips=40,addMult=9,addArmor=11,healHp=5,speed=3,addGold=2,extraDamagePct=0,xMultBonus=0},
 {addChips=60,addMult=15,addArmor=14,healHp=7,speed=4,addGold=2,extraDamagePct=.20,xMultBonus=.30},
 {addChips=80,addMult=21,addArmor=22,healHp=10,speed=4,addGold=2,extraDamagePct=.30,xMultBonus=0},
 {addChips=110,addMult=24,addArmor=28,healHp=16,speed=6,addGold=2,extraDamagePct=.35,xMultBonus=0},
}
local counts,ids={0,0,0,0,0},{}
for _,d in ipairs(T.definitions) do assert(not ids[d.id]);ids[d.id]=true;counts[d.craftTier]=counts[d.craftTier]+1 end
assert(#T.definitions==25 and #B.recipes==60 and #E.POOL==54)
for _,n in ipairs(counts) do assert(n==5,"exactly five additions in each tier") end
local function fixture(item,n,hp,fast)
 local c=D.newCard(2,"hearts");c.evolutionLevel=5;c.depthInvestment=5;c.disableFactionPassives=true
 c.speedBonus=fast and 30 or 0;c.equipments={item};for j=1,3-(item.slotsNeeded or 1) do c.equipments[#c.equipments+1]={id="fixture"..j,slotsNeeded=1} end
 local cs={};local suits={"hearts","diamonds","clubs","spades","hearts"}
 for i=1,n do cs[i]=i==math.min(2,n) and c or D.newCard(i+2,suits[i]);cs[i].disableFactionPassives=true end
 local i=math.min(2,n);c.suit=suits[i]
 if cs[i-1] then cs[i-1].equipments={E.ITEMS.gem_fire} end
 local values={};for key,v in pairs({charge=3,drops=3,quiet=3,heldHits=2}) do values[tostring(c.id)..":"..key]=v end
 local g={playerHp=hp,maxPlayerHp=100,playerArmor=30,gold=96,persistentDeck={c},depthCombat={values=values,damage=30,blocked=4,lastType="pair",lastSize=3}}
 local ctx={gameState=g,monster={attackSpeed=fast and 1 or 999},hand={D.newCard(3,"clubs"),D.newCard(5,"spades"),D.newCard(7,"hearts"),D.newCard(9,"diamonds"),D.newCard(11,"clubs"),D.newCard(13,"spades")},preview=true,depthHandType="straight"}
 return g,c,cs,i,ctx
end
local report={"id\tname\ttier\tcraft_gold\tshop_gold\tchips\tmult\tarmor\theal\tspeed\tgold\tdamage_pct\taura_bonus\tability"}
for _,r in ipairs(B.recipes) do
 local item=E.ITEMS[r.id];assert(item.craftTier==r.tier and item.cost==math.ceil(r.craftCost*1.5))
 assert(item.rarity==({"common","uncommon","rare","epic","legendary"})[r.tier])
 assert(not item.desc:find("{",1,true))
 local peak={speed=item.attackSpeed or 0}
 for n=1,5 do for _,hp in ipairs({25,50,85}) do for _,fast in ipairs({false,true}) do for _,mode in ipairs({"mixed","pair","ace","evolved","front","bankrupt"}) do
  local g,c,cs,i,ctx=fixture(item,n,hp,fast)
  if mode=="front" then cs[1],cs[i]=cs[i],cs[1];i=1;g.gold=6
  elseif mode=="bankrupt" then g.gold=0;ctx.depthHandType="pair"
  elseif mode=="pair" then for _,v in ipairs(cs) do v.rank=2;v.suit="hearts" end
  elseif mode=="ace" then c.rank=14
  elseif mode=="evolved" then c.rank=12;cs[1].rank=10;cs[1].suit="diamonds" end
  D.getCardAttackSpeed(c)
  local before=P.encode({g=g,c=c});Depth.begin(ctx)
  local result=item.onCardScore and item.onCardScore(c,cs,i,ctx)
  if item.onHandEvaluate then
   result={};for _,buff in pairs(item.onHandEvaluate(c,cs,i,ctx) or {}) do for k,v in pairs(buff) do if type(v)=="number" then result[k]=(result[k] or 0)+v end end end
  end
  assert(before==P.encode({g=g,c=c}),r.id.." preview changed saved resources")
  for k,v in pairs(result or {}) do if type(v)=="number" then peak[k]=math.max(peak[k] or 0,v) end end
 end end end end
 local shines=false
 for k,limit in pairs(caps[r.tier]) do
  assert((peak[k] or 0)<=limit+.00001,r.id.." tier "..r.tier.." exceeds "..k..": "..tostring(peak[k]))
  if (peak[k] or 0)>0 then shines=true end
 end
 assert(shines,r.id.." has no useful scenario")
 if ids[r.id] then
  for param,key in pairs({chips="addChips",mult="addMult",armor="addArmor",heal="healHp",speed="speed",gold="addGold"}) do
   local n=(item.params or {})[param];if n then assert((peak[key] or 0)>=n,r.id.." never reaches promised "..param) end
  end
 end
 if r.id=="itm_capacitor" then assert(peak.addChips==54 and peak.addMult==9,"three charges must match +18 ST / +3 Mult tooltip") end
 if r.id=="itm_bell" then assert(peak.addMult==20,"four quiet beats must match +5 Mult each") end
 if r.id=="itm_bloodvial" then assert(peak.addMult==21,"three drops must match +7 Mult each") end
 report[#report+1]=table.concat({r.id,item.name,r.tier,r.craftCost,item.cost,peak.addChips or 0,peak.addMult or 0,peak.addArmor or 0,peak.healHp or 0,peak.speed or 0,peak.addGold or 0,peak.extraDamagePct or 0,peak.xMultBonus or 0,item.desc},"\t")
end
-- Resource converters consume only once, agree with previews and cannot overdraft.
for _,id in ipairs({"itm_exchangehorn","itm_escrowseal","itm_sovereignscale"}) do
 local item=E.ITEMS[id];local g,c,cs,i,ctx=fixture(item,1,25,true);g.gold=item.params.goldCost
 c.equipments={item};local second=D.newCard(2,"clubs");second.equipments={item};second.disableFactionPassives=true
 local h=Poker.evaluate({c,second},{pair=true,high_card=true})
 D.getCardAttackSpeed(c);D.getCardAttackSpeed(second)
 local before=P.encode(g);local pre=S.calculate(h,{},ctx);assert(P.encode(g)==before)
 ctx.preview=false;local live=S.calculate(h,{},ctx)
 assert(g.gold==0 and live.bonusChips==pre.bonusChips and live.bonusMult==pre.bonusMult and live.addArmor==pre.addArmor and live.healHp==pre.healHp,id)
 local noMoney=S.calculate(h,{},ctx);assert(g.gold==0)
 if id~="itm_sovereignscale" then assert(noMoney.addArmor==0 and noMoney.healHp==0) end
 assert(not item.onCardScore(c,{c},0,{}))
end
local cards={};for i=1,5 do cards[i]=D.newCard(14,"diamonds");cards[i].disableFactionPassives=false;cards[i].equipments={E.ITEMS.lucky_coin,E.ITEMS.basic_stamp,E.ITEMS.itm_tollscale} end
local h=Poker.evaluate(cards,{four_of_a_kind=true,high_card=true});local income=S.calculate(h,{}, {gameState={gold=0}})
assert(income.bonusGoldAwarded<=6,"equipment cap must hold after faction amplification")
local owner=D.newCard(4,"clubs");local g={persistentDeck={owner},backpackEquipment={},gold=1000}
for _,item in ipairs(T.definitions) do B.store(g,item,item.cost) end
assert(B.attach(g,1,owner));local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(restored.persistentDeck[1].equipments[1].id==T.definitions[1].id)
-- Build every new item through real recursive transactions, paying every ingredient/fee.
for _,item in ipairs(T.definitions) do
 local card=D.newCard(4,"clubs");local run={gold=10000,persistentDeck={card},backpackEquipment={}}
 local function make(id)
  local d=E.ITEMS[id]
  if d.basic then run.gold=run.gold-d.cost;B.store(run,d,d.cost);return end
  local r=B.byResult[id];for _,ingredient in ipairs(r.ingredients) do make(ingredient) end
  assert(B.craft(run,r),id)
 end
 make(item.id);assert(#run.backpackEquipment==1 and B.count(run,item.id)==1)
 assert(run.gold==10000-item.craftCost and B.investment(run.backpackEquipment[1])==item.craftCost)
 assert(B.attach(run,1,card));assert(E.getUsedSlots(card)==(item.craftTier==5 and 2 or 1))
 if item.craftTier==5 then
  assert(item.legacyCost==E.ITEMS.void_catalyst.legacyCost,"same tier should not inflate soul conversion")
  assert(E.attach(card,E.ITEMS.basic_plate));assert(E.attach(card,E.ITEMS.basic_lace));assert(not E.canAttach(card,E.ITEMS.basic_chain));table.remove(card.equipments,3);table.remove(card.equipments,2)
 end
 assert(B.detach(run,card,1));assert(B.investment(run.backpackEquipment[1])==item.craftCost)
end
local f=assert(io.open("docs/equipment_tier_balance.tsv","wb"));f:write(table.concat(report,"\n").."\n");f:close()
print("Equipment tiers PASS: 25 unique additions / 5 per tier; 60 recipes; 10800 condition/resource/preview checks; tier ceilings, gold cap, conversions, sockets and persistence")
