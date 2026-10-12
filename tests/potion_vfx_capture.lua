local T={};local index,phase,deadline=1,0,0
local F=require("ui.potion_effects")
local P=require("src.potions")
local UI=require("src.ui")
local cases={
    {kind="heal",label="HỒI PHỤC · +60 HP",value=60},
    {kind="armor",label="LÁ CHẮN · +20 GIÁP",value=20},
    {kind="speed",label="TỐC ĐÁNH · +10",cards=true},
    {kind="accuracy",label="CHÍNH XÁC · TRÚNG 100%",target=true},
    {kind="evasion",label="NÉ TRÁNH · 1 LƯỢT"},
    {kind="armor_break",label="PHÁ 200 GIÁP · 50 ST",target=true},
    {kind="damage",label="TOÀN TAY · +20 ST",cards=true},
    {kind="empower",label="TOÀN TAY · +5 CƯỜNG HÓA",cards=true},
    {kind="gold_blood",label="MÁU VÀNG · 1 HP = 1 VÀNG"},
    {kind="draw",label="RÚT NGAY 5 LÁ",cards=true},
    {kind="slow",label="GIẢM TỐC · -50%",target=true},
    {kind="rest",label="NGHỈ NGƠI · HỒI ĐẦY HP"},
}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/potion_vfx_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    local c=cases[index]
    if not c then
        print("Potion VFX gallery PASS: 12 luminous motifs, soft light texture, additive cores/trails, deterministic particles and preserved graphics state")
        love.event.quit(0);return
    end
    if phase==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.hand={};game.deities={};game.consumables={};game.selectedIndices={}
        for i=1,(c.kind=="draw" and 5 or 3) do game.hand[i]=require("src.deck").newCard(i+4,({"spades","diamonds","hearts"})[(i-1)%3+1]) end
        game.monster.hp=300;game.monster.maxHp=300;game.monster.damageLagHp=300
        game.playerHp=100;game.gold=0;game.potionCombat={};F.active={}
        phase=1;deadline=love.timer.getTime()+.7
    elseif phase==1 then
        if c.kind=="slow" then game.monster.combatBuffs={slow={value=.5,turns=2}} end
        P.emit(game,c.kind,c.label,c.value,c.target and game.monster or nil,c.cards and game.hand or nil)
        phase=2;deadline=love.timer.getTime()+.5
    else
        assert(#F.active>0 and #F.active[1].particles==54)
        local g=love.graphics;local blend,alpha=g.getBlendMode();local width=g.getLineWidth()
        local rng=require("src.rng");local before=rng.getState()
        F.draw(UI,game,"playing")
        local afterBlend,afterAlpha=g.getBlendMode()
        assert(afterBlend==blend and afterAlpha==alpha and g.getLineWidth()==width and rng.getState()==before)
        shot(c.kind);index=index+1;phase=0;deadline=love.timer.getTime()+.2
    end
end
return T
