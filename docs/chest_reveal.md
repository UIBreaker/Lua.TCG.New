# Relic chest reveal

Visual reference: the user's `FFF.mp4` (3.46 seconds). The reference container tilts, dissolves into bright fragments, and three reward faces materialize from those fragments. Its content is a visual reference only.

The game now follows that sequence with its existing continental artwork: a restrained chest shake, ivory and antique-gold flakes, three cards spreading from the chest center, and a reverse dissolve that reconstructs the complete face and shared frame. Each card appears 0.11 seconds after the previous one. The glow follows the reward palette and fades when the reveal settles. No extra permanent frame or text is added to the artwork.

The same `ui/chest_choices.lua` path serves victory chests, treasure chests and shop packs. A reward's actions stay locked until its face and position have settled. Keep/use, full-inventory guards, cancellation and persistence retain their existing behavior. The reveal uses the existing reusable dissolve shader/canvas and radial light texture; particles use deterministic formulas and never consume reward RNG.

Checks: `tests/chest_reveal_smoke.lua` at 30/60/144 FPS; `--test-chest-vfx` for actual use/keep/cancel/equip/full inventory; `--test-pack-skip` for shop pack dismissal. Captures: `docs/chest_shards.png`, `docs/chest_gather.png`, `docs/chest_materialize.png`, `docs/chest_choices.png`.
