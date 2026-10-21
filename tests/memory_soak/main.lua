-- Run with: lovec . --test-memory-soak [frames]
local frames, game, callbacks = 0
local allocations = {}
local baseline
local ffi = require('ffi')
ffi.cdef[[typedef struct { unsigned long cb,faults; size_t peak,working,pagedPeak,paged,nonpagedPeak,nonpaged,pagefile,peakPagefile; } SoakMemory;
void *GetCurrentProcess(void); int GetProcessMemoryInfo(void*,SoakMemory*,unsigned long);]]
local function report(label)
    local info=ffi.new('SoakMemory');info.cb=ffi.sizeof(info)
    assert(ffi.load('psapi').GetProcessMemoryInfo(ffi.C.GetCurrentProcess(),info,info.cb)~=0)
    local stats=love.graphics.getStats()
    print(('%s frame=%d private=%.1fMiB rss=%.1fMiB textures=%.1fMiB lua=%.1fMiB canvases=%d images=%d'):format(
        label,frames,tonumber(info.pagefile)/1048576,tonumber(info.working)/1048576,
        stats.texturememory/1048576,collectgarbage('count')/1024,stats.canvases,stats.images))
    assert(tonumber(info.pagefile)<1536*1048576,'Memory safety limit exceeded')
    return {private=tonumber(info.pagefile),textures=stats.texturememory,lua=collectgarbage('count')}
end
function love.load(args)
    io.stdout:setvbuf('no')
    local limit=tonumber(args[2]) or 12000
    arg={'--capture'}
    local P=require('src.persistence')
    P.loadRun=function() end;P.saveRun=function() return true end;P.deleteRun=function() end
    P.loadSettings=function(defaults) defaults.fullscreen=false;return defaults end
    P.saveSettings=function() return true end
    package.loaded.capture_screens={update=function(g,cb) game,callbacks=g,cb end}
    local newCanvas=love.graphics.newCanvas
    love.graphics.newCanvas=function(...)
        local caller=debug.getinfo(2,'Sl');local key=caller.short_src..':'..caller.currentline
        allocations[key]=(allocations[key] or 0)+1
        return newCanvas(...)
    end
    assert(loadstring(assert(love.filesystem.read('main.lua')),'@game/main.lua'))()
    love.load();love.window.setVSync(0);report('loaded')
    local update,draw=love.update,love.draw
    love.update=function() update(1/60) end
    love.draw=function()
        draw();frames=frames+1
        local step=frames%1200
        if step==120 then
            -- Repeat identical stock/cards so new catalog art is not mistaken for a leak.
            require('src.rng').seed(12345)
            callbacks.startNewGame();callbacks.startMonsterEncounter(1,false)
        elseif step==180 then callbacks.selectCardIndex(1)
        elseif step==420 then callbacks.playSelectedHand()
        elseif step==720 then callbacks.openShop()
        elseif step==840 then callbacks.openInspector(game.persistentDeck[1])
        elseif step==960 then callbacks.closeInspector()
        elseif step==1080 then callbacks.setCaptureState('menu') end
        if frames%1200==0 then
            collectgarbage('collect');collectgarbage('collect')
            local sample=report('cycle_gc')
            if frames==3600 then baseline=sample end
        end
        if frames>=limit then
            collectgarbage('collect');collectgarbage('collect');local final=report('final_gc')
            if baseline then
                assert(final.lua-baseline.lua<1024,'Lua memory grows across repeated runs')
                assert(final.textures-baseline.textures<64*1048576,'Texture cache grows across repeated runs')
                assert(final.private-baseline.private<128*1048576,'Process memory grows across repeated runs')
            end
            for path,count in pairs(allocations) do print('CANVAS '..path..' '..count) end
            print('Memory soak PASS')
            love.event.quit(0)
        end
    end
    love.errorhandler=function(message) print(debug.traceback(tostring(message),2));return function() return 1 end end
end
