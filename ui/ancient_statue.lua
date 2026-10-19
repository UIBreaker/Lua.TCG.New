local UI=require("src.ui")
local Core=require("ui.components.core")
local Chrome=require("ui.combat_chrome")
local Theme=require("ui.theme")
local Statue=require("src.ancient_statue")
local V={}
local red={.87,.34,.38,1}
local function text(s,x,y,w,font,color,align) Core.text(s,x,y,w,font or UI.fonts.small,color or Theme.colors.text,align) end
local function hit(mx,my,x,y,w,h) return mx>=x and my>=y and mx<=x+w and my<=y+h end
local function button(buttons,id,label,x,y,w,h,mx,my,data)
    local b={id=id,text=label,x=x,y=y,w=w,h=h,color=Theme.colors.inset,font=UI.fonts.small}
    for k,v in pairs(data or {}) do b[k]=v end
    UI.drawButton(b,hit(mx,my,x,y,w,h));buttons[#buttons+1]=b
end
local function particles(time,x,y,w,h)
    local g=love.graphics
    g.setBlendMode("add")
    for i=1,22 do
        local px=x+(i*73.2+math.sin(time+i)*12)%w
        local py=y+h-(i*39.7+time*(13+i%5))%h
        g.setColor(.8,.12,.18,.12+.12*math.sin(time+i)^2);g.circle("fill",px,py,1+i%3)
    end
    g.setBlendMode("alpha")
end
function V.draw(game,buttons,mx,my)
    local reward=game.bloodDomain and game.bloodDomain.choices
    local time=love.timer.getTime()
    Chrome.panel(20,20,1240,78,red)
    text(reward and "CHIẾN LỢI PHẨM · VƯƠNG HUYẾT" or "TƯỢNG CỔ · GIAO ƯỚC SINH MỆNH",43,35,870,UI.fonts.large,Theme.colors.gold)
    text(string.format("SINH LỰC %.1f / %g  ·  %g VÀNG",game.playerHp or 0,game.maxPlayerHp or 100,game.gold or 0),45,73,1140,UI.fonts.tiny,red)
    V.hover=nil
    if reward then
        text("Đã chinh phục 8 ải Lãnh Địa Máu. Chọn 1 trong 3 SPN có chỉ số ×4.",100,123,1080,UI.fonts.medium,Theme.colors.text,"center")
        for i,item in ipairs(reward) do
            local x=126+(i-1)*362
            Chrome.panel(x,170,332,454,red)
            particles(time,x+7,177,318,435)
            UI.drawPatronCard(item,x+71,193,190,285,false,false,false)
            text(item.name,x+16,490,300,UI.fonts.medium,Theme.colors.gold,"center")
            text("LÃNH ĐỊA MÁU ×4",x+16,533,300,UI.fonts.small,red,"center")
            text("Rê chuột lên lá để đọc sức mạnh",x+16,563,300,UI.fonts.tiny,Theme.colors.muted,"center")
            button(buttons,"statue_claim","CHỌN SPN NÀY",x+22,632,288,48,mx,my,{index=i})
            if hit(mx,my,x+71,193,190,285) then V.hover=item end
        end
    else
        local e=game.ancientStatue;if not e then return end
        Chrome.panel(24,115,382,572,red)
        local image=require("src.continental_art").get("ancient_statue")
        if image then love.graphics.setColor(1,1,1,1);UI.CardFrame.image(image,68,134,294,441);UI.drawCardBorder(68,134,294,441,nil,nil,{}) end
        particles(time,50,130,330,445)
        text("HIẾN 10% MÁU HIỆN TẠI",42,590,346,UI.fonts.medium,red,"center")
        text(string.format("Lần chạm tới: −%.2f HP\nCòn ≤ %.1f HP: bị cuốn vào Lãnh Địa Máu.\nKhông thể rời lãnh địa trước khi hạ boss ải 8.",(game.playerHp or 0)*.1,(game.maxPlayerHp or 100)*.1),47,625,337,UI.fonts.tiny,Theme.colors.text,"center")
        Chrome.panel(424,115,832,572,Theme.colors.gold)
        text("CHỌN LÁ NHẬN GIAO ƯỚC",445,132,576,UI.fonts.medium,Theme.colors.gold)
        text("Thay đổi vĩnh viễn · Mỗi kết quả có tỷ lệ 10%",445,164,754,UI.fonts.tiny,Theme.colors.muted)
        local cards=game.persistentDeck or {};local pages=math.max(1,math.ceil(#cards/6))
        e.page=math.max(1,math.min(pages,e.page or 1))
        local selected
        for n=0,5 do
            local card=cards[(e.page-1)*6+n+1]
            if card then
                local x=445+n%3*264;local y=197+math.floor(n/3)*162
                local chosen=card.id==e.selectedId
                Core.color(chosen and red or Theme.colors.gold,.20);love.graphics.rectangle("fill",x-4,y-4,251,154,5)
                UI.drawCardFace(card,x,y,94,141,false)
                text((card.rankName or tostring(card.rank))..(card.suitSymbol or ""),x+106,y+4,128,UI.fonts.medium,Theme.colors.gold)
                text(string.format("ST %g\nTốc %g\nTiến hóa %g",card.baseChips or 0,require("src.deck").peekCardAttackSpeed(card),card.evolutionLevel or 0),x+106,y+38,132,UI.fonts.small)
                if chosen then text("ĐÃ CHỌN",x+106,y+112,132,UI.fonts.tiny,red) end
                buttons[#buttons+1]={id="statue_select",cardId=card.id,x=x-4,y=y-4,w=251,h=154}
                if hit(mx,my,x,y,94,141) then V.hover=card end
            end
        end
        for _,card in ipairs(cards) do if card.id==e.selectedId then selected=card end end
        text(e.message,446,526,780,UI.fonts.small,e.last and red or Theme.colors.muted)
        text("Đã chạm "..e.touches.." lần · "..e.page.." / "..pages,447,590,475,UI.fonts.tiny,Theme.colors.muted)
        button(buttons,"statue_prev","←",1020,578,68,32,mx,my)
        button(buttons,"statue_next","→",1098,578,68,32,mx,my)
        button(buttons,"statue_rates","KẾT QUẢ",444,631,176,42,mx,my)
        button(buttons,"statue_leave","RỜI TƯỢNG",632,631,212,42,mx,my)
        button(buttons,"statue_touch","CHẠM · HIẾN MÁU",856,631,374,42,mx,my,{disabled=not selected})
        if (e.flash or 0)>0 then
            e.flash=math.max(0,e.flash-love.timer.getDelta()*1.4)
            Core.color(red,e.flash*.10);love.graphics.rectangle("fill",0,0,1280,720)
        end
        if V.rates then
            for i=#buttons,1,-1 do buttons[i]=nil end
            Core.color({0,0,0,1},.83);love.graphics.rectangle("fill",0,0,1280,720)
            Chrome.panel(328,125,624,490,Theme.colors.gold)
            text("GIAO ƯỚC · TỶ LỆ CÔNG KHAI",350,146,580,UI.fonts.medium,Theme.colors.gold)
            for i,o in ipairs(Statue.outcomes) do text(o.name,356,194+(i-1)*34,470,UI.fonts.small);text("10%",830,194+(i-1)*34,80,UI.fonts.small,red,"right") end
            button(buttons,"statue_rates_close","ĐÓNG",550,555,180,40,mx,my)
            V.hover=nil
        end
    end
    if V.hover then UI.descriptionCandidate=V.hover end
end
function V.press(game,b)
    if V.rates then if b.id=="statue_rates_close" then V.rates=false end;return true end
    if b.id=="statue_claim" then return Statue.claim(game,b.index) and "claimed" end
    local e=game.ancientStatue;if not e then return end
    if b.id=="statue_select" then e.selectedId=b.cardId;return true
    elseif b.id=="statue_prev" then e.page=e.page-1;return true
    elseif b.id=="statue_next" then e.page=e.page+1;return true
    elseif b.id=="statue_rates" then V.rates=true;return true
    elseif b.id=="statue_leave" then game.ancientStatue=nil;return "leave"
    elseif b.id=="statue_touch" then local ok,result=Statue.touch(game,e.selectedId);return ok and (result=="entered" and "entered" or true) end
end
return V
