local T={}
function T.verify()
    local UI,F,D=require("src.ui"),require("ui.components.card_frame"),require("src.deities")
    local g=love.graphics
    for tier=1,11 do
        local texture=require("ui.components.card_jewelwork").texture(tier)
        assert(texture:getWidth()==384 and texture:getHeight()==576,"frame cache must use bounded GPU dimensions")
        local data=texture:newImageData()
        for _,xx in ipairs({.35,.5,.65}) do for _,yy in ipairs({.3,.5,.7}) do
            local _,_,_,a=data:getPixel(math.floor(xx*384),math.floor(yy*576))
            assert(a==0,"jewel frame center must remain transparent: "..tier)
        end end
        data:release()
    end
    local grayscale=g.newShader([[vec4 effect(vec4 color,Image image,vec2 uv,vec2 screen){
        vec4 p=Texel(image,uv)*color;float l=dot(p.rgb,vec3(.2126,.7152,.0722));return vec4(l,l,l,p.a);} ]])
    local minimum=1
    for _,w in ipairs({46,82,200}) do
        local h=math.floor(w*1.5);local canvas=g.newCanvas(w+20,h+20)
        local masks={}
        for tier=1,11 do
            g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.translate(10,10)
            F.drawTierOrnaments(w,h,tier,1);g.pop()
            local data=canvas:newImageData();local mask={}
            for y=0,h+19 do for x=0,w+19 do
                local r,b,c,a=data:getPixel(x,y)
                if a>.1 then
                    assert(x>=10 and x<w+10 and y>=10 and y<h+10,"tier ornaments spill off card: "..tier.." / "..w.." / "..x..","..y)
                    assert(not(x>10+w*.23 and x<10+w*.77 and y>10+h*.22 and y<10+h*.75),"ornaments obscure portrait")
                    mask[y*(w+20)+x]={alpha=a,luma=(r*.2126+b*.7152+c*.0722)/a}
                end
            end end
            masks[tier]=mask;data:release()
        end
        -- Compare grayscale relief and silhouette, without text, art, sockets or animation.
        for a=1,10 do for b=a+1,11 do
            local union,changed=0,0
            for pixel,value in pairs(masks[a]) do
                union=union+1;local other=masks[b][pixel]
                if not other or math.abs(value.alpha-other.alpha)>.15 or math.abs(value.luma-other.luma)>.1 then changed=changed+1 end
            end
            for pixel in pairs(masks[b]) do if not masks[a][pixel] then union=union+1;changed=changed+1 end end
            local difference=changed/math.max(1,union)
            minimum=math.min(minimum,difference)
            assert(difference>.30,string.format("tier silhouettes too similar: %d/%d at %dpx: %.2f",a,b,w,difference))
        end end
        canvas:release()
    end
    local canvas=g.newCanvas(1280,370)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.015,.023,.038,1)
    g.setFont(UI.fonts.medium);g.setColor(.95,.95,.95,1);g.print("KHUNG KIM HOÀN · THANG XÁM · TẮT CHUYỂN ĐỘNG",28,18)
    for tier,rarity in ipairs(D.RARITIES) do
        local x=24+(tier-1)*125
        g.push("all");g.setShader(grayscale);g.translate(x,64)
        F.drawTierOrnaments(106,159,tier,1);g.translate(30,184)
        F.drawTierOrnaments(46,69,tier,1);g.pop()
        g.setFont(UI.fonts.small);g.setColor(1,1,1,1);g.printf(rarity.code,x,330,106,"center")
    end
    g.pop();grayscale:release()
    local data=canvas:newImageData();local file=assert(io.open("docs/frame_tier_silhouettes.png","wb"))
    file:write(data:encode("png"):getString());file:close();data:release();canvas:release()
    local J=require("ui.components.card_jewelwork")
    local sample=g.newCanvas(82,123)
    local function emission(tier,time)
        g.push("all");g.setCanvas(sample);g.origin();g.clear(0,0,0,0)
        J.effects(F.image,tier,0,0,82,123,1,time,false);g.pop()
        local data=sample:newImageData();local energy=0
        for y=0,122 do for x=0,81 do local r,b,c=data:getPixel(x,y);energy=energy+r+b+c end end
        data:release();return energy
    end
    local supreme,ascended=0,0
    for i=0,11 do
        supreme=supreme+emission(10,i/3)
        ascended=ascended+emission(11,i/3)
    end
    assert(ascended>supreme*1.8,"level ten must be substantially brighter than nine across a full cycle")
    -- Material appearance must never depend on whichever tier was drawn just before it.
    local function material(tier)
        g.push("all");g.setCanvas(sample);g.origin();g.clear(0,0,0,0)
        J.material(F.image,tier,0,0,82,123,1);g.pop()
        local data=sample:newImageData();local bytes=data:getString();data:release();return bytes
    end
    local before=material(3);emission(11,1.2);assert(before==material(3),"apex uniforms leak into lower-tier material")
    sample:release()
    print(string.format("Tier identity PASS: 55 grayscale relief/silhouette pairs at 46/82/200 px >= %.0f%% difference; level-ten emission %.2fx level nine; material isolation",minimum*100,ascended/supreme))
end
return T
