local T={}
function T.verify()
    local UI=require("src.ui")
    local Frame,D,Rng=UI.CardFrame,require("src.deities"),require("src.rng")
    local Visual=require("config.visual_config")
    local g=love.graphics
    local originalTime,quality,enabled=UI.Polish.time,Visual.quality,Visual.enabled
    local rng=Rng.getState()
    local function playingCard(tier)
        local card=require("src.deck").newCard(3,({"hearts","diamonds","clubs","spades"})[(tier-1)%4+1])
        local maxLevel=require("config.card_ability_data").maxEvolutionLevel
        card.evolutionLevel=math.min(tier-1,maxLevel)
        card.temporaryAbilityLevels=math.max(0,tier-1-maxLevel)
        local shown,overflow=Frame.tier(card)
        assert(shown==math.min(tier,10) and overflow==math.max(0,tier-10),"playing frame must follow permanent and temporary evolution")
        return card
    end
    for _,size in ipairs({{46,69},{82,118},{200,300}}) do
        local w,h=size[1],size[2]
        local canvas=g.newCanvas(w+20,h+20)
        local function render(card,time,reduced,opacity)
            g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.translate(10,10)
            g.setColor(.2,.3,.4,.7);g.setLineWidth(3.25)
            local tx,ty=g.transformPoint(1,2)
            Frame.drawEnergy(0,0,w,h,card,opacity or 1,time,reduced)
            local r,b,c,a=g.getColor();local xx,yy=g.transformPoint(1,2)
            assert(math.abs(r-.2)+math.abs(b-.3)+math.abs(c-.4)+math.abs(a-.7)<.001
                and xx==tx and yy==ty and g.getLineWidth()==3.25,"frame energy leaks graphics state")
            g.pop();return canvas:newImageData()
        end
        for _,playing in ipairs({false,true}) do
        for tier=1,#D.RARITIES+(playing and 1 or 0) do
            local rarity=D.RARITIES[math.min(tier,#D.RARITIES)]
            local card=playing and playingCard(tier) or {id="spirit_ward",rarity=rarity.id}
            local first=render(card,.2,false);local second=render(card,1.9,false)
            assert((first:getString()~=second:getString())==(tier>=2),"rarity motion progression: "..rarity.id)
            local lit=0
            for yy=0,h+19 do for xx=0,w+19 do
                local r,b,c,a=first:getPixel(xx,yy)
                if math.max(r,b,c,a)>.005 then
                    lit=lit+1
                    assert(xx>=10 and xx<w+10 and yy>=10 and yy<h+10,"frame energy spills off card")
                    assert(not(xx>10+w*.27 and xx<10+w*.73 and yy>10+h*.2 and yy<10+h*.8),"frame energy obscures subject")
                end
            end end
            assert((lit>0)==(tier>=2),"missing frame emission: "..rarity.id.." / "..w)
            first:release();second:release()
            first=render(card,.2,true);second=render(card,1.9,true)
            assert(first:getString()==second:getString(),"Reduced Motion still animates frame")
            first:release();second:release()
            first=render(card,.2,false,0);card.faceDown=true;second=render(card,.2,false)
            assert(first:getString()==second:getString(),"faded/face-down card leaves frame energy")
            first:release();second:release()
        end
        end
        for _,card in ipairs({{id="spirit_ward",rarity="supreme"},playingCard(11)}) do
        Visual.quality="LOW"
        local first=render(card,.2,false);local second=render(card,1.9,false)
        assert(first:getString()~=second:getString(),"LOW must retain high-tier frame motion")
        first:release();second:release();Visual.quality=quality
        Visual.enabled=false
        first=render(card,.2,false);second=render(card,1.9,false)
        assert(first:getString()==second:getString(),"disabled effects must freeze frame")
        first:release();second:release();Visual.enabled=enabled
        end
        canvas:release()
    end
    local actual=Frame.drawEnergy
    Frame.drawEnergy=function(x,y,w,h,card,...)
        local state=assert(UI.CardPhysics.getState(card))
        local xx,yy=g.transformPoint(x,y)
        assert(math.abs(xx-state.ox)+math.abs(yy-state.oy)<.001,"energy detaches during card motion")
        return actual(x,y,w,h,card,...)
    end
    UI.CardPhysics.update(1/60,-1000,-1000);UI.CardPhysics.beginFrame(true)
    UI.drawPatronCard({id="spirit_ward",rarity="supreme"},200,100,128,192);UI.CardPhysics.endFrame()
    UI.CardPhysics.beginFrame(true);UI.drawCard(playingCard(10),200,100,128,192);UI.CardPhysics.endFrame()
    Frame.drawEnergy=actual
    local canvas=g.newCanvas(1280,920)
    local function sheet(time,playing)
        UI.Polish.time=time
        g.push("all");g.setCanvas(canvas);g.origin();g.clear(.015,.023,.038,1)
        g.setFont(UI.fonts.title);g.setColor(.96,.85,.60,1);g.print(playing and "QUÂN BÀI · VIỀN THEO TIẾN HÓA" or "VIỀN SPN · SỨC MẠNH THEO BẬC",38,22)
        g.setFont(UI.fonts.small);g.setColor(.62,.70,.79,1)
        g.print("KIM LOẠI VÁT CẠNH · DÒNG NĂNG LƯỢNG · TINH TÚ · BÙNG SÁNG",40,62)
        UI.CardPhysics.suspend()
        for i,rarity in ipairs(D.RARITIES) do
            local x,y=40+(i-1)%5*248,110+math.floor((i-1)/5)*390
            if playing then UI.drawCard(playingCard(i),x,y,200,300)
            else UI.drawPatronCard({id="spirit_ward",rarity=rarity.id},x,y,200,300) end
            g.setFont(UI.fonts.medium);g.setColor(rarity.color);g.print(rarity.code,x,y+311)
            g.setFont(UI.fonts.small);g.setColor(.91,.93,.96,1)
            g.print(playing and ("Tiến hóa "..(i-1)) or rarity.name,x,y+339)
        end
        UI.CardPhysics.resume();g.pop()
    end
    local function save(path)
        local data=canvas:newImageData();local file,err=io.open(path,"wb")
        -- Windows previews may briefly hold a regenerated gallery open.
        for attempt=1,10 do
            if file then break end
            love.timer.sleep(.1);file,err=io.open(path,"wb")
        end
        assert(file,err)
        file:write(data:encode("png"):getString());file:close();data:release()
    end
    sheet(1.3);save("docs/spn_rarity_frames.png")
    local video=os.getenv("POKER_FRAME_VIDEO")
    if video then for i=0,95 do sheet(i/24);save(video..string.format("/frame_%03d.png",i)) end end
    sheet(1.3,true);save("docs/playing_card_frames.png")
    local playingVideo=os.getenv("POKER_PLAYING_FRAME_VIDEO")
    if playingVideo then for i=0,95 do sheet(i/24,true);save(playingVideo..string.format("/frame_%03d.png",i)) end end
    local cards={};for i=1,15 do cards[i]={id="spirit_ward",rarity="supreme"} end
    UI.CardPhysics.suspend();g.push("all");g.setCanvas(canvas);g.origin()
    local function stress(time)
        UI.Polish.time=time;g.clear(.015,.023,.038,1)
        for i,card in ipairs(cards) do UI.drawPatronCard(card,20+(i-1)%8*115,20+math.floor((i-1)/8)*160,82,118) end
        g.flushBatch()
    end
    stress(0);local before=g.getStats();local start=love.timer.getTime()
    for i=1,45 do stress(i/60) end
    local ms=(love.timer.getTime()-start)/45*1000
    local after=g.getStats()
    assert(after.images==before.images and after.canvases==before.canvases,"living frames allocate GPU resources per frame")
    g.pop();UI.CardPhysics.resume();canvas:release()
    UI.Polish.time=originalTime
    assert(Rng.getState()==rng,"frame effects consumed gameplay RNG")
    print(string.format("SPN and playing frames PASS: 10 tiers/3 sizes, motion/Reduced/fade, subject clearance, attached transform, graphics isolation; SPN LOW/off/no gameplay RNG/GPU allocation; 15 TT cards %.2f ms/render",ms))
end
return T
