local Rng=require("src.rng")
local Deck=require("src.deck")
local Clone=require("src.blood_shop").clone
local S={chance=.30}
S.outcomes={
    {id="damage",name="Sát thương +5"},{id="speed",name="Tốc đánh +3"},
    {id="evolve",name="Tiến hóa +1 cấp"},{id="double",name="Nhân đôi chỉ số"},
    {id="copies",name="Thêm 3 bản sao"},{id="lose_damage",name="Sát thương −5"},
    {id="lose_speed",name="Tốc đánh −3"},{id="lose_level",name="Tiến hóa −1 cấp"},
    {id="gold",name="Nhận 100–300 vàng"},{id="nothing",name="Không nhận gì"},
}
S.enemies={
    {key="blood_hound",name="Huyết Khuyển",rank=2,kind="frost_wolf",skill="Săn Theo Bầy",desc="Tăng 20% sát thương cho mỗi đồng đội còn sống."},
    {key="blood_sentinel",name="Vệ Binh Huyết Thạch",rank=4,kind="lava_golem",skill="Giáp Huyết Thạch",desc="Giáp đầu trận bằng 12% HP. Sau đòn đánh, tái tạo giáp từ dự trữ hữu hạn."},
    {key="blood_oracle",name="Tiên Tri Huyết Vụ",rank=6,kind="forest_goblin",skill="Lễ Phí Huyết Ấn",desc="Mỗi 2 đòn đánh lấy 1 Vàng. Nếu bạn hết Vàng, sát thương của nó tăng 15%."},
    {key="blood_leech",name="Đỉa Chúa Huyết Hồ",rank=8,kind="swamp_wraith",skill="Hút Sinh Mệnh",desc="Hồi HP theo sát thương gây ra. Dùng chung dự trữ hồi máu hữu hạn trong trận."},
    {key="blood_executioner",name="Đao Phủ Huyết Ngục",rank=10,skill="Mùi Máu Yếu",desc="Khi bạn còn dưới 40% máu tối đa, đòn đánh gây thêm 35% sát thương."},
    {key="blood_weaver",name="Nhện Dệt Huyết Chú",rank=11,kind="desert_scorpion",skill="Tơ Độc Huyết Chú",desc="Đòn đánh gây HP thực thêm 2 Độc, cộng dồn tối đa 6. Cuối tay mất HP theo Độc, sau đó Độc giảm 1."},
    {key="blood_gargoyle",name="Thạch Quỷ Huyết Dực",rank=12,kind="ancient_skeleton",skill="Tái Kết Huyết Thạch",desc="Một lần mỗi trận: khi bị hạ, tái kết cơ thể và sống lại với 25% HP."},
    {key="blood_sovereign",name="VƯƠNG HUYẾT",rank=13},
}
S.boss={id="blood_sovereign",name="VƯƠNG HUYẾT",desc="Mỗi lần bạn thực sự hồi máu từ bất kỳ nguồn nào: nhân đôi máu hiện tại, máu tối đa, sát thương và tốc đánh của Vương Huyết. Cuối mỗi lượt đánh: bạn mất 2% máu hiện tại, xuyên giáp."}
function S.roll(game)
    local r=game.run
    if not r or game.bloodDomain or r.ante%2~=0 or r.currentBlindIndex~=3 or not r.blinds or r.blinds[3].status~="completed" then return false end
    local key=r.ante..":"..(r.regionId or "human")
    game.statueChecked=game.statueChecked or {}
    if game.statueChecked[key] then return false end
    game.statueChecked[key]=true
    return Rng.random()<S.chance
end
function S.create(game)
    game.pendingAncientStatue=nil
    game.ancientStatue={touches=0,page=1,message="Chọn một quân bài rồi đặt tay lên tượng. Mỗi kết quả có tỷ lệ 10%."}
end
function S.prepareStage(game)
    local r=game.run;local stage=r.areaStage
    r.blinds=require("src.run_manager").generateAnteBlinds(r.ante,game.selectedFaction,"blood_domain",stage,r.difficultyCap)
    r.currentBlindIndex=3;r.blinds[1].status="completed";r.blinds[2].status="completed";r.blinds[3].status="current"
    game.currentBlind=r.blinds[3];game.monster=nil;game.enemies=nil
end
function S.enter(game)
    if game.bloodDomain or not game.run then return false end
    game.bloodDomain={returnRun=Clone(game.run),entryAnte=game.run.ante}
    game.run=Clone(game.run);game.run.regionId="blood_domain";game.run.areaStage=1
    game.run.difficultyCap=math.min(game.run.ante,game.run.difficultyCap or game.run.ante);game.run.victory=false
    game.pendingBarter=nil;game.pendingAncientStatue=nil;game.ancientStatue=nil
    S.prepareStage(game);return true
