# Hand Attack VFX

Integrated into the existing scoring presentation queue and world renderer. No calculator, hand detection, card ability, monster damage, save, deck or shop rules are changed by this implementation.

## Files

Created: `config/hand_vfx_config.lua`, `src/hand_attacks.lua`, `tests/hand_vfx_smoke.lua`, `tests/hand_vfx_capture.lua`, `tests/hand_vfx_combat_capture.lua`, this document and `docs/hand_vfx/shot_hand_vfx_1..9.png`.

Modified for attack integration: `src/scoring_presentation.lua`, `main.lua`, `src/sound.lua`, `capture_screens.lua`, `render/renderer.lua`, `render/postprocess.lua`, `render/scene.lua`, `shaders/world_composite.glsl`. Existing uncommitted HD2D and other work is preserved.

## Profiles

| Poker ID | Card conversion | Projectile / movement | Impact | Rhythm hooks |
|---|---|---|---|---|
| high_card | Edge shards, strongest card source | One compressed piercing spear | Vertical pierce; delayed rear ring at EXTREME+ | highcard_compress |
| pair | Left/right split | Two staggered diagonal blades | X cross | pair_slash_1, pair_slash_2 |
| two_pair | Rank-group orbital directions | Four blades on two orbital axes | Four-way collapse | twopair_orbit_a, twopair_orbit_b |
| three_of_a_kind | Three-node conversion | Rotating triangle, converging nodes | Triangular seal | threekind_node_1..3 |
| straight | Sequential ascending ranks, Ace-low supported | Accelerating curved connected streaks | Long-wave final strike | straight_step_1..5 |
| flush | Fluid ribbon dissolve, faction/suit palette | Wide ribbons and sweeping wave | Elliptical tidal front | flush_wave |
| full_house | Triplet/pair clusters | Two orbiting, compressing fusion cores | Nested detonation rings | fullhouse_core_a, fullhouse_core_b, fullhouse_core_merge |
| four_of_a_kind | Four cardinal directions | Four square seals and inward beams | Square central seal/collapse | fourkind_seal_1..4 |
| straight_flush | Blade fragments | 7/11/16/22/28 blades, three depth bands, convergence, final giant blade | Giant blade and broad controlled collapse | straightflush_blade_summon, straightflush_barrage, straightflush_final |

Each profile additionally exposes its unique `<poker_id>_charge`, `<poker_id>_release`, `<poker_id>_impact` hooks. Existing synthesized sound sources are reused; no fake asset paths or missing audio files are introduced. Hook names and timestamps are independent so dedicated samples can replace aliases in `src/sound.lua` later.

## Aura / timing

Use `aura / enemy.targetAura`; use `enemy.maxHp` when targetAura is absent, and the configured 1000 fallback when the denominator is missing or non-positive. Intensity is `clamp(log(1 + min(ratio, 64)) / log(5), 0, 1)`.

| Tier | Ratio | Hit stop |
|---|---|---|
| NORMAL | < 0.5 | 25 ms |
| STRONG | 0.5 to <1 | 35 ms |
| POWERFUL | 1 to <2 | 50 ms |
| EXTREME | 2 to <4 | 65 ms |
| TRANSCEND | >=4 | 90 ms |

Conversion -> anticipation -> EXTREME/TRANSCEND convergence pause -> release -> arrival -> single existing gameplay damage dispatch -> impact/recoil/damage number -> HP main/trail -> settle. TRANSCEND interrupts active SFX for a 60 ms silence immediately before release. Fast scoring retains the existing 2x presentation clock and every attack beat; hit stop stays measured in real seconds.

The world renderer alone handles dim, focus, camera impulse, fog displacement, light and shockwave refraction. UI remains rendered after world post-processing. The Lab uses procedural glow and a target silhouette; world bloom/refraction is exercised by the real-combat integration test.

## VFX hooks

`HandAttacks.new`, `power`, `enter`, `update`, `draw`, `cardPose`, `fragments`; existing `ScoringFeel.start/update/damageApplied/camera/enemyReaction/drawWorld` remain the scoring lifecycle entry points. Damage is yielded only once at `ENEMY_IMPACT` and continues through the existing `Monster.takeDamage` handler.

## Tuning

