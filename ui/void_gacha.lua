local UI=require("src.ui")
local C=require("ui.theme").colors
local G=require("src.void_gacha")
local Sound=require("src.sound")
local Visual=require("config.visual_config")
local Art=require("src.continental_art")
local Effects=require("ui.reward_effects")
local V={}
local function text(s,x,y,w,font,color,align)
    love.graphics.setFont(font or UI.fonts.tiny);love.graphics.setColor(color or C.text)
    love.graphics.printf(s,x,y,w,align or "left")
end
local function panel(x,y,w,h,color)
    local g=love.graphics;g.setColor(.014,.016,.032,.91);UI.drawRoundedRect("fill",x,y,w,h,7)
    local c=color or C.purple;g.setColor(c[1],c[2],c[3],.52);g.setLineWidth(1);UI.drawRoundedRect("line",x+1,y+1,w-2,h-2,6)
end
local function button(buttons,id,label,x,y,w,h,disabled)
    local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled,font=UI.fonts.small,color=C.inset}
    UI.drawButton(b,false);buttons[#buttons+1]=b
end
function V.effectSpec(strength)
    return {duration=2.85+strength*.20,revealAt=1.70+(strength-1)*.055,
        particles=24+strength*16,rings=2+math.floor(strength/2),kick=strength*1.1}
end
function V.phase(strength,time)
    if time<1.05 then return "charge" end
    if time<1.48 then return "signal" end
    if time<V.effectSpec(strength).revealAt then return "fracture" end
    return "reveal"
end
local function rgba(c,a) love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function art(r,x,y,w,h)
    local g=love.graphics;local item=r.item
    if r.kind=="spn" then UI.drawPatronCard(item,x,y,w,h,false,false,false)
    elseif r.kind=="card" then UI.drawCardFace(item,x,y,w,h,false)
    else
        local image=(r.kind=="gold" and Art.get("void_gold") or r.kind=="souls" and Art.get("void_souls"))
            or r.kind=="hand" and UI.getVoucherImage("v_hand_size")
            or r.kind=="ticket" and Art.get("void_ticket") or item and (r.kind=="equipment" and UI.getEquipmentImage(item.id)
            or r.kind=="pack" and UI.getPackImage(item.packType)
            or r.kind=="voucher" and UI.getVoucherImage(item.id)
            or UI.getConsumableImage(item))
        if image then g.setColor(1,1,1);UI.CardFrame.image(image,x,y,w,h);UI.drawCardBorder(x,y,w,h,nil,nil,item)
        else
            panel(x,y,w,h,r.kind=="souls" and C.purple or C.gold)
            g.setLineWidth(2);rgba(r.kind=="souls" and C.purple or C.gold)
            if r.kind=="souls" then g.polygon("line",x+w/2,y+h*.22,x+w*.8,y+h*.47,x+w/2,y+h*.7,x+w*.2,y+h*.47)
            else g.circle("line",x+w/2,y+h*.43,w*.3);g.circle("line",x+w/2,y+h*.43,w*.23) end
            text(r.amount and "+"..r.amount or "+1",x,y+h*.65,w,UI.fonts.small,C.gold,"center")
        end
        if r.kind=="equipment" then require("ui.backpack").stats(UI,item,x,y,w,h) end
        if r.amount and (r.kind=="gold" or r.kind=="souls" or r.kind=="ticket") then
            local bh=math.max(16,h*.15);g.setColor(.015,.013,.029,.90)
            UI.drawRoundedRect("fill",x+w*.12,y+h-bh-4,w*.76,bh,3)
            text("+"..r.amount,x,y+h-bh-3,w,h>160 and UI.fonts.medium or UI.fonts.tiny,r.kind=="gold" and C.gold or C.purple,"center")
        end
    end
end
art=UI.CardPhysics.wrap(art)
function V.update(dt,game)
    local event=game.voidEvent;if not event then V.animation=nil;return end
    if event.pendingResults and (not V.animation or V.animation.event~=event or V.animation.serial~=event.serial) then
        V.animation={event=event,serial=event.serial,index=1,time=0};Sound.play("reward_chest_open")
    end
    local a=V.animation;if not a or not event.pendingResults then return end
    a.time=a.time+dt
    local reward=event.results[a.index];if not reward then G.finishReveal(game);V.animation=nil;return true end
    local spec=V.effectSpec(reward.strength)
    if not a.signal and a.time>=1.05 then a.signal=true;Sound.play("reward_chest_open") end
    if not a.impact and a.time>=spec.revealAt then
        a.impact=true
        if reward.kind=="ticket" then local profile=Effects.profile(reward);Sound.play(profile.sound,profile.pitch)
        elseif reward.kind=="gold" then Sound.play("coin",1.15)
        elseif reward.kind=="pack" then Sound.play("reward_chest_open")
        else Sound.play(reward.strength>=3 and "reward_rare_reveal" or "reward_loot_reveal") end
    end
    if a.time>=spec.duration then
        if a.index<#event.results then a.index=a.index+1;a.time=0;a.impact=nil;a.signal=nil;Sound.play("reward_chest_open")
        else G.finishReveal(game);V.animation=nil;return true end
    end
end
local function summon(event,buttons)
    local a=V.animation;if not a then return end
    local r=event.results[a.index];local strength=r.strength;local spec=V.effectSpec(strength)
    local ticket=r.kind=="ticket" and Effects.profile(r)
    local phase=V.phase(strength,a.time);local opened=phase=="reveal"
    local charge=math.min(1,a.time/1.05);local blast=math.max(0,(a.time-spec.revealAt)/(spec.duration-spec.revealAt));local g=love.graphics
    local c=phase=="charge" and {.46,.34,.95} or ticket and ticket.color or G.config.colors[strength];local x,y=640,343
    g.setColor(.002,.003,.012,.76);g.rectangle("fill",0,80,1280,640)
    local shake=Visual.enabled and opened and math.max(0,1-blast*4)*spec.kick or 0
    g.push();g.translate(math.sin(a.time*63)*shake,math.cos(a.time*79)*shake*.6)
    g.setBlendMode("add")
    for i=12,1,-1 do rgba(c,(opened and .027 or .016)*(1-blast*.55));g.ellipse("fill",x,y,40+i*19*charge,45+i*16*charge) end
    -- Flowing nebula filaments carry soft bloom and a sharp luminous centre.
    for strand=1,2 do
        local points={};local radius=opened and 160+blast*100 or 48+charge*70
        for j=0,40 do
            local angle=j/40*math.pi*1.65+a.time*(strand==1 and 1.5 or -1.1)+strand*math.pi
            local wave=radius+math.sin(angle*3+a.time*2)*12
            points[#points+1]=x+math.cos(angle)*wave
            points[#points+1]=y+math.sin(angle)*wave*.78
        end
        for layer=3,1,-1 do
            local tint=strand==1 and c or {.35,.8,1}
            rgba(tint,(layer==1 and .6 or .045)*(1-blast*.75))
            g.setLineWidth(layer==3 and 18 or layer==2 and 8 or 1.5);g.line(points)
        end
    end
    -- All rewards share the same charge. Rarity only appears when the signal arrives.
    for ring=1,(phase=="charge" and 3 or spec.rings) do
        g.push();g.translate(x,y);g.rotate(a.time*(ring%2==0 and -1 or 1)*(.55+ring*.12))
        rgba(c,.58*(1-blast*.65));g.setLineWidth(1+ring*.35)
        local radius=(85+ring*22)*(opened and 1+blast*1.5 or math.max(.1,charge))
        for layer=3,1,-1 do
            rgba(c,(layer==1 and .58 or .04)*(1-blast*.65));g.setLineWidth(layer==3 and 9 or layer==2 and 5 or 1+ring*.35)
            g.arc("line","open",0,0,radius,.15,math.pi*1.75)
        end
        local ticks=phase=="charge" and 12 or 8+strength
        for j=1,ticks do local angle=j*math.pi*2/ticks;g.line(math.cos(angle)*radius,math.sin(angle)*radius,math.cos(angle)*(radius+8),math.sin(angle)*(radius+8)) end
        g.pop()
    end
    local particles=phase=="charge" and 48 or spec.particles
    if Visual.quality=="LOW" then particles=math.min(32,particles) end
    for i=1,particles do
        local angle=i*2.399963+a.time*(opened and .06 or 1.4)
        local distance=opened and 65+blast*(180+i%13*24) or 48+(1-charge)*(100+i%9*22)+i%5*9
        local px,py=x+math.cos(angle)*distance,y+math.sin(angle)*distance*.74
        if strength>=8 and phase~="charge" then g.setColor(.55+.45*math.sin(angle)^2,.55+.45*math.sin(angle+2)^2,.55+.45*math.sin(angle+4)^2,math.max(0,.85-blast))
        else rgba(c,math.max(0,.8-blast*.7)) end
        g.setLineWidth(phase~="charge" and strength>=5 and 2 or 1);local tail=8+(phase=="charge" and 0 or strength*2)+blast*15
        g.line(px,py,px-math.cos(angle)*tail,py-math.sin(angle)*tail)
        if i%3==0 then
            rgba(c,.09*(1-blast*.8));g.circle("fill",px,py,6)
            g.setColor(.85,.94,1,.8*(1-blast*.8));g.circle("fill",px,py,1.2)
        end
        if phase~="charge" and strength>=4 then g.polygon("fill",px,py-3,px+2,py,px,py+3,px-2,py) end
    end
    if phase=="fracture" then
        local fracture=(a.time-1.48)/(spec.revealAt-1.48)
        for i=1,7 do
            local angle=i*2.399963;local radius=45+fracture*55
            rgba(c,.8);g.setLineWidth(1.5)
            g.line(x,y,x+math.cos(angle)*radius*.5,y+math.sin(angle)*radius*.5,
                x+math.cos(angle+.13)*radius,y+math.sin(angle+.13)*radius)
        end
    end
    if not opened then
        local pulse=.5+.5*math.sin(a.time*8)
        for halo=5,1,-1 do rgba(c,.04+charge*.014);g.circle("fill",x,y,halo*(5+charge*3+pulse)) end
        g.setColor(.78,.89,1,.7);g.ellipse("fill",x,y,3+charge*2,8+charge*6)
        rgba(c,.22);g.ellipse("fill",x,y,50+charge*30,1.5)
    elseif strength>=3 then
        for i=1,6 do
            local angle=i*math.pi/3+a.time*.3;local radius=168+blast*140
            local px,py=x+math.cos(angle)*radius,y+math.sin(angle)*radius*.8
            rgba(c,.18*(1-blast));g.circle("fill",px,py,11)
            g.setColor(.95,.93,1,.8*(1-blast));g.ellipse("fill",px,py,12,1);g.ellipse("fill",px,py,1,12)
        end
    end
    if opened then
        -- Shards, two travelling shockwaves and a bright, short impact bloom.
        for ring=1,2 do
            rgba(c,math.max(0,.7-blast*1.25));g.setLineWidth(3-ring)
            g.ellipse("line",x,y,90+blast*(420+ring*90),45+blast*(180+ring*55))
        end
        for i=1,18 do
            local angle=i*2.399963;local radius=70+blast*(220+i%6*28)
            local px,py=x+math.cos(angle)*radius,y+math.sin(angle)*radius*.82
            rgba(c,math.max(0,.75-blast));g.push();g.translate(px,py);g.rotate(angle+blast*4)
            g.polygon("fill",-3,-8,5,0,-2,6);g.pop()
        end
    end
    if strength>=5 and opened then
        for i=1,strength*4 do
            local angle=i*math.pi*2/(strength*4);local radius=80+blast*390
            rgba(c,math.max(0,.28-blast*.35));g.setLineWidth(1+strength*.5)
            g.line(x+math.cos(angle)*80,y+math.sin(angle)*80,x+math.cos(angle)*radius,y+math.sin(angle)*radius)
        end
        rgba(c,math.max(0,.75-blast));g.setLineWidth(2+strength*.3);g.ellipse("line",x,y,95+blast*560,45+blast*240)
    end
    if strength>=4 and phase~="charge" then
        local radius=130+blast*150
        if strength==4 then
            for side=1,6 do local angle=side*math.pi/3+a.time*.45;local nextAngle=angle+math.pi/3
                rgba(c,.65*(1-blast*.6));g.line(x+math.cos(angle)*radius,y+math.sin(angle)*radius,x+math.cos(nextAngle)*radius,y+math.sin(nextAngle)*radius)
            end
        elseif strength==5 then
            rgba(c,.6*(1-blast*.6));g.setLineWidth(4)
            for sign=-1,1,2 do g.arc("line","open",x+sign*75,y,radius*.8,sign<0 and math.pi*.55 or -math.pi*.45,sign<0 and math.pi*1.45 or math.pi*.45) end
        elseif strength==6 then
            for i=1,12 do local angle=i*math.pi/6+a.time*.3;rgba(c,.32*(1-blast*.5))
                g.polygon("fill",x+math.cos(angle-.05)*115,y+math.sin(angle-.05)*115,x+math.cos(angle)*(radius+80),y+math.sin(angle)*(radius+80),x+math.cos(angle+.05)*115,y+math.sin(angle+.05)*115)
            end
        elseif strength==7 then
            for sign=-1,1,2 do rgba(c,.6*(1-blast*.5));g.setLineWidth(3);g.ellipse("line",x+sign*(50+blast*120),y,46+blast*40,190+blast*65) end
        elseif strength>=8 then
            for i=1,8 do
                local angle=i*math.pi/4+a.time*.7
                for tail=1,7 do local a2=angle-tail*.026;g.setColor(.6+.4*math.sin(angle)^2,.6+.4*math.sin(angle+2)^2,.6+.4*math.sin(angle+4)^2,(1-tail/8)*.55)
                    g.circle("fill",x+math.cos(a2)*radius,y+math.sin(a2)*radius*.78,1+strength*.32-tail*.25)
                end
            end
        end
    end
    if strength==9 and opened then
        for i=1,5 do rgba(c,math.max(0,.22-blast*.4));g.rectangle("fill",x-200+i*70,y-280,6+i,560) end
    end
    g.setBlendMode("alpha")
    if opened then
        if Visual.enabled then g.setColor(1,.95,1,math.max(0,.16*strength/9-blast*.5));g.rectangle("fill",-20,-20,1320,760) end
        g.push();g.translate(x,y);g.scale(1.6)
        Effects.drawSlot(ticket or Effects.profile(r),0,0,a.time-spec.revealAt,false,a.time)
        g.pop()
        local size=math.min(1,blast*7);g.push();g.translate(x,y);g.scale(math.max(.01,size),math.max(.01,size))
        local width=156+strength*6;art(r,-width/2,-width*.75,width,width*1.5);g.pop()
        text(ticket and ticket.label or r.featured and "HƯ KHÔNG VỠ TAN · TRÚNG BANNER" or ({"THƯỜNG","KHÁC THƯỜNG","HIẾM","SỬ THI","HUYỀN THOẠI","THẦN THOẠI","SIÊU VIỆT","ĐỘC NHẤT"})[strength],210,127,860,UI.fonts.large,c,"center")
        text(r.name,230,526,820,UI.fonts.medium,C.text,"center")
    else
        -- The closed core has no reward artwork or rarity badge.
        rgba(c,.35+charge*.25);g.setLineWidth(2);g.ellipse("line",x,y,34+charge*24,52+charge*25)
        rgba({.45,.85,1},.6);g.arc("line","open",x,y,90,a.time*3,a.time*3+math.pi*.8)
        text(phase=="charge" and "HƯ KHÔNG ĐANG LẮNG NGHE..." or phase=="signal" and "MỘT TÍN HIỆU TỪ BÊN KIA..." or "LÕI TRIỆU HỒI ĐANG RẠN NỨT...",210,526,860,UI.fonts.medium,c,"center")
    end
    text("LẦN MỞ "..a.index.." / "..#event.results,390,104,500,nil,C.muted,"center")
    for i=1,#event.results do
        rgba(i<=a.index and c or C.muted,i==a.index and 1 or .35)
        g.circle("fill",640+(i-(#event.results+1)/2)*18,590,i==a.index and 4 or 2.5)
    end
    g.pop()
    if ticket and opened then Effects.jackpot(ticket,a.time-spec.revealAt,1280,720,UI.fonts) end
    button(buttons,"void_skip","MỞ TOÀN BỘ KẾT QUẢ",447,637,386,46,false)
end
local function rates(buttons)
    local g=love.graphics;g.setColor(0,0,0,.78);g.rectangle("fill",0,0,1280,720)
    panel(220,97,845,526)
    text("XÁC SUẤT THỰC · MỖI LƯỢT ĐỘC LẬP",245,119,680,UI.fonts.medium,C.gold)
    button(buttons,"void_rates_close","ĐÓNG",950,115,94,34,false)
    text("Quay 10 không bảo đảm quà hiếm. Không cộng dồn may mắn. Không có bảo hiểm.",245,159,790,nil,C.red)
    for i,row in ipairs(G.config.rates) do
        local y=195+(i-1)*23
        if i%2==0 then g.setColor(.1,.1,.18,.4);g.rectangle("fill",238,y-3,807,24) end
        text(row.label,251,y,545,nil,i<=3 and C.gold or C.text)
        text(string.format("%.3f%%",row.weight/1000):gsub("%.",","),842,y,182,UI.fonts.small,i<=3 and C.gold or C.text,"right")
    end
    text("SPN thường: C 61,4% · UC 20% · R 10% · E 5% · L 2% · M 1% · T 0,5% · UQ 0,1% trong nhóm SPN 3%.\nTrúng nhóm vé: nhận 1–100 vé, mỗi số lượng có xác suất bằng nhau (1% trong nhóm).",245,505,785,nil,C.muted)
    text("Đồ/lá/rương/tiêu hao/đặc quyền: chọn đều từ danh mục. Đặc quyền trùng → 3 vàng; rương không còn nội dung hợp lệ → 1 vàng. Rương mở tại shop sau Void.",245,547,785,nil,C.muted)
    text("Banner cộng lại 0,004% · Trung bình 1 / 25.000 lượt, không phải mốc bảo đảm.",245,589,785,UI.fonts.small,C.red)
end
function V.draw(game,buttons,mx,my)
    local event=game.voidEvent;if not event then return end
    local g=love.graphics;g.push("all")
    panel(18,14,1244,66)
    text("THE VOID · GIAO ƯỚC HƯ KHÔNG",36,23,790,UI.fonts.large,C.gold)
    text("Boss ải "..event.ante.." · Banner của lần viếng thăm này · KHÔNG BẢO HIỂM",38,58,790,nil,C.muted)
    if event.pendingResults then
        UI.CardPhysics.suspend();summon(event,buttons);UI.CardPhysics.resume()
        g.pop();return
    end
    button(buttons,"void_rates","BẢNG TỶ LỆ",974,27,130,37,false)
    button(buttons,"void_leave","RỜI THE VOID",835,27,126,37,false)
    panel(23,102,279,190)
    text("ĐÁNH ĐỔI VỚI HƯ KHÔNG",38,119,249,UI.fonts.small,C.gold)
    text("1 lượt  ·  10 vé / 100 vàng\n10 lượt  ·  100 vé / 1.000 vàng",38,154,249,UI.fonts.small,C.text)
    text("Mỗi lượt độc lập. Không bảo hiểm.",38,198,249,nil,C.muted)
    local offer=event.freeRemaining>0 and "ƯU ĐÃI: 1 LƯỢT MIỄN PHÍ" or event.goldMultiplier<1 and "ƯU ĐÃI: GIẢM "..math.floor((1-event.goldMultiplier)*100).."% GIÁ VÀNG" or "HÔM NAY KHÔNG CÓ ƯU ĐÃI"
    text(offer,38,223,249,UI.fonts.small,event.freeRemaining>0 and C.green or C.purple)
    if mx>=38 and mx<=287 and my>=220 and my<=252 then UI.descriptionCandidate={hoverKey=event,name="ƯU ĐÃI CỦA THE VOID",desc="Mỗi lần vào: 2% nhận một lượt miễn phí; 5% giảm 50% giá vàng; 10% giảm 25% giá vàng; 83% giá thường. Vé không giảm giá. Ưu đãi cố định khi tải lại.",color=C.purple} end
    text("Thường: 1% · Boss: luôn 1–100 vé.",38,257,249,nil,C.muted)
    panel(23,474,279,222)
    text("HÀNH TRANG VIỄN CHINH",38,491,249,UI.fonts.small,C.gold)
    for i,kind in ipairs({"gold","souls"}) do
        local y=522+(i-1)*54
        art({kind=kind},38,y,29,44)
        text(tostring(kind=="gold" and (game.gold or 0) or (game.souls or 0)),79,y+2,205,UI.fonts.medium,kind=="gold" and C.gold or C.purple)
        text(kind=="gold" and "VÀNG" or "LINH HỒN",79,y+28,205,nil,C.muted)
    end
    text(tostring(require("src.void_tickets").count(game)).." VÉ TRONG BALO",38,637,249,UI.fonts.small,C.purple)
    text("Đã quay tại đây: "..event.totalRolls.." lượt",38,671,249,nil,C.muted)
    text("Cổng mở. Không lời hứa.\nChỉ có vận may của bạn.",38,359,249,UI.fonts.small,C.muted,"center")
    panel(320,101,932,272)
    text("BANNER CỦA LẦN VIẾNG THĂM",338,111,650,nil,C.muted)
    text("CỰC HIẾM · KHÔNG BẢO ĐẢM",975,111,259,nil,C.red,"right")
    if V.bannerEvent~=event then V.bannerEvent=event;V.featured=G.banner(game) end
    for i,r in ipairs(V.featured) do
        local x=336+(i-1)*302;local color=G.config.colors[i==1 and 8 or 5]
        panel(x,136,292,220,color)
        art(r,x+12,157,104,156)
        text(r.label,x+129,152,150,UI.fonts.small,color)
        text(r.name,x+129,194,151,UI.fonts.small,C.text)
        text(r.chance,x+129,263,151,UI.fonts.medium,C.gold)
        text(i==1 and "1 / 50.000 lượt" or "1 / 100.000 lượt",x+129,291,151,nil,C.muted)
        text("Rê chuột để xem sức mạnh",x+12,332,267,nil,C.muted,"center")
        if mx>=x and mx<=x+292 and my>=136 and my<=356 then UI.descriptionCandidate=r.item end
    end
    panel(320,385,932,216)
    text("KẾT QUẢ LẦN QUAY",338,396,440,UI.fonts.small,C.gold)
    text(#event.results>0 and (#event.results.." PHẦN THƯỞNG · ĐÃ NHẬN") or "CHƯA TRIỆU HỒI",909,398,324,nil,C.muted,"right")
    if #event.results==0 then
        text("CỔNG TRIỆU HỒI ĐANG CHỜ",340,467,892,UI.fonts.medium,C.purple,"center")
        text("Chọn vé hoặc vàng bên dưới để mở cổng.\nPhần lớn lượt quay mang về vàng lẻ, linh hồn hoặc đồ thường.",350,506,870,nil,C.muted,"center")
    else
        for i,r in ipairs(event.results) do
            local x=336+(i-1)%5*181;local y=425+math.floor((i-1)/5)*85
            local ticket=r.kind=="ticket" and Effects.profile(r)
            local color=ticket and ticket.color or r.kind=="gold" and C.gold or r.kind=="souls" and C.purple or G.config.colors[r.strength]
            panel(x,y,175,80,color);art(r,x+5,y+5,46,69)
            text(r.name,x+59,y+8,109,UI.fonts.tiny,r.featured and C.gold or C.text)
            text(ticket and (ticket.jackpot and "JACKPOT" or "VÉ THE VOID") or r.featured and "BANNER" or r.kind=="gold" and "VÀNG" or r.kind=="souls" and "LINH HỒN" or ({"C","UC","R","E","L","M","T","UQ"})[r.strength],x+59,y+61,109,nil,color)
            if mx>=x and mx<=x+175 and my>=y and my<=y+80 then UI.descriptionCandidate=r.item or {name=r.name,desc=r.kind=="hand" and "Tay bài tối đa đã tăng thêm 1 lá." or r.kind=="gold" and "Vàng đã được cộng vào túi tiền, có thể dùng ngay tại shop hoặc The Void." or r.kind=="souls" and "Linh hồn đã được cộng vào hành trang để giao dịch tại shop linh hồn." or "Phần thưởng đã ghi nhận trong hành trang.",color=color} end
        end
    end
    panel(320,613,932,83)
    text("THANH TOÁN BẰNG",336,624,244,nil,C.muted)
    button(buttons,"void_tickets","VÉ",336,650,113,33,false)
    button(buttons,"void_gold","VÀNG",459,650,113,33,false)
    local bx=event.payment=="ticket" and 336 or 459
    rgba(C.purple,.9);g.setLineWidth(2);UI.drawRoundedRect("line",bx,650,113,33,4)
    for i,count in ipairs({1,10}) do
        local q=G.quote(game,count,event.payment)
        local label=q.cost==0 and "MIỄN PHÍ" or q.cost..(event.payment=="ticket" and " VÉ" or " VÀNG")
        button(buttons,"void_pull_"..count,"QUAY "..count.." LẦN\n"..label,597+(i-1)*322,625,310,59,not q.affordable)
    end
    if V.showRates then for i=#buttons,1,-1 do table.remove(buttons,i) end;rates(buttons) end
    g.pop()
end
function V.press(game,b)
    local event=game.voidEvent;if not event or b.disabled then return end
    if b.id=="void_skip" then G.finishReveal(game);V.animation=nil;return "changed" end
    if event.pendingResults then return end
    if b.id=="void_leave" then V.bannerEvent=nil;V.showRates=nil;return "leave"
    elseif b.id=="void_rates" then V.showRates=true
    elseif b.id=="void_rates_close" then V.showRates=nil
    elseif b.id=="void_gold" then event.payment="gold"
    elseif b.id=="void_tickets" then event.payment="ticket"
    elseif b.id:match("^void_pull_%d+$") then
        local ok=G.pull(game,tonumber(b.id:match("(%d+)$")),event.payment)
        if ok then V.update(0,game) end
        return ok and "pulled" or nil
    end
    return "changed"
end
return V
