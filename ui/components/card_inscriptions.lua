-- In-card metal/enamel inscriptions. Values select the spectacle, never gameplay.
local I={}
local thresholds={speed={0,15,25,40,65,100,175,300,600,900},damage={0,10,25,50,100,250,500,1000,2500,10000}}
function I.statTier(kind,value)
    local tier=1
    for i,minimum in ipairs(thresholds[kind]) do if value>=minimum then tier=i end end
    return tier
end

local function text(UI,label,x,y,w,font,color,alpha,glow)
    local g=love.graphics
    g.setFont(font)
    local scale=math.min(1,(w-4)/math.max(1,font:getWidth(label)))
    g.push();g.translate(x+w/2,y);g.scale(scale,scale)
    local left=-w/(2*scale)
    if glow then
        g.setColor(glow[1],glow[2],glow[3],alpha*glow[4])
        for _,offset in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
            g.printf(label,left+offset[1],offset[2],w/scale,"center")
        end
    end
    g.setColor(0,0,0,alpha*.95);g.printf(label,left+.6,1,w/scale,"center")
    g.setColor(color[1],color[2],color[3],alpha);g.printf(label,left,0,w/scale,"center")
    g.pop()
end

local function plate(x,y,w,h,tier,color,alpha,time,moving,low,flag)
    local g=love.graphics
    local pulse=moving and (.5+.5*math.sin(time*(1.4+tier*.12))) or .35
    local strength=(tier-1)/9
    local function tint(a,white)
        white=white or 0
        g.setColor(color[1]*(1-white)+white,color[2]*(1-white)+white,color[3]*(1-white)+white,alpha*a)
    end
    local points=flag and {x,y,x+w,y,x+w,y+h,x+w/2,y+h-5,x,y+h}
        or {x+3,y,x+w-3,y,x+w,y+3,x+w,y+h-3,x+w-3,y+h,x+3,y+h,x,y+h-3,x,y+3}
    if tier>=3 then
        g.setLineWidth(3+strength*2);tint(.08+strength*.12+pulse*.07);g.polygon("line",points)
    end
    g.setColor(.018+color[1]*.035,.025+color[2]*.035,.038+color[3]*.035,alpha*.98)
    g.polygon("fill",points)
    g.setLineWidth(tier>=5 and 1.3 or .8);tint(.5+strength*.4,.12);g.polygon("line",points)
    g.setLineWidth(.65);tint(.35+strength*.35,.6);g.line(x+3,y+1.5,x+w-3,y+1.5)
    tint(.13);g.line(x+3,y+h-2,x+w-3,y+h-2)
    if tier>=2 then
        local phase=moving and (time*(.16+tier*.018))%1 or .35
        local cx=x+3+(w-6)*phase
        g.setLineWidth(1);tint(.65,.5);g.line(math.max(x+2,cx-5-strength*5),y+1.5,cx,y+1.5)
        if tier>=5 then
            local count=low and 2 or math.min(6,tier-3)
            for i=1,count do
                local px=x+3+(w-6)*((phase+i/count)%1)
                local py=y+h-1-(flag and 5*(1-math.abs((px-x)/w*2-1)) or 0)
                local r=.6+strength*.6+pulse*.4
                tint(.5+pulse*.4,.35);g.polygon("fill",px-r,py,px,py-r,px+r,py,px,py+r)
            end
        end
    end
    if tier>=7 then
        for _,cx in ipairs({x+3,x+w-3}) do
            local cy=y+h/2;local r=1.3+strength
            tint(.85,.3);g.polygon("fill",cx-r,cy,cx,cy-r,cx+r,cy,cx,cy+r)
            if tier>=9 then
                g.setLineWidth(.7);tint(.3+pulse*.5,.6)
                g.line(cx-3,cy,cx+3,cy);g.line(cx,cy-3-pulse,cx,cy+3+pulse)
            end
        end
    end
    if tier>=8 then
        local burst=moving and math.max(0,math.sin(time*2+tier))^8 or .15
        g.setLineWidth(.7);tint(.18+burst*.65,.5)
        for i=1,(low and 3 or 5) do
            local cx=x+w*i/(low and 4 or 6)
            local reach=1+burst*(tier-5)*.6
            g.line(cx,y-1,cx+(i%2==0 and 1 or -1),y-1-reach)
        end
    end
end