`config/hand_vfx_config.lua`: tier boundaries/names, fallback target, silence/convergence, hitStop, quality caps, camera kick/recoil/zoom, trail segments/length/glow, procedural bloom/glow gain, shockwave radius/thickness/distortionStrength, particle count/length, arena bounds, faction/suit colors; each hand's five timing values are conversion/anticipation/projectile/impact/settle. Per-hand camera, projectile, conversion, impact, sound beat timestamps and Straight Flush blade counts are editable there. Silhouette geometry lives in named dispatch functions in `src/hand_attacks.lua`.

`config/scoring_feel_config.lua`: scoring/log steps, Normal/Fast/forward speeds, damage number/HP animation durations. `config/visual_config.lua`: existing GPU/bloom/quality settings. No shader is compiled per attack and no Canvas is allocated per frame. Procedural trails, fragments and shockwaves have no per-projectile particle tables or lifetime pool to grow; sources are allocated once per hand. LOW/MEDIUM/HIGH caps are 8/16/28; density, width, trail extent, impact and recoil are bounded by normalized intensity.

## Lab and checks

F6 opens HAND VFX LAB. Left/right selects all nine hands, 1..5 selects tier, R replays, Tab toggles Normal/Fast, Space fast-forwards, F5 toggles diagnostics, F6/Esc closes. The Lab owns an isolated animation and does not mutate the current run.

```
lua tests/hand_vfx_smoke.lua
lua tests/scoring_presentation_smoke.lua
lua test_poker.lua
../love-11.5-win64/lovec.exe . --test-hand-vfx 9
../love-11.5-win64/lovec.exe . --test-hand-vfx-combat
../love-11.5-win64/lovec.exe . --test-scoring-feel
```

Checkpoint runs completed incrementally for 2/4/6/8/9 hands, each at all five tiers and both speeds. Lua checks cover 270 sequences using real scoring results at 30/60/144 FPS, Aura boundaries/caps, Ace-low order, faction suit palette, unique silhouettes/conversions/impacts, single damage and HP ordering. Existing poker and scoring presentation tests pass. The real-combat capture covers all nine hand resolver IDs, input locking, three qualities, world shaders and one HP decrease. Existing combat capture also covers a 50% boss damage modifier and lethal impact.

## Fallbacks / limits

Audio hooks reuse existing synthesized sources rather than new bespoke recordings. GPU fallback uses procedural additive glow/rings and the existing renderer fallback if a world shader/Canvas is unavailable or cinematics are disabled; LOW quality bypasses bloom. All nine profiles have dedicated geometry. No dedicated dragon creature art is needed for Straight. The isolated Lab target is a silhouette, not a boss asset. A tuning pass on target hardware can use the replayable lab and the exposed configuration.

The HD2D GPU smoke runs inside the real-combat capture and verifies all five shaders, seven presets, three qualities, Canvas/shader reuse, UI bypass, state restoration, GPU fallback and gameplay RNG isolation. Bare Lua cannot run the GPU/UI-only tests; they require LÖVE.

## Motion polish (2026-10-04)

Charge progress is continuous across conversion, anticipation and convergence. Every projectile takes its launch origin from the final charge pose; later frames cannot move its origin or reshape the trail behind it. The shared position sampler drives both the head and the entire curved, tapered ribbon mesh. Windup pulls away from the target, with light orbital drift; release accelerates with a 2.2 power curve. Flush uses a smoother fluid curve instead. Card conversion has eased translation, a small lift and delayed shrink.

Pair and Two Pair have curved slash silhouettes with narrow blade cores. Straight Flush has depth-scaled blades, staggered convergence and early blade fading so the final giant blade remains readable. Contact starts with a narrow hot flash, followed by each hand's impact and a quickly expanding shockwave. Sparks travel back against the incoming attack. Camera and boss reaction use one damped rebound; the first hit frame already contains compression and recoil. Hit stop is 25/35/50/65/90 ms. Removed universal minimum windup/flight/impact/settle overrides that made all hands uniformly sluggish.

New regression assertions cover 135 hand/tier/quality combinations for phase continuity and stable launch origins, alongside the existing 270 real-calculator sequences. No scoring or damage behavior changes.

## Performance

Local uncapped LÖVE run with screenshots enabled: 90 Lab cases, mean frame 3.51 ms, raw peak 242.01 ms. Excluding the first 120 ms of each case: P95 4.14 ms, P99 4.65 ms, 13/21459 frames exceeded 16.67 ms. PNG capture/encoding and asset warm-up are included in the harness and can cause spikes. These are wall-clock frame intervals, not isolated GPU timings or a guarantee for other hardware. Latest final-run measurements are recorded in `docs/hand_vfx/performance.txt`.
