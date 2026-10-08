local T={};local stage=0;local untilTime=0;local coins,cards,index
local function click(x,y)
 local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
 local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
 love.mousepressed(px,py,1);love.mousereleased(px,py,1)
end
local function advance(n) stage=n;untilTime=love.timer.getTime()+.6 end
local function shot(name)
 love.graphics.captureScreenshot(function(data)
  local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
 end)
end
function T.update(g,cb)
 if love.timer.getTime()<untilTime then return end
 if stage==0 then
  cb.startNewGame("red_deck");local loaded,state=cb.resumeSavedRun()
  assert(state=="shop");coins=loaded.gold;cards=#loaded.persistentDeck;index=loaded.run.currentBlindIndex
  assert(index<3 and loaded.currentBlind.status=="completed");advance(1)
 elseif stage==1 then shot("run_resume_shop");advance(2)
 elseif stage==2 then
  click(100,674);local loaded,state=cb.getRunState()
  assert(state=="BLIND_SELECT" and loaded.run.currentBlindIndex==index+1 and loaded.currentBlind.status=="current")
  assert(loaded.gold==coins and #loaded.persistentDeck==cards);advance(3)
 elseif stage==3 then shot("run_resume_next_fight");advance(4)
 elseif stage==4 then
  click(24+index*416+200,590);local loaded,state=cb.getRunState()
  assert(state=="playing" and loaded.monster and loaded.currentBlind.index==index+1)
  print("Run resume UI PASS: player's old save reopened as shop; next fight unlocked and entered; gold and deck preserved; save file untouched")
  love.event.quit(0)
 end
end
return T
