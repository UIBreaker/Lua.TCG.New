local H=require("src.human_bosses")
local C=require("src.combat")
local A=require("src.enemy_abilities")
local D=require("src.deck")
local M=require("src.monster")
local G=require("src.game_state")
local P=require("src.persistence")
local R=require("src.rng")
local serial=0
local function fixture(n,prepare)
    serial=serial+1
    local g=G.new("red_deck");g.playerHp=10000000;g.maxPlayerHp=g.playerHp
    g.persistentDeck={}
    for i=1,8 do g.persistentDeck[i]=D.newCard(i+1,"hearts") end
    if prepare then prepare(g) end
    local data={};for k,v in pairs(H.definitions[n]) do data[k]=v end;data.encounterToken=serial
    local m={isBoss=true,bossData=data,name=data.name,hp=1000,maxHp=1000,attack=10,attackSpeed=5,
        stage=5,regionId="human",areaStage=5,phase=1,human=true,neutralHuman=true,cardRank=6,
        intent={type="attack",value=10,label="Tấn công"}}
    C.start(g,m,5)
    return g,m
end
local random=R.random
local function fixed(a,b) return a and (b and a or 1) or 0 end
R.random=fixed
local ok,err=xpcall(function()
    local Run=require("src.run_manager")
    local seen={}
    local oldState=R.getState()
    for sample=1,200 do
        local stage=(sample-1)%20+1;R.seed(1000+sample);local state=R.getState()
        local blind=Run.generateAnteBlinds(stage,nil,"human",stage)[3]
        assert(blind.debuff.humanBoss and blind.name==blind.debuff.name)
        assert(R.getState()==state,"boss selection must be RNG-neutral to combat reward rolls")
        seen[blind.debuff.humanBoss]=true
    end
    for i=1,10 do assert(seen[i],"all ten human bosses must be selectable") end
    R.setState(oldState)
    for _,region in ipairs({"hearts","diamonds","clubs","spades","unknown"}) do
        assert(not Run.generateAnteBlinds(5,nil,region,5)[3].debuff.humanBoss,"human roster must not leak into "..region)
    end
    assert(Run.generateAnteBlinds(40,nil,"human",7)[3].debuff.humanBoss,"returning to the human region uses its local roster")
    R.random=fixed
    local g,m=fixture(1)
    local base=math.floor(m.enemyInventory.base.maxHp*(1+require("src.enemy_loadout").stats(m).hp))
    assert(m.maxHp==math.floor(base*1.5))
    m.hp=1;local healed=0
    for i=1,30 do local before=m.hp;H.afterAttack(g,m,{action="attack",missed=true,damage=0});healed=healed+m.hp-before end
    assert(healed==math.floor(m.maxHp*.6),"5% attack heals must exhaust the shared reserve")

    g,m=fixture(2);local card=g.hand[1];card.speedBonus=999
    assert(A.speed(m)>=1998,"double speed must still work when the player's card reaches 999")
    card.speedBonus=10;g.abilityHand={played={card}};local before=D.peekCardAttackSpeed(card,g)
    H.afterAttack(g,m,{action="attack",damage=1})
    assert(D.peekCardAttackSpeed(card,g)==before-2 and m.humanBossState.stolen==2)
    local copy=D.cloneCard(card);assert(copy.humanSpeedPenalty==2)
    local restored=P.restoreSnapshot(P.makeSnapshot(g,"playing"))
    local found=false;for _,c in ipairs(restored.persistentDeck) do if c.id==card.id then assert(c.humanSpeedPenalty==2);found=true end end;assert(found)

    g,m=fixture(3);assert(m.humanBossState.required.id=="high_card")
    g.lastPlayedHandId="pair";g.potionCombat={accuracy=true}
    local damage,dead,hits,roll=C.resolvePlayerAttack(g,100000,{hitChance=1,missed=false})
    assert(damage==0 and roll.missed and roll.humanOath,"wrong hands miss even with guaranteed accuracy")
    g.lastPlayedHandId="high_card";m.creatureArmor=0
    assert(C.resolvePlayerAttack(g,1,{hitChance=1,missed=false})==1)
    local count=#g.hand;H.afterAttack(g,m,{action="attack",damage=0})
    assert(#g.hand==count-2 and #g.discardPile==2,"connected attacks force actual discards even when armor absorbs damage")

    g,m=fixture(4);local c=g.hand[1];local rank,chips=c.rank,c.baseChips
    H.afterAttack(g,m,{action="attack",damage=1})
    assert(c.rank==11 and H.disabled(g,c) and require("src.boss_abilities").isAbilityDisabled(g,c))
    for _,canonical in ipairs(g.persistentDeck) do if canonical.id==c.id then assert(canonical.rank==rank and not canonical.humanCourtForm) end end
    H.finish(g);assert(c.rank==rank and c.baseChips==chips and not c.humanCourtForm)

    g,m=fixture(5);assert(#g.hand==2 and require("src.card_abilities").handSize(g)==2)
    assert(H.attack(g,m,10)==20);g.hand[3]=D.newCard(3,"clubs");g.hand[4]=D.newCard(4,"clubs");g.hand[5]=D.newCard(5,"clubs")
    assert(H.attack(g,m,10)==50)

    g,m=fixture(6);assert(m.creatureArmor==m.hp)
    local armor=m.creatureArmor;assert(M.takeDamage(m,100000,true)==0 and m.creatureArmor==armor)
    g.playerArmor=1;assert(M.takeDamage(m,300,true)==0 and m.creatureArmor==armor-300)
    g.playerArmor=500;g.playerShield=500;g.lastPlayerAttackSpeed=1;m.intent={type="attack"}
    local hp=g.playerHp;local hit=C.resolveMonsterAttack(g,nil,nil,m)
    assert(hit.damage==hit.attack and g.playerHp==hp-hit.attack and g.playerArmor==500,"fortress attacks bypass armor without deleting it")

    local deity=require("src.deities").CATALOG.spirit_ember
    g,m=fixture(7,function(state)
        state.deities={};for i=1,2 do state.deities[i]={};for k,v in pairs(deity) do state.deities[i][k]=v end;state.deities[i].evolutionLevel=3 end
    end)
    local owned=require("src.loadout").ownedDeities(g);assert(#owned==1)
    local survivor=owned[1];m.creatureArmor=0;M.takeDamage(m,1,true)
    assert(survivor.evolutionLevel==2)
    C.start(g,m,5);assert(#require("src.loadout").ownedDeities(g)==1,"restarting an interrupted encounter cannot destroy another opening SPN")
    g.run=Run.newRun();g.run.currentBlindIndex=3
    g.run.blinds[3].debuff=m.bossData
    local saved=P.makeSnapshot(g,"playing");local loaded=P.restoreSnapshot(saved)
    assert(loaded.run.blinds[3].debuff.id==m.bossData.id and loaded.run.blinds[3].debuff.encounterToken==m.bossData.encounterToken)
    local countBefore=#require("src.loadout").ownedDeities(loaded)
    C.start(loaded,Run.createBlindMonster(loaded.run.blinds[3],loaded),5)
    assert(#require("src.loadout").ownedDeities(loaded)==countBefore,"save/load cannot repeat opening destruction")

    g,m=fixture(8,function(state) for _,c2 in ipairs(state.persistentDeck) do c2.evolutionLevel=3 end end);assert(#g.enemies==3 and #g.hand==1)
    H.afterAttack(g,m,{action="attack",damage=1});assert(g.hand[1].evolutionLevel==2)
    local deadAlly,savedAlly=g.enemies[2],g.enemies[3]
    local deadId,savedId=deadAlly.humanCaptive.card.id,savedAlly.humanCaptive.card.id
    M.takeDamage(deadAlly,100000,true);assert(#g.persistentDeck==7)
    for _,card2 in ipairs(g.persistentDeck) do assert(card2.id~=deadId) end
    m.creatureArmor=0;M.takeDamage(m,100000,true)
    assert(C.getOutcome(g)=="victory" and g.monster==m and #g.enemies==2)
    local returned=0;for _,card2 in ipairs(g.hand) do if card2.id==savedId then returned=returned+1 end end
    H.finish(g);assert(returned==1 and #g.persistentDeck==7 and savedAlly.hp>0,"rescue living captives without awarding them as kills or duplicating the card")

    g,m=fixture(8,function(state) state.persistentDeck={state.persistentDeck[1]} end)
    assert(#g.enemies==1 and #g.hand==1 and #g.persistentDeck==1,"capturing cards must leave the one-card starter deck playable")

    g,m=fixture(9);assert(g.discardsRemaining==0 and m.intent.type=="human_skill")
    local count=#g.persistentDeck;hit=C.resolveMonsterAttack(g,nil,nil,m)
    assert(hit.action=="human_skill" and #g.persistentDeck==count-1 and m.intent.type=="attack")
    m.intent={type="human_skill"};assert(C.resolveMonsterAttack(g,nil,nil,m).blocked and #g.persistentDeck==count-1)

    g,m=fixture(10,function(state) state.gold=20;state.backpackConsumables={{id="healing_potion",category="heal",name="Bình Máu"}} end)
    local stacks=m.humanBossState.goldStacks;assert(stacks[1]+stacks[2]+stacks[3]==2)
    g.playerArmor=0;g.playerShield=0;g.lastPlayerAttackSpeed=1;m.intent={type="attack"}
    hit=C.resolveMonsterAttack(g,nil,nil,m)
    assert(hit.damage>0 and #g.backpackConsumables==0 and g.gold>20)
    local snapshot=P.makeSnapshot(g,"playing");assert(snapshot.game.humanBossReceipt and not snapshot.game.monster)
    print("Human bosses: all 10 mechanics, finite healing, uncapped double speed, permanent theft/deletion/devolution, forced hands/discards, temporary court forms, hand capacity, gated armor/pierce, hostage rescue and gold/sales passed")
end,debug.traceback)
R.random=random
assert(ok,err)
return true
