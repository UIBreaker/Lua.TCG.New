# Scoring / Combat Presentation

This is an original presentation layer over the existing calculator. It does not replace poker detection, scoring, SPN scaling, editions, damage conversion, attack-speed turn order, rewards or saves.

## Actual pipeline

Play Hand → button rebound → staggered lift/travel → localized hand reveal → base Sát thương → base Cường hóa → each card contribution → that card's ITM/enhancement/seal/SPN/edition contributions → hand-level SPN → exact formula → eased AURA count-up → peak → card-to-energy conversion → convergence for high AURA → brief charge → release → projectile arrival → existing monster damage/rewards/counterattack → HP/trailing-bar easing → settle → existing next-state logic.

Cards remain visible throughout scoring. High AURA uses a charged core and beam; low AURA uses individual colored streaks. Energy derives its color from the existing Foil/Holographic/Polychrome definitions. Only peak and impact use stronger feedback. Intensity is logarithmic and bounded.

## Files

Created:

- `config/scoring_feel_config.lua`: timing, speed, logarithmic intensity, caps, colors, audio mappings.
- `src/scoring_presentation.lua`: queue, stat tweening, links, energy, camera reaction, HP presentation, debug overlay and isolated lab.
- `tests/scoring_presentation_smoke.lua`: real calculator + presentation checks at multiple frame rates.
- `tests/scoring_feel_capture.lua`: actual LÖVE renderer/audio/input/combat regression and screenshots.
- `docs/scoring_presentation.md`: this guide.

Updated:

- `src/scoring.lua`: numeric reporting metadata only. Embedded ITM/enhancement/SPN/edition contributions are recorded after their existing calculations, not re-evaluated. Adds the actual card/equipment multiplier used in rawScore, distinct from the combined informational XMult.
- `main.lua`: hooks the queue into Play Hand/update/draw, keeps the existing damage/reward/lifecycle handler, input lock, fast-forward, camera/HP timing, capture hook.
- `src/ui.lua`: exposes the controller through UI without adding another main.lua closure upvalue; fades edition rims during energy conversion.
- `ui/components/hand_info_panel.lua`: separate stat glow/pulses and HP trail.
- `ui/components/enemy_panel.lua`, `ui/components/progress_bar.lua`: reuse the HP bar with a trailing value.
- `capture_screens.lua`: isolated test flag dispatch.

## Real hooks

- Calculator: `Scoring.calculate` still supplies every gameplay result and `result.steps`.
- Base Sát thương/Cường hóa: `BASE_DAMAGE` / `BASE_ENHANCE` in the queue.
- Card: `card_scored` becomes the base card event, followed by recorded child contributions. The adapter subtracts child deltas from the aggregate for display only, preventing double-counting.
- SPN: `deity_card`, `deity_hand`, `deity_edition` events use real slot positions, pulses and exact resulting stats.
- ITM/enhancement/seal: `presentationTriggers` plus existing standalone trigger steps.
- AURA: `FORMULA` uses calculator totals, rawScore and finalScore. Both existing floor operations, extra-damage conversion, edition multiplier and Foil flat damage are preserved. `AURA_COUNT` animates towards finalScore; it never recalculates damage.
- Shader: existing `CardEffects.triggerScorePulse(card)` for card/SPN triggers, peak and conversion. Shaders and image resources remain shared.
- Enemy damage: `ScoringFeel.update(anim, dt, fast)` returns the original `final_score` step exactly once, at `ENEMY_IMPACT`. Only then does main call the existing `Monster.takeDamage`.
- HP: `ScoringFeel.damageApplied(anim, hpAfter, actualDamage)` begins the visual HP/trail transition and shows actual damage (including boss conversion), not blindly the AURA value.
- Input unlock: `ScoringFeel.isFinished(anim)` must be true before the old combat-outcome handler runs.

Some existing scoring effects mutate logical state while calculating (e.g. Ashen Seal's true damage). Their presentation HP is held at the pre-scoring snapshot until impact; their gameplay behavior has not been rewritten.

## Tuning and controls

Edit `config/scoring_feel_config.lua`:

- `timing`: button, lift/travel/stagger, base/card/modifier/SPN gaps, multiplier anticipation, formula, count-up range, peak, conversion/convergence, release/beam, impact/HP/trail/settle/camera.
- `speed.normal/fast/forward`: Normal, existing “Siêu Tốc (2x)” setting, and interactive fast-forward.
- `aura.expectedMagnitude`: logarithmic normalization (default 1,000,000 reaches maximum).
- `aura.convergenceThreshold`: core/beam instead of individual streaks (default 10,000).
- `impact`: bounded hit-stop, kick, particle count and knockback.
- `pulse`: card/SPN/Sát thương/Cường hóa/multiplier scales; `aura.maxScale`: peak scale cap.
- `color`: Sát thương cyan, Cường hóa red, AURA gold.
- `audio`: mappings to existing synthesized sounds, pitch range/step; no fake asset paths or runtime sound generation.
- `maxFrameDt`: prevents short presentation beats from disappearing after a stalled rendering frame.

Controls:

- Settings → Normal / Siêu Tốc: affects the entire queue, not only scoring ticks.
- Space/Enter or arena click during scoring: fast-forward without bypassing the damage handshake.
- F5: scoring debug (event/index, displayed stats, normalized intensity, time, impact pending, FPS).
- F6: Scoring Feel Lab, separate from the live run. Keys 1–5 simulate 100 / 1K / 10K / 100K / 1M AURA. Tab toggles Normal/Fast; Space fast-forwards; F6/Escape closes.

## Verification

```text
lua tests/scoring_presentation_smoke.lua
lua tests/card_effects_smoke.lua
lua tests/shop_vouchers_smoke.lua
lua tests/card_physics_smoke.lua
lovec.exe . --test-scoring-feel
lovec.exe . --test-pack-skip
lovec.exe . --test-card-physics --physics-tail
```

The LÖVE test never writes the player's save. It exercises real one-card and five-card scoring, shader editions, modifiers, Normal/Fast, input locking, projectile-before-HP timing, exactly one damage application, boss damage conversion, survival/victory transitions and lab isolation. Screenshots and frame-time logs are generated for review; these are measurements of the test environment, not a promise for every GPU.

Verified run: 63 AURA → 63 damage; 1,388,116 AURA → 1,388,116 damage; the same AURA against the test boss → 694,058 damage; victory/lab isolation passed. Mean frame time 5.08ms over 5,326 frames in the captured test. All nine chest skip paths and the held-card regression also passed. See `scoring_feel_runtime.log`, `scoring_pack_regression.log`, `scoring_physics_regression.log` and `shot_scoring_*_2.png` for retained evidence.
