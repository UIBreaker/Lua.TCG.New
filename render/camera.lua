local C=require("config.visual_config").camera
local Camera={x=0,y=0,zoom=1,time=0,kickX=0,kickY=0,focusX=0,focusY=0,targetZoom=1}
function Camera.focus(x,y,zoom)
    Camera.focusX,Camera.focusY,Camera.targetZoom=x or 0,y or 0,zoom or 1
end
function Camera.kick(x,y)
    Camera.kickX=math.max(-C.maxKick,math.min(C.maxKick,x or 0))
    Camera.kickY=math.max(-C.maxKick,math.min(C.maxKick,y or 0))
end
function Camera.update(dt,idle,impulseX,impulseY)
    dt=math.min(dt,0.1); Camera.time=Camera.time+dt
    local t=Camera.time*C.speed; local k=1-math.exp(-C.response*dt)
    Camera.kickX=Camera.kickX*math.exp(-C.shakeDecay*dt)
    Camera.kickY=Camera.kickY*math.exp(-C.shakeDecay*dt)
    local x=Camera.focusX+math.sin(t)*C.idleX*(idle or 1)
    local y=Camera.focusY+math.cos(t*0.79)*C.idleY*(idle or 1)
    Camera.x=Camera.x+(x-Camera.x)*k; Camera.y=Camera.y+(y-Camera.y)*k
    Camera.zoom=Camera.zoom+(Camera.targetZoom-Camera.zoom)*k
    Camera.offsetX=Camera.x+Camera.kickX+(impulseX or 0)
    Camera.offsetY=Camera.y+Camera.kickY+(impulseY or 0)
end
function Camera.apply(factor)
    local g=love.graphics; factor=factor or 1
    g.translate(640,360); local z=1+(Camera.zoom-1)*factor
    g.scale(z,z); g.translate(-640+(Camera.offsetX or 0)*factor,-360+(Camera.offsetY or 0)*factor)
end
return Camera
