local UI=require("src.ui")
local C=require("config.death_vfx_config").chest
local Choices={}
local function progress(t,a,d) return math.max(0,math.min(1,(t-a)/d)) end
local function smooth(p) return p*p*(3-2*p) end
function Choices.ready(timer,index) return timer>=C.flipAt+(index-1)*C.stagger+C.flipDuration end
function Choices.finished() return C.flipAt+2*C.stagger+C.flipDuration end
function Choices.pose(timer,index)
    local travel=smooth(progress(timer,C.cardsAt,C.cardsTravel))
    local reveal=smooth(progress(timer,C.flipAt+(index-1)*C.stagger,C.flipDuration))
    local total=3*C.cardW+2*C.gap
    local finalX=(1280-total)/2+(index-1)*(C.cardW+C.gap)
    return {x=640-C.cardW/2+(finalX-640+C.cardW/2)*travel,
        y=C.cardY+(1-travel)*74,rotation=(index-2)*0.13*(1-travel),
        scale=0.66+0.34*travel,reveal=reveal}
end
local function fragments(g,x,y,timer,index,reveal,color)
    local p=progress(timer,C.cardsAt+(index-1)*C.stagger,0.95)
    local alpha=math.sin(p*math.pi)*(1-reveal*0.75)
    if alpha<=0 then return end
    g.push("all");g.setBlendMode("add")
    for k=1,24 do
        local seed=(math.sin(k*127.1+index*31.7)*43758.5453)%1
        local vertical=(math.sin(k*67.7+index*173.1)*15731.743)%1
        local angle=k*2.399+index
        local gather=smooth(p)
        local px=640+(seed-0.5)*160+(x+seed*C.cardW-640-(seed-0.5)*160)*gather
        local py=328+(vertical-0.5)*110+(y+vertical*C.cardH-328-(vertical-0.5)*110)*gather
        local size=(3+seed*5)*(1-p*0.8)
        g.push();g.translate(px,py);g.rotate(angle+p*2)
        g.setColor(color[1],color[2],color[3],alpha*0.12)
        g.circle("fill",0,0,size*2.5)
        g.setColor(1,0.91,0.68,alpha*0.85)
        g.polygon("fill",-size,-size*0.3,size*0.65,-size,size,size*0.5,-size*0.4,size)
        g.pop()
    end
    g.pop()
end
function Choices.draw(rewards,timer,title,mx,my,buttons,full,packType)
    local g=love.graphics
    g.setFont(UI.fonts.large);g.setColor(0.90,0.76,0.49,1)
    g.printf(title,0,48,1280,"center")
    g.setFont(UI.fonts.small);g.setColor(0.68,0.70,0.76,1)
    g.printf("CHỌN MỘT PHẦN THƯỞNG",0,99,1280,"center")
    if timer<C.cardsAt then return end
    for i,rew in ipairs(rewards) do
        local pose=Choices.pose(timer,i)
        local x,y=pose.x,pose.y
        local ready=Choices.ready(timer,i)
        local hovered=ready and mx>=x and mx<=x+C.cardW and my>=y and my<=y+C.cardH
        local item=packType and rew or rew.card or rew.item
        local color=item.color or rew.color or {1,0.78,0.34}
        local flare=math.sin(pose.reveal*math.pi)
        g.push("all");g.setBlendMode("add")
        require("render.lighting").glow(x+C.cardW/2,y+C.cardH/2,C.cardH*0.68,color,flare*0.32)
        g.pop()
        fragments(g,x,y,timer,i,pose.reveal,color)
        if not ready then UI.CardPhysics.suspend() end
        g.push("all");g.translate(x+C.cardW/2,y+C.cardH/2);g.rotate(pose.rotation);g.scale(pose.scale)
        g.translate(-x-C.cardW/2,-y-C.cardH/2)
        local function face(a,b,w,h)
            require("ui.card_surfaces").fullReward(item,a,b,w,h,
                packType or (rew.type=="card" and "standard" or "arcana"),hovered)
        end
        if pose.reveal>0 and pose.reveal<1 then
            UI.Polish.dissolve(UI,x,y,C.cardW,C.cardH,1-pose.reveal,color,face)
        elseif pose.reveal>=1 then face(x,y,C.cardW,C.cardH) end
        g.pop()
        if not ready then UI.CardPhysics.resume() end
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
    if full then g.setFont(UI.fonts.tiny);g.setColor(0.82,0.58,0.42,1);g.printf("Ô GIỮ LẠI ĐÃ ĐẦY (3/3)",0,644,1280,"center") end
end
return Choices
