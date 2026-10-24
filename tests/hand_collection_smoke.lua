local M=require("src.hand_motion")
local C=require("config.ux_polish_config")
M.reset();M.fast=false;M.reducedMotion=false
local first,last={},{}
for i,card in ipairs({first,last}) do
    M.update(card,300+i*100,470,0,0,false,false)
    M.collect(card,i,1147.5,542.5)
end
M.updateReturns(C.collect+.001)
assert(M.busy({first,last}) and M.hidden(first) and M.hidden(last),
    "An early arrival must not reappear in the hand while later cards are returning")
M.updateReturns(1)

for _,fps in ipairs({30,60,120,144}) do
    for _,fast in ipairs({false,true}) do
        for _,count in ipairs({1,2,7,12,30}) do
            M.reset();M.fast=fast;M.reducedMotion=false
            local cards={}
            for i=1,count do
                local card={visualX=220+i*8,visualY=470,rotation=.02,visualScale=1}
                if i%2==0 then M.prepareDeal(card,i,1147.5,542.5) end
                cards[i]=card
                M.collect(card,i,1147.5,542.5)
                assert(M.hidden(card),"Even a new or still-dealing card must be hidden during collection")
                assert(not M.isDealing(card),"Collection takes over an unfinished deal")
            end
            local called=0
            M.onCollected=function() called=called+1 end
            local elapsed=0
            repeat
                M.updateReturns(1/fps);elapsed=elapsed+1/fps
                if M.busy(cards) then
                    assert(called==0)
                    for _,card in ipairs(cards) do assert(M.hidden(card),"No original face may return mid-collection") end
                end
                assert(elapsed<3,"Collection must complete")
            until not M.busy(cards)
            assert(called==1)
            for _,card in ipairs(cards) do assert(not M.hidden(card)) end
            M.updateReturns(2);assert(called==1,"Completion must run only once")
        end
    end
end
M.reset();local card={};M.collect(card,8,100,200)
M.reducedMotion=true;M.updateReturns(0)
assert(not M.busy({card}) and not M.hidden(card),"Reduced motion completes the whole batch")
M.reducedMotion=false;M.reset()
M.prepareDeal(card,1,10,20);M.collect(card,1,100,200)
M.prepareDeal(card,1,10,20,1);local newer=M.get(card)
M.updateReturns(2)
assert(M.get(card)==newer and M.isDealing(card) and M.hidden(card),"Old returns cannot clear a new deal")
M.reset();M.fast=false
print("Hand collection PASS: no early reappearing faces, stateless/dealing cards, 1/2/7/12/30 cards, 30/60/120/144 FPS, fast/reduced, one callback, reused cards")
