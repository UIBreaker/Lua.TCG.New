-- Forty continental discoveries. Catalogs and runtime share these definitions.
local X = {equipment={}, seals={}, spectral={}, spells={}, byId={}}
local function add(list,id,name,desc,concept,effect)
    local d={id=id,name=name,subtitle=name,desc=desc,artConcept=concept,icon="✦",
        color={0.66,0.76,0.88,1},params={},effect=effect}
    list[#list+1]=d;X.byId[id]=d
    return d
end
local function game(ctx) return ctx and (ctx.gameState or ctx) or {} end
local function suits(cards)
    local seen,n={},0
    for _,c in ipairs(cards) do if not seen[c.suit] then seen[c.suit]=true;n=n+1 end end
    return n
end
local function faces(cards)
    local n=0;for _,c in ipairs(cards) do if c.rank>=11 and c.rank<=13 then n=n+1 end end;return n
end
local function parity(cards)
    local n=0;for _,c in ipairs(cards) do if c.rank%2==0 then n=n+1 end end
    return n>0 and n*2==#cards
end
add(X.equipment,"itm_abacus","Bàn Tính Tân Binh","Rank 2–5 tính điểm: +8 ST cho mỗi bậc thấp hơn 6.","An antique expedition abacus with four large bone beads, fossil desert.",function(c)
    if c.rank<=5 then return {addChips=8*(6-c.rank)} end
end)
add(X.equipment,"itm_twinfang","Nanh Song Sinh","Có đúng một lá khác cùng rank tính điểm: +0.25 hệ số Aura (cộng vào trần ×5).","One tangible double-fanged silver dagger reflected in a glacial lake.",function(c,cs)
    local n=0;for _,o in ipairs(cs) do if o.rank==c.rank then n=n+1 end end
    if n==2 then return {xMultBonus=0.25} end
end)
add(X.equipment,"itm_wayfarer","La Bàn Lữ Hành","Lá tính điểm ngay trước lệch đúng 1 rank: +7 Cường hóa.","A weathered brass trail compass pointing along ascending mountain stepping stones.",function(c,cs,i)
    if cs[i-1] and math.abs(cs[i-1].rank-c.rank)==1 then return {addMult=7} end
end)
add(X.equipment,"itm_prism","Lăng Kính Viễn Chinh","Vùng tính điểm có ít nhất 3 chất: +35 ST.","One broad triangular glass prism splitting restrained light above coastal ruins.",function(c,cs)
    if suits(cs)>=3 then return {addChips=35} end
end)
add(X.equipment,"itm_hourglass","Cát Chậm","Tốc đánh lá này thấp hơn quái mục tiêu: +9 Giáp khi tính điểm.","A heavy physical hourglass frozen inside glacial blue ice.",function(c,cs,i,ctx)
    local m=ctx and ctx.monster
    if m and require("src.deck").getCardAttackSpeed(c)<(m.attackSpeed or 1) then return {addArmor=9} end
end)
add(X.equipment,"itm_miser","Chìa Khóa Ngân Khố","Mỗi 8 Vàng đang giữ: +1 Cường hóa khi tính điểm, tối đa +8.","One antique gold vault key over a weathered expedition coin chest in a desert.",function(c,cs,i,ctx)
    return {addMult=math.min(8,math.floor((game(ctx).gold or 0)/8))}
end)
add(X.equipment,"itm_quiver","Ống Tên Dự Trữ","Mỗi lá giữ lại trên tay: +6 ST khi tính điểm, tối đa +36.","A tangible leather quiver with six broad arrow shafts in a quiet ancient forest.",function(c,cs,i,ctx)
    return {addChips=math.min(36,#((ctx and ctx.hand) or {})*6)}
end)
add(X.equipment,"itm_anvil","Đe Ba Khảm","Lá đã dùng đủ 3 hốc trang bị: +12% sát thương khi tính điểm.","One volcanic iron anvil with three large socketed relic stones and restrained orange embers.",function(c)
    if require("src.equipment").getUsedSlots(c)==3 then return {extraDamagePct=0.12} end
end)
add(X.equipment,"itm_crown","Vương Miện Độc Hành","Nếu lá này là J/Q/K duy nhất tính điểm: +12 ST và +1 Vàng.","A single worn Western iron crown on an isolated coastal throne.",function(c,cs)
    if c.rank>=11 and c.rank<=13 and faces(cs)==1 then return {addChips=12,addGold=1} end
end)
add(X.equipment,"itm_root","Rễ Hóa Thạch","Mỗi cấp tiến hóa của lá này: +10 ST khi tính điểm, tối đa +50.","A tangible fossilized root relic growing through five broad stone strata in a green canyon.",function(c)
    return {addChips=math.min(50,(c.evolutionLevel or 0)*10)}
end)
for _,d in ipairs(X.equipment) do
    d.rarity="uncommon";d.cost=6;d.slotsNeeded=1
    d.onCardScore=function(c,cs,i,ctx)
        if i==0 then return nil end -- These discoveries require a scoring card.
        local r=d.effect(c,cs,i,ctx);if r then r.message=d.name end;return r
    end
end

-- Seals occupy the existing single seal slot, and trigger once per scored card.
add(X.seals,"seal_seed","Ấn Nảy Mầm","Mỗi lần tính điểm: tăng vĩnh viễn 2 ST cơ bản, tối đa +20 từ ấn này; có hiệu lực từ lần sau.","A large seed-shaped bronze stamp sprouting one green shoot from a stone tablet.",function(c,cs,i,ctx)
    local g=game(ctx)
    if not (ctx and ctx.preview) then
        local n=math.min(2,20-(c.seedChips or 0))
        if n>0 then X.sync(g,c,function(o) o.seedChips=(o.seedChips or 0)+n;o.bonusBaseChips=(o.bonusBaseChips or 0)+n;o.baseChips=(o.baseChips or 0)+n end) end
    end
    return {}
end)
add(X.seals,"seal_sunder","Ấn Phá Giáp","Khi tính điểm: phá 8 Giáp của quái mục tiêu trước khi gây Aura, không xuống dưới 0.","A heavy wedge-shaped stamp cracking an iron shield imprint in volcanic stone.",function(c,cs,i,ctx)
    if ctx and ctx.monster and not ctx.preview then ctx.monster.armor=math.max(0,(ctx.monster.armor or 0)-8) end
    return {}
end)
add(X.seals,"seal_mercy","Ấn Khoan Dung","Quái mục tiêu còn tối đa 25% HP khi tính điểm: hồi 6 HP.","A bronze open-palm stamp sheltering a small wounded spectral creature on a forest tablet.",function(c,cs,i,ctx)
    local m=ctx and ctx.monster
    if m and m.hp<=(m.maxHp or m.hp)*0.25 then return {healHp=6} end
end)
add(X.seals,"seal_reserve","Ấn Tiếp Tế","Giữ ít nhất 2 tiêu hao khi tính điểm: +1 Vàng.","A large supply-crate stamp beside two sealed expedition vials on coastal rock.",function(c,cs,i,ctx)
    if #(game(ctx).consumables or {})>=2 then return {addGold=1} end
end)
add(X.seals,"seal_pilgrim","Ấn Hành Hương","Mỗi lá khác đã tiến hóa trong vùng tính điểm: +2 Cường hóa, tối đa +8.","A bronze footprint stamp crossing a trail of awakened forest monoliths.",function(c,cs)
    local n=0;for _,o in ipairs(cs) do if o~=c and (o.evolutionLevel or 0)>0 then n=n+1 end end
    return {addMult=math.min(8,n*2)}
end)
add(X.seals,"seal_oath","Ấn Tuyên Thệ","HP ít nhất 75% tối đa khi tính điểm: trả 2 HP để nhận 10 Giáp.","A large shield-and-droplet oath stamp on a glacial altar, controlled red accent.",function(c,cs,i,ctx)
    local g=game(ctx)
    if (g.playerHp or 0)>=(g.maxPlayerHp or 100)*0.75 then return {hpCost=2,addArmor=10} end
end)
add(X.seals,"seal_equilibrium","Ấn Cân Bằng","Vùng tính điểm có số lá rank chẵn và lẻ bằng nhau: +30 ST.","A large balance-scale stamp with two equal stone weights in bone-colored desert ruins.",function(c,cs)
    if parity(cs) then return {addChips=30} end
end)
add(X.seals,"seal_harvest","Ấn Mùa Gặt","Đúng 5 lá tính điểm đều là rank 2–10: +2 Vàng.","A broad wheat-sheaf stamp with five clear stalks in an ancient green plain.",function(c,cs)
    if #cs~=5 then return end
    for _,o in ipairs(cs) do if o.rank<2 or o.rank>10 then return end end
    return {addGold=2}
end)
add(X.seals,"seal_dusk","Ấn Hoàng Hôn","Khi còn tối đa 1 lượt đánh: +20% sát thương khi tính điểm.","One setting-sun bronze stamp beneath an orange twilight over continental cliffs.",function(c,cs,i,ctx)
    local n=game(ctx).handsRemaining
    if n and n<=1 then return {extraDamagePct=0.2} end
end)
add(X.seals,"seal_lantern","Ấn Hải Đăng","Mỗi lá cùng rank giữ lại trên tay: +20 ST khi tính điểm, tối đa +60.","A lighthouse-shaped stamp casting three broad beams into a deep navy sea.",function(c,cs,i,ctx)
    local n=0;for _,o in ipairs(ctx and ctx.hand or {}) do if o.rank==c.rank then n=n+1 end end
    return {addChips=math.min(60,n*20)}
end)
for _,d in ipairs(X.seals) do d.sealType=d.id;d.sealName=d.name end

add(X.spectral,"spec_stairway","Bậc Thang Hư Ảnh","Chọn một lá: đổi tối đa 4 lá khác trên tay thành rank kế tiếp của nó (không vượt A), lần lượt theo thứ tự tay. Trả 4 HP.","A supernatural staircase of five spectral stone slabs ascending into a violet eclipse.")
add(X.spectral,"spec_twin","Giao Ước Song Sinh","Chọn một lá: lá khác đầu tiên trên tay nhận cùng rank, giữ chất và mọi nâng cấp. Trả 3 Vàng.","Two distinct spectral silhouettes bound by one violet thread above a cold coast.")
add(X.spectral,"spec_molt","Lột Xác","Chọn một lá đã tiến hóa: mất 1 cấp tiến hóa, nhận vĩnh viễn +8 tốc đánh (tối đa 999).","A spectral moth shedding one stone cocoon into cyan wind over forest ruins.")
add(X.spectral,"spec_prune","Tỉa Nhánh","Chọn một lá: tiêu hủy tối đa 2 lá khác cùng rank trong bộ bài; lá chọn nhận +10 ST cơ bản mỗi lá hủy. Luôn giữ ít nhất 1 lá.","A supernatural pruning shadow drawing strength from two fading branches into one living tree.")
add(X.spectral,"spec_migration","Đại Di Cư","Chọn một lá: mọi lá cùng rank trong bộ bài đổi sang chất tiếp theo trong vòng Cơ–Rô–Chuồn–Bích. Trả 4 Vàng.","A flock of spectral birds crossing from a green continent into glacial cliffs.")
add(X.spectral,"spec_inversion","Nghịch Số","Chọn một lá: đổi rank thành 16 trừ rank hiện tại (2↔A, 3↔K, 8 giữ nguyên); trả 2 HP.","A supernatural inverted mountain mirrored beneath a violet rift, two opposing peaks.")
add(X.spectral,"spec_temper","Tôi Luyện","Chọn một lá có trang bị: tháo trang bị cuối cùng, đổi lấy 2 cấp tiến hóa vĩnh viễn. Không dùng nếu vượt trần tiến hóa.","A spectral forge spirit consuming one iron relic to awaken a floating stone figure.")
add(X.spectral,"spec_fission","Phân Hạch","Chọn một lá rank 4–A: giảm rank đi 2, thêm một lá rank 2 cùng chất vào bộ bài; lá mới không mang nâng cấp.","One supernatural crystal splitting into a large shard and one tiny shard over volcanic wastes.")
add(X.spectral,"spec_redistribute","Hoán Mạch","Chọn một lá: hoán đổi chất với lá khác đầu tiên trên tay có chất khác, giữ nguyên rank và nâng cấp.","Two supernatural rivers exchanging their paths through a single suspended violet junction.")
add(X.spectral,"spec_distill","Chưng Cất","Chọn một lá có con dấu: xóa dấu, nhận vĩnh viễn +1 cấp tiến hóa và +4 tốc đánh. Không dùng ở trần tiến hóa.","A spectral seal dissolving into a single green-gold drop above an ancient forest altar.")

-- One enchantment per SPN; independent of edition and evolution. Once per hand.
add(X.spells,"spell_bastion","Phù Phép Thành Lũy","SPN đầu tiên nhận Thành Lũy: vùng tính điểm có ít nhất 4 lá thì +8 Giáp mỗi tay.","A supernatural guardian forming four broad stone walls around an expedition camp.",function(h,g)
    if #h.scoringCards>=4 then return {addArmor=8} end
end)
add(X.spells,"spell_mend","Phù Phép Giao Hòa","SPN đầu tiên nhận Giao Hòa: vùng tính điểm có đúng 2 chất thì hồi 4 HP mỗi tay.","A spectral forest healer joining two streams of blue and green light into one living spring.",function(h,g)
    if suits(h.scoringCards)==2 then return {healHp=4} end
end)
add(X.spells,"spell_prosper","Phù Phép Khởi Nghiệp","SPN đầu tiên nhận Khởi Nghiệp: khi giữ dưới 10 Vàng thì nhận 2 Vàng mỗi tay.","A small supernatural gold fox breathing life into an empty desert trading stall.",function(h,g)
    if (g.gold or 0)<10 then return {addGold=2} end
end)
add(X.spells,"spell_solitude","Phù Phép Độc Tôn","SPN đầu tiên nhận Độc Tôn: nếu chỉ sở hữu 1 SPN thì +0.4 hệ số Aura mỗi tay (cộng vào trần ×5).","One enormous solitary spectral titan beneath a violet eclipse above empty cliffs.",function(h,g)
    if require("src.deities").getCount(g.deities)==1 then return {xMultBonus=0.4} end
end)
add(X.spells,"spell_confluence","Phù Phép Hội Tụ","SPN đầu tiên nhận Hội Tụ: khi đánh Thùng hoặc Thùng Phá Sảnh, +10 Cường hóa mỗi tay.","A single ocean spirit formed by five navy waves merging into one clear vortex.",function(h,g)
    if h.type.id=="flush" or h.type.id=="straight_flush" then return {addMult=10} end
end)
add(X.spells,"spell_ladder","Phù Phép Dẫn Lối","SPN đầu tiên nhận Dẫn Lối: Sảnh hoặc Thùng Phá Sảnh nhận +60 ST mỗi tay.","A spectral mountain guide illuminating a clear ascending path between five glacial peaks.",function(h,g)
    if h.type.id=="straight" or h.type.id=="straight_flush" then return {addChips=60} end
end)
add(X.spells,"spell_requiem","Phù Phép Tinh Giản","SPN đầu tiên nhận Tinh Giản: bộ bài vĩnh viễn còn tối đa 15 lá thì +10 Cường hóa mỗi tay.","A spectral archivist gathering a dwindling cloud of stone fragments into one violet orb.",function(h,g)
    if #(g.persistentDeck or {})<=15 then return {addMult=10} end
end)
add(X.spells,"spell_chorus","Phù Phép Hợp Xướng","SPN đầu tiên nhận Hợp Xướng: mỗi SPN khác đang sở hữu cho +12 ST mỗi tay, tối đa +48.","One spectral conductor directing four large ghostly echoes in a Western ruined amphitheater.",function(h,g)
    return {addChips=math.min(48,math.max(0,require("src.deities").getCount(g.deities)-1)*12)}
end)
add(X.spells,"spell_balance","Phù Phép Trăng Non","SPN đầu tiên nhận Trăng Non: đánh đúng 1 lá rank 2–7 thì +0.35 hệ số Aura mỗi tay (cộng vào trần ×5).","A small crescent-shaped supernatural guardian sheltering a lone traveler in a navy desert night.",function(h,g)
    if #h.scoringCards==1 and h.scoringCards[1].rank<=7 then return {xMultBonus=0.35} end
end)
add(X.spells,"spell_ember","Phù Phép Tàn Hỏa","SPN đầu tiên nhận Tàn Hỏa: HP còn tối đa 25% thì +25% sát thương và hồi 2 HP mỗi tay.","A wounded spectral phoenix rekindling from one restrained orange ember in dark volcanic wastes.",function(h,g)
    if (g.playerHp or 100)<=(g.maxPlayerHp or 100)*0.25 then return {extraDamagePct=0.25,healHp=2} end
end)

function X.sync(g,c,fn)
    local seen={}
    local function update(o) if not seen[o] then seen[o]=true;fn(o) end end
    update(c)
    for _,pile in ipairs({g.persistentDeck or {},g.hand or {},g.deck or {},g.discardPile or {}}) do
        for _,o in ipairs(pile) do if c.id and o.id==c.id then update(o) end end
    end
end
function X.apply(g,item,target)
    local d=X.byId[item.id]
    if not d then return nil end
    if item.id:match("^spell_") then
        local slots={};for k,v in pairs(g.deities or {}) do if type(k)=="number" and type(v)=="table" then slots[#slots+1]=k end end
        table.sort(slots)
        if #slots==0 then return false,"Cần ít nhất một SPN để phù phép." end
        g.deities[slots[1]].enchantment=d.id
        return true,"Đã phù phép "..g.deities[slots[1]].name..": "..d.name.." (thay phù phép cũ, giữ ấn bản)."
    end
    if d.depth then return require("src.chest_depth").apply(g,d,target) end
    if not item.id:match("^spec_") then return nil end
    if not target or target.destroyed then return false,"Hãy chọn một lá bài hợp lệ." end
    local Deck=require("src.deck");local A=require("src.card_abilities");local id=d.id
    local function payGold(n) if (g.gold or 0)<n then return false end;g.gold=g.gold-n;return true end
    local function payHp(n) if (g.playerHp or 100)<=n then return false end;g.playerHp=(g.playerHp or 100)-n;return true end
    local other
    for _,c in ipairs(g.hand or {}) do if c.id~=target.id and not c.destroyed and (id~="spec_redistribute" or c.suit~=target.suit) then other=c;break end end
    if id=="spec_stairway" then
        if not other then return false,"Cần ít nhất 2 lá trên tay." end
        if not payHp(4) then return false,"Cần hơn 4 HP." end
        local n=0;for _,c in ipairs(g.hand) do if c.id~=target.id and n<4 then n=n+1;Deck.transformCard(g,c,math.min(14,target.rank+n)) end end
    elseif id=="spec_twin" then
        if not other then return false,"Cần một lá khác trên tay." end
        if not payGold(3) then return false,"Cần 3 Vàng." end
        Deck.transformCard(g,other,target.rank)
    elseif id=="spec_molt" then
        if (target.evolutionLevel or 0)<1 then return false,"Lá phải đã tiến hóa." end
        A.upgrade(g,target,-1,false);X.sync(g,target,function(c) Deck.applyAttackSpeedBonus(c,8) end)
    elseif id=="spec_prune" then
        local victims={};for _,c in ipairs(g.persistentDeck or {}) do if c.id~=target.id and c.rank==target.rank and #victims<2 then victims[#victims+1]=c end end
        if #victims==0 then return false,"Không có lá khác cùng rank trong bộ bài." end
        for _,c in ipairs(victims) do
            A.destroy(g,c)
            X.sync(g,c,function(o) o.destroyed=true;o.destructionNotified=true end)
        end
        require("src.combat").cleanupDestroyedCards(g)
        X.sync(g,target,function(c) c.bonusBaseChips=(c.bonusBaseChips or 0)+10*#victims;c.baseChips=c.baseChips+10*#victims end)
        g.selectedIndices={};for i,c in ipairs(g.hand or {}) do if c.selected then g.selectedIndices[#g.selectedIndices+1]=i end end
    elseif id=="spec_migration" then
        if not payGold(4) then return false,"Cần 4 Vàng." end
        local suit=target.suit;local standard=({valoria="hearts",aurelia="diamonds",elaris="clubs",vharos="spades"})[suit] or suit
        local order={"hearts","diamonds","clubs","spades"};local nextSuit
        for i,s in ipairs(order) do if s==standard then nextSuit=order[i%4+1] end end
        nextSuit=nextSuit or "hearts"
        local rank=target.rank;for _,c in ipairs(g.persistentDeck or {}) do if c.rank==rank then Deck.transformCard(g,c,nil,nextSuit) end end
    elseif id=="spec_inversion" then
        if not payHp(2) then return false,"Cần hơn 2 HP." end
        Deck.transformCard(g,target,16-target.rank)
    elseif id=="spec_temper" then
        local eq=target.equipments or {}
        if #eq==0 then return false,"Lá phải có trang bị." end
        if (target.evolutionLevel or 0)+2>require("config.card_ability_data").maxEvolutionLevel then return false,"Vượt trần tiến hóa." end
        X.sync(g,target,function(c) table.remove(c.equipments) end);A.upgrade(g,target,2,false)
    elseif id=="spec_fission" then
        if target.rank<4 then return false,"Cần rank ít nhất 4." end
        Deck.transformCard(g,target,target.rank-2);Deck.addCardToDeck(g,Deck.newCard(2,target.suit))
    elseif id=="spec_redistribute" then
        if not other then return false,"Cần một lá khác chất trên tay." end
        local suit=target.suit;Deck.transformCard(g,target,nil,other.suit);Deck.transformCard(g,other,nil,suit)
    elseif id=="spec_distill" then
        if not target.seal then return false,"Lá phải có con dấu." end
        if (target.evolutionLevel or 0)>=require("config.card_ability_data").maxEvolutionLevel then return false,"Đã đạt trần tiến hóa." end
        X.sync(g,target,function(c) c.seal=nil;c.isAnchor=false;Deck.applyAttackSpeedBonus(c,4) end);A.upgrade(g,target,1,false)
    end
    return true,"Đã dùng "..d.name.."."
end
for id,d in pairs(require("src.chest_depth").byId) do X.byId[id]=d end
return X
