-- Consumes the calculator's existing log. No score formula or gameplay mutations here.
local Feel = { config = require("config.scoring_feel_config"), debug = false, labOpen = false }
local Effects = require("src.card_effects")
local Sound = require("src.sound")
local Attacks = require("src.hand_attacks")
local Feedback = require("src.combat_feedback")
Feel.Attacks = Attacks
local C = Feel.config
local clamp = function(v, a, b) return math.max(a, math.min(b, v)) end
local ease = function(t) return 1 - (1 - clamp(t, 0, 1)) ^ 3 end
local smooth = function(t) t=clamp(t,0,1);return t*t*(3-2*t) end
local categories = { card_ability = "KHẢ NĂNG", card_scored = "LÁ BÀI", deity_card = "SPN", deity_hand = "SPN",
    deity_edition = "ẤN BẢN SPN", deity_enchantment = "PHÙ PHÉP SPN", equipment_trigger = "TRANG BỊ KHẢM", enhancement_trigger = "CƯỜNG HÓA BÀI",
    seal_trigger = "CON DẤU", card_edition = "ẤN BẢN", discard_buff_trigger = "CHIẾN THUẬT BỎ BÀI" }

function Feel.intensity(aura, target) return Attacks.power(aura, target) end

local function append(q, kind, duration, source, index)
    q[#q + 1] = {kind = kind, duration = duration, source = source, sourceIndex = index}
end

function Feel.start(anim, result, ui, deities, initialHp, enemy, handId)
    local attack = Attacks.new(result, anim.playedCards, ui, enemy and (enemy.targetAura or enemy.maxHp), handId)
    attack.cx=enemy and enemy.screenX or attack.cx
    local q, t = {}, C.timing
    append(q, "ENTRY", t.lift + t.travel + math.max(0, #anim.playedCards - 1) * t.stagger)
    local base = result.steps[1]
    append(q, "HAND_REVEAL", t.hand, base, 1)
    append(q, "BASE_DAMAGE", t.base, base, 1)
    append(q, "BASE_ENHANCE", t.base, base, 1)
    for i = 2, #result.steps do
        local st = result.steps[i]
        if st.type ~= "final_score" and not (st.equipment and (st.type=="armor_gain" or st.type=="heal_hp") and st.cardIndex) then
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
    local intensity = attack.intensity
    append(q, "FORMULA", t.formula, result.steps[#result.steps], #result.steps)
    append(q, "AURA_COUNT", t.countMin + (t.countMax - t.countMin) * intensity)
    append(q, "AURA_PEAK", t.peak)
    append(q, "ENERGY_CONVERSION", attack.profile.timing[1])
    append(q, "ANTICIPATION", attack.profile.timing[2])
    if attack.tier >= 4 then append(q, "CONVERGENCE", attack.tier == 5 and Attacks.config.silence or Attacks.config.convergence) end
    append(q, "ATTACK", attack.profile.timing[3])
    append(q, "ENEMY_IMPACT", attack.profile.timing[4], result.steps[#result.steps], #result.steps)
    append(q, "SETTLE", math.max(attack.profile.timing[5], t.trailDelay+t.trail-attack.profile.timing[4]))
    anim.sequence = {events = q, index = 1, age = 0, time = 0, entered = false, finished = false,
        attack = attack, intensity = intensity, result = result, ui = ui, deities = deities or {},
        hp = initialHp or 0, hpTrail = initialHp or 0, hpBefore = initialHp or 0,
        cameraAge = Attacks.config.camera.duration, damageApplied = false, energy = {}, links = {},
        high = attack.tier >= 3, tickAge = 0, milestone = 1000}
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
    for _,l in ipairs(s.links) do
        if math.abs(l.x-x)<8 and math.abs(l.y-y)<8 then l.duration=math.min(l.duration,l.age+0.06) end
    end
    s.links[#s.links + 1] = {text = (value > 0 and "+" or "") .. s.ui.formatNumber(value) .. " " .. label,
        x = x, y = y, tx = tx, ty = ty, age = 0, duration = 0.42, color = color}
    while #s.links>18 do table.remove(s.links,1) end
end

local function trigger(anim, st)
    local s = anim.sequence
    local x, y, cardIndex = sourcePoint(anim, st)
    if st.type=="card_ability" and st.kind=="destroy" then
        Feedback.destroyCard(st.card,x,y)
        if st.card then st.card.destroyFxActive=true;st.card.destroyFx=0 end
    end
    if st.type=="equipment_trigger" then Effects.triggerEquipmentPulse(st.card,st.equipmentIndex) end
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
    if st.type=="card_ability" and st.kind=="copy" and st.source then
        local sx,sy=sourcePoint(anim,{card=st.source})
        s.links[#s.links+1]={text="ÉCHO",x=sx,y=sy,tx=x,ty=y,age=0,duration=0.55,color=C.color.enhance,echo=true}
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
    s.multiply = (st.xMult or 1) > 1 or (st.xChips or 1)>1 or (st.xAura or 1)>1 or (st.auraMultiplier or 1) > 1 or anim.displayXMult > beforeX
    anim.bounceScale.chips = s.toChips ~= beforeChips and C.pulse.damage or 1
    anim.bounceScale.mult = s.toMult ~= beforeMult and (s.multiply and C.pulse.multiply or C.pulse.enhance) or 1
    local popupY=y-(cardIndex and 94 or 52)
    link(s, st.addedChips or 0, "ST", x, popupY, 70, 197, C.color.damage)
    link(s, st.addedMult or 0, "C.H", x, popupY+21, 176, 197, C.color.enhance)
    link(s, st.addedDamage or st.addFlatDamage or 0, "ST CỐ ĐỊNH", x, popupY-21, 126, 292, C.color.aura)
    if st.type=="equipment_trigger" then
        local rows={{st.addArmor,"GIÁP",{0.4,0.75,1,1}},{st.healHp,"HP",{0.4,0.95,0.6,1}},{st.addGold,"VÀNG",C.color.aura}}
        local offset=0
        for _,row in ipairs(rows) do
            if (row[1] or 0)>0 then
                s.links[#s.links+1]={text="+"..row[1].." "..row[2],x=x,y=popupY-24-offset,
                    tx=x,ty=popupY-24-offset,age=0,duration=0.62,color=row[3],resource=true}
                offset=offset+22
            end
        end
    end
    if s.multiply then
        local aura=(st.xAura or 1)>1 or st.auraMultiplier or st.cardXMultTotal
        local chips=(st.xChips or 1)>1
        local factor = (st.xAura or 1)>1 and st.xAura or chips and st.xChips or st.auraMultiplier or st.xMult or anim.displayXMult
        s.links[#s.links + 1] = {text = "×" .. string.format("%.2f",factor)
            .. (aura and " AURA" or chips and " ST" or " C.H"), x = x, y = popupY-21,
            tx = aura and 126 or chips and 70 or 176, ty = aura and 292 or 197,
            age = 0, duration = 0.48, color = C.color.aura, multiply = true}
    end
    anim.stepCategory = categories[st.type] or "HIỆU ỨNG"
    anim.stepLog = s.ui.localizeText(st.message or st.deityName or anim.stepCategory)
    if st.type == "card_scored" then
        anim.stepLog = (st.card.rankName or "") .. (st.card.suitSymbol or "") .. ": +"
            .. s.ui.formatNumber(st.addedChips or 0) .. " Sát thương / +"
            .. s.ui.formatNumber(st.addedMult or 0) .. " Cường hóa"
    end
    play(s, s.multiply and "multiply" or (s.toMult ~= beforeMult and "enhance" or "damage"))
    while #s.links>18 do table.remove(s.links,1) end
end

local function enter(anim, ev)
    local s, t = anim.sequence, C.timing
    Attacks.enter(s.attack, ev.kind)
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
        for i,card in ipairs(anim.playedCards) do
            anim.cardTransform[i] = 0
            Effects.triggerScorePulse(card)
        end
        -- Hand charge hook owns this beat.
    elseif ev.kind == "CONVERGENCE" then anim.stepCategory = "HỘI TỤ NĂNG LƯỢNG"
    elseif ev.kind == "ANTICIPATION" then anim.stepCategory = "TÍCH NĂNG"
    elseif ev.kind == "ATTACK" then
        anim.stepCategory, anim.stepLog = "PHÓNG NĂNG LƯỢNG", "Năng lượng lao vào quái"
        -- Hand release hook owns this beat.
    elseif ev.kind == "ENEMY_IMPACT" then
        s.cameraAge = 0
        anim.hitStop = s.attack.profile.hitStop[s.attack.tier]
        -- Impact illumination belongs to the world renderer, preserving sharp UI.
        anim.stepCategory, anim.stepLog = "ĐÁNH TRÚNG", "Năng lượng chạm quái"
        -- Hand impact hook owns this beat.
    elseif ev.kind == "SETTLE" then anim.stepCategory = "ỔN ĐỊNH" end
end

function Feel.formula(s)
    local r, fmt = s.result, s.ui.formatNumber
    local text = fmt(r.totalChips) .. " × " .. fmt(r.totalMult)
    if (r.cardXMultTotal or 1) ~= 1 then text = text .. " × " .. string.format("%.2f", r.cardXMultTotal) end
    -- Keep both floors used by Scoring.calculate (rawScore, then converted score).
    text = text .. " → " .. fmt(r.rawScore) .. " AURA gốc"
    if (r.localAuraBonus or 0) ~= 0 then text=text.." + "..fmt(r.localAuraBonus).." AURA Đa Sắc" end
    if (r.totalExtraDamagePct or 0) ~= 0 then text = text .. " × " .. string.format("%.2f", 1 + r.totalExtraDamagePct) end
    if (r.auraEditionMultiplier or 1) ~= 1 then text = text .. " × " .. string.format("%.2f", r.auraEditionMultiplier) end
    local flat=(r.flatDamageBonus or 0)+(r.auraDebtTotal or 0)
    if flat ~= 0 then text = text .. " + " .. fmt(flat) .. " ST cố định" end
    if (r.spnAuraMultiplier or 1)~=1 then text=text.." → ×"..string.format("%.2f",r.spnAuraMultiplier).." AURA tổng" end
    if (r.auraDebtTotal or 0)>0 then text=text.." - "..fmt(r.auraDebtTotal).." nợ AURA" end
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
    s.cameraAge = math.min(Attacks.config.camera.duration, s.cameraAge + dt)
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
        Attacks.update(s.attack, ev.kind, p)
        if ev.kind == "ENTRY" then anim.entranceTimer = s.age
        elseif ev.kind == "BASE_DAMAGE" or ev.kind == "BASE_ENHANCE" or ev.kind == "TRIGGER" or ev.kind == "FORMULA" then
            local wait = s.multiply and C.timing.multiplyAnticipation or 0
            local k = smooth((s.age - wait) / math.max(0.01, ev.duration - C.timing.gap - wait))
            anim.displayChips = s.fromChips + (s.toChips - s.fromChips) * k
            anim.displayMult = s.fromMult + (s.toMult - s.fromMult) * k
            local spring=math.sin(k*math.pi)*math.exp(-k*1.8)
            anim.bounceScale.chips=1+(s.toChips~=s.fromChips and 0.15*spring or 0)
            anim.bounceScale.mult=1+(s.toMult~=s.fromMult and (s.multiply and 0.24 or 0.17)*spring or 0)
        elseif ev.kind == "AURA_COUNT" then
            anim.displayAura = s.result.finalScore * smooth(p)
            anim.bounceScale.score = 1 + s.intensity * 0.12 * math.sin(p * math.pi)
            s.tickAge = s.tickAge + consumed
            if s.tickAge >= 0.065 then s.tickAge = s.tickAge % 0.065; play(s, "count", p * 0.05) end
            if anim.displayAura >= s.milestone then
                anim.bounceScale.score = 1.08 + s.intensity * 0.10
                repeat s.milestone = s.milestone * 10 until anim.displayAura < s.milestone
            end
        elseif ev.kind == "ENERGY_CONVERSION" then
            for i in ipairs(anim.playedCards) do
                local order = s.attack.sources[i].order
                local stagger = s.attack.profile.id == "straight" and (order-1)*0.09 or 0
                anim.cardTransform[i] = clamp((p-stagger)/(1-stagger),0,1)*0.42
            end
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
    if actualDamage > 0 then
        Feedback.add(anim.floatingTexts, "damage", actualDamage, s.attack.cx or s.ui.BATTLE_CENTER_X, 214, s.ui.formatNumber)
    else
        anim.floatingTexts[#anim.floatingTexts+1] = {text="ĐÒN BỊ CHẶN",color={0.4,0.84,1},
            x=s.attack.cx or s.ui.BATTLE_CENTER_X,y=232,alpha=1.6}
    end
end

function Feel.camera(anim)
    local s = anim.sequence
    if not s then return 0, 0 end
    local p = clamp(s.cameraAge / Attacks.config.camera.duration, 0, 1)
    local amount = 0.5 + Attacks.config.camera.maxKick * s.intensity
    local decay = math.exp(-7*p)*(1-p)
    -- One directional punch and a small rebound, not many oscillations.
    local spring=math.cos(p*7)
    return s.attack.profile.camera.x*amount*spring*decay,
        -amount*spring*decay
end

function Feel.enemyReaction(anim)
    local s = anim.sequence
    if not s then return 0, 1, 0 end
    local p = clamp(s.cameraAge / Attacks.config.camera.duration, 0, 1)
    local hit = (1 - p)^2
    local force=s.attack.tier>1 and s.intensity or 0.12
    local recoil=-Attacks.config.camera.maxRecoil*force*math.sin(p*8+0.22)*math.exp(-5*p)*(1-p)
    local compression=math.cos(p*7)*math.exp(-6*p)*(1-p)
    return recoil,1-0.07*compression*(0.3+s.intensity),hit
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
        local k=clamp(l.age/l.duration,0,1)
        local flight=smooth((k-0.20)/0.80)
        local x,y=l.x+(l.tx-l.x)*flight,l.y+(l.ty-l.y)*flight-math.sin(flight*math.pi)*22
        local fade=1-smooth((k-0.55)/0.45)
        g.push("all");g.setBlendMode("add")
        g.setColor(l.color[1],l.color[2],l.color[3],(1-k)*0.12)
        g.setLineWidth(3);g.line(x,y,x+(l.x-x)*0.045,y+(l.y-y)*0.045)
        g.setColor(l.color[1],l.color[2],l.color[3],math.sin(flight*math.pi)*0.85)
        g.circle("fill",x,y,l.multiply and 3.5 or 2.5)
        if l.echo then g.setLineWidth(1);g.line(l.x,l.y,x,y);g.circle("line",x,y,7+4*k) end
        g.pop()
        -- The value stays beside its source; only a small energy mote travels.
        if l.x>=240 then
        g.push("all");g.translate(l.x,l.y-10*smooth(k))
        local pop=1+0.23*math.exp(-l.age*11)*math.sin(l.age*26)-0.12*math.exp(-l.age*35)
        g.scale(pop);g.rotate(l.multiply and math.sin(l.age*19)*math.exp(-l.age*12)*0.035 or 0)
        g.setFont(l.multiply and ui.fonts.medium or (ui.fonts.regular or ui.fonts.small))
        local width=g.getFont():getWidth(l.text)
        if width>118 then g.scale(118/width) end
        g.setColor(0.015,0.025,0.045,fade*0.90)
        g.rectangle("fill",-width/2-7,-14,width+14,g.getFont():getHeight()+4,4,4)
        g.setColor(l.color[1],l.color[2],l.color[3],fade*0.20)
        g.printf(l.text,-125,-14,250,"center")
        g.setColor(0.01,0.015,0.025,fade);g.printf(l.text,-125,-10,250,"center")
        g.setColor(l.color[1],l.color[2],l.color[3],fade);g.printf(l.text,-125,-12,250,"center")
        g.pop()
        end
    end
    g.pop()
end

function Feel.drawWorld(anim, ui)
    local s = anim.sequence
    if not s then return end
    local ev = s.events[s.index]
    if not ev then return end
    Attacks.draw(s.attack, ev.kind, clamp(s.age/ev.duration,0,1), s.impactDispatched and s.cameraAge or nil)
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
    elseif key == "r" then Feel.labKeypressed(tostring(Feel.labTier or 3), ui)
    elseif key == "right" or key == "left" then
        Feel.labHand = ((Feel.labHand or 1)-1+(key == "right" and 1 or -1))%#Attacks.config.order+1
        Feel.labKeypressed(tostring(Feel.labTier or 3), ui)
    elseif key == "tab" then Feel.labFast = not Feel.labFast
    elseif key == "space" and Feel.labAnim then Feel.skipOrFastForward(Feel.labAnim)
    else
        local index = tonumber(key)
        if index and index >= 1 and index <= 5 then
            local Deck = require("src.deck")
            Feel.labTier = index
            local id = Attacks.config.order[Feel.labHand or 1]
            local ratios = {0.25,0.75,1.5,3,5}
            local aura = 10 ^ (index + 1) -- Existing tier-key compatibility.
            local target = aura/ratios[index]
            local presets = {
                high_card={14},pair={8,8},two_pair={8,8,11,11},three_of_a_kind={8,8,8},
                straight={7,8,9,10,11},flush={2,5,8,11,14},full_house={8,8,8,11,11},
                four_of_a_kind={8,8,8,8},straight_flush={10,11,12,13,14},
            }
            local cards = {}
            for i,rank in ipairs(presets[id]) do cards[i]=Deck.newCard(rank, (id=="flush" or id=="straight_flush") and "spades" or ({"spades","hearts","clubs","diamonds"})[(i-1)%4+1]) end
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
            Feel.start(a, {steps=steps, totalChips=100, totalMult=aura/100, rawScore=aura, finalScore=aura}, ui, {}, aura*1.2, {targetAura=target}, id)
            Feel.labAnim = a
        end
    end
    return true
end

function Feel.updateLab(dt)
    if Feel.labOpen and Feel.labAnim then
        local a = Feel.labAnim
        if (a.hitStop or 0)>0 then a.hitStop=math.max(0,a.hitStop-dt);return end
        if Feel.update(a, dt, Feel.labFast) then Feel.damageApplied(a, a.sequence.hpBefore - a.sequence.result.finalScore, a.sequence.result.finalScore) end
        for i=#a.floatingTexts,1,-1 do
            local ft=a.floatingTexts[i]
            if ft.kind then Feedback.update(ft,dt) else ft.alpha=math.max(0,ft.alpha-dt*1.1) end
            if ft.alpha<=0 then table.remove(a.floatingTexts,i) end
        end
    end
end

function Feel.drawLab(ui)
    if not Feel.labOpen then return end
    local g = love.graphics
    g.push("all")
    g.setColor(0.035, 0.055, 0.07, 1); g.rectangle("fill", 0, 0, 1280, 720)
    g.setColor(1, 0.80, 0.40, 1); g.setFont(ui.fonts.medium)
    g.print("HAND VFX LAB — 1..5: NORMAL / STRONG / POWERFUL / EXTREME / TRANSCEND", 255, 32)
    g.setFont(ui.fonts.small); g.print("←/→: hand • R: replay • Tab: Normal/Fast • Space: forward • F6/Esc: đóng", 255, 64)
    local a = Feel.labAnim
    if a then
        ui.components.HandInfoPanel.draw({handName=a.sequence.attack.profile.name .. " / " .. Attacks.config.tierNames[a.sequence.attack.tier], scoring=true, chips=a.displayChips, mult=a.displayMult,
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
            local dx,dy,rotation,shrink=Attacks.cardPose(a.sequence.attack,i,progress)
            if progress < 1 then
                g.setColor(1,1,1,1-progress)
                local oldAlpha = card.alpha
                card.alpha = 1-progress
                g.push();g.translate(ui.getScoringCardX(i,#a.playedCards)+48+dx,365+dy)
                g.rotate(rotation);g.scale(shrink,shrink)
                ui.Polish.dissolve(ui,-48,-70,96,140,progress,a.sequence.attack.color,
                    function(x,y,w,h) ui.drawCardFace(card,x,y,w,h) end)
                g.pop()
                Attacks.fragments(a.sequence.attack,i,progress,ui.getScoringCardX(i,#a.playedCards)+48,365)
                card.alpha = oldAlpha
            end
        end
        Feel.drawWorld(a,ui); Feel.draw(a,ui)
        for _,text in ipairs(a.floatingTexts) do
            Feedback.draw(text,ui)
        end
        Feel.drawDebug(a,ui)
    end
    g.pop()
end

return Feel
