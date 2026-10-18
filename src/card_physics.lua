-- A visual adapter for existing card renderers. Never stored in card/save data.
local Config = require("config.card_hold_config")
local Physics = { config = Config }
local states = setmetatable({}, { __mode = "k" })
local registry, previousRegistry, frame, depth = {}, {}, 0, 0
local held, lastCard, root, canvas, enabled
local mx, my, previousX, previousY = 0, 0, 0, 0
local mouseVX, mouseVY = 0, 0
local current, overlay = nil, false
local elapsed, serial = 0, 0
local contains
local debugEnabled, lab = false, false
local unpack = unpack or table.unpack
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function smooth(v, target, response, dt) return target + (v - target) * math.exp(-response * dt) end

local Motion=require("src.motion")
local spring = Motion.spring
Physics.spring = spring

local function inverse(a, b, c, d, tx, ty, x, y)
    local det = a * d - b * c
    if math.abs(det) < 0.00001 then return 0, 0 end
    x, y = x - tx, y - ty
    return (d * x - c * y) / det, (a * y - b * x) / det
end
Physics.inversePoint = inverse

local function logicalPoint(x, y)
    local px, py = love.graphics.transformPoint(x, y)
    return inverse(root.a, root.b, root.c, root.d, root.x, root.y, px, py)
end

function Physics.setPreset(name)
    if Config.presets[name] then Config.preset = name end
end

function Physics.reset()
    states=setmetatable({}, {__mode="k"})
    registry,previousRegistry={},{}
    held,lastCard=nil,nil
    mouseVX,mouseVY=0,0;previousX,previousY=mx,my
end

function Physics.move(x, y)
    mx, my = x, y
    if held then held.dragging = held.dragging or (x-held.pressX)^2+(y-held.pressY)^2 > Config.dragThreshold^2 end
end

