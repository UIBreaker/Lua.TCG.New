local F=require("src.scoring_presentation")
local N=require("src.nen_combat")
local UI=require("src.ui")
local R=require("render.renderer")
local Sound=require("src.sound")
local T={}
local case,started=0,nil
local initialized,warmUntil=false,nil
local captured={}
local all,benchmark=false,false
for _,option in ipairs(arg or {}) do
    if option=="--nen-all-lab" then all=true end
    if option=="--nen-benchmark" then all=true;benchmark=true end
end
local order=all and N.config.order or N.config.samples
local variants=#order*3
local intervals,drawPeak,particlePeak,spikes={},0,0,{}
local originalDraw=F.drawLab
F.drawLab=function(ui)
    local g=love.graphics
    local shader,canvas,width=g.getShader(),g.getCanvas(),g.getLineWidth()
    local sx,sy,sw,sh=g.getScissor();local blend,alpha=g.getBlendMode()
    local x,y=g.transformPoint(0,0)
    originalDraw(ui)
    if benchmark and started and love.timer.getTime()-started>.12 then
        drawPeak=math.max(drawPeak,g.getStats().drawcalls or 0)
        local n=F.labAnim and F.labAnim.sequence.attack.nen
        particlePeak=math.max(particlePeak,n and n.particleCount or 0)
    end
    local ax,ay,aw,ah=g.getScissor();local ab,aa=g.getBlendMode();local tx,ty=g.transformPoint(0,0)
    assert(shader==g.getShader() and canvas==g.getCanvas() and width==g.getLineWidth(),"Lab resource state leaked")
    assert(sx==ax and sy==ay and sw==aw and sh==ah and blend==ab and alpha==aa and x==tx and y==ty,"Lab clip/blend/transform leaked")
end
function T.update()
    if not started then
        if case==0 and not initialized then
            local cueCount=Sound.stats().cues
            assert(Sound.init() and Sound.stats().cues==cueCount,"audio reload must reuse catalog without procedural path entries")
            assert(not Sound.play("optional_missing_nen_cue"),"missing optional audio must be harmless")
            require("tests.nen_vfx_smoke")
            F.labAnim=nil
            F.labKeypressed("f6",UI);assert(F.labAnim,"F6 creates a ready preview")
            F.labOpen=true
            -- Exercise the actual developer controls, restoring a known preview afterwards.
            for _,key in ipairs({"n","right","left","q","b","l","l","t","v","m","m"}) do F.labKeypressed(key,UI) end
            F.labFilter=0;F.labTimeline=true;F.labAnchor=true
            initialized=true;warmUntil=benchmark and love.timer.getTime()+1 or nil
        end
        if warmUntil and love.timer.getTime()<warmUntil then return end
        warmUntil=nil
        case=case+1
        if case>variants*2 then
            F.drawLab=originalDraw;F.labOpen=false
            print("NEN native Lab: all "..variants.." variants / Normal+Fast / audio reload+missing cue / controls / Canvas, shader, scissor, blend and transform restoration passed")
            if benchmark then
                table.sort(intervals);local total=0;local over=0
                for _,v in ipairs(intervals) do total=total+v;if v>1000/60 then over=over+1 end end
                local report=string.format("Native HIGH Lab / all %d variants / Normal+Fast / no screenshots or encoding\n%d frames after 1s Lab startup and 120ms per-case warm-up / mean %.2fms / P95 %.2fms / P99 %.2fms / peak %.2fms\nframes over 16.67ms: %d / peak draw calls %d / peak particles %d\nFrame intervals include game/UI/audio on this host, not an isolated GPU timer or a hardware guarantee.\n",variants,#intervals,total/#intervals,intervals[math.ceil(#intervals*.95)],intervals[math.ceil(#intervals*.99)],intervals[#intervals],over,drawPeak,particlePeak)
                print(report);local file=assert(io.open("docs/nen_vfx/benchmark.txt","wb"));file:write(report);file:close()
                local out=assert(io.open("docs/nen_vfx/benchmark_spikes.txt","wb"))
                for _,spike in ipairs(spikes) do out:write(spike.."\n") end
                out:close()
            end
            love.event.quit(0);return
        end
        local index=math.floor(((case-1)%variants)/3)+1;local tier=(case-1)%3+1
        local id=order[index]
        for i,hand in ipairs(F.Attacks.config.labOrder) do if hand==id then F.labHand=i;break end end
        F.labFast=case>variants;F.labReduced=not benchmark and case>variants and case%3==0
        F.labBossSize=(case-1)%3+1
        R.setQuality((benchmark or case<=variants) and "HIGH" or ({"LOW","MEDIUM","HIGH"})[(case-1)%3+1])
        F.labKeypressed(tostring(tier),UI)
        local a=F.labAnim;local s=a.sequence
        for i,e in ipairs(s.events) do if e.kind=="PREPARE" then s.index=i;break end end
        a.displayChips,a.displayMult,a.displayAura=s.result.totalChips,s.result.totalMult,s.result.finalScore
        assert(s.attack.nen.tier==tier and s.attack.profile.id==id)
        started=love.timer.getTime()
    else
        local a=F.labAnim;local s=a.sequence;local e=s.events[s.index]
        assert(love.timer.getTime()-started<10,"Niệm Lab timeout")
        if benchmark and love.timer.getTime()-love.timer.getDelta()-started>.12 then
            local ms=love.timer.getDelta()*1000;intervals[#intervals+1]=ms
            if ms>1000/60 then spikes[#spikes+1]=string.format("%s / tier %d / %s / %s / %.2fms",s.attack.profile.id,s.attack.nen.tier,case>variants and "FAST" or "NORMAL",e and e.kind or "DONE",ms) end
        end
        if not benchmark and case<=variants and e and e.kind=="TRAVEL" and s.age>e.duration*.48 and not captured[case] then
            captured[case]=true
            love.graphics.captureScreenshot(function(data)
                local file=assert(io.open("docs/nen_vfx/lab/"..s.attack.profile.id.."_tier"..s.attack.nen.tier..".png","wb"))
                file:write(data:encode("png"):getString());file:close()
            end)
        end
        if F.isFinished(a) then
            assert(s.damageApplied and s.actualDamage==s.result.finalScore and s.attack.nen.releaseCount==1)
            print("NEN Lab "..s.attack.profile.id.." / tier "..s.attack.nen.tier.." / "..R.quality.." passed")
            started=nil
        end
    end
end
return T
