# Expedition journey

Campaign stages 1–20 each contain three mandatory encounters: opponent, elite and leader. Completing stage 20 awards a travel permit and opens the victory screen. Boarding continues the same deck and inventory in endless mode at stage 21. Stages 21–40 take place on the expedition ship; stage 41 onward uses the rocky mysterious coast and monster artwork.

Human opponents use the existing playing-card portraits of Valoria, Aurelia, Elaris and Vharos. Campaign ranks are 2–K; ship opponents are 8–K and leaders are K. Eight ship leaders reuse the existing passive hooks and have separate active abilities with a two-hand cycle. Shared boss definitions are never modified by a ship variant.

Round skipping is disabled in both the primary run and legacy map APIs, the buttons are removed, and skip pacts no longer appear in the collection. Skipping a pack or socket reward remains a separate action. Older saves regenerate the new encounters and preserve deck/inventory; the former eight-stage victory resumes the campaign at stage 9.

## Backgrounds

Created with the built-in imagegen tool. Final assets:

- `assets/scene/expedition_human.png`: medieval expedition guild courtyard, four kingdom banners, distant city and harbor, amber afternoon light and teal shadows.
- `assets/scene/expedition_ship.png`: grand wooden expedition ship deck, rigging, furled sails, four rival kingdom banners, cold dusk ocean and amber lanterns.
- `assets/scene/expedition_coast.png`: mysterious basalt shore, jagged submerged reefs, teal surf, misty ancient ruins and a distant expedition ship.

All prompts requested a wide 16:9 dark fantasy painterly game environment, no people, cards, text or UI, a clear central enemy area and a calm lower quarter for playing cards. Authored outdoor scenes omit the old shrine columns and arches.

## Enemy formations and creature cards

Enemy portraits are now 128 × 192 logical pixels. Ordinary encounters cycle between one, two and three opponents; elite encounters have two or three, and leaders remain solo. Every opponent has its own HP, speed and selectable card. Damage targets the selected opponent, enemy attacks resolve once in speed order, and rewards require the entire formation to be defeated. The original encounter HP and attack budgets are divided between formation members.

Creature artwork is composed into ivory playing cards with standard suit symbols, two rank corners, a painted backdrop and a gold frame for J/Q/K. `assets/scene/enemy_cards/` contains 57 exported PNGs: six ordinary creature portraits at 2/K and fifteen boss portraits at J/Q/K. Other ranks from 2–K are composed at runtime as progression increases their strength. Original sprite assets remain the illustration source.

Six creature traits operate in combat: goblins steal gold, golems absorb damage with renewing stone armor, wraiths drain health, wolves gain attack from living allies, scorpions inflict decaying poison, and skeletons revive once per fight. Existing boss passive and active skills remain attached alongside their creature trait.

The revised card frame uses full-width paintings, narrow engraved gold borders, mirrored angled parchment index ribbons and small corner ornaments. Card surfaces retain their original paper and suit colors instead of inheriting the world-entity ambient tint. All 57 PNGs were regenerated from the shared runtime composer.

## Verification results

- `lua tests/expedition_smoke.lua`: sixty campaign victories, no skip/advance without victory, permit, boundaries 20/21/40/41, card asset paths, RNG-neutral previews, ship skills and save migration.
- `lua tests/gameplay_expansion_smoke.lua`: 52 card abilities, ten combo chains and 22 boss passives/actives.
- `lua tests/enemy_art_smoke.lua`, `lua test_poker.lua`: asset selection and poker regression.
- `lovec.exe . --test-features`: all six advanced checks pass.
- `lua tests/enemy_group_smoke.lua`: 240 encounters, formation budgets, targeting, victory, speed order, six traits, ranks and save safety.
- `lovec.exe . --test-enemy-groups`: actual target clicks and scored hands against three humans and three creatures, partial kills, skeleton resurrection, reward exactly once and export of 57 creature cards.
- `lovec.exe . --test-expedition`: real rendering and fight-button input at stages 1, 20, 21, 40, 41 and 42; travel-permit screen and boarding input. PNG captures are stored here.
- `lovec.exe . --test`: passes through check 99, then stops at the pre-existing English spirit-name expectation in check 100 (`The Rock` versus current `Cổ Thạch`). See `system.log`.

The existing exponential HP progression is retained. Long-run balance has not been established by automated progression checks.
