local P=require("src.enemy_attack_presentation")
local attacker,other={},{}
local pose={attackers={attacker},index=1,phase="prepare",age=P.timing.prepare}
assert(math.abs(P.motion(pose,attacker)+0.18)<1e-9 and P.motion(pose,other)==0)
pose.phase="strike";pose.age=0
assert(math.abs(P.motion(pose,attacker)+0.18)<1e-9,"no jump at release")
pose.age=P.timing.strike
assert(math.abs(P.motion(pose,attacker)-1.15)<1e-9)
pose.phase="recover";pose.age=0
assert(math.abs(P.motion(pose,attacker)-1.15)<1e-9,"contact pose is held")
pose.age=P.timing.recover
assert(math.abs(P.motion(pose,attacker))<1e-9,"returns to original slot")
local Combat=require("src.combat")
local Game=require("src.game_state")
local Monster=require("src.monster")
for _,fps in ipairs({30,60,144}) do
    for _,order in ipairs({"before","after","all"}) do
        local g=Game.new("red_deck")
        Combat.start(g,Monster.create(1,false,false,1),1)
        local m=g.monster
        m.attackSpeed=order=="before" and 9 or 1
        g.playerHp=100;g.maxPlayerHp=100
        local hits,time,last=0,0,100
        local s=assert(P.start(g,order~="all" and order or nil,5,function(hit,enemy)
            hits=hits+1
            assert(enemy==m and time>=P.timing.pause+P.timing.prepare+P.timing.strike,"damage cannot precede windup and travel")
            assert(g.playerHp==100-hit.damage)
        end,function() end))
        repeat
            if s.phase~="recover" then assert(g.playerHp==last,"HP must wait for contact") end
            time=time+1/fps
        until P.update(s,g,1/fps)
        assert(hits==1 and time>=P.timing.pause+P.timing.prepare+P.timing.strike+P.timing.recover,"single hit and visible recovery")
    end
end
-- Group attacks remain separate, and a lethal hit cancels later attackers.
local g=Game.new("red_deck")
local m=Monster.create(1,false,false,1);m.stage=3
Combat.start(g,m,3)
g.playerHp=1;g.playerArmor=0;g.playerShield=0
local hits=0
local s=assert(P.start(g,nil,nil,function() hits=hits+1 end,function() end))
while not P.update(s,g,1/60) do end
assert(hits==1 and g.playerHp==0)
g.playerHp=1000;g.maxPlayerHp=1000
hits=0
s=assert(P.start(g,nil,nil,function() hits=hits+1 end,function() end))
while not P.update(s,g,1/60) do end
assert(hits==#g.enemies)
print("Enemy attack presentation passed: 30/60/144 FPS, before/after/end turn, contact-only HP, recovery, sequential enemies and lethal cancellation")
