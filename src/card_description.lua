local A = require("src.card_abilities")
local Boss = require("src.boss_abilities")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Deck = require("src.deck")
local Effects = require("src.card_effects")
local DescriptionView = require("ui.components.card_description")
local D = {}
local hoverItem, hoverAge, offered = nil, 0, false
function D.update(dt)
    hoverAge = hoverAge + dt
end
function D.reset() hoverItem=nil;hoverAge=0 end
function D.finishFrame()
    if not offered then D.reset() end
    offered=false
end
D.glossary = {
    {"Tái kích hoạt","Lặp điểm và hiệu ứng của cùng lá; không tính lại điểm nền của thế bài."},
    {"Giữ","Nằm trên tay, không được chơi trong tay vừa kết thúc."},
    {"Tiêu hủy","Xóa đúng instance khỏi run; hiến tế bán hàng không phải tiêu hủy."},
    {"Không tính điểm","Được chơi nhưng không thuộc thế poker được chấm."},
    {"Nâng bậc","Tăng cấp thông số khả năng, không đổi rank/chất. Cấp tạm mất khi hết trận."},
    {"Khóa Boss","Ngăn Nội Tại hoặc Chủ Động trong số tay ghi trên khả năng."},
    {"Nội Tại","Luật áp chế duy trì của Boss; có thể bị vô hiệu tạm thời."},
    {"Kỹ Năng Chủ Động","Hành động đã báo trước, có hồi chiêu và có thể bị hủy/trì hoãn."},
}
function D.edition(card)
    local definition=Effects.getDefinition(Effects.getEffectName(card))
    if not definition then return "" end
    return "\nẤN BẢN · "..definition.shopLabel.."\n"..definition.shopText
