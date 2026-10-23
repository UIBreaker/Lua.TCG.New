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
local function key(c,id,ctx) return tostring(c.id)..(ctx and ctx.equipmentIndex and (":itm"..ctx.equipmentIndex) or "")..":"..id end
local function value(g,c,id,ctx) return (state(g).values or {})[key(c,id,ctx)] or 0 end
local function set(g,c,id,n,ctx)
    if ctx and ctx.preview and not ctx.depthGame then return end
    g.depthCombat=g.depthCombat or {values={},seen={}}
    g.depthCombat.values=g.depthCombat.values or {};g.depthCombat.values[key(c,id,ctx)]=n
end
local function once(ctx,c,id)
    if not ctx then return false end
    if ctx.equipmentRetrigger and ctx.equipmentIndex then return true end
    local g=game(ctx);local s=ctx.preview and ctx or state(g)
    s.depthSeen=s.depthSeen or {};local k=key(c,id,ctx)
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
    ctx.depthInvestments={}
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
    for _,c in ipairs(g.hand or {}) do
        for index,eq in ipairs(c.equipments or {}) do if eq.id=="itm_hourhand" then
            local ctx={equipmentIndex=index};set(g,c,"heldHits",value(g,c,"heldHits",ctx)+1,ctx)
        end end
    end
