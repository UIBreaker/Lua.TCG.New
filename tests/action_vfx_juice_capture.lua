-- Real action triggers, ten uninterrupted repeats per effect. No player saves.
local F=require("src.combat_feedback")
local UI=require("src.ui")
local P=UI.Polish
local Deck=require("src.deck")
local Equipment=require("src.equipment")
local T={}
local Sound=require("src.sound")
local audioEvents={};local originalSound=Sound.play
Sound.play=function(name,pitch,...)
    audioEvents[#audioEvents+1]={name=name,pitch=pitch or 1,time=love.timer.getTime()}
    return originalSound(name,pitch,...)
end
local eventStarts=setmetatable({}, {__mode="k"});local originalEmit=F.emit
F.emit=function(...)
    local e=originalEmit(...)
    if e then eventStarts[e]=love.timer.getTime() end
    return e
end
local kinds={"armor_gain","armor_loss","heal","hurt","equip","destroy","enemy_first","player_first","buy","sell"}
local names={"TĂNG GIÁP","VỠ GIÁP","HỒI MÁU","NHẬN SÁT THƯƠNG","GẮN TRANG BỊ","TIÊU HỦY","QUÁI ĐÁNH TRƯỚC","BẠN ĐÁNH TRƯỚC","MUA","BÁN"}
local index=0;local began,fired,tracked;local shop,stock;local strip,tile
local maxFrame=0;local frames=0;local totalFrame=0
local function snapshot(row,event,card)
    local g=love.graphics
    strip=strip or g.newCanvas(870,2100);tile=tile or g.newCanvas(290,210)
    local phases={0.012,event.profile.contact+0.025,event.profile.duration*0.72}
    for column,age in ipairs(phases) do
        g.push("all");g.setCanvas(tile);g.origin();g.clear(0.025,0.035,0.05,1)
        g.setColor(1,1,1,1)
        if row==5 or row==6 or row==9 or row==10 then
            if row==6 or row==10 then
                P.dissolve(UI,103,30,84,126,math.min(1,age/event.profile.duration),event.profile.color,
                    function(x,y,w,h) UI.drawCardFace(card,x,y,w,h) end)
            else UI.drawCardFace(card,103,30,84,126) end
        end
        g.setFont(UI.fonts.tiny);g.setColor(0.75,0.82,0.9,1)
        g.printf(names[row].." · "..({"MỞ ĐẦU","CHẠM","KẾT"})[column],0,184,290,"center")
        local copy={};for k,v in pairs(event) do copy[k]=v end
        copy.age=age;copy.x=145;copy.y=94;copy.target={x=225,y=50}
        local queue=F.vfx;F.vfx={copy}
        local newCanvas,newShader=g.newCanvas,g.newShader
        g.newCanvas=function() error("VFX allocated Canvas") end;g.newShader=function() error("VFX allocated shader") end
        local red,green,blue,alpha=g.getColor();local blend=g.getBlendMode()
        F.drawVfx(UI)
        assert(g.getBlendMode()==blend,"blend leak")
        local r,gg,b,a=g.getColor();assert(r==red and gg==green and b==blue and a==alpha,"color leak")
        g.newCanvas,g.newShader=newCanvas,newShader;F.vfx=queue
        g.setCanvas(strip);g.origin();g.setShader();g.setBlendMode("alpha","premultiplied");g.setColor(1,1,1,1)
        g.draw(tile,(column-1)*290,(row-1)*210);g.pop()
    end
end
local function update(game,cb)
    local now=love.timer.getTime()
    if not began then
        index=index+1
        if index>100 then
            local data=strip:newImageData();local file=assert(io.open("docs/action_vfx/juice_contact_sheet.png","wb"))
            file:write(data:encode("png"):getString());file:close()
            print(string.format("JUICE GPU PASS: 100 real actions, 10 consecutive repeats per existing effect, Normal/Fast; contact audio exactly once, actual equip reaction, no residual tail, GPU state and zero VFX Canvas/shader allocation. Mean dt %.2f ms, max %.2f ms (%d frames).",totalFrame/frames*1000,maxFrame*1000,frames))
            Sound.play=originalSound;F.emit=originalEmit
            love.event.quit(0);return
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(index%2==0)
        game.playerHp=60;game.maxPlayerHp=100;game.playerArmor=20;game.playerShield=20;game.gold=100
        local card=Deck.newCard(8,"spades")
        game.hand={card};game.persistentDeck={card,Deck.newCard(5,"clubs")};game.selectedIndices={};game.deities={}
        P.applications={};P.job=nil;P.clearFocus()
        local anim=cb.getScoringState();anim.active=false;anim.enemyTurn=nil;anim.hitStop=0;anim.floatingTexts={}
        local kind=kinds[math.floor((index-1)/10)+1]
        if kind=="buy" or kind=="sell" then
            cb.openShop();shop=cb.getShopData();stock={category="card",card=Deck.newCard(7,"hearts"),cost=4}
            shop.items={stock};P.ensureShop(shop)
            if kind=="sell" then stock={id="test",name="Test",category="edition",edition="foil",cost=4};game.consumables={stock} end
        end
        began=now;fired=nil;tracked=nil
        return
    end
    assert(now-began<4,"action timeout "..index)
    local row=math.floor((index-1)/10)+1;local kind=kinds[row]
    if not fired and now-began>0.08 then
        F.clearVfx();audioEvents={}
        if row==1 then game.playerArmor=30;game.playerShield=30
        elseif row==2 then game.playerArmor=6;game.playerShield=6
        elseif row==3 then game.playerHp=80
        elseif row==4 then game.playerHp=40
        elseif row==5 then
            local before=P.snapshot(game);assert(Equipment.attach(game.hand[1],Equipment.ITEMS.gem_fire));P.changed(UI,game,before,Equipment.ITEMS.gem_fire)
        elseif row==6 then UI.Abilities.destroy(game,game.hand[1]);assert(game.hand[1].destroyed)
        elseif row==7 or row==8 then
            for _,m in ipairs(game.enemies) do m.attackSpeed=row==7 and 99 or 0.01;m.hp=10000000;m.maxHp=m.hp end
            game.abilityApproved={};cb.selectCardIndex(1);cb.playSelectedHand()
        else
            P.focusItem(stock,row==9 and "stock" or "consumable",1,{x=445,y=170,w=104,h=146})
            local gold=game.gold;assert(P.confirm(shop,game))
            assert(row==9 and game.gold==gold-4 or row==10 and game.gold>gold,"transaction authority changed")
        end
        fired=now
    elseif fired then
        local dt=love.timer.getDelta();frames=frames+1;totalFrame=totalFrame+dt;maxFrame=math.max(maxFrame,dt)
        if not tracked then
            for _,e in ipairs(F.vfx) do if e.kind==kind then tracked=e;break end end
            assert(tracked or now-fired<1,"missing real action "..kind)
            if tracked and row==5 then
                local pose=UI.CardPhysics.getState(game.hand[1])
                assert(pose and pose.active and math.abs(pose.vy)+math.abs(pose.angularVelocity)>0.01,"equip did not react at contact")
                assert(P.applications[1].hit and P.applications[1].effect==tracked,"equip reaction/contact mismatch")
            end
            if tracked and index%10==1 then snapshot(row,tracked,game.persistentDeck[1]) end
        elseif tracked.age>=tracked.profile.duration then
            assert(tracked.contacted,"contact missed "..kind)
            if not tracked.silent then
                local count=0
                for _,a in ipairs(audioEvents) do
                    if a.name==tracked.profile.sound and math.abs(a.pitch-tracked.profile.pitch)<0.0001 then
                        count=count+1
                        local delay=a.time-eventStarts[tracked]
                        assert(delay>=tracked.profile.contact-0.02 and delay<=tracked.profile.contact+maxFrame+0.05,"audio/contact drift "..kind)
                    end
                end
                assert(count==1,"duplicate/missing contact sound "..kind)
            end
            for _,e in ipairs(F.vfx) do assert(e~=tracked,"effect tail leaked "..kind) end
            if row==5 then assert(P.applications[1].hit and P.applications[1].effect==tracked,"equip contact mismatch") end
            if index%10==0 then print("JUICE 10/10 "..kind);io.stdout:flush() end
            began=nil
        end
    end
end
function T.update(game,cb)
    local ok,err=xpcall(function() update(game,cb) end,debug.traceback)
    if not ok then print("JUICE GPU FAILED: "..err);io.stdout:flush();love.event.quit(1) end
end
return T
