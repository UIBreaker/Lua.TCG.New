local A = {}
function A.cue(kind,grade) return "timing_"..kind.."_"..grade end
function A.play(kind,grade) return require("src.sound").play(A.cue(kind,grade)) end
function A.register(sound)
    if not (love and love.sound and love.sound.newSoundData) then return end
    for name,cue in pairs(require("config.timing_audio_baked")) do sound.registerFileCue(name,cue) end
end
return A
