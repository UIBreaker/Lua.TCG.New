package.path=love.filesystem.getWorkingDirectory().."/?.lua;"..package.path
local M=require("src.nen_magic")
local R=require("render.nen_magic")
local C=M.config
local index,aura,quality,speed=1,1000,"high",1
local bloom,paused,impactOnly=true,false,false
local attack,world,bright,blur,brightShader,blurShader,font
local auto=false;for _,a in ipairs(arg or {}) do if a=="--verify" then auto=true end end
local function source(path)
    local f=assert(io.open(path,"rb"));local data=f:read("*a");f:close();return data
end
local function restart()
    M.clear(attack);attack=M.play(C.order[index],aura,{x=520,y=445},{x=660,y=290},
        {quality=quality,speed=speed,impactOnly=impactOnly})
end
local function canvases()
    for _,c in ipairs({world,bright,blur}) do c:release() end
    local w,h=love.graphics.getDimensions()
    world=love.graphics.newCanvas(w,h);bright=love.graphics.newCanvas(math.ceil(w/2),math.ceil(h/2));blur=love.graphics.newCanvas(math.ceil(w/2),math.ceil(h/2))
end
local function scene()
    local g=love.graphics;local w,h=g.getDimensions();g.push("all");g.setCanvas(world);g.clear(.018,.025,.045,1)
    g.scale(w/1280,h/720);g.setShader();g.setBlendMode("alpha")
    g.setColor(.035,.052,.075);g.rectangle("fill",245,135,790,440,20,20)
    g.setColor(.07,.10,.14);g.ellipse("fill",660,440,195,23)
    g.setColor(.12,.16,.20);g.rectangle("fill",615,233,90,123,12,12)
    g.setColor(.23,.3,.35);g.rectangle("line",615,233,90,123,12,12)
    g.setColor(.32,.43,.49);g.circle("fill",660,271,18,24)
    g.polygon("fill",635,318,645,292,675,292,685,318)
    R.draw(attack,attack.phase or "CHARGE",attack.progress or 0,attack.impactAge)
    g.pop()
    if bloom and brightShader and blurShader then
        g.push("all");g.origin();g.setBlendMode("alpha","premultiplied");g.setColor(1,1,1,1)
        g.setCanvas(bright);g.clear();g.setShader(brightShader);brightShader:send("threshold",C.bloom.threshold);brightShader:send("knee",.16)
        g.draw(world,0,0,0,bright:getWidth()/w,bright:getHeight()/h)
        g.setCanvas(blur);g.clear();g.setShader(blurShader);blurShader:send("direction",{C.bloom.radius/bright:getWidth(),0});g.draw(bright)
        g.setCanvas(bright);g.clear();blurShader:send("direction",{0,C.bloom.radius/bright:getHeight()});g.draw(blur)
        g.pop()
    end
    g.setShader();g.setBlendMode("alpha","premultiplied");g.setColor(1,1,1,1);g.draw(world)
    if bloom and brightShader and blurShader then g.setBlendMode("add","premultiplied");g.setColor(C.bloom.intensity,C.bloom.intensity,C.bloom.intensity,1);g.draw(bright,0,0,0,w/bright:getWidth(),h/bright:getHeight()) end
    g.setBlendMode("alpha");g.setColor(1,1,1,1)
end
local function write(name,text)
    local f=assert(io.open("docs/nen_magic/"..name,"wb"));f:write(text);f:close()
