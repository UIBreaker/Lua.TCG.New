local T={}
function T.verify()
    local UI,Deck,I=require("src.ui"),require("src.deck"),require("ui.components.card_inscriptions")
    local Visual,Rng=require("config.visual_config"),require("src.rng")
    local g=love.graphics
    local oldTime,oldReduced,quality,enabled=UI.Polish.time,UI.Polish.reducedMotion,Visual.quality,Visual.enabled
    local rng=Rng.getState()
    local speeds={12,15,25,40,65,100,175,300,600,999}
    local damages={3,10,25,50,100,250,500,1000,2500,10000}
    local cards={}
    for i=1,10 do
        local card=Deck.newCard(({2,10,11,12,13,14,7,10,12,14})[i],({"hearts","diamonds","clubs","spades"})[(i-1)%4+1])
        card.evolutionLevel=math.min(8,i-1);card.temporaryAbilityLevels=math.max(0,i-9)
        card.speedBonus=speeds[i]-Deck.getAttackSpeed(card.rank);card.baseChips=damages[i]
        assert(I.statTier("speed",Deck.getCardAttackSpeed(card))==i and I.statTier("damage",card.baseChips)==i)
        cards[i]=card
    end
    assert(I.statTier("damage",0)==1 and I.statTier("damage",1e12)==10 and I.statTier("speed",999)==10)
    assert(I.statTier("speed",24.9)==2 and I.statTier("speed",25)==3)
    assert(I.statTier("damage",99.9)==4 and I.statTier("damage",100)==5)
    for _,size in ipairs({{46,69},{82,123},{200,300}}) do
        local w,h=size[1],size[2]
        local canvas=g.newCanvas(w,h)
        local function render(card,time,reduced)
            UI.Polish.time=time;UI.Polish.reducedMotion=reduced
            g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0)
            g.setColor(.2,.3,.4,.7);g.setLineWidth(2.5)
            UI.drawPlayingMetadata(card,w,h,true)
            local r,b,c,a=g.getColor()
            assert(math.abs(r-.2)+math.abs(b-.3)+math.abs(c-.4)+math.abs(a-.7)<.001 and g.getLineWidth()==2.5,"inscriptions leak graphics state")
            g.pop();return canvas:newImageData()
        end
        for i,card in ipairs(cards) do
            local a,b=render(card,.2,false),render(card,1.9,false)
            assert((a:getString()~=b:getString())==(i>1),"inscription motion must grow with stats and evolution")
            a:release();b:release()
            a,b=render(card,.2,true),render(card,1.9,true)
            assert(a:getString()==b:getString(),"Reduced Motion animates inscriptions")
            a:release();b:release()
        end
        local card=cards[10]
        Visual.quality="LOW"
        local a,b=render(card,.2,false),render(card,1.9,false)
        assert(a:getString()~=b:getString(),"LOW must keep inscription motion")
        a:release();b:release();Visual.quality=quality
        Visual.enabled=false
        a,b=render(card,.2,false),render(card,1.9,false)
        assert(a:getString()==b:getString(),"disabled effects animate inscriptions")
        a:release();b:release();Visual.enabled=enabled
        card.alpha=0;a=render(card,0,false);card.alpha=1;card.faceDown=true;b=render(card,0,false)
        assert(a:getString()==b:getString(),"hidden card leaves inscriptions")
        for y=0,h-1 do for x=0,w-1 do local r,b,c,alpha=a:getPixel(x,y);assert(r+b+c+alpha==0) end end
        a:release();b:release();card.faceDown=nil
        local identities={}
        for _,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
            for rank=2,14 do
                local sample=Deck.newCard(rank,suit)
                local data=render(sample,0,true);data:release()
                local crop=canvas:newImageData(1,1,math.floor(w*7/128),math.floor(h*7/192),math.ceil(w*30/128),math.ceil(h*56/192))
                local bytes=crop:getString()
                assert(not identities[bytes],"rank/suit badge is indistinguishable: "..suit.." / "..rank.." / "..w)
                identities[bytes]=true;crop:release()
            end
        end
        canvas:release()
    end
    -- Text must retain the real values, including fractions and large damage.
    local printf=g.printf;local labels={}
    g.printf=function(label,...) labels[tostring(label)]=true;return printf(label,...) end
    local card=Deck.newCard(3,"hearts");card.speedBonus=14.125;card.baseChips=123456789
    UI.drawPlayingMetadata(card,128,192,true);g.printf=printf
    assert(labels["25.125"] and labels["ST 123456789"],"inscriptions changed or rounded stat values")
    local canvas=g.newCanvas(1280,920)
    local function sheet(time)
        UI.Polish.time=time;UI.Polish.reducedMotion=false
        g.push("all");g.setCanvas(canvas);g.origin();g.clear(.015,.023,.038,1)
        g.setFont(UI.fonts.title);g.setColor(.96,.85,.60,1);g.print("QUÂN BÀI · SỐ, CHẤT & DANH HIỆU",38,22)
        g.setFont(UI.fonts.small);g.setColor(.68,.75,.83,1)
        g.print("MEN NGÀ · SỐ LỚN · BIỂU TƯỢNG SẮC NÉT · VIỀN THEO TIẾN HÓA",40,62)
        UI.CardPhysics.suspend()
        for i,card in ipairs(cards) do
            local x,y=40+(i-1)%5*248,110+math.floor((i-1)/5)*390
            UI.drawCard(card,x,y,200,300)
            local rarity=require("src.deities").RARITIES[i]
            g.setFont(UI.fonts.medium);g.setColor(rarity.color);g.print(rarity.code,x,y+311)
            g.setFont(UI.fonts.small);g.setColor(.91,.93,.96,1)
            g.print("Tốc "..speeds[i].." · ST "..damages[i],x,y+339)
        end
        UI.CardPhysics.resume();g.pop()
    end
    local function save(path)
        local data=canvas:newImageData();local f=assert(io.open(path,"wb"))
        f:write(data:encode("png"):getString());f:close();data:release()
    end
    sheet(1.3);save("docs/playing_card_inscriptions.png")
    save("docs/playing_card_identity.png")
    local video=os.getenv("POKER_INSCRIPTIONS_VIDEO")
    if video then for i=0,95 do sheet(i/24);save(video..string.format("/frame_%03d.png",i)) end end
    canvas:release();UI.Polish.time=oldTime;UI.Polish.reducedMotion=oldReduced
    assert(Rng.getState()==rng,"inscriptions consumed gameplay RNG")
    print("Card inscriptions PASS: 52 unique rank/suit badges at 3 sizes, 10 stat/evolution tiers, precise values, motion/LOW/Reduced/off/hidden, graphics isolation, no gameplay RNG")
end
return T
