local A=require("src.card_abilities")
local Deities=require("src.deities")
local Effects=require("src.card_effects")
local Sound=require("src.sound")
local Modal={current=nil,toast=nil}
local paramLabels={armor="Giáp",returnArmor="Giáp khi trả bài",healPercent="HP hồi (%)",maxStacks="Giới hạn tích",capacity="Kích thước tay",returns="Số lá trả",draw="Số lá rút",block="Sát thương chặn",gold="Vàng",maxGold="Trần Vàng",levels="Cấp khả năng",repeats="Lần tái kích hoạt",copies="Lần sao chép",range="Phạm vi bên trái",duration="Số tay hiệu lực",cancels="Số kỹ năng hủy",hands="Lượt đánh",skip="Hành động bỏ qua"}
function Modal.openChoices(game,choices,callback)
    Modal.current={mode="choices",game=game,choices=choices,index=1,decisions={},callback=callback,page=1}
end
function Modal.openEvolution(game,consumable,callback,sourceRect)
    local cards={}
    for _,c in ipairs(game.persistentDeck or {}) do if A.definition(c) and (c.evolutionLevel or 0)<A.config.maxEvolutionLevel then cards[#cards+1]=c end end
    for i=1,Deities.getMaxSlots(game) do if game.deities and game.deities[i] then cards[#cards+1]=game.deities[i] end end
    if #cards==0 then return false end
    Modal.current={mode="evolution",game=game,consumable=consumable,cards=cards,page=1,callback=callback,sourceRect=sourceRect}
    return true
end
local function close() Modal.current=nil;Sound.play("card_deselect") end
function Modal.choose(index)
    local m=Modal.current;if not m then return end
    local choice=m.choices[m.index]
    if index then
        local option=choice.options[index];if not option then return end
        m.decisions[#m.decisions+1]={card=choice.card,definition=choice.definition,params=choice.params,target=option.target,copySource=choice.copySource}
    end
    m.index=m.index+1;m.page=1
    if m.index>#m.choices then
        Modal.current=nil;m.callback(m.decisions)
    end
    Sound.play("card_select")
end
function Modal.confirm()
    local m=Modal.current;local c=m and m.selected;if not c then return false end
    local index;for i,item in ipairs(m.game.consumables or {}) do if item==m.consumable then index=i;break end end
    if not index then close();return false end
    local UI=require("src.ui");local before=UI.Polish.snapshot(m.game)
    local success=A.definition(c) and A.evolve(m.game,c) or not A.definition(c) and Deities.evolve(c)
    if not success then return false end
    table.remove(m.game.consumables,index);A.consumableUsed(m.game)
    UI.Polish.changed(UI,m.game,before,m.consumable,m.sourceRect)
    Effects.triggerScorePulse(c)
    Modal.toast=nil -- Changed-value feedback is anchored to the target instead.
    Modal.current=nil;Sound.play("xmult_boom")
    if m.callback then m.callback(c) end
    return true
end
function Modal.press(mx,my,button)
    local m=Modal.current;if not m then return false end
    if button~=1 then return true end
    for _,b in ipairs(m.buttons or {}) do
        if not b.disabled and mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h then
            if b.id=="cancel" then close()
            elseif b.id=="decline" then Modal.choose(nil)
            elseif b.id=="confirm" then Modal.confirm()
            elseif b.id=="prev" then m.page=math.max(1,m.page-1)
            elseif b.id=="next" then m.page=m.page+1
            elseif b.id=="tab_cards" or b.id=="tab_deities" then m.filter=b.id=="tab_cards" and "cards" or "deities";m.page=1;m.selected=nil
            elseif m.mode=="choices" then Modal.choose(b.index)
            else m.selected=m.cards[b.index];Sound.play("card_select") end
            return true
        end
    end
    return true
end
function Modal.key(key)
    if key=="f4" and not Modal.current then Modal.current={mode="glossary"};Sound.play("ui_click");return true end
    if not Modal.current then return false end
    if key=="escape" then close() end
    if key=="return" and Modal.current and Modal.current.mode=="evolution" then Modal.confirm() end
    return true
end
function Modal.update(dt)
    if Modal.toast then Modal.toast.age=Modal.toast.age+dt;if Modal.toast.age>1.6 then Modal.toast=nil end end
end
function Modal.draw(UI,mx,my)
    local m=Modal.current
    if Modal.toast then
        local t=Modal.toast;local alpha=math.min(1,(1.6-t.age)*2)
        love.graphics.setColor(0.85,0.72,1,alpha);love.graphics.setFont(UI.fonts.medium)
        love.graphics.printf(t.text,320,190-math.sin(math.min(1,t.age)*math.pi)*16,640,"center")
    end
    if not m then return end
    UI.CardPhysics.blockBehind()
    if m.mode=="evolution" then return require("ui.evolution_picker").draw(UI,m,mx,my) end
    love.graphics.setColor(0,0,0,0.84);love.graphics.rectangle("fill",0,0,1280,720)
    love.graphics.setColor(0.075,0.1,0.13,1);love.graphics.rectangle("fill",65,45,1150,630,12,12)
    love.graphics.setColor(0.85,0.7,0.36,1);love.graphics.rectangle("line",65,45,1150,630,12,12)
    if m.mode=="glossary" then
        love.graphics.setFont(UI.fonts.large);love.graphics.printf("THUẬT NGỮ · F4",95,72,1090,"center")
        for i,entry in ipairs(UI.Description.glossary) do
            local y=136+(i-1)*57
            love.graphics.setFont(UI.fonts.small);love.graphics.setColor(0.95,0.79,0.45,1);love.graphics.print(entry[1],100,y)
            love.graphics.setFont(UI.fonts.tiny);love.graphics.setColor(0.92,0.95,0.98,1);love.graphics.printf(entry[2],310,y,830)
        end
        m.buttons={{id="cancel",x=100,y=610,w=180,h=42}}
        UI.drawButton({text="ĐÓNG / ESC",x=100,y=610,w=180,h=42,color=UI.COLORS.btnNormal},false,false)
        return
    end
    local choice=m.mode=="choices" and m.choices[m.index]
    love.graphics.setFont(UI.fonts.large);love.graphics.printf(choice and choice.title or "TIẾN HÓA · CHỌN LÁ",90,65,1100,"center")
    love.graphics.setFont(UI.fonts.small);love.graphics.setColor(0.93,0.95,0.98,1)
    love.graphics.printf(choice and choice.description or "Nâng thông số khả năng. Giữ nguyên rank/chất. Nâng theo đúng instance được chọn.",100,115,1080,"center")
    m.buttons={}
    local function button(id,label,x,y,w,h,index)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,index=index,color=UI.COLORS.btnNormal}
        m.buttons[#m.buttons+1]=b
        UI.drawButton(b,mx>=x and mx<=x+w and my>=y and my<=y+h,false)
    end
    local count=choice and #choice.options or #m.cards
    local pageSize=choice and 8 or 10
    m.page=math.min(m.page,math.max(1,math.ceil(count/pageSize)))
    for i=(m.page-1)*pageSize+1,math.min(count,m.page*pageSize) do
        local slot=i-(m.page-1)*pageSize-1
        local x,y=105+(slot%5)*210,175+math.floor(slot/5)*150
        local target=choice and choice.options[i].target or m.cards[i]
        if A.definition(target) then UI.drawCard(target,x,y,76,110)
        elseif Deities.CATALOG[target.id] then UI.drawPatronCard(target,x,y,76,110)
        else
            local image=target.hp and target.maxHp and require("src.enemy_art").image(target,{}) or UI.getConsumableImage(target)
            if image then
                love.graphics.setColor(1,1,1,1);require("ui.card_surfaces").image(target,x,y,76,110,image)
            else
                love.graphics.setColor(0.25,0.18,0.35,1);love.graphics.rectangle("fill",x,y,76,110,5,5)
                UI.drawItemEmblem(target,x+38,y+45,30,target.color)
            end
        end
        button("target",choice and choice.options[i].label or target.name or (target.rankName..target.suitSymbol),x+84,y+22,116,64,i)
        m.buttons[#m.buttons+1]={id="target",index=i,x=x,y=y,w=76,h=110}
        if mx>=x and mx<=x+76 and my>=y and my<=y+110 then UI.Description.draw(UI,target,mx,my,m.game) end
    end
    if m.mode=="evolution" and m.selected then
        local c=m.selected;local d=A.definition(c)
        love.graphics.setFont(UI.fonts.tiny);love.graphics.setColor(0.86,0.76,1,1)
        local before=d and A.description(c) or Deities.getDescription(c)
        local after
        if d then after=A.description(c,A.level(c)+1)
        else local copy={};for k,v in pairs(c) do copy[k]=v end;copy.evolutionLevel=(copy.evolutionLevel or 0)+1;after=Deities.getDescription(copy) end
        local changes={}
        if d then local a,b=A.params(c),A.params(c,d,A.level(c)+1);for k,v in pairs(a) do if b[k]~=v then changes[#changes+1]=(paramLabels[k] or k)..": "..v.." → "..b[k] end end;table.sort(changes) end
        love.graphics.printf("TRƯỚC: "..before.."\nSAU: "..after.."\n"..table.concat(changes," · "),105,486,1040)
        button("confirm","XÁC NHẬN TIẾN HÓA",760,602,290,46)
    elseif choice then button("decline","KHÔNG DÙNG KHẢ NĂNG",480,602,315,46) end
    button("cancel","HỦY / ESC",100,602,180,46)
    if m.page>1 then button("prev","←",1100,230,60,50) end
    if m.page*pageSize<count then button("next","→",1100,300,60,50) end
end
return Modal
