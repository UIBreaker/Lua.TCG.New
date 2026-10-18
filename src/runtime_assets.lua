-- Release packages can replace source WAVs with Ogg; development keeps the originals.
local Assets={}
local cache={}
function Assets.audio(path)
    if cache[path] then return cache[path] end
    local fs=love and love.filesystem
    if path and path:match("%.wav$") and fs and fs.getInfo then
        local ogg=path:gsub("%.wav$",".ogg")
        if fs.getInfo(ogg) then cache[path]=ogg;return ogg end
        cache[path]=path
    end
    return path
end
function Assets.peak(cue,default)
    local peak=cue.peak or default
    -- Vorbis can overshoot PCM peaks; the package verifier enforces this margin.
    local compressed=cue.path and Assets.audio(cue.path)~=cue.path
    for _,path in ipairs(cue.variants or {}) do compressed=compressed or Assets.audio(path)~=path end
    if compressed then peak=math.min(1,peak*1.2) end
    return peak
end
return Assets
