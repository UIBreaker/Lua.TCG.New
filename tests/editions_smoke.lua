-- Run from the project root: lua tests/editions_smoke.lua
local E=require("src.card_effects")
local D=require("src.deck")
local A=require("src.card_abilities")
local P=require("src.poker")
local S=require("src.scoring")
local Shop=require("src.shop")
local G=require("src.game_state")
local Combat=require("src.combat")
local function fixture(cards)
    local g=G.new();g.hand=cards;g.persistentDeck={};g.deck={};g.discardPile={};g.deities={};g.gold=0
    g.monster={hp=10000,maxHp=10000};A.start(g)
    return g
end
local function score(cards,live)
    local h=P.evaluate(cards)
    local g=fixture(cards)
    if live then A.beginHand(g,h,cards);g.hand={} end
    return S.calculate(h,{},live and {gameState=g,monster=g.monster} or {}),g
end
local catalog=E.getEditionCatalog()
assert(#catalog==9)
for _,item in ipairs(catalog) do
    local card=D.newCard(2,"diamonds");assert(E.setEffect(card,item.edition))
    assert(D.cloneCard(card).edition==item.edition)
    assert(require("src.card_description").edition(card):find(item.name,1,true))
    local g=fixture({card});g.selectedIndices={1};g.persistentDeck={D.cloneCard(card)}
    local shop={currentPackOpening={pack={packType="edition"},cards={item}}}
    assert(Shop.choosePackCard(shop,1,g));assert(g.persistentDeck[1].edition==item.edition)
    assert(shop.currentPackOpening==nil)
end
assert(not E.setEffect({id="spn"},"astral"),"rank/suit editions must not be consumed on SPN")
-- Exercise the real target click handler, including consume VFX and persistent copies.
local f=assert(io.open("main.lua","r"));local main=f:read("*a");f:close()
local first=assert(main:find("local function applyPendingEditionAt",1,true))
local last=assert(main:find("local function applyPendingSpeedAt",first,true))
local handlerSource=main:sub(first,last-1).."\nreturn applyPendingEditionAt"
for _,item in ipairs(catalog) do
    local target=D.newCard(8,"diamonds");local game=fixture({target})
    game.consumables={item};game.persistentDeck={D.cloneCard(target)}
    local consumed,animated=false,false
    local env=setmetatable({game=game,pendingEditionCard=item,Shop=Shop,
        Deities=require("src.deities"),Sound=require("src.sound"),anim={floatingTexts={}},
        UI={Abilities=A,COLORS={goldYellow={}},Polish={snapshot=function() return {} end,changed=function() animated=true end}},
        getDeitySlotRect=function() return 1000,0,50,50 end,
        getConsumableSlotRect=function() return 0,0,80,120 end,
        spawnShopFx=function(kind) assert(kind=="consume");consumed=true end},{__index=_G})
    local loader
    if setfenv then loader=assert(loadstring(handlerSource));setfenv(loader,env)
    else loader=assert(load(handlerSource,"edition click","t",env)) end
    local click=loader()
    assert(not click(500,500,"playing") and #game.consumables==1,"missed target must not consume")
    if not E.getScoreBonus({edition=item.edition}) then
        game.deities={{id="test_spn",name="Test"}}
        assert(click(1010,10,"playing") and #game.consumables==1 and not game.deities[1].edition)
    end
    assert(click(10,10,"playing") and #game.consumables==0 and consumed and animated)
    assert(target.edition==item.edition and game.persistentDeck[1].edition==item.edition)
end
local seen={}
for _=1,150 do
    local opening=Shop.openPack({packType="edition"},{})
    assert(#opening.cards==3)
    local unique={}
    for _,c in ipairs(opening.cards) do assert(not unique[c.id]);unique[c.id]=true;seen[c.id]=true end
end
for _,c in ipairs(catalog) do assert(seen[c.id],"unreachable edition: "..c.id) end

local card=D.newCard(2,"diamonds");local other=D.newCard(2,"spades")
local plain=score({card,other},false)
E.setEffect(card,"foil");local foil=score({card,other},false)
assert(foil.finalScore==plain.finalScore+20)
E.setEffect(card,"holographic");local holo=score({card,other},false)
assert(holo.totalMult==plain.totalMult+10)
E.setEffect(card,"polychrome");local poly=score({card,other},false)
assert(poly.auraEditionMultiplier==1 and poly.localAuraBonus>0)
assert(poly.finalScore<math.floor(plain.finalScore*1.5),"base hand and other card must not be amplified")

E.setEffect(card,"echo")
local echo,g=score({card,other},true)
assert(math.abs(g.gold-2)<1e-8,"Echo ability must award gold twice at full strength")
local triggers=0;for _,st in ipairs(echo.steps) do if st.type=="card_scored" and st.card==card then triggers=triggers+1 end end
assert(triggers==2,"Echo must retrigger exactly once")
local ownChips=0;for _,st in ipairs(plain.steps) do if st.type=="card_scored" and st.card==card then ownChips=st.addedChips end end
assert(math.abs(echo.bonusChips-plain.bonusChips-ownChips)<1e-8)

E.setEffect(card,"ancient");card.evolutionLevel=2
assert(A.params(card).gold==7 and A.params(card).count==2)
card.evolutionLevel=0;assert(A.params(card).gold==1)
local left=D.newCard(2,"diamonds");local right=D.newCard(2,"diamonds");local relay=D.newCard(8,"spades")
E.setEffect(relay,"resonant");g=fixture({left,relay,right})
local h={type=P.HAND_TYPES.PAIR,scoringCards={left,right},unscoredCards={},chips=10,mult=2}
A.beginHand(g,h,{left,right});g.hand={relay}
S.calculate(h,{}, {gameState=g,monster=g.monster})
assert(math.abs(g.gold-2.4)<1e-8,"Both neighbors get 20%")
g=fixture({left,relay,right});A.beginHand(g,h,{left,relay,right});g.hand={}
S.calculate(h,{}, {gameState=g,monster=g.monster});assert(g.gold==2,"Played relay is no longer held")

local goldCard=D.newCard(9,"spades");E.setEffect(goldCard,"gilded");g=fixture({goldCard})
Combat.onPlayerTurnEnd(g);assert(g.gold==3)
goldCard.destroyed=true;Combat.onPlayerTurnEnd(g);assert(g.gold==3)
local stars={}
for i=1,5 do stars[i]=D.newCard(i+5,i==5 and "diamonds" or "spades") end
E.setEffect(stars[5],"astral")
local originalSuit=stars[5].suit
assert(P.evaluate(stars).type.id=="straight_flush")
assert(stars[5].suit==originalSuit and stars[5].rank==10)
stars[4].suit="hearts";assert(P.evaluate(stars).type.id=="straight","one Astral cannot cover two incompatible suits")

local dying=D.newCard(13,"diamonds");E.setEffect(dying,"void");g=fixture({dying})
assert(A.destroy(g,dying));assert(g.gold==88,"Void death ability fires ten additional times")
assert(not A.destroy(g,dying) and g.gold==88,"Destruction is idempotent")
local dyingScore=D.newCard(2,"diamonds");E.setEffect(dyingScore,"void")
g=fixture({dyingScore,other});A.beginHand(g,P.evaluate({dyingScore,other}),{dyingScore,other})
A.destroy(g,dyingScore);assert(g.gold==10,"Void activates a scoring ability ten times before removal")
for _,suit in ipairs({"valoria","aurelia","elaris","vharos"}) do
    for rank=2,14 do
        local c=D.newCard(rank,suit);E.setEffect(c,"void");g=fixture({c});g.gold=100
        assert(A.destroy(g,c),"Safe final activation outside a hand: "..suit..rank)
    end
end
local paid=D.newCard(10,"diamonds");E.setEffect(paid,"void")
local target=D.newCard(2,"diamonds");g=fixture({paid,target});g.gold=100
local decision={card=paid,definition=A.definition(paid),params=A.params(paid),target=target}
A.beginHand(g,P.evaluate({paid,target}),{paid,target},{decision})
local goldBefore=g.gold;local levelBefore=target.temporaryAbilityLevels
A.destroy(g,paid)
assert(g.gold==goldBefore-10*decision.params.cost and target.temporaryAbilityLevels==levelBefore+10*decision.params.levels)
local spn={name="Test",edition="polychrome",onCardScored=function() return {addChips=8} end}
local h=P.evaluate({D.newCard(9,"diamonds")})
local spnScore=S.calculate(h,{spn},{})
assert(spnScore.auraEditionMultiplier==1 and spnScore.localAuraBonus>0,"SPN Polychrome also amplifies only its own contribution")
print("Nine editions passed: pool, imprint/persistence, 20 ST, +10 Mult, local Aura, full Echo, evolution, held gold, wild suit, both neighbors and ten final activations")
