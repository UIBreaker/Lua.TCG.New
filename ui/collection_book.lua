local Book = { state = "CLOSED", time = 0, duration = 0, stackRatio = 0.5 }
Book.config = {
    turnDuration = 0.56,
    extraPageDuration = 0.07,
    maxTurnPages = 3,
    meshColumns = 28,
    meshRows = 6,
    pageStackDepth = 18,
    foldSkew = 0.035,
    curlHeight = 0.075,
    paperFlex = 1.8,
    shadowStrength = 0.17,
    cornerHoverRadius = 96,
}
local pageSnapshot, pageMesh, pageVertices
local preparePageMesh
local pageSnapshotDirty = true
local pageSnapshotScale = 0.5

local function clamp(t)
    return math.max(0, math.min(1, t))
end

local function ease(t)
    t = clamp(t)
    return t * t * (3 - 2 * t)
end

-- Pickup, fast crossing, soft landing, then a barely visible damped settle.
local function turnProgress(t)
    t = clamp(t)
    if t < 0.12 then return 0.025 * ease(t / 0.12) end
    if t < 0.32 then return 0.025 + 0.115 * ease((t - 0.12) / 0.20) end
    if t < 0.62 then return 0.14 + 0.68 * ease((t - 0.32) / 0.30) end
    if t < 0.84 then return 0.82 + 0.175 * (1 - (1 - (t - 0.62) / 0.22) ^ 3) end
    return 0.995 + 0.005 * (1 - math.exp(-(t - 0.84) * 18) * math.cos((t - 0.84) * 24))
end

local function visualProgress()
    if Book.state == "OPENING" then return ease(math.min(1, Book.time / Book.duration)) end
    if Book.state == "CLOSING" then return ease(1 - math.min(1, Book.time / Book.duration)) end
    return 1
end

function Book.open()
    Book.state, Book.time, Book.duration = "OPENING", 0, 0.88
    pageSnapshotDirty = true
end

function Book.close()
    if Book.state == "CLOSED" or Book.state == "CLOSING" then return end
    Book.state, Book.time, Book.duration = "CLOSING", 0, 0.62
end

function Book.invalidatePageSnapshot()
    if Book.state == "IDLE" then pageSnapshotDirty = true end
end

local function capturePage(sourceCanvas)
    if not sourceCanvas then return end
    if not pageSnapshot then Book.prepare(sourceCanvas) end
    if not pageSnapshot then return end
    local g = love.graphics
    local savedCanvas = g.getCanvas()
    g.push("all")
    g.setCanvas(pageSnapshot)
    g.origin()
    g.clear(0, 0, 0, 0)
    g.setColor(1, 1, 1, 1)
    g.draw(sourceCanvas, 0, 0, 0, pageSnapshotScale, pageSnapshotScale)
    g.setCanvas(savedCanvas)
    g.pop()
end

function Book.prepare(sourceCanvas)
    local ok = pcall(preparePageMesh)
    if not ok then pageMesh = nil end
    if sourceCanvas and not pageSnapshot then
        local canvasOk, canvas = pcall(love.graphics.newCanvas,
            math.max(1, math.floor(sourceCanvas:getWidth() * pageSnapshotScale)),
            math.max(1, math.floor(sourceCanvas:getHeight() * pageSnapshotScale)))
        if canvasOk then
            pageSnapshot = canvas
            pageSnapshot:setFilter("linear", "linear")
        end
    end
    return pageMesh ~= nil
end

function Book.setPagePosition(index, total)
    local target = total and total > 1 and clamp((index - 1) / (total - 1)) or 0.5
    if Book.state == "TURN_FORWARD" or Book.state == "TURN_BACKWARD" then
        if Book.stackTarget ~= target then
            Book.stackStart = Book.stackRatio or target
            Book.stackTarget = target
        end
        local p = turnProgress(Book.time / math.max(Book.duration, 0.001))
        Book.stackRatio = Book.stackStart + (Book.stackTarget - Book.stackStart) * p
    else
        Book.stackStart, Book.stackTarget, Book.stackRatio = target, target, target
    end
end

function Book.captureIdlePage(sourceCanvas)
    if Book.state ~= "IDLE" or not sourceCanvas or (not pageSnapshotDirty and pageSnapshot) then return false end
    capturePage(sourceCanvas)
    pageSnapshotDirty = pageSnapshot == nil
    return pageSnapshot ~= nil
