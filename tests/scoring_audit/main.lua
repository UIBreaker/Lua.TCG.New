-- Run gameplay regressions in the same LuaJIT runtime as the game.
function love.load(args)
    local suites = #args > 0 and args or {
        "tests.scoring_runtime_smoke",
        "tests.soul_market_smoke", "tests.equipment_sockets_smoke", "tests.spn_snapshot_smoke",
        "tests.equipment_tiers_smoke", "tests.equipment_feedback_smoke",
        "tests.soul_relics_smoke", "tests.chest_depth_smoke", "tests.chest_expansion_smoke",
        "tests.spn_tactics_smoke", "tests.spn_combat_smoke", "tests.spn_anomalies_smoke",
        "tests.spn_convergence_smoke", "tests.spn_velocity_smoke",
        "tests.continental52_smoke", "tests.editions_smoke", "tests.scoring_presentation_smoke",
    }
    local failed = 0
    for _, name in ipairs(suites) do
        local ok, err = pcall(require, name)
        if not ok then failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
    end
    print("Scoring audit: " .. #suites .. " suites, " .. failed .. " failures")
    os.exit(failed == 0 and 0 or 1)
end
