local Rng=require("src.rng")
local D=require("src.deities")
local E=require("src.equipment")
local Basic=require("src.basic_equipment")
local Loadout=require("src.loadout")
local Deck=require("src.deck")
local Blood=require("src.blood_shop")
local T={chance=.30,npcPath="assets/scene/events/mysterious_expeditioner.png",version=2}
T.kinds={spn="SPN",equipment="Trang bị",consumable="Tiêu hao",card="Quân bài",resource="Tài nguyên"}
local reasons={guard="Tôi cần thuốc và đồ phòng hộ để vượt vùng hiểm địa.",speed="Đoàn tôi cần ra đòn trước đối thủ.",wealth="Tôi cần nguồn lực cho một chuyến đi dài.",attack="Tôi đang tìm sức mạnh để đối mặt boss phía trước."}
local function copy(item) return Blood.clone(item) end
local function encode(item) return require("src.persistence").encode(item) end
local function integer(n) return type(n)=="number" and n==n and n>=0 and n<math.huge and n==math.floor(n) end
local function title(item) return item.name or item.characterName or ((item.rankName or tostring(item.rank or ""))..(item.suitSymbol or "")) end
local function itemStamp(item)
    local fields={"id","rank","baseRank","suit","baseChips","bonusBaseChips","speedBonus","maxSockets","unlockedSockets","allowDuplicateEquipment","rarity","baseRarity","baseRarityTier","evolutionLevel","edition","editionPower","enchantment","enchantmentPower","bloodPower","voidPower","seal","sealPower","enhancement","healAmt","armorAmt","permanentSpeed","investment","amount","resource","cost","potionPermanentDamage","potionPermanentMult","spnPermanentDamage"}
    fields[#fields+1]="bloodDomainPower";fields[#fields+1]="statuePower";fields[#fields+1]="statueSpeedPenalty"
    local stamp={};for _,field in ipairs(fields) do stamp[field]=item[field] end
    stamp.acquisitionCost=item.acquisitionCost
    stamp.acquisitionMarketValue=item.acquisitionMarketValue
    stamp.evolutionCredits=item.evolutionCredits
    stamp.equipments={};for _,eq in ipairs(item.equipments or {}) do stamp.equipments[#stamp.equipments+1]=itemStamp(eq) end
    if item.card then stamp.card=itemStamp(item.card) end
    return encode(stamp)
end
function T.describe(kind,item,game)
    if kind=="resource" then return item.desc end
    return select(2,require("src.card_description").resolve(item,game))
end
function T.role(kind,item)
    local s=(kind=="card" and require("src.card_abilities").description(item) or T.describe(kind,item)) or ""
    if s:find("Giáp",1,true) or s:find("HP",1,true) or s:find("hồi",1,true) then return "guard" end
    if s:find("Tốc",1,true) or s:find("tốc",1,true) then return "speed" end
    if s:find("Vàng",1,true) or s:find("vàng",1,true) or kind=="resource" then return "wealth" end
    return "attack"
end
function T.value(kind,item)
    if kind=="resource" then return item.amount*(item.resource=="voidTickets" and 1 or 3) end
    return require("src.shop").getMarketValue(item,kind)
end
local function resource(id,amount)
    return {id="barter_"..id,resource=id,amount=amount,name=(id=="souls" and "Linh Hồn" or "Vé The Void").." ×"..amount,
        desc="Trao đúng "..amount..(id=="souls" and " linh hồn." or " vé quay The Void; mỗi vé trị giá 1 vàng."),cost=amount*(id=="souls" and 3 or 1)}
end
function T.owned(game,kind)
    require("src.void_tickets").count(game)
    local list={}
    local function add(k,item,source,index,where,card)
        if k=="consumable" and require("src.void_tickets").isTicket(item) then return end
        if item and (not kind or kind==k) then
            list[#list+1]={key=k..":"..source..":"..(card and tostring(card.id)..":" or "")..index,kind=k,item=item,source=source,index=index,where=where,card=card}
        end
    end
    local slots={};for slot in pairs(game.deities or {}) do slots[#slots+1]=slot end;table.sort(slots)
    for _,slot in ipairs(slots) do add("spn",game.deities[slot],"active",slot,"Đang trang bị · Ô "..slot) end
    for i,item in ipairs(game.backpackDeities or {}) do add("spn",item,"reserve",i,"Trong balo") end
    for i,entry in ipairs(game.backpackEquipment or {}) do add("equipment",Basic.item(entry),"bag",i,"Trong balo") end
    for _,c in ipairs(game.persistentDeck or {}) do
        add("card",c,"deck",c.id,"Trong bộ bài")
        for i,eq in ipairs(c.equipments or {}) do add("equipment",eq,"socket",i,"Khảm trên "..title(c),c) end
    end
    for i,item in ipairs(game.consumables or {}) do add("consumable",item,"equipped",i,"Ô tiêu hao · "..(item.loadoutSlot or i)) end
    for i,item in ipairs(game.backpackConsumables or {}) do add("consumable",item,"bag",i,"Trong balo") end
    for _,id in ipairs({"souls","voidTickets"}) do
        local total=game[id] or 0
        if total>0 then
            local amounts=game.barterEvent and game.barterEvent.amounts or {}
            add("resource",resource(id,math.min(total,math.max(1,amounts[id] or 1))),"wallet",id,"Đang có "..total)
        end
    end
    return list
end
function T.inventory(game,side,filter)
    local all
    if side=="player" then all=T.owned(game)
    else all={};for _,entry in ipairs(game.barterEvent.stock) do all[#all+1]={key=entry.key,kind=entry.kind,item=entry.item,where="Hành trang người viễn chinh"} end end
    if not filter or filter=="all" then return all end
    local list={};for _,entry in ipairs(all) do if entry.kind==filter then list[#list+1]=entry end end;return list
end
local function newDraft() return {player={},npc={},playerGold=0,npcGold=0} end
function T.clear(game)
    local e=game.barterEvent;e.draft=newDraft();e.quote=nil;e.counter=nil;e.status="draft";e.thinkRemaining=nil;e.message="Chọn món từ hai kho đồ, thêm vàng rồi gửi lời đề nghị."
end
local function addStock(e,kind,item)
    e.serial=e.serial+1;e.stock[#e.stock+1]={key="npc:"..e.serial,kind=kind,item=copy(item)}
end
function T.create(game)
    local e={version=T.version,ante=game.run.ante,regionId=game.run.regionId,areaStage=game.run.areaStage,stock={},serial=0,
        gold=180+game.run.ante*40,need=({"guard","speed","wealth","attack"})[Rng.random(4)],temper=Rng.random(0,8),trades=0,rounds=0,
        filters={player="all",npc="all"},pages={player=1,npc=1},amounts={}}
    game.barterEvent=e;T.clear(game)
    local ids={};for id in pairs(D.CATALOG) do ids[#ids+1]=id end;table.sort(ids)
    local Shop=require("src.shop")
    for _=1,4 do
        local item=copy(D.CATALOG[ids[Rng.random(#ids)]])
        item.evolutionLevel=0;item.evolutionCredits=0;D.setRarity(item,Shop.rollSpnRarity(game).id)
        addStock(e,"spn",item)
    end
    ids={};for id in pairs(E.ITEMS) do ids[#ids+1]=id end;table.sort(ids)
    for _=1,4 do addStock(e,"equipment",E.instance(ids[Rng.random(#ids)])) end
    local retail=Shop.getRetailConsumables()
    for _=1,5 do local offer=retail[Rng.random(#retail)];local item=copy(offer.consumable);item.cost=offer.cost;addStock(e,"consumable",item) end
    for _,id in ipairs({"healing_potion","armor_potion_small","cons_draw"}) do
        local offer=Shop.healingItem(nil,id);local item=copy(offer.consumable);item.cost=offer.cost;addStock(e,"consumable",item)
    end
    for _=1,4 do
        local item=Deck.newCard(Rng.random(2,14),({"hearts","diamonds","clubs","spades"})[Rng.random(4)])
        item.evolutionLevel=Rng.random(0,2);if Rng.random()<.35 then require("src.card_effects").setEffect(item,"foil") end
        addStock(e,"card",item)
    end
    addStock(e,"resource",resource("souls",Rng.random(3,15)));addStock(e,"resource",resource("voidTickets",Rng.random(1,3)))
    T.initiate(game);return e
end
function T.roll(game)
    if game.bloodDomain then return false end
    local run=game.run
    if not run or run.ante%2~=0 or run.currentBlindIndex~=3 or not run.blinds or not run.blinds[3] or run.blinds[3].status~="completed" then return false end
    local key=run.ante..":"..(run.regionId or "human");game.barterChecked=game.barterChecked or {}
    if game.barterChecked[key] then return false end
    game.barterChecked[key]=true;return Rng.random()<T.chance
end
function T.restore(game)
    local e=game.barterEvent;if not e then return end
    if e.version~=T.version then T.create(game);return end
    for _,entry in ipairs(e.stock or {}) do
        local item=entry.item
        if entry.kind=="equipment" then entry.item=E.instance(item.id,item)
        elseif entry.kind=="spn" and D.CATALOG[item.id] then
            local restored=copy(D.CATALOG[item.id]);for k,v in pairs(item) do restored[k]=v end;entry.item=restored
        elseif entry.kind=="card" then
            Deck.ensureNextCardId(item.id);for i,eq in ipairs(item.equipments or {}) do item.equipments[i]=E.instance(eq.id,eq) end
        end
    end
end
function T.toggle(game,side,key)
    local e=game.barterEvent;if not e or e.status=="thinking" or (side~="player" and side~="npc") then return false end
    local found;for _,entry in ipairs(T.inventory(game,side)) do if entry.key==key then found=entry;break end end
    if not found then return false end
    local selected=e.draft[side]
    if not selected[key] and side=="player" then
        for _,entry in ipairs(T.owned(game)) do
            if selected[entry.key] and (entry.kind=="card" and found.card==entry.item or found.kind=="card" and entry.card==found.item) then selected[entry.key]=nil end
        end
    end
    selected[key]=not selected[key] or nil;e.status="draft";e.quote=nil;e.counter=nil
    e.message="Đề nghị đã thay đổi. Gửi để người viễn chinh cân nhắc lại.";return true
end
function T.setGold(game,side,amount)
    local e=game.barterEvent;if not e or e.status=="thinking" or not integer(amount) or (side~="player" and side~="npc") then return false end
    e.draft[side.."Gold"]=math.min(amount,side=="player" and (game.gold or 0) or e.gold)
    e.quote=nil;e.counter=nil;e.status="draft";e.message="Đề nghị đã thay đổi. Gửi để người viễn chinh cân nhắc lại.";return true
end
function T.setAmount(game,id,amount)
    local e=game.barterEvent
    if not e or e.status=="thinking" or (id~="souls" and id~="voidTickets") or not integer(amount) or amount<1 or amount>(game[id] or 0) then return false end
    e.amounts[id]=amount;e.quote=nil;e.counter=nil;e.status="draft";e.message="Đề nghị đã thay đổi. Gửi để người viễn chinh cân nhắc lại.";return true
end
local function picked(game,draft)
    if type(draft)~="table" or type(draft.player)~="table" or type(draft.npc)~="table" or not integer(draft.playerGold) or not integer(draft.npcGold) then return nil,"Đề nghị không hợp lệ." end
    local result={player={},npc={}};local stamps={}
    for _,side in ipairs({"player","npc"}) do
        local map={};for _,entry in ipairs(T.inventory(game,side)) do map[entry.key]=entry end
        for key,selected in pairs(draft[side]) do
            if selected then
                local entry=map[key];if not entry then return nil,"Một món đã rời kho. Hãy chọn lại." end
                result[side][#result[side]+1]=entry;stamps[#stamps+1]=side..key..itemStamp(entry.item)
            end
        end
        table.sort(result[side],function(a,b) return a.key<b.key end)
    end
    local cards={};local n=0
    for _,entry in ipairs(result.player) do if entry.kind=="card" then cards[entry.item]=true;n=n+1 end end
    if n>0 and n>=#(game.persistentDeck or {}) then return nil,"Đoàn cần giữ ít nhất một quân bài trong bộ bài." end
    for _,entry in ipairs(result.player) do if entry.card and cards[entry.card] then return nil,"Trang bị đã đi kèm quân bài, không thể tính hai lần." end end
    if draft.playerGold>(game.gold or 0) or draft.npcGold>game.barterEvent.gold then return nil,"Một bên không còn đủ vàng cho đề nghị này." end
    if #result.player==0 and draft.playerGold==0 or #result.npc==0 and draft.npcGold==0 then return nil,"Mỗi bên cần đưa vật phẩm hoặc vàng lên bàn." end
    table.sort(stamps);result.stamp=table.concat(stamps,"|")..encode(draft)..encode(game.barterEvent.amounts);return result
end
function T.quoteValue(game,kind,item,side)
    local e=game.barterEvent
    if side=="npc" then return T.value(kind,item)*(1.12+e.temper*.01) end
    local demand=T.role(kind,item)==e.need and 1.25 or 1
    local duplicates=0
    for _,held in ipairs(e.stock) do if held.kind==kind and held.item.id==item.id then duplicates=duplicates+1 end end
    local basis=kind=="resource" and T.value(kind,item) or require("src.shop").getResaleBasis(item,kind)
    return basis*.72*demand/(1+duplicates*.25)
end
function T.valuation(game,draft)
    local entries,msg=picked(game,draft);if not entries then return nil,msg end
    local e=game.barterEvent;local give,take=0,0
    for _,entry in ipairs(entries.player) do
        give=give+T.quoteValue(game,entry.kind,entry.item,"player")
    end
    for _,entry in ipairs(entries.npc) do take=take+T.quoteValue(game,entry.kind,entry.item,"npc") end
    entries.give=math.floor(give);entries.take=math.ceil(take);entries.balance=entries.give+draft.playerGold-entries.take-draft.npcGold;return entries
end
local function counterFor(game,draft)
    local e=game.barterEvent;local counter=copy(draft)
    local entries=T.valuation(game,counter);if not entries then return end
    local margin=math.ceil(math.max(entries.take,entries.give)*.12*math.max(0,1-(e.rounds or 0)*.25))
    local net=entries.take-entries.give+margin
    counter.playerGold=math.max(0,net);counter.npcGold=math.min(e.gold,math.max(0,-net))
    if counter.playerGold>(game.gold or 0) then
        -- Bridge the shortfall with useful objects instead of demanding impossible gold.
        local candidates=T.owned(game)
        table.sort(candidates,function(a,b)
            local av=T.value(a.kind,a.item)*(T.role(a.kind,a.item)==e.need and 2 or 1)
            local bv=T.value(b.kind,b.item)*(T.role(b.kind,b.item)==e.need and 2 or 1)
            if av==bv then return a.key<b.key end;return av>bv
        end)
        local added=0
        for _,entry in ipairs(candidates) do
            if not counter.player[entry.key] then
                counter.player[entry.key]=true;counter.playerGold=0;counter.npcGold=0
                local trial=T.valuation(game,counter)
                if trial then
                    added=added+1;net=trial.take-trial.give+margin
                    counter.playerGold=math.max(0,net);counter.npcGold=math.min(e.gold,math.max(0,-net))
                    if counter.playerGold<=(game.gold or 0) then break end
                else counter.player[entry.key]=nil end
                if added>=3 then break end
            end
        end
    end
    local final=T.valuation(game,counter);if final and final.balance>=0 then return counter end
end
function T.initiate(game)
    local e=game.barterEvent;if not e or e.status=="thinking" then return false end
    local owned=T.owned(game);local draft=newDraft()
    table.sort(owned,function(a,b)
        local av=T.role(a.kind,a.item)==e.need;local bv=T.role(b.kind,b.item)==e.need
        if av~=bv then return av end;return a.key<b.key
    end)
    local mode=(e.trades+e.temper)%3
    if owned[1] and mode~=2 then draft.player[owned[1].key]=true;draft.npcGold=1 end
    if mode~=1 or not owned[1] then
        local stock=copy(e.stock);table.sort(stock,function(a,b) return T.value(a.kind,a.item)<T.value(b.kind,b.item) end)
        if stock[1] then draft.npc[stock[1].key]=true;draft.npcGold=0;if not owned[1] or mode==2 then draft.playerGold=1 end end
    end
    e.counter=counterFor(game,draft)
    e.message=e.counter and (reasons[e.need]..(mode==1 and " Tôi muốn mua món của bạn. Đây là số vàng tôi có thể trả." or " Tôi có một đề nghị. Bạn có thể xem rồi trả giá lại.")) or "Hãy xem hành trang của tôi. Bạn muốn thương lượng món nào?"
    return e.counter~=nil
end
function T.propose(game)
    local e=game.barterEvent;if not e or e.status=="thinking" then return false end
    local entries,msg=T.valuation(game,e.draft)
    if not entries then e.message=msg;return false,msg end
    e.pendingStamp=entries.stamp;e.status="thinking";e.thinkRemaining=.95;e.counter=nil;e.quote=nil
    e.message="Người viễn chinh cân nhắc từng món, kiểm tra hành trang và đếm số vàng…";return true
end
function T.update(game,dt)
    local e=game.barterEvent;if not e or e.status~="thinking" then return false end
    e.thinkRemaining=math.max(0,(e.thinkRemaining or 0)-dt);if e.thinkRemaining>0 then return false end
    local entries,msg=T.valuation(game,e.draft);e.rounds=e.rounds+1
    if not entries or entries.stamp~=e.pendingStamp then e.status="refused";e.message=msg or "Hành trang đã thay đổi. Hãy kiểm tra lại đề nghị.";return true end
    if entries.balance>=0 then
        e.status="agreed";e.quote={stamp=entries.stamp,draft=copy(e.draft)}
        e.message="Tôi đồng ý. Chúng ta đều có thứ cần cho chuyến đi. Hãy chốt thỏa thuận khi bạn sẵn sàng."
    else
        local cashOnly=e.temper%3==0 and #entries.player>0 and #entries.npc>0
        for _,entry in ipairs(entries.player) do if T.role(entry.kind,entry.item)==e.need then cashOnly=false end end
        local offer=e.draft
        if cashOnly and (game.gold or 0)>=entries.take then
            offer=copy(e.draft);offer.player={};offer.playerGold=1;offer.npcGold=0
        else cashOnly=false end
        e.counter=counterFor(game,offer);e.status=e.counter and "counter" or "refused"
        e.message=e.counter and (reasons[e.need].." Đề nghị hiện tại chưa đủ. Tôi đề xuất thay đổi vật phẩm hoặc phần vàng bên dưới; bạn vẫn có thể trả giá tiếp.")
            or "Tôi không thể cân bằng cuộc đổi này với đồ và số vàng hiện có. Hãy bớt món muốn lấy, chọn đồ khác hoặc rời đi."
        if cashOnly and e.counter then e.message="Những món bạn đưa chưa hợp chuyến đi của tôi. Tôi muốn bán món này bằng vàng. Đây là giá tôi đề xuất; bạn có thể trả giá tiếp." end
    end
    return true
end
function T.useCounter(game)
    local e=game.barterEvent;if not e or not e.counter or e.status=="thinking" then return false end
    local entries,msg=T.valuation(game,e.counter)
    if not entries or entries.balance<0 then e.message=msg or "Đề nghị đã thay đổi.";return false end
    e.draft=copy(e.counter);e.counter=nil;e.status="agreed";e.quote={stamp=entries.stamp,draft=copy(e.draft)}
    e.message="Đây là toàn bộ điều khoản họ đề xuất. Bạn có thể chốt hoặc chỉnh lại để trả giá.";return true
end
local function removePlayer(game,entries)
    -- Descending indices keep multiple removals from the same inventory exact.
    table.sort(entries,function(a,b)
        local ak=a.kind..a.source..(a.card and tostring(a.card.id) or "");local bk=b.kind..b.source..(b.card and tostring(b.card.id) or "")
        if ak~=bk then return ak<bk end;return a.index>b.index
    end)
    for _,entry in ipairs(entries) do
        if entry.kind=="resource" then
            if entry.item.resource=="voidTickets" then assert(require("src.void_tickets").spend(game,entry.item.amount))
            else game[entry.item.resource]=game[entry.item.resource]-entry.item.amount end
        elseif entry.kind=="card" then
            for i,c in ipairs(game.persistentDeck) do if c==entry.item then table.remove(game.persistentDeck,i);break end end
            for _,pile in ipairs({game.hand or {},game.deck or {},game.discardPile or {}}) do
                for i=#pile,1,-1 do if pile[i].id==entry.item.id then table.remove(pile,i) end end
            end
        elseif entry.kind=="spn" then
            if entry.source=="active" then game.deities[entry.index]=nil else table.remove(game.backpackDeities,entry.index) end
        elseif entry.kind=="equipment" then
            if entry.card then table.remove(entry.card.equipments,entry.index) else table.remove(game.backpackEquipment,entry.index) end
        elseif entry.source=="equipped" then table.remove(game.consumables,entry.index)
        else table.remove(game.backpackConsumables,entry.index) end
    end
    game.masterDeck=game.persistentDeck;game.selectedIndices={}
end
local function grant(game,entry,budget)
    local item=copy(entry.item)
    if entry.kind~="resource" then
        item.acquisitionCost=math.min(T.value(entry.kind,item),budget)
        item.acquisitionMarketValue=T.value(entry.kind,item)
    end
    if entry.kind=="spn" then Loadout.storeDeity(game,item)
    elseif entry.kind=="equipment" then Basic.store(game,item,item.acquisitionCost or item.investment or 0)
    elseif entry.kind=="card" then Deck.addCardToDeck(game,item)
    elseif entry.kind=="resource" then
        if item.resource=="voidTickets" then require("src.void_tickets").add(game,item.amount)
        else game[item.resource]=(game[item.resource] or 0)+item.amount end
    else Loadout.storeConsumable(game,item) end
end
function T.accept(game)
    local e=game.barterEvent
    if not e or e.status~="agreed" or not e.quote then return false,"Hai bên cần đồng ý cùng một đề nghị trước khi chốt." end
    local entries,msg=T.valuation(game,e.draft)
    if not entries or entries.stamp~=e.quote.stamp or encode(e.draft)~=encode(e.quote.draft) or entries.balance<0 then
        e.quote=nil;e.status="draft";e.message=msg or "Hành trang hoặc giá đã thay đổi. Hãy thương lượng lại.";return false,e.message
    end
    local receipt={given={},received={},playerGold=e.draft.playerGold,npcGold=e.draft.npcGold}
    for _,entry in ipairs(entries.player) do receipt.given[#receipt.given+1]=title(entry.item) end
    for _,entry in ipairs(entries.npc) do receipt.received[#receipt.received+1]=title(entry.item) end
    removePlayer(game,entries.player)
    local total=0
    for _,entry in ipairs(entries.npc) do total=total+T.value(entry.kind,entry.item) end
    local budget=math.max(0,entries.give+e.draft.playerGold-e.draft.npcGold)
    for _,entry in ipairs(entries.npc) do
        grant(game,entry,math.floor(budget*T.value(entry.kind,entry.item)/total))
    end
    for i=#e.stock,1,-1 do if e.draft.npc[e.stock[i].key] then table.remove(e.stock,i) end end
    for _,entry in ipairs(entries.player) do addStock(e,entry.kind,entry.item) end
    game.gold=(game.gold or 0)-e.draft.playerGold+e.draft.npcGold;e.gold=e.gold+e.draft.playerGold-e.draft.npcGold
    e.trades=e.trades+1;e.lastReceipt=receipt;e.history=e.history or {};e.history[#e.history+1]=receipt
    T.clear(game);e.status="complete";e.message="Đã trao đủ vật phẩm và vàng. Bạn có thể tiếp tục thương lượng hoặc lên đường.";return true,e.message
end
return T
