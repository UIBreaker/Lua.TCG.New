local Equipment = require("src.equipment")
local CardEffects = require("src.card_effects")
local Souls = {}

function Souls.value(card)
    local equipment = 0
    for _, eq in ipairs(card.equipments or {}) do
        local definition=Equipment.ITEMS[eq.id] or eq
        -- Gold commissioning prices must not inflate the separate soul economy.
        equipment = equipment + (tonumber(definition.legacyCost or definition.cost) or 0)
    end
    local evolution = math.max(0, math.floor(tonumber(card.evolutionLevel) or 0)) * 4
    local edition = ({foil=3,holographic=6,polychrome=10,negative=12})[CardEffects.getEffectName(card) or card.edition] or 0
    return 1 + equipment + evolution + edition, equipment, evolution, edition
end

-- Combat copies share the persistent card's ID: only one payout per lost card.
function Souls.award(game, card)
    if not game or not card then return 0 end
    game.soulDestroyedIds = game.soulDestroyedIds or {}
    local key = card.rank and card.id and tostring(card.id)
    if card.soulAwarded or key and game.soulDestroyedIds[key] then return 0 end
    local amount = Souls.value(card)
    if key then game.soulDestroyedIds[key] = true end
    card.soulAwarded = true
    game.souls = (game.souls or 0) + amount
    return amount
end

-- Each enemy keeps its receipt so squad kills cannot pay twice.
function Souls.awardKills(game, victory)
    local added, total = 0, 0
    for _, enemy in ipairs(require("src.enemy_group").members(game)) do
        if victory or (enemy.hp or 1) <= 0 then
            if not enemy.soulKillAwarded then
                enemy.soulKillAwarded = enemy.isBoss and 4 or 1
                added = added + enemy.soulKillAwarded
            end
            total = total + enemy.soulKillAwarded
        end
    end
    game.souls = (game.souls or 0) + added
    return added, total
end

return Souls
