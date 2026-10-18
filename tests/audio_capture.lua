-- Real LÖVE decoder/OpenAL verification, with muted output and no game save writes.
function love.load()
    io.stdout:setvbuf("no")
    local realLove=love
    assert(loadfile("tests/nen_audio_smoke.lua"))()
    assert(loadfile("tests/reward_audio_smoke.lua"))()
    for _,name in ipairs({"audio_smoke","menu_music_smoke","enemy_attack_presentation_smoke",
        "action_vfx_juice_smoke","scoring_presentation_smoke","hand_vfx_smoke","bed_explosion_smoke","reward_ceremony_smoke","attack_outcome_audio_smoke","reward_audio_routing_smoke"}) do
        local ok,err=pcall(function() assert(loadfile("tests/"..name..".lua"))() end)
        love=realLove
        package.loaded["src.sound"]=nil
        assert(ok,name..": "..tostring(err))
    end
    local S=require("src.sound")
    local C=require("config.audio_catalog")
    local started=love.timer.getTime()
    assert(S.init(),"real decoder must load every cue")
    local initTime=love.timer.getTime()-started
    love.audio.setVolume(0)
    local count=0
    for name in pairs(C.cues) do
        assert(S.has(name),name)
        assert(S.play(name),"real playback: "..name)
        S.stopAll();count=count+1
    end
    local nenCount=0
    for _,id in ipairs(require("config.nen_vfx_config").order) do
        for _,kind in ipairs({"charge","charge_strong","charge_extreme","release","release_strong","release_extreme","beat","impact","impact_strong","impact_extreme",
            "armor_break","armor_break_strong","armor_break_extreme","finisher","finisher_strong","finisher_extreme",
            "armored_finisher","armored_finisher_strong","armored_finisher_extreme",
            "boss_finisher","boss_finisher_strong","boss_finisher_extreme",
            "boss_armored_finisher","boss_armored_finisher_strong","boss_armored_finisher_extreme"}) do
            assert(S.play("nen_"..id.."_"..kind));S.stopAll();nenCount=nenCount+1
        end
    end
    for _,c in pairs(C.cues) do
        for _,path in ipairs(c.variants or {}) do
            local v=love.audio.newSource(path,"static");v:setVolume(0);v:play();assert(v:isPlaying(),path);v:stop();v:release()
        end
    end
    local nativeNewSource=love.audio.newSource
    local allocations=0
    love.audio.newSource=function(...) allocations=allocations+1;return nativeNewSource(...) end
    local rewardCount=0
    for _,id in ipairs(require("src.reward_audio").order) do for _,phase in ipairs({"charge","open","receive","collect"}) do
        assert(S.play("reward_"..phase.."_"..id));S.stopAll();rewardCount=rewardCount+1
    end end
    for i=1,30 do love.timer.sleep(.04);assert(S.play("chip_tick"));S.stopAll() end
    for _,id in ipairs(require("config.nen_vfx_config").order) do
        assert(S.play("nen_"..id.."_charge_extreme",3.72));S.stopCue("nen_"..id.."_charge_extreme")
        assert(S.play("nen_"..id.."_release_extreme",3.72));S.stopAll()
        assert(S.play("nen_"..id.."_impact_extreme"));S.stopAll()
        for _,kind in ipairs({"armor_break","finisher","armored_finisher","boss_finisher","boss_armored_finisher"}) do assert(S.play("nen_"..id.."_"..kind.."_extreme"));S.stopAll() end
    end
    for i=1,4 do love.timer.sleep(.065);assert(S.play("nen_endless_cycle_impact_extreme")) end
    assert(S.stats().voices==3,"rapid extreme contacts must replace old tails")
    S.stopAll()
    assert(allocations==0,"runtime effects must use preallocated pools")
    for _,state in ipairs({"menu","playing","scoring","shop","map","rest","event","victory","gameover","defeating","chest","CASH_OUT","socketing","boss_deity","BLIND_SELECT"}) do
        for _,stage in ipairs({1,3,5,21,41}) do
            S.update(2,state,{run={ante=stage},monster={stage=stage,isBoss=stage%2==1},playerHp=20,maxPlayerHp=100})
            assert(S.stats().loops<=6,state)
        end
    end
    for name,entry in pairs(C.music) do
        local s=nativeNewSource(entry.path,"stream")
        s:setLooping(true);s:setVolume(0);s:play();assert(s:isPlaying(),name);s:stop();s:release()
    end
    for name,entry in pairs(C.ambience) do
        local data=love.sound.newSoundData(entry.path)
        assert(data:getChannelCount()==2 and data:getSampleRate()==32000,name)
        local s=nativeNewSource(entry.path,"stream")
        s:setLooping(true);s:setVolume(0);s:play();assert(s:isPlaying(),name);s:stop();s:release();data:release()
    end
    S.stopAll();S.update(2,"playing",{monster={stage=21}})
    S.setFocused(false);S.setFocused(true)
    S.setMusicVolume(0);S.setAmbienceVolume(0);S.update(2,"rest")
    assert(S.stats().loops==0)
    S.stopAll();love.audio.newSource=nativeNewSource
    -- Export real Nen PCM over the new arrangement for an audible in-world preview.
    local rate,seconds=32000,24
    local preview=love.sound.newSoundData(rate*seconds,rate,16,2)
    local bed=love.sound.newSoundData(C.music.boss.path)
    for i=0,preview:getSampleCount()-1 do
        for channel=1,2 do preview:setSample(i,channel,bed:getSample(i,channel)*.32) end
    end
    bed:release()
    local moments={nen_high_card_impact=2,nen_pair_release=5,nen_tesla_369_impact_extreme=8,
        nen_even_frost_impact_strong=12,nen_eclipse_duality_impact_extreme=16,nen_endless_cycle_impact_extreme=20}
    local handOrder=require("config.nen_vfx_config").order
    local signatures=love.sound.newSoundData(rate*#handOrder*2,rate,16,2)
    local weights=love.sound.newSoundData(rate*8,rate,16,2)
    local showcase=love.sound.newSoundData(rate*30,rate,16,2)
    local extremes=love.sound.newSoundData(math.floor(rate*#handOrder*2.5),rate,16,2)
    local compare={four_of_a_kind=1,tesla_369=2,even_frost=3,eclipse_duality=4}
    local launchShowcase=love.sound.newSoundData(math.floor(rate*38.4),rate,16,2)
    local fullExtremes=love.sound.newSoundData(math.floor(rate*#handOrder*3.2),rate,16,2)
    local outcomeShowcase=love.sound.newSoundData(math.floor(rate*43.2),rate,16,2)
    local outcomeExtremes=love.sound.newSoundData(rate*#handOrder*4,rate,16,2)
    local bossShowcase=love.sound.newSoundData(rate*64,rate,16,2)
    local bossExtremes=love.sound.newSoundData(rate*#handOrder*8,rate,16,2)
    local victoryShowcase=love.sound.newSoundData(rate*32,rate,16,2)
    local rewardShowcase=love.sound.newSoundData(rate*40,rate,16,2)
    local rewardFlow=love.sound.newSoundData(rate*16,rate,16,2)
    local function pitched(target,start,data,gain,pitch,limit)
        local offset=math.floor(start*rate)
        local n=math.min(math.floor((data:getSampleCount()-1)/pitch),target:getSampleCount()-offset)
        if limit then n=math.min(n,math.floor(limit*rate)) end
        for i=0,n-1 do
            local source=i*pitch
            local a=math.floor(source);local blend=source-a
            for channel=1,2 do
                local value=data:getSample(a,channel)*(1-blend)+data:getSample(a+1,channel)*blend
                if limit then value=value*math.min(1,(n-1-i)/64) end
                value=target:getSample(offset+i,channel)+value*gain
                assert(math.abs(value)<.92,"tier showcase headroom")
                target:setSample(offset+i,channel,value)
            end
        end
    end
    local positions={}
    for i,id in ipairs(handOrder) do positions[id]=(i-1)*2 end
    require("src.nen_audio").register({registerProcedural=function(name,data,cue)
        local bossHand=name:match("^nen_(.-)_boss_armored_finisher")
        local armored=bossHand~=nil
        if not bossHand then bossHand=name:match("^nen_(.-)_boss_finisher") end
        if bossHand then
            local level=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
            local pitch=1.05-(level-1)*.11
            if bossHand=="four_of_a_kind" then
                local slot=not armored and level-1 or level==3 and 3 or nil
                if slot then pitched(bossShowcase,slot*8+.02,data,cue.gain*.8,pitch) end
            elseif armored and level==3 then
                local slot=({tesla_369=4,even_frost=5,eclipse_duality=6,continental_gate=7})[bossHand]
                if slot then pitched(bossShowcase,slot*8+.02,data,cue.gain*.8,pitch) end
            end
            if armored and level==3 then
                pitched(bossExtremes,positions[bossHand]/2*8+.02,data,cue.gain*.8,pitch)
                if compare[bossHand] then pitched(victoryShowcase,(compare[bossHand]-1)*8+.02,data,cue.gain*.8,pitch) end
                if bossHand=="four_of_a_kind" then pitched(rewardFlow,0,data,cue.gain*.8,pitch) end
            end
        end
        local outcomeHand,kind
        for i,key in ipairs({"armor_break","finisher","armored_finisher"}) do
            outcomeHand=name:match("^nen_(.-)_"..key)
            if outcomeHand and require("config.attack_audio")[outcomeHand] then kind=i;break end
            outcomeHand=nil
        end
        if outcomeHand then
            local level=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
            local pitch=1.05-(level-1)*.11
            -- Nine gestures of the same hand expose both outcome and power differences.
            if outcomeHand=="four_of_a_kind" then
                pitched(outcomeShowcase,((kind-1)*3+level-1)*3.6+.02,data,cue.gain*.8,pitch)
            elseif level==3 and kind==3 then
                local slot=({tesla_369=9,even_frost=10,eclipse_duality=11})[outcomeHand]
                if slot then pitched(outcomeShowcase,slot*3.6+.02,data,cue.gain*.8,pitch) end
            end
            if level==3 and kind==3 then pitched(outcomeExtremes,positions[outcomeHand]/2*4+.02,data,cue.gain*.8,pitch) end
        end
        local cycleHand,phase=name:match("^nen_(.-)_(charge)")
        if not cycleHand then cycleHand,phase=name:match("^nen_(.-)_(release)") end
        if not cycleHand then cycleHand,phase=name:match("^nen_(.-)_(impact)") end
        if cycleHand then
            local level=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
            local timing=require("config.nen_vfx_config").timing[level]
            local windup=timing[3]+timing[4]+timing[5]
            local at=phase=="charge" and 0 or phase=="release" and windup or windup+timing[6]+timing[7]
            local pitch=phase=="impact" and 1.05-(level-1)*.11 or 1
            if compare[cycleHand] then
                pitched(launchShowcase,(compare[cycleHand]-1)*9.6+(level-1)*3.2+at+.02,data,cue.gain*.8,pitch)
            end
            if level==3 then pitched(fullExtremes,positions[cycleHand]/2*3.2+at+.02,data,cue.gain*.8,pitch) end
        end
        local hand=name:match("^nen_(.-)_impact")
        if hand then
            local level=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
            local pitch=1.05-(level-1)*.11
            if compare[hand] then pitched(showcase,(compare[hand]-1)*7.5+(level-1)*2.5+.05,data,cue.gain*.8,pitch) end
            if level==3 then pitched(extremes,positions[hand]/2*2.5+.05,data,cue.gain*.8,pitch) end
        end
        local at=moments[name]
        if at then
            for i=0,data:getSampleCount()-1 do
                for channel=1,2 do
                    local pos=at*rate+i
                    preview:setSample(pos,channel,preview:getSample(pos,channel)*.55+data:getSample(i,channel)*cue.gain)
                end
            end
        end
        local id=name:match("^nen_(.-)_release$")
        local offset=.08
        if not id then id=name:match("^nen_(.-)_impact$");offset=.32 end
        if id then
            local start=math.floor((positions[id]+offset)*rate)
            for i=0,data:getSampleCount()-1 do
                for channel=1,2 do
                    local value=signatures:getSample(start+i,channel)+data:getSample(i,channel)*cue.gain*.85
                    assert(math.abs(value)<.92,"signature preview headroom")
                    signatures:setSample(start+i,channel,value)
                end
            end
        end
        local tier=name=="nen_high_card_impact" and 1 or name=="nen_high_card_impact_strong" and 2
            or name=="nen_high_card_impact_extreme" and 3
        if tier then
            pitched(weights,(tier-1)*2,data,cue.gain*.8,1.05-(tier-1)*.11)
        end
    end})
    local rewardAudio=require("src.reward_audio")
    local rewardOrder={};for i,id in ipairs(rewardAudio.order) do rewardOrder[id]=i end
    rewardAudio.register({registerProcedural=function(name,data,cue)
        local phase,id=name:match("^reward_(.-)_([^_]+)$")
        local at=({charge=0,open=.50,receive=1.70,collect=2.50})[phase]
        pitched(rewardShowcase,(rewardOrder[id]-1)*4+at,data,cue.gain*.8,1,phase=="charge" and .50 or nil)
        local theme=210*.83*2/261.63
        if id=="legendary" and phase=="charge" then pitched(rewardFlow,4.10,data,cue.gain*.8,theme,.525)
        elseif id=="legendary" and phase=="open" then pitched(rewardFlow,4.625,data,cue.gain*.8,theme)
        elseif phase=="receive" then
            local moment=({common=6.0,rare=7.2,epic=8.6,legendary=10.2,supreme=12.3})[id]
            if moment then pitched(rewardFlow,moment,data,cue.gain*.8,theme) end
        elseif id=="supreme" and phase=="collect" then pitched(rewardFlow,13.8,data,cue.gain*.8,theme) end
    end})
    local function le(value,bytes)
        local parts={};for i=1,bytes do parts[i]=string.char(value%256);value=math.floor(value/256) end
        return table.concat(parts)
    end
    local function wav(name,pcm)
        local out=assert(io.open("docs/audio/"..name..".wav","wb"))
        out:write("RIFF"..le(36+#pcm,4).."WAVEfmt "..le(16,4)..le(1,2)..le(2,2)..le(rate,4)..le(rate*4,4)..le(4,2)..le(16,2).."data"..le(#pcm,4)..pcm)
        out:close()
    end
    wav("nen_cinematic_preview",preview:getString())
    local pcm=signatures:getString()
    wav("hand_attack_signatures",pcm)
    wav("poker_attack_preview",pcm:sub(1,18*rate*4))
    wav("attack_weights_preview",weights:getString())
    wav("attack_tiers_showcase",showcase:getString())
    wav("extreme_attack_signatures",extremes:getString())
    wav("windup_launch_showcase",launchShowcase:getString())
    wav("extreme_full_attacks",fullExtremes:getString())
    wav("armor_finisher_showcase",outcomeShowcase:getString())
    wav("armored_finisher_signatures",outcomeExtremes:getString())
    wav("boss_finisher_showcase",bossShowcase:getString())
    wav("boss_verdict_signatures",bossExtremes:getString())
    wav("boss_victory_showcase",victoryShowcase:getString())
    wav("reward_rarity_showcase",rewardShowcase:getString())
    wav("boss_reward_flow",rewardFlow:getString())
    preview:release();signatures:release();weights:release();showcase:release();extremes:release()
    launchShowcase:release();fullExtremes:release()
    outcomeShowcase:release();outcomeExtremes:release()
    bossShowcase:release();bossExtremes:release()
    victoryShowcase:release()
    rewardShowcase:release();rewardFlow:release()
    for _,path in ipairs({"main.lua","conf.lua","src/sound.lua","src/scoring_presentation.lua","src/enemy_attack_presentation.lua","ui/audio_settings.lua","config/audio_catalog.lua"}) do
        local fn,err=loadfile(path);assert(fn,err)
    end
    print(string.format("LÖVE audio PASS: %d file SFX + %d Nen + %d reward cues + all variants, music and ambience; no playback allocation; init %.1fms",count,nenCount,rewardCount,initTime*1000))
    love.event.quit(0)
end
function love.errorhandler(message)
    print(debug.traceback(message,2))
    return function() return 1 end
end
