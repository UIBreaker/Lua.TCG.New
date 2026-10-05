local Capture = {frames=0}
function Capture.draw()
    Capture.frames=Capture.frames+1
    if Capture.frames~=45 then return end
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/screenshots/mobile-fullscreen-preview.png","wb"))
        file:write(data:encode("png"):getString());file:close()
        print("Mobile full-screen preview captured at 1512x690")
        love.event.quit()
    end)
end
return Capture
