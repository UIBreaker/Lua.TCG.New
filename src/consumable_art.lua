-- Artwork IDs stay canonical even when collection entries add a pack prefix.
local Art = {}
local images = {}
local aliases = {ed_foil="edition_foil", ed_holo="edition_holographic", ed_poly="edition_polychrome"}

function Art.id(item)
    if not item then return nil end
    local id = item.artId or item.id
    -- Playing cards have numeric instance IDs and use the suit/rank loader.
    if type(id) ~= "string" then return nil end
    if item.isPackContent and item.packType then
        local prefix = "pack_content_" .. item.packType .. "_"
        if id and id:sub(1, #prefix) == prefix then id = id:sub(#prefix + 1) end
    end
    return aliases[id] or id
end

function Art.get(item)
    local id = Art.id(item)
    if not id then return nil end
    if id:match("^spec_") or id:match("^spell_") or id:match("^seal_")
        or id:match("^edition_") or id:match("^ed_") or id:match("^planet_") or id:match("^cons_")
        or id=="healing_potion" or id=="hand_expansion" or id=="soul_reaper" then
        local continental=require("src.continental_art").get(id)
        if continental then return continental end
    end
    if images[id] ~= nil then return images[id] or nil end
    local path = "assets/consumables/" .. id .. ".png"
    if love.filesystem.getInfo(path) then
        local image = love.graphics.newImage(path)
        image:setFilter("linear", "linear")
        images[id] = image
        return image
    end
    images[id] = false
end

return Art
