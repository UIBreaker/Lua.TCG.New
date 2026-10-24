local A = {}
function A.cue(kind,grade)
    if grade=="riposte" or grade=="exposed" then grade="trap" end
    if require("src.combat_timing").utility[grade] then grade="critical" end
    return "timing_"..kind.."_"..grade
end
function A.play(kind,grade)
    local u=require("src.combat_timing").utility[grade]
    return require("src.sound").play(A.cue(kind,grade),u and u.pitch)
end
function A.register(sound)
    if not (love and love.sound and love.sound.newSoundData) then return end
    for name,cue in pairs(require("config.timing_audio_baked")) do sound.registerFileCue(name,cue) end
end
return A
