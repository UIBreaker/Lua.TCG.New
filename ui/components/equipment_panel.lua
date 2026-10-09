local E=require("src.equipment")
local Frame=require("ui.components.card_frame")
local Core=require("ui.components.core")
local Panel={}
local positions={"Trái trên","Phải trên","Phải dưới","Trái dưới","Cạnh trên","Cạnh phải","Cạnh dưới","Cạnh trái"}
function Panel.draw(UI,card,x,y,w,h)
    local g=love.graphics
    local total,used=E.getMaxSlots(card),E.getUsedSlots(card)
    local entries=E.getSocketEntries(card)
    g.push("all");g.setShader()
    Core.text("TRANG BỊ KHẢM",x,y,w,UI.fonts.medium,UI.COLORS.textLight)
    Core.text(used.." / "..total.." HỐC",x,y+5,w,UI.fonts.small,UI.COLORS.goldYellow,"right")
    Core.text("Bốn góc mở sẵn · Cạnh mở thêm bằng Khảm Hốc · Tối đa 8",x,y+29,w,UI.fonts.tiny,UI.COLORS.textMuted)
    local gap,header=10,54
    local rows=math.ceil(total/2)
    local cw=(w-gap)/2
    local ch=math.min(104,(h-header-(rows-1)*gap)/rows)
    for i=1,total do
        local sx=x+(i-1)%2*(cw+gap)
        local sy=y+header+math.floor((i-1)/2)*(ch+gap)
        local entry=entries[i]
        local eq=entry and entry.equipment
        local color=eq and E.getTierColor(eq) or UI.COLORS.textMuted
        g.setColor(0.035,0.055,0.071,0.98);g.rectangle("fill",sx,sy,cw,ch,7,7)
        Core.color(color,eq and 0.45 or 0.17);g.setLineWidth(1);g.rectangle("line",sx+0.5,sy+0.5,cw-1,ch-1,7,7)
        Frame.socketGem(sx+15,sy+15,4,eq and color,1,0,entry and entry.linked)
        Core.text(string.format("%02d",i).." · "..positions[i],sx+27,sy+7,cw-37,UI.fonts.tiny,UI.COLORS.textMuted)
        if eq then
            local image=UI.getEquipmentImage(eq.id)
            if image then g.setColor(1,1,1,1);Frame.image(image,sx+10,sy+30,36,54) end
            Core.textLine(eq.name,sx+56,sy+27,cw-66,UI.fonts.small,color,"left",UI.fonts.tiny)
            local description=entry.linked and ("Hốc liên kết · "..eq.slotsNeeded.." hốc cho một trang bị") or E.getDescription(eq)
            local _,lines=UI.fonts.tiny:getWrap(description,cw-66)
            local shown={};local count=math.max(1,math.floor((ch-50)/UI.fonts.tiny:getHeight()))
            for j=1,math.min(count,#lines) do shown[j]=lines[j] end
            if #lines>count then
                local utf8=require("utf8")
                while #shown[count]>0 and UI.fonts.tiny:getWidth(shown[count].."…")>cw-66 do
                    shown[count]=shown[count]:sub(1,(utf8.offset(shown[count],-1) or 1)-1)
                end
                shown[count]=shown[count].."…"
            end
            Core.text(table.concat(shown,"\n"),sx+56,sy+49,cw-66,UI.fonts.tiny,UI.COLORS.textLight)
            Core.text("T"..E.getTier(eq),sx+cw-40,sy+7,30,UI.fonts.tiny,color,"right")
        else
            Core.text("Ô KHẢM TRỐNG",sx+13,sy+39,cw-26,UI.fonts.small,UI.COLORS.textMuted)
            Core.text("Gắn trang bị để thắp sáng ngọc",sx+13,sy+63,cw-26,UI.fonts.tiny,UI.COLORS.textMuted)
        end
    end
    g.pop()
end
return Panel
