local T={}
function T.verify()
    local UI=require("src.ui")
    local Frame,D,Rng=UI.CardFrame,require("src.deities"),require("src.rng")
    local g=love.graphics
    local originalTime=UI.Polish.time
    local rng=Rng.getState()
    for _,size in ipairs({{46,69},{82,118},{200,300}}) do
        local w,h=size[1],size[2]
        local canvas=g.newCanvas(w+20,h+20)
        local function render(card,time,reduced)
            g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.translate(10,10)
            g.setColor(.2,.3,.4,.7);g.setLineWidth(3.25)
            local px,py=g.transformPoint(2,3)
            Frame.drawRarityPennant(card,w,h,UI.fonts.medium,time,reduced)
            local r,b,c,a=g.getColor();local xx,yy=g.transformPoint(2,3)
            assert(math.abs(r-.2)+math.abs(b-.3)+math.abs(c-.4)+math.abs(a-.7)<.001
                and xx==px and yy==py and g.getLineWidth()==3.25,"badge leaks graphics state")
            g.pop()
            return canvas:newImageData()
        end
        for _,rarity in ipairs(D.RARITIES) do
            local card={id="spirit_ember",rarity=rarity.id}
            local data=render(card,.2,false)
            local lit,dark,bright=0,0,0
            for yy=0,h+19 do for xx=0,w+19 do
                local r,b,c,a=data:getPixel(xx,yy)
                if a>.01 then
                    assert(xx>=10 and xx<w+10 and yy>=10 and yy<h+10,"badge spills outside card: "..rarity.id)
                    assert(xx>=10+w*.45 and yy<10+h*.40,"badge obstructs card centre: "..rarity.id)
                    lit=lit+1
                    if math.max(r,b,c)<.15 then dark=dark+1 end
                    if math.min(r,b,c)>.6 then bright=bright+1 end
                end
            end end
            assert(lit>15 and dark>0 and bright>0,"badge loses metal/enamel contrast at small sizes: "..rarity.id)
            data:release()
            local first=render(card,.2,true);local second=render(card,2.2,true)
            assert(first:getString()==second:getString(),"Reduced Motion must keep insignia static")
            first:release();second:release()
            if D.getRarityTier(card)>=5 then
                first=render(card,.2,false);second=render(card,2.2,false)
                assert(first:getString()~=second:getString(),"high rarity has no living shimmer: "..rarity.id)
                first:release();second:release()
            end
            card.alpha=0;data=render(card,1,false)
            for yy=0,h+19 do for xx=0,w+19 do local _,_,_,a=data:getPixel(xx,yy);assert(a==0,"badge survives card fade") end end
            data:release()
        end
        canvas:release()
    end
    local card={id="spirit_ember",rarity="supreme",evolutionLevel=123}
    local actual=Frame.drawRarityPennant
    Frame.drawRarityPennant=function(c,w,h,...)
        local state=assert(UI.CardPhysics.getState(c))
        local x,y=g.transformPoint(0,0)
        assert(math.abs(x-state.ox)+math.abs(y-state.oy)<.001,"badge detached from moving card")
        return actual(c,w,h,...)
    end
    UI.CardPhysics.update(1/60,-1000,-1000);UI.CardPhysics.beginFrame(true)
    UI.drawPatronCard(card,200,100,128,192);UI.CardPhysics.endFrame()
    Frame.drawRarityPennant=actual
    local canvas=g.newCanvas(1280,850)
    local function sheet(time)
        UI.Polish.time=time
        g.push("all");g.setCanvas(canvas);g.origin();g.clear(.015,.023,.038,1)
        g.setFont(UI.fonts.title);g.setColor(.96,.85,.60,1);g.print("HUY HIỆU SPN · 10 BẬC",38,22)
        g.setFont(UI.fonts.small);g.setColor(.62,.70,.79,1)
        g.print("KIM LOẠI · BẢO THẠCH · VƯƠNG MIỆN · HÀO QUANG",40,62)
        UI.CardPhysics.suspend()
        for i,rarity in ipairs(D.RARITIES) do
            local x,y=40+(i-1)%5*248,110+math.floor((i-1)/5)*350
            local item={id="spirit_ember",rarity=rarity.id}
            UI.drawPatronCard(item,x,y,156,234)
            local bx,by,bw=Frame.pennantRect(200,300,item)
            g.push();g.translate(x+166+(64-bw)/2-bx,y+38-by)
            Frame.drawRarityPennant(item,200,300,UI.fonts.medium,time,false);g.pop()
            g.setFont(UI.fonts.medium);g.setColor(rarity.color);g.print(rarity.code,x,y+248)
            g.setFont(UI.fonts.small);g.setColor(.91,.93,.96,1);g.print(rarity.name,x,y+277)
        end
        UI.CardPhysics.resume();g.pop()
    end
    local function save(path)
        local data=canvas:newImageData();local file=assert(io.open(path,"wb"))
        file:write(data:encode("png"):getString());file:close();data:release()
    end
    sheet(1.3);save("docs/spn_rarity_badges.png")
    local video=os.getenv("POKER_RARITY_VIDEO")
    if video then for i=0,71 do sheet(i/24);save(video..string.format("/frame_%03d.png",i)) end end
    canvas:release();UI.Polish.time=originalTime
    assert(Rng.getState()==rng,"badge presentation must not consume gameplay RNG")
    print("SPN insignia PASS: 10 tiers at 46/82/200 px, bounded silhouette and contrast, animated/reduced, graphics isolation, alpha and attached transform, overflow, no gameplay RNG")
end
return T
