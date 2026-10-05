local Layout = require("ui.layout")
for _, size in ipairs({{1280,720},{2400,1080},{1512,690},{2340,1080}}) do
    local w,h = size[1],size[2]
    local sx,ox,oy,sy = Layout.scale(w,h,true)
    assert(ox==0 and oy==0, "mobile must not letterbox")
    assert(math.abs(Layout.width*sx-w)<0.001 and math.abs(Layout.height*sy-h)<0.001,"all screen pixels filled")
    local rs = Layout.width / Layout.logicalWidth
    for _, point in ipairs({{0,0},{1280,720},{640,360},{1225,670},{55,40}}) do
        local x,y = Layout.toLogical(point[1]*rs*sx,point[2]*rs*sy,sx,sy,ox,oy,rs)
        assert(math.abs(x-point[1])<0.001 and math.abs(y-point[2])<0.001,"touch must match drawn control")
    end
    local desktop,dx,dy,dsy=Layout.scale(w,h,false)
    assert(desktop==dsy and dx>=0 and dy>=0,"desktop keeps aspect ratio")
end
print("Mobile full-screen layout and touch mapping passed (4 screen ratios)")
