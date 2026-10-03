# Reward ceremony

## Files and transaction

- `src/reward_system.lua`: keeps the existing guaranteed gold calculation; rolls, validates and grants bonus loot once; animates and renders saved results; hands free packs to Shop.
- `config/reward_loot.lua`: definitions, drop weights, boss overrides, gold fallback, rarity colors, timing, coin limit and optional pity.
- `main.lua`: victory/skip/debug cash-out entry, immediate save, resume, input, free pack queue and durable ITM socket hand-off.
- `src/persistence.lua`: resumes CASH_OUT, queued packs and reward socketing; restores queued playing-card identities.
- `src/sound.lua`: reward events reuse existing synthesized samples with individual gain/cooldown.
- `capture_screens.lua`, `tests/reward_ceremony_smoke.lua`, `tests/reward_ceremony_capture.lua`: verification and isolated runtime capture.

`calculate()` retains base reward, remaining hands, interest (including Gilded uncapped interest), cached SPN rewards and Valoria's rounding. `begin()` commits those values plus bonus loot before animation and sets `game.pendingVictoryReward`. Repeated entry returns the same result without granting again. `newAnimation()` and `update()` only present it. Vàng bonus is separate from guaranteed gold and does not retroactively affect interest or Valoria.

The result contains `breakdown`, `loot`, `bonusGold`, `earnedGold`, `tableId`, `claimed`. Each loot definition has `type`, `id`, `rarity`, `amount`, `source` and optional metadata/card/pack opening/children. Playing cards use `Deck.addCardToDeck`; consumables use the current three slots. Full/invalid rewards convert to $2, visibly labeled VÀNG BÙ with the reason in the tooltip. SPN packs are checked again on opening because earlier packs may fill the last slot.

Pack contents are rolled through `Shop.openPack()` at victory and stored in `game.rewardPacks`. Continue opens that queue through the existing choice/keep/skip UI. These packs cost zero. A successful choice or explicit skip removes one queue entry and saves. ITM keeps its queue entry and `pendingRewardEquipment` until equipment is attached or explicitly skipped. Load restores the same candidates and SPN callbacks from the catalog. Animation uses a private deterministic visual generator, never `src.rng`.

## Starting weights (playtest balance)

| Loot | Normal | Boss |
| --- | ---: | ---: |
| Bonus gold ($1–3) | 40 | 20 |
| Playing card | 25 | 15 |
| Card Pack / standard | 15 | 20 |
| Consumable (single/team speed) | 10 | 0 |
| SPN Pack / buffoon | 5 | 15 |
| ITM Pack / arcana | 4 | 15 |
| Silver chest | 1 | 12 |
| Golden chest | 0 | 3 |

Normal enemies roll once; bosses roll one or two times, so these are **per-roll** weights rather than the chance of any drop across the whole battle. Every weighted roll chooses exactly one entry. Skipped blinds keep guaranteed rewards and receive no victory loot.

Silver chest: two rolls, gold 40 / playing card 30 / Card Pack 20 / consumable 10. Golden chest: two rolls, SPN Pack 35 / ITM Pack 35 / evolution consumable 20 / celestial consumable pack 10. Chest tables avoid recursive chests; the generator additionally limits nesting depth.

Boss overrides use actual boss IDs:

- `black_tax_collector` → `tax`: two rolls, gold 65 / Card Pack 25 / silver chest 10.
- `memory_eater` → `memory`: one or two rolls, playing card 40 / evolution 20 / Card Pack 30 / silver chest 10.
- `gatekeeper` → `gate`: one or two rolls, Card Pack 35 / SPN Pack 25 / ITM Pack 25 / silver chest 15.

A blind or boss can set `lootTableId`. `begin(breakdown, game, context)` also accepts `context.lootTableId` and `context.weightModifier(entry)` for explicit performance/condition rules; none are enabled by default. Pity is disabled by default. Its saved `rewardPackDrought` counter can increase pack weights after six victories when enabled in config.

## Presentation

