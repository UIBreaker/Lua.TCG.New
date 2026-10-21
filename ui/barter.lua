local UI=require("src.ui")
local Core=require("ui.components.core")
local Chrome=require("ui.combat_chrome")
local Theme=require("ui.theme")
local T=require("src.barter")
local Search=require("ui.backpack_qol")
local utf8=require("utf8")
local C=Theme.colors
local V={}
local sides={player={x=24,color={.46,.77,.80,1},title="Hành trang của bạn"},npc={x=840,color={.93,.75,.44,1},title="Người viễn chinh"}}
local filters={{"all","Tất cả vật phẩm"},{"spn","Hộ linh · SPN"},{"equipment","Trang bị"},{"consumable","Thẻ tiêu hao"},{"card","Quân bài"},{"resource","Linh hồn & vé"},{"selected","Đã đưa lên bàn"}}
local needs={guard="Tiếp tế & phòng hộ",speed="Tốc đánh",wealth="Nguồn lực",attack="Sức mạnh"}
local statuses={draft="Đang soạn đề nghị",thinking="Đang cân nhắc…",agreed="Hai bên đã đồng ý",counter="Họ muốn thương lượng",refused="Chưa đạt thỏa thuận",complete="Giao dịch hoàn tất"}
local function text(s,x,y,w,font,color,align) Core.text(s,x,y,w,font or UI.fonts.tiny,color or C.text,align) end
local function line(s,x,y,w,font,color,align) Core.textLine(s,x,y,w,font or UI.fonts.tiny,color or C.text,align or "left",UI.fonts.tiny) end
local function inside(mx,my,x,y,w,h) return mx>=x and my>=y and mx<=x+w and my<=y+h end
local function rule(x,y,w,color) Core.color(color or C.gold,.22);love.graphics.line(x,y,x+w,y) end
local function surface(x,y,w,h,color,alpha)
    Core.gradient(x,y,w,h,{.066,.082,.085,alpha or .97},{.023,.035,.041,alpha or .97},5)
    Core.color(color or C.goldDim,.30);love.graphics.setLineWidth(1);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,5)
