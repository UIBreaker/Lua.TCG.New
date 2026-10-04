local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Panel = require("ui.components.panel")
local View = {}

local function section(line)
    local labels = {
        {"KẾ TIẾP: ", "CẤP KẾ TIẾP", "next"},
        {"Cơ bản: ", "CHỈ SỐ CƠ BẢN", "stats"},
        {"Vai trò ", "VAI TRÒ", "role"},
        {"ITM · ", "TRANG BỊ", "equipment"},
        {"ẤN · ", "DẤU ẤN", "modifier"},
        {"RÈN · ", "CƯỜNG HÓA", "modifier"},
        {"ẤN BẢN · ", "ẤN BẢN", "edition"},
    }
    for _, label in ipairs(labels) do
        if line:sub(1, #label[1]) == label[1] then
            local text = line:sub(#label[1] + 1)
            if label[3] == "role" then text = text:match("^[^:]+: (.*)$") or text end
            return label[2], text, label[3]
        end
    end
    if line:find("KHÓA", 1, true) or line:find("VÔ HIỆU", 1, true) or line:find("QUÊN LÃNG", 1, true) then
        return "CẢNH BÁO", line, "warning"
    end
    return "TRẠNG THÁI", line, "state"
end

function View.model(item, title, body)
    while item.card or item.deity or item.equipment or item.item do
        item = item.card or item.deity or item.equipment or item.item
    end
    local model = {title=title, badge="TIÊU HAO", accent=Theme.colors.purple, rows={}}
    if item.rank then model.badge="QUÂN BÀI"; model.accent=Theme.colors.gold
    elseif body:match("^SPN · ") or item.deityId then model.badge="SPN"; model.accent=Theme.colors.cyan
    elseif body:match("^ITM · ") then model.badge="TRANG BỊ · ITM"; model.accent=Theme.colors.green
    elseif item.packType then model.badge="RƯƠNG BÀI"; model.accent=Theme.colors.gold
    elseif item.voucherId or tostring(item.id):match("^v_") then model.badge="ĐẶC QUYỀN"; model.accent=Theme.colors.green end
    for line in (body .. "\n"):gmatch("([^\n]+)\n") do
        if line:match("^SPN · ") then
            model.badge = line
        elseif line:match("^TIẾN HÓA ") then
            model.evolution = line:gsub(" · MAX EVOLUTION", " · TỐI ĐA")
            model.level, model.maxLevel = line:match("^TIẾN HÓA (%d+) / (%d+)")
        elseif #model.rows == 0 then
            model.rows[1] = {label="HIỆU ỨNG", text=line:gsub("^ITM · ", ""), kind="effect"}
        else
            local label, text, kind = section(line)
            model.rows[#model.rows+1] = {label=label, text=text, kind=kind}
        end
    end
    return model
end

local function textHeight(font, text, width, gap)
    local _, lines = font:getWrap(text, width)
    return #lines * (font:getHeight() + (gap or 2))
end

function View.layout(model, fonts)
    local layout = {w=360, font=fonts.description or fonts.small, titleFont=fonts.regular or fonts.small,
        labelFont=fonts.tiny, rows={}, textY=26, bottom=12, gap=8}
    local function measure()
        local width = layout.w - 36
        layout.titleH = textHeight(layout.titleFont, model.title, width, 1)
        layout.headerH = 48 + layout.titleH
        local y = layout.headerH + 10
        for i, row in ipairs(model.rows) do
            local h = layout.textY + textHeight(layout.font, row.text, width-20) + layout.bottom
            layout.rows[i] = {y=y, h=h}
            y = y + h + layout.gap
            if i == 1 and model.evolution then y = y + 42 end
        end
        layout.h = y + 10
    end
    measure()
    if layout.h > 680 then layout.w=430; measure() end
    if layout.h > 680 then layout.textY=22; layout.bottom=8; layout.gap=5; measure() end
    -- Extremely modified cards keep every effect visible inside the viewport.
    layout.scale = math.min(1, 680/layout.h)
    return layout
end

local function rich(text, color)
    local runs, pos = {}, 1
    while true do
        local first, last = text:find("[+%-]?%d+%.?%d*", pos)
        if not first then runs[#runs+1]=Theme.colors.text; runs[#runs+1]=text:sub(pos); break end
        runs[#runs+1]=Theme.colors.text; runs[#runs+1]=text:sub(pos,first-1)
        runs[#runs+1]=color; runs[#runs+1]=text:sub(first,last)
        pos=last+1
    end
    return runs
end

function View.draw(model, layout, x, y)
    local g = love.graphics
    local w, h, accent = layout.w, layout.h, model.accent
    g.push("all"); g.translate(x,y); g.scale(layout.scale)
    -- Opaque backing protects prose from the detailed expedition scenery.
    Core.color(Theme.colors.charcoal); g.rectangle("fill",0,0,w,h,9,9)
    Panel.draw(0,0,w,h,{accent=accent,focused=true})
    g.setColor(0.035,0.053,0.067,0.97); g.rectangle("fill",8,8,w-16,h-16,5,5)
    Core.color(accent,0.9); g.rectangle("fill",18,17,3,13,1,1)
    Core.text(model.badge,28,17,w-46,layout.labelFont,accent)
    Core.text(model.title,18,38,w-36,layout.titleFont,Theme.colors.text)
    Core.color(accent,0.25); g.line(18,layout.headerH-2,w-18,layout.headerH-2)
    for i, row in ipairs(model.rows) do
        local r = layout.rows[i]
        local color = row.kind=="warning" and Theme.colors.red
            or row.kind=="next" and Theme.colors.cyan
            or row.kind=="equipment" and Theme.colors.green or accent
        Core.color(color,row.kind=="effect" and 0.10 or 0.055)
        g.rectangle("fill",18,r.y,w-36,r.h,5,5)
        Core.text(row.label,28,r.y+(layout.textY==22 and 6 or 9),w-56,layout.labelFont,color)
        g.setFont(layout.font); g.setColor(1,1,1,1)
        local lineHeight = layout.font:getLineHeight()
        layout.font:setLineHeight((layout.font:getHeight()+2)/layout.font:getHeight())
        g.printf(rich(row.text,color),28,r.y+layout.textY,w-56,"left")
        layout.font:setLineHeight(lineHeight)
        if i==1 and model.evolution then
            local ey = r.y+r.h+10
            Core.text(model.evolution,20,ey,w-40,layout.labelFont,Theme.colors.muted)
            local maxLevel = tonumber(model.maxLevel) or 5
            local level = tonumber(model.level) or 0
            local segment = (w-40-(maxLevel-1)*4)/maxLevel
            for n=1,maxLevel do
                Core.color(n<=level and accent or Theme.colors.metal,n<=level and 0.95 or 0.5)
                g.rectangle("fill",20+(n-1)*(segment+4),ey+20,segment,4,2,2)
            end
        end
    end
    g.pop()
end

return View
