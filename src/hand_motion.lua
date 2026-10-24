local Motion = require("src.motion")
local Config = require("config.ux_polish_config")
local HandMotion = {}
-- Visual momentum belongs to the hand surface, never to saved card data.
local states = setmetatable({}, { __mode = "k" })
local returns = {}
local function clamp(t) return math.max(0, math.min(1, t)) end

function HandMotion.reset()
    states = setmetatable({}, { __mode = "k" })
    returns = {}; HandMotion.onCollected = nil
end

function HandMotion.isDealing(card) local s=states[card];return s and s.deal~=nil end
function HandMotion.hidden(card)
    local s=states[card]
    return s and (s.collecting or s.deal and s.deal.age<0)
end
function HandMotion.busy(cards)
    if #returns>0 or HandMotion.onCollected then return true end
    for _,card in ipairs(cards or {}) do if HandMotion.isDealing(card) then return true end end
    return false
end
function HandMotion.returnDuration()
    local remaining=0
    for _,fx in ipairs(returns) do remaining=math.max(remaining,Config.collect-fx.age) end
    return remaining
end

function HandMotion.prepareDeal(card,order,x,y,delay)
    local angle=-0.10+math.min(order-1,7)*0.02
    states[card]={vx=0,vy=0,angularVelocity=0,scaleVelocity=0,hover=0,selected=0,
        deal={age=-(delay or 0)-math.min(order-1,7)*Config.dealStagger,x=x,y=y,angle=angle}}
    card.visualX,card.visualY,card.visualAngle,card.rotation,card.visualScale=x,y,angle,angle,0.68
end

function HandMotion.collect(card,order,x,y)
    if HandMotion.reducedMotion or card.destroyed then return end
    local ghost={};for k,v in pairs(card) do ghost[k]=v end
    ghost.visualScale,ghost.rotation,ghost.selected,ghost.hovered=1,0,false,false
    ghost.scaleX,ghost.scaleY=1,1
    local s=states[card] or {vx=0,vy=0,angularVelocity=0,scaleVelocity=0,hover=0,selected=0}
    states[card]=s;s.collecting=true;s.deal=nil
    returns[#returns+1]={card=ghost,owner=card,state=s,age=-math.min(order-1,7)*Config.collectStagger,
        x=card.visualX or x,y=card.visualY or y,angle=card.rotation or 0,scale=card.visualScale or 1,targetX=x,targetY=y}
end

function HandMotion.returnPose(fx)
    local t=clamp(fx.age/Config.collect)
    local p=t*t*t*(t*(t*6-15)+10)
    return {x=fx.x+(fx.targetX-fx.x)*p,y=fx.y+(fx.targetY-fx.y)*p-math.sin(p*math.pi)*24,
        angle=fx.angle*(1-p)+0.08*p,scale=fx.scale+(0.68-fx.scale)*p,flip=p,progress=t}
end

function HandMotion.updateReturns(dt)
    local step=dt*(HandMotion.fast and Config.fastFactor or 1)
    local complete=#returns>0
    for i=#returns,1,-1 do
        local fx=returns[i];fx.age=HandMotion.reducedMotion and Config.collect or fx.age+step
        if fx.age<Config.collect then complete=false end
    end
    if complete then
        -- Originals remain hidden until the last staggered return has arrived.
        for _,fx in ipairs(returns) do
            if states[fx.owner]==fx.state and fx.state then fx.state.collecting=false end
        end
        returns={}
    end
    if #returns==0 and HandMotion.onCollected then
        local done=HandMotion.onCollected;HandMotion.onCollected=nil;done()
    end
end

function HandMotion.drawReturns(UI)
    local g=love.graphics
    UI.CardPhysics.suspend()
    for _,fx in ipairs(returns) do
        if fx.age>=0 and fx.age<Config.collect then
            local p=HandMotion.returnPose(fx)
            g.push("all");g.translate(p.x+50,p.y+72.5);g.rotate(p.angle)
            g.scale(p.scale*math.max(0.025,math.abs(math.cos(p.flip*math.pi))),p.scale)
            if p.flip<0.5 then UI.drawCard(fx.card,-50,-72.5,100,145)
            else UI.drawCardBack(-50,-72.5,100,145) end
            g.pop()
        end
    end
    UI.CardPhysics.resume()
end

function HandMotion.get(card) return states[card] end

function HandMotion.update(card, x, y, angle, dt, waitingForDeal, hovering)
    local s = states[card]
    if not s then
        s = { vx = 0, vy = 0, angularVelocity = 0, scaleVelocity = 0, hover = 0, selected = 0 }
        states[card] = s
    end
    if s.deal then
        local d=s.deal
        d.age=d.age+dt*(HandMotion.fast and Config.fastFactor or 1)
        local launched=not d.sounded and (d.age>=0 or HandMotion.reducedMotion)
        if launched then d.sounded=true end
        if d.age<0 and not HandMotion.reducedMotion then return false end
        local t=HandMotion.reducedMotion and 1 or clamp(d.age/Config.deal)
        local p=Motion.settle(t,1)
        card.visualX=d.x+(x-d.x)*p
        card.visualY=d.y+(y-d.y)*p-math.sin(t*math.pi)*32
        card.visualAngle=d.angle+(angle-d.angle)*p
        card.rotation=card.visualAngle
        card.visualScale=0.68+0.32*p
        if t>=1 then s.deal=nil end
        return launched
    end
    if s.collecting then return false end
    local step=dt*(HandMotion.fast and Config.fastFactor or 1)
    local response = Motion.response(22, step)
    s.hover = s.hover + ((hovering and 1 or 0) - s.hover) * response
    s.selected = s.selected + ((card.selected and 1 or 0) - s.selected) * response
    y = y - (card.selected and 28 or 0) - (not HandMotion.reducedMotion and hovering and (card.selected and 6 or 14) or 0)
    if not card.visualX then
        card.visualX, card.visualY, card.visualAngle = x, y, angle
    elseif not waitingForDeal then
        local damping=HandMotion.reducedMotion and 60 or 44
        card.visualX, s.vx = Motion.spring(card.visualX, s.vx, x, 900, damping, step)
        card.visualY, s.vy = Motion.spring(card.visualY, s.vy, y, 900, damping, step)
        card.visualAngle, s.angularVelocity = Motion.spring(card.visualAngle or angle,
            s.angularVelocity, angle, 500, 36, step)
    end
    card.rotation = card.visualAngle
    card.selectPulse = math.max(0, (card.selectPulse or 0) - step * 5.5)
    local scale = HandMotion.reducedMotion and 1 or card.selected and 1.045 or hovering and 1.035 or 1
    if not HandMotion.reducedMotion then scale=scale+Motion.impact((1-card.selectPulse)/5.5,1/5.5)*.018 end
    card.visualScale, s.scaleVelocity = Motion.spring(card.visualScale or 1,
        s.scaleVelocity, scale, 1100, HandMotion.reducedMotion and 67 or 54, step)
end

return HandMotion
