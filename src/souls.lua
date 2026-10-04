local Equipment = require("src.equipment")
local CardEffects = require("src.card_effects")
local Souls = {}

function Souls.value(card)
    local equipment = 0
    for _, eq in ipairs(card.equipments or {}) do
        equipment = equipment + (tonumber((Equipment.ITEMS[eq.id] or eq).cost) or 0)
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

return Souls
