# Animation polish

- Hand position, rotation, hover scale, tilt, score bounce, card squash/stretch and HUD bounce use exponential response instead of a frame-dependent linear lerp. Low-FPS frames no longer snap to the target.
- Held cards use the exact damped spring solution, preserving reversal momentum without per-card substep loops. Existing presets, grab positions, shared card frame and transformed hit testing remain in use.
- Shared buttons ease hover lift, scale, border and glow in/out, and compress on press. Motion survives recreated layout tables; unseen entries expire after one second. Disabled buttons reset immediately. Hitboxes retain their logical bounds.
- VSync is enabled by default for display-synchronized presentation.

Checks:

```powershell
lua tests/animation_smoke.lua
lua tests/card_physics_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-animation
& '../love-11.5-win64/lovec.exe' . --test-card-physics
& '../love-11.5-win64/lovec.exe' . --test-scoring-feel
```

The GPU-free check compares spring position/velocity at 30/60/120/144 FPS, all damping regimes, frame stalls, reversal momentum and button transitions. Runtime capture modes exercise real input/rendering and do not write player saves.

Verified: both GPU-free checks and `--test-animation` passed. The latter exercises actual hand grab/lag/reversal/release/settle and shop/button rendering, and exports `docs/animation_polish.png`.

Broader captures are not fully passing: `--test-card-physics` passes three battle surfaces then stops at `tests/card_physics_capture.lua:67` (shop deity hold); `--test-scoring-feel` passes its first two scoring/damage cases then stops at line 55 (boss case does not start scoring); `--test-ux-polish` passes dissolve and purchase checks then stops at line 107 (inventory sale focus). These remain outside the verified animation flow. No claim of a fully passing gameplay suite.
