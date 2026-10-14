local C=require("config.nen_magic_config")
local M={config=C}
local pi=math.pi
local function clamp(x) return math.max(0,math.min(1,x)) end
local function mix(a,b,t) return a+(b-a)*t end
function M.scale(aura,reference)
    reference=type(reference)=="number" and reference>0 and reference<math.huge and reference or C.aura.reference
    aura=type(aura)=="number" and aura==aura and math.max(0,aura) or 0
    local ratio=math.min(C.aura.cap,aura/reference)
    local level=1;for _,threshold in ipairs(C.aura.thresholds) do if ratio>=threshold then level=level+1 end end
    local power=math.log(1+ratio)/math.log(1+C.aura.cap)
    return {level=level,name=C.levels[level],ratio=ratio,power=power,size=math.min(1.45,.80+power*.65),
        trail=.18+power*.24,glow=.65+power*.55,particles=5+math.floor(power*19)}
end
function M.state(a)
    local n=a.nen;if not n or n.cancelled or n.snapshot.dead then return end
    if n.magic then return n.magic end
    local profile=C.hands[n.snapshot.handId];if not profile then return end
    n.magic={profile=profile,scale=M.scale(n.snapshot.aura,n.snapshot.reference),
        cx=n.snapshot.targetX,cy=n.snapshot.targetY,sourceX=n.snapshot.targetX-160,sourceY=n.snapshot.targetY+145,
        points={},particleCount=0,seed=profile.explosionIndex*.73}
    return n.magic
end
function M.position(s,i,p)
    p=clamp(p);local h=s.profile;local mode=h.movementPattern;local count=h.projectileCount
    local cx,cy=s.cx,s.cy;local side=i%2==1 and -1 or 1
    local x,y=s.sourceX,s.sourceY;local curve=0;local delay=0;local fall=false
    if mode=="cross" or mode=="pincer" then x,y=cx+side*190,cy+100;curve=side*95
    elseif mode=="volley" then x,y=cx+(i-2)*75,cy+160;delay=(i-1)*.16
    elseif mode=="arrows" or mode=="ice" then x,y=cx-170+(i-1)*22,cy+135;delay=(i-1)*.065;curve=(i-(count+1)/2)*10
    elseif mode=="wind" then curve=-90
    elseif mode=="stones" or mode=="obsidian" then x,y=cx-190+(i-1)*34,cy+135;delay=(i-1)*.10;curve=side*18
    elseif mode=="inward" then local t=(i-1)*pi/2;x,y=cx+math.cos(t)*150,cy+math.sin(t)*100
    elseif mode=="judgement" then x,y=cx,cy-105;fall=true
    elseif mode=="lightning" or mode=="sunfall" or mode=="starfall" then
        x,y=cx+(i-(count+1)/2)*29,cy-100;delay=(i-1)*(.52/math.max(1,count-1));fall=true
    elseif mode=="coins" then x,y=cx-125+(i-2)*48,cy+145;curve=side*36;delay=(i-1)*.11
    elseif mode=="helix" then x,y=cx-155,cy+110
    elseif mode=="stars" or mode=="orbit" then local t=(i-1)*2*pi/count-pi/2
        x,y=cx+math.cos(t)*170,cy+math.sin(t)*100;curve=mode=="orbit" and side*55 or 0
    elseif mode=="wave" then x,y=cx-205,cy+12;curve=-25
    elseif mode=="eclipse" then x,y=cx+side*180,cy+35;curve=side*42
    elseif mode=="prism" then x,y=cx-180,cy+(i-2.5)*52
    elseif mode=="crown" then x,y=cx+155,cy+115;curve=65
    elseif mode=="portal" or mode=="gate" then x,y=cx-185,cy+45
    elseif mode=="compass" then x,y=cx-160,cy+120;curve=-45
    elseif mode=="ley" then x,y=cx,cy+142
    elseif mode=="infinity" then x,y=cx-170,cy+110;curve=-65 end
    local k=clamp((p-delay)/(1-delay))^(fall and 1.65 or mode=="wave" and 1.8 or 2.65)
    local px,py=mix(x,cx,k)+math.sin(k*pi)*curve,mix(y,cy,k)
    if mode=="helix" then local r=22*math.sin(pi*k)
        px=px+math.cos(k*12+i*pi)*r;py=py+math.sin(k*12+i*pi)*r end
    if mode=="orbit" then local t=k*2.2;local dx,dy=px-cx,py-cy
        px,py=cx+dx*math.cos(t)-dy*math.sin(t),cy+dx*math.sin(t)+dy*math.cos(t) end
    return px,py,k
end
function M.play(handId,aura,source,target,options)
    options=options or {};assert(C.hands[handId],"Unknown Niệm attack")
    local a={cx=target.x,quality=options.quality or "high",nen={charge=0,travel=0,points={},
        reducedMotion=options.reducedMotion,snapshot={handId=handId,aura=aura,reference=options.reference or 1000,
            targetX=target.x,targetY=target.y},particleCount=0}}
    a.previewAge=0;a.previewSpeed=options.speed or 1;a.previewImpactOnly=options.impactOnly
    local s=M.state(a);s.sourceX=source.x;s.sourceY=source.y
    return a
end
function M.update(a,dt)
    a.previewAge=a.previewAge+math.max(0,dt)*a.previewSpeed
    local age=a.previewAge
    if a.previewImpactOnly then a.phase="ENEMY_IMPACT";a.progress=1;a.impactAge=age
    elseif age<.5 then a.phase="CHARGE";a.progress=age/.5;a.nen.charge=a.progress
    elseif age<.94 then a.phase="TRAVEL";a.progress=(age-.5)/.44;a.nen.charge=1;a.nen.travel=a.progress
    else a.phase="ENEMY_IMPACT";a.progress=1;a.impactAge=age-.94 end
    return age>(a.previewImpactOnly and .42 or 1.36)
end
function M.clear(a) if a and a.nen then a.nen.cancelled=true;a.nen.magic=nil end end
return M
