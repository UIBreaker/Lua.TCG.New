local K=require("src.kingdom_bosses")
local Run=require("src.run_manager")
local G=require("src.game_state")
local D=require("src.deck")
local A=require("src.enemy_abilities")
local Boss=require("src.boss_abilities")
local P=require("src.persistence")
local Rng=require("src.rng")
local aliases={hearts="valoria",diamonds="aurelia",clubs="elaris",spades="vharos"}
local function fixture(def)
    local g=G.new();g.run=Run.newRun("red_deck");local r=g.run
    r.ante=40;r.regionId=def.entitySuit;r.areaStage=20;r.currentBlindIndex=3
    r.blinds=Run.generateAnteBlinds(40,"red_deck",r.regionId,20)
    r.blinds[3].debuff=def
    local m=Run.createBlindMonster(r.blinds[3],g,true)
    require("src.combat").start(g,m,40)
    m.enemyInventory=nil;m.attack=100;m.attackSpeed=20
    g.playerHp=10000;g.maxPlayerHp=10000;g.playerArmor=0;g.playerShield=0
    local c=D.newCard(7,def.entitySuit);local legacy=D.newCard(8,aliases[def.entitySuit]);local other=D.newCard(9,def.entitySuit=="hearts" and "clubs" or "hearts")
    g.hand={c,legacy,other};g.persistentDeck={D.cloneCard(c),D.cloneCard(legacy),D.cloneCard(other)}
    return g,m,c,legacy,other
end
for _,def in ipairs(K.definitions) do
    local g,m,c,legacy,other=fixture(def)
    assert(m.name==def.name and not m.human and m.creatureCard and m.cardSuit==def.entitySuit and m.cardRank==13)
    assert(K.count(m)==2 and math.abs(A.attack(m)-120)<1e-8 and math.abs(A.speed(m)-24)<1e-8)
    assert(Boss.isAbilityDisabled(g,c) and Boss.isAbilityDisabled(g,legacy) and not Boss.isAbilityDisabled(g,other))
    local before=g.playerHp;local gear=require("src.equipment").instance("soul_phoenix_lantern")
    c.equipments={gear};g.hand={c};assert(require("src.soul_relics").guard(g,before)==before,"Sealed held card must not activate its revival relic")
    g.hand={c,legacy,other};table.remove(g.hand,1)
    assert(K.count(m)==1 and math.abs(A.attack(m)-110)<1e-8 and math.abs(A.speed(m)-22)<1e-8)
    legacy.destroyed=true;assert(K.count(m)==0 and A.attack(m)==100);legacy.destroyed=nil
    g.hand={c,legacy,other};Boss.disable(g,1)
    assert(K.count(m)==0 and A.speed(m)==20 and not Boss.isAbilityDisabled(g,c))
    m.bossState.passiveUntil=0
    c.equipments={require("src.equipment").instance("basic_steel_tip")};c.disableFactionPassives=false
    local info=require("src.poker").evaluate({c},g.unlockedHands,g.handLevels)
    local hp,gold=g.playerHp,g.gold;local encoded=P.encode(g.persistentDeck)
    local result=require("src.scoring").calculate(info,{}, {gameState=g,monster=m,hand=g.hand,preview=true})
    local found=false
    for _,step in ipairs(result.steps) do if step.type=="card_scored" and step.card.id==c.id then assert(step.addedChips==0 and step.addedMult==0);found=true end end
    assert(found and result.bonusChips==0 and hp==g.playerHp and gold==g.gold and P.encode(g.persistentDeck)==encoded,"Mute all suits including legacy spade immunity, without preview mutation")
    legacy.seal="seal_echoes"
    result=require("src.scoring").calculate(info,{}, {gameState=g,monster=m,hand=g.hand,preview=true})
    for _,step in ipairs(result.steps) do assert(step.type~="seal_trigger","A sealed held card must not activate its seal") end
    legacy.seal=nil
    A.resources(m).mustAttack=true;m.intent={type="attack"};g.playerArmor=0;g.playerShield=0
    local expected=A.attack(m);local hit=require("src.combat").resolveMonsterAttack(g,nil,1,m)
    assert(math.abs(hit.attack-expected)<1e-8 and hit.damage>0,"Real enemy contact must use suit-enhanced damage")
    local loaded=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"playing")))))
    assert(loaded.run.blinds[3].debuff.id==def.id)
    local enemy=Run.createBlindMonster(loaded.run.blinds[3],loaded,true)
    require("src.combat").start(loaded,enemy,40);loaded.hand={D.newCard(2,def.entitySuit)}
    assert(K.count(enemy)==1 and Boss.isAbilityDisabled(loaded,loaded.hand[1]))
    m.hp=0;assert(K.count(m)==0 and not Boss.isAbilityDisabled(g,c),"Dead entity must release the suit")
end
for _,region in ipairs({"human","hearts","diamonds","clubs","spades","unknown","voyage"}) do
    local seen,ordinary={},false
    for sample=1,200 do
        Rng.seed(1000+sample);local state=Rng.getState()
        local blind=Run.generateAnteBlinds(20,nil,region,20)[3]
        assert(state==Rng.getState(),"Selection cannot consume reward RNG")
        if blind.debuff.kingdomEntity then seen[blind.debuff.id]=true else ordinary=true end
    end
    for _,def in ipairs(K.definitions) do assert(seen[def.id],"Free boss must be available in "..region) end
    assert(ordinary,"Local stage 20 cannot force an entity")
end
assert(not Run.generateAnteBlinds(20,nil,"blood_domain",8)[3].debuff.kingdomEntity)
print("Kingdom entities PASS: all four roam every main region; RNG-neutral selection, no forced finale, live 10% speed/damage, seals, passive counters and save/load")
