-- Controlled build trajectories with real combat and an optional constrained shop buyer.
local G=require("src.game_state")
local D=require("src.deck")
local R=require("src.rng")
local Run=require("src.run_manager")
local C=require("src.combat")
local A=require("src.card_abilities")
local E=require("src.enemy_abilities")
local Group=require("src.enemy_group")
local Boss=require("src.boss_abilities")
local H=require("src.human_bosses")
local Poker=require("src.poker")
local Score=require("src.scoring")
local Potions=require("src.potions")
local Health=require("src.player_health")
local Spn=require("src.deities")
local seeds,offset,out,before,audit,proposal=40,0,"docs/balance_baseline",false,false,false
local proposalKit=false
local proposalBridge=false
local world=false
local supplies=false
local onlyProfile,onlyPolicy,noProbes,trace,noRest,originalPressure
for _,v in ipairs(arg or {}) do
    seeds=tonumber(v:match("^%-%-sim%-seeds=(%d+)$")) or seeds
    offset=tonumber(v:match("^%-%-sim%-offset=(%d+)$")) or offset
    out=v:match("^%-%-sim%-out=(.+)$") or out
    if v=="--sim-before" then before=true end
    if v=="--sim-audit" then audit=true end
    if v=="--sim-proposal" then proposal=true end
    if v=="--sim-proposal-kit" then proposal=true;proposalKit=true end
    if v=="--sim-proposal-bridge" then proposalBridge=true;proposalKit=true end
    if v=="--sim-world" then world=true end
    if v=="--sim-supplies" then supplies=true end
    onlyProfile=v:match("^%-%-sim%-profile=(%a+)$") or onlyProfile
    onlyPolicy=v:match("^%-%-sim%-policy=(%a+)$") or onlyPolicy
    if v=="--sim-no-probes" then noProbes=true end
    if v=="--sim-trace" then trace=true end
    if v=="--sim-no-rest" then noRest=true end
    if v=="--sim-original-pressure" then originalPressure=true end
end
if originalPressure then
    require("src.enemy_loadout").damageScale=function(m)
        if not (m.bossData and m.bossData.humanBoss) then return 1 end
        return (m.bossData.damageScale or 1)*((m.difficultyAnte or m.stage or m.round or 1)<=3 and .85 or 1)
    end
end
if proposal then
    Run.calculateBlindHp=function(stage,kind)
        local hp=100
        for step=2,math.max(1,stage) do hp=math.floor(hp*(step<=5 and 1.60 or 1.50)+.5) end
        return kind=="big" and math.floor(hp*1.5+.5) or kind=="boss" and math.floor(hp*2+.5) or hp
    end
end
if proposalBridge then
    Run.calculateBlindHp=function(stage,kind)
        local anchors={100,200,400,750,1284}
        local hp=anchors[math.min(5,math.max(1,stage))]
        for step=6,math.max(1,stage) do hp=math.floor(hp*(step<=20 and 1.64 or 1.71)+.5) end
        return kind=="big" and math.floor(hp*1.5+.5) or kind=="boss" and math.floor(hp*2+.5) or hp
    end
