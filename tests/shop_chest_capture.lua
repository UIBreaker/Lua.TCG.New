local T={};local Shop=require("src.shop");local D=require("src.death_vfx")
local P=require("src.persistence");P.deleteRun=function() return true end;P.saveRun=function() return true end;P.saveSettings=function() return true end
local stage,age,index=0,0,1
local shots={{0.34,"ash"},{0.96,"backs"},{1.35,"flip"},{2.75,"choices"}}
local function click(b)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function T.update(game,cb)
    age=age+love.timer.getDelta();assert(age<12,"shop chest timeout at "..stage)
    if stage==0 then
        cb.startNewGame("red_deck");cb.openShop();love.mouse.setPosition(4,4)
        cb.openPack({packType="spectral",name="RƯƠNG BIẾN ĐỔI"},true);stage=1;age=0
    elseif stage==1 then
        if shots[index] and age>shots[index][1] then
            local name=shots[index][2]
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open("docs/shop_chest_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
            end);index=index+1
        end
        if age<1 then assert(not button(cb,"choose_pack_1"),"face-down actions blocked") end
        if age>0.35 and age<0.7 then assert(D.kind=="chest" and D.count>0,"shop uses ash particles") end
        if age>2.85 then
            for i=1,3 do
                local use=assert(button(cb,"choose_pack_"..i));local keep=assert(button(cb,"keep_pack_"..i))
                assert(use.y>=492 and keep.y>use.y,"actions below full-bleed cards")
            end
            click(button(cb,"keep_pack_2"));assert(not cb.getShopData().currentPackOpening and #game.consumables==1)
            print("Shop ash / staggered flips / keep PASS")
            cb.openPack({packType="celestial",name="RƯƠNG HÀNH TINH"});stage=2;age=0
        end
    elseif stage==2 and age>0.2 then
        local before=0;for _,v in pairs(game.handLevels) do before=before+v end
        click(assert(button(cb,"choose_pack_1")));assert(not cb.getShopData().currentPackOpening)
        local after=0;for _,v in pairs(game.handLevels) do after=after+v end
        assert(after>before,"use now applies planet");print("Shop use now PASS")
        game.consumables={{},{},{}};cb.openPack({packType="spectral",name="RƯƠNG BIẾN ĐỔI"});stage=3;age=0
    elseif stage==3 and age>0.2 then
        local keep=assert(button(cb,"keep_pack_1"));assert(keep.disabled)
        click(keep);assert(cb.getShopData().currentPackOpening and #game.consumables==3)
        click(assert(button(cb,"skip_pack")));assert(not cb.getShopData().currentPackOpening)
        print("Shop full inventory and skip PASS");love.event.quit(0);stage=99
    end
end
return T