end
add(D.equipment,"itm_capacitor","Bình Tích Sét","Bỏ lá này: tích 1 điện, tối đa 3. Khi tính điểm: xả toàn bộ, mỗi điện +18 ST và +3 Cường hóa. Điện mất khi hết trận.","A physical copper lightning jar with three large charge chambers on a navy cliff.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"charge",ctx);set(g,c,"charge",0,ctx);return {addChips=18*n,addMult=3*n}
end)
add(D.equipment,"itm_counterweight","Rìu Phản Lực","Tính điểm sau khi bị quái gây mất HP từ lần đánh trước: +1.5% sát thương mỗi HP mất, tối đa 30%; không tính HP tự trả.","A physical iron counterweight axe swinging back from an impact in volcanic ruins.",function(c,cs,i,ctx)
    return {extraDamagePct=math.min(0.3,(state(game(ctx)).damage or 0)*0.015)}
end)
add(D.equipment,"itm_ledger","Sổ Giao Kèo","Khi tính điểm: tự trả 1 Vàng để đầu tư 1 nấc, tối đa 5 nấc vĩnh viễn trên lá. Mỗi nấc cho +3 Cường hóa, kể cả khi không đủ Vàng.","A tangible five-clasp leather ledger with a gold coin pressed into its cover in desert ruins.",function(c,cs,i,ctx)
    local g=game(ctx);ctx.depthInvestments=ctx.depthInvestments or {}
    local n=ctx.preview and ctx.depthInvestments[c.id] or nil
    n=n or c.depthInvestment or 0
    if n<5 and spend(g,"gold",1,ctx) then n=n+1;if not ctx.preview then sync(g,c,function(o) o.depthInvestment=n end) end end
    if ctx.preview then ctx.depthInvestments[c.id]=n end
    return {addMult=n*3}
end)
add(D.equipment,"itm_oar","Mái Chèo Chuyển Dòng","Khi tính điểm trong thế đánh khác lần đánh trước của trận: +20 ST và +4 Giáp. Không kích hoạt ở tay đầu.","A tangible expedition oar cutting across two opposing blue currents below coastal cliffs.",function(c,cs,i,ctx)
    local s=state(game(ctx));if s.lastType and s.lastType~=ctx.depthHandType then return {addChips=20,addArmor=4} end
end)
add(D.equipment,"itm_hourhand","Kim Đồng Hồ Canh Gác","Giữ lá này qua 2 đòn quái: lần tính điểm sau nhận +14 Cường hóa và xóa số đòn đã giữ; chỉ tính đòn quái thực sự ra tay.","One tangible silver clock hand braced against two frozen impact rings on a glacial monolith.",function(c,cs,i,ctx)
    local g=game(ctx);if value(g,c,"heldHits",ctx)>=2 then set(g,c,"heldHits",0,ctx);return {addMult=14} end
end)
add(D.equipment,"itm_bloodvial","Lọ Huyết Tế","Bỏ lá này khi còn hơn 2 HP: trả 2 HP, tích 1 giọt (tối đa 3). Khi tính điểm: xả giọt, mỗi giọt +7 Cường hóa. Mất giọt khi hết trận.","A physical red glass vial with three large blood drops over a volcanic expedition altar.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"drops",ctx);set(g,c,"drops",0,ctx);return {addMult=n*7}
end)
add(D.equipment,"itm_relay","Dây Xích Tiếp Sức","Nếu lá tính điểm ngay trước có trang bị: nhận thêm ST bằng một nửa ST cơ bản của lá trước (làm tròn xuống), tối đa 60.","A physical broad iron chain connecting two expedition weapon hilts in a forest workshop.",function(c,cs,i)
    local p=cs[i-1];if p and #(p.equipments or {})>0 then return {addChips=math.min(60,math.floor(require("src.deck").getCardDamage(p)/2))} end
end)
add(D.equipment,"itm_lockbox","Khóa Giáp Ngân","Khi tính điểm và đang có ít nhất 8 Giáp: tiêu 8 Giáp để +20% sát thương. Giáp đã tiêu không chặn đòn quái sau đó.","One physical silver shield-lock opening and releasing a controlled gold beam from glacial armor.",function(c,cs,i,ctx)
    local g=game(ctx);if spend(g,"playerArmor",8,ctx) then if not ctx.preview then g.playerShield=g.playerArmor end;return {extraDamagePct=0.2} end
end)
add(D.equipment,"itm_bell","Chuông Tĩnh Lặng","Mỗi lần lá tính điểm mà chưa bỏ bài từ lần đánh trước: tích 1 nhịp (tối đa 4), +5 Cường hóa mỗi nhịp. Bất kỳ lần bỏ bài nào xóa nhịp của mọi lá mang chuông.","A tangible silent bronze bell wrapped in cloth above a quiet forest sanctuary.",function(c,cs,i,ctx)
    local g=game(ctx);local n=value(g,c,"quiet",ctx)
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
add(D.seals,"seal_echoes","Ấn Tứ Phương","Mỗi lá mang ấn còn giữ trên tay nhân đôi Cường hóa của tay đánh. Lá đã đánh ra không kích hoạt.","A large four-direction compass stamp gathering four controlled elemental trails on coastal stone.")
add(D.seals,"seal_reclaimer","Ấn Thu Hồi","Bỏ lá mang ấn: +4 Vàng mỗi lá, không cần bỏ riêng và không giới hạn số lần trong trận.","One circular return-arrow stamp reclaiming a coin from a stone slot in a desert.")
add(D.seals,"seal_gambit","Ấn Đổi Lượt","Bỏ bài chỉ gồm các lá mang ấn: không mất lượt bỏ bài và vẫn được dùng khi đã hết lượt bỏ. Bỏ kèm lá khác vẫn mất một lượt.","A large five-spoked turnwheel stamp with a single controlled red flame over volcanic stone.")
add(D.seals,"seal_threshold","Ấn Tam Nhịp","Mỗi lá mang ấn được tính điểm tổng cộng 3 lần (hai lần thêm), hồi 3 HP mỗi lá. Không yêu cầu tích nhịp qua nhiều tay.","A large three-step heartbeat stamp with three broad grooves in a green forest altar.",function() return {healHp=3} end)
for _,d in ipairs(D.seals) do d.sealType=d.id;d.sealName=d.name;d.effect=d.effect or function() end end

add(D.spells,"spell_retinue","Phù Phép Bách Khí","Mỗi loại ITM khác nhau trên các lá tính điểm: tăng 10% ST sau SPN, tối đa 50% từ mỗi phép. Tổng tăng ST từ phù phép tối đa +200%.","One supernatural armory guardian surrounded by six large distinct spectral weapons in a ruined Western forge.",function(h)
    local ids,n={},0
    for _,c in ipairs(h.scoringCards) do for _,eq in ipairs(c.equipments or {}) do if not ids[eq.id] then ids[eq.id]=true;n=n+1 end end end
    if n>0 then return {addChipsPct=math.min(50,n*10)} end
end)
add(D.spells,"spell_switchcraft","Phù Phép Biến Thế","Đổi sang thế Poker khác tay trước của trận: tăng 50% Cường hóa sau SPN. Tay đầu không kích hoạt; tổng tăng Cường hóa từ phù phép tối đa +200%.","One supernatural blade spirit shifting between paired blades and a long glacial spear.",function(h,g)
    local last=state(g).lastType
    if last and last~=h.type.id then return {addMultPct=50} end
end)
for _,d in ipairs(D.spells) do d.isEnchantment=true;d.cost=4 end

for _,id in ipairs({"spec_rethread","spec_shrink"}) do
    local d=require("src.spectral").get(id);D.spectral[#D.spectral+1]=d;D.byId[id]=d
end

function D.discard(g,cards,context)
    g.depthCombat=g.depthCombat or {values={}};local s=state(g)
    s.discarded=(s.discarded or 0)+#cards
    for k in pairs(s.values or {}) do if k:match(":quiet$") then s.values[k]=0 end end
    for _,c in ipairs(cards) do
        for index,eq in ipairs(c.equipments or {}) do
            local ctx={equipmentIndex=index}
            if eq.id=="itm_capacitor" then set(g,c,"charge",math.min(3,value(g,c,"charge",ctx)+1),ctx)
            elseif eq.id=="itm_bloodvial" and value(g,c,"drops",ctx)<3 and (g.playerHp or 0)>2 then g.playerHp=g.playerHp-2;set(g,c,"drops",value(g,c,"drops",ctx)+1,ctx) end
        end
        if require("src.deck").normalizeSeal(c.seal)=="seal_reclaimer" and not (context and context.preview) then
            g.gold=(g.gold or 0)+4*(c.sealPower or 1)
        end
    end

end
function D.status(g,c)
    local lines={};local function line(label,n,cap) lines[#lines+1]=label..": "..n.." / "..cap end
    for index,eq in ipairs(c.equipments or {}) do
        local ctx={equipmentIndex=index};local suffix=" · ITM "..index
        if eq.id=="itm_capacitor" then line("Điện tích"..suffix,value(g,c,"charge",ctx),3)
        elseif eq.id=="itm_bloodvial" then line("Giọt huyết"..suffix,value(g,c,"drops",ctx),3)
        elseif eq.id=="itm_hourhand" then line("Đòn đã giữ"..suffix,math.min(2,value(g,c,"heldHits",ctx)),2)
        elseif eq.id=="itm_bell" then line("Nhịp tĩnh"..suffix,value(g,c,"quiet",ctx),4)
        elseif eq.id=="itm_ledger" then line("Đầu tư lâu dài",c.depthInvestment or 0,5) end
    end
    return table.concat(lines,"\n")
end
function D.apply(g,d,request)
    if require("src.spectral").get(d.id) then return require("src.spectral").apply(g,d,request) end
    return nil
end
return D
