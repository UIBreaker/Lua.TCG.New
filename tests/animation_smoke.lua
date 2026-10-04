-- lua tests/animation_smoke.lua (no GPU required)
local Motion = require("src.motion")
local function close(a, b) assert(math.abs(a-b)<0.000001, "motion depends on frame rate") end
for _, damping in ipairs({15, 20, 32}) do
    local x, v = Motion.spring(0, 80, 100, 100, damping, 0.4)
    for _, fps in ipairs({30, 60, 120, 144}) do
        local px, pv = 0, 80
        for _=1,fps do px,pv=Motion.spring(px,pv,100,100,damping,0.4/fps) end
        close(px,x); close(pv,v)
    end
    local px,pv=Motion.spring(0,80,100,100,damping,0.1)
    px,pv=Motion.spring(px,pv,100,100,damping,0.3)
    close(px,x);close(pv,v) -- One stalled frame keeps the same trajectory.
end
for _, fps in ipairs({30,60,120,144}) do
    local x=0
    for _=1,fps do x=x+(1-x)*Motion.response(18,1/fps) end
    close(x,1-math.exp(-18))
end
assert(Motion.response(18,0)==0 and Motion.response(18,-1)==0)
local x,v=Motion.spring(0,500,-30,600,32,1/240)
assert(x>0 and v>0,"reversing direction must preserve momentum")

-- Recreated button tables must retain a soft hover and release transition.
local scales={}
local font={getWidth=function(_,s) return #s*6 end,getHeight=function() return 12 end}
local noop=function() end
love={graphics={push=noop,pop=noop,translate=noop,scale=function(s) scales[#scales+1]=s end,
    rectangle=noop,setLineWidth=noop,getFont=function() return font end}}
package.loaded["ui.components.core"]={color=noop,gradient=noop,text=noop}
local Button=require("ui.components.button")
local function draw(state)
    scales={}
    Button.draw({id="test",text="Play",x=10,y=10,w=100,h=32},state)
    return scales[#scales] or 1
end
draw("normal");Button.update(1/60)
local hover=draw("hover")
assert(hover>1 and hover<1.012,"hover should ease into scale")
Button.update(1/60)
local release=draw("normal")
assert(release>1 and release<hover,"hover exit should ease out")
Button.update(0.1);draw("pressed")
assert(scales[#scales]<1,"press should compress the button")
close(draw("disabled"),1)
Button.update(2);draw("normal")
print("Animation passed: 30/60/120/144 FPS, three spring regimes, stalled frames, momentum, button hover/press/release")
