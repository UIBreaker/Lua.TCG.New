local Sound=require("src.sound")
local Audio={}
local rows={
    {key="masterVolume",label="ÂM LƯỢNG TỔNG",set=Sound.setMasterVolume},
    {key="musicVolume",label="NHẠC NỀN",set=Sound.setMusicVolume},
    {key="ambienceVolume",label="ÂM MÔI TRƯỜNG",set=Sound.setAmbienceVolume},
}
function Audio.draw(UI,settings,buttons,x,y,mx,my)
    UI.drawGildedPanel(x,y,230,302)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("ÂM THANH",x+12,y+16,206,"center")
    for i,row in ipairs(rows) do
        local ry=y+46+(i-1)*70
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(row.label,x+12,ry,206,"center")
        for _,delta in ipairs({-1,1}) do
            local b={id="audio_"..row.key..(delta<0 and "_down" or "_up"),text=delta<0 and "−" or "+",
                x=x+(delta<0 and 22 or 164),y=ry+22,w=44,h=30,font=UI.fonts.medium}
            buttons[#buttons+1]=b
            UI.drawButton(b,mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h)
        end
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(math.floor(settings[row.key]*100+.5).."%",x+68,ry+28,94,"center")
    end
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Nhạc theo hành trình\nTạm yên khi rời trò chơi",x+12,y+253,206,"center")
end
function Audio.activate(id,settings)
    for _,row in ipairs(rows) do
        local delta=id=="audio_"..row.key.."_down" and -.1 or id=="audio_"..row.key.."_up" and .1
        if delta then
            settings[row.key]=math.max(0,math.min(1,settings[row.key]+delta))
            row.set(settings[row.key]);Sound.play("ui_click")
            return true
        end
    end
    return false
end
return Audio
