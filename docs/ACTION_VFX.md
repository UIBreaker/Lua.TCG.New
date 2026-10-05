# Final VFX juice pass

Only the existing ten action effects were tuned. Score/damage formulas, HP/armor rules, attack-speed ordering, prices, inventory mutations and transaction input locks are unchanged. No new effect profile, mechanic, texture, dependency or GPU effect resource was added.

| Existing effect | Cue duration | Contact | Final response | Final GPU repeats |
| --- | --- | --- | --- | --- |
| Armor gain | 520 ms | 100 ms | Accelerated assembly, readable plate, short number pulse | 10/10 |
| Armor loss | 460 ms | 25 ms | One plate splits into six angular pieces; inertia, rotation, gravity and cold solid surfaces | 10/10 |
| Heal | 700 ms | 170 ms | Five soft converging motes, gentle cross/ripple, low number pulse | 10/10 |
| Hurt | 300 ms | Immediate | Three directed splinters, short slash, restrained flash/shake and 40/60 ms visual hitstop | 10/10 |
| Equip | 480 ms after contact | Application arrival | Accelerating approach; socket compression/rebound, card spring impulse, firm 200 ms lock sound | 10/10 |
| Destroy | 640 ms | 45 ms | Six charred fragments with hot edges rise; card shrinks and burns monotonically | 10/10 |
| Enemy first | 600 ms | 40 ms | Aggressive short leftward strokes, red silhouette and cue | 10/10 |
| Player first | 580 ms | 60 ms | Smooth rightward acceleration, cyan silhouette and cue | 10/10 |
| Buy | 440 ms after arrival | Item reaches destination | Earlier flight, ownership stamp at destination, short round rebound/chime | 10/10 |
| Sell | 520 ms | 80 ms | Item dissolves into four coins traveling to the wallet; pulse/chime at payout | 10/10 |

Equip approaches for the existing application contact time (270 ms Normal / 135 ms Fast). Buy flight now starts at 24% and reaches its target at 84% of the existing 550 ms transaction. UI transaction durations and input locks remain unchanged. Linked sell/destruction cues follow the presentation clock in Fast mode; their final tail releases normally. Duplicate HUD/contact and transaction sounds are suppressed. Gain/heal/Hurt/armor numbers now have separate pulse strengths; HP/armor HUD labels also respond briefly without resizing their bars.

Glow is concentrated on silhouettes and contact. Particle counts and full-screen camera response were reduced. Destruction ghosts no longer hop back toward their origin. Legacy purchase/sacrifice animations use the same arrival/coin direction rules; existing consumable presentation was preserved.

Validation of the final implementation:
- `lua tests/action_vfx_juice_smoke.lua`: each effect 10 consecutive times at 30/60/144 FPS (300 runs), contact audio exactly once, expiry, no residual queue, no gameplay RNG consumption; exactly ten profiles.
- `lua tests/action_vfx_smoke.lua`: signed stat events, bounded queue, destruction dedup, equipment contact, rejected/successful/spam transactions, buy stamp only at arrival, soul destruction.
- LÖVE `--test-action-vfx-juice`: 100 actual action triggers, each effect 10 consecutive times, alternating Normal/Fast. All ten passed. Uses real stat changes, attachment, ability destruction, attack ordering and Shop confirmations. GPU draw restores graphics state and allocates no Canvas/shader for the ten accents. Reverification also asserts real equip spring motion on its contact frame, one audible-cue request with matching timestamp/pitch, and removal of each cue before the next repeat. All 100 reverified actions passed.
- LÖVE `--test-enemy-attacks`: all four timeline cases passed, including three sequential attackers, contact-only damage and input locks.
- LÖVE `--test-soul-shop`: live destruction, boss transition, soul purchase, socket return and exit passed.
- Combat feedback, scoring presentation, enemy presentation, card physics and soul shop smoke checks passed; changed Lua files parse and diff whitespace checks pass.

`docs/action_vfx/juice_contact_sheet.png` is the current visual study of opening/contact/tail frames. Older preview images show the pre-pass version. All runtime tests use capture mode and do not write player saves. Capture/export stalls are included in the test frame measurements, so those measurements are not a production FPS benchmark.
