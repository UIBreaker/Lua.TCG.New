local Shop=require("src.shop")
local Deities=require("src.deities")
local Equipment=require("src.equipment")
local Poker=require("src.poker")
local Abilities=require("src.card_abilities")
local Run=require("src.run_manager")
local EnemyArt=require("src.enemy_art")
local rows={}
local function add(group,item,source)
    rows[#rows+1]={group=group,id=item.id or item.packType,name=item.name or item.vnName,
        ability=item.desc or item.description or "",rarity=item.rarity or "",source=source,
        handId=item.handId,rank=item.rank,suit=item.suit}
end
for _,d in pairs(Deities.CATALOG) do add("spn",d,"src/deities.lua") end
for _,id in ipairs(Equipment.POOL) do add("itm",Equipment.ITEMS[id],"src/equipment.lua") end
for _,group in ipairs({{"spectral",Shop.SPECTRAL_CARDS},{"spn_enchantment",Shop.JOKER_SPELLS},{"seal",Shop.SEAL_CARDS}}) do
    for _,item in ipairs(group[2]) do add(group[1],item,"src/shop.lua") end
end
for _,item in ipairs(require("src.card_effects").getEditionCatalog()) do add("edition",item,"config/card_effect_config.lua") end
for _,item in ipairs({Run.createSpeedSingleCard(),Run.createSpeedTeamCard()}) do add("speed",item,"src/run_manager.lua") end
add("evolution",Run.createEvolutionCard(),"src/run_manager.lua")
for _,item in ipairs(Poker.PLANET_CARDS) do item.desc=Shop.getConsumableDescription(item) or item.desc;add("planet",item,"src/poker.lua") end
for _,hand in ipairs(Poker.HAND_TYPES_ORDERED) do
    local book=Poker.SKILL_BOOKS[hand.id]
    add("hand",{id=hand.id,name=hand.vnName,desc=book and book.desc or "Thế đánh cơ bản."},"src/poker.lua")
end
for _,item in ipairs(Shop.PACK_CATALOG) do add("chest",item,"src/shop.lua") end
add("chest",{id="enchantment",name="Rương Phù Phép",desc="Ảnh riêng cho alias enchantment_pack; hiện cùng catalog phép với joker_edition, không thêm cơ chế mới."},"src/ui.lua:PACK_TYPE_MAP")
for _,item in ipairs(Shop.VOUCHERS) do add("voucher",item,"src/shop.lua") end
add("utility",{id="hand_expansion",name="Mở Rộng Tay Bài",desc="Tăng vĩnh viễn kích thước tay +1."},"src/shop.lua")
add("utility",{id="healing_potion",name="Bình Máu Thánh",desc="Hồi tối đa 25 HP."},"src/shop.lua")
add("back",{id="card_back",name="Mặt sau viễn chinh",desc="Mặt sau dùng chung cho mọi nhóm thẻ."},"ui/components/deck_counter.lua")
for _,item in ipairs(Shop.STANDARD_CARDS) do
    local def=Abilities.definition(item)
    local copy={};for k,v in pairs(item) do copy[k]=v end
    copy.name=item.name.." · "..(def and def.name or "")
    copy.desc=Abilities.description(item)
    add("playing",copy,"config/card_ability_data.lua")
    rows[#rows].op=def and def.op
end
for _,list in ipairs({EnemyArt.normal,EnemyArt.bosses}) do
    for _,id in ipairs(list) do
        local trait=require("src.enemy_abilities").types[id]
        local active=require("src.boss_abilities").actives[id]
        add("enemy",{id=id,name=id,desc=trait and trait.desc or active and active.description or "Đối thủ viễn chinh."},"src/enemy_art.lua")
    end
end
local function quote(s)
    return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"'
end
local function json(value)
    if type(value)=="string" then return quote(value) end
    if type(value)=="number" then return tostring(value) end
    local parts={}
    if #value>0 then for _,v in ipairs(value) do parts[#parts+1]=json(v) end;return "["..table.concat(parts,",").."]" end
    for k,v in pairs(value) do parts[#parts+1]=quote(k)..":"..json(v) end
    return "{"..table.concat(parts,",").."}"
end
table.sort(rows,function(a,b) return a.group..a.id<b.group..b.id end)
local f=assert(io.open("docs/continental_asset_inventory.json","wb"));f:write(json(rows));f:close()
print("Canonical continental assets: "..#rows)
