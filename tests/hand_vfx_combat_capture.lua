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
local outputDir=framesOnly and "docs/vfx_review/frames/" or "docs/vfx_review/"
local captured={}
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
    local function prohibit() error("GPU allocation during attack draw") end
    g.newCanvas,g.newShader,g.newImage=prohibit,prohibit,prohibit
    local ok,err=pcall(originalDraw,...)
    g.newCanvas,g.newShader,g.newImage=canvas,shader,image
    assert(ok,err)
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
        if case>#order*repeats then
            F.Attacks.draw=originalDraw
            print("All "..#order.." real combat attack profiles / "..repeats.." consecutive repeats each / HP / input / quality / shaders / zero draw GPU allocations passed")
            love.event.quit(0);return
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(case%2==0)
        R.setQuality(framesOnly and "HIGH" or ({"LOW","MEDIUM","HIGH"})[repeats>1 and ((case-1)%repeats+2)%3+1 or (case-1)%3+1])
        game.maxHandSize=5;game.unlockedHands={}
        for _,id in ipairs(F.Attacks.config.order) do game.unlockedHands[id]=true end
        game.hand,game.deck,game.discardPile,game.selectedIndices={},{},{},{}
        local handIndex=math.floor((case-1)/repeats)+1
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
        if allHands then
            -- Accelerate score bookkeeping only; all VFX phases keep their Normal/Fast timing.
            for _,e in ipairs(anim.sequence.events) do
                if not ({ENERGY_CONVERSION=true,ANTICIPATION=true,CONVERGENCE=true,ATTACK=true,ENEMY_IMPACT=true,SETTLE=true})[e.kind] then e.duration=e.duration*.12 end
            end
        end
        lastHp=game.monster.hp;hits=0;started=love.timer.getTime()
        local hands=game.handsRemaining;cb.playSelectedHand();assert(game.handsRemaining==hands)
    else
        local a,state=cb.getScoringState();local s=a.sequence
        if not s.impactDispatched then assert(game.monster.hp==10000000) end
        if game.monster.hp~=lastHp then hits=hits+1;lastHp=game.monster.hp end
        assert(love.timer.getTime()-started<25)
        if (repeats>1 or framesOnly) and (case-1)%repeats==0 then
            local e=s.events[s.index]
            if e and (e.kind=="ANTICIPATION" or e.kind=="ATTACK") and s.age>e.duration*.45 then shot(s.attack.profile.id,e.kind:lower()) end
            if s.impactDispatched and s.cameraAge>0.025 and s.cameraAge<0.07 then shot(s.attack.profile.id,"impact") end
            if s.impactDispatched and s.cameraAge>.11 and s.cameraAge<.18 then shot(s.attack.profile.id,"after_contact") end
        end
        if #s.attack.wave>0 then assert(#s.attack.wave==50,"shockwave contains stale slash vertices") end
        if #s.attack.ribbon>0 then assert(#s.attack.ribbon==64,"invalid tapered blade contour") end
        if state~="scoring" then
            assert(s.finished and s.damageApplied and hits==1 and a.damageDealt==expected)
            assert(game.monster.hp==10000000-expected-(s.attack.profile.id=="tesla_369" and 18 or 0))
            if s.attack.profile.advanced then assert(game.advancedHand.resolved,"advanced gameplay bonus must resolve once") end
            assert(#R.post.diagnostics==0,"world shader compilation fallback")
            print("Real combat "..s.attack.profile.id.." / "..R.quality.." passed")
            started=nil
        end
    end
end
return T
