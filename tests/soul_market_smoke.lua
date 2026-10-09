local G=require("src.game_state")
local D=require("src.deck")
local E=require("src.equipment")
local I=require("src.inventory")
local Run=require("src.run_manager")
local P=require("src.persistence")
local A=require("src.card_abilities")
local R=require("src.soul_relics")
local Depth=require("src.chest_depth")
local S=require("src.scoring")
local Shop=require("src.shop")
local function fixture(id,count)
    local g=G.new();local c=D.newCard(8,"valoria")
    c.disableFactionPassives=true;c.maxSockets=6;c.unlockedSockets=6;c.allowDuplicateEquipment=true
    g.persistentDeck={c,D.newCard(4,"elaris"),D.newCard(6,"aurelia")};g.masterDeck=g.persistentDeck
    if id then for _=1,count or 2 do assert(E.attach(c,E.ITEMS[id]),id) end end
    g.hand={D.cloneCard(c)};g.deck={};g.discardPile={}
    g.monster={hp=1000,maxHp=1000,attack=10,attackSpeed=1,armor=0};g.enemies={g.monster}
    A.start(g);return g,g.hand[1],c
end
local function score(g,c,preview)
    return S.calculate({type={id="high_card",baseChips=5,baseMult=1},chips=5,mult=1,scoringCards={c},unscoredCards={}},
        {},{gameState=g,monster=g.monster,preview=preview})
