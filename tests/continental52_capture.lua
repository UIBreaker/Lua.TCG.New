local UI=require("src.ui")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local function save(canvas,path)
    local data=canvas:newImageData();local f=assert(io.open(path,"wb"))
    f:write(data:encode("png"):getString());f:close();data:release()
end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    io.stdout:setvbuf("no");UI.initFonts();assert(require("src.card_effects").load())
    UI.CardPhysics.suspend()
    local g=love.graphics;local canvas=g.newCanvas(1664,912)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.025,.03,.045,1)
    local seen={}
    for i,id in ipairs(A.config.order) do
        local d=A.definitions[id]
        local suit=({heart="hearts",diamond="diamonds",club="clubs",spade="spades"})[d.suit]
        local c=Deck.newCard(d.rank,suit);c.evolutionLevel=(i-1)%9
        local art=assert(UI.getCardImage(c.suit,c.rank));assert(not seen[art],"unique runtime portrait")
        seen[art]=true
        local x,y=((i-1)%13)*128+5,math.floor((i-1)/13)*228+8
        UI.drawCard(c,x,y,118,177)
        g.setFont(UI.fonts.small);g.setColor(1,1,1,1)
        g.printf((c.rankName or "")..c.suitSymbol,x,y+185,118,"center")
    end
    g.pop();save(canvas,"docs/continental52_runtime.png");canvas:release()
    local c=Deck.newCard(10,"diamonds");c.evolutionLevel=8
    canvas=g.newCanvas(1280,720)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.025,.03,.045,1)
    UI.drawCard(c,50,130,256,384)
    local title,body=UI.Description.resolve(c,{hand={c},gold=10,playerHp=50,maxPlayerHp=100,playerArmor=10})
    local View=require("ui.components.card_description");local model=View.model(c,title,body)
    View.draw(model,View.layout(model,UI.fonts),370,12)
    -- Small hand card with triple-digit speed and two-digit rank at maximum ornament.
    c.speedBonus=995;UI.drawCard(c,850,140,82,123);UI.drawCardFace(c,960,140,128,192)
    g.pop();save(canvas,"docs/continental52_inspector.png");canvas:release()
    UI.CardPhysics.resume()
    print("Continental 52 render PASS: 52 unique runtime portraits, all tiers, 999 speed, rank 10, names and inspector")
    love.event.quit(0)
end
