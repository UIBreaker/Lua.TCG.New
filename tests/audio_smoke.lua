package.path="./?.lua;./?/init.lua;"..package.path
local savedLove=love
local time,loads,clones=0,0,0
local sources={}
local function source(path)
    local s={path=path,playing=false,position=0,volume=0}
    function s:isPlaying() return self.playing end
    function s:play() self.playing=true end
    function s:stop() self.playing=false end
    function s:pause() self.playing=false;self.paused=true end
    function s:release() self.released=true;self.playing=false end
    function s:setVolume(v) assert(v>=0 and v<=1);self.volume=v end
    function s:setPitch(v) assert(v>=.35 and v<=2.5);self.pitch=v end
    function s:setLooping(v) self.looping=v end
    function s:tell() return self.position end
    function s:seek(v) self.position=v end
    function s:clone() clones=clones+1;return source(path) end
    sources[#sources+1]=s
    return s
end
love={audio={newSource=function(path,kind)
    assert(kind=="static" or kind=="stream")
    loads=loads+1
    return source(path)
end,setVolume=function(v) assert(v>=0 and v<=1) end},timer={getTime=function() return time end}}
package.loaded["src.sound"]=nil
local S=require("src.sound")
local C=require("config.audio_catalog")
local peaks={}
for _,c in pairs(C.cues) do peaks[c.path]=.64 end
for name,c in pairs(C.music) do peaks[c.path]=name=="menu" and 1 or .48 end
for _,c in pairs(C.ambience) do peaks[c.path]=.32 end
local function checkPeak()
    local peak=0
    for _,s in ipairs(sources) do if s.playing and not s.released then peak=peak+s.volume*peaks[s.path] end end
    assert(peak<=.920001,"mixer must leave headroom even when every waveform peak coincides")
end
assert(S.init())
local cueCount=0
for name in pairs(C.cues) do cueCount=cueCount+1;assert(S.has(name),name) end
assert(S.stats().cues==cueCount and clones==cueCount*2)
local function advance(dt,state,game,paused)
    time=time+dt;S.update(dt,state or "playing",game or {playerHp=100,maxPlayerHp=100,monster={stage=1}},paused)
    checkPeak()
end
assert(S.play("card_draw") and not S.play("card_draw"),"cooldown")
time=time+.1;assert(S.play("card_draw"))
time=time+.1;assert(S.play("card_draw"))
time=time+.1;assert(not S.play("card_draw"),"per-cue pool cap")
local before=loads
S.stopAll()
local fillers={"card_slide","card_draw","card_deal","card_select","card_deselect","reward_coin_spawn","reward_coin_land","reward_coin_collect"}
for j=1,3 do
    for _,name in ipairs(fillers) do time=time+.1;assert(S.play(name),name) end
end
assert(S.stats().voices==24 and loads==before,"SFX allocate no new sources during playback")
assert(not S.play("ui_hover"),"hover must not interrupt stronger cues")
time=time+.1;assert(S.play("bed_explosion_boom") and S.stats().voices==24,"impact replaces a quiet cue")
checkPeak()
S.setVolume(0);assert(not S.play("round_win"));S.setVolume(.8)
S.setMasterVolume(0);assert(not S.play("round_win"));S.setMasterVolume(1)
S.setVolume(0/0);assert(S.getVolume()==.8,"invalid volume rejected")
S.stopAll();advance(.05,"menu")
local initial=loads
for i=1,120 do advance(1/60,"menu") end
assert(loads==initial,"same scene must not restart/reload music")
local title
for _,s in ipairs(sources) do if s.path=="assets/audio/menu_theme.mp3" and not s.released then title=s end end
assert(title and title.playing and title.looping)
local level=title.volume
advance(.1,"playing")
assert(title.playing and title.volume<level and title.volume>0,"crossfade keeps outgoing track alive")
advance(2,"playing");assert(title.released,"finished crossfade releases stream")
assert(S.stats().loops==3,"combat, tension and desert ambience")
local combat,stem
for _,s in ipairs(sources) do
    if not s.released and s.path==C.music.combat.path then combat=s end
    if not s.released and s.path==C.music.tension.path then stem=s end
end
assert(combat and stem)
local calm=stem.volume
advance(2,"playing",{monster={isBoss=true,stage=1},playerHp=20,maxPlayerHp=100})
assert(S.currentTrack=="boss" and stem.volume>calm,"boss and low HP raise tension")
assert(S.play("damage_heavy"));advance(.01,"playing")
assert(S.stats().duck<.6,"impact ducks music")
S.silence(.06);assert(not S.play("pair_impact") and S.stats().voices==0)
advance(.08,"playing");assert(S.play("pair_impact"))
S.stopAll();advance(2,"rest");local restVolume
for _,s in ipairs(sources) do if s.path==C.music.rest.path and not s.released then restVolume=s.volume end end
advance(2,"rest",nil,true)
for _,s in ipairs(sources) do if s.path==C.music.rest.path and not s.released then assert(s.volume<restVolume,"pause lowers bed") end end
S.setFocused(false);assert(not S.play("ui_click"))
for _,s in ipairs(sources) do assert(not s.playing,"background audio must pause") end
S.setFocused(true);advance(.1,"rest")
assert(S.currentTrack=="rest")
S.setMusicVolume(0);S.setAmbienceVolume(0);advance(2,"rest")
assert(S.stats().loops==0,"muted buses release decoders")
S.setMusicVolume(.8);S.setAmbienceVolume(.65)
for i=1,150 do
    advance(.01,({"menu","playing","shop","rest","victory","gameover","event"})[i%7+1],{monster={stage=i%60+1,isBoss=i%3==0}})
    assert(S.stats().loops<=S.stats().maxLoops,"rapid transitions stay bounded")
end
for name,expected in pairs({menu="menu",shop="shop",rest="rest",playing="combat",scoring="combat",victory="victory",gameover="defeat",defeating="defeat",CASH_OUT="victory",chest="victory",treasure="victory",map="exploration",BLIND_SELECT="exploration",event="mystery",boss_deity="mystery",socketing="mystery"}) do
    local track=S.context(name,{})
    assert(track==expected,name)
end
local _,ambient,weather,intensity=S.context("playing",{monster={stage=21,isBoss=true},playerHp=20,maxPlayerHp=100})
assert(ambient=="sea" and intensity==.95)
_,ambient,weather=S.context("playing",{monster={stage=3}})
assert(ambient=="desert" and weather=="rain")
local Audio=require("ui.audio_settings")
local settings={masterVolume=1,musicVolume=.8,ambienceVolume=.65}
assert(Audio.activate("audio_musicVolume_down",settings) and math.abs(settings.musicVolume-.7)<1e-8)
assert(not Audio.activate("unknown",settings))
for i=1,20 do Audio.activate("audio_ambienceVolume_down",settings) end
assert(settings.ambienceVolume==0)
S.stopAll();assert(S.stats().loops==0 and S.stats().voices==0)
-- One bad resource cannot take down unrelated effects or cause repeated IO.
love.audio.newSource=function(path,kind)
    if path==C.cues.card_select.path or path==C.music.combat.path then error("test missing file") end
    loads=loads+1;return source(path)
end
assert(not S.init() and S.has("damage_heavy") and not S.has("card_select"))
assert(S.play("damage_heavy"))
advance(.1,"playing");local afterFailure=loads
advance(.1,"playing");assert(loads==afterFailure,"failed stream is not retried every frame")
S.stopAll()
love={};assert(not S.init() and not S.play("ui_click"),"audio disabled is safe")
love=savedLove
package.loaded["src.sound"],package.loaded["ui.audio_settings"]=nil,nil
print("Audio mixer PASS: "..cueCount.." cues; pools, cooldowns, priorities, crossfades, tension, ducking, focus, buses, settings and failure isolation")
