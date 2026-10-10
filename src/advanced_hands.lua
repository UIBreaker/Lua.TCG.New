local A = {ordered={}, byId={}}
local function hand(id,name,chips,mult,condition,effect,planet,shape,bonus,mythic,specificity)
    local h={id=id,name=name,vnName=name,subtitle=condition,condition=condition,effect=effect,
        baseChips=chips,baseMult=mult,requiredCards=5,advanced=true,mythic=mythic,
        specificity=specificity or 1,planetName=planet,shape=shape,bonus=bonus or {},
        scaleChips=math.floor(chips/5),scaleMult=mythic and 3 or 2,
        color=mythic and {0.90,0.69,0.36,1} or {0.58,0.72,0.94,1}}
    A.ordered[#A.ordered+1]=h;A.byId[id]=h
end
hand("tesla_369","BA CỘT SẤM SÉT",110,8,"Có 3, 6, 9 cùng chất trong đúng 5 lá.","Sau đòn chính: 3 tia sét, mỗi tia 6 ST xuyên giáp và phá 3 Giáp.","Sao Cộng Hưởng","triangle",{},false,3)
hand("jackpot_777","KHO BÁU BA SỐ BẢY",112,9,"Đúng ba lá 7 trong 5 lá.","+7 Vàng; hạ mục tiêu nhận thêm 7 Giáp.","Sao Vận Mệnh","orbital_blades",{gold=7,killArmor=7},false,2)
hand("fibonacci","XOẮN ỐC SỰ SỐNG",118,9,"Đúng A, 2, 3, 5, 8; không cần cùng chất.","+1 Máu tối đa (tối đa 3/trận), hồi 2 Máu, +3 Giáp, +5 Tốc, +8 Vàng.","Sao Sinh Mệnh","fusion",{maxHp=1,heal=2,armor=3,speed=5,gold=8},false,5)
hand("prime","NĂM SAO ĐƠN ĐỘC",124,9,"Đúng 2, 3, 5, 7, J.","Hồi 2 Máu, +3 Giáp, +5 Tốc, +7 Vàng.","Sao Nguyên Tố","crossfire",{heal=2,armor=3,speed=5,gold=7},false,5)
hand("odd_star","CHÍN TIA BÌNH MINH",128,9,"Đúng A, 3, 5, 7, 9.","Hồi 5 Máu, +9 Tốc; mục tiêu −3 Tốc.","Sao Bình Minh","blade_storm",{heal=5,speed=9,slow=3},false,5)
hand("even_frost","PHÒNG TUYẾN BĂNG GIÁ",128,9,"Đúng 2, 4, 6, 8, 10.","+12 Giáp; mục tiêu −2 Tốc.","Sao Băng Giá","wave",{armor=12,slow=2},false,5)
hand("crimson_tide","SÓNG TRIỀU ĐỎ",132,10,"5 số khác nhau, tổng 35; chỉ Cơ/Rô và có cả hai chất.","Hồi 10 Máu; Máu dư đổi thành tối đa 5 Vàng.","Sao Biển Đỏ","wave",{heal=10,overflow=5},false,3)
hand("obsidian_tide","SÓNG TRIỀU ĐÁ ĐEN",132,10,"5 số khác nhau, tổng 35; chỉ Bích/Tép và có cả hai chất.","+15 Giáp, +2 Tốc.","Sao Đá Đen","crossfire",{armor=15,speed=2},false,3)
hand("eclipse_duality","HAI MẶT NHẬT THỰC",138,10,"Đỏ/đen 3–2 hoặc 2–3; số lá 1=5, 2=4 theo thứ tự đánh.","Đỏ nhiều: hồi 6 Máu, +3 Vàng. Đen nhiều: +10 Giáp, +3 Tốc.","Sao Nhật Thực","twin_blades",{},false,4)
hand("four_kingdom_prism","LĂNG KÍNH BỐN MÀU",145,10,"Đủ 4 chất, 5 số khác nhau; số lớn − nhỏ ≥9 (A=1).", "Hồi 4 Máu, +4 Giáp, +2 Tốc, +2 Vàng.","Sao Lăng Kính","crossfire",{heal=4,armor=4,speed=2,gold=2},false,2)
hand("four_kingdom_expedition","LIÊN MINH VIỄN CHINH",150,10,"Đủ 4 chất; có A và K trong 5 lá.","Hồi 8 Máu, +8 Giáp, +2 Tốc, +2 Vàng.","Sao Viễn Chinh","chain",{heal=8,armor=8,speed=2,gold=2},false,3)
hand("destiny_crown","VƯƠNG MIỆN ĐỊNH MỆNH",160,11,"Đúng 10, J, Q, K, A; không phải 5 lá cùng chất.","+10 Giáp, +5 Tốc, +5 Vàng; boss −2 Tốc.","Sao Vương Quyền","blade_storm",{armor=10,speed=5,gold=5,bossSlow=2},false,5)
hand("continental_gate","CỔNG LỤC ĐỊA THẤT LẠC",180,12,"Bốn lá A và một lá K.","Hồi 10 Máu, +20 Giáp, +3 Vàng; boss −3 Tốc.","Sao Đại Lục","fusion",{heal=10,armor=20,gold=3,bossSlow=3},false,6)
hand("answer_42","BẢN ĐỒ CHÂN TRỜI",142,10,"5 số khác nhau có tổng đúng 42 (A=1).", "Hồi 4 Máu, +2 Giáp, +4 Tốc, +2 Vàng.","Sao Chân Trời","chain",{heal=4,armor=2,speed=4,gold=2},false,2)
hand("sealed_gate","CÁNH CỔNG THỨC TỈNH",175,11,"Ba lá A và hai lá K.","+15 Giáp, +5 Vàng.","Sao Thức Tỉnh","fusion",{armor=15,gold=5},true,6)
hand("seven_stars","BẢY SAO DẪN LỐI",170,11,"Ba lá 7, một A và một K.","+7 Vàng, hồi 7 Máu, +7 Giáp.","Sao Dẫn Lối","orbital_blades",{gold=7,heal=7,armor=7},true,6)
hand("five_ley_lines","NĂM MẠCH NĂNG LƯỢNG",168,11,"Đúng A, 4, 8, 10, K.","+10 Giáp, +4 Tốc, +4 Vàng.","Sao Năng Lượng","triangle",{armor=10,speed=4,gold=4},true,5)
hand("endless_cycle","VÒNG XOAY BẤT TẬN",172,11,"5 số liên tiếp, đủ 4 chất; lá đầu/cuối cùng chất theo thứ tự đánh.","Hồi 6 Máu, +6 Giáp; tay đánh kế tiếp +2 Tốc.","Sao Bất Tận","orbital_blades",{heal=6,armor=6,nextSpeed=2},true,4)
local colors={tesla_369={.4,.75,1},jackpot_777={1,.77,.27},fibonacci={.45,.92,.62},prime={.75,.57,1},odd_star={1,.65,.24},even_frost={.49,.88,1},
    crimson_tide={1,.35,.42},obsidian_tide={.64,.65,.84},eclipse_duality={.88,.49,.72},four_kingdom_prism={.67,.9,.98},four_kingdom_expedition={.93,.77,.46},
    destiny_crown={1,.82,.4},continental_gate={.95,.88,.67},answer_42={.55,.74,.96},sealed_gate={.78,.53,1},seven_stars={1,.84,.5},five_ley_lines={.53,.87,.5},endless_cycle={.62,.94,.82}}
for _,h in ipairs(A.ordered) do h.color=colors[h.id];h.color[4]=1 end
table.sort(A.ordered,function(a,b)
    local am,bm=a.mythic==true,b.mythic==true
    if am~=bm then return am end
    if a.specificity~=b.specificity then return a.specificity>b.specificity end
    if a.baseChips*a.baseMult~=b.baseChips*b.baseMult then return a.baseChips*a.baseMult>b.baseChips*b.baseMult end
    return a.id<b.id
end)
for i,h in ipairs(A.ordered) do h.order=100+#A.ordered-i end

local suitIds={hearts=1,valoria=1,diamonds=2,aurelia=2,clubs=3,elaris=3,spades=4,vharos=4}
local sets={fibonacci={1,2,3,5,8},prime={2,3,5,7,11},odd_star={1,3,5,7,9},even_frost={2,4,6,8,10},destiny_crown={1,10,11,12,13},five_ley_lines={1,4,8,10,13}}
local function facts(cards)
    if not cards or #cards~=5 then return end
    local f={ranks={},counts={},suits={},sum=0,distinct=0,min=14,max=0,wild={},cards=cards}
    local seen={}
    for i,c in ipairs(cards) do
        local r=c.rank==14 and 1 or c.rank
        if seen[c] or type(r)~="number" or r<1 or r>13 or r%1~=0 or not suitIds[c.suit] then return end
        seen[c]=true;f.ranks[i]=r;f.counts[r]=(f.counts[r] or 0)+1
        if f.counts[r]==1 then f.distinct=f.distinct+1 end
        f.sum=f.sum+r;f.min=math.min(f.min,r);f.max=math.max(f.max,r);f.suits[i]=suitIds[c.suit]
        f.wild[i]=require("src.card_effects").getEffectName(c)=="astral" or not c.disableFactionPassives and (c.isWildSuit or r==1 and f.suits[i]==3)
    end
    return f
end
local function rankMatch(id,f)
    if sets[id] then for _,r in ipairs(sets[id]) do if f.counts[r]~=1 then return false end end;return true end
    if id=="tesla_369" then return f.counts[3] and f.counts[6] and f.counts[9] end
    if id=="jackpot_777" then return f.counts[7]==3 end
    if id=="continental_gate" then return f.counts[1]==4 and f.counts[13]==1 end
    if id=="sealed_gate" then return f.counts[1]==3 and f.counts[13]==2 end
    if id=="seven_stars" then return f.counts[7]==3 and f.counts[1]==1 and f.counts[13]==1 end
    if id=="answer_42" then return f.distinct==5 and f.sum==42 end
    if id=="crimson_tide" or id=="obsidian_tide" then return f.distinct==5 and f.sum==35 end
    if id=="eclipse_duality" then return f.ranks[1]==f.ranks[5] and f.ranks[2]==f.ranks[4] end
    if id=="four_kingdom_prism" then return f.distinct==5 and f.max-f.min>=9 end
    if id=="four_kingdom_expedition" then return f.counts[1] and f.counts[13] end
    if id=="endless_cycle" then return f.distinct==5 and (f.max-f.min==4 or f.counts[1] and f.counts[10] and f.counts[11] and f.counts[12] and f.counts[13]) end
    return false
end
local suited={tesla_369=true,crimson_tide=true,obsidian_tide=true,eclipse_duality=true,four_kingdom_prism=true,four_kingdom_expedition=true,destiny_crown=true,endless_cycle=true}
local function suitMatch(id,f,s)
    local unique={}
    local count,red=0,0
    for _,v in ipairs(s) do if not unique[v] then unique[v]=true;count=count+1 end;if v<=2 then red=red+1 end end
    if id=="tesla_369" then
        for suit=1,4 do local ranks={};for i,v in ipairs(s) do if v==suit then ranks[f.ranks[i]]=true end end
            if ranks[3] and ranks[6] and ranks[9] then return true end
        end
        return false
    elseif id=="crimson_tide" then return red==5 and count==2
    elseif id=="obsidian_tide" then return red==0 and count==2
    elseif id=="eclipse_duality" then return red==2 or red==3
    elseif id=="destiny_crown" then return count>1
    elseif id=="endless_cycle" then return count==4 and s[1]==s[5]
    end
    return count==4
end
function A.matches(cards)
    local f=facts(cards);local result={};if not f then return result end
    for _,h in ipairs(A.ordered) do if rankMatch(h.id,f) then
        local assignment
        if not suited[h.id] then assignment=f.suits else
            local s={}
            local function search(i)
                if i==6 then if suitMatch(h.id,f,s) then assignment={unpack(s)};return true end;return false end
                if f.wild[i] then for v=1,4 do s[i]=v;if search(i+1) then return true end end
                else s[i]=f.suits[i];return search(i+1) end
                return false
            end
            search(1)
        end
        if assignment then result[#result+1]={type=h,scoringCards=cards,unscoredCards={},effectiveSuits=assignment} end
    end end
    return result
end

function A.begin(game,eval)
    game.advancedCombat=game.advancedCombat or {gold=0,maxHp=0,speed=0}
    local c=game.advancedCombat;c.currentSpeed=c.nextSpeed or 0;c.nextSpeed=0
    game.advancedHand=eval.type.advanced and {id=eval.type.id,suits=eval.effectiveSuits} or nil
end
function A.resolve(game)
    local context=game.advancedHand
    if not context or context.resolved then return {} end
    context.resolved=true
    local h=A.byId[context.id];if not h then return {} end
    local c=game.advancedCombat or {gold=0,maxHp=0,speed=0};game.advancedCombat=c
    local b=h.bonus
    if h.id=="eclipse_duality" then
        local red=0;for _,s in ipairs(context.suits or {}) do if s<=2 then red=red+1 end end
        b=red==3 and {heal=6,gold=3} or {armor=10,speed=3}
    end
    local maxGain=math.min(b.maxHp or 0,math.max(0,3-(c.maxHp or 0)))
    c.maxHp=(c.maxHp or 0)+maxGain;game.maxPlayerHp=(game.maxPlayerHp or 100)+maxGain
    local hp=game.playerHp or game.maxPlayerHp
    local overflow=math.max(0,hp+(b.heal or 0)-game.maxPlayerHp)
    game.playerHp=math.min(game.maxPlayerHp,hp+(b.heal or 0))
    local gold=math.min((b.gold or 0)+math.min(overflow,b.overflow or 0),math.max(0,30-(c.gold or 0)))
    c.gold=(c.gold or 0)+gold;game.gold=(game.gold or 0)+gold
    local armor=(b.armor or 0)+((game.monster.hp or 0)<=0 and (b.killArmor or 0) or 0)
    local previousArmor=game.playerArmor or 0;local previousSpeed=c.speed or 0
    game.playerArmor=math.min(require("src.card_abilities").config.armorCap,previousArmor+armor);game.playerShield=game.playerArmor
    c.speed=math.min(12,previousSpeed+(b.speed or 0));c.nextSpeed=b.nextSpeed or 0
    local slow=(b.slow or 0)+(game.monster.isBoss and (b.bossSlow or 0) or 0)
    game.monster.attackSpeed=math.max(1,(game.monster.attackSpeed or 1)-slow)
    local hits={}
    if h.id=="tesla_369" then
        local members=require("src.enemy_group").members(game)
        local targetIndex=1;for i,m in ipairs(members) do if m==game.monster then targetIndex=i;break end end
        for hitIndex=1,3 do
            local living={}
            for _,index in ipairs({targetIndex-1,targetIndex+1}) do local m=members[index];if m and m.hp>0 then living[#living+1]=m end end
            if #living==0 and game.monster.hp>0 then living[1]=game.monster end
            if #living==0 then break end
            local m=living[((hitIndex-1)%#living)+1];m.creatureArmor=math.max(0,(m.creatureArmor or 0)-3)
            local damage=require("src.monster").takeDamage(m,6,true)
            hits[#hits+1]={enemy=m,damage=damage,deity={name="BA CỘT · SÉT"},advanced=true}
        end
    end
    game.advancedFeedback={name=h.vnName,heal=math.max(0,game.playerHp-hp),armor=game.playerArmor-previousArmor,gold=gold,speed=c.speed-previousSpeed+(b.nextSpeed or 0)}
    return hits
end
return A
