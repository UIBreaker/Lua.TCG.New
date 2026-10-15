local Alchemy=require("src.spn_alchemy")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Potions=require("src.potions")
local Shop=require("src.shop")
local I=require("src.inventory")
local Combat=require("src.combat")
local P=require("src.persistence")
local Rng=require("src.rng")
local function game(ids)
    local g=Game.new();g.deities={};g.playerHp=50;g.maxPlayerHp=100;g.gold=0;g.playerArmor=0;g.playerShield=0
    g.monster={hp=10000,maxHp=10000,attack=10,attackSpeed=20,armor=100};g.enemies={g.monster}
    g.persistentDeck={Deck.newCard(2,"spades"),Deck.newCard(4,"hearts")};g.masterDeck=g.persistentDeck
    g.hand={};for _,c in ipairs(g.persistentDeck) do g.hand[#g.hand+1]=Deck.cloneCard(c);g.hand[#g.hand].disableFactionPassives=true end
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    return g
end
local amp="spirit_potion_resonance";local eternal="spirit_potion_eternity"
local function use(g,id)
    g.consumables={Shop.healingItem("upper",id).consumable}
    assert(Potions.use(g,1));assert(#g.consumables==0)
end
local function roll(value,fn)
    local old=Rng.random;local calls=0
    Rng.random=function() calls=calls+1;return value end
    local ok,err=pcall(fn);Rng.random=old;assert(ok,err);return calls
end
local g=game({amp})
assert(Alchemy.effects(g)==2);D.evolve(g.deities[1]);assert(Alchemy.effects(g)==2.5);D.evolve(g.deities[1]);assert(Alchemy.effects(g)==3)
assert(D.getDescription(g.deities[1]):find("×3",1,true))
g=game({amp});g.consumables={Shop.healingItem("upper","healing_potion").consumable}
assert(I.useUtility(g,1) and g.playerHp==100)
g.playerHp=99;g.consumables={Shop.healingItem("upper","healing_potion_large").consumable};assert(I.useUtility(g,1) and g.playerHp==100)
g.consumables={Shop.healingItem("upper","armor_potion_large").consumable};assert(I.useUtility(g,1) and g.playerArmor==40)
g=game({amp});use(g,"cons_damage");use(g,"cons_empower")
for _,c in ipairs(g.hand) do local damage,mult=Potions.cardBonus(g,c);assert(damage==40 and mult==10 and (c.potionPermanentMult or 0)==0) end
Potions.endTurn(g);assert(Potions.cardBonus(g,g.hand[1])==0)
g=game({amp});use(g,"cons_armor_break");assert(g.monster.armor==0 and g.monster.hp==9950)
g=game({amp});use(g,"cons_gold_blood");Potions.payBlood(g,60);assert(g.gold==20)
g=game({amp});for i=1,20 do g.deck[#g.deck+1]=Deck.newCard(3,"spades") end
use(g,"cons_draw");assert(#g.hand==12 and #g.deck==10)
g=game({amp});use(g,"cons_slow");assert(require("src.enemy_abilities").speed(g.monster)==1 and g.monster.combatBuffs.slow.turns==2)
g=game({amp});use(g,"cons_accuracy");assert(g.potionCombat.accuracyTurns==2)
Combat.resolvePlayerAttack(g,1);assert(g.potionCombat.accuracy);Potions.endTurn(g)
assert(g.potionCombat.accuracyTurns==1);Combat.resolvePlayerAttack(g,1);assert(not g.potionCombat.accuracy)
g=game({amp});use(g,"cons_evasion");Combat.resolveMonsterAttack(g,nil,0);assert(g.playerHp==50)
Potions.endTurn(g);assert(g.potionCombat.evasion);Potions.endTurn(g);assert(not g.potionCombat.evasion)
g=game({amp});local speed=Shop.healingItem("upper","cons_speed_small").consumable
assert(Potions.applySpeed(g,speed,g.hand[1]) and g.hand[1].temporarySpeedBonus==6 and g.persistentDeck[1].speedBonus==0)
assert(Shop.getConsumableDescription(speed,g):find("+6",1,true))
assert(Alchemy.multiplier(g,require("src.run_manager").createSpeedSingleCard())==1,"permanent speed cards and non-potions do not amplify")

-- Shop offers store potion stats on the contained consumable, including blood-shop boosts.
local Description=require("src.card_description")
for _,boosted in ipairs({false,true}) do
    for _,def in ipairs(Shop.POTIONS) do
        local offer=Shop.healingItem("upper",def.id)
        if boosted then offer=require("src.blood_shop").offer(offer) end
        for _,context in ipairs({game(),game({amp})}) do
            local title,body=Description.resolve(offer,context)
            local expectedTitle,expectedBody=Description.resolve(offer.consumable,context)
            assert(title==expectedTitle and body==expectedBody and body~="",def.id..": shop tooltip must describe the actual potion")
        end
        local title,body=Description.resolve(offer)
        local expectedTitle,expectedBody=Description.resolve(offer.consumable)
        assert(title==expectedTitle and body==expectedBody,def.id..": catalog tooltip must describe the actual potion")
    end
end
assert(select(2,Description.resolve(Shop.healingItem("upper","healing_potion"),g)):find("Hồi 50 HP",1,true))
assert(select(2,Description.resolve(Shop.healingItem("upper","armor_potion_small"),g)):find("+16 Giáp",1,true))
assert(select(2,Description.resolve(Shop.healingItem("upper","cons_speed_small"),g)):find("+6",1,true))

g=game({eternal});local _,chance=Alchemy.effects(g);assert(math.abs(chance-10)<1e-8)
D.evolve(g.deities[1]);local _,chance=Alchemy.effects(g);assert(math.abs(chance-15)<1e-8)
assert(D.getDescription(g.deities[1]):find("15%",1,true))
assert(roll(.15,function() assert(not Alchemy.rollPermanent(g)) end)==1)
assert(roll(.149,function() assert(Alchemy.rollPermanent(g)) end)==1)
g=game({amp,eternal});local c=g.hand[1];g.discardPile={c};g.deck={Deck.cloneCard(c)}
assert(roll(.099,function() use(g,"cons_damage") end)==1,"one roll for the whole hand")
assert(c.baseChips==42 and c.bonusBaseChips==40 and g.persistentDeck[1].baseChips==42 and g.deck[1].baseChips==42)
assert(Potions.cardBonus(g,c)==0,"permanent damage has no duplicate temporary bonus")
assert(roll(.099,function() use(g,"cons_empower") end)==1)
local _,mult=Potions.cardBonus(g,c);assert(mult==10 and c.potionPermanentMult==10)
Potions.endTurn(g);local _,mult=Potions.cardBonus(g,c);assert(mult==10)
assert(roll(.099,function() assert(Potions.applySpeed(g,speed,c)) end)==1)
assert(c.speedBonus==6 and (c.temporarySpeedBonus or 0)==0 and g.persistentDeck[1].speedBonus==6)
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(loaded.persistentDeck[1].baseChips==42 and loaded.persistentDeck[1].potionPermanentMult==10 and loaded.persistentDeck[1].speedBonus==6)
Combat.start(loaded,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},1)
for _,card in ipairs(loaded.hand) do local _,m=Potions.cardBonus(loaded,card);assert(m==10 and card.baseChips==Deck.getChipValue(card.rank)+40) end
local Poker=require("src.poker");local S=require("src.scoring")
local info=assert(Poker.evaluate(g.hand));local before=P.encode(P.makeSnapshot(g,"shop"));local rng=Rng.getState()
S.calculate(info,g.deities,{preview=true,gameState=g,monster=g.monster})
assert(before==P.encode(P.makeSnapshot(g,"shop")) and rng==Rng.getState(),"preview never rolls or grants permanent stats")

g=game({amp,eternal});assert(roll(.1,function() use(g,"cons_damage") end)==1)
assert((g.hand[1].potionPermanentDamage or 0)==0 and Potions.cardBonus(g,g.hand[1])==40,"failure stays temporary at exact ten-percent boundary")
g=game({eternal});g.hand={};g.consumables={Shop.healingItem("upper","cons_damage").consumable}
assert(roll(0,function() assert(not Potions.use(g,1) and #g.consumables==1) end)==0)
assert(roll(0,function() assert(not Potions.applySpeed(g,speed,Deck.newCard(3,"hearts"))) end)==0)
for _,id in ipairs({"cons_accuracy","cons_evasion","cons_gold_blood","cons_slow","cons_armor_break"}) do
    g=game({eternal});assert(roll(0,function() use(g,id) end)==0,"non-stat potions never roll permanence")
end
g=game({eternal});g.deities[1].evolutionLevel=1000
assert(D.scaleEffect(g.deities[1],{addPotionChancePct=10}).addPotionChancePct==100)
assert(D.getDescription(g.deities[1]):find("100%",1,true) and roll(.99,function() assert(Alchemy.rollPermanent(g)) end)==0)
g=game({amp,eternal});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(Alchemy.effects(g)==1);g.monster.bossState.slotLock.slot=2;local power,chance=Alchemy.effects(g);assert(power==2 and chance==0)
g=game();g.backpackDeities={D.CATALOG[amp],D.CATALOG[eternal]};local power,chance=Alchemy.effects(g);assert(power==1 and chance==0)
g=game({"spirit_right_echo",amp});D.evolve(g.deities[1]);assert(Alchemy.effects(g)==8,"two copy activations and source multiply")
g=game({"spirit_right_echo",eternal});local _,chance=Alchemy.effects(g);assert(math.abs(chance-19)<1e-8)
g=game({amp});g.deities[1].bloodPower=5;assert(Alchemy.effects(g)==10)
g=game({amp});g.deities[1].evolutionLevel=10000;assert(Alchemy.effects(g)==128)
g=game({eternal});c=g.hand[1];c.isPrimalDrone=true;c.baseChips=50;c.bonusBaseChips=50;g.persistentDeck[1]=Deck.cloneCard(c)
roll(0,function() use(g,"cons_damage") end);Deck.restoreDeck(g.persistentDeck);assert(g.persistentDeck[1].baseChips==70)
for _,id in ipairs({amp,eternal}) do
    g=game();g.gold=100;assert(Shop.buyItem({items={{category="deity",deity=D.CATALOG[id],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));D.evolve(g.deities[1])
    loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(loaded.deities[1].id==id and loaded.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},99)==91)
print("SPN alchemy PASS: all potion magnitudes/durations, evolution/chance boundaries, one shared proc, confirmed speed target, permanent sync/no double bonus/save/next battle/drone, preview/RNG, ineligible/failed use, locks/reserve/copies/blood/caps/shop")
