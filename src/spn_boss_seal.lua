local C={id="spirit_crown_eraser"}
function C.register(D)
    local desc="Trong trận Boss, mở Balo và nhấn TIÊU HỦY lá này: vô hiệu hóa hoàn toàn nội tại và chiêu thức của Boss đến hết trận; Boss vẫn đánh thường. Dùng từ ô trang bị hoặc kho, kể cả bị khóa ô. Bán/hiến tế/tự hủy không kích hoạt. Khi trang bị: +{value} Sát thương và +{value} Cường hóa; mỗi cấp tiến hóa thêm đúng +5 mỗi chỉ số, cấp gốc +0."
    D.CATALOG[C.id]={id=C.id,name="Kẻ Xóa Vương Quyền",stat="addChips",values={value=0},rarity="common",cost=4,trigger="hand",
        descriptionTemplate=desc,desc=desc:gsub("{value}","0"),baseDesc=desc,
        lore="Dị linh tự xóa mình khỏi thế giới, kéo theo quyền năng của kẻ đội vương miện.",
        onHandScored=function() return {addChips=0,addMult=0,fixedMessage=true,message="DƯ ÂM VƯƠNG QUYỀN · SÁT THƯƠNG VÀ CƯỜNG HÓA THEO TIẾN HÓA"} end}
end
local function bosses(game)
    local list={}
    for _,m in ipairs(require("src.enemy_group").members(game)) do
        if m.isBoss and (m.hp or 0)>0 and not m.spnAbilitiesSealed then list[#list+1]=m end
    end
    return list
end
function C.canDestroy(game,source,index,inCombat)
    if not inCombat then return nil,"Chỉ tiêu hủy để phong ấn trong trận Boss." end
    if source~="equipped" and source~="reserve" then return nil,"Hãy chọn SPN trong balo." end
    local list=source=="equipped" and game.deities or game.backpackDeities
    local item=list and list[index]
    if not item or item.id~=C.id then return nil,"Hãy chọn Kẻ Xóa Vương Quyền." end
    if #bosses(game)==0 then return nil,"Không có Boss còn sống chưa bị vô hiệu hóa." end
    return item
end
function C.seal(game,m)
    local Boss=require("src.boss_abilities");local s=Boss.state(m)
    -- Release existing resource restrictions before permanently disabling their reapplication.
    if m==game.monster then Boss.disable(game,1,false) end
    m.spnAbilitiesSealed=true
    if s then
        if s.resourceLock and s.resourceLock.untilHand>=s.handIndex then
            local key=s.resourceLock.kind=="hands" and "handsRemaining" or "discardsRemaining"
            game[key]=(game[key] or 0)+(s.resourceLock.amount or 0)
        end
        s.slotLock=nil;s.resourceLock=nil;s.repeatUntil=nil;s.repeatHand=nil;s.forgotten={};s.forgottenCard=nil
        s.pendingDamage=0;s.debt=0;s.excess=0;s.activeUntil=0;s.activeCountdown=0;s.telegraph=nil;s.activeState="sealed"
        s.feedback="NỘI TẠI VÀ CHIÊU THỨC ĐÃ BỊ XÓA ĐẾN HẾT TRẬN"
    end
    for _,pile in ipairs({game.hand or {},game.deck or {},game.discardPile or {},game.persistentDeck or {}}) do
        for _,card in ipairs(pile) do card.faceDown=false;card.abilityDisabledUntil=nil end
    end
    local h=m.humanBossState
    if h then
        h.forms={}
        local base=h.abilityBase
        if base then
            m.maxHp=base.maxHp;m.hp=math.min(m.hp,m.maxHp);m.damageLagHp=m.hp
            m.attack=base.attack;m.attackSpeed=base.attackSpeed
            m.creatureArmorMax=base.creatureArmorMax;m.creatureArmor=math.min(m.creatureArmor or 0,base.creatureArmor)
        end
        if m.bossData.humanBoss==9 then
            game.spnDiscardCap=h.openingDiscardCap or game.maxDiscards or 3
            game.discardsRemaining=math.max(game.discardsRemaining or 0,h.openingDiscards or game.spnDiscardCap)
        end
        require("src.human_bosses").finish(game)
    end
    require("src.enemy_abilities").plan(game,m)
end
function C.destroy(game,source,index,inCombat)
    local item,message=C.canDestroy(game,source,index,inCombat)
    if not item then return false,message end
    local targets=bosses(game)
    local D=require("src.deities")
    if source=="equipped" then D.destroyDeity(game,index,true,nil,"CHỦ ĐỘNG TIÊU HỦY · XÓA VƯƠNG QUYỀN")
    else
        table.remove(game.backpackDeities,index)
        if game.spnCombat then game.spnCombat[item]=nil end
        game.spnFeedback=game.spnFeedback or {}
        game.spnFeedback[#game.spnFeedback+1]={deity=item,slot=0,kind="destroy",text="CHỦ ĐỘNG TIÊU HỦY · XÓA VƯƠNG QUYỀN"}
        require("src.spn_reserves").destroyed(game)
    end
    for _,m in ipairs(targets) do C.seal(game,m) end
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=item,slot=0,text="VƯƠNG QUYỀN ĐÃ XÓA · NỘI TẠI / CHIÊU THỨC BOSS VÔ HIỆU ĐẾN HẾT TRẬN"}
    return true,"Đã tiêu hủy SPN. Nội tại và chiêu thức Boss bị vô hiệu hóa đến hết trận."
end
return C
