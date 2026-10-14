-- Shared journey identity for the run, legacy encounters and scene selection.
local E = {}
E.regions = {
    {id="human", name="LỤC ĐỊA CON NGƯỜI", short="CON NGƯỜI", preset="DESERT",color={0.92,0.73,0.40},
        objective="Đối đầu các đoàn độc lập vô chất. Vượt 20 ải để nhận giấy phép di chuyển.",
        areas={"Đồng Cỏ Bình Minh","Cửa Ải Thạch Kiều","Bến Cảng Tự Do","Thành Trì Hội Đồng"}},
    {id="hearts",name="VƯƠNG QUỐC VALORIA",short="CƠ • VALORIA",suit="hearts",preset="VOLCANIC",color={0.91,0.35,0.36},
        objective="Khám phá Valoria. Mọi đối thủ đều thuộc chất Cơ.",
        areas={"Thung Lũng Thiết Huyết","Lò Rèn Hồng Thạch","Hẻm Núi Tro Tàn","Pháo Đài Valoria"}},
    {id="diamonds",name="VƯƠNG QUỐC AURELIA",short="RÔ • AURELIA",suit="diamonds",preset="DESERT",color={0.94,0.75,0.33},
        objective="Khám phá Aurelia. Mọi đối thủ đều thuộc chất Rô.",
        areas={"Biển Cát Hoàng Kim","Ốc Đảo Aurelia","Hẻm Núi Pha Lê","Điện Mặt Trời"}},
    {id="clubs",name="VƯƠNG QUỐC ELARIS",short="CHUỒN • ELARIS",suit="clubs",preset="FOREST",color={0.37,0.76,0.53},
        objective="Khám phá Elaris. Mọi đối thủ đều thuộc chất Chuồn.",
        areas={"Rừng Cổ Elaris","Thác Ngàn Lá","Cội Cây Khổng Lồ","Thánh Địa Sinh Linh"}},
    {id="spades",name="VƯƠNG QUỐC VHAROS",short="BÍCH • VHAROS",suit="spades",preset="ICE",color={0.61,0.53,0.90},
        objective="Khám phá Vharos. Mọi đối thủ đều thuộc chất Bích.",
        areas={"Bờ Băng Vharos","Đèo Bão Tuyết","Di Tích Nhật Thực","Tháp Vương Hắc"}},
    {id="unknown",name="LỤC ĐỊA BÍ ẨN",short="BÍ ẨN",background="mysteriousCoast",preset="FOREST",color={0.59,0.79,0.63},
        requiresRecognitions={"hearts","diamonds","clubs","spades"},
        objective="Đổ bộ bờ biển đá ngầm. Khám phá vô tận và đối đầu các sinh vật lục địa."},
}
E.byId={};E.backgroundPaths={}
for _,r in ipairs(E.regions) do
    E.byId[r.id]=r
    for i=1,#(r.areas or {}) do E.backgroundPaths["journey_"..r.id.."_"..i]="assets/scene/journey/"..r.id.."_"..i..".png" end
end
-- A legacy ship segment is retained only for callers/saves without route data.
E.legacyVoyage={id="voyage",name="HẢI TRÌNH VIỄN CHINH",background="expeditionShip",preset="ICE",color={0.36,0.76,0.87}}
E.byId.voyage=E.legacyVoyage
E.recognitionIds={"hearts","diamonds","clubs","spades"}
function E.recognitionCard(id)
    local r=E.byId[id];if not r or not r.suit then return end
    return {id="recognition_"..id,category="recognition",type="REGION_RECOGNITION",regionId=id,
        name="Công Nhận "..r.short,rarity="legendary",color=r.color,
        desc="Chứng nhận đã chinh phục 20 ải tại "..r.name..". Giữ vĩnh viễn trong hành trình; không tiêu hao. Thu thập đủ bốn công nhận để mở lục địa bí ẩn."}
end
function E.recognitionCount(game)
    local n=0;for _,id in ipairs(E.recognitionIds) do if (game.regionRecognitions or {})[id] then n=n+1 end end;return n
end
function E.canEnter(game,id)
    local r=E.byId[id];if not r or id=="voyage" then return false,"Điểm đến không hợp lệ." end
    for _,required in ipairs(r.requiresRecognitions or {}) do
        if not (game.regionRecognitions or {})[required] then return false,"Cần đủ 4 công nhận Cơ, Rô, Chuồn, Bích ("..E.recognitionCount(game).."/4)." end
    end
    return true
