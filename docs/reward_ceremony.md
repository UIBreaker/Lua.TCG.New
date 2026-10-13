# Reward ceremony

## One-click conversion on the ceremony

`QUY ĐỔI NHANH TẤT CẢ +N` sits beside the shop button. One click settles the presentation and converts all available loot from this victory across every page: queued packs, direct playing cards and consumables. It stays on CASH_OUT with updated gold and `ĐÃ ĐỔI +N` receipts, then Continue enters the shop without reopening converted packs. A disabled receipt replaces the conversion action after use.

`RewardSystem.exchangeAll` matches per-victory receipt tokens on granted cards/consumables and queued openings, so older owned inventory is preserved even when it has the same item ID. Older pending saves without tokens match their appended rewards by card ID or pack candidates. Chest containers have no extra payout; only their actual contents are valued. Existing gold and souls stay unchanged apart from the exchange credit. Pack values use `Shop.getPackExchangeGold`, direct cards/consumables use `Shop.getChestExchangeGold` for one item. `result.exchangeGold` and `bulkExchanged` persist the receipt; restored ceremonies immediately display the settled total.

`tests/reward_bulk_exchange_smoke.lua` checks owned inventory, current/legacy save round trips, missing grants, all reward types, nested chests and repeated conversion. The LÖVE ceremony capture clicks from the second loot page, double-clicks, checks that all eight packs are removed, enters shop, and converts two direct cards with one click during the reveal. Screenshot: `shot_reward_bulk_exchanged.png`.

## Declining an opened chest

Opened packs show `QUY ĐỔI RA VÀNG +N` in place of the old skip label. The same action appears on legacy treasure/boss choice screens after their reveal. Choosing conversion declines the entire set of alternatives; selecting or keeping a candidate continues to grant only that candidate.

`Shop.getPackExchangeGold` returns half the paid pack price, rounded down with a minimum of 1. A free victory pack uses the matching catalog price instead of its zero purchase price. `Shop.getChestExchangeGold` uses half the highest single candidate price (playing cards default to 4), not the sum of mutually exclusive alternatives. `Shop.skipPack(shop, game)` credits that gold and stores `opening.exchangedGold`; `Shop.exchangeChest` marks the choice list resolved. Both prevent repeated payouts. The main input handler removes converted victory packs from their saved queue and saves the gold immediately. Existing card/equipment claims are unaffected.

Verified by `tests/reward_exchange_smoke.lua` and `--test-pack-skip`: every catalog pack, paid/free/discounted prices, queue/save/reload, repeated clicks, legacy treasure/boss conversion and visible gold labels. Screenshots: `docs/chest_exchange_pack.png`, `docs/chest_exchange_treasure.png`.

## Soul harvest and supplies

Every defeated ordinary enemy grants 1 soul immediately, so a defeated squad of 1/2/3 grants 1/2/3. Each boss grants 4. `Souls.awardKills` marks individual enemies to prevent repeated payouts. The ceremony reports the encounter total through `earnedSouls` and `soulsBefore`, with curved teal wisps converging on a crystal and an animated balance. Skipped encounters grant none; saved CASH_OUT results and fast-forward only replay the presentation.

An independent supply roll happens after the loot rolls: 60% for ordinary encounters and guaranteed for bosses. It adds at most one supply. Its conditional distribution is small health 25%, large health 10%, small armor 20%, large armor 10%, small speed 20%, large speed 10%, destruction card 5%. Overall normal/boss probabilities respectively: small health 15/25%, large health 6/10%, small armor 12/20%, large armor 6/10%, small speed 12/20%, large speed 6/10%, destruction 3/5%.

Supplies reuse `Shop.healingItem` and `Shop.destructionItem`: 15/60 HP, 8/20 armor, +3/+10 permanent attack speed for one chosen hand card, or the existing shop destruction ritual. They use existing Continental art and the shared card frame. A full consumable inventory converts the drop to the existing visibly labeled gold fallback. All chances live in `config/reward_loot.lua`.

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

Normal encounters roll 2–3 times; bosses and all boss override tables roll 3–4 times, plus the separate supply above. These are **per-roll** weights rather than the chance of any drop across the whole battle. Every weighted roll chooses exactly one entry. Skipped blinds keep guaranteed rewards and receive no victory loot.

Boss victories add exactly 10 gold after the original faction/interest calculation, reported separately as `breakdown.bossVictoryBonus` and a dedicated gold-source row. Skipping does not grant it. Existing saved ceremonies keep their stored payout. Gold shop rerolls now start at 2 (then 4, 7, …); the discount voucher lowers the starting price to 1, and free rerolls keep their existing behavior.

The larger 1160×680 ceremony uses a gold treasury, separate teal soul crystal, six readable gold-source rows and larger Continental card art on lit pedestals. It shows up to six loot slots per page. Reveal follows the active page automatically; after completion, the arrow buttons or left/right keyboard keys review all pages without modifying rewards or advancing gameplay RNG.

Silver chest: two rolls, gold 40 / playing card 30 / Card Pack 20 / consumable 10. Golden chest: two rolls, SPN Pack 35 / ITM Pack 35 / evolution consumable 20 / celestial consumable pack 10. Chest tables avoid recursive chests; the generator additionally limits nesting depth.

Boss overrides use actual boss IDs:

- `black_tax_collector` → `tax`: 3–4 rolls, gold 65 / Card Pack 25 / silver chest 10.
- `memory_eater` → `memory`: 3–4 rolls, playing card 40 / evolution 20 / Card Pack 30 / silver chest 10.
- `gatekeeper` → `gate`: 3–4 rolls, Card Pack 35 / SPN Pack 25 / ITM Pack 25 / silver chest 15.

