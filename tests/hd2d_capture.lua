-- lovec.exe . --test-hd2d. Captures settled scenes and real frame intervals.
local R=require("render.renderer")
local T={};local stage="start";local deadline=0;local started=0;local pending
local perf={};local samples={};local warmup=0;local lastProfile;local sizes={{1920,1080},{1600,900},{1366,768}}
local scenesOnly=false
for _,value in ipairs(arg or {}) do if value=="--hd2d-scenes-only" then scenesOnly=true end end
local sizeIndex,qualityIndex=1,1;local qualities={"LOW","MEDIUM","HIGH"}
local function after(name,delay) stage=name;deadline=love.timer.getTime()+(delay or 0.9) end
local function shot(name)
    assert(R.transitionAge>=R.config.transition.duration or name:find("debug"), "scene transition must settle: "..name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/hd2d/after_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function report()
    local f=assert(io.open("docs/hd2d/performance.md","wb"))
    local engine,version,vendor,device=love.graphics.getRendererInfo();local os=love.system.getOS()
    f:write("# HD2D local runtime measurements\n\n",os," / ",engine," / ",version," / ",vendor," / ",device,"\n\n")
    f:write("Uncapped vsync=0, warmed idle boss battle. Consecutive wall-clock update intervals, not guarantees for target hardware.\n\n")
    f:write("| Window | Quality | Samples | Average ms | P50 ms | P95 ms | Mean FPS | World CPU submission ms |\n|---|---|---:|---:|---:|---:|---:|---:|\n")
    for _,p in ipairs(perf) do f:write(string.format("| %s | %s | %d | %.2f | %.2f | %.2f | %.1f | %.2f |\n",p.window,p.quality,p.count,p.avg,p.p50,p.p95,1000/p.avg,p.cpu)) end
    f:write("\nCPU submission timing surrounds world render command submission; it is not GPU execution time. Shader validation, snapshots, mode changes and warmup are excluded from frame sample windows. Artwork, card shaders and full UI are enabled. Bloom uses 2 reduced targets; particles capped at 18/36/56.\n")
    f:close()
end
function T.update(game,callbacks)
    local now=love.timer.getTime()
    if pending then local action=pending;pending=nil;action();return end
    assert(started==0 or now-started<65,"HD2D capture timeout at "..stage)
    if stage=="profile" and now>warmup then
        if lastProfile then samples[#samples+1]=(now-lastProfile)*1000 end
        lastProfile=now
    end
    if now<deadline then return end
    if stage=="start" then
        started=now;require("tests.hd2d_smoke")
        love.mouse.setPosition(4,4)
        callbacks.setCaptureState("menu");after("menu")
    elseif stage=="menu" then
        shot("menu"); pending=function()
            callbacks.openCollection();after("collection")
        end
        stage="pending"
    elseif stage=="collection" then
        shot("collection"); pending=function()
            callbacks.openCollection("jokers");after("collection_detail")
        end
        stage="pending"
    elseif stage=="collection_detail" then
        shot("collection_detail"); pending=function()
            callbacks.closeCollection();callbacks.startNewGame("red_deck")
        callbacks.startMonsterEncounter(20,true);game.playerHp,game.maxPlayerHp=100,100
        game.monster.hp,game.monster.maxHp,game.monster.damageLagHp=1000000,1000000,1000000
        after("battle")
        end
        stage="pending"
    elseif stage=="battle" then
        assert(R.scene.name=="battle");shot("battle"); pending=function()
            callbacks.openDeckViewer();after("deck")
        end
        stage="pending"
    elseif stage=="deck" then
        shot("deck"); pending=function()
            callbacks.closeDeckViewer();callbacks.openSettings();after("settings")
        end
        stage="pending"
    elseif stage=="settings" then
        shot("settings"); pending=function()
            callbacks.closeSettings();callbacks.openShop();game.gold=120;after("shop")
        end
        stage="pending"
    elseif stage=="shop" then
        shot("shop"); pending=function()
            callbacks.openPack({category="pack",packType="standard",name="HD2D test"});after("pack")
        end
        stage="pending"
    elseif stage=="pack" then
        shot("pack"); pending=function()
            if scenesOnly then print("HD2D scenes-only capture PASS");love.event.quit(0);return end
            callbacks.closePack();callbacks.openRest();after("rest")
        end
        stage="pending"
    elseif stage=="rest" then
        shot("rest"); pending=function()
            callbacks.openBossDeity();after("boss_draft")
        end
        stage="pending"
    elseif stage=="boss_draft" then
        shot("boss_draft"); pending=function()
            callbacks.openReward();after("reward",3.5)
        end
        stage="pending"
    elseif stage=="reward" then
        shot("reward"); pending=function()
            callbacks.startMonsterEncounter(20,true)
        game.playerHp,game.maxPlayerHp=100,100
        game.monster.hp,game.monster.maxHp,game.monster.damageLagHp=1000000,1000000,1000000
        after("profile_begin",0.1)
        end
        stage="pending"
    elseif stage=="profile_begin" then
        local size=sizes[sizeIndex];love.window.setMode(size[1],size[2],{resizable=true,vsync=0,highdpi=true})
        love.resize(size[1],size[2]);R.setQuality(qualities[qualityIndex]);samples={};lastProfile=nil;R.stats={frames=0,total=0,peak=0}
        warmup=now+0.5;after("profile",1.5)
    elseif stage=="profile" then
        table.sort(samples);local sum=0;for _,ms in ipairs(samples) do sum=sum+ms end
        local count=#samples;assert(count>5,"profile needs enough frames")
        perf[#perf+1]={window=sizes[sizeIndex][1].."x"..sizes[sizeIndex][2],quality=R.quality,count=count,
            avg=sum/count,p50=samples[math.ceil(count*0.5)],p95=samples[math.ceil(count*0.95)],cpu=R.stats.total/math.max(1,R.stats.frames)}
        if qualityIndex==3 then shot("battle_"..sizes[sizeIndex][1]) end
        pending=function()
        qualityIndex=qualityIndex+1
        if qualityIndex>3 then qualityIndex=1;sizeIndex=sizeIndex+1 end
        if sizeIndex>#sizes then R.setQuality("HIGH");love.window.setMode(1280,720,{resizable=true,vsync=0});love.resize(1280,720);R.debugIndex=2;after("debug_layers")
        else after("profile_begin",0.1) end
        end
        stage="pending"
    elseif stage=="debug_layers" then
        shot("debug_layers"); pending=function()
            R.debugIndex=3;after("debug_light",0.1)
        end
        stage="pending"
    elseif stage=="debug_light" then
        shot("debug_light"); pending=function()
            R.debugIndex=4;after("debug_bloom",0.1)
        end
        stage="pending"
    elseif stage=="debug_bloom" then
        shot("debug_bloom"); pending=function()
            R.debugIndex=5;after("debug_fog",0.1)
        end
        stage="pending"
    elseif stage=="debug_fog" then
        shot("debug_fog"); pending=function()
            R.debugIndex=6;after("debug_dof",0.1)
        end
        stage="pending"
    elseif stage=="debug_dof" then
        shot("debug_dof"); pending=function()
            R.debugIndex=7;after("debug_particles",0.1)
        end
        stage="pending"
    elseif stage=="debug_particles" then
        shot("debug_particles"); pending=function()
            R.debugIndex=0;R.config.enabled=false;after("disabled")
        end
        stage="pending"
    elseif stage=="disabled" then
        shot("effects_disabled"); pending=function()
            R.config.enabled=true;report()
        print("HD2D checkpoint 8 PASS: settled scenes, pass views, effects OFF, 9 window/quality profiles; "..#perf.." measurements")
        love.event.quit(0)
        end
        stage="pending"

    end
end
return T
