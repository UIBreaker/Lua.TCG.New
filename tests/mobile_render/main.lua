function love.load(args)
    local ok,err=xpcall(function()
        local file=assert(io.open(assert(args[1]),'rb'));local archive=love.filesystem.newFileData(file:read('*a'),'art.love');file:close()
        assert(love.filesystem.mount(archive,''))
        local g=love.graphics
        require('src.touch_input').lowPower=true
        local Frame=require('ui.components.card_frame')
        local Art=require('src.continental_art');local image=assert(Art.get('hearts_2'))
        local function reference(w,h)
            local b=math.min(w,h)*.06
            local p={b,0,w-b,0,w,b,w,h-b,w-b,h,b,h,0,h-b,0,b}
            local v={{w/2,h/2,.5,.5,1,1,1,1}}
            for i=1,16,2 do v[#v+1]={p[i],p[i+1],p[i]/w,p[i+1]/h,1,1,1,1} end
            v[#v+1]=v[2];local m=g.newMesh(v,'fan','static');m:setTexture(image);g.draw(m);return m
        end
        local function compare(a,b,label,limit)
            local x,y=a:newImageData(),b:newImageData();local sum,n,maximum=0,0,0
            for py=0,x:getHeight()-1,3 do for px=0,x:getWidth()-1,3 do
                local ar,ag,ab,aa=x:getPixel(px,py);local br,bg,bb,ba=y:getPixel(px,py)
                for _,d in ipairs({ar-br,ag-bg,ab-bb,aa-ba}) do sum=sum+d*d;n=n+1;maximum=math.max(maximum,math.abs(d)) end
            end end
            x:release();y:release();local rms=math.sqrt(sum/n)
            print(('%s pixel RMSE %.5f; max %.5f'):format(label,rms,maximum));assert(rms<limit,label)
        end
        for _,w in ipairs({64,128,193.37}) do
            local a,b=g.newCanvas(640,480),g.newCanvas(640,480)
            local mesh
            for i,target in ipairs({a,b}) do
                g.push('all');g.setCanvas(target);g.clear();g.origin();g.translate(180,55);g.rotate(.12);g.shear(.08,0);g.setColor(1,1,1,.73)
                if i==1 then mesh=reference(w,w*1.5) else Frame.image(image,0,0,w,w*1.5) end;g.pop()
            end
            compare(a,b,'normalized mesh '..w,.001);mesh:release();a:release();b:release()
        end
        for i=1,3000 do Frame.image(image,0,0,90+i*.001,(90+i*.001)*1.5) end
        assert(Frame.meshCount()<=4,'animation scale grew mesh cache')
        for i=1,100 do Frame.image(image,0,0,100,100+i) end
        assert(Frame.meshCount()<=64,'mesh cache exceeds cap')
        if args[2] then
            local f=assert(io.open(args[2],'rb'));local oldData=love.filesystem.newFileData(f:read('*a'),'before.love');f:close()
            assert(love.filesystem.mount(oldData,'before'))
            local old=assert(love.filesystem.load('before/ui/components/card_frame.lua'))()
            for _,tier in ipairs({1,3,6,10}) do for _,alpha in ipairs({1,.45}) do
                local card={id='spirit_galefang',baseRarityTier=tier,alpha=alpha}
                local a,b=g.newCanvas(256,384),g.newCanvas(256,384)
                for i,target in ipairs({a,b}) do
                    g.push('all');g.setCanvas(target);g.clear(.08,.08,.08,1);g.origin();g.translate(40,40);g.rotate(.07)
                    local renderer=i==1 and old or Frame
                    renderer.draw(11.3,13.7,128,192,{.8,.6,.2,1},nil,card,.75,false)
                    g.pop()
                end
                compare(a,b,'frame tier '..tier..' alpha '..alpha,.002);a:release();b:release()
            end end
        end
        local first=Art.withIndices(image,'hearts',2)
        for i=3,80 do Art.withIndices(image,'hearts',i) end
        local count=0;for _,entries in pairs(Art.indexed) do for _ in pairs(entries) do count=count+1 end end
        assert(count<=16 and first:getWidth()==512,'indexed cache cap or active reference invalidation')
        local Blur=require('render.static_blur');local shader=g.newShader('shaders/world_depth.glsl')
        local background=g.newImage('assets/scene/shrine_lowpoly.png')
        local cached=assert(Blur.get(background,.85,shader));local baked=Blur.bakes
        for _=1,100 do assert(Blur.get(background,.85,shader)==cached) end
        assert(Blur.bakes==baked,'static blur repeated per frame')
        for _,size in ipairs({{960,540},{1920,1080}}) do
            local a,b=g.newCanvas(unpack(size)),g.newCanvas(unpack(size))
            for i,target in ipairs({a,b}) do
                g.push('all');g.setCanvas(target);g.clear();g.origin();g.setColor(1,1,1,1)
                if i==1 then shader:send('texel',{1/background:getWidth(),1/background:getHeight()});shader:send('radius',.85);g.setShader(shader) else g.setShader() end
                g.draw(i==1 and background or cached,0,0,0,size[1]/background:getWidth(),size[2]/background:getHeight());g.pop()
            end
            compare(a,b,'cached depth blur '..size[1],.012);a:release();b:release()
        end
        Blur.clear();shader:release();background:release()
        print('Mobile render PASS: equivalent clipped art, bounded geometry/index caches, live references, cached blur/fallback')
    end,debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
