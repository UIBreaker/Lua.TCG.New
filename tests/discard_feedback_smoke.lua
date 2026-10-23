local A=require("src.card_abilities")
local Deck=require("src.deck")
local Game=require("src.game_state")
local Rng=require("src.rng")
local P=require("src.persistence")
local View=require("ui.discard_effects")
local Fx=require("ui.potion_effects")
local g=Game.new();g.maxPlayerHp=200;g.playerHp=199;g.gold=5;g.playerArmor=0;g.playerShield=0
g.hand={};g.deities={};g.deck={};g.discardPile={};g.potionFeedback={}
local discarded={}
for i,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
    g.hand[i]=Deck.newCard(8,suit);discarded[i]=Deck.newCard(4,suit)
end
discarded[1].evolutionLevel=3;discarded[2].evolutionLevel=1;discarded[3].evolutionLevel=1
local rng=Rng.getState()
A.discard(g,discarded,{playerDiscard=true})
local event=g.potionFeedback[1]
assert(#g.potionFeedback==1 and event.kind=="discard" and event.count==4)
assert(event.heal==1 and event.requestedHeal==8 and g.playerHp==200,"show actual capped healing")
assert(event.gold==2 and g.gold==7 and event.armor==2 and g.playerArmor==2)
assert(event.speed==1 and event.empowerment==4 and #event.targets==4)
for i,target in ipairs(event.targets) do
    assert(target.card==g.hand[i] and target.speed==1 and target.empowerment==1)
end
local rows=View.rows(event)
assert(#rows==5 and rows[1].value=="+1 HP" and rows[1].note=="Đã chạm máu tối đa")
assert(rows[4].note=="4 lá · 1 lượt đánh" and rows[5].note=="Tổng trên 4 lá cùng chất")
assert(not P.makeSnapshot(g,"MAP").game.potionFeedback,"presentation stays out of saves")
Fx.active={};Fx.update(g,.016,false,"playing",false)
assert(#Fx.active==1 and #g.potionFeedback==0 and Fx.active[1].reactive and #Fx.active[1].particles==0)
assert(View.receipt(g,"playing")==event)
g.selectedIndices={1};assert(not View.receipt(g,"playing"),"selection restores the hand preview")
g.selectedIndices={};assert(not View.receipt(g,"scoring"),"receipt never covers scoring")
local combat=g.abilityCombat;g.abilityCombat={}
assert(not View.receipt(g,"playing"),"old battle receipts stay hidden")
g.abilityCombat=combat
local slot=require("ui.components.hand_info_panel").receiptRect()
local Layout=require("ui.layout")
local reference=View.panelLayout(5,slot)
for count=1,5 do
    local panel=View.panelLayout(count,slot)
    assert(panel.x==reference.x and panel.y==reference.y,"all effect counts share one anchor")
    assert(panel.x>=slot.x and panel.y>=slot.y and panel.x+panel.w<=slot.x+slot.w+.001 and panel.y+panel.h<=slot.y+slot.h+.001)
    assert(panel.y+panel.h<Layout.battle.hand[2]+309,"receipt clears enemy action order")
    for _,size in ipairs({{960,600},{1280,720},{1920,1080},{720,960}}) do
        local sx,ox,oy,sy=Layout.scale(size[1],size[2],false)
        local rs=Layout.width/Layout.logicalWidth
        local x,y=ox+panel.x*sx*rs,oy+panel.y*sy*rs
        assert(x>=0 and y>=0 and x+panel.w*sx*rs<=size[1]+.001 and y+panel.h*sy*rs<=size[2]+.001,"inside letterboxed viewport")
    end
end
local active=Fx.active[1]
for _,fps in ipairs({30,60,120,144}) do
    local peak=0
    for frame=0,fps do
        active.age=frame/fps
        local x,y,angle=View.pose(active,1,false)
        assert(math.abs(x)<2 and y>=-12 and y<=0 and math.abs(angle)<.02)
        peak=math.min(peak,y)
        local rx,ry,ra=View.pose(active,1,true);assert(rx==0 and ry==0 and ra==0)
    end
    assert(peak<-10,"buff lift remains visible at every FPS")
end
active.age=.25
local _,lift=View.cardPose(g.hand[1],false);assert(lift<0)
local x,y,angle=View.cardPose(Deck.newCard(8,"hearts"),false)
assert(x==0 and y==0 and angle==0,"unbuffed cards stay still")
active.age=1;local px,py,pa=View.cardPose(g.hand[1],false)
assert(px==0 and py==0 and pa==0,"motion returns exactly to rest")
active.age=.016
local hp,gold=g.playerHp,g.gold
Fx.update(g,.016,true,"playing",false)
assert(g.playerHp==hp and g.gold==gold and Rng.getState()==rng,"animation changes no gameplay or RNG")
for _=1,80 do Fx.update(g,.05,true,"playing",false) end
assert(#Fx.active==0,"receipt expires")
A.discard(g,{discarded[1]},{playerDiscard=true});event=g.potionFeedback[1]
assert(event.heal==0 and View.rows(event)[1].note=="Máu đã đầy")
g.potionFeedback={};A.discard(g,discarded,{playerDiscard=true,preview=true});A.discard(g,discarded)
assert(#g.potionFeedback==0,"no false visuals for previews or forced discards")
g.hand={};A.discard(g,{discarded[3]},{playerDiscard=true})
assert(g.potionFeedback[1].speed==0 and #View.rows(g.potionFeedback[1])==0,"no claimed buffs without a recipient")
print("Discard feedback PASS: exact receipts, per-card buff motion at 30/60/120/144 FPS, reduced motion/rest, capped healing, expiry and preview/RNG/save isolation")
