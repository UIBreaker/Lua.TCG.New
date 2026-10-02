-- Run from the project root: lua scripts/describe_gameplay_expansion.lua
-- Report tables are generated from the same definitions as gameplay and tooltips.
local Data=require("config.card_ability_data")
local Deck=require("src.deck")
local Boss=require("src.boss_abilities")
local Monster=require("src.monster")
local Run=require("src.run_manager")
local function parameters(t,scaling)
    local keys,parts={},{}
    for k in pairs(t) do keys[#keys+1]=k end
    table.sort(keys)
    for _,k in ipairs(keys) do
        local v=t[k]
        parts[#parts+1]=k..(scaling and " +" or "=")..(type(v)=="table" and (v.amount.." / "..v.every.." levels") or tostring(v))
    end
    return table.concat(parts,", ")
end
print("## 52 lá và bảng tiến hóa\n\n| Lá | Ability ID — Tên | Trigger | Cấp 0 | Tăng mỗi cấp |\n|---|---|---|---|---|")
local suits={heart="♥",diamond="♦",club="♣",spade="♠"}
for _,id in ipairs(Data.order) do
    local d=Data.definitions[id]
    print("| "..Deck.RANK_NAMES[d.rank]..suits[d.suit].." | `"..id.."` — "..d.name.." | "..d.trigger.." | "..parameters(d.baseParams).." | "..parameters(d.evolutionRules,true).." |")
end
local catalog,keys={},{}
for _,d in pairs(Monster.BOSSES) do catalog[d.debuffId]=d end
for id,d in pairs(Monster.DISRUPTIVE_BOSSES) do catalog[id]=d end
for id,d in pairs(Run.BOSS_DEBUFFS) do catalog[id]=d end
for id in pairs(catalog) do keys[#keys+1]=id end
table.sort(keys)
print("\n## Boss: nội tại, chủ động, hồi chiêu, counter\n\nTelegraph lần đầu: 1 tay; sau mỗi lần dùng/hủy: cooldown + 1 tay. Counter chung: 3♠/Q♠/9♠ hủy, 6♠ trì hoãn, K♠ bỏ hành động, A♠/4♠/7♠ tắt nội tại, 8♠ khóa cả hai.\n\n| Boss ID — Tên | Nội tại | Chủ động | Cooldown | Counter theo build |\n|---|---|---|---|---|")
local counters={black_tax_collector="Chi tiền trước thuế; giữ lá Bích để hủy Tịch Thu",memory_eater="Chia retrigger ra nhiều lá; bảo vệ khả năng lá mục tiêu",gatekeeper="Cân nhắc tay lớn / tấn công tăng; giữ tài nguyên dự phòng",executioner="Giữ HP trên ngưỡng; hủy Lưỡi Đao",gem_devourer="Chơi lá có ITM để không giữ trên tay",taxman="Giữ Vàng để không mất HP",echo_knight="Đổi thế đánh giữa hai tay",the_arm="Bích vô hiệu nội tại trước khi scoring",the_hook="Giữ 6♣/6♠ để tận dụng Khi Bỏ",damage_resist="Tắt nội tại trước đòn mạnh"}
for _,id in ipairs(keys) do
    local d=catalog[id];local m={isBoss=true,bossData=d};local a=d.active
    print("| `"..id.."` — "..(d.name or d.title).." | "..Boss.passiveDescription(m).." | "..a.name..": "..Boss.activeDescription(m).." | "..a.cooldown.." | "..(counters[id] or (id:find("lock_")==1 and "Dùng chất/rank khác hoặc tắt Nội Tại" or "Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt")).." |")
end
