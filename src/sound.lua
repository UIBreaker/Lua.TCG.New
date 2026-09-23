local Sound = {}

local sounds = {}
local enabled = true
local activeVoices = {}
local lastPlayed = {}
local MAX_VOICES = 18
local gain = {
    ui_hover = 0.26, ui_click = 0.48,
    card_select = 0.52, card_deselect = 0.46, card_slide = 0.42,
    card_draw = 0.60, card_deal = 0.50, card_play = 0.78,
    chip_tick = 0.40, mult_pop = 0.60, coin = 0.66,
    score_impact = 0.80, xmult_boom = 0.72, jackpot = 0.72,
    round_win = 0.72, game_over = 0.72,
    shop_buy = 0.60, shop_reroll = 0.52, pack_open = 0.70,
    equip = 0.66, sell = 0.58, consume = 0.65, card_destroy = 0.56,
    cant_afford = 0.55,
}
local cooldown = {
    ui_hover = 0.07, ui_click = 0.035, card_slide = 0.035,
    card_draw = 0.025, chip_tick = 0.022, mult_pop = 0.028,
}

local function generateSound(duration, sampleRate, generator)
    local sampleCount = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)
    for i = 0, sampleCount - 1 do
        local t = i / sampleRate
        local sample = generator(t, duration)
        -- Clamp between -1.0 and 1.0
        local edge = math.min(1, t * 500, (duration - t) * 80)
        sample = math.max(-1.0, math.min(1.0, sample * math.max(0, edge)))
        soundData:setSample(i, sample)
    end
    return love.audio.newSource(soundData, "static")
end

