local UI=require("src.ui")
local Modal=UI.AbilityUI
local Evolution=require("ui.evolution_motion")
local Potion=require("ui.potion_effects")
local Potions=require("src.potions")
local Feel=UI.ScoringFeel
local Deck=require("src.deck")
local Run=require("src.run_manager")
local Rng=require("src.rng")
local function close(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." ~= "..tostring(b)) end
local seed=Rng.getState()
for _,fps in ipairs({30,60,120,144}) do
 for _,fast in ipairs({false,true}) do
  for _,reduced in ipairs({false,true}) do
   UI.CardPhysics.reducedMotion=reduced
   for _,spn in ipairs({false,true}) do
    local c=Deck.newCard(2,"hearts")
    if spn then c={};for k,v in pairs(require("src.deities").getStarterDeity("valoria")) do c[k]=v end end
    c.evolutionLevel=0
    local item=Run.createEvolutionCard()
    local game={persistentDeck=spn and {} or {c},hand={},deities=spn and {c} or {},consumables={item},gold=22,handsRemaining=3}
    local calls=0;assert(Modal.openEvolution(game,item,function() calls=calls+1 end))
    Modal.current.selected=c;assert(Modal.confirm())
    local m=Modal.current;local r=m.ritual
    assert(r.before.evolutionLevel==0 and c.evolutionLevel==1 and #game.consumables==0 and calls==1)
    assert(not Modal.confirm());Modal.key("escape");assert(Modal.current==m,"committed ritual cannot be canceled into a second use")
    local p=Evolution.pose(r);assert(p.old);close(p.scale,1);close(p.scaleX,1);close(p.y,0)
    while Modal.current do
     Modal.update(1/fps,fast,reduced)
     local pose=Evolution.pose(r)
     if reduced then close(pose.scale,1);close(pose.scaleX,1);close(pose.y,0) end
     if r.age<Evolution.contactAt then assert(pose.old) end
     assert(r.age<1.1)
    end
    assert(r.contacted and calls==1 and c.evolutionLevel==1 and game.gold==22 and game.handsRemaining==3)
    p=Evolution.pose(r);assert(not p.old);close(p.y,0);close(p.scale,1);close(p.scaleX,1)
   end
   for _,kind in ipairs({"heal","armor","damage","empower","draw","slow","accuracy","evasion","gold_blood","armor_break","speed","rest"}) do
    Potion.active={};local game={gold=20,playerHp=60,handsRemaining=3}
    Potions.emit(game,kind,"TEST",kind=="gold_blood" and 0 or 1)
    local event=game.potionFeedback[1];event.sourceX=1110;event.sourceY=250
    Potion.update(game,0,reduced,"playing",fast)
    assert(#game.potionFeedback==0 and #Potion.active==1)
    local e=Potion.active[1];local p=Potion.pose(e)
    close(p.x,reduced and e.x or 1110);close(p.y,reduced and e.y or 250)
    local time=0
    while #Potion.active>0 do
     Potion.update(game,1/fps,reduced,"playing",fast);time=time+1/fps
     p=Potion.pose(e)
     if e.age<e.contactAt then assert(not e.contacted and p.alpha==0) end
     if reduced then close(p.x,e.x);close(p.y,e.y);close(p.iconAlpha,0) end
     assert(time<2.1)
    end
    assert(e.contacted and game.gold==20 and game.playerHp==60 and game.handsRemaining==3)
   end
  end
 end
end
for _,age in ipairs({0,.04,.12,.24,.36}) do
 local anim={deityHit={[1]=age}}
 local scale,y,rotation,glow=Feel.spnPose(anim,1,false)
 assert(scale>=1 and scale<1.06 and y<=0 and y> -7 and glow>=0)
 if age==0 or age==.36 then close(scale,1);close(y,0);close(rotation,0) end
 scale,y,rotation=Feel.spnPose(anim,1,true);close(scale,1);close(y,0);close(rotation,0)
end
Potion.active={};UI.CardPhysics.reducedMotion=false
assert(Rng.getState()==seed,"presentation must preserve gameplay RNG")
print("Ability motion PASS: 12 potion motifs, card/SPN ritual, exact rest, single commit/callback, reduced/fast at 30/60/120/144 FPS; no resource/RNG mutation")
return true
