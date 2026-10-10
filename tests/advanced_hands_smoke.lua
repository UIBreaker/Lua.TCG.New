local P=require("src.poker")
local A=require("src.advanced_hands")
local Shop=require("src.shop")
local G=require("src.game_state")
local D=require("src.deck")
local Combat=require("src.combat")
local fixtures={
 tesla_369={{3,6,9,2,4},{"hearts","hearts","hearts","clubs","spades"}},
 jackpot_777={{7,7,7,2,4}},fibonacci={{14,2,3,5,8}},prime={{2,3,5,7,11}},odd_star={{14,3,5,7,9}},even_frost={{2,4,6,8,10}},
 crimson_tide={{3,5,7,9,11},{"hearts","diamonds","hearts","diamonds","hearts"}},
 obsidian_tide={{3,5,7,9,11},{"spades","clubs","spades","clubs","spades"}},
 eclipse_duality={{2,4,9,4,2},{"hearts","diamonds","hearts","clubs","spades"}},
 four_kingdom_prism={{2,4,6,9,13}},four_kingdom_expedition={{14,2,4,6,13}},destiny_crown={{10,11,12,13,14}},
 continental_gate={{14,14,14,14,13}},answer_42={{4,6,9,10,13}},sealed_gate={{14,14,14,13,13}},seven_stars={{7,7,7,14,13}},five_ley_lines={{14,4,8,10,13}},
 endless_cycle={{2,3,4,5,6},{"hearts","clubs","spades","diamonds","hearts"}},
}
local suits={"hearts","clubs","spades","diamonds","hearts"}
local function cards(f)
 local c={};for i,r in ipairs(f[1]) do c[i]=D.newCard(r,(f[2] or suits)[i]);c[i].disableFactionPassives=true end;return c
