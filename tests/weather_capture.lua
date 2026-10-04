-- Live rendering: lovec.exe . --test-weather (isolated from player saves).
local R = require("render.renderer")
local T = {}
local index, deadline, captured = 0, 0, false
local Weather = require("render.weather")
local encounters = {}
for i=1,#Weather.profiles do encounters[i]=i end
function T.update(game, callbacks)
    local now = love.timer.getTime()
    if now < deadline then return end
    if index == 0 then
        require("tests.hd2d_smoke")
        -- Exercise all weather variants with real GPU resources at every quality.
        for _,quality in ipairs({"LOW","MEDIUM","HIGH"}) do
            R.setQuality(quality)
            for stage=1,#Weather.profiles do
                R.update(1/60,"playing",{stage=stage})
                for _,time in ipairs({0,1.2,4}) do R.scene.time=time; R.drawWorld() end
            end
        end
        R.setQuality("HIGH")
        callbacks.startNewGame("red_deck")
        love.mouse.setPosition(4,4)
    elseif not captured then
        assert(R.scene.weather.kind == Weather.profiles[index].kind)
        -- Capture distant lightning and a meteor during their visible phases.
        if R.scene.weather.kind=="storm" then R.scene.time=1.2 end
        if R.scene.weather.kind=="meteor" then R.scene.time=0.8 end
        local name = "docs/weather/" .. R.scene.weather.kind .. ".png"
        love.graphics.captureScreenshot(function(data)
            local file = assert(io.open(name,"wb"))
            file:write(data:encode("png"):getString()); file:close()
        end)
        captured=true; deadline=now+0.2; return
    end
    index=index+1
    if index>#encounters then
        print("Weather GPU capture passed: "..#Weather.profiles.." types; all qualities; sharp battle UI")
        love.event.quit(0); return
    end
    callbacks.startMonsterEncounter(encounters[index],false)
    game.playerHp,game.maxPlayerHp=100,100
    captured=false; deadline=now+1.5
end
return T
