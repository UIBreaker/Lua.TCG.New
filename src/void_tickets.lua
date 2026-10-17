local V={id="void_ticket"}
function V.isTicket(item) return type(item)=="table" and item.id==V.id end
function V.item()
    return {id=V.id,category="void_ticket",name="Vé The Void",cost=1,rarity="rare",color={.73,.53,.96,1},
        desc="Vé quay The Void: 10 vé cho 1 lần quay, 100 vé cho 10 lần. The Void trừ trực tiếp vé trong balo hoặc ô tiêu hao. Dùng để đổi 1 vé lấy 1 vàng."}
end
local function valid(n) return type(n)=="number" and n==n and n>=0 and n<math.huge and n==math.floor(n) end
local function lists(game) game.backpackConsumables=game.backpackConsumables or {};game.consumables=game.consumables or {};return {game.backpackConsumables,game.consumables} end
function V.count(game)
    local total=0;local piles=lists(game)
    for _,pile in ipairs(piles) do for _,item in ipairs(pile) do if V.isTicket(item) then total=total+1 end end end
    if not game.voidTicketInventoryVersion then
        -- A legacy wallet is moved once; later the actual cards are the only source of truth.
        local legacy=tonumber(game.voidTickets) or 0;legacy=valid(legacy) and legacy or 0
        for _=total+1,legacy do piles[1][#piles[1]+1]=V.item() end
        total=math.max(total,legacy);game.voidTicketInventoryVersion=1
    end
    game.voidTickets=total;return total
end
function V.add(game,amount,receipt)
    if not valid(amount) then return false end
    V.count(game)
    for _=1,amount do local item=V.item();item.victoryRewardReceipt=receipt;game.backpackConsumables[#game.backpackConsumables+1]=item end
    game.voidTickets=game.voidTickets+amount;return true
end
function V.spend(game,amount)
    if not valid(amount) or V.count(game)<amount then return false end
    local left=amount
    for _,pile in ipairs(lists(game)) do
        for i=#pile,1,-1 do if left>0 and V.isTicket(pile[i]) then table.remove(pile,i);left=left-1 end end
    end
    V.count(game);return true
end
function V.redeem(game,source,index,amount)
    V.count(game);amount=amount or 1
    if source~="reserve" and source~="equipped" or not valid(amount) or amount<1 then return false end
    local pile=source=="reserve" and game.backpackConsumables or game.consumables
    if not V.isTicket(pile[index]) then return false end
    local available=0;for _,item in ipairs(pile) do if V.isTicket(item) then available=available+1 end end
    if available<amount then return false end
    table.remove(pile,index);local left=amount-1
    for i=#pile,1,-1 do if left>0 and V.isTicket(pile[i]) then table.remove(pile,i);left=left-1 end end
    game.gold=(game.gold or 0)+amount;V.count(game);return true,amount
end
return V
