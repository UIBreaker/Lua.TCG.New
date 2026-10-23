local C={}

-- Shared by the real timing result and the exported preview; glyphs use the game font.
function C.draw(text,grade,x,y,w,font,age,reduced)
    local g=love.graphics
    local p=require("src.timing_vfx").profiles[grade] or require("src.timing_vfx").profiles.normal
    local c=p.color;age=age or 0
    local scale=math.min(1,(w-24)/math.max(1,font:getWidth(text)))
    local tw,th=font:getWidth(text)*scale,font:getHeight()*scale
    local tx=x+(w-tw)/2
    g.push("all");g.setBlendMode("alpha");g.setFont(font)
    g.setColor(.008,.012,.025,.95);g.print(text,tx,y+1,0,scale,scale)
    g.setColor(c[1],c[2],c[3]);g.print(text,tx,y,0,scale,scale)
    if p.rank>=3 and not reduced then
        -- Clip a brief light sweep to the glyphs themselves, without a glow copy.
        local phase=math.min(1,age/.36)
        local sweep=tx-12+(tw+24)*phase
        local sx,sy=g.transformPoint(sweep,y)
        local ex,ey=g.transformPoint(sweep+9,y+th)
        g.push("all");g.intersectScissor(math.min(sx,ex),math.min(sy,ey),math.abs(ex-sx),math.abs(ey-sy))
        g.setColor(1,1,1,.8*math.sin(phase*math.pi))
        g.print(text,tx,y,0,scale,scale);g.pop()
        for i=1,math.min(3,p.rank-1) do
            local pulse=math.max(0,math.sin(age*15-i*1.8))^4
            local sx=tx+tw*(i/(math.min(3,p.rank-1)+1))
            local sy=y+(i%2==0 and th*.9 or th*.05)
            local h=(2+p.rank*.3)*pulse
            if h>.15 then
                g.setColor(1,.97,1,pulse*.95)
                g.polygon("fill",sx,sy-h,sx+h*.3,sy,sx,sy+h,sx-h*.3,sy)
            end
        end
    end
    g.pop()
end
return C
