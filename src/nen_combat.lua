-- The scoring timeline owns contact. This director reads a frozen visual snapshot.
local N={config=require("config.nen_vfx_config"),reducedMotion=false}
local C=N.config
local clamp=function(p) return math.max(0,math.min(1,p)) end
local smooth=function(p) p=clamp(p);return p*p*(3-2*p) end
local mix=function(a,b,p) return a+(b-a)*p end
local function positive(v) return type(v)=="number" and v==v and v>0 and v<math.huge and v or nil end
function N.reference(enemy,context)
    if positive(enemy and enemy.targetAura) then return enemy.targetAura end
    local total=0
    for _,m in ipairs(context and context.enemies or enemy and {enemy} or {}) do
        total=total+(positive(m.maxHp) or positive(m.hp) or 0)+math.max(0,tonumber(m.creatureArmor) or 0)
    end
    return total>0 and math.max(1,total/C.power.encounterHands) or C.power.fallbackReference
end
function N.power(aura,reference)
    reference=positive(reference) or C.power.fallbackReference
    aura=positive(aura) or 0
    local ratio=math.min(C.power.maxRatio,aura/reference)
    local tier=ratio>=C.power.extreme and 3 or ratio>=C.power.strong and 2 or 1
    return tier,ratio,clamp(math.log(1+ratio)/math.log(1+C.power.extreme*2))
