local R = {}
local summaries={
    soul_phoenix_lantern="Chặn chí tử, hồi 50% HP.\nMột lần/trận, khi giữ.",
    soul_frost_bell="Đóng băng 2 đòn địch.\nMột lần mỗi trận.",
    soul_rift_compass="Kéo lá rank cao nhất\nvào tay khi tính điểm.",
    soul_return_chain="Tính điểm xong,\ntrở lại tay.",
    soul_echo_mirror="Lá kề trái/phải\nkích hoạt thêm 2 lần.",
    soul_evolution_quill="Tiến hóa đồng đội +1.\nMột lần mỗi trận.",
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
    {id="soul_evolution_quill",name="Bút Ký Khởi Nguyên",cost=40,slotsNeeded=2,color={.6,.95,.4,1},desc="Khi tính điểm: tiến hóa vĩnh viễn +1 cấp cho đồng đội ít tiến hóa nhất đang tính điểm. Một lần mỗi trận."},
    {id="soul_silence_anchor",name="Neo Câm Lặng",cost=32,slotsNeeded=2,color={.65,.45,.95,1},desc="Khi tính điểm: tắt cả kỹ năng chủ động và nội tại boss đến hết 2 tay bài kế tiếp. Một lần mỗi trận."},
    {id="soul_plague_chalice",name="Chén Độc Vĩnh Dạ",cost=28,slotsNeeded=1,color={.4,.85,.3,1},desc="Khi tính điểm: đầu 3 đòn đánh của mục tiêu, độc gây sát thương bằng 8% máu tối đa địch. Không cộng dồn; làm mới thời hạn."},
    {id="soul_reaper_contract",name="Khế Ước Người Gặt",cost=30,slotsNeeded=1,color={.85,.65,.95,1},desc="Sau lần tính điểm đầu: mỗi kẻ địch chết cho +3 linh hồn đến hết trận. Không cộng dồn nhiều khế ước."},
    {id="soul_edition_prism",name="Lăng Kính Hoàng Hôn",cost=42,slotsNeeded=2,color={1,.7,.55,1},desc="Tính điểm cùng ít nhất 3 chất: nâng ấn bản chính lá này vĩnh viễn, Thường → Foil → Holo → Poly. Một lần mỗi trận."},
}
for _,def in ipairs(R.definitions) do def.shopSummary=summaries[def.id] end
local function state(g)
    g.soulRelicCombat=g.soulRelicCombat or {used={},claimed={},freeze=0}
    return g.soulRelicCombat
end
local function report(g,card,eq,message)
    local ctx=g.abilityHand and not g.abilityHand.finished and g.abilityHand or g.abilityCombat
    if ctx then
        ctx.feedback=ctx.feedback or {}
        ctx.feedback[#ctx.feedback+1]={type="equipment_trigger",card=card,equipment=eq,message=eq.name.." · "..message,addedChips=0,addedMult=0}
    end
end
function R.score(g,card,ctx)
    if ctx.retrigger then return end
    ctx.soulRelics=ctx.soulRelics or {}
    local s=state(g)
    for _,eq in ipairs(card.equipments or {}) do
        local key=tostring(card.id or card)..":"..eq.id
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
            elseif id=="soul_evolution_quill" and not s.used[key] then
                local target
                for _,other in ipairs(ctx.scoring) do
                    if other~=card and not other.destroyed and (not target or (other.evolutionLevel or 0)<(target.evolutionLevel or 0)) then target=other end
                end
                if target and require("src.card_abilities").upgrade(g,target,1,false) then s.used[key]=true;message="TIẾN HÓA ĐỒNG ĐỘI" end
            elseif id=="soul_silence_anchor" and not s.used[key] and require("src.boss_abilities").state(g.monster) then
                require("src.boss_abilities").disable(g,2,true,true);s.used[key]=true;message="KHÓA KỸ NĂNG BOSS"
            elseif id=="soul_plague_chalice" and g.monster and g.monster.hp>0 then
                g.monster.soulPoisonTurns=3;message="ĐỘC 3 ĐÒN · 8% HP"
            elseif id=="soul_reaper_contract" and not s.reaper then
                s.reaper=true;message="MỖI KẺ ĐỊCH CHẾT +3 LH"
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
            if message then report(g,card,eq,message) end
        end
    end
end
function R.guard(g,damage)
    if damage<=0 or damage<(g.playerHp or 100) then return damage end
    local s=state(g)
    for _,card in ipairs(g.hand or {}) do
        if not card.destroyed then
            for _,eq in ipairs(card.equipments or {}) do
                local key=tostring(card.id or card)..":"..eq.id
                if eq.id=="soul_phoenix_lantern" and not s.used[key] then
                    s.used[key]=true;g.playerHp=math.max(1,math.floor((g.maxPlayerHp or 100)*.5))
                    report(g,card,eq,"CHẶN CHÍ TỬ · HỒI SINH");return 0
                end
            end
        end
    end
    return damage
end
function R.reap(g)
    local s=state(g);if not s.reaper then return end
    for i,enemy in ipairs(g.enemies or {g.monster}) do
        if enemy and enemy.hp<=0 and not s.claimed[i] then
            s.claimed[i]=true;g.souls=(g.souls or 0)+3
            report(g,nil,{name="Khế Ước Người Gặt",id="soul_reaper_contract"},"+3 LH")
        end
    end
end
function R.beforeAttack(g,enemy)
    if (enemy.soulPoisonTurns or 0)>0 then
        enemy.soulPoisonTurns=enemy.soulPoisonTurns-1
        require("src.monster").takeDamage(enemy,math.max(1,math.floor((enemy.maxHp or enemy.hp)*.08)))
        R.reap(g)
        if enemy.hp<=0 then return false end
    end
    local s=state(g)
    if s.freeze>0 then s.freeze=s.freeze-1;report(g,nil,{name="Chuông Đông Cứng",id="soul_frost_bell"},"CHẶN ĐÒN ĐÁNH");return false end
    return true
end
return R
