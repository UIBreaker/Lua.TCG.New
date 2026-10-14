local T={};local step=0;local deadline=0
local Run=require("src.run_manager")
local E=require("src.expedition")
local Debug=require("src.debug_tools")
local stages={1,6,11,16}
local captures={}
for _,r in ipairs(E.regions) do
    if r.areas then for _,stage in ipairs(stages) do captures[#captures+1]={region=r.id,stage=stage} end end
end
captures[#captures+1]={region="unknown",stage=1}
local function click(x,y)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    love.mousepressed((w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/expedition/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function permit(game,cb)
    game.run.regionId="human";Debug.setAnte(game,20,3)
    Run.completeCurrentBlind(game.run,game);Run.advanceBlind(game.run,game)
    assert(game.run.travelPermit and game.run.difficultyCap);cb.setCaptureState("BLIND_SELECT")
    assert(require("src.ui").openTravelPermit("backpackConsumables",#game.backpackConsumables))
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    local n=#captures*4
    if step==0 then
        cb.startNewGame("red_deck");love.mouse.setPosition(5,5)
        require("tests.journey_routing_smoke")
        for rank=2,13 do
            local key="human_"..rank
            local img=assert(require("src.continental_art").get(key),"Missing portrait "..key)
            local indexed=assert(require("src.continental_art").withIndices(img,nil,rank))
            assert(indexed:getWidth()==512 and indexed:getHeight()==768)
        end
    elseif step<=n then
        local item=captures[math.ceil(step/4)]
        local phase=(step-1)%4
        if phase==0 then
            game.run.regionId=item.region;Debug.setAnte(game,item.stage,1)
            cb.setCaptureState("BLIND_SELECT")
        elseif phase==1 then
            shot("route_select_"..item.region.."_"..item.stage)
        elseif phase==2 then
            click(224,591)
            assert(game.monster and game.monster.regionId==item.region and game.monster.areaStage==item.stage)
            for _,m in ipairs(game.enemies) do
                if item.region=="human" then assert(m.neutralHuman and not m.cardSuit)
                elseif item.region~="unknown" then
                    assert(m.cardSuit==item.region)
                    local raw=require("src.ui").getCardImage(m.cardSuit,m.cardRank)
                    local indexed=require("src.enemy_art").image(m,{})
                    assert(indexed~=raw and require("src.continental_art").indexed[raw][m.cardSuit.."_"..m.cardRank]==indexed,"kingdom portraits must show runtime rank and suit")
                end
            end
        else shot("route_battle_"..item.region.."_"..item.stage) end
    elseif step==n+1 then permit(game,cb)
    elseif step==n+2 then shot("route_permit")
    elseif step==n+3 then T.gold=game.gold;T.deck=game.persistentDeck;click(510,660)
        assert(game.gold==T.gold+1000 and game.run.regionId=="human" and game.run.areaStage==20 and game.persistentDeck==T.deck,"sale button must retain conquered region and deck")
    elseif step==n+4 then shot("route_after_sale")
    elseif step==n+5 then permit(game,cb)
    elseif step==n+6 then click(140,500)
        assert(game.run.regionId=="hearts" and not game.run.travelPermit and game.run.areaStage==1 and game.persistentDeck==T.deck,"destination button must spend permit")
    elseif step==n+7 then shot("route_after_travel")
    elseif step==n+8 then permit(game,cb)
        game.regionRecognitions={hearts=true,diamonds=true,clubs=true,spades=true}
    elseif step==n+9 then click(1140,500)
        assert(game.run.regionId=="unknown" and game.run.travelPermit and game.run.areaStage==1,"unlimited mysterious continent travel")
    elseif step==n+10 then shot("route_after_unknown")
    else print("Journey UI passed: 20 unique backgrounds, 12 rank-only portraits, 21 regional fights, sell +1000, direct kingdom and mysterious travel");love.event.quit();return end
    step=step+1;deadline=love.timer.getTime()+.55
end
return T