local function rankBadge(UI,card,definition,tier,color,alpha,time,moving,low)
    local g=love.graphics
    plate(8,8,28,53,tier,color,alpha,time,moving,low)
    -- Ivory enamel keeps red/black identity readable regardless of frame rarity.
    g.setColor(.97,.95,.87,alpha)
    g.polygon("fill",12,11,32,11,33,12,33,54,30,57,14,57,11,54,11,12)
    g.setColor(1,1,.97,alpha*.65);g.rectangle("fill",12,12,2,40)
    g.setColor(.35,.27,.17,alpha*.30);g.setLineWidth(.6);g.line(14,36,30,36)
    local suit=definition and definition.suit
    local red=suit=="heart" or suit=="diamond"
    local ink=red and {.68,.025,.075} or {.025,.055,.10}
    local rank=tostring(card.rankName or require("src.deck").RANK_NAMES[card.rank] or card.rank)
    local font=UI.fonts.medium
    local scale=math.min(1,20/math.max(1,font:getWidth(rank)))
    g.push();g.translate(22,10);g.scale(scale,scale);g.setFont(font)
    local width=24/scale
    g.setColor(1,1,1,alpha*.75);g.printf(rank,-width/2,1,width,"center")
    g.setColor(ink[1],ink[2],ink[3],alpha);g.printf(rank,-width/2,0,width,"center")
    g.pop()
    -- Vector pips keep their silhouette at inventory sizes and do not rely on font glyphs.
    g.push();g.translate(22,46)
    g.setColor(ink[1],ink[2],ink[3],alpha)
    if suit=="diamond" then
        g.polygon("fill",0,-8,6,0,0,8,-6,0)
    elseif suit=="heart" then
        g.circle("fill",-3.1,-2.4,3.7,16);g.circle("fill",3.1,-2.4,3.7,16)
        g.polygon("fill",-6.5,-1.2,6.5,-1.2,0,7.2)
    elseif suit=="club" then
        g.circle("fill",0,-3.7,3.8,16);g.circle("fill",-3.8,1,3.8,16);g.circle("fill",3.8,1,3.8,16)
        g.polygon("fill",-1,1,1,1,1.7,6,3,7.5,-3,7.5,-1.7,6)
    elseif suit=="spade" then
        g.circle("fill",-3.1,1,3.7,16);g.circle("fill",3.1,1,3.7,16)
        g.polygon("fill",0,-7.5,6.5,0,-6.5,0)
        g.polygon("fill",-1,1,1,1,1.7,6,3,7.5,-3,7.5,-1.7,6)
    else
        text(UI,card.suitSymbol or "?",-10,-8,20,UI.fonts.small,ink,alpha)
    end
    g.pop()
end

function I.draw(UI,card,definition,showDamage)
    local g=love.graphics
    local alpha=card.alpha or 1
    if alpha<=0 or card.faceDown then return end
    local visual=require("config.visual_config")
    local moving=visual.enabled and not UI.Polish.reducedMotion
    local time=moving and UI.Polish.time or 0
    local low=visual.quality=="LOW"
    local tier=UI.CardFrame.tier(card)
    rankBadge(UI,card,definition,tier,UI.CardFrame.styles[tier].gem,alpha,time,moving,low)
    local speed=require("src.deck").getCardAttackSpeed(card)
    local damage=require("src.deck").getCardDamage(card)
    local speedTier,damageTier=I.statTier("speed",speed),I.statTier("damage",damage)
    local function statColor(tier,speedStat)
        local s=(tier-1)/9
        if speedStat then return {.30+s*.55,.65+s*.30,1-s*.12} end
        return {1,.44+s*.40,.22+s*.30}
    end
    local blue,fire=statColor(speedTier,true),statColor(damageTier,false)
    if (card.combatFatigue or 0)>0 then
        g.setColor(.10,.025,.035,alpha*.92);g.rectangle("fill",8,125,75,15,3)
        text(UI,"SUY YẾU −"..card.combatFatigue,10,126,71,UI.fonts.tiny,{1,.52,.39},alpha)
    end
    local function glow(tier,color)
        if tier<4 then return end
        return {color[1],color[2],color[3],.12+(tier-4)*.025+(moving and .08*math.sin(time*2)^2 or 0)}
    end
    plate(83,8,37,30,speedTier,blue,alpha,time,moving,low,true)
    text(UI,"TỐC",85,9,33,UI.fonts.tiny,blue,alpha)
    text(UI,tostring(speed),86,20,31,UI.fonts.small,{1,1,1},alpha,glow(speedTier,blue))
    if definition then
        local tier=UI.CardFrame.tier(card)
        local metal=UI.CardFrame.styles[tier].gem
        plate(8,145,112,17,tier,metal,alpha,time,moving,low)
        if tier>=4 then
            local cx,cy=64,145
            g.setColor(metal[1],metal[2],metal[3],alpha*.9)
            g.polygon("fill",cx-3,cy,cx,cy-2.5,cx+3,cy,cx,cy+2.5)
            if tier>=6 then
                g.setLineWidth(.8);g.line(cx-13,cy-1,cx-5,cy+1,cx,cy-3,cx+5,cy+1,cx+13,cy-1)
            end
        end
        local name=definition.characterName:match("^(.-) ·") or definition.characterName
        text(UI,name,14,147,100,UI.fonts.tiny,{.98,.96,.89},alpha)
    end
    if showDamage then
        plate(77,166,43,18,damageTier,blue,alpha,time,moving,low)
        text(UI,"CH "..tostring(require("src.deck").getCardEmpowerment(card)),79,168,39,UI.fonts.tiny,{.75,.90,1},alpha)
        plate(8,166,66,18,damageTier,fire,alpha,time,moving,low)
        text(UI,"ST "..tostring(damage),12,168,58,UI.fonts.tiny,{1,.90,.73},alpha,glow(damageTier,fire))
    end
end
return I
