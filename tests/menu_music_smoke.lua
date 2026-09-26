package.path = "./?.lua;./?/init.lua;" .. package.path

local played, stopped, sourcePath, looping = 0, 0, nil, false
local source = {
    isPlaying = function(self) return self.playing end,
    play = function(self) self.playing = true; played = played + 1 end,
    stop = function(self) self.playing = false; stopped = stopped + 1 end,
    setLooping = function(_, value) looping = value end,
    setVolume = function(_, value) assert(value > 0 and value <= 1) end,
}
love = {audio = {
    setVolume = function() end,
    newSource = function(path, kind)
        sourcePath = path
        assert(kind == "stream")
        return source
    end,
}}

local Sound = require("src.sound")
assert(Sound.setMenuMusicEnabled(true) and played == 1 and looping)
assert(sourcePath == "assets/audio/menu_theme.mp3")
assert(Sound.setMenuMusicEnabled(true) and played == 1, "menu update restarted active music")
assert(Sound.setMenuMusicEnabled(false) and stopped == 1, "leaving menu must stop music")
assert(Sound.setMenuMusicEnabled(false) and stopped == 1, "stopped music should stay stopped")
assert(Sound.setMenuMusicEnabled(true) and played == 2, "returning to menu should resume music")
print("Menu music smoke OK: loop, stop, and resume")
