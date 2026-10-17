local E={open=false,page=1,kind="spn",slots={},controls={}}
local L=require("src.loadout")
local H=require("ui.combat_chrome")
local C=require("ui.components.core")
local T=require("ui.theme")
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function E.close()
    E.open=false;E.drag=nil;E.moving=nil;E.targeting=false
end
function E.show(kind)
    E.open=true;E.kind=kind;E.page=1;E.selected=nil;E.scroll=0;E.moving=nil;E.drag=nil;E.message=nil;E.detail=nil;E.maxScroll=0
    require("src.ui").Description.reset();require("src.ui").Polish.clearFocus()
end
function E.rect(kind,slot)
    if E.open and E.kind==kind then for _,r in ipairs(E.slots) do if r.slot==slot then return r.x+20,r.y+27,100,150 end end end
end
function E.railButtons(UI,buttons,mx,my,game)
    for kind,rect in pairs({spn=require("ui.layout").battle.spm,consumable=require("ui.layout").battle.consumables}) do
        local b={id="expand_"..kind,text="MỞ RỘNG ▾",x=rect[1]+16,y=rect[2]+163,w=112,h=20,font=UI.fonts.tiny,variant=kind=="spn" and "gold" or "green"}
        buttons[#buttons+1]=b;H.button(UI,b,mx,my)
        C.text(UI.InventoryRail.hint(kind,game),rect[1]+140,b.y+4,rect[3]-156,UI.fonts.tiny,T.colors.muted,"right")
    end
end
function E.turn(delta)
    if E.game then E.pages=math.max(1,math.ceil(L.limit(E.game,E.kind)/10)) end
    E.page=math.max(1,math.min(E.pages or 1,E.page+delta));E.drag=nil
end
function E.draw(UI,game,mx,my,pending)
    E.game=game
    local g=love.graphics;local color=E.kind=="spn" and T.colors.gold or T.colors.green
    L.init(game);E.pages=math.max(1,math.ceil(L.limit(game,E.kind)/10));E.page=math.min(E.page,E.pages)
    E.slots={};E.controls={};UI.descriptionCandidate=nil;UI.CardPhysics.blockBehind()
    g.push("all");g.setColor(.003,.009,.014,.87);g.rectangle("fill",0,0,1280,720)
    H.panel(30,82,1220,620,color)
    H.crest(66,112,18,color,E.kind=="spn" and "spn" or "consumable")
    H.title(E.kind=="spn" and "ĐỘI HÌNH HỘ LINH" or "THẺ TIÊU HAO",96,95,570,UI.fonts.medium,color)
    C.text("Tách rõ từng lá · Thứ tự từ trái sang phải",96,123,560,UI.fonts.tiny,T.colors.muted)
    local function control(id,text,x,y,w,disabled,variant)
        local b={id=id,text=text,x=x,y=y,w=w,h=32,font=UI.fonts.tiny,variant=variant or "gold",disabled=disabled}
        E.controls[#E.controls+1]=b;H.button(UI,b,mx,my)
    end
    control("tab_spn","SPN",838,101,102,false,E.kind=="spn" and "gold" or "cyan")
    control("tab_consumable","TIÊU HAO",949,101,133,false,"green")
    control("close","THU GỌN ×",1092,101,130)
    H.rule(54,151,1172,color)
    C.text((E.kind=="spn" and require("src.deities").getCount(game.deities) or #game.consumables).." / "..L.limit(game,E.kind).." ĐANG TRANG BỊ",641,124,173,UI.fonts.tiny,color,"right")
    local first=(E.page-1)*10+1
    for slot=first,math.min(L.limit(game,E.kind),first+9) do
        local n=slot-first;local item,index=L.equipped(game,E.kind,slot)
        local r={x=54+n%5*158,y=169+math.floor(n/5)*236,w=140,h=223,slot=slot,item=item,index=index}
        E.slots[#E.slots+1]=r
        local selected=E.selected==slot;local over=inside(mx,my,r)
        local locked=require("src.boss_abilities").isSlotLocked(game,E.kind,slot)
        H.panel(r.x,r.y,r.w,r.h,selected and color or T.colors.goldDim)
        if selected or over then C.color(color,selected and .8 or .45);g.rectangle("line",r.x+6,r.y+6,r.w-12,r.h-12,4) end
        C.text("Ô "..slot..(locked and " · KHÓA" or ""),r.x+12,r.y+8,r.w-24,UI.fonts.tiny,locked and T.colors.red or color)
        if item then
            if E.kind=="spn" then
                item.slotIndex=slot
                UI.drawPatronCard(item,r.x+20,r.y+27,100,150,false,false,false,item.isCopyDeity and require("src.deities").resolveDeity(game.deities,slot,game))
            else UI.Polish.renderItem(UI,item,r.x+20,r.y+27,100,150) end
            C.text(item.name,r.x+7,r.y+181,r.w-14,UI.fonts.tiny,T.colors.text,"center")
        else
            C.text("+",r.x+20,r.y+74,100,UI.fonts.title,T.colors.goldDim,"center")
            C.text("Ô TRỐNG",r.x+7,r.y+181,r.w-14,UI.fonts.tiny,T.colors.muted,"center")
        end
    end
    H.panel(854,169,372,459,color)
    local item,index
    if E.selected then item,index=L.equipped(game,E.kind,E.selected) end
    E.activeIndex=index;E.selectedItem=item
    if item then
        local title,body=require("src.card_description").resolve(item,game)
        if E.kind=="consumable" then body=body:gsub("chuột phải dùng một lần","nhấn DÙNG THẺ để dùng một lần"):gsub("Dùng chuột phải;","Nhấn DÙNG THẺ;") end
        C.text(title,872,185,335,UI.fonts.medium,color)
        local _,titleLines=UI.fonts.medium:getWrap(title,335)
        local top=192+#titleLines*UI.fonts.medium:getHeight()
        local edition=require("src.card_effects").getDefinition(item.edition)
        C.text("VỊ TRÍ "..E.selected..(edition and " · "..edition.shopLabel or ""),872,top,335,UI.fonts.tiny,T.colors.muted)
        top=top+28;E.detail={x=872,y=top,w=335,h=542-top}
        local _,lines=UI.fonts.small:getWrap(body,335)
        E.maxScroll=math.max(0,#lines*UI.fonts.small:getHeight()-E.detail.h)
        E.scroll=math.max(0,math.min(E.scroll or 0,E.maxScroll))
        g.push("all")
        local sx,sy=g.transformPoint(E.detail.x,E.detail.y)
        local ex,ey=g.transformPoint(E.detail.x+E.detail.w,E.detail.y+E.detail.h)
        g.intersectScissor(sx,sy,ex-sx,ey-sy)
        C.text(body,872,top-E.scroll,335,UI.fonts.small,T.colors.text)
        g.pop()
        if E.maxScroll>0 then C.text("↕ Cuộn để đọc đầy đủ",872,544,335,UI.fonts.tiny,T.colors.muted,"right") end
        control("inspect","XEM CHI TIẾT",872,574,160)
        control(E.kind=="spn" and "reorder" or "use",E.kind=="spn" and "ĐỔI VỊ TRÍ" or "DÙNG THẺ",1045,574,161,pending~=nil,E.kind=="spn" and "gold" or "green")
    else
        H.crest(1040,305,37,color,E.kind=="spn" and "spn" or "consumable")
        C.text("CHỌN MỘT LÁ",879,369,322,UI.fonts.medium,color,"center")
        C.text("Đọc toàn bộ tác dụng, xem ấn bản\nvà thao tác đúng lá bạn cần.",882,409,316,UI.fonts.small,T.colors.muted,"center")
    end
    control("prev","‹",54,649,38,E.page<=1)
    control("next","›",213,649,38,E.page>=E.pages)
    C.text(E.page.." / "..E.pages,97,658,109,UI.fonts.tiny,T.colors.text,"center")
    local hint=pending and "CHỌN SPN ĐỂ ÁP DỤNG · THU GỌN ĐỂ CHỌN BÀI TRÊN TAY"
        or E.moving and ("CHỌN Ô ĐÍCH CHO Ô "..E.moving.." · ESC HỦY")
        or "Kéo thả đổi ô · Đổi đồ tốn 1 lượt đánh · Chuột phải xem chi tiết"
    C.text(E.message or hint,273,657,943,UI.fonts.tiny,E.message and T.colors.red or T.colors.muted)
    g.pop();UI.descriptionCandidate=nil
end
local function transfer(cb,from,to)
    if from==to then return end
    if cb.transfer(E.kind,"equipped",from,to) then E.close()
    else E.message=require("src.ui").Backpack.message;E.moving=nil end
end
function E.press(x,y,mouse,cb)
    for _,b in ipairs(E.controls) do if inside(x,y,b) then
        if mouse~=1 or b.disabled then return end
        if b.id=="close" then E.close()
        elseif b.id=="tab_spn" or b.id=="tab_consumable" then E.show(b.id:sub(5))
        elseif b.id=="prev" or b.id=="next" then E.turn(b.id=="prev" and -1 or 1)
        elseif b.id=="inspect" then cb.inspect(E.selectedItem)
        elseif b.id=="reorder" then E.moving=E.selected;E.message=nil
        elseif b.id=="use" then cb.activate(E.activeIndex) end
        return
    end end
    for _,r in ipairs(E.slots) do if inside(x,y,r) then
        if mouse==2 then if r.item then cb.inspect(r.item) end;return end
        if mouse~=1 then return end
        if r.item and cb.target(r) then return end
        if E.moving then transfer(cb,E.moving,r.slot);return end
        E.selected=r.slot;E.scroll=0;E.message=nil
        if r.item then
            require("src.card_physics").press(x,y,mouse)
            E.drag={slot=r.slot,startX=x,startY=y,x=x,y=y}
        end
        return
    end end
end
function E.move(x,y)
    if not E.drag then return end
    local d=E.drag;d.x=x;d.y=y
    if (x-d.startX)^2+(y-d.startY)^2>49 then d.moving=true end
end
function E.release(x,y,mouse,cb)
    if mouse~=1 then return end
    local d=E.drag;E.drag=nil
    if d and d.moving then for _,r in ipairs(E.slots) do if inside(x,y,r) then transfer(cb,d.slot,r.slot);return end end end
end
function E.wheel(y,x,my)
    if E.detail and inside(x,my,E.detail) then E.scroll=math.max(0,math.min(E.maxScroll or 0,(E.scroll or 0)-y*38))
    elseif y~=0 then E.turn(y>0 and -1 or 1) end
end
return E
