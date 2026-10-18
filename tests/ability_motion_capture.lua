local UI=require("src.ui")
local Modal=UI.AbilityUI
local Potion=require("ui.potion_effects")
local Deck=require("src.deck")
local Deities=require("src.deities")
local Shop=require("src.shop")
local Run=require("src.run_manager")
local Persistence=require("src.persistence")
Persistence.saveRun=function() return true end
Persistence.deleteRun=function() return true end
Persistence.saveSettings=function() return true end
local T={clock=0}
local stage,index,started="start",0,0
local modes={{name="normal"},{name="fast",fast=true},{name="reduced",reduced=true}}
local frame,nextShot=0,0
local target,spn,item,ritual,hands,gold,scoring,sources
local preview=true
for _,a in ipairs(arg or {}) do
 if a=="--no-motion-preview" then preview=false end
 local name=a:match("^%-%-ability%-case=(.+)$")
 if name then local found;for _,m in ipairs(modes) do if m.name==name then found=m end end;assert(found);modes={found} end
end
local function after(value) stage=value;started=T.clock end
local function click(r)
 assert(r,"missing control")
 local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
 local x,y=(w-1280*s)/2+(r.x+r.w/2)*s,(h-720*s)/2+(r.y+r.h/2)*s
 love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1);love.mouse.setPosition(3,3)
end
local function button(id,card)
 for _,b in ipairs(assert(Modal.current).buttons or {}) do
  if b.id==id and (not card or Modal.current.cards[b.index]==card) then return b end
 end
 error("missing modal control "..id)
end
local function supply(g,id)
 item=Shop.healingItem(nil,id).consumable;g.consumables={item}
