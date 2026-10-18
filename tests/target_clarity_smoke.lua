local F=require("ui.enemy_formation")
local G=require("src.enemy_group")
local list={}
for i=1,3 do list[i]={hp=20,name="Enemy "..i,enemyInventory={},group=list,groupIndex=i} end
local game={enemies=list,monster=list[1]}
for i,m in ipairs(list) do
    local x,y,w,h=G.rect(i,3)
    assert(F.press(game,x+w/2,y+h/2) and game.monster==m)
    local hx,hy,hw,hh=F.headerRect(i,3)
    assert(not F.inventoryAt(game,hx+30,hy+15),"nameplate must select, not open inventory")
    assert(F.press(game,hx+30,hy+15) and game.monster==m)
    local bx,by,bw,bh=F.bagRect(i,3)
    assert(F.inventoryAt(game,bx+bw/2,by+bh/2)==m,"bag remains an inventory control")
    assert(F.inventoryAt(game,x+w/2,y+h/2,true)==m,"right-click inspection remains available")
end
list[2].hp=0
local x,y,w,h=G.rect(2,3);local before=game.monster
assert(not F.press(game,x+w/2,y+h/2) and game.monster==before,"dead enemy must reject targeting")
assert(not F.inventoryAt(game,x+w/2,y+h/2,true))
game.monster=list[2];assert(G.ensureTarget(game)==list[1],"target must advance to a survivor")
assert(not F.press(game,10,700),"empty battlefield must not change target")
print("Target clarity PASS: card/header hit areas, bag/right-click isolation, dead targets and auto-retarget")
