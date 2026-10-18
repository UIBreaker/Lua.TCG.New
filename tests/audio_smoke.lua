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
    function s:setPitch(v) assert(v>=.35 and v<=4);self.pitch=v end
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
for _,c in pairs(C.cues) do
    peaks[c.path]=.64
    for _,path in ipairs(c.variants or {}) do peaks[path]=.64 end
end
for name,c in pairs(C.music) do peaks[c.path]=name=="menu" and 1 or .48 end
for _,c in pairs(C.ambience) do peaks[c.path]=.32 end
local function checkPeak()
    local peak=0
    for _,s in ipairs(sources) do if s.playing and not s.released then peak=peak+s.volume*peaks[s.path] end end
    assert(peak<=.920001,"mixer must leave headroom even when every waveform peak coincides")
end
assert(S.init())
local cueCount=0
local variantCount=0
for name,c in pairs(C.cues) do cueCount=cueCount+1;variantCount=variantCount+#(c.variants or {});assert(S.has(name),name) end
assert(S.stats().cues==cueCount and clones==cueCount*2-variantCount)
assert(loads==cueCount+variantCount,"all variants must be preloaded")
local function advance(dt,state,game,paused)
    time=time+dt;S.update(dt,state or "playing",game or {playerHp=100,maxPlayerHp=100,monster={stage=1}},paused)
    checkPeak()
end
assert(S.play("card_draw") and not S.play("card_draw"),"cooldown")
time=time+.1;assert(S.play("card_draw"))
time=time+.1;assert(S.play("card_draw"))
time=time+.1;assert(not S.play("card_draw"),"per-cue pool cap")
S.stopAll()
local takes={}
for i=1,6 do
    time=time+.1;assert(S.play("card_draw"))
    for _,s in ipairs(sources) do if s.playing then takes[s.path]=true end end
    S.stopAll()
end
local takeCount=0;for _ in pairs(takes) do takeCount=takeCount+1 end
assert(takeCount==3,"serial actions must rotate actual recordings, not just pitch")
time=time+.1;assert(S.play("card_deal"));assert(S.play("damage_heavy"))
local paper,impact
for _,s in ipairs(sources) do
    if s.playing and s.path==C.cues.card_deal.path then paper=s end
    if s.playing and s.path==C.cues.damage_heavy.path then impact=s end
