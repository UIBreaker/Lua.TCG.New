local D={list={},bySuit={},byId={}}
for _,row in ipairs({
    {"kingdom_heart_entity","Chủ Tể Tro Tim","hearts","Cơ",{.91,.35,.36,1}},
    {"kingdom_diamond_entity","Kẻ Nuốt Hoàng Kim","diamonds","Rô",{.94,.75,.33,1}},
    {"kingdom_club_entity","Cội Rễ Lãng Quên","clubs","Chuồn",{.37,.76,.53,1}},
    {"kingdom_spade_entity","Bóng Vương Băng Tịch","spades","Bích",{.61,.53,.90,1}},
}) do
    local d={id=row[1],debuffId=row[1],artKey=row[1],name=row[2],kingdomEntity=true,entitySuit=row[3],suitName=row[4],color=row[5],title="THỰC THỂ BÍ ẨN · "..row[4]}
    d.desc="Vô hiệu hóa quân bài chất "..d.suitName..": 0 điểm, không kích hoạt khả năng hoặc trang bị khi tính điểm. Mỗi lá "..d.suitName.." đang trên tay bạn: Boss +10% Tốc đánh và +10% Sát thương. Cập nhật theo tay hiện tại, không tích lũy qua lượt."
    D.list[#D.list+1]=d;D.bySuit[d.entitySuit]=d;D.byId[d.id]=d
end
function D.roll(stage)
    -- Use encounter entropy without advancing pending combat/reward RNG.
    local seed=math.max(1,stage or 1)
    local state=tostring(require("src.rng").getState())
    for i=1,#state do seed=(seed*131+state:byte(i))%2147483647 end
    local index=((seed*48271)%2147483647)%16+1
    return D.list[index] or require("config.free_human_boss_data").list[index-4]
end
return D