function Sound.init()
    if not love.sound or not love.audio then
        enabled = false
        return false
    end

    enabled = true
    sounds, activeVoices, lastPlayed = {}, {}, {}
    local success, err = pcall(function()
        local rate = 44100

        -- 1. Card Click / Select (Soft crisp pop)
        sounds.card_select = generateSound(0.04, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 480 + (t / d) * 320
            return env * 0.4 * math.sin(2 * math.pi * freq * t)
        end)

        -- 2. Card Deselect (Lower soft pop)
        sounds.card_deselect = generateSound(0.03, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 360 - (t / d) * 100
            return env * 0.3 * math.sin(2 * math.pi * freq * t)
        end)

        -- 3. Card Discard / Deal (Swoosh)
        sounds.card_deal = generateSound(0.08, rate, function(t, d)
            local env = (1 - t / d) ^ 3
            local noise = (love.math.random() * 2 - 1)
            local sine = math.sin(2 * math.pi * (200 + t * 400) * t)
            return env * 0.35 * (noise * 0.5 + sine * 0.5)
        end)

        -- Individual card draw (paper flick + soft table landing)
        sounds.card_draw = generateSound(0.12, rate, function(t, d)
            local progress = t / d
            local paper = (love.math.random() * 2 - 1) * math.sin(progress * math.pi) * 0.22
            local flick = math.sin(2 * math.pi * (760 - progress * 420) * t) * math.exp(-t * 28)
            local landing = (t > 0.065) and math.sin(2 * math.pi * 190 * (t - 0.065)) * math.exp(-(t - 0.065) * 45) or 0
            return paper + flick * 0.32 + landing * 0.34
        end)

        -- Cards committed to the play area (fast swoosh + firm snap)
        sounds.card_play = generateSound(0.18, rate, function(t, d)
            local progress = t / d
            local swoosh = (love.math.random() * 2 - 1) * math.sin(progress * math.pi) * 0.28
            local snap = (t > 0.105) and math.sin(2 * math.pi * 260 * (t - 0.105)) * math.exp(-(t - 0.105) * 38) or 0
            return swoosh + snap * 0.58
        end)

        -- Final score impact (short bass hit, separate from XMult sparkle)
        sounds.score_impact = generateSound(0.22, rate, function(t, d)
            local env = math.exp(-t * 16)
            local freq = 105 - 45 * (t / d)
            local bass = math.sin(2 * math.pi * freq * t)
            local crack = (love.math.random() * 2 - 1) * math.exp(-t * 70)
            return env * 0.72 * bass + crack * 0.22
        end)

        -- 4. Chip Tick (Clear crystal bell ping)
        sounds.chip_tick = generateSound(0.07, rate, function(t, d)
            local env = math.exp(-t * 35)
            local s1 = math.sin(2 * math.pi * 980 * t)
            local s2 = math.sin(2 * math.pi * 1960 * t) * 0.3
            return env * 0.45 * (s1 + s2)
        end)

        -- 5. Mult Pop (Punchy ascending thump)
        sounds.mult_pop = generateSound(0.1, rate, function(t, d)
            local env = math.exp(-t * 22)
            local freq = 320 + (t / d) * 200
            local s = math.sin(2 * math.pi * freq * t)
            return env * 0.55 * s
        end)

        -- 6. XMult Explosion (Boom + sparkle)
        sounds.xmult_boom = generateSound(0.3, rate, function(t, d)
            local env = math.exp(-t * 12)
            local bass = math.sin(2 * math.pi * (140 - t * 180) * t)
            local noise = (love.math.random() * 2 - 1) * math.exp(-t * 25)
            local sparkle = math.sin(2 * math.pi * 1760 * t) * math.exp(-t * 15) * 0.3
            return env * 0.7 * (bass * 0.6 + noise * 0.25 + sparkle)
        end)

        -- 7. Win Fanfare
        sounds.round_win = generateSound(0.45, rate, function(t, d)
            local env = (1 - t / d)
            local note = 440
            if t > 0.30 then note = 880
            elseif t > 0.20 then note = 659.25
            elseif t > 0.10 then note = 554.37
            end
            local s = math.sin(2 * math.pi * note * t)
            return env * 0.5 * s
        end)

        -- 8. Game Over tone
        sounds.game_over = generateSound(0.5, rate, function(t, d)
            local env = (1 - t / d)
            local freq = 220 - (t / d) * 110
            return env * 0.5 * (math.sin(2 * math.pi * freq * t) + math.sin(2 * math.pi * (freq * 1.5) * t) * 0.5)
        end)

        -- 9. Jackpot chime (Bright rapid casino victory chimes)
        sounds.jackpot = generateSound(0.55, rate, function(t, d)
            local env = (1 - t / d) ^ 1.5
            local note = 523.25 -- C5
            if t > 0.40 then note = 1046.50 -- C6
            elseif t > 0.28 then note = 783.99 -- G5
            elseif t > 0.14 then note = 659.25 -- E5
            end
            local chime = math.sin(2 * math.pi * note * t) + 0.35 * math.sin(2 * math.pi * note * 2 * t)
            return env * 0.55 * chime
        end)

        -- 10. UI Button Hover (Subtle soft blip)
        sounds.ui_hover = generateSound(0.025, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 620 + (t / d) * 180
            return env * 0.18 * math.sin(2 * math.pi * freq * t)
        end)

        -- 11. UI Button Click (Tactile mechanical clack + woody switch thud)
        sounds.ui_click = generateSound(0.05, rate, function(t, d)
            -- A. Sharp mechanical snap / clack transient (0 to 6ms)
            local snapNoise = (love.math.random() * 2 - 1) * math.exp(-t * 160) * 0.45
            local snapChirp = math.sin(2 * math.pi * (2400 - t * 16000) * t) * math.exp(-t * 110) * 0.35

            -- B. Tactile woody switch thud body (360-480 Hz bottom-out)
            local bodyFreq = 420 * math.exp(-t * 16)
            local body = math.sin(2 * math.pi * bodyFreq * t) + 0.35 * math.sin(4 * math.pi * bodyFreq * t)
            local bodyEnv = math.exp(-t * 40)

            -- C. Secondary micro tactile release ping around 10ms
            local ping = 0
            if t > 0.010 then
                local pt = t - 0.010
                ping = math.sin(2 * math.pi * 1350 * pt) * math.exp(-pt * 85) * 0.18
            end

            return (snapNoise + snapChirp) * 0.55 + body * bodyEnv * 0.50 + ping
        end)

        -- 12. Shop Buy (Crystal coin chimes + paper grab snap)
        sounds.shop_buy = generateSound(0.38, rate, function(t, d)
            local env = math.exp(-t * 12)
            -- Ascending bell arpeggio notes
            local note = 1318.51 -- E6
            if t > 0.18 then note = 2637.02 -- E7
            elseif t > 0.11 then note = 1975.53 -- B6
            elseif t > 0.05 then note = 1661.22 -- G#6
            end
            local bell = math.sin(2 * math.pi * note * t) + 0.4 * math.sin(2 * math.pi * note * 2.75 * t)
            local grabSnap = (t < 0.04) and ((love.math.random() * 2 - 1) * 0.35) or 0
            return env * 0.5 * bell + grabSnap
        end)

        -- 13. Shop Reroll (Crisp card riffle shuffle & deck slide)
        sounds.shop_reroll = generateSound(0.26, rate, function(t, d)
            local progress = t / d
            local env = math.sin(progress * math.pi) ^ 0.7
            -- Rapid riffle tick bursts
            local tickPhase = (t * 65) % 1.0
            local tick = (tickPhase < 0.3) and 1.0 or 0.15
            local noise = (love.math.random() * 2 - 1) * tick
            local freq = 380 + progress * 720
            local swoosh = math.sin(2 * math.pi * freq * t) * 0.4
            return env * 0.5 * (noise * 0.6 + swoosh * 0.4)
        end)

        -- 14. Can't Afford (Dull error thock)
        sounds.cant_afford = generateSound(0.12, rate, function(t, d)
            local env = math.exp(-t * 32)
            local freq = 160 - (t / d) * 70
            local thock = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * (freq * 0.5) * t)
            return env * 0.45 * thock
        end)

        -- 15. Booster Pack Open (Foil tear + magic shimmer)
        sounds.pack_open = generateSound(0.42, rate, function(t, d)
            local env = math.exp(-t * 9)
            local tearNoise = (t < 0.09) and ((love.math.random() * 2 - 1) * (1 - t / 0.09)) or 0
            local shimmerFreq = 1200 + (t / d) * 1600
            local shimmer = math.sin(2 * math.pi * shimmerFreq * t) * 0.5 + 0.25 * math.sin(2 * math.pi * (shimmerFreq * 1.5) * t)
            return env * 0.45 * (tearNoise * 0.7 + shimmer * 0.5)
        end)

        -- Soft paper drag; the hand reordering action used to be silent.
        sounds.card_slide = generateSound(0.11, rate, function(t, d)
            local p = t / d
            local paper = (love.math.random() * 2 - 1) * math.sin(math.pi * p) * 0.22
            local tap = math.sin(2 * math.pi * 420 * t) * math.exp(-t * 34)
            return paper + tap * 0.20
        end)

        sounds.coin = generateSound(0.24, rate, function(t)
            local bell = math.sin(2 * math.pi * 1174.66 * t)
                + 0.35 * math.sin(2 * math.pi * 1761.99 * t)
            return bell * math.exp(-t * 17) * 0.48
        end)

        sounds.equip = generateSound(0.28, rate, function(t)
            local click = math.sin(2 * math.pi * 280 * t) * math.exp(-t * 65)
            local ring = (math.sin(2 * math.pi * 784 * t)
                + 0.32 * math.sin(2 * math.pi * 1176 * t)) * math.exp(-t * 16)
            return click * 0.45 + ring * 0.35
        end)

        sounds.sell = generateSound(0.22, rate, function(t)
            local swipe = (love.math.random() * 2 - 1) * math.exp(-t * 38)
            local coin = math.sin(2 * math.pi * 880 * t) * math.exp(-t * 18)
            return swipe * 0.16 + coin * 0.40
        end)

        sounds.consume = generateSound(0.36, rate, function(t, d)
            local p = t / d
            local shimmer = math.sin(2 * math.pi * (620 + 620 * p) * t)
            local body = math.sin(2 * math.pi * 220 * t)
            return (shimmer * 0.42 + body * 0.18) * math.sin(math.pi * p)
        end)

        sounds.card_destroy = generateSound(0.34, rate, function(t, d)
            local p = t / d
            local noise = (love.math.random() * 2 - 1) * math.exp(-t * 11)
            local fall = math.sin(2 * math.pi * (520 - 360 * p) * t) * math.exp(-t * 13)
            return noise * 0.30 + fall * 0.28
        end)
    end)

    if not success then
        print("[Sound] Init warning: audio synthesizer disabled (" .. tostring(err) .. ")")
        enabled = false
    end
    return success
