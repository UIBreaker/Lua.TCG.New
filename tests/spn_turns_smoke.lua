local T=require("src.spn_turns")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function game()
    local g=Game.new();g.deities={};g.backpackDeities={};g.hand={}
    g.persistentDeck={Deck.newCard(3,"hearts"),Deck.newCard(6,"spades")}
    g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    return g
end
local function own(g,id,slot,rarity)
    assert(D.addDeity(g,D.CATALOG[id],slot))
    local d=g.deities[slot];if rarity then assert(D.setRarity(d,rarity)) end;return d
end
local function start(g,round) Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},round or 1) end
for _,row in ipairs({T.entries[1],T.entries[2]}) do
    local g=game();local owned=own(g,row[1],3)
    local key=row[3]=="addHands" and "handsRemaining" or "discardsRemaining"
    local limit=row[3]=="addHands" and "maxHands" or "maxDiscards"
    local base=g[limit]
    for level=0,2 do
        start(g,level+1);assert(g[key]==base+1+level and g[limit]==base,"integer bonus, no persistent limit growth")
        assert(D.getDescription(owned):find("+"..(level+1),1,true))
        assert((key=="handsRemaining" and g.turnHandLimit or g.spnDiscardCap)==base+1+level)
        g[key]=0;start(g,level+1);assert(g[key]==base+1+level,"restarting battle does not accumulate grants")
        if level<2 then assert(D.evolve(owned)) end
    end
    local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    start(restored);assert(restored[key]==base+3 and restored.deities[3].evolutionLevel==2)
    g=game();g.backpackDeities[1]=D.CATALOG[row[1]];start(g);assert(g[key]==g[limit],"reserve SPNs grant no turns")
    g=game();own(g,"spirit_right_echo",1);own(g,row[1],2)
    D.evolve(g.deities[1]);start(g);assert(g[key]==g[limit]+3,"two copied activations plus the source")
end
local cards={Deck.newCard(3,"hearts")};cards[1].disableFactionPassives=true
local hand=assert(Poker.evaluate(cards))
local function score(g,preview)
    return Scoring.calculate(hand,g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function factor(r,slot)
    local f=1
    for _,step in ipairs(r.steps) do if step.type=="deity_hand" and step.slotIndex==(slot or 1) then f=f*(step.xMult or 1) end end
    return f
end
local g=game();local council=own(g,"spirit_legend_council",1)
assert(factor(score(g))==1 and T.legendCount(g.deities)==0)
for i=1,3 do
    own(g,"spirit_pebble",i+1,"legendary")
    local rng=Rng.getState();local p=score(g,true);local r=score(g)
    assert(factor(r)==2.5^i and p.totalMult==r.totalMult and rng==Rng.getState())
end
for _,rarity in ipairs(D.RARITIES) do
    D.setRarity(g.deities[2],rarity.id)
    assert(T.legendCount(g.deities)==(rarity.id=="legendary" and 3 or 2),"exact L only: "..rarity.id)
end
D.setRarity(g.deities[2],"legendary");D.evolve(g.deities[2])
assert(T.legendCount(g.deities)==2,"evolving from L to M removes one factor")
local reserve={};for k,v in pairs(D.CATALOG.spirit_pebble) do reserve[k]=v end
g.backpackDeities={reserve};D.setRarity(reserve,"legendary")
assert(T.legendCount(g.deities)==2,"legendary reserve is excluded")
g.backpackDeities={}
D.evolve(council);assert(factor(score(g))==3.25^2,"each factor evolves before the repeated multiplication")
for i=1,3 do D.evolve(council) end
assert(D.getRarityBadge(council)=="L" and T.legendCount(g.deities)==3 and factor(score(g))==5.5^3,"self is counted at exact L")
D.evolve(council);assert(T.legendCount(g.deities)==2 and factor(score(g))==6.25^2)
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
restored.monster=g.monster;assert(factor(score(restored))==factor(score(g)))
g=game();own(g,"spirit_right_echo",1,"legendary");own(g,"spirit_legend_council",2)
assert(T.legendCount(g.deities)==1)
local rng=Rng.getState();assert(factor(score(g,true),1)==2.5^5 and Rng.getState()==rng)
local r=score(g);assert(factor(r,1)==2.5^5 and factor(r,2)==2.5,"count physical L copier, not its common proxy")
g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=2,untilHand=1}}
assert(factor(score(g),1)==1 and factor(score(g),2)==1,"locked council and its copies cannot trigger")
g=game();own(g,"spirit_legend_council",1);own(g,"spirit_pebble",5,"legendary")
g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}
assert(factor(score(g))==2.5,"locked L remains physically equipped")
local pool={};for _,entry in ipairs(D.getRandomShopPool({},999)) do pool[entry.id]=true end
for _,row in ipairs(T.entries) do
    assert(pool[row[1]])
    local buyer=game();buyer.gold=20
    local shop={items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}}
    assert(require("src.shop").buyItem(shop,1,buyer) and buyer.gold==16)
    assert(buyer.backpackDeities[1].id==row[1] and D.getCount(buyer.deities)==0)
    assert(require("src.loadout").move(buyer,"spn","reserve",1,1,false))
    assert(buyer.deities[1].id==row[1] and #buyer.backpackDeities==0)
end
g=game();g.extraDeitySlots=10;own(g,"spirit_legend_council",1)
own(g,"spirit_pebble",12,"legendary")
assert(factor(score(g))==2.5,"L in expanded sparse equipped slots is counted")
assert(not D.CATALOG.spirit_legend_council.onHandScored(hand),"empty context has no equipped L")
assert(#D.getRandomShopPool({},999)==100)
print("SPN turns PASS: integer evolved start grants/reset/caps, reserves/mimic/save, exact L tiers/self, repeated products/evolution, physical equipped copies, locks and pure previews")
