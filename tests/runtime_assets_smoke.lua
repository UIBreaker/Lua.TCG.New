local previousLove=love
local files={['tone.ogg']=true,['assets/cards/continental/runtime/spn/spirit_galefang.jpg']=true}
local loaded
love={filesystem={getInfo=function(path) return files[path] end},graphics={newImage=function(path)
    loaded=path
    return {setFilter=function() end,getDimensions=function() return 384,576 end}
end}}
package.loaded['src.runtime_assets']=nil
local A=require('src.runtime_assets')
assert(A.audio('tone.wav')=='tone.ogg' and A.audio('tiny.wav')=='tiny.wav' and A.audio('menu.mp3')=='menu.mp3')
assert(math.abs(A.peak({path='tone.wav',peak=.5},.64)-.6)<1e-9)
assert(math.abs(A.peak({path='tiny.wav',variants={'tone.wav'},peak=.5},.64)-.6)<1e-9)
assert(A.peak({path='tiny.wav'},.64)==.64)
package.loaded['src.continental_art']=nil
local Art=require('src.continental_art')
assert(Art.get('spirit_galefang') and loaded=='assets/cards/continental/runtime/spn/spirit_galefang.jpg')
files={};Art.cache={};assert(not Art.get('spirit_galefang'))
love=previousLove
package.loaded['src.continental_art']=nil;package.loaded['src.runtime_assets']=nil
print('Runtime assets PASS: Ogg/PCM fallback, codec peak margin, runtime art without source PNG, missing art')
