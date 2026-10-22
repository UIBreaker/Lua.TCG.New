local Sound = {}
local Catalog = require("config.audio_catalog")
local Assets = require("src.runtime_assets")
local pools, voices, loops, failed, lastPlayed, variations = {}, {}, {}, {}, {}, {}
local proceduralCues={}
local fileCues,fileBytes,fileUsed={},{},{}
local cacheBytes,cacheClock,mobileCache=0,0,false
local CACHE_BUDGET=16*1048576
local warmQueue,warmSet={},{}
local volumes = {master=1, sfx=.8, music=.8, ambience=.65}
local enabled, focused = false, true
local duck, quietRemaining = 1, 0
local limiter = 1
local MAX_VOICES, POOL_SIZE, MAX_LOOPS = 24, 3, 6
local aliases = {buy="shop_buy", destroy="card_destroy"}

local function clamp(value, fallback)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.max(0, math.min(1, value))
end
local function now()
    return love and love.timer and love.timer.getTime and love.timer.getTime() or os.clock()
end
local function release(source)
    source:stop()
    if source.release then source:release() end
end
local function prune()
    for i=#voices,1,-1 do
        if not voices[i].source:isPlaying() then table.remove(voices,i) end
    end
end
local function mixVoices()
    local foreground=false
    for _,v in ipairs(voices) do if v.priority>=4 then foreground=true;break end end
    local density=0
    for _,v in ipairs(voices) do
        v.weight=foreground and (v.priority<=1 and .18 or v.priority==2 and .34 or v.priority==3 and .68 or 1) or 1
        density=density+v.weight*v.weight
    end
    local headroom = 1 / math.sqrt(math.max(1, density / 4))
    local peak=0
    for _,v in ipairs(voices) do peak=peak+v.gain*v.weight*volumes.sfx*headroom*v.peak end
    for _,l in pairs(loops) do
        peak=peak+l.level*l.gain*volumes[l.bus]*duck*l.peak
    end
    -- Bound coincident hits, including the codec margin in optimized packages.
    limiter=math.min(1,.92/math.max(.001,peak))
    for _,v in ipairs(voices) do v.source:setVolume(v.gain * v.weight * volumes.sfx * headroom * limiter) end
    for _,l in pairs(loops) do l.source:setVolume(l.level*l.gain*volumes[l.bus]*duck*limiter) end
end

function Sound.stopAll()
    for _,v in ipairs(voices) do v.source:stop() end
    voices = {}
    for key,l in pairs(loops) do release(l.source);loops[key]=nil end
    quietRemaining, Sound.quietUntil, duck = 0, 0, 1
    warmQueue,warmSet={},{}
end
local function trimFiles(target,keep)
    prune()
    while cacheBytes>target do
        local oldest
        for name in pairs(fileBytes) do
            local active=false
            for _,source in ipairs(pools[name] or {}) do if source:isPlaying() then active=true;break end end
            if name~=keep and not active and (not oldest or fileUsed[name]<fileUsed[oldest]) then oldest=name end
        end
        if not oldest then break end
        for _,source in ipairs(pools[oldest]) do release(source) end
        pools[oldest]=nil;cacheBytes=cacheBytes-fileBytes[oldest];fileBytes[oldest]=nil;fileUsed[oldest]=nil
    end