end
assert(paper and impact and impact.volume>paper.volume*3,"foreground impact stays clear over paper")
S.stopAll()
local customData={}
peaks[customData]=.78
assert(S.registerProcedural("test_peak",customData,{gain=.9,priority=5,cooldown=0,peak=.78}))
assert(S.play("test_peak"));checkPeak()
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
combat.position,stem.position=24.5,24.5
local calm=stem.volume
advance(2,"playing",{monster={isBoss=true,stage=1},playerHp=20,maxPlayerHp=100})
assert(S.currentTrack=="boss" and stem.volume>calm,"boss and low HP raise tension")
for _,s in ipairs(sources) do if not s.released and s.path==C.music.boss.path then assert(s.position==24.5,"sync preserves developed second phrase") end end
assert(S.play("damage_heavy"));advance(.01,"playing")
assert(S.stats().duck<.6,"impact ducks music")
advance(1,"playing");assert(S.stats().duck>.8,"long effect tail must not hold music down")
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
local play,stopCue,silence=S.play,S.stopCue,S.silence
local routed={}
local stopped={}
S.play=function(name,pitch) routed[#routed+1]={name=name,pitch=pitch} end
S.stopCue=function(name) stopped[#stopped+1]=name end
S.silence=function() error("windup must not be silenced during pressure") end
local Nen=require("src.nen_combat")
local originalCount=Nen.count
Nen.count=function() return 0 end
for _,id in ipairs(require("config.nen_vfx_config").order) do
    for tier=1,3 do
        local a={profile={id=id},nen={tier=tier,audioSpeed=3.72,releaseCount=0}}
        local suffix=tier==3 and "_extreme" or tier==2 and "_strong" or ""
        Nen.enter(a,"NEN_AWAKENING")
        assert(routed[#routed].name=="nen_"..id.."_charge"..suffix and routed[#routed].pitch==3.72)
        Nen.enter(a,"CHARGE")
        Nen.enter(a,"RELEASE")
        assert(routed[#routed].name=="nen_"..id.."_release"..suffix and routed[#routed].pitch==3.72)
        assert(stopped[#stopped]=="nen_"..id.."_charge"..suffix and a.nen.chargeCue==nil)
        Nen.enter(a,"ENEMY_IMPACT")
        local expected="nen_"..id.."_impact"..suffix
        assert(routed[#routed].name==expected,"combat must choose the authored impact weight")
    end
end
assert(#routed==243 and #stopped==81)
local cancelled={profile={id="high_card"},nen={tier=3}}
Nen.enter(cancelled,"NEN_AWAKENING");Nen.cancel(cancelled)
assert(cancelled.nen.chargeCue==nil and stopped[#stopped]=="nen_high_card_charge_extreme")
S.play,S.stopCue,S.silence=play,stopCue,silence
Nen.count=originalCount
S.stopAll()
local fastData={};peaks[fastData]=.62
assert(S.registerProcedural("test_fast_charge",fastData,{gain=.6,priority=4,cooldown=0,peak=.62,maxPitch=4}))
assert(S.play("test_fast_charge",3.72))
local fastVoice
for _,s in ipairs(sources) do if s.path==fastData and s.playing then fastVoice=s end end
assert(fastVoice and fastVoice.pitch>3.6,"windup must follow fast-forward plus repeat acceleration")
time=time+.1;assert(S.play("card_draw"));S.stopCue("test_fast_charge")
assert(not fastVoice.playing and S.stats().voices==1,"launch/cancel stops only its own charge")
for tier,level in ipairs({.62,.46,.30}) do
    S.stopAll()
    local data={};peaks[data]=.78
    local name="test_tier_duck_"..tier
    local hold=({.12,.21,.34})[tier]
    assert(S.registerProcedural(name,data,{gain=.8,priority=5,cooldown=0,peak=.78,duck=level,duckDuration=hold}))
    assert(S.play(name) and math.abs(S.stats().duck-level)<.00001)
    advance(hold*.8,"playing")
    assert(math.abs(S.stats().duck-level)<.00001,"tier duck must hold through its transient")
    advance(1.2,"playing");assert(S.stats().duck>.9,"tier duck must recover before the long tail finishes")
end
S.stopAll()
local bossCue=require("config.attack_outcome_audio").nen_four_of_a_kind_boss_finisher_extreme
local bossData={};peaks[bossData]=bossCue.peak
assert(S.registerProcedural("nen_four_of_a_kind_boss_finisher_extreme",bossData,bossCue))
assert(S.play("nen_four_of_a_kind_boss_finisher_extreme",.83))
local rewardPitch,rewardLead=S.rewardPitch()
assert(math.abs(rewardPitch-210*.83*2/261.63)<.00001 and rewardLead>2.6 and rewardLead<2.8,"reward key and lead must follow the actual pitched triumph")
local bossVoices=S.stats().voices
assert(S.playCombatVictory() and S.playCombatVictory())
assert(S.stats().voices==bossVoices,"reward calculation and screen change must not stack generic victory over the hand's phrase")
advance(1.48,"CASH_OUT")
assert(math.abs(S.stats().duck-.14)<.00001,"victory transition must leave the late boss seal audible")
assert(S.play("card_deal"));advance(.04,"CASH_OUT")
assert(math.abs(S.stats().duck-.14)<.00001,"reward sounds must not release the boss duck early")
advance(1.2,"CASH_OUT");assert(math.abs(S.stats().duck-.14)<.00001,"hold the spotlight through the victory crown")
advance(2.5,"CASH_OUT");assert(S.stats().duck>.9,"background must recover after victory")
S.stopAll()
local neutralPitch,neutralLead=S.rewardPitch()
assert(neutralPitch==1 and neutralLead==0,"stopped victory must not leak its key or wait into another ceremony")
assert(S.playCombatVictory() and S.stats().voices==1,"ordinary wins and stopped boss voices keep the generic victory fallback")
S.stopAll()
local refireLoads=loads
for i=1,4 do time=time+.08;assert(S.play("test_tier_duck_3"),"long tails must not suppress a fresh extreme contact") end
assert(S.stats().voices==3 and loads==refireLoads,"rapid extreme refire reuses the oldest tail without allocating")
checkPeak()
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
