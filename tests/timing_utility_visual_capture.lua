local UI=require("src.ui")
local T=require("src.combat_timing")
local V=require("src.timing_vfx")
local Icon=require("ui.components.timing_utility")
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    UI.initFonts();local g=love.graphics;local rng=require("src.rng");local seed=rng.getState()
    local canvas=g.newCanvas(960,530);g.push("all");g.setCanvas(canvas);g.origin();g.clear(.022,.029,.044,1)
    g.setFont(UI.fonts.medium);g.setColor(.9,.93,.98);g.printf("SÁU MỐC · SÁU MÀU / HÌNH HIỆU ỨNG RIÊNG",0,18,960,"center")
    local circle,arc,ellipse=g.circle,g.arc,g.ellipse
    local function forbidden() error("utility effects must not draw rings") end
    g.circle=forbidden;g.arc=forbidden;g.ellipse=forbidden
    local signatures={}
    for i,grade in ipairs({"siphon","pierce","haste","mend","reserve","rebound"}) do
        local u=T.utility[grade];local x=18+(i-1)%3*316;local y=62+math.floor((i-1)/3)*225
        assert(UI.fonts.small:hasGlyphs(u.name..u.hint))
        g.setColor(.044,.055,.078);g.rectangle("fill",x,y,292,207,6,6)
        g.setColor(u.color[1],u.color[2],u.color[3]);g.rectangle("fill",x,y,292,3)
        g.setFont(UI.fonts.medium);g.printf(u.name,x,y+16,292,"center")
        g.setFont(UI.fonts.small);g.printf(u.hint,x+8,y+174,276,"center")
        -- Geometry, rather than color alone, must distinguish the six icons.
        local polygon,line,rectangle=g.polygon,g.line,g.rectangle;local ops={}
        for _,name in ipairs({"polygon","line","rectangle"}) do
            local original=g[name]
            g[name]=function(...) local args={...};for k,v in ipairs(args) do args[k]=tostring(v) end;ops[#ops+1]=name..table.concat(args,",");return original(...) end
        end
        Icon.draw(grade,x+146,y+59,12,u.color,1)
        g.polygon,g.line,g.rectangle=polygon,line,rectangle
        local signature=table.concat(ops,";");assert(not signatures[signature],"six icons need six different silhouettes");signatures[signature]=true
        for _,reduced in ipairs({false,true}) do
            V.clear();local kind=i<=3 and "attack" or grade=="rebound" and "reflect" or "block"
            local e=V.emit(kind,grade,0,270,{reducedMotion=reduced});e.age=kind=="reflect" and .13 or .09
            g.push("all");g.translate(reduced and -1000 or x+146,reduced and -1000 or y+123)
            g.scale(.7);if i>3 then g.translate(0,-430) else e.y=0 end
            g.setColor(.2,.3,.4,.8);g.setLineWidth(3);local bx,by=g.transformPoint(0,0)
            V.draw("world")
            local ax,ay=g.transformPoint(0,0);local r,green,b,a=g.getColor()
            assert(ax==bx and ay==by and math.abs(r-.2)<.001 and math.abs(a-.8)<.001 and g.getLineWidth()==3)
            g.pop()
        end
    end
    g.circle,g.arc,g.ellipse=circle,arc,ellipse;V.clear()
    assert(rng.getState()==seed,"utility rendering cannot consume combat RNG")
    g.pop();local data=canvas:newImageData();local f=assert(io.open("docs/timing_utility_styles.png","wb"))
    f:write(data:encode("png"):getString());f:close()
    print("Utility visuals PASS: six silhouettes/colors/hints, real attack/parry effects, reduced motion, no circular primitives, render state and RNG")
    love.event.quit(0)
end
