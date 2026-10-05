-- Translate one finger into the established mouse router; ignore SDL's duplicate mouse events.
local T = { enabled = false, reorder = false, holdSeconds = 0.5 }
local osName = love and love.system and love.system.getOS()
T.nativeMobile = osName == "Android" or osName == "iOS"
T.fillScreen = T.nativeMobile
T.lowPower = T.nativeMobile
    or not not (love and love.filesystem and love.filesystem.getInfo("mobile_build.flag"))
for _, value in ipairs(arg or {}) do
    if value == "--capture-mobile-fullscreen" then T.fillScreen, T.lowPower, T.previewMobile = true, true, true end
end
local finger, hooks, mousePosition

function T.install(callbacks)
    hooks = callbacks
    mousePosition = love.mouse.getPosition
    love.mouse.getPosition = function()
        if T.enabled and T.x then
            if finger then return T.x, T.y end
            return -1000, -1000 -- A lifted finger must not leave a permanent hover.
        end
        return mousePosition()
    end
end

function T.mouseInput()
    if not finger then T.enabled = false end
end

function T.press(id, x, y)
    if finger then return end
    T.enabled, T.x, T.y = true, x, y
    finger = { id=id, x=x, y=y, originX=x, originY=y, age=0 }
end

function T.move(id, x, y)
    if not finger or finger.id ~= id or finger.held then return end
    local dx, dy = x-finger.x, y-finger.y
    T.x, T.y = x, y
    local distance = (x-finger.originX)^2 + (y-finger.originY)^2
    if not finger.dragging and distance > 12^2 then
        finger.dragging = true
        finger.scrolling = hooks.canScroll and hooks.canScroll(dx,dy)
        if not finger.scrolling then
            T.x, T.y = finger.originX, finger.originY
            hooks.press(T.x, T.y, 1)
            T.x, T.y = x, y
        end
    end
    if finger.dragging then
        if finger.scrolling then hooks.scroll(dy)
        else hooks.move(x,y,dx,dy) end
    end
    finger.x, finger.y = x, y
end

function T.release(id, x, y)
    if not finger or finger.id ~= id then return end
    T.x, T.y = x, y
    local current = finger
    if current.held or current.scrolling then finger = nil; return end
    if not current.dragging then
        T.x, T.y = current.originX, current.originY
        hooks.press(T.x,T.y,1)
        T.x, T.y = x, y
    end
    hooks.release(x,y,1)
    finger = nil
end

function T.update(dt)
    if not finger or finger.dragging or finger.held then return end
    finger.age = finger.age + dt
    if finger.age >= T.holdSeconds then
        finger.held = true
        hooks.press(finger.x,finger.y,2)
        hooks.release(finger.x,finger.y,2)
    end
end

function T.cancel()
    finger = nil
    if hooks and hooks.cancel then hooks.cancel() end
end

return T
