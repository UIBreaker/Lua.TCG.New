local V=require("src.timing_vfx")
local T={index=1,frame=0}
local scenes={
    {"attack","good",.85,"XANH · ĐÒN ĐÁNH TỐT"},
    {"attack","perfect",.95,"VÀNG · CHÍNH XÁC"},
    {"attack","critical",1.0,"LAM ◆ · ĐÒN QUYẾT ĐỊNH",3},
    {"attack","ultimate",1.15,"TÍM ★ · TUYỆT KỸ",2},
    {"attack","apex",1.25,"TRẮNG ✦ · CỰC HẠN",2},
    {"attack","divine",1.30,"HỒNG NGỌC ♦ · THẦN TÍCH",3},
    {"block","perfect",.95,"PARRY · CHẶN HOÀN TOÀN"},
    {"reflect","ultimate",1.40,"PARRY TÍM · PHẢN LỰC"},
    {"reflect","apex",1.50,"PARRY TRẮNG · PHẢN LỰC CỰC HẠN",2},
    {"reflect","divine",1.60,"PARRY THẦN TÍCH · CHUỖI ×3",3},
    {"miss","trap",.85,"ĐÁNH HỤT · CHÉM LỆCH"},
    {"break","trap",.85,"PARRY TRƯỢT · VỠ THẾ ĐỠ"},
}
function T.update(game,cb)
    if T.finished or T.pending then return end
    if not T.started then
        -- Every exported frame has an exact authored timestamp, independent of encoding time.
        V.update=function() end
        local encoder=assert(os.getenv("TIMING_VFX_FFMPEG"),"set TIMING_VFX_FFMPEG to the local ffmpeg executable")
        assert(not encoder:find('[%s"&|<>]'),"use an encoder path relative to the workspace without spaces")
        local cmd=encoder:gsub("/","\\")..' -v error -y -f image2pipe -framerate 30 -i - -an -vf scale=960:540 -c:v libx264 -crf 20 -preset fast -pix_fmt yuv420p -movflags +faststart docs/timing_vfx_preview.mp4'
        T.pipe=assert(io.popen(cmd,love.system.getOS()=="Windows" and "wb" or "w"))
        love.window.setMode(960,540,{resizable=true})
        love.resize(960,540)
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        cb.setReducedMotion(false);cb.setGameSpeed(1)
        game.monster.hp=100000;game.monster.maxHp=100000;game.monster.damageLagHp=100000
        love.mouse.setPosition(2,2)
        local draw=love.draw;local font=require("src.ui").fonts.regular
        for _,scene in ipairs(scenes) do
            assert(font:hasGlyphs(scene[4]),"preview font is missing caption glyphs: "..scene[4])
        end
        love.draw=function()
            draw()
            local g=love.graphics;local w,h=g.getDimensions()
            g.push("all");g.origin();g.setShader()
            local profile=V.profiles[T.grade] or V.profiles.normal;local c=profile.color
            local panelW=math.min(w-32,font:getWidth(T.caption or "")+56)
            local px=(w-panelW)/2
            local captionY=h-115
            g.setColor(.012,.018,.032,.94);g.rectangle("fill",px,captionY,panelW,32,4)
            g.setColor(c[1],c[2],c[3],.7);g.setLineWidth(1)
            g.line(px+14,captionY+31,px+panelW-14,captionY+31)
            require("ui.components.timing_caption").draw(T.caption or "",T.grade,px+8,captionY+6,panelW-16,font,T.age,false)
            g.pop()
            if T.rail and T.age<.4 then
                g.push("all");g.origin();g.scale(w/1280,h/720)
                require("src.combat_timing").draw(T.rail,require("src.ui"));V.draw("rail")
                g.pop()
            end
        end
        T.started=true;T.ready=love.timer.getTime()+1
        return
    end
    if love.timer.getTime()<T.ready then return end
    local scene=scenes[T.index]
    if not scene then
        T.finished=true;T.pipe:close();T.pipe=nil
        print("Timing VFX reel passed: 12 scenes, deterministic 30 FPS, streamed PNG frames to H.264")
        love.event.quit(0);return
    end
    V.clear()
    if T.railScene~=T.index then
        local Timing=require("src.combat_timing")
        T.rail=Timing.start((scene[1]=="reflect" or scene[1]=="block") and "parry" or "attack",10,10)
        local band=scene[2]=="divine" and T.rail.divine or T.rail.apex
        for _,zone in ipairs(T.rail.zones) do if zone.grade==scene[2] then band=zone;break end end
        T.rail.position=(band.from+band.to)/2;T.rail.age=1;T.rail.result={grade=scene[2],chain=scene[5] or 1}
        T.railScene=T.index
    end
    T.rail.hold=T.frame/30
    local l=require("src.combat_timing").layout(require("src.ui"))
    local rail=V.emit("confirm",scene[2],l.bx+T.rail.position*l.bw,l.by+7,{railX=l.bx,railW=l.bw,chain=scene[5] or 1})
    rail.age=T.frame/30
    local e=V.emit(scene[1],scene[2],630,270)
    e.age=T.frame/30;T.caption=scene[4];T.grade=scene[2];T.age=e.age
    T.pending=true
    love.graphics.captureScreenshot(function(data)
        assert(T.pipe:write(data:encode("png"):getString()))
        T.frame=T.frame+1;T.pending=false
        if T.frame>=math.ceil(scene[3]*30) then T.index=T.index+1;T.frame=0 end
    end)
end
return T
