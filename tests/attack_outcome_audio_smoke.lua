-- Exercise resolved armor/HP, including zero HP damage, revives and splash-only kills.
local Feel=require("src.scoring_presentation")
local Monster=require("src.monster")
local Feedback=require("src.combat_feedback")
local previousSound=package.loaded["src.sound"]
local plays={}
package.loaded["src.sound"]={play=function(name,pitch) plays[#plays+1]={name=name,pitch=pitch} end}
local ui={BATTLE_CENTER_X=640,formatNumber=tostring,getScoringCardX=function(i) return 300+i*110 end}
local result={steps={{type="base_hand",chips=10,mult=1},{type="final_score",finalScore=100}},finalScore=100}
local cases={
    {armor=30,raw=15,kind="impact"},
    {armor=30,raw=30,kind="armor_break"}, -- Break with zero HP damage still sounds.
    {armor=30,raw=45,kind="armor_break"},
    {armor=0,raw=100,kind="finisher"},
    {armor=30,raw=130,kind="armored_finisher"},
    {armor=0,raw=0,kind="impact"},
    {armor=0,raw=150,creatureKind="ancient_skeleton",kind="impact"},
    {armor=30,raw=150,creatureKind="ancient_skeleton",kind="armor_break"},
    {armor=30,raw=45,hasBed=true,kind="armor_break"},
    {armor=30,raw=150,missed=true},
    {armor=0,raw=0,hp=0,kind="impact"},
    {armor=0,raw=10,outcome={armorBroken=false,finisher=true},kind="finisher"},
    {armor=0,raw=10,outcome={armorBroken=true,finisher=true},kind="armored_finisher"},
    {armor=0,raw=10,outcome={armorBroken=true,finisher=false},kind="armor_break"},
    {armor=0,raw=100,isBoss=true,kind="boss_finisher"},
    {armor=30,raw=130,isBoss=true,kind="boss_armored_finisher"},
    {armor=30,raw=30,isBoss=true,kind="armor_break"},
    {armor=0,raw=60,isBoss=true,phase=1,kind="impact"},
    {armor=0,raw=150,isBoss=true,creatureKind="ancient_skeleton",kind="impact"},
    {armor=30,raw=150,isBoss=true,creatureKind="ancient_skeleton",kind="armor_break"},
    {armor=30,raw=150,isBoss=true,missed=true},
    {armor=0,raw=100,isElite=true,kind="finisher"},
    {armor=0,raw=10,outcome={armorBroken=false,finisher=true,bossFinisher=true},kind="boss_finisher"},
    {armor=0,raw=10,outcome={armorBroken=true,finisher=true,bossFinisher=true},kind="boss_armored_finisher"},
    {armor=0,raw=10,isBoss=true,outcome={armorBroken=false,finisher=true,bossFinisher=false},kind="finisher"},
    {armor=0,raw=0,hp=0,isBoss=true,kind="impact"},
}
local checks=0
for _,id in ipairs(require("config.nen_vfx_config").order) do
    for tier=1,3 do for _,c in ipairs(cases) do
        local enemy={hp=c.hp or 100,maxHp=100,creatureArmor=c.armor,creatureKind=c.creatureKind,hasBed=c.hasBed,
            isBoss=c.isBoss,isElite=c.isElite,phase=c.phase,attack=10}
        local anim={playedCards={{id="a",rank=3,suit="spades"},{id="b",rank=6,suit="hearts"},{id="c",rank=9,suit="clubs"}},floatingTexts={}}
        Feel.start(anim,result,ui,{},enemy.hp,enemy,id,{lab=true})
        anim.sequence.attack.nen.tier=tier
        local damage=Monster.takeDamage(enemy,c.raw)
        local hp,armor=enemy.hp,enemy.creatureArmor
        plays={}
        local authored=Feel.damageApplied(anim,enemy.hp,damage,c.missed,enemy.creatureArmor,c.outcome)
        local suffix=tier==3 and "_extreme" or tier==2 and "_strong" or ""
        if c.missed then
            assert(#plays==0 and not authored,"misses must have no contact or outcome sound")
        else
            assert(#plays==1 and plays[1].name=="nen_"..id.."_"..c.kind..suffix,"one combined authored contact: "..id.."/"..c.kind)
            assert(math.abs(plays[1].pitch-(1.05-(tier-1)*.11))<.00001,"same contact pitch as its power tier")
            assert(authored==(c.kind:find("finisher",1,true)~=nil),"only real death outcomes suppress fallback death audio")
        end
        local once=#plays
        Feel.damageApplied(anim,0,999,false,0,{armorBroken=true,finisher=true})
        assert(#plays==once,"duplicate damage callback must never replay a kill")
        assert(enemy.hp==hp and enemy.creatureArmor==armor,"audio must not change combat state")
        checks=checks+1
    end end
end
-- Keep armor particles and numbers, but let the authored break own the sound.
Feedback.vfx={};plays={}
Feedback.add({},"armor",-30,640,176,tostring,true)
assert(#plays==0 and #Feedback.vfx==1 and Feedback.vfx[1].silent)
Feedback.add({},"armor",-5,640,176,tostring)
Feedback.updateVfx(.04)
assert(#plays==1,"partial armor loss retains its normal feedback")
local keys={"src.death_vfx","render.camera","render.lighting","src.enemy_art"}
local saved={};for _,key in ipairs(keys) do saved[key]=package.loaded[key] end
package.loaded["src.death_vfx"]=nil
package.loaded["render.camera"]={kick=function() end}
package.loaded["render.lighting"]={flash=function() end}
package.loaded["src.enemy_art"]={key=function() return "mini" end}
local D=require("src.death_vfx")
for i=1,D.config.particles.max do D.pool[i]={} end
for _,authored in ipairs({false,true}) do
    plays={};D.reset()
    local dead={hp=0}
    assert(D.startEnemy(dead,640,"HIGH",false,authored))
    assert(not D.startEnemy(dead,640,"HIGH",false,authored),"death restart must be silent")
    D.update(.23);D.update(.1)
    if authored then assert(#plays==0,"authored kill owns contact and disintegration")
    else assert(#plays==2 and plays[1].name=="enemy_death_hit" and plays[2].name=="enemy_ash_break","incidental deaths keep their fallback") end
end
for _,key in ipairs(keys) do package.loaded[key]=saved[key] end
package.loaded["src.sound"]=previousSound
print("Outcome audio PASS: "..checks.." resolved contacts; boss/elite/phase change, armor-only breaks, three tiers, revives, misses, splash outcomes, one kill cue and death fallback")
return true
