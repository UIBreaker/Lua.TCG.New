local T={id="spirit_trial_emissary"}
local function pool(game)
    local list={}
    for _,hand in ipairs(require("src.poker").ALL_HANDS_ORDERED) do
        if (game.unlockedHands or {})[hand.id] then list[#list+1]=hand end
    end
    return list
end
local function active(game,fn)
    local D=require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            local source=D.resolveDeity(game.deities,slot,game)
            local owner=game.deities and game.deities[slot]
            if owner and source and source.id==T.id then fn(owner,slot) end
        end
    end
end
local function notice(game,owner,slot,text)
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=owner,slot=slot,text=text}
end
function T.register(D)
    local desc="Cần mở khóa ít nhất 3 thế bài. Mỗi trận yêu cầu 2 thế khác nhau được chọn ngẫu nhiên từ các thế đã mở. Đánh đủ cả hai theo bất kỳ thứ tự: tiến hóa ngẫu nhiên 1 SPN đang trang bị đúng 1 cấp, có thể trúng chính lá này. Mỗi bản chỉ thưởng một lần/trận; tiến hóa không đổi số yêu cầu hay mức thưởng."
    D.CATALOG[T.id]={id=T.id,name="Sứ Giả Khảo Luyện",stat="trialEvolution",values={value=1},rarity="common",cost=4,trigger="trial",
        descriptionTemplate=desc,desc=desc,baseDesc=desc,lore="Dị linh giữ hai cổng thử thách, đánh thức sức mạnh của người đồng hành vượt qua cả hai."}
end
function T.prepare(game)
    local available=pool(game);if #available<3 then return end
    active(game,function(owner,slot)
        game.spnCombat=game.spnCombat or {};local state=game.spnCombat[owner] or {};game.spnCombat[owner]=state
        if state.trial then return end
        local choices={};for i,h in ipairs(available) do choices[i]=h end
        local first=table.remove(choices,require("src.rng").random(#choices))
        local second=choices[require("src.rng").random(#choices)]
        state.trial={ids={first.id,second.id},names={first.vnName,second.vnName},seen={}}
        notice(game,owner,slot,"KHẢO LUYỆN · "..first.vnName.." + "..second.vnName)
    end)
end
function T.handEnd(game,hand)
    if #pool(game)<3 or not hand or not hand.type then return end
    -- The real hand-end hook runs once; card/SPN retriggers cannot farm rewards.
    active(game,function(owner,slot)
        local state=game.spnCombat and game.spnCombat[owner]
        local trial=state and state.trial
        if not trial or trial.done then return end
        for _,id in ipairs(trial.ids) do if hand.type.id==id then trial.seen[id]=true end end
        if not (trial.seen[trial.ids[1]] and trial.seen[trial.ids[2]]) then return end
        local targets,seen={},{}
        local D=require("src.deities")
        for index=1,D.getMaxSlots(game) do
            local card=game.deities and game.deities[index]
            if card and D.CATALOG[card.id] and not seen[card] then targets[#targets+1]=card;seen[card]=true end
        end
        if #targets==0 then return end
        trial.done=true
        local target=targets[require("src.rng").random(#targets)]
        D.evolve(target);trial.rewardName=target.name
        notice(game,owner,slot,"KHẢO LUYỆN XONG · "..target.name.." +1 CẤP TIẾN HÓA")
    end)
end
function T.describe(game,item)
    if not game then return end
    local state=game.spnCombat and game.spnCombat[item]
    local trial=state and state.trial
    if not trial and item.id~=T.id then return end
    if #pool(game)<3 then return "CHƯA HOẠT ĐỘNG · Cần mở khóa ít nhất 3 thế bài." end
    if not trial then return "KHẢO LUYỆN · Nhận 2 yêu cầu khi bắt đầu trận hoặc trang bị trong trận." end
    local text="KHẢO LUYỆN TRẬN NÀY"
    for i,id in ipairs(trial.ids) do text=text.."\n"..(trial.seen[id] and "XONG · " or "CHƯA · ")..trial.names[i] end
    if trial.done then text=text.."\nĐÃ THƯỞNG · "..trial.rewardName.." +1 cấp. Chờ trận mới." end
    return text
end
return T
