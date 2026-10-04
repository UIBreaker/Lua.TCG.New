-- Transient presentation only. Shop remains the authority for prices and mutations.
local Shop = require("src.shop")
local Sound = require("src.sound")
local Effects = require("src.card_effects")
local Config = require("config.ux_polish_config")
local P = {config=Config, focus=nil, job=nil, age=0, time=0, applications={}}
local motion=setmetatable({}, {__mode="k"})
local shader, canvas, loaded
local function clamp(t) return math.max(0,math.min(1,t)) end
local function out(t) return 1-(1-clamp(t))^3 end
local function smooth(t) t=clamp(t);return t*t*(3-2*t) end
local function inside(r,x,y) return r and x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
local function identity(item) return item and (item.card or item.deity or item.equipment or item) end
function P.busy() return P.job~=nil end
function P.goldPulse()
    local j=P.job
    if not j then return 1 end
    return 1+0.06*math.sin(clamp((j.age/j.duration-0.06)/0.25)*math.pi)
end
function P.clearFocus() P.focus=nil end
function P.isFocused(card) return P.focus and identity(P.focus.item)==card end
function P.ensureShop(shop)
    if P.shop~=shop then P.shop=shop;P.age=0;P.clearFocus() end
end
function P.items(shop) return P.job and P.job.items or shop.items end
function P.focusItem(item,kind,index,rect)
    if P.busy() or not item then return false end
    P.focus={item=item,kind=kind,index=index,rect=rect,age=0}
    Sound.play("card_select")
    return true
end
function P.tooltipAllowed(item)
    local key=identity(item)
    for _,a in ipairs(P.applications) do if a.target==key and a.age<Config.application then return false end end
    return not P.busy() and (not P.focus or key==identity(P.focus.item))
end
function P.hiddenOwned(item)
    return P.focus and P.focus.kind~="stock" and identity(P.focus.item)==item
        or P.job and (identity(P.job.item)==item or P.job.acquired==item)
end
function P.rect(UI,item,fallback)
    local s=UI.CardPhysics.getState(identity(item)) or UI.CardPhysics.getState(item)
    if s and s.a and s.ox then
        local x,y=s.ox,s.oy
        local x2,y2=x+s.a*s.w,y+s.b*s.w
        local x3,y3=x+s.c*s.h,y+s.d*s.h
        local x4,y4=x2+s.c*s.h,y2+s.d*s.h
        local left,top=math.min(x,x2,x3,x4),math.min(y,y2,y3,y4)
        return {x=left,y=top,w=math.max(x,x2,x3,x4)-left,h=math.max(y,y2,y3,y4)-top}
    end
    return fallback or {x=600,y=350,w=80,h=110}
end
function P.button(game)
    local f=P.focus;if not f or P.busy() then return end
    if f.kind=="card" and not game.soulDestroyActive then return end
    local price=f.kind=="stock" and f.item.cost or Shop.getSacrificePrice(f.item,f.kind,game)
    if f.kind=="card" then price=Shop.getSoulValue(f.item) end
    local soul=f.kind=="stock" and f.item.currency=="souls"
    local full=f.kind=="stock" and f.item.consumable and #(game.consumables or {})>=3
    local disabled=f.kind=="stock" and (soul and (game.souls or 0) or (game.gold or 0))<price
        or f.kind=="card" and #(game.persistentDeck or {})<=1
        or full
    local r=f.rect
    return {id="polish_confirm",x=math.max(12,math.min(1118,r.x+r.w/2-74)),
        y=math.max(70,math.min(634,r.y+r.h+12)),w=148,h=34,
        text=disabled and (full and "Ô TIÊU HAO ĐẦY" or (f.kind=="stock" and (soul and "THIẾU LINH HỒN" or "KHÔNG ĐỦ VÀNG") or "GIỮ ÍT NHẤT 1 LÁ"))
            or (f.kind=="card" and ("HỦY · +"..price.." LH")
            or ((f.kind=="stock" and (soul and "MUA · " or "MUA — $") or "BÁN — $")..price..(soul and " LH" or ""))),disabled=disabled}
