-- Real input + renderer coverage; capture mode never writes player saves.
local UI=require("src.ui")
local P=UI.CardPhysics
local D=require("src.deck")
local Shop=require("src.shop")
local T={clock=0}
local cases,index,phase,started,current,pose,pressX,pressY,balance,hands
local record,nextShot,recordFrame=false,0,0
for _,value in ipairs(arg or {}) do if value=="--record-card-drag" then record=true end end
local function pointer(x,y,action,shift)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
    love.mouse.setPosition(px,py)
    if action=="press" then
        local isDown=love.keyboard.isDown
        if shift then love.keyboard.isDown=function(key,...) return key=="lshift" or key=="rshift" or isDown(key,...) end end
        love.mousepressed(px,py,1);love.keyboard.isDown=isDown
    elseif action=="release" then love.mousereleased(px,py,1)
    else love.mousemoved(px,py,0,0) end
end
local function after(nextPhase) phase=nextPhase;started=T.clock end
local function snapshot(path)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open(path,"wb"));file:write(data:encode("png"):getString());file:close()
    end)
end
function T.update(game,cb)
    if not cases then
        local g=love.graphics;local canvas=g.newCanvas(300,350)
        g.push("all");g.setCanvas(canvas);g.origin();g.clear(1,1,1,1)
        P.shadow(70,40,120,180,1,0,0,1)
        g.pop()
        local pixels=canvas:newImageData()
        local core=pixels:getPixel(130,235);local edge=pixels:getPixel(130,248);local outside=pixels:getPixel(130,260)
        assert(core<edge and edge<outside and outside>.99,"shadow must fade softly away from the projected silhouette")
        pixels:release();canvas:release()
        print("[PASS] rendered shadow: dark core, soft edge, clear exterior")
        local update=love.update
        love.update=function(dt) local step=math.min(dt,1/30);T.clock=T.clock+step;update(step) end
        cb.startNewGame("red_deck");game.maxHandSize=5;game.persistentDeck={}
        for i=1,12 do game.persistentDeck[i]=D.newCard(i+1,"spades") end
        cb.startMonsterEncounter(1,false)
        game.deities={require("src.deities").getStarterDeity("aurelia"),require("src.deities").getStarterDeity("valoria")}
        game.backpackDeities={require("src.deities").getStarterDeity("elaris")}
        game.consumables={Shop.healingItem(nil,"cons_armor_break").consumable}
        game.backpackConsumables={Shop.healingItem(nil,"cons_armor_break").consumable}
        game.backpackEquipment={"gem_fire"};game.gold=10000
        balance,hands=game.gold,game.handsRemaining
        cases={
            {name="hand",card=function() return game.hand[2] end,shift=true},
            {name="battle SPN",card=function() return game.deities[1] end},
            {name="battle consumable",card=function() return game.consumables[1] end},
            {name="expanded SPN",setup=function() UI.ExpandedInventory.show("spn") end,card=function() return game.deities[1] end},
            {name="expanded consumable",setup=function() UI.ExpandedInventory.show("consumable") end,card=function() return game.consumables[1] end},
            {name="deck viewer",setup=cb.openDeckViewer,at={100,205},viewer=true},
            {name="inspector",setup=function() cb.openInspector(game.persistentDeck[1]) end,card=function() return game.persistentDeck[1] end},
            {name="shop stock",setup=cb.openShop,card=function() return cb.getShopData().items[1] end},
            {name="backpack reserve SPN",setup=function() UI.Backpack.show();require("ui.backpack_qol").switch(UI.Backpack,"spn") end,card=function() return game.backpackDeities[1] end},
            {name="backpack equipped SPN",setup=function() UI.Backpack.show();require("ui.backpack_qol").switch(UI.Backpack,"spn") end,card=function() return game.deities[1] end},
            {name="backpack consumable",setup=function() UI.Backpack.show();require("ui.backpack_qol").switch(UI.Backpack,"consumable") end,card=function() return game.backpackConsumables[1] end},
            {name="backpack equipment",setup=function() UI.Backpack.show();require("ui.backpack_qol").switch(UI.Backpack,"equipment") end,at={300,220}},
            {name="collection",setup=function() cb.openCollection("consumables");require("ui.collection_book").skip() end,at={180,210}},
        }
        for _,pack in ipairs(Shop.PACK_CATALOG) do
            local item=pack
            cases[#cases+1]={name="pack "..item.packType,setup=function() cb.openPack(item) end,
                card=function() return cb.getShopData().currentPackOpening.cards[1] end}
        end
        local markets={
            {name="barter",setup=function() require("src.barter").create(game);cb.setCaptureState("barter") end,at={100,260}},
            {name="Void SPN",setup=function()
                game.run.ante=10;game.run.currentBlindIndex=3
                game.run.blinds[3].status="completed"
                assert(require("src.void_gacha").enterIfDue(game,true));cb.setCaptureState("void")
            end,at={395,230}},
            {name="Void equipment",at={695,230}},
            {name="Void playing card",at={1000,230}},
        }
        local marketsOnly=false
        for _,value in ipairs(arg or {}) do if value=="--drag-markets-only" then marketsOnly=true end end
        if marketsOnly then cases=markets else for _,case in ipairs(markets) do cases[#cases+1]=case end end
        for _,value in ipairs(arg or {}) do
            local name=value:match("^%-%-drag%-case=(.+)$")
            if name then
                local selected={}
                for _,case in ipairs(cases) do if case.name==name then selected[#selected+1]=case end end
                assert(#selected>0,"unknown drag case: "..name);cases=selected
            end
        end
        index=0;after("next");return
    end
    if record and current and (index==1 or index==8 or index==9 or index==13)
        and (phase=="drag" or phase=="settle") and T.clock>=nextShot then
        snapshot(string.format(".tmp/drag-reference/demo_%04d.png",recordFrame))
        recordFrame=recordFrame+1;nextShot=T.clock+1/30
    end
    assert(T.clock-started<8,"drag test timeout: "..tostring(phase))
    if phase=="next" then
        P.release();UI.Polish.clearFocus();UI.Backpack.close();UI.ExpandedInventory.close();cb.closeInspector();cb.closeDeckViewer()
        if index>0 and current.name=="collection" then cb.closeCollection();require("ui.collection_book").skip() end
        cb.closePack()
        index=index+1;current=cases[index]
        if not current then
            assert(game.gold==balance and game.handsRemaining==hands,"visual drags spent resources")
            print("CARD DRAG PASS: "..#cases.." hand/SPN/consumable/shop/backpack/expanded/viewer/inspector/collection/all-pack surfaces; lag, tilt, release, settle, no purchase or turn spent")
            love.event.quit(0);return
        end
        if current.setup then current.setup() end
        pointer(2,2);after("pick")
    elseif phase=="pick" and T.clock-started>1.3 then
        local card=current.card and current.card() or P.cardAt(unpack(current.at))
        pose=assert(P.getState(card),"missing physics surface: "..current.name)
        if current.at then pressX,pressY=unpack(current.at)
        else
            pressX=pose.ox+pose.a*pose.w*.45+pose.c*pose.h*.38
            pressY=pose.oy+pose.b*pose.w*.45+pose.d*pose.h*.38
        end
        assert(P.cardAt(pressX,pressY)==card,"surface covered: "..current.name)
        current.owner=card;pointer(pressX,pressY,"press",current.shift)
        pose=assert(P.getState(card))
        current.maxTilt,current.maxLag=0,0
        assert(P.isHeld(card),"input failed to grab: "..current.name)
        after("drag")
    elseif phase=="drag" then
        local age=T.clock-started
        pointer(math.max(60,math.min(1170,pressX+math.sin(age*6)*150)),math.max(80,math.min(660,pressY-age*110)))
        if age>.22 then
            assert(pose.held and P.isHolding(),"lost held surface: "..current.name)
            assert(pose.lift>.8,"missing lift: "..current.name.." / "..pose.lift)
            current.maxTilt=math.max(current.maxTilt,math.abs(pose.rotation))
            current.maxLag=math.max(current.maxLag,math.abs(pose.x-pose.targetX))
        end
        if age>.65 then
            assert(current.maxTilt>.01 and current.maxLag>.1,"missing tilt/inertia: "..current.name)
            snapshot(".tmp/drag-reference/game_"..index..".png")
            local vx,vy=pose.vx,pose.vy
            pointer(15,710,"release")
            assert(not P.isHolding() and pose.vx==vx and pose.vy==vy,"release reset momentum")
            if current.viewer then assert(not cb.getInspector(),"drag opened inspector") end
            after("settle")
        end
    elseif phase=="settle" and T.clock-started>1 then
        assert(math.abs(pose.x-pose.homeX)<3 and math.abs(pose.y-pose.homeY)<5,"failed to settle: "..current.name)
        assert(not pose.settling,"release overlay did not finish: "..current.name)
        assert(game.gold==balance and game.handsRemaining==hands,"drag changed gameplay: "..current.name)
        if current.viewer then
            local x=pose.ox+pose.a*pose.w*.4+pose.c*pose.h*.4
            local y=pose.oy+pose.b*pose.w*.4+pose.d*pose.h*.4
            pointer(x,y,"press");pointer(x,y,"release")
            assert(cb.getInspector()==current.owner,"ordinary viewer click must still open inspector")
            cb.closeInspector()
        end
        print("[PASS] drag/lift/tilt/settle: "..current.name)
        after("next")
    end
end
return T
