local Potions=require("src.potions")
local Shop=require("src.shop")
local Combat=require("src.combat")
local Deck=require("src.deck")
local Rng=require("src.rng")
local Game=require("src.game_state")
local Persistence=require("src.persistence")
local function fixture()
    local g=Game.new();g.run=require("src.run_manager").newRun("red_deck")
    local a={name="A",hp=1000,maxHp=1000,attack=30,attackSpeed=99,armor=40,creatureArmor=60,groupIndex=1}
    local b={name="B",hp=1000,maxHp=1000,attack=20,attackSpeed=1,armor=0,groupIndex=2}
    local c={name="C",hp=1000,maxHp=1000,attack=10,attackSpeed=1,armor=0,groupIndex=3}
    g.enemies={a,b,c};g.monster=a
    for _,m in ipairs(g.enemies) do m.group=g.enemies end
    g.hand={Deck.newCard(2,"spades"),Deck.newCard(4,"diamonds"),Deck.newCard(6,"clubs")}
    g.persistentDeck={};for _,card in ipairs(g.hand) do g.persistentDeck[#g.persistentDeck+1]=Deck.cloneCard(card) end
    g.gold=100;g.lastPlayerAttackSpeed=5
    return g,a,b,c
end
local function use(g,id,target)
    g.consumables={Shop.healingItem("upper",id).consumable}
    assert(Potions.use(g,1,target))
    assert(#g.consumables==0)
end
local g,a,b,c=fixture()
use(g,"cons_accuracy")
assert(Combat.rollPlayerAttack(g).hitChance==1 and g.potionCombat.accuracy)
local damage,_,_,roll=Combat.resolvePlayerAttack(g,100,{missed=true,hitChance=.05})
assert(not roll.missed and roll.hitChance==1 and damage==40 and not g.potionCombat.accuracy)
assert(Combat.rollPlayerAttack(g).hitChance<1,"Accuracy lasts for only one hand")

g,a,b,c=fixture();g.playerArmor=17;g.playerShield=17
use(g,"cons_evasion")
Combat.beginEnemyTurn(g,5)
assert(Combat.resolveMonsterAttack(g,"before",5).damage==0)
assert(Combat.resolveMonsterAttack(g,"after",5).damage==0)
assert(g.playerHp==100 and g.playerArmor==17 and g.playerShield==17 and g.potionCombat.evasion)
Combat.onPlayerTurnEnd(g)
assert(not g.potionCombat.evasion)
assert(Combat.resolveMonsterAttack(g,nil,0,a).damage==13,"Evasion must expire after the full group turn")

g,a,b,c=fixture();use(g,"cons_armor_break",a)
assert(a.armor==0 and a.creatureArmor==0 and a.hp==975 and b.hp==1000)
g.consumables={Shop.healingItem("upper","cons_armor_break").consumable}
assert(not Potions.use(g,1,b) and #g.consumables==1)
assert(not Potions.use(g,1,{hp=100,armor=10000}) and #g.consumables==1)
a.armor=4000000;a.creatureArmor=12000000;a.hp=6000000;a.maxHp=a.hp
assert(Potions.use(g,1,a) and a.armor==0 and a.creatureArmor==0 and a.hp==2000000,"Armor break has no armor cap")
a.armor=2;use(g,"cons_armor_break",a);assert(a.hp==1999999.5,"25 percent damage must not round away small armor")

g,a,b,c=fixture();use(g,"cons_damage");use(g,"cons_empower")
for _,card in ipairs(g.hand) do local d,m=Potions.cardBonus(g,card);assert(d==20 and m==5) end
for _,card in ipairs(g.persistentDeck) do assert(card.baseChips==Deck.getChipValue(card.rank) and not card.potionBonus) end
local new=Deck.newCard(8,"spades");assert(Potions.cardBonus(g,new)==0)
local info=require("src.poker").evaluate(g.hand,g.unlockedHands,g.handLevels)
local context={preview=true,gameState=g,hand=g.hand,unplayedCards=g.hand,monster=a}
local before=Rng.getState()
local score=require("src.scoring").calculate(info,{},context)
assert(Rng.getState()==before and g.potionCombat.damageCards and g.potionCombat.multCards)
local boostedCount=0
for _,step in ipairs(score.steps) do if step.type=="card_scored" then
    assert(step.addedChips>=Deck.getChipValue(step.card.rank)+20 and step.addedMult>=5)
    boostedCount=boostedCount+1
end end
assert(boostedCount>0)
Combat.onPlayerTurnEnd(g)
for _,card in ipairs(g.hand) do local d,m=Potions.cardBonus(g,card);assert(d==0 and m==0) end

g,a,b,c=fixture();g.playerArmor=20;g.playerShield=20;g.gold=0
use(g,"cons_gold_blood")
local hit=Combat.resolveMonsterAttack(g,nil,0,a)
assert(hit.damage==10 and g.playerHp==90 and g.gold==10,"Only HP damage pays gold, never absorbed armor")
g.consumables={Shop.healingItem("upper","cons_gold_blood").consumable}
assert(not Potions.use(g,1) and #g.consumables==1,"Gold blood does not stack")
Combat.onPlayerTurnEnd(g);assert(g.potionCombat.gold_blood)
g.playerHp=7;g.playerArmor=0;g.playerShield=0;a.attack=1000
Combat.resolveMonsterAttack(g,nil,0,a);assert(g.playerHp==0 and g.gold==17,"Lethal overkill cannot mint more gold than HP actually lost")
g,a,b,c=fixture();g.gold=0;use(g,"cons_gold_blood")
g.enemyPoison=3;require("src.enemy_abilities").handEnd(g)
assert(g.playerHp==97 and g.gold==3)
g.monster.isBoss=true;g.monster.bossState={pendingDamage=9,passiveUntil=0,handIndex=1}
require("src.card_abilities").resolveBossDamage(g)
assert(g.playerHp==88 and g.gold==12,"Boss damage uses the same actual HP-to-gold rule")
local gold=g.gold;g.playerHp=g.playerHp-5;assert(g.gold==gold,"Self-paid HP costs do not generate gold")

g,a,b,c=fixture()
for i=1,9 do g.deck[#g.deck+1]=Deck.newCard(i+2,"clubs") end
local count=#g.hand;local selected=g.hand[1];selected.selected=true;g.selectedIndices={1}
local prepared=0;g.consumables={Shop.healingItem("upper","cons_draw").consumable}
assert(Potions.use(g,1,nil,function(card,order) prepared=prepared+1;assert(order==prepared and not card.selected) end))
assert(#g.hand==count+5 and #g.deck==4 and prepared==5 and selected.selected and g.selectedIndices[1]==1)
assert(g.potionFeedback[#g.potionFeedback].value==5)
g.deck={Deck.newCard(2,"spades"),Deck.newCard(3,"spades")}
g.discardPile={Deck.newCard(4,"spades"),Deck.newCard(5,"spades"),Deck.newCard(6,"spades")}
count=#g.hand;use(g,"cons_draw")
assert(#g.hand==count+5 and #g.deck==0 and #g.discardPile==0,"Draw can exceed the hand cap and recycle a partial stock")
g.deck={Deck.newCard(9,"hearts")};count=#g.hand;use(g,"cons_draw");assert(#g.hand==count+1)
g.consumables={Shop.healingItem("upper","cons_draw").consumable}
assert(not Potions.use(g,1) and #g.consumables==1,"An empty stock never wastes the draw potion")

g,a,b,c=fixture();a.attackSpeed=100;a.combatBuffs={speed={value=20,turns=4}}
use(g,"cons_slow",a)
assert(require("src.enemy_abilities").speed(a)==60 and a.attackSpeed==100 and require("src.enemy_abilities").speed(b)==1)
g.consumables={Shop.healingItem("upper","cons_slow").consumable}
assert(not Potions.use(g,1,a) and #g.consumables==1)
assert(not Potions.use(g,1,b) and #g.consumables==1,"Cannot waste a slow potion on speed 1")
require("src.enemy_abilities").finishAction(g,a);assert(require("src.enemy_abilities").speed(a)==60)
require("src.enemy_abilities").finishAction(g,a);assert(require("src.enemy_abilities").speed(a)==120 and not a.combatBuffs.slow)
a.attackSpeed=8;a.combatBuffs={};g.lastPlayerAttackSpeed=5;use(g,"cons_slow",a)
Combat.beginEnemyTurn(g,5);assert(g.enemyActionPhases[a]=="after" and Combat.rollPlayerAttack(g).hitChance==1)

-- Stock and saved consumables remain canonical; combat-only effects never enter a save or a new battle.
g,a,b,c=fixture();g.gold=100000
local shop=Shop.new();g.shopMode="medicine";Shop.refresh(shop,g)
assert(#shop.items==15)
local heals=0
for _,item in ipairs(shop.items) do assert(item.id~="healing_potion_small");if item.category=="heal" then heals=heals+1 end end
assert(heals==2)
for _,def in ipairs(Potions.definitions) do
    for i,item in ipairs(shop.items) do if item.id==def.id then
        g.consumables={};g.backpackConsumables={};assert(Shop.buyItem(shop,i,g))
        local loaded=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop"))
        assert(loaded.backpackConsumables[1].id==def.id and loaded.backpackConsumables[1].desc==def.desc and #loaded.consumables==0 and loaded.shopMode=="medicine")
        break
    end end
end
for _,mode in ipairs({"small","large"}) do
    local seen={};g.shopMode=mode;Rng.seed(3489)
    for _=1,300 do Shop.refresh(shop,g);for _,item in ipairs(shop.items) do if Potions.byId[item.id] then seen[item.id]=true end end end
    for _,def in ipairs(Potions.definitions) do assert(seen[def.id],mode.." must sell "..def.id) end
end
use(g,"cons_accuracy");use(g,"cons_gold_blood")
local snapshot=Persistence.makeSnapshot(g,"shop")
assert(not snapshot.game.potionCombat and not snapshot.game.potionFeedback)
Combat.start(g,require("src.monster").create(1,false),1)
assert(not g.potionCombat.accuracy and not g.potionCombat.gold_blood)
Game.resetRun(g);assert(not g.potionCombat)
print("Potions PASS: 8 effects, immediate draw 5 above cap/recycle/empty stock, targeted slow/expiry/initiative, accuracy, evasion, armor break, hand buffs, HP-to-gold, 15 shop items, saves and reset")
