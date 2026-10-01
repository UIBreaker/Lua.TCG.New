local Config = require("config.card_effect_config")
local CardPhysics = require("src.card_physics")
local Rng = require("src.rng")

local CardEffects = {}
CardEffects.debugToggleKey = Config.debugToggleKey
local shaders = {}
local elapsed = 0
local cardStates = setmetatable({}, { __mode = "k" })
local debugEnabled = false
local debugCard
local mouseUVUniform = { 0.5, 0.5 }
local tiltUniform = { 0, 0 }

local DEFAULT_BEAM = { 0.72, 0.88, 1.0 }

local function normalize(name)
    if type(name) == "string" then name = string.lower(name) end
    if name == "holo" then name = "holographic" end
    if Config.effects[name] then return name end
    return nil
end

local function stateFor(card, definition)
    local state = cardStates[card]
    if not state then
        state = {
            intensity = definition and definition.idleStrength or 0,
            hover = 0,
            selected = 0,
            scoreTimer = 0,
            scorePulse = 0,
            selectPulse = 0,
            mouseU = 0.5,
            mouseV = 0.5,
            tiltX = 0,
            tiltY = 0,
            strength = 1,
        }
        cardStates[card] = state
    end
    return state
end

function CardEffects.getEffectName(card)
    if not card then return nil end
    return normalize(card.visualEffect) or normalize(card.edition)
end

function CardEffects.getDefinition(name)
    local effectName = normalize(name)
    return effectName and Config.effects[effectName] or nil
end

function CardEffects.getEditionCatalog()
    local options = {}
    for _, effectName in ipairs(Config.rollOrder) do
        local definition = Config.effects[effectName]
        options[#options + 1] = {
            id = "edition_" .. effectName,
            category = "edition",
            edition = effectName,
            name = definition.shopLabel,
            subtitle = definition.shopLabel,
            desc = definition.shopText .. " Chọn một lá bài để áp dụng.",
            icon = effectName == "foil" and "✧" or (effectName == "holographic" and "✦" or "✺"),
            color = definition.beamColor,
        }
    end
    return options
end

function CardEffects.setEffect(card, name)
    if not card then return false end
    local effectName = normalize(name)
    if name ~= nil and not effectName then return false end
    card.edition = effectName
    card.visualEffect = nil
    if effectName then
        stateFor(card, Config.effects[effectName])
    else
        cardStates[card] = nil
    end
    return true
end

function CardEffects.setStrength(card, value)
    if not card then return end
    local effectName = CardEffects.getEffectName(card)
    local definition = effectName and Config.effects[effectName]
    if definition then
        stateFor(card, definition).strength = math.max(0, math.min(1.5, tonumber(value) or 1))
    end
end

function CardEffects.getScoreBonus(card)
    local effectName = CardEffects.getEffectName(card)
    local definition = effectName and Config.effects[effectName]
    return definition and definition.score or nil
end

function CardEffects.getBeamColor(card)
    local effectName = CardEffects.getEffectName(card)
    local definition = effectName and Config.effects[effectName]
    return (definition and definition.beamColor) or DEFAULT_BEAM
end

function CardEffects.rollCard(card)
    if not card or CardEffects.getEffectName(card) then return nil end
    local roll = Rng.random()
    local threshold = 0
    for _, effectName in ipairs(Config.rollOrder) do
        local definition = Config.effects[effectName]
        threshold = threshold + (definition.shopChance or 0)
        if roll < threshold then
            CardEffects.setEffect(card, effectName)
            return effectName
        end
    end
    return nil
end

function CardEffects.rollShopItem(item)
    if not item then return nil end
    local target = item.category == "card" and item.card
        or (item.category == "deity" and item.deity)
    local effectName = CardEffects.rollCard(target)
    if effectName then
        local definition = Config.effects[effectName]
        item.editionName = definition.shopLabel
        if item.category == "deity" then
            item.deity.edition = effectName
        end
        item.name = (item.name or "LÁ BÀI") .. " · " .. definition.shopLabel
        item.desc = (item.desc or "") .. "\n" .. definition.shopText
    end
    return effectName
end