end
function N.attach(a,result,enemy,context)
    local p=C.hands[a.profile.id]
    if not p or not p.ready or #a.sources==0 then return end
    local ref=N.reference(enemy,context)
    local tier,ratio,intensity=N.power(result.finalScore,ref)
    local snapshot={aura=result.finalScore,reference=ref,handId=p.id,cards={},targetX=a.cx,targetY=270,
        stage=enemy and enemy.stage or 1,dead=enemy and (enemy.hp or 1)<=0 or false}
    for i,s in ipairs(a.sources) do
        snapshot.cards[i]={id=s.card.id,sourceIndex=i,rank=s.card.rank,suit=s.card.suit,x=s.x,y=s.y,order=s.order}
    end
    a.nen={profile=p,tier=tier,variant=p.tiers[tier],ratio=ratio,intensity=intensity,snapshot=snapshot,
        reducedMotion=context and context.reducedMotion==true or N.reducedMotion,charge=0,travel=0,
        points={},launch={},screenCenter={0,0},particleCount=0,beat=0,releaseCount=0,stage="PREPARE",phaseProgress=0,
        speed=1+math.min(C.repeatAcceleration.max,(context and context.streak or 0)*C.repeatAcceleration.step)}
    a.intensity=intensity
    local active={}
    if p.id=="tesla_369" then
        -- Resolver already confirmed the hand; this only assigns roles to the 3/6/9 cards.
        for _,rank in ipairs({3,6,9}) do for i,c in ipairs(snapshot.cards) do if c.rank==rank then active[#active+1]=i;break end end end
    else for i in ipairs(snapshot.cards) do active[#active+1]=i end end
    a.nen.roles=active
    if #active==0 then a.nen=nil;return end
    return a.nen
end
function N.timeline(a,append,q)
    for i,stage in ipairs(C.stages) do append(q,stage,C.timing[a.nen.tier][i]/a.nen.speed) end
end
function N.enter(a,phase)
    local n=a.nen;n.stage=phase;n.phaseProgress=0
    if phase=="PREPARE" then n.charge,n.travel,n.beat=0,0,0 end
    local sound=require("src.sound")
    if phase=="NEN_AWAKENING" then sound.play("nen_"..a.profile.id.."_charge",1.03-(n.tier-1)*.055) end
    if phase=="RELEASE" then
        n.charge=1;n.releaseCount=n.releaseCount+1
        for i=1,N.count(a) do local x,y=N.position(a,i,"CHARGE",1);n.launch[i]={x=x,y=y} end
        sound.play("nen_"..a.profile.id.."_release",1.07-(n.tier-1)*.085)
    end
    if phase=="CHARGE" and n.tier==3 and not n.reducedMotion then sound.silence(.035) end
    if phase=="ENEMY_IMPACT" then sound.play("nen_"..a.profile.id.."_impact",1.05-(n.tier-1)*.11) end
end
function N.update(a,phase,p)
    local n=a.nen;n.stage=phase;n.phaseProgress=p
    if phase=="PREPARE" then n.charge=p*.08
    elseif phase=="ANTICIPATION" then n.charge=.08+p*.12
    elseif phase=="NEN_AWAKENING" then n.charge=.20+p*.18
    elseif phase=="CARD_TRANSFORMATION" then n.charge=.38+p*.42
    elseif phase=="CHARGE" then n.charge=.8+p*.2
    elseif phase=="RELEASE" then n.charge=1
    elseif phase=="TRAVEL" then
        n.travel=p
        local beats=N.count(a)
        local count=math.min(beats,math.floor(p*beats*.9)+1)
        while n.beat<count do n.beat=n.beat+1;require("src.sound").play("nen_"..a.profile.id.."_beat",.88+n.beat*.06) end
    end
end
function N.count(a)
    local id=a.profile.id;local n=a.nen
    if id=="high_card" or id=="eclipse_duality" then return 1 end
    if id=="pair" then return 2 end
    if id=="tesla_369" then return 3 end
    if id=="even_frost" and n.tier>=2 then return 1 end
    if id=="flush" and n.tier>=2 then return 1 end
    if id=="full_house" then return n.tier==1 and 1 or n.tier==2 and 2 or 5 end
    if id=="straight_flush" then return n.tier==2 and 5 or 1 end
    if id=="jackpot_777" then return 3 end
    if id=="odd_star" then return 9 end
    if id=="crimson_tide" then return n.tier end
    if id=="obsidian_tide" then return n.tier==1 and 5 or n.tier==2 and 2 or 1 end
    if id=="four_kingdom_prism" then return n.tier==2 and 4 or 1 end
    if id=="four_kingdom_expedition" then return 4 end
    if id=="destiny_crown" then return n.tier==2 and 5 or 1 end
    if id=="continental_gate" then return 1 end
    if id=="sealed_gate" then return n.tier==2 and 3 or 1 end
    if id=="seven_stars" then return 7 end
    if id=="endless_cycle" then return n.tier==2 and 2 or 1 end
    return #n.snapshot.cards
end
local function source(a,i)
    local n=a.nen;local role=n.roles[(i-1)%#n.roles+1]
    if a.profile.id=="high_card" then role=a.strongest end
    if a.profile.id=="straight" then role=a.rankOrder[i] end
    return n.snapshot.cards[role]
end
function N.position(a,i,phase,p)
    local n=a.nen;local id=a.profile.id;local tier=n.tier;local cx,cy=n.snapshot.targetX,n.snapshot.targetY
    local c=source(a,i);local x0,y0,x1,y1=cx,385,cx,cy
    local curve,delay=0,0
    if id=="high_card" then x0,y0=c.x-(tier==3 and 155 or tier==2 and 108 or 0),tier>=2 and 425 or 392;curve=tier==1 and 0 or -38
    elseif id=="pair" then
        local side=i==1 and -1 or 1
        x0,y0=cx+side*(tier==3 and 180 or 145),tier==3 and 325 or 360
        x1=cx-side*23;curve=side*(tier==3 and 138 or tier==2 and 92 or 42)
        delay=tier==2 and (i-1)*.22 or 0
    elseif id=="even_frost" then
        if tier==1 then x0,y0=c.x,385;x1=cx+(i-3)*8;curve=(i-3)*18;delay=(i-1)*.08
        else x0,y0=cx-125,365;curve=-30 end
    elseif id=="tesla_369" then x0,y0=c.x,355;delay=(i-1)*(tier==1 and .23 or .17);curve=(i-2)*70
    elseif id=="straight" then x0,y0=c.x,405;curve=math.sin(i*1.7)*(tier>=2 and 56 or 18);delay=(i-1)*.11
    elseif id=="eclipse_duality" then x0,y0=cx,365;curve=tier==1 and 20 or 0 end
    if id=="two_pair" then
        local side=i<=2 and -1 or 1;local lane=(i-1)%2*26
        x0,y0=cx+side*(tier==3 and 205 or 165)+lane, tier==1 and 395 or 335+lane
        x1=cx-side*8;curve=side*(tier==1 and 30 or 140);delay=(side>0 and .18 or 0)+lane*.002
    elseif id=="three_of_a_kind" then
        local angle=(i-1)*math.pi*2/3-math.pi/2
        x0,y0=tier==1 and c.x or cx+math.cos(angle)*105,tier==1 and 398 or 320+math.sin(angle)*70
        curve=tier==1 and 0 or math.cos(angle)*(tier==3 and 100 or 60);delay=tier==1 and (i-1)*.22 or 0
    elseif id=="flush" then x0,y0=tier==1 and c.x or cx-(tier==3 and 125 or 0),425;curve=math.sin(i*2)*35
    elseif id=="full_house" then x0,y0=cx-130+(i-(N.count(a)+1)/2)*38,395;curve=(i%2==0 and -1 or 1)*20;delay=(i-1)*.10
    elseif id=="four_of_a_kind" then local t=(i-1)*math.pi/2+.785;x0,y0=cx+math.cos(t)*125,315+math.sin(t)*80;delay=tier>=2 and (i-1)*.16 or 0
    elseif id=="straight_flush" then x0,y0=n.tier==2 and c.x or cx,410;curve=tier==2 and (i-3)*26 or 0 end
    if id=="jackpot_777" then
        local t=(i-1)*math.pi*2/3-math.pi/2
        x0,y0=cx-125+math.cos(t)*65,350+math.sin(t)*48;curve=tier==3 and math.sin(i*2)*110 or (i-2)*25;delay=(i-1)*.15
    elseif id=="fibonacci" then
        local t=i*2.399;local r=math.sqrt(i)*31
        x0,y0=cx-120+math.cos(t)*r,350+math.sin(t)*r*.6;curve=math.sin(t)*(35+tier*24);delay=tier==2 and (i-1)*.13 or 0
    elseif id=="prime" then
        local t=(i-1)*math.pi*2/5-.9
        x0,y0=cx+math.cos(t)*(tier==1 and 100 or 155),310+math.sin(t)*70;curve=math.sin(i*3)*(tier==2 and 120 or 32);delay=tier==1 and (i-1)*.12 or tier==3 and .35 or 0
    elseif id=="odd_star" then
        local t=(i-1)*math.pi*2/9
        x0,y0=cx-125+math.cos(t)*(tier==1 and 25 or 61),350+math.sin(t)*(tier==1 and 18 or 45)
        curve=math.sin(t)*(tier==3 and 100 or 25);delay=tier>=2 and (i-1)*.055 or 0
    elseif id=="crimson_tide" then
        local side=i%2==0 and 1 or -1
        x0,y0=cx+side*(tier==3 and 185 or 130),405-(i-1)*20;curve=side*(tier==1 and 40 or 150);delay=(i-1)*.12
    elseif id=="obsidian_tide" then
        x0,y0=tier==1 and c.x or cx+(i%2==0 and 140 or -140),390
        curve=tier==3 and -90 or (i%2==0 and 45 or -45);delay=(i-1)*.13
    elseif id=="four_kingdom_prism" then
        x0,y0=cx-115+(i-1)*38,355;curve=tier==2 and math.sin(i*math.pi/2)*120 or 0;delay=tier==2 and (i-1)*.08 or 0
    elseif id=="four_kingdom_expedition" then
        local side=i%2==0 and 1 or -1;x0,y0=cx+side*185,300+math.floor((i-1)/2)*92
        curve=side*(tier==3 and 105 or 35);delay=(i-1)*.12
    elseif id=="destiny_crown" then x0,y0=cx+130+(i-3)*(tier==2 and 28 or 0),315;curve=tier==2 and (i-3)*20 or 0;delay=tier==2 and (i-1)*.12 or tier==3 and .25 or 0
    elseif id=="continental_gate" then x0,y0=cx-175,315;curve=0
    elseif id=="answer_42" then
        local t=i*2.1;x0,y0=cx+math.cos(t)*155,310+math.sin(t)*80;curve=math.cos(t)*55;delay=(i-1)*.11
    elseif id=="sealed_gate" then x0,y0=cx-160+(i-2)*(tier==2 and 32 or 0),310;curve=tier==2 and (i-2)*70 or -40;delay=(i-1)*.15
    elseif id=="seven_stars" then
        local t=(i-1)*math.pi/6+.15;x0,y0=cx-135+math.cos(t)*115,220+math.sin(t)*45
        curve=math.cos(t)*(tier==3 and 85 or 25);delay=(i-1)*.10
    elseif id=="five_ley_lines" then x0,y0=cx+(i-3)*52,440;curve=(i-3)*22;delay=tier>=2 and (i-1)*.12 or 0
    elseif id=="endless_cycle" then x0,y0=cx-125,340;curve=i==2 and 75 or -75;delay=tier==3 and .3 or 0 end
    if phase~="TRAVEL" and phase~="RELEASE" then
        local build=smooth((n.charge-.2)/.6)
        local wind=smooth((n.charge-.8)/.2)
        local pull=n.reducedMotion and 3 or 8+tier*5
        return mix(c.x,x0,build)+math.sin(n.charge*math.pi)*curve*.08,
            mix(c.y,y0,build)+wind*pull
    end
    local origin=n.launch[i];if origin then x0,y0=origin.x,origin.y end
    if phase=="RELEASE" then p=0 end
    local k=clamp((p-delay)/(1-delay))^(id=="even_frost" and tier>=2 and 1.7 or 2.25)
    if id=="pair" and tier==2 and i==1 then k=clamp(p/.55)^2.25 end -- shield pins first; lance follows
    if id=="straight_flush" and tier==3 then k=clamp((p-.18)/.82)^4.3 end
    if id=="four_of_a_kind" and tier==3 then
        k=clamp((p-delay)/(1-delay))^3.4
        return mix(x0,x1,k),mix(y0,y1,k)-math.sin(k*math.pi)*35
    end
    if id=="fibonacci" then
        local t=i*2.399+k*math.pi*(tier==3 and 3 or 1)
        return mix(x0,x1,k)+math.sin(t)*math.sin(k*math.pi)*(30+tier*12),mix(y0,y1,k)+math.cos(t)*math.sin(k*math.pi)*18
    end
    if id=="answer_42" and tier>=2 then
        local corner=clamp((k-.35)/.65);local waypointX=cx+(i%2==0 and 45 or -45)
        return k<.35 and mix(x0,waypointX,k/.35) or mix(waypointX,x1,corner),mix(y0,y1,k)
    end
    if id=="endless_cycle" and tier==3 then k=clamp((p-.3)/.7)^3.8 end
    return mix(x0,x1,k)+math.sin(k*math.pi)*curve,mix(y0,y1,k)
end
function N.cardEmitter(a,i)
    local n=a.nen;local c=n.snapshot.cards[i]
    local dest=1
    if a.profile.id=="pair" then dest=(i-1)%2+1
    elseif a.profile.id=="straight" then dest=c.order
    elseif a.profile.id=="even_frost" and n.tier==1 then dest=i
    elseif a.profile.id=="two_pair" or a.profile.id=="three_of_a_kind" or a.profile.id=="four_of_a_kind" then dest=i
    elseif a.profile.id=="flush" and n.tier==1 or a.profile.id=="straight_flush" and n.tier==2 then dest=i
    elseif a.profile.id=="full_house" then dest=(i-1)%N.count(a)+1
    elseif a.profile.id=="tesla_369" then for j,role in ipairs(n.roles) do if role==i then dest=j;break end end
    else dest=(i-1)%N.count(a)+1 end
    return dest
end
function N.cardPose(a,i,p)
    local n=a.nen;local c=n.snapshot.cards[i];local k=smooth(p)
    local dest=N.cardEmitter(a,i)
    local tx,ty=N.position(a,dest,"CHARGE",1)
    local rotation=n.reducedMotion and 0 or a.profile.id=="eclipse_duality" and k*(i%2==0 and .8 or -.8) or math.sin(i*2.1)*k*.22
    return (tx-c.x)*k,(ty-c.y)*k-math.sin(p*math.pi)*(n.reducedMotion and 2 or 10),rotation,1-.88*k
end
function N.camera(a,age)
    local n=a.nen;if n.reducedMotion then return 0,0 end
    local p=clamp(age/C.camera.duration);local kick=C.camera.kick[n.tier]*math.exp(-7*p)*(1-p)*math.cos(7*p)
    local side=a.profile.id=="pair" and .35 or a.profile.id=="straight" and -.35 or .08
    return side*kick,-kick
end
function N.reaction(a,age)
    local n=a.nen;local p=clamp(age/C.camera.duration);local weight=n.reducedMotion and .3 or 1
    local impulse=math.exp(-6*p)*(1-p)*math.cos(6*p)
    return -C.camera.recoil[n.tier]*impulse*weight,1-.06*impulse*weight,(1-p)^2
end
function N.cancel(a)
    if not a or not a.nen then return end
    local n=a.nen;n.cancelled=true;n.particleCount=0;n.points={};n.launch={}
end
return N
