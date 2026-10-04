local P=require("src.ux_polish")
local D=require("src.deities")
local Deck=require("src.deck")
local Persistence=require("src.persistence")
local Game=require("src.game_state")
local UI=require("src.ui")
local count=0
for id,def in pairs(D.CATALOG) do
    local game=Game.new()
    local card=Deck.newCard(3,"hearts")
    game.hand={card};game.persistentDeck={card};game.deities={}
    assert(D.addDeity(game,def,5))
    local deity=game.deities[5]
    local before=P.snapshot(game)
    assert(before[card] and before[deity][def.stat],id.." snapshot")
    assert(D.evolve(deity))
    local after=P.snapshot(game)
    assert(after[deity][def.stat]>before[deity][def.stat],id.." evolved stat")
    local expected=def.stat=="xMult" and 1+def.values.value*1.5 or def.values.value*1.5
    assert(math.abs(after[deity][def.stat]-expected)<0.00001,id.." scaling")
    P.applications={}
    P.changed(UI,game,before,{id="cons_evolution"},{x=0,y=0,w=64,h=88})
    assert(#P.applications==1 and P.applications[1].target==deity,id.." feedback")
    assert(not P.applications[1].text:find(def.stat,1,true),id.." localized label")
    local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(game,"shop")))
    local saved=restored.deities[5]
    assert(P.snapshot(restored)[saved][def.stat]==after[deity][def.stat],id.." existing saves")
    count=count+1
end
assert(count==21)
print("SPN snapshot PASS: all 21 SPNs, evolution feedback, XMult scaling, sparse slots, shared cards and save/load")
