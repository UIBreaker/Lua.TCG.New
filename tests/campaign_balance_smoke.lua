local Run=require("src.run_manager")
assert(Run.calculateBlindHp(1,"small")==50)
assert(Run.calculateBlindHp(1,"big")==100 and Run.calculateBlindHp(1,"boss")==150)
assert(Run.calculateBlindHp(2,"small")==75)
local previous=0
for stage=1,40 do
    local hp=Run.calculateBlindHp(stage,"small")
    assert(hp>previous)
    if stage>1 then
        local growth=stage<=5 and 1.50 or stage<=20 and 1.45 or 1.50
        assert(hp==math.floor(previous*growth+.5),"the campaign curve must keep its rounded stage recurrence")
    end
    previous=hp
    assert(Run.calculateBlindHp(stage,"big")==hp*2 and Run.calculateBlindHp(stage,"boss")==hp*3)
    for index,kind in ipairs({"small","big","boss"}) do
        assert(require("src.monster").getHpByEncounter((stage-1)*3+index)==Run.calculateBlindHp(stage,kind))
    end
end
for _,name in ipairs({"human_bosses_smoke","enemy_loadouts_smoke","combat_tactics_smoke",
    "enemy_support_limits_smoke","enemy_group_smoke","enemy_attack_presentation_smoke",
    "blood_difficulty_smoke","run_resume_smoke"}) do require("tests."..name) end
print("Campaign balance passed: 50/100/150 opening, shared encounter/stage growth, tier gates, playable judge patterns, gear/HP scaling, finite fights, blood-domain anchors and save/load")
return true
