local Game=require("src.game_state")
local Deck=require("src.deck")
local E=require("src.equipment")
local D=require("src.deities")
local A=require("src.card_abilities")
local R=require("src.soul_relics")
local FX=require("src.card_effects")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local function fixture(id,power)
    local g=Game.new();local c=Deck.newCard(8,"hearts");c.disableFactionPassives=true
    c.equipments={E.instance(id,power==5 and {bloodPower=5} or power==10 and {voidPower=10} or {})}
    g.persistentDeck={Deck.cloneCard(c)};g.hand={c};g.deck={};g.discardPile={}
    g.monster={hp=100000,maxHp=100000,attack=10,attackSpeed=1,armor=0};g.enemies={g.monster}
    A.start(g);return g,c
end
local function score(g,c,others,index)
    local cards={c};for _,other in ipairs(others or {}) do cards[#cards+1]=other end
    local ctx=A.beginHand(g,{type=Poker.HAND_TYPES.HIGH_CARD,scoringCards=cards,unscoredCards={}},cards)
    ctx.index=index or 1;R.score(g,c,ctx);return ctx
end
for _,power in ipairs({1,5,10}) do
    local g,c=fixture("soul_frost_bell",power);score(g,c);assert(g.soulRelicCombat.freeze==2*power)
    local x,y=Deck.newCard(2,"diamonds"),Deck.newCard(4,"clubs")
    g,c=fixture("soul_rift_compass",power)
    for _=1,15 do g.deck[#g.deck+1]=Deck.newCard(3,"clubs") end
    score(g,c);assert(#g.deck==15-power and #g.hand==1+power)
    g,c=fixture("soul_return_chain",power);local ctx=score(g,c,{x,y})
    local count=0;for _ in pairs(ctx.returns) do count=count+1 end;assert(count==math.min(power,3))
    g,c=fixture("soul_echo_mirror",power)
    local cards={x,c,y};ctx=A.beginHand(g,{type=Poker.HAND_TYPES.HIGH_CARD,scoringCards=cards,unscoredCards={}},cards);ctx.index=2
    R.score(g,c,ctx);assert(ctx.repeats[x.id]==2*power and ctx.repeats[y.id]==2*power,"echo power "..power..": "..tostring(ctx.repeats[x.id]).."/"..tostring(ctx.repeats[y.id]))
    g,c=fixture("soul_evolution_quill",power);x=Deck.newCard(2,"diamonds");g.persistentDeck[2]=x
    score(g,c,{Deck.cloneCard(x)});assert(x.evolutionLevel==math.min(power,A.config.maxEvolutionLevel))
    g,c=fixture("soul_silence_anchor",power);g.monster.isBoss=true;g.monster.bossData={id="the_water",debuffId="the_water"}
    require("src.boss_abilities").start(g);score(g,c)
    local bs=require("src.boss_abilities").state(g.monster);assert(bs.activeUntil-bs.handIndex==2*power)
    g,c=fixture("soul_plague_chalice",power);score(g,c)
    assert(g.monster.soulPoisonTurns==3*power);R.beforeAttack(g,g.monster)
    assert(g.monster.hp==100000-math.floor(100000*.08*power))
    g,c=fixture("soul_reaper_contract",power);score(g,c);g.monster.hp=0;R.reap(g);assert(g.souls==3*power);R.reap(g);assert(g.souls==3*power)
    g,c=fixture("soul_phoenix_lantern",power)
    for _=1,power do g.playerHp=1;assert(R.guard(g,2)==0 and g.playerHp==math.min(100,50*power)) end
    g.playerHp=1;assert(R.guard(g,2)==2)
    g,c=fixture("soul_edition_prism",power);x,y=Deck.newCard(2,"diamonds"),Deck.newCard(4,"clubs")
    score(g,c,{x,y});assert(FX.getEffectName(c)=="foil" and c.editionPower==power and FX.getScoreBonus(c).damage==20*power)
    assert(g.persistentDeck[1].editionPower==power)
    if power>1 then
        assert(E.getDescription(c.equipments[1]):find("×"..power,1,true))
        assert(require("src.card_description").edition(c):find("+"..(20*power),1,true))
        local gear=c.equipments[1];local title,body=require("src.card_description").resolve(gear,g)
        local model=require("ui.components.card_description").model(gear,title,body,false)
        local occurrences=0
        for _,row in ipairs(model.rows) do for _ in row.text:gmatch(power==10 and "THE VOID" or "HUYẾT LUYỆN") do occurrences=occurrences+1 end end
        assert(occurrences==1,"power note appears once in the tooltip")
        local loaded=assert(require("src.persistence").restoreSnapshot(require("src.persistence").makeSnapshot(g,"shop")))
        assert(FX.getScoreBonus(loaded.persistentDeck[1]).damage==20*power,"prism edition survives save/load")
    end
    g=Game.new();g.monster={hp=100000,maxHp=100000};g.deities={};g.spnCombat={}
    local spn={};for k,v in pairs(D.CATALOG.spirit_borrowed_turn) do spn[k]=v end
    if power==5 then spn.bloodPower=5 elseif power==10 then spn.voidPower=10 end;g.deities[1]=spn
    local h={type=Poker.HAND_TYPES.THREE_OF_A_KIND,scoringCards={Deck.newCard(3,"hearts"),Deck.newCard(3,"diamonds"),Deck.newCard(3,"clubs")},unscoredCards={}}
    g.hand=h.scoringCards;g.persistentDeck=h.scoringCards
    Scoring.calculate(h,g.deities,{gameState=g,monster=g.monster})
    local gift=assert(g.backpackConsumables[1]);assert(gift.permanentSpeed and require("src.shop").getConsumableParams(gift).speed==3*power)
    local old=g.hand[1].speedBonus or 0
    assert(require("src.potions").applySpeed(g,gift,g.hand[1]) and g.hand[1].speedBonus==old+3*power)
    assert(D.getDescription(spn):find("+"..(3*power),1,true))
    local archive={};for k,v in pairs(D.CATALOG.spirit_archive) do archive[k]=v end
    archive.bloodPower=spn.bloodPower;archive.voidPower=spn.voidPower;g.deities[1]=archive;g.backpackConsumables={}
    for _,kind in ipairs({"HIGH_CARD","PAIR","STRAIGHT"}) do
        Scoring.calculate({type=Poker.HAND_TYPES[kind],scoringCards={g.hand[1]},unscoredCards={}},g.deities,{gameState=g,monster=g.monster})
    end
    assert(#g.backpackConsumables==power,"powered archive grants the actual number of evolution cards")
end
print("Void power PASS: actual x1/x5/x10 for all ten soul relic mechanics, edition score strength, persistent copies, powered SPN potion creation/consumption and truthful descriptions")
