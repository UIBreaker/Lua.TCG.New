local D=require("config.enemy_loadout_data")
local L={config=D}
local function find(list,id)
    for _,def in ipairs(list) do if def.id==id then return def end end
end
local function magic(m)
    return require("src.boss_abilities").passiveEnabled(m)
end
function L.profile(m)
    local stage=math.max(1,m.difficultyAnte or m.stage or m.round or 1)
    local tier=math.min(3,math.floor((stage-1)/7))
    return {stage=stage,strength=math.min(1.2,.35+.65*stage/20),
        budget=m.isBoss and 5+tier*5 or m.isElite and 3+tier*3 or 1+tier*2,
        slots=m.isBoss and 3 or m.isElite and 2 or 1}
end
function L.generate(m)
    local p=L.profile(m)
    local seed=p.stage*11+(m.encounterCount or p.stage)*7+(m.groupIndex or 1)*13
    local role=D.roles[seed%#D.roles+1]
    local bag={role=role.name,budget=p.budget,spent=0,strength=p.strength,
        equipment={},backpack={equipment={},consumables={}},attacks=0}
    local function take(def,kind)
        if not def or bag.spent+def.cost>bag.budget then return end
        local item={id=def.id,kind=kind,power=p.strength}
        bag.spent=bag.spent+def.cost;return item
    end
    local first=find(D.equipment,role.equipment[1])
    if first.cost>p.budget then first=find(D.equipment,"basic_feather") end
    bag.equipment[1]=take(first,"equipment")
    if (m.isBoss and p.stage>=4 or m.isElite and p.stage>=8) then bag.spn=take(find(D.spns,role.spn),"spn") end
    if p.stage>=3 and (m.isBoss or m.isElite and not bag.spn or not m.isElite and seed%2==0) then bag.seal=take(find(D.seals,role.seal),"seal") end
    for i=2,p.slots do
        local item=take(find(D.equipment,role.equipment[i]),"equipment")
        if item then bag.equipment[#bag.equipment+1]=item end
    end
    if m.isBoss and p.stage>=8 then
        local id=role.name=="Đấu sĩ" and "ward_stone" or "blood_ring"
        local item=take(find(D.equipment,id),"equipment")
        if item then bag.backpack.equipment[1]=item end
    end
    -- An edition spends budget and amplifies one item, not the whole monster.
    if p.stage>=5 and bag.spent<bag.budget then
        local edition=p.stage>=20 and "polychrome" or p.stage>=12 and "holographic" or "foil"
        local item=bag.equipment[1];item.edition=edition;bag.spent=bag.spent+1
    end
    if p.stage>=8 and bag.spent<bag.budget then
        bag.spent=bag.spent+1
        bag.backpack.consumables[1]={id="healing_potion",kind="consumable",pct=.12*p.strength}
    end
    return bag
end
function L.item(item)
    if not item then return end
    local def=find(item.kind=="seal" and D.seals or item.kind=="spn" and D.spns or D.equipment,item.id)
    if not def then return end
    local edition=D.editions[item.edition]
    return def,(item.power or 1)*(1+(edition and edition.power or 0))
end
function L.stats(m)
    local result={hp=0,damage=0,speed=0,armor=0,heal=0}
    for _,item in ipairs(m.enemyInventory and m.enemyInventory.equipment or {}) do
        local def,power=L.item(item)
        if def then for key,pct in pairs(def.stats) do result[key]=result[key]+pct*power end end
    end
    for key,cap in pairs(D.caps) do result[key]=math.min(cap,result[key]) end
    return result
end
function L.start(m)
    local old=m.enemyInventory
    local base=old and old.base or {maxHp=m.maxHp,armor=m.creatureArmor or 0}
    m.enemyInventory=L.generate(m);m.enemyInventory.base=base
    local stats=L.stats(m)
    m.maxHp=math.max(1,math.floor(base.maxHp*(1+stats.hp)))
    m.hp=m.maxHp;m.damageLagHp=m.hp
    local innate=m.creatureKind=="lava_golem" and math.max(1,math.floor(m.maxHp*.12)) or base.armor
    m.creatureArmor=math.min(math.floor(m.maxHp*.5),innate+math.floor(m.maxHp*stats.armor))
    m.creatureArmorMax=m.creatureArmor
end
function L.attack(m)
    if not m.enemyInventory then return m.attack or 12 end
    return math.floor((m.attack or 12)*(1+L.stats(m).damage))
end
function L.speed(m)
    if not m.enemyInventory then return math.min(999,m.attackSpeed or 1) end
    return math.min(999,math.max(1,math.floor((m.attackSpeed or 1)*(1+L.stats(m).speed))))
end
local function effect(m,kind,stat)
    if not magic(m) then return 0 end
    local item=m.enemyInventory and m.enemyInventory[kind]
    local def,power=L.item(item)
    return def and def.stat==stat and def.pct*power or 0
end
function L.supportMultiplier(m) return 1+effect(m,"spn","support") end
function L.attackBonus(m)
    local bag=m.enemyInventory
    if bag and (bag.attacks+1)%3==0 then return math.floor(L.attack(m)*effect(m,"spn","echo")) end
    return 0
end
function L.pierce(m) return effect(m,"seal","pierce") end
function L.plan(m)
    local bag=m.enemyInventory;if not bag then return end
    local potion=bag.backpack.consumables[1]
    local healingLeft=require("src.enemy_abilities").resources(m).healingLeft
    if potion and m.hp/m.maxHp<=.35 and healingLeft>0 then
        local value=math.min(math.floor(m.maxHp*potion.pct),healingLeft)
        return {type="consume",targetIndex=m.groupIndex or 1,value=value,
            label="Dùng thuốc từ balo: hồi "..value.." HP · 1 lần"}
    end
    local reserve=bag.backpack.equipment[1]
    if reserve and m.hp/m.maxHp<=.5 then
        return {type="equip",targetIndex=m.groupIndex or 1,value=0,label="Đổi trang bị từ balo: "..L.describeItem(reserve).name}
    end
end
function L.action(m)
    local bag=m.enemyInventory;if not bag then return end
    local kind=(m.intent or {}).type
    if kind=="consume" then
        local item=table.remove(bag.backpack.consumables,1);if not item then return end
        local value=require("src.enemy_abilities").heal(m,math.floor(m.maxHp*item.pct))
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,action="heal",target=m,value=value,label="Dùng thuốc từ balo"}
    elseif kind=="equip" then
        local item=table.remove(bag.backpack.equipment,1);if not item then return end
        -- Swap one slot, preserve HP, and retain the old item for inspection only.
        local old=bag.equipment[1];bag.equipment[1]=item;bag.stowed=old
        local stats=L.stats(m);local before=m.creatureArmor or 0
        m.maxHp=math.max(1,math.floor(bag.base.maxHp*(1+stats.hp)));m.hp=math.min(m.hp,m.maxHp)
        local def,power=L.item(item)
        local armor=math.floor(m.maxHp*(def.stats.armor or 0)*power)
        require("src.enemy_abilities").addArmor(m,armor)
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,action="equip",target=m,value=m.creatureArmor-before,label="Đổi trang bị · "..L.describeItem(item).name}
    end
