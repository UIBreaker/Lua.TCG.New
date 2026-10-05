local T={}
function T.verify(requestedIds,output)
    local UI=require("src.ui")
    local Art=require("src.continental_art")
    local D=require("src.deities")
    local ids={"spirit_lone","spirit_confluence","spirit_rearguard","spirit_wound","spirit_bastion","spirit_stillness","spirit_molt","spirit_pivot","spirit_mender","spirit_gleaner"}
    ids=requestedIds or ids
    local g=love.graphics
    local canvas=g.newCanvas(1280,850)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.04,0.05,0.08)
    for i,id in ipairs(ids) do
        local image=assert(Art.get(id),id)
        assert(image:getWidth()==512 and image:getHeight()==768,id)
        assert(UI.getDeityImage(id)==image,id)
        local x=25+((i-1)%5)*250
        local y=15+math.floor((i-1)/5)*415
        UI.drawPatronCard(D.CATALOG[id],x,y,230,345,false,false,false)
        g.setColor(1,1,1);g.setFont(UI.fonts.regular)
        g.printf(D.CATALOG[id].name,x,y+352,230,"center")
    end
    g.pop()
    local f=assert(io.open(output or "docs/spn_tactics_runtime.png","wb"))
    f:write(canvas:newImageData():encode("png"):getString());f:close();canvas:release()
    print("SPN art runtime PASS: 10 native loader images and shared card frames rendered")
end
return T