end
local function activate() UI.ExpandedInventory.callbacks.activate(1) end
local function copy(value) local c={};for k,v in pairs(value) do c[k]=v end;return c end
function T.update(g,cb)
 assert(T.clock-started<16,"ability timeout "..stage.." / "..index)
 if preview and index==1 and T.clock>=nextShot then
  local path=string.format(".tmp/ability-motion/frame_%04d.png",frame)
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
  end)
  frame=frame+1;nextShot=nextShot+.05
 end
 local age=T.clock-started
 if stage=="start" then
  require("tests.ability_motion_smoke")
  local update=love.update
  love.update=function(dt) local step=math.min(dt,preview and index==1 and 1/30 or .05);T.clock=T.clock+step;update(step) end
  local original=UI.ScoringFeel.update
  UI.ScoringFeel.update=function(a,dt,fast)
   local result=original(a,dt,fast);local s=a.sequence;local ev=s and s.events[s.index]
   if sources and ev and ev.kind=="TRIGGER" and ev.source.slotIndex and s.entered then
    sources[ev.source.slotIndex]=true
    local scale,y,rotation=UI.ScoringFeel.spnPose(a,ev.source.slotIndex,s.reducedMotion)
    assert(scale>=1 and scale<1.06 and y<=0 and y> -7)
    if s.reducedMotion then assert(scale==1 and y==0 and rotation==0) end
   end
   return result
  end
  require("src.combat").getHitChance=function() return 1 end
  after("case")
 elseif stage=="case" then
  index=index+1
  if not modes[index] then
   cb.setScoringSpeed(false);cb.setReducedMotion(false)
   print("Ability runtime PASS: "..#modes.." mode(s); successful/canceled/failed potions, card/SPN evolution, socket upgrade, single consumption/commit, real SPN scoring; "..frame.." preview frames")
   love.event.quit(0);return
  end
  cb.startNewGame("red_deck");cb.setScoringSpeed(modes[index].fast==true);cb.setReducedMotion(modes[index].reduced==true)
  g.persistentDeck={};g.maxHandSize=3
  for i=1,8 do g.persistentDeck[i]=Deck.newCard(i+1,"hearts") end
  cb.startMonsterEncounter(1,false)
  spn=copy(Deities.CATALOG.spirit_ember);spn.evolutionLevel=0
  g.deities={spn,copy(Deities.CATALOG.spirit_blade)};g.abilityApproved={};g.potionCombat={};g.potionFeedback={};Potion.active={}
  local enemy=g.monster;enemy.hp=1000000;enemy.maxHp=1000000;enemy.damageLagHp=1000000
  enemy.armor=0;enemy.creatureArmor=0;enemy.attack=0;enemy.attackSpeed=0;enemy.intent={type="attack",value=0}
  enemy.enemyInventory=nil;enemy.enemyAbility=nil;enemy.isBoss=false;enemy.bossData=nil
  g.playerHp=30;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
  hands,gold=g.handsRemaining,g.gold;sources=nil
  supply(g,"healing_potion");love.mouse.setPosition(3,3);nextShot=T.clock;after("heal_ready")
 elseif stage=="heal_ready" and age>1 and not UI.sceneTransitionBusy() and not UI.HandMotion.busy(g.hand) then
  activate();assert(#g.consumables==0 and g.playerHp>30);T.healEvent=g.potionFeedback[#g.potionFeedback];after("heal")
 elseif stage=="heal" and age>1.5 then
  assert(T.healEvent and T.healEvent.contacted)
  supply(g,"cons_damage");after("buff_ready")
 elseif stage=="buff_ready" and age>.25 then activate();assert(#g.consumables==0 and g.potionCombat.damageCards);after("buff")
 elseif stage=="buff" and age>1.4 then
  supply(g,"cons_armor_break");activate();assert(#g.consumables==1 and not Modal.current,"failed target must keep the potion")
  g.monster.creatureArmor=80;after("target_ready")
 elseif stage=="target_ready" and age>.25 then
  activate();assert(Modal.current and #g.consumables==1);love.keypressed("escape")
  assert(not Modal.current and #g.consumables==1);after("target_retry")
 elseif stage=="target_retry" and age>.25 then activate();assert(Modal.current);after("target_draw")
 elseif stage=="target_draw" and age>.25 then click(button("target"));assert(#g.consumables==0 and g.monster.creatureArmor==0);after("target_hit")
 elseif stage=="target_hit" and age>1.4 then
  item=Run.createEvolutionCard();g.consumables={item};activate();assert(Modal.current);target=g.persistentDeck[1];after("evolve_select")
 elseif stage=="evolve_select" and age>.3 then click(button("target",target));after("evolve_preview")
 elseif stage=="evolve_preview" and age>.3 then
  click(button("confirm"));ritual=assert(Modal.current.ritual)
  assert(target.evolutionLevel==1 and #g.consumables==0 and ritual.before.evolutionLevel==0)
  for i=1,4 do Modal.confirm();love.keypressed("return");love.keypressed("escape") end
  assert(Modal.current and target.evolutionLevel==1);after("evolve")
 elseif stage=="evolve" and age>1.2 then
  assert(not Modal.current and ritual.contacted and target.evolutionLevel==1)
  item=Run.createEvolutionCard();g.consumables={item};activate();after("spn_tab")
 elseif stage=="spn_tab" and age>.3 then click(button("tab_deities"));after("spn_select")
 elseif stage=="spn_select" and age>.2 then click(button("target",spn));after("spn_preview")
 elseif stage=="spn_preview" and age>.25 then click(button("confirm"));assert(spn.evolutionLevel==1 and #g.consumables==0);after("spn_evolve")
 elseif stage=="spn_evolve" and age>1.2 then
  assert(not Modal.current)
  item=Run.createSocketCard();g.consumables={item};activate();after("socket_select")
 elseif stage=="socket_select" and age>.3 then click(button("target",target));after("socket_preview")
 elseif stage=="socket_preview" and age>.25 then click(button("confirm"));assert(#g.consumables==0);after("socket_ritual")
 elseif stage=="socket_ritual" and age>1.2 then
  assert(not Modal.current and require("src.equipment").getMaxSlots(target)==5)
  assert(g.gold==gold and g.handsRemaining==hands)
  sources={};cb.selectCardIndex(1);cb.playSelectedHand();after("combat")
 elseif stage=="combat" then
  if Modal.current and Modal.current.mode=="choices" then Modal.choose(1) end
  local anim,state=cb.getScoringState()
  if state=="scoring" then scoring=anim.sequence.result end
  if state=="playing" and not anim.active and not anim.enemyTurn and g.handsRemaining==hands-1 then
   assert(sources[1] and sources[2],"both scored SPNs must visibly trigger")
   assert(scoring and g.monster.hp<999980 and g.gold==gold and #g.consumables==0)
   print("Ability runtime PASS: "..modes[index].name.."; consumables/ritual/SPN score; correct resources and one combat turn")
   after("case")
  end
 end
end
return T
