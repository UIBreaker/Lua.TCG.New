local P=require("src.ux_polish")
local function close(a,b) assert(math.abs(a-b)<0.000001,"frame-rate dependent arrival") end
local shop={mode="small",items={}}
P.ensureShop(shop)
assert(not P.stockReady(1))
local x,y,r,s=P.arrivalPose(1,380,157,106,159)
assert(x>0 and y==54 and r<0 and s==0.88,"arrival starts toward the counter's center")
assert(select(2,P.arrivalPose(1,380,435,106,159))==16,"lower stock must clear navigation")
for _,fps in ipairs({30,60,120,144}) do
    P.age=0
    for _=1,fps do P.update(0.4/fps,false,"shop",shop) end
    local a,b,c,d=P.arrivalPose(1,380,157,106,159)
    P.age=0.4
    local aa,bb,cc,dd=P.arrivalPose(1,380,157,106,159)
    close(a,aa);close(b,bb);close(c,cc);close(d,dd)
end
P.age=0.35
local first=select(2,P.arrivalPose(1,380,157,106,159))
local last=select(2,P.arrivalPose(8,380,157,106,159))
assert(first<last,"stock must arrive in staggered waves")
P.update(2,false,"shop",shop)
for i=1,30 do
    local a,b,c,d=P.arrivalPose(i,380,157,106,159)
    assert(a==0 and b==0 and c==0 and d==1 and P.stockReady(i),"large stock settles exactly")
end
P.reducedMotion=true;P.age=0
x,y,r,s=P.arrivalPose(1,380,157,106,159)
assert(x==0 and y==0 and r==0 and s==1 and P.stockReady(1),"reduced motion skips the entrance")
P.reducedMotion=false
P.age=2;shop.page=2;P.ensureShop(shop);assert(P.age==0,"page change replays arrival")
P.age=2;shop.mode="blood_large";P.ensureShop(shop);assert(P.age==0,"market change replays arrival")
P.age=2;P.update(0,false,"playing",shop);P.ensureShop(shop);assert(P.age==0,"return to same shop replays arrival")
P.age=2;P.ensureShop(shop);assert(P.age==2,"drawing a shop must not restart motion")
print("Shop motion PASS: stagger, exact rest, 30/60/120/144 FPS, stalls, reduced motion, page/market/re-entry")
