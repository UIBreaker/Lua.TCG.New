local R = {}
local summaries={
    soul_phoenix_lantern="Chặn chí tử, hồi 50% HP.\nMột lần/trận, khi giữ.",
    soul_frost_bell="Đóng băng 2 đòn địch.\nMột lần mỗi trận.",
    soul_rift_compass="Kéo lá rank cao nhất\nvào tay khi tính điểm.",
    soul_return_chain="Tính điểm xong,\ntrở lại tay.",
    soul_echo_mirror="Lá kề trái/phải\nkích hoạt thêm 2 lần.",
    soul_evolution_quill="Tiến hóa đồng đội ngẫu nhiên +1 khi tính điểm.",
    soul_silence_anchor="Khóa kỹ năng boss\nqua 2 tay bài kế tiếp.",
    soul_plague_chalice="Độc: 8% HP tối đa\nmỗi đòn, trong 3 đòn.",
    soul_reaper_contract="Mỗi địch chết +3 LH\nsau khi tính điểm.",
    soul_edition_prism="Đủ 3 chất: nâng ấn bản.\nMột lần mỗi trận.",
}
R.definitions = {
    {id="soul_phoenix_lantern",name="Đèn Tro Bất Diệt",cost=38,slotsNeeded=2,color={1,.6,.2,1},desc="Khi còn trên tay: chặn sát thương chí tử và hồi 50% máu tối đa. Một lần mỗi trận."},
    {id="soul_frost_bell",name="Chuông Đông Cứng",cost=34,slotsNeeded=2,color={.45,.85,1,1},desc="Khi tính điểm: đóng băng 2 đòn đánh địch kế tiếp. Một lần mỗi trận."},
    {id="soul_rift_compass",name="La Bàn Khe Nứt",cost=26,slotsNeeded=1,color={.35,.75,1,1},desc="Mỗi tay tính điểm: kéo lá rank cao nhất còn trong bộ vào tay, vượt giới hạn cầm bài."},
    {id="soul_return_chain",name="Xích Vòng Luân Hồi",cost=30,slotsNeeded=1,color={.8,.5,1,1},desc="Sau khi tính điểm: lá mang xích trở lại tay thay vì nằm trong cọc bỏ."},
    {id="soul_echo_mirror",name="Gương Song Vọng",cost=36,slotsNeeded=2,color={.55,.85,.95,1},desc="Mỗi tay tính điểm: tái kích hoạt 2 lần cho mỗi lá kề trái/phải trong vùng tính điểm."},
    {id="soul_evolution_quill",name="Bút Ký Khởi Nguyên",cost=40,slotsNeeded=2,color={.6,.95,.4,1},desc="Khi tính điểm: tiến hóa vĩnh viễn +1 cấp cho đồng đội ngẫu nhiên đang tính điểm."},
    {id="soul_silence_anchor",name="Neo Câm Lặng",cost=32,slotsNeeded=2,color={.65,.45,.95,1},desc="Khi tính điểm: tắt cả kỹ năng chủ động và nội tại boss thêm 2 tay bài kế tiếp. Từng món dùng một lần mỗi trận; nhiều món nối tiếp thời hạn."},
    {id="soul_plague_chalice",name="Chén Độc Vĩnh Dạ",cost=28,slotsNeeded=1,color={.4,.85,.3,1},desc="Khi tính điểm: đặt độc riêng của món này lên mục tiêu trong 3 đòn, mỗi đòn gây 8% máu tối đa địch. Nhiều món cộng dồn; chính món đó làm mới thời hạn."},
    {id="soul_reaper_contract",name="Khế Ước Người Gặt",cost=30,slotsNeeded=1,color={.85,.65,.95,1},desc="Sau lần tính điểm đầu: mỗi kẻ địch chết cho +3 linh hồn đến hết trận từ từng khế ước đã kích hoạt. Mỗi cái chết chỉ trả một lần."},
    {id="soul_edition_prism",name="Lăng Kính Hoàng Hôn",cost=42,slotsNeeded=2,color={1,.7,.55,1},desc="Tính điểm cùng ít nhất 3 chất: nâng ấn bản chính lá này vĩnh viễn, Thường → Foil → Holo → Poly. Một lần mỗi trận."},
}
for _,def in ipairs(R.definitions) do def.shopSummary=summaries[def.id] end
local function state(g)
    g.soulRelicCombat=g.soulRelicCombat or {used={},claimed={},freeze=0}
    return g.soulRelicCombat
