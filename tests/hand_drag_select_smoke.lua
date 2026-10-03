-- lua tests/hand_drag_select_smoke.lua; exercises the actual input handlers without a GPU.
local file = assert(io.open("main.lua", "r"))
local source = file:read("*a"); file:close()
local function section(first, following)
    local start = assert(source:find(first, 1, true))
    return source:sub(start, assert(source:find(following, start + #first, true)) - 1)
end
local limit, held, sounds, shift = 5, false, 0, false
local env = setmetatable({
    love = {keyboard = {isDown = function() return shift end}}, state = "playing", game = {hand = {}, selectedIndices = {}},
    anim = {floatingTexts = {}}, juice = {}, buttons = {},
    shopDrag = {active = false}, deityDrag = {active = false},
    UI = {BATTLE_ARENA_X = 200, BATTLE_ARENA_W = 650, AbilityUI = {}, ScoringFeel = {},
        COLORS = {}, CardPhysics = {
            release = function() held = false end,
            isLabOpen = function() return false end,
            hit = function(_, _, _, fallback) return fallback end,
        }},
    DeathVFX = {enemyActive = function() return false end, busy = function() return false end},
    EnemyFormation = {press = function() return false end},
    Deities = {getMaxSlots = function() return 0 end},
    Deck = require("src.deck"),
    CardEffects = {triggerSelectPulse = function(card) card.pulses = (card.pulses or 0) + 1 end},
    Sound = {play = function() sounds = sounds + 1 end},
    toVirtual = function(x, y) return x / 2, y / 2 end,
    getMaxSelectableCards = function() return limit end,
    getConsumableSlotRect = function() return -1000, -1000, 1, 1 end,
}, {__index = _G})
env.syncCardSelections = function()
    for i, card in ipairs(env.game.hand) do
        card.selected = false
        for _, index in ipairs(env.game.selectedIndices) do
            if index == i then card.selected = true end
        end
    end
end
local code = section("local handDrag = {", "function anim.prepareDrawAnimation")
    .. section("local function toggleCardSelection", "local function beginPlayerDefeat")
    .. section("getHandCardPosition = function", "local function drawBattleHud")
    .. section("local function handlePlayingMousepressed", "local function handleShopMousepressed")
    .. section("function love.focus", "local function updateCaptureMode")
    .. source:sub((assert(source:find("function love.mousemoved", 1, true))))
    .. "\nreturn handDrag, getHandCardPosition, handlePlayingMousepressed"
local chunk
if setfenv then chunk = assert(loadstring(code)); setfenv(chunk, env)
else chunk = assert(load(code, "hand input", "t", env)) end
local drag, position, press = chunk()
local function reset(count, selected)
    env.state, env.isPauseMenuOpen, limit, sounds = "playing", false, 5, 0
    shift, env.anim.floatingTexts = false, {}
    env.game.hand, env.game.selectedIndices = {}, {}
    for i = 1, count do
        local x, y = position(i, count)
        env.game.hand[i] = {visualX = x, visualY = y, selected = false}
    end
    for _, i in ipairs(selected or {}) do table.insert(env.game.selectedIndices, i) end
    env.syncCardSelections()
end
local function point(index)
    local x, y = position(index, #env.game.hand)
    return x + 8, y + 70
end
local function start(index)
    local x, y = point(index)
    held = true
    assert(press(x, y, 1))
    return x, y
end
local function move(x, y) env.love.mousemoved(x * 2, y * 2, 0, 0) end
local function release(x, y) env.love.mousereleased(x * 2, y * 2, 1) end
reset(8)
local x, y = start(1)
assert(env.game.hand[1].selected and not held, "Selection must respond immediately without pickup physics")
move(x + 3, y); release(x + 3, y)
assert(#env.game.selectedIndices == 1 and sounds == 1, "Small jitter stays a click with one sound")
reset(8)
start(1); x, y = point(8); move(x, y)
assert(drag.mode == "select" and not held and #env.game.selectedIndices == 5, "Fast swipe fills the selection limit")
for i = 1, 5 do assert(env.game.hand[i].selected, "Fast swipe skipped a card") end
x, y = point(1); move(x, y); release(x, y)
assert(#env.game.selectedIndices == 5 and sounds == 5, "Revisiting cards must not toggle or spam sounds")
assert(#env.anim.floatingTexts == 1, "Selection limit must be explained once per gesture")
reset(8)
start(1); limit = 8
x, y = point(1); move(x + 2, y + 12)
x, y = point(8); move(x, y + 35); release(x, y + 35)
assert(#env.game.selectedIndices == 8 and drag.mode == "select", "Initial vertical jitter must never steal a selection gesture")
reset(8)
start(1); limit = 8
x, y = point(8); release(x, y)
assert(#env.game.selectedIndices == 8, "Release must sweep the final segment even without a move event")
reset(8)
local left, top = position(1, 8)
assert(press(left - 12, top + 60, 1))
limit = 8; x, y = point(8); move(x, y); release(x, y)
assert(#env.game.selectedIndices == 8, "A gesture starting next to the hand must select entered cards")
reset(8)
local hit = env.UI.CardPhysics.hit
env.UI.CardPhysics.hit = function() return false end
x, y = start(1); release(x, y)
assert(env.game.hand[1].selected, "Stale physics geometry must not reject a valid hand slot")
env.UI.CardPhysics.hit = hit
reset(8, {1})
env.UI.CardPhysics.hit = function(card) return card == env.game.hand[1] end
x, y = point(4); assert(press(x, y, 1)); release(x, y)
assert(#env.game.selectedIndices == 0, "Rendered surface must take priority over an overlapping stable slot")
env.UI.CardPhysics.hit = hit
reset(8, {1, 2, 3, 4, 5})
start(5); x, y = point(1); move(x, y); release(x, y)
assert(#env.game.selectedIndices == 0, "Starting on a selected card paints deselection in reverse")
reset(8)
start(8); limit = 8; x, y = point(1); move(x, y); release(x, y)
assert(#env.game.selectedIndices == 8, "Overlapping cards must work in both directions")
reset(8)
start(1); x, y = point(3); move(x, -100); release(x, -100)
assert(#env.game.selectedIndices == 1, "Leaving the hand must only retain the card selected on press")
reset(8, {1})
local original = env.game.hand[1]
shift = true
x, y = start(1); move(x, y - 30)
assert(drag.mode == "reorder" and held, "Vertical drag must preserve held physics")
x = position(4, #env.game.hand) + 50; move(x, y - 30); release(x, y - 30)
assert(env.game.hand[4] == original and env.game.selectedIndices[1] == 4, "Reordering must preserve card selection")
reset(8)
x, y = start(1); env.isPauseMenuOpen = true; release(x, y)
assert(not drag.active and not held and #env.game.selectedIndices == 1, "Modal release must cancel further selection")
reset(8)
x, y = start(1); env.state = "scoring"; move(x + 100, y); release(x + 100, y)
assert(not drag.active and #env.game.selectedIndices == 1, "Scene changes must cancel further selection")
reset(8)
start(1); env.love.focus(false)
assert(not drag.active and not held, "Focus loss must release the gesture")
print("Hand drag select passed: immediate click, diagonal jitter, fast/reverse swipes, release segment, adjacent start, stale physics, limits, Shift reorder, modal/scene/focus; 2x scaling")
