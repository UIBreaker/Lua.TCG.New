# TERRA SUIT - Cinematic Dark-Fantasy HD-2D Card Roguelike

## Audit before implementation

main.lua owned state routing and a 1920x1080 main Canvas with 1280x720 logical
coordinates. Boss, cards and HUD shared that target; CRT and impact distortion
therefore touched UI. Battle and shop redrew the same flat background. Other
scenes covered it with opaque rectangles. There was no reusable world camera.
Existing scoring staging/audio, card materials/physics, shop focus/buy/sell/flip,
reward coins/loot and component theme are reused. No second scene manager.
Graphify supplied module relationships; old graph line locations were checked
against current source. No combat, ability, economy or save schema rewrite.

## Architecture and render pipeline

mainCanvas remains the sharp UI/output target. Renderer temporarily binds the
reused World Canvas and restores the UI target and graphics state:

base/far painting -> distant arches -> midground columns -> arena -> boss/shop
pedestals -> scoring energy/beam/impact -> mist/particles/foreground -> light
Canvas -> bright extraction -> two reduced blur passes -> ambient/color grade/
vignette/bloom composite -> sharp cards/HUD/modals/labels/tooltips -> crossfade
-> aspect-preserving window presentation.

Card glow uses the existing material shaders after world postprocessing. Scoring
light illuminates the environment. LÖVE video retains its native YCbCr decoder;
image DOF is bypassed for video. Optional CRT scanlines affect world pixels only.

## Files created

| File | Responsibility |
|---|---|
| config/visual_config.lua | Visual values, per-effect flags, LOW/MEDIUM/HIGH |
| config/scene_definitions.lua | Layers, scene mapping, seven presets, boss overrides |
| render/renderer.lua | World Canvas, composite, transition, F1 views, CPU statistics |
| render/scene.lua | Texture/fallback layers, cover scaling, geometry, fog, particles |
| render/camera.lua | Drift, smoothed focus/zoom/return, decaying kick |
| render/lighting.lua | addPoint / flash / setAmbient and radial practical/event light |
| render/entity.lua | Boss contact shadow, breathing and ambient/rim response |
| render/postprocess.lua | Cached shaders and reduced bloom buffers |
| shaders/world_depth.glsl | Mild nine-tap image-layer depth blur |
| shaders/world_bright.glsl | Soft-knee bright extraction |
| shaders/world_blur.glsl | Separable reduced-resolution blur |
| shaders/world_composite.glsl | Grade, ambient, vignette, bloom, optional scanlines |
| shaders/world_entity.glsl | Boss tint and edge rim response |
| tests/hd2d_smoke.lua | Live GPU invariants, fallback, RNG, crossfade pixel test |
| tests/hd2d_capture.lua | Settled scenes, pass captures, resolution/quality profiles |
| HD2D_ASSET_REQUIREMENTS.md | Existing vs planned assets and delivery specification |
| docs/hd2d/ | Before/after evidence, regression captures, logs, measurements |

## Files adapted

- main.lua: render/entity/VFX hooks, sharp UI, scene veils, settings, transitions,
  F1. Removed obsolete screen-wide shaders and their unused color interpolation.
- capture_screens.lua: isolated --test-hd2d mode; player saves never loaded/written.
- src/scoring_presentation.lua: existing world VFX split from sharp scoring labels.
- src/ui.lua: height-aware card shadows; original artwork/material/tilt retained.
- src/reward_system.lua: ceremony veil/frame transparency; payout unchanged.
- ui/theme.lua and ui/components/panel.lua: quiet gothic borders, navy, engraving.
- ui/shop_display.lua: shared pedestal positions, rarity/focus light, object shadow.
- ui/card_surfaces.lua: pack description wraps into a bounded excerpt; full text
  stays in hover tooltip, preventing overlap with the existing choose/keep button.
- tests/ui_theme_smoke.lua: graphics mock supports existing transform calls.

## Scene system, presets and camera

Data-driven SceneDefinitions map game states to battle/menu/shop/reward/map/rest/
archive worlds without replacing gameplay routing. Layers have id, optional
texture, procedural kind, stage, depth, parallaxFactor, offset, scale,
blurAmount, brightness and tint. Textures load once, only if present.

RUINS: blue/slate and warm practical lights, dust. ICE: cold blue haze, snow.
FOREST: green-gray haze, motes. DESERT: sand/charcoal, dust. VOID: violet motes.
VOLCANIC: red/charcoal, orange embers. MYSTIC: violet/blue/cyan motes.
Each preset defines ambientColor, fogColor/density, particleType, bloomStrength,
lightTint, colorGrade, cameraIdle and vignette. Boss IDs can override presets.

