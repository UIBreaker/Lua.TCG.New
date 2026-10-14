local C=require("config.void_gacha")
local Rng=require("src.rng")
local D=require("src.deities")
local E=require("src.equipment")
local Deck=require("src.deck")
local Shop=require("src.shop")
local Basic=require("src.basic_equipment")
local Loadout=require("src.loadout")
local Clone=require("src.blood_shop").clone
local G={config=C}
local function ids(catalog)
    local list={};for id in pairs(catalog) do list[#list+1]=id end;table.sort(list);return list
end
local function choose(list) return list[Rng.random(#list)] end
function G.pick(roll)
    assert(type(roll)=="number" and roll>=1 and roll<=100000 and roll==math.floor(roll))
    local n=0;for _,row in ipairs(C.rates) do n=n+row.weight;if roll<=n then return row.id end end
    error("Void rates must sum to 100000")
end
local function rarity()
    local roll=Rng.random();local total=0
    for _,r in ipairs(D.RARITIES) do total=total+Shop.SPN_RARITY_WEIGHTS[r.id];if roll<total then return r.id end end
    return "unique"
end
local function deity(id,r)
    local item=Clone(D.CATALOG[id]);item.rarity=r;item.baseRarity=r
    for i,t in ipairs(D.RARITIES) do if t.id==r then item.baseRarityTier=i end end
    item.evolutionLevel=0;return item
end
local function playingCard(rank,suit,power)
    local card=Deck.newCard(rank,suit)
    if power then card.voidPower=power;card.baseChips=card.baseChips*power;card.bonusBaseChips=card.baseChips-Deck.getChipValue(rank) end
    return card
end
function G.enterIfDue(game)
    local run=game.run
    if not run or run.ante%10~=0 or run.currentBlindIndex~=3 or not run.blinds or run.blinds[3].status~="completed" then return false end
    local key=run.ante..":"..(run.regionId or "human");game.voidVisited=game.voidVisited or {}
    if game.voidVisited[key] then return false end
    local gear={};for _,id in ipairs(ids(E.ITEMS)) do if (E.ITEMS[id].craftTier or 0)>=3 or E.ITEMS[id].soulOnly then gear[#gear+1]=id end end
    if #gear==0 then gear=ids(E.ITEMS) end
    local promotion=Rng.random();local discount=promotion<.02 and 0 or promotion<.07 and .5 or promotion<.17 and .75 or 1
    game.voidEvent={ante=run.ante,spnId=choose(ids(D.CATALOG)),equipmentId=choose(gear),rank=Rng.random(2,14),suit=choose(Deck.SUIT_ORDER),
        goldMultiplier=discount==0 and 1 or discount,freeRemaining=discount==0 and 1 or 0,totalRolls=0,serial=0,results={},payment=(game.voidTickets or 0)>0 and "ticket" or "gold"}
    game.voidVisited[key]=true
    return true
end
function G.banner(game)
    local event=game.voidEvent;if not event then return {} end
    local spn=deity(event.spnId,"unique");spn.voidPower=5
    return {
        {kind="spn",item=spn,name=spn.name,label="SPN · UQ ×5",chance="0,002%",strength=9},
        {kind="equipment",item=E.instance(event.equipmentId,{voidPower=10}),name=E.ITEMS[event.equipmentId].name,label="TRANG BỊ ×10",chance="0,001%",strength=9},
        {kind="card",item=playingCard(event.rank,event.suit,10),name=Deck.RANK_NAMES[event.rank]..Deck.SUITS[event.suit].symbol,label="QUÂN BÀI ×10",chance="0,001%",strength=9},
    }
end
function G.quote(game,count,payment)
    local event=game.voidEvent
    if not event or (count~=1 and count~=10) or (payment~="gold" and payment~="ticket") then return end
    local free=math.min(count,event.freeRemaining or 0);local paid=count-free
    local cost=payment=="gold" and math.ceil(paid*C.price*event.goldMultiplier) or paid
    return {count=count,payment=payment,cost=cost,free=free,affordable=not event.pendingResults and (game[payment=="gold" and "gold" or "voidTickets"] or 0)>=cost}
end
function G.consumablePool()
    local pool,seen={},{}
    local function add(item) if item and not seen[item.id] then pool[#pool+1]=Clone(item);seen[item.id]=true end end
    for _,offer in ipairs(Shop.getRetailConsumables()) do add(offer.consumable) end
    for _,p in ipairs(Shop.POTIONS) do add(Shop.healingItem(nil,p.id).consumable) end
    add(Shop.destructionItem().consumable)
    local Run=require("src.run_manager")
    for _,support in ipairs(Shop.SOUL_SUPPORT) do add(Run[support.factory]()) end
    return pool
end
function G.createReward(game,id)
    local event=game.voidEvent;local r={id=id,strength=1}
    if id=="featured_spn" then r.kind="spn";r.item=deity(event.spnId,"unique");r.item.voidPower=5;r.featured=true
    elseif id=="featured_equipment" then r.kind="equipment";r.item=E.instance(event.equipmentId,{voidPower=10});r.featured=true
    elseif id=="featured_card" then r.kind="card";r.item=playingCard(event.rank,event.suit,10);r.featured=true
    elseif id=="spn" then r.kind="spn";r.item=deity(choose(ids(D.CATALOG)),rarity())
    elseif id=="equipment" then r.kind="equipment";r.item=E.instance(choose(ids(E.ITEMS)))
    elseif id=="card" then r.kind="card";r.item=playingCard(Rng.random(2,14),choose(Deck.SUIT_ORDER))
    elseif id=="consumable" then r.kind="consumable";r.item=Clone(choose(G.consumablePool()));r.strength=2
    elseif id=="pack" then
        r.kind="pack";r.item=Clone(choose(Shop.PACK_CATALOG));r.item.cost=0;r.item.category="pack";r.item.rewardPack=true
        r.opening=Shop.openPack(r.item,game);r.strength=4
        if #r.opening.cards==0 then r.kind="gold";r.amount=1;r.name="Rương rỗng → 1 Vàng";r.item=nil;r.opening=nil;r.strength=1 end
    elseif id=="voucher" then r.kind="voucher";r.item=Clone(choose(Shop.VOUCHERS));r.item.category="voucher";r.item.voucherId=r.item.id;r.item.cost=0;r.strength=4
    elseif id=="hand" then r.kind="hand";r.name="Mở rộng tay bài +1";r.strength=4
    elseif id=="ticket" then r.kind="ticket";r.amount=Rng.random(1,100);r.name="+"..r.amount.." Vé The Void";r.strength=3
    else r.kind=id; r.amount=id=="gold" and Rng.random(1,10) or Rng.random(1,5);r.name="+"..r.amount..(id=="gold" and " Vàng" or " Linh hồn") end
    if r.item then
        r.name=r.kind=="card" and r.item.rankName..r.item.suitSymbol or r.item.name
        r.strength=math.max(r.strength,C.strengths[r.item.rarity] or 1)
    end
    if r.featured then r.strength=9;r.name=r.name..(r.kind=="spn" and " · UQ ×5" or " · ×10") end
    return r
end
local function award(game,r)
    if r.kind=="gold" then game.gold=(game.gold or 0)+r.amount
    elseif r.kind=="souls" then game.souls=(game.souls or 0)+r.amount
    elseif r.kind=="ticket" then game.voidTickets=(game.voidTickets or 0)+r.amount
    elseif r.kind=="spn" then Loadout.storeDeity(game,r.item)
    elseif r.kind=="equipment" then Basic.store(game,r.item,0)
    elseif r.kind=="card" then Deck.addCardToDeck(game,r.item)
    elseif r.kind=="consumable" then Loadout.storeConsumable(game,r.item)
    elseif r.kind=="hand" then game.maxHandSize=(game.maxHandSize or 3)+1
    elseif r.kind=="pack" then
        game.rewardPacks=game.rewardPacks or {};game.rewardPacks[#game.rewardPacks+1]=r.opening
    elseif r.kind=="voucher" then
        if game.vouchers and game.vouchers[r.item.id] then
            r.kind="gold";r.amount=3;r.name="Đặc quyền trùng → 3 Vàng";r.strength=1;game.gold=(game.gold or 0)+3
        else local shop=Shop.new();shop.items={r.item};shop.mode="small";assert(Shop.buyItem(shop,1,game)) end
    end
end
function G.pull(game,count,payment)
    local quote=G.quote(game,count,payment)
    if not quote or not quote.affordable then return false,"Không đủ tài nguyên hoặc lượt quay trước chưa mở xong." end
    local results={}
    for i=1,count do results[i]=G.createReward(game,G.pick(Rng.random(1,100000))) end
    local event=game.voidEvent;local key=payment=="gold" and "gold" or "voidTickets"
    game[key]=(game[key] or 0)-quote.cost;event.freeRemaining=event.freeRemaining-quote.free
    for _,r in ipairs(results) do award(game,r) end
    event.serial=event.serial+1;event.totalRolls=event.totalRolls+count;event.results=results;event.pendingResults=true;event.lastQuote=quote
    return true,results
end
function G.finishReveal(game)
    if game.voidEvent then game.voidEvent.pendingResults=nil end
end
function G.ticketReward(boss)
    if Rng.random()>=(boss and C.bossTicketChance or C.ticketChance) then return end
    return {id="void_ticket",type="VOID_TICKET",source="THE VOID",name="VÉ THE VOID",amount=1,rarity="rare",desc="Một vé quay The Void. Dùng thay 100 vàng, lưu trong run; không có bảo hiểm."}
end
return G
