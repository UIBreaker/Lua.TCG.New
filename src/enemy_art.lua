-- Presentation-only asset selection. Boss data can change after monster creation.
local Art = { images = {} }
Art.normal = { "forest_goblin", "lava_golem", "swamp_wraith", "frost_wolf", "desert_scorpion", "ancient_skeleton" }
Art.bosses = {
    "lock_royals", "black_tax_collector", "the_water", "memory_eater", "the_arm",
    "gatekeeper", "the_hook", "max_3_cards", "the_needle", "the_fish",
    "echo_knight", "taxman", "gem_devourer", "executioner", "faceless",
}
function Art.key(monster)
    if not monster then return nil end
    if monster.isBoss then
        local data = monster.bossData or {}
        return data.debuffId or data.id
    end
    if not monster.isElite then
        return Art.normal[((monster.round or monster.encounterCount or 1) - 1) % #Art.normal + 1]
    end
end
function Art.path(key) return "assets/scene/enemies/" .. key .. ".png" end
function Art.load()
    for _, list in ipairs({ Art.normal, Art.bosses }) do
        for _, key in ipairs(list) do
            local path = Art.path(key)
            if love.filesystem.getInfo(path) then
                local ok, image = pcall(love.graphics.newImage, path)
                if ok then image:setFilter("linear", "linear"); Art.images[key] = image end
            end
        end
    end
end
function Art.image(monster, fallback)
    return Art.images[Art.key(monster)] or
        (monster.isBoss and fallback.enemyBoss or monster.isElite and fallback.enemyElite or fallback.enemySmall)
end
return Art
