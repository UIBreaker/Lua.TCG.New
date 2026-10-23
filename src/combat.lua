local Deck = require("src.deck")
local Deities = require("src.deities")

local Abilities = require("src.card_abilities")
local Boss = require("src.boss_abilities")
local Group = require("src.enemy_group")
local EnemyAbilities = require("src.enemy_abilities")
local Anomalies = require("src.spn_anomalies")
local Combat = { Abilities = Abilities, Boss = Boss }

function Combat.getHitChance(attackerSpeed,targetSpeed)
    if attackerSpeed==nil or targetSpeed==nil then return 1 end
    attackerSpeed=math.max(0,attackerSpeed);targetSpeed=math.max(1,targetSpeed)
    return math.max(.05,math.min(1,attackerSpeed/targetSpeed))
end
local function accuracy(attackerSpeed,targetSpeed)
    local chance=Combat.getHitChance(attackerSpeed,targetSpeed)
    return {hitChance=chance,missed=chance<1 and require("src.rng").random()>=chance}
end
function Combat.rollPlayerAttack(game,timing)
    if timing and timing.forceMiss then return {hitChance=0,missed=true,timingMiss=true} end
    if timing and (timing.grade=="perfect" or timing.grade=="critical" or timing.grade=="ultimate" or timing.grade=="apex") then return {hitChance=1,missed=false,timing=timing} end
    if require("src.spn_elements").openingPower(game)>0 then return {hitChance=1,missed=false,frozen=true} end
    if (game.potionCombat or {}).accuracy or game.spnAttack and game.spnAttack.guaranteeHit then return {hitChance=1,missed=false} end
    return accuracy(game.lastPlayerAttackSpeed,EnemyAbilities.speed(game.monster))
end

function Combat.beginEnemyTurn(game,speed)
    game.enemyActed={};game.enemyActionPhases={}
    game.spnBasicArmorGranted=nil
    for _,m in ipairs(Group.members(game)) do
        game.enemyActionPhases[m]=EnemyAbilities.speed(m)>(speed or game.lastPlayerAttackSpeed or 0) and "before" or "after"
    end
end
function Combat.canEnemyAct(game,m,phase,speed)
    if m.hp<=0 or phase and (game.enemyActed or {})[m] then return false end
    local order=(game.enemyActionPhases or {})[m]
        or (EnemyAbilities.speed(m)>(speed or game.lastPlayerAttackSpeed or 0) and "before" or "after")
    return not phase or order==phase
end

