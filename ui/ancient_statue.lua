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
    Chrome.button(UI,b,mx,my);buttons[#buttons+1]=b
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
        text(string.format("Lần chạm tới: −%.2f HP",(game.playerHp or 0)*.1),47,632,337,UI.fonts.small,Theme.colors.text,"center")
        Chrome.panel(424,115,832,572,Theme.colors.gold)
        Chrome.title("GIAO ƯỚC VỚI TƯỢNG CỔ",448,135,755,UI.fonts.bookHeading or UI.fonts.medium,Theme.colors.gold)
        text("Chọn một quân bài từ balo để đặt lên tế đàn",449,173,755,UI.fonts.small,Theme.colors.muted)
        local selected
        for _,card in ipairs(game.persistentDeck or {}) do if card.id==e.selectedId and not card.destroyed then selected=card end end
        Chrome.well(474,209,242,328,red)
        if selected then
            local pulse=V.ritual and math.sin(math.min(V.ritual.age,.8)/.8*math.pi) or 0
            require("ui.backpack_style").glow(595,368,130,red,.10+pulse*.32)
            UI.drawCardFace(selected,506,229,178,267,false)
            if hit(mx,my,506,229,178,267) then V.hover=selected end
            text("LÁ NHẬN GIAO ƯỚC",487,511,216,UI.fonts.tiny,Theme.colors.gold,"center")
        else
            require("ui.backpack_style").glyph("cards",595,331,34,Theme.colors.goldDim)
            text("CHƯA ĐẶT QUÂN BÀI",490,397,210,UI.fonts.small,Theme.colors.gold,"center")
            text("Mở balo và chọn một lá",490,430,210,UI.fonts.tiny,Theme.colors.muted,"center")
        end
        button(buttons,"statue_select",selected and "ĐỔI QUÂN BÀI · BALO" or "CHỌN TỪ BALO",475,551,242,40,mx,my,{disabled=V.ritual~=nil})
        local r=V.ritual
        if r then
            local reveal=math.max(0,r.age-.8)
            if not r.result then
                text("ĐANG DÂNG SINH MỆNH",759,241,453,UI.fonts.medium,red,"center")
                text("−"..string.format("%.2f",r.before.hp*.1).." HP",759,292,453,UI.fonts.large,red,"center")
                particles(time*4,494,226,202,280)
            else
                local color=r.negative and red or r.result=="gold" and Theme.colors.gold or Theme.colors.green
                Chrome.title(r.title,756,218,455,UI.fonts.bookChapter or UI.fonts.medium,color,"center")
                text("ĐÃ HIẾN −"..string.format("%.2f",r.before.hp-r.after.hp).." HP",756,257,455,UI.fonts.small,red,"center")
                local y=301
                if r.result=="copies" then
                    local t=math.min(1,reveal/.7);local ease=1-(1-t)^3
                    for i=1,3 do
                        local x=595+(786+(i-1)*109-595)*ease
                        UI.drawCardFace(r.card,x,297,78,117,false)
                    end
                    y=443
                elseif r.result=="gold" then
                    text("+"..math.floor((r.after.gold-r.before.gold)*math.min(1,reveal/.8)).." VÀNG",760,303,450,UI.fonts.large,Theme.colors.gold,"center")
                    local Style=require("ui.backpack_style")
                    for i=1,12 do
                        local t=math.min(1,reveal/(.4+i*.035))
                        if t<1 then Style.glyph("gold",970+math.sin(i*2.4)*105*t,365-130*t,5,Theme.colors.gold) end
                    end
                    y=369
                end
                for _,delta in ipairs(r.deltas) do
                    Chrome.well(762,y,440,43,color)
                    text(delta.label,776,y+13,180,UI.fonts.tiny,Theme.colors.muted)
                    text(delta.before.."  →  "..delta.after,949,y+11,237,UI.fonts.small,color,"right")
                    y=y+51
                end
                if #r.deltas==0 then text("Không có thay đổi nào khác.",762,y,440,UI.fonts.small,Theme.colors.muted,"center") end
                text("Sinh lực: "..string.format("%.2f",r.before.hp).." → "..string.format("%.2f",r.after.hp),762,592,440,UI.fonts.tiny,Theme.colors.muted,"center")
                particles(time*2,752,278,449,270)
            end
        else
            text(selected and "SẴN SÀNG HIẾN MÁU" or "TẾ ĐÀN ĐANG CHỜ",758,239,452,UI.fonts.medium,Theme.colors.gold,"center")
            text("Hiến 10% máu hiện tại để nhận một kết quả ngẫu nhiên. Thay đổi lên quân bài là vĩnh viễn.",779,292,408,UI.fonts.regular,Theme.colors.text)
            if selected then
                text("Sát thương  "..(selected.baseChips or 0).."\nTốc đánh  "..require("src.deck").peekCardAttackSpeed(selected).."\nTiến hóa  "..(selected.evolutionLevel or 0),779,390,408,UI.fonts.regular,Theme.colors.muted)
            end
            if e.last then text(e.message,761,515,442,UI.fonts.small,Theme.colors.muted) end
        end
        text("Đã chạm "..e.touches.." lần",448,607,296,UI.fonts.tiny,Theme.colors.muted)
        button(buttons,"statue_rates","KẾT QUẢ",444,641,176,34,mx,my,{disabled=r~=nil})
        button(buttons,"statue_leave","RỜI TƯỢNG",632,641,212,34,mx,my,{disabled=r~=nil})
        if r then
            button(buttons,"statue_continue",r.result and "ĐÃ RÕ · TIẾP TỤC" or "ĐANG HIẾN MÁU…",856,641,374,34,mx,my,{disabled=not r.result or r.age<2})
        else
            button(buttons,"statue_touch","CHẠM · HIẾN MÁU",856,641,374,34,mx,my,{disabled=not selected})
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
function V.snapshot(game,card)
    return {hp=game.playerHp,gold=game.gold or 0,count=#(game.persistentDeck or {}),
        damage=card.baseChips or 0,speed=require("src.deck").peekCardAttackSpeed(card),level=card.evolutionLevel or 0,power=card.statuePower or 1}
end
function V.update(game,dt)
    local r=V.ritual;if not r then return end
    if game.ancientStatue~=r.event then V.ritual=nil;return end
    r.age=r.age+dt
    if r.age>=.8 and not r.result then
        local ok,result=Statue.touch(game,r.card.id)
        if not ok then V.ritual=nil;return end
        if result=="entered" then V.ritual=nil;return "entered" end
        r.result=result
        local selected=r.card
        for _,card in ipairs(game.persistentDeck) do if card.id==r.card.id then selected=card;break end end
        r.after=V.snapshot(game,selected)
        r.negative=result:match("^lose_")~=nil
        for _,o in ipairs(Statue.outcomes) do if o.id==result then r.title=o.name end end
        r.deltas={}
        for _,field in ipairs({{"damage","SÁT THƯƠNG"},{"speed","TỐC ĐÁNH"},{"level","TIẾN HÓA"},{"power","SỨC MẠNH KHẢ NĂNG"},{"gold","VÀNG"},{"count","LÁ TRONG BỘ"}}) do
            local key,label=field[1],field[2]
            if r.before[key]~=r.after[key] then r.deltas[#r.deltas+1]={label=label,before=r.before[key],after=r.after[key]} end
        end
        require("src.sound").play(r.negative and "card_deal" or "round_win")
        return "changed"
    end
end
function V.press(game,b)
    if V.rates then if b.id=="statue_rates_close" then V.rates=false end;return true end
    if b.id=="statue_claim" then return Statue.claim(game,b.index) and "claimed" end
    local e=game.ancientStatue;if not e then return end
    if b.id=="statue_continue" and V.ritual and V.ritual.result and V.ritual.age>=2 then V.ritual=nil;return true end
    if V.ritual then return false end
    if b.id=="statue_select" then
        UI.Backpack.show();UI.Backpack.cardPicker=true
        require("ui.backpack_qol").switch(UI.Backpack,"cards")
        UI.Backpack.message="Chọn quân bài để đặt lên tế đàn. Esc để quay lại."
        return true
    elseif b.id=="statue_rates" then V.rates=true;return true
    elseif b.id=="statue_leave" then game.ancientStatue=nil;return "leave"
    elseif b.id=="statue_touch" then
        for _,card in ipairs(game.persistentDeck or {}) do if card.id==e.selectedId and not card.destroyed then
            V.ritual={event=e,age=0,card=require("src.blood_shop").clone(card),before=V.snapshot(game,card)}
            require("src.sound").play("card_slide");return true
        end end
    end
end
return V
