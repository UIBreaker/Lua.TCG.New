local UI=require("src.ui")
local Core=require("ui.components.core")
local Chrome=require("ui.combat_chrome")
local C=require("ui.theme").colors
local M=require("src.memory_match")
local V={}
local gold={.93,.74,.42,1}
local green={.42,.83,.65,1}
local function text(s,x,y,w,font,color,align) Core.text(s,x,y,w,font or UI.fonts.small,color or C.text,align) end
local function inside(mx,my,x,y,w,h) return mx>=x and mx<=x+w and my>=y and my<=y+h end
local function button(buttons,id,label,x,y,w,h,mx,my,disabled,data)
    local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled,color=C.inset,font=UI.fonts.small}
    for k,v in pairs(data or {}) do b[k]=v end
    Chrome.button(UI,b,mx,my);buttons[#buttons+1]=b
end
function V.rect(index)
    return 360+((index-1)%6)*148,122+math.floor((index-1)/6)*168,100,150
end
local function rules(buttons,mx,my)
    local g=love.graphics;g.setColor(0,0,0,.84);g.rectangle("fill",0,0,1280,720)
    Chrome.panel(184,96,912,528,gold)
    text("LUẬT BÀN KÝ ỨC",215,119,700,UI.fonts.large,gold)
    local lines={
        "Phí 50 vàng/ván · 18 thẻ · 9 cặp · "..M.flips.." lần lật. Bỏ qua không mất vàng.",
        "Mỗi cặp đúng giữ lại 1 lá thưởng. Đúng liên tiếp: chuỗi 2 ×2, 3 ×3, 4+ ×4.",
        "Hệ số chuỗi CUỐI nhân mọi cặp đã tìm. Chuỗi tốt nhất trước đó không được giữ.",
        "Hai thẻ khác nhau: mất chuỗi, vẫn giữ 1 lá mỗi cặp. Có thể gây dựng chuỗi mới.",
        "Dừng sớm sau một cặp để chốt chuỗi, hoặc tiếp tục và chấp nhận rủi ro.",
        "Kết thúc: tối đa 36 lá, cất vào balo. Ba cặp SPN được chọn trước, không đổi khi tải lại.",
    }
    for i,line in ipairs(lines) do text(line,216,176+(i-1)*43,848,UI.fonts.small,i==3 and gold or C.text) end
    text("TỶ LỆ BẬC CHO MỖI SPN TRÊN BÀN",216,451,848,UI.fonts.small,green)
    local D=require("src.deities")
    for i,rarity in ipairs(D.RARITIES) do
        text(rarity.code.." · "..M.rarityWeights[i].."%",216+((i-1)%5)*168,484+math.floor((i-1)/5)*30,158,UI.fonts.small,rarity.color)
    end
    button(buttons,"memory_rules_close","ĐÃ HIỂU",748,560,306,42,mx,my,false)
end
function V.draw(game,buttons,mx,my)
    local e=game.memoryMatch;if not e then return end
    if V.event~=e then V.event=e;V.rules=false end
    local g=love.graphics
    g.setColor(.012,.018,.022,.48);g.rectangle("fill",0,0,1280,720)
    Chrome.panel(20,16,1240,72,gold)
    text("BÀN KÝ ỨC",42,29,450,UI.fonts.large,gold)
    text("TÌM CẶP · GIỮ CHUỖI · CHỌN LÚC DỪNG",43,63,510,UI.fonts.tiny,C.muted)
    for i,stat in ipairs({{"LƯỢT LẬT",e.remaining.." / "..M.flips},{"CẶP ĐÃ TÌM",e.matched.." / "..#e.pairs},{"CHUỖI "..e.streak,"THƯỞNG ×"..(e.rewardMultiplier or M.multiplier(e))}}) do
        local x=540+(i-1)*178;Chrome.well(x,28,166,47,i==3 and gold or C.goldDim)
        text(stat[1],x+7,31,152,UI.fonts.tiny,C.muted,"center")
        text(stat[2],x+7,48,152,UI.fonts.medium,i==3 and gold or C.text,"center")
    end
    Chrome.panel(20,106,280,530,gold)
    if not V.host and love.filesystem.getInfo("assets/scene/events/memory_match_host.png") then V.host=love.graphics.newImage("assets/scene/events/memory_match_host.png");V.host:setFilter("linear","linear") end
    if V.host then g.setColor(1,1,1,1);g.draw(V.host,33,110,0,254/V.host:getWidth(),381/V.host:getHeight()) end
    Chrome.well(37,450,246,169,gold)
    text("ÔNG CHỦ BÀN KÝ ỨC",49,464,222,UI.fonts.small,gold,"center")
    text(e.phase=="results" and "“Nhớ giỏi cũng cần biết dừng. Phần này là của cậu.”" or "“50 vàng một ván. Mang theo trí nhớ… và một chút can đảm.”",49,498,222,UI.fonts.small,C.text,"center")
    text("6 thẻ hỗ trợ · 3 SPN\nĐúng liên tiếp: ×2 / ×3 / ×4",47,563,226,UI.fonts.tiny,green,"center")
    Chrome.panel(316,106,944,530,gold)
    Core.gradient(329,116,918,507,{.025,.095,.085,.98},{.012,.039,.038,.98},8)
    -- A restrained felt grain gives the board a physical table surface.
    for i=1,23 do g.setColor(.28,.44,.35,.035);g.line(337,125+i*21,1239,125+i*21) end
    V.hover=nil
    local results=e.phase=="results" or e.phase=="claimed"
    if results then
        text("CHỐT BÀN · "..(e.rewardCount or 0).." LÁ THƯỞNG",346,122,872,UI.fonts.large,gold,"center")
        text(e.matched.." cặp × "..(e.rewardMultiplier or 1).." · Nhận bản sao lá bài, không nhân chỉ số",346,163,872,UI.fonts.small,C.muted,"center")
        local n=0
        for _,reward in ipairs(e.pairs) do if reward.matched then
            n=n+1;local x=346+((n-1)%3)*294;local y=207+math.floor((n-1)/3)*136
            Chrome.well(x,y,278,124,reward.kind=="spn" and {.64,.48,.84,1} or gold)
            UI.Polish.renderItem(UI,reward.item,x+9,y+8,67,101)
            Core.textLine(reward.item.name,x+87,y+13,179,UI.fonts.small,C.text,"left",UI.fonts.tiny)
            text("×"..e.rewardMultiplier.." LÁ",x+87,y+70,176,UI.fonts.medium,gold)
            text(reward.kind=="spn" and require("src.deities").getRarityBadge(reward.item).." · SPN" or "THẺ HỖ TRỢ",x+87,y+97,176,UI.fonts.tiny,green)
            if inside(mx,my,x,y,278,124) then V.hover=reward.item end
        end end
        if n==0 then text("CHƯA TÌM ĐƯỢC CẶP NÀO\nLần sau hãy ghi nhớ từng vị trí đã lật.",396,325,780,UI.fonts.medium,C.muted,"center") end
    else
        for index,card in ipairs(e.cards) do
            local x,y,w,h=V.rect(index);local turn=card.turn or 0
            if UI.CardPhysics and UI.CardPhysics.reducedMotion then turn=(card.shown or card.matched) and 1 or 0 end
            local hover=not e.resolving and not card.shown and not card.matched and inside(mx,my,x,y,w,h)
            local reward=e.pairs[card.pair];local sx=math.max(.035,math.abs(math.cos(turn*math.pi)))
            g.push("all");g.translate(x+w/2,y+h/2);g.scale(sx,1)
            if card.matched then g.setColor(.27,.82,.57,.15);g.rectangle("fill",-w/2-4,-h/2-4,w+8,h+8,5) end
            if turn>.5 then
                UI.Polish.renderItem(UI,reward.item,-w/2,-h/2,w,h)
            else
                g.setColor(1,1,1,1);UI.drawCardBack(-w/2,-h/2,w,h)
                text(tostring(index),-w/2+6,-h/2+6,24,UI.fonts.tiny,gold)
            end
            if hover then g.setColor(.95,.79,.46,.65);g.setLineWidth(2);g.rectangle("line",-w/2-2,-h/2-2,w+4,h+4,3) end
            g.pop()
            if card.shown or card.matched then
                Core.textLine(card.matched and "ĐÃ GIỮ · "..reward.item.name or reward.item.name,x-14,y+h+3,w+28,UI.fonts.tiny,card.matched and green or C.text,"center")
                if inside(mx,my,x,y,w,h) then V.hover=reward.item end
            else text("VỊ TRÍ "..index,x-12,y+h+3,w+24,UI.fonts.tiny,C.muted,"center") end
            buttons[#buttons+1]={id="memory_flip",index=index,x=x,y=y,w=w,h=h,disabled=e.phase~="playing" or e.resolving~=nil or card.shown or card.matched}
        end
        if e.resolving and e.resolving.matched then
            local alpha=math.min(1,e.resolving.timer*2)
            text("CHUỖI "..e.streak.." · ×"..M.multiplier(e),492,333,588,UI.fonts.large,{1,.82,.4,alpha},"center")
        end
        if e.phase=="ready" then
            g.setColor(.008,.016,.019,.9);g.rectangle("fill",329,116,918,507,8)
            text("MỘT VÁN, MỘT CƠ HỘI",383,213,810,UI.fonts.large,gold,"center")
            text("18 THẺ · 9 CẶP · "..M.flips.." LẦN LẬT",383,269,810,UI.fonts.medium,green,"center")
            text("Tìm cặp để giữ lá thưởng. Hai cặp liên tiếp bắt đầu nhân thưởng.\nLật sai mất chuỗi; dừng sớm để bảo toàn hệ số đang có.\nChuỗi 4+ đạt trần ×4 · Tối đa 36 lá thưởng.",405,319,764,UI.fonts.small,C.text,"center")
            text("PHÍ THAM GIA 50 VÀNG · BẠN CÓ "..math.floor(game.gold or 0).." VÀNG",405,402,764,UI.fonts.small,(game.gold or 0)>=M.entryFee and gold or {.95,.43,.43,1},"center")
            button(buttons,"memory_start",(game.gold or 0)>=M.entryFee and "THAM GIA · 50 VÀNG" or "KHÔNG ĐỦ 50 VÀNG",554,444,470,60,mx,my,(game.gold or 0)<M.entryFee)
        end
    end
    Chrome.panel(20,650,1240,54,gold)
    Core.textLine(results and "Phần thưởng được cất vào balo, chưa tự trang bị." or e.message,39,667,661,UI.fonts.small,C.text,"left",UI.fonts.tiny)
    button(buttons,"memory_rules","LUẬT & TỶ LỆ",718,660,202,34,mx,my,false)
    button(buttons,results and "memory_claim" or "memory_finish",results and "NHẬN THƯỞNG · RỜI BÀN" or e.phase=="ready" and "BỎ QUA" or "CHỐT THƯỞNG ×"..M.multiplier(e),935,660,307,34,mx,my,e.resolving~=nil or #e.open>0)
    if V.hover then UI.descriptionCandidate=V.hover end
    if V.rules then for i=#buttons,1,-1 do buttons[i]=nil end;rules(buttons,mx,my) end
end
function V.press(game,b)
    if V.rules then if b.id=="memory_rules_close" then V.rules=false;return true end;return false end
    if b.id=="memory_rules" then V.rules=true;return true end
    if b.id=="memory_start" then return M.start(game) end
    if b.id=="memory_flip" then return M.flip(game,b.index) end
    if b.id=="memory_finish" then
        if game.memoryMatch.phase=="ready" then
            if M.skip(game) and M.claim(game) then return "claimed" end
            return false
        end
        return M.finish(game)
    end
    if b.id=="memory_claim" then
        if game.memoryMatch.phase=="claimed" then return "claimed" end
        if M.claim(game) then return "claimed" end
    end
end
return V
