local T={}
local Shop=require("src.shop")
local Deck=require("src.deck")
local UI=require("src.ui")
local offers,index,phase,deadline,panel=nil,1,0,0,nil
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/shop_seal_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if now<deadline then return end
    if not offers then
        require("tests.seal_smoke")
        cb.startNewGame("red_deck");game.shopMode="consumable";cb.openShop()
        offers={}
        for _,offer in ipairs(Shop.getRetailConsumables()) do
            if offer.category=="seal" then offers[#offers+1]=offer end
        end
        local View=require("ui.components.card_description")
        local draw=View.draw
        View.draw=function(m,l,...)
            panel={model=m,layout=l};return draw(m,l,...)
        end
    end
    if phase==0 then
        if index>#offers then
            print("PASS: all 10 retail seals show complete effects in live shop tooltips")
            love.event.quit(0);return
        end
        local offer=offers[index];offer.section="stall";offer.bay=3
        cb.getShopData().items={offer}
        UI.Polish.clearFocus();require("src.card_description").reset()
        panel=nil;phase=1;deadline=now+.15
    elseif phase==1 then
        local button
        for _,b in ipairs(cb.getButtons()) do if b.stockItem==offers[index] then button=b;break end end
        assert(button,"seal display hitbox")
        local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
        love.mouse.setPosition((w-1280*s)/2+(button.x+button.w/2)*s,
            (h-720*s)/2+(button.y+button.h/2)*s)
        phase=2;deadline=now+.65
    else
        local offer=offers[index]
        assert(panel and panel.model.title==offer.name,"live tooltip title: "..offer.id)
        local text={};for _,row in ipairs(panel.model.rows) do text[#text+1]=row.text end
        assert(table.concat(text,"\n"):find(Deck.getModifierDescription("seal",offer.id),1,true),"live tooltip effect: "..offer.id)
        assert(panel.layout.maxScroll==0 and not panel.layout.summarized,"seal effect must fit without truncation")
        if offer.id=="seal_blood" or offer.id=="seal_gambit" then shot(offer.id) end
        index=index+1;phase=0;deadline=now+.15
    end
end
return T
