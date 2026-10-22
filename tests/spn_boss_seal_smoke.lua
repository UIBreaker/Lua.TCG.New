local Seal=require("src.spn_boss_seal")
local D=require("src.deities")
local Deck=require("src.deck")
local G=require("src.game_state")
local Combat=require("src.combat")
local Boss=require("src.boss_abilities")
local EA=require("src.enemy_abilities")
local H=require("src.human_bosses")
local W=require("src.free_human_bosses")
local K=require("src.kingdom_bosses")
local R=require("src.rng")
local P=require("src.persistence")
local serial=0
local function fixture(def)
    serial=serial+1
    local g=G.new("red_deck");g.playerHp=100000;g.maxPlayerHp=100000;g.gold=100;g.deities={};g.persistentDeck={}
    for i=1,10 do g.persistentDeck[i]=Deck.newCard(i+1,"hearts") end
    local data={};for k,v in pairs(def or {}) do data[k]=v end;data.encounterToken=serial;data.id=data.id or "black_tax_collector"
    local m={isBoss=true,bossData=data,name=data.name or "Seal test Boss",hp=1000,maxHp=1000,attack=10,attackSpeed=5,stage=7,regionId="human",areaStage=7,phase=1,human=true}
    Combat.start(g,m,7);m.enemyInventory=nil;EA.plan(g,m)
    assert(D.addDeity(g,D.CATALOG[Seal.id],1));return g,m
end
local function strip(g,source)
    if source=="reserve" then g.backpackDeities={table.remove(g.deities,1)} end
    local hands,discards=g.handsRemaining,g.discardsRemaining
    assert(Seal.destroy(g,source or "equipped",1,true))
    assert(source=="reserve" and #g.backpackDeities==0 or not g.deities[1])
    assert(g.handsRemaining>=hands and g.discardsRemaining>=discards,"free action; restrictions may refund resources")
end
local g,m=fixture({id="black_tax_collector"});local card=g.deities[1]
local function stats(level)
    assert((card.evolutionLevel or 0)==level)
    local result=D.scaleEffect(card,card.onHandScored(nil,nil,card))
    assert(result.addChips==level*5 and result.addMult==level*5,"exact +5 each axis per evolution")
    assert(D.getDescription(card):find("+"..(level*5).." Sát thương",1,true))
end
for level=0,8 do stats(level);assert(D.evolve(card)) end
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(loaded.deities[1].evolutionLevel==9)
local previous=P.encode(g);assert(not Seal.destroy(g,"equipped",1,false) and P.encode(g)==previous)
assert(not Seal.destroy(g,"wrong",1,true) and not Seal.destroy(g,"equipped",99,true))
g.monster.isBoss=false;assert(not Seal.destroy(g,"equipped",1,true));g.monster.isBoss=true
g,m=fixture({id="black_tax_collector"});assert(D.addDeity(g,D.CATALOG.spirit_ashen_legacy,2))
m.bossState.slotLock={kind="spn",slot=1,untilHand=99};m.bossState.pendingDamage=500;m.bossState.debt=9
g.hand[1].faceDown=true;g.hand[1].abilityDisabledUntil=99
strip(g);assert(m.spnAbilitiesSealed and not Boss.passiveEnabled(m) and not Boss.isSlotLocked(g,"spn",1))
assert(not g.hand[1].faceDown and not Boss.isAbilityDisabled(g,g.hand[1]) and m.bossState.pendingDamage==0)
assert(g.deities[2].spnGrowth.deathChips==.5,"manual destruction fires true-destruction synergies")
local gold=g.gold
for i=1,30 do Boss.handStart(g);Boss.handEnd(g);assert(g.gold==gold and m.bossState.pendingDamage==0) end
assert(Boss.beforeAttack(g) and m.intent.type=="attack","normal attacks remain enabled")
assert(Boss.describe(m):find("ĐẾN HẾT TRẬN",1,true))
g,m=fixture({id="the_needle"});strip(g,"reserve");assert(m.spnAbilitiesSealed)
g,m=fixture();assert(D.destroyDeity(g,1,true));assert(not m.spnAbilitiesSealed,"automatic sacrifice is not manual activation")
for n,def in ipairs(H.definitions) do
    g,m=fixture(def);g.playerArmor=0;g.playerShield=0
    if n==4 then
        m.humanBossState.forms[g.hand[1].id]=11;H.handStart(g);assert(g.hand[1].humanCourtForm)
    end
    strip(g)
    assert(not H.rejectHand(g) and H.handSize(g,5)==5 and not H.disabled(g,g.hand[1]))
    assert(H.speed(m,7)==7 and H.attack(g,m,10)==10 and not H.intent(g,m))
    m.intent={type="human_skill"};assert(not H.action(g,m));EA.plan(g,m);assert(m.intent.type=="attack")
    local before=P.encode(g.persistentDeck);local count=#g.backpackDeities
    for i=1,3 do H.handStart(g);H.afterDamage(m,m.hp+1);H.afterAttack(g,m,{action="attack",damage=20});Boss.handEnd(g) end
    assert(P.encode(g.persistentDeck)==before and #g.backpackDeities==count,"human skills remain inactive")
    if n==4 then assert(not g.hand[1].humanCourtForm) end
    if n==8 then assert(#g.enemies==1,"captives released") end
    if n==9 then assert(g.discardsRemaining>0 and g.spnDiscardCap>0) end
    if n==1 or n==10 then assert(m.maxHp==m.humanBossState.abilityBase.maxHp and m.attack==10 and m.attackSpeed==5) end
end
for _,def in ipairs(W.definitions) do
    g,m=fixture(def);strip(g)
    m.freeHumanState.usedHands.high_card=true;g.areaPlayedCards={key="legacy:7",ids={[g.hand[1].id]=true}}
    assert(not W.handBlocked(g,"high_card") and not W.blocked(m,g.hand[1]) and not W.spnBlocked(m,g.deities[1]))
    local before=P.encode(g.persistentDeck);local hp=g.playerHp
    W.active(g);assert(g.playerHp==hp and before==P.encode(g.persistentDeck))
    assert(W.attackFactor(m)==1 and W.playerDamageFactor(g)==1 and not W.absorbOneshot(m,m.hp,m.hp*10))
end
for _,def in ipairs(K.definitions) do
    g,m=fixture(def);strip(g);assert(K.factor(m)==1 and not K.disabled(g,Deck.newCard(7,def.entitySuit)))
end
g,m=fixture();m.creatureKind="ancient_skeleton";strip(g);m.hp=0;assert(not EA.revive(m))
g,m=fixture();m.creatureKind="forest_goblin";m.enemyAbility={};strip(g)
local goldBefore=g.gold;EA.afterAttack(g,m,100);EA.afterAttack(g,m,100);assert(g.gold==goldBefore and EA.attackBonus(g,m)==0)
local nextBoss={isBoss=true,bossData={id="black_tax_collector"},hp=1000,maxHp=1000,attack=10,attackSpeed=5,human=true,name="Next boss"}
Combat.start(g,nextBoss,8);assert(Boss.passiveEnabled(nextBoss) and not nextBoss.spnAbilitiesSealed)
assert(#D.getRandomShopPool({},999)==100)
print("SPN boss seal PASS: exact +5/+5 evolution; manual equipped/reserve destruction incl locked slots; all human/free/kingdom boss families sealed; live restrictions released, normal attacks kept, true destruction synergies, no automatic activation, save and next-battle boundaries")
return true
