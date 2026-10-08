-- Backpack receipts store an ID and actual investment; legacy ID-only saves remain valid.
local B = {basic={}, recipes={}, definitions={}}
local colors={heal={.35,.85,.55,1},armor={.4,.7,.95,1},speed={.35,.9,.9,1},gold={.95,.78,.35,1}}
local rows={
 {"basic_bandage","Băng Vải",2,"heal",1,"A rolled linen bandage tied with a green cord on a mossy expedition table, forest ruins behind"},
 {"basic_herb","Rễ Sinh Lực",3,"heal",2,"One thick medicinal root with two green leaves in a wooden bowl on a forest camp stone"},
 {"basic_salve","Hộp Cao Lành",4,"heal",3,"An open bronze tin of emerald healing salve with a wooden applicator at a ruined forest infirmary"},
 {"basic_plate","Tấm Sắt",2,"armor",2,"One simple curved iron armor plate with two rivets resting on stone in a snowy western mountain forge"},
 {"basic_leather","Da Thuộc",3,"armor",4,"A folded heavy brown hide armor pad with broad stitched seams at a windswept coastal camp"},
 {"basic_chain","Khoanh Xích",4,"armor",6,"A tightly coiled length of thick steel chain on a frost dusted anvil, clear circular silhouette"},
 {"basic_lace","Dây Giày",3,"speed",1,"One pair of braided silver blue boot laces laid in a clear loop on a coastal expedition stone"},
 {"basic_spur","Đinh Thúc",5,"speed",2,"A single steel riding spur with a small star wheel and leather strap on a glacial pass camp rock"},
 {"basic_feather","Lông Gió",7,"speed",3,"One long silver feather pinned in a simple bronze clasp on a high forest cliff, subtle horizontal breeze"},
 {"basic_pouch","Túi Đồng",5,"gold",1,"One small worn brown leather coin purse with a few antique copper coins on a desert caravan table"},
 {"basic_weight","Quả Cân",10,"gold",2,"One large brass merchant scale weight beside two antique coins on a bone gold desert market slab"},
 {"basic_stamp","Con Dấu Buôn",15,"gold",3,"One simple bronze merchant seal stamp beside an unlettered wax seal and coins in a ruined western caravan post"},
}
local big={
 {"crafted_guard","Áo Hộ Mệnh",2,{"basic_bandage","basic_plate"},{heal=2,armor=4},"A sturdy green padded expedition vest reinforced by iron plates, on a mossy western ruin stone"},
 {"crafted_runner","Ủng Hồi Sức",2,{"basic_herb","basic_lace"},{heal=3,speed=2},"One pair of worn forest green leather walking boots with silver laces and a medicinal herb pouch, at a forest trail"},
 {"crafted_bulwark","Giáp Hành Quân",3,{"basic_leather","basic_spur"},{armor=6,speed=3},"One broad leather and steel expedition cuirass with a wind swept blue cloak in a cold mountain pass"},
 {"crafted_medic","Túi Quân Y",3,{"basic_salve","basic_pouch"},{heal=4,gold=1},"One large open leather field medic satchel showing a bronze salve tin, linen rolls and a tiny coin pocket in a forest infirmary"},
 {"crafted_caravan","Khiên Thương Đội",3,{"basic_chain","basic_weight"},{armor=8,gold=2},"One broad iron caravan shield with a central brass weight shaped boss and short chain, on desert caravan stones"},
 {"crafted_courier","La Bàn Giao Thương",4,{"basic_feather","basic_stamp"},{speed=4,gold=3},"One large antique bronze merchant compass with a silver feather needle and wax seal, on a coastal expedition map without letters"},
}
local function description(p)
 local parts={}
 for _,r in ipairs({"heal","armor","speed","gold"}) do
  if p[r] then parts[#parts+1]="+"..p[r].." "..({heal="HP",armor="Giáp",speed="Tốc đánh",gold="Vàng"})[r] end
 end
 local summary=table.concat(parts," · ")
 return summary..(p.speed and (p.heal or p.armor or p.gold) and ". Tốc khi gắn; chỉ số khác khi lá tính điểm." or p.speed and " cho lá được gắn." or " khi lá tính điểm."),summary
end
local function add(id,name,cost,p,concept,basic)
 local desc,summary=description(p)
 local d={id=id,name=name,cost=cost,slotsNeeded=1,rarity=basic and "common" or "uncommon",basic=basic,crafted=not basic,params=p,concept=concept,
  color=colors[p.gold and "gold" or p.speed and "speed" or p.armor and "armor" or "heal"],attackSpeed=p.speed or 0,desc=desc,statSummary=summary:gsub("Tốc đánh","Tốc")}

 d.onCardScore=function(_,_,index,context)
  if index==0 then return nil end
  local gold=p.gold or 0
  -- Shared six-gold allowance across these new items, never a persistent preview mutation.
  if context and gold>0 then
   gold=math.min(gold,math.max(0,6-(context.basicEquipmentGold or 0)))
   context.basicEquipmentGold=(context.basicEquipmentGold or 0)+gold
  end
  return {healHp=p.heal,addArmor=p.armor,addGold=gold,message=name}
 end
 if p.gold then d.desc=d.desc.." Các trang bị cơ bản/ghép: tối đa 6 Vàng mỗi tay." end
 B.definitions[#B.definitions+1]=d
 if basic then B.basic[#B.basic+1]=id end
 return d
end
for _,r in ipairs(rows) do add(r[1],r[2],r[3],{[r[4]]=r[5]},r[6],true) end
for _,r in ipairs(big) do
 local total=r[3]
 for _,id in ipairs(r[4]) do for _,d in ipairs(B.definitions) do if d.id==id then total=total+d.cost end end end
 add(r[1],r[2],total,r[5],r[6],false)
end
function B.install(E)
 B.recipes=require("config.equipment_recipes");B.byResult={}
 for _,r in ipairs(B.recipes) do
  assert(E.ITEMS[r.id] and not E.ITEMS[r.id].soulOnly,"Invalid craft result: "..r.id)
  assert(not B.byResult[r.id],"Duplicate recipe: "..r.id);B.byResult[r.id]=r
 end
 local visiting={}
 local function price(id)
  local d=assert(E.ITEMS[id],"Missing ingredient: "..id)
  assert(not d.soulOnly,"Soul relics cannot be ingredients: "..id)
  if d.basic then return d.cost end
  local r=assert(B.byResult[id],"Missing ordinary recipe: "..id)
  if r.craftCost then return r.craftCost end
  assert(not visiting[id],"Cyclic recipe: "..id);visiting[id]=true
  local n=r.fee;for _,ingredient in ipairs(r.ingredients) do n=n+price(ingredient) end
  r.craftCost=n;visiting[id]=nil
  d.legacyCost=d.cost;d.craftTier=r.tier;d.craftCost=n
  d.cost=math.ceil(n*1.5) -- Commissioned stock costs more than making it yourself.
  return n
 end
 for id,d in pairs(E.ITEMS) do if not d.basic and not d.soulOnly then price(id) end end
end
function B.entryId(entry) return type(entry)=="table" and entry.id or entry end
function B.item(entry)
 local d=require("src.equipment").ITEMS[B.entryId(entry)]
 if not d then return nil end
 if type(entry)~="table" then return d end
 local copy={};for k,v in pairs(d) do copy[k]=v end;copy.acquisitionCost=entry.investment or 0;return copy
end
function B.investment(entry)
 if type(entry)=="table" then return entry.investment or 0 end
 local d=require("src.equipment").ITEMS[entry];return d and (d.legacyCost or d.cost) or 0
end
function B.resale(entry) return math.floor(B.investment(entry)/3) end
function B.store(game,item,cost)
 game.backpackEquipment=game.backpackEquipment or {}
 game.backpackEquipment[#game.backpackEquipment+1]={id=item.id,investment=math.max(0,cost or 0)}
end
function B.count(game,id)
 local n=0;for _,v in ipairs(game.backpackEquipment or {}) do if B.entryId(v)==id then n=n+1 end end;return n
end
function B.canCraft(game,recipe)
 if (game.gold or 0)<recipe.fee then return false,"Thiếu vàng trả công ghép." end
 local need={};for _,id in ipairs(recipe.ingredients) do need[id]=(need[id] or 0)+1 end
 for id,n in pairs(need) do if B.count(game,id)<n then return false,"Thiếu nguyên liệu trong balo." end end
 return true
end
function B.craft(game,recipe)
 local valid=false;for _,r in ipairs(B.recipes) do if r==recipe then valid=true end end
 if not valid then return false,"Công thức không hợp lệ." end
 local ok,msg=B.canCraft(game,recipe);if not ok then return false,msg end
 local investment=recipe.fee
 for _,id in ipairs(recipe.ingredients) do for i,v in ipairs(game.backpackEquipment) do if B.entryId(v)==id then investment=investment+B.investment(v);table.remove(game.backpackEquipment,i);break end end end
 game.gold=game.gold-recipe.fee;B.store(game,require("src.equipment").ITEMS[recipe.id],investment)
 return true,"Đã ghép "..require("src.equipment").ITEMS[recipe.id].name.."."
end
function B.attach(game,index,card)
 local E=require("src.equipment");local entry=(game.backpackEquipment or {})[index];local id=B.entryId(entry)
 local owned=false;for _,c in ipairs(game.persistentDeck or {}) do if c==card then owned=true end end
 if not owned or not id or not E.ITEMS[id] then return false,"Hãy chọn trang bị và lá bài của bạn." end
 local ok,msg=E.attach(card,B.item(entry));if ok then table.remove(game.backpackEquipment,index) end
 return ok,msg
end
function B.detach(game,card,index)
 local owned=false;for _,c in ipairs(game.persistentDeck or {}) do if c==card then owned=true end end
 if not owned or not (card.equipments or {})[index] then return false end
 game.backpackEquipment=game.backpackEquipment or {}
 local eq=card.equipments[index]
 B.store(game,eq,eq.acquisitionCost or eq.legacyCost or eq.cost);table.remove(card.equipments,index);return true
end
return B