end
local function loadFile(name)
    cacheClock=cacheClock+1;fileUsed[name]=cacheClock
    if pools[name] then return true end
    local cue=fileCues[name];if not cue then return false end
    local ok,source=pcall(love.audio.newSource,Assets.audio(cue.path),'static')
    if not ok then failed[name]=tostring(source);return false end
    local pool={source}
    for i=2,POOL_SIZE do local success,copy=pcall(source.clone,source);if success then pool[#pool+1]=copy end end
    pools[name]=pool;fileBytes[name]=math.ceil(source:getDuration()*128000);cacheBytes=cacheBytes+fileBytes[name]
    if mobileCache then trimFiles(CACHE_BUDGET,name) end
    return true
end
function Sound.registerFileCue(name,cue)
    if not enabled then return false end
    fileCues[name]=cue;proceduralCues[name]=cue
    if not mobileCache then return loadFile(name) end
    return true
end
local function warm(name)
    if mobileCache and fileCues[name] and not pools[name] and not warmSet[name] and #warmQueue<48 then
        warmQueue[#warmQueue+1]=name;warmSet[name]=true
    end
end
function Sound.prepareAttack(id,tier)
    local suffix=tier==3 and '_extreme' or tier==2 and '_strong' or ''
    for _,kind in ipairs({'charge','impact','release','miss','armor_break','finisher','armored_finisher','boss_finisher','boss_armored_finisher'}) do
        warm('nen_'..id..'_'..kind..suffix)
    end
    warm('nen_'..id..'_beat')
end
function Sound.prepareRewards(rarity)
    for _,phase in ipairs({'charge','open','receive','collect'}) do warm('reward_'..phase..'_'..rarity) end
end
function Sound.trimMemory() warmQueue,warmSet={},{};prune();trimFiles(0) end
function Sound.init()
    Sound.stopAll()
    for _,pool in pairs(pools) do for _,source in ipairs(pool) do release(source) end end
    pools, failed, lastPlayed, variations = {}, {}, {}, {}
    proceduralCues={}
    fileCues,fileBytes,fileUsed={},{},{};cacheBytes,cacheClock=0,0
    mobileCache=require('src.touch_input').lowPower==true
    enabled = love and love.audio and love.audio.newSource ~= nil or false
    if not enabled then return false end
    local complete = true
    for name,c in pairs(Catalog.cues) do
        local ok,source = pcall(love.audio.newSource,Assets.audio(c.path),"static")
        if ok then
            local pool = {source}
            for i=2,POOL_SIZE do
                local path=c.variants and c.variants[i-1]
                local cloned,copy
                if path then
                    cloned,copy=pcall(love.audio.newSource,Assets.audio(path),"static")
                    if not cloned then print("[Sound] Variant unavailable: "..path) end
                end
                if not cloned then cloned,copy=pcall(source.clone,source) end
                if cloned then pool[#pool+1]=copy end
            end
            pools[name]=pool
        else
            complete=false
            print("[Sound] Missing cue "..name..": "..tostring(source))
        end
    end
    require("src.nen_audio").register(Sound)
    require("src.reward_audio").register(Sound)
    require("src.timing_audio").register(Sound)
    Sound.setMasterVolume(volumes.master)
    return complete
end
function Sound.registerProcedural(name,data,cue)
    if not enabled then return false end
    local ok,source=pcall(love.audio.newSource,data,"static")
    if not ok then failed[name]=tostring(source);return false end
    if pools[name] then for _,s in ipairs(pools[name]) do release(s) end end
    local pool={source}
    for i=2,POOL_SIZE do local success,copy=pcall(source.clone,source);if success then pool[#pool+1]=copy end end
    pools[name]=pool;proceduralCues[name]=cue
    if fileBytes[name] then cacheBytes=cacheBytes-fileBytes[name];fileBytes[name]=nil end
    fileCues[name]=nil
    return true
end
function Sound.setMasterVolume(value)
    volumes.master=clamp(value,1)
    if love and love.audio and love.audio.setVolume then love.audio.setVolume(volumes.master) end
end
function Sound.getMasterVolume() return volumes.master end
local function setBus(bus,value)
    volumes[bus]=clamp(value,bus=="ambience" and .65 or .8)
    mixVoices()
end
function Sound.setVolume(value) setBus("sfx",value) end
function Sound.getVolume() return volumes.sfx end
function Sound.setMusicVolume(value) setBus("music",value) end
function Sound.getMusicVolume() return volumes.music end
function Sound.setAmbienceVolume(value) setBus("ambience",value) end
function Sound.getAmbienceVolume() return volumes.ambience end
function Sound.setFocused(value)
    focused=value~=false
    if not focused then
        for _,v in ipairs(voices) do v.source:stop() end
        voices={}
        for _,l in pairs(loops) do l.source:pause() end
    else
        for _,l in pairs(loops) do if l.level>0 or l.target>0 then l.source:play() end end
    end
end

local function loop(bus,name)
    local key=bus..":"..name
    if loops[key] then return loops[key] end
    if failed[key] or not focused or not love or not love.audio then return nil end
    local entry=Catalog[bus][name]
    if not entry then return nil end
    local count,oldest=0,nil
    for k,l in pairs(loops) do
        count=count+1
        if l.target==0 and (not oldest or l.level<loops[oldest].level) then oldest=k end
    end
    if count>=MAX_LOOPS then
        if not oldest then return nil end
        release(loops[oldest].source);loops[oldest]=nil
    end
    local ok,source=pcall(love.audio.newSource,Assets.audio(entry.path),"stream")
    if not ok then
        failed[key]=true
        print("[Sound] Missing loop "..key..": "..tostring(source))
        return nil
    end
    source:setLooping(true);source:setVolume(0)
    local l={source=source,bus=bus,name=name,gain=entry.gain,level=0,target=0,
        peak=Assets.peak(entry,bus=="ambience" and .32 or name=="menu" and 1 or .48)}
    -- Match position across the full phrase, including its developed second half.
    if bus=="music" and (name=="tension" or name=="boss" or name=="combat") then
        for _,other in pairs(loops) do
            if other.bus=="music" and (other.name=="combat" or other.name=="boss" or other.name=="tension") and other.source.tell then
                source:seek(other.source:tell("seconds")%(entry.seconds or 16),"seconds");break
            end
        end
    end
    loops[key]=l
    return l
end
-- Compatibility for callers that explicitly start/stop title music.
function Sound.setMenuMusicEnabled(shouldPlay)
    if not shouldPlay then
        local l=loops["music:menu"]
        if l then release(l.source);loops["music:menu"]=nil end
        return true
    end
    local l=loop("music","menu")
    if not l then return false end
    l.level,l.target=1,1
    mixVoices()
    if not l.source:isPlaying() then l.source:play() end
    return true
end
function Sound.has(name) name=aliases[name] or name;return pools[name]~=nil or fileCues[name]~=nil end
function Sound.rewardPitch()
    prune()
    for i=#voices,1,-1 do
        local cue=proceduralCues[voices[i].name]
        if cue and cue.bossVictory==1 then
            local id=voices[i].name:match("^nen_(.-)_boss_")
            local score=require("config.attack_audio")[id]
            if score then
                local root=score.tone*voices[i].pitch
                while root>392.445 do root=root*.5 end
                while root<196.2225 do root=root*2 end
                local tier=voices[i].name:match("_extreme$") and 3 or voices[i].name:match("_strong$") and 2 or 1
                local lift=.65+(tier-1)*.45+.70
                return root/261.63,math.max(0,lift/voices[i].pitch-(now()-voices[i].startedAt))
            end
        end
    end
    return 1,0
end
function Sound.playCombatVictory()
    prune()
    -- A boss's own finishing voice already contains its seamless victory phrase.
    for _,v in ipairs(voices) do
        local cue=proceduralCues[v.name]
        if cue and cue.bossVictory==1 then return true end
    end
    return Sound.play("round_win")
end
function Sound.stopCue(name)
    name=aliases[name] or name
    for i=#voices,1,-1 do
        if voices[i].name==name then table.remove(voices,i).source:stop() end
    end
    mixVoices()
end
function Sound.silence(duration)
    quietRemaining=math.max(0,math.min(.08,duration or .06))
    Sound.quietUntil=now()+quietRemaining
    for _,v in ipairs(voices) do v.source:stop() end
    voices={}
    duck=.14
    mixVoices()
end
function Sound.play(name,pitch)
    name=aliases[name] or name
    if not enabled or not focused or volumes.master<=0 or volumes.sfx<=0 then return false end
    if fileCues[name] and not loadFile(name) then return false end
    local pool,c=pools[name],proceduralCues[name] or Catalog.cues[name]
    if not pool or not c then return false end
    local time=now()
    if time<(Sound.quietUntil or 0) or time-(lastPlayed[name] or -math.huge)<c.cooldown then return false end
    prune()
    local source
    for offset=0,#pool-1 do
        local s=pool[((variations[name] or 0)+offset)%#pool+1]
        if not s:isPlaying() then source=s;break end
    end
    -- A fresh heavy contact takes precedence over its own oldest lingering tail.
    if not source and c.priority>=4 then
        for i,v in ipairs(voices) do
            if v.name==name then source=table.remove(voices,i).source;source:stop();break end
        end
    end
    if not source then return false end
    if #voices>=MAX_VOICES then
        local victim
        for i,v in ipairs(voices) do
            if v.priority<=c.priority and (not victim or v.priority<voices[victim].priority) then victim=i end
        end
        if not victim then return false end
        table.remove(voices,victim).source:stop()
    end
    local ok=pcall(function()
        variations[name]=(variations[name] or 0)+1
        local variation=1+((variations[name]*7)%5-2)*.007
        if type(pitch)~="number" or pitch~=pitch then pitch=1 end
        local playbackPitch=math.max(.35,math.min(c.maxPitch or 2.5,pitch*variation))
        source:setPitch(playbackPitch)
        voices[#voices+1]={source=source,gain=c.gain,priority=c.priority,name=name,peak=Assets.peak(c,.64),
            pitch=playbackPitch,startedAt=time,
            duckUntil=time+(c.duckDuration or (c.priority>=5 and .18 or .10)),duckLevel=c.duck or .58}
        if c.priority>=4 then duck=math.min(duck,c.duck or .48) end
        mixVoices();source:play()
    end)
    if ok then lastPlayed[name]=time end
    return ok
end

local presetAmbience={RUINS="ruins",ICE="ice",FOREST="forest",DESERT="desert",VOID="void",VOLCANIC="volcanic",MYSTIC="mystic"}
function Sound.context(state,game,menuMode,scene)
    game=game or {}
    local m=game.monster or {}
    local combat=state=="playing" or state=="scoring"
    local track=state=="menu" and (menuMode==nil or menuMode=="title") and "menu"
        or combat and (m.isBoss and "boss" or "combat")
        or state=="shop" and "shop" or state=="rest" and "rest"
        or state=="victory" and "victory" or (state=="gameover" or state=="defeating") and "defeat"
        or (state=="chest" or state=="treasure" or state=="CASH_OUT") and "victory"
        or (state=="socketing" or state=="event" or state=="boss_deity") and "mystery" or "exploration"
    local stage=game.run and game.run.ante or m.stage or game.act or 1
    local ambient
    if state~="menu" then
        local _,definition,preset=require("config.scene_definitions").resolve(state,m.stage and m or {stage=stage})
        if scene and scene.definition then definition,preset=scene.definition,scene.preset end
        ambient=stage>20 and stage<=40 and "sea" or presetAmbience[definition.preset]
        if not ambient then
            for name,p in pairs(require("config.scene_definitions").presets) do
                if p==preset then ambient=presetAmbience[name];break end
            end
        end
        ambient=ambient or "ruins"
    end
    local weather=combat and ((scene and scene.weather) or require("render.weather").resolve({stage=stage})).kind or nil
    weather=(weather=="rain" or weather=="storm") and weather or nil
    local health=(game.playerHp or 100)/math.max(1,game.maxPlayerHp or 100)
    local intensity=combat and math.max(m.isBoss and .65 or .18,state=="scoring" and .45 or 0,health<.3 and .95 or 0) or 0
    return track,ambient,weather,intensity
end
function Sound.update(dt,state,game,paused,menuMode,scene)
    if not focused then return end
    dt=math.max(0,dt or 0)
    prune()
    local deadline=now()+.001
    for _=1,2 do
        local name=table.remove(warmQueue,1);if not name then break end
        warmSet[name]=nil;loadFile(name)
        if now()>=deadline then break end
    end
    if mobileCache then trimFiles(CACHE_BUDGET) end
    quietRemaining=math.max(0,quietRemaining-dt)
    local targetDuck=quietRemaining>0 and .14 or 1
    local time=now()
    for _,v in ipairs(voices) do if v.priority>=4 and time<v.duckUntil then targetDuck=math.min(targetDuck,v.duckLevel) end end
    duck=duck+(targetDuck-duck)*(1-math.exp(-dt*(targetDuck<duck and 24 or 3)))
    for _,l in pairs(loops) do l.target=0 end
    local track,ambient,weather,intensity=Sound.context(state,game,menuMode,scene)
    Sound.currentTrack,Sound.currentAmbience=track,ambient
    if volumes.music>0 and volumes.master>0 then
        local l=loop("music",track);if l then l.target=paused and .4 or 1 end
        if intensity>0 then local stem=loop("music","tension");if stem then stem.target=paused and intensity*.2 or intensity end end
    end
    if ambient and volumes.ambience>0 and volumes.master>0 then
        local l=loop("ambience",ambient);if l then l.target=paused and .4 or 1 end
        if weather then local w=loop("ambience",weather);if w then w.target=paused and .2 or .65 end end
    end
    for key,l in pairs(loops) do
        local step=dt/(l.bus=="music" and 1.25 or 1.8)
        l.level=l.level<l.target and math.min(l.target,l.level+step) or math.max(l.target,l.level-step)
        if l.level==0 and l.target==0 then
            release(l.source);loops[key]=nil
        else
            if not l.source:isPlaying() then l.source:play() end
        end
    end
    mixVoices()
end
function Sound.stats()
    local loopCount,cueCount=0,0
    for _ in pairs(loops) do loopCount=loopCount+1 end
    for _ in pairs(pools) do cueCount=cueCount+1 end
    local registered=cueCount
    for name in pairs(fileCues) do if not pools[name] then registered=registered+1 end end
    return {voices=#voices,maxVoices=MAX_VOICES,loops=loopCount,maxLoops=MAX_LOOPS,cues=registered,
        loadedCues=cueCount,cachedAudioBytes=cacheBytes,audioCacheBudget=CACHE_BUDGET,duck=duck,limiter=limiter}
end
return Sound
