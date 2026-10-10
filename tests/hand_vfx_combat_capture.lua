local UI=require("src.ui")
local F=UI.ScoringFeel
local D=require("src.deck")
local R=require("render.renderer")
local T={}
local case,started,lastHp,hits,expected=0,nil,0,0,0
local repeats=1
for _,value in ipairs(arg or {}) do if value=="--vfx-review" then repeats=10 end end
local framesOnly=false
for _,value in ipairs(arg or {}) do if value=="--vfx-frame-review" then framesOnly=true end end
local allHands=false
for _,value in ipairs(arg or {}) do if value=="--all-hand-vfx" then allHands=true end end
local order={};for _,id in ipairs(F.Attacks.config.order) do order[#order+1]=id end
if allHands then for _,h in ipairs(require("src.advanced_hands").ordered) do order[#order+1]=h.id end end
local nenSamples=false
local nenBasics,nenAll,nenPolish=false,false,false
for _,value in ipairs(arg or {}) do if value=="--nen-samples" then nenSamples=true;repeats=10 end end
for _,value in ipairs(arg or {}) do
    if value=="--nen-basics" then nenBasics=true end
    if value=="--nen-all" then nenAll=true;repeats=3 end
    if value=="--nen-polish" then nenPolish=true end
end
if nenSamples then order=require("config.nen_vfx_config").samples end
if nenAll then order=require("config.nen_vfx_config").order end
if nenPolish then order={"high_card","straight","four_of_a_kind","even_frost","obsidian_tide","tesla_369","eclipse_duality","destiny_crown","sealed_gate","prime"} end
local nenMode=nenSamples or nenBasics or nenAll or nenPolish
local tierCount=nenMode and 3 or 1
local outputDir=framesOnly and "docs/vfx_review/frames/" or "docs/vfx_review/"
if nenSamples then outputDir="docs/nen_vfx/checkpoint2/final/" end
if nenBasics then outputDir="docs/nen_vfx/checkpoint3/" end
if nenAll then outputDir="docs/nen_vfx/final/" end
if nenPolish then outputDir="docs/nen_vfx/final/" end
local captured={}
local frameSamples,drawPeak,particlePeak={},0,0
local function performance()
    if #frameSamples==0 then return end
    table.sort(frameSamples)
    local total=0;for _,ms in ipairs(frameSamples) do total=total+ms end
    local report=string.format("NEN real combat frame intervals (capture/encoding included, first 150ms per attack omitted)\nframes %d / mean %.2fms / P95 %.2fms / P99 %.2fms / peak %.2fms\npeak draw calls %d / peak Niệm particles %d\nNot an isolated GPU timer or a guarantee on other hardware.\n",#frameSamples,total/#frameSamples,frameSamples[math.ceil(#frameSamples*.95)],frameSamples[math.ceil(#frameSamples*.99)],frameSamples[#frameSamples],drawPeak,particlePeak)
    print(report)
    local file=assert(io.open(outputDir.."performance.txt","wb"));file:write(report);file:close()
end
local function shot(id,phase)
    local key=id.."_"..phase
    if captured[key] then return end;captured[key]=true
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(outputDir..key..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
local originalDraw=F.Attacks.draw
F.Attacks.draw=function(...)
    local g=love.graphics;local canvas,shader,image=g.newCanvas,g.newShader,g.newImage
    local beforeShader,beforeCanvas,beforeWidth=g.getShader(),g.getCanvas(),g.getLineWidth()
    local sx,sy,sw,sh=g.getScissor();local blend,alpha=g.getBlendMode()
    local effect=require("render.nen_effects");local material=effect.shader
    if nenMode and (nenSamples and case%10==9 or nenAll and case%3==2 or nenPolish and case%3==2) then effect.shader=nil end
    local function prohibit() error("GPU allocation during attack draw") end
    g.newCanvas,g.newShader,g.newImage=prohibit,prohibit,prohibit
    local ok,err=pcall(originalDraw,...)
    g.newCanvas,g.newShader,g.newImage=canvas,shader,image
    effect.shader=material
    assert(ok,err)
    local ax,ay,aw,ah=g.getScissor();local afterBlend,afterAlpha=g.getBlendMode()
    assert(beforeShader==g.getShader() and beforeCanvas==g.getCanvas() and beforeWidth==g.getLineWidth(),"Niệm graphics state leak")
    assert(sx==ax and sy==ay and sw==aw and sh==ah and blend==afterBlend and alpha==afterAlpha,"Niệm clip/blend leak")
    if nenMode then drawPeak=math.max(drawPeak,g.getStats().drawcalls or 0) end
end
local basic={{14},{8,8},{8,8,11,11},{8,8,8},{7,8,9,10,11},{2,5,8,11,14},{8,8,8,11,11},{8,8,8,8},{10,11,12,13,14}}
local presets={}
for i,id in ipairs(F.Attacks.config.order) do presets[id]=basic[i] end
local advanced={tesla_369={3,6,9,2,4},jackpot_777={7,7,7,2,4},fibonacci={14,2,3,5,8},prime={2,3,5,7,11},odd_star={14,3,5,7,9},even_frost={2,4,6,8,10},crimson_tide={3,5,7,9,11},obsidian_tide={3,5,7,9,11},eclipse_duality={2,4,9,4,2},four_kingdom_prism={2,4,6,9,13},four_kingdom_expedition={14,2,4,6,13},destiny_crown={10,11,12,13,14},continental_gate={14,14,14,14,13},answer_42={4,6,9,10,13},sealed_gate={14,14,14,13,13},seven_stars={7,7,7,14,13},five_ley_lines={14,4,8,10,13},endless_cycle={2,3,4,5,6}}
for id,ranks in pairs(advanced) do presets[id]=ranks end
local suitSets={tesla_369={"hearts","hearts","hearts","clubs","spades"},crimson_tide={"hearts","diamonds","hearts","diamonds","hearts"},obsidian_tide={"spades","clubs","spades","clubs","spades"},eclipse_duality={"hearts","diamonds","hearts","clubs","spades"}}
function T.update(game,cb)
    if not started then
        if case==0 then require("tests.hd2d_smoke") end
        case=case+1
        if case>#order*repeats*tierCount then
            F.Attacks.draw=originalDraw
            if nenMode then performance() end
            print("All "..#order.." real combat attack profiles / "..tierCount.." tiers / "..repeats.." consecutive repeats each / HP / input / quality / shaders / zero draw GPU allocations passed")
            love.event.quit(0);return
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(case%2==0)
        R.setQuality(nenAll and ({"HIGH","MEDIUM","LOW"})[(case-1)%3+1] or (nenBasics or nenPolish or framesOnly) and "HIGH" or ({"LOW","MEDIUM","HIGH"})[repeats>1 and ((case-1)%repeats+2)%3+1 or (case-1)%3+1])
        game.maxHandSize=5;game.unlockedHands={}
        for _,id in ipairs(F.Attacks.config.order) do game.unlockedHands[id]=true end
        game.hand,game.deck,game.discardPile,game.selectedIndices={},{},{},{}
        local handIndex=math.floor((case-1)/(repeats*tierCount))+1
        local nenTier=math.floor((case-1)/repeats)%tierCount+1
        local id=order[handIndex]
        local isAdvanced=F.Attacks.config.hands[id].advanced
        if isAdvanced then game.unlockedHands={high_card=true,[id]=true} end
        local suits=suitSets[id] or {"hearts","clubs","spades","diamonds","hearts"}
        for i,rank in ipairs(presets[id]) do
            local suit=isAdvanced and suits[i] or ((id=="flush" or id=="straight_flush") and "spades" or ({"spades","hearts","clubs","diamonds"})[(i-1)%4+1])
            game.hand[i]=D.newCard(rank,suit);game.hand[i].disableFactionPassives=true
        end
        game.monster.hp,game.monster.maxHp,game.monster.damageLagHp=10000000,10000000,10000000
        game.monster.creatureArmor=0;game.monster.targetAura=1;game.monster.attackSpeed=1;game.deities={}
        for i=1,#game.hand do cb.selectCardIndex(i) end
        game.abilityApproved={} -- Default decisions in isolated capture; no interactive prompt.
        cb.playSelectedHand()
        local anim,state=cb.getScoringState()
        assert(state=="scoring" and anim.sequence.attack.profile.id==id, "case "..case.." state "..state.." profile "..tostring(anim.sequence and anim.sequence.attack.profile.id))
        expected=anim.scoringData.finalScore
        if nenMode then
            game.monster.targetAura=expected/({.25,1,2.5})[nenTier]
            F.start(anim,anim.scoringData,UI,{},game.monster.hp,game.monster,id,{lab=true,reducedMotion=nenSamples and case%10==0 or nenAll and case%3==0})
            assert(anim.sequence.attack.nen and anim.sequence.attack.nen.tier==nenTier)
            assert(#require("render.nen_effects").diagnostics==0,"Niệm material shader fallback")
            for _,cue in ipairs({"charge","release","beat","impact"}) do assert(require("src.sound").has("nen_"..id.."_"..cue),"missing Niệm audio") end
        end
        if allHands or nenMode then
            -- Accelerate score bookkeeping only; all VFX phases keep their Normal/Fast timing.
            for _,e in ipairs(anim.sequence.events) do
                local ultimate={ENERGY_CONVERSION=true,ANTICIPATION=true,CONVERGENCE=true,ATTACK=true,ENEMY_IMPACT=true,SETTLE=true}
                for _,stage in ipairs(require("config.nen_vfx_config").stages) do ultimate[stage]=true end
                if not ultimate[e.kind] then e.duration=e.duration*.12 end
            end
        end
        lastHp=game.monster.hp;hits=0;started=love.timer.getTime()
        local hands=game.handsRemaining;cb.playSelectedHand();assert(game.handsRemaining==hands)
    else
        local a,state=cb.getScoringState();local s=a.sequence
        if nenMode and love.timer.getTime()-started>.15 then
            frameSamples[#frameSamples+1]=love.timer.getDelta()*1000
            particlePeak=math.max(particlePeak,s.attack.nen.particleCount)
        end
        if not s.impactDispatched then assert(game.monster.hp==10000000) end
        if game.monster.hp~=lastHp then hits=hits+1;lastHp=game.monster.hp end
        assert(love.timer.getTime()-started<25)
        if (repeats>1 or framesOnly or nenMode) and (case-1)%repeats==0 then
            local e=s.events[s.index]
            local id=s.attack.profile.id..(nenMode and "_tier"..s.attack.nen.tier or "")
            local charge=s.attack.nen and "CHARGE" or "ANTICIPATION"
            local travel=s.attack.nen and "TRAVEL" or "ATTACK"
            if e and (e.kind==charge or e.kind==travel) and s.age>e.duration*.45 then shot(id,e.kind==charge and "anticipation" or "attack") end
            if s.impactDispatched and s.cameraAge>0.025 and s.cameraAge<0.07 then shot(id,"impact") end
            if s.impactDispatched and s.cameraAge>.11 and s.cameraAge<.18 then shot(id,"after_contact") end
        end
        if #s.attack.wave>0 then assert(#s.attack.wave==50,"shockwave contains stale slash vertices") end
        if #s.attack.ribbon>0 then assert(#s.attack.ribbon==64,"invalid tapered blade contour") end
        if state~="scoring" then
            assert(s.finished and s.damageApplied and hits==1 and a.damageDealt==expected)
            if nenMode then
                assert(s.attack.nen.releaseCount==1,"ultimate restarted by scoring triggers")
                local x,y=F.camera(a);assert(math.abs(x)+math.abs(y)<.001,"Niệm camera did not settle")
            end
            assert(game.monster.hp==10000000-expected-(s.attack.profile.id=="tesla_369" and 18 or 0))
            if s.attack.profile.advanced then assert(game.advancedHand.resolved,"advanced gameplay bonus must resolve once") end
            assert(#R.post.diagnostics==0,"world shader compilation fallback")
            print("Real combat "..s.attack.profile.id.." / "..R.quality.." passed")
            started=nil
        end
    end
end
return T
