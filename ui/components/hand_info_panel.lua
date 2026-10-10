local Theme = require("ui.theme")
local Core = require("ui.components.core")
local HandInfoPanel = {}
local utf8 = require("utf8")

local ICON_IMAGE = "assets/ui/hand_info_icons_v2.png"
local ICON_INDEX = {damage = 1, power = 2, aura = 3, health = 4, intent = 5, trait = 6}
local loaded, iconImage, iconQuads, iconCellW, iconCellH = false, nil, {}, 0, 0

local function loadImages()
    if loaded then return end
    loaded = true

    local ok, image = pcall(love.graphics.newImage, ICON_IMAGE)
    if ok and image then
        iconImage = image
        iconImage:setFilter("linear", "linear")
        local w, h = image:getDimensions()
        iconCellW, iconCellH = w / 3, h / 2
        for index = 1, 6 do
            local column = (index - 1) % 3
            local row = math.floor((index - 1) / 3)
            iconQuads[index] = love.graphics.newQuad(
                column * iconCellW, row * iconCellH, iconCellW, iconCellH, w, h)
        end
    end
end

local function drawIcon(name, x, y, size)
    if not iconImage then return end
    local quad = iconQuads[ICON_INDEX[name]]
    if not quad then return end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(iconImage, quad, x, y, 0, size / iconCellW, size / iconCellH)
end

local function boundedLines(text, font, width, maxLines)
    local _, lines = font:getWrap(tostring(text or ""), width)
    if #lines > maxLines then
        local last = lines[maxLines] or ""
        while last ~= "" and font:getWidth(last .. "…") > width do
            local ok, start = pcall(utf8.offset, last, -1)
            if not ok or not start then break end
            last = last:sub(1, start - 1)
        end
        lines[maxLines] = last .. "…"
        for i = #lines, maxLines + 1, -1 do lines[i] = nil end
    end
    return table.concat(lines, "\n")
end

local function fitValue(text, fonts, width)
    for _, key in ipairs({"aura", "value", "body", "label", "detail"}) do
        local font = fonts[key]
        if font and font:getWidth(text) <= width then return font end
    end
    return fonts.detail or love.graphics.getFont()
end

local function drawMetric(x, y, w, h, label, value, variant, icon, fonts, bounce)
    local color = Theme.colors[variant] or Theme.colors.gold
    local text = value~=nil and tostring(value) or "—"
    Core.text(label, x + 3, y + 7, w - 6, fonts.detail, color, "center")

    local iconSize = 15
    local valueFont = fitValue(text, fonts, w - iconSize - 14)
    local textWidth = math.min(valueFont:getWidth(text), w - iconSize - 14)
    local groupWidth = iconSize + 5 + textWidth
    local startX = x + (w - groupWidth) / 2
    local centerX, centerY = startX + groupWidth / 2, y + h - 23
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(bounce or 1, bounce or 1)
    love.graphics.translate(-centerX, -centerY)
    drawIcon(icon, startX, y + h - 33, iconSize)
    Core.text(text, startX + iconSize + 5, y + h - 39, textWidth + 2,
        valueFont, Theme.colors.text, "left")
    love.graphics.pop()
end

