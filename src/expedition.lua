-- Shared journey identity for the run, legacy encounters and scene selection.
local E = {}
E.regions = {
    {id="human", name="LỤC ĐỊA CON NGƯỜI", range="ẢI 01 — 20", first=1, last=20, background="humanContinent", preset="DESERT",
        objective="Vượt thử thách bốn vương quốc để nhận giấy phép viễn chinh.", color={0.92,0.73,0.40}},
    {id="voyage", name="HẢI TRÌNH VIỄN CHINH", range="ẢI 21 — 40", first=21, last=40, background="expeditionShip", preset="ICE",
        objective="Đọ sức các đoàn thám hiểm mạnh nhất trên tàu. Đổ bộ sau ải 40.", color={0.36,0.76,0.87}},
    {id="unknown", name="VÙNG ĐẤT BÍ ẨN", range="ẢI 41 — VÔ TẬN", first=41, background="mysteriousCoast", preset="FOREST",
        objective="Vượt bờ biển đá ngầm, khám phá lục địa và đối đầu quái vật.", color={0.59,0.79,0.63}},
}
E.kingdoms = {
    {id="valoria", suit="hearts", name="Valoria", color={0.91,0.35,0.36}},
    {id="aurelia", suit="diamonds", name="Aurelia", color={0.94,0.75,0.33}},
    {id="elaris", suit="clubs", name="Elaris", color={0.37,0.76,0.53}},
    {id="vharos", suit="spades", name="Vharos", color={0.61,0.53,0.90}},
}
E.shipBosses = {
    {name="ĐẠI ĐÔ ĐỐC", key="gatekeeper", skill="Mệnh Lệnh Phong Tỏa", op="gate_lock", amount=2, desc="Luân phiên khóa 2 lượt đổi / lượt đánh tay kế tiếp (giữ tối thiểu 1)."},
    {name="ĐAO VƯƠNG", key="executioner", skill="Đao Phán Quyết", op="damage", amount=8, desc="Gây 8 sát thương, có thể chặn bằng Giáp."},
    {name="NỮ HOÀNG MẶT NẠ", key="faceless", skill="Phong Ấn Câm Lặng", op="silence", amount=1, desc="Khóa khả năng lá đã báo trước trong tay kế tiếp."},
    {name="CHỦ HỘI HẮC KIM", key="black_tax_collector", skill="Lệnh Tịch Thu", op="tax_lock", amount=1, desc="Luân phiên khóa ô Tiêu Hao / SPN và gây sát thương theo Nợ."},
    {name="KIẾM THÁNH VỌNG ÂM", key="echo_knight", skill="Phản Kiếm", op="repeat_penalty", amount=4, desc="Lặp thế đánh vừa dùng sẽ mất 4 Cường hóa ở tay kế tiếp."},
    {name="BẬC THẦY KÝ ỨC", key="memory_eater", skill="Xóa Ký Ức", op="silence", amount=1, desc="Khóa khả năng lá đã báo trước trong tay kế tiếp."},
    {name="VƯƠNG HẦU ĐOẠT NGỌC", key="gem_devourer", skill="Hấp Thu Linh Lực", op="heal", amount=60, desc="Hồi 60 HP, không xóa thêm trang bị."},
    {name="TỔNG CHỈ HUY HẢI ĐOÀN", key="the_hook", skill="Tước Vũ Khí", op="silence", amount=1, desc="Khóa khả năng lá đã báo trước trong tay kế tiếp."},
}
function E.region(stage)
    stage=tonumber(stage) or 1
    return stage<=20 and E.regions[1] or stage<=40 and E.regions[2] or E.regions[3]
end
function E.rankName(rank) return ({[11]="J",[12]="Q",[13]="K",[14]="A"})[rank] or tostring(rank) end
function E.shipBoss(stage) return E.shipBosses[(stage-21)%#E.shipBosses+1] end
function E.bossData(stage, definitions, fallback)
    if stage<=20 or stage>40 then return fallback end
    local captain=E.shipBoss(stage)
    local base=definitions[captain.key] or fallback
    local data={}
    for k,v in pairs(base) do data[k]=v end
    data.name=captain.name
    data.active={name=captain.skill, op=captain.op, amount=captain.amount, cooldown=1, description=captain.desc}
    data.activeCooldown=1
    data.expeditionActive=true
    return data
end
function E.decorate(m, stage, encounter)
    m.stage=stage or 1; m.regionId=E.region(m.stage).id
    if m.stage>40 then
        local creatures={
            {"forest_goblin","Yêu Tinh Rừng Xanh"}, {"lava_golem","Thạch Quỷ Nham Thạch"},
            {"swamp_wraith","Bóng Ma Đầm Lầy"}, {"frost_wolf","Sói Băng Cực Bắc"},
            {"desert_scorpion","Bọ Cạp Sa Mạc"}, {"ancient_skeleton","Hiệp Sĩ Xương Cổ"},
        }
        if not m.isBoss then
            local creature=creatures[((encounter or m.stage)-1)%#creatures+1]
            m.artKey=creature[1];m.name=creature[2]..(m.isElite and " • Tinh Anh" or "")
            m.title="VÙNG ĐẤT BÍ ẨN";m.desc="Sinh vật hoang dã trên lục địa chưa được khám phá."
        end
        return require("src.enemy_abilities").attach(m)
    end
    local n=encounter or m.encounterCount or m.stage
    local kingdom=E.kingdoms[(n-1)%4+1]
    local rank=math.min(13,2+math.floor((m.stage-1)*11/19)+(m.isElite and 1 or 0)+(m.isBoss and 2 or 0))
    if m.stage>20 then rank=m.isBoss and 13 or math.min(13,8+math.floor((m.stage-21)/4)+(m.isElite and 1 or 0)) end
    m.human=true; m.cardSuit=kingdom.suit; m.cardRank=rank; m.kingdom=kingdom.name
    local role=m.isBoss and "Thủ lĩnh" or m.isElite and "Đội trưởng" or "Nhà thám hiểm"
    m.name=m.stage>20 and m.isBoss and (E.shipBoss(m.stage).name.." · "..kingdom.name)
        or (role.." "..kingdom.name.." · "..E.rankName(rank))
    m.title=(m.stage<=20 and "LIÊN MINH BỐN VƯƠNG QUỐC" or "ĐOÀN VIỄN CHINH").." · CẤP "..E.rankName(rank)
    m.desc=m.bossData and m.bossData.desc or "Đối thủ thuộc đoàn thám hiểm "..kingdom.name.."."
    m.color=kingdom.color
    return m
end
return E
