# Expedition journey

The journey begins on the human continent. Each stage contains three mandatory encounters: opponent, elite and leader. Stages 1–5, 6–10, 11–15 and 16–20 each have their own authored landscape. Defeating the stage-20 leader awards a single-use travel permit. The destination screen offers the four suit kingdoms and the mysterious continent, or a sale for exactly 1,000 gold to start another human expedition. Subsequent kingdom completions issue another permit; selling one continues in the current region.

Human-continent opponents have twelve dedicated neutral portraits (2–K), runtime rank indices, and no suit. Each kingdom uses only its own existing Continental playing-card suit: Valoria/hearts, Aurelia/diamonds, Elaris/clubs, Vharos/spades. Every kingdom has twenty local stages and four distinct backgrounds. Monster artwork and existing creature traits are used upon direct arrival at the mysterious continent, which remains endless. The former automatic ship route is retained only for compatibility with legacy encounter APIs.

`run.ante` tracks cumulative progression and combat difficulty. `run.regionId` and `run.areaStage` track the current destination and local stage displayed in the HUD. Travel and sales preserve deck, inventory and HP. The permit is consumed atomically before returning to encounter selection; a second click or save/reload cannot repeat the sale. New saves persist route and local stage. Older saves retain cumulative progression and cards; stages 21–40 migrate to another human expedition, and stages 41 onward to the mysterious coast.

Round skipping is disabled in both the primary run and legacy map APIs, the buttons are removed, and skip pacts no longer appear in the collection. Skipping a pack or socket reward remains a separate action. Older saves regenerate the new encounters and preserve deck/inventory; the former eight-stage victory resumes the campaign at stage 9.

## Backgrounds

Created with the built-in imagegen tool. Final assets:

- `assets/scene/journey/`: twenty new 16:9 battlefields, four per human/kingdom region.
- `assets/cards/continental/enemy/human_2.png` through `human_13.png`: twelve new full-bleed neutral human portraits, with all indices and frames drawn by the game.
- `docs/journey_assets.json`: exact prompts, concepts and generator source paths for all 32 new assets. The canonical card manifest includes the twelve portraits; the prompt catalog includes all 32.

The three earlier backgrounds below remain available to legacy scenes:

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
- `lua tests/journey_routing_smoke.lua`: 666 opponent identities across six regions, four-area boundaries, full region campaigns, one-time sales, all destinations, inventory and save migration.
- `lovec.exe . --test-journey-routing`: real fight clicks in twenty regional backgrounds plus the mysterious continent; twelve neutral rank overlays; actual permit sale and destination buttons. Captures use the `route_` prefix.
- `lovec.exe . --test-enemy-groups`: actual target clicks and scored hands against three humans and three creatures, partial kills, skeleton resurrection, reward exactly once and export of 57 creature cards.
- `lovec.exe . --test-expedition`: alias for the updated journey routing capture.
- `lovec.exe . --test`: current run stops in the unrelated legacy SPN scoring expectation at `test_system.lua:1001`, expecting 15 Mult while current `spirit_ember` gives 6. HEAD already defines this SPN as a multiplier instead of the old +4 Mult assumed by that fixture.

The existing exponential HP progression is retained. Long-run balance has not been established by automated progression checks.
