local P=require("src.persistence")
local G=require("src.game_state")
local Run=require("src.run_manager")
local D=require("src.deck")
local E=require("src.equipment")
local function fixture(ante,index)
 local g=G.new();g.gold=22;g.souls=7;g.playerHp=64
 g.persistentDeck={D.newCard(7,"hearts")};g.backpackEquipment={{id="basic_plate",investment=2}}
 g.run=Run.newRun(g.selectedFaction);g.run.ante=ante;g.run.currentBlindIndex=index
 g.run.blinds=Run.generateAnteBlinds(ante,g.selectedFaction)
 for i,b in ipairs(g.run.blinds) do b.status=i<=index and "completed" or "upcoming" end
 g.run.stats.blindsWon=(ante-1)*3+index
 return g
end
for _,ante in ipairs({1,3,19,20,21,40,41}) do
 for index=1,3 do
  local g=fixture(ante,index);g.run.endless=ante>20
  local shop=P.makeSnapshot(g,"shop");assert(shop.activeState=="shop")
  local restored,state=P.restoreSnapshot(assert(P.decode(P.encode(shop))))
  assert(state=="shop" and restored.gold==22 and restored.souls==7 and restored.playerHp==64)
  assert(restored.run.currentBlindIndex==index and restored.currentBlind.status=="completed")
  assert(#restored.persistentDeck==1 and restored.backpackEquipment[1].investment==2)
  local won=restored.run.stats.blindsWon
  shop.activeState="BLIND_SELECT" -- Exact broken format produced before this fix.
  restored,state=P.restoreSnapshot(shop)
  assert(state=="shop" and restored.run.stats.blindsWon==won and restored.run.ante==ante)
  local twice,twiceState=P.restoreSnapshot(P.makeSnapshot(restored,state))
  assert(twiceState=="shop" and twice.gold==22 and twice.run.shopsVisitedInAnte==0)
  local continues,reason=Run.advanceBlind(twice.run,twice)
  if index<3 then
   assert(continues and twice.run.currentBlindIndex==index+1 and Run.getCurrentBlind(twice.run).status=="current")
  elseif ante==20 then assert(not continues and reason=="victory")
  else assert(continues and twice.run.ante==ante+1 and twice.run.currentBlindIndex==1) end
  assert(twice.run.stats.blindsWon==won and twice.gold==22)
 end
end
local broken=P.makeSnapshot(fixture(3,2),"BLIND_SELECT")
broken.game.pendingVictoryReward={total=9}
assert(select(2,P.restoreSnapshot(broken))=="CASH_OUT")
broken.game.pendingVictoryReward=nil;broken.game.pendingRewardEquipment={id="gem_fire"}
local gear,state=P.restoreSnapshot(broken);assert(state=="socketing" and gear.pendingRewardEquipment.onCardScore)
local ready=G.new();ready.run=Run.newRun();ready.persistentDeck={D.newCard(2,"clubs")}
local snap=P.makeSnapshot(ready,"BLIND_SELECT");snap.game.run.blinds[1].status="upcoming"
local resumed,resumeState=P.restoreSnapshot(snap);assert(resumeState=="BLIND_SELECT" and resumed.currentBlind.status=="current")
-- Read the player's existing save without writing/deleting it.
local existing,existingState=P.loadRun()
if existing then
 local blind=Run.getCurrentBlind(existing.run)
 assert(existingState~="BLIND_SELECT" or blind.status=="current")
 print("Existing save recovered: ante "..existing.run.ante..", fight "..existing.run.currentBlindIndex..", state "..existingState..", gold "..existing.gold)
end
require("tests.expedition_smoke")
require("tests.reward_ceremony_smoke")
print("Run resume PASS: old/new shop saves, 21 progress boundaries, resources/ownership, no double rewards, reward/socket recovery, ready fight, expedition and reward regressions")
return true