end
local function report(g,card,eq,message,equipmentIndex)
    local ctx=g.abilityHand and not g.abilityHand.finished and g.abilityHand or g.abilityCombat
    if ctx then
        ctx.feedback=ctx.feedback or {}
        ctx.feedback[#ctx.feedback+1]={type="equipment_trigger",card=card,equipment=eq,equipmentIndex=equipmentIndex,message=eq.name.." · "..message,addedChips=0,addedMult=0}
    end
end
function R.score(g,card,ctx)
    if ctx.retrigger then return end
    ctx.soulRelics=ctx.soulRelics or {}
    local s=state(g)
    for equipmentIndex,eq in ipairs(card.equipments or {}) do
        local key=tostring(card.id or card)..":"..eq.id..":"..equipmentIndex
        if not ctx.soulRelics[key] then
            ctx.soulRelics[key]=true
            local id,message=eq.id,nil
            if id=="soul_frost_bell" and not s.used[key] then
                s.freeze=s.freeze+2;s.used[key]=true;message="ĐÓNG BĂNG 2 ĐÒN"
            elseif id=="soul_rift_compass" then
                local index
                for i,c in ipairs(g.deck or {}) do
                    if not c.destroyed and (not index or c.rank>g.deck[index].rank) then index=i end
                end
                if index then
                    local drawn=table.remove(g.deck,index)
                    drawn.selected=false;drawn.dealPending=true;drawn.visualX=1180;drawn.visualY=620
                    g.hand=g.hand or {};g.hand[#g.hand+1]=drawn;message="KÉO LÁ MẠNH NHẤT"
                end
            elseif id=="soul_return_chain" then
                ctx.returns[card.id]=true;message="TRỞ LẠI TAY"
            elseif id=="soul_echo_mirror" then
                local n=0
                for _,i in ipairs({ctx.index-1,ctx.index+1}) do
                    local other=ctx.scoring[i]
                    if other and not other.destroyed then require("src.card_abilities").repeatCard(g,other,2,ctx);n=n+1 end
                end
                if n>0 then message="VỌNG ÂM "..n.." LÁ KỀ" end
            elseif id=="soul_evolution_quill" then
                local Abilities=require("src.card_abilities")
                local target,candidates
                for _,other in ipairs(ctx.scoring) do
                    if other~=card and not other.destroyed and not other.exhausted and Abilities.definition(other)
                        and (other.evolutionLevel or 0)<Abilities.config.maxEvolutionLevel then
                        candidates=candidates or {};candidates[#candidates+1]=other
                    end
                end
                target=candidates and candidates[require("src.rng").random(#candidates)]
                if target and Abilities.upgrade(g,target,1,false) then message="TIẾN HÓA "..(target.rankName or "")..(target.suitSymbol or "").." · +1 CẤP"
                else message="CẦN ĐỒNG ĐỘI TÍNH ĐIỂM CHƯA ĐẠT TRẦN" end
            elseif id=="soul_silence_anchor" and not s.used[key] and require("src.boss_abilities").state(g.monster) then
                local Boss=require("src.boss_abilities");local bs=Boss.state(g.monster)
                local remaining=math.max(0,math.max(bs.passiveUntil or 0,bs.activeUntil or 0)-bs.handIndex)
                Boss.disable(g,remaining+2,true,true);s.used[key]=true;message="KHÓA KỸ NĂNG BOSS · +2 TAY"
            elseif id=="soul_plague_chalice" and g.monster and g.monster.hp>0 then
                g.monster.soulPoisonSources=g.monster.soulPoisonSources or {}
                g.monster.soulPoisonSources[key]=3;g.monster.soulPoisonTurns=3;message="ĐỘC RIÊNG · 3 ĐÒN · 8% HP"
            elseif id=="soul_reaper_contract" then
                s.reaperSources=s.reaperSources or {}
                if not s.reaperSources[key] then s.reaperSources[key]=true;message="MỖI KẺ ĐỊCH CHẾT +3 LH" end
            elseif id=="soul_edition_prism" and not s.used[key] then
                local suits,count={},0
                for _,other in ipairs(ctx.scoring) do
                    local d=require("src.card_abilities").definition(other)
                    local suit=d and d.suit or other.suit
                    if not suits[suit] then suits[suit]=true;count=count+1 end
                end
                local Effects=require("src.card_effects")
                local nextEdition=({normal="foil",foil="holographic",holographic="polychrome"})[Effects.getEffectName(card) or "normal"]
                if count>=3 and nextEdition then
                    Effects.setEffect(card,nextEdition)
                    for _,pile in ipairs({g.persistentDeck or {},g.hand or {},g.deck or {},g.discardPile or {}}) do
                        for _,copy in ipairs(pile) do if copy.id==card.id then Effects.setEffect(copy,nextEdition) end end
                    end
                    s.used[key]=true;message="ẤN BẢN → "..nextEdition
                end
            end
            if message then report(g,card,eq,message,equipmentIndex) end
        end
    end
end
function R.guard(g,damage)
    if damage<=0 or damage<(g.playerHp or 100) then return damage end
    local s=state(g)
    for _,card in ipairs(g.hand or {}) do
        if not card.destroyed then
            for equipmentIndex,eq in ipairs(card.equipments or {}) do
                local key=tostring(card.id or card)..":"..eq.id..":"..equipmentIndex
                if eq.id=="soul_phoenix_lantern" and not s.used[key] then
                    s.used[key]=true;g.playerHp=math.max(1,math.floor((g.maxPlayerHp or 100)*.5))
                    report(g,card,eq,"CHẶN CHÍ TỬ · HỒI SINH",equipmentIndex);return 0
                end
            end
        end
    end
    return damage
end
function R.reap(g)
    local s=state(g);local reward=0
    for _ in pairs(s.reaperSources or {}) do reward=reward+3 end
    if reward==0 then return end
    for i,enemy in ipairs(g.enemies or {g.monster}) do
        if enemy and enemy.hp<=0 and not s.claimed[i] then
            s.claimed[i]=true;g.souls=(g.souls or 0)+reward
            report(g,nil,{name="Khế Ước Người Gặt",id="soul_reaper_contract"},"+"..reward.." LH")
        end
    end
end
function R.beforeAttack(g,enemy)
    if (enemy.soulPoisonTurns or 0)>0 then
        local sources,remaining=0,0
        for key,turns in pairs(enemy.soulPoisonSources or {}) do if turns>0 then
            sources=sources+1;enemy.soulPoisonSources[key]=turns-1;remaining=math.max(remaining,turns-1)
        end end
        if not enemy.soulPoisonSources then sources=1;remaining=enemy.soulPoisonTurns-1 end
        enemy.soulPoisonTurns=remaining
        for _=1,sources do
            if enemy.hp>0 then require("src.monster").takeDamage(enemy,math.max(1,math.floor((enemy.maxHp or enemy.hp)*.08))) end
        end
        R.reap(g)
        if enemy.hp<=0 then return false end
    end
    local s=state(g)
    if s.freeze>0 then s.freeze=s.freeze-1;report(g,nil,{name="Chuông Đông Cứng",id="soul_frost_bell"},"CHẶN ĐÒN ĐÁNH");return false end
    return true
end
return R