end
assert(#A.ordered==18 and #P.HAND_TYPES_ORDERED==9 and #P.ALL_HANDS_ORDERED==27 and #P.PLANET_CARDS==29)
assert(#Shop.getPackContents("hand_styles_advanced")==18)
for id,f in pairs(fixtures) do
 local c=cards(f);local g=G.new();g.unlockedHands[id]=true
 local eval=P.evaluate(c,g.unlockedHands,g.handLevels)
 assert(eval.type.id==id,"Expected "..id..", got "..eval.type.id)
 assert(#eval.scoringCards==5 and #eval.unscoredCards==0)
 for i,v in ipairs(c) do assert(eval.scoringCards[i]==v) end
 assert(P.evaluate(c,{high_card=true}).type.id=="high_card")
 assert(#A.matches({c[1],c[2],c[3],c[4]})==0)
 local planet
 for _,v in ipairs(P.PLANET_CARDS) do if v.handId==id then planet=v end end
 assert(planet and planet.id=="planet_"..id)
 assert(Shop.choosePackCard({currentPackOpening={pack={packType="celestial"},cards={planet}}},1,g))
 assert(g.handLevels[id]==3)
 assert(P.evaluate(c,g.unlockedHands,g.handLevels).chips==A.byId[id].baseChips+2*A.byId[id].scaleChips)
 local monster=require("src.monster").create(1,false);monster.hp=10000;monster.maxHp=10000;monster.attackSpeed=20
 Combat.start(g,monster,8);g.playerHp=50;g.gold=0
 A.begin(g,eval);local _,_,hits=Combat.resolvePlayerAttack(g,1)
 assert(g.advancedHand.resolved and g.playerHp>=50 and g.playerArmor<=require("src.card_abilities").config.armorCap)
 if id=="tesla_369" then assert(#hits==3 and monster.hp==9981) end
 local gold,hp,armor=g.gold,g.playerHp,g.playerArmor
 assert(#A.resolve(g)==0 and g.gold==gold and g.playerHp==hp and g.playerArmor==armor)
end
local g=G.new();g.gold=100
local all={high_card=true};for _,h in ipairs(A.ordered) do all[h.id]=true end
assert(P.evaluate(cards(fixtures.seven_stars),all).type.id=="seven_stars")
local cycle=cards(fixtures.endless_cycle);cycle[4],cycle[5]=cycle[5],cycle[4]
assert(P.evaluate(cycle,{high_card=true,endless_cycle=true}).type.id=="high_card")
local dual=cards(fixtures.eclipse_duality);dual[2],dual[3]=dual[3],dual[2]
assert(P.evaluate(dual,{high_card=true,eclipse_duality=true}).type.id=="high_card")
local wild=cards(fixtures.tesla_369);wild[2].suit="clubs";wild[2].disableFactionPassives=false;wild[2].isWildSuit=true
assert(P.evaluate(wild,{tesla_369=true}).type.id=="tesla_369")
wild[2].disableFactionPassives=true
assert(P.evaluate(wild,{tesla_369=true,high_card=true}).type.id=="high_card")
assert(#A.matches({wild[1],wild[1],wild[1],wild[1],wild[1]})==0)
local opening=Shop.openPack(Shop.ADVANCED_HAND_CHEST,g)
assert(#opening.cards==3)
local seen={};for _,b in ipairs(opening.cards) do assert(not seen[b.handId]);seen[b.handId]=true;assert(not g.unlockedHands[b.handId]) end
local shop={items={{category="pack",packType="hand_styles_advanced",cost=12}}}
local lockedGold=g.gold
assert(not Shop.buyItem(shop,1,g))
assert(g.gold==lockedGold and #shop.items==1 and not shop.currentPackOpening)
for _,h in ipairs(P.HAND_TYPES_ORDERED) do g.unlockedHands[h.id]=true end
local before=g.gold;assert(Shop.buyItem(shop,1,g));assert(g.gold==before-12 and shop.currentPackOpening)
local selected=shop.currentPackOpening.cards[1]
assert(Shop.choosePackCard(shop,1,g));assert(g.unlockedHands[selected.handId] and g.handLevels[selected.handId]==1)
shop.currentPackOpening={pack=Shop.ADVANCED_HAND_CHEST,cards={selected}}
assert(Shop.choosePackCard(shop,1,g) and g.handLevels[selected.handId]==2)
for _,h in ipairs(A.ordered) do g.unlockedHands[h.id]=true end
g.run=require("src.run_manager").newRun(g.selectedFaction)
local Persistence=require("src.persistence")
local restored=assert(Persistence.restoreSnapshot(assert(Persistence.decode(Persistence.encode(Persistence.makeSnapshot(g,"shop"))))))
assert(restored.unlockedHands[selected.handId] and restored.handLevels[selected.handId]==2)
local f=G.new();f.monster=require("src.monster").create(2,false);f.playerHp=1
for _=1,12 do A.begin(f,{type=A.byId.fibonacci});A.resolve(f) end
assert(f.gold==36 and f.maxPlayerHp==103 and f.advancedCombat.speed==12 and f.playerArmor<=require("src.card_abilities").config.armorCap)
local unlockedOpening=Shop.openPack({packType="celestial"},G.new())
for _,v in ipairs(unlockedOpening.cards) do assert(not A.byId[v.handId]) end
local edge=G.new();edge.monster=require("src.monster").create(1,false);edge.playerHp=98
A.begin(edge,{type=A.byId.crimson_tide});A.resolve(edge)
assert(edge.playerHp==100 and edge.gold==11,"overflow is capped at five gold")
edge=G.new();edge.monster=require("src.monster").create(1,false);edge.playerHp=50
A.begin(edge,{type=A.byId.eclipse_duality,effectiveSuits={3,4,3,1,2}});A.resolve(edge)
assert(edge.playerHp==50 and edge.playerArmor==10 and edge.advancedCombat.speed==3 and edge.gold==6,"black eclipse branch")
edge=G.new();edge.monster=require("src.monster").create(1,false);edge.monster.hp=0
A.begin(edge,{type=A.byId.jackpot_777});A.resolve(edge)
assert(edge.gold==13 and edge.playerArmor==7,"jackpot killing bonus")
edge=G.new();edge.enemies={}
for i=1,3 do local m=require("src.monster").create(1,false);m.hp=100;m.maxHp=100;m.creatureArmor=100;edge.enemies[i]=m end
edge.monster=edge.enemies[2];for _,m in ipairs(edge.enemies) do m.group=edge.enemies end
A.begin(edge,{type=A.byId.tesla_369});local bolts=A.resolve(edge)
assert(#bolts==3 and edge.monster.hp==100 and edge.enemies[1].hp==88 and edge.enemies[3].hp==94,"Tesla distributes three true hits to living neighbors")
assert(edge.enemies[1].creatureArmor==94 and edge.enemies[3].creatureArmor==97)
local queued=G.new();queued.monster=require("src.monster").create(1,false)
A.begin(queued,{type=A.byId.endless_cycle});A.resolve(queued)
assert(queued.advancedCombat.nextSpeed==2)
A.begin(queued,{type=P.HAND_TYPES.HIGH_CARD});assert(queued.advancedCombat.currentSpeed==2 and queued.advancedCombat.nextSpeed==0)
A.begin(queued,{type=P.HAND_TYPES.HIGH_CARD});assert(queued.advancedCombat.currentSpeed==0)
local Feel=require("src.scoring_presentation")
local ui={BATTLE_CENTER_X=635,formatNumber=tostring,localizeText=function(s)return s end,getScoringCardX=function(i,n)return 635-n*55+(i-1)*110 end}
for id,fixture in pairs(fixtures) do
 local played=cards(fixture);local eval=P.evaluate(played,{[id]=true});local result=require("src.scoring").calculate(eval,{},{})
 for _,fps in ipairs({30,60,144}) do for _,fast in ipairs({false,true}) do
  local anim={playedCards=played,cardBounce={},cardHit={},deityBounce={},scoredCards={},floatingTexts={},bounceScale={chips=1,mult=1,score=1}}
  Feel.start(anim,result,ui,{},10000000,{targetAura=result.finalScore/5})
  assert(anim.sequence.attack.profile.id==id)
  local hits=0
  for _=1,fps*30 do
   if (anim.hitStop or 0)>0 then anim.hitStop=math.max(0,anim.hitStop-1/fps)
   else local step=Feel.update(anim,1/fps,fast);if step then hits=hits+1;Feel.damageApplied(anim,10000000-result.finalScore,result.finalScore) end end
   if Feel.isFinished(anim) then break end
  end
  assert(Feel.isFinished(anim) and hits==1 and anim.displayAura==result.finalScore,id.." presentation dispatch")
 end end
end
require("tests.balance_chests_smoke")
require("tests.hand_vfx_smoke")
print("Advanced hands: 18 matches, 18 planets, priority/order/wild, once-only effects/caps, real chest purchase and save round-trip passed")
return true
