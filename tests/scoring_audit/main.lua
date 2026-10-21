-- Run gameplay regressions in the same LuaJIT runtime as the game.
function love.load(args)
    local suites = #args > 0 and args or {
        "tests.scoring_runtime_smoke", "tests.preview_memory_smoke", "tests.spn_enchantments_smoke", "tests.spectral_persistence_smoke",
        "tests.soul_market_smoke", "tests.equipment_sockets_smoke", "tests.spn_snapshot_smoke",
        "tests.equipment_tiers_smoke", "tests.equipment_feedback_smoke",
        "tests.soul_relics_smoke", "tests.chest_depth_smoke", "tests.chest_expansion_smoke",
        "tests.spn_tactics_smoke", "tests.spn_combat_smoke", "tests.spn_anomalies_smoke",
        "tests.spn_convergence_smoke", "tests.spn_velocity_smoke", "tests.spn_provisions_smoke", "tests.spn_discard_smoke", "tests.spn_souls_smoke", "tests.spn_legacy_smoke", "tests.spn_twin_fang_smoke", "tests.spn_mimic_smoke", "tests.spn_basics_smoke", "tests.spn_turns_smoke",
        "tests.continental52_smoke", "tests.editions_smoke", "tests.scoring_presentation_smoke",
        "tests.spn_pacts_smoke",
        "tests.spn_vitality_smoke",
        "tests.spn_discard_forge_smoke",
        "tests.spn_foundations_smoke",
        "tests.spn_growth_smoke",
        "tests.spn_bounty_smoke",
        "tests.spn_alchemy_smoke",
        "tests.spn_elements_smoke",
        "tests.spn_predators_smoke",
        "tests.spn_reserves_smoke",
        "tests.spn_formations_smoke",
        "tests.spn_aura_smoke",
        "tests.spn_trials_smoke",
    }
    local failed = 0
    for _, name in ipairs(suites) do
        local ok, err = pcall(require, name)
        if not ok then failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
    end
    print("Scoring audit: " .. #suites .. " suites, " .. failed .. " failures")
    os.exit(failed == 0 and 0 or 1)
end
