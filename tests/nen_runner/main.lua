function love.load()
    package.path=love.filesystem.getWorkingDirectory().."/?.lua;"..package.path
    local ok,err=xpcall(function()
        for _,name in ipairs({"nen_vfx_smoke","nen_all_smoke","nen_audio_smoke","advanced_hands_smoke",
            "scoring_presentation_smoke","bed_speed_smoke","continental52_smoke","editions_smoke",
            "scoring_runtime_smoke","spn_snapshot_smoke","spn_convergence_smoke",
            "spectral_persistence_smoke","audio_smoke"}) do require("tests."..name) end
    end,debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