end
local function verify()
    assert(R.shader,table.concat(R.diagnostics,"\n"));require("tests.nen_magic_smoke")
    local g=love.graphics;local target=g.newCanvas(1280,720);local timings={};local plays=0
    collectgarbage("collect");local before=collectgarbage("count");local textures=g.getStats().images
    for _,id in ipairs(C.order) do
        for level,value in ipairs({200,1000,2500,8000}) do
            for repetition=1,10 do
                local q=({"low","medium","high"})[(repetition-1)%3+1]
                local a=M.play(id,value,{x=520,y=445},{x=660,y=290},{quality=q})
                local snapshot=a.nen.snapshot;local score=snapshot.aura
                local start=love.timer.getTime();g.push("all");g.setCanvas(target)
                for frame=0,24 do
                    g.clear();a.nen.charge=1
                    local phase=frame<5 and "CHARGE" or frame<17 and "TRAVEL" or "ENEMY_IMPACT"
                    local progress=phase=="TRAVEL" and (frame-5)/11 or 1
                    R.draw(a,phase,progress,phase=="ENEMY_IMPACT" and (frame-17)/7*.42 or nil)
                    assert(a.nen.particleCount<=C.quality[q].particles,id.." particle budget")
                    assert(a.nen.snapshot==snapshot and snapshot.aura==score,id.." immutable score")
                    assert(g.getCanvas()==target and g.getShader()==nil,id.." canvas/shader restoration")
                end
                g.pop();g.flushBatch();local data=target:newImageData();data:release()
                timings[#timings+1]=(love.timer.getTime()-start)*1000/25
                M.clear(a);assert(not M.state(a));plays=plays+1
            end
        end
        print("NEN MAGIC verified "..id.." : 4 AURA x 10 repeats")
    end
    -- All fallback silhouettes must render, with no textures/assets supplied by disk.
    R.forceFallback=true;g.push("all");g.setCanvas(target)
    for _,id in ipairs(C.order) do local a=M.play(id,1e308,{x=520,y=445},{x=660,y=290})
        a.nen.charge=1;R.draw(a,"TRAVEL",.8);R.draw(a,"ENEMY_IMPACT",1,.10);M.clear(a) end
    g.pop();R.forceFallback=false
    assert(g.getStats().images==textures,"per-frame GPU image allocation")
    collectgarbage("collect");local growth=collectgarbage("count")-before
    -- Separate retained attack data from one-time LuaJIT shader/uniform call traces.
    local jitEnabled=jit and jit.status();if jit then jit.off() end
    collectgarbage("collect");local retainedBefore=collectgarbage("count")
    g.push("all");g.setCanvas(target)
    for repetition=1,10 do for _,id in ipairs(C.order) do
        local a=M.play(id,8000,{x=520,y=445},{x=660,y=290});a.nen.charge=1
        R.draw(a,"TRAVEL",.8);R.draw(a,"ENEMY_IMPACT",1,.1);M.clear(a)
    end end
    g.pop();g.flushBatch();collectgarbage("collect")
    local retained=collectgarbage("count")-retainedBefore
    if jitEnabled then jit.on() end
    assert(retained<128,"retained attack memory: "..retained.." KB")
    table.sort(timings);local sum=0;for _,v in ipairs(timings) do sum=sum+v end
    local report=string.format("Native LÖVE 11.5: %d plays, 27000 rendered phase frames; every hand 4 AURA x 10 consecutive repeats.\nLOW/MEDIUM/HIGH particle budgets, immutable aura, graphics-state restoration, cancellation: PASS\n27 shader fallbacks: PASS; GPU image count unchanged.\nPer-frame batch+GPU-readback mean %.3f ms, P95 %.3f ms, max %.3f ms (not whole-game FPS).\nCollected heap delta %.1f KB (includes one-time JIT traces).\nGPU: %s\n",plays,sum/#timings,timings[math.ceil(#timings*.95)],timings[#timings],growth,table.concat({g.getRendererInfo()}," / "))
    report=report..string.format("270 additional create/draw/clear cycles with JIT disabled: retained %.1f KB (<128 KB), PASS.\n",retained)
    write("native_results.txt",report);print(report)
    target:release()
    -- Capture native travel and impact frames at MAXIMUM; metadata stays outside the battlefield.
    for i,id in ipairs(C.order) do
        index=i;aura=8000;restart();attack.nen.charge=1
        for _,phase in ipairs({"travel","impact"}) do
            attack.phase=phase=="travel" and "TRAVEL" or "ENEMY_IMPACT";attack.progress=.78
            attack.impactAge=phase=="impact" and .085 or nil
            scene();local data=world:newImageData();write(id.."_"..phase..".png",data:encode("png"):getString());data:release()
        end
    end
    -- Resize, zero/huge AURA, clearing in flight, pause (no update) and replay.
    for _,resolution in ipairs({{960,540},{1920,1080},{1280,720}}) do
        love.window.setMode(resolution[1],resolution[2],{resizable=true,vsync=0});canvases()
        aura=0;restart();local age=attack.previewAge;scene();assert(attack.previewAge==age)
        aura=1e308;restart();M.update(attack,.8);scene();M.clear(attack);scene()
    end
    print("NEN MAGIC resize/pause/zero/huge/clear: PASS")
end
function love.load()
    local ok,err=xpcall(function()
        local data=love.filesystem.newFileData(source("fonts/font.ttf"),"font.ttf");font=love.graphics.newFont(data,17);love.graphics.setFont(font)
        R.load();canvases()
        local shadersOK=pcall(function() brightShader=love.graphics.newShader(source("shaders/world_bright.glsl"));blurShader=love.graphics.newShader(source("shaders/world_blur.glsl")) end)
        if not shadersOK then bloom=false end
        restart()
        if auto then verify();love.event.quit(0) end
    end,debug.traceback)
    if not ok then print(err);love.event.quit(1) end
end
function love.update(dt) if attack and not paused and not auto and M.update(attack,dt) then restart() end end
function love.draw()
    if not attack or auto then return end
    scene();local g=love.graphics;local w,h=g.getDimensions();g.push();g.scale(w/1280,h/720)
    local profile=C.hands[C.order[index]];local scale=M.scale(aura,1000)
    g.setColor(.72,.82,.94);g.print(string.format("TERRA SUIT / %02d OF 27",index),44,25)
    g.setColor(1,.87,.52);g.print(profile.attackName.."  •  "..profile.name,44,57)
    g.setColor(.72,.82,.94);g.print(string.format("AURA %.3g  /  %s   |   %s   |   %.2fx   |   Bloom %s",aura,scale.name,quality,speed,bloom and "ON" or "OFF"),44,90)
    g.print(string.format("FPS %d   Particles %d/%d   Draws %d",love.timer.getFPS(),R.stats.particles,C.quality[quality].particles,R.stats.draws),44,603)
    g.print("← → chọn chiêu   R phát lại   Space dừng   1–4 mức AURA   +/− chỉnh AURA",44,637)
    g.print("Q chất lượng   B Bloom   E chỉ vụ nổ   Tab tốc độ   F độ phân giải   Esc thoát",44,667)
    g.pop()
end
function love.resize() if world then canvases() end end
function love.keypressed(key)
    if key=="escape" then love.event.quit()
    elseif key=="space" then paused=not paused;return
    elseif key=="right" then index=index%27+1
    elseif key=="left" then index=(index-2)%27+1
    elseif tonumber(key) and tonumber(key)>=1 and tonumber(key)<=4 then aura=({200,1000,2500,8000})[tonumber(key)]
    elseif key=="=" or key=="kp+" then aura=aura==0 and 100 or math.min(1e308,aura*1.5)
    elseif key=="-" or key=="kp-" then aura=aura/1.5
    elseif key=="q" then quality=({low="medium",medium="high",high="low"})[quality]
    elseif key=="b" then bloom=not bloom;return
    elseif key=="e" then impactOnly=not impactOnly
    elseif key=="tab" then speed=speed==.5 and 1 or speed==1 and 2 or .5
    elseif key=="f" then local w=love.graphics.getWidth();local size=w==1280 and {1920,1080} or w==1920 and {960,540} or {1280,720};love.window.setMode(size[1],size[2],{resizable=true,vsync=0});canvases();return
    elseif key~="r" then return end
    restart()
end
