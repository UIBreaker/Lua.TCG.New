local T={}
function T.verify()
    local Game=require("src.game_state")
    local D=require("src.deities")
    local Reward=require("src.reward_system")
    local Rng=require("src.rng")
    local g=Game.new();g.deities={};g.gold=24;g.handsRemaining=2;g.selectedFaction="aurelia"
    g.monster={hp=0,maxHp=100,isBoss=true};g.enemies={g.monster}
    g.lastRoundDeityRewards={bonusGold=0,details={}}
    assert(D.addDeity(g,D.CATALOG.spirit_victory_bounty,1));D.evolve(g.deities[1]);D.evolve(g.deities[1])
    Rng.seed(20261014)
    local result=Reward.begin(Reward.calculate({type="boss",baseReward=5,title="BOSS",name="PHÚC LINH KHẢI HOÀN"},g),g,{lootTableId="boss"})
    assert(result.spnLootBonus.extraRolls==3 and result.spnLootBonus.rareWeightPct==200)
    local anim=Reward.newAnimation(result.breakdown,result)
    local gold,rng=g.gold,Rng.getState()
    Reward.finishImmediately(anim);anim.lootPage=1
    local graphics=love.graphics
    local canvas=graphics.newCanvas(1280,720)
    graphics.push("all");graphics.setCanvas(canvas);graphics.origin();graphics.clear(.025,.035,.06)
    Reward.draw(anim,1280,720,0,0,{},g)
    graphics.pop()
    local file=assert(io.open("docs/spn_bounty_ceremony.png","wb"))
    file:write(canvas:newImageData():encode("png"):getString());file:close();canvas:release()
    assert(g.gold==gold and Rng.getState()==rng and #anim.slots>=6,"render never grants or rerolls")
    print("SPN bounty native ceremony PASS: evolved extra grants, visible quantity/rarity blessing, shared paging and pure rendering")
end
return T
