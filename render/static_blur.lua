-- The base painting and its blur radius are constant; camera/fog/particles stay live.
local B={bakes=0}
local source,radius,canvas
function B.clear()
    if canvas then canvas:release() end
    source,radius,canvas=nil,nil,nil
end
function B.get(image,amount,shader)
    if not image.typeOf or not image:typeOf('Image') then return nil end
    if source==image and radius==amount and canvas then return canvas end
    B.clear()
    local g=love.graphics;local w,h=image:getDimensions()
    local ok,value=pcall(g.newCanvas,w,h)
    if not ok then return nil end
    local ready=pcall(function()
        g.push('all');g.origin();g.setScissor();g.setCanvas(value);g.clear(0,0,0,0)
        g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.setShader(shader)
        shader:send('texel',{1/w,1/h});shader:send('radius',amount);g.draw(image)
    end)
    g.pop()
    if not ready then value:release();return nil end
    value:setFilter('linear','linear')
    source,radius,canvas=image,amount,value;B.bakes=B.bakes+1
    return canvas
end
return B
