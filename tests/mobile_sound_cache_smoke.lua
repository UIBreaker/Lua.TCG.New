local previousLove=love
local T=require('src.touch_input');local low=T.lowPower;T.lowPower=true
local clock,loads,releases=0,0,0
local function source(path)
    local s={path=path,playing=false,volume=0}
    function s:isPlaying() assert(not self.dead,'used released Source');return self.playing end
    function s:play() assert(not self.dead);self.playing=true end
    function s:stop() assert(not self.dead);self.playing=false end
    function s:release() assert(not self.dead);self.dead=true;releases=releases+1 end
    function s:clone() return source(path) end
    function s:setVolume(v) self.volume=v end
    function s:setPitch() end
    function s:setLooping() end
    function s:tell() return 0 end
    function s:seek() end
    function s:getDuration() return path:find('high_card',1,true) and .2 or path:find('nen_',1,true) and 20 or .1 end
    return s
end
love={filesystem={getInfo=function() return true end},timer={getTime=function() return clock end},
    sound={newSoundData=function() error('synthesis/decode must not run during mobile init') end},
    audio={newSource=function(path) loads=loads+1;clock=clock+.002;return source(path) end,setVolume=function() end}}
package.loaded['src.sound']=nil;package.loaded['src.runtime_assets']=nil
local S=require('src.sound');assert(S.init());local stats=S.stats()
local common=0;for _ in pairs(require("config.audio_catalog").cues) do common=common+1 end
local expected=common+#require("config.nen_vfx_config").order*28+#require("src.reward_audio").order*4
assert(stats.cues==expected and stats.loadedCues==common and stats.cachedAudioBytes==0,'mobile startup only loads common SFX')
assert(S.play('nen_high_card_impact'))
for _,id in ipairs(require('config.nen_vfx_config').order) do
    if id~='high_card' then clock=clock+1;assert(S.play('nen_'..id..'_impact'));S.stopCue('nen_'..id..'_impact') end
end
assert(releases>0 and S.stats().cachedAudioBytes<=S.stats().audioCacheBudget,'bounded cache evicts inactive pools')
assert(S.stats().voices==1,'active voice was evicted')
S.stopAll();S.trimMemory();assert(S.stats().cachedAudioBytes==0)
assert(S.has('nen_pair_impact'),'eviction does not unregister a cue')
S.prepareAttack('high_card',1)
for _=1,15 do clock=clock+.1;S.update(.016,'menu',{},false) end
local prepared=loads
for _,kind in ipairs({'charge','release','impact','armor_break','finisher','armored_finisher','boss_finisher','boss_armored_finisher','beat'}) do
    clock=clock+1;assert(S.play('nen_high_card_'..kind));S.stopAll()
end
assert(loads==prepared,'prepared attack must not allocate Sources at playback')
S.trimMemory();S.init();assert(S.stats().cachedAudioBytes==0,'repeat initialization releases cache')
love=previousLove;T.lowPower=low
package.loaded['src.sound']=nil;package.loaded['src.runtime_assets']=nil
print('Mobile sound cache PASS: no startup synthesis, 796 deferred cues, active voices, bounded eviction, prewarm/no playback allocation, reload and trim')
