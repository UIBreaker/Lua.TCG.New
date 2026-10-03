# TERRA SUIT — HD-2D asset requirements

Official direction: **Cinematic Dark-Fantasy HD-2D Card Roguelike**.
High-resolution original artwork; navy/black, antique gold, cool shadows, warm
practical lights. No pixel-art conversion or copying third-party game assets,
shaders, interfaces or compositions.

## Assets that actually exist

- `assets/scene/shrine_lowpoly.png`: currently the battle base painting and the
  temporary shop/reward/other scene environment. It is ONE flattened image.
- `assets/scene/menu_world_v2.png` and `menu_background.ogv`: menu painting/video.
- `assets/scene/enemy_small_lowpoly.png`, `enemy_elite_lowpoly.png`,
  `enemy_boss_lowpoly.png`: existing boss/enemy artwork kept intact.
- `assets/scene/treasure_chest.png`: existing reward chest.
- Existing card, SPN, item, pack, frame and button artwork remains unchanged.

The world now also has separately drawn procedural architecture, arena rings,
near stone fragments, mist, capped particles, radial lights and shop pedestals.
These are real render layers, but **not** a substitute for separated painted
environment assets. No runtime references pretend the following files exist.

## Required production art — all paths below are planned, currently missing

| Planned directory | Files required | Purpose |
|---|---|---|
| `assets/scene/hd2d/battle_ruins/` | `sky.png`, `mountains.png`, `shrine.png`, `arena.png`, `foreground_stones.png`, `fog_mask.png` | Replace the single painting with genuine skyline, architecture, ground and near occluders. |
| `assets/scene/hd2d/shop_vault/` | `ceiling.png`, `rear_arches.png`, `display_bays.png`, `floor.png`, `foreground_drapery.png`, `lamp_emissive.png` | Give the shop its own merchant vault. Present code uses shrine + procedural pedestals. |
| `assets/scene/hd2d/reward_altar/` | `rear_shrine.png`, `columns.png`, `dais.png`, `foreground_candles.png`, `rune_emissive.png` | Dedicated ceremony staging; shrine and live gold lighting are temporary. |
| `assets/scene/hd2d/menu/` | `sky.png`, `landscape.png`, `ruins.png`, `foreground_branches.png` | The existing menu movie already animates, but its baked world cannot parallax independently. Logo stays sharp. |
| `assets/scene/hd2d/archive/` | `rear_library.png`, `shelves.png`, `display_table.png`, `foreground_arch.png` | Collection, deck detail and socketing archive. Shared world / translucent UI is current fallback. |

For **ICE, FOREST, DESERT, VOID, VOLCANIC, MYSTIC**, each planned directory
`assets/scene/hd2d/<preset_lowercase>/` needs:
`sky.png`, `far_environment.png`, `midground.png`, `arena.png`,
`foreground.png`, `emissive.png`. RUINS uses `battle_ruins/` above.
Current presets alter tint/fog/particle/light/grade/motion, not the geography
inside the painting. Boss IDs can choose presets without modifying combat data.

## Delivery constraints and integration

- 1920x1080 reference composition; base/far layers should overscan by 3–5%.
  Runtime uses aspect-preserving cover, never nonuniform stretching.
- PNG alpha for all cut-out layers. Keep matching camera horizon, arena contact
  line near logical y=414, focal target x=630. HUD edges must remain quiet.
- Far backgrounds gently soft; boss/card focal areas sharp. Near fragments may
  have an artist-authored soft edge. Foreground procedural geometry currently
  remains sharp; texture DOF takes effect once real foreground art is supplied.
- Remove the enemy from painted backgrounds. Keep practical emissive masks
  separate from the painted lighting, so event lighting can visibly respond.
- Avoid baked UI/text. Respect the fixed logical safe areas in `ui/layout.lua`.
- Layer definitions live in `config/scene_definitions.lua`: `id`, `texture`,
  `kind` (procedural fallback), `stage`, `depth`, `parallaxFactor`, `offset`,
  `scale`, `blurAmount`, `brightness`, `tint`. Use a scene-specific `layers`
  array when adding these files. Textures are loaded once, only if present;
  an absent texture draws its procedural/base fallback.
- Supply original high-resolution boss poses later for stronger attack staging.
  Current integration uses the supplied static sprites, breathing, contact
  shadow, ambient tint and rim response. It does not add skeletal animation.

## Honest completion boundary

The reusable presentation/render migration can run with current assets. Final
art quality depends on these separated world paintings, especially the shop,
reward altar and menu. Color grading seven presets does not create seven painted
biomes. No 60 FPS guarantee is made for unspecified target hardware; see measured
local frame intervals in `docs/hd2d/performance.md`.
