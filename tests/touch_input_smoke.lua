local events = {}
love = {mouse={getPosition=function() return 0,0 end}}
local T = require("src.touch_input")
local scrolling = false
T.install({
    press=function(x,y,b) events[#events+1]={"press",x,y,b} end,
    release=function(x,y,b) events[#events+1]={"release",x,y,b} end,
    move=function(x,y) events[#events+1]={"move",x,y} end,
    cancel=function() events[#events+1]={"cancel"} end,
    canScroll=function() return scrolling end,
    scroll=function(dy) events[#events+1]={"scroll",dy} end,
})
T.press(1,100,200); T.release(1,100,200)
assert(#events==2 and events[1][4]==1 and events[2][1]=="release", "tap once")
events={}; T.press(1,100,200); T.update(0.51); T.update(1); T.release(1,100,200)
assert(#events==2 and events[1][4]==2, "hold activates exactly once without a tap")
events={}; T.press(1,100,200); T.press(2,400,400); T.move(2,420,420); T.release(2,420,420)
assert(#events==0,"second finger is ignored")
T.move(1,120,200); T.update(1); T.release(1,130,200)
assert(#events==3 and events[1][4]==1 and events[2][1]=="move", "drag suppresses hold")
events={}; T.press(1,100,200); T.cancel(); T.release(1,100,200)
assert(#events==1 and events[1][1]=="cancel", "focus loss cannot commit a gesture")
assert(love.mouse.getPosition()==100, "hover follows last touch")
events={}; scrolling=true; T.press(1,100,200); T.move(1,100,230); T.release(1,100,230)
assert(#events==1 and events[1][1]=="scroll", "scrolling a list cannot select an item")
print("Touch input smoke passed: tap, hold, drag, multitouch, cancellation, pointer, scrolling")
