local Panel={}
local L=require("src.loadout")
local Style=require("ui.backpack_style")
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function Panel.select(UI,Bag,entry,combat)
    Bag.selected=entry.index;Bag.selectedSource=entry.source
    Bag.message=entry.source=="reserve" and ("Nhấp ô phía trên để gắn hoặc thay thế; đồ cũ trở về kho."..(combat and " Đổi đồ tốn 1 lượt đánh." or "")) or "Đã chọn ô trang bị; có thể cất lại hoặc kéo sang ô khác."
    UI.Polish.clearFocus()
    if not combat then
        local kind=entry.source=="reserve" and (Bag.tab=="spn" and "reserve_deity" or "reserve_consumable")
            or (Bag.tab=="spn" and "deity" or "consumable")
        local _,activeIndex=L.equipped(Bag.game,Bag.tab,entry.index)
        UI.Polish.focusItem(entry.item,kind,entry.source=="reserve" and entry.index or activeIndex,entry)
    end
end
function Panel.draw(UI,Bag,game,buttons,mx,my)
    L.init(game);Bag.game=game;Bag.loadoutSlots={}
    local g=love.graphics;local limit=L.limit(game,Bag.tab)
    local selected=Bag.selectedSource=="reserve" and (game.backpackDeities or {})[Bag.selected]
    if Bag.tab=="spn" and selected and selected.edition=="negative" then limit=limit+((selected.editionPower==5 or selected.bloodPower==5) and 5 or 1) end
    local offset=math.max(0,math.min(Bag.loadoutOffset or 0,math.max(0,limit-6)))
    Bag.loadoutOffset=offset
    Style.panel(235,117,692,141,UI.COLORS.goldYellow)
    g.setFont(UI.fonts.tiny);g.setColor(UI.COLORS.goldYellow)
    g.print("TRANG BỊ · MANG VÀO TRẬN",249,126)
    g.setColor(UI.COLORS.textMuted)
    g.printf(Bag.combat and "ĐỔI ĐỒ: 1 LƯỢT ĐÁNH · ĐỊCH HÀNH ĐỘNG" or "SẮP XẾP MIỄN PHÍ TRONG SHOP",492,126,420,"right")
    for slot=offset+1,math.min(limit,offset+6) do
        local item,index=L.equipped(game,Bag.tab,slot)
        local r={x=254+(slot-offset-1)*109,y=150,w=64,h=96,index=slot,item=item,activeIndex=index,source="equipped"}
        Bag.loadoutSlots[#Bag.loadoutSlots+1]=r
        local hover=inside(mx,my,r)
        Style.panel(r.x-5,r.y-3,r.w+10,r.h+6,selected and UI.COLORS.goldYellow or item and (item.color or UI.COLORS.goldYellow) or {.3,.38,.4,1},hover or selected or Bag.selectedSource=="equipped" and Bag.selected==slot)
        if item and not (Bag.drag and Bag.drag.moving and Bag.drag.item==item) and not UI.Polish.hiddenOwned(item) then
            if Bag.tab=="spn" then
                item.slotIndex=slot
                UI.drawPatronCard(item,r.x,r.y,r.w,r.h,hover,false,false,item.isCopyDeity and require("src.deities").resolveDeity(game.deities,slot,game))
            else UI.Polish.renderItem(UI,item,r.x,r.y,r.w,r.h) end
        elseif not item then
            g.setFont(UI.fonts.medium);g.setColor(.55,.65,.64,.65);g.printf("+",r.x,r.y+29,r.w,"center")
            g.setFont(UI.fonts.tiny);g.printf("Ô "..slot,r.x,r.y+65,r.w,"center")
        end
        if hover and item then UI.descriptionCandidate=item end
    end
    if limit>6 then
        for i,id in ipairs({"bag_loadout_prev","bag_loadout_next"}) do
            local b={id=id,text=i==1 and "‹" or "›",x=879,y=151+(i-1)*49,w=34,h=40,font=UI.fonts.small,color=UI.COLORS.btnSpecial,
                disabled=i==1 and offset<=0 or i==2 and offset+6>=limit}
            buttons[#buttons+1]=b;UI.drawButton(b,inside(mx,my,b))
        end
    end
end
function Panel.press(UI,Bag,game,x,y,mouse,callbacks)
    for _,r in ipairs(Bag.loadoutSlots or {}) do if inside(x,y,r) then
        if mouse==1 and Bag.selectedSource=="reserve" and Bag.selected then
            callbacks.transfer(Bag.tab,"reserve",Bag.selected,r.index);return true
        end
        if not r.item then return true end
        if mouse==2 then
            if Bag.tab=="consumable" then callbacks.activate(r.activeIndex)
            elseif callbacks.inspect then callbacks.inspect(r.item) end
            return true
        end
        if mouse==1 then
            Panel.select(UI,Bag,r,Bag.combat)
            Bag.drag={item=r.item,index=r.index,source="equipped",startX=x,startY=y,x=x,y=y,rect=r}
        end
        return true
    end end
    return false
end
function Panel.move(Bag,x,y)
    if not Bag.drag then return false end
    local d=Bag.drag;d.x=x;d.y=y
    if (x-d.startX)^2+(y-d.startY)^2>49 then d.moving=true;require("src.ui").Polish.clearFocus() end
    return true
end
function Panel.release(Bag,x,y,mouse,transfer)
    if mouse~=1 or not Bag.drag then return false end
    local d=Bag.drag;Bag.drag=nil
    if not d.moving then return true end
    for _,r in ipairs(Bag.loadoutSlots or {}) do if inside(x,y,r) then
        transfer(Bag.tab,d.source,d.index,r.index);return true
    end end
    if d.source=="equipped" and x>=235 and x<=927 and y>=266 and y<=635 then transfer(Bag.tab,d.source,d.index,nil)
    else Bag.message="Kéo lên ô trang bị hoặc kéo xuống kho balo." end
    return true
end
function Panel.drawDrag(UI,Bag)
    local d=Bag.drag
    if d and d.moving then
        UI.CardPhysics.suspend()
        local g=love.graphics;g.push("all")
        Style.glow(d.x,d.y,80,d.item.color or UI.COLORS.goldYellow,.25)
        UI.Polish.renderItem(UI,d.item,d.x-43,d.y-65,86,130)
        g.pop();UI.CardPhysics.resume()
    end
end
return Panel
