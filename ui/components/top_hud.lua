local C=require("ui.components.core")
local T=require("ui.theme")
local S=require("ui.backpack_style")
local Chrome=require("ui.combat_chrome")
local Health=require("ui.components.health_bar")
local HUD={}
function HUD.draw(data,fonts,mx,my,pressed)
 data=data or {};fonts=fonts or {};local g=love.graphics;g.push("all")
 local f=fonts.tiny or g.getFont();local small=fonts.small or f;local title=fonts.hudTitle or small
 local stat=fonts.hudStat or small
 Chrome.panel(12,10,1256,60)
 Chrome.crest(42,40,20,T.colors.gold)
 Chrome.title("ẢI "..(data.ante or 1).." · TRẬN "..(data.round or 1),69,29,149,title,T.colors.gold)
 Chrome.well(230,14,194,51,T.colors.gold)
 Chrome.well(430,16,81,47,T.colors.gold)
 Chrome.well(523,16,125,47,T.colors.gold)
 Chrome.well(658,16,95,47,T.colors.gold)
 local meters=data.meters or {};local hp=meters.hp;local armor=meters.armor
 g.push();g.translate(327,50);g.scale(data.hpBounce or 1);g.translate(-327,-50)
 Health.draw(235,39,184,23,hp and hp.shown or data.hp or 0,data.maxHp or 1,
  {variant="green",font=f,label="MÁU "..math.floor(data.hp or 0).." / "..math.floor(data.maxHp or 1),
   trailValue=hp and hp.trail,trailColor={1,.58,.36}})
 g.pop()
 Health.draw(235,18,184,16,armor and armor.shown or data.armor or 0,data.armorCap or 30,
  {variant="cyan",shield=true,font=f,label="GIÁP "..math.floor(data.armor or 0),
   trailValue=armor and armor.trail,pulse=((data.armorBounce or 1)-1)*8})
 g.push();g.translate(470,30);g.scale(data.goldBounce or 1);g.translate(-470,-30)
 S.glyph("gold",444,28,8,T.colors.gold)
 C.text(math.floor((meters.gold and meters.gold.shown or data.gold or 0)+.5),461,20,49,stat,T.colors.gold)
 g.pop()
 S.glyph("souls",444,51,6,T.colors.purple)
 C.text((data.souls or 0).." LH",461,44,49,f,T.colors.purple)
 C.text("LƯỢT ĐÁNH",536,21,99,f,T.colors.muted,"center")
 C.text((data.hands or 0).." / "..(data.maxHands or 0),536,33,99,stat,T.colors.text,"center")
 C.text("LƯỢT BỎ",670,21,71,f,T.colors.muted,"center")
 C.text(data.discards or 0,670,35,71,stat,T.colors.text,"center")
 local specs={
  {id="open_handbook",text="SỔ TAY",x=860,y=15,w=116,h=45,variant="cyan",font=fonts.bookChapter or small},
  {id="open_deck_viewer",text="BỘ BÀI",x=984,y=15,w=123,h=45,variant="gold",font=fonts.bookChapter or small},
  {id=data.resolving and "open_pause_menu" or "open_settings",text="TÙY CHỌN",x=1115,y=15,w=145,h=45,variant="purple",font=fonts.bookChapter or small},
 }
 for i,b in ipairs(specs) do if i<3 then b.disabled=data.resolving end;Chrome.button({fonts={small=small,tiny=f}},b,mx or -100,my or -100,pressed) end
 g.pop();return specs
end
return HUD