function HandInfoPanel.draw(data,fonts,formatNumber)
 data=data or {};loadImages()
 local Chrome=require("ui.combat_chrome")
 local g=love.graphics;g.push("all")
 local x,y,w=12,76,222
 local info=(fonts and fonts.info) or fonts or {};local base=g.getFont()
 local f={detail=info.detail or base,label=info.label or base,body=info.body or base,
  title=info.title or base,value=info.value or base,aura=info.aura or base}
 local fmt=formatNumber or tostring
 local panelH=615
 Chrome.panel(x,y,w,panelH)
 Chrome.title("THẾ TRẬN",x+18,y+17,w-36,(fonts and fonts.bookChapter) or f.title,Theme.colors.gold)
 Core.text(data.scoring and "ĐANG TÍNH AURA" or "CHỌN THẾ ĐÁNH",x+18,y+45,w-36,f.detail,Theme.colors.muted)

 Core.textLine(data.handName or "Chọn bài để xem",x+16,y+76,w-32,f.body,Theme.colors.text,"left",f.label)
 for _,v in ipairs({{x+12,"SÁT THƯƠNG",data.chips,"cyan","damage",data.chipsBounce},
  {x+116,"CƯỜNG HÓA",data.mult,"red","power",data.multBounce}}) do
  Chrome.well(v[1],y+108,94,68,Theme.colors[v[4]])
  drawMetric(v[1],y+108,94,68,v[2],data.scoring and fmt(v[3] or 0) or nil,v[4],v[5],f,v[6])
 end
 if data.scoring then
  local formula=fmt(data.chips or 0).." × "..fmt(data.mult or 0)
   ..((data.xMult or 1)>1 and " × "..string.format("%.2f",data.xMult) or "")
  Core.textLine(formula,x+16,y+181,w-32,f.detail,Theme.colors.muted,"center")
  Chrome.panel(x+12,y+206,w-24,100,Theme.colors.gold)
  Chrome.crest(x+44,y+252,21,Theme.colors.gold)
  Chrome.title("AURA · TÍCH NĂNG",x+68,y+216,w-85,f.detail,Theme.colors.gold,"center")
  local text=fmt(data.aura or 0)
  g.push();g.translate(x+w/2,y+258);g.scale(data.auraBounce or 1);g.translate(-x-w/2,-y-258)
  Chrome.title(text,x+69,y+239,w-89,fitValue(tostring(text),f,w-89),{1,.91,.72},"center");g.pop()
  Core.textLine(data.category or "ĐANG KẾT TOÁN",x+21,y+278,w-42,f.detail,Theme.colors.muted,"center")
  local progress=math.max(0,math.min(1,data.scoreProgress or 0))
  Core.color(Theme.colors.gold,.85);g.rectangle("fill",x+22,y+294,(w-44)*progress,2)
 end
 -- Keep scoring targets fixed; only the preparation layout closes the empty space.
 y=y+(data.scoring and 0 or -108)
 local es=tonumber(data.enemySpeed);local ps=tonumber(data.playerSpeed)
 Chrome.well(x+12,y+309,w-24,54,not ps and Theme.colors.gold or ps>=(es or 1) and Theme.colors.cyan or Theme.colors.red)
 Core.text(ps and ps>=(es or 1) and "BẠN RA ĐÒN TRƯỚC" or ps and "ĐỐI THỦ RA ĐÒN TRƯỚC" or "THỨ TỰ HÀNH ĐỘNG",x+21,y+317,w-42,f.detail,not ps and Theme.colors.gold or ps>=(es or 1) and Theme.colors.cyan or Theme.colors.red,"center")
 local speed=ps and string.format("%.1f",ps):gsub("%.0$","") or "—"
 Core.text("Tốc bạn "..speed.."  /  Địch "..tostring(es or "—"),x+21,y+338,w-42,f.detail,Theme.colors.muted,"center")
 Chrome.rule(x+16,y+378,w-32)
 Chrome.title("MỤC TIÊU",x+16,y+390,w-32,f.detail,Theme.colors.gold)
 Core.textLine(data.enemyName or "Không rõ",x+16,y+411,w-32,f.body,Theme.colors.text,"left",f.label)
 Chrome.well(x+12,y+439,w-24,72,Theme.colors.red)
 Chrome.title("CHIÊU TIẾP THEO",x+21,y+449,w-42,f.detail,Theme.colors.red)
 Core.text(boundedLines(data.intent or "Chưa rõ",f.label,w-42,2),x+21,y+470,w-42,f.label,Theme.colors.text)
 local traitY=y+528
 local trait=data.debuff
 if data.isBoss and data.boss and data.boss.bossData then
  local Boss=require("src.boss_abilities");local bs=Boss.state(data.boss);local a=data.boss.bossData.active
  trait=(Boss.passiveEnabled(data.boss) and "Nội tại đang bật" or "Nội tại vô hiệu")
   ..(a and " · "..a.name.." / "..(bs and bs.activeCountdown or 1).." tay" or "")
   ..(bs and bs.cancelNextActive>0 and " · Đã phong ấn" or "")
 end
 if data.isBoss or data.boss and data.boss.enemyAbility then
  Core.text(data.isBoss and "NỘI TẠI / KỸ NĂNG" or "ĐẶC ĐIỂM",x+16,traitY,w-32,f.detail,Theme.colors.gold)
  Core.text(boundedLines(trait,f.detail,w-32,4),x+16,traitY+20,w-32,f.detail,Theme.colors.muted)
 end
 if data.boss and (data.boss.enemyAbility or data.isBoss) then
  local UI=require("src.ui");local mx,my=UI.virtualMouseX or 0,UI.virtualMouseY or 0
  if mx>=x and mx<=x+w and my>=traitY and my<=76+panelH then
   UI.descriptionCandidate={name=data.boss.name,desc=data.isBoss and require("src.boss_abilities").describe(data.boss) or data.debuff,hoverKey=data.boss}
  end
 end
 g.pop()
end
return HandInfoPanel
