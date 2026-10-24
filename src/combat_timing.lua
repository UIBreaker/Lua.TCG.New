local Rng = require("src.rng")
local T = {}
T.utility={
    siphon={name="HẤP HUYẾT",short="HÚT",hint="×1.2 ST · Hồi 4% HP tối đa",color={1,.19,.28},pitch=.84,multiplier=1.2,healPct=.04},
    pierce={name="XUYÊN PHÁ",short="XUYÊN",hint="×1.6 ST · Xuyên giáp",color={1,.93,.74},pitch=1.12,multiplier=1.6,piercing=true},
    haste={name="TIẾP NHỊP",short="TỐC",hint="×1.4 ST · Tay bài +1 Tốc",color={.08,.88,1},pitch=1.27,multiplier=1.4,haste=1},
    mend={name="HỒI SỨC",short="HỒI",hint="Giảm 75% · Hồi 4% HP tối đa",color={.20,1,.40},pitch=1.04,reduction=.75,healPct=.04},
    reserve={name="TIẾP TẾ",short="BỎ+",hint="Giảm 75% · +1 lượt bỏ",color={1,.56,.10},pitch=.94,reduction=.75,discards=1},
    rebound={name="ĐỠ PHẢN",short="PHẢN",hint="Giảm 75% · Phản ×3",color={.57,.36,1},pitch=.76,reduction=.75,reflectMultiplier=3},
}

