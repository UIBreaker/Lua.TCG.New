-- The second expedition: memory, preparation and conversions, shared by UI/runtime.
local D={equipment={},seals={},spells={},spectral={},byId={}}
local function add(list,id,name,desc,art,effect)
    local v={id=id,name=name,subtitle=name,desc=desc,artConcept=art,effect=effect,depth=true,
        icon="✦",params={},color={0.75,0.64,0.9,1}}
    list[#list+1]=v;D.byId[id]=v;return v
end
local function game(ctx) return ctx and (ctx.depthGame or ctx.gameState or ctx) or {} end
D.game=game
local function state(g) return g.depthCombat or {} end
local function key(c,id) return tostring(c.id)..":"..id end
local function value(g,c,id) return (state(g).values or {})[key(c,id)] or 0 end
local function set(g,c,id,n,ctx)
    if ctx and ctx.preview and not ctx.depthGame then return end
    g.depthCombat=g.depthCombat or {values={},seen={}}
    g.depthCombat.values=g.depthCombat.values or {};g.depthCombat.values[key(c,id)]=n
end
local function once(ctx,c,id)
    if not ctx then return false end
    local g=game(ctx);local s=ctx.preview and ctx or state(g)
    s.depthSeen=s.depthSeen or {};local k=key(c,id)
    if s.depthSeen[k] then return false end;s.depthSeen[k]=true;return true
end
D.allowSeal=once
local function sync(g,c,fn) require("src.chest_expansion").sync(g,c,fn) end
local function spend(g,field,n,ctx)
    if (g[field] or 0)<n then return false end
    if not (ctx and ctx.preview) or ctx.depthGame then g[field]=g[field]-n end
    return true
end
function D.begin(ctx)
    if not ctx then return end
    ctx.depthGame=nil
    ctx.depthSeen={}
    if ctx.preview then
        local original=ctx.gameState or ctx;local copy={}
        for k,v in pairs(original) do copy[k]=v end
        local function clone(t) local out={};for k,v in pairs(t or {}) do out[k]=type(v)=="table" and clone(v) or v end;return out end
        copy.depthCombat=clone(original.depthCombat);ctx.depthGame=copy
        return
    end
    local g=game(ctx);g.depthCombat=g.depthCombat or {values={}}
    g.depthCombat.depthSeen={}
end
function D.finish(ctx,h)
    if not ctx or ctx.preview then return end
    local g=game(ctx);local s=state(g)
    s.lastType=h.type.id;s.lastSize=#h.scoringCards
    s.lastRanks={};for _,c in ipairs(h.scoringCards) do s.lastRanks[c.id]=c.rank end
    s.damage=0;s.blocked=0;s.discarded=0
end
function D.enemyAttack(g,damage,absorbed)
    g.depthCombat=g.depthCombat or {values={}}
    local s=state(g);s.damage=(s.damage or 0)+damage
    s.attacks=(s.attacks or 0)+1
    if damage==0 and absorbed>0 then s.blocked=(s.blocked or 0)+1 end
    for _,c in ipairs(g.hand or {}) do set(g,c,"heldHits",value(g,c,"heldHits")+1) end
end
add(D.equipment,"itm_capacitor","Bình Tích Sét","Bỏ lá này: tích 1 điện, tối đa 3. Khi tính điểm: xả toàn bộ, mỗi điện +18 ST và +3 Cường hóa. Điện mất khi hết trận.","A physical copper lightning jar with three large charge chambers on a navy cliff.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"charge");set(g,c,"charge",0,ctx);return {addChips=18*n,addMult=3*n}
end)
add(D.equipment,"itm_counterweight","Rìu Phản Lực","Tính điểm sau khi bị quái gây mất HP từ lần đánh trước: +1.5% sát thương mỗi HP mất, tối đa 30%; không tính HP tự trả.","A physical iron counterweight axe swinging back from an impact in volcanic ruins.",function(c,cs,i,ctx)
    return {extraDamagePct=math.min(0.3,(state(game(ctx)).damage or 0)*0.015)}
end)
add(D.equipment,"itm_ledger","Sổ Giao Kèo","Khi tính điểm: tự trả 1 Vàng để đầu tư 1 nấc, tối đa 5 nấc vĩnh viễn trên lá. Mỗi nấc cho +3 Cường hóa, kể cả khi không đủ Vàng.","A tangible five-clasp leather ledger with a gold coin pressed into its cover in desert ruins.",function(c,cs,i,ctx)
    local g=game(ctx);local n=c.depthInvestment or 0
    if n<5 and spend(g,"gold",1,ctx) then n=n+1;if not ctx.preview then sync(g,c,function(o) o.depthInvestment=n end) end end
    return {addMult=n*3}
end)
add(D.equipment,"itm_oar","Mái Chèo Chuyển Dòng","Khi tính điểm trong thế đánh khác lần đánh trước của trận: +20 ST và +4 Giáp. Không kích hoạt ở tay đầu.","A tangible expedition oar cutting across two opposing blue currents below coastal cliffs.",function(c,cs,i,ctx)
    local s=state(game(ctx));if s.lastType and s.lastType~=ctx.depthHandType then return {addChips=20,addArmor=4} end
end)
add(D.equipment,"itm_hourhand","Kim Đồng Hồ Canh Gác","Giữ lá này qua 2 đòn quái: lần tính điểm sau nhận +14 Cường hóa và xóa số đòn đã giữ; chỉ tính đòn quái thực sự ra tay.","One tangible silver clock hand braced against two frozen impact rings on a glacial monolith.",function(c,cs,i,ctx)
    local g=game(ctx);if value(g,c,"heldHits")>=2 then set(g,c,"heldHits",0,ctx);return {addMult=14} end
end)
add(D.equipment,"itm_bloodvial","Lọ Huyết Tế","Bỏ lá này khi còn hơn 2 HP: trả 2 HP, tích 1 giọt (tối đa 3). Khi tính điểm: xả giọt, mỗi giọt +7 Cường hóa. Mất giọt khi hết trận.","A physical red glass vial with three large blood drops over a volcanic expedition altar.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"drops");set(g,c,"drops",0,ctx);return {addMult=n*7}
end)
add(D.equipment,"itm_relay","Dây Xích Tiếp Sức","Nếu lá tính điểm ngay trước có trang bị: nhận thêm ST bằng một nửa ST cơ bản của lá trước (làm tròn xuống), tối đa 60.","A physical broad iron chain connecting two expedition weapon hilts in a forest workshop.",function(c,cs,i)
    local p=cs[i-1];if p and #(p.equipments or {})>0 then return {addChips=math.min(60,math.floor((p.baseChips or 0)/2))} end
end)
add(D.equipment,"itm_lockbox","Khóa Giáp Ngân","Khi tính điểm và đang có ít nhất 8 Giáp: tiêu 8 Giáp để +20% sát thương. Giáp đã tiêu không chặn đòn quái sau đó.","One physical silver shield-lock opening and releasing a controlled gold beam from glacial armor.",function(c,cs,i,ctx)
    local g=game(ctx);if spend(g,"playerArmor",8,ctx) then if not ctx.preview then g.playerShield=g.playerArmor end;return {extraDamagePct=0.2} end
end)
add(D.equipment,"itm_bell","Chuông Tĩnh Lặng","Mỗi lần lá tính điểm mà chưa bỏ bài từ lần đánh trước: tích 1 nhịp (tối đa 4), +5 Cường hóa mỗi nhịp. Bất kỳ lần bỏ bài nào xóa nhịp của mọi lá mang chuông.","A tangible silent bronze bell wrapped in cloth above a quiet forest sanctuary.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"quiet")
    if (state(g).discarded or 0)==0 then n=math.min(4,n+1) end
    set(g,c,"quiet",n,ctx);return {addMult=5*n}
end)
add(D.equipment,"itm_pendulum","Quả Lắc Viễn Chinh","So với số lá tính điểm ở tay trước: đánh nhiều hơn thì +24 ST; đánh ít hơn thì +6 Giáp. Bằng nhau hoặc tay đầu không có thưởng.","One physical pendulum swinging between a tall and a short stone expedition column in a desert.",function(c,cs,i,ctx)
    local n=state(game(ctx)).lastSize
    if n and #cs>n then return {addChips=24} elseif n and #cs<n then return {addArmor=6} end
end)
for _,d in ipairs(D.equipment) do
    d.cost=7;d.rarity="rare";d.slotsNeeded=1
    d.onCardScore=function(c,cs,i,ctx)
        if i==0 or not once(ctx,c,d.id) then return end
        local r=d.effect(c,cs,i,ctx);if r then r.message=d.name end;return r
    end
end
add(D.seals,"seal_echoes","Ấn Tứ Phương","Các lá mang ấn cùng ghi chất mỗi khi bị bỏ. Đủ 4 chất đã ghi chung: lá mang ấn tính điểm kế tiếp +0.6 hệ số Aura rồi xóa bộ ghi. Ký ức chỉ giữ trong trận.","A large four-direction compass stamp gathering four controlled elemental trails on coastal stone.",function(c,cs,i,ctx)
    local g=game(ctx);local s=state(g);local n=0
    for _ in pairs(s.suitMarks or {}) do n=n+1 end
    if n>=4 then s.suitMarks={};return {xMultBonus=0.6} end
end)
add(D.seals,"seal_reclaimer","Ấn Thu Hồi","Bỏ riêng lá này: trả 2 Vàng để hoàn 1 lượt bỏ bài, tối đa một lần mỗi trận. Thiếu Vàng không trả chi phí và không hoàn lượt.","One circular return-arrow stamp reclaiming a coin from a stone slot in a desert.")
add(D.seals,"seal_tutor","Ấn Truyền Nghề","Khi tính điểm: lá ngay sau trong vùng tính điểm nhận +1 cấp khả năng tạm thời trong trận (tối đa trần tiến hóa). Không tự nâng bản thân.","A large mentor-hand stamp passing one green flame to a smaller stone hand in an ancient forest.",function(c,cs,i,ctx)
    local p=cs[i+1];if p and not ctx.preview then
        local A=require("src.card_abilities");local n=math.max(0,math.min(1,A.config.maxEvolutionLevel-A.level(p)))
        if n>0 then A.upgrade(game(ctx),p,n,true) end
    end
    if p then return {} end
end)
add(D.seals,"seal_gambit","Ấn Đổi Lượt","Tính điểm cùng đúng 5 lá: trả 4 HP để nhận +1 lượt đánh, một lần mỗi trận; chỉ trả khi còn hơn 4 HP.","A large five-spoked turnwheel stamp with a single controlled red flame over volcanic stone.",function(c,cs,i,ctx)
    local g=game(ctx);if #cs==5 and value(g,c,"gambit")==0 and (g.playerHp or 0)>4 then
        if not ctx.preview then g.playerHp=g.playerHp-4;g.handsRemaining=(g.handsRemaining or 0)+1 end
        set(g,c,"gambit",1,ctx);return {}
    end
end)
add(D.seals,"seal_constellation","Ấn Chòm Sao","Khi tính điểm: +8 ST mỗi lá khác trong bộ bài vĩnh viễn đang mang Ấn Chòm Sao, tối đa +48. Khuyến khích xây mạng lưới dấu thay vì chỉ một lá mạnh.","A large star-network stamp linking six broad stars above a violet continental night.",function(c,cs,i,ctx)
    local n=0;for _,o in ipairs(game(ctx).persistentDeck or {}) do if o.id~=c.id and o.seal==c.seal then n=n+1 end end
    return {addChips=math.min(48,8*n)}
end)
add(D.seals,"seal_pact","Ấn Gửi Vàng","Bỏ lá này: gửi 1 Vàng vào ấn (tối đa 3 Vàng mỗi trận). Khi tính điểm: nhận lại gấp đôi số đã gửi rồi xóa khoản gửi.","A large two-compartment treasury stamp enclosing a coin in a desert stone tablet.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"deposit");set(g,c,"deposit",0,ctx);return {addGold=2*n}
end)
add(D.seals,"seal_waymark","Ấn Đường Rẽ","Lá này tính điểm trong hai thế đánh khác nhau liên tiếp của chính nó: hoàn 1 lượt bỏ bài, tối đa một lần mỗi trận. Không cần đánh liên tiếp hai tay.","A large forked-road stamp with two clearly separated paths over continental cliffs.",function(c,cs,i,ctx)
    local g=game(ctx);local s=state(g);local last=(s.cardTypes or {})[c.id]
    local award=last and last~=ctx.depthHandType and value(g,c,"waymark")==0
    if not ctx.preview then s.cardTypes=s.cardTypes or {};s.cardTypes[c.id]=ctx.depthHandType end
    if award then if not ctx.preview then g.discardsRemaining=(g.discardsRemaining or 0)+1 end;set(g,c,"waymark",1,ctx);return {} end
end)
add(D.seals,"seal_debt","Ấn Thế Chấp","Khi tính điểm: nếu còn lượt bỏ bài, tiêu 1 lượt để nhận 15 Giáp; nếu hết lượt bỏ bài, trả 3 HP để nhận +9 Cường hóa (cần hơn 3 HP).","One heavy shield-and-chain collateral stamp balanced against a red crystal on desert stone.",function(c,cs,i,ctx)
    local g=game(ctx)
    if spend(g,"discardsRemaining",1,ctx) then return {addArmor=15}
    elseif (g.playerHp or 0)>3 then return {hpCost=3,addMult=9} end
end)
add(D.seals,"seal_duel","Ấn Song Đấu","Chỉ một lá tính điểm và đúng một lá giữ lại: +2% sát thương mỗi bậc rank chênh giữa hai lá, tối đa 24%.","A large crossed-duelist stamp showing a long and a short sword on a glacial tablet.",function(c,cs,i,ctx)
    local held=ctx.hand or {};if #cs==1 and #held==1 then return {extraDamagePct=math.min(0.24,0.02*math.abs(c.rank-held[1].rank))} end
end)
add(D.seals,"seal_threshold","Ấn Tam Nhịp","Mỗi lần lá tính điểm tích một nhịp. Cứ lần thứ ba: hồi 8 HP và xóa nhịp. Nhịp mất khi hết trận; tái kích hoạt không thêm nhịp.","A large three-step heartbeat stamp with three broad grooves in a green forest altar.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"third")+1;set(g,c,"third",n%3,ctx)
    if n>=3 then return {healHp=8} end
    return {}
end)
for _,d in ipairs(D.seals) do d.sealType=d.id;d.sealName=d.name;d.effect=d.effect or function() end end

local function spellState(g,id) return (state(g).spellValues or {})[id] or {} end
local function saveSpell(g,id,t,ctx)
    if ctx and ctx.preview and not ctx.depthGame then return end
    local s=state(g);s.spellValues=s.spellValues or {};s.spellValues[id]=t
end
add(D.spells,"spell_seasons","Phù Phép Bốn Mùa","SPN đầu tiên: ghi các thế đánh đã dùng. Đủ 4 thế khác nhau trong trận thì thêm 1 lượt đánh và xóa bộ ghi. Mỗi tay chỉ ghi một lần.","One spectral season wheel with four broad weather sectors above a Western forest.",function(h,g,ctx)
    local t={};for k,v in pairs(spellState(g,"seasons")) do t[k]=v end;t[h.type.id]=true
    local n=0;for _ in pairs(t) do n=n+1 end
    if n>=4 then t={};if not ctx.preview then g.handsRemaining=(g.handsRemaining or 0)+1 end end
    saveSpell(g,"seasons",t,ctx);return {}
end)
add(D.spells,"spell_escrow","Phù Phép Bảo Hiểm","SPN đầu tiên: mỗi tay nhận 1 Vàng cho mỗi 5 HP thực sự bị quái lấy từ lần đánh trước, tối đa 3 Vàng; tự trả HP không được bồi thường.","One spectral merchant sheltering a wounded traveler beneath a translucent antique gold canopy.",function(h,g)
    return {addGold=math.min(3,math.floor((state(g).damage or 0)/5))}
end)
add(D.spells,"spell_switchcraft","Phù Phép Biến Thế","SPN đầu tiên: chuyển từ Đôi/Hai Đôi sang Sảnh hoặc ngược lại giữa hai tay liên tiếp: +0.45 hệ số Aura. Thùng Phá Sảnh cũng tính là Sảnh.","One supernatural blade spirit shifting between paired blades and a long glacial spear.",function(h,g)
    local function mode(id) return (id=="pair" or id=="two_pair") and 1 or (id=="straight" or id=="straight_flush") and 2 end
    local a,b=mode(state(g).lastType),mode(h.type.id)
    if a and b and a~=b then return {xMultBonus=0.45} end
end)
add(D.spells,"spell_recycle","Phù Phép Tái Chế","SPN đầu tiên: khi đánh mà cọc rút đã hết, nhận 1 lượt bỏ bài, một lần mỗi trận; không tự xáo cọc hoặc rút thêm bài.","One spectral serpent carrying discarded stone fragments into a new circle over forest ruins.",function(h,g,ctx)
    if #(g.deck or {})==0 and not spellState(g,"recycle").used then
        if not ctx.preview then g.discardsRemaining=(g.discardsRemaining or 0)+1 end
        saveSpell(g,"recycle",{used=true},ctx);return {}
    end
end)
add(D.spells,"spell_retinue","Phù Phép Bách Khí","SPN đầu tiên: mỗi loại trang bị khác nhau trên các lá tính điểm cho +2 Cường hóa, tối đa +12; trang bị trùng ID chỉ tính một lần.","One supernatural armory guardian surrounded by six large distinct spectral weapons in a ruined Western forge.",function(h)
    local ids,n={},0;for _,c in ipairs(h.scoringCards) do for _,eq in ipairs(c.equipments or {}) do if not ids[eq.id] then ids[eq.id]=true;n=n+1 end end end
    return {addMult=math.min(12,2*n)}
end)
add(D.spells,"spell_metronome","Phù Phép Nhịp Tiến","SPN đầu tiên: tay trước tính điểm 2 lá, tay này 3 lá: lá thấp rank nhất giữ lại nhận +1 cấp khả năng tạm thời trong trận; hòa rank chọn lá trái nhất.","One spectral conductor marking a two-beat rhythm turning into three luminous mountain stepping stones.",function(h,g,ctx)
    if state(g).lastSize==2 and #h.scoringCards==3 then
        local target;for _,c in ipairs(ctx.hand or {}) do if not target or c.rank<target.rank then target=c end end
        if target then if not ctx.preview then
            local A=require("src.card_abilities");local n=math.max(0,math.min(1,A.config.maxEvolutionLevel-A.level(target)))
            if n>0 then A.upgrade(g,target,n,true) end
        end;return {} end
    end
end)
add(D.spells,"spell_caravan","Phù Phép Trú Quân","SPN đầu tiên: tích số đòn quái thực sự ra tay trong trận. Sau mỗi 3 đòn, tay đánh kế tiếp hồi 10 HP rồi xóa 3 đòn; tối đa một lần mỗi tay.","One broad spectral caravan shelter guarded through three incoming storm waves on a navy coast.",function(h,g,ctx)
    local n=state(g).attacks or 0
    if n>=3 then if not ctx.preview or ctx.depthGame then state(g).attacks=n-3 end;return {healHp=10} end
end)
add(D.spells,"spell_magnet","Phù Phép Hút Gió","SPN đầu tiên: bỏ đúng 3 lá có rank khác nhau thì mọi lá còn giữ trên tay nhận +2 tốc đánh tạm trong trận (tối đa 999). Có thể kích hoạt nhiều lần.","One spectral wind ray drawing three separate stone fragments into a coordinated cyan current.")
add(D.spells,"spell_reprisal","Phù Phép Phản Thành","SPN đầu tiên: mỗi đòn quái bị Giáp chặn hết từ lần đánh trước cho +40 ST ở tay kế tiếp, tối đa +80; đòn Boss hủy trước khi ra tay không tính.","One spectral stone fortress reflecting two broad impacts into a single silver shockwave.",function(h,g)
    return {addChips=math.min(80,40*(state(g).blocked or 0))}
end)
add(D.spells,"spell_codex","Phù Phép Luân Vai","SPN đầu tiên: chuyển giữa vùng tính điểm toàn J/Q/K và toàn quân số 2–10: tăng vĩnh viễn 1 cấp của thế đánh mới, một lần mỗi trận; áp dụng từ tay sau.","One spectral librarian turning a page between a royal silhouette and a soldier in Western violet ruins.",function(h,g,ctx)
    local mode="number";for _,c in ipairs(h.scoringCards) do if c.rank<2 or c.rank>10 then mode=nil end end
    local allFace=true;for _,c in ipairs(h.scoringCards) do if c.rank<11 or c.rank>13 then allFace=false end end
    if allFace then mode="face" end
    local old=spellState(g,"codex");local t={last=mode,used=old.used}
    if mode and old.last and old.last~=mode and not old.used then
        t.used=true;if not ctx.preview then g.handLevels=g.handLevels or {};g.handLevels[h.type.id]=(g.handLevels[h.type.id] or 1)+1 end
    end
    saveSpell(g,"codex",t,ctx);return {}
end)
for _,s in ipairs(D.spells) do s.effect=s.effect or function() end;s.desc=s.desc.." Thay phù phép cũ; giữ ấn bản/tiến hóa." end

add(D.spectral,"spec_partition","Phân Số","Chọn lá rank ít nhất 6: chia rank của nó thành hai phần gần bằng nhau, đổi rank lá chọn và lá khác đầu tiên trên tay theo hai phần đó. Trả 3 Vàng; giữ chất và nâng cấp.","A supernatural numbered stone splitting into two equal broad spectral slabs over a violet canyon.")
add(D.spectral,"spec_consolidate","Hợp Lưu Tốc Độ","Chọn một lá: chuyển tối đa 12 tốc đánh thưởng từ các lá khác trên tay sang lá chọn, theo trái sang phải. Trả 4 Vàng; chỉ dùng khi có tốc thưởng và không mất do trần 999.","Three supernatural cyan wind streams converging into a single falcon-shaped current above coastal cliffs.")
add(D.spectral,"spec_rethread","Hoán Y","Hoán đổi toàn bộ trang bị và cường hóa giữa lá chọn và lá khác đầu tiên trên tay. Rank, chất, con dấu, ấn bản và tiến hóa giữ nguyên; trả 2 Vàng.","Two spectral expedition figures exchanging their armors through a single violet loom.")
add(D.spectral,"spec_keystone","Trụ Bát","Chọn lá có ấn bản: xóa ấn bản, đổi rank thành 8 và nhận vĩnh viễn +20 ST cơ bản; giữ chất, dấu, trang bị và tiến hóa.","One supernatural eight-sided foundation monolith consuming a shimmering surface layer in a desert.")
add(D.spectral,"spec_heritage","Di Sản","Chuyển tối đa 3 cấp tiến hóa vĩnh viễn từ lá khác đã tiến hóa đầu tiên trên tay sang lá chọn; không vượt trần. Trả 3 HP, cần hơn 3 HP.","A spectral elder transferring three large green flames to an expedition successor in forest ruins.")
add(D.spectral,"spec_synthesis","Luyện Chất","Chọn lá có cường hóa: xóa cường hóa để nhận vĩnh viễn +25 ST cơ bản; không xóa trang bị, dấu, ấn bản hay tiến hóa.","One supernatural alchemist condensing an enchanted stone skin into a single dense gold core.")
add(D.spectral,"spec_shrink","Giải Phóng Vương Quyền","Tiêu hủy lá J/Q/K được chọn để tăng vĩnh viễn 1 kích thước tay; giảm 10 HP tối đa (tối thiểu còn 25), HP hiện tại không vượt trần mới. Không dùng với lá cuối bộ bài.","A spectral crown dissolving and releasing a broad flock of expedition silhouettes into the open sky.")
add(D.spectral,"spec_sieve","Sàng Mệnh","Chọn một lá: tiêu hủy tối đa 2 lá khác chất có rank thấp nhất trong bộ bài, thêm vĩnh viễn 1 lượt bỏ bài mỗi trận. Trả 8 Vàng; phải có ít nhất một mục tiêu hủy.","A supernatural sieve filtering two dark stone fragments away from a green continental river.")
add(D.spectral,"spec_traverse","Mượn Đường","Chọn một lá: nhận rank của lá thấp rank nhất khác trên tay và chất của lá cao rank nhất khác trên tay. Hòa rank chọn trái nhất; trả 2 Vàng, giữ mọi nâng cấp.","A spectral traveler crossing a low forest bridge and a high glacial arch through one violet doorway.")
add(D.spectral,"spec_rebirth","Tái Sinh Đối Ảnh","Tiêu hủy lá chọn, tạo lá mới cùng chất với rank 16 trừ rank cũ và tiến hóa +1 cấp (tối đa trần). Lá mới mất toàn bộ trang bị, dấu, cường hóa, ấn bản và tốc thưởng; ID mới.","One supernatural ash silhouette dissolving while its inverted green reflection awakens as a new traveler.")

function D.discard(g,cards)
    g.depthCombat=g.depthCombat or {values={}};local s=state(g)
    s.discarded=(s.discarded or 0)+#cards
    for k in pairs(s.values or {}) do if k:match(":quiet$") then s.values[k]=0 end end
    for _,c in ipairs(cards) do
        for _,eq in ipairs(c.equipments or {}) do
            if eq.id=="itm_capacitor" then set(g,c,"charge",math.min(3,value(g,c,"charge")+1))
            elseif eq.id=="itm_bloodvial" and value(g,c,"drops")<3 and (g.playerHp or 0)>2 then g.playerHp=g.playerHp-2;set(g,c,"drops",value(g,c,"drops")+1) end
        end
        if c.seal=="seal_echoes" then
            s.suitMarks=s.suitMarks or {};s.suitMarks[c.suit]=true
        elseif c.seal=="seal_reclaimer" and #cards==1 and value(g,c,"reclaim")==0 and spend(g,"gold",2) then
            g.discardsRemaining=(g.discardsRemaining or 0)+1;set(g,c,"reclaim",1)
        elseif c.seal=="seal_pact" and value(g,c,"deposit")<3 and spend(g,"gold",1) then set(g,c,"deposit",value(g,c,"deposit")+1) end
    end
    local distinct={};for _,c in ipairs(cards) do distinct[c.rank]=true end
    local n=0;for _ in pairs(distinct) do n=n+1 end
    if #cards==3 and n==3 then
        for _,spn in pairs(g.deities or {}) do if spn.enchantment=="spell_magnet" then
            for _,c in ipairs(g.hand or {}) do require("src.deck").applyAttackSpeedBonus(c,2) end
        end end
    end
end
function D.status(g,c)
    local lines={};local function line(label,n,cap) lines[#lines+1]=label..": "..n.." / "..cap end
    for _,eq in ipairs(c.equipments or {}) do
        if eq.id=="itm_capacitor" then line("Điện tích",value(g,c,"charge"),3)
        elseif eq.id=="itm_bloodvial" then line("Giọt huyết",value(g,c,"drops"),3)
        elseif eq.id=="itm_hourhand" then line("Đòn đã giữ",math.min(2,value(g,c,"heldHits")),2)
        elseif eq.id=="itm_bell" then line("Nhịp tĩnh",value(g,c,"quiet"),4)
        elseif eq.id=="itm_ledger" then line("Đầu tư lâu dài",c.depthInvestment or 0,5) end
    end
    if c.seal=="seal_threshold" then line("Nhịp hồi phục",value(g,c,"third"),3)
    elseif c.seal=="seal_pact" then line("Vàng đã gửi",value(g,c,"deposit"),3)
    elseif c.seal=="seal_echoes" then local n=0;for _ in pairs(state(g).suitMarks or {}) do n=n+1 end;line("Chất đã ghi chung",n,4) end
    return table.concat(lines,"\n")
end
function D.apply(g,d,c)
    if d.id:match("^spell_") then return nil end -- Shared SPN targeting lives in chest_expansion.
    if not d.id:match("^spec_") then return nil end
    if not c or c.destroyed then return false,"Chọn một lá hợp lệ." end
    local Deck=require("src.deck");local A=require("src.card_abilities");local cap=A.config.maxEvolutionLevel
    local id=d.id;local other,lowest,highest,donor
    for _,o in ipairs(g.hand or {}) do if o.id~=c.id and not o.destroyed then
        other=other or o;if not lowest or o.rank<lowest.rank then lowest=o end;if not highest or o.rank>highest.rank then highest=o end
        if not donor and (o.evolutionLevel or 0)>0 then donor=o end
    end end
    local function fail(text) return false,text end
    local function destroy(o) A.destroy(g,o);sync(g,o,function(v) v.destroyed=true;v.destructionNotified=true end) end
    if id=="spec_partition" then
        if c.rank<6 or not other then return fail("Cần rank từ 6 và một lá khác trên tay.") end
        if not spend(g,"gold",3) then return fail("Cần 3 Vàng.") end
        local rank=c.rank;Deck.transformCard(g,c,math.floor(rank/2));Deck.transformCard(g,other,math.ceil(rank/2))
    elseif id=="spec_consolidate" then
        local available=999-Deck.getCardAttackSpeed(c);local amount=0
        for _,o in ipairs(g.hand or {}) do if o.id~=c.id then amount=amount+(o.speedBonus or 0) end end
        amount=math.min(12,available,amount)
        if amount<=0 then return fail("Cần tốc thưởng ở lá khác và khoảng trống dưới trần 999.") end
        if not spend(g,"gold",4) then return fail("Cần 4 Vàng.") end
        local left=amount
        for _,o in ipairs(g.hand) do if o.id~=c.id then
            local n=math.min(left,o.speedBonus or 0);left=left-n
            sync(g,o,function(v) v.speedBonus=(v.speedBonus or 0)-n;Deck.getCardAttackSpeed(v) end)
        end end
        sync(g,c,function(v) Deck.applyAttackSpeedBonus(v,amount) end)
    elseif id=="spec_rethread" then
        if not other then return fail("Cần một lá khác trên tay.") end
        if not spend(g,"gold",2) then return fail("Cần 2 Vàng.") end
        local a,b=c.equipments or {},other.equipments or {};local ea,eb=c.enhancement,other.enhancement
        local function copy(eq) local list={};for _,v in ipairs(eq) do list[#list+1]=v end;return list end
        sync(g,c,function(v) v.equipments=copy(b);v.enhancement=eb end)
        sync(g,other,function(v) v.equipments=copy(a);v.enhancement=ea end)
    elseif id=="spec_keystone" or id=="spec_synthesis" then
        if id=="spec_keystone" and not (c.edition or c.visualEffect) then return fail("Cần một ấn bản.") end
        if id=="spec_synthesis" and not c.enhancement then return fail("Cần một cường hóa.") end
        if id=="spec_keystone" then Deck.transformCard(g,c,8) end
        sync(g,c,function(v)
            if id=="spec_keystone" then v.edition=nil;v.visualEffect=nil else v.enhancement=nil end
            local n=id=="spec_keystone" and 20 or 25;v.bonusBaseChips=(v.bonusBaseChips or 0)+n;v.baseChips=v.baseChips+n
        end)
    elseif id=="spec_heritage" then
        local n=donor and math.min(3,donor.evolutionLevel,cap-(c.evolutionLevel or 0)) or 0
        if n<=0 then return fail("Cần lá khác đã tiến hóa và lá nhận chưa đạt trần.") end
        if (g.playerHp or 0)<=3 then return fail("Cần hơn 3 HP.") end
        g.playerHp=g.playerHp-3;A.upgrade(g,donor,-n,false);A.upgrade(g,c,n,false)
    elseif id=="spec_shrink" then
        if c.rank<11 or c.rank>13 or #(g.persistentDeck or {})<2 or (g.maxPlayerHp or 100)<35 then return fail("Cần J/Q/K, còn lá khác và ít nhất 35 HP tối đa.") end
        destroy(c);g.maxHandSize=(g.maxHandSize or 3)+1;g.maxPlayerHp=g.maxPlayerHp-10;g.playerHp=math.min(g.playerHp,g.maxPlayerHp)
    elseif id=="spec_sieve" then
        local victims={};for _,o in ipairs(g.persistentDeck or {}) do if o.id~=c.id and o.suit~=c.suit and not o.destroyed then victims[#victims+1]=o end end
        table.sort(victims,function(a,b) if a.rank==b.rank then return a.id<b.id end;return a.rank<b.rank end)
        if #victims==0 then return fail("Không có lá khác chất để tiêu hủy.") end
        if not spend(g,"gold",8) then return fail("Cần 8 Vàng.") end
        for i=1,math.min(2,#victims) do destroy(victims[i]) end
        g.maxDiscards=(g.maxDiscards or 3)+1;g.discardsRemaining=(g.discardsRemaining or 0)+1
    elseif id=="spec_traverse" then
        if not lowest then return fail("Cần một lá khác trên tay.") end
        if not spend(g,"gold",2) then return fail("Cần 2 Vàng.") end
        Deck.transformCard(g,c,lowest.rank,highest.suit)
    elseif id=="spec_rebirth" then
        local fresh=Deck.newCard(16-c.rank,c.suit);fresh.evolutionLevel=math.min(cap,(c.evolutionLevel or 0)+1)
        destroy(c);Deck.addCardToDeck(g,fresh)
    end
    require("src.combat").cleanupDestroyedCards(g)
    g.selectedIndices={};for i,o in ipairs(g.hand or {}) do if o.selected then g.selectedIndices[#g.selectedIndices+1]=i end end
    return true,"Đã dùng "..d.name.."."
end
return D
