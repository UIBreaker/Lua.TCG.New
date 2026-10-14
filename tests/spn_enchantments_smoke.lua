local E=require("src.spn_enchantments")
local Shop=require("src.shop")
local X=require("src.chest_expansion")
local Deck=require("src.deck")
local Game=require("src.game_state")
local A=require("src.card_abilities")
local S=require("src.scoring")
local P=require("src.persistence")
local D=require("src.deities")
local Poker=require("src.poker")
local Modal=require("ui.ability_choices")
local function fixture()
    local g=Game.new();g.playerHp=100;g.maxPlayerHp=1000;g.gold=100
    local cards={}
    for i=1,5 do cards[i]=Deck.newCard(i+2,"clubs");cards[i].disableFactionPassives=true end
    g.hand=cards;g.persistentDeck=cards;g.masterDeck=cards;g.deck={};g.discardPile={}
    g.deities={[1]={id="enchantment_test",name="SPN kiểm tra",rarity="common",onHandScored=function() return {addChips=1000,addMult=100} end}}
    g.monster={hp=100000,maxHp=100000,attackSpeed=1};g.enchantmentCombat={gold=0}
    A.start(g);return g,cards
end
local function score(g,cs,kind,preview)
    return S.calculate({type=Poker.HAND_TYPES[kind or "HIGH_CARD"],chips=10,mult=2,scoringCards=cs,unscoredCards={}},g.deities,
        {gameState=g,monster=g.monster,hand={},preview=preview})
