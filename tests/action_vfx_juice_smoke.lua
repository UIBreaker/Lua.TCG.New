local F=require("src.combat_feedback")
local Sound=require("src.sound")
local Rng=require("src.rng");local rngBefore=Rng.getState()
local old=Sound.play;local calls=0
Sound.play=function() calls=calls+1;return true end
local kinds={"armor_gain","armor_loss","heal","hurt","equip","destroy","enemy_first","player_first","buy","sell"}
for _,fps in ipairs({30,60,144}) do
    F.clearVfx()
    for _,kind in ipairs(kinds) do
        for repeatIndex=1,10 do
            local before=calls;local e=assert(F.emit(kind,640,360,20))
            local elapsed=0
            while elapsed<e.profile.duration+1/fps do
                F.updateVfx(1/fps);elapsed=elapsed+1/fps
                if e.age<e.profile.contact then assert(not e.contacted and calls==before,"early audio") end
                if e.age>=e.profile.contact then assert(e.contacted and calls==before+1,"missing/repeated contact audio") end
            end
            assert(#F.vfx==0,"tail leaked into next repeat")
        end
    end
end
Sound.play=old
assert(Rng.getState()==rngBefore,"presentation consumed gameplay RNG")
local n=0;for _ in pairs(F.config.profiles) do n=n+1 end;assert(n==10,"no new effect profiles")
print("Juice PASS: each existing effect repeated 10 times at 30/60/144 FPS (300 runs); one sound per contact, bounded settle, no residual queue")
