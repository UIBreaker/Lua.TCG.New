-- Consumes the calculator's existing log. No score formula or gameplay mutations here.
local Feel = { config = require("config.scoring_feel_config"), debug = false, labOpen = false }
local Effects = require("src.card_effects")
local Sound = require("src.sound")
local C = Feel.config
local clamp = function(v, a, b) return math.max(a, math.min(b, v)) end
local ease = function(t) return 1 - (1 - clamp(t, 0, 1)) ^ 3 end
local categories = { card_scored = "LÁ BÀI", deity_card = "SPN", deity_hand = "SPN",
    deity_edition = "ẤN BẢN SPN", equipment_trigger = "TRANG BỊ KHẢM", enhancement_trigger = "CƯỜNG HÓA BÀI",
    seal_trigger = "CON DẤU", card_edition = "ẤN BẢN", discard_buff_trigger = "CHIẾN THUẬT BỎ BÀI" }

function Feel.intensity(aura)
    return clamp(math.log(math.max(0, aura or 0) + 1) / math.log(10) / C.aura.expectedMagnitude, 0, 1)
end

local function append(q, kind, duration, source, index)
    q[#q + 1] = {kind = kind, duration = duration, source = source, sourceIndex = index}
end

function Feel.start(anim, result, ui, deities, initialHp)
    local q, t = {}, C.timing
    append(q, "ENTRY", t.lift + t.travel + math.max(0, #anim.playedCards - 1) * t.stagger)
    local base = result.steps[1]
    append(q, "HAND_REVEAL", t.hand, base, 1)
    append(q, "BASE_DAMAGE", t.base, base, 1)
    append(q, "BASE_ENHANCE", t.base, base, 1)
    for i = 2, #result.steps do
        local st = result.steps[i]
        if st.type ~= "final_score" then
            if st.type == "card_scored" then
                -- These contributions are already in addedChips/addedMult. Split only their presentation.
                local core = {}
                for k, v in pairs(st) do core[k] = v end
                core.addedChips, core.addedMult = st.addedChips or 0, st.addedMult or 0
                core.addedDamage, core.auraMultiplier = st.addedDamage or 0, st.auraMultiplier or 1
                for _, child in ipairs(st.presentationTriggers or {}) do
                    core.addedChips = core.addedChips - (child.addedChips or 0)
                    core.addedMult = core.addedMult - (child.addedMult or 0)
                    core.addedDamage = core.addedDamage - (child.addedDamage or 0)
                    core.auraMultiplier = core.auraMultiplier / (child.auraMultiplier or 1)
                end
                append(q, "TRIGGER", t.card + t.gap, core, i)
                for _, child in ipairs(st.presentationTriggers or {}) do
                    append(q, "TRIGGER", (child.slotIndex and t.spn or t.modifier) + t.gap, child, i)
                end
            else
                append(q, "TRIGGER", (st.slotIndex and t.spn or t.modifier) + t.gap, st, i)
            end
        end
    end
    local intensity = Feel.intensity(result.finalScore)
    append(q, "FORMULA", t.formula, result.steps[#result.steps], #result.steps)
    append(q, "AURA_COUNT", t.countMin + (t.countMax - t.countMin) * intensity)
    append(q, "AURA_PEAK", t.peak)
    append(q, "ENERGY_CONVERSION", t.conversion)
    if result.finalScore >= C.aura.convergenceThreshold then append(q, "CONVERGENCE", t.convergence) end
    append(q, "ANTICIPATION", t.releaseMin + (t.releaseMax - t.releaseMin) * intensity)
    append(q, "ATTACK", t.beam)
    append(q, "ENEMY_IMPACT", t.impact, result.steps[#result.steps], #result.steps)
    append(q, "SETTLE", t.settle)
    anim.sequence = {events = q, index = 1, age = 0, time = 0, entered = false, finished = false,
        intensity = intensity, result = result, ui = ui, deities = deities or {},
        hp = initialHp or 0, hpTrail = initialHp or 0, hpBefore = initialHp or 0,
        cameraAge = C.timing.camera, damageApplied = false, energy = {}, links = {},
        high = result.finalScore >= C.aura.convergenceThreshold, tickAge = 0, milestone = 1000}
    anim.displayChips, anim.displayMult, anim.displayFinalScore, anim.displayAura = 0, 0, 0, 0
    anim.displayXMult, anim.displayAuraEditionMultiplier, anim.displayFlatDamage = 1, 1, 0
    anim.currentStepIndex, anim.entranceTimer = 0, 0
    anim.stepCategory, anim.stepLog = "CHUẨN BỊ", "Đưa bài vào vùng tính điểm"
    anim.cardTransform, anim.energyBolts = {}, {}
    return anim.sequence
end

local function play(s, name, boost)
    s.pitchStep = (s.pitchStep or 0) + 1
    Sound.play(C.audio[name] or name, clamp(C.audio.minPitch + s.pitchStep * C.audio.pitchStep + (boost or 0),
        C.audio.minPitch, C.audio.maxPitch))
end

local function sourcePoint(anim, st)
    local s, ui = anim.sequence, anim.sequence.ui
    if st.slotIndex then
        local x, y, w, h = ui.getDeitySlotRect(st.slotIndex, "playing")
        return x + w / 2, y + h / 2
    end
    for i, card in ipairs(anim.playedCards) do
        if st.card == card then return ui.getScoringCardX(i, #anim.playedCards) + 48, 355, i end
    end
    return ui.BATTLE_CENTER_X, 445
end

local function link(s, value, label, x, y, tx, ty, color)
    if value == 0 then return end
    s.links[#s.links + 1] = {text = (value > 0 and "+" or "") .. s.ui.formatNumber(value) .. " " .. label,
        x = x, y = y, tx = tx, ty = ty, age = 0, duration = 0.55, color = color}
end

local function trigger(anim, st)
    local s = anim.sequence
    local x, y, cardIndex = sourcePoint(anim, st)
    anim.activeCardIndex = cardIndex
    if st.slotIndex then
        anim.deityBounce[st.slotIndex] = C.pulse.spn
        Effects.triggerScorePulse(st.deity or s.deities[st.slotIndex])
    elseif cardIndex then
        anim.cardBounce[cardIndex] = {scaleX = C.pulse.cardX, scaleY = C.pulse.cardY}
        anim.cardHit[cardIndex] = 0
        Effects.triggerScorePulse(st.card)
        if st.type == "card_scored" then anim.scoredCards[cardIndex] = st end
    end
    local beforeChips, beforeMult = anim.displayChips, anim.displayMult
    s.fromChips, s.fromMult = beforeChips, beforeMult
    s.toChips = st.resultingChips or (beforeChips + (st.addedChips or 0))
    s.toMult = st.resultingMult or ((beforeMult + (st.addedMult or 0)) * (st.type == "deity_hand" and (st.xMult or 1) or 1))
    anim.displayFlatDamage = anim.displayFlatDamage + (st.addedDamage or st.addFlatDamage or 0)
    anim.displayAuraEditionMultiplier = anim.displayAuraEditionMultiplier * (st.auraMultiplier or 1)
    -- Card XMult is additive and capped by the calculator; hand SPN XMult is already in resultingMult.
    local beforeX = anim.displayXMult
    if st.cardXMultTotal then anim.displayXMult = st.cardXMultTotal end
    s.multiply = (st.xMult or 1) > 1 or (st.auraMultiplier or 1) > 1 or anim.displayXMult > beforeX
    anim.bounceScale.chips = s.toChips ~= beforeChips and C.pulse.damage or 1
    anim.bounceScale.mult = s.toMult ~= beforeMult and (s.multiply and C.pulse.multiply or C.pulse.enhance) or 1
    link(s, st.addedChips or 0, "ST", x, y - 28, 70, 197, C.color.damage)
    link(s, st.addedMult or 0, "C.H", x, y - 8, 176, 197, C.color.enhance)
    link(s, st.addedDamage or st.addFlatDamage or 0, "ST CỐ ĐỊNH", x, y - 28, 126, 292, C.color.aura)
    if s.multiply then
        local factor = st.auraMultiplier or st.xMult or anim.displayXMult
        s.links[#s.links + 1] = {text = "×" .. string.format("%.2f",factor)
            .. ((st.auraMultiplier or st.cardXMultTotal) and " AURA" or " CƯỜNG HÓA"), x = x, y = y - 28,
            tx = st.auraMultiplier and 126 or 176, ty = st.auraMultiplier and 292 or 197,
            age = 0, duration = 0.60, color = C.color.aura, multiply = true}
    end
    anim.stepCategory = categories[st.type] or "HIỆU ỨNG"
    anim.stepLog = s.ui.localizeText(st.message or st.deityName or anim.stepCategory)
    if st.type == "card_scored" then
        anim.stepLog = (st.card.rankName or "") .. (st.card.suitSymbol or "") .. ": +"
            .. s.ui.formatNumber(st.addedChips or 0) .. " Sát thương / +"
            .. s.ui.formatNumber(st.addedMult or 0) .. " Cường hóa"
    end
    play(s, s.multiply and "multiply" or (s.toMult ~= beforeMult and "enhance" or "damage"))
end

local function enter(anim, ev)
    local s, t = anim.sequence, C.timing
    if ev.sourceIndex then anim.currentStepIndex = ev.sourceIndex end
    s.multiply = false
    if ev.kind == "HAND_REVEAL" then
        anim.stepCategory, anim.stepLog = "THẾ ĐÁNH", ev.source.vnName
        s.handName = ev.source.vnName
        play(s, "hand")
    elseif ev.kind == "BASE_DAMAGE" then
        s.fromChips, s.toChips = 0, ev.source.chips
        s.fromMult, s.toMult = 0, 0
        anim.bounceScale.chips = C.pulse.damage
        anim.stepCategory, anim.stepLog = "SÁT THƯƠNG GỐC", tostring(ev.source.chips) .. " Sát thương"
        link(s, ev.source.chips, "ST", 78, 223, 78, 197, C.color.damage)
        play(s, "damage")
    elseif ev.kind == "BASE_ENHANCE" then
        s.fromChips, s.toChips = ev.source.chips, ev.source.chips
        s.fromMult, s.toMult = 0, ev.source.mult
        anim.bounceScale.mult = C.pulse.enhance
        anim.stepCategory, anim.stepLog = "CƯỜNG HÓA GỐC", tostring(ev.source.mult) .. " Cường hóa"
        link(s, ev.source.mult, "C.H", 176, 223, 176, 197, C.color.enhance)
        play(s, "enhance")
    elseif ev.kind == "TRIGGER" then trigger(anim, ev.source)
    elseif ev.kind == "FORMULA" then
        anim.activeCardIndex = nil
        -- Authoritative final snapshots, including every cap/rounding/extra-damage conversion.
        s.fromChips, s.fromMult = anim.displayChips, anim.displayMult
        s.toChips, s.toMult = s.result.totalChips, s.result.totalMult
        anim.displayXMult = s.result.cardXMultTotal or 1
        anim.displayAuraEditionMultiplier = s.result.auraEditionMultiplier or 1
        anim.displayFlatDamage = s.result.flatDamageBonus or 0
        anim.displayFinalScore = s.result.finalScore
        anim.stepCategory, anim.stepLog = "HÌNH THÀNH AURA", Feel.formula(s)
    elseif ev.kind == "AURA_COUNT" then
        anim.stepCategory = "AURA TĂNG DẦN"
    elseif ev.kind == "AURA_PEAK" then
        anim.displayAura = s.result.finalScore
        anim.bounceScale.score = 1.08 + (C.aura.maxScale - 1.08) * s.intensity
        anim.stepCategory = "AURA ĐẠT ĐỈNH"
        play(s, "peak", -0.04)
        for _, card in ipairs(anim.playedCards) do Effects.triggerScorePulse(card) end
    elseif ev.kind == "ENERGY_CONVERSION" then
        anim.stepCategory, anim.stepLog = "CHUYỂN HÓA NĂNG LƯỢNG", "Bài chuyển thành năng lượng"
        s.coreColor = {0,0,0,1}
        for i, card in ipairs(anim.playedCards) do
            anim.cardTransform[i] = 0
            s.energy[i] = {x = s.ui.getScoringCardX(i, #anim.playedCards) + 48, y = 365,
                color = Effects.getBeamColor(card)}
            for channel=1,3 do s.coreColor[channel] = s.coreColor[channel] + s.energy[i].color[channel]/#anim.playedCards end
            Effects.triggerScorePulse(card)
        end
        play(s, "charge")
    elseif ev.kind == "CONVERGENCE" then anim.stepCategory = "HỘI TỤ NĂNG LƯỢNG"
    elseif ev.kind == "ANTICIPATION" then anim.stepCategory = "TÍCH NĂNG"
    elseif ev.kind == "ATTACK" then
        anim.stepCategory, anim.stepLog = "PHÓNG NĂNG LƯỢNG", "Năng lượng lao vào quái"
        play(s, "release")
    elseif ev.kind == "ENEMY_IMPACT" then
        s.cameraAge = 0
        anim.hitStop = C.impact.minHitStop + (C.impact.maxHitStop - C.impact.minHitStop) * s.intensity
        anim.screenFlash = 0.035 + 0.055 * s.intensity
        anim.screenDistortion = s.intensity >= 0.66 and 0.10 or 0
        anim.stepCategory, anim.stepLog = "ĐÁNH TRÚNG", "Năng lượng chạm quái"
        play(s, s.high and "heavyImpact" or "impact")
    elseif ev.kind == "SETTLE" then anim.stepCategory = "ỔN ĐỊNH" end
end

function Feel.formula(s)
    local r, fmt = s.result, s.ui.formatNumber
    local text = fmt(r.totalChips) .. " × " .. fmt(r.totalMult)
    if (r.cardXMultTotal or 1) ~= 1 then text = text .. " × " .. string.format("%.2f", r.cardXMultTotal) end
    -- Keep both floors used by Scoring.calculate (rawScore, then converted score).
    text = text .. " → " .. fmt(r.rawScore) .. " AURA gốc"
    if (r.totalExtraDamagePct or 0) ~= 0 then text = text .. " × " .. string.format("%.2f", 1 + r.totalExtraDamagePct) end
    if (r.auraEditionMultiplier or 1) ~= 1 then text = text .. " × " .. string.format("%.2f", r.auraEditionMultiplier) end
    if (r.flatDamageBonus or 0) ~= 0 then text = text .. " + " .. fmt(r.flatDamageBonus) .. " ST cố định" end
    return text .. " = " .. fmt(r.finalScore)
end

function Feel.skipOrFastForward(anim)
    if anim.sequence then anim.sequence.forward = true end
end

function Feel.isFinished(anim) return anim.sequence and anim.sequence.finished end

function Feel.update(anim, dt, fast)
    local s = anim.sequence
    if not s or s.finished then return end
    local speed = s.forward and C.speed.forward or (fast and C.speed.fast or C.speed.normal)
    dt = clamp(dt, 0, C.maxFrameDt) * speed
    s.time = s.time + dt
    s.cameraAge = math.min(C.timing.camera, s.cameraAge + dt)
    for i = #s.links, 1, -1 do
        local p = s.links[i]
        p.age = p.age + dt
        if p.age >= p.duration then table.remove(s.links, i) end
    end
    if s.damageApplied then
        s.hpAge = s.hpAge + dt
        s.hp = s.hpBefore + (s.hpTarget - s.hpBefore) * ease(s.hpAge / C.timing.hp)
        s.hpTrail = s.hpBefore + (s.hpTarget - s.hpBefore) * ease((s.hpAge - C.timing.trailDelay) / C.timing.trail)
    end
    while not s.finished do
        local ev = s.events[s.index]
        if not s.entered then
            enter(anim, ev)
            s.entered = true
            if ev.kind == "ENEMY_IMPACT" and not s.impactDispatched then
                s.impactDispatched = true
                -- Yield to existing gameplay damage/reward/counterattack handler exactly once.
                return ev.source
            end
        end
        local consumed = math.min(dt, math.max(0, ev.duration - s.age))
        s.age, dt = s.age + consumed, dt - consumed
        local p = clamp(s.age / ev.duration, 0, 1)
        if ev.kind == "ENTRY" then anim.entranceTimer = s.age
        elseif ev.kind == "BASE_DAMAGE" or ev.kind == "BASE_ENHANCE" or ev.kind == "TRIGGER" or ev.kind == "FORMULA" then
            local wait = s.multiply and C.timing.multiplyAnticipation or 0
            local k = ease((s.age - wait) / math.max(0.01, ev.duration - C.timing.gap - wait))
            anim.displayChips = s.fromChips + (s.toChips - s.fromChips) * k
            anim.displayMult = s.fromMult + (s.toMult - s.fromMult) * k
        elseif ev.kind == "AURA_COUNT" then
            anim.displayAura = s.result.finalScore * ease(p)
            anim.bounceScale.score = 1 + s.intensity * 0.12 * math.sin(p * math.pi)
            s.tickAge = s.tickAge + consumed
            if s.tickAge >= 0.065 then s.tickAge = s.tickAge % 0.065; play(s, "count", p * 0.05) end
            if anim.displayAura >= s.milestone then
                anim.bounceScale.score = 1.08 + s.intensity * 0.10
                repeat s.milestone = s.milestone * 10 until anim.displayAura < s.milestone
            end
        elseif ev.kind == "ENERGY_CONVERSION" then
            for i in ipairs(anim.playedCards) do anim.cardTransform[i] = p * 0.42 end
        end
        if s.age < ev.duration then break end
        if ev.kind == "TRIGGER" or ev.kind == "BASE_DAMAGE" or ev.kind == "BASE_ENHANCE" or ev.kind == "FORMULA" then
            anim.displayChips, anim.displayMult = s.toChips, s.toMult
        end
        s.index, s.age, s.entered = s.index + 1, 0, false
        if s.index > #s.events then s.finished = true; anim.currentStepIndex = #s.result.steps + 1; break end
        if dt <= 0 then break end
    end
end

function Feel.damageApplied(anim, hp, actualDamage)
    local s = anim.sequence
    if not s or s.damageApplied then return end
    s.damageApplied, s.hpAge, s.hpTarget, s.actualDamage = true, 0, math.max(0, hp), actualDamage
    anim.damageDealt = actualDamage
    anim.floatingTexts[#anim.floatingTexts + 1] = {text = "−" .. s.ui.formatNumber(actualDamage) .. " HP",
        color = C.color.enhance, x = s.ui.BATTLE_CENTER_X, y = 214, alpha = 1.5,
        scale = 1.05 + 0.27 * s.intensity}
end

function Feel.camera(anim)
    local s = anim.sequence
    if not s then return 0, 0 end
    local p = clamp(s.cameraAge / C.timing.camera, 0, 1)
    local amount = C.impact.minKick + (C.impact.maxKick - C.impact.minKick) * s.intensity
    local decay = (1 - p)^3
    -- Beam travels upwards, so the initial camera kick is directional rather than random.
    return math.sin(p * 30) * amount * 0.30 * decay, (-amount + math.sin(p * 36) * amount * 0.45) * decay
end

function Feel.enemyReaction(anim)
    local s = anim.sequence
    if not s then return 0, 1, 0 end
    local p = clamp(s.cameraAge / C.timing.camera, 0, 1)
    local hit = (1 - p)^2
    return -C.impact.maxKnockback * s.intensity * math.sin(p * math.pi),
        1 + math.sin(p * math.pi) * 0.05 * s.intensity, hit
end

function Feel.draw(anim, ui)
    local s = anim.sequence
    if not s then return end
    local ev = s.events[s.index]
    if not ev then return end
    local g, p, cx = love.graphics, clamp(s.age / ev.duration, 0, 1), ui.BATTLE_CENTER_X
    g.push("all")
    if ev.kind == "HAND_REVEAL" then
        g.setFont(ui.fonts.medium)
        g.translate(cx, 446)
        g.scale(0.88 + 0.12 * ease(p) + math.sin(p * math.pi) * 0.07)
        g.setColor(C.color.aura[1], C.color.aura[2], C.color.aura[3], 1)
        g.printf(s.handName, -210, 0, 420, "center")
    end
    g.pop()
    g.push("all")
    for _, l in ipairs(s.links) do
        local k = ease(l.age / l.duration)
        local x, y = l.x + (l.tx - l.x) * k, l.y + (l.ty - l.y) * k - math.sin(k * math.pi) * 24
        g.setColor(l.color[1], l.color[2], l.color[3], 1 - k * k)
        g.setFont(l.multiply and ui.fonts.medium or ui.fonts.small)
        g.printf(l.text, x - 125, y - 12, 250, "center")
    end
    local phase = ev.kind
    local energyPhase = phase == "ENERGY_CONVERSION" or phase == "CONVERGENCE" or phase == "ANTICIPATION" or phase == "ATTACK"
    if energyPhase then
        local coreX, coreY = cx, 350
        g.setBlendMode("add")
        for i, source in ipairs(s.energy) do
            local targetX, targetY = s.high and coreX or cx, s.high and coreY or 270
            local travel = phase == "ENERGY_CONVERSION" and 0 or (phase == "CONVERGENCE" and ease(p) or 1)
            if not s.high then travel = phase == "ATTACK" and ease(clamp((p - (i - 1) * 0.025) / 0.90, 0, 1)) or 0 end
            for shard = 1, 6 do
                local ox = math.cos(shard * 2.37 + s.time * 6) * 14 * (1 - travel)
                local oy = math.sin(shard * 2.37 + s.time * 6) * 12 * (1 - travel)
                local x = source.x + (targetX - source.x) * travel + ox
                local y = source.y + (targetY - source.y) * travel + oy
                g.setColor(source.color[1], source.color[2], source.color[3], 0.65)
                g.setLineWidth(1 + 1.8 * s.intensity)
                g.line(x, y, x - (targetX - source.x) * 0.12 * travel, y - (targetY - source.y) * 0.12 * travel + 5)
                g.circle("fill", x, y, 1.7 + 1.3 * s.intensity)
            end
        end
        if s.high and phase ~= "ENERGY_CONVERSION" then
            local charge = phase == "ANTICIPATION" and (1 - p * 0.3) or 1
            local radius = (7 + 13 * s.intensity) * charge
            local col = s.coreColor or C.color.aura
            g.setColor(col[1], col[2], col[3], 0.16)
            g.circle("fill", coreX, coreY, radius * 1.65)
            g.setColor(col[1], col[2], col[3], 0.8)
            g.circle("line", coreX, coreY, radius + math.sin(s.time * 24) * 2)
            g.setColor(1, 0.93, 0.78, 0.8)
            g.circle("fill", coreX, coreY, radius * 0.43)
            if phase == "ATTACK" then
                local y = coreY + (270 - coreY) * ease(p)
                g.setColor(col[1], col[2], col[3], 0.36)
                g.setLineWidth(6 + 16 * s.intensity)
                g.line(coreX, coreY, cx, y)
                g.setColor(1, 0.96, 0.86, 0.95)
                g.setLineWidth(2 + 5 * s.intensity)
                g.line(coreX, coreY, cx, y)
                g.circle("fill", cx, y, radius * 0.35)
            end
        end
    end
    if s.cameraAge < C.timing.camera and s.impactDispatched then
        local k = s.cameraAge / C.timing.camera
        g.setBlendMode("add")
        g.setColor(1, 0.83, 0.48, (1 - k) * 0.6)
        g.setLineWidth(2)
        g.circle("line", cx, 270, 8 + k * (28 + 55 * s.intensity))
        if s.high then g.circle("line", cx, 270, 16 + k * 105) end
    end
    g.pop()
end

function Feel.drawDim(anim)
    local s = anim.sequence
    if not s or not s.high or s.finished then return end
    local ev = s.events[s.index]
    if ev and (ev.kind == "AURA_COUNT" or ev.kind == "AURA_PEAK" or ev.kind == "ENERGY_CONVERSION"
        or ev.kind == "CONVERGENCE" or ev.kind == "ANTICIPATION") then
        love.graphics.setColor(0.01, 0.025, 0.04, 0.10 * s.intensity)
        love.graphics.rectangle("fill", 242, 145, 780, 440)
    end
end

function Feel.drawDebug(anim, ui)
    local s = anim.sequence
    if not Feel.debug or not s then return end
    local g = love.graphics
    g.push("all")
    g.setColor(0.02, 0.03, 0.05, 0.94); g.rectangle("fill", 290, 600, 550, 100, 6)
    g.setColor(1, 1, 1, 1); g.setFont(ui.fonts.small)
    local event = s.events[s.index]
    g.print(string.format("%s | %d/%d | %.2fs | intensity %.2f | impact pending %s",
        event and event.kind or "DONE", s.index, #s.events, s.time, s.intensity, tostring(not s.impactDispatched)), 302, 610)
    g.print("ST " .. ui.formatNumber(anim.displayChips) .. " | C.H " .. ui.formatNumber(anim.displayMult)
        .. " | AURA " .. ui.formatNumber(anim.displayAura) .. " | FPS " .. love.timer.getFPS(), 302, 637)
    g.print("F5 debug • F6 Feel Lab • Space: nhanh hơn", 302, 664)
    g.pop()
end

-- Isolated developer scene: never borrows or mutates the current run.
function Feel.labKeypressed(key, ui)
    if key == C.debugKey then Feel.debug = not Feel.debug; return true end
    if key == C.labKey then Feel.labOpen = not Feel.labOpen; return true end
    if not Feel.labOpen then return false end
    if key == "escape" then Feel.labOpen = false
    elseif key == "tab" then Feel.labFast = not Feel.labFast
    elseif key == "space" and Feel.labAnim then Feel.skipOrFastForward(Feel.labAnim)
    else
        local index = tonumber(key)
        if index and index >= 1 and index <= 5 then
            local Deck = require("src.deck")
            local aura = 10 ^ (index + 1)
            local cards = {Deck.newCard(8, "spades"), Deck.newCard(8, "hearts"), Deck.newCard(8, "clubs")}
            for i, card in ipairs(cards) do Effects.setEffect(card, ({"foil", "holographic", "polychrome"})[i]) end
            local a = {playedCards = cards, cardBounce = {}, cardHit = {}, deityBounce = {}, scoredCards = {},
                bounceScale = {chips=1,mult=1,score=1}, displayFlatDamage=0, displayAuraEditionMultiplier=1,
                floatingTexts = {}}
            local steps = {{type="base_hand", vnName="SCORING FEEL LAB", chips=40, mult=1}}
            for i, card in ipairs(cards) do steps[#steps+1] = {type="card_scored", card=card, cardIndex=i,
                addedChips=20, addedMult=0, message="+20 Sát thương"} end
            steps[#steps+1] = {type="deity_hand", addedChips=0, addedMult=0, xMult=aura/100,
                resultingChips=100, resultingMult=aura/100, message="SPN thử: ×" .. aura/100}
            steps[#steps+1] = {type="final_score", finalScore=aura}
            Feel.start(a, {steps=steps, totalChips=100, totalMult=aura/100, rawScore=aura, finalScore=aura}, ui, {}, aura*1.2)
            Feel.labAnim = a
        end
    end
    return true
end

function Feel.updateLab(dt)
    if Feel.labOpen and Feel.labAnim then
        local a = Feel.labAnim
        if Feel.update(a, dt, Feel.labFast) then Feel.damageApplied(a, a.sequence.hpBefore - a.sequence.result.finalScore, a.sequence.result.finalScore) end
    end
end

function Feel.drawLab(ui)
    if not Feel.labOpen then return end
    local g = love.graphics
    g.push("all")
    g.setColor(0.035, 0.055, 0.07, 0.98); g.rectangle("fill", 0, 0, 1280, 720)
    g.setColor(1, 0.80, 0.40, 1); g.setFont(ui.fonts.medium)
    g.print("SCORING FEEL LAB — 1:100   2:1K   3:10K   4:100K   5:1M", 255, 32)
    g.setFont(ui.fonts.small); g.print("Tab: Normal/Fast • Space: Fast-forward • F5: debug • F6/Esc: đóng", 255, 64)
    local a = Feel.labAnim
    if a then
        ui.components.HandInfoPanel.draw({handName="FEEL LAB", scoring=true, chips=a.displayChips, mult=a.displayMult,
            aura=a.displayAura, chipsBounce=a.bounceScale.chips, multBounce=a.bounceScale.mult,
            auraBounce=a.bounceScale.score, enemyHp=math.floor(a.sequence.hp), enemyBarHp=a.sequence.hp,
            enemyTrailHp=a.sequence.hpTrail, enemyMaxHp=a.sequence.hpBefore, category=a.stepCategory,
            detail=a.stepLog, enemyName="Mục tiêu thử"}, ui.fonts, ui.formatNumber)
        local offset, squash, flash = Feel.enemyReaction(a)
        g.setColor(0.24+flash*0.5,0.36+flash*0.3,0.43+flash*0.2,1)
        g.ellipse("fill", ui.BATTLE_CENTER_X, 265+offset, 43*squash, 56/squash)
        Feel.drawDim(a)
        for i, card in ipairs(a.playedCards) do
            local progress = (a.cardTransform[i] or 0) / 0.42
            if progress < 1 then
                g.setColor(1,1,1,1-progress)
                local oldAlpha = card.alpha
                card.alpha = 1-progress
                ui.drawCardFace(card, ui.getScoringCardX(i,#a.playedCards), 295, 96, 140)
                card.alpha = oldAlpha
            end
        end
        Feel.draw(a,ui); Feel.drawDebug(a,ui)
    end
    g.pop()
end

return Feel
