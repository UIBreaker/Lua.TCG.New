local T={}
function T.verify()
    local Art=require("src.continental_art")
    local UI=require("src.ui")
    local paths=require("config.continental_asset_paths")
    local unique={};local count=0
    for id,path in pairs(paths) do
        assert(love.filesystem.getInfo(path),"Missing continental PNG: "..path)
        local image=assert(Art.get(id),"New art loader: "..id)
        assert(image:getWidth()==512 and image:getHeight()==768,"Shared portrait ratio: "..id)
        if not unique[path] then unique[path]=true;count=count+1 end
    end
    assert(count==157,"Canonical asset coverage must remain complete")
    for _,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
        for rank=2,14 do
            local image=assert(UI.getCardImage(suit,rank))
            assert(Art.generated[image],"Playing cards must use new art with native indices")
        end
    end
    for _,item in ipairs(require("src.poker").PLANET_CARDS) do
        assert(UI.getConsumableImage(item)==Art.get(item.id),"Each planet needs dedicated art, not a hand-style alias")
    end
    assert(UI.getPackImage("joker_edition")~=UI.getPackImage("enchantment_pack"),"SPN and ordinary enchantment chests have distinct art")
    assert(UI.getVoucherImage("hand_expansion")==Art.get("hand_expansion"))
    print("Continental art coverage PASS: 157 PNGs, 52 indexed playing cards, 11 planets, chest/utility aliases")
end
return T
