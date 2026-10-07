local Choices=require("ui.chest_choices")
local C=require("config.death_vfx_config").chest
local Rng=require("src.rng")
local before=Rng.getState()
for _,fps in ipairs({30,60,144}) do
    for i=1,3 do
        local previous=0
        for frame=0,math.ceil(Choices.finished()*fps)+1 do
            local t=frame/fps
            local p=Choices.pose(t,i)
            assert(p.x==p.x and p.y==p.y and p.scale>0)
            assert(p.reveal>=previous and p.reveal<=1,"reveal must never disappear again")
            if Choices.ready(t,i) then
                assert(p.reveal==1 and p.rotation==0 and p.scale==1,"input unlocks only on settled face")
            end
            previous=p.reveal
        end
        assert(not Choices.ready(C.flipAt+(i-1)*C.stagger+C.flipDuration-0.001,i))
    end
end
assert(Rng.getState()==before,"reveal must not change rewards RNG")
assert(Choices.ready(Choices.finished(),3))
print("Chest reveal passed: 30/60/144 FPS, monotonic materialization, input only on settled faces, unchanged gameplay RNG")
