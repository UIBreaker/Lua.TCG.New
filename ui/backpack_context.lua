local Q=require("ui.backpack_qol")
local C={}
function C.capture(bag)
 if not bag.open then return nil end
 local view=Q.state(bag)
 local effects={};for _,effect in ipairs(require("src.ui").Polish.applications) do effects[effect]=true end
 return {tab=bag.tab,page=bag.page,offset=bag.loadoutOffset,query=view.query,sort=view.sort,filter=view.filter,effects=effects}
end
function C.restore(bag,context)
 if not context then return end
 Q.switch(bag,context.tab)
 local view=Q.state(bag)
 view.query=context.query;view.sort=context.sort;view.filter=context.filter;view.page=context.page
 bag.show();bag.loadoutOffset=context.offset;bag.message="Đã quay lại hành trang."
 local UI=require("src.ui")
 if context.effects then
  for i=#UI.Polish.applications,1,-1 do if not context.effects[UI.Polish.applications[i]] then table.remove(UI.Polish.applications,i) end end
 end
 if context.item and context.game then
  local kept=false;for _,item in ipairs(context.game.consumables or {}) do if item==context.item then kept=true;break end end
  bag.message=(kept and "Đã hủy · Giữ lại " or "Đã dùng · ")..tostring(context.item.name or "vật phẩm")
 end
 UI.Description.reset()
end
return C
