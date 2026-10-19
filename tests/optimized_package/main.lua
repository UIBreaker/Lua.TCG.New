function love.load(args)
    local ok,err=xpcall(function()
        assert(args[1],'Pass the absolute .love file to verify')
        local file=assert(io.open(args[1],'rb'))
        local archive=love.filesystem.newFileData(file:read('*a'),'release.love');file:close()
        assert(love.filesystem.mount(archive,''),'Cannot mount release package')
        local A=require('src.runtime_assets')
        local paths=require('config.continental_asset_paths')
        local Art=require('src.continental_art')
        local count=0
        for id,path in pairs(paths) do
            assert(not love.filesystem.getInfo(path),'Source image duplicated: '..path)
            local image=assert(Art.get(id),id)
            local w,h=image:getDimensions();assert(w<=512 and h<=768,id)
            image:release();Art.cache={};count=count+1
        end
        local audio=0
        local function walk(path)
            for _,file in ipairs(love.filesystem.getDirectoryItems(path)) do
                local full=path..'/'..file
                if love.filesystem.getInfo(full).type=='directory' then walk(full)
                elseif full:match('%.ogg$') or full:match('%.wav$') or full:match('%.mp3$') then
                    local data=love.sound.newSoundData(full)
                    assert(data:getSampleCount()>0 and data:getSampleRate()>0,full)
                    data:release();audio=audio+1
                end
            end
        end
        walk('assets/audio')
        local N=require('src.nen_audio');local cues=0
        local decode=love.sound.newSoundData
        local rendered=0
        love.sound.newSoundData=function(value,...)
            if type(value)=='number' then rendered=rendered+1 end
            return decode(value,...)
        end
        N.register({registerProcedural=function(name,data,cue)
            if cue.path then assert(love.filesystem.getInfo(A.audio(cue.path)),name) end
            cues=cues+1
        end})
        love.sound.newSoundData=decode
        assert(cues==#require("config.nen_vfx_config").order*28 and rendered==0,'Baked effects unexpectedly synthesized')
        local Sound=require('src.sound')
        assert(Sound.init(),'Mixer could not initialize compressed cues')
        local common=0;for _ in pairs(require('config.audio_catalog').cues) do common=common+1 end
        assert(Sound.stats().cues==common+cues+#require('src.reward_audio').order*4,'Missing mixer cues')
        assert(Sound.play('nen_high_card_armor_break') and Sound.play('card_deal'))
        local game={playerHp=100,maxPlayerHp=100,monster={stage=1}}
        for _,state in ipairs({'menu','playing','shop','defeat'}) do Sound.update(.02,state,game,false) end
        assert(Sound.stats().loops>0 and Sound.stats().loops<=6,'Compressed music/ambience streams')
        Sound.stopAll()
        print(('Optimized package PASS: %d canonical artworks, %d decodable audio files, %d cues, all baked attack phases registered'):format(count,audio,cues))
    end,debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
