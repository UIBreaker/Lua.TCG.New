# Generated Top HUD Assets

These files were generated from scratch for the game's top HUD; they do not reuse the earlier UI asset sets.

- `top_hud_frame_v1.png` — transparent frame sprite, 2126×740. The visible strip is in source rect `(10, 308, 2105, 121)`; its wells read left-to-right as stage, health, coin, turn, discard, battle, deck, options.
- `top_hud_icons_atlas_v1.png` — transparent 4×2 atlas, 1774×887. Cells are 443.5×443.5 px; row 1: heart, coin, cards, discard; row 2: crossed swords, deck, options. The final cell is intentionally empty.

The runtime metadata and icon `Quad`s are defined in `ui/components/top_hud.lua`. Dynamic labels and the HP fill are drawn separately. The HUD prefers Georgia Bold from the Windows font set and falls back to the bundled Arial font if Georgia is unavailable.
