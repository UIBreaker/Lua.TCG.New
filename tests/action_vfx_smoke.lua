local F=require("src.combat_feedback")
local P=require("src.ux_polish")
local Shop=require("src.shop")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Equipment=require("src.equipment")
F.clearVfx()
for _,fps in ipairs({30,60,144}) do
    for kind,profile in pairs(F.config.profiles) do
        F.clearVfx();local e=assert(F.emit(kind,640,360,1000000));assert(e.scale<=F.config.maxScale)
        for i=1,math.ceil(profile.duration*fps)+1 do F.updateVfx(1/fps) end
        assert(#F.vfx==0)
    end
end
assert(not F.emit("unknown",0,0) and not F.emit("heal",0,0,0))
for i=1,100 do F.emit("heal",0,0,i) end
assert(#F.vfx==F.config.cap)
F.clearVfx()
for _,v in ipairs({{"armor",10,"armor_gain"},{"armor",-10,"armor_loss"},{"heal",10,"heal"},{"heal",-10,"hurt"}}) do
    F.add({},v[1],v[2],300,114);assert(F.vfx[#F.vfx].kind==v[3])
end
local c=Deck.newCard(8,"spades")
F.clearVfx();assert(F.destroyCard(c,400,400));assert(not F.destroyCard(c,400,400) and #F.vfx==1)
local g=Game.new();g.hand={c};g.persistentDeck={c};g.gold=100
local ui={CardPhysics={getState=function() return nil end}}
local before=P.snapshot(g);assert(Equipment.attach(c,Equipment.ITEMS.gem_fire))
P.changed(ui,g,before,Equipment.ITEMS.gem_fire);assert(#P.applications==1 and P.applications[1].kind=="equip")
local applicationDuration=P.applications[1].duration or P.config.application
F.clearVfx();P.update(applicationDuration*0.59,false,"playing");assert(#F.vfx==0)
P.update(applicationDuration*0.02,false,"playing");assert(#F.vfx==1 and F.vfx[1].kind=="equip")
P.applications={};P.job=nil
local stock={card=Deck.newCard(5,"clubs"),category="card",cost=4}
local shop=Shop.new();shop.items={stock};local r={x=400,y=150,w=80,h=110}
F.clearVfx();g.gold=0;P.focusItem(stock,"stock",1,r)
assert(not P.confirm(shop,g) and #F.vfx==0)
g.gold=100;assert(P.confirm(shop,g));assert(g.gold==96 and #F.vfx==0)
assert(not P.confirm(shop,g) and #F.vfx==0)
P.update(P.config.buy*P.config.buyFlightEnd-0.001,false,"shop",shop);assert(#F.vfx==0)
P.update(0.002,false,"shop",shop);assert(F.vfx[1].kind=="buy" and F.vfx[1].x==P.job.target.x)
P.update(2,false,"shop",shop)
local item={id="test",category="edition",cost=4,name="test"};g.consumables={item}
P.focusItem(item,"consumable",1,r);assert(P.confirm(shop,g));assert(#g.consumables==0 and F.vfx[#F.vfx].kind=="sell")
P.update(2,false,"shop",shop)
g.soulDestroyActive=true;g.soulDestroyConsumable={id="soul_reaper"};g.consumables={g.soulDestroyConsumable};local target=g.persistentDeck[2];local oldSouls=g.souls or 0
P.focusItem(target,"card",nil,r);assert(P.confirm(shop,g));assert((g.souls or 0)>oldSouls and F.vfx[#F.vfx].kind=="destroy")
print("Action VFX PASS: 10 profiles at 30/60/144 FPS, bounds/expiry, stat signs, destruction dedup, equip at contact, failed/successful/spam transactions, soul destruction")