function CardEffects.setInteraction(card, hovered, selected)
    local effectName = CardEffects.getEffectName(card)
    local definition = effectName and Config.effects[effectName]
    if not definition then return end
    local state = stateFor(card, definition)
    if hovered ~= nil then state.hoverTarget = hovered and 1 or 0 end
    if selected ~= nil then state.selectedTarget = selected and 1 or 0 end
    if hovered or selected then debugCard = card end
end

function CardEffects.load()
    if not (love and love.graphics and love.graphics.newShader and love.filesystem and love.filesystem.read) then
        return false, 0
    end

    local loadedCount = 0
    for effectName, definition in pairs(Config.effects) do
        local readOk, source = pcall(love.filesystem.read, definition.shader)
        if readOk and type(source) == "string" then
            local shaderOk, shader = pcall(love.graphics.newShader, source)
            if shaderOk then
                shaders[effectName] = shader
                loadedCount = loadedCount + 1
            else
                print("[CardEffects] Shader fallback for " .. effectName .. ": " .. tostring(shader))
            end
        else
            print("[CardEffects] Shader file unavailable for " .. effectName .. "; normal card rendering remains enabled.")
        end
    end

    return loadedCount == #Config.rollOrder, loadedCount
end

local function approach(current, target, dt)
    return current + (target - current) * (1 - math.exp(-Config.transitionSpeed * math.max(0, dt)))
end

function CardEffects.update(dt)
    elapsed = elapsed + dt
    for card, state in pairs(cardStates) do
        local effectName = CardEffects.getEffectName(card)
        local definition = effectName and Config.effects[effectName]
        if not definition then
            cardStates[card] = nil
        else
            state.scoreTimer = math.max(0, state.scoreTimer - dt)
            state.scorePulse = math.max(0, state.scorePulse - dt / Config.scorePulseDuration)
            state.selectPulse = math.max(0, state.selectPulse - dt / Config.selectPulseDuration)

            local hovered = state.hoverTarget
            if hovered == nil then hovered = card.hovered and 1 or 0 end
            local selected = state.selectedTarget
            if selected == nil then selected = card.selected and 1 or 0 end

            local targetIntensity = definition.idleStrength
            if state.scoreTimer > 0 then
                targetIntensity = definition.scoringStrength
            elseif selected > 0.5 then
                targetIntensity = definition.selectedStrength
            elseif hovered > 0.5 then
                targetIntensity = definition.hoverStrength
            end
            targetIntensity = targetIntensity * state.strength
            state.intensity = approach(state.intensity, targetIntensity, dt)
            state.hover = approach(state.hover, hovered, dt)
            state.selected = approach(state.selected, selected, dt)

            local targetTiltX = (state.mouseU - 0.5) * 2 * state.hover
            local targetTiltY = (state.mouseV - 0.5) * 2 * state.hover
            state.tiltX = approach(state.tiltX, targetTiltX, dt)
            state.tiltY = approach(state.tiltY, targetTiltY, dt)
        end
    end
end

function CardEffects.triggerScorePulse(card)
    if not card or not CardEffects.getEffectName(card) then return end
    local effectName = CardEffects.getEffectName(card)
    local state = stateFor(card, Config.effects[effectName])
    state.scoreTimer = Config.scoreStateDuration
    state.scorePulse = 1
end

function CardEffects.triggerSelectPulse(card)
    if not card or not CardEffects.getEffectName(card) then return end
    local effectName = CardEffects.getEffectName(card)
    stateFor(card, Config.effects[effectName]).selectPulse = 1
end

function CardEffects.getTilt(card)
    local state = card and cardStates[card]
    return state and state.tiltX * Config.tiltShear or 0,
        state and state.tiltY * Config.tiltShear * Config.tiltVerticalScale or 0
end