function Physics.update(dt, mouseX, mouseY)
    if not dt or dt <= 0 then return end
    local hdt = math.min(dt, Config.maxDt)
    elapsed = elapsed + hdt
    Physics.move(mouseX or mx, mouseY or my)
    local vx = clamp((mx - previousX) / dt, -Config.input.maxVelocity, Config.input.maxVelocity)
    local vy = clamp((my - previousY) / dt, -Config.input.maxVelocity, Config.input.maxVelocity)
    mouseVX = smooth(mouseVX, vx, Config.input.smoothing, hdt)
    mouseVY = smooth(mouseVY, vy, Config.input.smoothing, hdt)
    previousX, previousY = mx, my
    local preset = Config.presets[Config.preset]
    for owner, surfaces in pairs(states) do
        for key, s in pairs(surfaces) do
            if s.frame < frame - 120 and s ~= held and not (s.detached and s.active) then
                surfaces[key] = nil -- Release cached render args for disappeared cards.
            elseif s.active or s.frame >= frame - 1 then
                s.active = true
                local holding = s == held
                local reduced=Physics.reducedMotion
                local step=hdt*(not holding and Physics.fast and 2 or 1)
                if s.contactAge then s.contactAge=s.contactAge+step end
                if holding then
                    s.holdTime = s.holdTime + hdt
                end
                local visible = not s.detached and s.frame >= frame - 1
                local hover = enabled and visible and s.hovered and not holding
                local pointerX, pointerY = 0, 0
                if hover and s.a and not reduced then
                    local lx, ly = inverse(s.a,s.b,s.c,s.d,s.ox,s.oy,mx,my)
                    pointerX = clamp(lx / s.w - 0.5, -0.5, 0.5) * 2
                    pointerY = clamp(ly / s.h - 0.5, -0.5, 0.5) * 2
                end
                local idleAngle = not reduced and visible and math.sin(elapsed * Config.idle.speed + s.phase) * Config.idle.angle or 0
                local bob = not reduced and visible and math.sin(elapsed * Config.idle.speed * 0.8 + s.phase) * Config.idle.bob or 0
                s.hoverLift = smooth(s.hoverLift or 0, hover and 1 or 0, Config.hover.response, hdt)
                s.targetX = holding and (mx - s.grabX) or s.homeX
                s.targetY = holding and (my - s.grabY - (reduced and 0 or Config.pickup.lift)) or (s.homeY + bob - (reduced and 0 or Config.hover.lift * s.hoverLift))
                local sway = 0
                if holding and Config.sway.enabled and not reduced then
                    sway = math.sin(s.holdTime * Config.sway.speed1) * Config.sway.amplitude1
                        + math.sin(s.holdTime * Config.sway.speed2 + 0.8) * Config.sway.amplitude2
                end
                s.targetRotation = reduced and 0 or holding and clamp(mouseVX * Config.input.velocityToTilt
                    + (s.targetX - s.x) * Config.input.lagToTilt + sway,
                    -Config.rotation.maxAngle, Config.rotation.maxAngle) or (idleAngle + pointerX * Config.hover.angle)
                local damping=reduced and 2*math.sqrt(preset.stiffness) or preset.damping
                s.x, s.vx = spring(s.x, s.vx, s.targetX, preset.stiffness, damping, step)
                s.y, s.vy = spring(s.y, s.vy, s.targetY, preset.stiffness, damping, step)
                s.rotation, s.angularVelocity = spring(s.rotation, s.angularVelocity,
                    s.targetRotation, preset.rotationStiffness, preset.rotationDamping, step)
                s.rotation = clamp(s.rotation, -Config.rotation.maxAngle * 1.2, Config.rotation.maxAngle * 1.2)
                s.lift = smooth(s.lift, holding and not reduced and 1 or 0, Config.pickup.response, step)
                s.tiltY = smooth(s.tiltY, reduced and 0 or holding and clamp(mouseVY * Config.rotation.verticalResponse
                    + (s.targetY - s.y) * 0.002, -1, 1) or pointerY * 0.7, Config.hover.response, step)
                local stretch = not reduced and Config.stretch.enabled and holding
                    and math.min(Config.stretch.maxAmount, math.sqrt(s.vx^2 + s.vy^2)
                        / Config.stretch.speedScale * Config.stretch.maxAmount) or 0
                s.stretch = smooth(s.stretch, stretch, Config.stretch.response, step)
                if s.settling and not holding and math.abs(s.x - s.targetX) + math.abs(s.y - s.targetY) < 0.4
                    and math.abs(s.vx) + math.abs(s.vy) < 4 and s.lift < 0.003
                    and math.abs(s.rotation - s.targetRotation) < 0.006 then s.settling = false end
                if not holding and not visible and math.abs(s.x - s.homeX) + math.abs(s.y - s.homeY) < 0.5
                    and math.abs(s.vx) + math.abs(s.vy) < 6
                    and math.abs(s.rotation) + math.abs(s.angularVelocity) < 0.002 and s.lift < 0.001 then
                    s.active = false
                end
            end
        end
        if not next(surfaces) then states[owner] = nil end
    end
end

function Physics.beginFrame(interactive)
    local g = love.graphics
    frame, enabled, canvas = frame + 1, interactive ~= false, g.getCanvas()
    registry, previousRegistry = previousRegistry, registry
    for i = #registry, 1, -1 do registry[i] = nil end
    root = root or {}
    root.x, root.y = g.transformPoint(0, 0)
    local x1, y1 = g.transformPoint(1, 0)
    local x2, y2 = g.transformPoint(0, 1)
    root.a, root.b, root.c, root.d = x1 - root.x, y1 - root.y, x2 - root.x, y2 - root.y
    if not enabled then Physics.release() end
end

local function saveMatrix(s, x, y)
    s.ox, s.oy = logicalPoint(x, y)
    local x1, y1 = logicalPoint(x + 1, y)
    local x2, y2 = logicalPoint(x, y + 1)
    s.a, s.b, s.c, s.d = x1 - s.ox, y1 - s.oy, x2 - s.ox, y2 - s.oy
end

function Physics.capture(card, x, y, w, h)
    -- Called AFTER the renderer's own rotation/shear/scale; shared with shader UV.
    if not root or love.graphics.getCanvas() ~= canvas then return end
    if current and current.w == w and current.h == h then saveMatrix(current, x, y) end
end

function Physics.shaderInput(w, h)
    if not root or love.graphics.getCanvas() ~= canvas then return end
    local px = root.a * mx + root.c * my + root.x
    local py = root.b * mx + root.d * my + root.y
    local lx, ly = love.graphics.inverseTransformPoint(px, py)
    local s = current
    return clamp(lx / math.max(1, w), 0, 1), clamp(ly / math.max(1, h), 0, 1),
        not Physics.reducedMotion and s and clamp(s.rotation / Config.rotation.maxAngle, -1, 1) or 0, not Physics.reducedMotion and s and s.tiltY or 0,
        s and s == held or false
