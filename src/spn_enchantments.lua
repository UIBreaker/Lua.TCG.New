local E={order={"spell_bastion","spell_mend","spell_prosper","spell_confluence",
    "spell_ladder","spell_balance","spell_retinue","spell_switchcraft"}}
E.retired={spell_solitude="spell_balance",spell_requiem="spell_balance",spell_chorus="spell_retinue",
    spell_ember="spell_mend",spell_seasons="spell_switchcraft",spell_escrow="spell_prosper",
    spell_recycle="spell_prosper",spell_metronome="spell_ladder",spell_caravan="spell_mend",
    spell_magnet="spell_ladder",spell_reprisal="spell_bastion",spell_codex="spell_switchcraft",
    spell_aura="spell_confluence",spell_ectoplasm="spell_bastion",spell_ankh="spell_retinue",spell_hex="spell_confluence"}
E.multCap=200
E.chipsCap=200
E.healCapPct=25
E.goldCap=9
function E.normalize(id) return E.retired[id] or id end
function E.get(id)
    local d=require("src.chest_expansion").byId[E.normalize(id)]
    return d and d.isEnchantment and d or nil
end
function E.catalog()
    local out={};for _,id in ipairs(E.order) do out[#out+1]=assert(E.get(id)) end;return out
end
function E.targets(game)
    local out,slots,seen={},{},{}
    for slot,d in pairs(game.deities or {}) do if type(slot)=="number" and type(d)=="table" then slots[#slots+1]=slot end end
    table.sort(slots)
    local function add(d,label)
        if not seen[d] then
            seen[d]=true
            local old=E.get(d.enchantment)
            out[#out+1]={target=d,label=label.."\n"..(old and "Thay "..old.name:gsub("Phù Phép ","") or "Chưa phù phép")}
        end
    end
    for _,slot in ipairs(slots) do add(game.deities[slot],"Ô SPN "..slot) end
    for i,d in ipairs(game.backpackDeities or {}) do add(d,"Balo "..i) end
    return out
end
function E.apply(game,item,target)
    local d=E.get(item.id);if not d then return nil end
    local options=E.targets(game)
    if #options==0 then return false,"Cần một SPN đang sở hữu để phù phép." end
    local valid=false
    for _,option in ipairs(options) do if option.target==target then valid=true;break end end
    if target and not valid then return false,"SPN đã chọn không còn được sở hữu; chưa dùng lá phép." end
    if not valid then
        if #options~=1 then return false,"choose_enchantment",item end
        target=options[1].target
    end
    local power=require("src.blood_shop").powerOf(item)
    if E.normalize(target.enchantment)==d.id and (target.enchantmentPower or 1)>=power then
        return false,"SPN đã mang phù phép này với hiệu lực bằng hoặc cao hơn."
    end
    target.enchantment=d.id;target.enchantmentPower=power
    return true,"Đã phù phép "..target.name..": "..d.name.."."
end
function E.openTarget(game,item,ui,callback)
    local d=E.get(item.id);if not d then return false,"Phù phép không hợp lệ." end
    local power=require("src.blood_shop").powerOf(item)
    local options={}
    for _,option in ipairs(E.targets(game)) do
        local target=option.target
        if E.normalize(target.enchantment)~=d.id or (target.enchantmentPower or 1)<power then options[#options+1]=option end
    end
    if #options==0 then return false,"Không có SPN phù hợp; chưa tiêu hao lá phép." end
    ui.openChoices(game,{{card=item,title=d.name.." · CHỌN SPN",description=d.desc,
        declineLabel="GIỮ LẠI LÁ PHÉP",options=options}},function(decisions)
        local choice=decisions[1];if choice then callback(choice.target) end
    end)
    return true
end
function E.migrateDeity(deity)
    if deity and deity.enchantment then deity.enchantment=E.normalize(deity.enchantment) end
end
function E.migrateItem(item)
    if not item then return end
    local d=E.get(item.id);if not d then return end
    for _,field in ipairs({"id","name","subtitle","desc","params","icon","color","isEnchantment"}) do item[field]=d[field] end
    item.artId=d.id
    item.category="joker_spell"
end
function E.reset(game)
    game.enchantmentCombat={gold=0}
    for _,option in ipairs(E.targets(game)) do E.migrateDeity(option.target) end
end
return E