end

preparePageMesh = function()
    if pageMesh then return end
    local cols, rows = Book.config.meshColumns, Book.config.meshRows
    pageVertices = {}
    local indices = {}
    for y = 0, rows do
        for x = 0, cols do
            pageVertices[#pageVertices + 1] = { 0, 0, x / cols, y / rows, 1, 1, 1, 1 }
        end
    end
    for y = 0, rows - 1 do
        for x = 0, cols - 1 do
            local a = y * (cols + 1) + x + 1
            local b, c, d = a + 1, a + cols + 1, a + cols + 2
            indices[#indices + 1] = a; indices[#indices + 1] = b; indices[#indices + 1] = c
            indices[#indices + 1] = b; indices[#indices + 1] = d; indices[#indices + 1] = c
        end
    end
    pageMesh = love.graphics.newMesh({
        { "VertexPosition", "float", 2 },
        { "VertexTexCoord", "float", 2 },
        { "VertexColor", "float", 4 },
    }, pageVertices, "triangles", "dynamic")
    pageMesh:setVertexMap(indices)
end

function Book.turn(direction, distance, onReveal, sourceCanvas, renderScale)
    if Book.state ~= "IDLE" then return false end
    -- Normally the stable idle frame was cached after it was presented. Keep
    -- the input path free of a synchronous full-screen canvas copy.
    if not pageSnapshot then capturePage(sourceCanvas) end
    Book.state = direction == "back" and "TURN_BACKWARD" or "TURN_FORWARD"
    Book.time, Book.duration = 0, Book.config.turnDuration + math.min(Book.config.maxTurnPages, math.max(0, (distance or 1) - 1)) * Book.config.extraPageDuration
    Book.turnCount = math.min(Book.config.maxTurnPages, math.max(1, distance or 1))
    Book.renderScale = renderScale or 1
    Book.onReveal, Book.revealed = onReveal, false
    return true
end

function Book.skip()
    if Book.state == "OPENING" or Book.state == "CLOSING" then
        Book.state, Book.time = Book.state == "OPENING" and "IDLE" or "CLOSED", 0
        return true
    end
    return false
end

function Book.isBusy()
    return Book.state ~= "IDLE" and Book.state ~= "CLOSED"
end

function Book.update(dt)
    if Book.state == "CLOSED" or Book.state == "IDLE" then return Book.state == "CLOSED" end
    Book.time = Book.time + dt
    if (Book.state == "TURN_FORWARD" or Book.state == "TURN_BACKWARD") and not Book.revealed then
        -- Reveal the destination immediately underneath the captured leaf. The
        -- snapshot remains on top and uncovers it progressively as it curls.
        Book.revealed = true
        if Book.onReveal then Book.onReveal(); Book.onReveal = nil end
    end
    if Book.time >= Book.duration then
        local wasClosing = Book.state == "CLOSING"
        Book.state, Book.time, Book.duration = wasClosing and "CLOSED" or "IDLE", 0, 0
        pageSnapshotDirty = true
        Book.onReveal, Book.revealed = nil, false
        return wasClosing
    end
    return false
end

function Book.drawBackdrop(w, h, timer)
    local g = love.graphics
    local alpha = visualProgress()
    g.setColor(0.012, 0.020, 0.030, 0.93 * alpha)
    g.rectangle("fill", 0, 0, w, h)
    for i = 1, 9 do
        local inset = (i - 1) * 13
        g.setColor(0.006, 0.012, 0.020, 0.035 * alpha)
        g.rectangle("line", inset, inset * 0.55, w - inset * 2, h - inset * 1.1)
    end
    for i = 10, 1, -1 do
        g.setColor(0.62, 0.43, 0.20, 0.004 * alpha)
        g.ellipse("fill", w * 0.5, h * 0.52, 190 + i * 26, 110 + i * 18)
    end
    for i = 1, 9 do
        local phase = timer * 0.22 + i * 2.41
        local x = w * (0.18 + ((i * 0.173 + math.sin(phase) * 0.028) % 0.64))
        local y = h * (0.16 + ((i * 0.217 + timer * (0.008 + i * 0.0004)) % 0.70))
        local particleAlpha = (0.08 + (math.sin(phase * 1.7) + 1) * 0.035) * alpha
        g.setColor(1, 0.84, 0.55, particleAlpha)
        g.circle("fill", x, y, i % 3 == 0 and 1.5 or 1)
    end
end

function Book.pushBookTransform(w, h)
    local g = love.graphics
    local progress = visualProgress()
    local pulse = 0
    if Book.state == "OPENING" then
        local t = Book.time / Book.duration
        pulse = 0.005 * math.exp(-((t - 0.91) / 0.055) ^ 2)
    end
    g.push()
    g.translate(w / 2, h / 2 + 8 * (1 - progress))
    g.scale(0.92 + 0.08 * progress, 0.92 + 0.08 * progress - pulse)
    g.translate(-w / 2, -h / 2)
end

function Book.popBookTransform()
    love.graphics.pop()
end

-- Paper gradients are cached meshes, not full-screen textures or per-frame
-- image work. A gentle bow and dark inner edge make the leaves read as paper.
local paperMeshes, paperSize
local function preparePaper(w, h)
    local key = w .. ":" .. h
    if paperSize == key then return end
    paperSize, paperMeshes = key, {}
    for side = 1, 2 do
        local vertices = {}
        for i = 0, 20 do
            local t = i / 20
            local outside, inside = side == 1 and 78 or w - 78, w / 2 + (side == 1 and -5 or 5)
            local topX = outside + (inside - outside) * t
            local bottomOutside = side == 1 and 66 or w - 66
            local bottomX = bottomOutside + (inside - bottomOutside) * t
            local bow = math.sin(t * math.pi)
            local edge = math.exp(-t * 30) * 0.045 + t ^ 12 * 0.16
            local red, green, blue = 0.94 - edge, 0.874 - edge * 1.04, 0.729 - edge * 1.02
            vertices[#vertices+1] = {topX, 92 + 5*t - 3*bow, 0, 0, red+0.01, green+0.012, blue+0.012, 1}
            vertices[#vertices+1] = {bottomX, h-94 - 4*t + 2*bow, 0, 1, red-0.012, green-0.018, blue-0.022, 1}
        end
        paperMeshes[side] = love.graphics.newMesh(vertices, "strip", "static")
    end
end

function Book.drawShell(w, h)
    local g = love.graphics
    local x, y, bw, bh = 58, 82, w - 116, h - 160
    local cx = w/2
    for i = 8, 1, -1 do
        g.setColor(0.006, 0.008, 0.01, 0.035)
        g.ellipse("fill", cx, y+bh+18+i*2, bw*(0.46+i*0.008), 12+i*2)
    end
    -- Dark expedition leather, raised cover lips and brass corner guards.
    g.setColor(0.045, 0.065, 0.074, 1)
    g.rectangle("fill", x-3, y+4, bw+6, bh+17, 8, 8)
    g.setColor(0.15, 0.105, 0.068, 1)
    g.rectangle("fill", x, y, bw, bh+11, 7, 7)
    g.setColor(0.065, 0.105, 0.12, 1)
    g.rectangle("fill", x+3, y+3, bw-6, bh+3, 5, 5)
    g.setColor(0.48, 0.36, 0.19, 0.86)
    g.setLineWidth(1)
    g.rectangle("line", x+6, y+7, bw-12, bh-2, 3, 3)
    for _, corner in ipairs({{x+6,y+7,1,1},{x+bw-6,y+7,-1,1},
        {x+6,y+bh+4,1,-1},{x+bw-6,y+bh+4,-1,-1}}) do
        g.push(); g.translate(corner[1],corner[2]); g.scale(corner[3],corner[4])
        g.setColor(0.59,0.44,0.24,1)
        g.polygon("fill",0,0,28,0,20,5,8,8,5,20,0,28)
        g.setColor(0.85,0.69,0.41,0.78)
        g.line(2,22,3,3,22,2); g.circle("fill",6,6,1.3)
        g.pop()
    end
    -- An ivory page block has individual cut edges and a curved lower lip.
    local ratio = clamp(Book.stackRatio or 0.5)
    for i = 10, 1, -1 do
        local depth = i/10
        local l = 3 + depth*(6+Book.config.pageStackDepth*ratio)
        local r = 3 + depth*(6+Book.config.pageStackDepth*(1-ratio))
        local tone = i%2 == 0 and 0.78 or 0.82
        g.setColor(tone, tone*0.92, tone*0.76, 1)
        g.polygon("fill",72,97,cx-6,99,cx-6,h-98+l,68,h-94+l)
        g.polygon("fill",cx+6,99,w-72,97,w-68,h-94+r,cx+6,h-98+r)
    end
    preparePaper(w,h)
    g.setColor(1,1,1,1)
    g.draw(paperMeshes[1]); g.draw(paperMeshes[2])
    -- Sewn binding sits below the pages; thin highlights define the gutter.
    g.setColor(0.12,0.09,0.055,1)
    g.rectangle("fill",cx-5,96,10,h-194,3,3)
    for i = 1, 6 do
        g.setColor(0.95,0.83,0.59,0.075)
        g.line(cx-6-i,104,cx-6-i,h-108)
        g.setColor(0.19,0.12,0.06,0.035)
        g.line(cx+6+i,104,cx+6+i,h-108)
    end
    for i = 1, 7 do
        local sy = 116+i*(h-234)/8
        g.setColor(0.43,0.32,0.17,0.58)
        g.line(cx-2,sy,cx+2,sy+2)
    end
    -- Fine printer's rules and engraved corner accents leave generous margins.
    for side = 1, 2 do
        local outer, inner = side == 1 and 86 or w-86, cx+(side == 1 and -29 or 29)
        g.setColor(0.61,0.44,0.23,0.35)
        g.line(outer,112,inner,116)
        g.line(outer,h-108,inner,h-112)
        g.setColor(0.59,0.43,0.22,0.46)
        local dir = side == 1 and 1 or -1
        g.line(outer,130,outer,112,outer+dir*22,112)
        g.line(outer,h-126,outer,h-108,outer+dir*22,h-108)
    end
    -- Sparse, fixed paper grain: no random noise, shaders or texture allocation.
    for i = 1, 38 do
        local px = 94 + (i*127) % (w-188)
        local py = 123 + (i*67) % (h-249)
        if math.abs(px-cx)>32 then
            g.setColor(0.41,0.29,0.15,i%3 == 0 and 0.045 or 0.02)
            g.line(px,py,px+1.5,py+0.2)
        end
    end
    g.setLineWidth(1)
end

function Book.drawCover(w, h)
    if Book.state ~= "OPENING" and Book.state ~= "CLOSING" then return end
    local t = math.min(1, Book.time / Book.duration)
    local opening = Book.state == "OPENING"
    local p = ease(opening and t or (1 - t))
    local x, y, bw, bh = 58, 82, w - 116, h - 160
    local left, right = x + 10, x + bw - 10
    local edge = left + (right - left) * p
    local curl = math.sin(p * math.pi) * 8
    local g = love.graphics
    if edge < right - 1 then
        g.setColor(0.01, 0.01, 0.01, 0.28 * (1 - p))
        g.polygon("fill", edge + 8, y + 12, right + 8, y + 22, right + 8, y + bh - 20, edge + 8, y + bh - 13)
        g.setColor(0.055, 0.13, 0.17, 1)
        g.polygon("fill", edge, y + 10 + curl, right, y + 10, right, y + bh - 10, edge, y + bh - 10 - curl)
        g.setColor(0.78, 0.61, 0.32, 0.95 * (1 - p))
        g.setLineWidth(2)
        g.line(edge + 12, y + 24 + curl, right - 12, y + 24, right - 12, y + bh - 25, edge + 12, y + bh - 25 - curl)
        g.setColor(0.96, 0.83, 0.54, 0.9 * (1 - p))
        local sealX, sealY = (edge+right)/2, y+bh*0.33
        g.circle("line", sealX, sealY, 35)
        g.circle("line", sealX, sealY, 30)
        local compass = {}
        for i = 0, 15 do
            local angle, radius = i*math.pi/8, i%2 == 0 and 24 or 8
            compass[#compass+1] = sealX+math.sin(angle)*radius
            compass[#compass+1] = sealY-math.cos(angle)*radius
        end
        g.polygon("line",compass)
        if p < 0.42 then
            local UI = require("src.ui")
            g.setFont(UI.fonts.bookTitle or UI.fonts.title)
            g.printf("BÁCH KHOA", edge + 22, y + bh * 0.48, right - edge - 44, "center")
            g.setFont(UI.fonts.small)
            g.printf("TERRA SUIT • LỤC ĐỊA & DI VẬT", edge + 22, y + bh * 0.57, right - edge - 44, "center")
        end
        g.setLineWidth(1)
    end
end

function Book.drawPageTurn(w, h)
    if Book.state ~= "TURN_FORWARD" and Book.state ~= "TURN_BACKWARD" then return end
    local raw = math.min(1, Book.time / Book.duration)
    local forward = Book.state == "TURN_FORWARD"
    local x, y, bw, bh = 58, 82, w - 116, h - 160
    local spine = x + bw / 2
    local left, right = spine - bw / 2 + 14, spine + bw / 2 - 14
    local pageW = right - spine
    local curl = math.sin(raw * math.pi) * 26
    local strength = math.sin(raw * math.pi) ^ 0.8
    local sheets = Book.turnCount or 1
    local g = love.graphics
    if pageSnapshot and pageMesh then
        local left, top, width, height = 70, 92, w - 140, h - 186
        local scale = Book.renderScale or 1
        local texW, texH = pageSnapshot:getDimensions()
        local u0, v0 = left * scale * pageSnapshotScale / texW, top * scale * pageSnapshotScale / texH
        local uWidth, vHeight = width * scale * pageSnapshotScale / texW, height * scale * pageSnapshotScale / texH
        local cols, rows = Book.config.meshColumns, Book.config.meshRows
        -- A few offset leaves trail the main leaf, so the turn reads as a small
        -- stack of paper instead of one stiff board. Their faint print keeps
        -- the old page legible during the transition.
        for sheet = sheets, 1, -1 do
            local delay = (sheet - 1) * 0.055
            local sheetRaw = math.max(0, math.min(1, (raw - delay) / (1 - delay)))
            local sheetProgress = turnProgress(sheetRaw)
            local foldBase = forward and (1 - sheetProgress) or sheetProgress
            local lift = math.sin(sheetRaw * math.pi)
            local curl = lift * height * Book.config.curlHeight
            local foldX = left + foldBase * width
            local offsetX = (forward and 1 or -1) * (sheet - 1) * 2
            for y = 0, rows do
                for x = 0, cols do
                    local u, v = x / cols, y / rows
                    -- A diagonal fold lets one outer corner lead the turn.
                    local skew = Book.config.foldSkew * lift * (v - 0.5)
                    local fold = clamp(foldBase + (forward and -skew or skew))
                    local turned = forward and u >= fold or (not forward and u <= fold)
                    local mappedU = turned and (2 * fold - u) or u
                    local distance = math.abs(u - fold)
                    local influence = math.exp(-distance * 15) * lift
                    local wave = math.sin(v * math.pi + sheetRaw * 8) * influence * Book.config.paperFlex
                    local z = influence * (16 + height * 0.018)
                    local compressed = turned and (1 - influence * 0.09) or 1
                    local wx = left + mappedU * width + offsetX + (forward and z or -z) * 0.24
                    local wy = top + v * height + math.sin(math.pi * v) * curl * math.exp(-distance * 10) + wave
                    wx = left + fold * width + (wx - (left + fold * width)) * compressed
                    local underside = turned and 0.87 or 1
                    local shade = underside - 0.08 * influence * math.sin(math.pi * v)
                    local uvU = u0 + u * uWidth
                    local uvV = v0 + v * vHeight
                    local index = y * (cols + 1) + x + 1
                    pageMesh:setVertex(index, wx, wy, uvU, uvV, shade, shade, shade, 1)
                end
            end
            pageMesh:setTexture(pageSnapshot)
            local opacity = sheet == 1 and 1 or 0.12
            g.setColor(1, 1, 1, opacity)
            g.draw(pageMesh)
            if sheet == 1 then
                local shadowWidth = 5 + lift * 16
                local shadowAlpha = 0.10 + lift * Book.config.shadowStrength
                for band = 0, 6 do
                    local v = band / 6
                    local skew = Book.config.foldSkew * lift * (v - 0.5)
                    local bandFold = clamp(foldBase + (forward and -skew or skew))
                    local bandX = left + bandFold * width
                    g.setColor(0.12, 0.08, 0.035, shadowAlpha)
                    g.ellipse("fill", bandX + (forward and 1 or -1) * (10 + lift * 8), top + v * height,
                        shadowWidth, 16 + lift * 5)
                end
                local topSkew, bottomSkew = -0.0175 * lift, 0.0175 * lift
                local topFold = left + clamp(foldBase + (forward and -topSkew or topSkew)) * width
                local bottomFold = left + clamp(foldBase + (forward and -bottomSkew or bottomSkew)) * width
                g.setColor(0.25, 0.16, 0.08, 0.72 * strength)
                g.line(topFold - 1.5, top + 12, bottomFold - 1.5, top + height - 12)
                g.setColor(1, 0.94, 0.76, 0.82 * strength)
                g.setLineWidth(1.5)
                g.line(topFold, top + 12, bottomFold, top + height - 12)
            end
        end
        g.setLineWidth(1)
        return
    end
    for sheet = sheets, 1, -1 do
        local delay = (sheet - 1) * 0.055
        local p = math.max(0, math.min(1, (raw - delay) / (1 - delay)))
        local moved = turnProgress(p)
        local edge = forward and (right - pageW * moved) or (left + pageW * moved)
        if (forward and edge > spine + 1) or (not forward and edge < spine - 1) then
            local sheetAlpha = sheet == 1 and 1 or 0.55
            g.setColor(0.04, 0.025, 0.012, 0.18 * strength * sheetAlpha)
            if forward then
                g.rectangle("fill", edge - 5, y + 20, 12, bh - 40)
            else
                g.rectangle("fill", edge - 7, y + 20, 12, bh - 40)
            end
            -- Stacked horizontal strips fake a flexible curl while keeping the fold attached to the spine.
            for band = 0, 27 do
                local y0 = y + 15 + (bh - 30) * band / 28
                local y1 = y + 15 + (bh - 30) * (band + 1) / 28
                local bend = math.sin(math.pi * band / 28) * curl
                local shade = 0.91 - 0.12 * strength * math.sin(math.pi * band / 28)
                g.setColor(shade, shade * 0.91, shade * 0.74, sheetAlpha)
                if forward then
                    g.polygon("fill", spine, y0, edge + bend, y0, edge - bend, y1, spine, y1)
                else
                    g.polygon("fill", edge + bend, y0, spine, y0, spine, y1, edge - bend, y1)
                end
            end
            g.setColor(1, 0.91, 0.68, 0.75 * strength * sheetAlpha)
            g.setLineWidth(2)
            g.line(edge, y + 15 + curl, edge, y + bh - 15 - curl)
        end
    end
    g.setLineWidth(1)
end

function Book.stateName()
    return Book.state
end

function Book.drawBookmark(w, h, label, hovered)
    local g = love.graphics
    local x, y, bw = (w - 184) / 2, h - 65, 184
    local pull = hovered and 5 or 0
    g.setColor(0.055, 0.13, 0.17, 1)
    g.polygon("fill", x, y, x + bw, y, x + bw, y + 38 + pull, x + bw / 2, y + 29 + pull, x, y + 38 + pull)
    g.setColor(0.78, 0.61, 0.32, 0.95)
    g.setLineWidth(1.5)
    g.polygon("line", x + 4, y + 2, x + bw - 4, y + 2, x + bw - 4, y + 34 + pull, x + bw / 2, y + 26 + pull, x + 4, y + 34 + pull)
    g.setFont(require("src.ui").fonts.small)
    g.setColor(0.95, 0.86, 0.66, 1)
    g.printf(label or "QUAY LẠI", x, y + 7 + pull / 2, bw, "center")
    g.setLineWidth(1)
    return { x = x, y = y, w = bw, h = 42 + pull }
end

function Book.drawCornerHover(w, h, mx, my)
    local g = love.graphics
    local corners = {
        { x = 72, y = h - 94, dir = -1 },
        { x = w - 72, y = h - 94, dir = 1 },
    }
    for _, corner in ipairs(corners) do
        local dx, dy = mx - corner.x, my - corner.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local amount = clamp(1 - distance / Book.config.cornerHoverRadius)
        if amount > 0 then
            local size = 9 + amount * 17
            local x, y, d = corner.x, corner.y, corner.dir
            -- Folded paper triangle, thin underside, and a warm catching edge.
            g.setColor(0.24, 0.16, 0.08, 0.13 * amount)
            g.polygon("fill", x - d * 2, y + 2, x - d * size - 2, y + 1, x - d * 1, y - size - 1)
            g.setColor(0.83, 0.74, 0.56, 0.78 * amount)
            g.polygon("fill", x, y, x - d * size, y, x, y - size)
            g.setColor(1, 0.91, 0.70, 0.72 * amount)
            g.setLineWidth(1.2)
            g.line(x - d * (size * 0.72), y, x, y - size * 0.72)
            g.setLineWidth(1)
        end
    end
end

return Book