-- Invert UI.drawCard's translate/rotate/shear/scale transform to feed the shader
-- a real local-space cursor position, including card fan rotation and scaling.
function CardEffects.prepareDraw(card, x, y, w, h, shearX, shearY, scaleX, scaleY, mx, my)
    local effectName = CardEffects.getEffectName(card)
    if not effectName then return end
    local state = stateFor(card, Config.effects[effectName])

    state.drawW, state.drawH = w, h
    if not mx or not my then
        mx, my = 0, 0
    end
    local dx, dy = mx - (x + w * 0.5), my - (y + h * 0.5)
    local rotation = card.rotation or 0
    local cosine, sine = math.cos(rotation), math.sin(rotation)
    local rx, ry = cosine * dx + sine * dy, -sine * dx + cosine * dy
    local determinant = 1 - shearX * shearY
    if math.abs(determinant) < 0.001 then determinant = 1 end
    local unShearedX = (rx - shearX * ry) / determinant
    local unShearedY = (ry - shearY * rx) / determinant
    local localX = unShearedX / (math.abs(scaleX) > 0.001 and scaleX or 1) + w * 0.5
    local localY = unShearedY / (math.abs(scaleY) > 0.001 and scaleY or 1) + h * 0.5
    state.mouseU = math.max(0, math.min(1, localX / math.max(1, w)))
    state.mouseV = math.max(0, math.min(1, localY / math.max(1, h)))
    local state = cardStates[card]
    if card.hovered or card.selected or (state and (state.hoverTarget or 0) > 0) then debugCard = card end
end

local function sendUniform(shader, name, ...)
    if shader:hasUniform(name) then shader:send(name, ...) end
end

function CardEffects.beginCard(card)
    local effectName = CardEffects.getEffectName(card)
    local shader = effectName and shaders[effectName]
    if not shader then return false end

    local g = love.graphics
    local state = stateFor(card, Config.effects[effectName])
    g.push("all")
    local u, v, physicalX, physicalY, held
    -- Dimensions are recorded by the card renderer, not inferred from its PNG.
    if state.drawW and state.drawH then
        u, v, physicalX, physicalY, held = CardPhysics.shaderInput(state.drawW, state.drawH)
        if u then state.mouseU, state.mouseV = u, v end
    end
    if held then state.hoverTarget = 1 end
    g.setShader(shader)
    sendUniform(shader, "u_time", elapsed)
    sendUniform(shader, "u_intensity", state.intensity)
    sendUniform(shader, "u_speed", Config.effects[effectName].speed or 0.5)
    mouseUVUniform[1], mouseUVUniform[2] = state.mouseU, state.mouseV
    tiltUniform[1], tiltUniform[2] = math.max(-1, math.min(1, state.tiltX + (physicalX or 0))),
        math.max(-1, math.min(1, state.tiltY + (physicalY or 0)))
    sendUniform(shader, "u_mouseUV", mouseUVUniform)
    sendUniform(shader, "u_tilt", tiltUniform)
    sendUniform(shader, "u_hoverAmount", state.hover)
    sendUniform(shader, "u_selectedAmount", state.selected)
    sendUniform(shader, "u_scorePulse", state.scorePulse)
    sendUniform(shader, "u_selectPulse", state.selectPulse)
    return true
end

function CardEffects.endCard(active)
    if not active then return end
    love.graphics.pop()
end

function CardEffects.setDebugEnabled(enabled)
    debugEnabled = enabled == true
end

function CardEffects.toggleDebug()
    debugEnabled = not debugEnabled
    return debugEnabled
end

function CardEffects.drawDebug()
    if not debugEnabled then return end
    local card = debugCard
    local effectName = CardEffects.getEffectName(card) or "NONE"
    local state = card and cardStates[card]
    local g = love.graphics
    g.push("all")
    g.setColor(0.025, 0.045, 0.06, 0.94)
    g.rectangle("fill", 10, 78, 245, 112, 7, 7)
    g.setColor(0.35, 0.72, 0.9, 1)
    g.rectangle("line", 10, 78, 245, 112, 7, 7)
    g.setColor(0.9, 0.94, 1, 1)
    g.print("CARD FX  [F7]", 20, 88)
    g.print("Effect: " .. tostring(effectName):upper(), 20, 108)
    g.print(string.format("Intensity %.2f  •  UV %.2f, %.2f", state and state.intensity or 0,
        state and state.mouseU or 0.5, state and state.mouseV or 0.5), 20, 128)
    g.print(string.format("Tilt %.2f, %.2f  •  Pulse %.2f", state and state.tiltX or 0,
        state and state.tiltY or 0, state and state.scorePulse or 0), 20, 148)
    g.print("FPS " .. tostring(love.timer.getFPS()), 20, 168)
    g.pop()
end

return CardEffects
