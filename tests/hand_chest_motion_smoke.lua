local M=require("src.hand_motion")
local C=require("config.ux_polish_config")
local Motion=require("src.motion")
local function close(a,b) assert(math.abs(a-b)<0.000001,"trajectory depends on FPS") end
local function deal(fps,seconds,order)
    M.reset();M.reducedMotion=false;M.fast=false
    local card={};M.prepareDeal(card,order or 1,1147.5,542.5)
    local sound=0
    for _=1,math.floor(seconds*fps+0.5) do
        if M.update(card,440,470,0.02,1/fps,false,false) then sound=sound+1 end
    end
    return card,sound
end
local reference=deal(60,0.3)
for _,fps in ipairs({30,60,120,144}) do
    local card,sound=deal(fps,0.5)
    assert(not M.isDealing(card) and not M.busy({card}))
    assert(sound==1,"one deal sound per card")
    close(card.visualX,440);close(card.visualScale,1)
    -- Compare at exactly the same elapsed time, including a partial final frame.
    card=deal(fps,0)
    local elapsed=0
    while elapsed<0.3 do
        local dt=math.min(1/fps,0.3-elapsed);elapsed=elapsed+dt
        M.update(card,440,470,0.02,dt,false,false)
    end
    close(card.visualX,reference.visualX);close(card.visualY,reference.visualY)
end
M.reset();local card={};M.prepareDeal(card,3,1147.5,542.5)
assert(M.hidden(card));M.update(card,440,470,0,0.05,false,false)
assert(M.hidden(card) and card.visualX==1147.5,"stagger keeps waiting cards in the pile")
M.update(card,440,470,0,2,false,false)
assert(not M.isDealing(card) and card.visualX==440,"a stall must finish the deal")
M.prepareDeal(card,3,1147.5,542.5);M.reducedMotion=true
M.update(card,440,470,0,1/144,false,false)
assert(card.visualX==440 and card.visualY==470 and card.visualScale==1 and not M.busy({card}))
M.reducedMotion=false;M.fast=true;M.prepareDeal(card,1,1147.5,542.5)
M.update(card,440,470,0,C.deal/2,false,false)
assert(not M.isDealing(card),"fast deal uses the existing speed factor")
M.fast=false

card.visualX,card.visualY,card.rotation,card.visualScale=400,466,-0.05,1.045
M.collect(card,1,1147.5,542.5)
assert(M.hidden(card) and M.returnDuration()==C.collect)
local called=0;M.onCollected=function() called=called+1 end
M.updateReturns(C.collect-0.01);assert(called==0 and M.busy({}))
M.updateReturns(0.02);M.updateReturns(2)
assert(called==1 and not M.busy({}) and not M.hidden(card),"collection callback runs exactly once")
assert(card.rotation==-0.05 and card.visualScale==1.045,"ghost must not mutate the live card")
local fx={x=400,y=466,angle=-0.05,scale=1.045,targetX=1147.5,targetY=542.5}
for _,fps in ipairs({30,60,120,144}) do
    fx.age=0;local previous=0
    for i=0,fps do
        fx.age=C.collect*i/fps
        local p=M.returnPose(fx)
        assert(p.progress>=previous and p.scale>0 and p.x>=400 and p.x<=1147.5)
        previous=p.progress
    end
    local p=M.returnPose(fx);close(p.x,1147.5);close(p.y,542.5);close(p.scale,0.68)
end
M.collect(card,2,1147.5,542.5)
local delay=M.returnDuration();local incoming={}
M.prepareDeal(incoming,1,1147.5,542.5,delay)
M.update(incoming,440,470,0,delay-0.001,false,false)
assert(M.hidden(incoming),"replacement waits for collection")
M.reducedMotion=true;M.updateReturns(0);assert(not M.busy({}))
M.reducedMotion=false;M.reset()
close(Motion.settle(0,0.5),0);close(Motion.settle(0.5,0.5),1)

local Choices=require("ui.chest_choices")
local UI=require("src.ui")
local chest=require("config.death_vfx_config").chest
local early=Choices.pose(chest.cardsAt+0.12,1)
local late=Choices.pose(chest.cardsAt+0.12,3)
assert(early.scale>late.scale,"chest cards spread in sequence")
UI.Polish.reducedMotion=true
local pose=Choices.pose(chest.cardsAt,1)
assert(pose.scale==1 and pose.rotation==0 and pose.y==chest.cardY)
UI.Polish.reducedMotion=false
require("tests.chest_reveal_smoke")
require("tests.hand_collection_smoke")
print("Hand/chest motion PASS: exact endpoints, stagger, collection-before-deal, ghost isolation, one-shot callback/sound, FPS/stalls, fast/reduced motion")
