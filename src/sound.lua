local Sound = {}
local Catalog = require("config.audio_catalog")
local pools, voices, loops, failed, lastPlayed, variations = {}, {}, {}, {}, {}, {}
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
    -- Headroom falls with density so scoring cascades do not overwhelm impacts.
    local headroom = 1 / math.sqrt(math.max(1, #voices / 4))
    local peak=0
    for _,v in ipairs(voices) do peak=peak+v.gain*volumes.sfx*headroom*.64 end
    for _,l in pairs(loops) do
        peak=peak+l.level*l.gain*volumes[l.bus]*duck*(l.bus=="ambience" and .32 or l.name=="menu" and 1 or .48)
    end
    -- WAV peak ceilings are verified at build time; bound even coincident hits.
    limiter=math.min(1,.92/math.max(.001,peak))
    for _,v in ipairs(voices) do v.source:setVolume(v.gain * volumes.sfx * headroom * limiter) end
    for _,l in pairs(loops) do l.source:setVolume(l.level*l.gain*volumes[l.bus]*duck*limiter) end
end

function Sound.stopAll()
    for _,v in ipairs(voices) do v.source:stop() end
    voices = {}
    for key,l in pairs(loops) do release(l.source);loops[key]=nil end
    quietRemaining, Sound.quietUntil, duck = 0, 0, 1
end
function Sound.init()
    Sound.stopAll()
    for _,pool in pairs(pools) do for _,source in ipairs(pool) do release(source) end end
    pools, failed, lastPlayed, variations = {}, {}, {}, {}
    enabled = love and love.audio and love.audio.newSource ~= nil or false
    if not enabled then return false end
    local complete = true
    for name,c in pairs(Catalog.cues) do
        local ok,source = pcall(love.audio.newSource,c.path,"static")
        if ok then
            local pool = {source}
            for i=2,POOL_SIZE do
                local cloned,copy = pcall(source.clone,source)
                if cloned then pool[#pool+1]=copy end
            end
            pools[name]=pool
        else
            complete=false
            print("[Sound] Missing cue "..name..": "..tostring(source))
        end
    end
    Sound.setMasterVolume(volumes.master)
    return complete
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
    local ok,source=pcall(love.audio.newSource,entry.path,"stream")
    if not ok then
        failed[key]=true
        print("[Sound] Missing loop "..key..": "..tostring(source))
        return nil
    end
    source:setLooping(true);source:setVolume(0)
    local l={source=source,bus=bus,name=name,gain=entry.gain,level=0,target=0}
    -- Combat, boss and percussion stems share the same 120 BPM / 16 second grid.
    if bus=="music" and (name=="tension" or name=="boss" or name=="combat") then
        for _,other in pairs(loops) do
            if other.bus=="music" and (other.name=="combat" or other.name=="boss" or other.name=="tension") and other.source.tell then
                source:seek(other.source:tell("seconds")%16,"seconds");break
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
function Sound.has(name) return pools[aliases[name] or name]~=nil end
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
    local pool,c=pools[name],Catalog.cues[name]
    if not pool or not c then return false end
    local time=now()
    if time<(Sound.quietUntil or 0) or time-(lastPlayed[name] or -math.huge)<c.cooldown then return false end
    prune()
    local source
    for _,s in ipairs(pool) do if not s:isPlaying() then source=s;break end end
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
        source:setPitch(math.max(.35,math.min(2.5,pitch*variation)))
        voices[#voices+1]={source=source,gain=c.gain,priority=c.priority,name=name}
        if c.priority>=4 then duck=math.min(duck,.48) end
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
    quietRemaining=math.max(0,quietRemaining-dt)
    local targetDuck=quietRemaining>0 and .14 or 1
    for _,v in ipairs(voices) do if v.priority>=4 then targetDuck=math.min(targetDuck,.58) end end
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
    return {voices=#voices,maxVoices=MAX_VOICES,loops=loopCount,maxLoops=MAX_LOOPS,cues=cueCount,duck=duck,limiter=limiter}
end
return Sound
