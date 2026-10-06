-- Canonical new art; old loaders remain available as fallbacks.
local paths=require("config.continental_asset_paths")
local Art={cache={},indexed=setmetatable({}, {__mode="k"}),generated=setmetatable({}, {__mode="k"})}
function Art.get(id)
    if not id or not paths[id] then return nil end
    if Art.cache[id]~=nil then return Art.cache[id] or nil end
    local path=paths[id]
    if Art.cache[path] then Art.cache[id]=Art.cache[path];return Art.cache[path] end
    if not love.filesystem.getInfo(path) then return nil end
    -- Load the already-sized texture instead of decoding a multi-megabyte
    -- source PNG and allocating a resize Canvas on the first card visit.
    local runtimeBase=path:gsub("assets/cards/continental/", "assets/cards/continental/runtime/", 1):gsub("%.png$", "")
    local loadPath=path
    for _, extension in ipairs({".jpg", ".png"}) do
        local candidate=runtimeBase..extension
        if love.filesystem.getInfo(candidate) then loadPath=candidate;break end
    end
    local image=love.graphics.newImage(loadPath);image:setFilter("linear","linear")
    local w,h=image:getDimensions()
    if w>512 then
        local g=love.graphics;local canvas=g.newCanvas(512,768)
        g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.clear()
        g.setColor(1,1,1,1);g.setBlendMode("alpha");g.draw(image,0,0,0,512/w,768/h);g.pop()
        image:release();image=canvas;image:setFilter("linear","linear")
    end
    Art.cache[id]=image;Art.cache[path]=image;Art.generated[image]=true
    return image
end
function Art.withIndices(image,suit,rank)
    local key=suit.."_"..tostring(rank)
    Art.indexed[image]=Art.indexed[image] or {}
    if Art.indexed[image][key] then return Art.indexed[image][key] end
    local g=love.graphics;local canvas=g.newCanvas(512,768)
    g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.setBlendMode("alpha");g.clear()
    g.setColor(1,1,1,1);g.draw(image,0,0,0,512/image:getWidth(),768/image:getHeight())
    Art.indexFont=Art.indexFont or g.newFont("fonts/arialbd.ttf",64)
    Art.suitFont=Art.suitFont or g.newFont("fonts/arialbd.ttf",59)
    local glyph=({hearts="♥",diamonds="♦",clubs="♣",spades="♠"})[suit] or "♠"
    local label=({[11]="J",[12]="Q",[13]="K",[14]="A"})[tonumber(rank)] or tostring(rank)
    local function index()
        g.setColor(0.96,0.94,0.85,0.96);g.polygon("fill",8,8,90,8,90,126,8,151)
        g.setColor((suit=="hearts" or suit=="diamonds") and {0.69,0.10,0.13,1} or {0.06,0.13,0.22,1})
        g.setFont(Art.indexFont);g.printf(label,9,8,80,"center")
        g.setFont(Art.suitFont);g.printf(glyph,9,72,80,"center")
    end
    index();g.push();g.translate(512,768);g.rotate(math.pi);index();g.pop();g.pop()
    canvas:setFilter("linear","linear");Art.indexed[image][key]=canvas;Art.generated[canvas]=true
    return canvas
end
return Art
