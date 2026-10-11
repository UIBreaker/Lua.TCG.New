local F = require("src.combat_feedback")
for tier,value in ipairs({25,250,2500,25000,250000}) do
    assert(F.tier(value)==tier)
    local ft = F.new("damage",value,640,214,tostring)
    local label=({false,"CỰC MẠNH","BÙNG NỔ","SIÊU VIỆT","TUYỆT ĐỈNH"})[tier]
    assert(ft.tier==tier and (not label and not ft.label or ft.label==label.." · "..ft.power.name))
    F.update(ft,0.12)
    assert(ft.alpha==1 and ft.life>0)
    assert(F.update(ft,3) and ft.alpha==0)
end
assert(F.tier(99)==1 and F.tier(100)==2 and F.tier(999)==2 and F.tier(1000)==3)
assert(F.tier(9999)==3 and F.tier(10000)==4 and F.tier(100000)==5 and F.tier(1e15)==5)
local previous
for degree=0,30 do
    local amount=tonumber("1e"..degree)
    assert(F.magnitude(amount)==degree and F.magnitude(-amount)==degree,"every decimal boundary has its own magnitude")
    if degree>0 then assert(F.magnitude(amount*(1-1e-12))==degree-1,"values below a boundary must stay in the lower magnitude") end
    local power=F.damageProfile(amount)
    assert(power.degree==degree and power.name and power.scale<1.5 and power.duration<2.5)
    assert(power.bolts<=20 and power.embers<=30 and power.branches<=3 and power.reach<69)
    if previous then
        assert(power.scale>previous.scale and power.glow>previous.glow,"every decade must look stronger, including normal and beyond billions")
        if degree>=3 then assert(power.reach>previous.reach and power.embers>=previous.embers) end
        if degree>=6 then assert(power.stroke>previous.stroke and power.foil>=previous.foil and power.speed>previous.speed) end
    end
    previous=power
end
assert(F.magnitude(0)==0 and F.magnitude(9)==0 and F.magnitude(99)==1)
assert(select(2,F.magnitude(1e9))=="TỈ" and select(2,F.magnitude(1e11))=="TRĂM TỈ")
assert(F.magnitude(1e308)==308 and F.damageProfile(1e308).bolts<=20)
local signatures={}
local Touch=require("src.touch_input")
local lowPower=Touch.lowPower
for degree=0,308 do
    local amount=tonumber("1e"..degree)
    local desktop,mobile=F.damageProfile(amount),F.damageProfile(amount,true)
    local key=table.concat(desktop.accent,",")..":"..desktop.signature
    assert(not signatures[key],"every representable decimal order has a distinct visual signature")
    signatures[key]=true
    assert(mobile.signature==desktop.signature and mobile.tier==desktop.tier and mobile.name==desktop.name)
    for i=1,3 do assert(mobile.accent[i]==desktop.accent[i]) end
    assert(mobile.reach==desktop.reach and mobile.foil==desktop.foil and mobile.corona==desktop.corona,
        "mobile must preserve flame, holographic strength and magnitude identity")
    assert(mobile.bolts<=12 and mobile.branches<=2 and mobile.embers<=18)
    assert((desktop.bolts==0)==(mobile.bolts==0),"mobile must retain lightning at every electric magnitude")
    Touch.lowPower=true
    assert(F.new("damage",amount,640,214).power.mobile,"APK/phone runtime must select the mobile drawing budget")
