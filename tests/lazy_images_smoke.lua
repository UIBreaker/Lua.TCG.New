local Images=require('src.lazy_images')
local saved=love
local loads,probes=0,0
love={filesystem={getInfo=function(path) probes=probes+1;return path~='missing' end},graphics={newImage=function(path) loads=loads+1;return {setFilter=function()end,path=path} end}}
local cache=Images.install({},{a='present',b='missing'})
assert(loads==0 and probes==0)
assert(cache.a.path=='present' and cache.a.path=='present' and loads==1 and probes==1)
assert(not cache.b and not cache.b and probes==2 and loads==1)
assert(cache.unknown==nil and probes==2)
love=saved
print('Lazy images PASS: no startup load, single read, missing/unknown paths cached safely')
