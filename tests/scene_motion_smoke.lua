local T=require("src.scene_transition")
local C=require("config.visual_config").transition
local Rng=require("src.rng")
local function close(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local game={run={ante=1,regionId="unknown"},shopMode="small",monster={},enemies={}}
local rng=Rng.getState()
for _,fps in ipairs({30,60,120,144}) do
    for _,fast in ipairs({false,true}) do
        for _,reduced in ipairs({false,true}) do
            local s={}
            assert(not T.observe(s,"playing",game,true,reduced),"first frame has no old scene")
            assert(not T.busy(s,"scoring",game,true),"scoring stays in the same arena")
            assert(T.busy(s,"CASH_OUT",game,true),"new scene input is blocked before its first draw")
            T.update(s,.01,fast)
            assert(s.stateKey=="battle","update cannot observe an unseen scene")
            assert(T.observe(s,"CASH_OUT",game,true,reduced))
            local p=T.pose(s);close(p.opacity,1);close(p.outY,0)
            local duration=reduced and C.reducedDuration or C.duration
            local last=1;local elapsed=0
            repeat
                T.update(s,1/fps,fast);elapsed=elapsed+1/fps
                p=T.pose(s);assert(p.opacity<=last+1e-7 and p.opacity>=0,"monotone crossfade")
                if reduced then close(p.outY,0);close(p.mapY,0) end
                last=p.opacity
            until not T.busy(s,"CASH_OUT",game,true)
            close(p.opacity,0)
            assert(math.abs(elapsed-duration/(fast and 2 or 1))<=1/fps+1e-7,"FPS-independent completion")
            local serial=s.transitionSerial
            assert(not T.observe(s,"CASH_OUT",game,true,reduced) and s.transitionSerial==serial,"draw must not restart a fade")
            assert(T.observe(s,"shop",game,true,reduced))
            T.update(s,.1,fast);close(s.transitionAge,.05*(fast and 2 or 1))
            assert(T.observe(s,"BLIND_SELECT",game,true,reduced),"rapid changes use the latest visible composite")
            close(s.transitionAge,0);assert(s.transitionFrom=="shop")
            close(T.pose(s).mapY,reduced and 0 or C.mapLift)
            T.update(s,-1,fast);close(s.transitionAge,0)
            for _=1,fps do T.update(s,1/fps,fast) end
            close(T.pose(s).mapY,0)
        end
    end
end
local s={};T.observe(s,"shop",game,true,false)
game.shopMode="blood_small";assert(T.busy(s,"shop",game,true));assert(T.observe(s,"shop",game,true,false))
assert(not T.observe(s,"shop",game,true,false),"inventory changes within a market do not restart scenes")
T.observe(s,"playing",game,true,false);s.transitionAge=C.duration
for _,state in ipairs({"scoring","defeating","gameover","playing"}) do
    game.monster={};assert(not T.observe(s,state,game,true,false),"target changes and defeat already have their own motion")
end
T.observe(s,"map",game,true,false);s.transitionAge=C.duration
game.run.regionId="hearts";assert(T.busy(s,"map",game,true))
assert(not T.observe(s,"map",game,false,false) and not T.busy(s,"map",game,false),"disabled/missing canvas fallback unlocks immediately")
s.transitionAge=C.duration/2;s.transitionDuration=C.duration;close(T.pose(s).opacity,.5)
assert(Rng.getState()==rng and not game.rewardClaimSerial,"transition has no gameplay side effects")
print("Scene motion PASS: late changes, canonical arena, map/market context, rapid changes, exact endpoints, 30/60/120/144 FPS normal/2x/reduced, stalls, fallback, no RNG")