end
local function relicScore(g,c,others)
    local cs={c};for _,o in ipairs(others or {}) do cs[#cs+1]=o end
    local ctx=A.beginHand(g,{type={id="high_card"},scoringCards=cs,unscoredCards={}},cs);ctx.index=1
    R.score(g,c,ctx);return ctx
end
-- Buy with souls; upgrade the selected persistent identity and every live copy.
local g=G.new();local c=D.newCard(9,"elaris");g.persistentDeck={c,D.newCard(3,"valoria")};g.masterDeck=g.persistentDeck
g.hand={D.cloneCard(c)};g.deck={D.cloneCard(c)};g.discardPile={D.cloneCard(c)}
g.shopMode="soul";g.souls=80
local shop=Shop.new();Shop.refresh(shop,g)
assert(#Shop.SOUL_SUPPORT==8 and #shop.items==14)
for _,id in ipairs({"cons_socket","cons_rulebreak"}) do
    local index;for i,item in ipairs(shop.items) do if item.id==id then index=i end end
    assert(Shop.buyItem(shop,index,g))
    assert(I.useCardUpgrade(g,1,g.hand[1]))
end
assert(g.souls==0 and #g.consumables==0)
for _,pile in ipairs({g.persistentDeck,g.hand,g.deck,g.discardPile}) do
    for _,copy in ipairs(pile) do if copy.id==c.id then assert(copy.maxSockets==5 and copy.unlockedSockets==5 and copy.allowDuplicateEquipment) end end
end
g.consumables={Run.createRulebreakCard()};assert(not I.useCardUpgrade(g,1,c) and #g.consumables==1)
g.consumables={Run.createSocketCard()};assert(not I.useCardUpgrade(g,1,D.newCard(2,"valoria")) and #g.consumables==1)
for _=1,3 do assert(I.useCardUpgrade(g,1,c));g.consumables={Run.createSocketCard()} end
g.consumables={Run.createSocketCard()};assert(not I.useCardUpgrade(g,1,c) and #g.consumables==1 and c.maxSockets==8)
for _=1,8 do assert(E.attach(c,E.ITEMS.gem_fire)) end
assert(not E.attach(c,E.ITEMS.gem_fire))
local loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"));local saved=loaded.persistentDeck[1]
assert(saved.maxSockets==8 and saved.unlockedSockets==8 and saved.allowDuplicateEquipment and #saved.equipments==8)
local copy=D.cloneCard(saved);assert(copy.maxSockets==8 and copy.allowDuplicateEquipment and #copy.equipments==8)
D.transformCard(loaded,saved,11);assert(saved.maxSockets==8 and saved.allowDuplicateEquipment)
local ordinary=D.newCard(8,"valoria");assert(E.attach(ordinary,E.ITEMS.gem_fire));assert(not E.attach(ordinary,E.ITEMS.gem_fire))
-- Picker cancellation preserves the consumable. Only confirmation applies it.
local Modal=require("ui.ability_choices")
loaded.consumables={Run.createRulebreakCard()}
assert(Modal.openCardUpgrade(loaded,loaded.consumables[1]));Modal.key("escape");assert(#loaded.consumables==1)
assert(Modal.openCardUpgrade(loaded,loaded.consumables[1]));Modal.current.selected=loaded.persistentDeck[2]
assert(Modal.confirm() and #loaded.consumables==0 and loaded.persistentDeck[2].allowDuplicateEquipment)
-- Actual score combines every duplicate; passive speed also stacks.
g,c=fixture();local base=score(g,c)
g,c=fixture("gem_fire",6);local result=score(g,c)
assert(result.bonusChips-base.bonusChips==E.ITEMS.gem_fire.params.edge*6)
g,c=fixture("gem_blast");result=score(g,c)
assert(result.bonusMult-base.bonusMult==E.ITEMS.gem_blast.params.mult*2)
g,c=fixture("itm_heelhook");local bare=D.cloneCard(c);bare.equipments={};assert(D.getCardAttackSpeed(c)==D.getCardAttackSpeed(bare)+4)
g,c=fixture("lucky_coin",6);D.transformCard(g,c,14);assert(score(g,c).bonusGoldAwarded==6)
g,c=fixture("ward_stone",6);assert(score(g,c).addArmor==30)
g,c=fixture("blood_ring");assert(score(g,c).hpCost==2*E.ITEMS.blood_ring.params.hpCost)
g,c=fixture("soul_crown",3);assert(score(g,c).bonusMult-base.bonusMult==90)
-- Each charged item stores and empties its own preparation; preview is read-only.
g,c=fixture("itm_capacitor");Depth.discard(g,{c});Depth.discard(g,{c})
local memory=P.encode(g.depthCombat);local preview=score(g,c,true)
assert(P.encode(g.depthCombat)==memory)
result=score(g,c);assert(result.bonusChips-base.bonusChips==72 and result.bonusMult-base.bonusMult==12)
assert(result.bonusChips==preview.bonusChips and score(g,c).bonusChips==base.bonusChips)
g,c=fixture("itm_hourhand");Depth.enemyAttack(g,0,0);Depth.enemyAttack(g,0,0)
assert(score(g,c).bonusMult-base.bonusMult==28 and score(g,c).bonusMult==base.bonusMult)
g,c=fixture("itm_bloodvial");local hp=g.playerHp;Depth.discard(g,{c});assert(g.playerHp==hp-4)
assert(score(g,c).bonusMult-base.bonusMult==14)
g,c=fixture("itm_bell");assert(score(g,c).bonusMult-base.bonusMult==10);assert(score(g,c).bonusMult-base.bonusMult==20)
Depth.discard(g,{});assert(score(g,c).bonusMult-base.bonusMult==10)
g,c=fixture("itm_ledger");g.gold=10;preview=score(g,c,true)
assert(g.gold==10 and (c.depthInvestment or 0)==0)
result=score(g,c);assert(result.bonusMult==preview.bonusMult and result.bonusMult-base.bonusMult==9 and g.gold==8 and c.depthInvestment==2)
g,c=fixture("itm_ledger");g.gold=1;preview=score(g,c,true);result=score(g,c)
assert(result.bonusMult==preview.bonusMult and g.gold==0 and c.depthInvestment==1)
-- Every soul copy has its own once-per-battle charge and ongoing effect.
g,c=fixture("soul_frost_bell");local ctx=relicScore(g,c);assert(g.soulRelicCombat.freeze==4)
ctx.retrigger=true;R.score(g,c,ctx);assert(g.soulRelicCombat.freeze==4)
relicScore(g,c);assert(g.soulRelicCombat.freeze==4)
g,c=fixture("soul_phoenix_lantern");g.playerHp=1;assert(R.guard(g,10)==0)
g.playerHp=1;assert(R.guard(g,10)==0);g.playerHp=1;assert(R.guard(g,10)==10)
g,c=fixture("soul_rift_compass");g.deck={D.newCard(4,"elaris"),D.newCard(14,"elaris")};relicScore(g,c)
assert(#g.deck==0 and #g.hand==3)
g,c=fixture("soul_reaper_contract");relicScore(g,c);relicScore(g,c);g.monster.hp=0;R.reap(g)
assert(g.souls==6);R.reap(g);assert(g.souls==6)
g,c=fixture("soul_plague_chalice");relicScore(g,c);R.beforeAttack(g,g.monster);assert(g.monster.hp==840)
R.beforeAttack(g,g.monster);R.beforeAttack(g,g.monster);assert(g.monster.hp==520 and g.monster.soulPoisonTurns==0)
g,c=fixture("soul_evolution_quill");local ally=g.persistentDeck[2];relicScore(g,c,{ally});assert(ally.evolutionLevel==2)
relicScore(g,c,{ally});assert(ally.evolutionLevel==4)
g,c=fixture("soul_edition_prism");relicScore(g,c,{g.persistentDeck[2],g.persistentDeck[3]})
assert(require("src.card_effects").getEffectName(c)=="holographic")
g,c=fixture("soul_silence_anchor");g.monster.isBoss=true;g.monster.bossData={id="the_water",debuffId="the_water"}
local Boss=require("src.boss_abilities");Boss.start(g);relicScore(g,c)
local bs=Boss.state(g.monster);assert(bs.activeUntil-bs.handIndex==4)
-- Ritual rewards are contextual and paid exactly once, including after reload.
g,c=fixture("gem_fire");g.shopMode="soul";g.playerHp=95;g.gold=10;g.souls=0
g.consumables={Shop.destructionItem().consumable};assert(Shop.activateDestruction(g,g.consumables[1]))
local value=Shop.getSoulValue(c);local rewards=Shop.getDestructionRewards(g,c);assert(rewards.souls==value*2 and rewards.heal==10 and rewards.gold==5)
local ok,amount=Shop.destroyCard(g,c);assert(ok and amount==value*2 and g.souls==amount and g.playerHp==100 and g.gold==15 and #g.hand==0 and #g.persistentDeck==2)
assert(not Shop.destroyCard(g,c));loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(require("src.souls").award(loaded,D.cloneCard(c),2)==0 and loaded.souls==amount and loaded.gold==15)
g,c=fixture();g.shopMode="normal";g.playerHp=40;g.gold=10;g.consumables={Shop.destructionItem().consumable}
assert(Shop.activateDestruction(g,g.consumables[1]) and Shop.destroyCard(g,c))
assert(g.souls==1 and g.playerHp==40 and g.gold==10)
print("Soul market PASS: purchase, permanent upgrades, cancellation, eight sockets, duplicate scores and charged relics, previews, save/reload, ritual rewards and receipts")
require("tests.soul_relics_smoke")
require("tests.chest_depth_smoke")
