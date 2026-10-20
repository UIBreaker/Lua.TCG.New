local Data=require("config.human_boss_data")
local R=require("src.rng")
local H={definitions=Data.list}
local testMode=false
for _,a in ipairs(arg or {}) do if a:match("^%-%-test") or a:match("^%-%-capture") or a=="--simulate-campaign-balance" then testMode=true end end
function H.number(m) return m and m.isBoss and m.bossData and m.bossData.humanBoss end
function H.primary(g)
    for _,m in ipairs(g.enemies or {g.monster}) do if H.number(m) then return m end end
end
local function passive(m) return require("src.boss_abilities").passiveEnabled(m) end
local function emit(g,message)
    g.enemyFeedback=message
    g.spnFeedback=g.spnFeedback or {}
    g.spnFeedback[#g.spnFeedback+1]={deity={name="BOSS"},slot=0,text=message}
end
function H.roll(stage)
    -- Encounter selection must not consume a potion/SPN reward's pending RNG roll.
    local level=math.max(1,stage or 1)
    local seed=level
    local state=tostring(R.getState())
    for i=1,#state do seed=(seed*131+state:byte(i))%2147483647 end
    seed=(seed*48271)%2147483647
    local pool={}
    for _,definition in ipairs(Data.list) do if (definition.firstStage or 1)<=level then pool[#pool+1]=definition end end
    local source=pool[seed%#pool+1];local d={}
    for k,v in pairs(source) do d[k]=v end
    d.encounterToken=(seed*48271)%2147483647
    return d
end
local function deityTargets(g)
    local out={}
    for _,key in ipairs({"deities","backpackDeities"}) do
        for index,item in pairs(g[key] or {}) do if type(item)=="table" and item.id then
            out[#out+1]={list=g[key],index=index,item=item,reserve=key=="backpackDeities"}
        end end
    end
    table.sort(out,function(a,b) if a.reserve~=b.reserve then return not a.reserve end;return a.index<b.index end)
    return out
end
local function save(g)
    if g.run and not testMode then require("src.persistence").saveRun(g,"playing") end
end
local function destroy(g,c)
    require("src.card_abilities").destroy(g,c)
    require("src.chest_expansion").sync(g,c,function(copy) copy.destroyed=true end)
    require("src.combat").cleanupDestroyedCards(g)
end
local function downgradeDeity(d)
    local D=require("src.deities")
    if (d.evolutionLevel or 0)>0 then d.evolutionLevel=d.evolutionLevel-1
    else
        local base=d.baseRarityTier or D.getRarityTier(d)
        if base<=1 then return false end
        D.setRarity(d,D.RARITIES[base-1].id)
    end
    local tier=D.getRarityTier(d);d.rarity=D.RARITIES[tier].id;d.desc=D.getDescription(d)
    return true
end
function H.start(g)
    local m=g.monster;local n=H.number(m);if not n then return end
    local token=m.bossData.encounterToken or (m.bossData.id..":"..tostring(m.stage or g.round or 1))
    if not g.humanBossReceipt or g.humanBossReceipt.token~=token then g.humanBossReceipt={token=token} end
    m.humanBossState={game=g,receipt=g.humanBossReceipt,forms={},stolen=0}
    local s=m.humanBossState
    local hpScale=m.bossData.hpScale or 1
    m.maxHp=math.max(1,math.floor(m.maxHp*hpScale));m.hp=m.maxHp;m.damageLagHp=m.hp
    m.creatureArmor=math.floor((m.creatureArmor or 0)*hpScale)
    m.creatureArmorMax=math.floor((m.creatureArmorMax or 0)*hpScale)
    if n==1 then m.maxHp=math.floor(m.maxHp*1.5);m.hp=m.maxHp;m.damageLagHp=m.hp
    elseif n==6 then m.creatureArmor=m.hp;m.creatureArmorMax=m.hp
    elseif n==7 and not s.receipt.spiritDestroyed then
        local targets=deityTargets(g)
        if #targets>0 then
            local target=targets[R.random(#targets)]
            if target.reserve then table.remove(target.list,target.index) else target.list[target.index]=nil end
            emit(g,"BẺ HỒN · MẤT VĨNH VIỄN "..(target.item.name or target.item.id))
        end
        s.receipt.spiritDestroyed=true;save(g)
    elseif n==10 then
        local counts=s.receipt.goldStacks or {0,0,0};local remaining=s.receipt.goldStacks and 0 or math.min(6,math.floor(math.max(0,g.gold or 0)/10))
        s.gold=s.receipt.startGold or g.gold or 0;s.receipt.startGold=s.gold
        while remaining>0 do
            local batch=math.max(1,math.floor(remaining/300));local index=R.random(3)
            counts[index]=counts[index]+batch;remaining=remaining-batch
        end
        local function boosted(value,count) return math.floor(math.min(1e150,value*1.5^math.min(850,count))) end
        m.attack=boosted(m.attack,counts[1]);m.attackSpeed=boosted(m.attackSpeed,counts[2])
        m.maxHp=boosted(m.maxHp,counts[3]);m.hp=m.maxHp;m.damageLagHp=m.hp;s.goldStacks=counts
        s.receipt.goldStacks=counts
    end
    -- Snapshot recovery after Boss vitality/wealth has changed the final HP total.
    m.enemyResources=nil
end
function H.speed(m,value)
    local s=m.humanBossState
    if H.number(m)==2 and s and passive(m) then
        local highest=1
        for _,c in ipairs(s.game.hand or {}) do if not c.destroyed then highest=math.max(highest,require("src.deck").peekCardAttackSpeed(c,s.game)) end end
        local active=s.game.abilityHand
        if active and not active.finished then
            for _,c in ipairs(active.played or {}) do if not c.destroyed then highest=math.max(highest,require("src.deck").peekCardAttackSpeed(c,s.game)) end end
        end
        return math.max(value,highest*2)+(s.stolen or 0)
    end
    if H.number(m)==2 and s then return value+(s.stolen or 0) end
    return value
end
function H.notice(g)
    local m=H.primary(g);local s=m and m.humanBossState
    if not s or m.hp<=0 then return end
    if H.number(m)==3 and passive(m) and s.required then return "CHỈ ĐÁNH TRÚNG: "..s.required.vnName end
    if H.number(m)==6 and passive(m) and (m.creatureArmor or 0)>0 and (g.playerArmor or g.playerShield or 0)<=0 then
        return "CẦN CÓ GIÁP ĐỂ PHÁ LỚP GIÁP ĐẶC BIỆT CỦA BOSS"
    end
end
function H.handSize(g,value)
    local m=H.primary(g)
    return H.number(m)==5 and m.hp>0 and passive(m) and math.max(1,value-1) or value
end
function H.disabled(g,c)
    local m=g and H.primary(g)
    return H.number(m)==4 and m.hp>0 and passive(m) and c.rank>=11 and c.rank<=13 or false
end
local function applyForm(c,form)
    if c.humanCourtForm then return end
    local Deck=require("src.deck")
    c.humanCourtForm={rank=c.rank,rankName=c.rankName,chips=c.baseChips,applied=Deck.getChipValue(form)}
    c.rank=form;c.rankName=Deck.RANK_NAMES[form];c.baseChips=Deck.getChipValue(form)
    Deck.getCardAttackSpeed(c)
end
function H.handStart(g)
    local m=H.primary(g);if not m or not m.humanBossState then return end
    local s=m.humanBossState
    for _,c in ipairs(g.hand or {}) do if s.forms[c.id] then applyForm(c,s.forms[c.id]) end end
    if H.number(m)==3 and m.hp>0 and passive(m) then
        local choices={};local limit=require("src.card_abilities").handSize(g,g.maxHandSize)
        local Poker=require("src.poker");local reachable={high_card=true}
        -- Bound oversized potion hands; every offered pattern still has a real playable subset.
        local size=math.min(10,#(g.hand or {}))
        for mask=1,2^size-1 do
            local cards={}
            for index=1,size do if math.floor(mask/2^(index-1))%2==1 then cards[#cards+1]=g.hand[index] end end
            if #cards<=math.min(5,limit) then
                local info=Poker.evaluate(cards,g.unlockedHands,g.handLevels)
                if info then reachable[info.type.id]=true end
            end
        end
        for _,hand in ipairs(Poker.ALL_HANDS_ORDERED) do
            if (g.unlockedHands or {}).high_card==nil and hand.id=="high_card" or (g.unlockedHands or {})[hand.id] then
                if reachable[hand.id] and (hand.requiredCards or 1)<=limit then choices[#choices+1]=hand end
            end
        end
        s.required=#choices>0 and choices[R.random(#choices)] or require("src.poker").HAND_TYPES.HIGH_CARD
        if m.bossState then m.bossState.telegraph="CHỈ TRÚNG: "..s.required.vnName end
        emit(g,"THỆ ƯỚC · CHỈ "..s.required.vnName)
    end
end
function H.rejectHand(g)
    local m=H.primary(g);local s=m and m.humanBossState
    if H.number(m)~=3 or not s or not s.required or not passive(m) then return false end
    local info=g.abilityHand and g.abilityHand.handInfo
    local id=info and info.type and info.type.id or g.lastPlayedHandId
    return id~=s.required.id
end
function H.opening(g)
    local m=H.primary(g);if not m or not m.humanBossState then return end
    local s=m.humanBossState;local n=H.number(m)
    if n==9 then g.discardsRemaining=0;g.spnDiscardCap=0 end
    if n~=8 then return end
    local Deck=require("src.deck")
    if not s.receipt.captives then
        s.receipt.captives={}
        for i=1,math.min(2,#g.hand,math.max(0,#(g.persistentDeck or {})-1)) do
            local c=table.remove(g.hand,R.random(#g.hand))
            s.receipt.captives[#s.receipt.captives+1]={id=c.id}
        end
    end
    for _,record in ipairs(s.receipt.captives) do if not record.dead then
        local canonical
        for _,c in ipairs(g.persistentDeck or {}) do if c.id==record.id then canonical=c;break end end
        if canonical then
            for _,pile in ipairs({g.hand,g.deck,g.discardPile}) do for i=#pile,1,-1 do if pile[i].id==record.id then table.remove(pile,i) end end end
            local c=Deck.cloneCard(canonical)
            local ally={name="Bị khống chế · "..c.rankName..(c.suitSymbol or ""),title="GIẾT BOSS ĐỂ GIẢI CỨU",human=true,kingdom="BỊ KHỐNG CHẾ",
                cardSuit=c.suit,cardRank=c.rank,evolutionLevel=c.evolutionLevel,hp=math.max(1,math.floor(m.maxHp*.2)),
                maxHp=math.max(1,math.floor(m.maxHp*.2)),attack=math.max(1,math.floor(m.attack*.4)),attackSpeed=Deck.peekCardAttackSpeed(c,g),
                group=g.enemies,groupIndex=#g.enemies+1,humanCaptive={card=c,record=record,boss=m},stage=m.stage}
            require("src.enemy_abilities").start(ally);g.enemies[#g.enemies+1]=ally
            require("src.enemy_abilities").plan(g,ally)
        end
    end end
    save(g)
end
function H.finish(g)
    local m=H.primary(g);local s=m and m.humanBossState
    if not s or s.finished then return end
    s.finished=true
    for _,pile in ipairs({g.hand or {},g.deck or {},g.discardPile or {}}) do for _,c in ipairs(pile) do
        local form=c.humanCourtForm
        if form then c.rank=form.rank;c.rankName=form.rankName;c.baseChips=form.chips+(c.baseChips-form.applied);c.humanCourtForm=nil;require("src.deck").getCardAttackSpeed(c) end
    end end
    for i=#g.enemies,1,-1 do
        local ally=g.enemies[i];local captive=ally.humanCaptive
        if captive and ally.hp>0 and not captive.record.dead then
            g.hand[#g.hand+1]=captive.card;ally.captiveFreed=true;table.remove(g.enemies,i)
        end
    end
    g.monster=m
end
function H.victory(g)
    local m=H.primary(g)
    if m and m.hp<=0 then H.finish(g);return true end
    return false
end
function H.intent(g,m)
    local s=m.humanBossState
    if H.number(m)==9 and s and not s.receipt.executionUsed then
        return {type="human_skill",value=0,label="ĐOẠN MỆNH · Tiêu hủy vĩnh viễn 1 lá trên tay · 1 lần"}
    end
end
function H.action(g,m)
    if (m.intent or {}).type~="human_skill" then return end
    local s=m.humanBossState
    if not s or s.receipt.executionUsed then return {attack=0,absorbed=0,damage=0,blocked=true,action="human_skill",value=0,label="Đoạn Mệnh đã dùng"} end
    s.receipt.executionUsed=true
    local label="ĐOẠN MỆNH · KHÔNG CÒN MỤC TIÊU"
    if #g.hand>0 then
        local c=g.hand[R.random(#g.hand)];destroy(g,c);emit(g,"ĐOẠN MỆNH · MẤT VĨNH VIỄN "..(c.rankName or "lá bài"))
        label="TIÊU HỦY VĨNH VIỄN 1 LÁ"
    end
    save(g)
    return {attack=0,absorbed=0,damage=0,killedPlayer=false,action="human_skill",target=m,value=0,label=label}
end
function H.attack(g,m,value)
    if H.number(m)==5 then return value*math.max(1,#(g.hand or {})) end
    return value
end
function H.armor(m,value)
    if H.number(m)~=6 or not m.humanBossState or not passive(m) or (m.creatureArmor or 0)<=0 then return value,false end
    local g=m.humanBossState.game
    if (g.playerArmor or g.playerShield or 0)<=0 then return 0,true end
    local absorbed=math.min(value,m.creatureArmor);m.creatureArmor=m.creatureArmor-absorbed
    return value-absorbed,true
end
function H.afterDamage(m,before)
    if m.humanCaptive and m.hp<=0 and not m.humanCaptive.record.dead then
        local c=m.humanCaptive;local g=c.boss.humanBossState.game
        c.record.dead=true;destroy(g,c.card);save(g)
    end
    if H.number(m)==7 and m.hp<before and m.humanBossState
        and not (m.bossState and m.bossState.activeUntil>=m.bossState.handIndex) then
        local g=m.humanBossState.game;local choices=deityTargets(g)
        if #choices>0 and downgradeDeity(choices[R.random(#choices)].item) then emit(g,"BÀO MÒN LINH HỒN · SPN GIẢM 1 BẬC");save(g) end
    end
end
function H.afterAttack(g,m,result)
    local n=H.number(m);local s=m.humanBossState
    if not n or not s or result.blocked or result.action~="attack" then return end
    if n==1 then
        local healed=require("src.enemy_abilities").heal(m,math.floor(m.maxHp*.05))
        if healed>0 then emit(g,"HUYẾT MẠCH · +"..healed.." HP") end
    end
    if result.missed then return end
    if n==2 then
        local target
        for _,c in ipairs(g.abilityHand and g.abilityHand.played or {}) do
            if not c.destroyed and (not target or require("src.deck").peekCardAttackSpeed(c,g)>require("src.deck").peekCardAttackSpeed(target,g)) then target=c end
        end
        if target then
            local stolen=math.min(2,require("src.deck").peekCardAttackSpeed(target,g)-1)
            require("src.chest_expansion").sync(g,target,function(c) c.humanSpeedPenalty=(c.humanSpeedPenalty or 0)+stolen;require("src.deck").getCardAttackSpeed(c) end)
            s.stolen=s.stolen+stolen;emit(g,"ĐOẠT PHONG · -"..stolen.." TỐC VĨNH VIỄN");save(g)
            g.lastPlayerAttackSpeed=require("src.combat").getAverageAttackSpeed(g.abilityHand.played,g)
        end
    elseif n==3 then
        local discarded={}
        for i=1,math.min(2,#g.hand) do discarded[#discarded+1]=table.remove(g.hand,R.random(#g.hand)) end
        require("src.card_abilities").discard(g,discarded)
        for _,c in ipairs(discarded) do g.discardPile[#g.discardPile+1]=c end
        g.selectedIndices={};emit(g,"TƯỚC LỆNH · BỎ "..#discarded.." LÁ")
    elseif n==4 and #g.hand>0 then
        local choices={};for _,c in ipairs(g.hand) do if not c.humanCourtForm then choices[#choices+1]=c end end
        if #choices==0 then return end
        local c=choices[R.random(#choices)];local rank=R.random(11,13);s.forms[c.id]=rank
        applyForm(c,rank);emit(g,"MẶT NẠ · BIẾN THÀNH "..require("src.deck").RANK_NAMES[rank])
    elseif n==8 and #g.hand>0 then
        local choices={};for _,c in ipairs(g.hand) do if (c.evolutionLevel or 0)>0 then choices[#choices+1]=c end end
        if #choices==0 then return end
        local c=choices[R.random(#choices)]
        require("src.card_abilities").upgrade(g,c,-1,false);emit(g,"XIỀNG SUY TÀN · -1 CẤP TIẾN HÓA");save(g)
    elseif n==10 and result.damage>0 then
        local choices={}
        for _,key in ipairs({"backpackEquipment","backpackConsumables","backpackDeities"}) do for index,item in ipairs(g[key] or {}) do
            choices[#choices+1]={list=g[key],index=index,item=item,kind=key=="backpackDeities" and "deity" or key=="backpackEquipment" and "equipment" or "consumable"}
        end end
        if #choices>0 then
            local choice=choices[R.random(#choices)];local price=require("src.shop").getSacrificePrice(choice.item,choice.kind,g)
            table.remove(choice.list,choice.index);g.gold=(g.gold or 0)+price;emit(g,"CƯỠNG BÁN · "..(choice.item.name or choice.item.id).." +"..price.." VÀNG");save(g)
        end
    end
end
return H
