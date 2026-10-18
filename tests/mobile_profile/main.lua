local started,frames,phase,last=0,0,1,0
local phases={'menu','battle','shop'}
local samples,rows={},{}
local function memory()
    local ok,value=pcall(function()
        local ffi=require('ffi')
        ffi.cdef[[typedef struct { unsigned long cb,faults; size_t peak,working,pagedPeak,paged,nonpagedPeak,nonpaged,pagefile,peakPagefile; } ProfileMemory;
            void *GetCurrentProcess(void); int GetProcessMemoryInfo(void*,ProfileMemory*,unsigned long);]]
        local info=ffi.new('ProfileMemory');info.cb=ffi.sizeof(info)
        assert(ffi.load('psapi').GetProcessMemoryInfo(ffi.C.GetCurrentProcess(),info,info.cb)~=0)
        return tonumber(info.working)/1048576
    end)
    return ok and value or 0
end
local function record(name,seconds)
    local stats=love.graphics.getStats()
    local row=('%s,%.3f,%.1f,%.1f,%.1f'):format(name,seconds*1000,memory(),stats.texturememory/1048576,collectgarbage('count')/1024)
    print(row);rows[#rows+1]=row
end
function love.load(args)
    io.stdout:setvbuf('no')
    assert(args[1],'Pass .love archive')
    local file=assert(io.open(args[1],'rb'))
    local archive=love.filesystem.newFileData(file:read('*a'),'game.love');file:close()
    assert(love.filesystem.mount(archive,''))
    package.path=''
    arg={'--capture'}
    os.time=function() return 1792330200 end -- identical encounters and shop stock before/after
    local P=require('src.persistence')
    P.loadRun=function() end;P.saveRun=function() return true end;P.deleteRun=function() end
    P.loadSettings=function(defaults) defaults.fullscreen=false;defaults.graphicsQuality=args[3] or defaults.graphicsQuality;return defaults end
    P.saveSettings=function() return true end
    local capture={}
    package.loaded.capture_screens=capture
    function capture.update(game,cb)
        if frames==240 then cb.startNewGame();cb.startMonsterEncounter(1,false)
        elseif frames==480 then cb.openShop() end
    end
    local function wrap(module,key)
        local object=require(module);local original=object[key]
        object[key]=function(...)
            local t=love.timer.getTime();local results={original(...)}
            record(module..'.'..key,love.timer.getTime()-t)
            return unpack(results)
        end
    end
    for _,entry in ipairs({{'src.sound','init'},{'src.enemy_art','load'},{'render.scene','load'},
        {'render.renderer','load'},{'src.card_effects','load'},{'src.ui','initFonts'},{'ui.collection_book','prepare'}}) do wrap(unpack(entry)) end
    require('src.touch_input').lowPower=true
    collectgarbage('collect');record('before_load',0)
    local main=assert(love.filesystem.read('main.lua'))
    assert(main:find('cardEffectsSmokeMode',1,true),'Archive must precede harness')
    started=love.timer.getTime();assert(loadstring(main,'@packaged/main.lua'))()
    love.load();record('menu_ready',love.timer.getTime()-started)
    love.window.setVSync(0)
    local update,draw=love.update,love.draw
    love.update=function(dt) update(1/60) end
    love.draw=function()
        local t=love.timer.getTime();draw()
        frames=frames+1
        if frames%240>80 and last>0 then samples[#samples+1]=t-last end
        last=t
        if frames%240==0 then
            table.sort(samples);local sum=0;for _,v in ipairs(samples) do sum=sum+v end
            record(phases[phase]..'_mean_frame',sum/#samples)
            record(phases[phase]..'_p95_frame',samples[math.ceil(#samples*.95)])
            samples={};phase=phase+1
        end
        if frames>=720 then
            local out=assert(io.open(args[2] or '.tmp/mobile-profile.csv','wb'))
            out:write('phase,ms,rss_mib,texture_mib,lua_mib\n'..table.concat(rows,'\n'));out:close()
            love.event.quit(0)
        end
    end
end