end

local masterVolume = 0.8
if love and love.audio and love.audio.setVolume then
    love.audio.setVolume(masterVolume)
end

function Sound.setVolume(vol)
    masterVolume = math.max(0, math.min(1.0, vol or 0.8))
    if love and love.audio and love.audio.setVolume then
        love.audio.setVolume(masterVolume)
    end
end

function Sound.getVolume()
    return masterVolume
end

function Sound.has(name)
    return sounds[name] ~= nil
end

function Sound.play(name, pitch)
    if not enabled or masterVolume <= 0 then return false end
    local s = sounds[name]
    if not s then return false end
    local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
    if now - (lastPlayed[name] or -math.huge) < (cooldown[name] or 0) then return false end
    lastPlayed[name] = now

    local ok = pcall(function()
        for i = #activeVoices, 1, -1 do
            if not activeVoices[i]:isPlaying() then table.remove(activeVoices, i) end
        end
        while #activeVoices >= MAX_VOICES do
            local oldest = table.remove(activeVoices, 1)
            oldest:stop()
        end
        local voice = s.clone and s:clone() or s
        if voice == s then voice:stop() end
        if voice.setPitch then voice:setPitch(math.max(0.2, math.min(3, pitch or 1))) end
        if voice.setVolume then voice:setVolume(gain[name] or 0.6) end
        voice:play()
        activeVoices[#activeVoices + 1] = voice
    end)
    return ok
end

return Sound
