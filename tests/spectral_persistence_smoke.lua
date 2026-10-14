local Deck=require("src.deck")
local Shop=require("src.shop")
local G=require("src.game_state")
local P=require("src.persistence")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local S=require("src.spectral")
local B=require("src.blood_shop")
local Modal=require("ui.ability_choices")
local Equipment=require("src.equipment")
local Poker=require("src.poker")
local function fixture()
    local g=G.new();g.gold=20;g.playerHp=80;g.maxPlayerHp=100
    g.persistentDeck={}
    for _,r in ipairs({6,12,3,9,14}) do g.persistentDeck[#g.persistentDeck+1]=Deck.newCard(r,"hearts") end
    g.masterDeck=g.persistentDeck
    local c=g.persistentDeck[1]
    c.evolutionLevel=2;c.bonusBaseChips=15;c.baseChips=21;c.speedBonus=7
    c.seal="seal_threshold";c.sealPower=5;c.edition="foil";c.enhancement="enh_armor"
    c.maxSockets=6;c.equipments={Equipment.instance("gem_fire")};c.allowDuplicateEquipment=true
    g.hand={Deck.cloneCard(c),Deck.cloneCard(g.persistentDeck[2])}
    g.deck={Deck.cloneCard(g.persistentDeck[3])};g.discardPile={Deck.cloneCard(g.persistentDeck[4])}
    g.selectedIndices={1};A.start(g);return g
end
local function find(list,id) for _,c in ipairs(list or {}) do if c.id==id then return c end end end
local f=assert(io.open("main.lua","r"));local source=f:read("*a");f:close()
local first=assert(source:find("local function useConsumable(idx)",1,true))
local last=assert(source:find("local function activateConsumable",first,true))
local handler=source:sub(first,last-1).."\nreturn useConsumable"
local function stored(g,item)
    local env=setmetatable({game=g,Shop=Shop,Deck=Deck,Sound=require("src.sound"),
        UI={Inventory=require("src.inventory"),BossAbilities=require("src.boss_abilities"),COLORS={goldYellow={}},
            Abilities=A,AbilityUI=Modal,Polish={snapshot=function() return {} end,changed=function() end}},
        anim={floatingTexts={}},saveRunAtSafePoint=function() end},{__index=_G})
    local fn=assert(loadstring(handler));setfenv(fn,env);g.consumables={item};return fn()(1)
end
local function drive(request)
    local selected=0;local steps=0
    while Modal.current do
        steps=steps+1;assert(steps<12,"picker stuck")
        local choice=Modal.current.choices[1];local title=choice.title;local wanted
        if title:find("CHỌN CHẤT",1,true) then wanted=function(o) return Deck.SUITS[o.suit].id==Deck.SUITS[request.suit].id end
        elseif title:find("CHỌN RANK",1,true) then wanted=function(o) return o.rank==request.rank end
        elseif title:find("CHỌN SỐ LÁ",1,true) then wanted=function(o) return o.count==#request.cards end
        elseif title:find("CHỌN LÁ",1,true) then
            selected=selected+1;wanted=function(o) return o.id==request.cards[selected].id end
        else wanted=function() return true end end
        local index;for i,o in ipairs(choice.options) do if wanted(o.target) then index=i;break end end
        assert(index,"desired target absent: "..title);Modal.choose(index)
    end
end
local function requestFor(g,id)
    local c=g.persistentDeck
    if id=="spec_cryptid" then return {cards={c[1]}}
    elseif id=="spec_immolate" then return {cards={c[3],c[4]}}
    elseif id=="spec_sigil" then return {cards={c[1],c[2],c[4]},suit="diamonds"}
    elseif id=="spec_ouija" then return {cards={c[1],c[2]},rank=14}
    elseif id=="spec_rethread" then return {cards={c[1],c[2]}}
    elseif id=="spec_shrink" then return {cards={c[2]}}
    else return {} end
end
assert(#S.cards==7 and #Shop.SPECTRAL_CARDS==7)
local retired=0;for _ in pairs(S.retired) do retired=retired+1 end;assert(retired==21)
local retail=0;for _,o in ipairs(Shop.getRetailConsumables()) do if o.category=="spectral" then
    retail=retail+1;assert(S.byId[o.id] and o.cost==8 and o.desc==S.get(o.id).desc)
end end;assert(retail==7)
for _,path in ipairs({"chest","stored"}) do for _,d in ipairs(S.cards) do
    local g=fixture();local c=g.persistentDeck;local before={}
    for _,v in ipairs(c) do before[v.id]=B.clone(v) end
    local size=g.maxHandSize;local request=requestFor(g,d.id);local original=c[1]
    if path=="stored" then assert(stored(g,B.clone(d)));drive(request);assert(#g.consumables==0)
    else
        local shop=Shop.new();shop.currentPackOpening={pack={packType="spectral"},cards={d}}
        assert(S.openTarget(g,d,Modal,function(r) assert(Shop.choosePackCard(shop,1,g,r)) end))
        drive(request);assert(not shop.currentPackOpening)
    end
    if d.id=="spec_cryptid" then
        assert(#c==6 and #g.hand==2 and #g.deck==2 and g.playerHp==75)
        local copy=c[6];assert(copy.id~=original.id)
        for _,k in ipairs({"rank","suit","seal","sealPower","edition","enhancement","evolutionLevel","speedBonus","bonusBaseChips","maxSockets","allowDuplicateEquipment"}) do assert(copy[k]==original[k],"clone lost "..k) end
        assert(copy.equipments[1]~=original.equipments[1] and #copy.equipments==1)
        assert(g.deck[2].id==copy.id and g.deck[2].sealPower==5 and not copy.selected and not copy.exhausted)
    elseif d.id=="spec_immolate" then
        assert(#c==3 and #g.deck==0 and #g.discardPile==0 and g.gold==30 and g.playerHp==80)
        assert(not find(c,request.cards[1].id) and not find(c,request.cards[2].id))
    elseif d.id=="spec_sigil" then
        assert(original.suit=="aurelia" and g.hand[1].suit==original.suit and g.playerHp==77)
        assert(c[3].suit=="valoria" and c[5].suit=="valoria")
    elseif d.id=="spec_ouija" then
        assert(original.rank==14 and original.baseRank==14 and original.baseChips==26 and g.hand[1].rank==14)
        assert(g.playerHp==76 and g.maxHandSize==size and c[3].rank==3)
    elseif d.id=="spec_rethread" then
        assert(#original.equipments==0 and not original.enhancement)
        assert(#c[2].equipments==1 and c[2].enhancement=="enh_armor" and c[2].rank==12)
        assert(#g.hand[2].equipments==1 and g.hand[2].equipments[1]~=c[2].equipments[1] and g.gold==20)
        assert(original.seal=="seal_threshold" and original.edition=="foil" and original.evolutionLevel==2)
    elseif d.id=="spec_shrink" then
        assert(#c==4 and #g.hand==1 and g.maxHandSize==size+1 and g.maxPlayerHp==90 and g.playerHp==80)
    elseif d.id=="spec_black_hole" then
        for _,h in ipairs(Poker.ALL_HANDS_ORDERED) do assert(g.handLevels[h.id]==2) end
        assert(not g.unlockedHands.five_of_a_kind and g.gold==20 and g.playerHp==80)
    end
    local souls=0;for id,v in pairs(before) do if not find(c,id) then souls=souls+Shop.getSoulValue(v) end end
    assert(g.souls==souls,"destruction awards souls exactly once")
    local expected={};for _,v in ipairs(c) do expected[v.id]=B.clone(v) end
    local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
    assert(loaded.souls==g.souls and loaded.gold==g.gold and loaded.maxPlayerHp==g.maxPlayerHp and loaded.maxHandSize==g.maxHandSize)
    Combat.start(loaded,require("src.monster").create(1,false,false,1),2)
    assert(#loaded.persistentDeck==#c)
    for id,v in pairs(expected) do
        local master=assert(find(loaded.persistentDeck,id));local live=assert(find(loaded.hand,id) or find(loaded.deck,id))
        for _,k in ipairs({"rank","baseRank","suit","baseChips","bonusBaseChips","seal","sealPower","edition","enhancement","evolutionLevel","speedBonus","maxSockets"}) do
            assert((master[k] or 0)==(v[k] or 0),"save lost "..k);assert((live[k] or 0)==(v[k] or 0),"next battle lost "..k)
        end
        assert(#master.equipments==#v.equipments and #live.equipments==#v.equipments)
    end
end end
local function unchanged(g,item,request)
    local before=P.encode({g.persistentDeck,g.hand,g.deck,g.discardPile,g.playerHp,g.gold,g.maxHandSize,g.maxPlayerHp,g.souls})
    assert(not S.apply(g,item,request))
    assert(before==P.encode({g.persistentDeck,g.hand,g.deck,g.discardPile,g.playerHp,g.gold,g.maxHandSize,g.maxPlayerHp,g.souls}),"failed effect mutated state")
end
for _,d in ipairs(S.cards) do if d.limit>0 then
    local g=fixture();unchanged(g,d,nil)
    unchanged(g,d,{cards={Deck.newCard(6,"hearts")},rank=2,suit="spades"})
    unchanged(g,d,{cards={g.persistentDeck[1],g.persistentDeck[1]},rank=2,suit="spades"})
end end
for _,id in ipairs({"spec_cryptid","spec_sigil","spec_ouija"}) do
    local g=fixture();g.playerHp=S.get(id).hpCost;unchanged(g,S.get(id),requestFor(g,id))
end
local g=fixture();unchanged(g,S.get("spec_ouija"),{cards={g.persistentDeck[1]},rank=6})
unchanged(g,S.get("spec_sigil"),{cards={g.persistentDeck[1]},suit="hearts"})
unchanged(g,S.get("spec_ouija"),{cards={g.persistentDeck[1]},rank=15})
g=fixture();g.persistentDeck={g.persistentDeck[2]};unchanged(g,S.get("spec_shrink"),{cards=g.persistentDeck})
unchanged(g,S.get("spec_immolate"),{cards=g.persistentDeck})
g=fixture();g.maxPlayerHp=34;unchanged(g,S.get("spec_shrink"),requestFor(g,"spec_shrink"))
g=fixture();g.persistentDeck[1].equipments={{id="gem_fire",slotsNeeded=6}};g.persistentDeck[2].maxSockets=4
unchanged(g,S.get("spec_rethread"),requestFor(g,"spec_rethread"))
g=fixture();g.persistentDeck[1].equipments={{id="gem_fire"},{id="gem_fire"}};g.persistentDeck[2].allowDuplicateEquipment=false
unchanged(g,S.get("spec_rethread"),requestFor(g,"spec_rethread"))
g=fixture();for _,c in ipairs(g.persistentDeck) do c.equipments={};c.enhancement=nil end
assert(not S.openTarget(g,S.get("spec_rethread"),Modal,function() error("no viable pair") end))
-- The live modal must cancel at every step without spending HP or removing the item.
for stop=1,5 do
    g=fixture();local item=B.clone(S.get("spec_ouija"));assert(stored(g,item))
    for step=1,stop-1 do
        local title=Modal.current.choices[1].title;Modal.choose(title:find("CHỌN SỐ LÁ",1,true) and 2 or 1)
    end
    assert(Modal.current);Modal.key("escape");assert(g.consumables[1]==item and g.playerHp==80 and g.persistentDeck[1].rank==6)
end
-- Revalidate after selection; an invalidated target cannot consume a stored card.
g=fixture();local item=B.clone(S.get("spec_cryptid"));assert(stored(g,item));Modal.choose(1)
local removed=table.remove(g.persistentDeck,1);Modal.choose(1)
assert(#g.consumables==1 and g.playerHp==80 and #g.persistentDeck==4 and removed.rank==6)
-- Keep-in-backpack path and migration retain paid costs/powers, update art and deduplicate rewards.
g=fixture();local shop=Shop.new();shop.currentPackOpening={pack={packType="spectral"},cards={S.get("spec_ouija")}}
assert(Shop.keepPackCard(shop,1,g));local kept=g.backpackConsumables[#g.backpackConsumables]
assert(kept.id=="spec_ouija" and kept.category=="spectral")
g.consumables={};g.backpackConsumables={};g.rewardPacks={{pack={packType="spectral"},cards={}}}
for old,new in pairs(S.retired) do
    local v={id=old,category="spectral",name="old",desc="old",artId=old,cost=13,bloodPower=5,voidPower=10}
    g.consumables[#g.consumables+1]=B.clone(v);g.backpackConsumables[#g.backpackConsumables+1]=B.clone(v)
    g.rewardPacks[1].cards[#g.rewardPacks[1].cards+1]=B.clone(v)
end
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(#loaded.consumables==21 and #loaded.backpackConsumables==21)
for _,list in ipairs({loaded.consumables,loaded.backpackConsumables,loaded.rewardPacks[1].cards}) do
    local seen={};for _,v in ipairs(list) do
        assert(S.byId[v.id] and v.artId==v.id and v.desc==S.get(v.id).desc and v.cost==13 and B.powerOf(v)==10)
        if list==loaded.rewardPacks[1].cards then assert(not seen[v.id]);seen[v.id]=true end
    end
end
-- Copy existing strength, never drop or amplify Blood/Void and edition powers.
g=fixture();local original=g.persistentDeck[1]
original.bloodPower=5;original.voidPower=10;original.editionPower=5
original.equipments[1].params={owned={value=7}}
assert(S.apply(g,S.get("spec_cryptid"),{cards={original}}))
local copy=g.persistentDeck[6]
assert(copy.bloodPower==5 and copy.voidPower==10 and copy.editionPower==5 and copy.sealPower==5)
assert(Deck.getCardAttackSpeed(copy)==Deck.getCardAttackSpeed(original))
copy.equipments[1].params.owned.value=8;assert(original.equipments[1].params.owned.value==7)
local combatCopy=Deck.cloneCard(copy)
assert(combatCopy.voidPower==10 and combatCopy.editionPower==5 and combatCopy.sealPower==5)
-- Blood/Void scaling improves gains, without scaling costs or mutation target counts.
for _,power in ipairs({5,10}) do for _,d in ipairs(S.cards) do
    g=fixture();local v=B.clone(d);v.voidPower=power
    assert(S.apply(g,v,requestFor(g,d.id)))
    if d.id=="spec_cryptid" then assert(#g.persistentDeck==5+power and g.playerHp==75 and g.persistentDeck[6].baseChips==21)
    elseif d.id=="spec_immolate" then assert(g.gold==20+10*power and #g.persistentDeck==3)
    elseif d.id=="spec_shrink" then assert(g.maxHandSize==3+power and g.maxPlayerHp==90)
    elseif d.id=="spec_black_hole" then assert(g.handLevels.high_card==1+power)
    elseif d.id=="spec_sigil" then assert(g.playerHp==77)
    elseif d.id=="spec_ouija" then assert(g.playerHp==76) end
    assert(S.describe(v):find("×"..power,1,true))
end end
print("PASS: 7 spectral tools, chest/stored modal, cancellation, validation, 21 migrations, souls, Blood/Void, save/load and next combat")
