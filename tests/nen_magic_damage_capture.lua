-- Render the unchanged number system on an isolated canvas before/after attack drawing.
local T={}
function T.verify(ui)
    local g=love.graphics;local F=require("src.combat_feedback")
    local M=require("src.nen_magic");local R=require("render.nen_magic")
    local baseline=g.newCanvas(1280,720);local after=g.newCanvas(1280,720);local world=g.newCanvas(1280,720)
    local values={0,1,10,100,1000,10000,1e5,1e6,1e7,1e8,1e9,1e10,1e11,1e12,1e13,1e14,1e15,1e20,1e308}
    local checks=0;g.push("all");g.origin()
    for _,amount in ipairs(values) do
        local ft=F.new("damage",amount,640,300,ui.formatNumber)
        for _,age in ipairs({.04,.14,.4,.9}) do
            ft.age=age;ft.life=ft.maxLife-age
            g.setCanvas(baseline);g.clear();F.draw(ft,ui)
            g.setCanvas();local before=baseline:newImageData()
            local a=M.play("endless_cycle",1e308,{x=500,y=440},{x=640,y=270});a.nen.charge=1
            g.setCanvas(world);g.clear();R.draw(a,"TRAVEL",.8);R.draw(a,"ENEMY_IMPACT",1,.07)
            g.setCanvas(after);g.clear();F.draw(ft,ui)
            g.setCanvas();local result=after:newImageData()
            assert(before:getString()==result:getString(),"Damage number changed after attack render: "..amount.." at "..age)
            if amount==1e15 and age==.14 then
                for name,data in pairs({damage_baseline=before,damage_after_attack=result}) do
                    local f=assert(io.open("docs/nen_magic/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
                end
            end
            before:release();result:release();M.clear(a);checks=checks+1
        end
    end
    g.pop();baseline:release();after:release();world:release()
    local report=checks.." pixel-exact number-layer comparisons PASS: 0 to 1e308, four animation ages; attack shader/draw does not alter number layer.\n"
    print(report);local f=assert(io.open("docs/nen_magic/damage_preservation.txt","wb"));f:write(report);f:close()
end
return T
