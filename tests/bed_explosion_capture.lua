local T={};local E=require("src.bed_explosion");local R=require("render.renderer")
local D=require("src.deck");local Deities=require("src.deities");local Group=require("src.enemy_group")
local case,started,expected,lastHp,hits=0,nil,0,0,0
for _,value in ipairs(arg or {}) do if value=="--bed-preview-only" then case=11 end end
local sawPending=false;local captured={};local originalDraw=E.draw;local originalUpdate=E.update
local previewIndex=0;local previews={{"anticipation",.035},{"contact",.050},{"shockwave",.11},{"fireball",.19},{"debris",.37},{"smoke",.75}}
local function shot(name)
 if captured[name] then return end;captured[name]=true
 love.graphics.captureScreenshot(function(data)
  local f=assert(io.open("docs/bed_explosion/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
 end)
end
function T.update(game,cb)
 if case==11 then
  if previewIndex==0 then
   for _,name in ipairs({"bed_explosion_charge","bed_explosion_boom","bed_explosion_debris","bed_explosion_rumble"}) do assert(require("src.sound").has(name),"missing audio hook: "..name) end
   assert(E.fireShader and not E.shaderError,"fire shader must compile")
   R.setQuality("HIGH")
   if not game.monster then cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false) end
   R.stateKey="battle";R.transitionPending=false;R.transitionAge=R.config.transition.duration
  end
  previewIndex=previewIndex+1
  if previewIndex>#previews then
   E.update=originalUpdate;E.draw=originalDraw;E.clear()
   print("Bed explosion captures: anticipation, contact, shockwave, debris and smoke / HIGH passed")
   love.event.quit(0);return
  end
  require("render.lighting").events={}
  E.start(game.monster.screenX or 630,410,"HIGH",R.scene.weather)
  local age=previews[previewIndex][2]
  while E.age<age-.000001 do
   local dt=math.min(1/120,age-E.age)
   originalUpdate(dt);require("render.lighting").update(dt)
  end
  if age>=E.config.anticipation and not E.detonated then originalUpdate(.000002) end
  E.pending=false
  E.update=function() end
  shot(previews[previewIndex][1]);return
 end
 if not started then
  if case==0 then
   assert(E.fireShader and not E.shaderError,"fire shader must compile")
   for _,name in ipairs({"bed_explosion_charge","bed_explosion_boom","bed_explosion_debris","bed_explosion_rumble"}) do assert(require("src.sound").has(name),"missing audio hook: "..name) end
   E.draw=function()
    if E.active and E.detonated then
     assert(not game.monster.hasBed and game.monster.hp==10000000-expected-math.floor(expected*2),"rendered contact must match HP")
    end
    local g=love.graphics;local canvas,shader,image=g.newCanvas,g.newShader,g.newImage
    local function prohibit() error("GPU allocation during explosion draw") end
    g.newCanvas,g.newShader,g.newImage=prohibit,prohibit,prohibit
    local ok,err=pcall(originalDraw)
    g.newCanvas,g.newShader,g.newImage=canvas,shader,image
    assert(ok,err)
   end
  end
  case=case+1
  if case>10 then
   assert(#R.post.diagnostics==0,"shader fallback")
   print("Bed explosion live: 10 real three-enemy traps / contact HP sync / unchanged 200% AoE / input lock / 3 qualities / audio resources / shaders passed")
   E.draw=originalDraw;E.update=function() end;captured={};return
  end
  cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false);cb.setScoringSpeed(case%2==0)
  R.setQuality(({"LOW","MEDIUM","HIGH"})[(case-1)%3+1])
  game.enemies={game.monster,require("src.monster").create(3,false),require("src.monster").create(3,false)}
  for _,m in ipairs(game.enemies) do m.group=game.enemies;m.hp=10000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.creatureArmor=0;m.attackSpeed=.01 end
  assert(#Group.members(game)==3)
  game.deities={};Deities.addDeity(game,Deities.CATALOG.spirit_hell_sleep)
  game.consumables={require("src.shop").healingItem("upper","cons_bed").consumable}
  assert(require("src.inventory").useBed(game,1,game.monster))
  game.hand={D.newCard(8,"spades")};game.deck={};game.discardPile={};game.selectedIndices={};game.abilityApproved={}
  cb.selectCardIndex(1);cb.playSelectedHand()
  local anim,state=cb.getScoringState();assert(state=="scoring")
  expected=anim.scoringData.finalScore;lastHp=game.monster.hp;hits=0;sawPending=false;started=love.timer.getTime()
  local hands=game.handsRemaining;cb.playSelectedHand();assert(hands==game.handsRemaining)
 else
  local a,state=cb.getScoringState()
  assert(love.timer.getTime()-started<25,"combat timeout")
  if a.pendingBedScore then
   sawPending=true;assert(game.monster.hp==10000000 and game.monster.hasBed,"damage must wait for blast")

  end
  if E.active and E.detonated and not a.pendingBedScore then
   assert(not game.monster.hasBed and game.monster.hp==10000000-expected-math.floor(expected*2),"HP/contact sync")

  end
  if game.monster.hp~=lastHp then hits=hits+1;lastHp=game.monster.hp end
  if state~="scoring" then
   assert(sawPending and hits==1 and a.damageDealt==expected and not a.pendingBedScore)
   for i,m in ipairs(Group.members(game)) do assert(m.hp==10000000-math.floor(expected*2)-(i==1 and expected or 0),"unchanged AoE") end
   print("Bed real combat "..case.." / "..R.quality.." / "..expected.." passed")
   started=nil
  end
 end
end
return T
