# Battle death presentation

## Files

Added `config/death_vfx_config.lua`, `src/death_vfx.lua`,
`shaders/enemy_ash_dissolve.glsl`, `tests/death_vfx_capture.lua` and this document.
Integrated into `main.lua`, `render/renderer.lua`, `render/lighting.lua`,
`src/sound.lua` and `capture_screens.lua`. Existing uncommitted HD2D/hand VFX
changes were retained.

## Architecture and lifecycle

DeathVFX is a presentation controller. It never writes HP, rewards, cards,
boss data, saves, or gameplay RNG. It reuses render.camera, render.lighting,
the existing world/UI render passes and Sound hooks. All easing is elapsed-time
based; death durations are independent of fast scoring.

Enemy: final damage or a live zero-HP observation starts the sequence once per
monster instance. The original scoring queue continues after a 45/55/70 ms
presentation hold. Its finished handler waits until ash settles before executing
the existing victory/reward handler once. Mini/elite/boss durations are
1.08/1.25/1.48 s. Staged flash, recoil, internal cracks, spatial dissolve,
directional ash/embers/smoke, floor residue and fading floor glow retain body
presence through the transformation. Elite/boss also get a restrained ring.

Player: all five original gameover transition sites call beginPlayerDefeat.
The existing deleteRun call stays at the original gameplay outcome site. The
temporary `defeating` state updates presentation while battle input is blocked.
The scene and victorious enemy remain visible; cards slump/tilt/darken, soul
light breaks apart, fog and vignette close, practical lights weaken and camera
drifts/zooms slightly. Played card references are retained when the hand is empty,
including a lethal enemy pre-score attack. No card attributes are changed for
the effect. Title reveals at 0.98 s, information/buttons at 1.42 s and the existing
gameover/retry handler becomes active at 1.70 s. Dust continues drifting after
settle. Retry uses the original menu flow.

## Audio

Hooks use existing generated sounds; no fictional asset paths:

| Hook | Existing sound |
|---|---|
| enemy_death_hit | damage_heavy |
| enemy_ash_break | chest_dissolve |
| defeat_hit | damage_heavy |
| defeat_collapse | card_destroy |
| defeat_ambience | game_over (low pitch/gain) |
| defeat_text_reveal | score_impact (low pitch/gain) |

There is only menu music in the current audio implementation, so no battle
music bus/low-pass system was added. Independent gains live in src/sound.lua.

## Tuning and fallback

Edit config/death_vfx_config.lua: enemy presets (duration, hit-stop, amount,
camera kick, size), normalized crack/break/dissolve windows, ember/crack/ash/smoke
palette, recoil, ash drift, floor presence; player timing, drop/tilt, camera
drift/zoom, torchDim, soul/shadow; overlay title, sigil, vignette/dust; particle
quality caps and lifetimes. burstAt and player times are seconds; enemy crackAt,
breakAt and dissolvedAt are fractions of the sequence.

LOW/MEDIUM/HIGH caps are 40/78/120, further scaled for smaller enemies. A fixed
120-object pool is allocated once. Three silhouette point sets are sampled once
from existing artwork; ImageData is released. Shader compilation is once at load;
no death canvas or per-frame shader/canvas allocation is introduced. Existing
radial light texture supplies smoke/ember softness. Missing shader uses a stencil
grid that breaks the actual image into holes and retains particles/recoil/floor
presence, rather than reducing the effect to an alpha fade. Missing artwork
falls back to a bounded emitter footprint, as the existing entity renderer also
has no image to draw.

## Replay and verification

```powershell
& '../love-11.5-win64/lovec.exe' . --test-death-vfx
# Quick player sequence replay (no real HP change)
& '../love-11.5-win64/lovec.exe' . --test-death-vfx --death-preview-only
```

The capture harness replays mini/elite/boss, player defeat, actual mini/boss kills
through CASH_OUT, pre-score death, counterattack death, end-turn death, The Needle
hand exhaustion, all three quality levels and a forced shader fallback. It checks
damage applies once, rewards wait for settle, encounter count advances once,
defeat grants no gold, all particle families exist and audio hooks resolve.
Save write/delete methods are stubbed in this harness before gameplay callbacks.
Screenshots and local performance measurements are in docs/death_*.png and
docs/death_performance.log. These measure uncapped wall-clock frame intervals
on this machine with the full battle UI, not a guarantee for other hardware.

Checkpoint runtime checks passed for basic enemy, polished enemy presets,
basic player, polished player, and final integration/fallback/quality.
Poker (11 cases) and advanced features passed. The larger system suite stops at
test_system.lua:2868: deity name expected `The Rock`, actual `Cổ Thạch`;
test_system.lua and src/deities.lua are outside the VFX changes. Standalone Lua
cannot run the graphics-dependent parts of the system/features suites; use LÖVE.
