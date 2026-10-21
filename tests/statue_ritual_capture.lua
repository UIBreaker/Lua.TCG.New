local T={step=0,deadline=0,index=1}
local UI=require("src.ui")
local V=require("ui.ancient_statue")
local S=require("src.ancient_statue")
local R=require("src.rng")
local outcomes={1,9,5,4,6,10}
local function pointer(x,y,click)
 local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
 local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
 love.mouse.setPosition(px,py)
 if click then love.mousepressed(px,py,1);love.mousereleased(px,py,1) end
end
local function button(cb,id,click)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then
  if click then assert(not b.disabled,id);pointer(b.x+b.w/2,b.y+b.h/2,true) end
  return b
 end end
 error("Missing "..id)
end
local function shot(name)
 pointer(5,5);UI.Description.reset()
 love.graphics.captureScreenshot(function(data)
  local f=assert(io.open("docs/statue_ritual_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
 end)
end
function T.update(game,cb)
 local now=love.timer.getTime();if now<T.deadline then return end
 local n=T.step
 -- Screenshots can stall wall time; wait on the actual animation clock, with a deadline.
 local threshold=({[7]=1.05,[8]=2.05,[13]=.95})[n]
 if threshold and V.ritual and V.ritual.age<threshold then
  T.waitStarted=T.waitStarted or now
  assert(now-T.waitStarted<8,"ritual animation did not advance")
  return
 end
 T.waitStarted=nil
 if n==0 then
  require("tests.ancient_statue_smoke")
  cb.startNewGame("red_deck")
  game.persistentDeck={require("src.deck").newCard(7,"hearts"),require("src.deck").newCard(12,"clubs")}
  S.create(game);cb.setCaptureState("blood_statue")
  T.original=R.random
 elseif n==1 then
  assert(button(cb,"statue_touch").disabled);shot("empty")
 elseif n==2 then button(cb,"statue_select",true)
 elseif n==3 then
  assert(UI.Backpack.open and UI.Backpack.cardPicker and UI.Backpack.tab=="cards")
  local r=UI.Backpack.cellRect(1);pointer(r.x+r.w/2,r.y+r.h/2,true)
  assert(not UI.Backpack.open and game.ancientStatue.selectedId==game.persistentDeck[1].id,"bag click places owned card into offering slot")
 elseif n==4 then shot("selected")
 elseif n==5 then
  T.hp=game.playerHp;T.gold=game.gold;T.count=#game.persistentDeck
  R.random=function(a,b) if b then return 150 elseif a then return outcomes[T.index] else return .9 end end
  button(cb,"statue_touch",true)
  assert(game.playerHp==T.hp and V.ritual and not V.ritual.result,"ritual charge precedes mutation")
  V.press(game,{id="statue_touch"});assert(game.playerHp==T.hp,"repeat press blocked during charge")
  T.step=6;T.deadline=now+.3;return
 elseif n==6 then shot("charge");T.step=7;T.deadline=now+1/require("src.game_speed").base;return
 elseif n==7 then
  assert(V.ritual and V.ritual.result==S.outcomes[outcomes[T.index]].id)
  assert(math.abs(game.playerHp-T.hp*.9)<.0001 and game.ancientStatue.touches==T.index,"one payment and one result")
  if outcomes[T.index]==9 then assert(game.gold==T.gold+150) end
  if outcomes[T.index]==5 then assert(#game.persistentDeck==T.count+3) end
  shot(V.ritual.result)
  T.step=8;T.deadline=now+1/require("src.game_speed").base;return
 elseif n==8 then
  assert(not button(cb,"statue_continue").disabled)
  button(cb,"statue_continue",true);assert(not V.ritual)
  if T.index<#outcomes then T.index=T.index+1;T.step=5;T.deadline=now+.4;return end
 elseif n==9 then
  love.window.setMode(960,540,{resizable=true});love.resize(960,540)
 elseif n==10 then
  shot("960");button(cb,"statue_select",true)
 elseif n==11 then
  love.keypressed("escape");assert(not UI.Backpack.open and not UI.Backpack.cardPicker,"picker cancellation preserves offering")
  game.playerHp=11;R.random=function(a,b) if b then return a elseif a then return 10 else return .9 end end
 elseif n==12 then
  button(cb,"statue_touch",true)
  T.step=13;T.deadline=now+1.1/require("src.game_speed").base;return
 elseif n==13 then
  assert(select(2,cb.getRunState())=="BLIND_SELECT" and game.bloodDomain,"hidden entry mechanic remains intact")
  R.random=T.original
  print("STATUE RITUAL PASS: bag selection/cancel, empty slot, staged charge, exact-once results/payment, damage/gold/copies/double/loss/nothing reveals, 960, hidden entry")
  love.event.quit(0);return
 end
 T.step=n+1;T.deadline=now+.7
end
return T
