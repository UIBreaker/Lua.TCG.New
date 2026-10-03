local UI=require("src.ui")
local C=require("config.death_vfx_config").chest
local Choices={}
local function progress(t,a,d) return math.max(0,math.min(1,(t-a)/d)) end
function Choices.ready(timer,index) return timer>=C.flipAt+(index-1)*C.stagger+C.flipDuration end
function Choices.finished() return C.flipAt+2*C.stagger+C.flipDuration end
function Choices.draw(rewards,timer,title,mx,my,buttons,full,packType)
    local g=love.graphics
    g.setFont(UI.fonts.large);g.setColor(0.90,0.76,0.49,1)
    g.printf(title,0,48,1280,"center")
    g.setFont(UI.fonts.small);g.setColor(0.68,0.70,0.76,1)
    g.printf("CHỌN MỘT PHẦN THƯỞNG",0,99,1280,"center")
    if timer<C.cardsAt then return end
    local travel=progress(timer,C.cardsAt,C.cardsTravel);local ease=1-(1-travel)^3
    local total=3*C.cardW+2*C.gap;local start=(1280-total)/2
    UI.CardPhysics.suspend()
    for i,rew in ipairs(rewards) do
        local x=start+(i-1)*(C.cardW+C.gap);local y=C.cardY+(1-ease)*42
        local flip=progress(timer,C.flipAt+(i-1)*C.stagger,C.flipDuration)
        local ready=Choices.ready(timer,i)
        local hovered=ready and mx>=x and mx<=x+C.cardW and my>=y and my<=y+C.cardH
        local item=packType and rew or rew.card or rew.item
        local scaleX=math.max(0.025,math.abs(math.cos(flip*math.pi)))
        g.push("all");g.translate(x+C.cardW/2,y+C.cardH/2);g.scale(scaleX,1)
        g.translate(-x-C.cardW/2,-y-C.cardH/2)
        if flip<0.5 then UI.drawCardBack(x,y,C.cardW,C.cardH)
        else require("ui.card_surfaces").fullReward(item,x,y,C.cardW,C.cardH,packType or (rew.type=="card" and "standard" or "arcana"),hovered) end
        g.pop()
        if ready then
            g.setFont(UI.fonts.small);g.setColor(0.87,0.84,0.79,1)
            require("ui.components.core").textLine(item.name or rew.title,x-18,y+C.cardH+12,C.cardW+36,UI.fonts.small,UI.COLORS.textLight,"center",UI.fonts.tiny)
            local canKeep=not packType or packType=="joker_edition" or packType=="seal" or packType=="spectral" or packType=="celestial" or packType=="edition"
            for action=1,canKeep and 2 or 1 do
                local btn={id=packType and ((action==1 and "choose_pack_" or "keep_pack_")..i) or "chest_choice_"..i.."_"..action,rewardIndex=i,cardIndex=packType and i,keep=action==2,
                    text=action==1 and "DÙNG NGAY" or "GIỮ LẠI",x=x,y=y+C.cardH+44+(action-1)*(C.buttonH+8),
                    w=C.cardW,h=C.buttonH,font=UI.fonts.small,color=action==1 and UI.COLORS.btnPlay or {0.20,0.35,0.49,1},disabled=action==2 and full}
                buttons[#buttons+1]=btn;UI.drawButton(btn,not btn.disabled and mx>=btn.x and mx<=btn.x+btn.w and my>=btn.y and my<=btn.y+btn.h)
            end
        end
    end
    UI.CardPhysics.resume()
    if full then g.setFont(UI.fonts.tiny);g.setColor(0.82,0.58,0.42,1);g.printf("Ô GIỮ LẠI ĐÃ ĐẦY (3/3)",0,644,1280,"center") end
end
return Choices
