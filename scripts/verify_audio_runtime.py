"""Windows fallback for checking audio when the LÖVE launcher is unavailable.

Uses the actual LÖVE/LuaJIT DLLs, decoders and OpenAL; no Python audio substitute.
python scripts/verify_audio_runtime.py [--runtime PATH] [--render]
"""
import argparse
import ctypes
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--runtime", default=os.path.join(os.path.dirname(os.getcwd()), "love-11.5-win64"))
parser.add_argument("--render", action="store_true")
args = parser.parse_args()
sys.stdout.reconfigure(encoding="utf-8")
dll_directory = os.add_dll_directory(args.runtime)
lua = ctypes.CDLL(os.path.join(args.runtime, "lua51.dll"))
native_love = ctypes.CDLL(os.path.join(args.runtime, "love.dll"))
lua.luaL_newstate.restype = ctypes.c_void_p
for name, types in {
    "luaL_openlibs": [ctypes.c_void_p], "lua_close": [ctypes.c_void_p],
    "luaL_loadstring": [ctypes.c_void_p, ctypes.c_char_p],
    "lua_pcall": [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int],
    "lua_getfield": [ctypes.c_void_p, ctypes.c_int, ctypes.c_char_p],
    "lua_setfield": [ctypes.c_void_p, ctypes.c_int, ctypes.c_char_p],
    "lua_pushcclosure": [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int],
    "lua_settop": [ctypes.c_void_p, ctypes.c_int],
    "lua_tolstring": [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p],
}.items():
    getattr(lua, name).argtypes = types
lua.lua_tolstring.restype = ctypes.c_char_p
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
lua.lua_getfield(state, -10002, b"package")
lua.lua_getfield(state, -1, b"preload")
lua.lua_pushcclosure(state, ctypes.cast(native_love.luaopen_love, ctypes.c_void_p), 0)
lua.lua_setfield(state, -2, b"love")
lua.lua_settop(state, 0)


def run(code):
    status = lua.luaL_loadstring(state, code.encode("utf-8")) or lua.lua_pcall(state, 0, 0, 0)
    if status:
        print(lua.lua_tolstring(state, -1, None).decode("utf-8"))
        raise RuntimeError("LÖVE verification failed")


complete = False
try:
    run('''
        love=require("love")
        for _,m in ipairs({"filesystem","sound","audio","timer","event"}) do require("love."..m) end
        love.filesystem.init("audio_check")
        love.filesystem.setSource(love.filesystem.getWorkingDirectory())
    ''')
    if not args.render:
        run('assert(loadfile("tests/audio_capture.lua"))();love.load()')
    else:
        run('''
            for _,m in ipairs({"window","graphics","font","image","math","keyboard","mouse","system","video","touch","joystick","data"}) do require("love."..m) end
            assert(love.window.setMode(1280,720,{vsync=0,resizable=false}))
        ''')
        sdl = ctypes.CDLL(os.path.join(args.runtime, "SDL2.dll"))
        sdl.SDL_GetKeyboardFocus.restype = ctypes.c_void_p
        sdl.SDL_HideWindow.argtypes = [ctypes.c_void_p]
        window = sdl.SDL_GetKeyboardFocus()
        if window:
            sdl.SDL_HideWindow(window)
        run('''
            arg={"--capture"}
            package.loaded["capture_screens"]={update=function(game,cb) cb.openSettings() end}
            assert(loadfile("main.lua"))();love.load()
            love.audio.setVolume(0)
            love.update(1/60)
            local draw,callbacks
            for i=1,200 do
                local name,value=debug.getupvalue(love.draw,i)
                if name=="drawSettingsModal" then draw=value;break end
                if not name then break end
            end
            assert(draw,"actual settings draw function")
            local canvas=love.graphics.newCanvas(1280,720)
            love.graphics.setCanvas(canvas);love.graphics.clear(.04,.05,.07,1);draw();love.graphics.setCanvas()
            local data=canvas:newImageData()
            local f=assert(io.open("docs/audio/settings.png","wb"));f:write(data:encode("png"):getString());f:close()
            local Sound=require("src.sound")
            assert(Sound.currentTrack=="menu" and Sound.stats().cues==108)
            local actualButtons
            for i=1,60 do
                local name,value=debug.getupvalue(draw,i)
                if name=="buttons" then actualButtons=value;break end
            end
            assert(actualButtons,"settings button hit regions")
            local music=Sound.getMusicVolume()
            local ambient=Sound.getAmbienceVolume()
            local master=Sound.getMasterVolume()
            for _,target in ipairs({"audio_musicVolume_down","audio_ambienceVolume_down","audio_masterVolume_down"}) do
                local found=false
                for _,b in ipairs(actualButtons) do
                    if b.id==target then
                        assert(b.x>=0 and b.y>=0 and b.x+b.w<=1280 and b.y+b.h<=720)
                        love.mousepressed(b.x+b.w/2,b.y+b.h/2,1)
                        found=true;break
                    end
                end
                assert(found,target)
            end
            assert(math.abs(Sound.getMusicVolume()-math.max(0,music-.1))<.00001)
            assert(math.abs(Sound.getAmbienceVolume()-math.max(0,ambient-.1))<.00001)
            assert(math.abs(Sound.getMasterVolume()-math.max(0,master-.1))<.00001)
            Sound.stopAll()
            print("Actual game/settings renderer + audio integration + real button input PASS")
        ''')
    complete = True
finally:
    if args.render:
        # shortcut: embedding lacks LÖVE's graphics shutdown order; use process cleanup until its launcher works.
        sys.stdout.flush()
        os._exit(0 if complete else 1)
    lua.lua_close(state)