end
function D.resolve(item,game)
    if not item then return "", "" end
    if item.card then return D.resolve(item.card,game) end
    if item.deity then return D.resolve(item.deity,game) end
    if item.equipment then return D.resolve(item.equipment,game) end
    if item.item then return D.resolve(item.item,game) end
    if item.deityId and Deities.CATALOG[item.deityId] then return D.resolve(Deities.CATALOG[item.deityId],game) end
    local def=A.definition(item)
    if def then
        local level=item.evolutionLevel or 0
        local text=A.description(item).."\nTIẾN HÓA "..level.." / "..A.config.maxEvolutionLevel
        if (item.temporaryAbilityLevels or 0)>0 then text=text.." · TẠM +"..item.temporaryAbilityLevels end
        if level>=A.config.maxEvolutionLevel then text=text.." · MAX EVOLUTION" end
        text=text.."\n"..def.ambition.."\nKích hoạt trước so tốc đánh, một lần/lá/tay; lặp điểm không lặp tài nguyên."
        text=text.."\nToàn tay: tối đa 12 hồi Máu, 24 Giáp, +3 Tốc; 3 Vàng/tay và 12 Vàng/trận từ bộ 52."
        if def.suit=="heart" then text=text.."\nCơ: hồi Máu dư chuyển thành Giáp." end
        text=text.."\nVàng hoặc Tốc vượt giới hạn tạo 2 Giáp mỗi đơn vị, vẫn chịu giới hạn Giáp."
        if level<A.config.maxEvolutionLevel then text=text.."\nKẾ TIẾP: "..A.description(item,A.level(item)+1) end
        text=text.."\nCơ bản: "..(item.baseChips or Deck.getChipValue(item.rank)).." ST · Tốc đánh "..Deck.getCardAttackSpeed(item)
        if item.rank==11 then text=text.."\nVai trò J: +15 ST và +2 Cường hóa mỗi lá 2–10 được chơi."
        elseif item.rank==12 then text=text.."\nVai trò Q: +0.1 hệ số và +15 ST / +2 Cường hóa mỗi ITM trên lá."
        elseif item.rank==13 then text=text.."\nVai trò K: +25 ST và +5 Cường hóa."
        elseif item.rank==14 then text=text.."\nVai trò A: +15 ST." end
        local state=item.abilityState or {}
        if state.tacticCharge then text=text.."\nTích hiện tại: "..state.tacticCharge end
        if state.hearts then text=text.."\nTâm hiện tại: "..state.hearts.." / "..(A.params(item).maxStacks or 0) end
        if state.savings then text=text.."\nVàng tích: "..state.savings.." / "..(A.params(item).maxStacks or 0) end
        if state.bribeUsed then text=text.."\nHối lộ: đã dùng trong trận." end
        if state.guardUsed then text=text.."\nVí Cứu Mệnh: đã dùng trong vòng." end
        if game and Boss.isAbilityDisabled(game,item) then text=text.."\nKHẢ NĂNG VÔ HIỆU trong tay này." end
        local monster=game and game.monster
        if monster and Boss.passiveEnabled(monster) and (monster.lockedFaction==item.suit or monster.lockedRoyals and item.rank>=11 and item.rank<=13) then text=text.."\nBOSS KHÓA TÍNH ĐIỂM: 0 ST / 0 Cường hóa từ lá này." end
        local bs=game and Boss.state(game.monster)
        if bs and bs.forgottenCard==item.id then text=text.."\nQUÊN LÃNG: lần lặp kế tiếp chỉ còn điểm, không chạy khả năng." end
        for _,eq in ipairs(item.equipments or {}) do text=text.."\nITM · "..eq.name..": "..Equipment.getDescription(eq) end
        if item.seal then text=text.."\nẤN · "..Deck.getModifierDescription("seal",item.seal) end
        if item.enhancement then text=text.."\nRÈN · "..Deck.getModifierDescription("enhancement",item.enhancement) end
        if game then local status=require("src.chest_depth").status(game,item);if status~="" then text=text.."\n"..status end end
        return (item.rankName or tostring(item.rank))..(item.suitSymbol or "").." · "..def.characterName.." · "..def.name,text..D.edition(item)
    end
    if Deities.CATALOG[item.id] then
        local text="SPN · "..Deities.getRarityLabel(item).."\n"..Deities.getDescription(item)..D.edition(item)
        if game then for slot,c in pairs(game.deities or {}) do if c==item and Boss.isSlotLocked(game,"spn",slot) then text=text.."\nÔ SPN BỊ KHÓA trong tay này." end end end
        return item.name,text
    end
    if Equipment.ITEMS[item.id] then
        local text="ITM · "..Equipment.getDescription(item)
        local B=require("src.basic_equipment")
        local recipe=B.byResult and B.byResult[item.id]
        if recipe then
            local needs={};for _,id in ipairs(recipe.ingredients) do needs[#needs+1]=Equipment.ITEMS[id].name end
            text=text.."\nGhép tầng "..recipe.tier..": "..table.concat(needs," + ")..". Công ghép "..recipe.fee.." Vàng."
        elseif item.basic then
            local names={};for _,r in ipairs(B.recipes) do for _,id in ipairs(r.ingredients) do if id==item.id then names[#names+1]=Equipment.ITEMS[r.id].name;break end end end
            for i=1,math.min(3,#names) do text=text.."\nNguyên liệu cho "..names[i].."." end
            if #names>3 then text=text.."\nVà "..(#names-3).." công thức khác — xem Bàn Ghép." end
        end
        if not item.soulOnly then text=text.."\nGắn/tháo miễn phí trong balo; tháo trước khi dùng làm nguyên liệu." end
        return item.name,text
    end
    if item.category=="evolution" or item.id=="cons_evolution" then
        return item.name,"Chọn một lá trong bộ bài, xem TRƯỚC → SAU rồi xác nhận. +1 cấp thông số khả năng lâu dài, không đổi rank/chất. Tối đa "..A.config.maxEvolutionLevel..". Cũng có thể nâng SPN theo hệ bậc hiện tại."
    end
    if item.sealType and Deck.SEALS[item.sealType] then return item.name,"Đóng lên lá được chọn (hoặc lá đầu tay/bộ bài nếu chưa chọn).\n"..Deck.getModifierDescription("seal",item.sealType) end
    if item.category=="edition" then return item.name,(Effects.getScoreBonus({edition=item.edition}) and "Chọn lá bài hoặc SPN" or "Chọn lá bài").." để áp dụng. Dùng chuột phải; không tiêu hao nếu hủy lựa chọn."..D.edition({edition=item.edition}) end
    if item.packType then return item.name,item.desc or "" end
    local consumable=require("src.shop").getConsumableDescription(item)
    if consumable then return item.name,consumable end
    if item.category=="heal" then return item.name,"Mua vào ô tiêu hao, chuột phải dùng một lần: hồi tối đa "..(item.healAmt or 25).." HP, không vượt HP tối đa." end
    local voucher=require("src.shop").voucherDescription(item.voucherId or item.id)
    if voucher then return item.name,voucher end
    return item.name or item.title or "Thẻ bài",item.desc or item.description or ""
end
function D.draw(UI,item,mx,my,game)
    if not item or item.faceDown then return end
    offered=true
    local key=item.hoverKey or item.card or item.deity or item.equipment or item
    if key~=hoverItem then hoverItem=key;hoverAge=0 end
    if hoverAge < require("config.ux_polish_config").hoverDelay then return end
    local title,body=D.resolve(item,game)
    local model=DescriptionView.model(item,title,body)
    local layout=DescriptionView.layout(model,UI.fonts)
    local w,h=layout.w*layout.scale,layout.h*layout.scale
    local surface=UI.CardPhysics.getState(key) or UI.CardPhysics.getState(item)
    local r=surface and UI.Polish and UI.Polish.rect(UI,item)
    if UI.Polish and UI.Polish.focus then r=UI.Polish.focus.rect end
    local right=r and r.x+r.w+24 or mx+16
    local left=r and r.x-w-24 or mx-w-16
    local x=math.max(10,math.min(1270-w,right+w<=1270 and right or left))
    local y=math.max(10,math.min(710-h,my+14))
    DescriptionView.draw(model,layout,x,y)
end
return D
