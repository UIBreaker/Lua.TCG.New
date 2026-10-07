local Data = require("config.card_ability_data")
local Boss = require("src.boss_abilities")
local A = { config=Data, definitions=Data.definitions, handlers={} }
local aliases={hearts="heart",valoria="heart",sanguine_covenant="heart",diamonds="diamond",aurelia="diamond",gilded_conclave="diamond",
    clubs="club",elaris="club",feral_swarm="club",spades="spade",vharos="spade",iron_axiom="spade"}
local ranks={[14]="ace",[1]="ace",[11]="jack",[12]="queen",[13]="king"}
function A.definition(card)
    if not card or not card.rank then return nil end
    return Data.definitions[(aliases[card.suit] or card.suit).."_"..(ranks[card.rank] or card.rank)]
end
function A.level(card) return math.max(0,(tonumber(card.evolutionLevel) or 0)+(tonumber(card.temporaryAbilityLevels) or 0)) end
function A.params(card, def, level)
    def=def or A.definition(card); if not def then return {} end
    level=level or A.level(card)
    local p={}
    for k,v in pairs(def.baseParams) do
        local r=def.evolutionRules[k]
        local gain=type(r)=="number" and r*level or type(r)=="table" and math.floor(level/r.every)*r.amount or 0
        p[k]=v+gain*((card.edition=="ancient" or card.visualEffect=="ancient") and 3 or 1)
    end
    return p
end
local effectParams={armor=true,heal=true,speed=true,bonus=true,charge=true,returnArmor=true,healPercent=true,gold=true,gain=true,maxStacks=true,
    capacity=true,draw=true,levels=true,repeats=true,returns=true,duration=true,hands=true,
    cancels=true,skip=true,block=true,copies=true,freeze=true,maxGold=true}
function A.effectiveParams(game,card,def,ctx)
    local p=A.params(card,def)
    local factor=1
    -- Use the live hand for held triggers and the pre-play snapshot for scoring.
    local hand=ctx and ctx.resonanceHand or game.hand or {}
    for i,c in ipairs(hand) do
        if c==card then
            for _,j in ipairs({i-1,i+1}) do
                local neighbor=hand[j]
                local held=true
                for _,played in ipairs(ctx and ctx.played or {}) do if played==neighbor then held=false end end
                if held and neighbor and not neighbor.destroyed and (neighbor.edition=="resonant" or neighbor.visualEffect=="resonant") then factor=factor+.2 end
            end
            break
        end
    end
    for key,value in pairs(p) do
        if effectParams[key] then
            local strength=ctx and ctx.effectiveness or 1
            -- Direct resource gains are scaled after activation, including stored gold/hearts.
            if key=="gold" or key=="armor" or key=="healPercent" then strength=1 end
            p[key]=value*factor*strength
        end
    end
    return p
end
local function number(n) return string.format("%g",n) end
function A.description(card, level)
    local d=A.definition(card); if not d then return "" end
    local p=A.params(card,d,level)
    return d.description:gsub("{([%w_]+)}",function(k) return number(p[k] or 0) end)
end
function A.runtime(card) card.abilityState=card.abilityState or {}; return card.abilityState end
local function stateCopy(card)
    local result={};for k,v in pairs(card and card.abilityState or {}) do result[k]=v end;return result