end

-- Project the silhouette onto the table before applying the face's lift/scale.
function Physics.shadow(x, y, w, h, lift, hover, rotation, opacity)
    local strength = math.max(lift, hover * 0.45)
    if strength < 0.002 then return end
    local g, shadow = love.graphics, Config.shadow
    g.push("all")
    g.setShader()
    g.translate(x + w * Config.pivot.x + 3 + rotation * 12,
        y + h * Config.pivot.y + 4 + shadow.offset * strength)
    g.rotate(rotation * 0.8)
    local spread = 1 + lift * 0.025
    g.scale(spread, spread)
    for band = shadow.layers, 1, -1 do
        local blur = (1 + shadow.softness * strength) * band / shadow.layers
        g.setColor(0.005, 0.009, 0.017, shadow.alpha * strength * (opacity or 1) / shadow.layers)
        g.rectangle("fill", -w * Config.pivot.x - blur, -h * Config.pivot.y - blur,
            w + blur * 2, h + blur * 2, 5 + blur, 5 + blur)
    end
    g.pop()
end

local function apply(s)
    local g = love.graphics
    local reduced=Physics.reducedMotion
    local dx, dy = inverse(s.pa, s.pb, s.pc, s.pd, 0, 0, s.x - s.renderX, s.y - s.renderY)
    g.translate(dx, dy)
    local _, _, _, alpha = g.getColor()
    Physics.shadow(s.args[2], s.args[3], s.w, s.h, reduced and 0 or s.lift, reduced and 0 or s.hoverLift or 0,
        s.rotation, alpha * (s.args[1].alpha or 1))
    local x, y = s.args[2] + s.w * Config.pivot.x, s.args[3] + s.h * Config.pivot.y
    g.translate(x, y)
    local contact=not Physics.reducedMotion and s.contactAge and Motion.impact(s.contactAge,.28) or 0
    g.rotate(reduced and 0 or s.rotation+contact*.012)
    local scale = Physics.reducedMotion and 1 or 1 + (Config.pickup.scale - 1) * s.lift + (Config.hover.scale - 1) * (s.hoverLift or 0)
    local stretch=reduced and 0 or s.stretch
    g.scale(scale * (1 + stretch+contact*.025), scale * (1 - stretch * 0.5+contact*.018))
    g.shear(0, reduced and 0 or s.tiltY * Config.rotation.verticalShear)
    g.translate(-x, -y)
end

local function render(s)
    local g = love.graphics
    g.push("all")
    local red, green, blue, alpha = g.getColor()
    if s.active then apply(s); g.setColor(red, green, blue, alpha) end
    current, depth = s, depth + 1
    saveMatrix(s, s.args[2], s.args[3])
    s.draw(unpack(s.args, 1, s.argCount))
    depth, current = depth - 1, nil
    g.pop()
end