end
Touch.lowPower=lowPower
local list={}
F.add(list,"damage",50,640,214)
F.add(list,"damage",50,640,214)
assert(list[1].x~=list[2].x and list[1].y~=list[2].y)
for i=1,100 do F.add(list,"gold",i,475,96) end
assert(#list==24)
assert(F.new("gold",-20,0,0).text=="−20 VÀNG")
assert(F.new("armor",-12,0,0).text=="−12 GIÁP")
assert(F.new("gold",3,0,0).rewardLevel==1 and F.new("gold",120,0,0).rewardLevel==4)
local rng=require("src.rng");local before=rng.getState()
for _,fps in ipairs({30,60,120,144}) do
    local meter=F.updateMeter(nil,100,0)
    meter=F.updateMeter(meter,40,1/fps)
    assert(meter.value==40 and meter.shown>40 and meter.trail==100,"damage has a visible delayed trail")
    for _=1,fps do
        meter=F.updateMeter(meter,40,1/fps)
        assert(meter.shown>=40 and meter.shown<=100 and meter.trail>=meter.shown-1e-9)
    end
    assert(meter.shown==40 and meter.trail==40)
    meter=F.updateMeter(meter,90,1/fps,0.58)
    assert(meter.shown>40 and meter.shown<90 and meter.trail==meter.shown)
    -- New gains/spends can arrive while a previous count is still moving.
    for _,amount in ipairs({5,120,0,12,0}) do
        meter=F.updateMeter(meter,amount,1/fps,0.58)
        assert(meter.shown>=0 and meter.shown<=120)
    end
    meter=F.updateMeter(meter,0,2,0.58)
    assert(meter.shown==0 and meter.trail==0,"armor depletion and interrupted counts settle exactly")
end
assert(rng.getState()==before,"feedback must not consume gameplay RNG")
local burst={}
for i=1,100 do
    local hit=F.add(burst,"damage",i*1000,630,214)
    assert(#burst<=3 and hit.y<=342 and not hit.crowded,"bursts stay on three bounded lanes with a bright newest hit")
    local lanes={}
    for _,ft in ipairs(burst) do
        assert(not lanes[ft.lane],"a target cannot have two values on the same lane")
        lanes[ft.lane]=true
    end
end
for _,x in ipairs({454,806}) do for i=1,3 do F.add(burst,"damage",250,x,214) end end
assert(#burst==9,"separate enemies keep separate damage lanes")
for _,fps in ipairs({30,60,120,144}) do
    for _,amount in ipairs({1,25,250,2500,25000,250000,1e9,1e15,1e30,1e308}) do
        local ft=F.new("damage",amount,630,214)
        for _=1,math.floor(fps*2.5) do
            F.update(ft,1/fps)
            local sx,sy,tilt,rise=F.damagePose(ft)
            assert(sx>0 and sx<1.6 and sx==sy and tilt==0 and rise<41,"digits keep their proportions and bounded size/rise")
        end
        assert(ft.alpha==0)
    end
end
assert(F.new("damage",1e9,0,0).label=="TUYỆT ĐỈNH · TỈ" and F.new("damage",1e15,0,0).label=="TUYỆT ĐỈNH · TRIỆU TỈ")
for _,amount in ipairs({25000,250000,1e9,1e15,1e30,1e308}) do
    local reference
    for _,fps in ipairs({30,60,120,144}) do
        local ft=F.new("damage",amount,630,214)
        local paths=F.lightningGeometry(ft,150,36)
        local first=paths[1].points
        assert(F.lightningGeometry(ft,150,36)==paths,"stable strike must reuse geometry")
        local left,right,top,bottom=0,0,18,18
        for _=1,fps do
            F.update(ft,1/fps)
            assert(F.lightningGeometry(ft,150,36)==paths and paths[1].points==first,"strike changes must not grow geometry buffers")
            for _,path in ipairs(paths) do
                assert(#paths==ft.power.bolts and #path.points<=32 and #path.branches==ft.power.branches)
                for _,branch in ipairs(path.branches) do
                    assert(#branch==10)
                    for i=1,#branch,2 do assert(math.abs(branch[i])<145 and branch[i+1]>-90 and branch[i+1]<126) end
                end
                for i=1,#path.points,2 do
                    local x,y=path.points[i],path.points[i+1]
                    assert(math.abs(x)<125 and y>-60 and y<96,"lightning stays close to its number")
                    left,right,top,bottom=math.min(left,x),math.max(right,x),math.min(top,y),math.max(bottom,y)
                end
            end
        end
        assert(left<-75 and right>75 and top<0 and bottom>36,"arcs must wrap every side of the number")
        if reference then assert(paths[1].points[1]==reference,"strike shape must follow elapsed time across FPS") end
        reference=paths[1].points[1]
        ft.reducedMotion=true
        F.lightningGeometry(ft,150,36)
        local still=paths[1].points[1]
        ft.age=1.7;F.lightningGeometry(ft,150,36)
        assert(paths[1].points[1]==still,"reduced motion keeps lightning static")
    end
end
local Feel=require("src.scoring_presentation")
for _,x in ipairs({454,630,806}) do
    for _,tier in ipairs({1,2,3}) do
        for _,amount in ipairs({77,2500,1e15}) do
            local anim={floatingTexts={},sequence={attack={cx=x,profile={id="high_card"},nen={tier=tier,reducedMotion=true}},
                ui={BATTLE_CENTER_X=630,formatNumber=tostring}}}
            Feel.damageApplied(anim,0,amount)
            Feel.damageApplied(anim,0,amount)
            assert(#anim.floatingTexts==1,"resolved damage is emitted once")
            local ft=anim.floatingTexts[1]
            assert(ft.tier==F.tier(amount) and ft.x==x and ft.originX==x,"Nen intensity cannot inflate or displace damage numbers")
            assert(ft.quietImpact and ft.reducedMotion and ft.text=="−"..tostring(amount))
            local sx,sy,tilt,rise=F.damagePose(ft)
            assert(sx==sy and tilt==0 and rise<=8)
        end
    end
end
assert(rng.getState()==before,"impact motion and bursts must not consume gameplay RNG")
print("Damage impact PASS: proportional rebound through 1e15 at 30/60/120/144 FPS, bounded burst lanes, actual damage tiers independent of all Nen tiers/target positions and reduced motion")
print("Combat feedback PASS: distinct decimal magnitudes through 1e30, boundaries through 1e308, escalating fire/lightning/foil with bounded geometry, resource trails, exact settle, bounded queue, no gameplay RNG")