local function band(s, center, width, grade)
    s.zones[#s.zones+1]={from=center-width/2,to=center+width/2,grade=grade}
end

function T.start(kind, playerSpeed, enemySpeed,game)
    local ratio=math.max(1,enemySpeed or 1)/math.max(1,playerSpeed or 1)
    local pressure=0
    for _,n in pairs(game and game.timingChains or {}) do pressure=math.max(pressure,math.min(.25,n*.0125)) end
    local speed=math.min(2.4,math.max(.95,math.sqrt(ratio))*(1+pressure))
    local reverse=Rng.random(2)==2
    local s={kind=kind,speed=speed,duration=1.45/speed,age=0,position=reverse and 1 or 0,
        reverse=reverse,ready=0.45,zones={},reducedMotion=T.reducedMotion,game=game,
        cadence=Rng.random(3),pressure=pressure}
    local slots={.12,.31,.50,.69,.88}
    for i=1,#slots do slots[i]=slots[i]+(Rng.random()-.5)*.016 end
    for i=#slots,2,-1 do local j=Rng.random(i);slots[i],slots[j]=slots[j],slots[i] end
    -- Inner bands take priority; the risky gold point is surrounded by red on both sides.
    band(s,slots[1],.062,"perfect")
    band(s,slots[1],.17,"good")
    band(s,slots[2],.17,"trap")
    s.hazard={from=slots[2]-.065,to=slots[2]+.065,grade=kind=="parry" and "exposed" or "riposte"}
    band(s,slots[3],.04,"critical")
    band(s,slots[3],.17,"trap")
    band(s,slots[4],.12,"trap")
    band(s,slots[5],.022,"ultimate")
    band(s,slots[5],.16,"trap")
    s.apex={from=slots[4]-.0065,to=slots[4]+.0065,grade="apex"}
    local center=slots[3]+(Rng.random(2)==1 and -.052 or .052)
    s.divine={from=center-.0035,to=center+.0035,grade="divine"}
    local pool=kind=="parry" and {"mend","reserve","rebound"} or {"siphon","pierce","haste"}
    local first=Rng.random(3);local second=(first-1+Rng.random(2))%3+1
    s.utilityZones={}
    for i,index in ipairs({first,second}) do
        local c=slots[1]+(i==1 and -.060 or .060)
        s.utilityZones[i]={from=c-.013,to=c+.013,grade=pool[index]}
    end
    require("src.timing_audio").play(kind,"ready")
    return s
end

function T.grade(s, position)
    for _,zone in ipairs(s.utilityZones or {}) do if position>=zone.from and position<=zone.to then return zone.grade end end
    if s.hazard and position>=s.hazard.from and position<=s.hazard.to then return s.hazard.grade end
    if s.divine and position>=s.divine.from and position<=s.divine.to then return "divine" end
    if position>=s.apex.from and position<=s.apex.to then return "apex" end
    for _,zone in ipairs(s.zones) do
        if position>=zone.from and position<=zone.to then return zone.grade end
    end
    return "normal"
end

local function result(grade)
    local r={grade=grade,multiplier=grade=="divine" and 12 or grade=="apex" and 8 or grade=="ultimate" and 4 or grade=="critical" and 2.6 or grade=="perfect" and 2
        or grade=="good" and 1.35 or grade=="timeout" and .75 or grade=="trap" and 0 or 1,
        reduction=(grade=="perfect" or grade=="critical" or grade=="ultimate" or grade=="apex" or grade=="divine") and 1 or grade=="good" and .5
        or grade=="exposed" and -4 or grade=="trap" and -.25 or 0,
        selfReflect=grade=="riposte",
        forceMiss=grade=="trap",armorPct=(grade=="ultimate" or grade=="apex" or grade=="divine") and .5 or grade=="critical" and .25 or 0,
        reflectMultiplier=grade=="divine" and 500 or grade=="apex" and 250 or grade=="ultimate" and 100 or 0}
    for k,v in pairs(T.utility[grade] or {}) do r[k]=v end
    return r
end

local valid={good=true,perfect=true,critical=true,ultimate=true,apex=true,divine=true}
for grade in pairs(T.utility) do valid[grade]=true end
function T.record(game,timing)
    if not game or not timing or timing.chainRecorded then return end
    timing.chainRecorded=true
    game.timingChains=game.timingChains or {}
    if not valid[timing.grade] then
        timing.chainBroken=next(game.timingChains)~=nil
        game.timingChains={};timing.chain=0;return
    end
    local n=math.min(9007199254740991,(game.timingChains[timing.grade] or 0)+1)
    game.timingChains[timing.grade]=n;timing.chain=n
    timing.multiplier=(timing.multiplier or 1)*n
    timing.reflectMultiplier=(timing.reflectMultiplier or 0)*n
end
function T.soulReward(grade)
    return (grade=="ultimate" or grade=="apex" or grade=="divine") and 5 or 0
end
function T.awardSuccess(game,timing)
    if not timing or timing.successClaimed then return 0 end
    timing.successClaimed=true
    local n=math.max(1,timing.chain or 1)
    if timing.healPct and (game.playerHp or 0)>0 then timing.rewardHeal=require("src.player_health").heal(game,(game.maxPlayerHp or 100)*timing.healPct*n) end
    if timing.haste then
        timing.rewardSpeed=timing.haste*n
        for _,card in ipairs(require("src.boss_abilities").playableCards(game,game.hand)) do require("src.deck").applyTemporaryAttackSpeedBonus(card,timing.rewardSpeed) end
        require("ui.progression_effects").team(game.hand)
    end
    if timing.discards then
        local before=game.discardsRemaining or 0
        game.discardsRemaining=math.max(before,math.min(game.spnDiscardCap or game.maxDiscards or 3,before+timing.discards*n))
        timing.rewardDiscards=game.discardsRemaining-before
    end
    local amount=T.soulReward(timing.grade)*n
    local before=game.souls or 0;local gold=game.gold or 0
    game.souls=math.min(9007199254740991,before+amount)
    game.gold=math.min(9007199254740991,gold+amount)
    timing.rewardGold=game.gold-gold
    if timing.grade=="apex" or timing.grade=="divine" then
        game.timingRewardMultiplier=math.max(game.timingRewardMultiplier or 1,2*n)
        timing.ceremonyMultiplier=game.timingRewardMultiplier
    end
    if timing.grade=="divine" then
        local seen={};timing.evolvedSpn=0;timing.evolvedCards=0
        for _,d in ipairs(require("src.loadout").ownedDeities(game)) do
            if not seen[d] then
                seen[d]=true
                for _=1,n do require("src.deities").evolve(d) end
                timing.evolvedSpn=timing.evolvedSpn+1
            end
        end
        local cards={};for _,card in ipairs(game.hand or {}) do cards[#cards+1]=card end
        seen={}
        for _,card in ipairs(cards) do
            local key=card.id or card
            if not card.destroyed and not seen[key] then
                seen[key]=true
                if require("src.card_abilities").upgrade(game,card,n,false) then timing.evolvedCards=timing.evolvedCards+1 end
            end
        end
    end
    return game.souls-before
end

function T.press(s)
    if not s or s.result or s.age<s.ready then return false end
    s.result=result(T.grade(s,s.position));s.hold=0
    T.record(s.game,s.result)
    require("src.timing_vfx").emit("confirm",s.result.grade,(s.railX or 386)+s.position*(s.railW or 588),s.railY or 670,{reducedMotion=s.reducedMotion,railX=s.railX or 386,railW=s.railW or 588,chain=s.result.chain})
    require("src.timing_audio").play(s.kind,s.result.grade)
    return true
end

function T.update(s,dt)
    dt=math.max(0,dt)
    if s.result then s.hold=s.hold+dt;return s.hold>=.4 end
    s.age=s.age+dt
    local progress=math.min(1,math.max(0,(s.age-s.ready)/s.duration))
    -- Monotonic, advertised cadence: no surprise reversals or frame-dependent RNG.
    local offset=s.cadence==2 and .045 or s.cadence==3 and -.045 or 0
    local travel=progress+offset*math.sin(progress*math.pi*2)
    s.position=s.reverse and 1-travel or travel
    if progress>=1 then
        s.result=result("timeout");s.hold=0
        T.record(s.game,s.result)
        require("src.timing_audio").play(s.kind,"timeout")
    end
    return false
end

local colors={good={.25,.72,.70},perfect={.95,.72,.28},critical={.25,.70,1},ultimate={.82,.52,1},apex={.86,1,1},divine={1,.38,.60},trap={.76,.25,.24},riposte={1,.39,.13},exposed={1,.39,.13}}
for grade,u in pairs(T.utility) do colors[grade]=u.color end
local function label(s)
    local grade=s.result and s.result.grade
    if not grade then return nil end
    if grade=="riposte" then return "ĐỊCH PHẢN ĐÒN · DỘI LẠI 100% SÁT THƯƠNG CỦA BẠN" end
    if grade=="exposed" then return "VỠ THẾ · NHẬN SÁT THƯƠNG ĐỊCH ×5" end
    local n=s.result.chain or 1
    local u=T.utility[grade]
    if u then
        local extra=u.healPct and ("HỒI "..(u.healPct*100*n).."% HP TỐI ĐA")
            or u.haste and ("TOÀN ĐỘI +"..(u.haste*n).." TỐC TRONG TRẬN")
            or u.discards and ("+"..(u.discards*n).." LƯỢT BỎ · TỐI ĐA GIỚI HẠN")
            or u.reflectMultiplier and ("PHẢN ×"..(u.reflectMultiplier*n)) or "BỎ QUA GIÁP THƯỜNG"
        return u.name..(s.kind=="parry" and " · GIẢM 75% · " or (" · ST ×"..(s.result.multiplier or u.multiplier*n).." · "))..extra
    end
    if grade=="ultimate" or grade=="apex" or grade=="divine" then
        local name=({ultimate="TUYỆT KỸ",apex="CỰC HẠN",divine="THẦN TÍCH"})[grade]
        local power=s.kind=="parry" and (s.result.reflectMultiplier or ({ultimate=100,apex=250,divine=500})[grade]*n)
            or (s.result.multiplier or ({ultimate=4,apex=8,divine=12})[grade]*n)
        local extra=grade=="ultimate" and "" or (" · LỄ ×"..(2*n))
        if grade=="divine" then extra=extra.." · TIẾN HÓA +"..n end
        return name..(s.kind=="parry" and " · PHẢN ×" or " · ST ×")..power.." · +"..(5*n).." LH +"..(5*n).." V"..extra
    end
    if s.kind=="attack" and valid[grade] then
        local name=({good="ĐÁNH TỐT",perfect="CHÍNH XÁC",critical="ĐÒN QUYẾT ĐỊNH"})[grade]
        return name.." · SÁT THƯƠNG ×"..(s.result.multiplier or ({good=1.35,perfect=2,critical=2.6})[grade]*n)
    end
    if s.kind=="parry" and grade=="critical" then return "PHẢN THẾ · CHẶN TOÀN BỘ · GIÁP THƯỞNG ×"..n end
    if s.kind=="parry" then
        return ({perfect="PARRY · CHẶN TOÀN BỘ",good="ĐỠ TỐT · GIẢM 50%",
            trap="LỘ SƯỜN · NHẬN THÊM 25%",normal="LỠ NHỊP · KHÔNG ĐỠ ĐƯỢC",
            timeout="QUÁ CHẬM · KHÔNG ĐỠ ĐƯỢC"})[grade]
    end
    return ({trap="SA BẪY · ĐÁNH HỤT",normal="ĐÒN THƯỜNG · SÁT THƯƠNG ×1",
        timeout="QUÁ CHẬM · SÁT THƯƠNG ×0.75"})[grade]
end

function T.layout(UI)
    local x=(UI.BATTLE_CENTER_X or 630)-360
    return {x=x,y=620,w=720,h=94,bx=x+116,by=663,bw=588}
end
function T.draw(s,UI)
    if not s then return end
    local g=love.graphics
    local Core=require("ui.components.core")
    local layout=T.layout(UI)
    local x,y,w=layout.x,layout.y,layout.w
    local bx,by,bw=layout.bx,layout.by,layout.bw
    s.railX,s.railY,s.railW=bx,by+7,bw
    local parry=s.kind=="parry"
    local accent=s.result and colors[s.result.grade] or (parry and {.34,.78,.96} or {1,.47,.24})
    if s.result and s.result.chainBroken then accent={1,.34,.30} end
    g.push("all");g.setShader()
    require("ui.combat_chrome").panel(x,y,w,94,accent)
    Core.gradient(x+5,y+4,w-10,86,parry and {.025,.08,.13,.92} or {.14,.045,.025,.92},{.02,.025,.03,.4},3)
    Core.color(accent,.8);g.setLineWidth(1.5);g.line(x+8,y+3,x+w-8,y+3)
    Core.gradient(x+7,y+7,99,80,{accent[1]*.24,accent[2]*.24,accent[3]*.24,1},{.025,.03,.035,1},3)
    Core.color(accent);g.setLineWidth(1.8)
    local ix,iy=x+24,y+30
    if parry then
        require("ui.components.shield").draw(ix,iy,25,accent,1)
    else
        g.polygon("fill",ix+8,iy-13,ix+5,iy-3,ix-4,iy+6,ix-7,iy+3,ix+2,iy-6)
        g.line(ix-9,iy+1,ix-1,iy+9);g.line(ix-5,iy+5,ix-10,iy+10)
    end
    Core.text(parry and "PARRY" or "RA ĐÒN",x+40,y+17,64,UI.fonts.small,accent)
    Core.text(parry and "PHÒNG THỦ" or "TẤN CÔNG",x+8,y+54,99,UI.fonts.tiny,accent,"center")
    if s.result and valid[s.result.grade] then
        Core.text("THÀNH CÔNG · CHUỖI ×"..(s.result.chain or 1),bx,y+7,bw-145,UI.fonts.small,accent)
    elseif s.result and s.result.chainBroken then
        Core.text("MẤT CHUỖI",bx,y+7,bw-145,UI.fonts.small,accent)
    elseif s.result and (s.result.grade=="riposte" or s.result.grade=="exposed") then
        Core.text("NGUY HIỂM",bx,y+7,bw-145,UI.fonts.small,accent)
    else
    local rhythm=({"ĐỀU NHỊP","NHANH → CHẬM → NHANH","CHẬM → NHANH → CHẬM"})[s.cadence or 1]
    local pressure=s.pressure and s.pressure>0 and string.format(" · ÁP LỰC +%.0f%%",s.pressure*100) or ""
    Core.text((s.age<s.ready and "ĐỌC NHỊP · " or string.format("%s ×%.2f · ",s.reverse and "←" or "→",s.speed))..rhythm..pressure,bx,y+5,bw-140,UI.fonts.tiny,accent)
    end
    Core.text("SPACE / CHẠM",bx+150,y+5,bw-150,UI.fonts.tiny,{.75,.79,.8},"right")
    g.setColor(.012,.022,.027);g.rectangle("fill",bx-2,by-2,bw+4,18,3)
    Core.color(parry and {.055,.13,.20} or {.20,.09,.045});g.rectangle("fill",bx,by,bw,14,2)
    for tick=1,19 do
        g.setColor(.48,.58,.60,.16);g.line(bx+bw*tick/20,by+4,bx+bw*tick/20,by+8)
    end
    for i=#s.zones,-2,-1 do
        local zone=i==-2 and s.hazard or i==-1 and s.divine or i==0 and s.apex or s.zones[i]
        if zone then
        local c=colors[zone.grade]
        local zx,zw=bx+bw*zone.from,bw*(zone.to-zone.from)
        Core.gradient(zx,by,zw,14,{c[1],c[2],c[3],.95},{c[1]*.48,c[2]*.48,c[3]*.48,1},1)
        if zone.grade=="riposte" or zone.grade=="exposed" then
            local cx=zx+zw/2
            g.setColor(.10,.025,.015,.95);g.rectangle("fill",zx+2,by+2,zw-4,10,1)
            Core.color(c);g.setLineWidth(1.7)
            for dx=-6,6,12 do g.line(cx+dx-3,by+3,cx+dx+3,by+11);g.line(cx+dx-3,by+11,cx+dx+3,by+3) end
            Core.text(parry and "×5" or "DỘI",cx-22,by-18,44,UI.fonts.tiny,c,"center")
        elseif zone.grade=="divine" then
            local cx=zx+zw/2
            g.setColor(.10,.015,.04,.98);g.rectangle("fill",cx-13,by-20,26,18,3)
            local shine=s.reducedMotion and .85 or .75+.25*math.sin(s.age*7)^2
            g.setColor(1,.80,.38,shine);g.setLineWidth(1.7);g.rectangle("line",cx-13,by-20,26,18,3)
            Core.color(c);g.polygon("fill",cx,by-20,cx+6,by-11,cx,by-2,cx-6,by-11)
            g.setColor(1,1,.84);g.polygon("fill",cx,by-17,cx+2,by-11,cx,by-5,cx-2,by-11)
            Core.color(c,.45);g.rectangle("fill",zx-2,by-1,zw+4,16)
        elseif zone.grade=="apex" then
            local cx=zx+zw/2
            Core.color(c,.25);g.rectangle("fill",zx-2,by-2,zw+4,18,2)
            g.setColor(1,1,1)
            g.polygon("fill",cx,by-10,cx+2,by-6,cx+6,by-4,cx+2,by-2,cx,by+2,cx-2,by-2,cx-6,by-4,cx-2,by-6)
        elseif zone.grade=="trap" then
            g.setColor(.15,.035,.03,.75);g.setLineWidth(1)
            for stripe=3,zw-5,7 do g.line(zx+stripe,by+10,zx+stripe+4,by+2) end
        elseif zone.grade=="ultimate" then
            local cx=zx+zw/2
            Core.color(c,.25);g.rectangle("fill",zx-2,by-2,zw+4,18,2)
            g.setColor(1,.9,1);g.setLineWidth(1)
            g.line(cx-4,by-4,cx+4,by-4);g.line(cx,by-8,cx,by)
            g.line(cx-3,by-7,cx+3,by-1);g.line(cx-3,by-1,cx+3,by-7)
        elseif zone.grade=="critical" then
            local cx=zx+zw/2
            Core.color(c);g.polygon("fill",cx,by-5,cx+3,by-2,cx,by+1,cx-3,by-2)
        end
        end
    end
    for _,zone in ipairs(s.utilityZones or {}) do
        local u=T.utility[zone.grade];local zx,zw=bx+bw*zone.from,bw*(zone.to-zone.from)
        Core.color(u.color);g.rectangle("fill",zx,by,zw,14,1)
        require("ui.components.timing_utility").draw(zone.grade,zx+zw/2,by+7,5.2,{.025,.035,.045},1)
        Core.text(u.short,zx+zw/2-24,by-18,48,UI.fonts.tiny,u.color,"center")
    end
    if s.result and valid[s.result.grade] then
        local c=colors[s.result.grade]
        Core.color(c,.24);g.rectangle("fill",bx,by,bw,14,2)
        Core.color(c,.85);g.setLineWidth(1.2);g.line(bx,by-1,bx+bw,by-1)
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
        require("ui.components.timing_caption").draw(text,s.result.grade,bx,y+62,bw,UI.fonts.small,s.hold,s.reducedMotion)
    else
        local legend=parry and {"Đỡ 50%","Đỡ hết","◆ GIÁP","★ ×100","✦ ×250","♦ ×500","Lộ 25%","Nhận ×5"}
            or {"×1.35","×2","◆ ×2.6","★ ×4","✦ ×8","♦ ×12","Hụt","Dội 100%"}
        for i,grade in ipairs({"good","perfect","critical","ultimate","apex","divine","trap",parry and "exposed" or "riposte"}) do
            local lx=bx+(i-1)*bw/8
            Core.color(colors[grade]);g.rectangle("fill",lx,y+67,5,5,1)
            local n=s.game and s.game.timingChains and s.game.timingChains[grade] or 0
            local text=legend[i]..(n>0 and (" ["..n.."]") or "")
            local font=UI.fonts.tiny;local scale=math.min(1,(bw/8-8)/font:getWidth(text))
            g.setFont(font);Core.color(colors[grade]);g.print(text,lx+8,y+61,0,scale,scale)
        end
        Core.text("CHUỖI [N]",x+8,y+77,99,UI.fonts.tiny,{.65,.71,.75},"center")
        for i,zone in ipairs(s.utilityZones or {}) do
            local u=T.utility[zone.grade];local n=s.game and s.game.timingChains and s.game.timingChains[zone.grade] or 0
            local ux=bx+(i-1)*bw/2
            require("ui.components.timing_utility").draw(zone.grade,ux+5,y+83,5,u.color,1)
            Core.text(u.short..(n>0 and (" ["..n.."]") or "").." · "..u.hint,ux+15,y+77,bw/2-18,UI.fonts.tiny,u.color)
        end
    end
    g.pop()
end

return T
