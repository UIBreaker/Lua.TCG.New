local T={stage=0}
local function screenshot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/oneshot_boss_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();if T.next and now<T.next then return end
    if T.stage==0 then
        require("tests.oneshot_boss_smoke")
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local R=require("src.run_manager");local D=require("src.deck")
        game.run.ante=7;game.run.areaStage=7;game.run.regionId="human";game.run.currentBlindIndex=3
        game.run.blinds=R.generateAnteBlinds(7,nil,"human",7)
        game.run.blinds[3].debuff=require("config.free_human_boss_data").byId.human_death_challenger
        local m=R.createBlindMonster(game.run.blinds[3],game,true);require("src.combat").start(game,m,7)
        m.enemyInventory=nil;m.creatureArmor=0;game.deities={}
        require("src.enemy_abilities").plan(game,m)
        game.hand={D.newCard(5,"spades"),D.newCard(7,"hearts"),D.newCard(9,"clubs")}
        assert(require("src.enemy_art").image(m,{}),"Missing new portrait")
        T.baseAttack=require("src.enemy_abilities").attack(m);T.stage=1;T.next=now+1
    elseif T.stage==1 then
        screenshot("before");T.stage=2;T.next=now+.35
    elseif T.stage==2 then
        local m=game.monster;local raw=m.maxHp*2
        local damage,dead=require("src.combat").resolvePlayerAttack(game,raw,{hitChance=1,missed=false})
        assert(not dead and m.hp==damage and m.maxHp==damage and require("src.enemy_abilities").attack(m)==T.baseAttack*3)
        require("src.boss_abilities").handEnd(game);require("src.boss_abilities").handEnd(game)
        assert(require("src.free_human_bosses").playerDamageFactor(game)==1.4)
        T.stage=3;T.next=now+.4
    elseif T.stage==3 then
        screenshot("rebirth");T.stage=4;T.next=now+.4
    else
        local m=game.monster;require("src.monster").takeDamage(m,1,true)
        local _,dead=require("src.monster").takeDamage(m,m.maxHp*10,true)
        assert(dead and m.hp==0)
        T.done=true;print("Death Challenger UI PASS: portrait, full-HP rebirth/no premature victory, x3 damage, +40% player HUD and chip-then-kill");love.event.quit(0)
    end
end
return T
