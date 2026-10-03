-- Native card surface: original creature paintings stay intact. Rank/suit and
-- strength trims are authored here, matching the human deck's corner layout.
local C = {cache={}}
function C.image(monster, illustration)
    if not illustration then return nil end
    local Art=require("src.enemy_art")
    local key=Art.key(monster).."_"..tostring(monster.cardRank or 2)
    if C.cache[key] then return C.cache[key] end
    local g=love.graphics
    local rank=monster.cardRank or 2;local suit=monster.cardSuit or "spades"
    local color=(suit=="hearts" or suit=="diamonds") and {0.74,0.12,0.18} or {0.08,0.14,0.30}
    local canvas=g.newCanvas(256,384)
    local previous=g.getCanvas()
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setShader();g.setScissor();g.setBlendMode("alpha")
    g.setColor(0.14,0.12,0.09,1);g.rectangle("fill",2,2,252,380,12,12)
    g.setColor(0.92,0.86,0.70,1);g.rectangle("fill",5,5,246,374,10,10)
    g.setColor(0.14,0.22,0.27,1);g.rectangle("fill",12,12,232,360,6,6)
    for i=0,29 do
        local p=i/29
        g.setColor(0.08+p*0.12,0.15+p*0.10,0.22+p*0.06,1);g.rectangle("fill",12,12+i*12,232,12)
    end
    -- Concentric atmosphere emphasizes the creature without enlarging the card.
    for i=6,1,-1 do
        g.setColor(0.42,0.62,0.70,0.025);g.ellipse("fill",128,188,18+i*13,26+i*17)
    end
    local art=require("render.scene").art or {}
    local backdrop=(monster.creatureKind=="lava_golem" or monster.creatureKind=="ancient_skeleton")
        and "background" or monster.creatureKind=="frost_wolf" and "expeditionShip" or "mysteriousCoast"
    local scene=art[backdrop]
    -- Match the human deck's illustrated landscape, rather than a floating sprite.
    if scene then
        local bw,bh=scene:getDimensions();local cover=math.max(232/bw,360/bh)
        g.setScissor(12,12,232,360);g.setColor(0.74,0.77,0.79,1)
        g.draw(scene,128-bw*cover/2,192-bh*cover/2,0,cover,cover);g.setScissor()
    end
    local iw,ih=illustration:getDimensions();local fit=math.min(218/iw,302/ih)
    g.setColor(1,1,1,1);g.draw(illustration,128-iw*fit/2,193-ih*fit/2,0,fit,fit)
    -- Fine engraved metal surrounds a full-width painting; no empty side rail.
    g.setColor(0.42,0.30,0.15,1);g.setLineWidth(1);g.rectangle("line",5,5,246,374,10,10)
    g.setColor(0.88,0.72,0.43,1);g.setLineWidth(rank>=11 and 2 or 1)
    g.rectangle("line",11,11,234,362,6,6)
    for _,corner in ipairs({{0,0},{256,0},{0,384},{256,384}}) do
        g.push();g.translate(corner[1],corner[2]);g.scale(corner[1]==0 and 1 or -1,corner[2]==0 and 1 or -1)
        g.setColor(0.91,0.78,0.51,1);g.line(16,38,16,22,22,16,38,16)
        g.polygon("fill",20,20,25,18,30,20,25,23);g.pop()
    end
    -- Mirrored parchment ribbons use the same angled index silhouette as humans.
    local function indexField()
        g.setColor(0.24,0.16,0.08,0.5);g.polygon("fill",12,12,62,12,62,79,48,96,12,110)
        g.setColor(0.98,0.94,0.82,1);g.polygon("fill",12,12,58,12,58,77,44,91,12,104)
        g.setColor(0.74,0.58,0.32,1);g.setLineWidth(1);g.line(58,13,58,77,44,91,12,104)
        g.setColor(0.87,0.79,0.62,1);g.line(17,17,52,17)
    end
    indexField();g.push();g.translate(256,384);g.rotate(math.pi);indexField();g.pop()
    C.rankFont=C.rankFont or g.newFont("fonts/arialbd.ttf",37)
    g.setFont(C.rankFont);g.setColor(color[1],color[2],color[3],1)
    local label=require("src.expedition").rankName(rank)
    g.printf(label,11,9,43,"center")
    local function drawSuit()
        g.setColor(color[1],color[2],color[3],1)
        if suit=="diamonds" then g.polygon("fill",33,51,43,65,33,79,23,65)
        elseif suit=="clubs" then
            g.circle("fill",33,57,6);g.circle("fill",26,66,6);g.circle("fill",40,66,6);g.polygon("fill",33,63,27,79,39,79)
        elseif suit=="hearts" then
            g.circle("fill",27,59,6);g.circle("fill",39,59,6);g.polygon("fill",21,60,45,60,33,79)
        else
            g.polygon("fill",33,51,21,66,45,66);g.circle("fill",27,66,6);g.circle("fill",39,66,6);g.polygon("fill",33,63,27,79,39,79)
        end
    end
    drawSuit()
    g.push();g.translate(256,384);g.rotate(math.pi)
    g.printf(label,11,9,43,"center");drawSuit();g.pop()
    g.setCanvas(previous);g.pop();canvas:setFilter("linear","linear")
    C.cache[key]=canvas;return canvas
end
return C
