function love.conf(t)
    t.identity = "poker_roguelike_demo"
    t.version = "11.5"
    t.console = false

    t.window.title = "Poker Roguelike Demo (LÖVE 2D)"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 720
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 960
    t.window.minheight = 540
    t.window.fullscreen = false
    t.window.vsync = 0
    t.window.highdpi = true

    t.modules.audio = true
    t.modules.sound = true
    t.modules.graphics = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.keyboard = true
    t.modules.timer = true
    t.modules.window = true
    t.modules.system = true
    t.modules.video = true
end
