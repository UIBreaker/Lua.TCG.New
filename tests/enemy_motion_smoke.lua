local P=require("src.enemy_attack_presentation")
local Combat=require("src.combat")
local Game=require("src.game_state")
local Monster=require("src.monster")
local function close(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local attacker={}
local pose={attackers={attacker},index=1,phase="prepare",age=0}
for _,support in ipairs({false,true}) do
    pose.intent=support and {type="armor"} or {type="attack"}
    local previous=0
    for _,phase in ipairs({"prepare","strike","recover"}) do
        pose.phase=phase;pose.age=0;close(P.motion(pose,attacker),previous)
        pose.age=1e-6;assert(math.abs(P.motion(pose,attacker)-previous)<1e-5,"no velocity snap at phase boundary")
        pose.age=P.timing[phase];previous=P.motion(pose,attacker)
    end
    close(previous,0)
end
pose.reducedMotion=true;pose.phase="strike";pose.age=.1;close(P.motion(pose,attacker),0)
pose.phase="recover";pose.result={damage=20,absorbed=0,action="attack"}
close(P.camera(pose),0)
pose.reducedMotion=false;pose.age=0;close(P.contact(pose),0)
pose.age=.08;assert(P.contact(pose)>0)
for _,result in ipairs({{missed=true},{blocked=true},{action="heal",damage=0},{damage=0,absorbed=0}}) do
    pose.result=result;close(P.contact(pose),0);close(P.camera(pose),0)
end

for _,fps in ipairs({30,60,120,144}) do
    for _,fast in ipairs({false,true}) do
        for _,scenario in ipairs({"hit","armor","miss","blocked","support","lethal","group"}) do
            local g=Game.new("red_deck")
            local m=Monster.create(1,false,false,1);m.stage=scenario=="group" and 3 or 1
            Combat.start(g,m,m.stage)
            g.playerHp=scenario=="lethal" and 1 or 100;g.maxPlayerHp=100
            g.playerArmor=scenario=="armor" and 100 or 0;g.playerShield=g.playerArmor
            g.deities={};g.potionCombat={evasion=scenario=="miss" or nil}
            for _,enemy in ipairs(require("src.enemy_group").members(g)) do
                enemy.attack=20;enemy.attackSpeed=10;enemy.enemyInventory=nil;enemy.enemyAbility=nil
                enemy.intent={type="attack",value=20};enemy.spnFrozen=scenario=="blocked" and 1 or nil
            end
            if scenario=="support" then m.intent={type="armor",value=5} end
            local hits,elapsed=0,0
            local s=assert(P.start(g,nil,10,function(hit)
                hits=hits+1
                assert(elapsed*(fast and 2 or 1)>=P.timing.pause+P.timing.prepare+P.timing.strike-1e-6)
                if scenario=="miss" then assert(hit.missed) end
                if scenario=="blocked" then assert(hit.blocked) end
                if scenario=="support" then assert(hit.action=="armor") end
            end,function() end))
            local beforeHp,beforeArmor=g.playerHp,g.playerArmor
            repeat
                local oldHp,oldArmor=s.hp.shown,s.armor.shown
                elapsed=elapsed+1/fps
                local done=P.update(s,g,1/fps,fast)
                if hits==0 then close(g.playerHp,beforeHp);close(g.playerArmor,beforeArmor) end
                assert(s.hp.shown<=oldHp+1e-7 and s.armor.shown<=oldArmor+1e-7,"meters must not rebound")
                assert(s.hp.shown>=g.playerHp-1e-7 and s.hp.trail>=s.hp.shown-1e-7)
                if done then break end
                assert(elapsed<10,"timeline must finish")
            until false
            local expected=scenario=="group" and #g.enemies or 1
            assert(hits==expected)
            close(s.hp.shown,g.playerHp);close(s.hp.trail,g.playerHp)
            close(s.armor.shown,g.playerArmor);close(s.armor.trail,g.playerArmor)
            assert(P.update(s,g,1,true) and hits==expected,"completed queue cannot dispatch twice")
            local duration=0;for _,t in pairs(P.timing) do duration=duration+t end
            assert(math.abs(elapsed-duration*expected/(fast and 2 or 1))<=1/fps+1e-6,"FPS-independent phase duration")
        end
    end
end
print("Enemy motion PASS: continuous attack/support poses, 30/60/120/144 FPS, normal/2x, HP and armor settle, miss/block/support/lethal/group, contact once")
