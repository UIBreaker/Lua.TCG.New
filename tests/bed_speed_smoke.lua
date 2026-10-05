local Shop=require("src.shop")
local I=require("src.inventory")
local Combat=require("src.combat")
local D=require("src.deities")
local Deck=require("src.deck")
local Monster=require("src.monster")
local function bed() return Shop.healingItem("upper","cons_bed").consumable end
local function game()
    local a={name="A",hp=1000,maxHp=1000,attack=1,attackSpeed=1}
    local b={name="B",hp=1000,maxHp=1000,attack=1,attackSpeed=1}
    local g={monster=a,enemies={a,b},deities={},playerHp=20,maxPlayerHp=150,consumables={bed()}}
    a.group=g.enemies;b.group=g.enemies
    return g,a,b
end
local g,a,b=game()
assert(I.useBed(g,1) and g.playerHp==150 and #g.consumables==0)
g.consumables={bed()};assert(not I.useBed(g,1) and #g.consumables==1)
assert(I.useBed(g,1,a) and a.hasBed)
assert(not I.useBed(g,1,b))
Combat.resolvePlayerAttack(g,50)
assert(a.hp==1000 and not a.hasBed and a.bedHeal==50 and b.hp==1000)
g,a,b=game();assert(I.useBed(g,1,a))
Monster.takeDamage(a,0);assert(a.hasBed)
Monster.takeDamage(a,2000);assert(a.hp==0 and not a.hasBed)
g,a,b=game();assert(I.useBed(g,1,a))
g.deities={D.CATALOG.spirit_hell_sleep}
local damage,dead,hits=Combat.resolvePlayerAttack(g,50)
assert(damage==50 and not dead and #hits==2)
assert(a.hp==850 and b.hp==900 and not a.hasBed and not a.bedHeal)
Combat.resolvePlayerAttack(g,50);assert(a.hp==800 and b.hp==900,"trap is single use")
g,a,b=game();I.useBed(g,1,a);g.deities={D.CATALOG.spirit_hell_sleep}
Combat.resolvePlayerAttack(g,1500);assert(a.hp==0 and b.hp==0,"a lethal first hit must still explode")
g,a,b=game();I.useBed(g,1,a);g.deities={D.CATALOG.spirit_hell_sleep}
a.isBoss=true;a.bossState={slotLock={kind="spn",slot=1,untilHand=1},handIndex=1,passiveUntil=0}
Combat.resolvePlayerAttack(g,50);assert(a.hp==1000 and b.hp==1000 and not a.hasBed,"locked SPN leaves normal bed healing")
-- The real handler preserves cancellation and dispatches sleeping to the turn boundary.
local f=assert(io.open("main.lua"));local source=f:read("*a");f:close()
local first=assert(source:find("local function useConsumable(idx)",1,true))
local last=assert(source:find("local function activateConsumable",first,true))
local chunk=source:sub(first,last-1).."\nreturn useConsumable"
local factory=assert((loadstring or load)(chunk))
g,a,b=game();local callback,choices;local skipped=0
local env=setmetatable({game=g,state="playing",Shop=Shop,Sound=require("src.sound"),anim={floatingTexts={}},
    saveRunAtSafePoint=function() end,UI={Inventory=I,BossAbilities=require("src.boss_abilities"),
    AbilityUI={openChoices=function(_,c,cb) choices=c;callback=cb end},Abilities={consumableUsed=function() end},
    endBedTurn=function() skipped=skipped+1 end}}, {__index=_G})
if setfenv then setfenv(factory,env) else factory=assert(load(chunk,"bed handler","t",env)) end
local use=factory()
assert(use(1) and #g.consumables==1 and #choices[1].options==3)
callback({});assert(#g.consumables==1 and skipped==0)
callback({{target={id="bed_self"}}});assert(g.playerHp==150 and skipped==1 and #g.consumables==0)
g.consumables={bed()};assert(use(1));callback({{target=a}})
assert(a.hasBed and skipped==1 and #g.consumables==0)
-- New speed cards use their own params through the existing target picker.
for _,id in ipairs({"cons_speed_small","cons_speed_large"}) do
    local item=Shop.healingItem("upper",id);g.consumables={item.consumable}
    g.hand={Deck.newCard(7,"spades")};env.Deck=Deck
    assert(use(1) and env.pendingSpeedCard.id==id)
    local c=g.hand[1];local old=Deck.getCardAttackSpeed(c)
    Deck.applyAttackSpeedBonus(c,Shop.getConsumableParams(item.consumable).speed)
    assert(Deck.getCardAttackSpeed(c)==old+(id=="cons_speed_small" and 3 or 10))
end
local restored=require("src.persistence").restoreSnapshot(require("src.persistence").makeSnapshot({
    deities={D.CATALOG.spirit_hell_sleep},consumables={bed()},persistentDeck={}},"shop"))
assert(restored.deities[1].onAttack().bedExplosionPct==200 and restored.consumables[1].category=="bed")
print("Bed/speed passed: self heal, cancel, lost turn dispatch, enemy heal, lethal trap, 200% AoE, one use, speed params and persistence")
