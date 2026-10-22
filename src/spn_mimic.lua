local Boss=require("src.boss_abilities")
local M={MAX_ACTIVATIONS=require("config.card_ability_data").maxTriggersPerHand}
local D
local cache=setmetatable({},{__mode="k"})
local function clone(value)
    if type(value)~="table" then return value end
    local out={};for k,v in pairs(value) do out[k]=clone(v) end;return out
end
function M.register(deities)
    D=deities
    local entry={id="spirit_right_echo",name="Vọng Linh Hữu Ảnh",stat="copyActivations",values={value=1},integerEffect=true,
        trigger="copy",isCopyDeity=true,rarity="common",cost=4,lore="Dị linh rỗng mượn tiếng vọng từ người đồng hành phía phải.",
        descriptionTemplate="Sao chép khả năng SPN ngay bên phải, kích hoạt {value} lần tại ô này theo điều kiện và cấp của nguồn. Mỗi cấp thêm 1 lần; tối đa 128 lần/sự kiện. Ô phải trống hoặc bị khóa: không kích hoạt."}
    entry.desc=entry.descriptionTemplate:gsub("{value}","1");entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
end
local function resolveRaw(list,slot,game,locked)
    D=D or require("src.deities")
    local owner=list and list[slot]
    if not owner or owner.id~="spirit_right_echo" then return owner,1 end
    local target,index,count=owner,slot,1
    local seen={}
    while target and target.id=="spirit_right_echo" do
        if seen[target] or locked and locked[index] or game and Boss.isSlotLocked(game,"spn",index) then return nil,0 end
        seen[target]=true
        count=math.min(M.MAX_ACTIVATIONS,count*D.scaleEffect(target,{copyActivations=1}).copyActivations)
        index=index+1;target=list[index]
    end
    if not target or locked and locked[index] or game and Boss.isSlotLocked(game,"spn",index) then return nil,0 end
    local record=cache[owner]
    if not record then record={};cache[owner]=record end
    local proxy=record[target.id]
    if not proxy then proxy={};record[target.id]=proxy end
    for key in pairs(proxy) do proxy[key]=nil end
    for key,value in pairs(target) do proxy[key]=value end
    proxy.edition=owner.edition;proxy.enchantment=owner.enchantment
    proxy.spnGrowth=owner.mimicGrowth and owner.mimicGrowth[target.id] or clone(target.spnGrowth)
    return proxy,count
end
function M.resolve(list,slot,game,locked)
    if locked and locked[slot] or game and Boss.isSlotLocked(game,"spn",slot) then return nil,0 end
    local source,count=resolveRaw(list,slot,game,locked)
    if not source then return nil,0 end
    local first
    for index,item in pairs(list or {}) do
        if type(index)=="number" and type(item)=="table" and item.id and (not first or index<first) then first=index end
    end
    if slot==first and source.id~="spirit_left_refrain" then
        local repeats=0
        for index,item in pairs(list or {}) do
            if type(index)=="number" and type(item)=="table" and index~=slot
                and not (locked and locked[index]) and not (game and Boss.isSlotLocked(game,"spn",index)) then
                local repeater,activations=resolveRaw(list,index,game,locked)
                if repeater and repeater.id=="spirit_left_refrain" then
                    repeats=math.min(M.MAX_ACTIVATIONS-1,repeats+D.scaleEffect(repeater,{copyActivations=2}).copyActivations*activations)
                end
            end
        end
        count=math.min(M.MAX_ACTIVATIONS,count*(1+repeats))
    end
    return source,count
end
-- Run existing mechanics with a separate owned identity at the copier's slot.
-- Restore the physical card even on errors, but retain intentional self-destruction/replacement.
function M.each(game,list,slot,fn,locked)
    local physical=list and list[slot]
    local effective,count=M.resolve(list,slot,game,locked)
    if not effective or effective.id=="spirit_left_refrain" then return end
    if not physical or physical.id~="spirit_right_echo" then
        local result
        for _=1,count do if list[slot]~=physical then break end;result=fn(effective) end
        return result
    end
    for i=1,count do
        if list[slot]~=physical then break end
        local gameList=game and game.deities
        local previous=gameList and gameList[slot]
        list[slot]=effective;if gameList then gameList[slot]=effective end
        local feedbackStart=game and #(game.spnFeedback or {}) or 0
        local ok,err=pcall(fn,effective)
        -- Feedback belongs to the equipped copier, not its temporary effect proxy.
        if game then for j=feedbackStart+1,#(game.spnFeedback or {}) do
            local event=game.spnFeedback[j];if event.deity==effective then event.deity=physical end
        end end
        if list[slot]==effective then list[slot]=physical end
        if gameList and gameList~=list and gameList[slot]==effective then gameList[slot]=previous end
        if effective.spnGrowth then
            physical.mimicGrowth=physical.mimicGrowth or {};physical.mimicGrowth[effective.id]=effective.spnGrowth
        end
        if not ok then error(err,0) end
    end
end
return M
