local T={stage=0,deadline=0}
local UI=require("src.ui");local Bag=UI.Backpack;local X=UI.EquipmentTransfer
local Q=require("ui.backpack_qol");local E=require("src.equipment");local B=require("src.basic_equipment")
local Modal=UI.AbilityUI
local function press(r,mouse)
 assert(r,"missing control");local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local x,y=(w-1280*scale)/2+(r.x+r.w/2)*scale,(h-720*scale)/2+(r.y+r.h/2)*scale
 love.mouse.setPosition(x,y);love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1)
end
local function button(cb,id)
 for _,b in ipairs(Modal.current and Modal.current.buttons or cb.getButtons()) do if b.id==id then assert(not b.disabled,id);return b end end
 error("missing button "..id)
end
local function click(cb,id)press(button(cb,id))end
local function shot(name)
 love.mouse.setPosition(2,2);UI.Description.reset()
 love.graphics.captureScreenshot(function(data)local f=assert(io.open("docs/backpack_return_transfer_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()end)
end
local function returned()
 assert(Bag.open and Bag.tab=="consumable" and Bag.page==2 and Q.state(Bag).query=="sao" and Q.state(Bag).sort==2 and not UI.backpackUseReturn,"must return to the same reserve view")
end
local function slot(n)for _,r in ipairs(Bag.loadoutSlots or {}) do if r.index==n then return r end end;error("missing loadout slot "..n)end
function T.update(game,cb)
 local now=love.timer.getTime();if now<T.deadline then return end
 T.started=T.started or now;assert(now-T.started<65,"return/transfer timeout at "..T.stage)
 local s=T.stage
 if s==0 then
  cb.startNewGame("red_deck");game.gold=300;game.persistentDeck={}
  for i=1,16 do game.persistentDeck[i]=require("src.deck").newCard(2+(i-1)%12,({"hearts","diamonds","clubs","spades"})[(i-1)%4+1]) end
  T.source=game.persistentDeck[1];T.source.maxSockets=8;T.original={}
  for i=1,8 do assert(E.attach(T.source,E.ITEMS[B.basic[i]]));T.original[i]=T.source.equipments[i] end
  assert(E.attach(game.persistentDeck[3],T.original[1]))
  local Run=require("src.run_manager")
  game.consumables={Run.createEvolutionCard(),Run.createSocketCard(),{id="ed_foil",category="edition",edition="foil",name="Phủ Bạc",color={.4,.7,.9,1}}}
  game.backpackConsumables={}
  for _,p in ipairs(require("src.poker").PLANET_CARDS) do local c={category="celestial"};for k,v in pairs(p) do c[k]=v end;game.backpackConsumables[#game.backpackConsumables+1]=c end
  cb.openShop();Bag.views={};Bag.tab="consumable";Bag.show();Q.state(Bag).query="sao";Q.state(Bag).sort=2;Bag.page=2
 elseif s==1 then shot("origin_page2");T.stage=1.5;T.deadline=now+.3;return
 elseif s==1.5 then press(slot(1),2);T.stage=2;T.deadline=now+.3;return
 elseif s==2 then assert(Modal.current and not Bag.open);click(cb,"target");shot("evolution_target")
 elseif s==3 then click(cb,"confirm");assert(T.source.evolutionLevel==1 and #game.consumables==2)
 elseif s==4 then if Modal.current then return end;returned();shot("after_evolution");T.stage=4.5;T.deadline=now+.3;return
 elseif s==4.5 then press(slot(2),2);T.stage=5;T.deadline=now+.3;return
 elseif s==5 then assert(Modal.current.mode=="card_upgrade" and not Bag.open);love.keypressed("escape")
 elseif s==6 then returned();assert(#game.consumables==2);press(slot(2),2)
 elseif s==7 then click(cb,"target");T.socketTarget=Modal.current.selected;T.sockets=E.getMaxSlots(T.socketTarget)
 elseif s==8 then click(cb,"confirm")
 elseif s==9 then
  if Modal.current then return end
  returned();assert(E.getMaxSlots(T.socketTarget)==T.sockets+1 and #game.consumables==1)
  T.stage=9.5;T.deadline=now+.3;return
 elseif s==9.5 then press(slot(3),2);T.stage=10;T.deadline=now+.3;return
 elseif s==10 then assert(Bag.open and Bag.tab=="cards");love.keypressed("escape")
 elseif s==11 then returned();assert(#game.consumables==1);press(slot(3),2)
 elseif s==12 then assert(Bag.tab=="cards");press(Bag.cells[1])
 elseif s==13 then returned();assert(#game.consumables==0 and T.source.edition=="foil");shot("after_edition")
 elseif s==14 then love.keypressed("i");assert(not Bag.open)
 elseif s==15 then click(cb,"open_shop_transfer")
 elseif s==16 then shot("source_picker");T.stage=16.5;T.deadline=now+.3;return
 elseif s==16.5 then click(cb,"transfer_card_1");T.stage=17;T.deadline=now+.3;return
 elseif s==17 then
  assert(X.source==T.source and not X.eqIndex)
  local count=0;for _,b in ipairs(cb.getButtons()) do if b.id:match("^transfer_equipment_") then count=count+1;assert(b.x+b.w<=610 and b.y+b.h<=652) end end;assert(count==8)
  shot("eight_equipment");T.stage=17.5;T.deadline=now+.3;return
 elseif s==17.5 then click(cb,"transfer_equipment_1");T.stage=18;T.deadline=now+.3;return
 elseif s==18 then
  for _,v in ipairs(X.list(game.persistentDeck)) do assert(v.card~=game.persistentDeck[3]) end
  love.window.setMode(960,540,{resizable=true});love.resize(960,540)
 elseif s==19 then shot("targets_960");T.stage=19.5;T.deadline=now+.3;return
 elseif s==19.5 then click(cb,"transfer_card_2");assert(#T.source.equipments==7 and game.persistentDeck[2].equipments[1].id==T.original[1].id and game.gold==300);T.stage=20;T.deadline=now+.3;return
 elseif s==20 then shot("transferred");T.stage=20.5;T.deadline=now+.3;return
 elseif s==20.5 then click(cb,"transfer_undo");T.stage=21;T.deadline=now+1.2;return
 elseif s==21 then
  assert(#T.source.equipments==8 and #game.persistentDeck[2].equipments==0)
  for i,eq in ipairs(T.source.equipments) do assert(eq==T.original[i]) end
  love.window.setMode(1920,1080,{resizable=true});love.resize(1920,1080)
 elseif s==22 then shot("undo_1920");T.stage=22.5;T.deadline=now+.3;return
 elseif s==22.5 then press(button(cb,"transfer_equipment_1"),2);assert(cb.getInspector()==T.original[1]);T.stage=23;T.deadline=now+.3;return
 elseif s==23 then love.keypressed("escape");assert(not cb.getInspector() and cb.getShopTransferState())
 elseif s==24 then click(cb,"transfer_search");love.textinput("khongtimthayzz")
 elseif s==25 then assert(#X.list(game.persistentDeck)==0);click(cb,"transfer_clear")
 elseif s==26 then assert(#X.list(game.persistentDeck)>0);click(cb,"transfer_next")
 elseif s==27 then assert(X.page==2);love.keypressed("escape");assert(not X.source and cb.getShopTransferState())
 elseif s==28 then
  love.keypressed("escape");assert(not cb.getShopTransferState())
  print("Backpack return / workshop UI PASS: evolution confirm, socket cancel+confirm, edition cancel+confirm return to page/query/sort; eight gears, compatible targets, real free transfer/undo/order, inspector, search/pagination and 960+1920 layouts")
  love.event.quit(0)
 end
 T.stage=s+1;T.deadline=now+(s==0 and 1.5 or .35)
end
return T
