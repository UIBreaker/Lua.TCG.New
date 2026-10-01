# Held card physics

All existing card renderers share `src/card_physics.lua`. The adapter does not
create cards or change card stats, poker/scoring, inventory, purchases or saves.
Physics state lives outside the persisted card tables. Existing drag handlers
still decide selection, reorder, purchases and sacrifice from logical mouse input.

## Render/input flow

Mouse in logical screen coordinates → target + smoothed mouse velocity → position
spring → velocity/position-lag rotation target → angular spring → deterministic
micro-sway → pickup scale / subtle stretch / shadow → existing card renderer.
The actual final graphics transform is inverted for picking and shader mouse UV.
Physical horizontal/vertical tilt also feeds the three existing surface shaders.
On release, velocity is retained and the card settles towards its current slot
(including a reordered hand fan or SPN slot). A card dragged out of the deck
viewer returns to the visible deck pile if it isn't sacrificed.

Coverage: hand/deck/inspector/socketing cards, SPN, consumables, shop stock,
vouchers, equipment, pack choices, round rewards, collection/preview cards and
starter-deck tile. Scoring/dissolve sprites are animation-owned, not draggable.

## Tune `config/card_hold_config.lua`

- `preset` / `presets`: LIGHT, MEDIUM (default), HEAVY.
- `stiffness`: higher follows faster; lower feels heavier/more delayed.
- `damping`: higher settles sooner with less oscillation; lower keeps momentum.
- `rotationStiffness`, `rotationDamping`: angular response and settle time.
- `input.velocityToTilt`, `input.lagToTilt`, `rotation.maxAngle`: tilt strength/cap.
- `input.smoothing`, `input.maxVelocity`: smooth input and clamp spikes.
- `sway`: two tiny sine waves, only while held; no frame-random jitter.
- `pickup`: lift, scale and transition response.
- `pivot`: normalized origin (default 0.5, 0.75).
- `stretch`: toggle/cap (default 2.5%) and speed scale.
- `shadow`: held alpha and lift offset.
- `maxDt`, `step`: stall guard and spring substep.

## Developer controls

F9 toggles state, target/pivot/velocity vectors. F10 opens Card Feel Lab; Esc closes.
Drag/release the lab card. 1/2/3 choose LIGHT/MEDIUM/HEAVY. Space cycles normal,
Foil, Holographic, Polychrome. P triggers the existing scoring pulse.
Q/A: position stiffness; W/S: damping; E/D: angular stiffness; R/F: angular damping;
T/G: velocity tilt; Y/H: angle cap; U/J: micro-sway amplitude.
Runtime tuning is development-only and isn't written into the player save.

## Integrating another card renderer

Wrap an existing `(card, x, y, width, height, ...)` renderer with
`CardPhysics.wrap(renderer)`. Nested card layers don't create another physics
surface. If the renderer applies its own transform, call
`CardPhysics.capture(card, localX, localY, width, height)` after that transform.
No additional Canvas/image/shader compilation is needed. Static surfaces skip
spring integration; disappeared surfaces release their cached arguments.

## Regression checks

- `lua tests/card_physics_smoke.lua`: spring consistency at 60/120/144 FPS,
  inverse affine transform and reversal momentum.
- `lovec.exe . --test-card-physics`: real render/input integration across hand,
  SPN, consumables, shop, all nine packs, viewer return, SPN reorder, collection,
  lab/presets/shaders, lost focus and dt spike. Capture mode doesn't write saves.
- `lovec.exe . --test-pack-skip`: all nine pack skip/closing animation paths.
- `lovec.exe . --capture-shop`: card/potion/voucher purchase hitboxes.
