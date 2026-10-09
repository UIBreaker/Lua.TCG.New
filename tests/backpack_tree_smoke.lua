local Tree=require("ui.crafting_tree")
local B=require("src.basic_equipment")
local E=require("src.equipment")
local Bag=require("ui.backpack")
local function expectedRaw(id,count,out)
 local r=B.byResult[id]
 if not r then out[id]=(out[id] or 0)+count;return end
 for _,key in ipairs(r.ingredients) do expectedRaw(key,count,out) end
end
for _,recipe in ipairs(B.recipes) do
 local model=Tree.build(recipe.id);local expected={};expectedRaw(recipe.id,1,expected)
 for id,n in pairs(expected) do assert(model.raw[id]==n,recipe.id..":"..id) end
 for id,n in pairs(model.raw) do assert(expected[id]==n) end
 local overview=Tree.overviewModel(recipe.id);local unique={}
 for _,node in ipairs(overview.nodes) do assert(not unique[node.id] and node.count==model.totals[node.id]);unique[node.id]=node;assert(node.y+66<=overview.h) end
 for _,edge in ipairs(overview.edges) do assert(edge.from.x<edge.to.x,"ingredients flow toward their result") end
 assert(#model.edges==#model.nodes-1 and model.nodes[1].id==recipe.id)
 for _,node in ipairs(model.nodes) do assert(node.count>=1 and node.x>=0 and node.x+164<=model.w and node.y>=0 and node.y+62<=model.h) end
 for _,part in ipairs(Tree.ingredients(recipe.id)) do
  local found=false;for _,v in ipairs(Tree.upgrades(part.id)) do if v.id==recipe.id then found=true end end;assert(found)
 end
end
local parts=Tree.ingredients("gem_blast");assert(parts[2].id=="basic_spur" and parts[2].count==2)
Tree.history={};Tree.select("crafted_guard");Tree.mouse("bag_node_basic_plate");assert(Tree.id=="basic_plate" and #Tree.history==1)
assert(Tree.mouse("bag_tree_back") and Tree.id=="crafted_guard")
local previous=Tree.id;Tree.select("soul_crown",true);assert(Tree.id==previous)
for i=1,Bag.pageSize do local r=Bag.cellRect(i);assert(r.x>=212 and r.x+r.w<942 and r.y>=109 and r.y+r.h<641) end
local M=require("ui.equipment_motion")
for _,kind in ipairs({"equip","unequip"}) do
 local a={kind=kind,source=Bag.pocket,rect=Bag.cellRect(1)}
 local x,y=M.position(a,0);local x2,y2=M.position(a,1)
 local from,to=kind=="equip" and a.source or a.rect,kind=="equip" and a.rect or a.source
 assert(x==from.x+from.w/2 and y==from.y+from.h/2)
 assert(math.abs(x2-to.x-to.w/2)<.001 and math.abs(y2-to.y-to.h/2)<.001)
end
print("Backpack tree PASS: all 60 full ancestry trees, repeated quantities, upgrade edges, drill-down/back, soul exclusion, full-screen geometry and separate equipment trajectories")
return true
