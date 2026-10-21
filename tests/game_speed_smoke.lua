local S=require("src.game_speed")
for _,fps in ipairs({30,60,120,144}) do
    for _,speed in ipairs({1,2,4}) do
        local settings={gameSpeed=speed};local elapsed,real,calls=0,0,0
        local tick=S.wrap(function(dt,wall)
            assert(dt<=1/60+1e-9,"fast mode must not hit animation delta caps")
            elapsed=elapsed+math.min(dt,.05);real=real+wall;calls=calls+1
        end,function() return settings end)
        for _=1,fps do tick(1/fps) end
        assert(math.abs(elapsed-S.base*speed)<1e-8,"exact speed ratio")
        assert(math.abs(real-1)<1e-8,"input/audio stay on the real clock")
        assert(calls>=fps and not settings.fastScoring,"no second speed multiplier")
    end
end
local old={gameSpeed=1,fastScoring=true};assert(S.normalize(old)==2 and not old.fastScoring)
assert(S.cycle(old)==4 and S.cycle(old)==1 and S.cycle(old)==2)
assert(S.set(old,99)==1)
local P=require("src.persistence")
local decoded=assert(P.decode(P.encode({settings={gameSpeed=4,fastScoring=false}})))
assert(S.normalize(decoded.settings)==4,"saved ×4 survives serialization")
local fs=love.filesystem
love.filesystem={getInfo=function() return true end,read=function() return P.encode({version=P.SAVE_VERSION,settings={gameSpeed=4,fastScoring=false}}) end}
local loaded=P.loadSettings({gameSpeed=1,fastScoring=false})
love.filesystem=fs
assert(S.normalize(loaded)==4,"settings loader restores ×4")
print("Game speed PASS: slower base, exact 1/2/4 ratios at 30/60/120/144 FPS, real-time input/audio, bounded steps, legacy migration, cycle and serialization")
