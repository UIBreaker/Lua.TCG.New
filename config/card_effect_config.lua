local config = {
    transitionSpeed = 14,
    scoreStateDuration = 0.34,
    scorePulseDuration = 0.20,
    selectPulseDuration = 0.16,
    tiltShear = 0.018,
    tiltVerticalScale = 0.72,
    debugToggleKey = "f7",
    rollOrder = { "foil", "holographic", "polychrome" },
    catalogOrder = { "foil", "holographic", "polychrome", "gilded", "echo", "ancient", "void", "astral", "resonant" },
    effects = {
        foil = {
            shader = "shaders/card_foil.glsl",
            idleStrength = 0.36,
            hoverStrength = 0.88,
            selectedStrength = 1.08,
            scoringStrength = 1.32,
            speed = 0.86,
            shopChance = 0.075,
            shopLabel = "FOIL — KIM QUANG",
            shopText = "Khi lá này tính điểm: +20 SÁT THƯƠNG.",
            score = { damage = 20, chips = 0, mult = 0, auraMultiplier = 1 },
            beamColor = { 0.70, 0.86, 1.0 },
        },
        holographic = {
            shader = "shaders/card_holographic.glsl",
            idleStrength = 0.32,
            hoverStrength = 0.92,
            selectedStrength = 1.10,
            scoringStrength = 1.35,
            speed = 0.62,
            shopChance = 0.035,
            shopLabel = "HOLOGRAPHIC — HUYỄN QUANG",
            shopText = "Khi lá này tính điểm: +10 CƯỜNG HÓA trong tay bài hiện tại.",
            score = { chips = 0, mult = 10, auraMultiplier = 1 },
            beamColor = { 0.72, 0.50, 1.0 },
        },
        polychrome = {
            shader = "shaders/card_polychrome.glsl",
            idleStrength = 0.38,
            hoverStrength = 0.78,
            selectedStrength = 0.98,
            scoringStrength = 1.20,
            speed = 0.40,
            shopChance = 0.01,
            shopLabel = "POLYCHROME — ĐA SẮC",
            shopText = "AURA do chính lá này đóng góp ×1.5.",
            score = { chips = 0, mult = 0, auraMultiplier = 1.5 },
            beamColor = { 1.0, 0.56, 0.86 },
        },
    },
}
-- Each edition owns a different material/motion shader; interaction timing stays shared.
for _, entry in ipairs({
    {"gilded", "KIM ẤN", "Nếu lá vẫn còn trên tay khi kết thúc lượt: +3 Vàng.", "foil", {1,.76,.3}},
    {"echo", "VỌNG ẢNH", "Lần đầu tính điểm mỗi tay: kích hoạt 2 lần, mỗi lần 100% hiệu lực.", "holographic", {.4,.8,1}},
    {"ancient", "CỔ ĐẠI", "Mọi chỉ số nhận từ Tiến Hóa mạnh hơn 200%.", "foil", {.66,.68,.4}},
    {"void", "HƯ KHÔNG", "Khi tiêu hủy: khả năng kích hoạt thêm 10 lần trước khi biến mất.", "holographic", {.55,.25,.9}},
    {"astral", "TINH TÚ", "Khi xét tổ hợp: có thể là bất kỳ Chất nào đang thiếu. Bậc không đổi.", "holographic", {.5,.8,1}},
    {"resonant", "CỘNG HƯỞNG", "Khi nằm trên tay: hai lá sát bên nhận +20% hiệu quả khả năng.", "foil", {.3,.9,1}},
}) do
    local definition = {}
    for key, value in pairs(config.effects[entry[4]]) do definition[key] = value end
    definition.shader = "shaders/card_" .. entry[1] .. ".glsl"
    definition.idleStrength = 0.42
    definition.speed = ({gilded=.35,echo=.65,ancient=.28,void=.48,astral=.32,resonant=.72})[entry[1]]
    definition.shopChance = 0
    definition.shopLabel = string.upper(entry[1]) .. " — " .. entry[2]
    definition.shopText, definition.beamColor, definition.score = entry[3], entry[5], nil
    config.effects[entry[1]] = definition
end
return config
