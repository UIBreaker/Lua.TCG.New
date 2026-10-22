local Rng = require("src.rng")
local T = {}

local function band(s, center, width, grade)
    s.zones[#s.zones+1]={from=center-width/2,to=center+width/2,grade=grade}
end

function T.start(kind, playerSpeed, enemySpeed)
    local ratio=math.max(1,enemySpeed or 1)/math.max(1,playerSpeed or 1)
    local speed=math.max(0.55,math.min(2.4,math.sqrt(ratio)))
    local reverse=Rng.random(2)==2
    local s={kind=kind,speed=speed,duration=1.6/speed,age=0,position=reverse and 1 or 0,
        reverse=reverse,ready=0.45,zones={}}
    local slots={.12,.31,.50,.69,.88}
    for i=1,#slots do slots[i]=slots[i]+(Rng.random()-.5)*.016 end
    for i=#slots,2,-1 do local j=Rng.random(i);slots[i],slots[j]=slots[j],slots[i] end
    -- Inner bands take priority; the risky gold point is surrounded by red on both sides.
    band(s,slots[1],.07,"perfect")
    band(s,slots[1],.19,"good")
    band(s,slots[2],.13,"good")
    band(s,slots[3],.045,"critical")
    band(s,slots[3],.145,"trap")
    band(s,slots[4],.09,"trap")
    band(s,slots[5],.025,"ultimate")
    band(s,slots[5],.13,"trap")
    require("src.timing_audio").play(kind,"ready")
    return s
end

function T.grade(s, position)
    for _,zone in ipairs(s.zones) do
        if position>=zone.from and position<=zone.to then return zone.grade end
    end
    return "normal"
end

local function result(grade)
    return {grade=grade,multiplier=grade=="ultimate" and 4 or grade=="critical" and 2.6 or grade=="perfect" and 2
        or grade=="good" and 1.35 or grade=="timeout" and .75 or grade=="trap" and 0 or 1,
        reduction=(grade=="perfect" or grade=="critical" or grade=="ultimate") and 1 or grade=="good" and .5
        or grade=="trap" and -.25 or 0,
        forceMiss=grade=="trap",armorPct=grade=="ultimate" and .5 or grade=="critical" and .25 or 0,
        reflectMultiplier=grade=="ultimate" and 100 or 0}
end

function T.press(s)
    if not s or s.result or s.age<s.ready then return false end
    s.result=result(T.grade(s,s.position));s.hold=0
    require("src.timing_audio").play(s.kind,s.result.grade)
    return true
end

function T.update(s,dt)
    dt=math.max(0,dt)
    if s.result then s.hold=s.hold+dt;return s.hold>=.4 end
    s.age=s.age+dt
    local progress=math.min(1,math.max(0,(s.age-s.ready)/s.duration))
    s.position=s.reverse and 1-progress or progress
    if progress>=1 then
        s.result=result("timeout");s.hold=0
        require("src.timing_audio").play(s.kind,"timeout")
    end
    return false
end

local colors={good={.25,.72,.70},perfect={.95,.72,.28},critical={1,.91,.61},ultimate={.82,.52,1},trap={.76,.25,.24}}
local function label(s)
    local grade=s.result and s.result.grade
    if not grade then return nil end
    if s.kind=="parry" then
        return ({perfect="PARRY · CHẶN TOÀN BỘ",critical="PHẢN THẾ · CHẶN ĐÒN + TẠO GIÁP",
            ultimate="TUYỆT KỸ · PHẢN 10.000% SÁT THƯƠNG",
            good="ĐỠ TỐT · GIẢM 50%",trap="LỘ SƯỜN · NHẬN THÊM 25%",normal="LỠ NHỊP · KHÔNG ĐỠ ĐƯỢC",
            timeout="QUÁ CHẬM · KHÔNG ĐỠ ĐƯỢC"})[grade]
    end
    return ({perfect="CHÍNH XÁC · SÁT THƯƠNG ×2",critical="ĐÒN QUYẾT ĐỊNH · SÁT THƯƠNG ×2.6",
        ultimate="TUYỆT KỸ · SÁT THƯƠNG ×4",
        good="ĐÁNH TỐT · SÁT THƯƠNG ×1.35",trap="SA BẪY · ĐÁNH HỤT",normal="ĐÒN THƯỜNG · SÁT THƯƠNG ×1",
        timeout="QUÁ CHẬM · SÁT THƯƠNG ×0.75"})[grade]
end

function T.draw(s,UI)
    if not s then return end
    local g=love.graphics
    local Core=require("ui.components.core")
    local x,y,w=(UI.BATTLE_CENTER_X or 630)-255,636,510
    local bx,by,bw=x+125,y+25,w-140
    local parry=s.kind=="parry"
    local accent=parry and {.34,.78,.96} or {1,.47,.24}
    g.push("all");g.setShader()
    require("ui.combat_chrome").panel(x,y,w,62,accent)
    Core.gradient(x+5,y+4,w-10,54,parry and {.025,.08,.13,.92} or {.14,.045,.025,.92},{.02,.025,.03,.4},3)
    Core.color(accent,.8);g.setLineWidth(1.5);g.line(x+8,y+3,x+w-8,y+3)
    Core.gradient(x+7,y+7,107,48,{accent[1]*.24,accent[2]*.24,accent[3]*.24,1},{.025,.03,.035,1},3)
    Core.color(accent);g.setLineWidth(1.8)
    local ix,iy=x+24,y+23
    if parry then
        g.polygon("line",ix-9,iy-8,ix,iy-12,ix+9,iy-8,ix+7,iy+4,ix,iy+11,ix-7,iy+4)
        g.line(ix-5,iy-1,ix-1,iy+3,ix+5,iy-4)
    else
        g.polygon("fill",ix+8,iy-13,ix+5,iy-3,ix-4,iy+6,ix-7,iy+3,ix+2,iy-6)
        g.line(ix-9,iy+1,ix-1,iy+9);g.line(ix-5,iy+5,ix-10,iy+10)
    end
    Core.text(parry and "PARRY" or "RA ĐÒN",x+40,y+9,72,UI.fonts.small,accent)
    Core.text(parry and "PHÒNG THỦ" or "TẤN CÔNG",x+10,y+37,101,UI.fonts.tiny,accent,"center")
    Core.text(s.age<s.ready and "ĐỌC NHỊP" or string.format("%s  ×%.2f",s.reverse and "←" or "→",s.speed),bx,y+5,130,UI.fonts.tiny,accent)
    Core.text("SPACE / CHẠM",bx+150,y+5,bw-150,UI.fonts.tiny,{.75,.79,.8},"right")
    g.setColor(.012,.022,.027);g.rectangle("fill",bx-2,by-2,bw+4,16,3)
    Core.color(parry and {.055,.13,.20} or {.20,.09,.045});g.rectangle("fill",bx,by,bw,12,2)
    for tick=1,19 do
        g.setColor(.48,.58,.60,.16);g.line(bx+bw*tick/20,by+4,bx+bw*tick/20,by+8)
    end
    for i=#s.zones,1,-1 do
        local zone=s.zones[i];local c=colors[zone.grade]
        local zx,zw=bx+bw*zone.from,bw*(zone.to-zone.from)
        Core.gradient(zx,by,zw,12,{c[1],c[2],c[3],.95},{c[1]*.48,c[2]*.48,c[3]*.48,1},1)
        if zone.grade=="trap" then
            g.setColor(.15,.035,.03,.75);g.setLineWidth(1)
            for stripe=3,zw-5,7 do g.line(zx+stripe,by+10,zx+stripe+4,by+2) end
        elseif zone.grade=="ultimate" then
            local cx=zx+zw/2
            Core.color(c,.25);g.rectangle("fill",zx-2,by-2,zw+4,16,2)
            g.setColor(1,.9,1);g.setLineWidth(1)
            g.line(cx-4,by-4,cx+4,by-4);g.line(cx,by-8,cx,by)
            g.line(cx-3,by-7,cx+3,by-1);g.line(cx-3,by-1,cx+3,by-7)
        elseif zone.grade=="critical" then
            local cx=zx+zw/2
            g.setColor(1,.92,.64);g.polygon("fill",cx,by-5,cx+3,by-2,cx,by+1,cx-3,by-2)
        end
    end
    local px=bx+bw*s.position
    Core.color(accent,.18);g.rectangle("fill",px-5,by-4,10,20,2)
    g.setColor(1,.98,.87);g.setLineWidth(2);g.line(px,by-4,px,by+16)
    Core.color(accent)
    if parry then
        g.polygon("fill",px-4,by-7,px+4,by-7,px+3,by-2,px,by+1,px-3,by-2)
    else g.polygon("fill",px,by+1,px-4,by-7,px+4,by-7) end
    local text=label(s)
    if text then
        local c=colors[s.result.grade] or {.70,.77,.77}
        Core.text(text,bx,y+44,bw,UI.fonts.tiny,c,"center")
    else
        local legend=parry and {"Đỡ 50%","Đỡ 100%","◆ +giáp","★ ×100","Lộ +25%"}
            or {"×1.35","×2","◆ ×2.6","★ ×4","Đánh hụt"}
        for i,grade in ipairs({"good","perfect","critical","ultimate","trap"}) do
            local lx=bx+(i-1)*bw/5
            Core.color(colors[grade]);g.rectangle("fill",lx,y+48,5,5,1)
            Core.text(legend[i],lx+10,y+43,bw/5-10,UI.fonts.tiny,colors[grade])
        end
    end
    g.pop()
end

return T
