local D=require("src.deities")
local G=require("src.game_state")
local Run=require("src.run_manager")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Souls=require("src.souls")
local Shop=require("src.shop")
local Rng=require("src.rng")
local P=require("src.persistence")
local Modal=require("ui.ability_choices")
local Deck=require("src.deck")
assert(D.CATALOG.spirit_meteor_solitude.values.value==100)
assert(D.CATALOG.spirit_hour_product.values.value==.5)
local g=G.new();g.run=Run.newRun("red_deck");g.persistentDeck={Deck.newCard(3,"hearts")}
assert(D.addDeity(g,D.CATALOG.spirit_pebble,1) and D.addDeity(g,D.CATALOG.spirit_hour_product,2))
local first,second=g.deities[1],g.deities[2]
g.backpackDeities={{id="spirit_blade"}}
assert(not D.useEvolutionCard(g,first) and not first.evolutionLevel)
assert(D.awardBossEvolution(g,{hp=0,isBoss=false})==0 and D.getEvolutionCredits(first)==0)
local function winBoss(stage)
    g.run.ante=stage;g.run.areaStage=stage;g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(stage,"red_deck","human",stage)
    Combat.start(g,Run.createBlindMonster(g.run.blinds[3],g),stage)
    for _,m in ipairs(require("src.enemy_group").members(g)) do m.hp=0 end
    A.combatWin(g);A.combatWin(g);Souls.awardKills(g);Souls.awardKills(g)
end
winBoss(1)
assert(D.getEvolutionCredits(first)==1 and D.getEvolutionCredits(second)==1)
assert(D.getEvolutionCredits(g.backpackDeities[1])==0)
winBoss(2)
assert(D.getEvolutionCredits(first)==2 and D.getEvolutionCredits(second)==2)
local loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(D.getEvolutionCredits(loaded.deities[1])==2)
local replay=Run.createBlindMonster(loaded.run.blinds[3],loaded);replay.hp=0
assert(D.awardBossEvolution(loaded,replay)==0,"reloaded boss receipt cannot grant twice")
assert(D.getEvolutionCredits(loaded.deities[1])==2)
assert(require("src.loadout").move(g,"spn","equipped",1,nil,false))
assert(not D.useEvolutionCard(g,first) and D.getEvolutionCredits(first)==2)
local index;for i,c in ipairs(g.backpackDeities) do if c==first then index=i end end
assert(require("src.loadout").move(g,"spn","reserve",index,1,false))
assert(D.useEvolutionCard(g,first) and first.evolutionLevel==1 and D.getEvolutionCredits(first)==1)
local ok,_,gain=D.useEvolutionCard(g,first,5)
assert(ok and gain==1 and first.evolutionLevel==2 and D.getEvolutionCredits(first)==0)
assert(D.getEvolutionCredits(second)==2,"credits belong to each SPN separately")
local item=Run.createEvolutionCard();g.consumables={item}
assert(Modal.openEvolution(g,item));Modal.current.selected=first
assert(not Modal.confirm() and g.consumables[1]==item and first.evolutionLevel==2)
winBoss(3)
assert(Modal.openEvolution(g,item));Modal.current.selected=first
assert(Modal.confirm() and #g.consumables==0 and first.evolutionLevel==3 and D.getEvolutionCredits(first)==0)
assert(D.evolve(first) and first.evolutionLevel==4,"automatic evolution keeps its existing mechanics")
item=Run.createEvolutionCard();g.consumables={item}
assert(Modal.openEvolution(g,item));Modal.current.selected=g.persistentDeck[1]
assert(Modal.confirm() and #g.consumables==0 and g.persistentDeck[1].evolutionLevel==1,"playing cards do not spend SPN boss credits")
local legacy=P.restoreSnapshot(P.makeSnapshot(g,"shop"));legacy.deities[1].evolutionCredits=nil
assert(D.getEvolutionCredits(legacy.deities[1])==0 and not D.useEvolutionCard(legacy,legacy.deities[1]))

local copyGame=G.new();assert(D.addDeity(copyGame,D.CATALOG.spirit_pebble,1))
assert(D.addDeity(copyGame,D.CATALOG.spirit_legacy_cocoon,2))
copyGame.deities[1].evolutionCredits=4
copyGame.monster={hp=0,isBoss=true};copyGame.enemies={copyGame.monster}
Souls.awardKills(copyGame);A.combatWin(copyGame)
assert(D.getEvolutionCredits(copyGame.deities[1])==5 and D.getEvolutionCredits(copyGame.deities[2])==0,"new copies cannot inherit or earn the source's boss credits")

g=G.new();g.run=Run.newRun("red_deck");g.run.ante=120;g.shopMode="spn"
local counts={};local n=0;Rng.seed(91283)
for _=1,1000 do
    local shop=Shop.new();Shop.refresh(shop,g)
    for _,item in ipairs(shop.items) do
        assert(D.getRarityTier(item.deity)<=5,"shop must never sell above L")
        counts[item.rarity]=(counts[item.rarity] or 0)+1;n=n+1
    end
end
for _,id in ipairs({"common","uncommon","rare","epic","legendary"}) do
    assert(counts[id] and math.abs(counts[id]/n-Shop.SPN_RARITY_WEIGHTS[id])<.025,id)
end
assert(counts.common>counts.uncommon and counts.uncommon>counts.rare and counts.rare>counts.epic and counts.epic>counts.legendary)
local previous=0
for _,id in ipairs({"common","uncommon","rare","epic","legendary"}) do
    local base=math.ceil(4*Shop.SPN_RARITY_PRICE_MULTIPLIERS[id])
    local price=Shop.priceItem({cost=base,deity={rarity=id}})
    assert(price>previous);previous=price
end
for _,mode in ipairs({"small","large","blood_small","blood_large"}) do
    g.shopMode=mode
    for _=1,80 do
        local shop=Shop.new();Shop.refresh(shop,g)
        for _,item in ipairs(shop.items) do if item.deity then assert(D.getRarityTier(item.deity)<=5) end end
    end
end
print("SPN balance limits PASS: nerfs, 6000 weighted C-L offers, rising prices, all SPN markets, boss-only per-owner credits, receipt/save safety, modal consumption, empowered cards and automatic/playing-card evolution")
return true
