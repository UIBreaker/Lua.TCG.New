local Art=require("src.enemy_art")
local Run=require("src.run_manager")
local seen={}
for _,key in ipairs(Run.BOSS_KEYS) do
    local m={isBoss=true,bossData=Run.BOSS_DEBUFFS[key]}
    assert(Art.key(m)==key,"boss identity must come from current boss data")
    local f=assert(io.open(Art.path(key),"rb"),"missing boss art: "..key);f:close()
    assert(not seen[Art.path(key)],"bosses must have distinct assets");seen[Art.path(key)]=true
end
for round,key in ipairs(Art.normal) do
    assert(Art.key({round=round,encounterCount=(round-1)*3+1})==key,"all six small blind variants must appear")
    local f=assert(io.open(Art.path(key),"rb"),"missing normal art: "..key);f:close()
end
local fallback={enemySmall={},enemyElite={},enemyBoss={}}
assert(Art.image({isBoss=true,bossData={id="unknown"}},fallback)==fallback.enemyBoss)
assert(Art.image({isElite=true},fallback)==fallback.enemyElite)
local m={isBoss=true,bossData={id="the_fish"}}
local loadedImages=Art.images
Art.images={the_fish={},the_water={}}
assert(Art.image(m,fallback)==Art.images.the_fish)
m.bossData={id="the_water"}
assert(Art.image(m,fallback)==Art.images.the_water,"debug boss swaps must update the sprite")
Art.images=loadedImages
print("Enemy art smoke passed: 6 normal variants, 10 unique run bosses, fallback and live boss swaps")
return true
