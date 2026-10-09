-- lovec.exe . --capture-shop --capture-combat-ui (isolated from player saves).
local T={stage=0,deadline=0}
local UI=require("src.ui");local D=require("src.deck");local Group=require("src.enemy_group")
local function pointer(x,y,mouse)
 local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
 local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
 love.mouse.setPosition(px,py)
 if mouse then love.mousepressed(px,py,mouse);love.mousereleased(px,py,mouse) end
end
local function control(cb,id,click)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then
  assert(b.x>=0 and b.y>=0 and b.x+b.w<=1280 and b.y+b.h<=720,"control bounds "..id)
  if click then assert(not b.disabled,id);pointer(b.x+b.w/2,b.y+b.h/2,1) end
  return b
 end end
 error("Missing control "..id)
end
local function shot(name)
 pointer(2,2)
 love.graphics.captureScreenshot(function(data) local f=assert(io.open("docs/combat_ui_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close() end)
end
function T.update(game,cb)
 local now=love.timer.getTime();if now<T.deadline then return end
 local n=T.stage
 if n==0 then cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
 elseif n==1 then
  if not T.materialCheck then require("tests.combat_material_smoke")(UI);T.materialCheck=true end
  if not T.starterShot then shot("starter");T.starterShot=true;T.deadline=now+.6;return end
  assert(control(cb,"play").disabled)
  for _,id in ipairs({"sort_rank","sort_suit","discard","open_settings","open_deck_viewer","open_handbook"}) do control(cb,id) end
  game.monster.stage=3;require("src.combat").start(game,game.monster,3)
  game.hand={};game.selectedIndices={};game.maxHandSize=8
  game.unlockedHands={high_card=true,pair=true,flush=true,three_of_a_kind=true}
  for i=1,8 do game.hand[i]=D.newCard(i<4 and 7 or i+3,({"hearts","clubs","diamonds","spades"})[(i-1)%4+1]) end
  for _,m in ipairs(game.enemies) do m.hp=100000;m.maxHp=100000;m.damageLagHp=100000;m.attackSpeed=1 end
  local ds=require("src.deities").CATALOG
  game.deities={ds.spirit_blade,ds.spirit_drum}
  game.consumables={require("src.shop").healingItem("featured","healing_potion").consumable}
  game.gold=126;game.souls=38;game.playerHp=72;game.playerArmor=18;game.enemyPoison=3
 elseif n==2 then
  assert(#game.enemies==3);control(cb,"sort_suit",true)
 elseif n==3 then
  assert(game.sortMode=="suit");control(cb,"sort_rank",true)
  local x,y,w,h=Group.rect(3,3);pointer(x+w/2,y+h/2,1);assert(game.monster==game.enemies[3])
  cb.selectCardIndex(1);cb.selectCardIndex(2);cb.selectCardIndex(3)
 elseif n==4 then
  assert(not control(cb,"play").disabled)
  if not T.previewShot then shot("squad_preview");T.previewShot=true;T.deadline=now+.6;return end
  local r=require("ui.layout").battle
  for _,rect in ipairs({r.spm,r.consumables}) do local _,y,_,h=require("ui.layout").fanCardRect(rect,1,6);assert(y>=rect[2]+34 and y+h<=rect[2]+rect[4]-17) end
  T.hp=game.monster.hp;T.hands=game.handsRemaining;control(cb,"play",true);T.scoringStart=now
 elseif n==5 then
  local a,state=cb.getScoringState()
  if state=="scoring" then
   if T.resumed and not T.scoringShot and a.active and a.sequence and (a.displayAura or 0)>0 then shot("scoring");T.scoringShot=true end
   assert(control(cb,"play").disabled);assert(control(cb,"sort_rank").disabled)
   if not T.paused then control(cb,"open_pause_menu",true);T.paused=true;T.deadline=now+.2;return
   elseif not T.resumed then control(cb,"pause_resume",true);T.resumed=true;T.deadline=now+.2;return end
   assert(now-T.scoringStart<25,"scoring timeout")
   T.deadline=now+.15;return
  end
  assert(T.scoringShot and game.monster.hp<T.hp and game.handsRemaining==T.hands-1,"real hand score once")
  cb.startNewGame("red_deck");cb.startMonsterEncounter(20,true)
  game.hand={D.newCard(13,"spades"),D.newCard(12,"hearts"),D.newCard(11,"clubs")};game.selectedIndices={}
  game.maxHandSize=3;game.monster.attackSpeed=999
  cb.selectCardIndex(1)
 elseif n==6 then
  if not T.bossShot then shot("boss");T.bossShot=true;T.deadline=now+.6;return end
  control(cb,"open_handbook",true)
 elseif n==7 then cb.closeHandbook();control(cb,"open_deck_viewer",true)
 elseif n==8 then cb.closeDeckViewer();control(cb,"open_settings",true)
 elseif n==9 then cb.closeSettings();love.window.setMode(960,540,{resizable=true});love.resize(960,540)
 elseif n==10 then require("tests.combat_material_smoke")(UI);shot("960");control(cb,"sort_suit",true)
 elseif n==11 then assert(game.sortMode=="suit");love.window.setMode(1920,1080,{resizable=true});love.resize(1920,1080)
 elseif n==12 then require("tests.combat_material_smoke")(UI);shot("1920");control(cb,"sort_rank",true)
 elseif n==13 then assert(game.sortMode=="rank");print("Combat UI PASS: starter, disabled/active controls, 8-card squad, target click, inventory rails, real scoring, boss, handbook/deck/options, 960/1920 input mapping");love.event.quit(0);return end
 T.stage=n+1;T.deadline=now+.6
end
return T
