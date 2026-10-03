local UI=require("src.ui")
local F=UI.ScoringFeel
local T={}
local index,tier,fast=1,1,false
local started,frames,total,peak=0,0,0,0
local shots={}
local samples={}
local overBudget=0
local limit=tonumber((arg or {})[#(arg or {})]) or 9
local function start()
    F.labOpen=true;F.labHand=index;F.labFast=fast
    F.labKeypressed(tostring(tier),UI)
    local a=F.labAnim
    -- Exercise conversion through settle immediately; calculator is covered by real scoring test.
    for i,e in ipairs(a.sequence.events) do if e.kind=="ENERGY_CONVERSION" then a.sequence.index=i;break end end
    a.displayAura=a.sequence.result.finalScore
    started=love.timer.getTime()
end
function T.update()
    if started==0 then start();return end
    local a=F.labAnim;local s=a.sequence;local e=s.events[s.index]
    if e and e.kind=="ATTACK" and s.age>e.duration*0.4 and tier==5 and not fast and not shots[index] then
        shots[index]=true
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/hand_vfx/shot_hand_vfx_"..index..".png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    end
    local dt=love.timer.getDelta()
    if love.timer.getTime()-started>0.12 then samples[#samples+1]=dt;if dt>1/60 then overBudget=overBudget+1 end end
    frames=frames+1;total=total+dt;peak=math.max(peak,dt)
    assert(love.timer.getTime()-started<5,"Attack Lab timeout")
    if not F.isFinished(a) then return end
    assert(s.damageApplied and s.actualDamage==s.result.finalScore)
    assert(s.attack.tier==tier)
    assert(math.abs(s.hpTrail-s.hpTarget)<0.001,"HP trail must settle")
    print(string.format("Hand VFX %s / %s / %s passed",s.attack.profile.id,F.Attacks.config.tierNames[tier],fast and "FAST" or "NORMAL"))
    tier=tier+1
    if tier>5 then tier=1;index=index+1 end
    if index>limit then
        if not fast then fast=true;index=1
        else
            print(string.format("VFX Lab complete: %d cases, mean %.2fms, peak %.2fms, %d frames",limit*10,total/frames*1000,peak*1000,frames))
            table.sort(samples)
            print(string.format("After 120ms warm-up per case: P95 %.2fms, P99 %.2fms, >16.67ms %d/%d",samples[math.ceil(#samples*0.95)]*1000,samples[math.ceil(#samples*0.99)]*1000,overBudget,#samples))
            love.event.quit(0);return
        end
    end
    start()
end
return T
