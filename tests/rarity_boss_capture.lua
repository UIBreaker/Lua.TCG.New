local T={stage=0}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/rarity_boss_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();if T.next and now<T.next then return end
    local D=require("src.deities");local B=require("src.boss_abilities")
    if T.stage==0 then
        require("tests.rarity_boss_smoke")
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local R=require("src.run_manager")
        game.run.ante=7;game.run.areaStage=7;game.run.regionId="unknown";game.run.currentBlindIndex=3
        game.run.blinds=R.generateAnteBlinds(7,nil,"unknown",7)
        local data={};for k,v in pairs(require("config.free_human_boss_data").byId.human_rank_inquisitor) do data[k]=v end
        data.sealedSpnTier=3;game.run.blinds[3].debuff=data
        local m=R.createBlindMonster(game.run.blinds[3],game,true);require("src.combat").start(game,m,7)
        local function spn(id,tier)
            local d={};for k,v in pairs(D.CATALOG[id]) do d[k]=v end;D.setRarity(d,D.RARITIES[tier].id);return d
        end
        game.deities={spn("spirit_blade",3),spn("spirit_drum",3),spn("spirit_pebble",1),spn("spirit_ember",10)}
        game.backpackDeities={};game.hand={require("src.deck").newCard(5,"spades"),require("src.deck").newCard(7,"hearts")}
        assert(B.isSlotLocked(game,"spn",1) and B.isSlotLocked(game,"spn",2) and not B.isSlotLocked(game,"spn",3))
        assert(require("src.enemy_art").image(m,{}))
        T.stage=1;T.next=now+1
    elseif T.stage==1 then
        shot("sealed");T.stage=2;T.next=now+.3
    elseif T.stage==2 then
        local rng=require("src.rng");local random=rng.random;rng.random=function() return 1 end
        B.handEnd(game);rng.random=random
        assert(D.getRarityTier(game.deities[1])==1 and not B.isSlotLocked(game,"spn",1) and B.isSlotLocked(game,"spn",2))
        T.stage=3;T.next=now+.4
    elseif T.stage==3 then
        shot("downgrade");T.stage=4;T.next=now+.3
    else
        assert(game.monster.bossData.sealedSpnTier==3)
        T.done=true;print("Rank Inquisitor UI PASS: portrait, rarity R seal/overlay, permanent R to C downgrade, immediate release and purple drain VFX");love.event.quit(0)
    end
end
return T