end
local function allCards(game)
    local list,seen={},{}
    for _,pile in ipairs({game.hand or {},game.deck or {},game.discardPile or {},game.abilityHand and game.abilityHand.played or {}}) do
        for _,c in ipairs(pile) do if not seen[c.id or c] then seen[c.id or c]=true; list[#list+1]=c end end
    end
    return list
end
function A.start(game)
    game.martyrStacks=0;game.storedSlaughterChips=0
    game.soulRelicCombat={used={},claimed={},freeze=0}
    game.abilityCombat={playIndex=0,handSizeBonus=0,pendingRepeat=0,lastDestroyed=nil,roundNumber=1,feedback={}}
    game.abilityHand=nil
    for _,c in ipairs(allCards(game)) do
        c.abilityState={};c.temporaryAbilityLevels=0;c.abilityDisabledUntil=nil;c.destroyed=nil;c.destructionNotified=nil
        c.disableFactionPassives=true;c.isWildSuit=false;c.isDualRankAce=false
    end
end
local function combat(game)
    if not game.abilityCombat then
        game.abilityCombat={playIndex=0,handSizeBonus=0,pendingRepeat=0,lastDestroyed=nil,roundNumber=1,feedback={}}
    end
    return game.abilityCombat
end
local function feedback(game, card, text, kind, source)
    local ctx=game.abilityHand and not game.abilityHand.finished and game.abilityHand or combat(game)
    ctx.feedback=ctx.feedback or {}
    ctx.feedback[#ctx.feedback+1]={type="card_ability",card=card,abilityId=A.definition(card) and A.definition(card).id,
        message=text,kind=kind or "ability",source=source,addedChips=0,addedMult=0}
end
function A.takeFeedback(game)
    local ctx=game.abilityHand and not game.abilityHand.finished and game.abilityHand or combat(game)
    local result=ctx.feedback or {}; ctx.feedback={}; return result
end
local function armor(game,n) game.playerArmor=math.min(Data.armorCap,(game.playerArmor or game.playerShield or 0)+n); game.playerShield=game.playerArmor end
local function heal(game,percent) game.playerHp=math.min(game.maxPlayerHp or 100,(game.playerHp or 100)+(game.maxPlayerHp or 100)*percent/100) end
local function gold(game,n) game.gold=(game.gold or 0)+n end
local function contains(list,c) for _,v in ipairs(list or {}) do if v==c then return true end end return false end
local function lowest(cards,except,suit)
    local result
    for _,c in ipairs(cards or {}) do
        if c~=except and not c.destroyed and (not suit or A.definition(c) and A.definition(c).suit==suit)
            and (not result or A.level(c)<A.level(result)) then result=c end
    end
    return result
end
function A.upgrade(game,card,levels,temporary)
    if not A.definition(card) then return false end
    local previous=A.level(card)
    if temporary then card.temporaryAbilityLevels=(card.temporaryAbilityLevels or 0)+levels
    else
        local level=math.max(0,math.min(Data.maxEvolutionLevel,(card.evolutionLevel or 0)+levels))
        card.evolutionLevel=level
        for _,pile in ipairs({game.persistentDeck or {},game.hand or {},game.deck or {},game.discardPile or {}}) do
            for _,copy in ipairs(pile) do if copy.id==card.id then copy.evolutionLevel=level end end
        end
    end
    if A.level(card)>previous then
        A.dispatch(game,"upgraded",{card},{})
        feedback(game,card,(card.rankName or "")..(card.suitSymbol or "").." · CẤP KHẢ NĂNG +"..levels,"evolution")
    end
    return A.level(card)~=previous
end
function A.evolve(game,card)
    if (card.evolutionLevel or 0)>=Data.maxEvolutionLevel then return false end
    return A.upgrade(game,card,1,false)
end
function A.handSize(game,base)
    local bonus=combat(game).handSizeBonus or 0
    for i,c in ipairs(game.hand or {}) do
        if not c.destroyed and not Boss.isAbilityDisabled(game,c) then
            local d=A.definition(c); local p=d and A.params(c,d)
            if d and d.op=="capacity" then bonus=bonus+p.capacity
            elseif d and d.op=="full_consumables" and #(game.consumables or {})>=(game.maxConsumables or 3) then bonus=bonus+p.capacity
            elseif d and d.op=="copy_held" then
                for offset=1,p.range do
                    local source=game.hand[i-offset]; local sd=A.definition(source)
                    if sd and sd.rank~=11 and not Boss.isAbilityDisabled(game,source) then
                        local sp=A.params(source,sd)
                        if sd.op=="capacity" or sd.op=="full_consumables" and #(game.consumables or {})>=(game.maxConsumables or 3) then bonus=bonus+sp.capacity end
                    end
                end
            end
        end
    end
    return math.max(1,(base or game.maxHandSize or 3)+bonus)
end
function A.handStart(game)
    -- Hand start is after drawing/sorting, never every frame or every discard.
    A.dispatch(game,"hand_start",game.hand or {},{full=#(game.hand or {})>=A.handSize(game)})
    Boss.handStart(game)
end
function A.beginHand(game, handInfo, played, decisions)
    local ctx={game=game,handInfo=handInfo,scoring=handInfo.scoringCards,played=played,
        active={},full=#(game.hand or {})>=A.handSize(game),play=combat(game).playIndex+1,
        queue={},cursor=0,repeats={},triggerCount=0,feedback={},spnSeen={},spnCount=0,
        returns={},scored={},decisions=decisions or {},copyDepth=0,visited={},once={},depth=0,echoSeen={},resonanceHand={}}
    for _,c in ipairs(game.hand or {}) do ctx.resonanceHand[#ctx.resonanceHand+1]=c end
    for _,c in ipairs(game.hand or {}) do ctx.active[#ctx.active+1]=c end
    game.abilityHand=ctx
    for i,c in ipairs(ctx.scoring) do ctx.queue[#ctx.queue+1]={card=c,index=i,depth=0} end
    for _,c in ipairs(game.hand or {}) do
        local d=A.definition(c)
        if d and d.op=="copy_held" then local i;for n,v in ipairs(game.hand) do if v==c then i=n end end
            local sources={};for off=1,A.params(c).range do local source=game.hand[i-off];local sd=A.definition(source);if sd and sd.rank~=11 then sources[#sources+1]=source end end
            A.runtime(c).heldSources=sources
        end
    end
    combat(game).playIndex=ctx.play
    A.applyDecisions(game,"before")
    A.dispatch(game,"before_score",ctx.scoring,ctx)
    A.dispatch(game,"not_scored",handInfo.unscoredCards or {},ctx)
    local repeatCount=combat(game).pendingRepeat or 0
    combat(game).pendingRepeat=0
    if repeatCount>0 then A.repeatCard(game,ctx.scoring[1],repeatCount,ctx) end
    return ctx
end
function A.repeatCard(game,card,count,ctx,effectiveness)
    ctx=ctx or game.abilityHand
    if not ctx or not card or card.destroyed and not contains(ctx.scored,card) then return end
    local depth=(ctx.depth or 0)+1
    if depth>Data.maxRetriggerDepth then return end
    local idx; for i,c in ipairs(ctx.scoring) do if c==card then idx=i; break end end
    if not idx then return end
    for _=1,count do
        local used=ctx.repeats[card.id] or 0
        if used>=Data.maxRetriggersPerCard or #ctx.queue>=Data.maxTriggersPerHand then break end
        ctx.repeats[card.id]=used+1
        ctx.queue[#ctx.queue+1]={card=card,index=idx,depth=depth,retrigger=true,effectiveness=effectiveness}
    end
end
function A.nextScore(game)
    local ctx=game.abilityHand; ctx.cursor=ctx.cursor+1
    local job=ctx.queue[ctx.cursor]
    if job then ctx.depth=job.depth; ctx.retrigger=job.retrigger; ctx.current=job.card; ctx.index=job.index;ctx.effectiveness=job.effectiveness end
    return job
end
function A.score(game,card)
    local ctx=game.abilityHand
    local before=stateCopy(card)
    local resources={gold=game.gold or 0,playerHp=game.playerHp or 100,playerArmor=game.playerArmor or 0}
    require("src.soul_relics").score(game,card,ctx)
    if Boss.key(game.monster)=="taxman" and Boss.passiveEnabled(game.monster) then
        if (game.gold or 0)>=Boss.config.taxCardCost then game.gold=game.gold-Boss.config.taxCardCost else game.playerHp=math.max(0,(game.playerHp or 100)-Boss.config.taxCardHp) end
    end
    if not ctx.retrigger or Boss.allowRetriggerAbility(game,card) then A.dispatch(game,"score",{card},ctx) end
    if ctx.effectiveness and ctx.effectiveness~=1 then
        for key,value in pairs(resources) do
            if (game[key] or value)>value then game[key]=value+(game[key]-value)*ctx.effectiveness end
        end
        game.playerShield=game.playerArmor
    end
    if not ctx.retrigger then ctx.scored[#ctx.scored+1]=card; ctx.previous=card;ctx.previousAbilityState=before end
    if (card.edition=="echo" or card.visualEffect=="echo") and not ctx.echoSeen[card] then
        ctx.echoSeen[card]=true
        A.repeatCard(game,card,1,ctx,1)
    end
    if card.destroyed then A.destroy(game,card,ctx) end
end
function A.destroy(game,card,ctx)
    if not card or card.destructionNotified then return false end
    card.destroyed=true; card.destructionNotified=true
    if card.edition=="void" or card.visualEffect=="void" then
        local d=A.definition(card)
        local x=ctx or game.abilityHand or {game=game,handInfo={type={id="high_card"}},
            scoring={},scored={},played={},active={},queue={},returns={},repeats={},
            cursor=0,depth=0,play=combat(game).playIndex,spnCount=0,damage=0,full=false}
        if d and A.handlers[d.op] and d.trigger~="choice" then
            local oldEvent,oldOnce,oldEffect=x.event,x.once,x.effectiveness
            x.event=d.trigger;x.effectiveness=1
            for _=1,10 do
                x.once={}
                A.handlers[d.op](game,card,A.effectiveParams(game,card,d,x),x)
            end
            x.event,x.once,x.effectiveness=oldEvent,oldOnce,oldEffect
            feedback(game,card,"HƯ KHÔNG · KÍCH HOẠT 10 LẦN", "edition")
        elseif d and d.trigger=="choice" and game.abilityHand==x then
            -- Reuse an approved target/cost; never invent a sacrifice or spend without a decision.
            local decisions=x.decisions
            for _,decision in ipairs(decisions or {}) do
                if decision.card==card and decision.applied then
                    local final={};for key,value in pairs(decision) do final[key]=value end
                    final.applied=false;x.decisions={final}
                    for _=1,10 do
                        final.applied=false
                        A.applyDecisions(game,(d.op=="pair_sacrifice" or d.op=="five_sacrifice") and "after" or "before",card)
                    end
                    x.decisions=decisions
                    break
                end
            end
        end
    end
    local souls = require("src.souls").award(game, card)
    A.dispatch(game,"destroyed",{card},ctx or game.abilityHand or {})
    combat(game).lastDestroyed=card
    feedback(game,card,"TIÊU HỦY · "..(card.rankName or "")..(card.suitSymbol or "")..(souls>0 and (" · +"..souls.." LH") or ""),"destroy")
    return true
end
function A.resolveBossDamage(game)
    local bs=Boss.state(game.monster)
    if bs and (bs.pendingDamage or 0)>0 then
        local damage=bs.pendingDamage;bs.pendingDamage=0
        local absorbed=math.min(game.playerArmor or 0,damage)
        game.playerArmor=math.max(0,(game.playerArmor or 0)-absorbed);game.playerShield=game.playerArmor
        damage=A.damageGuard(game,damage-absorbed)
        game.playerHp=math.max(0,(game.playerHp or 100)-damage)
        feedback(game,nil,"BOSS · -"..damage.." HP", "boss")
    end
end

function A.finishHand(game)
    local ctx=game.abilityHand; if not ctx or ctx.finished then return end
    ctx.finished=true
    A.applyDecisions(game,"after")
    -- Returned instances leave the discard pile; they are never duplicated.
    for _,card in ipairs(ctx.scoring) do
        if ctx.returns[card.id] and not card.destroyed then
            armor(game,ctx.returnArmor and ctx.returnArmor[card.id] or 0)
            for i=#(game.discardPile or {}),1,-1 do if game.discardPile[i].id==card.id then table.remove(game.discardPile,i) end end
            if not contains(game.hand,card) then game.hand[#game.hand+1]=card end
        end
    end
    local held={}
    for _,c in ipairs(game.hand or {}) do if not contains(ctx.played,c) then held[#held+1]=c end end
    A.dispatch(game,"hand_end",held,ctx)
    require("src.playing_card_tactics").hold(game,held)
    combat(game).tacticDiscarded=nil
    combat(game).previousHandType=ctx.handInfo.type.id
    Boss.handEnd(game)
    A.resolveBossDamage(game)
    require("src.enemy_abilities").handEnd(game)
end
function A.roundEnd(game)
    local ctx={unusedDiscards=game.discardsRemaining or 0}
    A.dispatch(game,"round_end",allCards(game),ctx)
    combat(game).roundNumber=(combat(game).roundNumber or 1)+1
end
function A.roundStart(game)
    for _,c in ipairs(allCards(game)) do A.runtime(c).guardUsed=nil; A.runtime(c).fullGoldUsed=nil end
end
function A.combatWin(game)
    if combat(game).won then return end
    combat(game).won=true
    A.roundEnd(game)
    local ctx={goldBeforeInterest=game.gold or 0}
    A.dispatch(game,"combat_win",allCards(game),ctx)
end
function A.discard(game,cards)
    if #(cards or {})>0 then combat(game).tacticDiscarded=true end
    require("src.chest_depth").discard(game,cards)
    A.dispatch(game,"discard",cards,{})
    local x=game.abilityHand
    if x and not x.finished then for i=#x.active,1,-1 do if contains(cards,x.active[i]) then table.remove(x.active,i) end end end
end
function A.consumableUsed(game)
    A.dispatch(game,"consumable",game.hand or {},{})
end
function A.damageGuard(game,damage)
    local ctx={damage=damage}
    A.dispatch(game,"damage",game.abilityHand and game.abilityHand.active or game.hand or {},ctx)
    return require("src.spn_anomalies").guard(game,require("src.soul_relics").guard(game,ctx.damage))
end
function A.spnTriggered(game,slot)
    local ctx=game.abilityHand; if not ctx then return 0 end
    if not ctx.spnSeen[slot] then ctx.spnSeen[slot]=true; ctx.spnCount=ctx.spnCount+1 end
    ctx.spnRepeats=0
    A.dispatch(game,"spn",ctx.active,ctx)
    return math.min(Data.maxRetriggersPerCard,ctx.spnRepeats)
end
function A.dispatch(game,event,cards,ctx)
    ctx=ctx or {}; ctx.game=game
    for _,card in ipairs(cards or {}) do
        local d=A.definition(card)
        local eventMatch=d and (d.trigger==event or (event=="score" or event=="not_scored") and (d.op=="heart_store" or d.op=="gold_store")
            or d.op=="copy_held" and (event=="hand_start" or event=="hand_end" or event=="consumable" or event=="damage" or event=="score"))
        if eventMatch and (event=="destroyed" or not card.destroyed) and not Boss.isAbilityDisabled(game,card) then
            local hand=game.abilityHand and not game.abilityHand.finished and game.abilityHand
            if not hand or hand.triggerCount<Data.maxTriggersPerHand then
                if hand then hand.triggerCount=hand.triggerCount+1 end
                local handler=A.handlers[d.op]
                if handler then
                    ctx.event=event
                    local before=stateCopy(card)
                    local fired=handler(game,card,A.effectiveParams(game,card,d,ctx),ctx)
                    if fired then
                        feedback(game,card,d.name,"ability")
                        if d.suit=="diamond" and d.rank~=11 then combat(game).lastDiamond={card=card,definition=d,event=event,abilityState=event=="score" and before or stateCopy(card)} end
                    end
                end
            end
        end
    end
end
local H=A.handlers
H.tactic=require("src.playing_card_tactics").apply
local function suits(ctx) local seen,n={},0; for _,c in ipairs(ctx.scoring or {}) do local d=A.definition(c); local s=d and d.suit or c.suit; if not seen[s] then seen[s]=true;n=n+1 end end return n end
local function once(ctx,c,key) ctx.once=ctx.once or {}; key=(c.id or tostring(c))..":"..key..((ctx.copyDepth or 0)>0 and (":copy"..(ctx.copyIteration or 1)) or ""); if ctx.once[key] then return false end; ctx.once[key]=true; return true end
H.capacity=function() return true end
H.full_consumables=function(g,c,p) return #(g.consumables or {})>=(g.maxConsumables or 3) end
H.copy_held=function(g,c,p,x)
    local sources={};local index
    for i,v in ipairs(g.hand or {}) do if v==c then index=i end end
    if index then
        for offset=1,p.range do local source=g.hand[index-offset];local d=A.definition(source)
            if d and d.rank~=11 then sources[#sources+1]=source end
        end
        A.runtime(c).heldSources=sources
    else sources=A.runtime(c).heldSources or {} end
    local fired=false
    for _,source in ipairs(sources) do
        local d=A.definition(source)
        if d and (d.trigger==x.event or x.event=="score" and (d.op=="heart_store" or d.op=="gold_store")) then
            fired=A.handlers[d.op](g,c,A.params(source,d),x) or fired
        end
    end
    return fired
end
H.return_other=function(g,c,p,x) if #x.scoring==p.count then local n=0; for _,o in ipairs(x.scoring) do if o~=c and n<p.returns then x.returns[o.id]=true;x.returnArmor=x.returnArmor or {};x.returnArmor[o.id]=(x.returnArmor[o.id] or 0)+p.returnArmor;n=n+1 end end return n>0 end end
H.return_lowest=function(g,c,p,x) if #x.scoring~=p.count then return end; local list={}; for _,o in ipairs(x.scoring) do list[#list+1]=o end; for _=1,p.returns do local o=lowest(list); if o then x.returns[o.id]=true;x.returnArmor=x.returnArmor or {};x.returnArmor[o.id]=(x.returnArmor[o.id] or 0)+(p.returnArmor or 0); for i,v in ipairs(list) do if v==o then table.remove(list,i);break end end end end return true end
H.third_draw=function(g,c,p,x) if x.play==p.play then armor(g,p.armor); A.draw(g,p.draw); return true end end
H.suits_armor=function(g,c,p,x) if suits(x)>=p.suits then armor(g,p.armor);return true end end
H.discard_armor=function(g,c,p,x) local n=math.min(p.discards,g.discardsRemaining or 0); if n>0 then g.discardsRemaining=g.discardsRemaining-n;armor(g,p.armor*n);return true end end
H.guard=function(g,c,p,x) local r=A.runtime(c); if x.damage>0 and not r.guardUsed and (g.gold or 0)>=p.threshold then r.guardUsed=true;gold(g,-p.cost);x.damage=math.max(0,x.damage-p.block);return true end end
H.spn_armor=function(g,c,p) local n=0; for _,d in pairs(g.deities or {}) do if type(d)=="table" then n=n+1 end end; if n>0 then armor(g,n*p.armor);return true end end
H.growth=function(g,c,p) local r=A.runtime(c); if not r.growthUsed then r.growthUsed=true;combat(g).handSizeBonus=combat(g).handSizeBonus+p.capacity;return true end end
H.heart_store=function(g,c,p,x) local r=A.runtime(c); if x.event=="score" or x.event=="not_scored" then if (r.hearts or 0)>0 then heal(g,r.hearts*p.healPercent);r.hearts=0;return true end else r.hearts=math.min(p.maxStacks,(r.hearts or 0)+p.gain);return true end end
H.gold_store=function(g,c,p,x) local r=A.runtime(c); if x.event=="score" or x.event=="not_scored" then if (r.savings or 0)>0 then gold(g,r.savings);r.savings=0;return true end else r.savings=math.min(p.maxStacks,(r.savings or 0)+p.gain);return true end end
H.death_heal=function(g,c,p) heal(g,p.healPercent);armor(g,p.armor);return true end
H.full_gold=function(g,c,p,x) local r=A.runtime(c); if x.full and not r.fullGoldUsed then r.fullGoldUsed=true;gold(g,p.gold);return true end end
H.pair_gold=function(g,c,p,x) if #x.scoring==p.count then gold(g,p.gold);return true end end
H.third_gold=function(g,c,p,x) if x.play==p.play then gold(g,p.gold);return true end end
H.suits_gold=function(g,c,p,x) if suits(x)>=p.suits then gold(g,p.gold);return true end end
H.invest_lowest=function(g,c,p,x) if #x.scoring==p.count and once(x,c,"invest") then local o=lowest(x.scoring);if o then A.upgrade(g,o,p.levels,true);return true end end end
H.discard_gold=function(g,c,p,x) local n=math.min(p.maxGold,(x.unusedDiscards or 0)*p.gold);if n>0 then gold(g,n);return true end end
H.interest=function(g,c,p,x) local n=math.min(p.maxGold,math.floor((x.goldBeforeInterest or g.gold or 0)/p.divisor)*p.gold);if n>0 then gold(g,n);return true end end
H.commission=function(g,c,p,x) if x.spnCount>=p.required and once(x,c,"commission") then gold(g,p.gold);return true end end
H.refund=function(g,c,p) local r=A.runtime(c);local turn=Boss.state(g.monster) and Boss.state(g.monster).handIndex or combat(g).playIndex; if r.refundHand~=turn then r.refundHand=turn;gold(g,p.gold);return true end end
H.death_gold=function(g,c,p) gold(g,p.gold); local o=lowest(allCards(g),c,"diamond");if o then A.upgrade(g,o,p.levels,true) end;return true end
local function repeatOnce(g,c,p,x,targets,key)
    if x.retrigger or not once(x,c,key) then return end
    for _,t in ipairs(targets) do A.repeatCard(g,t,p.repeats,x) end
    return #targets>0
end
H.full_repeat=function(g,c,p,x) if x.full then return repeatOnce(g,c,p,x,{x.scoring[1]},"full") end end
H.pair_repeat=function(g,c,p,x) if x.handInfo.type.id=="pair" then local other=lowest(x.scoring,c);if other then return repeatOnce(g,c,p,x,{other},"pair") end end end
H.third_repeat=function(g,c,p,x) if x.play==p.play then return repeatOnce(g,c,p,x,{x.scoring[#x.scoring]},"third") end end
H.suits_repeat=function(g,c,p,x) if suits(x)<p.suits then return end;local seen,list={},{};for _,o in ipairs(x.scoring) do local s=A.definition(o).suit;if not seen[s] then seen[s]=true;list[#list+1]=o end end;return repeatOnce(g,c,p,x,list,"suits") end
H.ends_repeat=function(g,c,p,x) if #x.scoring==p.count then return repeatOnce(g,c,p,x,{x.scoring[1],x.scoring[#x.scoring]},"ends") end end
H.prime_repeat=function(g,c,p) combat(g).pendingRepeat=combat(g).pendingRepeat+p.repeats;return true end
H.spn_repeat=function(g,c,p,x) if x.spnCount==1 and once(x,c,"spn") then x.spnRepeats=x.spnRepeats+p.repeats;return true end end
H.cons_repeat=H.prime_repeat
H.higher_repeat=function(g,c,p,x) for _,o in ipairs(x.scoring) do if A.level(o)>A.level(c) then return repeatOnce(g,c,p,x,{c},"higher") end end end
H.miss_repeat=function(g,c,p,x) A.repeatCard(g,x.scoring[1],p.repeats,x);return true end
H.death_repeat=function(g,c,p,x) if x.scored and not x.finished then return repeatOnce(g,c,p,x,x.scored,"death") end end
H.third_cancel=function(g,c,p,x) if x.play==p.play then Boss.counter(g,"cancelNextActive",p.cancels);return true end end
H.suits_disable=function(g,c,p,x) if suits(x)>=p.suits then Boss.disable(g,p.duration);return true end end
H.delay=function(g,c,p) Boss.counter(g,"delayNextAction",p.duration);return true end
H.miss_cancel=function(g,c,p) Boss.counter(g,"cancelNextActive",p.cancels);return true end
H.death_lock=function(g,c,p) Boss.counter(g,"skipNextAction",p.skip);Boss.disable(g,p.duration,false,true);return true end
local function copy(g,c,p,x,source,definition,event,sourceState)
    local d=definition or A.definition(source)
    if not d or d.rank==11 or d.trigger=="choice" or d.trigger=="held" then return end
    if (x.copyDepth or 0)>=Data.maxCopyDepth or x.visited and x.visited[d.id] then return end
    x.visited=x.visited or {};x.visited[d.id]=true;x.copyDepth=(x.copyDepth or 0)+1
    local previousEvent=x.event;x.event=(d.op=="heart_store" or d.op=="gold_store") and "score" or event or d.trigger
    local fired=false;local ownState=c.abilityState;local oldIteration=x.copyIteration
    for iteration=1,p.copies do
        if x.triggerCount and x.triggerCount>=Data.maxTriggersPerHand then break end
        if x.triggerCount then x.triggerCount=x.triggerCount+1 end
        x.copyIteration=iteration
        if sourceState then c.abilityState={};for k,v in pairs(sourceState) do c.abilityState[k]=v end end
        fired=A.handlers[d.op](g,c,A.params(source,d),x) or fired
    end
    c.abilityState=ownState;x.copyIteration=oldIteration
    x.event=previousEvent;x.copyDepth=x.copyDepth-1;x.visited[d.id]=nil
    if fired then feedback(g,c,"ÉCHO · "..d.name,"copy",source) end
    return fired
end
H.copy_diamond=function(g,c,p,x) local last=combat(g).lastDiamond;if last then return copy(g,c,p,x,last.card,last.definition,last.event,last.abilityState) end end
H.copy_previous=function(g,c,p,x) return copy(g,c,p,x,x.previous,nil,nil,x.previousAbilityState) end
H.copy_destroyed=function(g,c,p,x) return copy(g,c,p,x,combat(g).lastDestroyed) end
function A.draw(game,count,full)
    game.hand=game.hand or {};game.deck=game.deck or {}
    local limit=full and A.handSize(game) or #game.hand+count
    while #game.hand<limit and #game.deck>0 do
        local c=table.remove(game.deck);c.selected=false;c.dealPending=true;c.visualX=1180;c.visualY=620
        game.hand[#game.hand+1]=c
    end
end
-- Optional costs are collected before scoring and explicitly approved, never picked randomly.
function A.choices(game,handInfo,played)
    local choices={};local candidates={}
    for _,c in ipairs(played) do candidates[#candidates+1]=c end
    for _,c in ipairs(game.hand or {}) do if not contains(played,c) and A.definition(c) and A.definition(c).op=="consume_cancel" then candidates[#candidates+1]=c end end
    local previousDiamond=combat(game).lastDiamond and combat(game).lastDiamond.card
    local previousScore
    for _,c in ipairs(candidates) do
        local own=A.definition(c);local source
        if contains(handInfo.scoringCards,c) and own then
            if own.op=="copy_diamond" then source=previousDiamond
            elseif own.op=="copy_previous" then source=previousScore
            elseif own.op=="copy_destroyed" then source=combat(game).lastDestroyed end
        end
        local copied=A.definition(source)
        local d=copied and copied.rank~=11 and copied.trigger=="choice" and copied or own
        local p=d and A.params(source or c,d)
        if source and d==copied then
            local n=A.params(c).copies
            for _,key in ipairs({"cost","levels","repeats","duration","hands","cancels"}) do if p[key] then p[key]=p[key]*n end end
        end
        if contains(handInfo.scoringCards,c) then previousScore=c;if own and own.suit=="diamond" and own.rank~=11 then previousDiamond=c end end
        if d and d.trigger=="choice" and not Boss.isAbilityDisabled(game,c) then
            local scoring=contains(handInfo.scoringCards,c); local op=d.op;local options
            if (op=="paid_invest" or op=="paid_repeat") and scoring and (game.gold or 0)>=(p.threshold or p.cost) then options={{label="Đồng ý",target=lowest(handInfo.scoringCards)}}
            elseif op=="pair_sacrifice" and scoring and handInfo.type.id=="pair" then options={};for _,o in ipairs(handInfo.scoringCards) do options[#options+1]={label="Tiêu hủy "..o.rankName..o.suitSymbol,target=o} end
            elseif op=="five_sacrifice" and scoring and #handInfo.scoringCards==p.count then options={};for _,o in ipairs(handInfo.scoringCards) do options[#options+1]={label="Tiêu hủy "..o.rankName..o.suitSymbol,target=o} end
            elseif op=="transfer" and scoring and (c.evolutionLevel or 0)>=p.costLevels then options={};for _,o in ipairs(handInfo.scoringCards) do if o~=c then options[#options+1]={label="Nâng "..o.rankName..o.suitSymbol,target=o} end end
            elseif op=="burn_refill" then options={{label="Tiêu hủy lá này",target=c}}
            elseif op=="bribe" and Boss.state(game.monster) and not A.runtime(c).bribeUsed and (game.gold or 0)>=p.cost then options={{label="Trả Vàng",target=c}}
            elseif op=="burn_lock" and Boss.state(game.monster) then local n=0;for _,v in pairs(game.deities or {}) do if type(v)=="table" then n=n+1 end end;if n>=p.required then options={{label="Tiêu hủy lá này",target=c}} end
            elseif op=="consume_cancel" and not contains(played,c) and Boss.state(game.monster) then options={};for _,v in ipairs(game.consumables or {}) do options[#options+1]={label="Tiêu hủy "..v.name,target=v} end end
            if options and #options>0 then
                local description=source and ("SAO CHÉP · "..d.description:gsub("{([%w_]+)}",function(k) return tostring(p[k] or 0) end).." Chi phí được trả riêng, chỉ khi đồng ý.") or A.description(c)
                choices[#choices+1]={card=c,definition=d,params=p,options=options,title=d.name,description=description,copySource=source}
            end
        end
    end
    return choices
end
function A.applyDecisions(game,stage,finalCard)
    local ctx=game.abilityHand
    for _,decision in ipairs(ctx and ctx.decisions or {}) do
        local d,p,c,t=decision.definition,decision.params,decision.card,decision.target
        local after=d.op=="pair_sacrifice" or d.op=="five_sacrifice"
        if not decision.applied and (after and stage=="after" or not after and stage=="before") and (not c.destroyed or c==finalCard) and (not after or t and not t.destroyed) then
            decision.applied=true; local op=d.op;local success=true
            if op=="paid_invest" or op=="paid_repeat" or op=="bribe" then
                if (game.gold or 0)<p.cost then success=false else gold(game,-p.cost)
                    if op=="paid_invest" then A.upgrade(game,t,p.levels,true)
                    elseif op=="paid_repeat" then A.repeatCard(game,c,p.repeats,ctx)
                    else A.runtime(c).bribeUsed=true;Boss.disable(game,p.duration) end
                end
            elseif op=="transfer" then
                if (c.evolutionLevel or 0)<p.costLevels then success=false else A.upgrade(game,c,-p.costLevels,false);A.upgrade(game,t,p.levels,true) end
            elseif op=="pair_sacrifice" then A.destroy(game,t,ctx);local o=lowest(ctx.scoring,t);if o then A.upgrade(game,o,p.levels,false) end
            elseif op=="five_sacrifice" then A.destroy(game,t,ctx);game.handsRemaining=(game.handsRemaining or 0)+p.hands
            elseif op=="burn_refill" then A.destroy(game,c,ctx);Boss.disable(game,p.duration);ctx.refill=true
            elseif op=="burn_lock" then A.destroy(game,c,ctx);Boss.disable(game,p.duration,true)
            elseif op=="consume_cancel" then for i,v in ipairs(game.consumables or {}) do if v==t then table.remove(game.consumables,i);break end end;Boss.counter(game,"cancelNextActive",p.cancels) end
            if success then feedback(game,c,d.name,decision.copySource and "copy" or "choice",decision.copySource) end
        end
    end
    if stage=="after" and ctx.refill then A.draw(game,0,true) end
end
return A