Camera uses a few logical pixels of sine/cosine drift. Existing scoring impulses
supply impact kicks. Aura phases focus/zoom toward the boss; card phases focus
lower. Boss attacks trigger directional kick and red flash. Event lighting
settles to ambient. Cards/HUD preserve input coordinates. Boss static artwork
breathes and receives contact/soft shadow, rim/tint and overlapping ground mist.

Shop keeps existing transactions, gold flight, focus/dim and flip sequencing;
world pedestals, pools/cones and translucent bays expose the chamber. Reward
keeps coin collection/loot ceremony with rare event lights and world visibility.
Menu, collection, deck, boss draft, rest and pack presentation share the direction.

## Eight checkpoints

1. PASS: World Canvas + sharp UI, live game 11 frames, same-quality resource reuse.
2. PASS: battle layers, parallax, camera and capped atmosphere; live game ran.
3. PASS: four world shaders, reduced bloom buffers, screenshot inspection.
4. PASS: boss in world; existing card effects and all 3 card shaders passed.
5. PASS: theme, settings and F1; card physics and UI layout at all three resolutions.
6. PASS: real shop OPEN -> FOCUS -> BUY -> SELL -> REROLL -> BUY, poor funds,
   cancellation, spam and Fast; existing purchase/economy lifecycle unchanged.
7. PASS: reward ceremony, 2105 frames, coins, six slots, audio, saved pack handoff,
   socketing, skip, direct card and keyboard fast-forward.
8. PASS: live GPU smoke: five shaders, seven presets, three qualities, state
   restoration, no per-draw GPU allocations, UI pixel color bypass, Canvas/shader
   fallback, RNG isolation and crossfade RGB interpolation. Settled scene images,
   all F1 passes, effects OFF and nine resolution/quality profiles captured.

Additional passing checks: poker (11), advanced features (6), card physics math,
52 abilities/evolution/old-new saves, 22 boss actives and passives, reward formulas/
all loot/save-load/capacity, nine vouchers/economy/rerolls/save-reset, scoring math
at 30/60/120/144 FPS and 24 hands, plus real scoring cases 1-4 (including 50% boss
resistance and Fast). Real scoring mean frame: 5.70 ms over 4770 frames.

The broad legacy system suite passes cases 1-99 then stops on a PRE-EXISTING name
mismatch: test_system.lua expects The Rock, while HEAD's spirit_pebble catalog
already uses the localized name. Catalog and test were left unchanged. See
system_tests.log. This suite is not claimed to pass fully.

## Visual settings, performance and fallback

Existing settings serialization stores graphicsQuality and cinematicEnabled;
old settings get defaults. No run-save schema change. The extra settings panel
preserves old hit regions. F1 cycles FINAL / LAYERS / LIGHT / BLOOM / FOG / DOF /
PARTICLES / OFF and displays camera, particle cap and CPU submission time.
Individual effect flags and tuning are in config/visual_config.lua.

| Quality | World | Bloom / DOF | Particle cap | Sharp UI |
|---|---|---|---:|---|
| LOW | 960x540 | off / off | 18 | 1920x1080 |
| MEDIUM | 1280x720 | reduced / image layers | 36 | 1920x1080 |
| HIGH | 1920x1080 | reduced / image layers | 56 | 1920x1080 |

Canvases allocate at load/quality changes, shaders compile once. No full-resolution
multipass blur. Missing resources fall back to base/direct rendering. Particles
are bounded and deterministically computed, without consuming gameplay RNG.
See docs/hd2d/performance.md for local wall-clock frame intervals and GPU/driver
context. CPU submission timing is not GPU execution time. No universal 60 FPS
claim for unspecified hardware. Warmup, captures and mode changes are excluded
from frame sample windows. Isolated renderer smoke also verifies no allocation
inside drawWorld.

## Artwork boundary and evidence

BEFORE files are archived prior captures, not controlled paired measurements.
AFTER files capture settled scenes at the named stage. Regression images include
shop focus, rare reveal and scoring attack/impact. Root legacy screenshots were
restored after tests; new evidence is confined to docs/hd2d.

Original paintings remain ONE base layer each. Procedural architecture, arena,
foreground, fog and particles are real independent render layers, but artist-
authored environment cut-outs, shop chamber and reward altar remain missing.
Seven atmosphere presets do not create seven painted biomes. Near procedural
geometry remains sharp; real foreground textures can use DOF. Menu video is a
single decoded animated layer. Final art quality requires the exact missing
assets in HD2D_ASSET_REQUIREMENTS.md. None are falsely claimed to exist.
