return {
    background="assets/scene/events/the_void_space.png",price=100,ticketPrice=10,
    entryChance=.10,ticketChance=.01,bossTicketAmount={1,100},
    -- Integer weights out of 100,000. Every pull uses the same table; no pity.
    rates={
        {id="featured_spn",label="Banner SPN UQ ×5",weight=2},
        {id="featured_equipment",label="Banner trang bị ×10",weight=1},
        {id="featured_card",label="Banner quân bài ×10",weight=1},
        {id="gold",label="Vàng lẻ · 1–10",weight=37000},
        {id="souls",label="Linh hồn · 1–5",weight=20000},
        {id="consumable",label="Tiêu hao · Thuốc · Thẻ phép",weight=18000},
        {id="equipment",label="Trang bị toàn danh mục",weight=10000},
        {id="card",label="Một trong 52 quân bài",weight=8000},
        {id="spn",label="SPN ngẫu nhiên · C–TT",weight=3000},
        {id="pack",label="Rương toàn danh mục",weight=2000},
        {id="voucher",label="Đặc quyền",weight=496},
        {id="hand",label="Mở rộng tay bài +1",weight=500},
        {id="ticket",label="Vé The Void · 1–100",weight=1000},
    },
    strengths={common=1,uncommon=2,rare=3,epic=4,legendary=5,mythic=6,transcendent=7,unique=8,eternal=9,supreme=10},
    colors={{.62,.72,.83},{.28,.86,.52},{.28,.68,1},{.76,.38,1},{1,.76,.25},{1,.3,.43},{.35,1,1},{.94,.68,1},{.46,.95,.77},{1,.85,.43}},
    bannerColor={1,.9,.6},
}
