local T = {}
function T.verify()
    local UI = require("src.ui")
    local Frame, Entity = UI.CardFrame, require("render.entity")
    local Deities = require("src.deities")
    local g = love.graphics
    local image = UI.getCardImage("hearts",3)
    local canvas = g.newCanvas(900,math.ceil((#Deities.RARITIES+1)/3)*350)
    local originalImage, originalDraw = Frame.image, Frame.draw
    local facePosition, framePosition
    Frame.image = function(art,x,y,w,h)
        facePosition={g.transformPoint(x,y)}
        return originalImage(art,x,y,w,h)
    end
    Frame.draw = function(x,y,w,h,...)
        framePosition={g.transformPoint(x,y)}
        return originalDraw(x,y,w,h,...)
    end
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0)
    local preset={lightTint={1,0.8,0.5},ambientColor={1,1,1}}
    for _, motion in ipairs({{0,0,1},{0.6,-8,0.85},{-0.2,11,1.13}}) do
        local card={hp=20}
        Entity.draw(image,450,280,192,1,motion[1],0,motion[2],motion[3],preset,0,true,{1,0.8,0.4,1},card)
        assert(facePosition and framePosition and math.abs(facePosition[1]-framePosition[1])<0.001
            and math.abs(facePosition[2]-framePosition[2])<0.001,"frame must move with the face during attack and recoil")
        local face=assert(Entity.face(card))
        assert(math.abs(face[1]-facePosition[1])+math.abs(face[2]-facePosition[2])<.001,"sharp targeting geometry must follow attack/recoil transforms")
    end
    Frame.image,Frame.draw=originalImage,originalDraw
    local calls, drawBorder=0,UI.drawCardBorder
    UI.drawCardBorder=function(...) calls=calls+1;return drawBorder(...) end
    local dead={hp=0,maxHp=20,human=true,kingdom="Elaris",cardRank=3,attack=4,attackSpeed=1}
    local alive={hp=22,maxHp=22,human=true,kingdom="Valoria",cardRank=3,attack=4,attackSpeed=10}
    local enemies={dead,alive};dead.group=enemies;alive.group=enemies
    require("ui.enemy_formation").hud({enemies=enemies,monster=alive},UI,-1000,-1000)
    UI.drawCardBorder=drawBorder
    assert(calls==0,"HUD must never leave a stationary or dead enemy frame")
    g.pop()
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.03,0.045,1)
    UI.CardPhysics.suspend()
    local patron={id="spirit_ember",rarity="common",name="Tàn Hỏa"}
    local previous
    for level=0,#Deities.RARITIES do
        local x,y=(level%3)*300+50,math.floor(level/3)*350+10
        UI.drawPatronCard(patron,x,y,200,300)
        -- The top-centre border changes at every level, independently of rarity text.
        g.setCanvas()
        local data=canvas:newImageData(1,1,x,y,200,300)
        g.setCanvas(canvas)
        local pixels=data:getString()
        assert(not previous or pixels~=previous,"each evolution must improve the frame, including TT overflow")
        previous=pixels;data:release()
        g.setColor(1,1,1,1);g.setFont(UI.fonts.small)
        g.printf(level==0 and "Khung cơ bản" or ("Tiến hóa "..level),x-25,y+311,250,"center")
        assert(Deities.evolve(patron))
    end
    UI.CardPhysics.resume();g.pop()
    local file=assert(io.open("docs/card_frame_evolution.png","wb"))
    file:write(canvas:newImageData():encode("png"):getString());file:close();canvas:release()
    print("Card frame motion PASS: attached attack/recoil, no stationary/dead HUD rim, "..(#Deities.RARITIES+1).." evolution appearances")
end
return T