end
function E.travelPermit()
    return {id="cons_travel_permit",category="travel_permit",type="TRAVEL_PERMIT",name="Giấy Phép Di Chuyển",
        rarity="rare",cost=2000,color={.53,.78,.94,1},
        desc="Dùng giữa các trận để chọn khu vực đến; mỗi lần di chuyển tiêu hao một giấy phép. Lục địa bí ẩn yêu cầu đủ 4 công nhận Cơ, Rô, Chuồn, Bích. Có thể bán lấy 1.000 vàng tại màn hình chọn điểm đến."}
end
E.humanNames={"Tân Binh Lữ Hành","Trinh Sát Biên Cương","Xạ Thủ Thạch Kiều","Vệ Binh Khiên Thép","Dược Sư Dã Chiến","Kiếm Sĩ Lãng Du","Công Binh Hội Thợ","Lão Binh Thành Cổ","Thống Lĩnh Thương Đoàn","Đội Trưởng Độc Lập","Nữ Công Tước Hội Đồng","Đại Thủ Lĩnh Nhân Loại"}
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
function E.region(stage,regionId)
    if E.byId[regionId] then return E.byId[regionId] end
    stage=tonumber(stage) or 1
    return stage<=20 and E.regions[1] or stage<=40 and E.legacyVoyage or E.byId.unknown
end
function E.area(stage,regionId)
    local region=E.region(stage,regionId)
    local localStage=math.max(1,tonumber(stage) or 1)
    local index=math.floor(((localStage-1)%20)/5)+1
    return {index=index,name=region.areas and region.areas[index] or region.name,
        background=region.areas and ("journey_"..region.id.."_"..index) or region.background,
        preset=region.preset,first=(index-1)*5+1,last=index*5}
end
function E.rankName(rank) return ({[11]="J",[12]="Q",[13]="K",[14]="A"})[rank] or tostring(rank) end
function E.shipBoss(stage) return E.shipBosses[(stage-21)%#E.shipBosses+1] end
function E.bossData(stage, definitions, fallback,regionId)
    if E.region(stage,regionId).id~="voyage" then return fallback end
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
function E.decorate(m, stage, encounter,regionId,areaStage)
    m.stage=stage or 1
    local region=E.region(m.stage,regionId or m.regionId)
    m.regionId=region.id;m.areaStage=areaStage or m.areaStage or (region.id=="voyage" and m.stage or ((m.stage-1)%20)+1)
    if region.id=="unknown" then
        m.human=false;m.neutralHuman=nil
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
    if region.suit then for _,k in ipairs(E.kingdoms) do if k.suit==region.suit then kingdom=k;break end end end
    local rank=math.min(13,2+math.floor((m.areaStage-1)*11/19)+(m.isElite and 1 or 0)+(m.isBoss and 2 or 0))
    if region.id=="voyage" then rank=m.isBoss and 13 or math.min(13,8+math.floor((m.stage-21)/4)+(m.isElite and 1 or 0)) end
    local offset=m.formationOffset or 0
    rank=rank+offset<=13 and rank+offset or math.max(2,rank-offset)
    if region.id=="human" then
        m.human=true;m.neutralHuman=true;m.cardSuit=nil;m.cardRank=rank;m.kingdom="NHÂN LOẠI"
        m.creatureCard=nil;m.enemyAbility=nil;m.creatureKind=nil
        m.artKey="human_"..rank;m.name=E.humanNames[rank-1]
        m.title="LỤC ĐỊA CON NGƯỜI • CẤP "..E.rankName(rank).." • VÔ CHẤT"
        m.desc=m.bossData and m.bossData.desc or "Đoàn thám hiểm độc lập của nhân loại. Lá bài vô chất, không thuộc bốn vương quốc."
        m.color=region.color;return m
    end
    m.human=true; m.cardSuit=kingdom.suit; m.cardRank=rank; m.kingdom=kingdom.name
    m.neutralHuman=nil;m.artKey=nil;m.creatureCard=nil;m.enemyAbility=nil;m.creatureKind=nil
    local role=m.isBoss and "Thủ lĩnh" or m.isElite and "Đội trưởng" or "Nhà thám hiểm"
    m.name=region.id=="voyage" and m.isBoss and (E.shipBoss(m.stage).name.." · "..kingdom.name)
        or (role.." "..kingdom.name.." · "..E.rankName(rank))
    m.title=region.name.." · CẤP "..E.rankName(rank)
    m.desc=m.bossData and m.bossData.desc or "Đối thủ thuộc đoàn thám hiểm "..kingdom.name.."."
    m.color=kingdom.color
    return m
end
return E