end
local function ownedValid(f,game)
    if f.kind=="deity" then return game.deities and game.deities[f.index]==f.item end
    if f.kind=="consumable" then return game.consumables and game.consumables[f.index]==f.item end
    for _,card in ipairs(game.persistentDeck or {}) do if card==f.item then return true end end
end
function P.confirm(shop,game,done)
    local f=P.focus;if not f or P.busy() then return false end
    local b=P.button(game);if not b then P.clearFocus();return false end
    if b.disabled then Sound.play("cant_afford");return false end
    local soulTransaction=f.kind=="card" or f.kind=="stock" and f.item.currency=="souls"
    local before=soulTransaction and (game.souls or 0) or (game.gold or 0)
    local occupied={};for slot,d in pairs(game.deities or {}) do occupied[slot]=d end
    local ok,action,equipment
    local items={};for i,item in ipairs(shop.items or {}) do items[i]=item end
    if f.kind=="stock" then
        if shop.items[f.index]~=f.item then P.clearFocus();return false end
        ok,action,equipment=Shop.buyItem(shop,f.index,game)
    elseif ownedValid(f,game) then
        if f.kind=="card" then ok,action=Shop.destroyCard(game,f.item)
        elseif f.kind=="deity" then ok,action=Shop.sellDeity(game,f.index)
        elseif f.kind=="consumable" then ok,action=Shop.sellConsumable(game,f.index) end
    end
    if not ok then P.message=type(action)=="string" and action or "Không thể giao dịch.";P.messageAge=0;return false,action end
    local kind=f.kind=="stock" and "buy" or "sell"
    local target={x=Config.deck.x,y=Config.deck.y}
    local acquired
    local gold=P.goldPosition or Config.gold
    if kind=="sell" then target=gold
    elseif f.item.deity then
        for slot,d in pairs(game.deities or {}) do if d~=occupied[slot] then
            acquired=d;target={x=1074+((slot-1)%3)*78,y=156+math.floor((slot-1)/3)*107};break end end
    elseif f.item.consumable then
        acquired=f.item.consumable
        target={x=1074+(#game.consumables-1)*78,y=408}
    end
    P.job={kind=kind,age=0,duration=Config[kind],item=f.item,rect=f.rect,target=target,button=b,
        items=kind=="buy" and items or nil,delta=(soulTransaction and (game.souls or 0) or (game.gold or 0))-before,
        soul=soulTransaction,acquired=acquired,gold=gold,
        done=function() if done then done(action,equipment) end end}
    P.clearFocus();return true
end
function P.reroll(shop,game)
    if P.busy() then return false end
    local refresh
    local ok,msg=Shop.reroll(shop,game,function() refresh=true end)
    if not ok then return false,msg end
    P.clearFocus()
    local items={};for i,item in ipairs(shop.items or {}) do items[i]=item end
    local factor=Config.reroll/0.78
    local stagger,flip=Config.stagger*factor,Config.flip*factor
    local maxDelay=(math.min(Config.flipGroup,#items)-1)*stagger
    P.job={kind="flip",age=0,duration=Config.reroll,items=items,stagger=stagger,flip=flip,groupSize=Config.flipGroup,
        swapAt=0.08*factor+math.max(0,maxDelay)+flip*2,revealDelay=0.025*factor,startDelay=0.08*factor,
        refresh=refresh,shop=shop,game=game}
    return true
end
function P.update(dt,fast,state,shop)
    local step=dt*(fast and Config.fastFactor or 1)
    P.time=P.time+step;P.age=P.age+step
    if state=="shop" and shop then P.ensureShop(shop) elseif not P.job then P.clearFocus();P.shop=nil end
    if P.focus then P.focus.age=P.focus.age+step end
    if P.message then P.messageAge=P.messageAge+step;if P.messageAge>Config.popup then P.message=nil end end
    local job=P.job
    if job then
        job.age=job.age+step
        if job.kind=="buy" and not job.reacted and job.age>=job.duration*0.18 then
            job.reacted=true;Effects.triggerScorePulse(identity(job.item));Sound.play("coin")
        end
        if job.kind=="flip" and not job.swapped and job.age>=job.swapAt then
            -- Every old front is now covered. Never refresh while a front is visible.
            Shop.refresh(job.shop,job.game);job.items=job.shop.items;job.swapped=true
            Sound.play("card_slide")
        end
        if job.age>=job.duration then
            P.job=nil;Sound.play(job.kind=="sell" and "coin" or "card_deal")
            if job.done then job.done() end
        end
    end
    for i=#P.applications,1,-1 do
        local a=P.applications[i];a.age=a.age+step
        if not a.hit and a.age>=Config.application*0.60 then
            a.hit=true;Effects.triggerScorePulse(a.target);Sound.play("mult_pop")
        end
        if a.age>=Config.application+Config.popup then table.remove(P.applications,i) end
    end
end
function P.surface(item,index,hovered,x,y,w,h,draw)
    local job=P.job;local focused=P.focus and P.focus.item==item
    local s=motion[item];if not s then s={scale=1,lift=0,last=P.time};motion[item]=s end
    if hovered and not s.hovered and not job then Sound.play("ui_hover") end
    s.hovered=hovered
    local elapsed=math.max(0,P.time-s.last);s.last=P.time
    local response=1-math.exp(-Config.hoverResponse*elapsed)
    local target=focused and Config.focusScale or hovered and not job and Config.hoverScale or 1
    s.scale=s.scale+(target-s.scale)*response
    s.lift=s.lift+((focused and -Config.focusLift or hovered and not job and -4 or 0)-s.lift)*response
    local flip,back=1,false
    if job and job.kind=="flip" then
        local start=(job.swapped and job.swapAt+job.revealDelay or job.startDelay)+((index-1)%job.groupSize)*job.stagger
        local t=clamp((job.age-start)/(job.flip*2))
        flip=math.abs(math.cos(smooth(t)*math.pi))
        back=job.swapped and t<0.5 or not job.swapped and t>=0.5
    else
        local entrance=clamp((P.age-(index-1)*0.025)/Config.arrival)
        flip=0.90+0.10*out(entrance)
    end
    if job and job.item==item then return end -- Transaction ghost owns the surface.
    local g=love.graphics
    local entryLift=job and 0 or (1-out((P.age-(index-1)*0.025)/Config.arrival))*16
    g.push("all");g.translate(x+w/2,y+h/2+s.lift+entryLift);g.scale(math.max(0.012,flip)*s.scale,s.scale);g.translate(-x-w/2,-y-h/2)
    if back then require("src.ui").drawCardBack(x,y,w,h)
    else draw() end
    if P.focus and not focused or P.age<(index-1)*0.025+Config.arrival then
        local a=P.focus and not focused and Config.dim or 1-out((P.age-(index-1)*0.025)/Config.arrival)
        g.setShader();g.setColor(0.01,0.02,0.03,a);g.rectangle("fill",x,y,w,h,5,5)
    end
    g.pop()
    return back
end
function P.load()
    if loaded then return shader~=nil end;loaded=true
    local ok,result=pcall(love.graphics.newCanvas,256,384)
    if ok then canvas=result else print("[UX] canvas fallback: "..tostring(result)) end
    ok,result=pcall(love.graphics.newShader,"shaders/card_dissolve.glsl")
    if ok then shader=result else print("[UX] dissolve fallback: "..tostring(result)) end
    return shader~=nil
end
function P.dissolve(UI,x,y,w,h,amount,color,draw)
    P.load();amount=clamp(amount)
    if amount>=1 then return end
    local g=love.graphics
    if not canvas then
        g.push("all");g.setColor(1,1,1,1-amount);draw(x,y,w,h);g.pop();return
    end
    UI.CardPhysics.suspend()
    local oldCanvas=g.getCanvas()
    g.push("all");g.origin();g.setCanvas(canvas);g.setShader();g.clear(0,0,0,0)
    g.setBlendMode("alpha");g.setColor(1,1,1,1)
    g.scale(256/w,384/h);draw(0,0,w,h)
    g.setCanvas(oldCanvas);g.pop()
    g.push("all");g.setShader(shader)
    if shader then
        shader:send("dissolveAmount",amount);shader:send("time",P.time)
        shader:send("edgeColor",color or {1,0.8,0.35})
    end
    local alpha=shader and 1 or 1-amount
    g.setBlendMode("alpha","premultiplied");g.setColor(alpha,alpha,alpha,alpha)
    g.draw(canvas,x,y,0,w/256,h/384);g.pop();UI.CardPhysics.resume()
end
function P.application(UI,source,target,text,sourceRect,targetRect)
    if not target or not text or text=="" then return end
    local s=sourceRect or P.rect(UI,source,{x=1110,y=405,w=64,h=88})
    local r=targetRect or P.rect(UI,target)
    P.applications[#P.applications+1]={source=s,target=target,rect=r,text=text,age=0,color=Effects.getBeamColor(target)}
end
function P.snapshot(game)
    local A=require("src.card_abilities");local D=require("src.deities");local Deck=require("src.deck")
    local snap={}
    local function remember(card)
        if snap[card] then return end
        local values={level=card.evolutionLevel or 0,speed=card.rank and Deck.getCardAttackSpeed(card) or nil,
            edition=Effects.getEffectName(card) or "",seal=card.seal or "",enhancement=card.enhancement or "",
            equipment=#(card.equipments or {}),frozen=card.frozen or card.freezeTurns or 0,cursed=card.cursed or false}
        local params=A.definition(card) and A.params(card)
        local def=D.CATALOG[card.id]
        if def then
            local value=def.values.value
            -- XMult values store the bonus above 1, as in the scoring callback.
            local effect=D.scaleEffect(card,{[def.stat]=def.stat=="xMult" and 1+value or value})
            params={[def.stat]=effect[def.stat]};values.rarity=D.getRarityBadge(card)
        end
        for k,v in pairs(params or {}) do if type(v)=="number" then values[k]=v end end
        snap[card]=values
    end
    for _,pile in ipairs({game.hand or {},game.persistentDeck or {},game.deities or {}}) do for _,c in pairs(pile) do remember(c) end end
    return snap
end
local labels={level="TIẾN HÓA",speed="TỐC ĐÁNH",edition="ẤN BẢN",seal="ẤN",enhancement="RÈN",equipment="ITM",
    rarity="BẬC",addMult="CƯỜNG HÓA",addChips="SÁT THƯƠNG",addGold="VÀNG",
    xMult="HỆ SỐ CƯỜNG HÓA",addArmor="GIÁP",addHealHp="HỒI HP",addSplashPct="LAN (%)",
    armor="GIÁP",gold="VÀNG",mult="CƯỜNG HÓA",chips="SÁT THƯƠNG",damage="SÁT THƯƠNG",repeats="TÁI KÍCH HOẠT",
    frozen="ĐÓNG BĂNG",cursed="NGUYỀN",returnArmor="GIÁP TRẢ BÀI",healPercent="HỒI HP (%)",
    maxStacks="TRẦN TÍCH",capacity="KÍCH THƯỚC TAY",returns="LÁ TRẢ",draw="LÁ RÚT",block="CHẶN ST",
    maxGold="TRẦN VÀNG",levels="CẤP KHẢ NĂNG",copies="SAO CHÉP",range="PHẠM VI",duration="TAY HIỆU LỰC",
    cancels="KỸ NĂNG HỦY",hands="LƯỢT ĐÁNH",skip="HÀNH ĐỘNG BỎ QUA"}
local function valueText(key,value)
    if type(value)=="number" then return (string.format("%.2f",value):gsub("0+$",""):gsub("%.$","")) end
    if type(value)=="boolean" then return value and "BẬT" or "TẮT" end
    if value=="" then return "KHÔNG" end
    if key=="edition" then return string.upper(value) end
    local Deck=require("src.deck")
    local def=key=="seal" and Deck.SEALS[value] or key=="enhancement" and Deck.ENHANCEMENTS[value]
    return def and def.name or tostring(value)
end
function P.changed(UI,game,before,source,sourceRect)
    local after=P.snapshot(game)
    local seen={}
    local function report(target)
        local key=target.rank and target.id or target
        if seen[key] then return end;seen[key]=true
        local values=before[target];if not values then return end
        local nextValues=after[target]
        if nextValues then
            local lines={}
            for key,old in pairs(values) do
                local new=nextValues[key]
                if new~=nil and new~=old then lines[#lines+1]=(labels[key] or key).." "..valueText(key,old).." → "..valueText(key,new) end
            end
            table.sort(lines)
            if #lines>0 then P.application(UI,source,target,table.concat(lines,"\n"),sourceRect) end
        end
    end
    -- Prefer visible hand instances over their persistent copies (same card ID).
    for _,pile in ipairs({game.hand or {},game.deities or {},game.persistentDeck or {}}) do
        for _,target in pairs(pile) do report(target) end
    end
end
function P.renderItem(UI,item,x,y,w,h)
    if UI.getConsumableImage(item) or (item.handId and UI.getHandImage(item.handId)) then
        return require("ui.card_surfaces").fullReward(item,x,y,w,h,item.packType,false)
    end
    if item.rank then return UI.drawCard(item,x,y,w,h) end
    if require("src.deities").CATALOG[item.id] then return UI.drawPatronCard(item,x,y,w,h) end
    if item.category~="pack" and not item.card and not item.deity and not item.equipment
        and item.category~="voucher" and item.category~="heal" and item.category~="destroy" and item.category~="hand_expansion" and P.drawConsumable then
        return P.drawConsumable(item,x,y,w,h,1,-1000,-1000,false,true,1)
    end
    return require("ui.shop_display").drawArt(item,x,y,w,h,false,-1000,-1000)
end
function P.draw(UI,game,buttons,mx,my)
    local function drawItem(item,x,y,w,h) return P.renderItem(UI,item,x,y,w,h) end
    local g=love.graphics
    UI.CardPhysics.suspend()
    if P.focus and P.focus.kind~="stock" then
        local r=P.focus.rect;local scale=1+0.08*out(P.focus.age/0.16)
        g.push("all");g.translate(r.x+r.w/2,r.y+r.h/2-Config.focusLift*out(P.focus.age/0.16));g.scale(scale)
        drawItem(P.focus.item,-r.w/2,-r.h/2,r.w,r.h);g.pop()
    end
    local b=P.button(game)
    if b then
        b.color=UI.COLORS.btnConfirm;b.font=UI.fonts.tiny
        buttons[#buttons+1]=b;UI.drawButton(b,inside(b,mx,my),false)
    end
    local job=P.job
    if job and job.kind~="flip" then
        local tint=job.soul and {0.73,0.48,1} or {1,0.77,0.25}
        if job.button and job.age<job.duration*0.22 then
            local b=job.button;b.color=UI.COLORS.btnConfirm;b.font=UI.fonts.tiny
            b.animationScale=1-0.06*math.sin(clamp(job.age/(job.duration*0.22))*math.pi)
            UI.drawButton(b,false,true)
        end
        local r=job.rect;local t=clamp(job.age/job.duration)
        local flight=job.kind=="buy" and smooth((t-Config.buyFlightStart)/(Config.buyFlightEnd-Config.buyFlightStart)) or 0
        local x=r.x+r.w/2+(job.target.x-r.x-r.w/2)*flight
        local y=r.y+r.h/2+(job.target.y-r.y-r.h/2)*flight-math.sin(flight*math.pi)*38
        local size=1+math.sin(clamp(t/0.36)*math.pi)*(job.kind=="sell" and -0.04 or 0.06)-flight*0.55
        g.push("all");g.translate(x,y);g.rotate(flight*0.12+(job.kind=="sell" and math.sin(t*25)*0.008*(1-t) or 0));g.scale(size)
        if job.kind=="sell" then
            UI.drawCardBorder(-r.w/2,-r.h/2,r.w,r.h,{1,0.77,0.25,math.max(0,1-t*4)})
            P.dissolve(UI,-r.w/2,-r.h/2,r.w,r.h,out((t-0.18)/0.55),tint,function(a,c,w,h) drawItem(job.item,a,c,w,h) end)
        else drawItem(job.item,-r.w/2,-r.h/2,r.w,r.h) end
        g.pop()
        for i=1,Config.shards do
            local p=out((t-Config.coinStart-i*0.015)/Config.coinTravel)
            local sx,sy,tx,ty=job.gold.x,job.gold.y,r.x+r.w/2,r.y+r.h/2
            if job.kind=="sell" then sx,sy,tx,ty=tx,ty,sx,sy end
            g.setColor(tint[1],tint[2],tint[3],math.sin(p*math.pi));g.circle("fill",sx+(tx-sx)*p,sy+(ty-sy)*p-math.sin(p*math.pi)*(20+i*3),2)
        end
        g.setFont(UI.fonts.small);g.setColor(1,0.8,0.35,1-t)
        g.print((job.delta>0 and "+" or "-")..(job.soul and "" or "$")..math.abs(job.delta)..(job.soul and " LH" or ""),job.gold.x,job.gold.y+24-out(t)*16)
    end
    for _,a in ipairs(P.applications) do
        local current=UI.CardPhysics.getState(a.target)
        if current and current.x then
            a.rect=P.rect(UI,a.target,a.rect)
        else
            -- A deck-only target needs a brief preview after its picker has closed.
            a.rect.x=568;a.rect.y=290;a.rect.w=80;a.rect.h=110
            P.renderItem(UI,a.target,a.rect.x,a.rect.y,a.rect.w,a.rect.h)
        end
        local r,s=a.rect,a.source;local p=out(a.age/(Config.application*0.6))
        local x=s.x+s.w/2+(r.x+r.w/2-s.x-s.w/2)*p
        local y=s.y+s.h/2+(r.y+r.h/2-s.y-s.h/2)*p-math.sin(p*math.pi)*45
        local c=a.color
        g.setColor(c[1],c[2],c[3],1-p);g.circle("fill",x,y,5)
        local contact=math.max(0,a.age-Config.application*0.6)
        g.setColor(c[1],c[2],c[3],a.hit and math.max(0,0.6-contact*3) or 0.22)
        UI.drawCardBorder(r.x,r.y,r.w,r.h,{c[1],c[2],c[3],a.hit and math.max(0,0.6-contact*3) or 0.22})
        if a.hit and contact<0.10 then
            g.setColor(c[1],c[2],c[3],0.08*(1-contact/0.10));g.rectangle("fill",r.x,r.y,r.w,r.h,5,5)
        end
        if a.hit then
            g.setColor(c[1],c[2],c[3],clamp((Config.application+Config.popup-a.age)/0.25))
            g.setFont(UI.fonts.tiny)
            if not a.height then local _,lines=UI.fonts.tiny:getWrap(a.text,190);a.height=#lines*UI.fonts.tiny:getHeight() end
            g.printf(a.text,math.max(10,math.min(1080,r.x-40)),math.max(60,r.y-a.height-10-out(contact)*15),190,"center")
        end
    end
    if P.message then g.setColor(1,0.5,0.4,1);g.setFont(UI.fonts.small);g.printf(P.message,350,640,580,"center") end
    UI.CardPhysics.resume()
end
return P
