-- Real LÖVE decoder/OpenAL verification, with muted output and no game save writes.
function love.load()
    io.stdout:setvbuf("no")
    local realLove=love
    for _,name in ipairs({"audio_smoke","menu_music_smoke","enemy_attack_presentation_smoke",
        "action_vfx_juice_smoke","scoring_presentation_smoke","hand_vfx_smoke","bed_explosion_smoke","reward_ceremony_smoke"}) do
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
    local nativeNewSource=love.audio.newSource
    local allocations=0
    love.audio.newSource=function(...) allocations=allocations+1;return nativeNewSource(...) end
    for i=1,30 do love.timer.sleep(.04);assert(S.play("chip_tick"));S.stopAll() end
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
    for _,path in ipairs({"main.lua","conf.lua","src/sound.lua","src/scoring_presentation.lua","src/enemy_attack_presentation.lua","ui/audio_settings.lua","config/audio_catalog.lua"}) do
        local fn,err=loadfile(path);assert(fn,err)
    end
    print(string.format("LÖVE audio PASS: %d real SFX, all context streams + 10 ambient decoders; no playback allocation; init %.1fms",count,initTime*1000))
    love.event.quit(0)
end
function love.errorhandler(message)
    print(debug.traceback(message,2))
    return function() return 1 end
end