end
assert(seeds>=1 and seeds<=1000 and not out:find("..",1,true) and out:match("^docs/[%w_/-]+$"))
io.stdout:setvbuf("no")
-- Reproduce the pre-tuning boss rules without editing the live source/save.
if before then
    Run.calculateBlindHp=function(stage,kind)
        local hp=21;for _=2,math.max(1,stage) do hp=math.floor(hp*1.71+.5) end
        return kind=="big" and math.floor(hp*1.5+.5) or kind=="boss" and math.floor(hp*2+.5) or hp
    end
    for _,d in ipairs(H.definitions) do d.firstStage=1;d.hpScale=1;d.damageScale=1 end
    require("src.enemy_loadout").damageScale=function() return 1 end
    local handStart=H.handStart
    H.handStart=function(g)
        local m=H.primary(g)
        if H.number(m)~=3 then return handStart(g) end
        local choices={};local limit=A.handSize(g,g.maxHandSize)
        for _,hand in ipairs(Poker.ALL_HANDS_ORDERED) do
            if g.unlockedHands[hand.id] and (hand.requiredCards or 1)<=limit then choices[#choices+1]=hand end
        end
        m.humanBossState.required=choices[R.random(#choices)] or Poker.HAND_TYPES.HIGH_CARD
    end
end
local profiles={{id="weak",chips=2500,speed=12},{id="normal",chips=14000,speed=24},{id="strong",chips=70000,speed=36}}
local function copy(t) local n={};for k,v in pairs(t) do n[k]=type(v)=="table" and copy(v) or v end;return n end
local function newGame(seed)
    R.seed(seed)
    local g=G.new("red_deck");g.persistentDeck=D.createRedStarterDeck();g.simAcquired=#g.persistentDeck
    return g
end
local function progress(g,p,stage,fresh)
    local maxHp=100+math.floor(400*(stage-1)/19)
    local gain=maxHp-(g.simMaxHp or 100);g.simMaxHp=maxHp
    g.maxPlayerHp=g.maxPlayerHp+gain;g.playerHp=math.min(g.maxPlayerHp,g.playerHp+gain)
    if fresh then g.playerHp=g.maxPlayerHp end
    local handSize=stage>=12 and 5 or stage>=5 and 4 or 3
    g.maxHandSize=g.maxHandSize+handSize-(g.simHandSize or 3);g.simHandSize=handSize
    for _,id in ipairs({"pair","straight","three_of_a_kind"}) do if stage>=3 then g.unlockedHands[id]=true end end
    if stage>=12 then g.unlockedHands.two_pair=true;g.unlockedHands.flush=true end
    local count=math.min(12,4+stage)
    while g.simAcquired<count do
        g.persistentDeck[#g.persistentDeck+1]=D.newCard(R.random(2,14),D.FACTION_ORDER[R.random(4)])
        g.simAcquired=g.simAcquired+1
    end
    local upgrade=math.floor(12*((p.chips/12)^((stage-1)/19)-1))
    for _,card in ipairs(g.persistentDeck) do
        local delta=upgrade-(card.simChips or 0)
        card.bonusBaseChips=(card.bonusBaseChips or 0)+delta;card.simChips=upgrade
        local speed=math.floor((p.speed-8)*(stage-1)/19)
        card.speedBonus=(card.speedBonus or 0)+speed-(card.simSpeed or 0);card.simSpeed=speed
        if stage>=2 and not card.simGear then
            card.equipments={copy(require("src.equipment").ITEMS.gem_blast)};card.simGear=true
        end
    end
    for _,milestone in ipairs({4,9,14}) do
        g.simSpn=g.simSpn or {}
        if stage>=milestone and not g.simSpn[milestone] then
            g.simSpn[milestone]=true
            local id=({[4]="spirit_blade",[9]="spirit_drum",[14]="spirit_pebble"})[milestone]
            for slot=1,5 do if not g.deities[slot] then g.deities[slot]=copy(Spn.CATALOG[id]);break end end
        end
    end
    if not supplies or fresh then
        g.gold=10+math.floor(stage/4)
        g.simMedicine=2
        g.consumables={{id="cons_accuracy"},{id="cons_evasion"},{id="armor_potion_small",armorAmt=8,category="armor_potion"}}
    end
end
local function living(g) local a={};for _,m in ipairs(Group.members(g)) do if m.hp>0 then a[#a+1]=m end end;return a end
local function estimate(g,cards,info)
    local chips=info.chips or 5;local mult=info.mult or 1
    for _,card in ipairs(info.scoringCards) do if not H.disabled(g,card) then
        chips=chips+(card.baseChips or D.getChipValue(card.rank))
        if #(card.equipments or {})>0 then mult=mult+3 end
    end end
    return chips*mult
end
local function select(g,smart,options)
    local best,bestValue=nil,-1
    local required=(H.primary(g) or {}).humanBossState
    required=required and required.required
    local n=math.min(8,#g.hand)
    local targets=smart and living(g) or {Group.ensureTarget(g)}
    local candidates={}
    local function valueOf(raw,cards,info,target)
        local speed=C.getAverageAttackSpeed(cards,g,info)
        local chance=C.getHitChance(speed,E.speed(target))
        local value=smart and raw*chance or raw
        if smart then
            if required and info.type.id~=required.id then value=value*.001 end
            if target.humanCaptive then value=value*.12 end
            local durability=target.hp+(target.creatureArmor or 0)
            value=math.min(value,durability*1.1)+(raw>=durability and chance*.2*durability or 0)
            if target.intent and target.intent.type=="heal" then value=value*1.1 end
        end
        return value
    end
    for mask=1,2^n-1 do
        local cards={};for i=1,n do if math.floor(mask/2^(i-1))%2==1 then cards[#cards+1]=g.hand[i] end end
        local info=Poker.evaluate(cards,g.unlockedHands,g.handLevels)
        if info and #cards<=A.handSize(g) then
            local raw=estimate(g,cards,info)
            for _,target in ipairs(targets) do
                local value=valueOf(raw,cards,info,target)
                candidates[#candidates+1]={cards=cards,info=info,target=target,raw=raw,value=value,order=#candidates+1}
                if value>bestValue then bestValue=value;best={cards=cards,info=info,target=target,raw=raw} end
            end
        end
    end
    if smart and options and options.preview then
        -- Bounded tactical search keeps eight-card late-game hands practical to simulate.
        table.sort(candidates,function(a,b) return a.value==b.value and a.order<b.order or a.value>b.value end)
        best,bestValue=nil,-1
        for i=1,math.min(16,#candidates) do
            local c=candidates[i]
            local result=Score.calculate(c.info,g.deities,{gameState=g,monster=c.target,preview=true,
                hand=g.hand,unplayedCards=g.hand,gold=g.gold,handsAfterPlay=g.handsRemaining-1,
                handsRemaining=g.handsRemaining-1,discardsRemaining=g.discardsRemaining})
            c.raw=result.finalScore
            local value=valueOf(c.raw,c.cards,c.info,c.target)
            if value>bestValue or value==bestValue and c.order<best.order then best,bestValue=c,value end
        end
        collectgarbage("collect")
    end
    return best
end
local function use(g,id,target)
    for i,item in ipairs(g.consumables) do if item.id==id then
        if id=="armor_potion_small" then
            g.playerArmor=math.min(A.config.armorCap,(g.playerArmor or 0)+item.armorAmt)
            g.playerShield=g.playerArmor;table.remove(g.consumables,i);A.consumableUsed(g);return true
        end
        return Potions.use(g,i,target)
    end end
end
local function enemyTurn(g,phase,speed,stats)
    local result=C.resolveMonsterAttack(g,phase,speed)
    if result then stats.enemyDamage=stats.enemyDamage+(result.damage or 0) end
end
local function fight(g,blind,smart,options)
    C.start(g,Run.createBlindMonster(blind,g),blind.ante)
    local stats={turns=0,enemyDamage=0,oneShots=0,hits=0,misses=0,boss=H.number(g.monster) or 0,auras={}}
    while C.getOutcome(g)=="continue" and stats.turns<60 do
        if smart and options and options.supplies then
            for i=#g.consumables,1,-1 do
                local item=g.consumables[i]
                if item.category=="heal" and g.maxPlayerHp-g.playerHp>=(item.healAmt or 25)
                    or item.category=="armor_potion" and (g.playerArmor or 0)<=2 then
                    require("src.inventory").useUtility(g,i)
                end
            end
        end
        if #g.hand==0 or g.handsRemaining<=0 then
            A.roundEnd(g);C.beginEnemyTurn(g);enemyTurn(g,nil,nil,stats)
            C.onPlayerTurnEnd(g);C.onMonsterTurnEnd(g)
            g.handsRemaining=g.turnHandLimit or g.maxHands
            if #g.hand==0 then C.drawCards(g,g.maxHandSize,nil,true) end
            Boss.handEnd(g);A.resolveBossDamage(g);E.handEnd(g);A.roundStart(g);A.handStart(g)
            if #g.hand==0 or g.playerHp<=0 then break end
        end
        local choice=select(g,smart,options);if not choice then break end
        if smart and options and options.supplies then
            for i=#g.consumables,1,-1 do
                local item=g.consumables[i]
                if item.id=="cons_speed_small" then
                    if Potions.applySpeed(g,item,choice.cards[1]) then table.remove(g.consumables,i) end
                    choice=select(g,smart,options) or choice
                end
            end
        end
        if smart then
            local required=(H.primary(g) or {}).humanBossState;required=required and required.required
            if required and choice.info.type.id~=required.id and g.discardsRemaining>0 and #g.deck>0 then
                local discarded={table.remove(g.hand,1)}
                A.discard(g,discarded,{playerDiscard=true});g.discardPile[#g.discardPile+1]=discarded[1]
                g.discardsRemaining=g.discardsRemaining-1;C.drawCards(g,g.maxHandSize)
                choice=select(g,true,options) or choice
            end
        end
        g.monster=choice.target
        if smart then
            if H.number(g.monster)==6 and (g.monster.creatureArmor or 0)>0 and (g.playerArmor or 0)==0 then use(g,"armor_potion_small") end
            if C.getHitChance(C.getAverageAttackSpeed(choice.cards,g,choice.info),E.speed(g.monster))<.8 then use(g,"cons_accuracy") end
            local danger=0
            for _,m in ipairs(living(g)) do if not m.intent or m.intent.type=="attack" then
                danger=danger+E.attack(m)*C.getHitChance(E.speed(m),C.getAverageAttackSpeed(choice.cards,g,choice.info))
            end end
            if danger>g.playerHp*.3 then use(g,"cons_evasion") end
        end
        A.beginHand(g,choice.info,choice.cards)
        require("src.advanced_hands").begin(g,choice.info)
        g.lastPlayerAttackSpeed=C.getAverageAttackSpeed(choice.cards,g)
        g.lastPlayedHandId=choice.info.type.id;g.handsRemaining=g.handsRemaining-1
        local selected={};for _,c in ipairs(choice.cards) do selected[c]=true end
        for i=#g.hand,1,-1 do if selected[g.hand[i]] then g.discardPile[#g.discardPile+1]=table.remove(g.hand,i) end end
        Boss.onPlay(g)
        C.beginEnemyTurn(g,g.lastPlayerAttackSpeed);enemyTurn(g,"before",g.lastPlayerAttackSpeed,stats)
        if g.playerHp<=0 then break end
        local result=Score.calculate(choice.info,g.deities,{gameState=g,monster=g.monster,hand=g.hand,
            unplayedCards=g.hand,playerAttackSpeed=g.lastPlayerAttackSpeed,handsRemaining=g.handsRemaining,
            handsAfterPlay=g.handsRemaining,gold=g.gold,discardsRemaining=g.discardsRemaining,round=g.round,
            discardBuffs=g.discardBuffs,playedHandsHistory=g.playedHandsHistory,handsPlayedThisCombat=g.handsPlayedThisCombat,
            drawCards=function(n) return A.draw(g,n) end})
        g.handsPlayedThisCombat=g.handsPlayedThisCombat+1
        if options then g.gold=g.gold+(result.bonusGoldAwarded or 0) end
        g.playerArmor=math.min(A.config.armorCap,(g.playerArmor or 0)+(result.addArmor or 0));g.playerShield=g.playerArmor
        Health.heal(g,result.healHp or 0);g.playerHp=math.max(0,g.playerHp-(result.hpCost or 0))
        local target=g.monster
        local before=target.hp+(target.creatureArmor or 0)
        local _,_,_,roll=C.resolvePlayerAttack(g,result.finalScore)
        stats.auras[#stats.auras+1]=result.finalScore
        if roll.missed then stats.misses=stats.misses+1 else
            stats.hits=stats.hits+1
            if before>target.hp+(target.creatureArmor or 0) then
                target.simDamageHits=(target.simDamageHits or 0)+1
                if target.hp<=0 and target.simDamageHits==1 then stats.oneShots=stats.oneShots+1 end
            end
        end
        stats.turns=stats.turns+1
        g.playedHandsHistory[choice.info.type.id]=options and (tonumber(g.playedHandsHistory[choice.info.type.id]) or 0)+1 or true
        g.discardBuffs={chips=0,mult=0,xMult=1,bonusDamagePct=0}
        if C.getOutcome(g)~="victory" then enemyTurn(g,"after",g.lastPlayerAttackSpeed,stats) end
        A.finishHand(g);C.cleanupDestroyedCards(g)
        if C.getOutcome(g)~="continue" then break end
        C.onPlayerTurnEnd(g);C.onMonsterTurnEnd(g);Group.ensureTarget(g)
        C.drawCards(g,g.maxHandSize);A.handStart(g)
    end
    local outcome=C.getOutcome(g)
    stats.won=outcome=="victory";stats.timeout=outcome=="continue" and stats.turns>=60
    stats.hp=g.playerHp
    if stats.won then
        A.combatWin(g)
        if noRest then g.playerHp=g.playerHp-(g.abilityCombat.victoryRecovery or 0);g.abilityCombat.victoryRecovery=0 end
    end
    H.finish(g)
    return stats
end
if audit then return require("tests.balance_new_audit").run({fight=fight,newGame=newGame,copy=copy}) end
local maxStage=world and 120 or 20
local function blindsFor(stage,g)
    if not world then return Run.generateAnteBlinds(stage,nil,"human",stage) end
    local regions={"human","hearts","diamonds","clubs","spades","unknown"}
    local region=regions[math.min(6,math.floor((stage-1)/20)+1)]
    local area=(stage-1)%20+1
    g.run=g.run or Run.newRun("red_deck")
    g.run.ante=stage;g.run.regionId=region;g.run.areaStage=area
    return Run.generateAnteBlinds(stage,"red_deck",region,area)
end
local rows={"mode,profile,policy,seed,stage,encounter,boss,won,turns,hp,enemy_damage,hits,misses,kill_hits,aura_mean,timeout"}
local function record(mode,p,policy,seed,stage,index,s)
    local sum=0;for _,v in ipairs(s.auras) do sum=sum+v end
    rows[#rows+1]=table.concat({mode,p.id,policy,seed,stage,index,s.boss,s.won and 1 or 0,s.turns,
        math.floor(s.hp),s.enemyDamage,s.hits,s.misses,s.oneShots,math.floor(sum/math.max(1,#s.auras)),s.timeout and 1 or 0},",")
end
local results={}
local economy={"profile,policy,seed,stage,encounter,gold,hp,spent,starter,heal_bought"}
local function resupply(g,blind,stage,index,p,policy,seed)
    local Shop=require("src.shop")
    local Reward=require("src.reward_system")
    g.run=g.run or Run.newRun("red_deck")
    g.run.ante=stage;g.run.areaStage=(stage-1)%20+1;g.run.currentBlindIndex=index
    g.run.stats.blindsWon=g.run.stats.blindsWon+1
    g.pendingVictoryReward=nil
    Reward.begin(Reward.calculate(blind,g),g)
    local before=g.gold;local healBought=0
    Shop.enterAfterCombat(g)
    local shop=Shop.new();Shop.refresh(shop,g)
    for visit=1,3 do
        local boughtStarter=false
        for i=#shop.items,1,-1 do
            local item=shop.items[i]
            if item.starterOffer and Shop.canAfford(item,g) then
                assert(Shop.buyItem(shop,i,g))
                boughtStarter=true
                local target=g.persistentDeck[1]
                for _,card in ipairs(g.persistentDeck) do if card.baseChips>target.baseChips then target=card end end
                assert(require("src.basic_equipment").attach(g,#g.backpackEquipment,target));target.simGear=true
            elseif item.currency~="blood" and item.consumable and item.consumable.category=="heal"
                and g.maxPlayerHp-g.playerHp>=(item.consumable.healAmt or 25) and Shop.canAfford(item,g) then
                assert(Shop.buyItem(shop,i,g));healBought=healBought+1
                local card=table.remove(g.backpackConsumables)
                Health.heal(g,card.healAmt)
            end
        end
        -- A modest buyer: one useful upgrade per visit, no rerolls, no sale farming.
        local best,bestValue,targetIndex
        for i,item in ipairs(shop.items) do if item.currency~="blood" and Shop.canAfford(item,g) then
            local value,target=0,nil
            if item.equipment then
                local eq=item.equipment;local params=eq.params or {}
                value=(params.heal or 0)*6+(params.armor or 0)*2+(eq.attackSpeed or params.speed or 0)*3
                if eq.soulOnly then value=20 end
                if value>0 then
                    for _,card in ipairs(g.persistentDeck) do
                        if require("src.equipment").canAttach(card,eq) then target=card;break end
                    end
                    if not target then value=0 end
                end
            elseif item.category=="voucher" and (item.voucherId=="v_vitality" or item.voucherId=="v_apothecary") then value=15
            elseif item.deity and (item.deity.id=="spirit_life_bloom" or item.deity.id=="spirit_guardian_shell" or item.deity.id=="spirit_fleet_wind") then
                for slot=1,5 do if not g.deities[slot] then target=slot;value=12;break end end
            end
            value=value/math.max(1,item.cost)
            if value>(bestValue or 0) then best,bestValue,targetIndex=i,value,target end
        end end
        if best and not boughtStarter then
            local item=shop.items[best];assert(Shop.buyItem(shop,best,g))
            if item.equipment then
                if item.currency=="souls" then assert(require("src.equipment").attach(targetIndex,item.equipment))
                else assert(require("src.basic_equipment").attach(g,#g.backpackEquipment,targetIndex)) end
            elseif item.deity then g.deities[targetIndex]=table.remove(g.backpackDeities) end
        end
        if Shop.leave(shop,g)~="shop" then break end
    end
    economy[#economy+1]=table.concat({p.id,policy,seed,stage,index,g.gold,math.floor(g.playerHp),before-g.gold,
        g.run.stats.starterGearPurchased and 1 or 0,healBought},",")
    -- Presentation queues are never consumed by this headless controller.
    g.rewardPacks={};g.spnFeedback={};g.potionFeedback={}
end
for _,p in ipairs(profiles) do for _,policy in ipairs({"greedy","tactical"}) do
    if (not onlyProfile or p.id==onlyProfile) and (not onlyPolicy or policy==onlyPolicy) then
    local completed,total,stageSum=0,0,0
    for sample=1,seeds do
        local seed=10000+offset+sample
        local g=newGame(seed);local alive=true;local last=0
        if supplies then
            g.run=Run.newRun("red_deck")
            g.consumables={require("src.shop").healingItem(nil,"healing_potion").consumable,
                require("src.shop").healingItem(nil,"armor_potion_small").consumable,
                require("src.shop").healingItem(nil,"cons_speed_small").consumable}
        end
        for stage=1,maxStage do
            if trace then print("stage",stage,"memory MB",math.floor(collectgarbage("count")/1024)) end
            R.seed(seed*1000+stage*10);progress(g,p,stage)
            local blinds=blindsFor(stage,g)
            for index,blind in ipairs(blinds) do
                R.seed(seed*1000+stage*10+index)
                if not supplies and g.simMedicine>0 and g.gold>=7 and g.maxPlayerHp-g.playerHp>=60 then
                    Health.heal(g,60);g.gold=g.gold-7;g.simMedicine=g.simMedicine-1
                end
                local stats=fight(g,blind,policy=="tactical",supplies and {supplies=true,preview=policy=="tactical"} or nil);record("campaign",p,policy,seed,stage,index,stats);total=total+1
                if not stats.won then alive=false;break end
                if supplies then resupply(g,blind,stage,index,p,policy,seed) else g.gold=g.gold+blind.baseReward end
                if proposalKit and stage==1 and index==1 and g.gold>=12 then
                    local target=g.persistentDeck[1]
                    for _,card in ipairs(g.persistentDeck) do if card.baseChips>target.baseChips then target=card end end
                    target.equipments={copy(require("src.equipment").ITEMS.gem_blast)}
                    target.simGear=true;g.gold=g.gold-12
                end
                if stage==1 and index==1 and g.simAcquired==1 then
                    g.persistentDeck[#g.persistentDeck+1]=D.newCard(R.random(2,14),D.FACTION_ORDER[R.random(4)])
                    g.simAcquired=2
                    g.persistentDeck[1].equipments={copy(require("src.equipment").ITEMS.gem_blast)}
                    g.persistentDeck[1].simGear=true;g.gold=g.gold-4
                end
            end
            if not alive then break end
            last=stage
        end
        if alive then completed=completed+1 end;stageSum=stageSum+last
        -- Independent stage probes expose late-stage difficulty despite campaign attrition.
        for stage=1,(noProbes and 0 or maxStage) do
            local probe=newGame(seed);R.seed(seed*1000+stage*10);progress(probe,p,stage,true)
            local blinds=blindsFor(stage,probe)
            for index,blind in ipairs(blinds) do
                local state=R.getState();local fresh=copy(probe)
                R.seed(seed*1000+stage*10+index)
                record("probe",p,policy,seed,stage,index,fight(fresh,blind,policy=="tactical",supplies and {preview=policy=="tactical",supplies=true} or nil))
                R.setState(state)
            end
        end
    end
    results[#results+1]={p.id,policy,completed,seeds,stageSum/seeds,total}
    print(string.format("%s/%s: %d/%d campaigns; mean stages %.2f; %d campaign fights",p.id,policy,completed,seeds,stageSum/seeds,total))
end end end
local f=assert(io.open(out..".csv","w"));f:write(table.concat(rows,"\n"),"\n");f:close()
local f2=assert(io.open(out.."_summary.csv","w"));f2:write("profile,policy,completed,seeds,mean_stages,campaign_fights\n")
for _,row in ipairs(results) do f2:write(table.concat(row,","),"\n") end;f2:close()
if supplies then local ef=assert(io.open(out.."_supplies.csv","w"));ef:write(table.concat(economy,"\n"),"\n");ef:close() end
print("Simulation results: "..out..".csv; "..(#rows-1).." encounters")
return true