end
function L.afterHit(m,damage,attack)
    local pct=effect(m,"seal","leech")
    if damage>0 and pct>0 and m.hp>0 then
        -- Player and enemy HP grow on different scales; leech uses enemy HP, reduced by blocked damage.
        local ratio=math.min(1,damage/math.max(1,attack or L.attack(m)))
        require("src.enemy_abilities").heal(m,math.floor(m.maxHp*math.min(.04,pct)*ratio))
    end
end
function L.afterAction(m,action,blocked)
    local bag=m.enemyInventory;if not bag or blocked or m.hp<=0 then return end
    if action=="attack" then bag.attacks=bag.attacks+1;return end
    if action=="equip" then return end
    local stats=L.stats(m)
    require("src.enemy_abilities").heal(m,math.floor(m.maxHp*stats.heal))
    local armorPct=math.min(.10,effect(m,"seal","supportArmor")+effect(m,"spn","supportArmor"))
    require("src.enemy_abilities").addArmor(m,math.floor(m.maxHp*armorPct))
end
local labels={damage="ST",speed="Tốc",hp="HP tối đa",armor="HP tối đa thành Giáp đầu trận",heal="HP tối đa sau hành động hỗ trợ"}
function L.describeItem(item)
    if item.kind=="consumable" then return {id=item.id,name="Bình Máu",desc="Dùng một lần khi HP ≤35%: hồi "..math.floor(item.pct*100).."% HP tối đa. Thay lượt đánh.",kind=item.kind} end
    local def,power=L.item(item)
    if not def then return {name=item.id,desc="",kind=item.kind} end
    local catalog=item.kind=="seal" and require("src.deck").SEALS or item.kind=="spn" and require("src.deities").CATALOG or require("src.equipment").ITEMS
    local source=catalog[item.id];local parts={}
    if def.stats then
        for _,key in ipairs({"damage","hp","speed","armor","heal"}) do
            if def.stats[key] then parts[#parts+1]=string.format("+%.1f%% %s",def.stats[key]*power*100,labels[key]):gsub("%.0%%","%%") end
        end
    else
        local p=def.pct*power*100
        local desc={leech="Gây mất HP: hồi %.1f%% HP tối đa bản thân (trần 4%%); giảm theo phần ST bị giáp/né chặn.",
            pierce="Đánh trúng: %.1f%% sát thương đòn đánh xuyên Giáp người chơi.",
            supportArmor="Sau hành động hỗ trợ: thêm Giáp bằng %.1f%% HP tối đa; trần chung 50%% HP.",
            support="Tăng %.1f%% hiệu lực các buff/hồi máu cho bản thân và đồng đội.",
            echo="Mỗi đòn thứ ba tăng %.1f%% ST từ chỉ số sau trang bị; vẫn có thể hụt."}
        parts[1]=string.format(desc[def.stat],p):gsub("%.0%%","%%")
    end
    local edition=D.editions[item.edition]
    return {id=item.id,name=source and source.name or item.id,kind=item.kind,
        desc=table.concat(parts," · "),edition=edition and edition.name,
        editionDesc=edition and ("Ấn bản tăng "..(edition.power*100).."% hiệu lực món này; đã tính vào các % bên trên.")}
end
function L.describe(m)
    local bag=m.enemyInventory;if not bag then return "Chưa có kho đồ" end
    return bag.role.." · "..#bag.equipment.." trang bị"..(bag.seal and " · 1 dấu" or "")..(bag.spn and " · 1 SPN" or "")
end
return L
