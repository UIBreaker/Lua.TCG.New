local T={case=0}
local Deck=require("src.deck")
local Combat=require("src.combat")
local Rng=require("src.rng")
local cases={{kind="armor",target=2},{kind="speed",target=1},{kind="damage",target=2},
    {kind="heal",target=2},{kind="heal",target=1},{kind="player_miss"},{kind="enemy_miss"},
    {kind="armor",target=2,stage=20,value=250000}}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/combat_tactics_"..name..".png","wb"))
        file:write(data:encode("png"):getString());file:close()
    end)
end
function T.update(game,cb)
    if not T.started then
        T.case=T.case+1
        local spec=cases[T.case]
        if not spec then
            Rng.random=T.random
            print("Combat tactics runtime passed: armor, speed, damage, ally/self healing, player miss and enemy miss with real scoring/UI")
            love.event.quit(0);return
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.monster.stage=3;Combat.start(game,game.monster,3)
        game.hand={Deck.newCard(8,"spades")};game.selectedIndices={};game.deities={}
        if spec.kind=="enemy_miss" then game.hand[1].speedBonus=27-Deck.peekCardAttackSpeed(game.hand[1]) end
        game.playerHp=1000;game.maxPlayerHp=1000;game.playerArmor=0;game.playerShield=0
        for i,m in ipairs(game.enemies) do
            m.hp=10000;m.maxHp=10000;m.damageLagHp=m.hp
            m.creatureArmor=0;m.attack=10;m.attackSpeed=i==1 and spec.kind~="enemy_miss" and 99 or 1
            if spec.stage then m.stage=spec.stage end
            m.intent={type="attack",value=10,label="Tấn công 10 ST"}
        end
        if spec.target then
            local actor,target=game.enemies[1],game.enemies[spec.target]
            if spec.stage then target.hp=1000000;target.maxHp=1000000;target.damageLagHp=1000000 end
            actor.intent={type=spec.kind,targetIndex=spec.target,label=spec.kind.." → #"..spec.target}
            if spec.kind=="heal" then target.hp=4000;target.damageLagHp=4000 end
        end
        T.random=T.random or Rng.random
        Rng.random=function(low,high)
            if low then return T.random(low,high) end
            return spec.target and 0 or spec.kind=="enemy_miss" and .1 or .99
        end
        T.shot=false;T.checked=false;T.started=love.timer.getTime()
        local anim=cb.getScoringState();anim.floatingTexts={}
        game.abilityApproved={};cb.selectCardIndex(1);cb.playSelectedHand()
        if spec.kind=="enemy_miss" then assert(game.lastPlayerAttackSpeed==27) end
    else
        local anim,state=cb.getScoringState();local spec=cases[T.case]
        assert(love.timer.getTime()-T.started<25,"combat tactics runtime timeout")
        local turn=anim.enemyTurn
        if spec.target and turn and turn.index==1 and turn.phase=="recover" and not T.checked then
            local result=assert(turn.result)
            assert(result.action==spec.kind and result.target==game.enemies[spec.target])
            assert(game.playerHp==1000 and result.value>0,"support consumes an action without player damage")
            if spec.value then assert(result.value==spec.value and result.target.creatureArmor==spec.value) end
            if spec.kind=="speed" or spec.kind=="damage" then assert(result.target.combatBuffs[spec.kind].turns==2) end
            if spec.kind=="heal" then assert(result.target.hp==6000) end
            T.checked=true;shot(spec.kind.."_"..spec.target..(spec.stage and "_stage"..spec.stage or ""));T.shot=true
        elseif spec.kind=="player_miss" and state=="scoring" and anim.active and anim.sequence and anim.sequence.damageApplied and not T.checked then
            assert(anim.playerAttackResult.missed and anim.damageDealt==0 and game.enemies[1].hp==10000)
            assert(anim.sequence.missed and anim.hitStop==0)
            local x,y= require("src.scoring_presentation").camera(anim);assert(x==0 and y==0)
            T.checked=true;shot("player_miss");T.shot=true
        elseif spec.kind=="enemy_miss" and turn and turn.phase=="recover" and not T.checked then
            assert(turn.result.missed and turn.result.damage==0 and game.playerHp==1000)
            assert(turn.result.hitChance==.05,"27 vs 1 must display and resolve 5% accuracy")
            T.checked=true;shot("enemy_miss");T.shot=true
        end
        if T.checked and state=="playing" and not anim.active and not anim.enemyTurn then
            if spec.kind=="enemy_miss" then assert(game.playerHp==1000,"all slow enemies miss under the forced roll") end
            print("Combat tactics runtime case "..T.case.." passed ("..spec.kind..")")
            Rng.random=T.random;T.started=nil
        end
    end
end
return T