The victory panel uses a framed charcoal-and-gold layout: itemized income at left, a large coin and earned amount at right, and the wallet before/after directly underneath. Currency uses coin icons and explicit XU VÀNG labels. Loot cards retain image aspect ratios and separate rarity, name and claimed status. The footer provides a gold continue button and context-sensitive keyboard instructions.

`ENTER → GOLD_BREAKDOWN → COIN_RAIN → GOLD_SETTLE → LOOT_PREPARE → LOOT_REVEAL / RARE_REVEAL → SUMMARY → EXIT`

Reward rows spawn `reward_coin` sprites with upward impulse, rotation, gravity, one bounce, then attraction to the gold counter. Each collected coin carries an integer batch of gold; the received total and wallet increase only on collection. Small collection pulses and a final 1.16 pulse settle the gold. At most 40 visual coins are budgeted across the whole ceremony, independent of currency size. Fixed physics steps keep slow frames from skipping collection.

Loot is revealed in sequence, with card backs, a short flip, rarity borders and flares. Rare+ adds 0.24 seconds of anticipation. Chest art reuses `assets/scene/treasure_chest.png`: drop, dust, lock shake, opening audio/light burst, then contents rise into their own slots. There is no separate open-lid sprite in the asset set; the chest uses the existing closed artwork with an opening flare rather than a fabricated asset. Details and the gold explanation appear only on hover. Interest has a green tint and an accurate cap tooltip.

Click, Space or Enter completes the current ceremony; a subsequent action continues. This changes no transaction state or RNG. The existing Fast Scoring setting doubles ceremony speed. Pack choice/skip behavior remains the current Shop behavior.

Audio hooks: `reward_coin_spawn`, `reward_coin_land`, `reward_coin_collect`, `reward_gold_total`, `reward_loot_reveal`, `reward_rare_reveal`, `reward_chest_open`. Coin pitches vary within a narrow range; per-event volume and cooldown prevent overlapping pings from becoming noise. Existing global voice limits and volume settings apply.

## Extending and testing

To add a reward, add a definition and a weighted table entry in `config/reward_loot.lua`; new pack rewards need only a supported `packType`. For a genuinely new type, add generation/validation in `createReward`, grant handling in `begin` and presentation in `draw`. Adjust drop weights, gold ranges, rolls, rarity and timings in the same config. Keep rewards committed before reveal.

- `lua tests/reward_ceremony_smoke.lua`: formulas, all reward types, capacity conversion, boss overrides, chest children, exact gold totals, visual RNG isolation, repeated fast-forward, particle budget, save round trips, free pack choices and ITM hand-off.
- `lovec.exe . --test-reward-ceremony`: actual rendering, six slots, coin particles/audio hooks, keyboard continue/fast-forward, free pack choice, socketing and skip. Capture mode does not load/write player saves; screenshots are `shot_reward_*.png`.

Combat/scoring formulas are untouched by this feature. These initial bonus weights still need playtesting across full runs; guaranteed reward economics are preserved, while bonus loot intentionally adds resources.

Verified on this implementation: reward smoke, gameplay expansion smoke (52 abilities / 22 bosses), voucher smoke, scoring presentation smoke, card effects and card physics smoke. Real LÖVE 11.5 reward capture passed, all nine existing pack types passed purchase/skip regression, and the scoring renderer/input/HP/victory lifecycle passed all four cases (mean 5.02 ms per sampled frame during the parallel run). The summary and tooltip screenshots were inspected for clipping and readability.

The older full `test_system.lua` suite was also run in LÖVE: checks through 99 passed, then its spirit-name assertion at line 2868 failed because it expects `The Rock` for `spirit_pebble`, while the unchanged deity catalog supplies `Cổ Thạch`. This unrelated catalog expectation was not modified. Running that suite directly in standalone Lua also lacks the LÖVE font context. An additional existing `spectral_persistence_smoke.lua` attempt under standalone Lua was incompatible with its LuaJIT-only `loadstring`/`setfenv` calls; it is not counted as passing.
