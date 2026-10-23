local V=require("src.timing_vfx")
local R=require("src.rng")
local state=R.getState()
for _,fps in ipairs({30,60,144}) do
    for _,grade in ipairs({"good","perfect","critical","ultimate","apex","trap","normal","timeout"}) do
        for _,kind in ipairs({"confirm","attack","block","reflect","miss","break"}) do
            V.clear()
            local e=V.emit(kind,grade,630,270)
            local time=0
            repeat
                local a,p=V.envelope(e);local x,y=V.camera()
                assert(a>=0 and a<=1 and p>=0 and p<=1 and math.abs(x)<3 and math.abs(y)<3)
                V.update(1/fps);time=time+1/fps
                assert(time<2,"every accent must clean up")
            until #V.active==0
        end
    end
end
assert(R.getState()==state,"visuals cannot consume gameplay RNG")
V.clear()
for i=1,100 do V.emit("reflect","apex",630,270,{reducedMotion=true}) end
assert(#V.active==V.limit and V.camera()==0,"bounded events, no reduced-motion shake")
local previous=0
for _,grade in ipairs({"good","perfect","critical","ultimate","apex"}) do
    local p=V.profiles[grade]
    assert(p.radius>previous and p.shards<=12 and p.radius<=100 and p.duration<=.80)
    previous=p.radius
end
V.update(10);assert(#V.active==0)
local sound=require("src.sound");local play=sound.play;local impacts=0
sound.play=function(name) assert(name=="timing_attack_apex");impacts=impacts+1;return true end
V.emit("reflect","apex",630,270,{audio=true})
V.update(.21);assert(impacts==0,"impact audio waits for the return beam")
V.update(.011);assert(impacts==1)
V.update(.4);assert(impacts==1,"one sound at reflected contact")
sound.play=play;V.clear()
for _,fps in ipairs({30,60,144}) do
    local e=V.emit("reflect","apex",630,270)
    local previous=0
    for frame=0,math.ceil(.5*fps) do
        e.age=frame/fps
        local pose=V.parryPose(e);local travel=V.returnTravel(e.age)
        assert(pose.sx>.7 and pose.sx<1.3 and pose.sy>.7 and pose.sy<1.3)
        assert(travel>=previous and travel<=1,"return force accelerates without reversing or overshooting")
        previous=travel
    end
    assert(V.returnTravel(.09)==0 and V.returnTravel(.22)==1,"reflected contact stays synchronized at 220 ms")
    e.age=.04;assert(V.pause() and V.parryPose(e).y>0,"parry compresses and holds at contact")
    e.age=.13;assert(V.parryPose(e).y<0,"shield kicks forward at release")
    e.age=.25;assert(V.pause(),"reflected contact has its own short impact pause")
    e.age=.5;assert(not V.pause(),"impact pauses cannot hold the combat queue")
    e.reduced=true;e.age=.04
    assert(not V.pause() and V.parryPose(e).y==0 and V.parryPose(e).sx==1)
    V.clear()
end
print("Timing VFX passed: 144 grade/outcome/FPS combinations, bounded lifetime/geometry, RNG isolation and reduced motion")