end
local function button(buttons,id,label,x,y,w,h,disabled,color,data)
    local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled,color=color or C.inset,font=UI.fonts.small}
    for k,v in pairs(data or {}) do b[k]=v end
    UI.drawButton(b,not disabled and inside(V.mx or -1,V.my or -1,x,y,w,h));buttons[#buttons+1]=b;return b
end
local function action(buttons,id,label,x,y,w,h,disabled,color,data)
    local b=button(buttons,id,label,x,y,w,h,disabled,color,data)
    if disabled then return b end
    -- A filled metal face distinguishes the two transaction actions from navigation.
    local light=inside(V.mx or -1,V.my or -1,x,y,w,h) and .54 or .42
    Core.gradient(x+3,y+3,w-6,h-6,{color[1]*light,color[2]*light,color[3]*light,1},{color[1]*.16,color[2]*.16,color[3]*.16,1},3)
    Core.color(color,.65);love.graphics.line(x+7,y+3,x+w-7,y+3)
    line(label,x+12,y+(h-UI.fonts.small:getHeight())/2,w-24,UI.fonts.small,{.98,.95,.85,1},"center")
    return b
end
local function name(item)
    return item.name or ((item.rankName or tostring(item.rank or ""))..(item.suitSymbol or "").." · "..(item.characterName or require("src.card_abilities").definition(item) and require("src.card_abilities").definition(item).characterName or "Quân bài"))
end
local function paragraph(s,x,y,w,rows,font,color)
    font=font or UI.fonts.tiny;local _,wrapped=font:getWrap(s or "",w)
    for i=1,math.min(rows,#wrapped) do
        local value=wrapped[i]..(i==rows and #wrapped>rows and "…" or "")
        line(value,x,y+(i-1)*(font:getHeight()+2),w,font,color)
    end
end
local function art(entry,x,y,w,h)
    local item=entry.item
    if entry.kind=="spn" then UI.drawPatronCard(item,x,y,w,h,false,false,false)
    elseif entry.kind=="card" then UI.drawCardFace(item,x,y,w,h,false)
    elseif entry.kind=="consumable" then UI.Polish.renderItem(UI,item,x,y,w,h)
    else
        local image=entry.kind=="resource" and require("src.continental_art").get(item.resource=="souls" and "void_souls" or "void_ticket") or UI.getEquipmentImage(item.id)
        if image then Core.color({1,1,1,1});UI.CardFrame.image(image,x,y,w,h) end
        UI.drawCardBorder(x,y,w,h,nil,nil,item)
    end
end
art=UI.CardPhysics.wrap(art,function(entry) return entry.item end)
local function picked(game,draft,side)
    local result={};for _,entry in ipairs(T.inventory(game,side)) do if draft[side][entry.key] then result[#result+1]=entry end end;return result
end
function V.list(game,side)
    local e=game.barterEvent;local list=e.filters[side]=="selected" and picked(game,e.draft,side) or T.inventory(game,side,e.filters[side])
    local result={};for _,entry in ipairs(list) do if Search.matches(entry.item,(V.queries or {})[side] or "") then result[#result+1]=entry end end
    return result
end
local function filterName(id) for _,f in ipairs(filters) do if f[1]==id then return f[2] end end;return filters[1][2] end
local function field(buttons,id,value,placeholder,x,y,w,h,data)
    surface(x,y,w,h,C.goldDim)
    local active=V.input and V.input.id==id and V.input.side==data.side
    if active then Core.color(C.gold,.8);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,4) end
    local content=active and V.input.value or value
    if active and love.timer.getTime()%1<.5 then content=content.."│" end
    line(content~="" and content or placeholder,x+10,y+(h-UI.fonts.small:getHeight())/2,w-20,UI.fonts.small,content~="" and C.text or C.muted)
    local b={id=id,x=x,y=y,w=w,h=h};for k,v in pairs(data) do b[k]=v end;buttons[#buttons+1]=b
end
local function inventory(game,buttons,side,mx,my)
    local e=game.barterEvent;local style=sides[side];local x=style.x;local accent=style.color
    Chrome.panel(x,108,416,450,accent)
    Chrome.crest(x+31,140,16,accent,side=="player" and "consumable" or "spn")
    Chrome.title(style.title,x+58,122,338,UI.fonts.medium,accent)
    line((side=="player" and game.gold or e.gold).." vàng đang có",x+59,153,330,nil,C.muted)
    -- Filters live in a single menu so inventory art keeps its space.
    button(buttons,"barter_filter_menu",filterName(e.filters[side]).."  ▾",x+16,178,176,30,false,nil,{side=side})
    field(buttons,"barter_search",V.queries[side],"Tìm vật phẩm…",x+201,178,197,30,{side=side})
    local items=V.list(game,side);local pages=math.max(1,math.ceil(#items/6));e.pages[side]=math.max(1,math.min(pages,e.pages[side] or 1))
    local first=(e.pages[side]-1)*6+1
    for i=first,math.min(#items,first+5) do
        local entry=items[i];local n=i-first;local tx,ty=x+16+n%3*129,218+math.floor(n/3)*153
        local selected=e.draft[side][entry.key];local hover=inside(mx,my,tx,ty,121,150)
        local wanted=side=="player" and T.role(entry.kind,entry.item)==e.need
        if selected or hover then
            surface(tx,ty,121,150,selected and C.green or accent,1)
            Core.color(selected and C.green or accent,.7);love.graphics.line(tx+8,ty+149,tx+113,ty+149)
        end
        art(entry,tx+28,ty+5,64,96)
        paragraph(name(entry.item),tx+3,ty+104,115,2,UI.fonts.tiny,C.text)
        local quote=T.quoteValue(game,entry.kind,entry.item,side)
        local price=side=="npc" and math.ceil(quote) or math.floor(quote)
        line((wanted and "Họ cần · " or "~ ")..price.." vàng",tx+3,ty+133,115,nil,wanted and C.green or C.gold,"center")
        if selected then
            Core.color(C.green);love.graphics.circle("fill",tx+104,ty+14,9)
            text("✓",tx+96,ty+6,17,UI.fonts.small,C.charcoal,"center")
        end
        buttons[#buttons+1]={id="barter_item",cardSurface=true,side=side,key=entry.key,resource=entry.kind=="resource" and entry.item.resource or nil,x=tx,y=ty,w=121,h=150,disabled=e.status=="thinking"}
        if hover then UI.descriptionCandidate=entry.item;V.hover=entry end
    end
    if #items==0 then
        text("Không có vật phẩm phù hợp",x+24,334,368,UI.fonts.small,C.muted,"center")
        text("Đổi bộ lọc hoặc từ khóa tìm kiếm",x+24,361,368,nil,C.muted,"center")
    end
    rule(x+16,524,382,accent)
    line(#items.." món  ·  "..e.pages[side].." / "..pages,x+18,531,270,nil,C.muted)
    button(buttons,"barter_page","‹",x+302,527,43,23,e.pages[side]<=1,nil,{side=side,delta=-1})
    button(buttons,"barter_page","›",x+355,527,43,23,e.pages[side]>=pages,nil,{side=side,delta=1})
end
local function tray(game,buttons,side,mx,my)
    local e=game.barterEvent;local x=sides[side].x;local color=sides[side].color;local entries=picked(game,e.draft,side)
    Chrome.panel(x,571,416,125,color)
    text(side=="player" and "BẠN ĐƯA" or "BẠN NHẬN",x+17,584,160,UI.fonts.small,color)
    line(#entries.." món  +  "..e.draft[side.."Gold"].." vàng",x+164,586,231,nil,C.gold,"right")
    rule(x+16,609,382,color)
    for i=1,math.min(6,#entries) do
        local entry=entries[i];local cx=x+20+(i-1)*51
        art(entry,cx,620,34,51)
        Core.color({.04,.06,.07,1});love.graphics.circle("fill",cx+32,624,7)
        text("×",cx+26,616,13,UI.fonts.small,C.text,"center")
        buttons[#buttons+1]={id="barter_item",cardSurface=true,side=side,key=entry.key,resource=entry.kind=="resource" and entry.item.resource or nil,x=cx-2,y=617,w=44,h=60,disabled=e.status=="thinking"}
        if inside(mx,my,cx-2,617,44,60) then UI.descriptionCandidate=entry.item end
    end
    if #entries==0 then
        text("+",x+26,629,25,UI.fonts.medium,C.goldDim)
        text("Chọn đồ ở kho phía trên để đưa lên bàn",x+63,638,325,nil,C.muted)
    elseif #entries>6 then text("+"..(#entries-6),x+326,632,62,UI.fonts.medium,color,"center") end
    if #entries>0 then
        button(buttons,"barter_review","Xem đủ →",x+302,675,94,18,false,nil,{font=UI.fonts.tiny})
    end
end
local function wallets(game,buttons)
    local e=game.barterEvent
    for i,side in ipairs({"player","npc"}) do
        local x=477+(i-1)*169
        text(side=="player" and "Bạn bù vàng" or "Họ bù vàng",x,418,156,UI.fonts.small,sides[side].color)
        field(buttons,"barter_gold_input",tostring(e.draft[side.."Gold"]),"0",x,441,156,36,{side=side})
        for n,s in ipairs({{"−25",-25},{"−1",-1},{"+1",1},{"+25",25}}) do
            button(buttons,"barter_gold",s[1],x+(n-1)*40,484,36,25,e.status=="thinking",nil,{side=side,delta=s[2],font=UI.fonts.tiny})
        end
    end
    local net=e.draft.playerGold-e.draft.npcGold
    local hint=V.input and V.input.id=="barter_gold_input" and "Enter để áp dụng · Esc để hủy"
    line(hint or (net>0 and ("Bạn trả ròng "..net.." vàng") or net<0 and ("Bạn nhận ròng "..(-net).." vàng") or "Trao đổi không bù vàng"),477,520,325,nil,C.gold,"center")
end
local function finishInput(game,commit)
    local input=V.input;if not input then return end;V.input=nil
    if input.id=="barter_gold_input" and commit then T.setGold(game,input.side,tonumber(input.value) or 0);return "changed" end
end
function V.textinput(game,value)
    if not V.input then return false end
    local input=V.input
    if input.id=="barter_gold_input" then value=value:gsub("[^0-9]","");if value=="" then return true end end
    input.value=(input.selectAll and "" or input.value)..value;input.selectAll=false
    if input.id=="barter_search" then
        local at=utf8.offset(input.value,65);if at then input.value=input.value:sub(1,at-1) end
        V.queries[input.side]=input.value;game.barterEvent.pages[input.side]=1
    else input.value=input.value:sub(1,9) end
    return true
end
function V.keypressed(game,key)
    if V.input then
        if key=="escape" then finishInput(game,false)
        elseif key=="return" or key=="kpenter" or key=="tab" then return finishInput(game,true) or "handled"
        elseif key=="backspace" then
            if V.input.selectAll then V.input.value="" else local at=utf8.offset(V.input.value,-1);if at then V.input.value=V.input.value:sub(1,at-1) end end
            V.input.selectAll=false
            if V.input.id=="barter_search" then V.queries[V.input.side]=V.input.value;game.barterEvent.pages[V.input.side]=1 end
        elseif key=="a" and love.keyboard.isDown("lctrl","rctrl") then V.input.selectAll=true end
        return "handled"
    end
    if key=="escape" and (V.showDialogue or V.dropdown) then V.showDialogue=nil;V.modal=nil;V.dropdown=nil;return "handled" end
end
function V.wheel(game,y,mx,my)
    local e=game.barterEvent;if not e or V.dropdown or y==0 then return false end
    local delta=y>0 and -1 or 1
    if V.modal then V.dialoguePage=math.max(1,(V.dialoguePage or 1)+delta);return true end
    for side,s in pairs(sides) do
        if inside(mx,my,s.x,108,416,450) then e.pages[side]=math.max(1,math.min(math.max(1,math.ceil(#V.list(game,side)/6)),e.pages[side]+delta));return true end
    end
    return false
end
local function filterMenu(game,buttons)
    if not V.dropdown then return end
    local side=V.dropdown;local x=sides[side].x+16
    for i=#buttons,1,-1 do buttons[i]=nil end
    Chrome.panel(x,211,242,252,sides[side].color)
    for i,f in ipairs(filters) do
        button(buttons,"barter_filter",f[2],x+10,219+(i-1)*33,222,30,false,game.barterEvent.filters[side]==f[1] and sides[side].color or C.inset,{side=side,filter=f[1]})
    end
    buttons[#buttons+1]={id="barter_dismiss_menu",x=0,y=0,w=1280,h=720}
end
function V.draw(game,buttons,mx,my)
    local e=game.barterEvent;if not e then return end
    if V.event~=e then V.event=e;V.showDialogue=nil;V.lastStatus=nil;V.resource=nil;V.queries={player="",npc=""};V.input=nil;V.dropdown=nil end
    V.hover=nil;V.modal=nil;V.mx=mx;V.my=my
    if e.status~=V.lastStatus then
        if e.status=="counter" or e.status=="refused" then V.showDialogue=true;V.dialoguePage=1;V.input=nil end
        V.lastStatus=e.status
    end
    local g=love.graphics;g.push("all")
    Core.color({.008,.012,.017,.38});g.rectangle("fill",0,0,1280,720)
    Chrome.panel(24,16,1232,75,C.gold)
    Chrome.crest(53,49,19,C.gold)
    Chrome.title("GIAO ƯỚC VIỄN CHINH",84,29,920,UI.fonts.large,{.97,.83,.58,1})
    text("Ải "..e.ante.."  /  Hai hành trang, một thỏa thuận",85,65,560,nil,C.muted)
    text("01  CHỌN ĐỒ   /   02  TRẢ GIÁ   /   03  CHỐT",646,65,400,nil,C.gold,"center")
    button(buttons,"barter_leave","Lên đường →",1064,60,172,24,false,nil,{font=UI.fonts.tiny})
    inventory(game,buttons,"player",mx,my);inventory(game,buttons,"npc",mx,my)
    if not V.npc then
        V.npc=g.newImage(T.npcPath);V.npc:setFilter("linear","linear")
        local iw,ih=V.npc:getDimensions();V.npcBands={};V.portraitHeight=ih*.47
        for i=1,22 do V.npcBands[i]=g.newQuad(0,(i-1)*V.portraitHeight/22,iw,V.portraitHeight/22,iw,ih) end
    end
    local iw=V.npc:getWidth();local scale=163/V.portraitHeight
    for i=3,1,-1 do Core.color(C.gold,.018*i);g.circle("fill",640,190,65+i*7,64) end
    Core.color(C.gold,.24);g.setLineWidth(1);g.arc("line","open",640,192,76,-math.pi*.82,-math.pi*.18,48)
    for i,quad in ipairs(V.npcBands) do
        Core.color({1,1,1,math.min(1,(23-i)/5)});g.draw(V.npc,quad,640-iw*scale/2,104+(i-1)*163/22,0,scale,scale)
    end
    Chrome.title("Kẻ lữ hành vô danh",474,273,332,UI.fonts.medium,C.gold,"center")
    line("ĐANG TÌM  ·  "..needs[e.need],474,304,332,nil,C.green,"center")
    surface(461,329,358,77,C.goldDim)
    paragraph("“"..e.message.."”",477,339,326,3,UI.fonts.small,C.text)
    buttons[#buttons+1]={id="barter_review",x=461,y=329,w=358,h=77}
    wallets(game,buttons)
    local good=e.status=="agreed" or e.status=="complete"
    Core.color(good and C.green or C.gold,.85);g.circle("fill",496,548,3)
    line(statuses[e.status],507,541,276,nil,good and C.green or C.muted)
    tray(game,buttons,"player",mx,my);tray(game,buttons,"npc",mx,my)
    action(buttons,"barter_propose",e.status=="thinking" and "ĐANG CÂN NHẮC…" or "GỬI ĐỀ NGHỊ / TRẢ GIÁ",461,574,358,41,e.status=="thinking",C.gold)
    action(buttons,"barter_accept","CHỐT GIAO DỊCH",461,624,358,42,e.status~="agreed",C.green)
    button(buttons,"barter_clear","Chọn lại",461,674,108,23,e.status=="thinking",nil,{font=UI.fonts.tiny})
    button(buttons,"barter_initiate",e.counter and "Xem đề nghị của họ →" or "Nghe họ đề nghị →",578,674,241,23,e.status=="thinking",nil,{font=UI.fonts.tiny})
    if e.filters.player=="resource" then V.resource=V.resource or ((game.souls or 0)>0 and "souls" or "voidTickets") end
    if e.filters.player=="resource" and V.resource then
        local id=V.resource;local amount=math.min(game[id] or 0,e.amounts[id] or 1)
        surface(40,486,382,41,C.goldDim)
        line((id=="souls" and "Linh hồn" or "Vé quay").." đem đổi: "..amount,51,500,194,nil,C.gold)
        for i,s in ipairs({{"−1",-1},{"+1",1},{"Hết",0}}) do
            button(buttons,"barter_amount",s[1],251+(i-1)*54,493,49,28,e.status=="thinking",nil,{resource=id,delta=s[2],maximum=i==3,font=UI.fonts.tiny})
        end
    end
    filterMenu(game,buttons)
    g.pop()
    V.dialogue(game,buttons,mx,my)
end
function V.dialogue(game,buttons,mx,my)
    local e=game.barterEvent;if not V.showDialogue then return end
    for i=#buttons,1,-1 do buttons[i]=nil end
    UI.descriptionCandidate=nil;V.modal=true
    local g=love.graphics;g.push("all");Core.color({0,0,0,.79});g.rectangle("fill",0,0,1280,720)
    Chrome.panel(174,72,932,594,C.gold)
    text(e.counter and "HỌ ĐƯA RA ĐỀ NGHỊ KHÁC" or "ĐIỀU KHOẢN TRAO ĐỔI",199,94,820,UI.fonts.medium,C.gold)
    button(buttons,"barter_close_dialogue","×",1040,91,39,30,false,nil)
    paragraph(e.message,199,132,876,3,UI.fonts.small,C.text)
    local draft=e.counter or e.draft;local lists={player=picked(game,draft,"player"),npc=picked(game,draft,"npc")}
    local pages=math.max(1,math.ceil(math.max(#lists.player,#lists.npc)/4));V.dialoguePage=math.max(1,math.min(pages,V.dialoguePage or 1))
    for _,side in ipairs({"player","npc"}) do
        local x=side=="player" and 198 or 656;local color=sides[side].color
        text(side=="player" and "BẠN ĐƯA" or "BẠN NHẬN",x+12,204,416,UI.fonts.small,color)
        surface(x,234,426,293,color)
        local first=(V.dialoguePage-1)*4+1
        for i=first,math.min(#lists[side],first+3) do
            local entry=lists[side][i];local y=246+(i-first)*68
            art(entry,x+12,y,34,51);line(name(entry.item),x+59,y+1,351,UI.fonts.small,C.text)
            line(T.kinds[entry.kind].." · "..entry.where,x+59,y+23,351,nil,C.muted)
            if side=="player" and T.role(entry.kind,entry.item)==e.need then text("Hợp nhu cầu của họ",x+59,y+40,351,nil,C.green) end
            if inside(mx,my,x,y,426,61) then UI.descriptionCandidate=entry.item end
        end
        if #lists[side]==0 then
            Chrome.crest(x+213,337,29,C.gold)
            text(draft[side.."Gold"]>0 and "THANH TOÁN BẰNG VÀNG" or "Chưa chọn vật phẩm",x+20,387,386,UI.fonts.small,C.muted,"center")
        end
        line(#lists[side].." món  +  "..draft[side.."Gold"].." vàng",x+12,542,402,UI.fonts.regular,C.gold,"right")
    end
    text("Giữ nguyên nâng cấp, ấn bản và đồ đi kèm",199,581,600,nil,C.muted)
    text(V.dialoguePage.." / "..pages,872,578,80,nil,C.muted,"center")
    button(buttons,"barter_dialogue_page","‹",965,575,47,26,V.dialoguePage<=1,nil,{delta=-1})
    button(buttons,"barter_dialogue_page","›",1026,575,47,26,V.dialoguePage>=pages,nil,{delta=1})
    button(buttons,"barter_close_dialogue","Tiếp tục trả giá",199,617,259,32,false,nil)
    if e.counter then action(buttons,"barter_use_counter","DÙNG ĐỀ NGHỊ NÀY",473,613,607,40,false,C.gold)
    else action(buttons,"barter_dialogue_accept","CHỐT GIAO DỊCH",473,613,607,40,e.status~="agreed",C.green) end
    g.pop()
end
function V.press(game,b)
    local e=game.barterEvent;if not e or b.disabled then return end
    if V.modal and not b.id:match("^barter_dialogue") and b.id~="barter_close_dialogue" and b.id~="barter_use_counter" then return end
    if V.input and not (b.id==V.input.id and b.side==V.input.side) then finishInput(game,true) end
    if b.id=="barter_search" or b.id=="barter_gold_input" then
        if b.id=="barter_gold_input" and e.status=="thinking" then return end
        V.input={id=b.id,side=b.side,value=b.id=="barter_search" and V.queries[b.side] or tostring(e.draft[b.side.."Gold"]),selectAll=true}
    elseif b.id=="barter_leave" then V.showDialogue=nil;return "leave"
    elseif b.id=="barter_filter_menu" then V.dropdown=b.side
    elseif b.id=="barter_dismiss_menu" then V.dropdown=nil
    elseif b.id=="barter_filter" then e.filters[b.side]=b.filter;e.pages[b.side]=1;V.dropdown=nil
    elseif b.id=="barter_close_dialogue" then V.showDialogue=nil;V.modal=nil
    elseif b.id=="barter_dialogue_page" then V.dialoguePage=V.dialoguePage+b.delta
    elseif b.id=="barter_use_counter" then T.useCounter(game);V.showDialogue=nil;V.modal=nil
    elseif b.id=="barter_counter" or b.id=="barter_review" then V.showDialogue=true;V.dialoguePage=1
    elseif b.id=="barter_page" then e.pages[b.side]=math.max(1,e.pages[b.side]+b.delta)
    elseif b.id=="barter_item" then
        T.toggle(game,b.side,b.key)
        if b.side=="player" and b.resource then V.resource=b.resource end
    elseif b.id=="barter_gold" then T.setGold(game,b.side,b.zero and 0 or b.maximum and (b.side=="player" and game.gold or e.gold) or math.max(0,e.draft[b.side.."Gold"]+b.delta))
    elseif b.id=="barter_amount" then T.setAmount(game,b.resource,b.maximum and game[b.resource] or math.max(1,(e.amounts[b.resource] or 1)+b.delta))
    elseif b.id=="barter_clear" then T.clear(game)
    elseif b.id=="barter_initiate" then if not e.counter then T.initiate(game) end;V.showDialogue=true;V.dialoguePage=1
    elseif b.id=="barter_propose" then T.propose(game)
    elseif b.id=="barter_accept" or b.id=="barter_dialogue_accept" then
        local ok,msg=T.accept(game);e.message=msg;if ok then V.showDialogue=nil;V.modal=nil end;return ok and "accepted" or "changed"
    end
    return "changed"
end
return V
