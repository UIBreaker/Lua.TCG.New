local Q={}
local utf8=require("utf8")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local accents={a="àáạảãâầấậẩẫăằắặẳẵÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ",e="èéẹẻẽêềếệểễÈÉẸẺẼÊỀẾỆỂỄ",i="ìíịỉĩÌÍỊỈĨ",o="òóọỏõôồốộổỗơờớợởỡÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ",u="ùúụủũưừứựửữÙÚỤỦŨƯỪỨỰỬỮ",y="ỳýỵỷỹỲÝỴỶỸ",d="đĐ"}
local fold={};for letter,chars in pairs(accents) do for _,code in utf8.codes(chars) do fold[code]=letter end end
local searchCache=setmetatable({},{__mode="k"})
function Q.normalize(s)
 local out={};for _,code in utf8.codes(tostring(s or "")) do out[#out+1]=fold[code] or utf8.char(code):lower() end
 return table.concat(out)
end
function Q.state(bag)
 bag.views=bag.views or {};bag.views[bag.tab]=bag.views[bag.tab] or {query="",sort=1,filter=1,page=1}
 return bag.views[bag.tab]
end
function Q.matches(item,query)
 if query=="" then return true end
 local definition=item.rank and require("src.card_abilities").definition(item)
 local source=table.concat({item.name or "",item.desc or "",item.statSummary or "",item.rankName or "",item.suitName or "",definition and definition.characterName or "",definition and definition.name or ""}," ")
 local cached=searchCache[item]
 if not cached or cached.source~=source then cached={source=source,text=Q.normalize(source)};searchCache[item]=cached end
 local text=cached.text
 for word in Q.normalize(query):gmatch("%S+") do if not text:find(word,1,true) then return false end end
 return true
end
function Q.list(bag,game,list,recipes)
 local state=Q.state(bag);local out={}
 for _,v in ipairs(list) do
  local item=recipes and E.ITEMS[v.recipe.id] or v.item
  local include=Q.matches(item,state.query)
  if bag.pending and bag.tab=="cards" and state.filter==2 then include=include and E.canAttach(item,bag.pendingItem)
  elseif recipes and state.filter==2 then include=include and B.canCraft(game,v.recipe)
  elseif bag.tab=="equipment" then include=include and (state.filter==1 or state.filter==2 and item.basic or state.filter==3 and not item.basic)
  elseif bag.tab=="cards" then include=include and (state.filter==1 or state.filter==2 and E.getUsedSlots(item)>0 or state.filter==3 and E.getUsedSlots(item)==0) end
  if include then out[#out+1]=v end
 end
 if state.sort>1 then table.sort(out,function(a,b)
  local ai,bi=recipes and E.ITEMS[a.recipe.id] or a.item,recipes and E.ITEMS[b.recipe.id] or b.item
  if state.sort==3 then
   local av=recipes and (B.canCraft(game,a.recipe) and 1 or 0) or ai.rank or E.getTier(ai)
   local bv=recipes and (B.canCraft(game,b.recipe) and 1 or 0) or bi.rank or E.getTier(bi)
   if av~=bv then return av>bv end
  end
  local an,bn=Q.normalize(ai.name or ai.rankName),Q.normalize(bi.name or bi.rankName)
  if an~=bn then return an<bn end;return a.index<b.index
 end) end
 return out
end
function Q.switch(bag,tab)
 Q.state(bag).page=bag.page;bag.tab=tab;bag.page=Q.state(bag).page
 bag.selected=nil;bag.selectedSource=nil;bag.drag=nil;bag.searchFocus=false;bag.searchSelectAll=false;bag.lastClick=nil;bag.message=nil
 bag.cells={};bag.loadoutSlots={}
 love.keyboard.setTextInput(false)
 require("src.ui").Polish.clearFocus()
end
function Q.resetPage(bag)
 bag.page=1;Q.state(bag).page=1;bag.selected=nil;bag.selectedSource=nil;bag.message=nil
 bag.cells={}
 require("src.ui").Polish.clearFocus()
end
function Q.text(bag,text)
 if not bag.open or not bag.searchFocus then return false end
 local state=Q.state(bag)
 local query=(bag.searchSelectAll and "" or state.query)..text;bag.searchSelectAll=false
 if utf8.len(query)>60 then query=query:sub(1,utf8.offset(query,61)-1) end
 state.query=query;Q.resetPage(bag)
 return true
end
function Q.erase(bag)
 local state=Q.state(bag);local at=utf8.offset(state.query,-1)
 if bag.searchSelectAll then state.query="";bag.searchSelectAll=false;Q.resetPage(bag)
 elseif at then state.query=state.query:sub(1,at-1);Q.resetPage(bag) end
end
return Q