end
function S.touch(game,cardId)
    local e=game.ancientStatue
    if not e or game.bloodDomain or (game.playerHp or 0)<=0 then return false end
    local card
    for _,c in ipairs(game.persistentDeck or {}) do if c.id==cardId and not c.destroyed then card=c;break end end
    if not card then return false end
    local paid=game.playerHp*.10;game.playerHp=game.playerHp-paid;e.touches=e.touches+1
    local result=S.outcomes[Rng.random(#S.outcomes)]
    local Sync=require("src.chest_expansion").sync
    if result.id=="damage" or result.id=="lose_damage" then
        local value=math.max(1,(card.baseChips or Deck.getChipValue(card.rank))+(result.id=="damage" and 5 or -5))
        Sync(game,card,function(c) c.baseChips=value;c.bonusBaseChips=value-Deck.getChipValue(c.rank) end)
    elseif result.id=="speed" then
        Sync(game,card,function(c) c.speedBonus=(c.speedBonus or 0)+3;Deck.getCardAttackSpeed(c) end)
    elseif result.id=="lose_speed" then
        Sync(game,card,function(c) c.statueSpeedPenalty=(c.statueSpeedPenalty or 0)+3;Deck.getCardAttackSpeed(c) end)
    elseif result.id=="evolve" or result.id=="lose_level" then
        require("src.card_abilities").upgrade(game,card,result.id=="evolve" and 1 or -1,false)
    elseif result.id=="double" then
        Sync(game,card,function(c)
            c.statuePower=(c.statuePower or 1)*2
            c.baseChips=(c.baseChips or Deck.getChipValue(c.rank))*2;c.bonusBaseChips=c.baseChips-Deck.getChipValue(c.rank)
            c.speedBonus=(c.speedBonus or 0)*2;c.statueSpeedPenalty=(c.statueSpeedPenalty or 0)*2
            c.potionPermanentDamage=(c.potionPermanentDamage or 0)*2;c.potionPermanentMult=(c.potionPermanentMult or 0)*2
            Deck.getCardAttackSpeed(c)
        end)
    elseif result.id=="copies" then
        for _=1,3 do local c=Deck.cloneCard(card);c.id=Deck.newCard(card.rank,card.suit).id;Deck.addCardToDeck(game,c) end
    elseif result.id=="gold" then
        local amount=Rng.random(100,300);game.gold=(game.gold or 0)+amount
        e.gold=amount
    end
    e.last=result.id;e.message=result.name..(result.id=="gold" and (" · +"..e.gold.." vàng") or "")..string.format(" · Hiến %.2f HP",paid)
    e.flash=1
    if game.playerHp<=(game.maxPlayerHp or 100)*.10 then S.enter(game);return true,"entered" end
    return true,result.id
end
function S.decorate(m,stage)
    local e=S.enemies[math.max(1,math.min(8,stage))]
    m.human=false;m.neutralHuman=nil;m.creatureCard=true;m.artKey=e.key;m.cardSuit=nil;m.cardRank=e.rank
    m.name=e.name;m.title="LÃNH ĐỊA MÁU · "..stage.." / 8";m.color={.83,.25,.31,1}
    m.isBoss=stage==8;m.isElite=stage==7
    m.bossData=m.isBoss and S.boss or nil;m.bloodSovereign=m.isBoss
    m.creatureKind=e.kind;m.bloodExecutioner=e.key=="blood_executioner"
    m.desc=m.isBoss and S.boss.desc or (e.skill..": "..e.desc)
    m.enemyAbility=m.isBoss and {name="Khát Sinh Mệnh",desc=S.boss.desc} or {name=e.skill,desc=e.desc}
    return m
end
function S.blinds(blinds,ante,stage,difficulty)
    local e=S.enemies[math.max(1,math.min(8,stage))];local b=blinds[3]
    b.type=stage==8 and "boss" or stage==7 and "big" or "small";b.debuff=stage==8 and S.boss or nil
    b.name=e.name;b.title="LÃNH ĐỊA MÁU · "..stage.." / 8";b.color={.83,.25,.31,1}
    b.hp=require("src.run_manager").calculateBlindHp(difficulty or ante,b.type)*2
    b.bloodDomainMultiplier=2
    b.regionId="blood_domain";b.areaStage=stage
    return blinds
end
function S.complete(game)
    local d=game.bloodDomain
    if not d or game.run.areaStage~=8 or d.choices then return end
    d.choices={}
    for _,spn in ipairs(require("src.deities").getRandomShopPool({},3)) do
        local item=Clone(spn);item.bloodDomainPower=4;d.choices[#d.choices+1]=item
    end
end
function S.advance(game)
    if game.run.areaStage>=8 then return false,"blood_reward" end
    game.run.areaStage=game.run.areaStage+1;game.run.ante=game.run.ante+1
    S.prepareStage(game);return true,"next_ante"
end
function S.claim(game,index)
    local d=game.bloodDomain;local item=d and d.choices and d.choices[index]
    if not item then return false end
    require("src.loadout").storeDeity(game,item)
    local stats=game.run.stats;game.run=d.returnRun;game.run.stats=stats
    game.bloodDomain=nil;game.monster=nil;game.enemies=nil;game.currentBlind=game.run.blinds[game.run.currentBlindIndex]
    return true
end
function S.restore(game)
    local d=game.bloodDomain;if not d then return end
    local r=d.returnRun
    local old=r.blinds;r.blinds=require("src.run_manager").generateAnteBlinds(r.ante,game.selectedFaction,r.regionId,r.areaStage,r.difficultyCap)
    for i,b in ipairs(r.blinds) do b.status=old[i].status end
    game.run.difficultyCap=math.min(r.ante,r.difficultyCap or r.ante)
    old=game.run.blinds
    game.run.blinds=require("src.run_manager").generateAnteBlinds(game.run.ante,game.selectedFaction,"blood_domain",game.run.areaStage,game.run.difficultyCap)
    for i,b in ipairs(game.run.blinds) do b.status=old[i].status end
    game.currentBlind=game.run.blinds[game.run.currentBlindIndex]
    for i,item in ipairs(d.choices or {}) do
        local live=Clone(require("src.deities").CATALOG[item.id]);for k,v in pairs(item) do live[k]=v end;d.choices[i]=live
    end
end
return S
