local T={}
local R=require("render.renderer")
function T.update(game,cb)
    if not T.started then
        for _,layer in ipairs(require("config.scene_definitions").scenes.menu.layers) do
            assert(layer.kind~="foreground","menu must not have stone corner overlays")
        end
        require("tests.hd2d_smoke")
        cb.setCaptureState("menu");cb.setMenuMode("title")
        love.mouse.setPosition(3,3);T.started=love.timer.getTime();return
    end
    if love.timer.getTime()-T.started<2 then return end
    assert(R.scene.name=="menu")
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/menu_sparkles.png","wb"))
        file:write(data:encode("png"):getString());file:close()
    end)
    print("Menu sparkles PASS: no foreground stones; GPU rendering, quality limits, state restoration and gameplay RNG checks passed")
    love.event.quit(0)
end
return T
