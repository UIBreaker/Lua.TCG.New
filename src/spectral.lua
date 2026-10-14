-- Seven permanent deck tools. Shop, stored cards and old saves share one runtime.
local S={cards={},byId={}}
local function add(id,name,desc,limit,hp,icon,color)
    local d={id=id,name=name,subtitle=name,desc=desc,limit=limit,hpCost=hp or 0,
        category="spectral",icon=icon,color=color,params={},cost=8}
    S.cards[#S.cards+1]=d;S.byId[id]=d
end
add("spec_cryptid","Đối Ảnh","Chọn 1 lá trong bộ: tạo 1 bản sao giữ mọi nâng cấp vĩnh viễn, ID riêng. Trả 5 HP; bản sao vào chồng rút, không thêm ngay lên tay.",1,5,"◈",{0.40,0.75,0.95,1})
add("spec_immolate","Thiêu Rụi","Chọn 1–2 lá trong bộ để tiêu hủy vĩnh viễn; +5 Vàng mỗi lá. Không thể hủy lá cuối bộ bài.",2,0,"♨",{0.95,0.40,0.20,1})
add("spec_sigil","Ấn Ký","Chọn chất và 1–3 lá trong bộ: đổi vĩnh viễn sang chất đó, giữ nâng cấp. Trả 3 HP cho cả lần dùng.",3,3,"✥",{0.50,0.85,0.65,1})
add("spec_ouija","Cầu Cơ","Chọn rank 2–A và 1–2 lá trong bộ: đổi vĩnh viễn sang rank đó, giữ nâng cấp. Trả 4 HP cho cả lần dùng; không giảm kích thước tay.",2,4,"◉",{0.75,0.35,0.85,1})
add("spec_rethread","Hoán Y","Chọn 2 lá bất kỳ trong bộ: hoán đổi toàn bộ ITM và cường hóa. Giữ rank, chất, dấu, ấn bản, tiến hóa và tốc đánh. Phải đủ hốc và hợp lệ trang bị ở cả hai lá.",2,0,"✦",{0.75,0.64,0.9,1})
add("spec_shrink","Giải Phóng Vương Quyền","Tiêu hủy 1 lá J/Q/K được chọn: +1 kích thước tay vĩnh viễn, giảm 10 HP tối đa (còn ít nhất 25). Không thể hủy lá cuối bộ bài.",1,0,"♕",{0.75,0.64,0.9,1})
add("spec_black_hole","Hố Đen","Tăng +1 cấp tất cả thế đánh Poker, gồm thế nâng cao. Giữ trạng thái mở khóa; không thêm chi phí phụ.",0,0,"●",{0.30,0.30,0.45,1})
S.retired={spec_familiar="spec_cryptid",spec_grim="spec_cryptid",spec_incantation="spec_cryptid",
    spec_stairway="spec_ouija",spec_twin="spec_ouija",spec_molt="spec_rethread",
    spec_prune="spec_immolate",spec_migration="spec_sigil",spec_inversion="spec_ouija",
    spec_temper="spec_rethread",spec_fission="spec_cryptid",spec_redistribute="spec_sigil",
    spec_distill="spec_rethread",spec_partition="spec_ouija",spec_consolidate="spec_rethread",
    spec_keystone="spec_ouija",spec_heritage="spec_rethread",spec_synthesis="spec_rethread",
    spec_sieve="spec_immolate",spec_traverse="spec_sigil",spec_rebirth="spec_cryptid"}
function S.normalize(id) return S.retired[id] or id end
function S.get(id) return S.byId[S.normalize(id)] end
function S.migrateItem(item)
    local d=item and S.get(item.id);if not d then return end
    for _,key in ipairs({"id","name","subtitle","desc","icon","color","params","limit","hpCost","category"}) do item[key]=d[key] end
    item.artId=d.id
end
function S.describe(item)
    local d=S.get(item.id);if not d then return end
    local n=require("src.blood_shop").powerOf(item)
    if n==1 then return d.desc end
    local text=d.desc
    if d.id=="spec_cryptid" then text=text:gsub("tạo 1 bản sao","tạo "..n.." bản sao")
    elseif d.id=="spec_immolate" then text=text:gsub("%+5 Vàng","+"..5*n.." Vàng")
    elseif d.id=="spec_shrink" then text=text:gsub("%+1 kích thước","+"..n.." kích thước")
    elseif d.id=="spec_black_hole" then text=text:gsub("%+1 cấp","+"..n.." cấp") end
    return text.."\nCường hóa ×"..n.." · Số mục tiêu và chi phí phụ giữ nguyên."
end
local function label(c) return (c.rankName or tostring(c.rank))..(c.suitSymbol or "") end
local function suit(c) return (require("src.deck").SUITS[c.suit] or {}).id or c.suit end
function S.targets(game,item,request)
    local d=S.get(item.id);local out={};request=request or {}
    if not d then return out end
    for _,c in ipairs(game.persistentDeck or {}) do if not c.destroyed then
        local valid=d.id~="spec_shrink" or c.rank>=11 and c.rank<=13
        if d.id=="spec_sigil" and request.suit then valid=valid and suit(c)~=suit({suit=request.suit}) end
        if d.id=="spec_ouija" and request.rank then valid=valid and (c.baseRank or c.rank)~=request.rank end
        if valid then out[#out+1]={target=c,label=label(c)} end
    end end
    return out
end
local function gearFits(recipient,source)
    local E=require("src.equipment");local ids={}
    if E.getUsedSlots(source)>E.getMaxSlots(recipient) then return false end
    for _,eq in ipairs(source.equipments or {}) do
        if ids[eq.id] and not recipient.allowDuplicateEquipment then return false end
        ids[eq.id]=true
    end
    return true
end
function S.validate(game,item,request)
    local d=S.get(item.id);if not d then return false,"Dị Thể không hợp lệ." end
    if (game.playerHp or 100)<=d.hpCost then return false,"Cần hơn "..d.hpCost.." HP; chưa dùng Dị Thể." end
    if d.id=="spec_black_hole" then return true,{} end
    if not request or not request.cards then return false,"choose_spectral",item end
    local count=#request.cards
    if count<1 or count>d.limit or d.id=="spec_rethread" and count~=2 then return false,"Số lá chọn không hợp lệ." end
    local chosen,seen={},{}
    for _,target in ipairs(request.cards) do
        local found
        for _,c in ipairs(game.persistentDeck or {}) do if c.id==target.id and not c.destroyed then found=c;break end end
        if not found or seen[found.id] then return false,"Lá chọn không còn trong bộ hoặc bị chọn trùng; chưa dùng Dị Thể." end
        seen[found.id]=true;chosen[#chosen+1]=found
    end
    local live=0;for _,c in ipairs(game.persistentDeck or {}) do if not c.destroyed then live=live+1 end end
    if (d.id=="spec_immolate" or d.id=="spec_shrink") and count>=live then return false,"Phải giữ lại ít nhất 1 lá trong bộ bài." end
    if d.id=="spec_shrink" then
        if chosen[1].rank<11 or chosen[1].rank>13 then return false,"Phải chọn J, Q hoặc K." end
        if (game.maxPlayerHp or 100)<35 then return false,"Cần ít nhất 35 HP tối đa." end
    elseif d.id=="spec_sigil" then
        local info=require("src.deck").SUITS[request.suit]
        if not info then return false,"Chọn chất mới." end
        for _,c in ipairs(chosen) do if suit(c)==info.id then return false,"Lá đã mang chất này; chưa dùng Dị Thể." end end
    elseif d.id=="spec_ouija" then
        local r=request.rank
        if type(r)~="number" or r~=math.floor(r) or r<2 or r>14 then return false,"Chọn rank từ 2 đến A." end
        for _,c in ipairs(chosen) do if (c.baseRank or c.rank)==r then return false,"Lá đã mang rank này; chưa dùng Dị Thể." end end
    elseif d.id=="spec_rethread" then
        if not gearFits(chosen[1],chosen[2]) or not gearFits(chosen[2],chosen[1]) then return false,"Thiếu hốc hoặc trùng ITM ở lá nhận; chưa dùng Dị Thể." end
        if #(chosen[1].equipments or {})==0 and #(chosen[2].equipments or {})==0 and chosen[1].enhancement==chosen[2].enhancement then
            return false,"Hai lá không có trang bị/cường hóa để hoán đổi."
        end
    end
    return true,chosen
end
function S.apply(game,item,request)
    local ok,chosen,extra=S.validate(game,item,request);if not ok then return false,chosen,extra end
    local d=S.get(item.id);local id=d.id;local Deck=require("src.deck");local B=require("src.blood_shop")
    local power=B.powerOf(item);local sync=require("src.chest_expansion").sync
    game.playerHp=(game.playerHp or 100)-d.hpCost
    if id=="spec_cryptid" then
        for _=1,power do
            local copy=Deck.cloneCard(chosen[1]);copy.id=Deck.newCard(copy.rank,copy.suit).id
            copy.equipments=B.clone(chosen[1].equipments or {})
            copy.sealPower=chosen[1].sealPower;copy.faceDown=false;copy.exhausted=false
            copy.overchargeStacks=0;copy.destroyed=nil;copy.destructionNotified=nil
            Deck.addCardToDeck(game,copy)
            if game.deck then table.insert(game.deck,Deck.cloneCard(copy)) end
        end
    elseif id=="spec_sigil" or id=="spec_ouija" then
        for _,c in ipairs(chosen) do Deck.transformCard(game,c,id=="spec_ouija" and request.rank or nil,id=="spec_sigil" and request.suit or nil) end
    elseif id=="spec_rethread" then
        local a,b=chosen[1],chosen[2];local ea,eb=B.clone(a.equipments or {}),B.clone(b.equipments or {})
        local ha,hb=a.enhancement,b.enhancement
        sync(game,a,function(c) c.equipments=B.clone(eb);c.enhancement=hb end)
        sync(game,b,function(c) c.equipments=B.clone(ea);c.enhancement=ha end)
    elseif id=="spec_immolate" or id=="spec_shrink" then
        for _,c in ipairs(chosen) do
            require("src.card_abilities").destroy(game,c)
            sync(game,c,function(o) o.destroyed=true;o.destructionNotified=true end)
        end
        require("src.combat").cleanupDestroyedCards(game)
        game.selectedIndices={};for i,c in ipairs(game.hand or {}) do if c.selected then game.selectedIndices[#game.selectedIndices+1]=i end end
        if id=="spec_immolate" then game.gold=(game.gold or 0)+5*#chosen*power
        else
            game.maxHandSize=(game.maxHandSize or 3)+power;game.maxPlayerHp=(game.maxPlayerHp or 100)-10
            game.playerHp=math.min(game.playerHp,game.maxPlayerHp)
        end
    elseif id=="spec_black_hole" then
        game.handLevels=game.handLevels or {}
        for _,h in ipairs(require("src.poker").ALL_HANDS_ORDERED) do game.handLevels[h.id]=(game.handLevels[h.id] or 1)+power end
    end
    return true,"Đã dùng "..d.name.."."
end
function S.openTarget(game,item,ui,callback)
    local d=S.get(item.id);if not d then return false,"Dị Thể không hợp lệ." end
    if d.id=="spec_black_hole" then callback({});return true end
    if (game.playerHp or 100)<=d.hpCost then return false,"Cần hơn "..d.hpCost.." HP; chưa dùng Dị Thể." end
    if d.id=="spec_shrink" and (game.maxPlayerHp or 100)<35 then return false,"Cần ít nhất 35 HP tối đa." end
    local request={cards={}}
    local function destination()
        return request.rank and " → "..(require("src.deck").RANK_NAMES[request.rank] or request.rank) or
            request.suit and " → "..require("src.deck").STANDARD_SUIT_NAMES[request.suit] or ""
    end
    local function pick(title,options,nextStep)
        local description=S.describe(item)
        if #request.cards>0 then
            local names={};for _,c in ipairs(request.cards) do names[#names+1]=label(c) end
            description=description.."\nĐã chọn: "..table.concat(names," · ")
        end
        ui.openChoices(game,{{card=item,title=d.name.." · "..title,description=description,
            declineLabel="GIỮ LẠI DỊ THỂ",options=options}},function(decisions)
            if decisions[1] then nextStep(decisions[1].target) end
        end)
    end
    local function pairAvailable(c)
        for _,o in ipairs(S.targets(game,item)) do
            if o.target.id~=c.id and S.validate(game,item,{cards={c,o.target}}) then return true end
        end
        return false
    end
    local function confirm()
        local names={};for _,c in ipairs(request.cards) do names[#names+1]=label(c) end
        pick("XÁC NHẬN: "..table.concat(names," · ")..destination(),
            {{target=item,label="DÙNG DỊ THỂ"}},function() callback(request) end)
    end
    local count
    local function pickCard()
        local options={}
        for _,o in ipairs(S.targets(game,item,request)) do
            local taken=false;for _,c in ipairs(request.cards) do if c.id==o.target.id then taken=true end end
            if not taken then
                if d.id=="spec_rethread" and #request.cards==1 then
                    local candidate={cards={request.cards[1],o.target}}
                    if S.validate(game,item,candidate) then options[#options+1]=o end
                elseif d.id~="spec_rethread" or pairAvailable(o.target) then options[#options+1]=o end
            end
        end
        if #options==0 then return end
        pick("CHỌN LÁ "..(#request.cards+1).." / "..count..destination(),options,function(c)
            request.cards[#request.cards+1]=c
            if #request.cards==count then confirm() else pickCard() end
        end)
    end
    local function pickCount()
        local available=#S.targets(game,item,request);local limit=math.min(d.limit,available)
        if d.id=="spec_immolate" then limit=math.min(limit,#(game.persistentDeck or {})-1) end
        if d.id=="spec_rethread" then count=2;pickCard();return end
        if limit==1 then count=1;pickCard();return end
        local options={};for n=1,limit do options[#options+1]={target={id="spec_count_"..n,count=n},label=n.." lá"} end
        if #options>0 then pick("CHỌN SỐ LÁ",options,function(o) count=o.count;pickCard() end) end
    end
    local targets=S.targets(game,item,request)
    if d.id=="spec_rethread" then
        local valid=false;for _,o in ipairs(targets) do if pairAvailable(o.target) then valid=true;break end end
        if not valid then return false,"Không có cặp bài hợp lệ để hoán đổi; chưa dùng Dị Thể." end
    end
    if #targets==0 or d.id=="spec_rethread" and #targets<2 or d.id=="spec_shrink" and #(game.persistentDeck or {})<2 or d.id=="spec_immolate" and #(game.persistentDeck or {})<2 then
        return false,"Không có mục tiêu phù hợp; chưa tiêu hao Dị Thể."
    end
    if d.id=="spec_sigil" then
        local Deck=require("src.deck");local options={}
        for _,s in ipairs(Deck.SUIT_ORDER) do
            if #S.targets(game,item,{suit=s})>0 then options[#options+1]={target={id="spec_suit_"..s,suit=s},label=Deck.STANDARD_SUIT_NAMES[s].." "..Deck.SUITS[s].symbol} end
        end
        pick("CHỌN CHẤT",options,function(o) request.suit=o.suit;pickCount() end)
    elseif d.id=="spec_ouija" then
        local options={};for r=2,14 do
            if #S.targets(game,item,{rank=r})>0 then options[#options+1]={target={id="spec_rank_"..r,rank=r},label=require("src.deck").RANK_NAMES[r] or tostring(r)} end
        end
        pick("CHỌN RANK",options,function(o) request.rank=o.rank;pickCount() end)
    else pickCount() end
    return true
end
return S
