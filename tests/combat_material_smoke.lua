return function(UI)
 local H=require("ui.combat_chrome");local g=love.graphics
 local canvas=g.newCanvas(260,150)
 local images,canvases=0,0;local newImage,newCanvas=g.newImage,g.newCanvas
 g.newImage=function(...) images=images+1;return newImage(...) end
 g.newCanvas=function(...) canvases=canvases+1;return newCanvas(...) end
 local function render()
  g.push("all");g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
  g.setBlendMode("alpha","alphamultiply");g.setColor(.2,.3,.4,.7)
  local r,b,c,a=g.getColor()
  H.panel(12,12,236,122,UI.COLORS.goldYellow)
  H.well(25,29,100,72,UI.COLORS.chipsBlue)
  H.button(UI,{x=139,y=29,w=93,h=72,text="Đánh",font=UI.fonts.small,variant="cyan",id="test_material"},0,0,nil)
  local rr,bb,cc,aa=g.getColor();local blend,alpha=g.getBlendMode()
  assert(rr==r and bb==b and cc==c and aa==a and blend=="alpha" and alpha=="alphamultiply" and g.getCanvas()==canvas,"material rendering must restore graphics state")
  g.pop()
 end
 render();local warmImages,warmCanvases=images,canvases
 for _=1,30 do render() end
 assert(images==warmImages and canvases==warmCanvases,"material surfaces must be reused, never allocated per frame")
 g.newImage,g.newCanvas=newImage,newCanvas
 local data=canvas:newImageData();local _,_,_,a=data:getPixel(0,0);assert(a==0,"surface shadow remains bounded")
 local function brightness(x,y) local r,b,c=data:getPixel(x,y);return r*.2126+b*.7152+c*.0722 end
 assert(brightness(31,13)>brightness(31,136),"raised frame needs a lit upper edge and a cast lower shadow")
 assert(brightness(40,34)<brightness(40,101),"inset socket needs a dark upper lip and a lit lower lip")
 data:release();canvas:release()
 print("Combat material PASS: raised bevel, inset shading, bounded shadow, graphics-state restoration and 30 frames without new images/canvases")
end