A blind or boss can set `lootTableId`. `begin(breakdown, game, context)` also accepts `context.lootTableId` and `context.weightModifier(entry)` for explicit performance/condition rules; none are enabled by default. Pity is disabled by default. Its saved `rewardPackDrought` counter can increase pack weights after six victories when enabled in config.

## Presentation

The cinematic upgrade adds a moving dust backdrop, broad light shafts, animated victory seal, staged reward rows, depth-scaled coins with spin/shadows and reusable trail points, collection sparks and a gold shock ring. Rare loot gets a local spotlight, expanding ring, star burst and short rarity callout. Chest contents rise from their parent chest toward their slot. Hover lifts and lightly tilts the complete card; packs and consumables use the current Continental loaders and shared card frame. No new bitmap art or card frames are introduced.

Effects use only the private presentation RNG and are capped at 40 coins and 72 sparks. Particle rendering respects `visual_config.effects.particles`. Settings live in `reward_loot.presentation`; the existing sequence timing and fast-forward remain intact. The received number scales down for long values and the encounter title truncates to prevent overlap. The smoke test exercises monotonic totals and effect budgets at 30/60/144 FPS.

The victory panel uses a framed charcoal-and-gold layout: itemized income at left, a large coin and earned amount at right, and the wallet before/after directly underneath. Currency uses coin icons and explicit XU VÀNG labels. Loot cards retain image aspect ratios and separate rarity, name and claimed status. The footer provides a gold continue button and context-sensitive keyboard instructions.

`ENTER → GOLD_BREAKDOWN → COIN_RAIN → GOLD_SETTLE → SOUL_GATHER → LOOT_PREPARE → LOOT_REVEAL / RARE_REVEAL → SUMMARY → EXIT`

Reward rows spawn `reward_coin` sprites with upward impulse, rotation, gravity, one bounce, then attraction to the gold counter. Each collected coin carries an integer batch of gold; the received total and wallet increase only on collection. Small collection pulses and a final 1.16 pulse settle the gold. At most 40 visual coins are budgeted across the whole ceremony, independent of currency size. Fixed physics steps keep slow frames from skipping collection.

Loot is revealed in sequence, with card backs, a short flip, rarity borders and flares. Rare+ adds 0.24 seconds of anticipation. Chest art reuses `assets/scene/treasure_chest.png`: drop, dust, lock shake, opening audio/light burst, then contents rise into their own slots. There is no separate open-lid sprite in the asset set; the chest uses the existing closed artwork with an opening flare rather than a fabricated asset. Details and the gold explanation appear only on hover. Interest has a green tint and an accurate cap tooltip.

Click, Space or Enter completes the current ceremony; a subsequent action continues. This changes no transaction state or RNG. The existing Fast Scoring setting doubles ceremony speed. Pack choice/skip behavior remains the current Shop behavior.

Audio hooks: `reward_coin_spawn`, `reward_coin_land`, `reward_coin_collect`, `reward_gold_total`, `reward_loot_reveal`, `reward_rare_reveal`, `reward_chest_open`. Coin pitches vary within a narrow range; per-event volume and cooldown prevent overlapping pings from becoming noise. Existing global voice limits and volume settings apply.

## Extending and testing

To add a reward, add a definition and a weighted table entry in `config/reward_loot.lua`; new pack rewards need only a supported `packType`. For a genuinely new type, add generation/validation in `createReward`, grant handling in `begin` and presentation in `draw`. Adjust drop weights, gold ranges, rolls, rarity and timings in the same config. Keep rewards committed before reveal.

- `lua tests/reward_ceremony_smoke.lua`: formulas, all reward types, capacity conversion, boss overrides, chest children, exact gold totals, visual RNG isolation, repeated fast-forward, particle budget, save round trips, free pack choices and ITM hand-off.
- `lovec.exe . --test-reward-ceremony`: actual rendering of six income rows, boss +10 gold and 4 souls, seven supply artworks, 12 loot slots across two pages, mouse/keyboard paging, coin particles/audio hooks, continue/fast-forward, free pack choice, socketing and skip. Capture mode does not load/write player saves; screenshots are `shot_reward_*.png`, including `shot_reward_boss_grand.png` and `shot_reward_boss_page2.png`.

Combat/scoring formulas are untouched by this feature. Reward balance still needs playtesting across full runs: bosses now pay 10 more guaranteed gold, and multiple loot rolls intentionally add resources.

Verified on this implementation: reward smoke, gameplay expansion smoke (52 abilities / 22 bosses), voucher smoke, scoring presentation smoke, card effects and card physics smoke. Real LÖVE 11.5 reward capture passed, all nine existing pack types passed purchase/skip regression, and the scoring renderer/input/HP/victory lifecycle passed all four cases (mean 5.02 ms per sampled frame during the parallel run). The summary and tooltip screenshots were inspected for clipping and readability.

The older full `test_system.lua` suite was also run in LÖVE: checks through 99 passed, then its spirit-name assertion at line 2868 failed because it expects `The Rock` for `spirit_pebble`, while the unchanged deity catalog supplies `Cổ Thạch`. This unrelated catalog expectation was not modified. Running that suite directly in standalone Lua also lacks the LÖVE font context. An additional existing `spectral_persistence_smoke.lua` attempt under standalone Lua was incompatible with its LuaJIT-only `loadstring`/`setfenv` calls; it is not counted as passing.
