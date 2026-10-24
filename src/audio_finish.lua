-- Offline/procedural rendering only: remove sub-rumble and soften brittle overtones.
local Finish={}
function Finish.apply(left,right,rate)
    local bass=1-math.exp(-2*math.pi*60/rate)
    local treble=1-math.exp(-2*math.pi*2300/rate)
    local dcL,dcR,lpL,lpR,lp2L,lp2R,peak=0,0,0,0,0,0,0
    for i=1,#left do
        dcL=dcL+(left[i]-dcL)*bass;dcR=dcR+(right[i]-dcR)*bass
        lpL=lpL+(left[i]-dcL-lpL)*treble;lpR=lpR+(right[i]-dcR-lpR)*treble
        lp2L=lp2L+(lpL-lp2L)*treble;lp2R=lp2R+(lpR-lp2R)*treble
        local mid,side=(lp2L+lp2R)*.5,(lp2L-lp2R)*.325
        local edge=math.min(1,(i-1)/96,(#left-i)/480)
        left[i],right[i]=(mid+side)*edge,(mid-side)*edge
        peak=math.max(peak,math.abs(left[i]),math.abs(right[i]))
    end
    return math.max(.001,peak)
end
return Finish
