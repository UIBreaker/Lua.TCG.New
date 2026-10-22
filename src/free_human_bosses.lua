local W={definitions=require("config.free_human_boss_data").list}
local function kind(m) return m and m.isBoss and m.bossData and m.bossData.freeHumanBoss end
local function live(m) return kind(m) and (m.hp or 0)>0 and require("src.boss_abilities").passiveEnabled(m) end
local function history(g)
    local r=g.run or {};local key=table.concat({r.regionId or "legacy",r.ante or g.round or 1},":")
    if not g.areaPlayedCards or g.areaPlayedCards.key~=key then g.areaPlayedCards={key=key,ids={}} end
    return g.areaPlayedCards.ids
end
function W.start(g)
    history(g)
    if kind(g.monster) then g.monster.freeHumanState={game=g,usedHands={},playerDamageStacks=0};g.monster.oneshotRages=0 end
    if kind(g.monster)=="rarity" then
        local data={};for k,v in pairs(g.monster.bossData) do data[k]=v end
        data.sealedSpnTier=data.sealedSpnTier or require("src.rng").random(#require("src.deities").RARITIES)
        g.monster.bossData=data
        local blind=g.run and g.run.blinds and g.run.blinds[g.run.currentBlindIndex or 3]
        if blind and blind.debuff and blind.debuff.id==data.id then blind.debuff=data end
    end
end
function W.spnBlocked(m,deity)
    return live(m) and kind(m)=="rarity" and deity and require("src.deities").getRarityTier(deity)==m.bossData.sealedSpnTier or false
end
function W.attackFactor(m)
    if m.spnAbilitiesSealed then return 1 end
    if kind(m)~="oneshot" then return 1 end
    return (m.bossData.baseAttackMultiplier or 5)*3^(m.oneshotRages or 0)
end
function W.playerDamageFactor(g)
    local m=g and g.monster;local s=m and m.freeHumanState
    if m and m.spnAbilitiesSealed then return 1 end
    return kind(m)=="oneshot" and (m.hp or 0)>0 and s and 1+.2*(s.playerDamageStacks or 0) or 1
end
function W.absorbOneshot(m,hpBefore,damage)
    if kind(m)~="oneshot" or hpBefore<=0 or hpBefore~=m.maxHp or damage<hpBefore or not require("src.boss_abilities").passiveEnabled(m) then return false end
    m.maxHp=damage;m.hp=damage;m.damageLagHp=damage;m.oneshotRages=(m.oneshotRages or 0)+1
    local g=m.freeHumanState and m.freeHumanState.game
    if g then
        if m.intent and m.intent.type=="attack" then
            local A=require("src.enemy_abilities")
            local echo=require("src.enemy_loadout").attackBonus(m)*W.attackFactor(m)
            local value=A.attack(m)+A.attackBonus(g,m)+echo
            m.intent.value=value;m.intent.label="Tấn công "..string.format("%g",value).." ST"..(echo>0 and " · Vọng Âm" or "")
                ..(((m.enemyInventory or {}).guaranteedAttacks or 0)>0 and " · Trúng 100%" or "")
        end
        g.enemyFeedback="THÁCH TỬ · "..string.format("%g",damage).." MÁU MỚI · SÁT THƯƠNG ×3"
        g.spnFeedback=g.spnFeedback or {};g.spnFeedback[#g.spnFeedback+1]={deity={name=m.name},slot=0,kind="boss",text=g.enemyFeedback}
        require("src.potions").emit(g,"rebirth",g.enemyFeedback,damage,m)
    end
    return true
end
function W.blocked(m,c)
    return live(m) and kind(m)=="cards" and c and c.id and m.freeHumanState and history(m.freeHumanState.game)[c.id] or false
end
function W.disabled(g,c)
    return g and W.blocked(g.monster,c) or false
end
function W.handBlocked(g,id)
    local m=g and g.monster
    return live(m) and kind(m)=="formation" and m.freeHumanState and m.freeHumanState.usedHands[id] or false
end
function W.finishHand(g,ctx)
    local m=g.monster;local s=m and m.freeHumanState
    if s and kind(m)=="formation" and live(m) then s.usedHands[ctx.handInfo.type.id]=true end
    local ids=history(g)
    for _,c in ipairs(ctx.played or {}) do if c.id then ids[c.id]=true end end
end
function W.active(g)
    local m=g.monster;local s=m and m.freeHumanState
    if m and m.spnAbilitiesSealed then return end
    if not s or (m.hp or 0)<=0 then return end
    local message
    if kind(m)=="formation" and live(m) then
        local count=0
        for id,enabled in pairs(g.unlockedHands or {high_card=true}) do
            if enabled then count=count+1;if not s.usedHands[id] then return end end
        end
        if count>0 then g.playerHp=0;message="PHÁN QUYẾT CUỐI · KHÔNG CÒN THẾ BÀI" end
    elseif kind(m)=="cards" and live(m) then
        local choices,seen={},{}
        for _,pile in ipairs({g.hand or {},g.deck or {},g.discardPile or {},g.persistentDeck or {}}) do
            for _,c in ipairs(pile) do
                if not c.destroyed and c.id and not seen[c.id] and W.blocked(m,c) then choices[#choices+1]=c;seen[c.id]=true end
            end
        end
        if #choices>0 then
            local c=choices[require("src.rng").random(#choices)]
            require("src.card_abilities").upgrade(g,c,-1,false)
            message="TƯỚC TIẾN HÓA · "..(c.rankName or c.rank or "")..(c.suitSymbol or "").." -1 CẤP (TỐI THIỂU 0)"
        end
    elseif kind(m)=="oneshot" then
        s.playerDamageStacks=(s.playerDamageStacks or 0)+1
        message="KHIÊU CHIẾN · BẠN +"..(s.playerDamageStacks*20).."% SÁT THƯƠNG TRONG TRẬN"
        require("src.potions").emit(g,"damage",message,nil,nil,g.hand)
    elseif kind(m)=="rarity" then
        local D=require("src.deities");local choices,seen={},{}
        for _,deity in ipairs(require("src.loadout").ownedDeities(g)) do
            if type(deity)=="table" and deity.id and not seen[deity] and D.getRarityTier(deity)>1 then choices[#choices+1]=deity;seen[deity]=true end
        end
        if #choices>0 then
            local deity=choices[require("src.rng").random(#choices)];local before=D.getRarityBadge(deity)
            D.downgrade(deity,2)
            message="GIÁNG HAI PHẨM · "..(deity.name or deity.id).." · "..before.." → "..D.getRarityBadge(deity)
            require("src.potions").emit(g,"rank_drain",message,nil,m)
        else message="GIÁNG HAI PHẨM · KHÔNG CÓ SPN TRÊN BẬC C" end
    end
    if message then
        g.enemyFeedback=message
        g.spnFeedback=g.spnFeedback or {};g.spnFeedback[#g.spnFeedback+1]={deity={name=m.name},slot=0,kind="boss",text=message}
    end
end
function W.notice(m)
    local s=m and m.freeHumanState;if not s then return m and m.bossData and m.bossData.desc end
    if kind(m)=="rarity" then
        local tier=require("src.deities").RARITIES[m.bossData.sealedSpnTier]
        return (live(m) and "PHONG ẤN SPN BẬC " or "TẠM NGỪNG PHONG ẤN ")..(tier and tier.code or "?").."\nMỖI LƯỢT: MỘT SPN -2 BẬC · C MIỄN HẠ"
    end
    if kind(m)=="oneshot" then
        return "CHỐNG ONESHOT TỪ ĐẦY MÁU · "..(m.oneshotRages or 0).." LẦN\nST BOSS ×"..string.format("%g",W.attackFactor(m)).." · BẠN +"..((s.playerDamageStacks or 0)*20).."% ST"
    end
    if kind(m)=="formation" then
        local names={};local Poker=require("src.poker")
        for _,h in ipairs(Poker.HAND_TYPES_ORDERED or {}) do if s.usedHands[h.id] then names[#names+1]=h.vnName or h.id end end
        local used,total=0,0
        for id,enabled in pairs(s.game.unlockedHands or {high_card=true}) do if enabled then total=total+1;if s.usedHands[id] then used=used+1 end end end
        return "ĐÃ KHÓA "..used.." / "..total.." THẾ · HẾT THẾ SẼ THUA\n"..(#names>0 and table.concat(names,", ") or "Mỗi thế bài chỉ đánh 1 lần.")
    end
    local n=0;for _ in pairs(history(s.game)) do n=n+1 end
    return "GẠCH TÊN · "..n.." LÁ ĐÃ ĐÁNH TRONG ẢI\nMỖI LƯỢT: -1 CẤP MỘT LÁ BỊ KHÓA"
end
return W