end
assert(#E.catalog()==8 and #Shop.JOKER_SPELLS==8 and #Shop.getPackContents("joker_edition")==8)
local count=0
for _,offer in ipairs(Shop.getRetailConsumables()) do if offer.category=="joker_spell" then
    count=count+1;assert(offer.cost==4 and E.get(offer.id) and offer.desc:find("Chọn SPN",1,true))
end end
assert(count==8)
for _,d in ipairs(E.catalog()) do
    local g,cs=fixture();g.deities[1].enchantment=d.id
    local before=P.encode(g);score(g,{cs[1],cs[2]},"FLUSH",true);assert(P.encode(g)==before,d.id.." mutated preview")
end
-- Percentage buffs must include the SPN's contribution, rather than just the small base hand.
for _,case in ipairs({{"spell_confluence","FLUSH","totalMult",1.75,5},
    {"spell_ladder","STRAIGHT","totalChips",1.75,5},{"spell_balance","HIGH_CARD","totalMult",2,1}}) do
    local g,cs=fixture();local played={};for i=1,case[5] do played[i]=cs[i] end
    local base=score(g,played,case[2],true);g.deities[1].enchantment=case[1]
    local actual=score(g,played,case[2]);assert(actual[case[3]]==base[case[3]]*case[4],case[1])
end
local g,cs=fixture();g.deities[1].enchantment="spell_bastion"
assert(score(g,{cs[1]}).addArmor==0);assert(score(g,{cs[1],cs[2]}).addArmor==150)
g,cs=fixture();g.deities[1].enchantment="spell_mend"
assert(score(g,{cs[1]}).healHp==80 and score(g,cs).healHp==40)
for i=2,4 do g.deities[i]={id="enchantment_test_"..i,name="Giao Hòa "..i,enchantment="spell_mend"} end
assert(score(g,{cs[1]}).healHp==250)
g,cs=fixture();g.deities[1].enchantment="spell_prosper"
local before=P.encode(g);assert(score(g,{cs[1]},nil,true).bonusGoldAwarded==3 and P.encode(g)==before)
for i=1,3 do assert(score(g,{cs[1]}).bonusGoldAwarded==3) end
assert(score(g,{cs[1]}).bonusGoldAwarded==0 and g.enchantmentCombat.gold==9)
E.reset(g);assert(score(g,{cs[1]}).bonusGoldAwarded==3)
g,cs=fixture();g.deities[1].enchantment="spell_switchcraft"
local first=score(g,{cs[1]});assert(first.totalMult==102)
local second=score(g,{cs[1]},"PAIR");assert(second.totalMult==153)
assert(score(g,{cs[1]},"PAIR").totalMult==102)
g,cs=fixture();cs[1].equipments={{id="test_itm_1"},{id="test_itm_2"}};cs[2].equipments={{id="test_itm_1"}}
local base=score(g,{cs[1],cs[2]},nil,true);g.deities[1].enchantment="spell_retinue"
assert(score(g,{cs[1],cs[2]}).totalChips==base.totalChips*1.2)
-- Duplicate enchantments add percentages with a shared cap, and locked SPNs contribute nothing.
g,cs=fixture();for i=1,4 do g.deities[i]={id="enchantment_test_"..i,name="Trăng Non "..i,enchantment="spell_balance"} end
assert(score(g,{cs[1]}).totalMult==6)
g,cs=fixture();g.deities[1].enchantment="spell_balance"
g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(score(g,{cs[1]}).totalMult==2,"a locked SPN's enchantment must be disabled too")
g,cs=fixture();g.deities[1].enchantment="spell_prosper";g.enchantmentCombat.gold=9
require("src.combat").start(g,{hp=100000,maxHp=100000,attackSpeed=1},1)
assert(g.enchantmentCombat.gold==0,"new combat must reset the shared gold budget")
-- Target selection includes sparse equipped slots and reserve SPNs, and consumes nothing on cancel.
g,cs=fixture();g.deities={[2]={id="spirit_ward",name="Băng Vệ",edition="foil",evolutionLevel=3},
    [11]={id="spirit_blade",name="Kiếm Linh",enchantment="spell_ladder",enchantmentPower=1}}
g.backpackDeities={{id="spirit_ember",name="Hỏa Linh"}};local item=E.get("spell_balance")
assert(#E.targets(g)==3)
local ok,message=E.apply(g,item);assert(not ok and message=="choose_enchantment")
assert(not E.apply(g,item,cs[1]),"a playing card cannot be used as a SPN target")
local committed=false;assert(E.openTarget(g,item,Modal,function(target) committed=true;assert(E.apply(g,item,target)) end))
assert(not committed and not g.deities[2].enchantment);Modal.key("escape");assert(not committed)
assert(E.openTarget(g,item,Modal,function(target) committed=true;assert(E.apply(g,item,target)) end));Modal.choose(2)
assert(committed and g.deities[11].enchantment==item.id and not g.deities[2].enchantment)
assert(g.deities[2].edition=="foil" and g.deities[2].evolutionLevel==3 and #g.backpackDeities==1)
local beforePower=g.deities[11].enchantmentPower
assert(E.apply(g,{id=item.id,bloodPower=5},g.deities[2]))
assert(g.deities[2].enchantmentPower==5 and g.deities[11].enchantmentPower==beforePower)
assert(require("src.blood_shop").applyConsumable(g,{id="spell_ladder",bloodPower=5},g.deities[2],X.apply))
assert(g.deities[2].enchantmentPower==5 and g.deities[11].enchantmentPower==beforePower)
assert(E.apply(g,{id=item.id,bloodPower=5},g.deities[2]))
assert(not E.apply(g,item,g.deities[2]),"a weaker duplicate must not erase an upgraded enchantment")
local shop={currentPackOpening={pack={packType="joker_edition"},cards={E.get("spell_mend")}}}
ok,message=Shop.choosePackCard(shop,1,g);assert(not ok and message=="choose_enchantment" and shop.currentPackOpening)
assert(Shop.choosePackCard(shop,1,g,g.backpackDeities[1]) and not shop.currentPackOpening)
-- The stored-card handler opens selection first and consumes the book only after committing a target.
local file=assert(io.open("main.lua","r"));local source=file:read("*a");file:close()
local start=assert(source:find("local function useConsumable(idx)",1,true))
local stop=assert(source:find("local function activateConsumable",start,true))
local env=setmetatable({game=g,Shop=Shop,Sound={play=function() end},anim={floatingTexts={}},saveRunAtSafePoint=function() end,
    UI={BossAbilities=require("src.boss_abilities"),Inventory=require("src.inventory"),AbilityUI=Modal,Abilities=A,
        Polish={snapshot=function() return {} end,changed=function() end},COLORS={goldYellow={1,1,1,1}}}},{__index=_G})
local chunk=source:sub(start,stop-1).."\nreturn useConsumable"
local loader
if setfenv then loader=assert(loadstring(chunk));setfenv(loader,env) else loader=assert(load(chunk,"stored enchantment","t",env)) end
local stored=loader();g.consumables={E.get("spell_mend")}
assert(stored(1) and #g.consumables==1 and Modal.current)
Modal.key("escape");assert(#g.consumables==1 and g.deities[11].enchantment==item.id)
assert(stored(1));Modal.choose(2);assert(#g.consumables==0 and g.deities[11].enchantment=="spell_mend")
-- All sixteen retired spell IDs migrate in equipped/reserve SPNs, stored cards and open rewards.
local retired=0
for old,new in pairs(E.retired) do
    retired=retired+1;g,cs=fixture()
    g.deities={[1]={id="spirit_ward",name="Băng Vệ",enchantment=old,enchantmentPower=5,edition="foil",evolutionLevel=3}}
    g.backpackDeities={{id="spirit_blade",enchantment=old}}
    g.consumables={{id=old,category="joker_spell",bloodPower=5,cost=9}}
    g.backpackConsumables={{id=old,category="joker_spell"}}
    g.rewardPacks={{pack={packType="joker_edition"},cards={{id=old},{id=new}}}}
    local restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
    assert(restored.deities[1].enchantment==new and restored.deities[1].enchantmentPower==5 and restored.deities[1].edition=="foil")
    assert(restored.backpackDeities[1].enchantment==new and restored.backpackConsumables[1].id==new)
    assert(restored.consumables[1].id==new and restored.consumables[1].bloodPower==5 and restored.consumables[1].cost==9)
    assert(#restored.rewardPacks[1].cards==1 and not restored.enchantmentCombat)
end
assert(retired==16)
for i=1,150 do local pack=Shop.openPack({packType="joker_edition"},Game.new());local ids={}
    assert(#pack.cards==3);for _,d in ipairs(pack.cards) do assert(E.get(d.id) and not ids[d.id]);ids[d.id]=true end
end
print("PASS: 8 strategic SPN enchantments, final-stat scaling, budgets, target/cancel/replace, sparse and reserve SPNs, preview and 16 save migrations")