function Physics.wrap(draw, ownerSelector, hoverArg)
    local wrapper
    wrapper = function(owner, x, y, w, h, ...)
        local g = love.graphics
        if not root or depth > 0 or g.getCanvas() ~= canvas or type(owner) ~= "table"
            or type(w) ~= "number" or type(h) ~= "number" then
            return draw(owner, x, y, w, h, ...)
        end
        local identity = ownerSelector and ownerSelector(owner, x, y, w, h, ...) or owner
        local surfaces = states[identity]
        if not surfaces then surfaces = {}; states[identity] = surfaces end
        local key, s = wrapper, surfaces[wrapper]
        while s and s.frame == frame and not overlay do
            s.nextKey = s.nextKey or {}
            key, s = s.nextKey, surfaces[s.nextKey]
        end
        if not s then
            serial = serial + 1
            s = { args = {}, draw = draw, x = 0, y = 0, vx = 0, vy = 0, rotation = 0,
                angularVelocity = 0, lift = 0, stretch = 0, tiltY = 0, holdTime = 0, frame = 0, phase = serial * 2.399 }
            surfaces[key] = s
        end
        s.frame, s.w, s.h, s.attached = frame, w, h, nil
        s.args[1], s.args[2], s.args[3], s.args[4], s.args[5] = owner, x, y, w, h
        local n = select("#", ...)
        for i = 1, n do s.args[i + 5] = select(i, ...) end
        for i = n + 6, (s.argCount or #s.args) do s.args[i] = nil end
        s.argCount = n + 5
        local explicitHover = hoverArg and s.args[hoverArg]
        s.hovered = enabled and (s == held or explicitHover == true
            or (explicitHover == nil and contains and contains(s, mx, my))) or false
        if hoverArg then s.args[hoverArg] = s.hovered; s.argCount = math.max(s.argCount, hoverArg) end
        local homeX,homeY=logicalPoint(x,y)
        if s.homeX and s~=held and not s.settling and ((homeX-s.homeX)^2+(homeY-s.homeY)^2 > math.max(w,h)^2*4) then
            -- A new scene/slot must not drag an old idle pose across the screen.
            s.x,s.y=s.x+homeX-s.homeX,s.y+homeY-s.homeY
        end
        s.homeX,s.homeY=homeX,homeY
        s.renderX, s.renderY, s.detached = s.homeX, s.homeY, false
        local px, py = logicalPoint(0, 0)
        local x1, y1 = logicalPoint(1, 0)
        local x2, y2 = logicalPoint(0, 1)
        s.pa, s.pb, s.pc, s.pd, s.px, s.py = x1 - px, y1 - py, x2 - px, y2 - py, px, py
        if not s.active then s.x, s.y = s.homeX, s.homeY end
        local sx, sy, sw, sh = g.getScissor()
        s.clipX, s.clipY, s.clipW, s.clipH = sx, sy, sw, sh
        registry[#registry + 1] = s
        if not enabled or (s ~= held and not s.settling) then render(s) end
    end
    return wrapper
end

contains = function(s, x, y)
    if not s.a then return false end
    if s.clipX then
        local px, py = root.a * x + root.c * y + root.x, root.b * x + root.d * y + root.y
        if px < s.clipX or py < s.clipY or px > s.clipX + s.clipW or py > s.clipY + s.clipH then return false end
    end
    local lx, ly = inverse(s.a, s.b, s.c, s.d, s.ox, s.oy, x, y)
    return lx >= 0 and ly >= 0 and lx <= s.w and ly <= s.h
end

function Physics.hit(card, x, y, fallback)
    for i = #registry, 1, -1 do
        local s = registry[i]
        if s.args[1] == card then return contains(s, x, y) end
    end
    for i = #previousRegistry, 1, -1 do
        local s = previousRegistry[i]
        if s.args[1] == card then return contains(s, x, y) end
    end
    return fallback == true
end

function Physics.press(x, y, button)
    mx, my = x, y
    if button ~= 1 or not enabled then return end
    Physics.release()
    for i = #registry, 1, -1 do
        local s = registry[i]
        if contains(s, x, y) then
            held, lastCard = s, s
            s.active, s.held, s.dragging, s.holdTime, s.settling = true, true, false, 0, false
            s.grabX, s.grabY, s.pressX, s.pressY = x - s.x, y - s.y, x, y
            previousX, previousY, mouseVX, mouseVY = x, y, 0, 0
            return s.args[1]
        end
    end
end

function Physics.cardAt(x, y)
    for i = #registry, 1, -1 do
        if contains(registry[i], x, y) then return registry[i].args[1] end
    end
end

function Physics.release(x, y)
    if held then
        local dragging = held.dragging or (x and y and (x-held.pressX)^2+(y-held.pressY)^2 > Config.dragThreshold^2) or false
        held.settling = dragging or held.lift > 0.02
        held.held, held.dragging, lastCard = false, false, held
        held = nil
        return dragging
    end
    return false
end

function Physics.returnTo(x, y)
    -- A card pulled out of the closed deck viewer returns to the visible deck.
    if lastCard then
        lastCard.homeX, lastCard.homeY, lastCard.detached = x, y, true
    end
end

function Physics.blockBehind()
    for i = #registry, 1, -1 do registry[i] = nil end
    for i = #previousRegistry, 1, -1 do previousRegistry[i] = nil end
end

function Physics.isHeld(card) return held and held.args[1] == card or false end
function Physics.isHolding() return held ~= nil end
function Physics.isOverlay() return overlay end
function Physics.suspend() depth = depth + 1 end
function Physics.resume() depth = math.max(0, depth - 1) end

local function renderOverlay(s)
    -- Lifted/returning faces escape panel scissors in the root coordinate space.
    local g = love.graphics
    g.push("all")
    g.setScissor()
    local transform = Physics.overlayTransform
    if not transform then transform = love.math.newTransform(); Physics.overlayTransform = transform end
    transform:setMatrix("row", root.a * s.pa + root.c * s.pb, root.a * s.pc + root.c * s.pd, 0,
        root.a * s.px + root.c * s.py + root.x,
        root.b * s.pa + root.d * s.pb, root.b * s.pc + root.d * s.pd, 0,
        root.b * s.px + root.d * s.py + root.y,
        0, 0, 1, 0, 0, 0, 0, 1)
    g.replaceTransform(transform)
    overlay = true
    render(s)
    for _, draw in ipairs(s.attached or {}) do Physics.drawAttached(s.args[1], draw) end
    overlay = false
    g.pop()
end

function Physics.endFrame()
    if not enabled then return end
    if held and held.frame ~= frame and not held.detached then
        Physics.release()
        lastCard.settling = false
    end
    for _, s in ipairs(registry) do
        if s.settling and s ~= held then renderOverlay(s) end
    end
    local s = held or (lastCard and lastCard.detached and lastCard.active and lastCard)
    if s then renderOverlay(s) end
end

function Physics.getState(card)
    if held and held.args[1] == card then return held end
    for i = #registry, 1, -1 do
        if registry[i].args[1] == card then return registry[i] end
    end
    local surfaces = states[card]
    if surfaces then for _, s in pairs(surfaces) do if s.frame >= frame - 1 then return s end end end
end

function Physics.pulse(card)
    local s=Physics.getState(card)
    if s and not Physics.reducedMotion then s.active=true;s.contactAge=0 end
end

-- Late selection/evolution rims reuse the final face matrix, including renderer tilt.
function Physics.drawAttached(card, draw)
    if depth>0 or current or not root or love.graphics.getCanvas()~=canvas then return false end
    local s=Physics.getState(card)
    if not s or s.frame~=frame or not s.a then return false end
    if not overlay and (s == held or s.settling) then
        s.attached=s.attached or {};s.attached[#s.attached+1]=draw
        return true
    end
    local g=love.graphics
    s.rimTransform=s.rimTransform or love.math.newTransform()
    s.rimTransform:setMatrix("row",root.a*s.a+root.c*s.b,root.a*s.c+root.c*s.d,0,root.a*s.ox+root.c*s.oy+root.x,
        root.b*s.a+root.d*s.b,root.b*s.c+root.d*s.d,0,root.b*s.ox+root.d*s.oy+root.y,
        0,0,1,0,0,0,0,1)
    g.push("all");g.replaceTransform(s.rimTransform);draw(0,0,s.w,s.h);g.pop()
    return true
end

function Physics.drawDebug()
    if not debugEnabled then return end
    local s = held or lastCard
    local g = love.graphics
    g.push("all")
    g.setShader()
    g.setColor(0.025, 0.035, 0.05, 0.94)
    g.rectangle("fill", 14, 204, 355, 195, 7, 7)
    g.setColor(0.9, 0.95, 1)
    g.print("CARD PHYSICS [F9]  " .. Config.preset, 24, 214)
    if s then
        g.print(string.format("Held %s / drag %s   pivot %.2f, %.2f", tostring(s == held), tostring(s.dragging), Config.pivot.x, Config.pivot.y), 24, 237)
        g.print(string.format("Position %.1f, %.1f  target %.1f, %.1f", s.x, s.y, s.targetX or s.x, s.targetY or s.y), 24, 260)
        g.print(string.format("Velocity %.1f, %.1f  mouse %.1f, %.1f", s.vx, s.vy, mouseVX, mouseVY), 24, 283)
        g.print(string.format("Angle %.3f > %.3f  angular %.3f", s.rotation, s.targetRotation or 0, s.angularVelocity), 24, 306)
        g.print(string.format("Shader tilt %.2f, %.2f  stretch %.3f", s.rotation / Config.rotation.maxAngle, s.tiltY, s.stretch), 24, 329)
        g.setColor(1, 0.7, 0.2)
        g.circle("line", s.targetX or s.x, s.targetY or s.y, 5)
        g.line(s.x, s.y, s.targetX or s.x, s.targetY or s.y)
        g.setColor(0.3, 0.9, 1)
        g.line(s.x, s.y, s.x + s.vx * 0.06, s.y + s.vy * 0.06)
        local pivotX = s.ox + s.a * s.w * Config.pivot.x + s.c * s.h * Config.pivot.y
        local pivotY = s.oy + s.b * s.w * Config.pivot.x + s.d * s.h * Config.pivot.y
        g.circle("fill", pivotX, pivotY, 3)
    else g.print("Hold any card to inspect its spring.", 24, 260) end
    g.setColor(0.65, 0.73, 0.8)
    g.print("F10: Card Feel Lab", 24, 370)
    g.pop()
end

function Physics.isLabOpen() return lab end
function Physics.keypressed(key)
    if key == Config.debugKey then debugEnabled = not debugEnabled; return true end
    if key == Config.labKey then lab = not lab; Physics.release(); debugEnabled = lab; return true end
    if not lab then return false end
    if key == "escape" then lab = false; Physics.release(); return true end
    if key == "1" then Physics.setPreset("LIGHT") end
    if key == "2" then Physics.setPreset("MEDIUM") end
    if key == "3" then Physics.setPreset("HEAVY") end
    local p = Config.presets[Config.preset]
    if key == "q" then p.stiffness = p.stiffness + 30 end
    if key == "a" then p.stiffness = math.max(60, p.stiffness - 30) end
    if key == "w" then p.damping = p.damping + 1 end
    if key == "s" then p.damping = math.max(4, p.damping - 1) end
    if key == "e" then p.rotationStiffness = p.rotationStiffness + 10 end
    if key == "d" then p.rotationStiffness = math.max(30, p.rotationStiffness - 10) end
    if key == "r" then p.rotationDamping = p.rotationDamping + 1 end
    if key == "f" then p.rotationDamping = math.max(3, p.rotationDamping - 1) end
    if key == "t" then Config.input.velocityToTilt = Config.input.velocityToTilt + 0.00002 end
    if key == "g" then Config.input.velocityToTilt = math.max(0, Config.input.velocityToTilt - 0.00002) end
    if key == "y" then Config.rotation.maxAngle = math.min(0.5, Config.rotation.maxAngle + 0.01) end
    if key == "h" then Config.rotation.maxAngle = math.max(0.02, Config.rotation.maxAngle - 0.01) end
    if key == "u" then Config.sway.amplitude1 = math.min(0.015, Config.sway.amplitude1 + 0.001) end
    if key == "j" then Config.sway.amplitude1 = math.max(0, Config.sway.amplitude1 - 0.001) end
    return true
end

function Physics.drawLab(UI, CardEffects)
    if not lab then return end
    Physics.blockBehind()
    Physics.labCard = Physics.labCard or { suit = "spades", rank = 12, rankName = "Q" }
    local g = love.graphics
    g.setColor(0.025, 0.035, 0.055, 0.98)
    g.rectangle("fill", 0, 0, 1280, 720)
    g.setFont(UI.fonts.medium)
    g.setColor(0.85, 0.93, 1)
    g.print("CARD FEEL LAB [F10 / Esc]", 425, 55)
    g.setFont(UI.fonts.small)
    g.print("1 Light  /  2 Medium  /  3 Heavy     Space: normal > foil > holo > poly", 405, 100)
    UI.drawCard(Physics.labCard, 535, 175, 210, 310, false, Physics.hit(Physics.labCard, mx, my))
    g.print("Drag / release card.  F9 vectors.  P score pulse.", 425, 530)
    local p = Config.presets[Config.preset]
    g.print(string.format("Q/A stiffness %d   W/S damping %d   E/D rotation stiffness %d   R/F rotation damping %d", p.stiffness, p.damping, p.rotationStiffness, p.rotationDamping), 380, 570)
    g.print(string.format("T/G velocity tilt %.5f   Y/H angle %.2f   U/J sway %.3f", Config.input.velocityToTilt, Config.rotation.maxAngle, Config.sway.amplitude1), 425, 605)
end

function Physics.labAction(key, CardEffects)
    if not lab or not Physics.labCard then return end
    if key == "space" then
        local effects = { "foil", "holographic", "polychrome" }
        Physics.labEffect = ((Physics.labEffect or 0) + 1) % 4
        CardEffects.setEffect(Physics.labCard, effects[Physics.labEffect])
    elseif key == "p" then CardEffects.triggerScorePulse(Physics.labCard) end
end

return Physics