function Combat.bedExplosions(game,aura,locked)
    local target=game.monster
    local bedExplosions={}
    if target.hasBed then
        for slot=1,Deities.getMaxSlots(game) do
            local deity=game.deities and game.deities[slot]
            local isLocked=locked and locked[slot]
            if not locked then isLocked=Boss.isSlotLocked(game,"spn",slot) end
            if deity and not isLocked then
                require("src.spn_mimic").each(game,game.deities,slot,function(effective)
                    local result=effective.onAttack and effective.onAttack()
                    if result and (result.bedExplosionPct or 0)>0 then
                        bedExplosions[#bedExplosions+1]={deity=deity,slot=slot,amount=math.floor(math.max(0,aura)*result.bedExplosionPct/100)}
                    end
                end,locked)
            end
        end
    end
    return bedExplosions
end

function Combat.resolvePlayerAttack(game, aura,roll,timing)
    require("src.spn_basics").armor(game,false)
    local Monster = require("src.monster")
    local target = game.monster
    if require("src.spn_elements").opening(game) then
        game.spnAttack=nil;require("src.advanced_hands").resolve(game,false)
        return 0,false,{}, {hitChance=1,missed=false,frozen=true}
    end
    for _,enemy in ipairs(Group.members(game)) do
        enemy.enemyObservedDamage=math.max(0,aura or 0)
    end
    roll=roll or Combat.rollPlayerAttack(game,timing)
    local attackEffects=game.spnAttack or {}
    game.spnAttack=nil
    if (game.potionCombat or {}).accuracy then
        roll={hitChance=1,missed=false}
        if (game.potionCombat.accuracyTurns or 1)<=1 then game.potionCombat.accuracy=nil;game.potionCombat.accuracyTurns=nil end
        require("src.potions").emit(game,"accuracy",timing and timing.forceMiss and "SA BẪY · ĐÁNH HỤT" or "ĐÁNH TRÚNG 100%",nil,target)
    end
    if attackEffects.guaranteeHit then roll={hitChance=1,missed=false} end
    if timing and timing.forceMiss then roll={hitChance=0,missed=true,timingMiss=true} end
    if require("src.human_bosses").rejectHand(game) then roll={hitChance=0,missed=true,humanOath=true} end
    if roll.missed then
        local sync=require("src.chest_expansion").sync
        for _,source in ipairs(attackEffects.afterstorms or {}) do
            for _,card in ipairs(source.cards) do
                sync(game,card,function(copy) Deck.applyAttackSpeedBonus(copy,2) end)
            end
            game.spnFeedback=game.spnFeedback or {}
            game.spnFeedback[#game.spnFeedback+1]={deity=source.deity,slot=source.slot,text="ĐÁNH HỤT · +2 TỐC VĨNH VIỄN"}
        end
        require("src.advanced_hands").resolve(game,false)
        return 0,false,{},roll
    end
    if timing then aura=math.floor(math.max(0,aura)*timing.multiplier+0.5) end
    local locked = {}
    for slot = 1, Deities.getMaxSlots(game) do locked[slot] = Boss.isSlotLocked(game, "spn", slot) end
    local bedExplosions=Combat.bedExplosions(game,aura,locked)
    if #bedExplosions>0 then target.hasBed=nil end
    local hpBefore=target.hp
    local spread=require("src.spn_elements").spread(game,aura,locked)
    local routedAura,portalHits=require("src.spn_convergence").route(game,spread and 0 or aura,locked)
    local damage=0
    if spread then
        portalHits={}
        for _,hit in ipairs(spread) do
            if hit.enemy==target then damage=Monster.takeDamage(target,hit.raw)
            else portalHits[#portalHits+1]=hit end
        end
    else damage=Monster.takeDamage(target, routedAura) end
    for _,hit in ipairs(portalHits) do hit.damage=Monster.takeDamage(hit.enemy,hit.raw) end
    local splashHits = Anomalies.playerAttack(game,aura,hpBefore,damage,locked)
    for _,hit in ipairs(portalHits) do splashHits[#splashHits+1]=hit end
    for _,source in ipairs(attackEffects.afterstorms or {}) do
        for _,enemy in ipairs(Group.members(game)) do
            if enemy~=target and enemy.hp>0 then
                local actual=Monster.takeDamage(enemy,aura)
                splashHits[#splashHits+1]={enemy=enemy,damage=actual,deity=source.deity,slotIndex=source.slot,afterstorm=true}
            end
        end
    end
    for _,explosion in ipairs(bedExplosions) do
        for _,enemy in ipairs(Group.members(game)) do
            if enemy.hp>0 then
                local actual=Monster.takeDamage(enemy,explosion.amount)
                splashHits[#splashHits+1]={enemy=enemy,damage=actual,deity=explosion.deity,slotIndex=explosion.slot,explosion=true}
            end
        end
    end
    for slot = 1, Deities.getMaxSlots(game) do
        require("src.spn_mimic").each(game,game.deities,slot,function(deity)
        if deity and deity.onAttack and not locked[slot] then
            local neighbors = {}
            local members = Group.members(game)
            for index, enemy in ipairs(members) do
                if enemy == target then
                    for _, adjacent in ipairs({index - 1, index + 1}) do
                        local neighbor = members[adjacent]
                        if neighbor and neighbor.hp > 0 then neighbors[#neighbors + 1] = neighbor end
                    end
                    break
                end
            end
            if #neighbors > 0 then
                local result = Deities.scaleEffect(deity, deity.onAttack())
                local amount = math.floor(math.max(0, aura) * (result.addSplashPct or 0) / 100)
                if amount > 0 then
                    local enemy = neighbors[require("src.rng").random(#neighbors)]
                    local actual = Monster.takeDamage(enemy, amount)
                    splashHits[#splashHits + 1] = {enemy=enemy, damage=actual, deity=deity, slotIndex=slot}
                end
            end
        end
        end,locked)
    end
    for _,hit in ipairs(require("src.advanced_hands").resolve(game)) do splashHits[#splashHits+1]=hit end
    require("src.soul_relics").reap(game)
    return damage, Group.alive(Group.members(game)) == 0, splashHits,roll
end

function Combat.getOutcome(game)
    if not game or not game.monster then return "continue" end
    if game.playerHp and game.playerHp <= 0 then require("src.human_bosses").finish(game);return "defeat" end
    if require("src.human_bosses").victory(game) then return "victory" end
    if Group.alive(Group.members(game))==0 then return "victory" end
    local noCards = #(game.hand or {}) + #(game.deck or {}) + #(game.discardPile or {}) == 0
    local handLimitIsFinal = game.monster.isBoss and game.monster.bossData
        and game.monster.bossData.debuffId == "the_needle" and Boss.passiveEnabled(game.monster)
    if game.handsRemaining and game.handsRemaining <= 0 and (noCards or handLimitIsFinal) then require("src.human_bosses").finish(game);return "defeat" end
    return "continue"
end

function Combat.getAverageAttackSpeed(cards,game,handInfo)
    if game then require("src.spn_basics").bind(game,cards or {}) end
    local total, count = 0, 0
    for _, card in ipairs(cards or {}) do
        total = total + Deck.peekCardAttackSpeed(card)
        count = count + 1
    end
    local bonus=0
    local advanced=game and game.advancedCombat or {}
    bonus=bonus+(advanced.speed or 0)+(handInfo and (advanced.nextSpeed or 0) or (advanced.currentSpeed or 0))
    return count > 0 and math.min(999,total/count+bonus) or 0
end

local function resolveOneAttack(game,playerSpeed,timing)
    local monster = game and game.monster
    if not monster or (monster.hp or 0) <= 0 then return nil end
    if require("src.spn_elements").frozen(game,monster) then
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true,frozen=true}
    end
    if Anomalies.sleep(game,monster) then
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true}
    end
    if not require("src.soul_relics").beforeAttack(game,monster) then
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true}
    end

    if not Boss.beforeAttack(game) then return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true} end
    local humanAction=require("src.human_bosses").action(game,monster)
    if humanAction then return humanAction end
    local inventoryAction=require("src.enemy_loadout").action(monster,game)
    if inventoryAction then return inventoryAction end
    local support=EnemyAbilities.support(game,monster)
    if support then return support end
    if EnemyAbilities.speed(monster)>(playerSpeed or game.lastPlayerAttackSpeed or 0) then
        require("src.spn_basics").armor(game,true)
    end
    if (game.potionCombat or {}).evasion then
        require("src.potions").emit(game,"evasion","NÉ ĐÒN ĐỊCH · 0 ST",nil,monster)
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,missed=true,hitChance=0,action="attack"}
    end
    local guaranteed=((monster.enemyInventory or {}).guaranteedAttacks or 0)>0
    local roll=guaranteed and {hitChance=1,missed=false} or accuracy(EnemyAbilities.speed(monster),playerSpeed or game.lastPlayerAttackSpeed)
    if roll.missed then
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,missed=true,hitChance=roll.hitChance,action="attack"}
    end
    local baseAttack = (monster.attack or 12)
    local attack = EnemyAbilities.attack(monster) + EnemyAbilities.attackBonus(game,monster)+require("src.enemy_loadout").attackBonus(monster)*require("src.free_human_bosses").attackFactor(monster)
    local bossState = Boss.state(monster)
    if bossState and Boss.passiveEnabled(monster) then attack=attack+(bossState.excess or 0)*Boss.config.gateAttackPerCard end
    local execution = Boss.key(monster)=="executioner" and Boss.passiveEnabled(monster)
        and (game.playerHp or 100)<(game.maxPlayerHp or 100)*Boss.config.executionThreshold
    if execution then attack=attack*Boss.config.executionMultiplier end
    attack=require("src.human_bosses").attack(game,monster,attack)
    execution=execution or require("src.human_bosses").number(monster)==6
    local incomingAttack=attack
    if timing and timing.reduction==1 then
        local armorBefore=game.playerArmor or game.playerShield or 0
        local reward=math.floor(incomingAttack*(timing.armorPct or 0))
        game.playerArmor=math.max(armorBefore,math.min(Abilities.config.armorCap,armorBefore+reward))
        game.playerShield=game.playerArmor
        local reflectedAttack=incomingAttack*(timing.reflectMultiplier or 0)
        local reflectedDamage=reflectedAttack>0 and require("src.monster").takeDamage(monster,reflectedAttack) or 0
        return {attack=incomingAttack,absorbed=0,damage=0,killedPlayer=false,blocked=true,parried=true,
            parryArmor=game.playerArmor-armorBefore,reflectedAttack=reflectedAttack,reflectedDamage=reflectedDamage,action="attack"}
    end
    attack=attack*(1-(timing and timing.reduction or 0))
    local phantomAbsorbed
    attack,phantomAbsorbed=require("src.spn_elements").absorb(game,attack)
    local armor = execution and 0 or (game.playerArmor or game.playerShield or 0)
    local pierce=attack*require("src.enemy_loadout").pierce(monster)
    local absorbed = math.min(armor, attack-pierce)
    armor = phantomAbsorbed>0 and attack==0 and armor or math.floor((armor - absorbed) * 0.5)
    local damage = attack - absorbed

    damage = require("src.spn_convergence").redirect(game,monster,damage)
    damage = Abilities.damageGuard(game, damage)
    game.playerArmor = execution and (game.playerArmor or game.playerShield or 0) or armor
    game.playerShield = game.playerArmor
    local hpBeforeDamage=game.playerHp or 100
    game.playerHp = math.max(0, hpBeforeDamage - damage)
    require("src.enemy_loadout").afterHit(monster,math.min(damage,hpBeforeDamage),attack)
    monster.attack = math.floor(baseAttack * 1.08 + 0.5)
    monster.armor = math.floor((monster.armor or 0) * 1.05 + 2)
    EnemyAbilities.afterAttack(game,monster,damage)
    require("src.chest_depth").enemyAttack(game,math.min(damage,hpBeforeDamage),absorbed)
    Anomalies.enemyAttack(game,monster,math.min(damage,hpBeforeDamage))
    require("src.potions").payBlood(game,hpBeforeDamage)

    for _, card in ipairs(game.hand or {}) do
        if card.enhancement == "enh_escort" or card.enhancement == "escort" then
            game.playerArmor = math.min(30, (game.playerArmor or 0) + Deck.ENHANCEMENTS.enh_escort.params.armor)
            game.playerShield = game.playerArmor
        end
    end

    return {
        attack = incomingAttack,
        absorbed = absorbed+phantomAbsorbed,
        phantomAbsorbed = phantomAbsorbed,
        damage = damage,
        killedPlayer = game.playerHp <= 0,
        playerSpeed = game.lastPlayerAttackSpeed or 0,
        monsterSpeed = EnemyAbilities.speed(monster),
        action="attack",hitChance=roll.hitChance,
    }
end

-- Each living enemy acts on its own side of the player's speed, exactly once.
function Combat.resolveMonsterAttack(game, phase, playerSpeed, attacker,timing)
    if not game or not game.monster then return nil end
    if (not attacker and phase~="after") or not game.enemyActionPhases then Combat.beginEnemyTurn(game,playerSpeed) end
    local target=game.monster
    local result
    for _,m in ipairs(Group.members(game)) do
        if (not attacker or m==attacker) and Combat.canEnemyAct(game,m,phase,playerSpeed) then
            game.monster=m
            local attack=resolveOneAttack(game,playerSpeed,attacker and timing or nil)
            if attack then
                game.enemyActed[m]=true
                require("src.human_bosses").afterAttack(game,m,attack)
                require("src.enemy_loadout").afterAction(m,attack.action,attack.blocked and not attack.parried)
                EnemyAbilities.finishAction(game,m,attack)
                if not result then result={attack=0,absorbed=0,damage=0,attackerCount=0,playerSpeed=game.lastPlayerAttackSpeed or 0,monsterSpeed=0} end
                result.attack=result.attack+attack.attack;result.absorbed=result.absorbed+attack.absorbed
                result.damage=result.damage+attack.damage;result.attackerCount=result.attackerCount+1
                result.monsterSpeed=math.max(result.monsterSpeed,EnemyAbilities.speed(m))
                result.killedPlayer=attack.killedPlayer
                result.blocked=attack.blocked
                result.parried=attack.parried
                result.parryArmor=attack.parryArmor
                result.reflectedAttack=attack.reflectedAttack
                result.reflectedDamage=attack.reflectedDamage
                result.missed=attack.missed;result.hitChance=attack.hitChance
                result.action=attack.action;result.target=attack.target;result.value=attack.value;result.label=attack.label
            end
            if (game.playerHp or 0)<=0 then break end
        end
    end
    game.monster=target
    return result
end

function Combat.drawCards(game, maxHandSize, prepareDraw, recycleDiscard)
    if not game then return 0 end
    game.deck = game.deck or {}
    game.discardPile = game.discardPile or {}
    game.hand = game.hand or {}

    if recycleDiscard and #game.deck == 0 and #game.discardPile > 0 then
        while #game.discardPile > 0 do
            table.insert(game.deck, table.remove(game.discardPile))
        end
        Deck.shuffle(game.deck)
    end

    local drawnCount = 0
    while #game.hand < Abilities.handSize(game, maxHandSize) and #game.deck > 0 do
        local card = table.remove(game.deck)
        card.selected = false
        drawnCount = drawnCount + 1
        if prepareDraw then prepareDraw(card, drawnCount) end
        table.insert(game.hand, card)
        require("src.spn_basics").bind(game,{card})
    end
    if Boss.passiveEnabled(game.monster) and (Boss.key(game.monster)=="faceless" or Boss.key(game.monster)=="the_fish") then
        for _,c in ipairs(game.hand) do c.faceDown=true end
    end
    return drawnCount
end

local function isFaction(game, id)
    return game.selectedFaction == id or game.selectedSuit == id
end

function Combat.start(game, monster, round)
    assert(game and monster, "Combat.start requires game state and monster")
    require("src.human_bosses").finish(game)
    game.round = round or 1
    game.monster = monster
    game.spnBasicArmorGranted=nil
    game.enemies=Group.build(monster)
    require("src.kingdom_bosses").start(game)
    require("src.free_human_bosses").start(game)
    game.enemyPoison=0;game.enemyFeedback=nil
    game.lastPlayerAttackSpeed=nil;game.enemyActed={};game.enemyActionPhases=nil
    game.spnCombat={};game.spnFeedback={}
    require("src.spn_enchantments").reset(game)
    game.spnAttack=nil
    game.potionCombat={};game.potionFeedback={};game.potionVictoryPending=nil
    local heal=require("src.shop").voucherParams("v_apothecary",game).heal
    local before=game.playerHp or 100
    if heal>0 and before>0 then
        require("src.player_health").heal(game,heal)
        if game.playerHp>before then require("src.potions").emit(game,"heal","DƯỢC SƯ · +"..(game.playerHp-before).." HP",game.playerHp-before) end
    end
    game.spnOpeningAttackUsed=nil
    for i,m in ipairs(game.enemies) do
        if i>1 then m.attackSpeed=require("src.monster").rollAttackSpeed(m.encounterCount)*(m.bloodDomainMultiplier or 1) end
        EnemyAbilities.start(m)
        require("src.enemy_loadout").start(m)
    end
    for _,m in ipairs(game.enemies) do EnemyAbilities.plan(game,m) end
    game.maxSelectableCards = nil
    game.abilityHand = nil
    game.advancedHand=nil;game.advancedCombat={gold=0,maxHp=0,speed=0};game.advancedFeedback=nil
    game.depthCombat = {values={}}
    Boss.start(game)
    require("src.human_bosses").start(game)
    game.handsRemaining = game.maxHands
    game.playerArmor = 0
    game.playerShield = 0
    game.discardsUsedInCombat = 0
    game.discardsRemaining = isFaction(game, "valoria") and (game.maxDiscards + 1) or game.maxDiscards
    game.martyrStacks = 0
    game.jHeartDiscardUsed = false
    game.playedHandsHistory = {}
    game.handsPlayedThisCombat = 0
    game.selectedIndices = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    -- Boss modifiers and deity round-start effects are intentionally combat
    -- scoped. Persistent limits such as maxHands/maxDiscards are never reset.
    if monster.isBoss and monster.bossData and monster.bossData.applyModifier then
        monster.bossData.applyModifier(game)
    end
    local maxSlots = Deities.getMaxSlots(game)
    for slot = 1, maxSlots do
        require("src.spn_mimic").each(game,game.deities,slot,function(deity)
        if deity and deity.onRoundStart then
            local result = Deities.scaleEffect(deity, deity.onRoundStart(game))
            game.playerArmor = math.min(Abilities.config.armorCap, game.playerArmor + (result and result.addArmor or 0))
            game.playerShield = game.playerArmor
            game.discardsRemaining = game.discardsRemaining + (result and result.addDiscards or 0)
            game.handsRemaining = game.handsRemaining + (result and result.addHands or 0)
            if result then
                local parts={}
                for _,p in ipairs({{"addArmor","GIÁP"},{"addDiscards","LƯỢT BỎ"},{"addHands","LƯỢT ĐÁNH"}}) do
                    if (result[p[1]] or 0)>0 then parts[#parts+1]="+"..result[p[1]].." "..p[2] end
                end
                if #parts>0 then game.spnFeedback[#game.spnFeedback+1]={deity=game.deities[slot],slot=slot,text="VÀO TRẬN · "..table.concat(parts," · ")} end
            end
        end
        end)
    end
    game.turnHandLimit = game.handsRemaining
    game.spnDiscardCap=game.discardsRemaining

    local slaughterChips = game.storedSlaughterChips or 0
    if slaughterChips > 0 then
        game.discardBuffs.chips = slaughterChips
        game.storedSlaughterChips = 0
    end

    game.bountySealClaimedThisCombat=false
    game.combatFlags = {
        vitalityGemUsed = false,
        holyRelicTriggered = false,
    }

    if not game.persistentDeck or #game.persistentDeck == 0 then
        game.persistentDeck = Deck.createStarterDeck(game.selectedFaction or game.selectedSuit or "aurelia")
    end
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck
    game.deck = {}
    for _, card in ipairs(game.persistentDeck) do
        table.insert(game.deck, Deck.cloneCard(card))
    end
    game.discardPile = {}
    game.hand = {}
    Deck.shuffle(game.deck)

    -- Anchor Seal (Ấn Neo): Prioritize cards with Anchor Seal to be dealt in the opening hand
    local anchors = {}
    local nonAnchors = {}
    for _, c in ipairs(game.deck) do
        if c.isAnchor or c.seal == "seal_anchor" or c.seal == "anchor" then
            table.insert(anchors, c)
        else
            table.insert(nonAnchors, c)
        end
    end
    if #anchors > 0 then
        game.deck = {}
        for _, c in ipairs(nonAnchors) do table.insert(game.deck, c) end
        for _, c in ipairs(anchors) do table.insert(game.deck, c) end -- popped first from the end
    end

    require("src.spn_pacts").prepare(game)
    require("src.spn_trials").prepare(game)
    Abilities.start(game)
    local maxHandSize = isFaction(game, "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    local dealOrder = 0
    local openingSize=math.max(#anchors,Abilities.handSize(game,maxHandSize))
    while #game.hand < openingSize and #game.deck > 0 do
        local card = table.remove(game.deck)
        dealOrder = dealOrder + 1
        card.selected = false
        card.visualX = 1180
        card.visualY = 620
        card.visualAngle = -0.12 + dealOrder * 0.025
        card.visualScale = 0.68
        card.dealPending = true
        card.dealDelay = (dealOrder - 1) * 0.075
        card.dealTrail = 0
        local isAxiomCard = not card.disableFactionPassives and (card.suit == "spades" or card.suit == "vharos" or card.suit == "iron_axiom")
        local bossData = monster.bossData
        if not isAxiomCard and monster.isBoss and bossData and (bossData.id == "the_fish" or bossData.debuffId == "the_fish") then
            card.faceDown = true
        end
        table.insert(game.hand, card)
    end

    if isFaction(game, "vharos") or isFaction(game, "spades") or isFaction(game, "iron_axiom") or game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end
    Abilities.handStart(game)
    require("src.spn_foundations").openingSpeed(game)
    require("src.human_bosses").opening(game)
    for _,enemy in ipairs(game.enemies) do EnemyAbilities.plan(game,enemy) end
    return { slaughterChips = slaughterChips }
end

-- Enemy plans advance here; held seals resolve once in the scoring calculation.
function Combat.onMonsterTurnEnd(game)
    if not game or not game.hand then return false end
    require("src.spn_elements").roundEnd(game)
    for _,m in ipairs(Group.members(game)) do
        if m.hp>0 and m.actionTurns~=nil then EnemyAbilities.plan(game,m) end
    end
    return false
end

-- End of turn lifecycle: recovers exhausted cards and checks persistent states
function Combat.onPlayerTurnEnd(game)
    if not game or not game.hand then return end
    require("src.potions").endTurn(game)
    for _, c in ipairs(game.hand) do
        if not c.destroyed and require("src.card_effects").getEffectName(c)=="gilded" then
            game.gold=(game.gold or 0)+3
        end
        if c.exhausted then
            if c.justExhausted then
                c.justExhausted = nil
            else
                c.exhausted = false
            end
        end
    end
end

-- Permadeath: Cleanly and permanently destroys cards marked with card.destroyed from combat & persistent deck
function Combat.cleanupDestroyedCards(game)
    if not game then return {} end
    local destroyedIds = {}
    local function filterDestroyed(tbl)
        if not tbl then return end
        for i = #tbl, 1, -1 do
            local c = tbl[i]
            if c and c.destroyed then
                Abilities.destroy(game, c)
                if c.id then
                    destroyedIds[c.id] = true
                    if tonumber(c.id) then destroyedIds[tonumber(c.id)] = true end
                    destroyedIds[tostring(c.id)] = true
                end
                table.remove(tbl, i)
            end
        end
    end

    filterDestroyed(game.hand)
    filterDestroyed(game.deck)
    filterDestroyed(game.discardPile)

    if game.persistentDeck then
        for i = #game.persistentDeck, 1, -1 do
            local pc = game.persistentDeck[i]
            local isDestroyed = pc and (pc.destroyed or (pc.id and (destroyedIds[pc.id] or (tonumber(pc.id) and destroyedIds[tonumber(pc.id)]) or destroyedIds[tostring(pc.id)])))
            if isDestroyed then
                require("src.souls").award(game, pc)
                table.remove(game.persistentDeck, i)
            end
        end
    end
    return destroyedIds
end

return Combat
